import { IWxpBaseMvpPresenter, IWxpBaseMvpView } from '../../base/common/WxpBaseMvp';
import { WxpBindPageData } from '../login/WxpLoginBindOrCreateAccountBean';

export interface IWxpRegisterOrBindView extends IWxpBaseMvpView<IWxpRegisterOrBindPresenter> {
  onGoMain(): void;
}

export interface IWxpRegisterOrBindPresenter extends IWxpBaseMvpPresenter<IWxpRegisterOrBindView, IWxpRegisterOrBindPresenter> {
  weixinBind(code: string | null, bindData: WxpBindPageData | null): void;
  createAccount(data: WxpBindPageData | null): void;
}
