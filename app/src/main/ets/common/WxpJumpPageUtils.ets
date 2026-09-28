import { common } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { router } from '@kit.ArkUI';
import { WxpToastUtils } from '@wxpusher/shared';

/**
 * 页面跳转 & 系统设置工具类（对齐 Android WxpJumpPageUtils）
 */
export class WxpJumpPageUtils {

  /**
   * 打开系统通知设置页面（对齐 Android jumpToSystemNotificationSettingPage）
   * 用于用户手动关闭通知权限后引导其重新开启。
   */
  static openNotificationSettings(): void {
    const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
    if (!ctx) {
      WxpToastUtils.showToast('无法打开通知设置');
      return;
    }
    try {
      notificationManager.openNotificationSettings(ctx).catch(() => {
        WxpToastUtils.showToast('无法打开通知设置');
      });
    } catch {
      WxpToastUtils.showToast('无法打开通知设置');
    }
  }

  /**
   * 请求通知权限；若权限已被手动关闭则直接跳转系统通知设置。
   * （对齐 Android checkNotificationPermission + jumpToSystemNotificationSettingPage）
   */
  static async requestNotificationPermission(): Promise<void> {
    const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
    if (!ctx) {
      WxpJumpPageUtils.openNotificationSettings();
      return;
    }
    try {
      await notificationManager.requestEnableNotification(ctx);
      // resolve 后再次验证：用户手动关闭权限时 API 可能静默 resolve 而不弹对话框
      const enabled = await notificationManager.isNotificationEnabled();
      if (!enabled) {
        WxpJumpPageUtils.openNotificationSettings();
      }
    } catch {
      // 错误码 1600004：权限已被手动拒绝，系统不再弹对话框，直接跳设置
      WxpJumpPageUtils.openNotificationSettings();
    }
  }

  /**
   * 跳转到 WebView 页面
   */
  static jumpToWebUrl(url: string): void {
    router.pushUrl({
      url: 'pages/WebViewPage',
      params: { url },
    });
  }

  /**
   * 交给系统打开非 http 链接（如 weixin://），可能拉起外部 App（对齐 Android openExternalUri）。
   * API 12 起隐式 startAbility 不允许跳转第三方应用（错误码 16000018），所以用 openLink。
   * 找不到能打开的 App 时不弹系统提示框，由 onFail 处理。
   */
  static openExternalUrl(url: string, onFail: () => void): void {
    const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
    if (!ctx) {
      onFail();
      return;
    }
    try {
      ctx.openLink(url, { appLinkingOnly: false, hideFailureTipDialog: true }).catch(() => {
        onFail();
      });
    } catch {
      onFail();
    }
  }
}
