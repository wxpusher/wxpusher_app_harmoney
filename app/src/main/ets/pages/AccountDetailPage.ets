import { router } from '@kit.ArkUI';
import {
  WxpAccountDetailPresenter,
  IWxpAccountDetailPresenter,
  WxpAppDataService,
  WxpMaskUtils,
  WxpToastUtils,
} from '@wxpusher/shared';
import { WxpWeixinOpenManager } from '../wxapi/WxpWeixinOpenManager';

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
    this.setupData();
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
  }

  onPageShow(): void {
    // Refresh data when returning from other pages (e.g. change phone)
    this.setupData();
  }

  private setupData(): void {
    const loginInfo = WxpAppDataService.getLoginInfo();
    if (loginInfo) {
      this.phone = loginInfo.phone ? WxpMaskUtils.mask(loginInfo.phone, 3, 4) : '未绑定';
      this.weixinBind = loginInfo.weiXinBind === true;
      this.appleBind = loginInfo.appleBind === true;
    }
  }

  onWeixinBindSuccess(): void {
    this.weixinBind = true;
    WxpToastUtils.showToast('微信绑定成功');
  }

  onAppleBindSuccess(): void {
    this.appleBind = true;
  }

  private handleBindWeixinTap(): void {
    WxpWeixinOpenManager.requestAuth('snsapi_userinfo', 'wechat_auth', (response, error) => {
      if (error !== null) {
        WxpToastUtils.showToast(`微信授权失败: ${error.message}`);
        return;
      }
      if (response !== null) {
        this.presenter?.weixinBind(response.code);
      }
    });
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Image($r('app.media.ic_chevron_left'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .onClick(() => { router.back(); })
        Text('账号信息')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      List() {
        // 手机账号
        ListItem() {
          Row() {
            Image($r('app.media.ic_person'))
              .width(20)
              .height(20)
              .margin({ right: 12 })
            Text('手机账号')
            Blank()
            Text(this.phone)
              .fontColor('#999999')
            Image($r('app.media.ic_chevron_right'))
              .width(16)
              .height(16)
              .margin({ left: 4 })
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
        }
        .onClick(() => {
          router.pushUrl({ url: 'pages/ChangePhonePage' });
        })

        // 微信绑定
        ListItem() {
          Row() {
            Image($r('app.media.ic_weixin'))
              .width(20)
              .height(20)
              .margin({ right: 12 })
            Text('微信绑定')
            Blank()
            Text(this.weixinBind ? '已绑定' : '未绑定')
              .fontColor(this.weixinBind ? '#4CAF50' : '#999999')
            if (!this.weixinBind) {
              Image($r('app.media.ic_chevron_right'))
                .width(16)
                .height(16)
                .margin({ left: 4 })
            }
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
        }
        .onClick(() => {
          if (!this.weixinBind) {
            this.handleBindWeixinTap();
          }
        })

        // Apple账号（仅在已绑定时显示）
        if (this.appleBind) {
          ListItem() {
            Row() {
              Image($r('app.media.ic_cloud'))
                .width(20)
                .height(20)
                .margin({ right: 12 })
              Text('Apple账号')
              Blank()
              Text('已绑定')
                .fontColor('#4CAF50')
            }
            .width('100%')
            .height(52)
            .padding({ left: 16, right: 16 })
          }
        }
      }
      .divider({ strokeWidth: 0.5, color: '#F0F0F0' })

      Blank()

      Button('退出登录')
        .width('85%')
        .height(48)
        .type(ButtonType.Capsule)
        .backgroundColor('#FF3B30')
        .margin({ bottom: 16 })
        .onClick(() => {
          this.presenter?.logout();
        })

      Text('注销账号')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ bottom: 40 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/RemoveAccountPage' });
        })
    }
    .width('100%')
    .height('100%')
  }
}
