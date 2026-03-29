import { promptAction } from '@kit.ArkUI';
import { IWxpToastBackend } from '@wxpusher/shared';

/**
 * HarmonyOS 平台 Toast 实现
 */
export class WxpToastUtilsImpl implements IWxpToastBackend {
  showToast(msg: string): void {
    try {
      promptAction.showToast({
        message: msg,
        duration: 2000,
      });
    } catch (e) {
      console.error('showToast error:', (e as Error).message);
    }
  }
}
