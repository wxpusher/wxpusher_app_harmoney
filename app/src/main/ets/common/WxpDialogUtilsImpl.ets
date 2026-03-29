import { promptAction } from '@kit.ArkUI';
import { IWxpDialogBackend, WxpDialogParams } from '@wxpusher/shared';

/**
 * HarmonyOS 平台 Dialog 实现
 */
export class WxpDialogUtilsImpl implements IWxpDialogBackend {
  showDialog(params: WxpDialogParams): void {
    try {
      const buttons: promptAction.Button[] = [];
      if (params.leftText) {
        buttons.push({ text: params.leftText, color: '#666666' });
      }
      if (params.rightText) {
        buttons.push({ text: params.rightText, color: '#007AFF' });
      }

      promptAction.showDialog({
        title: params.title ?? '',
        message: params.message ?? '',
        buttons: buttons,
      }).then((result) => {
        if (result.index === 0 && params.leftText) {
          params.leftBlock?.();
        } else if ((result.index === 1 && params.rightText) || (result.index === 0 && !params.leftText)) {
          params.rightBlock?.();
        }
      });
    } catch (e) {
      console.error('showDialog error:', (e as Error).message);
    }
  }
}
