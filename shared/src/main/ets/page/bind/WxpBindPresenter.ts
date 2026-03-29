import { WxpApiService } from '../../api/WxpApiService';
import { WxpAppDataService } from '../../base/biz/WxpAppDataService';
import { createWxpLoginInfoFromResp } from '../../base/biz/bean/WxpLoginInfo';
import { WxpBaseInfoService } from '../../base/common/WxpBaseInfoService';
import { WxpBaseMvpPresenter } from '../../base/common/WxpBaseMvp';
import { WxpScopeUtils } from '../../base/common/WxpScopeUtils';
import { WxpToastUtils } from '../../base/common/WxpToastUtils';
import { WxpLoginSendVerifyCodeReq } from '../login/WxpLoginBean';
import { IWxpBindPresenter, IWxpBindView } from './WxpBindPageContract';

export class WxpBindPresenter extends WxpBaseMvpPresenter<IWxpBindView, IWxpBindPresenter>
  implements IWxpBindPresenter {
  constructor(view: IWxpBindView) {
    super(view);
  }

  queryBindStatus(phone: string | null, verifyCode: string | null): void {
    if (!phone || phone.length === 0) {
      WxpToastUtils.showToast('手机号为空，请重新登录');
      return;
    }
    if (!verifyCode || verifyCode.length === 0) {
      WxpToastUtils.showToast('验证码为空，请重新登录');
      return;
    }
    const req: WxpLoginSendVerifyCodeReq = {
      justCreateAccount: false,
      phone: phone,
      code: verifyCode,
      deviceId: WxpAppDataService.getLoginInfo()?.deviceId,
      deviceName: WxpBaseInfoService.getDeviceName(),
      pushToken: WxpAppDataService.getPushToken() ?? undefined,
    };
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.view?.showLoading(true);
      const loginData = await WxpApiService.verifyCodeLogin(req);
      this.view?.showLoading(false);
      if (loginData) {
        if (loginData.phoneHasRegister === true) {
          WxpAppDataService.saveLoginInfo(createWxpLoginInfoFromResp(loginData));
          WxpAppDataService.updateDeviceInfo();
          this.view?.onGoMain();
        } else {
          WxpToastUtils.showToast('绑定未完成，请先按步骤绑定');
        }
      }
    });
  }
}
