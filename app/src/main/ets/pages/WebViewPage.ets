import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { uri } from '@kit.ArkTS';
import {
  WxpWebHostPolicy,
  AppFeVersionManager,
  WxpToastUtils,
  WxpDialogUtils,
  WxpDialogParams,
} from '@wxpusher/shared';
import { WxpWebBridgeManager, WxpWebPageContext } from '../webbridge/WxpWebBridgeManager';

interface WebViewPageParams {
  url?: string;
}

/**
 * WxpWebPageContext 的具体实现类。
 * ArkTS 严格模式不允许用对象字面量实现接口，必须使用 class。
 * 通过回调函数将操作委托回 WebViewPage。
 */
class WxpWebPageContextImpl implements WxpWebPageContext {
  private callback: (visible: boolean | null) => void;

  constructor(callback: (visible: boolean | null) => void) {
    this.callback = callback;
  }

  setBottomBarVisible(visible: boolean | null): void {
    this.callback(visible);
  }
}

@Entry
@Component
struct WebViewPage {
  @State pageTitle: string = '';
  @State progress: number = 0;
  @State showProgress: boolean = false;
  @State showThirdPartyBanner: boolean = false;
  @State bottomBarVisible: boolean = true;
  @State canGoBack: boolean = false;
  @State canGoForward: boolean = false;

  private controller: webview.WebviewController = new webview.WebviewController();
  private url: string = '';
  private currentUrl: string = '';
  private bridgeManager: WxpWebBridgeManager | null = null;
  // null = 使用默认逻辑；非 null = bridge 显式设置（对应 Android bottomBarVisibleOverride）
  private bottomBarVisibleOverride: boolean | null = null;

  aboutToAppear(): void {
    const params = router.getParams() as WebViewPageParams;
    this.url = params?.url ?? '';
    this.currentUrl = this.url;

    // 对应 Android loadWebContentWithVersionCheck：版本更新时清缓存并追加版本参数
    const pendingVersion = AppFeVersionManager.consumePendingRefreshVersion(this.url);
    if (pendingVersion) {
      try {
        // 对应 Android clearWebViewCacheForVersionUpdate
        this.controller.clearHistory();
      } catch {
        // controller 尚未 attach，忽略
      }
      this.url = AppFeVersionManager.appendVersionParam(this.url, pendingVersion);
    }

    // 构造 WxpWebPageContext，对应 Android BridgeContext 对 WxpWebViewFragment 的反向控制
    const pageCtx: WxpWebPageContextImpl = new WxpWebPageContextImpl((visible: boolean | null) => {
      this.bottomBarVisibleOverride = visible;
      this.applyBottomBarVisible(this.currentUrl);
    });

    this.bridgeManager = new WxpWebBridgeManager(this.controller, pageCtx);

    // 初始化底栏可见性
    this.applyBottomBarVisible(this.url);
  }

  /**
   * 对应 Android resolveBottomBarVisible：
   *   - override 非 null 时使用 override 值
   *   - 默认：白名单 host 且路径含 /app 时隐藏（H5 内嵌页面不需要底栏）
   */
  private applyBottomBarVisible(url: string): void {
    if (this.bottomBarVisibleOverride !== null) {
      this.bottomBarVisible = this.bottomBarVisibleOverride;
      return;
    }
    if (!url || url.length === 0) {
      this.bottomBarVisible = true;
      return;
    }
    try {
      const parsed = new uri.URI(url);
      const path = parsed.path ?? '';
      if (WxpWebHostPolicy.isHostInWhitelist(parsed.host) && path.includes('/app')) {
        this.bottomBarVisible = false;
        return;
      }
    } catch {
      // 解析失败，默认显示
    }
    this.bottomBarVisible = true;
  }

  /**
   * 对应 Android checkAndShowThirdPartyBanner
   */
  private updateThirdPartyBanner(url: string | undefined): void {
    if (!url || url.length === 0) {
      return;
    }
    this.showThirdPartyBanner = !WxpWebHostPolicy.isUrlInWhitelist(url);
  }

  private showThirdPartyContentAlert(): void {
    const params: WxpDialogParams = {
      title: '第三方内容提示',
      message: '当前页面包含第三方提供的内容。这些内容由第三方独立提供和维护，与WxPusher无关。请谨慎对待页面中的信息，WxPusher不对第三方内容的准确性、安全性或合法性承担责任。\n\n如果您对内容有疑问或遇到问题，请直接联系内容提供方。',
      rightText: '我知道了',
    };
    WxpDialogUtils.showDialog(params);
  }

