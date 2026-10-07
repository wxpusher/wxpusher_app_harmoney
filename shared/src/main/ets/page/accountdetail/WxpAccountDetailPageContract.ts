import { IWxpBaseMvpPresenter, IWxpBaseMvpView } from '../../base/common/WxpBaseMvp';

export interface IWxpAccountDetailView extends IWxpBaseMvpView<IWxpAccountDetailPresenter> {
  onWeixinBindSuccess(): void;
  onAppleBindSuccess(): void;
  onHuaweiBindSuccess(): void;
}

export interface IWxpAccountDetailPresenter extends IWxpBaseMvpPresenter<IWxpAccountDetailView, IWxpAccountDetailPresenter> {
  weixinBind(code: string | null): void;
  appleBind(code: string | null, userId: string | null, email: string | null, name: string | null): void;
  huaweiBind(idToken: string | null): void;
  logout(): void;
}
