import { WxpConfig } from '../../config/WxpConfig';
import { WxpApiService } from '../../api/WxpApiService';
import { WxpBaseInfoService } from '../common/WxpBaseInfoService';
import { WxpLogUtils } from '../common/WxpLogUtils';
import { WxpSaveService } from '../common/WxpSaveService';
import { WxpDateTimeUtils } from '../common/WxpDateTimeUtils';
import { WxpLoadingUtils } from '../common/WxpLoadingUtils';
import { WxpNetworkService } from '../common/WxpNetworkService';
import { WxpAppPageService } from './WxpAppPageService';
import { WxpLoginInfo, createWxpLoginInfoFromResp } from './bean/WxpLoginInfo';
import { WxpPlatformEnum } from './bean/WxpPlatformEnum';
import { WxpUpdateInfoReq } from './bean/WxpUpdateInfoBean';
import { WxpMessageListMessage } from '../../page/messagelist/WxpMessageListBean';

/**
 * 对应 KMP WxpAppDataService.kt
 */
export class WxpAppDataService {
  private static readonly MessageListCacheKey = 'WxpMessageList_MessageSaveCacheKey';
  private static readonly SaveLoginInfoKey = 'SaveLoginInfoKey';
  private static readonly PushTokenKey = 'PushTokenKey';
  private static readonly ApiUrl = 'ApiUrl';
  private static readonly WebKey = 'WebKey';
  private static readonly WsUrlKey = 'WsUrlKey';

  /** 相同设备信息的最小重复上报间隔。 */
  private static readonly DEVICE_INFO_REPORT_INTERVAL_MILLIS = 60 * 60 * 1000;

  // 上报信息去重
  private static hasUpdateInfoData: WxpUpdateInfoReq | null = null;
  private static hasUpdateInfoDataTime: number = 0;

  // 正在上报中的内容，用于挡掉冷启动时多个入口发起的完全相同的请求。
  private static reportingInfoData: WxpUpdateInfoReq | null = null;

  static init(): void {
    // 设置 NetworkService 的登录信息获取器
    WxpNetworkService.setLoginInfoGetter(() => {
      return WxpAppDataService.getLoginInfo()?.deviceToken ?? '';
    });
    WxpAppDataService.getUserDeviceInfo();
  }

  /**
   * 上传当前已经生效的平台和 pushToken。
   *
   * HarmonyOS 只有 Push Kit 一条通道，platform 为空时使用当前生效平台，不能再单独覆盖 token。
   *
   * @param platform 需要上报的推送路由平台，为空时使用当前生效平台。
   * @param silent 后台自动上报传 true，失败时不弹 toast，也不会跳转登录页。
   */
  static updateDeviceInfo(platform?: string, silent: boolean = false): void {
    (async () => {
      // 读取登录信息 / token 也可能抛异常，整段包在 try 内，避免变成未捕获的 Promise 异常。
      let reportingReq: WxpUpdateInfoReq | null = null;
      try {
        const loginInfo = WxpAppDataService.getLoginInfo();
        const updateInfoReq: WxpUpdateInfoReq = {
          deviceUuid: loginInfo?.deviceId,
          pushToken: WxpAppDataService.getPushToken() ?? undefined,
          platform: platform ?? WxpBaseInfoService.getEffectivePushPlatform(),
        };
        // 相同内容一小时内不重复上报；token 或平台变化时仍然立即上报。
        if (WxpAppDataService.isSameUpdateInfo(WxpAppDataService.hasUpdateInfoData, updateInfoReq)
          && !WxpAppDataService.isDeviceInfoReportExpired()) {
          return;
        }
        // 冷启动时多个入口可能同时发起完全相同的请求，在途的直接跳过。
        if (WxpAppDataService.isSameUpdateInfo(WxpAppDataService.reportingInfoData, updateInfoReq)) {
          return;
        }

        reportingReq = updateInfoReq;
        WxpAppDataService.reportingInfoData = updateInfoReq;
        await WxpApiService.updateDeviceInfo(updateInfoReq, silent, () => {
          // 只有上报成功后才记录去重状态，失败请求允许后续继续重试。
          WxpAppDataService.recordDeviceInfoReportSuccess(updateInfoReq);
          WxpLogUtils.i('WxPusher', `更新pushToken成功,updateInfoReq=${JSON.stringify(updateInfoReq)}`);
        });
      } catch (e) {
        WxpLogUtils.e('WxPusher', '更新设备信息失败', e as Error);
      } finally {
        // 期间可能已经有更新的内容开始上报，不能把它的在途标记清掉。
        if (reportingReq !== null && WxpAppDataService.reportingInfoData === reportingReq) {
          WxpAppDataService.reportingInfoData = null;
        }
      }
    })();
  }

  /**
   * App 进入前台时按需重新上报 push token 和设备活跃信息。
   *
   * Push Kit 返回 token 失效后，服务端会把设备标记为异常并跳过后续推送；客户端使用仍然
   * 有效的 token 重新上报后，服务端会恢复正常状态。进程存活期间使用一小时间隔避免频繁请求；
   * 冷启动会重新上报，失败不会更新时间，后续进入前台仍可重试。
   *
   * deviceId、pushToken 和相同内容去重都由 updateDeviceInfo 和接口层统一校验，
   * 这里只判断登录态和上报间隔，避免同一条规则散落在多处。
   */
  static reportHarmonyActiveIfNeeded(): void {
    if (!WxpAppDataService.getLoginInfo()?.deviceToken || !WxpAppDataService.isDeviceInfoReportExpired()) {
      return;
    }
    WxpLogUtils.i('WxPusher', 'HarmonyOS进入前台，重新上报push token和设备活跃信息');
    WxpAppDataService.updateDeviceInfo(undefined, true);
  }

