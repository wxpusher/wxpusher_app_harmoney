import { router } from '@kit.ArkUI';
import { WxpDialogUtils, WxpSaveService } from '@wxpusher/shared';
import { WxpJumpPageUtils } from '../common/WxpJumpPageUtils';
import { USER_HAS_AGREEMENT_KEY } from '../common/WxpAppGateKeys';

interface UserAgreementPageParams {
  force?: boolean;
}

@Entry
@Component
struct UserAgreementPage {
  private static readonly PRIVACY_AGREEMENT_URL: string =
    'https://wxpusher.zjiecode.com/admin/agreement/privacy-agreement.html';
  private static readonly USER_SERVICE_URL: string =
    'https://wxpusher.zjiecode.com/admin/agreement/user-service.html';
  @State private forceAgree: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as UserAgreementPageParams | undefined;
    this.forceAgree = params?.force === true;
  }

  onBackPress(): boolean {
    return this.forceAgree;
  }

  private openPrivacyAgreement(): void {
    WxpJumpPageUtils.jumpToWebUrl(UserAgreementPage.PRIVACY_AGREEMENT_URL);
  }

  private openUserServiceAgreement(): void {
    WxpJumpPageUtils.jumpToWebUrl(UserAgreementPage.USER_SERVICE_URL);
  }

  private async onAgreeClicked(): Promise<void> {
    WxpSaveService.setBoolean(USER_HAS_AGREEMENT_KEY, true);
    await WxpJumpPageUtils.requestNotificationPermission();
    router.replaceUrl({ url: 'pages/MainPage' });
  }

  private onDisagreeClicked(): void {
    WxpDialogUtils.showDialog({
      title: '',
      message: 'WxPusher需要你同意用户和隐私协议，我们才能获取到相关设备信息，才能实现消息推送的功能，如您不同意，软件无法正常工作。您是否同意相关协议？',
      leftText: '取消',
      rightText: '同意',
      rightBlock: () => {
        void this.onAgreeClicked();
      },
    });
  }

  build() {
    Column() {
      if (!this.forceAgree) {
        Row() {
          Image($r('app.media.ic_chevron_left'))
            .width(24)
            .height(24)
            .fillColor('#333333')
            .onClick(() => { router.back(); })
          Text('用户协议与隐私政策')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 12 })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16 })
        .alignItems(VerticalAlign.Center)
      }

      Scroll() {
        Column() {
          Text('用户协议与隐私政策')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 24 })

          Text() {
            Span('欢迎使用WxPusher！在使用我们的服务前，请您仔细阅读并同意以下协议：\n\n')
            Span('我们非常重视您的个人信息和隐私保护。为了更好地保障您的权益，请您认真阅读《')
            Span('用户协议')
              .fontColor($r('app.color.AccentColor'))
              .decoration({ type: TextDecorationType.Underline })
              .onClick(() => { this.openUserServiceAgreement(); })
            Span('》和《')
            Span('隐私政策')
              .fontColor($r('app.color.AccentColor'))
              .decoration({ type: TextDecorationType.Underline })
              .onClick(() => { this.openPrivacyAgreement(); })
            Span('》的全部内容，同意并接受全部条款后开始使用我们的产品和服务。\n\n')
            Span('1. 我们会收集您的设备信息、用于向您提供消息推送服务；\n')
            Span('2. 我们可能会记录程序日志，用于问题排查；')
          }
          .fontSize(16)
          .lineHeight(28)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')
          .margin({ top: 24 })
        }
        .width('100%')
        .padding({ left: 24, right: 24, bottom: 24 })
      }
      .layoutWeight(1)
      .width('100%')

      Column() {
        Button('同意并继续')
          .width('100%')
          .height(48)
          .borderRadius(8)
          .backgroundColor($r('app.color.AccentColor'))
          .fontSize(16)
          .fontColor(Color.White)
          .onClick(() => {
            void this.onAgreeClicked();
          })

        Button('不同意')
          .width('100%')
          .height(48)
          .margin({ top: 12 })
          .borderRadius(8)
          .backgroundColor(Color.White)
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
          .onClick(() => {
            this.onDisagreeClicked();
          })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 12, bottom: 24 })
      .backgroundColor($r('sys.color.background_primary'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }
}
