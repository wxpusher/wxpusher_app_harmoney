/**
 * 对应 KMP WxpBaseInfoService.kt
 */
export interface IWxpBaseInfoServiceBackend {
  getAppVersionName(): string;
  getDeviceName(): string;
  /** 获取客户端操作系统平台，不包含具体推送通道信息。 */
  getClientPlatform(): string;
  /** 获取当前用于后端消息分发的推送路由平台。 */
  getEffectivePushPlatform(): string;
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

  /** 获取客户端操作系统平台，不包含具体推送通道信息。 */
  static getClientPlatform(): string {
    return WxpBaseInfoService.backend?.getClientPlatform() ?? 'HarmonyOS';
  }

  /** 获取当前用于后端消息分发的推送路由平台。 */
  static getEffectivePushPlatform(): string {
    return WxpBaseInfoService.backend?.getEffectivePushPlatform() ?? 'HarmonyOS';
  }
}
