import { uri } from '@kit.ArkTS';

/**
 * 对应 KMP WxpWebHostPolicy.kt
 */
export class WxpWebHostPolicy {
  /**
   * 白名单完整配置（scheme://host）。
   * 桥的 permission 按这里的 scheme + host 生成；ArkWeb 同一个 host 只认最后一条规则，所以每个 host 只配一个 scheme。
   * 其他白名单判断只比较 host，和 KMP 一致。
   */
  static readonly DEFAULT_WHITELIST_HOSTS: string[] = [
    'https://wxpusher.zjiecode.com',
    'http://wxpusher.test.zjiecode.com',
    'http://10.0.0.11',
    'http://10.0.2.2',
    'http://127.0.0.1',
  ];

  private static readonly WHITELIST_HOST_SET: Set<string> = new Set(
    WxpWebHostPolicy.DEFAULT_WHITELIST_HOSTS.map((origin: string) => new uri.URI(origin).host)
  );

  static isHostInWhitelist(host: string | null | undefined): boolean {
    return host !== null && host !== undefined && WxpWebHostPolicy.WHITELIST_HOST_SET.has(host);
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
