import { pushService } from '@kit.PushKit';
import { UIAbility } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { WxpAppDataService, WxpLogUtils, WxpPlatformEnum } from '@wxpusher/shared';

const TAG = 'WxpPushManager';

/**
 * HarmonyOS Push 管理器。
 *
 * HarmonyOS 与 Android 的关键差异：
 *   - Android：HmsInstanceId.getToken(appId, "HCM") 需要传 AppID
 *   - HarmonyOS：pushService.getToken() 直接调用，系统通过 bundle 自动识别应用
 *
 *   - Android：token 刷新由 HuaweiHmsMessageService.onNewToken() 回调
 *   - HarmonyOS：token 刷新通过 pushService.on('tokenUpdate', ability, callback) 订阅，
 *               需在 UIAbility 中调用（PushExtensionAbility 无此回调）
 *
 * 使用方式：在 AppAbility.onCreate 中调用 WxpPushManager.init(this)。
 */
export class WxpPushManager {

  /**
   * 在 AppAbility.onCreate 中调用，传入 UIAbility 实例。
   *
   * 步骤：
   *   1. pushService.getToken()          — 获取当前 push token 并上报
   *   2. pushService.on('tokenUpdate')   — 订阅 token 刷新，刷新后重新上报
   */
  static init(ability: UIAbility): void {
    // 1. 获取当前 push token
    WxpLogUtils.i(TAG, '开始获取 HarmonyOS Push Token');
    pushService.getToken().then((token: string) => {
      if (!token || token.length === 0) {
        WxpLogUtils.w(TAG, '获取 Push Token 成功但为空，忽略');
        return;
      }
      WxpLogUtils.i(TAG, `获取 Push Token 成功: token=${token}`);
      WxpPushManager.onGetPushToken(token);
    }).catch((err: BusinessError) => {
      WxpLogUtils.e(TAG, `获取 Push Token 失败: code=${err.code}, message=${err.message}`, err as Error);
    });

    // 2. 订阅 token 刷新事件（HarmonyOS 特有，替代 Android onNewToken 回调）
    pushService.on('tokenUpdate', ability, (newToken: string) => {
      if (!newToken || newToken.length === 0) {
        WxpLogUtils.w(TAG, 'tokenUpdate: 新 token 为空，忽略');
        return;
      }
      WxpLogUtils.i(TAG, `tokenUpdate: Push Token 已刷新: token=${newToken}`);
      WxpPushManager.onGetPushToken(newToken);
    });
  }

  /**
   * 保存 token 并上报设备信息到服务器。
   */
  private static onGetPushToken(token: string): void {
    WxpAppDataService.savePushToken(token);
    WxpAppDataService.updateDeviceInfo(WxpPlatformEnum.HarmonyOS);
  }
}
