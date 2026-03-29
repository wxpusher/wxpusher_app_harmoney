import { IWxpBaseMvpPresenter, IWxpBaseMvpView } from '../../base/common/WxpBaseMvp';

export interface IWxpChangePhoneView extends IWxpBaseMvpView<IWxpChangePhonePresenter> {
  onSendButtonText(msg: string): void;
  onChangPhoneFinish(): void;
}

export interface IWxpChangePhonePresenter extends IWxpBaseMvpPresenter<IWxpChangePhoneView, IWxpChangePhonePresenter> {
  sendVerifyCode(phone: string | null): void;
  bindPhone(phone: string | null, verifyCode: string | null): void;
}
