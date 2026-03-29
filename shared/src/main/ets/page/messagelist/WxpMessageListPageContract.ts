import { IWxpBaseMvpPresenter, IWxpBaseMvpView } from '../../base/common/WxpBaseMvp';
import { WxpCheckAppMsgReasonResp, WxpListBannerResp, WxpMessageListMessage } from './WxpMessageListBean';

export interface IWxpMessageListView extends IWxpBaseMvpView<IWxpMessageListPresenter> {
  showMessageRefreshing(refreshing: boolean): void;
  showMessageMoreLoading(loading: boolean, hasMore: boolean): void;
  onMessageList(data: WxpMessageListMessage[]): void;
  onFeedback(): void;
  onOpenSubscribeManagerPage(url: string): void;
  onCheckReason(data: WxpCheckAppMsgReasonResp | null): void;
  onListBanner(data: WxpListBannerResp | null): void;
}

export interface IWxpMessageListPresenter extends IWxpBaseMvpPresenter<IWxpMessageListView, IWxpMessageListPresenter> {
  init(): void;
  getTipsOfLastRefreshTime(): string;
  onReceiveNewMessage(message: WxpMessageListMessage): void;
  searchIfChanged(key: string | null): void;
  refresh(scene: number): void;
  loadMore(): void;
  fetchMessageResume(): void;
  fetchCheckReason(): void;
  fetchListBanner(): void;
  closeListBanner(bannerId: number | null): void;
  markMessageReadStatus(id: number | null, read: boolean): void;
  deleteById(id: number): void;
  openSubscribeManagerPage(): void;
}
