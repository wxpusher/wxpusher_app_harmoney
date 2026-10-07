import { webview } from '@kit.ArkWeb';

/**
 * 对应 Android BridgeRequest。
 */
export interface BridgeRequest {
  action: string;
  data: Record<string, Object>;
  callbackId: string | undefined;
}

/**
 * 对应 Android WxpBridgeEmitter 公开方法的抽象接口。
 * 定义在此处以避免 BridgeActionHandler 与 WxpBridgeEmitter 之间的循环引用。
 */
export interface BridgeEmitter {
  sendBridgeCallback(
    callbackId: string | undefined,
    success: boolean,
    data?: Record<string, Object>,
    error?: string
  ): void;

  sendNativeEvent(action: string, data: Record<string, Object>): void;
}

/**
 * 对应 Android fun interface BridgeActionHandler。
 * ArkTS 严格模式不支持 fun interface，改为普通接口，各 handler 用 class 实现。
 */
export interface BridgeActionHandler {
  handle(request: BridgeRequest, context: BridgeContext, emitter: BridgeEmitter): void;
}

/**
 * 对应 Android data class BridgeHandler。
 */
export interface BridgeHandler {
  requiresWhitelist: boolean;
  handler: BridgeActionHandler;
}

/**
 * WebViewPage 向 bridge 暴露的页面控制接口。
 * 对应 Android BridgeContext 中通过 fragment 调用的方法。
 *
 * 新增 setOptionMenuItems 以对齐 Android SetWebOptionMenuBridgeHandler 的 options 字段。
 */
export interface WxpWebPageContext {
  /** 对应 Android setBottomBarVisibleOverride */
  setBottomBarVisible(visible: boolean | null): void;
  /** 对应 Android setOptionMenuVisibleOverride */
  setOptionMenuVisible(visible: boolean | null): void;
  /** 对应 Android setOptionMenuItemsOverride */
  setOptionMenuItems(items: string[] | null): void;
  /** 对应 Android CloseWebPageBridgeHandler：H5 主动关闭当前 WebView 页 */
  closeWebPage(): void;
}

/**
 * 对应 Android data class BridgeContext。
 * 封装 WebviewController（JS 执行）、WxpWebPageContext（页面控制）以及当前 URL 追踪。
 */
export class BridgeContext {
  private readonly controller: webview.WebviewController;
  readonly pageContext: WxpWebPageContext;
  private currentUrlSnapshot: string = '';

  constructor(controller: webview.WebviewController, pageContext: WxpWebPageContext) {
    this.controller = controller;
    this.pageContext = pageContext;
  }

  get currentUrl(): string {
    return this.currentUrlSnapshot;
  }

  updateCurrentUrl(url: string): void {
    this.currentUrlSnapshot = url;
  }

  runJavaScript(js: string): void {
    this.controller.runJavaScript(js);
  }
}
