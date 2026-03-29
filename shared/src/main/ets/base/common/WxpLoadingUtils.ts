/**
 * 对应 KMP WxpLoadingUtils.kt
 */
export interface IWxpLoading {
  showLoading(msg?: string, canDismiss?: boolean): void;
  dismissLoading(): void;
}

export class WxpLoadingUtils {
  private static loading: IWxpLoading | null = null;

  static setLoadingImpl(loadingImpl: IWxpLoading): void {
    WxpLoadingUtils.loading = loadingImpl;
  }

  static showLoading(msg?: string, canDismiss: boolean = true): void {
    WxpLoadingUtils.loading?.showLoading(msg, canDismiss);
  }

  static dismissLoading(): void {
    WxpLoadingUtils.loading?.dismissLoading();
  }
}
