import { BridgeActionHandler, BridgeContext, BridgeEmitter, BridgeRequest } from '../WxpBridgeContracts';

/**
 * 对应 Android SetWebOptionMenuBridgeHandler。
 * 控制右上角菜单的可见性（visible）及显示项（options）。
 *
 * 支持的 options 值（对应 Android SUPPORTED_OPTION_MENU_KEYS）：
 *   copy_link / weixin_share / share / open_browser
 */

const SUPPORTED_OPTION_MENU_KEYS: string[] = [
  'copy_link',
  'weixin_share',
  'share',
  'open_browser',
];

class SetWebOptionMenuBridgeHandlerImpl implements BridgeActionHandler {
  handle(request: BridgeRequest, context: BridgeContext, emitter: BridgeEmitter): void {
    const hasVisibleField = Object.keys(request.data).includes('visible');
    const hasOptionsField = Object.keys(request.data).includes('options');

    if (!hasVisibleField && !hasOptionsField) {
      // 没有任何字段 → 重置为默认
      context.pageContext.setOptionMenuVisible(null);
      context.pageContext.setOptionMenuItems(null);
      emitter.sendBridgeCallback(request.callbackId, true);
      return;
    }

    if (hasVisibleField) {
      const visible = parseBooleanValue(request.data['visible']);
      if (visible === null) {
        emitter.sendBridgeCallback(request.callbackId, false, undefined, 'visible must be boolean');
        return;
      }
      context.pageContext.setOptionMenuVisible(visible);
    }

    if (hasOptionsField) {
      const parsedOptions = parseOptionKeys(request.data['options']);
      if (parsedOptions === null) {
        emitter.sendBridgeCallback(request.callbackId, false, undefined, 'options must be string array');
        return;
      }
      const unsupported = parsedOptions.filter((key: string) => !SUPPORTED_OPTION_MENU_KEYS.includes(key));
      if (unsupported.length > 0) {
        emitter.sendBridgeCallback(
          request.callbackId,
          false,
          undefined,
          `unsupported options: ${unsupported.join(',')}`
        );
        return;
      }
      context.pageContext.setOptionMenuItems(parsedOptions);
    }

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

function parseOptionKeys(value: Object | undefined): string[] | null {
  if (value === null || value === undefined) {
    return null;
  }
  if (!Array.isArray(value)) {
    return null;
  }
  const result: string[] = [];
  for (const item of value as Object[]) {
    if (typeof item !== 'string') {
      return null;
    }
    result.push(item as string);
  }
  return result;
}

export const SetWebOptionMenuBridgeHandler: BridgeActionHandler = new SetWebOptionMenuBridgeHandlerImpl();
