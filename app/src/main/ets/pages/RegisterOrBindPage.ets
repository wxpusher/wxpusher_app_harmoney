import { router } from '@kit.ArkUI';
import {
  WxpRegisterOrBindPresenter,
  IWxpRegisterOrBindPresenter,
  WxpBindPageData,
  WxpBindPageDataUtils,
  WxpDialogUtils,
  WxpLoadingUtils,
  WxpToastUtils,
} from '@wxpusher/shared';
import { WxpWeixinOpenManager } from '../wxapi/WxpWeixinOpenManager';

interface PageParams {
  bindData?: string;
}

/**
 * 选择创建账号方式页面。
 * 对应 Android WxpRegisterOrBindActivity。
 */
@Entry
@Component
struct RegisterOrBindPage {
  // ─── 颜色常量（对齐 Android colors.xml） ──────────────────────
  private static readonly COLOR_PAGE_BG: string = '#FFFFFF';
  private static readonly COLOR_WECHAT_GREEN: string = '#07C160';
  private static readonly COLOR_WECHAT_GREEN_BG: string = '#1A07C160';
  private static readonly COLOR_ACCENT: string = '#B300B3';
  private static readonly COLOR_ACCENT_BG: string = '#FFFFFF';
  private static readonly COLOR_GRAY_CARD_BORDER: string = '#C7C7CC';
  private static readonly COLOR_BLACK_BTN_BG: string = '#333333';
  private static readonly COLOR_TEXT_PRIMARY: string = '#030303';
  private static readonly COLOR_TEXT_DESC: string = '#757575';
  private static readonly COLOR_DANGER: string = '#F44336';
  private static readonly COLOR_WHITE: string = '#FFFFFF';

  private presenter: WxpRegisterOrBindPresenter | null = null;
  private bindPageData: WxpBindPageData | null = null;
  @State private hasPhoneLogin: boolean = false;

  createPresenter(): IWxpRegisterOrBindPresenter {
    return new WxpRegisterOrBindPresenter(this);
  }

  aboutToAppear(): void {
    this.presenter = this.createPresenter() as WxpRegisterOrBindPresenter;
    const params = router.getParams() as PageParams | undefined;
    if (params?.bindData) {
      this.bindPageData = WxpBindPageDataUtils.fromJson(params.bindData);
    }
    this.hasPhoneLogin = this.bindPageData?.phoneLogin != null;
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
  }

  /** IWxpRegisterOrBindView.onGoMain — 登录/绑定成功后跳转主页 */
  onGoMain(): void {
    router.replaceUrl({ url: 'pages/MainPage' });
  }

  // ─── 交互：选项一 —— 微信一键绑定 ─────────────────────────────
  private onOptionOneClick(): void {
    WxpLoadingUtils.showLoading('微信授权中', true);
    WxpWeixinOpenManager.requestAuth(
      'snsapi_userinfo',
      'wechat_auth',
      (response, error) => {
        WxpLoadingUtils.dismissLoading();
        if (error !== null) {
          WxpToastUtils.showToast(error.message);
          return;
        }
        if (response !== null) {
          this.presenter?.weixinBind(response.code, this.bindPageData);
        }
      }
    );
  }

  // ─── 交互：选项二 —— 通过微信公众号绑定（仅手机登录） ────────
  private onOptionTwoClick(): void {
    const phoneLogin = this.bindPageData?.phoneLogin;
    if (!phoneLogin) {
      return;
    }
    router.pushUrl({
      url: 'pages/BindPage',
      params: {
        phone: phoneLogin.phone,
        verifyCode: phoneLogin.code,
        phoneVerifyCode: phoneLogin.phoneVerifyCode,
      },
    });
  }

  // ─── 交互：选项三 —— 创建全新账号（二次确认） ─────────────────
  private onOptionThreeClick(): void {
    WxpDialogUtils.showDialog({
      title: '确认创建新账号？',
      message:
        '创建新账号后，会和已有微信账号完全分开，不能和微信账号的数据一致，也不能收到微信的消息。\n\n强烈建议绑定微信创建账号（即使你之前没有用过微信账号也可以绑定）。',
      leftText: '取消',
      rightText: '确认创建',
      rightBlock: () => {
        this.presenter?.createAccount(this.bindPageData);
      },
    });
  }

