import { IWxpBaseMvpPresenter, IWxpBaseMvpView } from '../../base/common/WxpBaseMvp';
import { WxpBindPageData } from './WxpLoginBindOrCreateAccountBean';

export interface IWxpLoginView extends IWxpBaseMvpView<IWxpLoginPresenter> {
  onSendButtonText(msg: string, loading: boolean): void;
  onGoBindOrCreateAccount(data: WxpBindPageData): void;
  onGoMain(): void;
}

export interface IWxpLoginPresenter extends IWxpBaseMvpPresenter<IWxpLoginView, IWxpLoginPresenter> {
  init(): void;
  sendVerifyCode(phone: string | null): void;
  verifyCodeLogin(phone: string | null, verifyCode: string | null): void;
  weixinLogin(code: string | null): void;
  appleLogin(code: string | null, userId: string | null, email: string | null, name: string | null): void;
  huaweiLogin(idToken: string | null): void;
}
