import { WxpApiService } from '../../api/WxpApiService';
import { WxpAppDataService } from '../../base/biz/WxpAppDataService';
import { createWxpLoginInfoFromResp } from '../../base/biz/bean/WxpLoginInfo';
import { WxpBaseInfoService } from '../../base/common/WxpBaseInfoService';
import { WxpBaseMvpPresenter } from '../../base/common/WxpBaseMvp';
import { WxpLoadingUtils } from '../../base/common/WxpLoadingUtils';
import { WxpLogUtils } from '../../base/common/WxpLogUtils';
import { WxpScopeUtils } from '../../base/common/WxpScopeUtils';
import { WxpToastUtils } from '../../base/common/WxpToastUtils';
import {
  WxpAppleLoginReq,
  WxpHuaweiLoginReq,
  WxpLoginSendVerifyCodeReq,
  WxpWeixinLoginReq,
} from '../login/WxpLoginBean';
import { WxpBindPageData } from '../login/WxpLoginBindOrCreateAccountBean';
import { IWxpRegisterOrBindPresenter, IWxpRegisterOrBindView } from './WxpRegisterOrBindPageContract';

export class WxpRegisterOrBindPresenter extends WxpBaseMvpPresenter<IWxpRegisterOrBindView, IWxpRegisterOrBindPresenter>
  implements IWxpRegisterOrBindPresenter {
  constructor(view: IWxpRegisterOrBindView) {
    super(view);
  }

  weixinBind(code: string | null, bindData: WxpBindPageData | null): void {
    if (!bindData) return;
    if (!code || code.length === 0) {
      WxpToastUtils.showToast('微信授权码错误');
      return;
    }
    const req: WxpWeixinLoginReq = {
      code: code,
      bindCode: bindData.phoneLogin?.phoneVerifyCode,
      appleLoginJwtCode: bindData.appleLogin?.code,
      appleName: bindData.appleLogin?.name,
      huaweiLoginIdToken: bindData.huaweiLogin?.code,
      deviceId: WxpAppDataService.getLoginInfo()?.deviceId,
      deviceName: WxpBaseInfoService.getDeviceName(),
      pushToken: WxpAppDataService.getPushToken() ?? undefined,
    };

    WxpScopeUtils.runAtMainSuspend(async () => {
      WxpLoadingUtils.showLoading('绑定中...');
      const loginData = await WxpApiService.weixinLogin(req);
      WxpLoadingUtils.dismissLoading();
      if (loginData) {
        WxpAppDataService.saveLoginInfo(createWxpLoginInfoFromResp(loginData));
        WxpAppDataService.updateDeviceInfo();
        this.view?.onGoMain();
      }
    });
  }

  createAccount(bindData: WxpBindPageData | null): void {
    if (!bindData) return;

    const phoneLogin = bindData.phoneLogin;
    if (phoneLogin) {
      const req: WxpLoginSendVerifyCodeReq = {
        justCreateAccount: true,
        phone: phoneLogin.phone,
        code: phoneLogin.code,
        deviceId: WxpAppDataService.getLoginInfo()?.deviceId,
        deviceName: WxpBaseInfoService.getDeviceName(),
        pushToken: WxpAppDataService.getPushToken() ?? undefined,
      };
      WxpScopeUtils.runAtMainSuspend(async () => {
        WxpLoadingUtils.showLoading('处理中...');
        const loginData = await WxpApiService.verifyCodeLogin(req);
        WxpLoadingUtils.dismissLoading();
        if (loginData) {
          WxpAppDataService.saveLoginInfo(createWxpLoginInfoFromResp(loginData));
          WxpAppDataService.updateDeviceInfo();
          this.view?.onGoMain();
        }
      });
      return;
    }

    const appleLogin = bindData.appleLogin;
    if (appleLogin) {
      if (!appleLogin.code || appleLogin.code.length === 0) {
        WxpToastUtils.showToast('苹果登录信息为空');
        return;
      }
      const req: WxpAppleLoginReq = {
        justCreateAccount: true,
        code: appleLogin.code,
        name: appleLogin.name,
        deviceId: WxpAppDataService.getLoginInfo()?.deviceId,
        deviceName: WxpBaseInfoService.getDeviceName(),
        pushToken: WxpAppDataService.getPushToken() ?? undefined,
      };
      WxpScopeUtils.runAtMainSuspend(async () => {
        WxpLoadingUtils.showLoading('处理中...');
        const loginData = await WxpApiService.appleLogin(req);
        WxpLoadingUtils.dismissLoading();
        if (loginData) {
          WxpLogUtils.i('WxPusher', '登录直接注册苹果账号成功');
          WxpAppDataService.saveLoginInfo(createWxpLoginInfoFromResp(loginData));
          WxpAppDataService.updateDeviceInfo();
          this.view?.onGoMain();
        }
      });
      return;
    }

    const huaweiLogin = bindData.huaweiLogin;
    if (huaweiLogin) {
      if (!huaweiLogin.code || huaweiLogin.code.length === 0) {
        WxpToastUtils.showToast('华为登录信息为空');
        return;
      }
      const req: WxpHuaweiLoginReq = {
        justCreateAccount: true,
        code: huaweiLogin.code,
        deviceId: WxpAppDataService.getLoginInfo()?.deviceId,
        deviceName: WxpBaseInfoService.getDeviceName(),
        pushToken: WxpAppDataService.getPushToken() ?? undefined,
      };
      WxpScopeUtils.runAtMainSuspend(async () => {
        WxpLoadingUtils.showLoading('处理中...');
        const loginData = await WxpApiService.huaweiLogin(req);
        WxpLoadingUtils.dismissLoading();
        if (loginData) {
          WxpLogUtils.i('WxPusher', '登录直接注册华为账号成功');
          WxpAppDataService.saveLoginInfo(createWxpLoginInfoFromResp(loginData));
          WxpAppDataService.updateDeviceInfo();
          this.view?.onGoMain();
        }
      });
    }
  }
}
