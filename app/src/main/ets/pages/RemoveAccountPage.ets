import { router } from '@kit.ArkUI';
import {
  WxpAppDataService,
  WxpDialogUtils,
  WxpDialogParams,
} from '@wxpusher/shared';

const REQUIRED_TEXT = '删除账号';

@Entry
@Component
struct RemoveAccountPage {
  @State inputText: string = '';
  @State isValid: boolean = false;

  private checkInput(text: string): void {
    this.inputText = text;
    this.isValid = text.trim() === REQUIRED_TEXT;
  }

  private showConfirmDialog(): void {
    const params: WxpDialogParams = {
      title: '最后一次提示',
      message: '删除后账号将无法使用，并且删除所有数据，无法进行找回，点击确认后，立即删除账号，是否继续？',
      leftText: '取消',
      rightText: '确认删除',
      rightBlock: () => {
        WxpAppDataService.removeAccount();
      },
    };
    WxpDialogUtils.showDialog(params);
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
        Text('删除账号')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      // 警告图标 + 提示文案
      Image($r('app.media.ic_warning'))
        .width(48)
        .height(48)
        .margin({ top: 32, bottom: 16 })

      Text('此操作将永久删除您的账号')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      Text('删除后账号将无法使用，所有数据将被清除且无法找回。')
        .fontSize(14)
        .fontColor('#666666')
        .width('85%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 40 })

      // 输入区域
      Text(`请在下方输入"${REQUIRED_TEXT}"以确认`)
        .fontSize(14)
        .fontColor('#666666')
        .width('85%')
        .margin({ bottom: 12 })

      TextInput({ placeholder: `请输入"${REQUIRED_TEXT}"` })
        .width('85%')
        .height(48)
        .border({
          width: 1,
          color: this.inputText.length === 0
            ? '#DDDDDD'
            : (this.isValid ? '#4CAF50' : '#FF3B30'),
          radius: 8,
        })
        .onChange((value: string) => { this.checkInput(value); })

      Blank()

      // 确认按钮
      Button('确认删除')
        .width('85%')
        .height(48)
        .type(ButtonType.Capsule)
        .backgroundColor(this.isValid ? '#FF3B30' : '#CCCCCC')
        .fontColor(Color.White)
        .enabled(this.isValid)
        .margin({ bottom: 40 })
        .onClick(() => { this.showConfirmDialog(); })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
