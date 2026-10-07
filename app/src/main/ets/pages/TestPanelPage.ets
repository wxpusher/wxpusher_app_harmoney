import { promptAction, router } from '@kit.ArkUI';
import process from '@ohos.process';
import { WxpConfig } from '@wxpusher/shared';

const DEFAULT_HOST: string = 'https://wxpusher.zjiecode.com';
const DEFAULT_APP_FE_URL: string = 'https://wxpusher.zjiecode.com';
const DEFAULT_WS_URL: string = 'wss://wxpusher.zjiecode.com';

const TEST_HOST: string = 'http://wxpusher.test.zjiecode.com';
const TEST_APP_FE_URL: string = 'http://wxpusher.test.zjiecode.com';
const TEST_WS_URL: string = 'ws://wxpusher.test.zjiecode.com';

@Entry
@Component
struct TestPanelPage {
  @State hostSelected: string = 'prod';
  @State hostCustom: string = '';
  @State appFeSelected: string = 'prod';
  @State appFeCustom: string = '';
  @State wsSelected: string = 'prod';
  @State wsCustom: string = '';

  aboutToAppear(): void {
    const savedHost = WxpConfig.baseUrl;
    if (savedHost === DEFAULT_HOST) {
      this.hostSelected = 'prod';
    } else if (savedHost === TEST_HOST) {
      this.hostSelected = 'test';
    } else {
      this.hostSelected = 'custom';
      this.hostCustom = savedHost;
    }

    const savedAppFe = WxpConfig.appFeUrl;
    if (savedAppFe === DEFAULT_APP_FE_URL) {
      this.appFeSelected = 'prod';
    } else if (savedAppFe === TEST_APP_FE_URL) {
      this.appFeSelected = 'test';
    } else {
      this.appFeSelected = 'custom';
      this.appFeCustom = savedAppFe;
    }

    const savedWs = WxpConfig.wsUrl;
    if (savedWs === DEFAULT_WS_URL) {
      this.wsSelected = 'prod';
    } else if (savedWs === TEST_WS_URL) {
      this.wsSelected = 'test';
    } else {
      this.wsSelected = 'custom';
      this.wsCustom = savedWs;
    }
  }

  private saveSettings(): void {
    const selectedHost = this.hostSelected === 'prod' ? DEFAULT_HOST
      : this.hostSelected === 'test' ? TEST_HOST
      : this.hostCustom.trim();

    const selectedAppFe = this.appFeSelected === 'prod' ? DEFAULT_APP_FE_URL
      : this.appFeSelected === 'test' ? TEST_APP_FE_URL
      : this.appFeCustom.trim();

    const selectedWs = this.wsSelected === 'prod' ? DEFAULT_WS_URL
      : this.wsSelected === 'test' ? TEST_WS_URL
      : this.wsCustom.trim();

    if ((this.hostSelected === 'custom' && selectedHost.length === 0) ||
      (this.wsSelected === 'custom' && selectedWs.length === 0)) {
      promptAction.showToast({ message: '自定义配置不能为空' });
      return;
    }

    WxpConfig.saveBaseUrl(selectedHost);
    WxpConfig.saveWsUrl(selectedWs);
    WxpConfig.saveAppFeUrl(selectedAppFe);

    promptAction.showToast({ message: '配置已保存，重启后生效' });
    router.back();
    setTimeout(() => {
      process.exit(0);
    }, 1000);
  }

