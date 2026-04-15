/**
 * 可复用的 WebView 容器组件，统一收口所有 WebView 能力。
 *
 * 对应 Android WxpWebViewFragment：
 *   - Bridge 初始化、JS 通信、白名单检查
 *   - 进度条、第三方内容 Banner
 *   - 顶部导航栏（返回键 + 标题 + 菜单）
 *   - 底部工具栏（后退/前进/刷新/关闭或主页）
 *   - 版本检查（AppFeVersionManager）
 *   - 深色/浅色模式适配
 *
 * 用法：
 *   // 标准独立页（WebViewPage）
 *   WxpWebViewComponent({ url: this.url })
 *
 *   // Tab 内嵌（ProviderListTab，不显示内置导航栏和底栏）
 *   WxpWebViewComponent({ url: this.url, showNavBar: false, showBottomBar: false })
 */

import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { uri } from '@kit.ArkTS';
import { pasteboard } from '@kit.BasicServicesKit';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import {
  WxpWebHostPolicy,
  AppFeVersionManager,
  WxpAppDataService,
  WxpBaseInfoService,
  WxpToastUtils,
  WxpDialogUtils,
  WxpDialogParams,
} from '@wxpusher/shared';
import { WxpWebBridgeManager, WxpWebPageContext } from '../webbridge/WxpWebBridgeManager';
import { WxpWeixinOpenManager, WX_SCENE_SESSION } from '../wxapi/WxpWeixinOpenManager';

/**
 * WxpWebPageContext 实现（对应 Android BridgeContext，委托回调模式）。
 * ArkTS 严格模式不允许对象字面量实现接口，必须使用 class。
 */
class WxpWebViewPageContext implements WxpWebPageContext {
  private bottomBarCallback: (visible: boolean | null) => void;
  private optionMenuCallback: (visible: boolean | null) => void;
  private optionMenuItemsCallback: (items: string[] | null) => void;

  constructor(
    bottomBarCallback: (visible: boolean | null) => void,
    optionMenuCallback: (visible: boolean | null) => void,
    optionMenuItemsCallback: (items: string[] | null) => void,
  ) {
    this.bottomBarCallback = bottomBarCallback;
    this.optionMenuCallback = optionMenuCallback;
    this.optionMenuItemsCallback = optionMenuItemsCallback;
  }

  setBottomBarVisible(visible: boolean | null): void {
    this.bottomBarCallback(visible);
  }

  setOptionMenuVisible(visible: boolean | null): void {
    this.optionMenuCallback(visible);
  }

  setOptionMenuItems(items: string[] | null): void {
    this.optionMenuItemsCallback(items);
  }
}

@Component
export struct WxpWebViewComponent {

  // ── @Prop：响应父组件变化 ──

  /** 加载 URL；空字符串 = 显示 loading 占位（ProviderListTab 等待 Presenter 异步回调场景） */
  @Prop @Watch('onUrlChanged') url: string = '';

  /** 是否显示顶部导航栏（返回键 + 动态标题 + 右上角菜单）
   *  WebViewPage = true（默认）；ProviderListTab = false（自管标题栏） */
  @Prop showNavBar: boolean = true;

  /** 是否启用底部工具栏（后退/前进/刷新/关闭）
   *  WebViewPage = true（默认）；ProviderListTab = false（Tab 内嵌，已有系统 Tab 栏） */
  @Prop showBottomBar: boolean = true;

  // ── 普通属性：函数不能用 @Prop（不可序列化）──

  /**
   * 底栏第四按钮自定义行为（对应 Android onCloseButtonClicked 虚方法重写）：
   *   null  → 显示 ic_close，点击 router.back()（WebViewPage 默认行为）
   *   非null → 显示 ic_home，点击调用此回调（ProviderListTab 等需要自定义场景）
   */
  onCloseButtonClicked: (() => void) | null = null;

  // ── 内部 @State ──

