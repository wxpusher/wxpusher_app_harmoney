import { webview } from '@kit.ArkWeb';
import { WxpWebHostPolicy, WxpAppDataService, WxpConfig, WxpToastUtils, WxpLogUtils } from '@wxpusher/shared';
import { router } from '@kit.ArkUI';

/**
 * 对应 Android WxpBridgeManager + handlers
 * Bridge 消息路由和处理器
 */
interface BridgeRequest {
  action: string;
  data?: string;
  callbackId?: string;
}

/** 无业务字段的 bridge 回调体（与 Android 侧空 JSON 对象一致） */
interface BridgeEmptyCallbackData {}

interface BridgeGetEnvBaseUrlData {
  apiBaseUrl: string;
}

export class WxpWebBridgeManager {
  private controller: webview.WebviewController;

  constructor(controller: webview.WebviewController) {
    this.controller = controller;
  }

  onMessage(messageStr: string, currentUrl: string): void {
    try {
      const request = JSON.parse(messageStr) as BridgeRequest;
      WxpLogUtils.d('Bridge', `收到bridge消息: action=${request.action}`);
      this.handleAction(request, currentUrl);
    } catch (e) {
      WxpLogUtils.e('Bridge', '解析bridge消息失败', e as Error);
    }
  }

  private handleAction(request: BridgeRequest, currentUrl: string): void {
    const isWhitelisted = WxpWebHostPolicy.isUrlInWhitelist(currentUrl);

    switch (request.action) {
      case 'getLoginInfo':
        if (!isWhitelisted) return;
        this.handleGetLoginInfo(request);
        break;
      case 'getEnvBaseUrl':
        if (!isWhitelisted) return;
        this.handleGetEnvBaseUrl(request);
        break;
      case 'openUrl':
        this.handleOpenUrl(request);
        break;
      case 'showToast':
        if (!isWhitelisted) return;
        this.handleShowToast(request);
        break;
      case 'setWebOptionMenu':
        if (!isWhitelisted) return;
        // 鸿蒙侧暂不实现菜单控制
        const menuAck: BridgeEmptyCallbackData = {};
        this.sendCallback(request.callbackId, menuAck);
        break;
      case 'setWebBottomBar':
        if (!isWhitelisted) return;
        // 鸿蒙侧暂不实现底栏控制
        const bottomBarAck: BridgeEmptyCallbackData = {};
        this.sendCallback(request.callbackId, bottomBarAck);
        break;
      default:
        WxpLogUtils.w('Bridge', `未知bridge action: ${request.action}`);
        break;
    }
  }

  private handleGetLoginInfo(request: BridgeRequest): void {
    const loginInfo = WxpAppDataService.getLoginInfo();
    const data: Record<string, string | undefined> = {
      'deviceToken': loginInfo?.deviceToken,
      'uid': loginInfo?.uid,
      'openId': loginInfo?.openId,
      'nickName': loginInfo?.nickName,
    };
    this.sendCallback(request.callbackId, data);
  }

  private handleGetEnvBaseUrl(request: BridgeRequest): void {
    const envData: BridgeGetEnvBaseUrlData = {
      apiBaseUrl: WxpConfig.baseUrl,
    };
    this.sendCallback(request.callbackId, envData);
  }

  private handleOpenUrl(request: BridgeRequest): void {
    if (request.data) {
      router.pushUrl({
        url: 'pages/WebViewPage',
        params: { url: request.data },
      });
    }
    const openUrlAck: BridgeEmptyCallbackData = {};
    this.sendCallback(request.callbackId, openUrlAck);
  }

  private handleShowToast(request: BridgeRequest): void {
    if (request.data) {
      WxpToastUtils.showToast(request.data);
    }
    const toastAck: BridgeEmptyCallbackData = {};
    this.sendCallback(request.callbackId, toastAck);
  }

  private sendCallback(callbackId: string | undefined, data: Object): void {
    if (!callbackId) return;
    try {
      const jsonStr = JSON.stringify(data).replace(/\\/g, '\\\\').replace(/'/g, "\\'");
      const js = `(function(){
        try {
          var event = new CustomEvent('wxpusherBridgeCallback', {detail: {callbackId:'${callbackId}', data:'${jsonStr}'}});
          window.dispatchEvent(event);
        } catch(e) {}
      })()`;
      this.controller.runJavaScript(js);
    } catch (e) {
      WxpLogUtils.e('Bridge', '发送bridge回调失败', e as Error);
    }
  }
}
