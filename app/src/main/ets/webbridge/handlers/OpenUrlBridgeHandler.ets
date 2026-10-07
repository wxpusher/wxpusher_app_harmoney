import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';
import { WxpJumpPageUtils } from '../../common/WxpJumpPageUtils';

/**
 * 对应 Android OpenUrlBridgeHandler。
 * 打开指定 URL：网页在新 WebView 页中打开，其他 App 的链接直接交给系统打开。
 */
class OpenUrlBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, _context: BridgeContext, emitter: BridgeEmitter): void {
    const targetUrl = request.data['url'] as string | undefined;
    if (!targetUrl || targetUrl.length === 0) {
      emitter.sendBridgeCallback(request.callbackId, false, undefined, 'url is empty');
      return;
    }
    WxpJumpPageUtils.jumpToWebUrl(targetUrl);
    const data: Record<string, Object> = { 'opened': true };
    emitter.sendBridgeCallback(request.callbackId, true, data);
  }
}

export const OpenUrlBridgeHandler: BridgeActionHandler = new OpenUrlBridgeHandlerImpl();
