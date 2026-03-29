import { WxpSaveService } from '../base/common/WxpSaveService';

/**
 * 对应 KMP WxpConfig.kt
 */
export class WxpConfig {
  // 和服务器 BaseLoginResp 模型的版本号对齐
  static readonly UserLoginInfoVersion = 1;

  // 后端地址
  static baseUrl: string = 'https://wxpusher.zjiecode.com';

  // ws 的地址
  static wsUrl: string = 'wss://wxpusher.zjiecode.com';

  // app 内嵌的 H5 页面的地址
  static appFeUrl: string = 'https://wxpusher.zjiecode.com';

  static init(): void {
    WxpConfig.baseUrl = WxpSaveService.getString('baseUrl', WxpConfig.baseUrl);
    WxpConfig.wsUrl = WxpSaveService.getString('wsUrl', WxpConfig.wsUrl);
    WxpConfig.appFeUrl = WxpSaveService.getString('appFeUrl', WxpConfig.appFeUrl);
  }

  static saveBaseUrl(baseUrl: string): void {
    WxpSaveService.setString('baseUrl', baseUrl);
  }

  static saveWsUrl(wsUrl: string): void {
    WxpSaveService.setString('wsUrl', wsUrl);
  }

  static saveAppFeUrl(appFeUrl: string): void {
    WxpSaveService.setString('appFeUrl', appFeUrl);
  }
}
