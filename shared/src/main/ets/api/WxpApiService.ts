import { WxpAppPageService } from '../base/biz/WxpAppPageService';
import { WxpUpdateInfoReq } from '../base/biz/bean/WxpUpdateInfoBean';
import { BaseResp, WxpNetworkService } from '../base/common/WxpNetworkService';
import { WxpLogUtils } from '../base/common/WxpLogUtils';
import { WxpToastUtils } from '../base/common/WxpToastUtils';
import { WxpAppleBindReq, WxpHuaweiBindReq, WxpWeixinBindReq } from '../page/accountdetail/WxpAccountBindBean';
import { WxpPhoneBindReq } from '../page/changephone/WxpChangePhoneBean';
import {
  WxpAppleLoginReq,
  WxpAppleLoginResp,
  WxpBaseLoginResp,
  WxpHuaweiLoginReq,
  WxpHuaweiLoginResp,
  WxpLoginSendVerifyCodeReq,
  WxpLoginSendVerifyCodeResp,
  WxpWeixinLoginReq,
  WxpWeixinLoginResp,
} from '../page/login/WxpLoginBean';
import {
  WxpCheckAppMsgReasonResp,
  WxpListBannerResp,
  WxpMessageListMessage,
  WxpMessageListReq,
} from '../page/messagelist/WxpMessageListBean';
import { WxpScanQrcodeResp } from '../page/scan/WxpScanBean';
import { AppVersionCheckResp } from '../biz/version/AppVersionCheckResp';

/**
 * 对应 KMP WxpApiService.kt
 */
export class BizError extends Error {
  code: number;

  constructor(code: number, msg: string) {
    super(msg);
    this.code = code;
  }
}

export class WxpApiService {
  static async commonRespDeal<T>(
    block: () => Promise<BaseResp<T>>,
    toastError: boolean = true,
    successBlock?: (data: T) => void,
    errorBlock?: (e: Error) => void,
  ): Promise<T | null> {
    try {
      const resp = await block();
      if (resp.code === 1000) {
        successBlock?.(resp.data);
        return resp.data;
      }
      if (resp.code === 1002) {
        WxpAppPageService.jumpToLogin();
        return null;
      }
      if (toastError) {
        WxpToastUtils.showToast(resp.msg);
      }
      errorBlock?.(new BizError(resp.code, resp.msg));
    } catch (e) {
      const error = e as Error;
      if (toastError) {
        if (error.message?.includes('net::') || error.message?.includes('network')) {
          WxpToastUtils.showToast('请检查网络');
        } else {
          WxpToastUtils.showToast(error.message);
        }
      }
      errorBlock?.(error);
    }
    return null;
  }

  static async sendLoginPing(): Promise<string | null> {
    return WxpApiService.commonRespDeal<string>(
      () => WxpNetworkService.get<string>(WxpNetworkService.getUrl('/api/device/login-ping'))
    );
  }

  static async sendVerifyCode(phone: string): Promise<boolean | null> {
    return WxpApiService.commonRespDeal<boolean>(
      () => WxpNetworkService.post<boolean>(
        WxpNetworkService.getUrl('/api/device/send-verify-code'),
        { phone }
      )
    );
  }

  static async verifyCodeLogin(req: WxpLoginSendVerifyCodeReq): Promise<WxpLoginSendVerifyCodeResp | null> {
    return WxpApiService.commonRespDeal<WxpLoginSendVerifyCodeResp>(
      () => WxpNetworkService.post<WxpLoginSendVerifyCodeResp>(
        WxpNetworkService.getUrl('/api/device/verify-code-login'),
        req
      )
    );
  }

  static async logout(
    successBlock?: () => void,
    errorBlock?: () => void,
  ): Promise<boolean | null> {
    return WxpApiService.commonRespDeal<boolean>(
      () => WxpNetworkService.post<boolean>(
        WxpNetworkService.getUrl('/api/need-login/device/logout')
      ),
      true,
      () => successBlock?.(),
      () => errorBlock?.(),
    );
  }

  static async weixinLogin(req: WxpWeixinLoginReq): Promise<WxpWeixinLoginResp | null> {
    return WxpApiService.commonRespDeal<WxpWeixinLoginResp>(
      () => WxpNetworkService.post<WxpWeixinLoginResp>(
        WxpNetworkService.getUrl('/api/device/weixin-login'),
        req
      )
    );
  }