  /** 实际传给 Web({ src }) 的值（版本追加处理后）。
   *  空字符串 = Web 组件未挂载，显示 loading 占位。 */
  @State private webSrc: string = '';
  @State private pageTitle: string = '';
  @State private progress: number = 0;
  @State private showProgress: boolean = false;
  @State private showThirdPartyBanner: boolean = false;
  /** URL 规则 + Bridge 动态控制的底栏可见性（与 showBottomBar 取 AND） */
  @State private bottomBarVisible: boolean = true;
  /** URL 规则 + Bridge 动态控制的右上角菜单可见性 */
  @State private optionMenuVisible: boolean = true;
  @State private canGoBack: boolean = false;
  @State private canGoForward: boolean = false;

  @StorageProp('colorMode') colorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

  // ── 内部私有字段 ──

  private controller: webview.WebviewController = new webview.WebviewController();
  private bridgeManager: WxpWebBridgeManager | null = null;
  private currentUrl: string = '';
  // null = 使用默认逻辑；非 null = Bridge setWebBottomBar 显式设置
  private bottomBarVisibleOverride: boolean | null = null;
  // null = 使用默认逻辑；非 null = Bridge setWebOptionMenu 显式设置
  private optionMenuVisibleOverride: boolean | null = null;
  // null = 显示全部菜单项；非 null = Bridge setWebOptionMenu options 字段指定的菜单项
  @State private optionMenuItemsOverride: string[] | null = null;
  // '' 表示 Web 组件未挂载；非空表示已挂载（用于 onUrlChanged 决策）
  private lastLoadedUrl: string = '';

  // ── 生命周期 ──

  aboutToAppear(): void {
    // Bridge 初始化（对应 Android setupWebView + addJavascriptInterface）
    const pageCtx = new WxpWebViewPageContext(
      (visible: boolean | null) => {
        this.bottomBarVisibleOverride = visible;
        this.applyBottomBarVisible(this.currentUrl);
      },
      (visible: boolean | null) => {
        this.optionMenuVisibleOverride = visible;
        this.applyOptionMenuVisible(this.currentUrl);
      },
      (items: string[] | null) => {
        this.optionMenuItemsOverride = items;
      },
    );
    this.bridgeManager = new WxpWebBridgeManager(this.controller, pageCtx);

    // 若初始 url 非空（如 WebViewPage 从 router params 获取到了 url），
    // 立即处理版本检查并设置 webSrc，触发 Web 组件首次渲染
    if (this.url.length > 0) {
      const processed = this.processUrlWithVersionCheck(this.url);
      this.webSrc = processed;
      this.lastLoadedUrl = processed;
      this.currentUrl = processed;
      this.bridgeManager?.updateCurrentUrl(processed);
      this.applyBottomBarVisible(processed);
      this.applyOptionMenuVisible(processed);
    }
    // 若 url 为空（如 ProviderListTab 等待 Presenter），webSrc 保持 ''，
    // 显示 loading 占位，待 @Watch onUrlChanged 回调时再加载
  }

  // ── @Watch handler ──

  /**
   * 监听父组件传入的 url 变化。
   * 场景 A：ProviderListTab — url 从 '' 变为真实 URL（Presenter 异步回调）
   *   → Web 组件首次挂载，设置 webSrc 触发
   * 场景 B：url 在两个非空值之间切换（未来扩展）
   *   → Web 已挂载，调 controller.loadUrl()
   * 场景 C：url 重置为 ''（中间态，如 ProviderListTab home 按钮）
   *   → Web 组件卸载，回到 loading 占位
   */
  onUrlChanged(): void {
    const newUrl = this.url;

    if (!newUrl || newUrl.length === 0) {
      // 场景 C：URL 清空
      this.webSrc = '';
      this.lastLoadedUrl = '';
      return;
    }

    if (newUrl === this.lastLoadedUrl) {
      return; // 无实质变化，忽略
    }

    const wasAlreadyMounted = this.lastLoadedUrl.length > 0;
    this.lastLoadedUrl = newUrl;
    this.bottomBarVisibleOverride = null; // URL 切换时重置 Bridge 覆盖
    this.optionMenuVisibleOverride = null;
    this.optionMenuItemsOverride = null;
    this.applyBottomBarVisible(newUrl);
    this.applyOptionMenuVisible(newUrl);

    if (wasAlreadyMounted) {
      // 场景 B：Web 已挂载，src 不再响应 @State 变化，改用 controller.loadUrl()
      try {
        this.controller.loadUrl(newUrl, this.buildLoadHeaders(newUrl));
        this.currentUrl = newUrl;
        this.bridgeManager?.updateCurrentUrl(newUrl);
      } catch {
        // 降级：重置 webSrc 触发 Web 重新挂载
        this.webSrc = newUrl;
        this.currentUrl = newUrl;
        this.bridgeManager?.updateCurrentUrl(newUrl);
      }
    } else {
      // 场景 A：Web 尚未挂载，设置 webSrc 触发首次挂载
      this.webSrc = newUrl;
      this.currentUrl = newUrl;
      this.bridgeManager?.updateCurrentUrl(newUrl);
    }
  }

