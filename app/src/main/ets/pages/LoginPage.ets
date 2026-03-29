import { router } from '@kit.ArkUI';
import {
  WxpLoginPresenter,
  IWxpLoginPresenter,
  WxpBindPageData,
  WxpBindPageDataUtils,
} from '@wxpusher/shared';

@Entry
@Component
struct LoginPage {
  @State phone: string = '';
  @State verifyCode: string = '';
  @State sendButtonText: string = '发送验证码';
  @State sendButtonLoading: boolean = false;
  private presenter: WxpLoginPresenter | null = null;

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

  build() {
    Column() {
      Text('WxPusher')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 60 })

      TextInput({ placeholder: '请输入手机号', text: this.phone })
        .type(InputType.PhoneNumber)
        .width('85%')
        .height(48)
        .margin({ bottom: 16 })
        .onChange((value: string) => {
          this.phone = value;
        })

      Row() {
        TextInput({ placeholder: '请输入验证码', text: this.verifyCode })
          .type(InputType.Number)
          .width('55%')
          .height(48)
          .onChange((value: string) => {
            this.verifyCode = value;
          })

        Button(this.sendButtonText)
          .width('28%')
          .height(48)
          .margin({ left: 8 })
          .enabled(!this.sendButtonLoading)
          .onClick(() => {
            this.presenter?.sendVerifyCode(this.phone);
          })
      }
      .width('85%')
      .justifyContent(FlexAlign.SpaceBetween)

      Button('登录')
        .width('85%')
        .height(48)
        .margin({ top: 32 })
        .type(ButtonType.Capsule)
        .onClick(() => {
          this.presenter?.verifyCodeLogin(this.phone, this.verifyCode);
        })

      Text('登录即同意《隐私政策》和《用户协议》')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 24 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/UserAgreementPage' });
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
