import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 对应 Android SetWebBottomBarBridgeHandler。
 * 控制底部工具栏的可见性。
 */
class SetWebBottomBarBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, context: BridgeContext, emitter: BridgeEmitter): void {
    if (!Object.keys(request.data).includes('visible')) {
      // 没有 visible 字段 → 重置为默认
      context.pageContext.setBottomBarVisible(null);
      emitter.sendBridgeCallback(request.callbackId, true);
      return;
    }
    const visible = parseBooleanValue(request.data['visible']);
    if (visible === null) {
      emitter.sendBridgeCallback(request.callbackId, false, undefined, 'visible must be boolean');
      return;
    }
    context.pageContext.setBottomBarVisible(visible);
    emitter.sendBridgeCallback(request.callbackId, true);
  }
}

function parseBooleanValue(value: Object | undefined): boolean | null {
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
    if (s === 'true') {
      return true;
    }
    if (s === 'false') {
      return false;
    }
    return null;
  }
  return null;
}

export const SetWebBottomBarBridgeHandler: BridgeActionHandler = new SetWebBottomBarBridgeHandlerImpl();
