import { WxpSaveService } from '@wxpusher/shared';
import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 通用存储写入。直接写 WxpSaveService（原生与 H5 同一 key 空间，无前缀）；安全由桥 requiresWhitelist 保证。
 */
class SetKeyValueBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, _context: BridgeContext, emitter: BridgeEmitter): void {
    const key = request.data['key'] as string | undefined;
    if (!key || key.length === 0) {
      emitter.sendBridgeCallback(request.callbackId, false, undefined, 'key is empty');
      return;
    }
    const value = (request.data['value'] as string | undefined) ?? '';
    WxpSaveService.setString(key, value);
    emitter.sendBridgeCallback(request.callbackId, true);
  }
}

export const SetKeyValueBridgeHandler: BridgeActionHandler = new SetKeyValueBridgeHandlerImpl();
