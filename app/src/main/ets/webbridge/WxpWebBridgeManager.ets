import { webview } from '@kit.ArkWeb';
import { WxpWebHostPolicy, WxpAppDataService, WxpConfig, WxpToastUtils, WxpLogUtils } from '@wxpusher/shared';
import { router } from '@kit.ArkUI';
import { WxpWeixinOpenManager } from '../wxapi/WxpWeixinOpenManager';

/**
 * 对应 Android BridgeRequest：
 *   action: string
 *   data:   Map<String, Any?>  → 这里是 Record<string, Object>
 *   callbackId: String?
 */
interface BridgeRequest {
  action: string;
  data?: Record<string, Object>;
  callbackId?: string;
}

/**
 * WebViewPage 向 bridge 暴露的页面控制接口，对应 Android BridgeContext 中
 * 可通过 fragment 调用的方法。
 */
export interface WxpWebPageContext {
  /** 对应 Android setBottomBarVisibleOverride */
  setBottomBarVisible(visible: boolean | null): void;
}

export class WxpWebBridgeManager {
  private controller: webview.WebviewController;
  private pageContext: WxpWebPageContext | null;

  constructor(controller: webview.WebviewController, pageContext?: WxpWebPageContext) {
    this.controller = controller;
    this.pageContext = pageContext ?? null;
  }

  onMessage(messageStr: string, currentUrl: string): void {
    try {
      const request = JSON.parse(messageStr) as BridgeRequest;
      WxpLogUtils.d('Bridge', `收到bridge消息: action=${request.action}`);
      this.dispatch(request, currentUrl);
    } catch (e) {
      WxpLogUtils.e('Bridge', '解析bridge消息失败', e as Error);
    }
  }

  private dispatch(request: BridgeRequest, currentUrl: string): void {
    const isWhitelisted = WxpWebHostPolicy.isUrlInWhitelist(currentUrl);

    // actions that require whitelist
    const whitelistRequired: string[] = [
      'getLoginInfo', 'getEnvBaseUrl', 'showToast',
      'setWebOptionMenu', 'setWebBottomBar', 'payRequest',
    ];

    if (whitelistRequired.indexOf(request.action) >= 0 && !isWhitelisted) {
      WxpLogUtils.w('Bridge', `非白名单地址，不允许调用桥: action=${request.action}, url=${currentUrl}`);
      this.sendCallback(request.callbackId, false, undefined, 'host is not allowed');
      return;
    }

    switch (request.action) {
      case 'getLoginInfo':
        this.handleGetLoginInfo(request);
        break;
      case 'getEnvBaseUrl':
        this.handleGetEnvBaseUrl(request);
        break;
      case 'openUrl':
        this.handleOpenUrl(request);
        break;
      case 'showToast':
        this.handleShowToast(request);
        break;
      case 'setWebOptionMenu':
        // 鸿蒙无 ActionBar 菜单，ACK 即可
        this.sendCallback(request.callbackId, true);
        break;
      case 'setWebBottomBar':
        this.handleSetWebBottomBar(request);
        break;
      case 'payRequest':
        this.handlePayRequest(request);
        break;
      default:
        WxpLogUtils.w('Bridge', `未知bridge action: ${request.action}`);
        this.sendCallback(request.callbackId, false, undefined, `unknown action: ${request.action}`);
        break;
    }
  }

  // ──────────────── handlers ────────────────

  private handleGetLoginInfo(request: BridgeRequest): void {
    const loginInfo = WxpAppDataService.getLoginInfo();
    // 对应 Android GetLoginInfoBridgeHandler：把 loginInfo 序列化后整体作为 data 回传
    const loginInfoStr = WxpAppDataService.getLoginInfoStr();
    let dataMap: Record<string, Object> = {};
    if (loginInfoStr && loginInfoStr.length > 0) {
      try {
        dataMap = JSON.parse(loginInfoStr) as Record<string, Object>;
      } catch (e) {
        WxpLogUtils.w('Bridge', '解析登录信息失败');
      }
    }
    this.sendCallback(request.callbackId, true, dataMap);
  }

  private handleGetEnvBaseUrl(request: BridgeRequest): void {
    // 对应 Android WxpGetEnvBaseUrlBridgeHandler：同时返回 apiBaseUrl + appFeBaseUrl
    const data: Record<string, Object> = {
      'apiBaseUrl': WxpConfig.baseUrl,
      'appFeBaseUrl': WxpConfig.appFeUrl,
    };
    this.sendCallback(request.callbackId, true, data);
  }

