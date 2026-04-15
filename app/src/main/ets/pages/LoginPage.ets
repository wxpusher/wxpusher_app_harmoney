import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import BuildProfile from 'BuildProfile';
import {
  WxpLoginPresenter,
  IWxpLoginPresenter,
  WxpBindPageData,
  WxpBindPageDataUtils,
  WxpToastUtils,
} from '@wxpusher/shared';
import { WxpWeixinOpenManager } from '../wxapi/WxpWeixinOpenManager';

@Entry
@Component
struct LoginPage {
  private static readonly PRIVACY_AGREEMENT_URL: string =
    'https://wxpusher.zjiecode.com/admin/agreement/privacy-agreement.html';
  private static readonly USER_SERVICE_URL: string =
    'https://wxpusher.zjiecode.com/admin/agreement/user-service.html';
  @State phone: string = '';
  @State verifyCode: string = '';
  @State sendButtonText: string = '发送验证码';
  @State sendButtonLoading: boolean = false;
  @State showPhoneLogin: boolean = false;
  @State privacyChecked: boolean = false;
  private presenter: WxpLoginPresenter | null = null;

  onBackPress(): boolean {
    const ctx = AppStorage.get<common.UIAbilityContext>('abilityContext');
    ctx?.terminateSelf().catch(() => {});
    return true;
  }

  createPresenter(): IWxpLoginPresenter {
    return new WxpLoginPresenter(this);
  }

  aboutToAppear(): void {
    this.presenter = this.createPresenter() as WxpLoginPresenter;
    this.presenter.init();
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
  }

  onSendButtonText(msg: string, loading: boolean): void {
    this.sendButtonText = msg;
    this.sendButtonLoading = loading;
  }

  onGoBindOrCreateAccount(data: WxpBindPageData): void {
    router.pushUrl({
      url: 'pages/RegisterOrBindPage',
      params: { bindData: WxpBindPageDataUtils.toJson(data) },
    });
  }

  onGoMain(): void {
    router.replaceUrl({ url: 'pages/MainPage' });
  }

  private checkPrivacyAgree(run: () => void): void {
    if (!this.privacyChecked) {
      promptAction.showDialog({
        title: '请同意用户和隐私协议',
        message: '我已经阅读并且同意《用户和隐私协议》',
        buttons: [
          { text: '取消', color: '#888888' },
          { text: '同意协议', color: '#B300B3' },
        ],
      }).then((result) => {
        if (result.index === 1) {
          this.privacyChecked = true;
          run();
        }
      });
      return;
    }
    run();
  }

  private onWeixinLoginClick(): void {
    this.checkPrivacyAgree(() => {
      this.handleWeixinLogin();
    });
  }

  private openPrivacyAgreement(): void {
    router.pushUrl({
      url: 'pages/WebViewPage',
      params: { url: LoginPage.PRIVACY_AGREEMENT_URL },
    });
  }

  private openUserServiceAgreement(): void {
    router.pushUrl({
      url: 'pages/WebViewPage',
      params: { url: LoginPage.USER_SERVICE_URL },
    });
  }

  /**
   * 发起微信授权登录。
   * 对应 Android WxpLoginActivity.handleWeixinLogin()。
   */
  private handleWeixinLogin(): void {
    WxpWeixinOpenManager.requestAuth(
      'snsapi_userinfo',
      'wechat_auth',
      (response, error) => {
        if (error !== null) {
          WxpToastUtils.showToast(error.message);
          return;
        }
        this.presenter?.weixinLogin(response?.code ?? null);
      }
    );
  }

