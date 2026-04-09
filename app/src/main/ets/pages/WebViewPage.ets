import { router } from '@kit.ArkUI';
import { WxpWebViewComponent } from '../components/WxpWebViewComponent';

interface WebViewPageParams {
  url?: string;
}

/**
 * 独立 WebView 页面（对应 Android WxpWebViewActivity + WxpWebViewFragment）。
 * 所有 WebView 能力由 WxpWebViewComponent 统一提供。
 */
@Entry
@Component
struct WebViewPage {
  private url: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as WebViewPageParams;
    this.url = params?.url ?? '';
  }

  build() {
    Column() {
      WxpWebViewComponent({
        url: this.url,
        showNavBar: true,
        showBottomBar: true,
        // onCloseButtonClicked = null → 底栏显示 ic_close，点击 router.back()
      })
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
