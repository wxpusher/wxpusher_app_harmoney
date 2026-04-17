import { router } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import {
  WxpBindPresenter,
  IWxpBindPresenter,
  WxpToastUtils,
} from '@wxpusher/shared';

interface BindPageParams {
  phone?: string;
  verifyCode?: string;
  phoneVerifyCode?: string;
}

/**
 * 通过微信公众号绑定页面。
 * 对应 Android WxpBindActivity。
 */
@Entry
@Component
struct BindPage {
  // ─── 颜色常量（对齐 Android colors.xml） ──────────────────────
  private static readonly COLOR_PAGE_BG: string = '#FFFFFF';
  private static readonly COLOR_ACCENT: string = '#B300B3';
  private static readonly COLOR_TEXT_PRIMARY: string = '#030303';
  private static readonly COLOR_INPUT_BG: string = '#F5F5F5';
  private static readonly COLOR_WHITE: string = '#FFFFFF';

  @State private isLoading: boolean = false;
  private presenter: WxpBindPresenter | null = null;
  private phone: string = '';
  private verifyCode: string = '';
  private phoneVerifyCode: string = '';

  createPresenter(): IWxpBindPresenter {
    return new WxpBindPresenter(this);
  }

  aboutToAppear(): void {
    this.presenter = this.createPresenter() as WxpBindPresenter;
    const params = router.getParams() as BindPageParams | undefined;
    this.phone = params?.phone ?? '';
    this.verifyCode = params?.verifyCode ?? '';
    this.phoneVerifyCode = params?.phoneVerifyCode ?? '';
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
  }

  /** IWxpBindView.onGoMain */
  onGoMain(): void {
    router.replaceUrl({ url: 'pages/MainPage' });
  }

  /** IWxpBindView.showLoading */
  showLoading(show: boolean): void {
    this.isLoading = show;
  }

  // ─── 交互 ────────────────────────────────────────────────
  private copyBindCode(): void {
    this.copyToClipboard(this.phoneVerifyCode);
    WxpToastUtils.showToast('复制成功');
  }

  private copyWxPusher(): void {
    this.copyToClipboard('wxpusher');
    WxpToastUtils.showToast('复制成功');
  }

  private copyToClipboard(text: string): void {
    if (!text) {
      return;
    }
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      pasteboard.getSystemPasteboard().setDataSync(data);
    } catch (_e) {
      // 忽略剪贴板写入异常
    }
  }

  private onCheckStatusClick(): void {
    this.presenter?.queryBindStatus(this.phone, this.verifyCode);
  }

  // ─── 子构建：顶部导航栏 ──────────────────────────────────
  @Builder
  private buildTopBar() {
    Row() {
      Image($r('app.media.ic_chevron_left'))
        .width(24)
        .height(24)
        .fillColor(BindPage.COLOR_TEXT_PRIMARY)
        .onClick(() => {
          router.back();
        })
      Text('绑定公众号账号')
        .fontSize(18)
        .fontColor(BindPage.COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 12 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  // ─── 子构建：步骤标题（左紫条 + 加粗紫色大字） ────────────
  @Builder
  private buildStepTitle(title: string) {
    Row() {
      Column()
        .width(5)
        .height(20)
        .backgroundColor(BindPage.COLOR_ACCENT)
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(BindPage.COLOR_ACCENT)
        .margin({ left: 8 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  // ─── 子构建：第二步说明（带可点击的 "WxPusher" 文字） ───
  @Builder
  private buildStepTwoText() {
    Text() {
      Span('关注微信公众号 ')
        .fontColor(BindPage.COLOR_TEXT_PRIMARY)
      Span('WxPusher')
        .fontColor(BindPage.COLOR_ACCENT)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          this.copyWxPusher();
        })
      Span(' ，将复制的绑定码发给公众号')
        .fontColor(BindPage.COLOR_TEXT_PRIMARY)
    }
    .fontSize(16)
    .lineHeight(22)
    .width('100%')
  }

  build() {
    Column() {
      this.buildTopBar()

      Scroll() {
        Column() {
          // 描述（注意：Scroll 默认 align=Center，当内容短于视口时会被垂直居中，
          // 因此这里在外层 Scroll 上显式设为 Alignment.Top，确保内容从上到下排列）
          Text(
            '你好，你的手机号没有注册,你需要先和已经存在的UID绑定才可以接收消息，绑定方式如下：'
          )
            .fontSize(16)
            .fontColor(BindPage.COLOR_TEXT_PRIMARY)
            .lineHeight(22)
            .width('100%')

          // 第一步
          Column() {
            this.buildStepTitle('第一步')
          }
          .margin({ top: 20 })

          Text('复制下面的绑定码')
            .fontSize(16)
            .fontColor(BindPage.COLOR_TEXT_PRIMARY)
            .margin({ top: 12 })
            .width('100%')

          // 绑定码 + 复制按钮
          Row() {
            Text(this.phoneVerifyCode)
              .fontSize(16)
              .fontColor(BindPage.COLOR_TEXT_PRIMARY)
              .height(45)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .padding({ left: 16, right: 16 })
              .backgroundColor(BindPage.COLOR_INPUT_BG)
              .borderRadius(4)
              .textAlign(TextAlign.Start)

            Button('复制绑定码')
              .height(45)
              .fontSize(14)
              .fontColor(BindPage.COLOR_WHITE)
              .backgroundColor(BindPage.COLOR_ACCENT)
              .borderRadius(4)
              .margin({ left: 16 })
              .type(ButtonType.Normal)
              .onClick(() => {
                this.copyBindCode();
              })
          }
          .width('100%')
          .margin({ top: 8 })
          .alignItems(VerticalAlign.Center)

          // 第二步
          Column() {
            this.buildStepTitle('第二步')
          }
          .margin({ top: 20 })

          Column() {
            this.buildStepTwoText()
          }
          .margin({ top: 12 })
          .width('100%')

          // 第三步
          Column() {
            this.buildStepTitle('第三步')
          }
          .margin({ top: 20 })

          Text('发送绑定码后，请点击下面的按钮，查询绑定状态')
            .fontSize(16)
            .fontColor(BindPage.COLOR_TEXT_PRIMARY)
            .lineHeight(22)
            .margin({ top: 12 })
            .width('100%')

          // 查询绑定状态按钮（带内嵌 Loading）
          Stack() {
            Button(this.isLoading ? '' : '查询绑定状态')
              .width('100%')
              .height(45)
              .fontSize(16)
              .fontColor(BindPage.COLOR_WHITE)
              .backgroundColor(BindPage.COLOR_ACCENT)
              .borderRadius(4)
              .type(ButtonType.Normal)
              .enabled(!this.isLoading)
              .onClick(() => {
                this.onCheckStatusClick();
              })
            if (this.isLoading) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(BindPage.COLOR_WHITE)
            }
          }
          .width('100%')
          .margin({ top: 20 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 20 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BindPage.COLOR_PAGE_BG)
  }
}
