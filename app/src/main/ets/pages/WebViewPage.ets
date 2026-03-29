import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import {
  WxpWebHostPolicy,
  WxpAppDataService,
  WxpBaseInfoService,
  AppFeVersionManager,
} from '@wxpusher/shared';
import { WxpWebBridgeManager } from '../webbridge/WxpWebBridgeManager';

interface WebViewPageParams {
  url?: string;
}

@Entry
@Component
struct WebViewPage {
  @State pageTitle: string = '';
  @State progress: number = 0;
  @State showProgress: boolean = true;
  private controller: webview.WebviewController = new webview.WebviewController();
  private url: string = '';
  private bridgeManager: WxpWebBridgeManager | null = null;

  aboutToAppear(): void {
    const params = router.getParams() as WebViewPageParams;
    this.url = params?.url ?? '';

    // 检查版本更新
    const pendingVersion = AppFeVersionManager.consumePendingRefreshVersion(this.url);
    if (pendingVersion) {
      this.url = AppFeVersionManager.appendVersionParam(this.url, pendingVersion);
    }

    this.bridgeManager = new WxpWebBridgeManager(this.controller);
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
          .onClick(() => {
            if (this.controller.accessBackward()) {
              this.controller.backward();
            } else {
              router.back();
            }
          })
        Text(this.pageTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 12 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Image($r('app.media.startIcon'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .onClick(() => { router.back(); })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 进度条
      if (this.showProgress && this.progress > 0 && this.progress < 100) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color('#007AFF')
      }

      // WebView
      Web({ src: this.url, controller: this.controller })
        .width('100%')
        .layoutWeight(1)
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .mixedMode(MixedMode.All)
        .onTitleReceive((event) => {
          this.pageTitle = event?.title ?? '';
        })
        .onProgressChange((event) => {
          this.progress = event?.newProgress ?? 0;
          if (this.progress >= 100) {
            this.showProgress = false;
          }
        })
        .onPageBegin(() => {
          this.showProgress = true;
        })
        .javaScriptProxy({
          object: {
            postMessage: (message: string) => {
              this.bridgeManager?.onMessage(message, this.controller.getUrl());
            },
          },
          name: 'wxpusher',
          methodList: ['postMessage'],
          controller: this.controller,
        })
        .onInterceptRequest((event) => {
          // 为白名单域名请求注入 header
          const requestUrl = event?.request?.getRequestUrl() ?? '';
          if (WxpWebHostPolicy.isUrlInWhitelist(requestUrl)) {
            const loginInfo = WxpAppDataService.getLoginInfo();
            const headers: Array<webview.WebHeader> = [
              { headerKey: 'deviceToken', headerValue: loginInfo?.deviceToken ?? '' },
              { headerKey: 'versionName', headerValue: WxpBaseInfoService.getAppVersionName() },
              { headerKey: 'platform', headerValue: WxpBaseInfoService.getPlatform() },
            ];
            // 注：鸿蒙Web组件的onInterceptRequest需要返回WebResourceResponse或null
            // 此处仅用于演示header注入逻辑，实际需要根据API版本调整
          }
          return null;
        })
    }
    .width('100%')
    .height('100%')
  }
}
