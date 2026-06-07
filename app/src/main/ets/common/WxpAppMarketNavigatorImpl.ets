import { common, Want } from '@kit.AbilityKit';
import { WxpAppMarketNavigator, WxpToastUtils } from '@wxpusher/shared';

/**
 * HarmonyOS 版应用市场跳转实现。
 * 拉起华为应用市场（AppGallery）当前 App 详情页；鸿蒙无 TBS。
 */
export class WxpAppMarketNavigatorImpl implements WxpAppMarketNavigator {
  private static readonly PACKAGE_NAME = 'com.smjcco.wxpusher.hm';

  jumpToMarket(downloadUrl: string): void {
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
      if (!ctx) {
        WxpAppMarketNavigatorImpl.openDownloadUrlFallback(downloadUrl);
        return;
      }
      const want: Want = {
        uri: `store://appgallery.huawei.com/app/detail?id=${WxpAppMarketNavigatorImpl.PACKAGE_NAME}`,
      };
      ctx.startAbility(want)
        .then(() => {
          // 拉起成功
        })
        .catch(() => {
          WxpAppMarketNavigatorImpl.openDownloadUrlFallback(downloadUrl);
        });
    } catch {
      WxpAppMarketNavigatorImpl.openDownloadUrlFallback(downloadUrl);
    }
  }

  /**
   * 应用市场拉起失败时，尝试用浏览器打开后端下发的下载地址。
   */
  private static openDownloadUrlFallback(downloadUrl: string): void {
    if (!downloadUrl || downloadUrl.length === 0) {
      WxpToastUtils.showToast('无法打开应用市场');
      return;
    }
    try {
      const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
      if (!ctx) {
        WxpToastUtils.showToast('无法打开应用市场');
        return;
      }
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: downloadUrl,
      };
      ctx.startAbility(want).catch(() => {
        WxpToastUtils.showToast('无法打开应用市场');
      });
    } catch {
      WxpToastUtils.showToast('无法打开应用市场');
    }
  }
}
