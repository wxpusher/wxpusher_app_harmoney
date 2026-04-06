import { MessageListTab } from './tabs/MessageListTab';
import { ProviderListTab } from './tabs/ProviderListTab';
import { ProfileTab } from './tabs/ProfileTab';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  @Builder
  tabBuilder(title: string, index: number, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? '#B300B3' : '#999999')
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#B300B3' : '#999999')
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
        ProviderListTab()
      }
      .tabBar(this.tabBuilder('消息市场', 1, $r('app.media.ic_cloud')))

      TabContent() {
        ProfileTab()
      }
      .tabBar(this.tabBuilder('我的', 2, $r('app.media.ic_person')))
    }
    .scrollable(false)
    .barHeight(56)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
