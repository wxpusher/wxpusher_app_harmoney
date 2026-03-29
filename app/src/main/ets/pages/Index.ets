import { router } from '@kit.ArkUI';
import { WxpAppDataService } from '@wxpusher/shared';

/**
 * 启动页 - 检查登录状态后跳转
 */
@Entry
@Component
struct Index {
  aboutToAppear(): void {
    const loginInfo = WxpAppDataService.getLoginInfo();
    if (loginInfo && loginInfo.deviceToken) {
      router.replaceUrl({ url: 'pages/MainPage' });
    } else {
      router.replaceUrl({ url: 'pages/LoginPage' });
    }
  }

  build() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
