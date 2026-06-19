import { WxpApiService } from '../../api/WxpApiService';
import { WxpAppDataService } from '../../base/biz/WxpAppDataService';
import { WxpAppPageService } from '../../base/biz/WxpAppPageService';
import { WxpBaseMvpPresenter } from '../../base/common/WxpBaseMvp';
import { WxpDialogUtils, WxpDialogParams } from '../../base/common/WxpDialogUtils';
import { WxpLoadingUtils } from '../../base/common/WxpLoadingUtils';
import { WxpLogUtils } from '../../base/common/WxpLogUtils';
import { WxpScopeUtils } from '../../base/common/WxpScopeUtils';
import { WxpToastUtils } from '../../base/common/WxpToastUtils';
import { WxpAppleBindReq, WxpHuaweiBindReq, WxpWeixinBindReq } from './WxpAccountBindBean';
import { IWxpAccountDetailPresenter, IWxpAccountDetailView } from './WxpAccountDetailPageContract';

export class WxpAccountDetailPresenter extends WxpBaseMvpPresenter<IWxpAccountDetailView, IWxpAccountDetailPresenter>
  implements IWxpAccountDetailPresenter {
  constructor(view: IWxpAccountDetailView) {
    super(view);
  }

  weixinBind(code: string | null): void {
    WxpLogUtils.i('WxPusher', `绑定微信账号，code=${code}`);
    if (!code || code.length === 0) {
      WxpToastUtils.showToast('微信授权码为空');
      return;
    }
    const req: WxpWeixinBindReq = { code };
    WxpScopeUtils.runAtMainSuspend(async () => {
      WxpLoadingUtils.showLoading('绑定中...');
      const success = await WxpApiService.weixinBind(req);
      WxpLoadingUtils.dismissLoading();
      if (success) {
        const loginInfo = WxpAppDataService.getLoginInfo();
        if (loginInfo) {
          loginInfo.weiXinBind = true;
          WxpAppDataService.saveLoginInfo(loginInfo);
          this.view?.onWeixinBindSuccess();
        }
      }
    });
  }

  appleBind(code: string | null, userId: string | null, email: string | null, name: string | null): void {
    WxpLogUtils.i('WxPusher', `绑定苹果账号，code=${code}`);
    if (!code || code.length === 0) {
      WxpToastUtils.showToast('苹果授权为空');
      return;
    }
    const req: WxpAppleBindReq = { jwtCode: code, name: name ?? undefined };
    WxpScopeUtils.runAtMainSuspend(async () => {
      WxpLoadingUtils.showLoading('绑定中...');
      const success = await WxpApiService.appleBind(req);
      WxpLoadingUtils.dismissLoading();
      if (success) {
        const loginInfo = WxpAppDataService.getLoginInfo();
        if (loginInfo) {
          loginInfo.appleBind = true;
          WxpAppDataService.saveLoginInfo(loginInfo);
          this.view?.onAppleBindSuccess();
        }
      }
    });
  }

  huaweiBind(idToken: string | null, name: string | null): void {
    WxpLogUtils.i('WxPusher', `绑定华为账号，idToken=${idToken}`);
    if (!idToken || idToken.length === 0) {
      WxpToastUtils.showToast('华为授权为空');
      return;
    }
    const req: WxpHuaweiBindReq = { idToken: idToken, name: name ?? undefined };
    WxpScopeUtils.runAtMainSuspend(async () => {
      WxpLoadingUtils.showLoading('绑定中...');
      const success = await WxpApiService.huaweiBind(req);
      WxpLoadingUtils.dismissLoading();
      if (success) {
        const loginInfo = WxpAppDataService.getLoginInfo();
        if (loginInfo) {
          loginInfo.huaweiBind = true;
          WxpAppDataService.saveLoginInfo(loginInfo);
          this.view?.onHuaweiBindSuccess();
        }
      }
    });
  }

  logout(): void {
    const params: WxpDialogParams = {
      title: '退出当前账号吗？',
      message: '退出后需要重新登录才可以接收消息',
      leftText: '取消',
      rightText: '退出账号',
      rightBlock: () => {
        WxpScopeUtils.runAtMainSuspend(async () => {
          WxpLoadingUtils.showLoading('退出中...');
          await WxpApiService.logout(
            () => {
              WxpLoadingUtils.dismissLoading();
              const loginInfo = WxpAppDataService.getLoginInfo();
              if (loginInfo) {
                loginInfo.deviceToken = undefined;
                WxpAppDataService.saveLoginInfo(loginInfo);
              }
              WxpAppPageService.jumpToLogin();
            },
            () => {
              WxpLoadingUtils.dismissLoading();
            },
          );
        });
      },
    };
    WxpDialogUtils.showDialog(params);
  }
}
