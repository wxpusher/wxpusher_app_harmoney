import { WxpApiService } from '../../api/WxpApiService';
import { WxpAppDataService } from '../../base/biz/WxpAppDataService';
import { WxpBaseMvpPresenter } from '../../base/common/WxpBaseMvp';
import { WxpLoadingUtils } from '../../base/common/WxpLoadingUtils';
import { WxpLogUtils } from '../../base/common/WxpLogUtils';
import { WxpScopeUtils } from '../../base/common/WxpScopeUtils';
import { WxpToastUtils } from '../../base/common/WxpToastUtils';
import { WxpPhoneBindReq } from './WxpChangePhoneBean';
import { IWxpChangePhonePresenter, IWxpChangePhoneView } from './WxpChangePhonePageContract';

export class WxpChangePhonePresenter extends WxpBaseMvpPresenter<IWxpChangePhoneView, IWxpChangePhonePresenter>
  implements IWxpChangePhonePresenter {
  private canSendVerifyCode = true;

  constructor(view: IWxpChangePhoneView) {
    super(view);
  }

  private sendTimeWait(): void {
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.canSendVerifyCode = false;
      for (let i = 120; i >= 0; i--) {
        if (i <= 0) {
          this.canSendVerifyCode = true;
          this.view?.onSendButtonText('发送验证码');
          break;
        }
        this.view?.onSendButtonText(`${i}S`);
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
    if (phone === WxpAppDataService.getLoginInfo()?.phone) {
      WxpToastUtils.showToast('已经绑定到当前手机号码');
      return;
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      this.view?.onSendButtonText('发送中');
      if (await WxpApiService.sendVerifyCode(phone) === true) {
        WxpToastUtils.showToast('发送成功');
        this.sendTimeWait();
      } else {
        this.view?.onSendButtonText('发送验证码');
      }
    });
  }

  bindPhone(phone: string | null, verifyCode: string | null): void {
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
    WxpLogUtils.i('WxPusher', `换绑手机号，phone=${phone}`);
    const req: WxpPhoneBindReq = { phone, code: verifyCode };
    WxpLoadingUtils.showLoading('处理中...');
    WxpScopeUtils.runAtMainSuspend(async () => {
      const result = await WxpApiService.phoneBind(req);
      WxpLoadingUtils.dismissLoading();
      if (result === true) {
        WxpToastUtils.showToast('绑定手机号成功');
        const loginInfo = WxpAppDataService.getLoginInfo();
        if (loginInfo) {
          loginInfo.phone = phone;
          WxpAppDataService.saveLoginInfo(loginInfo);
          this.view?.onChangPhoneFinish();
        }
      }
    });
  }
}
