import { WxpSaveService } from '../../base/common/WxpSaveService';

/**
 * 底部 tab 显隐配置。「消息列表」「我的」为核心 tab 恒显示，此处仅管理两个可配置 tab。
 * 与 H5（app-fe common/TabConfig.ts）约定同一份 JSON 结构，缺省全部显示。
 */
export interface WxpTabConfig {
  market: boolean;
  extFunc: boolean;
}

export class WxpTabConfigStore {
  // 与 H5 约定的存储 key（原生与 H5 共享同一 WxpSaveService，无前缀）
  static readonly TAB_CONFIG_KEY = 'tab_config';

  static read(): WxpTabConfig {
    const defaultConfig: WxpTabConfig = { market: true, extFunc: true };
    const raw = WxpSaveService.getString(WxpTabConfigStore.TAB_CONFIG_KEY, '');
    if (raw.length === 0) {
      return defaultConfig;
    }
    try {
      const obj = JSON.parse(raw) as Record<string, Object>;
      // 只有显式 false 才隐藏，缺省/异常按显示处理
      const config: WxpTabConfig = {
        market: obj['market'] !== false,
        extFunc: obj['extFunc'] !== false,
      };
      return config;
    } catch (e) {
      return defaultConfig;
    }
  }
}
