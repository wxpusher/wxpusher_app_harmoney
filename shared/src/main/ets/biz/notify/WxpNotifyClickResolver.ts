import { WxpSaveService } from '../../base/common/WxpSaveService';

/**
 * 点击通知后要打开的地址。
 */
export interface WxpNotifyClickTarget {
  url: string;
  // true：交给系统打开（可能拉起外部 App）；false：App 内 WebView 打开
  openExternal: boolean;
  // 系统打开失败时改为打开的地址（详情页），App 内打开时为 null
  fallbackUrl: string | null;
}

enum SourceUrlType {
  WEB,
  EXTERNAL,
  INVALID
}

/**
 * 「点击通知直接打开原文链接」：决定点击通知后打开详情页还是原文链接。
 * 与 wxpusher-app shared 的 WxpNotifyClickResolver.kt 规则逐条一致，改动时两边同步。
 */
export class WxpNotifyClickResolver {
  // 与 H5（app-fe common/NotifyClickSetting.ts）约定的存储 key，值为 "1" 表示开启
  static readonly SETTING_KEY = 'notify_click_open_source_url';

  private static readonly WEB_SCHEMES: string[] = ['http', 'https'];

  // 会执行脚本、读取本地文件、拉起 App 内部页面，或者绕回自己的 deeplink，一律不打开
  private static readonly BLOCKED_SCHEMES: string[] = [
    'javascript', 'vbscript', 'data', 'file', 'content', 'blob', 'about',
    'intent', 'android-app', 'wxpusher'
  ];

  private static readonly SCHEME_REGEX: RegExp = /^[A-Za-z][A-Za-z0-9+.\-]*$/;

  static isEnabled(): boolean {
    return WxpSaveService.getString(WxpNotifyClickResolver.SETTING_KEY, '') === '1';
  }

  /**
   * @param detailUrl 消息详情页地址
   * @param sourceUrl 开发者传入的原文链接
   * @returns 要打开的地址；detailUrl 和原文链接都用不了时返回 null，保持现有逻辑不跳转
   */
  static resolve(detailUrl: string | null | undefined, sourceUrl: string | null | undefined): WxpNotifyClickTarget | null {
    const detail = (detailUrl ?? '').trim();
    const detailTarget: WxpNotifyClickTarget | null =
      detail.length === 0 ? null : { url: detail, openExternal: false, fallbackUrl: null };
    if (!WxpNotifyClickResolver.isEnabled()) {
      return detailTarget;
    }
    const source = (sourceUrl ?? '').trim();
    switch (WxpNotifyClickResolver.classify(source)) {
      case SourceUrlType.WEB:
        return { url: source, openExternal: false, fallbackUrl: null };
      case SourceUrlType.EXTERNAL:
        return { url: source, openExternal: true, fallbackUrl: detailTarget ? detailTarget.url : null };
      default:
        return detailTarget;
    }
  }

  private static classify(url: string): SourceUrlType {
    if (url.length === 0) {
      return SourceUrlType.INVALID;
    }
    // 浏览器会忽略 scheme 里的 Tab、换行，java\tscript: 这类写法靠这一步挡住
    for (let i = 0; i < url.length; i++) {
      const code = url.charCodeAt(i);
      if (code < 0x20 || code === 0x7F) {
        return SourceUrlType.INVALID;
      }
    }
    const colonIndex = url.indexOf(':');
    if (colonIndex <= 0) {
      return SourceUrlType.INVALID;
    }
    const rawScheme = url.substring(0, colonIndex);
    if (!WxpNotifyClickResolver.SCHEME_REGEX.test(rawScheme)) {
      return SourceUrlType.INVALID;
    }
    const scheme = rawScheme.toLowerCase();
    if (WxpNotifyClickResolver.WEB_SCHEMES.includes(scheme)) {
      const rest = url.substring(colonIndex + 1);
      if (!rest.startsWith('//')) {
        return SourceUrlType.INVALID;
      }
      const hostMatch = rest.substring(2).match(/^[^/?#]*/);
      const host = hostMatch ? hostMatch[0] : '';
      return host.length === 0 ? SourceUrlType.INVALID : SourceUrlType.WEB;
    }
    if (WxpNotifyClickResolver.BLOCKED_SCHEMES.includes(scheme)) {
      return SourceUrlType.INVALID;
    }
    return SourceUrlType.EXTERNAL;
  }
}
