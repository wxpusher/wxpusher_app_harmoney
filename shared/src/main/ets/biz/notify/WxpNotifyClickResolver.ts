import { WxpSaveService } from '../../base/common/WxpSaveService';
import { WxpLinkClassifier, WxpLinkType } from '../link/WxpLinkClassifier';

/**
 * 点击通知后要打开的地址，交给 jumpToWebUrl 按 scheme 决定 App 内打开还是交给系统打开。
 */
export interface WxpNotifyClickTarget {
  url: string;
  // 交给系统打开失败（没有能打开的 App）时改为打开的地址，即详情页
  fallbackUrl: string | null;
}

/**
 * 「点击通知直接打开原文链接」：决定点击通知后打开详情页还是原文链接。
 * 与 wxpusher-app shared 的 WxpNotifyClickResolver.kt 逻辑一致，改动时两边同步。
 */
export class WxpNotifyClickResolver {
  // 与 H5（app-fe common/NotifyClickSetting.ts）约定的存储 key，值为 "1" 表示开启
  static readonly SETTING_KEY = 'notify_click_open_source_url';

  static isEnabled(): boolean {
    return WxpSaveService.getString(WxpNotifyClickResolver.SETTING_KEY, '') === '1';
  }

  /**
   * @param detailUrl 消息详情页地址
   * @param sourceUrl 开发者传入的原文链接
   * @returns 要打开的地址；详情页地址为空时返回 null，保持现有逻辑不跳转
   */
  static resolve(detailUrl: string | null | undefined, sourceUrl: string | null | undefined): WxpNotifyClickTarget | null {
    const detail = (detailUrl ?? '').trim();
    if (detail.length === 0) {
      return null;
    }
    if (!WxpNotifyClickResolver.isEnabled()) {
      return { url: detail, fallbackUrl: null };
    }
    const source = (sourceUrl ?? '').trim();
    // 没有原文链接，或者原文链接不能打开（危险、格式不对），都打开详情页
    if (WxpLinkClassifier.classify(source) === WxpLinkType.INVALID) {
      return { url: detail, fallbackUrl: null };
    }
    return { url: source, fallbackUrl: detail };
  }
}
