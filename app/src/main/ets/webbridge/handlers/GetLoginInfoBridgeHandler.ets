import { WxpAppDataService, WxpLogUtils } from '@wxpusher/shared';
import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 对应 Android GetLoginInfoBridgeHandler。
 * 返回当前用户的登录信息。
 */
class GetLoginInfoBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, _context: BridgeContext, emitter: BridgeEmitter): void {
    const loginInfoStr = WxpAppDataService.getLoginInfoStr();
    let dataMap: Record<string, Object> = {};
    if (loginInfoStr && loginInfoStr.length > 0) {
      try {
        dataMap = JSON.parse(loginInfoStr) as Record<string, Object>;
      } catch (e) {
        WxpLogUtils.w('GetLoginInfoHandler', '解析登录信息失败');
      }
    }
    emitter.sendBridgeCallback(request.callbackId, true, dataMap);
  }
}

export const GetLoginInfoBridgeHandler: BridgeActionHandler = new GetLoginInfoBridgeHandlerImpl();
