import { WxpApiService } from '../../api/WxpApiService';
import { WxpDialogUtils } from '../../base/common/WxpDialogUtils';
import { WxpLogUtils } from '../../base/common/WxpLogUtils';
import { WxpSaveService } from '../../base/common/WxpSaveService';
import { WxpToastUtils } from '../../base/common/WxpToastUtils';
import { WxpConfig } from '../../config/WxpConfig';

/**
 * App 端采集的多因素，和 H5 落地页口径一致：屏幕用逻辑像素（vp），竖屏短边为宽。
 */
export interface WxpSubscribeIntentFactors {
  os?: string;
  osVersion?: string;
  model?: string;
  screenW?: number;
  screenH?: number;
  dpr?: number;
  netType?: string;
  lang?: string;
  tz?: string;
}

export interface WxpSubscribeIntentMatchResp {
  level?: string;
  intentId?: string;
  type?: number;
  id?: number;
  name?: string;
  extraDropped?: boolean;
}

/** 消息搜索时，搜索词正好是订阅暗号匹配到的订阅目标（服务端 FollowInfo 的部分字段） */
export interface WxpCodeWordMatch {
  /** 搜索的暗号，服务端不返回，查到后补上 */
  word?: string;
  /** 1 应用，2 主题 */
  type?: number;
  id?: number;
  name?: string;
  /** 当前用户是否已订阅 */
  subscribed?: boolean;
}

/** 和服务端 CodeWordService.VALID_WORD 一致 */
const VALID_WORD = /^[\u4e00-\u9fa5A-Za-z0-9]{2,16}$/;

export interface WxpSubscribeFollowResult {
  code?: number;
  msg?: string;
}

const TAG = 'SubscribeLink';
const SCHEME = 'wxpusher';
const SCHEME_HOST = 'wxpusher.smjcco.com';
const KEY_PENDING_URL = 'subscribe_link_pending_url';
const KEY_RESTORE_CHECKED = 'subscribe_restore_checked';

interface ParsedLink {
  scheme: string;
  host: string;
  path: string;
  params: Map<string, string>;
}

