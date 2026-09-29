import { MessageListTab } from './tabs/MessageListTab';
import { ProviderListTab } from './tabs/ProviderListTab';
import { ExtFuncTab } from './tabs/ExtFuncTab';
import { ProfileTab } from './tabs/ProfileTab';
import { router } from '@kit.ArkUI';
import { WxpAppDataService, WxpSaveService, WxpTabConfigStore, WxpTabConfig } from '@wxpusher/shared';
import { USER_HAS_AGREEMENT_KEY } from '../common/WxpAppGateKeys';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;
  // 当前有序 tab 列表（按显隐配置动态构建），元素为 tab key
  @State private tabs: string[] = ['messageList', 'market', 'extFunc', 'profile'];
  private tabsController: TabsController = new TabsController();
  private hasCheckedGate: boolean = false;
  // 已应用的可配置 tab 快照，用于 diff，仅变化才重建
  private appliedMarket: boolean = true;
  private appliedExtFunc: boolean = true;
  // KV 变更监听 id（保存即广播机制）
  private kvListenerId: number = -1;

  aboutToAppear(): void {
    if (this.hasCheckedGate) {
      return;
    }
    if (!WxpSaveService.getBoolean(USER_HAS_AGREEMENT_KEY, false)) {
      this.hasCheckedGate = true;
      router.replaceUrl({
        url: 'pages/UserAgreementPage',
        params: { force: true },
      });
      return;
    }
    const deviceToken = WxpAppDataService.getLoginInfo()?.deviceToken;
    if (!deviceToken) {
      this.hasCheckedGate = true;
      router.replaceUrl({ url: 'pages/LoginPage' });
      return;
    }
    this.hasCheckedGate = true;
    // 按 tab 显隐配置构建底部 tab
    const config = WxpTabConfigStore.read();
    this.appliedMarket = config.market;
    this.appliedExtFunc = config.extFunc;
    this.tabs = this.buildTabs(config);
    // 注册 KV 变更监听（保存即广播）：tab_config 变化即重建，未变不动
    this.kvListenerId = WxpSaveService.addListener((key: string) => {
      if (key === WxpTabConfigStore.TAB_CONFIG_KEY) {
        this.refreshTabsIfConfigChanged();
      }
    });
  }

  aboutToDisappear(): void {
    if (this.kvListenerId >= 0) {
      WxpSaveService.removeListener(this.kvListenerId);
      this.kvListenerId = -1;
    }
  }

  // KV 广播回调：配置变化则重建（未变不动，避免闪烁）
  private refreshTabsIfConfigChanged(): void {
    const config = WxpTabConfigStore.read();
    if (config.market === this.appliedMarket && config.extFunc === this.appliedExtFunc) {
      return;
    }
    const currentKey: string = (this.currentIndex >= 0 && this.currentIndex < this.tabs.length)
      ? this.tabs[this.currentIndex] : 'messageList';
    this.appliedMarket = config.market;
    this.appliedExtFunc = config.extFunc;
    const newTabs = this.buildTabs(config);
    this.tabs = newTabs;
    // 恢复到原来所在 tab；若该 tab 已被隐藏，回落到消息列表
    let idx = newTabs.indexOf(currentKey);
    if (idx < 0) {
      idx = 0;
    }
    this.currentIndex = idx;
    this.tabsController.changeIndex(idx);
  }

  // 有序构建：消息列表(必) → 消息市场(可配) → 扩展功能(可配) → 我的(必)
  private buildTabs(config: WxpTabConfig): string[] {
    const list: string[] = ['messageList'];
    if (config.market) {
      list.push('market');
    }
    if (config.extFunc) {
      list.push('extFunc');
    }
    list.push('profile');
    return list;
  }

  private tabTitle(key: string): string {
    if (key === 'messageList') {
      return '消息列表';
    }
    if (key === 'market') {
      return '消息市场';
    }
    if (key === 'extFunc') {
      return '扩展功能';
    }
    return '我的';
  }

  private tabIcon(key: string): Resource {
    if (key === 'messageList') {
      return $r('app.media.ic_paperplane');
    }
    if (key === 'market') {
      return $r('app.media.ic_cloud');
    }
    if (key === 'extFunc') {
      return $r('app.media.ic_ext_func');
    }
    return $r('app.media.ic_person');
  }

  @Builder
  tabBuilder(title: string, index: number, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? $r('app.color.wxp_brand') : $r('sys.color.font_secondary'))
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? $r('app.color.wxp_brand') : $r('sys.color.font_secondary'))
        .margin({ top: 2 })
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = index;
      this.tabsController.changeIndex(index);
    })
  }

  @Builder
  tabContentBuilder(key: string) {
    if (key === 'messageList') {
      MessageListTab({ currentTabIndex: this.currentIndex })
    } else if (key === 'market') {
      ProviderListTab({ currentTabIndex: this.currentIndex })
    } else if (key === 'extFunc') {
      ExtFuncTab({ currentTabIndex: this.currentIndex })
    } else {
      ProfileTab()
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
      ForEach(this.tabs, (key: string, index: number) => {
        TabContent() {
          this.tabContentBuilder(key)
        }
        .tabBar(this.tabBuilder(this.tabTitle(key), index, this.tabIcon(key)))
      }, (key: string) => key)
    }
    .scrollable(false)
    .barHeight(56)
    .barBackgroundColor($r('sys.color.background_primary'))
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
