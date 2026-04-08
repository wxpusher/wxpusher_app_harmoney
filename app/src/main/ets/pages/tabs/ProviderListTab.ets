// ─────────────────────────────────────────────────────────
// 消息市场 Tab（对齐 Android WxpProviderListFragment）
// ─────────────────────────────────────────────────────────

import { webview } from '@kit.ArkWeb';
import { ConfigurationConstant } from '@kit.AbilityKit';
import {
  WxpProviderListPresenter,
  IWxpProviderListPresenter,
  IWxpProviderListView,
  WxpToastUtils,
  WxpDialogUtils,
  WxpDialogParams,
} from '@wxpusher/shared';
import { WxpWebBridgeManager, WxpWebPageContext } from '../../webbridge/WxpWebBridgeManager';

/**
 * WxpWebPageContext 的最简实现。
 * 市场 Tab 内嵌 WebView，不需要对外控制底栏可见性。
 */
class ProviderListPageContext implements WxpWebPageContext {
  setBottomBarVisible(_visible: boolean | null): void {
    // 市场 Tab 内嵌，忽略 H5 侧底栏控制请求
  }
}

@Component
export struct ProviderListTab {
  /** 父级传入的当前 Tab 索引，便于未来感知 resume（目前市场 Tab index = 1）*/
  @Prop @Watch('onTabIndexChanged') currentTabIndex: number = 0;

  // ── WebView 状态 ──
  @State private url: string = '';          // 空字符串表示尚未就绪，显示加载中
  @State private progress: number = 0;
  @State private showProgress: boolean = false;
  @State private canGoBack: boolean = false;
  @State private canGoForward: boolean = false;

  // 跟随系统深色/浅色模式
  @StorageProp('colorMode') colorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

  private controller: webview.WebviewController = new webview.WebviewController();
  private bridgeManager: WxpWebBridgeManager | null = null;
  private currentUrl: string = '';
  private presenter: IWxpProviderListPresenter | null = null;

  // ── IWxpProviderListView 实现 ──

  /**
   * 对应 Android WxpProviderListFragment.onLoadPage → loadWebContent(url)。
   * Presenter 获取 openId 成功后回调此方法，触发 WebView 加载。
   */
  onLoadPage(url: string): void {
    if (this.url === url) {
      // 已加载相同 URL（如 home 按钮重复点击），直接刷新
      try {
        this.controller.refresh();
      } catch {
        // controller 尚未 attach，忽略
      }
      return;
    }
    this.url = url;
    this.currentUrl = url;
  }

  createPresenter(): IWxpProviderListPresenter {
    return new WxpProviderListPresenter(this);
  }

  // ── 生命周期 ──

  aboutToAppear(): void {
    this.bridgeManager = new WxpWebBridgeManager(this.controller, new ProviderListPageContext());
    this.presenter = this.createPresenter();
    // 对应 Android onViewCreated → presenter.loadPage()
    this.presenter.loadPage();
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
    this.presenter = null;
  }

  /**
   * 切回本 Tab 时触发（对应 Android Fragment onResume）。
   * 市场页无需特殊刷新，保留此钩子供后续扩展。
   */
  onTabIndexChanged(): void {
    // market tab index = 1；切入时如需刷新可在此处添加逻辑
  }

  // ── 私有交互 ──

  /**
   * 对应 Android WxpProviderListFragment.onCloseButtonClicked：
   * 点击"主页"按钮重新加载市场 URL（而非关闭页面）。
   */
  private onHomeButtonClicked(): void {
    this.url = '';  // 先清空，触发 loading 态，presenter 回调后再重新设置
    this.presenter?.loadPage();
  }

  // ── Build ──

  build() {
    Column() {

      // ── 顶部标题栏（对应 Android Toolbar，市场 Tab 不显示返回按钮）──
      Row() {
        Text('消息市场')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      if (this.url.length === 0) {
        // ── 加载中占位（Presenter 尚未返回 URL）──
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#B300B3')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

      } else {
        // ── 进度条（对应 Android ProgressBar）──
        if (this.showProgress && this.progress > 0 && this.progress < 100) {
          Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(2)
            .color('#007AFF')
        }

        // ── WebView（对应 Android WxpWebViewFragment 内嵌 WebView）──
        Web({ src: this.url, controller: this.controller })
          .width('100%')
          .layoutWeight(1)
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .mixedMode(MixedMode.All)
          .wideViewModeAccess(true)
          .overviewModeAccess(true)
          .zoomAccess(true)
          .userAgent('Mozilla/5.0 (Linux; Android 10; HarmonyOS) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36 WxPusher-HarmonyOS')
          .onProgressChange((event) => {
            // 对应 Android onProgressChanged
            const p = event?.newProgress ?? 0;
            this.progress = p;
            this.showProgress = p < 100;
          })
          .onPageBegin((event) => {
            // 对应 Android onPageStarted
            const url = event?.url ?? '';
            this.currentUrl = url;
            this.showProgress = true;
            this.progress = 0;
          })
          .onPageEnd((event) => {
            // 对应 Android onPageFinished
            const url = event?.url ?? '';
            this.currentUrl = url;
            this.showProgress = false;
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
              WxpToastUtils.showToast('加载失败');
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

        // ── 底部工具栏（对应 Android webOptionView，close 改为 home）──
        Column() {
          Divider()
            .width('100%')
            .height(1)
            .color(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
              ? '#1AFFFFFF' : '#1A000000')
          Row() {

            // 后退（对应 Android backButton）
            Column() {
              Image($r('app.media.ic_chevron_left'))
                .width(26)
                .height(26)
                .fillColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                  ? '#E5E5E5' : '#333333')
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
                .fillColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                  ? '#E5E5E5' : '#333333')
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
                .fillColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                  ? '#E5E5E5' : '#333333')
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.controller.refresh();
            })

            // 主页（对应 Android closeButton → 覆盖为 ic_home + onCloseButtonClicked → loadPage()）
            Column() {
              Image($r('app.media.ic_home'))
                .width(26)
                .height(26)
                .fillColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                  ? '#E5E5E5' : '#333333')
            }
            .layoutWeight(1)
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.onHomeButtonClicked();
            })

          }
          .width('100%')
          .height(55)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .backgroundColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
          ? '#1C1C1E' : Color.White)
      }

    }
    .width('100%')
    .height('100%')
  }
}
