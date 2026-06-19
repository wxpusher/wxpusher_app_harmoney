import { common } from '@kit.AbilityKit';
import { WxpLogUtils } from '@wxpusher/shared';
import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 对应 Android OpenSystemBrowserBridgeHandler。
 * 由 H5 传入 url，使用系统默认浏览器打开外链（而非内置 WebView）。
 * 复用 WxpWebViewComponent.openInBrowser 的同款 API：UIAbilityContext.openLink。
 */
class OpenSystemBrowserBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, _context: BridgeContext, emitter: BridgeEmitter): void {
    const targetUrl = request.data['url'] as string | undefined;
    if (!targetUrl || targetUrl.length === 0) {
      emitter.sendBridgeCallback(request.callbackId, false, undefined, 'url is empty');
      return;
    }
    const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
    if (!ctx) {
      emitter.sendBridgeCallback(request.callbackId, false, undefined, 'ability context not ready');
      return;
    }
    ctx.openLink(targetUrl, { appLinkingOnly: false })
      .then(() => {
        const data: Record<string, Object> = { 'opened': true };
        emitter.sendBridgeCallback(request.callbackId, true, data);
      })
      .catch((e: Error) => {
        WxpLogUtils.w('OpenSystemBrowser', '系统浏览器打开失败', e);
        emitter.sendBridgeCallback(request.callbackId, false, undefined, 'open browser failed');
      });
  }
}

export const OpenSystemBrowserBridgeHandler: BridgeActionHandler = new OpenSystemBrowserBridgeHandlerImpl();