  private handleOpenUrl(request: BridgeRequest): void {
    // 对应 Android OpenUrlBridgeHandler：从 data["url"] 取目标地址
    const targetUrl = request.data?.['url'] as string | undefined;
    if (!targetUrl || targetUrl.length === 0) {
      this.sendCallback(request.callbackId, false, undefined, 'url is empty');
      return;
    }
    router.pushUrl({
      url: 'pages/WebViewPage',
      params: { url: targetUrl },
    });
    const data: Record<string, Object> = { 'opened': true };
    this.sendCallback(request.callbackId, true, data);
  }

  private handleShowToast(request: BridgeRequest): void {
    // 对应 Android ShowToastBridgeHandler：从 data["msg"] 取文本
    const msg = request.data?.['msg'] as string | undefined;
    if (!msg || msg.length === 0) {
      this.sendCallback(request.callbackId, false, undefined, 'msg is empty');
      return;
    }
    WxpToastUtils.showToast(msg);
    this.sendCallback(request.callbackId, true);
  }

  /**
   * 处理微信支付请求（对应 Android PayRequestBridgeHandler）。
   * 支付完成后通过 sendNativeEvent('payResponse') + sendBridgeCallback 回传结果。
   */
  private handlePayRequest(request: BridgeRequest): void {
    WxpLogUtils.i('Bridge', `支付请求: ${JSON.stringify(request.data)}`);
    const params = request.data ?? {};
    WxpWeixinOpenManager.requestPayment(params, (success, error) => {
      if (success) {
        const data: Record<string, Object> = { 'success': true, 'message': '支付成功' };
        this.sendNativeEvent('payResponse', data);
        this.sendCallback(request.callbackId, true, data);
      } else {
        const message = error?.message ?? '支付失败';
        const data: Record<string, Object> = { 'success': false, 'message': message };
        this.sendNativeEvent('payResponse', data);
        this.sendCallback(request.callbackId, false, data, message);
      }
    });
  }

  private handleSetWebBottomBar(request: BridgeRequest): void {
    // 对应 Android SetWebBottomBarBridgeHandler
    if (!request.data || !Object.keys(request.data).includes('visible')) {
      // 没有 visible 字段 → 重置为默认
      this.pageContext?.setBottomBarVisible(null);
      this.sendCallback(request.callbackId, true);
      return;
    }
    const rawVisible = request.data['visible'];
    const visible = this.parseBooleanValue(rawVisible);
    if (visible === null) {
      this.sendCallback(request.callbackId, false, undefined, 'visible must be boolean');
      return;
    }
    this.pageContext?.setBottomBarVisible(visible);
    this.sendCallback(request.callbackId, true);
  }

  // ──────────────── emitter ────────────────

  /**
   * 对应 Android WxpBridgeEmitter.sendBridgeCallback。
   *
   * 回调格式（与 Android/iOS/H5 三端对齐）：
   *   window.dispatchEvent(
   *     new CustomEvent('wxpusherBridgeCallback', { detail: '<JSON_STRING>' })
   *   );
   *
   * JSON_STRING 结构：{ callbackId, success, data?, error? }
   */
  sendCallback(
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
      const escaped = bodyJson.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
      const js = `window.dispatchEvent(new CustomEvent('wxpusherBridgeCallback', { detail: '${escaped}' }));`;
      this.controller.runJavaScript(js);
    } catch (e) {
      WxpLogUtils.e('Bridge', '发送bridge回调失败', e as Error);
    }
  }

  /**
   * 对应 Android WxpBridgeEmitter.sendNativeEvent。
   */
  sendNativeEvent(action: string, data: Record<string, Object>): void {
    try {
      const jsonData = JSON.stringify(data);
      const escaped = jsonData.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
      const js = `window.dispatchEvent(new CustomEvent('nativeEvent_${action}', { detail: '${escaped}' }));`;
      this.controller.runJavaScript(js);
    } catch (e) {
      WxpLogUtils.e('Bridge', `发送nativeEvent失败: action=${action}`, e as Error);
    }
  }

  // ──────────────── helpers ────────────────

  private parseBooleanValue(value: Object | undefined): boolean | null {
    if (value === null || value === undefined) {
      return null;
    }
    if (typeof value === 'boolean') {
      return value as boolean;
    }
    if (typeof value === 'number') {
      return (value as number) !== 0;
    }
    if (typeof value === 'string') {
      const s = (value as string).toLowerCase();
      if (s === 'true') return true;
      if (s === 'false') return false;
      return null;
    }
    return null;
  }
}
