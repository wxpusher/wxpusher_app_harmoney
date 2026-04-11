import { WxpLogUtils } from '@wxpusher/shared';
import { BridgeContext, BridgeEmitter } from './WxpBridgeContracts';

/**
 * 对应 Android WxpBridgeEmitter。
 * 负责将回调/事件结果注入到 WebView 的 JS 环境中。
 */
export class WxpBridgeEmitter implements BridgeEmitter {
  private readonly context: BridgeContext;

  constructor(context: BridgeContext) {
    this.context = context;
  }

  /**
   * 对应 Android WxpBridgeEmitter.sendBridgeCallback。
   *
   * 回调格式（与 Android / iOS / H5 三端对齐）：
   *   window.dispatchEvent(
   *     new CustomEvent('wxpusherBridgeCallback', { detail: '<JSON_STRING>' })
   *   );
   *
   * JSON_STRING 结构：{ callbackId, success, data?, error? }
   */
  sendBridgeCallback(
    callbackId: string | undefined,
    success: boolean,
    data?: Record<string, Object>,
    error?: string
  ): void {
    if (!callbackId || callbackId.length === 0) {
      return;
    }
    try {
      const body: Record<string, Object> = {
        'callbackId': callbackId,
        'success': success,
      };
      if (data !== undefined) {
        body['data'] = data;
      }
      if (error !== undefined && error.length > 0) {
        body['error'] = error;
      }
      const bodyJson = JSON.stringify(body);
      const escaped = this.escapeForSingleQuotedJs(bodyJson);
      const js =
        `window.dispatchEvent(new CustomEvent('wxpusherBridgeCallback', { detail: '${escaped}' }));`;
      this.context.runJavaScript(js);
    } catch (e) {
      WxpLogUtils.e('BridgeEmitter', `发送 bridge 回调失败: callbackId=${callbackId}`, e as Error);
    }
  }

  /**
   * 对应 Android WxpBridgeEmitter.sendNativeEvent。
   * 用于主动向 H5 推送事件（不需要 callbackId）。
   *
   * 事件格式：window.dispatchEvent(new CustomEvent('nativeEvent_${action}', { detail: '<JSON_STRING>' }));
   */
  sendNativeEvent(action: string, data: Record<string, Object>): void {
    try {
      const jsonData = JSON.stringify(data);
      WxpLogUtils.i('BridgeEmitter', `发送数据给 WebView: action=${action}, data=${jsonData}`);
      const escaped = this.escapeForSingleQuotedJs(jsonData);
      const js =
        `window.dispatchEvent(new CustomEvent('nativeEvent_${action}', { detail: '${escaped}' }));`;
      this.context.runJavaScript(js);
    } catch (e) {
      WxpLogUtils.e('BridgeEmitter', `发送 nativeEvent 失败: action=${action}`, e as Error);
    }
  }

  private escapeForSingleQuotedJs(source: string): string {
    return source.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
  }
}