function parseLink(link: string): ParsedLink | null {
  const m = /^([a-zA-Z][a-zA-Z0-9+.-]*):\/\/([^\/?#]+)([^?#]*)(?:\?([^#]*))?/.exec(link);
  if (!m) {
    return null;
  }
  const params = new Map<string, string>();
  const query = m[4] ?? '';
  for (const part of query.split('&')) {
    if (part.length === 0) {
      continue;
    }
    const idx = part.indexOf('=');
    const key = idx >= 0 ? part.substring(0, idx) : part;
    const raw = idx >= 0 ? part.substring(idx + 1) : '';
    try {
      params.set(decodeURIComponent(key), decodeURIComponent(raw.replace(/\+/g, ' ')));
    } catch (_e) {
      return null;
    }
  }
  return {
    scheme: m[1].toLowerCase(),
    host: m[2].toLowerCase().replace(/:\d+$/, ''),
    path: m[3] ?? '',
    params,
  };
}

/**
 * 统一订阅链接在 App 端只做路由，和 KMP WxpSubscribeLinkManager.kt 保持一致：
 * App Linking / scheme / 开放标签拉起后，统一用 WebView 打开 H5 落地页 #/subscribe-link。
 */
export class WxpSubscribeLinkManager {
  /** 「输入订阅暗号」页 */
  static codeWordPageUrl(): string {
    return `${WxpConfig.appFeUrl}/app/#/code-word`;
  }

  /** 是否可能是订阅暗号，不是的话不用去服务端查 */
  static isCodeWordLike(word: string | null | undefined): boolean {
    return !!word && VALID_WORD.test(word);
  }

  /** 按暗号打开落地页，和市场搜索命中暗号时跳转的一致 */
  static pageUrlForCodeWord(word: string): string {
    return `${WxpConfig.appFeUrl}/app/#/subscribe-link?sk=${encodeURIComponent(word)}&via=code`;
  }

  /** 开放标签 extinfo 只带 intentId */
  static pageUrlForIntent(intentId: string): string {
    return `${WxpConfig.appFeUrl}/app/#/subscribe-link?intentId=${encodeURIComponent(intentId)}`;
  }

  /**
   * 把拉起 App 的链接转换成 H5 落地页地址，不是订阅链接时返回 null：
   * - https://{本环境域名}/api/s/{sk}?extra=&jump=（App Linking）
   * - wxpusher://wxpusher.smjcco.com/subscribe?sk=&extra=&intentId=（落地页「打开 App 订阅」）
   */
  static toPageUrl(link: string | null | undefined): string | null {
    if (!link) {
      return null;
    }
    const url = parseLink(link);
    if (!url) {
      return null;
    }
    const query: [string, string][] = [];
    if (url.scheme === SCHEME) {
      if (url.host !== SCHEME_HOST || url.path.replace(/\/+$/, '') !== '/subscribe') {
        return null;
      }
      for (const key of ['sk', 'extra', 'intentId']) {
        const v = url.params.get(key);
        if (v) {
          query.push([key, v]);
        }
      }
    } else if (url.scheme === 'http' || url.scheme === 'https') {
      const apiHost = parseLink(WxpConfig.baseUrl)?.host;
      const prefix = '/api/s/';
      if (url.host !== apiHost || !url.path.startsWith(prefix)) {
        return null;
      }
      let sk: string;
      try {
        sk = decodeURIComponent(url.path.substring(prefix.length).replace(/\/+$/, ''));
      } catch (_e) {
        return null;
      }
      if (sk.length === 0 || sk.includes('/')) {
        return null;
      }
      query.push(['sk', sk]);
      for (const key of ['extra', 'jump']) {
        const v = url.params.get(key);
        if (v) {
          query.push([key, v]);
        }
      }
    } else {
      return null;
    }
    if (!query.some((it) => it[0] === 'sk' || it[0] === 'intentId')) {
      return null;
    }
    const queryString = query.map((it) => `${it[0]}=${encodeURIComponent(it[1])}`).join('&');
    return `${WxpConfig.appFeUrl}/app/#/subscribe-link?${queryString}`;
  }

  /** 未登录时先记下来，登录进入首页后再打开 */
  static savePending(pageUrl: string): void {
    WxpSaveService.setString(KEY_PENDING_URL, pageUrl);
  }

  static consumePending(): string | null {
    const url = WxpSaveService.getString(KEY_PENDING_URL, '');
    if (!url) {
      return null;
    }
    WxpSaveService.setString(KEY_PENDING_URL, '');
    return url;
  }

  /**
   * 安装后还原：首次登录进入首页时调用一次（每次安装只查一次）。
   * 匹配到高 / 中置信的订阅意图时弹窗确认；服务端灰度关闭时返回 none，不弹窗。
   */
  static async checkRestoreOnce(factors: WxpSubscribeIntentFactors): Promise<void> {
    if (WxpSaveService.getBoolean(KEY_RESTORE_CHECKED, false)) {
      return;
    }
    const resp = await WxpApiService.matchSubscribeIntent(factors);
    if (!resp) {
      return;
    }
    WxpSaveService.setBoolean(KEY_RESTORE_CHECKED, true);
    const intentId = resp.intentId;
    if (!intentId || (resp.level !== 'high' && resp.level !== 'mid')) {
      WxpLogUtils.d(TAG, `restore: no match, level=${resp.level}`);
      return;
    }
    const name = resp.name ?? '';
    let message = '你刚才在网页上打开过它的订阅链接，现在可以一键订阅。';
    if (resp.extraDropped) {
      message += `\n\n如需关联你在「${name}」的账号，订阅后请回到原来的页面，再点一次订阅链接。`;
    }
    WxpDialogUtils.showDialog({
      title: `是否订阅「${name}」？`,
      message,
      leftText: '不是我',
      rightText: '订阅',
      rightBlock: () => {
        void WxpSubscribeLinkManager.subscribeByIntent(intentId);
      },
      cancelable: false,
    });
  }

  private static async subscribeByIntent(intentId: string): Promise<void> {
    const result = await WxpApiService.subscribeByIntent(intentId);
    if (!result) {
      return;
    }
    WxpToastUtils.showToast(result.code === 1 ? '订阅成功' : (result.msg ?? '订阅失败'));
  }
}
