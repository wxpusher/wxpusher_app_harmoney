/**
 * 对应 KMP WxpAppPageService.kt
 */
export interface IWxpAppPageService {
  jumpToLogin(): void;
}

export class WxpAppPageService {
  private static pageService: IWxpAppPageService | null = null;

  static init(service: IWxpAppPageService): void {
    WxpAppPageService.pageService = service;
  }

  static jumpToLogin(): void {
    WxpAppPageService.pageService?.jumpToLogin();
  }
}