  @Builder
  SectionCard(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 8 })
  }

  @Builder
  HostSection() {
    this.SectionCard('API Host')
    Column() {
      Row() {
        Radio({ value: 'prod', group: 'hostGroup' })
          .radioStyle({ checkedBackgroundColor: $r('app.color.wxp_brand') })
          .checked(this.hostSelected === 'prod')
          .onChange((isChecked: boolean) => {
            if (isChecked) { this.hostSelected = 'prod'; }
          })
        Text(`生产环境（${DEFAULT_HOST}）`)
          .fontSize(14)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Row() {
        Radio({ value: 'test', group: 'hostGroup' })
          .radioStyle({ checkedBackgroundColor: $r('app.color.wxp_brand') })
          .checked(this.hostSelected === 'test')
          .onChange((isChecked: boolean) => {
            if (isChecked) { this.hostSelected = 'test'; }
          })
        Text(`测试环境（${TEST_HOST}）`)
          .fontSize(14)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Row() {
        Radio({ value: 'custom', group: 'hostGroup' })
          .radioStyle({ checkedBackgroundColor: $r('app.color.wxp_brand') })
          .checked(this.hostSelected === 'custom')
          .onChange((isChecked: boolean) => {
            if (isChecked) { this.hostSelected = 'custom'; }
          })
        Text('自定义')
          .fontSize(14)
          .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.hostSelected === 'custom') {
        TextInput({ placeholder: '请输入自定义 Host', text: this.hostCustom })
          .width('100%')
          .height(44)
          .margin({ top: 8 })
          .borderRadius(8)
          .borderWidth(1)
          .borderColor($r('app.color.wxp_brand'))
          .onChange((value: string) => {
            this.hostCustom = value;
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor($r('sys.color.comp_background_list_card'))
  }

  @Builder
  AppFeSection() {
    this.SectionCard('AppFe URL')
    Column() {
      Row() {
        Radio({ value: 'prod', group: 'appFeGroup' })
          .radioStyle({ checkedBackgroundColor: $r('app.color.wxp_brand') })
          .checked(this.appFeSelected === 'prod')
          .onChange((isChecked: boolean) => {
            if (isChecked) { this.appFeSelected = 'prod'; }
          })
        Text(`生产环境（${DEFAULT_APP_FE_URL}）`)
          .fontSize(14)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Row() {
        Radio({ value: 'test', group: 'appFeGroup' })
          .radioStyle({ checkedBackgroundColor: $r('app.color.wxp_brand') })
          .checked(this.appFeSelected === 'test')
          .onChange((isChecked: boolean) => {
            if (isChecked) { this.appFeSelected = 'test'; }
          })
        Text(`测试环境（${TEST_APP_FE_URL}）`)
          .fontSize(14)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Row() {
        Radio({ value: 'custom', group: 'appFeGroup' })
          .radioStyle({ checkedBackgroundColor: $r('app.color.wxp_brand') })
          .checked(this.appFeSelected === 'custom')
          .onChange((isChecked: boolean) => {
            if (isChecked) { this.appFeSelected = 'custom'; }
          })
        Text('自定义')
          .fontSize(14)
          .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.appFeSelected === 'custom') {
        TextInput({ placeholder: '请输入自定义 AppFe URL', text: this.appFeCustom })
          .width('100%')
          .height(44)
          .margin({ top: 8 })
          .borderRadius(8)
          .borderWidth(1)
          .borderColor($r('app.color.wxp_brand'))
          .onChange((value: string) => {
            this.appFeCustom = value;
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor($r('sys.color.comp_background_list_card'))
  }

  @Builder
  WsSection() {
    this.SectionCard('WS URL')
    Column() {
      Row() {
        Radio({ value: 'prod', group: 'wsGroup' })
          .radioStyle({ checkedBackgroundColor: $r('app.color.wxp_brand') })
          .checked(this.wsSelected === 'prod')
          .onChange((isChecked: boolean) => {
            if (isChecked) { this.wsSelected = 'prod'; }
          })
        Text(`生产环境（${DEFAULT_WS_URL}）`)
          .fontSize(14)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Row() {
        Radio({ value: 'test', group: 'wsGroup' })
          .radioStyle({ checkedBackgroundColor: $r('app.color.wxp_brand') })
          .checked(this.wsSelected === 'test')
          .onChange((isChecked: boolean) => {
            if (isChecked) { this.wsSelected = 'test'; }
          })
        Text(`测试环境（${TEST_WS_URL}）`)
          .fontSize(14)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })

      Row() {
        Radio({ value: 'custom', group: 'wsGroup' })
          .radioStyle({ checkedBackgroundColor: $r('app.color.wxp_brand') })
          .checked(this.wsSelected === 'custom')
          .onChange((isChecked: boolean) => {
            if (isChecked) { this.wsSelected = 'custom'; }
          })
        Text('自定义')
          .fontSize(14)
          .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.wsSelected === 'custom') {
        TextInput({ placeholder: '请输入自定义 WS URL', text: this.wsCustom })
          .width('100%')
          .height(44)
          .margin({ top: 8 })
          .borderRadius(8)
          .borderWidth(1)
          .borderColor($r('app.color.wxp_brand'))
          .onChange((value: string) => {
            this.wsCustom = value;
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor($r('sys.color.comp_background_list_card'))
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
        Text('测试面板')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      Divider().color($r('sys.color.ohos_id_color_list_separator'))

      Scroll() {
        Column() {
          this.HostSection()
          this.AppFeSection()
          this.WsSection()

          Button('保存并重启')
            .width('90%')
            .height(48)
            .margin({ top: 32, bottom: 32 })
            .borderRadius(8)
            .backgroundColor($r('app.color.wxp_brand'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .onClick(() => {
              this.saveSettings();
            })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .backgroundColor($r('sys.color.background_secondary'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
