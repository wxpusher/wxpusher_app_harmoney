/**
 * 跳转应用市场的能力抽象，由端侧注入实现。
 *
 * HarmonyOS：检测到更新统一弹窗提醒，点「去升级」拉起华为应用市场（AppGallery）当前 App 详情页。
 * 鸿蒙无 TBS，无需 downgradeToTbs 分流。
 */
export interface WxpAppMarketNavigator {
  jumpToMarket(downloadUrl: string): void;
}