  build() {
    Column() {

      // ── 顶部导航栏 ──
      // 对应 Android ActionBar（提供返回箭头 + 标题）；
      // 右侧关闭按钮是鸿蒙侧特有交互，方便用户直接退出页面。
      Row() {
        // 返回：用 Row 做触摸区，Image 本身不加 padding，避免内容区被压缩
        Row() {
          Image($r('app.media.ic_chevron_left'))
            .width(26)
            .height(26)
            .fillColor('#333333')
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
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
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        // 关闭：同上
        Row() {
          Image($r('app.media.ic_close'))
            .width(26)
            .height(26)
            .fillColor('#333333')
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          router.back();
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      // ── 第三方内容警告 Banner（对应 Android thirdPartyBannerView）──
      if (this.showThirdPartyBanner) {
        Row() {
          Image($r('app.media.ic_warning'))
            .width(16)
            .height(16)
            .fillColor(Color.White)
            .margin({ right: 8 })
          Text('当前内容由第三方提供，与WxPusher无关')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
          Image($r('app.media.ic_chevron_right'))
            .width(16)
            .height(16)
            .fillColor(Color.White)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FF6200EE')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.showThirdPartyContentAlert();
        })
      }

      // ── 进度条（对应 Android ProgressBar，放在 WebView 上方覆盖显示）──
      if (this.showProgress && this.progress > 0 && this.progress < 100) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color('#007AFF')
      }

      // ── WebView ──
      Web({ src: this.url, controller: this.controller })
        .width('100%')
        .layoutWeight(1)
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .mixedMode(MixedMode.All)
        // 对应 Android useWideViewPort=true：尊重 viewport meta，避免页面被强制压缩
        .wideViewModeAccess(true)
        // 对应 Android loadWithOverviewMode=true：初始以全屏宽显示页面
        .overviewModeAccess(true)
        // 对应 Android setSupportZoom(true) + builtInZoomControls=true
        .zoomAccess(true)
        // 对应 Android：webSettings.userAgentString + "/WxPusher-Android"
        // 必须保留 "Mobile Safari" 标识，否则网站识别为桌面浏览器会返回桌面版页面（页面极小）
        .userAgent('Mozilla/5.0 (Linux; Android 10; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36 WxPusher-HarmonyOS')
        .onTitleReceive((event) => {
          // 对应 Android onReceivedTitle
          const title = event?.title ?? '';
          this.pageTitle = title.length > 0 ? title : '网页内容';
        })
        .onProgressChange((event) => {
          // 对应 Android onProgressChanged
          const p = event?.newProgress ?? 0;
          this.progress = p;
          if (p >= 100) {
            this.showProgress = false;
          }
        })
        .onPageBegin((event) => {
          // 对应 Android onPageStarted
          const url = event?.url ?? '';
          this.currentUrl = url;
          this.showProgress = true;
          this.progress = 0;
          this.updateThirdPartyBanner(url);
          this.applyBottomBarVisible(url);
        })
        .onPageEnd((event) => {
          // 对应 Android onPageFinished
          const url = event?.url ?? '';
          this.currentUrl = url;
          this.showProgress = false;
          this.updateThirdPartyBanner(url);
          this.applyBottomBarVisible(url);
          try {
            this.canGoBack = this.controller.accessBackward();
            this.canGoForward = this.controller.accessForward();
          } catch {
            // ignore
          }
        })
        .onErrorReceive((event) => {
          // 对应 Android onReceivedError（仅主框架错误）
          if (event?.request?.isMainFrame()) {
            this.showProgress = false;
            this.pageTitle = '加载失败';
            WxpToastUtils.showToast('加载失败');
            try {
              this.canGoBack = this.controller.accessBackward();
              this.canGoForward = this.controller.accessForward();
            } catch {
              // ignore
            }
          }
        })
        .onAlert((event) => {
          // 对应 Android onJsAlert 拦截：将 window.alert() 替换为原生 Dialog
          if (event) {
            const dialogParams: WxpDialogParams = {
              title: event.message,
              rightText: '我知道了',
              rightBlock: () => {
                event.result.handleConfirm();
              },
            };
            WxpDialogUtils.showDialog(dialogParams);
            return true;
          }
          return false;
        })
        .javaScriptProxy({
          object: {
            postMessage: (message: string) => {
              // 对应 Android WxpWebBridgeInterface.postMessage
              this.bridgeManager?.onMessage(message, this.currentUrl);
            },
          },
          name: 'wxpusher',
          methodList: ['postMessage'],
          controller: this.controller,
        })
        .onInterceptRequest((_event) => {
          // HarmonyOS onInterceptRequest 不支持直接注入请求 header（只能修改响应）。
          // Header 注入（deviceToken/versionName/platform）建议改用 controller.loadUrl(url, headers)。
          // 当前保持 null 返回，不拦截请求。
          return null;
        })

      // ── 底部工具栏（对应 Android webOptionView：后退 / 前进 / 刷新 / 关闭）──
      if (this.bottomBarVisible) {
        Column() {
          Divider()
            .width('100%')
            .height(1)
            .color('#1A000000')
          Row() {

            // 后退（对应 Android backButton）
            // Column 作为触摸区，Image 不加 padding，避免内容区被压缩为负值
            Column() {
              Image($r('app.media.ic_chevron_left'))
                .width(26)
                .height(26)
                .fillColor('#333333')
                .opacity(this.canGoBack ? 1.0 : 0.3)
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              if (this.controller.accessBackward()) {
                this.controller.backward();
              }
            })

            // 前进（对应 Android forwardButton）
            Column() {
              Image($r('app.media.ic_chevron_right'))
                .width(26)
                .height(26)
                .fillColor('#333333')
                .opacity(this.canGoForward ? 1.0 : 0.3)
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              if (this.controller.accessForward()) {
                this.controller.forward();
              }
            })

            // 刷新（对应 Android refreshButton）
            Column() {
              Image($r('app.media.ic_refresh'))
                .width(26)
                .height(26)
                .fillColor('#333333')
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.controller.refresh();
            })

            // 关闭（对应 Android closeButton → activity.finish()）
            Column() {
              Image($r('app.media.ic_close'))
                .width(26)
                .height(26)
                .fillColor('#333333')
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              router.back();
            })

          }
          .width('100%')
          .height(55)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .backgroundColor(Color.White)
      }

    }
    .width('100%')
    .height('100%')
  }
}