  static async appleLogin(req: WxpAppleLoginReq): Promise<WxpAppleLoginResp | null> {
    return WxpApiService.commonRespDeal<WxpAppleLoginResp>(
      () => WxpNetworkService.post<WxpAppleLoginResp>(
        WxpNetworkService.getUrl('/api/device/apple-login'),
        req
      )
    );
  }

  static async huaweiLogin(req: WxpHuaweiLoginReq): Promise<WxpHuaweiLoginResp | null> {
    return WxpApiService.commonRespDeal<WxpHuaweiLoginResp>(
      () => WxpNetworkService.post<WxpHuaweiLoginResp>(
        WxpNetworkService.getUrl('/api/device/huawei-login'),
        req
      )
    );
  }

  static async weixinBind(req: WxpWeixinBindReq): Promise<boolean | null> {
    return WxpApiService.commonRespDeal<boolean>(
      () => WxpNetworkService.put<boolean>(
        WxpNetworkService.getUrl('/api/need-login/device/weixin-bind'),
        req
      )
    );
  }

  static async appleBind(req: WxpAppleBindReq): Promise<boolean | null> {
    return WxpApiService.commonRespDeal<boolean>(
      () => WxpNetworkService.put<boolean>(
        WxpNetworkService.getUrl('/api/need-login/device/apple-bind'),
        req
      )
    );
  }

  static async huaweiBind(req: WxpHuaweiBindReq): Promise<boolean | null> {
    return WxpApiService.commonRespDeal<boolean>(
      () => WxpNetworkService.put<boolean>(
        WxpNetworkService.getUrl('/api/need-login/device/huawei-bind'),
        req
      )
    );
  }

  static async phoneBind(req: WxpPhoneBindReq): Promise<boolean | null> {
    return WxpApiService.commonRespDeal<boolean>(
      () => WxpNetworkService.put<boolean>(
        WxpNetworkService.getUrl('/api/need-login/device/phone-bind'),
        req
      )
    );
  }

  static async removeAccount(): Promise<boolean | null> {
    return WxpApiService.commonRespDeal<boolean>(
      () => WxpNetworkService.delete<boolean>(
        WxpNetworkService.getUrl('/api/need-login/device/remove-account')
      )
    );
  }

  static async updateDeviceInfo(
    req: WxpUpdateInfoReq,
    successBlock?: () => void,
  ): Promise<boolean | null> {
    if (!req.deviceUuid || !req.pushToken) {
      return false;
    }
    WxpLogUtils.d('WxPusher', '上报设备信息-updateDeviceInfo');
    return WxpApiService.commonRespDeal<boolean>(
      () => WxpNetworkService.put<boolean>(
        WxpNetworkService.getUrl('/api/need-login/device/update-device-info'),
        req
      ),
      true,
      () => successBlock?.(),
    );
  }

  static async fetchMessageList(req: WxpMessageListReq): Promise<WxpMessageListMessage[] | null> {
    const params: Record<string, string> = {
      'messageId': String(req.messageId),
    };
    if (req.key) {
      params['key'] = req.key;
    }
    if (req.scene !== undefined && req.scene !== null) {
      params['scene'] = String(req.scene);
    }
    return WxpApiService.commonRespDeal<WxpMessageListMessage[]>(
      () => WxpNetworkService.get<WxpMessageListMessage[]>(
        WxpNetworkService.getUrl('/api/need-login/device/message/list-v2'),
        params
      )
    );
  }

  static async markMessageReadStatus(
    messageId: number | null | undefined,
    read: boolean,
    successBlock: () => void,
  ): Promise<void | null> {
    const params: Record<string, string> = {
      'read': String(read),
    };
    if (messageId !== null && messageId !== undefined) {
      params['messageId'] = String(messageId);
    }
    const baseUrl = WxpNetworkService.getUrl('/api/need-login/device/message/read-mark');
    const query = Object.entries(params)
      .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
      .join('&');
    const fullUrl = baseUrl + '?' + query;
    return WxpApiService.commonRespDeal<void>(
      () => WxpNetworkService.put<void>(fullUrl),
      true,
      () => successBlock(),
    );
  }

