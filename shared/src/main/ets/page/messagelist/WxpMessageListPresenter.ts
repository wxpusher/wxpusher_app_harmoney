import { WxpApiService } from '../../api/WxpApiService';
import { WxpAppDataService } from '../../base/biz/WxpAppDataService';
import { WxpBaseMvpPresenter } from '../../base/common/WxpBaseMvp';
import { WxpDateTimeUtils } from '../../base/common/WxpDateTimeUtils';
import { WxpDialogUtils, WxpDialogParams } from '../../base/common/WxpDialogUtils';
import { WxpLogUtils } from '../../base/common/WxpLogUtils';
import { WxpSaveService } from '../../base/common/WxpSaveService';
import { WxpScopeUtils } from '../../base/common/WxpScopeUtils';
import {
  WxpCheckAppMsgReasonResp,
  WxpListBannerResp,
  WxpMessageListMessage,
  WxpMessageListReqScene,
} from './WxpMessageListBean';
import { IWxpMessageListPresenter, IWxpMessageListView } from './WxpMessageListPageContract';
import { WxpMessageListMerger } from './WxpMessageListMerger';

const MAX_MESSAGE_ID = Number.MAX_SAFE_INTEGER;

export class WxpMessageListPresenter extends WxpBaseMvpPresenter<IWxpMessageListView, IWxpMessageListPresenter>
  implements IWxpMessageListPresenter {
  private readonly MessageRefreshTimeKey = 'WxpMessageList_MessageRefreshTimeKey';
  private readonly BannerHasCloseIdKey = 'WxpMessageList_hasCloseBannerId';

  private clickMessage: WxpMessageListMessage | null = null;
  private messageListData: WxpMessageListMessage[] = [];
  private lastMessageId: number = MAX_MESSAGE_ID;
  private pageMinCount = 20;
  private key: string | null = null;
  private hasMore = true;
  private loading = false;
  private lastCheckNoMsgTime: number = 0;
  private checkNoMsgResp: WxpCheckAppMsgReasonResp | null = null;
  private lastFetchNoTime: number = 0;

  /** 同步锚点：最近一次从服务端拉到的最大消息 id，规则见 WxpMessageListMerger.merge */
  private syncedMaxId: number = 0;
  /** 请求进行中又需要增量拉取，先记下来，当前请求结束后补拉一次 */
  private pendingFetch = false;
  /** 请求进行中用户触发了刷新，先记下场景，当前请求结束后再刷新，避免刷新被丢掉、下拉头一直转 */
  private pendingRefreshScene: number | null = null;
  /** 当前是否有全量刷新在跑，以及它用的搜索词：同一个搜索词的刷新再来一次时直接忽略 */
  private refreshInFlight = false;
  private refreshingKey: string | null = null;
  /** 推送到达信号的防抖定时器 */
  private signalDebounceTimer: number = -1;
  private readonly SignalDebounceMillis = 1500;
  /** 回前台增量拉取的节流 */
  private lastForegroundFetchTime: number = 0;
  private readonly ForegroundThrottleMillis = 5000;

  constructor(view: IWxpMessageListView) {
    super(view);
  }

  searchIfChanged(key: string | null): void {
    if (this.key !== key) {
      this.key = key;
      this.refresh(WxpMessageListReqScene.SceneSearch);
    }
  }

  init(): void {
    const cached = WxpAppDataService.getCacheMessageList();
    if (cached) {
      this.messageListData = [...cached];
      // 缓存本身就是服务端数据，可以作为同步锚点
      this.syncedMaxId = cached.length > 0 ? Math.max(...cached.map(m => m.messageId)) : 0;
      this.view?.onMessageList(cached);
    }
  }

  onReceiveNewMessage(message: WxpMessageListMessage): void {
    this.clickMessage = message;
    const existingIndex = this.messageListData.findIndex(m => m.messageId === message.messageId);
    if (existingIndex !== -1) {
      this.messageListData[existingIndex] = { ...this.messageListData[existingIndex], read: message.read };
      this.view?.onMessageList([...this.messageListData]);
      this.saveRefreshListData();
      return;
    }
    // 搜索中不往搜索结果里插入，退出搜索时会全量刷新
    if (this.isSearching()) {
      return;
    }
    const insertIndex = this.messageListData.findIndex(m => m.messageId < message.messageId);
    if (insertIndex === -1) {
      this.messageListData.push(message);
    } else {
      this.messageListData.splice(insertIndex, 0, message);
    }
    this.view?.onMessageList([...this.messageListData]);
    this.saveRefreshListData();
  }

  onPushSignal(): void {
    if (this.signalDebounceTimer !== -1) {
      clearTimeout(this.signalDebounceTimer);
    }
    this.signalDebounceTimer = setTimeout(() => {
      this.signalDebounceTimer = -1;
      WxpLogUtils.d('WxPusher', '推送到达信号-增量拉取');
      this.fetchIncremental();
    }, this.SignalDebounceMillis);
  }

  onAppForeground(): void {
    const now = WxpDateTimeUtils.getTimestamp();
    if (now - this.lastForegroundFetchTime < this.ForegroundThrottleMillis) {
      WxpLogUtils.d('WxPusher', '回到前台-5秒内已拉取过，跳过');
      return;
    }
    this.lastForegroundFetchTime = now;
    WxpLogUtils.d('WxPusher', '回到前台-增量拉取');
    this.fetchIncremental();
  }

  onDestroy(): void {
    if (this.signalDebounceTimer !== -1) {
      clearTimeout(this.signalDebounceTimer);
      this.signalDebounceTimer = -1;
    }
    super.onDestroy();
  }

  refresh(scene: number): void {
    WxpLogUtils.d('WxPusher', '开始刷新-refresh');
    if (this.loading) {
      // 正在跑的就是同一个搜索词的全量刷新，结果一样，不用再刷一次，它结束时会收起下拉动画
      // （列表页冷启动时 Refresh 组件会连着触发两次刷新，不忽略就会多发一次请求）
      if (this.refreshInFlight && this.refreshingKey === this.key) {
        return;
      }
      // 当前有其他请求在跑，等它结束后再刷新
      this.pendingRefreshScene = scene;
      return;
    }
    if (WxpMessageListReqScene.SceneManual === scene) {
      this.view?.onFeedback();
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.loading = true;
      this.refreshInFlight = true;
      this.refreshingKey = this.key;
      this.view?.showMessageRefreshing(true);
      const fetchResultList = await WxpApiService.fetchMessageList({
        messageId: MAX_MESSAGE_ID,
        key: this.key ?? undefined,
        scene: scene,
      });
      this.view?.showMessageRefreshing(false);
      WxpSaveService.setDouble(this.MessageRefreshTimeKey, WxpDateTimeUtils.getTimestamp());
      if (fetchResultList !== null) {
        //如果有被点击消息，就更新一下被点击消息的状态
        //只用来改成已读：不能用它把服务端的已读改回未读
        if (this.clickMessage?.read === true) {
          const found = fetchResultList.find(m => m.messageId === this.clickMessage?.messageId);
          if (found) {
            found.read = true;
          }
        }
        // 搜索结果不能作为同步锚点
        if (!this.isSearching()) {
          this.syncedMaxId = fetchResultList.length > 0 ? Math.max(...fetchResultList.map(m => m.messageId)) : 0;
        }
        this.messageListData = [...fetchResultList];
        const last = this.messageListData[this.messageListData.length - 1];
        this.lastMessageId = last?.messageId ?? MAX_MESSAGE_ID;
        this.hasMore = this.messageListData.length >= this.pageMinCount;
        this.view?.showMessageMoreLoading(false, this.hasMore);
        this.view?.onMessageList([...this.messageListData]);
        this.saveRefreshListData();
      }
      this.loading = false;
      this.refreshInFlight = false;
      this.runPendingRequest();
    });
  }

  fetchMessageResume(): void {
    WxpLogUtils.d('WxPusher', '开始刷新-fetchMessageResume');
    this.fetchIncremental();
  }

  /**
   * 增量拉取：请求第一页，按 WxpMessageListMerger.merge 的规则合并进列表
   * 有重叠只补齐缺失的消息，有断层就用第一页替换整个列表，都只发一次请求
   */
  private fetchIncremental(): void {
    // 搜索中不合并，退出搜索时会全量刷新
    if (this.isSearching()) {
      WxpLogUtils.d('WxPusher', '增量拉取-搜索中，跳过');
      return;
    }
    if (!WxpAppDataService.getLoginInfo()?.deviceToken) {
      WxpLogUtils.d('WxPusher', '增量拉取-没有登录，跳过');
      return;
    }
    if (this.loading) {
      this.pendingFetch = true;
      return;
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.loading = true;
      try {
        const fetchResultList = await WxpApiService.fetchMessageList({
          messageId: MAX_MESSAGE_ID,
          scene: WxpMessageListReqScene.SceneFetchResume,
        });
        // 请求期间进入了搜索，丢弃结果，退出搜索时会全量刷新
        if (fetchResultList !== null && !this.isSearching()) {
          WxpSaveService.setDouble(this.MessageRefreshTimeKey, WxpDateTimeUtils.getTimestamp());
          const mergeResult = WxpMessageListMerger.merge(this.messageListData, fetchResultList, this.syncedMaxId);
          this.syncedMaxId = mergeResult.syncedMaxId;
          this.messageListData = mergeResult.list;
          if (mergeResult.replaced) {
            WxpLogUtils.d('WxPusher', '增量拉取-有断层，替换整个列表');
            const last = this.messageListData[this.messageListData.length - 1];
            this.lastMessageId = last?.messageId ?? MAX_MESSAGE_ID;
            this.hasMore = this.messageListData.length >= this.pageMinCount;
            this.view?.showMessageMoreLoading(false, this.hasMore);
          }
          this.view?.onMessageList([...this.messageListData]);
          this.saveRefreshListData();
        }
      } finally {
        this.loading = false;
      }
      this.runPendingRequest();
    });
  }

  /**
   * 当前请求结束后，执行期间被推迟的请求，刷新优先，刷新本身就包含了增量拉取
   */
  private runPendingRequest(): void {
    const scene = this.pendingRefreshScene;
    if (scene !== null) {
      this.pendingRefreshScene = null;
      this.pendingFetch = false;
      this.refresh(scene);
      return;
    }
    if (this.pendingFetch) {
      this.pendingFetch = false;
      this.fetchIncremental();
    }
  }

  private isSearching(): boolean {
    return !!this.key && this.key.length > 0;
  }

  getTipsOfLastRefreshTime(): string {
    const time = WxpSaveService.getDouble(this.MessageRefreshTimeKey, 0);
    if (time <= 0) {
      return '更新于 无';
    }
    return '更新于 ' + WxpDateTimeUtils.getRelativeDateTime(time);
  }

  private saveRefreshListData(): void {
    // 搜索的时候，不保存缓存，否则下次启动会用搜索结果渲染首页
    if (this.isSearching()) {
      return;
    }
    WxpAppDataService.setCacheMessageList(this.messageListData);
  }

  loadMore(): void {
    if (!this.hasMore) {
      WxpLogUtils.d('WxPusher', 'loadMore-没有更多数据，不进行加载');
      return;
    }
    if (this.messageListData.length < this.pageMinCount) {
      WxpLogUtils.d('WxPusher', 'loadMore-数据不够1页，不加载更多');
      this.hasMore = false;
      this.view?.showMessageMoreLoading(false, this.hasMore);
      return;
    }
    // 增量拉取和加载更多都会改列表，不能同时跑，结束加载状态让用户稍后再拉
    if (this.loading) {
      WxpLogUtils.d('WxPusher', 'loadMore-有请求进行中，不加载');
      this.view?.showMessageMoreLoading(false, this.hasMore);
      return;
    }
    this.view?.onFeedback();
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.loading = true;
      this.view?.showMessageMoreLoading(true, this.hasMore);
      const fetchResultList = await WxpApiService.fetchMessageList({
        messageId: this.lastMessageId,
        key: this.key ?? undefined,
        scene: WxpMessageListReqScene.SceneLoadMore,
      });
      if (fetchResultList !== null) {
        if (fetchResultList.length === 0) {
          this.hasMore = false;
        } else {
          this.messageListData.push(...fetchResultList);
          const last = this.messageListData[this.messageListData.length - 1];
          this.lastMessageId = last?.messageId ?? MAX_MESSAGE_ID;
          this.view?.onMessageList([...this.messageListData]);
        }
      }
      this.view?.showMessageMoreLoading(false, this.hasMore);
      this.loading = false;
      this.runPendingRequest();
    });
  }

  markMessageReadStatus(messageId: number | null, read: boolean): void {
    WxpScopeUtils.runAtMainSuspend(async () => {
      await WxpApiService.markMessageReadStatus(messageId, read, () => {
        if (messageId === null) {
          // 创建新对象：ArkUI ForEach 以 key 做 diff，原地修改属性不会触发重渲染
          this.messageListData = this.messageListData.map(m => ({ ...m, read }));
        } else {
          this.messageListData = this.messageListData.map(m =>
            m.messageId === messageId ? { ...m, read } : m
          );
        }
        this.view?.onMessageList([...this.messageListData]);
      });
    });
  }

  /**
   * @deprecated 请使用 executeDeleteById(id) 代替。
   *
   * 此方法内部通过 WxpDialogUtils（底层调用全局 promptAction）弹出确认框，
   * 但在 bindContextMenu 场景下，菜单关闭时会销毁其 overlay 窗口，导致全局
   * promptAction 的 UI 上下文短暂失效，showDialog 调用会静默失败。
   *
   * 正确做法：由调用方（页面组件）使用 this.getUIContext().getPromptAction()
   * 弹出确认框（绑定到主窗口上下文），确认后再调用 executeDeleteById(id)。
   */
  deleteById(id: number): void {
    const params: WxpDialogParams = {
      title: '确认删除消息',
      message: '你确认删除此消息吗？删除后不可恢复。',
      leftText: '取消',
      rightText: '删除',
      rightBlock: () => {
        WxpScopeUtils.runAtMainSuspend(async () => {
          await WxpApiService.deleteMessageById(id, () => {
            this.messageListData = this.messageListData.filter(m => m.messageId !== id);
            this.view?.onMessageList([...this.messageListData]);
          });
        });
      },
    };
    WxpDialogUtils.showDialog(params);
  }

  executeDeleteById(id: number): void {
    WxpScopeUtils.runAtMainSuspend(async () => {
      await WxpApiService.deleteMessageById(id, () => {
        this.messageListData = this.messageListData.filter(m => m.messageId !== id);
        this.view?.onMessageList([...this.messageListData]);
      });
    });
  }

  markMessageReadStatusBatch(ids: number[], read: boolean): void {
    if (!ids || ids.length === 0) {
      return;
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      await WxpApiService.markMessageReadStatusBatch(ids, read, () => {
        const idSet = new Set<number>(ids);
        this.messageListData = this.messageListData.map(m =>
          idSet.has(m.messageId) ? ({ ...m, read }) : m
        );
        this.view?.onMessageList([...this.messageListData]);
        this.saveRefreshListData();
      });
    });
  }

  executeDeleteByIds(ids: number[]): void {
    if (!ids || ids.length === 0) {
      return;
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      await WxpApiService.deleteMessagesByIds(ids, () => {
        const idSet = new Set<number>(ids);
        this.messageListData = this.messageListData.filter(m => !idSet.has(m.messageId));
        this.view?.onMessageList([...this.messageListData]);
        this.saveRefreshListData();
      });
    });
  }

  executeDeleteAll(): void {
    WxpScopeUtils.runAtMainSuspend(async () => {
      await WxpApiService.deleteAllMessages(() => {
        this.messageListData = [];
        this.view?.onMessageList([]);
        this.saveRefreshListData();
      });
    });
  }

  fetchCheckReason(): void {
    if (WxpDateTimeUtils.getTimestamp() - this.lastCheckNoMsgTime < 10 * 60 * 1000) {
      this.view?.onCheckReason(this.checkNoMsgResp);
      return;
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.checkNoMsgResp = await WxpApiService.checkReason();
      this.lastCheckNoMsgTime = WxpDateTimeUtils.getTimestamp();
      this.view?.onCheckReason(this.checkNoMsgResp);
    });
  }

  fetchListBanner(): void {
    if (WxpDateTimeUtils.getTimestamp() - this.lastFetchNoTime < 10 * 60 * 1000) {
      return;
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      const listBannerResp = await WxpApiService.getListBanner();
      this.lastFetchNoTime = WxpDateTimeUtils.getTimestamp();
      if (listBannerResp?.id === WxpSaveService.getInt(this.BannerHasCloseIdKey, 0)) {
        return;
      }
      this.view?.onListBanner(listBannerResp);
    });
  }

  closeListBanner(bannerId: number | null): void {
    if (bannerId !== null) {
      WxpSaveService.setInt(this.BannerHasCloseIdKey, bannerId);
    }
    this.view?.onListBanner(null);
  }
}
