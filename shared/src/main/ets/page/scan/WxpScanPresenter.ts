import { WxpConfig } from '../../config/WxpConfig';
import { WxpApiService } from '../../api/WxpApiService';
import { WxpAppDataService } from '../../base/biz/WxpAppDataService';
import { WxpBaseMvpPresenter } from '../../base/common/WxpBaseMvp';
import { WxpDialogUtils, WxpDialogParams } from '../../base/common/WxpDialogUtils';
import { WxpScopeUtils } from '../../base/common/WxpScopeUtils';
import { WxpToastUtils } from '../../base/common/WxpToastUtils';
import { ScanQrcodeType, WxpFollowResult } from './WxpScanBean';
import { IWxpScanPresenter, IWxpScanView } from './WxpScanContract';

export class WxpScanPresenter extends WxpBaseMvpPresenter<IWxpScanView, IWxpScanPresenter>
  implements IWxpScanPresenter {
  constructor(view: IWxpScanView) {
    super(view);
  }

  private dealFollowResult(followResult: WxpFollowResult): void {
    const params: WxpDialogParams = {
      title: '订阅成功',
      message: followResult.msg ?? '',
      leftText: '关闭',
      leftBlock: () => { this.view?.onClosePage(); },
      rightText: '查看详情',
      rightBlock: () => {
        this.view?.onClosePage();
        WxpScopeUtils.runAtMainSuspend(async () => {
          let openId = WxpAppDataService.getLoginInfo()?.openId;
          if (!openId || openId.length === 0) {
            openId = await WxpApiService.getOpenId() ?? undefined;
            if (openId && openId.length > 0) {
              WxpAppDataService.saveOpenId(openId);
            }
          }
          if (!openId || openId.length === 0) {
            WxpToastUtils.showToast('获取openId失败，请重试');
            return;
          }
          this.view?.onOpenWebPage(`${WxpConfig.baseUrl}/app/?openId=${openId}&subId=${followResult.subId}#/subscribe-detail`);
        });
      },
    };
    WxpDialogUtils.showDialog(params);
  }

  scan(data: string | null): void {
    if (!data || data.length === 0) {
      WxpToastUtils.showToast('扫描数据为空');
      return;
    }
    WxpScopeUtils.runAtMainSuspend(async () => {
      const scanResult = await WxpApiService.getScanResult(data);
      if (!scanResult) {
        this.view?.onClosePage();
        return;
      }
      if (scanResult.type === ScanQrcodeType.TypeSubscribe) {
        if (scanResult.followResult) {
          this.dealFollowResult(scanResult.followResult);
        } else {
          WxpToastUtils.showToast('数据异常，请重试');
          this.view?.onClosePage();
        }
      } else if (scanResult.type === ScanQrcodeType.TypeOpenUrlWithConfirm) {
        if (!scanResult.data || scanResult.data.length === 0) {
          this.view?.onClosePage();
          WxpToastUtils.showToast('返回数据错误，无法打开');
        } else {
          const url = scanResult.data;
          const params: WxpDialogParams = {
            title: '扫描成功',
            message: url,
            leftText: '关闭',
            leftBlock: () => { this.view?.onClosePage(); },
            rightText: '打开',
            rightBlock: () => {
              this.view?.onClosePage();
              this.view?.onOpenWebPage(url);
            },
          };
          WxpDialogUtils.showDialog(params);
        }
      } else if (scanResult.type === ScanQrcodeType.TypeOpenUrl) {
        if (!scanResult.data || scanResult.data.length === 0) {
          this.view?.onClosePage();
          WxpToastUtils.showToast('返回数据错误，无法打开');
        } else {
          this.view?.onClosePage();
          this.view?.onOpenWebPage(scanResult.data);
        }
      } else {
        const params: WxpDialogParams = {
          title: '扫描成功',
          message: scanResult.data ?? '',
          leftText: '关闭',
          leftBlock: () => { this.view?.onClosePage(); },
          rightText: '复制',
          rightBlock: () => {
            this.view?.onCopy(scanResult.data ?? '');
            this.view?.onClosePage();
          },
        };
        WxpDialogUtils.showDialog(params);
      }
    });
  }
}
