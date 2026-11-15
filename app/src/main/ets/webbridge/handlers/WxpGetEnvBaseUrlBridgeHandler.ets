import { WxpBaseInfoService, WxpConfig } from '@wxpusher/shared';
import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 对应 Android WxpGetEnvBaseUrlBridgeHandler。
 * 返回 API 基础 URL 和 H5 基础 URL，供 H5 动态覆盖默认域名。
 */
class WxpGetEnvBaseUrlBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, _context: BridgeContext, emitter: BridgeEmitter): void {
    const data: Record<string, Object> = {
      'apiBaseUrl': WxpConfig.baseUrl,
      'appFeBaseUrl': WxpConfig.appFeUrl,
      // app-fe 内嵌消息详情页时据此传 wxpClient（monorepo docs/message-detail-sandbox-design.md 第 6.10 节）。
      // 桥对象配了 permission，只有白名单页面（只在主 frame 运行）能调用，所以 frameSafe 恒为 true
      'platform': WxpBaseInfoService.getClientPlatform(),
      'versionName': WxpBaseInfoService.getAppVersionName(),
      'frameSafe': true,
    };
    emitter.sendBridgeCallback(request.callbackId, true, data);
  }
}

export const WxpGetEnvBaseUrlBridgeHandler: BridgeActionHandler = new WxpGetEnvBaseUrlBridgeHandlerImpl();
