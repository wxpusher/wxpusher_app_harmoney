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
    const insertIndex = this.messageListData.findIndex(m => m.messageId < message.messageId);
    if (insertIndex === -1) {
      this.messageListData.push(message);
    } else {
      this.messageListData.splice(insertIndex, 0, message);
    }
    this.view?.onMessageList([...this.messageListData]);
    this.saveRefreshListData();
  }

  refresh(scene: number): void {
    WxpLogUtils.d('WxPusher', '开始刷新-refresh');
    if (this.loading) return;
    if (WxpMessageListReqScene.SceneManual === scene) {
      this.view?.onFeedback();
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.loading = true;
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
        if (this.clickMessage) {
          const found = fetchResultList.find(m => m.messageId === this.clickMessage?.messageId);
          if (found) {
            found.read = this.clickMessage?.read === true;
          }
        }
        this.messageListData = [...fetchResultList];
        const last = this.messageListData[this.messageListData.length - 1];
        this.lastMessageId = last?.messageId ?? MAX_MESSAGE_ID;
        this.hasMore = this.messageListData.length >= this.pageMinCount;
        this.view?.showMessageMoreLoading(false, this.hasMore);
        this.view?.onMessageList([...this.messageListData]);
        if (!this.key || this.key.length === 0) {
          this.saveRefreshListData();
        }
      }
      this.loading = false;
    });
  }

  fetchMessageResume(): void {
    WxpLogUtils.d('WxPusher', '开始刷新-fetchMessageResume');
    if (this.loading) return;
    if (!WxpAppDataService.getLoginInfo()?.deviceToken) {
      WxpLogUtils.d('WxPusher', '开始刷新-fetchMessageResume-没有登录，放弃刷新');
      return;
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.loading = true;
      const fetchResultList = await WxpApiService.fetchMessageList({
        messageId: MAX_MESSAGE_ID,
        key: this.key ?? undefined,
        scene: WxpMessageListReqScene.SceneFetchResume,
      });
      WxpSaveService.setDouble(this.MessageRefreshTimeKey, WxpDateTimeUtils.getTimestamp());
      if (fetchResultList !== null) {
        for (const message of fetchResultList) {
          const has = this.messageListData.some(m => m.messageId === message.messageId);
          if (has) continue;
          const insertIndex = this.messageListData.findIndex(m => m.messageId < message.messageId);
          if (insertIndex === -1) {
            this.messageListData.push(message);
          } else {
            this.messageListData.splice(insertIndex, 0, message);
          }
        }
        this.view?.onMessageList([...this.messageListData]);
        this.saveRefreshListData();
      }
      this.loading = false;
    });
  }

  getTipsOfLastRefreshTime(): string {
    const time = WxpSaveService.getDouble(this.MessageRefreshTimeKey, 0);
    if (time <= 0) {
      return '更新于 无';
    }
    return '更新于 ' + WxpDateTimeUtils.getRelativeDateTime(time);
  }

  private saveRefreshListData(): void {
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
