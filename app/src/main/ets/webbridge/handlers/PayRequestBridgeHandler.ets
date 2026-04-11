import { WxpLogUtils } from '@wxpusher/shared';
import { WxpWeixinOpenManager, WeChatError } from '../../wxapi/WxpWeixinOpenManager';
import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 对应 Android PayRequestBridgeHandler。
 * 触发微信支付流程；支付完成后同时发送 nativeEvent 和桥回调。
 */
class PayRequestBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, _context: BridgeContext, emitter: BridgeEmitter): void {
    WxpLogUtils.i('PayRequestHandler', `支付请求: ${JSON.stringify(request.data)}`);
    const params = request.data;
    WxpWeixinOpenManager.requestPayment(params, (success: boolean, error: WeChatError | null) => {
      if (success) {
        const data: Record<string, Object> = { 'success': true, 'message': '支付成功' };
        emitter.sendNativeEvent('payResponse', data);
        emitter.sendBridgeCallback(request.callbackId, true, data);
      } else {
        const message = error?.message ?? '支付失败';
        const data: Record<string, Object> = { 'success': false, 'message': message };
        emitter.sendNativeEvent('payResponse', data);
        emitter.sendBridgeCallback(request.callbackId, false, data, message);
      }
    });
  }
}

export const PayRequestBridgeHandler: BridgeActionHandler = new PayRequestBridgeHandlerImpl();
