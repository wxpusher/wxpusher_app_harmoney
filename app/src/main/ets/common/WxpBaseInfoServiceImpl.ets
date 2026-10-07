import { bundleManager } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { IWxpBaseInfoServiceBackend } from '@wxpusher/shared';
import { WxpPlatformEnum } from '@wxpusher/shared';

/**
 * HarmonyOS 平台 BaseInfoService 实现
 */
export class WxpBaseInfoServiceImpl implements IWxpBaseInfoServiceBackend {
  private versionName: string = '';

  constructor() {
    try {
      const info = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      this.versionName = info.versionName;
    } catch {
      this.versionName = '1.0.0';
    }
  }

  getAppVersionName(): string {
    return this.versionName;
  }

  getDeviceName(): string {
    return deviceInfo.productModel || 'HarmonyOS Device';
  }

  /** HarmonyOS 客户端运行平台，不包含具体推送通道信息。 */
  getClientPlatform(): string {
    return WxpPlatformEnum.HarmonyOS;
  }

  /** HarmonyOS 当前只使用 Push Kit，因此后端推送路由平台固定为 HarmonyOS。 */
  getEffectivePushPlatform(): string {
    return WxpPlatformEnum.HarmonyOS;
  }
}