  // ─── 子构建：顶部导航栏（对齐 Android：无返回按钮，仅显示标题） ─
  @Builder
  private buildTopBar() {
    Row() {
      Text('选择创建账号方式')
        .fontSize(18)
        .fontColor(RegisterOrBindPage.COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  // ─── 子构建：通用 badge（推荐 / 不推荐） ────────────────────
  @Builder
  private buildBadge(text: string, bgColor: string) {
    Text(text)
      .fontSize(12)
      .fontColor(RegisterOrBindPage.COLOR_WHITE)
      .fontWeight(FontWeight.Bold)
      .height(24)
      .padding({ left: 10, right: 10 })
      .backgroundColor(bgColor)
      .borderRadius(4)
      .textAlign(TextAlign.Center)
  }

  // ─── 子构建：选项一卡片（微信一键绑定，强烈推荐） ───────────
  @Builder
  private buildOptionOne() {
    Column() {
      Row() {
        Image($r('app.media.ic_weixin'))
          .width(40)
          .height(40)
          .objectFit(ImageFit.Contain)
        Column() {
          Row() {
            Text('微信一键绑定')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(RegisterOrBindPage.COLOR_TEXT_PRIMARY)
              .layoutWeight(1)
            this.buildBadge('强烈推荐', RegisterOrBindPage.COLOR_WECHAT_GREEN)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(
            '绑定到本设备的微信，与原WxPusher公众号绑定，和微信公众号数据一致。\n新用户，也推荐和微信绑定，方便以后通过微信接收消息。'
          )
            .fontSize(14)
            .fontColor(RegisterOrBindPage.COLOR_TEXT_DESC)
            .lineHeight(22)
            .margin({ top: 8 })
            .width('100%')
        }
        .layoutWeight(1)
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Button('打开微信一键绑定')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor(RegisterOrBindPage.COLOR_WHITE)
        .backgroundColor(RegisterOrBindPage.COLOR_WECHAT_GREEN)
        .borderRadius(6)
        .margin({ top: 16 })
        .type(ButtonType.Normal)
        .onClick(() => {
          this.onOptionOneClick();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(RegisterOrBindPage.COLOR_WECHAT_GREEN_BG)
    .borderRadius(8)
    .borderWidth(2)
    .borderColor(RegisterOrBindPage.COLOR_WECHAT_GREEN)
  }

  // ─── 子构建：选项二卡片（通过公众号绑定，仅手机登录） ───────
  @Builder
  private buildOptionTwo() {
    Column() {
      Row() {
        Image($r('app.media.ic_paperplane'))
          .width(40)
          .height(40)
          .fillColor(RegisterOrBindPage.COLOR_ACCENT)
        Column() {
          Text('通过微信公众号绑定')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(RegisterOrBindPage.COLOR_TEXT_PRIMARY)
            .width('100%')

          Text(
            '如果你要绑定的微信账号不是本设备登录的，你可以获取一个绑定码，发送给原WxPusher公众号进行绑定。'
          )
            .fontSize(14)
            .fontColor(RegisterOrBindPage.COLOR_TEXT_DESC)
            .lineHeight(22)
            .margin({ top: 8 })
            .width('100%')
        }
        .layoutWeight(1)
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Button('去通过公众号绑定')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor(RegisterOrBindPage.COLOR_WHITE)
        .backgroundColor(RegisterOrBindPage.COLOR_ACCENT)
        .borderRadius(6)
        .margin({ top: 16 })
        .type(ButtonType.Normal)
        .onClick(() => {
          this.onOptionTwoClick();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(RegisterOrBindPage.COLOR_ACCENT_BG)
    .borderRadius(8)
    .borderWidth(1)
    .borderColor(RegisterOrBindPage.COLOR_ACCENT)
  }

  // ─── 子构建：选项三卡片（创建全新账号，不推荐） ─────────────
  @Builder
  private buildOptionThree() {
    Column() {
      Row() {
        Image($r('app.media.ic_person'))
          .width(40)
          .height(40)
          .fillColor(RegisterOrBindPage.COLOR_TEXT_DESC)
        Column() {
          Row() {
            Text('创建全新账号')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(RegisterOrBindPage.COLOR_TEXT_PRIMARY)
              .layoutWeight(1)
            this.buildBadge('不推荐', RegisterOrBindPage.COLOR_DANGER)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(
            '创建全新的空白账号，和原来微信公众号没有任何关系，数据完全隔离，如果你不添加订阅，不会收到任何消息。'
          )
            .fontSize(14)
            .fontColor(RegisterOrBindPage.COLOR_TEXT_DESC)
            .lineHeight(22)
            .margin({ top: 8 })
            .width('100%')
        }
        .layoutWeight(1)
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Button('创建新的空白账号')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor(RegisterOrBindPage.COLOR_WHITE)
        .backgroundColor(RegisterOrBindPage.COLOR_BLACK_BTN_BG)
        .borderRadius(6)
        .margin({ top: 16 })
        .type(ButtonType.Normal)
        .onClick(() => {
          this.onOptionThreeClick();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(RegisterOrBindPage.COLOR_PAGE_BG)
    .borderRadius(8)
    .borderWidth(1)
    .borderColor(RegisterOrBindPage.COLOR_GRAY_CARD_BORDER)
  }

  build() {
    Column() {
      this.buildTopBar()

      Scroll() {
        Column() {
          // 描述文本
          Text('你还未注册，请绑定已有账号或者创建新账号')
            .fontSize(14)
            .fontColor(RegisterOrBindPage.COLOR_TEXT_DESC)
            .lineHeight(22)
            .width('100%')
            .textAlign(TextAlign.Center)

          // 选项一：微信一键绑定
          Column() {
            this.buildOptionOne()
          }
          .margin({ top: 24 })

          // 选项二：通过公众号绑定（仅手机登录）
          if (this.hasPhoneLogin) {
            Column() {
              this.buildOptionTwo()
            }
            .margin({ top: 20 })
          }

          // 选项三：创建全新账号
          Column() {
            this.buildOptionThree()
          }
          .margin({ top: 20 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 24, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(RegisterOrBindPage.COLOR_PAGE_BG)
  }
}
