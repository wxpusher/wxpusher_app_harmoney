/**
 * 对应 KMP WxpDialogUtils.kt
 */
export interface WxpDialogParams {
  title?: string;
  message?: string;
  leftText?: string;
  leftBlock?: () => void;
  rightText?: string;
  rightBlock?: () => void;
}

export interface IWxpDialogBackend {
  showDialog(params: WxpDialogParams): void;
}

export class WxpDialogUtils {
  private static backend: IWxpDialogBackend | null = null;

  static setBackend(impl: IWxpDialogBackend): void {
    WxpDialogUtils.backend = impl;
  }

  static showDialog(params: WxpDialogParams | null | undefined): void {
    if (!params) {
      return;
    }
    WxpDialogUtils.backend?.showDialog(params);
  }
}
