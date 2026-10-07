import { WxpApiService } from '../../api/WxpApiService';
import { WxpDateTimeUtils } from '../../base/common/WxpDateTimeUtils';
import { WxpDialogParams, WxpDialogUtils } from '../../base/common/WxpDialogUtils';
import { WxpLogUtils } from '../../base/common/WxpLogUtils';
import { WxpSaveService } from '../../base/common/WxpSaveService';
import { WxpToastUtils } from '../../base/common/WxpToastUtils';
import { WxpScopeUtils } from '../../base/common/WxpScopeUtils';
import { AppVersionCheckResp } from './AppVersionCheckResp';
import { WxpAppMarketNavigator } from './WxpAppMarketNavigator';

/**
 * 统一的 App 版本升级检测入口。对应 KMP WxpVersionCheckManager.kt
 *
 * - App 启动 / 从后台切前台时调用 onAppForeground 触发检测；
 * - 节流：默认 3 小时内只检测一次；只要接口返回成功（无论是否有更新）就记录本次检查时间；
 * - 发现新版本时统一弹窗（普通升级可取消 / 强制升级不可取消），点击「去升级」调 navigator.jumpToMarket；
 * - 鸿蒙无 TBS，统一弹窗提醒后跳转华为应用市场详情页。
 */
export class WxpVersionCheckManager {
  private static readonly TAG = 'VersionCheck';
  private static readonly KEY_LAST_CHECK_TS = 'app_version_last_check_ts';
  private static readonly THROTTLE_MILLIS = 3 * 60 * 60 * 1000;
  private static navigator: WxpAppMarketNavigator | null = null;

  static setNavigator(navigator: WxpAppMarketNavigator): void {
    WxpVersionCheckManager.navigator = navigator;
  }

  /**
   * @param force true 时绕过节流（用于 Profile 页手动点"软件更新"）
   */
  static onAppForeground(force: boolean = false): void {
    const now = WxpDateTimeUtils.getTimestamp();
    if (!force) {
      const last = WxpSaveService.getDouble(WxpVersionCheckManager.KEY_LAST_CHECK_TS, 0);
      if (now - last >= 0 && now - last < WxpVersionCheckManager.THROTTLE_MILLIS) {
        WxpLogUtils.d(WxpVersionCheckManager.TAG, `skip: throttled, last=${last} now=${now}`);
        return;
      }
    }

    WxpScopeUtils.runAtIOSuspend(async () => {
      const resp = await WxpApiService.checkAppVersion();
      if (!resp) {
        return;
      }
      // 只要接口检查成功，就记录本次检查时间，避免外部升级页关闭后再触发导致弹窗反复弹出。
      WxpSaveService.setDouble(WxpVersionCheckManager.KEY_LAST_CHECK_TS, now);
      if (!resp.hasUpdate) {
        if (force) {
          WxpToastUtils.showToast('已经是最新版本');
        }
        return;
      }
      // 鸿蒙无 TBS，统一弹窗提醒，点「去升级」跳转应用市场
      WxpVersionCheckManager.showUpdateDialog(resp);
    });
  }

  private static showUpdateDialog(resp: AppVersionCheckResp): void {
    const params: WxpDialogParams = {
      title: resp.title && resp.title.length > 0 ? resp.title : '发现新版本',
      message: resp.content,
      rightText: '去升级',
      rightBlock: () => {
        WxpVersionCheckManager.navigator?.jumpToMarket(resp.downloadUrl);
      },
    };
    if (resp.forceUpdate) {
      params.cancelable = false;
    } else {
      params.leftText = '稍后';
    }
    WxpDialogUtils.showDialog(params);
  }
}
