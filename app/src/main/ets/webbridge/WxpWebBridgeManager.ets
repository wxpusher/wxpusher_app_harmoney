import { webview } from '@kit.ArkWeb';
import { WxpWebHostPolicy, WxpLogUtils } from '@wxpusher/shared';
import { BridgeActionHandler, BridgeContext, BridgeHandler, BridgeRequest, WxpWebPageContext } from './WxpBridgeContracts';
import { WxpBridgeEmitter } from './WxpBridgeEmitter';
import { WxpBridgeMessageParser } from './WxpBridgeMessageParser';
import { GetLoginInfoBridgeHandler } from './handlers/GetLoginInfoBridgeHandler';
import { WxpGetEnvBaseUrlBridgeHandler } from './handlers/WxpGetEnvBaseUrlBridgeHandler';
import { OpenUrlBridgeHandler } from './handlers/OpenUrlBridgeHandler';
import { ShowToastBridgeHandler } from './handlers/ShowToastBridgeHandler';
import { PayRequestBridgeHandler } from './handlers/PayRequestBridgeHandler';
import { SetWebOptionMenuBridgeHandler } from './handlers/SetWebOptionMenuBridgeHandler';
import { SetWebBottomBarBridgeHandler } from './handlers/SetWebBottomBarBridgeHandler';
import { CloseWebPageBridgeHandler } from './handlers/CloseWebPageBridgeHandler';
import { OpenSystemBrowserBridgeHandler } from './handlers/OpenSystemBrowserBridgeHandler';

export { WxpWebPageContext } from './WxpBridgeContracts';

/**
 * 对应 Android WxpWebBridgeManager。
 * 只负责 handler 注册与消息分发，不包含任何业务逻辑。
 */
export class WxpWebBridgeManager {
  private readonly context: BridgeContext;
  private readonly emitter: WxpBridgeEmitter;
  private readonly parser: WxpBridgeMessageParser;
  private readonly handlers: Map<string, BridgeHandler> = new Map();

  constructor(controller: webview.WebviewController, pageContext: WxpWebPageContext) {
    this.context = new BridgeContext(controller, pageContext);
    this.emitter = new WxpBridgeEmitter(this.context);
    this.parser = new WxpBridgeMessageParser();
    this.registerDefaultHandlers();
  }

  // ──────────────── 注册 ────────────────

  registerHandler(action: string, requiresWhitelist: boolean, handler: BridgeActionHandler): void {
    const entry: BridgeHandler = { requiresWhitelist, handler };
    this.handlers.set(action, entry);
  }

  private registerDefaultHandlers(): void {
    this.registerHandler('payRequest', true, PayRequestBridgeHandler);
    this.registerHandler('openUrl', false, OpenUrlBridgeHandler);
    this.registerHandler('getLoginInfo', true, GetLoginInfoBridgeHandler);
    this.registerHandler('getEnvBaseUrl', true, WxpGetEnvBaseUrlBridgeHandler);
    this.registerHandler('showToast', true, ShowToastBridgeHandler);
    this.registerHandler('setWebOptionMenu', true, SetWebOptionMenuBridgeHandler);
    this.registerHandler('setWebBottomBar', true, SetWebBottomBarBridgeHandler);
    this.registerHandler('closeWebPage', false, CloseWebPageBridgeHandler);
    this.registerHandler('openSystemBrowser', false, OpenSystemBrowserBridgeHandler);
  }

  // ──────────────── URL 追踪 ────────────────

  /**
   * 对应 Android BridgeContext.updateCurrentUrl。
   * 由 WxpWebViewComponent 在 URL 变更时主动调用。
   */
  updateCurrentUrl(url: string): void {
    this.context.updateCurrentUrl(url);
  }

  // ──────────────── 消息入口 ────────────────

  /**
   * 对应 Android WxpWebBridgeManager.onMessage。
   * 由 WxpWebViewComponent 的 javaScriptProxy 调用。
   */
  onMessage(messageStr: string): void {
    const request = this.parser.parse(messageStr);
    if (request === null) {
      return;
    }
    WxpLogUtils.d('BridgeManager', `收到 bridge 消息: action=${request.action}`);
    this.dispatch(request);
  }

  // ──────────────── 分发 ────────────────

  private dispatch(request: BridgeRequest): void {
    const bridgeHandler = this.handlers.get(request.action);
    if (bridgeHandler === undefined) {
      WxpLogUtils.w('BridgeManager', `未知 bridge action: ${request.action}`);
      this.emitter.sendBridgeCallback(
        request.callbackId,
        false,
        undefined,
        `unknown action: ${request.action}`
      );
      return;
    }

    if (bridgeHandler.requiresWhitelist && !WxpWebHostPolicy.isUrlInWhitelist(this.context.currentUrl)) {
      WxpLogUtils.w('BridgeManager', `非白名单地址，不允许调用桥: action=${request.action}, url=${this.context.currentUrl}`);
      this.emitter.sendBridgeCallback(
        request.callbackId,
        false,
        undefined,
        'host is not allowed'
      );
      return;
    }

    try {
      bridgeHandler.handler.handle(request, this.context, this.emitter);
    } catch (e) {
      WxpLogUtils.w('BridgeManager', `处理桥接逻辑失败: action=${request.action}`, e as Error);
      this.emitter.sendBridgeCallback(
        request.callbackId,
        false,
        undefined,
        'bridge handler error'
      );
    }
  }
}
