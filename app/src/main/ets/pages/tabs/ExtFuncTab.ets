// ─────────────────────────────────────────────────────────
// 扩展功能 Tab（对齐 Android WxpExtFuncFragment）
// 原生 WebView 容器加载 app-fe 九宫格入口页
// ─────────────────────────────────────────────────────────

import { WxpConfig } from '@wxpusher/shared';
import { router } from '@kit.ArkUI';
import { WxpWebViewComponent } from '../../components/WxpWebViewComponent';

@Component
export struct ExtFuncTab {
  /** 父级传入的当前 Tab 索引，用于感知 resume */
  @Prop currentTabIndex: number = 0;

  /** 传给 WxpWebViewComponent 的 URL；空字符串 = 显示 loading 占位 */
  @State private webUrl: string = '';

  aboutToAppear(): void {
    this.webUrl = `${WxpConfig.appFeUrl}/app#/ext-func`;
  }

  // 打开「底部标签设置」
  private openTabSetting(): void {
    router.pushUrl({
      url: 'pages/WebViewPage',
      params: { url: `${WxpConfig.appFeUrl}/app/#/tab-setting` },
    });
  }

  build() {
    Column() {

      // 顶部标题栏（自管，标题"扩展功能" + 右侧齿轮=底部标签设置）
      Row() {
        Text('扩展功能')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))

        Image($r('app.media.ic_settings'))
          .width(22)
          .height(22)
          .fillColor($r('sys.color.font_secondary'))
          .onClick(() => { this.openTabSetting(); })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      WxpWebViewComponent({
        url: this.webUrl,
        showNavBar: false,
        showBottomBar: false,
      })
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
