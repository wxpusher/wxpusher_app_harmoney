import { promptAction } from '@kit.ArkUI';
import { IWxpDialogBackend, WxpDialogParams } from '@wxpusher/shared';

/**
 * HarmonyOS 平台 Dialog 实现
 */
export class WxpDialogUtilsImpl implements IWxpDialogBackend {
  showDialog(params: WxpDialogParams): void {
    this.doShow(params);
  }

  private doShow(params: WxpDialogParams): void {
    try {
      const buttons: promptAction.Button[] = [];
      if (params.leftText) {
        buttons.push({ text: params.leftText, color: '#666666' });
      }
      if (params.rightText) {
        buttons.push({ text: params.rightText, color: '#B300B3' });
      }

      // cancelable === false 表示强制弹窗（如强制更新），禁止点击蒙层 / 返回关闭。
      // promptAction.showDialog 无禁用蒙层关闭的选项，这里用 isModal + 关闭后重新弹出做兜底。
      const cancelable = params.cancelable !== false;

      promptAction.showDialog({
        title: params.title ?? '',
        message: params.message ?? '',
        buttons: buttons,
        isModal: true,
      }).then((result) => {
        const clickedLeft = result.index === 0 && !!params.leftText;
        const clickedRight = (result.index === 1 && !!params.rightText) ||
          (result.index === 0 && !params.leftText);
        if (clickedLeft) {
          params.leftBlock?.();
        } else if (clickedRight) {
          params.rightBlock?.();
        } else if (!cancelable) {
          // 非按钮触发的关闭（蒙层/返回），强制弹窗需重新弹出
          this.doShow(params);
        }
      }).catch(() => {
        // 被系统关闭（如返回键）时，强制弹窗重新弹出
        if (!cancelable) {
          this.doShow(params);
        }
      });
    } catch (e) {
      console.error('showDialog error:', (e as Error).message);
    }
  }
}
