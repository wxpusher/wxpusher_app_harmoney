import { router } from '@kit.ArkUI';
import {
  WxpChangePhonePresenter,
  IWxpChangePhonePresenter,
  WxpAppDataService,
  WxpMaskUtils,
} from '@wxpusher/shared';

@Entry
@Component
struct ChangePhonePage {
  @State currentPhone: string = '';
  @State phone: string = '';
  @State verifyCode: string = '';
  @State sendButtonText: string = '发送验证码';
  private presenter: WxpChangePhonePresenter | null = null;

  createPresenter(): IWxpChangePhonePresenter {
    return new WxpChangePhonePresenter(this);
  }

  aboutToAppear(): void {
    this.presenter = this.createPresenter() as WxpChangePhonePresenter;
    this.initData();
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
  }

  private initData(): void {
    const loginInfo = WxpAppDataService.getLoginInfo();
    const phone = loginInfo?.phone;
    if (phone && phone.length > 0) {
      this.currentPhone = `当前绑定手机号: ${WxpMaskUtils.mask(phone, 3, 4)}`;
    }
  }

  onSendButtonText(msg: string): void {
    this.sendButtonText = msg;
  }

  onChangPhoneFinish(): void {
    router.back();
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_chevron_left'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.font_primary'))
          .onClick(() => { router.back(); })
        Text('换绑手机')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      if (this.currentPhone.length > 0) {
        Text(this.currentPhone)
          .fontSize(14)
          .fontColor($r('sys.color.font_secondary'))
          .width('85%')
          .margin({ top: 24, bottom: 8 })
      }

      TextInput({ placeholder: '请输入新手机号' })
        .type(InputType.PhoneNumber)
        .width('85%')
        .height(48)
        .margin({ top: this.currentPhone.length > 0 ? 0 : 32 })
        .onChange((value: string) => { this.phone = value; })

      Row() {
        TextInput({ placeholder: '请输入验证码' })
          .type(InputType.Number)
          .width('55%')
          .height(48)
          .onChange((value: string) => { this.verifyCode = value; })

        Button(this.sendButtonText)
          .width('28%')
          .height(48)
          .margin({ left: 8 })
          .backgroundColor($r('app.color.wxp_brand'))
          .onClick(() => { this.presenter?.sendVerifyCode(this.phone); })
      }
      .width('85%')
      .margin({ top: 16 })
      .justifyContent(FlexAlign.SpaceBetween)

      Button('确认绑定')
        .width('85%')
        .height(48)
        .margin({ top: 32 })
        .type(ButtonType.Capsule)
        .backgroundColor($r('app.color.wxp_brand'))
        .onClick(() => { this.presenter?.bindPhone(this.phone, this.verifyCode); })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('sys.color.background_primary'))
  }
}
