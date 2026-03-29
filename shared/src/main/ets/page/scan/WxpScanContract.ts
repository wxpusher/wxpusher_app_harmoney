import { IWxpBaseMvpPresenter, IWxpBaseMvpView } from '../../base/common/WxpBaseMvp';

export interface IWxpScanView extends IWxpBaseMvpView<IWxpScanPresenter> {
  onClosePage(): void;
  onOpenWebPage(url: string): void;
  onCopy(data: string): void;
}

export interface IWxpScanPresenter extends IWxpBaseMvpPresenter<IWxpScanView, IWxpScanPresenter> {
  scan(data: string | null): void;
}
