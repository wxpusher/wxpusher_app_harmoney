/**
 * 对应 KMP WxpBaseInfoService.kt
 */
export interface IWxpBaseInfoServiceBackend {
  getAppVersionName(): string;
  getDeviceName(): string;
  getPlatform(): string;
}

export class WxpBaseInfoService {
  private static backend: IWxpBaseInfoServiceBackend | null = null;

  static init(listener: IWxpBaseInfoServiceBackend): void {
    WxpBaseInfoService.backend = listener;
  }

  static getAppVersionName(): string {
    return WxpBaseInfoService.backend?.getAppVersionName() ?? '';
  }

  static getDeviceName(): string {
    return WxpBaseInfoService.backend?.getDeviceName() ?? '';
  }

  static getPlatform(): string {
    return WxpBaseInfoService.backend?.getPlatform() ?? 'HarmonyOS';
  }
}
