import { router } from '@kit.ArkUI';
import {
  WxpBindPresenter,
  IWxpBindPresenter,
} from '@wxpusher/shared';

interface BindPageParams {
  phone?: string;
  verifyCode?: string;
}

@Entry
@Component
struct BindPage {
  @State isLoading: boolean = false;
  private presenter: WxpBindPresenter | null = null;
  private phone: string = '';
  private verifyCode: string = '';

  createPresenter(): IWxpBindPresenter {
    return new WxpBindPresenter(this);
  }

  aboutToAppear(): void {
    this.presenter = this.createPresenter() as WxpBindPresenter;
    const params = router.getParams() as BindPageParams;
    this.phone = params?.phone ?? '';
    this.verifyCode = params?.verifyCode ?? '';
    this.presenter.queryBindStatus(this.phone, this.verifyCode);
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
  }

  onGoMain(): void {
    router.replaceUrl({ url: 'pages/MainPage' });
  }

  showLoading(show: boolean): void {
    this.isLoading = show;
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
          .onClick(() => { router.back(); })
        Text('绑定账号')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      if (this.isLoading) {
        LoadingProgress()
          .width(48)
          .height(48)
          .margin({ top: 100 })
      } else {
        Text('请在微信公众号中完成绑定操作后返回此页面')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 60, left: 16, right: 16 })
          .textAlign(TextAlign.Center)

        Button('我已绑定，查询状态')
          .width('85%')
          .height(48)
          .margin({ top: 32 })
          .type(ButtonType.Capsule)
          .onClick(() => {
            this.presenter?.queryBindStatus(this.phone, this.verifyCode);
          })
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
