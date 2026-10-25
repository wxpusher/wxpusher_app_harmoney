import { IWxpBaseMvpPresenter, IWxpBaseMvpView } from '../../base/common/WxpBaseMvp';
import { WxpCheckAppMsgReasonResp, WxpListBannerResp, WxpMessageListMessage } from './WxpMessageListBean';

export interface IWxpMessageListView extends IWxpBaseMvpView<IWxpMessageListPresenter> {
  showMessageRefreshing(refreshing: boolean): void;
  showMessageMoreLoading(loading: boolean, hasMore: boolean): void;
  onMessageList(data: WxpMessageListMessage[]): void;
  onFeedback(): void;
  onCheckReason(data: WxpCheckAppMsgReasonResp | null): void;
  onListBanner(data: WxpListBannerResp | null): void;
}

export interface IWxpMessageListPresenter extends IWxpBaseMvpPresenter<IWxpMessageListView, IWxpMessageListPresenter> {
  init(): void;
  getTipsOfLastRefreshTime(): string;
  onReceiveNewMessage(message: WxpMessageListMessage): void;
  /**
   * 收到不带数据的推送到达信号，防抖后增量拉取一次
   */
  onPushSignal(): void;
  /**
   * App 回到前台，节流后增量拉取一次
   */
  onAppForeground(): void;
  searchIfChanged(key: string | null): void;
  refresh(scene: number): void;
  loadMore(): void;
  fetchMessageResume(): void;
  fetchCheckReason(): void;
  fetchListBanner(): void;
  closeListBanner(bannerId: number | null): void;
  markMessageReadStatus(id: number | null, read: boolean): void;
  deleteById(id: number): void;
  executeDeleteById(id: number): void;
  /**
   * 批量标记消息已读状态
   * @param ids 要操作的消息 id 集合，调用方需保证长度 <= 200
   * @param read 是否标记为已读状态
   */
  markMessageReadStatusBatch(ids: number[], read: boolean): void;
  /**
   * 批量删除消息（不弹确认框，确认逻辑由页面组件用 UIContext 弹窗承载）
   * @param ids 要删除的消息 id 集合，调用方需保证长度 <= 200
   */
  executeDeleteByIds(ids: number[]): void;
  /**
   * 删除当前用户的全部消息（不弹确认框，确认逻辑由页面组件承载）
   */
  executeDeleteAll(): void;
}
