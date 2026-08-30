import { WxpApiService } from '../../api/WxpApiService';
import { WxpAppDataService } from '../../base/biz/WxpAppDataService';
import { createWxpLoginInfoFromResp } from '../../base/biz/bean/WxpLoginInfo';
import { WxpBaseInfoService } from '../../base/common/WxpBaseInfoService';
import { WxpBaseMvpPresenter } from '../../base/common/WxpBaseMvp';
import { WxpLoadingUtils } from '../../base/common/WxpLoadingUtils';
import { WxpLogUtils } from '../../base/common/WxpLogUtils';
import { WxpScopeUtils } from '../../base/common/WxpScopeUtils';
import { WxpToastUtils } from '../../base/common/WxpToastUtils';
import { WxpLoginSendVerifyCodeReq, WxpWeixinLoginReq, WxpAppleLoginReq, WxpHuaweiLoginReq } from './WxpLoginBean';
import { WxpBindPageData, WxpPhoneBind, WxpAppleBind, WxpHuaweiBind } from './WxpLoginBindOrCreateAccountBean';
import { IWxpLoginPresenter, IWxpLoginView } from './WxpLoginPageContract';

export class WxpLoginPresenter extends WxpBaseMvpPresenter<IWxpLoginView, IWxpLoginPresenter>
  implements IWxpLoginPresenter {
  private canSendVerifyCode = true;

  constructor(view: IWxpLoginView) {
    super(view);
  }

  init(): void {
    this.view?.onSendButtonText('发送验证码', false);
  }

  private sendTimeWait(): void {
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.canSendVerifyCode = false;
      for (let i = 120; i >= 0; i--) {
        if (i <= 0) {
          this.canSendVerifyCode = true;
          this.view?.onSendButtonText('发送验证码', false);
          break;
        }
        this.view?.onSendButtonText(`${i}S`, false);
        await WxpScopeUtils.delay(1000);
      }
    });
  }

  sendVerifyCode(phone: string | null): void {
    if (!this.canSendVerifyCode) return;
    if (!phone || phone.length === 0) {
      WxpToastUtils.showToast('请输入手机号');
      return;
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.view?.onSendButtonText('发送中', true);
      if (await WxpApiService.sendVerifyCode(phone) === true) {
        WxpToastUtils.showToast('发送成功');
        this.sendTimeWait();
      } else {
        this.view?.onSendButtonText('发送验证码', false);
      }
    });
  }

  verifyCodeLogin(phone: string | null, verifyCode: string | null): void {
    if (!phone || phone.length === 0) {
      WxpToastUtils.showToast('请输入手机号');
      return;
    }
    if (!verifyCode || verifyCode.length === 0) {
      WxpToastUtils.showToast('请输入验证码');
      return;
    }
    if (verifyCode.length !== 6) {
      WxpToastUtils.showToast('验证码错误');
      return;
    }
    WxpLogUtils.i('WxPusher', `手机登录，phone=${phone}`);
    const req: WxpLoginSendVerifyCodeReq = {
      justCreateAccount: false,
      phone: phone,
      code: verifyCode,
      deviceId: WxpAppDataService.getLoginInfo()?.deviceId,
      deviceName: WxpBaseInfoService.getDeviceName(),
      pushToken: WxpAppDataService.getPushToken() ?? undefined,
    };

    WxpLoadingUtils.showLoading('登录中...');
    WxpScopeUtils.runAtMainSuspend(async () => {
      const loginData = await WxpApiService.verifyCodeLogin(req);
      WxpLoadingUtils.dismissLoading();
      if (loginData) {
        if (loginData.phoneHasRegister === true) {
          WxpAppDataService.saveLoginInfo(createWxpLoginInfoFromResp(loginData));
          this.view?.onGoMain();
        } else {
          WxpLogUtils.i('WxPusher', '手机登录，用户未注册');
          const data: WxpBindPageData = {
            phoneLogin: {
              phone: phone,
              code: verifyCode,
              phoneVerifyCode: loginData.phoneVerifyCode,
            } as WxpPhoneBind,
          };
          this.view?.onGoBindOrCreateAccount(data);
        }
      }
    });
  }

  weixinLogin(code: string | null): void {
    WxpLogUtils.i('WxPusher', `微信登录，code=${code}`);
    if (!code || code.length === 0) {
      WxpToastUtils.showToast('微信授权码错误');
      return;
    }
    const req: WxpWeixinLoginReq = {
      code: code,
      deviceId: WxpAppDataService.getLoginInfo()?.deviceId,
      deviceName: WxpBaseInfoService.getDeviceName(),
      pushToken: WxpAppDataService.getPushToken() ?? undefined,
    };

    WxpScopeUtils.runAtMainSuspend(async () => {
      WxpLoadingUtils.showLoading('验证中...');
      const loginData = await WxpApiService.weixinLogin(req);
      WxpLoadingUtils.dismissLoading();
      if (loginData) {
        WxpAppDataService.saveLoginInfo(createWxpLoginInfoFromResp(loginData));
        this.view?.onGoMain();
      }
    });
  }

  appleLogin(code: string | null, userId: string | null, email: string | null, name: string | null): void {
    WxpLogUtils.i('WxPusher', `苹果登录，code=${code}`);
    if (!code || code.length === 0) {
      WxpToastUtils.showToast('苹果登录信息为空');
      return;
    }
    const req: WxpAppleLoginReq = {
      justCreateAccount: false,
      code: code,
      name: name ?? undefined,
      deviceId: WxpAppDataService.getLoginInfo()?.deviceId,
      deviceName: WxpBaseInfoService.getDeviceName(),
      pushToken: WxpAppDataService.getPushToken() ?? undefined,
    };

    WxpScopeUtils.runAtMainSuspend(async () => {
      WxpLoadingUtils.showLoading('验证中...');
      const loginData = await WxpApiService.appleLogin(req);
      WxpLoadingUtils.dismissLoading();
      if (loginData) {
        if (loginData.hasRegister === true) {
          WxpLogUtils.i('WxPusher', '苹果登录，用户已经注册');
          WxpAppDataService.saveLoginInfo(createWxpLoginInfoFromResp(loginData));
          this.view?.onGoMain();
        } else {
          WxpLogUtils.i('WxPusher', '苹果登录，用户未注册');
          const data: WxpBindPageData = {
            appleLogin: { code, name } as WxpAppleBind,
          };
          this.view?.onGoBindOrCreateAccount(data);
        }
      }
    });
  }

  huaweiLogin(idToken: string | null): void {
    WxpLogUtils.i('WxPusher', `华为登录，idToken=${idToken}`);
    if (!idToken || idToken.length === 0) {
      WxpToastUtils.showToast('华为登录信息为空');
      return;
    }
    const req: WxpHuaweiLoginReq = {
      justCreateAccount: false,
      code: idToken,
      deviceId: WxpAppDataService.getLoginInfo()?.deviceId,
      deviceName: WxpBaseInfoService.getDeviceName(),
      pushToken: WxpAppDataService.getPushToken() ?? undefined,
    };

    WxpScopeUtils.runAtMainSuspend(async () => {
      WxpLoadingUtils.showLoading('验证中...');
      const loginData = await WxpApiService.huaweiLogin(req);
      WxpLoadingUtils.dismissLoading();
      if (loginData) {
        if (loginData.hasRegister === true) {
          WxpLogUtils.i('WxPusher', '华为登录，用户已经注册');
          WxpAppDataService.saveLoginInfo(createWxpLoginInfoFromResp(loginData));
          this.view?.onGoMain();
        } else {
          WxpLogUtils.i('WxPusher', '华为登录，用户未注册');
          const data: WxpBindPageData = {
            huaweiLogin: { code: idToken } as WxpHuaweiBind,
          };
          this.view?.onGoBindOrCreateAccount(data);
        }
      }
    });
  }
}
