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
  /**
   * 是否可取消（点击蒙层 / 返回键关闭）。默认 true。
   * 强制更新等场景设为 false，此时底层需使用支持禁用蒙层关闭的弹窗实现。
   */
  cancelable?: boolean;
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
