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

  // 上报信息去重
  private static hasUpdateInfoData: WxpUpdateInfoReq | null = null;
  private static hasUpdateInfoDataTime: number = 0;

  static init(): void {
    // 设置 NetworkService 的登录信息获取器
    WxpNetworkService.setLoginInfoGetter(() => {
      return WxpAppDataService.getLoginInfo()?.deviceToken ?? '';
    });
    WxpAppDataService.getUserDeviceInfo();
  }

  /**
   * 上传设备信息到服务器
   */
  static updateDeviceInfo(platform?: string): void {
    (async () => {
      try {
        const loginInfo = WxpAppDataService.getLoginInfo();
        const updateInfoReq: WxpUpdateInfoReq = {
          deviceUuid: loginInfo?.deviceId,
          pushToken: WxpAppDataService.getPushToken() ?? undefined,
          platform: platform,
        };
        // 避免重复上报
        if (WxpAppDataService.hasUpdateInfoData !== null
          && JSON.stringify(WxpAppDataService.hasUpdateInfoData) === JSON.stringify(updateInfoReq)
          && WxpDateTimeUtils.getTimestamp() - WxpAppDataService.hasUpdateInfoDataTime < 3600000
        ) {
          return;
        }
        WxpAppDataService.hasUpdateInfoData = updateInfoReq;
        WxpAppDataService.hasUpdateInfoDataTime = WxpDateTimeUtils.getTimestamp();
        await WxpApiService.updateDeviceInfo(updateInfoReq, () => {
          WxpLogUtils.i('WxPusher', `更新pushToken成功,updateInfoReq=${JSON.stringify(updateInfoReq)}`);
        });
      } catch (e) {
        WxpLogUtils.e('WxPusher', '更新设备信息失败', e as Error);
      }
    })();
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
