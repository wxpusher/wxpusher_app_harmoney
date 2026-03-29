/**
 * 对应 KMP WxpBaseMvp.kt
 * MVP 基础接口和抽象类
 */
export interface IWxpBaseMvpView<P> {
  createPresenter(): P;
}

export interface IWxpBaseMvpPresenter<V extends IWxpBaseMvpView<P>, P> {
  onShow(): void;
  onDestroy(): void;
}

export abstract class WxpBaseMvpPresenter<V extends IWxpBaseMvpView<P>, P>
  implements IWxpBaseMvpPresenter<V, P> {
  protected view: V | null;

  constructor(view: V | null) {
    this.view = view;
  }

  onShow(): void {
  }

  onDestroy(): void {
    this.view = null;
  }
}
