// ─────────────────────────────────────────────────────────
// 消息市场 Tab（对齐 Android WxpProviderListFragment）
// ─────────────────────────────────────────────────────────

import {
  WxpProviderListPresenter,
  IWxpProviderListPresenter,
  IWxpProviderListView,
} from '@wxpusher/shared';
import { WxpWebViewComponent } from '../../components/WxpWebViewComponent';

@Component
export struct ProviderListTab {
  /** 父级传入的当前 Tab 索引，用于感知 resume（目前市场 Tab index = 1）*/
  @Prop @Watch('onTabIndexChanged') currentTabIndex: number = 0;

  /** 传给 WxpWebViewComponent 的 URL；空字符串 = 显示 loading 占位 */
  @State private webUrl: string = '';

  private presenter: IWxpProviderListPresenter | null = null;

  // ── IWxpProviderListView 实现 ──

  /**
   * 对应 Android WxpProviderListFragment.onLoadPage → loadWebContent(url)。
   * Presenter 获取 openId 成功后回调此方法，触发 WebView 加载。
   */
  onLoadPage(url: string): void {
    this.webUrl = url;
  }

  createPresenter(): IWxpProviderListPresenter {
    return new WxpProviderListPresenter(this);
  }

  // ── 生命周期 ──

  aboutToAppear(): void {
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

  // ── Build ──

  build() {
    Column() {

      // 顶部标题栏（自管，不使用 WxpWebViewComponent 内置导航栏）
      // 对应 Android：隐藏 ActionBar 返回按钮，固定标题"消息市场"
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

      // WebView 组件：
      //   showNavBar = false   — 不显示内置导航栏（上方已有自管标题栏）
      //   showBottomBar = false — Tab 内嵌场景不需要底部工具栏（系统 Tab 栏已在底部）
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