  build() {
    Scroll() {
      Column() {
        // 顶部弹性空间
        Column().layoutWeight(1)

        // 主体内容
        Column() {
          // 标题（测试包可点击进入测试面板）
          Text('用户登录')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })
            .onClick(() => {
              if (BuildProfile.DEBUG) {
                router.pushUrl({ url: 'pages/TestPanelPage' });
              }
            })

          // 副标题
          Text('首次登录自动注册')
            .fontSize(16)
            .fontColor('#888888')
            .margin({ bottom: 40 })

          // 登录区域
          Column() {
            // 手机登录区域（点击"使用手机号登录"后显示）
            if (this.showPhoneLogin) {
              Column() {
                // 手机号输入框
                TextInput({ placeholder: '手机号', text: this.phone })
                  .type(InputType.PhoneNumber)
                  .width('100%')
                  .height(52)
                  .borderRadius(12)
                  .borderWidth(1.5)
                  .borderColor($r('app.color.AccentColor'))
                  .maxLength(11)
                  .onChange((value: string) => {
                    this.phone = value;
                  })
                  .margin({ bottom: 16 })

                // 验证码行
                Row() {
                  TextInput({ placeholder: '验证码', text: this.verifyCode })
                    .type(InputType.Number)
                    .height(52)
                    .layoutWeight(1)
                    .borderRadius(12)
                    .borderWidth(1.5)
                    .borderColor($r('app.color.AccentColor'))
                    .maxLength(6)
                    .onChange((value: string) => {
                      this.verifyCode = value;
                    })

                  Button(this.sendButtonText)
                    .height(44)
                    .width(120)
                    .margin({ left: 12 })
                    .borderRadius(8)
                    .backgroundColor($r('app.color.AccentColor'))
                    .fontSize(14)
                    .enabled(!this.sendButtonLoading)
                    .onClick(() => {
                      this.presenter?.sendVerifyCode(this.phone);
                    })
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)

                // 登录按钮
                Button('登录')
                  .width('100%')
                  .height(44)
                  .margin({ top: 32 })
                  .borderRadius(8)
                  .backgroundColor($r('app.color.AccentColor'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .onClick(() => {
                    this.checkPrivacyAgree(() => {
                      this.presenter?.verifyCodeLogin(this.phone, this.verifyCode);
                    });
                  })
              }
              .width('100%')
            }

            // 微信一键登录（默认显示）
            if (!this.showPhoneLogin) {
              Row() {
                Image($r('app.media.ic_weixin_btn'))
                  .width(30)
                  .height(30)
                  .margin({ right: 8 })
                Text('微信一键登录')
                  .fontColor(Color.White)
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .height(44)
              .borderRadius(8)
              .backgroundColor('#07C160')
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.onWeixinLoginClick();
              })

              // 使用手机号登录
              Text('使用手机号登录')
                .fontSize(16)
                .fontColor($r('app.color.AccentColor'))
                .margin({ top: 15, bottom: 15 })
                .onClick(() => {
                  this.showPhoneLogin = true;
                })
            }
          }
          .width('100%')

          // 隐私协议区域
          Row() {
            Checkbox()
              .select(this.privacyChecked)
              .selectedColor($r('app.color.AccentColor'))
              .width(20)
              .height(20)
              .onChange((value: boolean) => {
                this.privacyChecked = value;
              })
            Text('同意《')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ left: 4 })
            Text('隐私协议')
              .fontSize(14)
              .fontColor($r('app.color.AccentColor'))
              .onClick(() => {
                this.openPrivacyAgreement();
              })
            Text('和')
              .fontSize(14)
              .fontColor('#666666')
            Text('用户协议')
              .fontSize(14)
              .fontColor($r('app.color.AccentColor'))
              .onClick(() => {
                this.openUserServiceAgreement();
              })
            Text('》')
              .fontSize(14)
              .fontColor('#666666')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 24 })

          // "其他登录方式"分割线（手机登录时显示微信图标）
          if (this.showPhoneLogin) {
            // 分割线
            Row() {
              Column()
                .height(1)
                .layoutWeight(1)
                .backgroundColor('#888888')
                .opacity(0.3)
              Text('其他登录方式')
                .fontSize(12)
                .fontColor('#888888')
                .padding({ left: 8, right: 8 })
              Column()
                .height(1)
                .layoutWeight(1)
                .backgroundColor('#888888')
                .opacity(0.3)
            }
            .width('100%')
            .margin({ top: 32, bottom: 32 })
            .alignItems(VerticalAlign.Center)

            // 微信登录图标
            Column() {
              Image($r('app.media.ic_weixin'))
                .width(48)
                .height(48)
              Text('微信登录')
                .fontSize(13)
                .margin({ top: 8 })
            }
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              this.onWeixinLoginClick();
            })
          }
        }
        .width('85%')
        .padding({ top: 32, bottom: 32 })

        // 底部弹性空间
        Column().layoutWeight(1)

        // 版权文字
        Text('© 2025 WxPusher')
          .fontSize(12)
          .fontColor('#888888')
          .margin({ bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .constraintSize({ minHeight: '100%' })
    }
    .width('100%')
    .height('100%')
  }
}
