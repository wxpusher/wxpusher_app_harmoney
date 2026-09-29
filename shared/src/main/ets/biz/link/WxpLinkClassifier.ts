/**
 * 链接的打开方式
 */
export enum WxpLinkType {
  // http/https 网页，App 内 WebView 打开
  WEB,
  // 其他 App 的链接（weixin://、alipays://、tel: 等），交给系统打开，可能拉起外部 App
  EXTERNAL,
  // 空的、格式不对，或者危险的链接，不打开
  INVALID
}

/**
 * 按 scheme 判断链接的打开方式，WxpJumpPageUtils.jumpToWebUrl 统一用它决定怎么打开。
 * 与 wxpusher-app shared 的 WxpLinkClassifier.kt 规则逐条一致，改动时两边同步。
 */
export class WxpLinkClassifier {
  private static readonly WEB_SCHEMES: string[] = ['http', 'https'];

  // 会执行脚本、读取本地文件、拉起 App 内部页面，或者绕回自己的 deeplink，一律不打开
  private static readonly BLOCKED_SCHEMES: string[] = [
    'javascript', 'vbscript', 'data', 'file', 'content', 'blob', 'about',
    'intent', 'android-app', 'wxpusher'
  ];

  private static readonly SCHEME_REGEX: RegExp = /^[A-Za-z][A-Za-z0-9+.\-]*$/;

  static classify(url: string | null | undefined): WxpLinkType {
    const link = (url ?? '').trim();
    if (link.length === 0) {
      return WxpLinkType.INVALID;
    }
    // 浏览器会忽略 scheme 里的 Tab、换行，java\tscript: 这类写法靠这一步挡住
    for (let i = 0; i < link.length; i++) {
      const code = link.charCodeAt(i);
      if (code < 0x20 || code === 0x7F) {
        return WxpLinkType.INVALID;
      }
    }
    const colonIndex = link.indexOf(':');
    if (colonIndex <= 0) {
      return WxpLinkType.INVALID;
    }
    const rawScheme = link.substring(0, colonIndex);
    if (!WxpLinkClassifier.SCHEME_REGEX.test(rawScheme)) {
      return WxpLinkType.INVALID;
    }
    const scheme = rawScheme.toLowerCase();
    if (WxpLinkClassifier.WEB_SCHEMES.includes(scheme)) {
      const rest = link.substring(colonIndex + 1);
      if (!rest.startsWith('//')) {
        return WxpLinkType.INVALID;
      }
      const hostMatch = rest.substring(2).match(/^[^/?#]*/);
      const host = hostMatch ? hostMatch[0] : '';
      return host.length === 0 ? WxpLinkType.INVALID : WxpLinkType.WEB;
    }
    if (WxpLinkClassifier.BLOCKED_SCHEMES.includes(scheme)) {
      return WxpLinkType.INVALID;
    }
    return WxpLinkType.EXTERNAL;
  }
}
