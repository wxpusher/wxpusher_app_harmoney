import { uri } from '@kit.ArkTS';
import { WxpConfig } from '../config/WxpConfig';
import { WxpDateTimeUtils } from '../base/common/WxpDateTimeUtils';
import { WxpLogUtils } from '../base/common/WxpLogUtils';
import { WxpNetworkService } from '../base/common/WxpNetworkService';
import { WxpSaveService } from '../base/common/WxpSaveService';

/**
 * 对应 KMP AppFeVersionManager.kt
 */
export class AppFeVersionManager {
  private static readonly VERSION_FILE_NAME = '/app/version.txt';
  private static readonly VERSION_KEY_PREFIX = 'app_fe_version_';
  private static readonly LAST_REQ_KEY_PREFIX = 'app_fe_version_last_req_';
  private static readonly PENDING_REFRESH_KEY_PREFIX = 'app_fe_pending_refresh_';
  private static readonly REQUEST_TIMEOUT_MS = 1800;
  private static readonly MIN_REQUEST_INTERVAL_MS = 60 * 60 * 1000;

  /**
   * 启动时调用一次即可
   */
  static refreshOnAppLaunch(): void {
    (async () => {
      try {
        const origin = AppFeVersionManager.normalizeOrigin(WxpConfig.appFeUrl);
        if (!origin) return;
        const now = WxpDateTimeUtils.getTimestamp();
        const lastReqAt = AppFeVersionManager.getLastRequestAt(origin);
        if (now - lastReqAt < AppFeVersionManager.MIN_REQUEST_INTERVAL_MS) {
          return;
        }
        AppFeVersionManager.saveLastRequestAt(origin, now);

        const remoteVersion = await AppFeVersionManager.fetchRemoteVersion(origin);
        if (!remoteVersion) return;
        const localVersion = AppFeVersionManager.getLocalVersion(origin);
        if (!localVersion || localVersion !== remoteVersion) {
          AppFeVersionManager.saveLocalVersion(origin, remoteVersion);
          AppFeVersionManager.markPendingRefresh(origin, remoteVersion);
        }
      } catch (e) {
        WxpLogUtils.w('AppFeVersion', '刷新版本失败', e as Error);
      }
    })();
  }

  static appendVersionParam(url: string, version: string | null | undefined): string {
    if (!version || version.length === 0) {
      return url;
    }
    try {
      // 移除已有的 _appfev 参数后追加新版本
      let cleanUrl = url.replace(/[?&]_appfev=[^&]*/g, '').replace(/\?$/, '');
      const separator = cleanUrl.includes('?') ? '&' : '?';
      return `${cleanUrl}${separator}_appfev=${encodeURIComponent(version)}`;
    } catch {
      return url;
    }
  }

  static consumePendingRefreshVersion(url: string): string | null {
    const origin = AppFeVersionManager.normalizeOrigin(url);
    if (!origin) return null;
    const key = AppFeVersionManager.buildPendingRefreshKey(origin);
    const pendingVersion = WxpSaveService.getString(key, '');
    if (pendingVersion.length === 0) return null;
    WxpSaveService.setString(key, '');
    return pendingVersion;
  }

  private static async fetchRemoteVersion(origin: string): Promise<string | null> {
    try {
      const versionUrl = `${origin}${AppFeVersionManager.VERSION_FILE_NAME}?t=${WxpDateTimeUtils.getTimestamp()}`;
      const text = await WxpNetworkService.getText(versionUrl, {
        'Cache-Control': 'no-cache, no-store, max-age=0',
        'Pragma': 'no-cache',
      });
      const trimmed = text.trim();
      return trimmed.length > 0 ? trimmed : null;
    } catch (e) {
      WxpLogUtils.w('AppFeVersion', `请求version.txt失败,url=${origin}`, e as Error);
      return null;
    }
  }

  private static normalizeOrigin(url: string): string | null {
    try {
      const parsed = new uri.URI(url);
      const scheme = parsed.scheme;
      const host = parsed.host;
      if (!scheme || !host) return null;
      return `${scheme}://${host}`;
    } catch {
      return null;
    }
  }

  private static buildVersionKey(origin: string): string {
    return AppFeVersionManager.VERSION_KEY_PREFIX + origin;
  }

  private static buildLastReqKey(origin: string): string {
    return AppFeVersionManager.LAST_REQ_KEY_PREFIX + origin;
  }

  private static buildPendingRefreshKey(origin: string): string {
    return AppFeVersionManager.PENDING_REFRESH_KEY_PREFIX + origin;
  }

  private static getLocalVersion(origin: string): string | null {
    const v = WxpSaveService.getString(AppFeVersionManager.buildVersionKey(origin), '');
    return v.length > 0 ? v : null;
  }

  private static saveLocalVersion(origin: string, version: string): void {
    WxpSaveService.setString(AppFeVersionManager.buildVersionKey(origin), version);
  }

  private static getLastRequestAt(origin: string): number {
    const raw = WxpSaveService.getString(AppFeVersionManager.buildLastReqKey(origin), '');
    return parseInt(raw, 10) || 0;
  }

  private static saveLastRequestAt(origin: string, timestamp: number): void {
    WxpSaveService.setString(AppFeVersionManager.buildLastReqKey(origin), String(timestamp));
  }

  private static markPendingRefresh(origin: string, version: string): void {
    WxpSaveService.setString(AppFeVersionManager.buildPendingRefreshKey(origin), version);
  }
}