  // ── 私有工具方法 ──

  /**
   * 版本检查与 URL 处理（对应 Android loadWebContentWithVersionCheck）。
   * 注意：返回值存入内部 webSrc，不回写 @Prop url。
   */
  private processUrlWithVersionCheck(url: string): string {
    const pendingVersion = AppFeVersionManager.consumePendingRefreshVersion(url);
    if (pendingVersion) {
      try {
        this.controller.clearHistory();
      } catch {
        // controller 尚未 attach，忽略
      }
      return AppFeVersionManager.appendVersionParam(url, pendingVersion);
    }
    return url;
  }

  /**
   * 构建 WebView 加载请求头（对齐 Android createRequestWithTokenIfNeeded）。
   * 仅白名单 URL 注入 deviceToken/versionName/platform。
   */
  private buildLoadHeaders(url: string): Array<webview.WebHeader> {
    if (!WxpWebHostPolicy.isUrlInWhitelist(url)) {
      return [];
    }
    return [
      {
        headerKey: 'deviceToken',
        headerValue: WxpAppDataService.getLoginInfo()?.deviceToken ?? '',
      },
      {
        headerKey: 'versionName',
        headerValue: WxpBaseInfoService.getAppVersionName(),
      },
      {
        headerKey: 'platform',
        headerValue: WxpBaseInfoService.getPlatform(),
      },
    ];
  }

  /**
   * 底栏可见性判断（对应 Android resolveBottomBarVisible）。
   *   - Bridge override 非 null 时优先使用 override 值
   *   - 默认：白名单 host 且路径含 '/app' → 隐藏（H5 内嵌页面不需要底栏）
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
   * 右上角菜单可见性判断（对应 Android resolveOptionMenuVisible）。
   *   - Bridge override 非 null 时优先使用 override 值
   *   - 默认：白名单 host 且路径含 'wxuser' → 隐藏（对应 Android 订阅管理页逻辑）
   */
  private applyOptionMenuVisible(url: string): void {
    if (this.optionMenuVisibleOverride !== null) {
      this.optionMenuVisible = this.optionMenuVisibleOverride;
      return;
    }
    if (!url || url.length === 0) {
      this.optionMenuVisible = true;
      return;
    }
    try {
      const parsed = new uri.URI(url);
      const path = parsed.path ?? '';
      if (WxpWebHostPolicy.isHostInWhitelist(parsed.host) && path.includes('wxuser')) {
        this.optionMenuVisible = false;
        return;
      }
    } catch {
      // 解析失败，默认显示
    }
    this.optionMenuVisible = true;
  }

  /** 对应 Android checkAndShowThirdPartyBanner */
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

