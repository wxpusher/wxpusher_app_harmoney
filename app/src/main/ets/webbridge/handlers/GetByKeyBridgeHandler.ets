import { WxpSaveService } from '@wxpusher/shared';
import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 通用存储读取。直接读 WxpSaveService（原生与 H5 同一 key 空间，无前缀），空值视为不存在返回空 data。
 */
class GetByKeyBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, _context: BridgeContext, emitter: BridgeEmitter): void {
    const key = request.data['key'] as string | undefined;
    if (!key || key.length === 0) {
      emitter.sendBridgeCallback(request.callbackId, false, undefined, 'key is empty');
      return;
    }
    const value = WxpSaveService.getString(key, '');
    const data: Record<string, Object> = {};
    if (value.length > 0) {
      data['value'] = value;
    }
    emitter.sendBridgeCallback(request.callbackId, true, data);
  }
}

export const GetByKeyBridgeHandler: BridgeActionHandler = new GetByKeyBridgeHandlerImpl();
