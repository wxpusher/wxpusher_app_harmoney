import { router } from '@kit.ArkUI';
import {
  WxpRegisterOrBindPresenter,
  IWxpRegisterOrBindPresenter,
  WxpBindPageData,
  WxpBindPageDataUtils,
} from '@wxpusher/shared';

interface PageParams {
  bindData?: string;
}

@Entry
@Component
struct RegisterOrBindPage {
  private presenter: WxpRegisterOrBindPresenter | null = null;
  private bindPageData: WxpBindPageData | null = null;

  createPresenter(): IWxpRegisterOrBindPresenter {
    return new WxpRegisterOrBindPresenter(this);
  }

  aboutToAppear(): void {
    this.presenter = this.createPresenter() as WxpRegisterOrBindPresenter;
    const params = router.getParams() as PageParams;
    if (params?.bindData) {
      this.bindPageData = WxpBindPageDataUtils.fromJson(params.bindData);
    }
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
  }

  onGoMain(): void {
    router.replaceUrl({ url: 'pages/MainPage' });
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
          .onClick(() => { router.back(); })
        Text('选择注册方式')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      Text('您的手机号尚未注册，请选择一种方式创建账号')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 40, left: 16, right: 16 })
        .textAlign(TextAlign.Center)

      Button('直接创建新账号')
        .width('85%')
        .height(48)
        .margin({ top: 40 })
        .type(ButtonType.Capsule)
        .onClick(() => {
          this.presenter?.createAccount(this.bindPageData);
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