  static async deleteMessageById(
    messageId: number,
    successBlock: () => void,
  ): Promise<void | null> {
    return WxpApiService.commonRespDeal<void>(
      () => WxpNetworkService.delete<void>(
        WxpNetworkService.getUrl('/api/need-login/device/message/delete'),
        { 'messageId': String(messageId) }
      ),
      true,
      () => successBlock(),
    );
  }

  /**
   * 批量标记消息已读状态
   * @param messageIds 非空的消息id集合，单次最多 200 条
   * @param read 是否标记为已读状态
   */
  static async markMessageReadStatusBatch(
    messageIds: number[],
    read: boolean,
    successBlock: () => void,
  ): Promise<void | null> {
    const baseUrl = WxpNetworkService.getUrl('/api/need-login/device/message/read-mark');
    const query = `messageIds=${encodeURIComponent(messageIds.join(','))}&read=${encodeURIComponent(String(read))}`;
    const fullUrl = baseUrl + '?' + query;
    return WxpApiService.commonRespDeal<void>(
      () => WxpNetworkService.put<void>(fullUrl),
      true,
      () => successBlock(),
    );
  }

  /**
   * 批量删除消息
   * @param messageIds 非空的消息id集合，单次最多 200 条
   */
  static async deleteMessagesByIds(
    messageIds: number[],
    successBlock: () => void,
  ): Promise<void | null> {
    return WxpApiService.commonRespDeal<void>(
      () => WxpNetworkService.delete<void>(
        WxpNetworkService.getUrl('/api/need-login/device/message/delete'),
        { 'messageIds': messageIds.join(',') }
      ),
      true,
      () => successBlock(),
    );
  }

  /**
   * 删除当前用户的全部消息（清空）
   */
  static async deleteAllMessages(
    successBlock: () => void,
  ): Promise<void | null> {
    return WxpApiService.commonRespDeal<void>(
      () => WxpNetworkService.delete<void>(
        WxpNetworkService.getUrl('/api/need-login/device/message/delete-all')
      ),
      true,
      () => successBlock(),
    );
  }

  static async getOpenId(): Promise<string | null> {
    const data = await WxpApiService.commonRespDeal<Record<string, string>>(
      () => WxpNetworkService.get<Record<string, string>>(
        WxpNetworkService.getUrl('/api/need-login/device/openid')
      )
    );
    if (data && Object.keys(data).length > 0) {
      return data['openId'] ?? null;
    }
    return null;
  }

  static async getUserDeviceInfo(): Promise<WxpBaseLoginResp | null> {
    return WxpApiService.commonRespDeal<WxpBaseLoginResp>(
      () => WxpNetworkService.get<WxpBaseLoginResp>(
        WxpNetworkService.getUrl('/api/need-login/device/get-user-device-info')
      )
    );
  }

  static async getScanResult(data: string): Promise<WxpScanQrcodeResp | null> {
    return WxpApiService.commonRespDeal<WxpScanQrcodeResp>(
      () => WxpNetworkService.post<WxpScanQrcodeResp>(
        WxpNetworkService.getUrl('/api/need-login/device/scan'),
        { data }
      )
    );
  }

  static async checkReason(): Promise<WxpCheckAppMsgReasonResp | null> {
    return WxpApiService.commonRespDeal<WxpCheckAppMsgReasonResp>(
      () => WxpNetworkService.get<WxpCheckAppMsgReasonResp>(
        WxpNetworkService.getUrl('/api/need-login/device/no-msg-check')
      )
    );
  }

  static async getListBanner(): Promise<WxpListBannerResp | null> {
    return WxpApiService.commonRespDeal<WxpListBannerResp>(
      () => WxpNetworkService.get<WxpListBannerResp>(
        WxpNetworkService.getUrl('/api/need-login/device/list-banner')
      )
    );
  }

  /**
   * 检查是否有新版本。失败静默，不 Toast 打扰用户。
   */
  static async checkAppVersion(): Promise<AppVersionCheckResp | null> {
    return WxpApiService.commonRespDeal<AppVersionCheckResp>(
      () => WxpNetworkService.get<AppVersionCheckResp>(
        WxpNetworkService.getUrl('/api/device/version-update')
      ),
      false,
    );
  }
}
