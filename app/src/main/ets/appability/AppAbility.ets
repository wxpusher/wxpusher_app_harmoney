import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { WxpWeixinOpenManager } from '../wxapi/WxpWeixinOpenManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import {
  WxpSaveService,
  WxpLogUtils,
  WxpConfig,
  WxpBaseInfoService,
  WxpAppPageService,
  WxpToastUtils,
  WxpDialogUtils,
  WxpAppDataService,
  AppFeVersionManager,
} from '@wxpusher/shared';
import { WxpSaveServiceImpl } from '../common/WxpSaveServiceImpl';
import { WxpLogUtilsImpl } from '../common/WxpLogUtilsImpl';
import { WxpBaseInfoServiceImpl } from '../common/WxpBaseInfoServiceImpl';
import { WxpToastUtilsImpl } from '../common/WxpToastUtilsImpl';
import { WxpDialogUtilsImpl } from '../common/WxpDialogUtilsImpl';
import { WxpAppPageServiceImpl } from '../common/WxpAppPageServiceImpl';
import { WxpPushManager } from '../push/WxpPushManager';

const DOMAIN = 0x0000;
const TAG = 'WxPusher';

export default class AppAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, 'AppAbility onCreate - start init chain');

    // 1. 初始化日志
    WxpLogUtils.setPlatformLog(new WxpLogUtilsImpl());

    // 2. 初始化存储
    const saveServiceImpl = new WxpSaveServiceImpl(this.context);
    WxpSaveService.setBackend(saveServiceImpl);
    WxpSaveService.init();

    // 3. 初始化配置
    WxpConfig.init();

    // 4. 初始化平台信息
    WxpBaseInfoService.init(new WxpBaseInfoServiceImpl());

    // 5. 初始化页面服务
    WxpAppPageService.init(new WxpAppPageServiceImpl());

    // 6. 初始化 Toast & Dialog
    WxpToastUtils.setBackend(new WxpToastUtilsImpl());
    WxpDialogUtils.setBackend(new WxpDialogUtilsImpl());

    // 7. 初始化数据服务
    WxpAppDataService.init();

    // 8. 启动 App-FE 版本检查
    AppFeVersionManager.refreshOnAppLaunch();

    // 9. 初始化微信 SDK（对应 Android WxPusherApplication.onCreate 中的 WxpWeixinOpenManager.init）
    WxpWeixinOpenManager.init(this.context);

    // 10. 处理微信回调（对应 Android WXEntryActivity.handleIntent）
    //     App 冷启动时 want 可能来自微信，需要在此处理
    WxpWeixinOpenManager.handleWant(want);

    // 11. 初始化 Push，传入 UIAbility 实例供 tokenUpdate 订阅使用
    WxpPushManager.init(this);

    // 12. 处理通知点击冷启动携带的 pushUrl（对应 Android 通知 Intent 中的 url 参数）
    AppAbility.handlePushWant(want);

    hilog.info(DOMAIN, TAG, 'AppAbility onCreate - init chain complete');
  }

  /**
   * App 在后台时被微信或通知点击唤起（对应 Android onNewIntent）。
   */
  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'Ability onNewWant');
    WxpWeixinOpenManager.setContext(this.context);
    WxpWeixinOpenManager.handleWant(want);
    // 处理通知点击热启动携带的 pushUrl
    AppAbility.handlePushWant(want);
  }

  /**
   * 读取 Want.parameters 中的 pushUrl，写入 AppStorage，
   * Index / MainPage 组件通过 @StorageProp('pendingPushUrl') 监听并跳转 WebView。
   */
  private static handlePushWant(want: Want): void {
    // 方式一：透传推送 WantAgent 传参（WxpPushExtensionAbility 发出的本地通知点击）
    const pushUrl = want.parameters?.['pushUrl'] as string | undefined;
    if (pushUrl && pushUrl.length > 0) {
      hilog.info(0x0000, TAG, `收到通知点击跳转 URL (parameters): ${pushUrl}`);
      AppStorage.setOrCreate<string>('pendingPushUrl', pushUrl);
      return;
    }
    // 方式二：notification push clickAction URI scheme（与 Android/iOS scheme 一致）
    // scheme: wxpusher://wxpusher.smjcco.com/message?url=<encoded>
    const uri = want.uri;
    if (uri && uri.startsWith('wxpusher://')) {
      try {
        const idx = uri.indexOf('?url=');
        if (idx >= 0) {
          const url = decodeURIComponent(uri.substring(idx + 5));
          if (url.length > 0) {
            hilog.info(0x0000, TAG, `收到通知点击跳转 URL (uri scheme): ${url}`);
            AppStorage.setOrCreate<string>('pendingPushUrl', url);
          }
        }
      } catch (_e) {
        hilog.warn(0x0000, TAG, `解析 URI scheme 失败: ${uri}`);
      }
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');
    // 将 UIAbilityContext 存入 AppStorage，供非 Entry 组件（如 MessageListTab）安全获取
    AppStorage.setOrCreate('abilityContext', this.context);
    windowStage.loadContent('pages/MainPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Content loaded successfully');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
