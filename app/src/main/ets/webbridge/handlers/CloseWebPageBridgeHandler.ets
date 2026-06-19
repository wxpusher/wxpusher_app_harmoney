import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 对应 Android CloseWebPageBridgeHandler。
 * 由 H5 主动关闭当前 WebView 页（委托宿主页 pageContext.closeWebPage）。
 */
class CloseWebPageBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, context: BridgeContext, emitter: BridgeEmitter): void {
    context.pageContext.closeWebPage();
    emitter.sendBridgeCallback(request.callbackId, true);
  }
}

export const CloseWebPageBridgeHandler: BridgeActionHandler = new CloseWebPageBridgeHandlerImpl();
