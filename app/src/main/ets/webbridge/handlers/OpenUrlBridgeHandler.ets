import { router } from '@kit.ArkUI';
import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 对应 Android OpenUrlBridgeHandler。
 * 在新 WebView 页中打开指定 URL。
 */
class OpenUrlBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, _context: BridgeContext, emitter: BridgeEmitter): void {
    const targetUrl = request.data['url'] as string | undefined;
    if (!targetUrl || targetUrl.length === 0) {
      emitter.sendBridgeCallback(request.callbackId, false, undefined, 'url is empty');
      return;
    }
    router.pushUrl({
      url: 'pages/WebViewPage',
      params: { url: targetUrl },
    });
    const data: Record<string, Object> = { 'opened': true };
    emitter.sendBridgeCallback(request.callbackId, true, data);
  }
}

export const OpenUrlBridgeHandler: BridgeActionHandler = new OpenUrlBridgeHandlerImpl();
