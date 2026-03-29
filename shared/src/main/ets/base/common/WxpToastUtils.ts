/**
 * 对应 KMP WxpToastUtils.kt
 */
export interface IWxpToastBackend {
  showToast(msg: string): void;
}

export class WxpToastUtils {
  private static backend: IWxpToastBackend | null = null;

  static setBackend(impl: IWxpToastBackend): void {
    WxpToastUtils.backend = impl;
  }

  static showToast(msg: string | null | undefined): void {
    if (!msg || msg.length === 0) {
      return;
    }
    WxpToastUtils.backend?.showToast(msg);
  }
}
