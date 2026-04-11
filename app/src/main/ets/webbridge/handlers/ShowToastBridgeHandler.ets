import { WxpToastUtils } from '@wxpusher/shared';
import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 对应 Android ShowToastBridgeHandler。
 * 显示原生 Toast 通知。
 */
class ShowToastBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, _context: BridgeContext, emitter: BridgeEmitter): void {
    const msg = request.data['msg'] as string | undefined;
    if (!msg || msg.length === 0) {
      emitter.sendBridgeCallback(request.callbackId, false, undefined, 'msg is empty');
      return;
    }
    WxpToastUtils.showToast(msg);
    emitter.sendBridgeCallback(request.callbackId, true);
  }
}

export const ShowToastBridgeHandler: BridgeActionHandler = new ShowToastBridgeHandlerImpl();
