import { router } from '@kit.ArkUI';
import {
  WxpAccountDetailPresenter,
  IWxpAccountDetailPresenter,
  WxpAppDataService,
  WxpMaskUtils,
} from '@wxpusher/shared';

@Entry
@Component
struct AccountDetailPage {
  @State phone: string = '';
  @State weixinBind: boolean = false;
  @State appleBind: boolean = false;
  private presenter: WxpAccountDetailPresenter | null = null;

  createPresenter(): IWxpAccountDetailPresenter {
    return new WxpAccountDetailPresenter(this);
  }

  aboutToAppear(): void {
    this.presenter = this.createPresenter() as WxpAccountDetailPresenter;
    const loginInfo = WxpAppDataService.getLoginInfo();
    if (loginInfo) {
      this.phone = loginInfo.phone ? WxpMaskUtils.mask(loginInfo.phone, 3, 4) : '未绑定';
      this.weixinBind = loginInfo.weiXinBind === true;
      this.appleBind = loginInfo.appleBind === true;
    }
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
  }

  onWeixinBindSuccess(): void {
    this.weixinBind = true;
  }

  onAppleBindSuccess(): void {
    this.appleBind = true;
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
          .onClick(() => { router.back(); })
        Text('账号详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      List() {
        ListItem() {
          Row() {
            Text('手机号')
            Blank()
            Text(this.phone)
              .fontColor('#999999')
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
        }

        ListItem() {
          Row() {
            Text('微信')
            Blank()
            Text(this.weixinBind ? '已绑定' : '未绑定')
              .fontColor(this.weixinBind ? '#4CAF50' : '#999999')
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
        }

        ListItem() {
          Row() {
            Text('注销账号')
            Blank()
            Text('>')
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/RemoveAccountPage' });
          })
        }
      }
      .divider({ strokeWidth: 0.5, color: '#F0F0F0' })

      Blank()

      Button('退出登录')
        .width('85%')
        .height(48)
        .type(ButtonType.Capsule)
        .backgroundColor('#FF3B30')
        .margin({ bottom: 40 })
        .onClick(() => {
          this.presenter?.logout();
        })
    }
    .width('100%')
    .height('100%')
  }
}
