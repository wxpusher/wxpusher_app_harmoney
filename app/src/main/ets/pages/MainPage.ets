import { MessageListTab } from './tabs/MessageListTab';
import { ProviderListTab } from './tabs/ProviderListTab';
import { ProfileTab } from './tabs/ProfileTab';
import { router } from '@kit.ArkUI';
import { WxpAppDataService, WxpSaveService } from '@wxpusher/shared';
import { USER_HAS_AGREEMENT_KEY } from '../common/WxpAppGateKeys';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();
  private hasCheckedGate: boolean = false;

  aboutToAppear(): void {
    if (this.hasCheckedGate) {
      return;
    }
    if (!WxpSaveService.getBoolean(USER_HAS_AGREEMENT_KEY, false)) {
      this.hasCheckedGate = true;
      router.replaceUrl({
        url: 'pages/UserAgreementPage',
        params: { force: true },
      });
      return;
    }
    const deviceToken = WxpAppDataService.getLoginInfo()?.deviceToken;
    if (!deviceToken) {
      this.hasCheckedGate = true;
      router.replaceUrl({ url: 'pages/LoginPage' });
      return;
    }
    this.hasCheckedGate = true;
  }

  @Builder
  tabBuilder(title: string, index: number, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? $r('app.color.wxp_brand') : $r('sys.color.font_secondary'))
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? $r('app.color.wxp_brand') : $r('sys.color.font_secondary'))
        .margin({ top: 2 })
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = index;
      this.tabsController.changeIndex(index);
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
      TabContent() {
        MessageListTab({ currentTabIndex: this.currentIndex })
      }
      .tabBar(this.tabBuilder('消息列表', 0, $r('app.media.ic_paperplane')))

      TabContent() {
        ProviderListTab({ currentTabIndex: this.currentIndex })
      }
      .tabBar(this.tabBuilder('消息市场', 1, $r('app.media.ic_cloud')))

      TabContent() {
        ProfileTab()
      }
      .tabBar(this.tabBuilder('我的', 2, $r('app.media.ic_person')))
    }
    .scrollable(false)
    .barHeight(56)
    .barBackgroundColor($r('sys.color.background_primary'))
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
