import { WxpConfig } from '@wxpusher/shared';
import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 对应 Android WxpGetEnvBaseUrlBridgeHandler。
 * 返回 API 基础 URL 和 H5 基础 URL，供 H5 动态覆盖默认域名。
 */
class WxpGetEnvBaseUrlBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, _context: BridgeContext, emitter: BridgeEmitter): void {
    const data: Record<string, Object> = {
      'apiBaseUrl': WxpConfig.baseUrl,
      'appFeBaseUrl': WxpConfig.appFeUrl,
    };
    emitter.sendBridgeCallback(request.callbackId, true, data);
  }
}

export const WxpGetEnvBaseUrlBridgeHandler: BridgeActionHandler = new WxpGetEnvBaseUrlBridgeHandlerImpl();