  /**
   * 判断距离最近一次成功上报是否已经超过间隔。
   *
   * 与 Android / iOS 共用同一套一小时规则。尚未成功上报过，或系统时间回拨导致间隔为负时，
   * 都允许立即上报，避免异常时间让设备长期无法恢复正常状态。
   */
  static isDeviceInfoReportExpired(): boolean {
    const elapsed = WxpDateTimeUtils.getTimestamp() - WxpAppDataService.hasUpdateInfoDataTime;
    return elapsed < 0 || elapsed >= WxpAppDataService.DEVICE_INFO_REPORT_INTERVAL_MILLIS;
  }

  /**
   * 记录最近一次成功上报的内容和时间。
   *
   * 只能在服务端明确返回成功后调用；失败请求不能更新，否则会阻止后续前台重试。
   */
  static recordDeviceInfoReportSuccess(reportedInfo: WxpUpdateInfoReq): void {
    WxpAppDataService.hasUpdateInfoData = reportedInfo;
    WxpAppDataService.hasUpdateInfoDataTime = WxpDateTimeUtils.getTimestamp();
  }

  /** 比较两次上报内容是否完全相同，对应 KMP 里 data class 的等值判断。 */
  private static isSameUpdateInfo(left: WxpUpdateInfoReq | null, right: WxpUpdateInfoReq): boolean {
    return left !== null && JSON.stringify(left) === JSON.stringify(right);
  }

  /**
   * 删除账号
   */
  static removeAccount(): void {
    (async () => {
      WxpLoadingUtils.showLoading('处理中', false);
      const result = await WxpApiService.removeAccount();
      WxpLoadingUtils.dismissLoading();
      if (result === true) {
        WxpSaveService.setString(WxpAppDataService.SaveLoginInfoKey, '');
        WxpAppPageService.jumpToLogin();
      }
    })();
  }

  /**
   * 补全用户数据
   */
  static getUserDeviceInfo(): void {
    const loginInfo = WxpAppDataService.getLoginInfo();
    if (!loginInfo?.deviceToken) {
      return;
    }
    if (loginInfo.version === WxpConfig.UserLoginInfoVersion) {
      return;
    }
    (async () => {
      try {
        const result = await WxpApiService.getUserDeviceInfo();
        if (result) {
          WxpAppDataService.saveLoginInfo(createWxpLoginInfoFromResp(result));
          WxpLogUtils.i('WxPusher', '补全用户数据完成');
        }
      } catch (e) {
        WxpLogUtils.e('WxPusher', '补全用户数据失败', e as Error);
      }
    })();
  }

  static getLoginInfo(): WxpLoginInfo | null {
    const str = WxpAppDataService.getLoginInfoStr();
    if (!str || str.length === 0) {
      return null;
    }
    try {
      return JSON.parse(str) as WxpLoginInfo;
    } catch {
      return null;
    }
  }

  static saveOpenId(openId: string | null | undefined): void {
    if (!openId || openId.length === 0) {
      return;
    }
    (async () => {
      const loginInfo = WxpAppDataService.getLoginInfo();
      if (loginInfo) {
        loginInfo.openId = openId;
        WxpAppDataService.saveLoginInfo(loginInfo);
      }
    })();
  }

  static getCacheMessageList(): WxpMessageListMessage[] | null {
    const str = WxpSaveService.getString(WxpAppDataService.MessageListCacheKey, '');
    if (str.length === 0) {
      return null;
    }
    try {
      return JSON.parse(str) as WxpMessageListMessage[];
    } catch {
      return null;
    }
  }

  static setCacheMessageList(messageList: WxpMessageListMessage[] | null): void {
    if (!messageList || messageList.length === 0) {
      WxpSaveService.setString(WxpAppDataService.MessageListCacheKey, '');
      return;
    }
    WxpSaveService.setString(WxpAppDataService.MessageListCacheKey, JSON.stringify(messageList));
  }

  static getLoginInfoStr(): string | null {
    return WxpSaveService.getString(WxpAppDataService.SaveLoginInfoKey, '');
  }

  static saveLoginInfo(loginInfo: WxpLoginInfo): void {
    WxpSaveService.setString(WxpAppDataService.SaveLoginInfoKey, JSON.stringify(loginInfo));
  }

  static getPushToken(): string | null {
    return WxpSaveService.getString(WxpAppDataService.PushTokenKey, '') || null;
  }

  static savePushToken(pushToken: string | null): void {
    WxpSaveService.setString(WxpAppDataService.PushTokenKey, pushToken);
  }

  static saveApiUrl(baseApiUrl: string | null): void {
    WxpSaveService.setString(WxpAppDataService.ApiUrl, baseApiUrl);
  }

  static getApiUrl(): string {
    return WxpSaveService.getString(WxpAppDataService.ApiUrl, 'https://wxpusher.zjiecode.com');
  }

  static saveWebUrl(webUrl: string | null): void {
    WxpSaveService.setString(WxpAppDataService.WebKey, webUrl);
  }

  static getWebUrl(): string {
    return WxpSaveService.getString(WxpAppDataService.WebKey, 'https://static.zjiecode.com/wxpusher/web-app');
  }

  static saveWsUrl(wsUrl: string | null): void {
    WxpSaveService.setString(WxpAppDataService.WsUrlKey, wsUrl);
  }

  static getWsUrl(): string {
    return WxpSaveService.getString(WxpAppDataService.WsUrlKey, 'wss://wxpusher.zjiecode.com');
  }
}
