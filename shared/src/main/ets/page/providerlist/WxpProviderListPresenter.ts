import { WxpConfig } from '../../config/WxpConfig';
import { WxpApiService } from '../../api/WxpApiService';
import { WxpAppDataService } from '../../base/biz/WxpAppDataService';
import { WxpBaseMvpPresenter } from '../../base/common/WxpBaseMvp';
import { WxpScopeUtils } from '../../base/common/WxpScopeUtils';
import { WxpToastUtils } from '../../base/common/WxpToastUtils';
import { IWxpProviderListPresenter, IWxpProviderListView } from './WxpProviderListContract';

export class WxpProviderListPresenter extends WxpBaseMvpPresenter<IWxpProviderListView, IWxpProviderListPresenter>
  implements IWxpProviderListPresenter {
  constructor(view: IWxpProviderListView) {
    super(view);
  }

  loadPage(): void {
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
      this.view?.onLoadPage(`${WxpConfig.appFeUrl}/app#/market`);
    });
  }
}
