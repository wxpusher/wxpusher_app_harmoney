import { deviceInfo } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';
import { WxpSubscribeIntentFactors } from '@wxpusher/shared';

/**
 * 安装后还原用的设备多因素，口径和 H5 落地页一致：屏幕用 vp，竖屏短边为宽。
 * 网络类型不采集（需要额外权限），服务端按缺失处理。
 */
export function collectSubscribeFactors(): WxpSubscribeIntentFactors {
  const factors: WxpSubscribeIntentFactors = {
    os: 'harmony',
    osVersion: `${deviceInfo.majorVersion}.${deviceInfo.seniorVersion}`,
    model: deviceInfo.productModel,
  };
  try {
    const d = display.getDefaultDisplaySync();
    const density = d.densityPixels > 0 ? d.densityPixels : 1;
    factors.screenW = Math.round(Math.min(d.width, d.height) / density);
    factors.screenH = Math.round(Math.max(d.width, d.height) / density);
    factors.dpr = density;
  } catch (_e) {
    // 取不到屏幕信息就不带，服务端按缺失处理
  }
  try {
    factors.lang = i18n.System.getSystemLocale();
    factors.tz = i18n.getTimeZone().getID();
  } catch (_e) {
    // 同上
  }
  return factors;
}
