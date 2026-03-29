import { uri } from '@kit.ArkTS';

/**
 * 对应 KMP WxpWebHostPolicy.kt
 */
export class WxpWebHostPolicy {
  static readonly DEFAULT_WHITELIST_HOSTS: Set<string> = new Set([
    'wxpusher.zjiecode.com',
    'wxpusher.test.zjiecode.com',
    '10.0.0.11',
    '10.0.2.2',
    '127.0.0.1',
  ]);

  static isHostInWhitelist(host: string | null | undefined): boolean {
    return host !== null && host !== undefined && WxpWebHostPolicy.DEFAULT_WHITELIST_HOSTS.has(host);
  }

  static isUrlInWhitelist(url: string | null | undefined): boolean {
    if (!url || url.trim().length === 0) {
      return false;
    }
    try {
      const parsed = new uri.URI(url);
      return WxpWebHostPolicy.isHostInWhitelist(parsed.host);
    } catch {
      return false;
    }
  }
}
