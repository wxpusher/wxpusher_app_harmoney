import { IWxpBaseMvpPresenter, IWxpBaseMvpView } from '../../base/common/WxpBaseMvp';

export interface IWxpBindView extends IWxpBaseMvpView<IWxpBindPresenter> {
  onGoMain(): void;
  showLoading(show: boolean): void;
}

export interface IWxpBindPresenter extends IWxpBaseMvpPresenter<IWxpBindView, IWxpBindPresenter> {
  queryBindStatus(phone: string | null, verifyCode: string | null): void;
}
