import { router } from '@kit.ArkUI';
import {
  WxpAccountDetailPresenter,
  IWxpAccountDetailPresenter,
  WxpAppDataService,
  WxpMaskUtils,
  WxpToastUtils,
} from '@wxpusher/shared';
import { WxpWeixinOpenManager } from '../wxapi/WxpWeixinOpenManager';
import { WxpHuaweiAccountManager } from '../loginhuawei/WxpHuaweiAccountManager';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct AccountDetailPage {
  @State phone: string = '';
  @State weixinBind: boolean = false;
  @State appleBind: boolean = false;
  @State huaweiBind: boolean = false;
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
      this.huaweiBind = loginInfo.huaweiBind === true;
    }
  }

  onWeixinBindSuccess(): void {
    this.weixinBind = true;
    WxpToastUtils.showToast('微信绑定成功');
  }

  onAppleBindSuccess(): void {
    this.appleBind = true;
  }

  onHuaweiBindSuccess(): void {
    this.huaweiBind = true;
    WxpToastUtils.showToast('华为账号绑定成功');
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

  private handleBindHuaweiTap(): void {
    const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
    if (!ctx) {
      WxpToastUtils.showToast('华为登录初始化失败');
      return;
    }
    WxpHuaweiAccountManager.requestHuaweiAuth(ctx, (result, error) => {
      if (error !== null) {
        WxpToastUtils.showToast(error);
        return;
      }
      // result 与 error 均为 null 表示用户取消，静默处理
      if (result !== null) {
        this.presenter?.huaweiBind(result.idToken);
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
          .fillColor($r('sys.color.font_primary'))
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
              .fontColor($r('sys.color.font_secondary'))
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
              .fontColor(this.weixinBind ? $r('app.color.wxp_success') : $r('sys.color.font_secondary'))
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
                .fontColor($r('app.color.wxp_success'))
            }
            .width('100%')
            .height(52)
            .padding({ left: 16, right: 16 })
          }
        }

        // 华为账号（鸿蒙原生，支持登录后绑定）
        ListItem() {
          Row() {
            Stack() {
              Image($r('app.media.ic_huawei_btn'))
                .width(15)
                .height(15)
                .objectFit(ImageFit.Contain)
            }
            .width(22)
            .height(22)
            .borderRadius(5)
            .backgroundColor($r('app.color.wxp_huawei'))
            .margin({ right: 12 })
            Text('华为账号')
            Blank()
            Text(this.huaweiBind ? '已绑定' : '未绑定')
              .fontColor(this.huaweiBind ? $r('app.color.wxp_success') : $r('sys.color.font_secondary'))
            // 已绑定时不显示箭头，但用 Hidden 占位保留宽度，让「已绑定」右边距和上面「未绑定」对齐
            Image($r('app.media.ic_chevron_right'))
              .width(16)
              .height(16)
              .margin({ left: 4 })
              .visibility(this.huaweiBind ? Visibility.Hidden : Visibility.Visible)
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
        }
        .onClick(() => {
          if (!this.huaweiBind) {
            this.handleBindHuaweiTap();
          }
        })
      }
      .divider({ strokeWidth: 0.5, color: $r('sys.color.ohos_id_color_list_separator') })

      Blank()

      Button('退出登录')
        .width('85%')
        .height(48)
        .type(ButtonType.Capsule)
        .backgroundColor($r('app.color.wxp_danger'))
        .margin({ bottom: 16 })
        .onClick(() => {
          this.presenter?.logout();
        })

      Text('注销账号')
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .margin({ bottom: 40 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/RemoveAccountPage' });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }
}
