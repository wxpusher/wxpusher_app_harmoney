import { router } from '@kit.ArkUI';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  @Builder
  tabBuilder(title: string, index: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === index ? selectedImg : normalImg)
        .width(24)
        .height(24)
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#007AFF' : '#999999')
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
        MessageListTab()
      }
      .tabBar(this.tabBuilder('消息', 0, $r('app.media.startIcon'), $r('app.media.startIcon')))

      TabContent() {
        ProviderListTab()
      }
      .tabBar(this.tabBuilder('市场', 1, $r('app.media.startIcon'), $r('app.media.startIcon')))

      TabContent() {
        ProfileTab()
      }
      .tabBar(this.tabBuilder('我的', 2, $r('app.media.startIcon'), $r('app.media.startIcon')))
    }
    .scrollable(false)
    .barHeight(56)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}

@Component
struct MessageListTab {
  @State messageList: object[] = [];
  @State isRefreshing: boolean = false;

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('消息列表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Blank()

        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/ScanPage' });
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 消息列表区域
      Refresh({ refreshing: $$this.isRefreshing }) {
        Text('消息列表加载中...')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 100 })
      }
      .onRefreshing(() => {
        // 刷新逻辑由 Presenter 驱动
        this.isRefreshing = false;
      })
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct ProviderListTab {
  build() {
    Column() {
      Row() {
        Text('消息市场')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      // WebView 加载市场 H5
      Text('市场页面（WebView）')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 100 })
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct ProfileTab {
  build() {
    Column() {
      Row() {
        Text('我的')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      List() {
        ListItem() {
          Row() {
            Text('账号详情')
            Blank()
            Text('>')
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/AccountDetailPage' });
          })
        }

        ListItem() {
          Row() {
            Text('换绑手机号')
            Blank()
            Text('>')
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/ChangePhonePage' });
          })
        }

        ListItem() {
          Row() {
            Text('关于 WxPusher')
            Blank()
            Text('>')
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/WebViewPage',
              params: { url: 'https://wxpusher.zjiecode.com/docs' },
            });
          })
        }
      }
      .divider({ strokeWidth: 0.5, color: '#F0F0F0' })
    }
    .width('100%')
    .height('100%')
  }
}
