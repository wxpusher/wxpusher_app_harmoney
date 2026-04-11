import { WxpLogUtils } from '@wxpusher/shared';
import { BridgeRequest } from './WxpBridgeContracts';

/**
 * 对应 Android WxpBridgeMessageParser。
 * 负责将 JS 侧传入的 JSON 字符串解析为 BridgeRequest。
 */
export class WxpBridgeMessageParser {
  parse(messageStr: string): BridgeRequest | null {
    try {
      const parsed = JSON.parse(messageStr) as Record<string, Object>;
      const action = parsed['action'] as string | undefined;
      if (!action || action.length === 0) {
        WxpLogUtils.w('BridgeParser', '消息缺少 action 字段');
        return null;
      }
      const callbackId = parsed['callbackId'] as string | undefined;
      const rawData = parsed['data'];
      let data: Record<string, Object> = {};
      if (rawData !== null && rawData !== undefined && typeof rawData === 'object') {
        data = rawData as Record<string, Object>;
      }
      const request: BridgeRequest = {
        action: action,
        data: data,
        callbackId: callbackId,
      };
      return request;
    } catch (e) {
      WxpLogUtils.w('BridgeParser', '解析 bridge 消息失败');
      return null;
    }
  }
}
