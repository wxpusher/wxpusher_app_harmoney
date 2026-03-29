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

  getPlatform(): string {
    return WxpPlatformEnum.HarmonyOS;
  }
}
