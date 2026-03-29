import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
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

    hilog.info(DOMAIN, TAG, 'AppAbility onCreate - init chain complete');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
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
