/**
 * 对应 KMP WxpPlatformEnum.kt
 * 平台枚举，新增 HarmonyOS
 */
export class WxpPlatformEnum {
  static readonly iOS = 'iOS';
  static readonly Android = 'Android';
  static readonly Android_XIAOMI = 'Android_Xiaomi';
  static readonly Android_HUAWEI = 'Android_Huawei';
  static readonly Android_VIVO = 'Android_Vivo';
  static readonly Android_HONOR = 'Android_Honor';
  static readonly Android_OPPO = 'Android_Oppo';
  static readonly HarmonyOS = 'HarmonyOS';
  static readonly Mac = 'Mac';
  static readonly Windows = 'Windows';
  static readonly Linux = 'Linux';
  static readonly Web = 'Web';
  static readonly Chrome_Windows = 'Chrome-Windows';
  static readonly Chrome_Mac = 'Chrome-Mac';
  static readonly Chrome_Android = 'Chrome-Android';
  static readonly Chrome_Other = 'Chrome-Other';
  static readonly Safari_MacOS = 'Safari-MacOS';
  static readonly Safari_iOS = 'Safari-iOS';
  static readonly Wecom = 'Wecom';

  private static readonly ALL_PLATFORMS: string[] = [
    WxpPlatformEnum.iOS,
    WxpPlatformEnum.Android,
    WxpPlatformEnum.Android_XIAOMI,
    WxpPlatformEnum.Android_HUAWEI,
    WxpPlatformEnum.Android_VIVO,
    WxpPlatformEnum.Android_HONOR,
    WxpPlatformEnum.Android_OPPO,
    WxpPlatformEnum.HarmonyOS,
    WxpPlatformEnum.Mac,
    WxpPlatformEnum.Windows,
    WxpPlatformEnum.Linux,
    WxpPlatformEnum.Web,
    WxpPlatformEnum.Chrome_Windows,
    WxpPlatformEnum.Chrome_Mac,
    WxpPlatformEnum.Chrome_Android,
    WxpPlatformEnum.Chrome_Other,
    WxpPlatformEnum.Safari_MacOS,
    WxpPlatformEnum.Safari_iOS,
    WxpPlatformEnum.Wecom,
  ];

  /**
   * 验证平台是否合法
   */
  static verify(name: string | null | undefined): boolean {
    if (!name || name.length === 0) {
      return false;
    }
    if (WxpPlatformEnum.ALL_PLATFORMS.includes(name)) {
      return true;
    }
    if (name.startsWith('Chrome-') || name.startsWith('Safari-')) {
      return true;
    }
    return false;
  }

  /**
   * 是否是 Chrome 设备
   */
  static isChrome(platform: string | null | undefined): boolean {
    return platform !== null && platform !== undefined && platform.startsWith('Chrome-');
  }
}