  /** 对应 Android copyLinkToClipboard */
  private copyLink(): void {
    const url = this.currentUrl || this.webSrc;
    if (!url || url.length === 0) {
      return;
    }
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, url);
      pasteboard.getSystemPasteboard().setDataSync(data);
      WxpToastUtils.showToast('复制成功');
    } catch {
      WxpToastUtils.showToast('复制失败');
    }
  }

  /** 对应 Android weixinShareURL */
  private weixinShare(): void {
    const url = this.currentUrl || this.webSrc;
    if (!url || url.length === 0) {
      return;
    }
    WxpWeixinOpenManager.shareWebPage(
      url,
      this.pageTitle,
      WX_SCENE_SESSION,
      (_success, error) => {
        if (error !== null) {
          WxpToastUtils.showToast(error.message);
        }
      }
    );
  }

  /** 对应 Android shareURL（系统分享） */
  private shareUrl(): void {
    const url = this.currentUrl || this.webSrc;
    if (!url || url.length === 0) {
      return;
    }
    try {
      const sharedData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
        content: url,
        title: this.pageTitle,
      });
      const shareController = new systemShare.ShareController(sharedData);
      const context = getContext(this) as common.UIAbilityContext;
      shareController.show(context, {
        previewMode: systemShare.SharePreviewMode.DETAIL,
        selectionMode: systemShare.SelectionMode.SINGLE,
      }).catch(() => {
        WxpToastUtils.showToast('分享失败');
      });
    } catch {
      WxpToastUtils.showToast('分享失败');
    }
  }

  /** 对应 Android openInBrowser */
  private openInBrowser(): void {
    const url = this.currentUrl || this.webSrc;
    if (!url || url.length === 0) {
      return;
    }
    try {
      const context = getContext(this) as common.UIAbilityContext;
      context.openLink(url, { appLinkingOnly: false })
        .catch(() => {
          WxpToastUtils.showToast('无法打开浏览器');
        });
    } catch {
      WxpToastUtils.showToast('无法打开浏览器');
    }
  }

  /** 右上角选项菜单（对应 Android ActionBar options menu）。
   *  optionMenuItemsOverride 为 null 时显示全部；非 null 时只显示指定项。
   *  支持的 key 对应 Android SUPPORTED_OPTION_MENU_KEYS：
   *    copy_link / weixin_share / share / open_browser
   */
  @Builder
  optionMenuBuilder() {
    Menu() {
      if (this.optionMenuItemsOverride === null || this.optionMenuItemsOverride.includes('copy_link')) {
        MenuItem({ content: '复制链接' })
          .onClick(() => { this.copyLink(); })
      }
      if (this.optionMenuItemsOverride === null || this.optionMenuItemsOverride.includes('weixin_share')) {
        MenuItem({ content: '微信分享' })
          .onClick(() => { this.weixinShare(); })
      }
      if (this.optionMenuItemsOverride === null || this.optionMenuItemsOverride.includes('share')) {
        MenuItem({ content: '分享' })
          .onClick(() => { this.shareUrl(); })
      }
      if (this.optionMenuItemsOverride === null || this.optionMenuItemsOverride.includes('open_browser')) {
        MenuItem({ content: '在浏览器中打开' })
          .onClick(() => { this.openInBrowser(); })
      }
    }
  }

  // ── Build ──

  build() {
    Column() {

      // ── ① 顶部导航栏（对应 Android ActionBar，if showNavBar）──
      if (this.showNavBar) {
        Row() {
          // 返回：WebView 可后退则后退，否则 router.back()
          Row() {
            Image($r('app.media.ic_chevron_left'))
              .width(26)
              .height(26)
              .fillColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                ? '#E5E5E5' : '#333333')
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
            .fontColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
              ? '#E5E5E5' : '#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          // 右上角菜单（对应 Android ActionBar options menu）
          if (this.optionMenuVisible) {
            Row() {
              Image($r('app.media.ic_more'))
                .width(26)
                .height(26)
                .fillColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                  ? '#E5E5E5' : '#333333')
            }
            .width(44)
            .height(44)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .bindMenu(this.optionMenuBuilder())
          } else {
            // 占位，保持标题居中布局不变
            Row()
              .width(44)
              .height(44)
          }
        }
        .width('100%')
        .height(56)
        .padding({ left: 8, right: 8 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
          ? '#1C1C1E' : Color.White)
      }

      // ── ② 第三方内容警告 Banner（对应 Android thirdPartyBannerView）──
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
        .backgroundColor('#B300B3')
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.showThirdPartyContentAlert();
        })
      }

      // ── ③ 进度条（对应 Android ProgressBar，浮于 WebView 上方）──
      if (this.showProgress && this.progress > 0 && this.progress < 100) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color('#B300B3')
      }

      // ── ④ 主体区域 ──
      if (this.webSrc.length === 0) {
        // Loading 占位（url 为空时，等待 Presenter 异步回调）
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
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

      } else {

        // WebView
        Web({ src: '', controller: this.controller })
          .width('100%')
          .layoutWeight(1)
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .mixedMode(MixedMode.All)
          // 对应 Android useWideViewPort=true：尊重 viewport meta，避免页面被强制压缩
          .wideViewModeAccess(true)
          // 对应 Android loadWithOverviewMode=true：初始以全屏宽显示页面
          .overviewModeAccess(true)
          // 对应 Android setSupportZoom(true)
          .zoomAccess(true)
          // 对应 Android userAgentString + "/WxPusher-Android"
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
            this.showProgress = p < 100;
          })
          .onPageBegin((event) => {
            // 对应 Android onPageStarted
            const url = event?.url ?? '';
            this.currentUrl = url;
            this.bridgeManager?.updateCurrentUrl(url);
            this.showProgress = true;
            this.progress = 0;
            this.updateThirdPartyBanner(url);
            this.applyBottomBarVisible(url);
            this.applyOptionMenuVisible(url);
          })
          .onPageEnd((event) => {
            // 对应 Android onPageFinished
            const url = event?.url ?? '';
            this.currentUrl = url;
            this.bridgeManager?.updateCurrentUrl(url);
            this.showProgress = false;
            this.updateThirdPartyBanner(url);
            this.applyBottomBarVisible(url);
            this.applyOptionMenuVisible(url);
            try {
              this.canGoBack = this.controller.accessBackward();
              this.canGoForward = this.controller.accessForward();
            } catch {
              // ignore
            }
          })
          .onControllerAttached(() => {
            if (this.webSrc.length > 0) {
              this.controller.loadUrl(this.webSrc, this.buildLoadHeaders(this.webSrc));
            }
          })
          .onLoadIntercept((event) => {
            const url = event?.data?.getRequestUrl() ?? '';
            if (url.length === 0) {
              return false;
            }
            if (WxpWebHostPolicy.isUrlInWhitelist(url) && url !== this.lastLoadedUrl) {
              this.lastLoadedUrl = url;
              this.currentUrl = url;
              this.bridgeManager?.updateCurrentUrl(url);
              this.controller.loadUrl(url, this.buildLoadHeaders(url));
              return true;
            }
            return false;
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
                this.bridgeManager?.onMessage(message);
              },
            },
            name: 'wxpusher',
            methodList: ['postMessage'],
            controller: this.controller,
          })
          .onInterceptRequest((_event) => {
            // 该回调用于资源级拦截；页面主请求 Header 注入由 onLoadIntercept + loadUrl 处理。
            return null;
          })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

        // ── ⑤ 底部工具栏（对应 Android webOptionView）──
        // showBottomBar：调用方静态关闭（ProviderListTab = false）
        // bottomBarVisible：URL 规则 + Bridge 动态控制（WebViewPage 场景）
        if (this.showBottomBar && this.bottomBarVisible) {
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

              // 关闭 / 主页（对应 Android closeButton，可被子类重写）
              // onCloseButtonClicked 为 null → ic_close + router.back()
              // onCloseButtonClicked 非 null → ic_home + 调用回调（如 ProviderListFragment 行为）
              Column() {
                Image(this.onCloseButtonClicked !== null
                  ? $r('app.media.ic_home')
                  : $r('app.media.ic_close'))
                  .width(26)
                  .height(26)
                  .fillColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                    ? '#E5E5E5' : '#333333')
              }
              .layoutWeight(1)
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                if (this.onCloseButtonClicked !== null) {
                  this.onCloseButtonClicked();
                } else {
                  router.back();
                }
              })

            }
            .width('100%')
            .height(55)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .backgroundColor(this.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
            ? '#1C1C1E' : Color.White)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        }

      }

    }
    .width('100%')
    .height('100%')
  }
}
