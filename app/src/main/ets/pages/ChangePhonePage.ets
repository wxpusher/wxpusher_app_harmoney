import { router } from '@kit.ArkUI';
import {
  WxpChangePhonePresenter,
  IWxpChangePhonePresenter,
} from '@wxpusher/shared';

@Entry
@Component
struct ChangePhonePage {
  @State phone: string = '';
  @State verifyCode: string = '';
  @State sendButtonText: string = '发送验证码';
  private presenter: WxpChangePhonePresenter | null = null;

  createPresenter(): IWxpChangePhonePresenter {
    return new WxpChangePhonePresenter(this);
  }

  aboutToAppear(): void {
    this.presenter = this.createPresenter() as WxpChangePhonePresenter;
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
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
        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
          .onClick(() => { router.back(); })
        Text('换绑手机号')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      TextInput({ placeholder: '请输入新手机号' })
        .type(InputType.PhoneNumber)
        .width('85%')
        .height(48)
        .margin({ top: 32 })
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
        .onClick(() => { this.presenter?.bindPhone(this.phone, this.verifyCode); })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
