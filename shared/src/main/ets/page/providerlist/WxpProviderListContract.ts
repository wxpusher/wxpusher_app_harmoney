import { IWxpBaseMvpPresenter, IWxpBaseMvpView } from '../../base/common/WxpBaseMvp';

export interface IWxpProviderListView extends IWxpBaseMvpView<IWxpProviderListPresenter> {
  onLoadPage(url: string): void;
}

export interface IWxpProviderListPresenter extends IWxpBaseMvpPresenter<IWxpProviderListView, IWxpProviderListPresenter> {
  loadPage(): void;
}
