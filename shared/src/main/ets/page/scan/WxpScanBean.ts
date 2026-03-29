/**
 * 对应 KMP WxpScanBean.kt
 */

export interface WxpScanQrcodeResp {
  type: number;
  data?: string;
  followResult?: WxpFollowResult;
}

export const ScanQrcodeType = {
  TypeShowRaw: 0,
  TypeSubscribe: 1,
  TypeOpenUrl: 2,
  TypeOpenUrlWithConfirm: 3,
} as const;

export interface WxpFollowResult {
  code?: number;
  extraQrcode?: boolean;
  type?: number;
  String?: string;
  subId?: number;
  msg?: string;
}

export const FollowResultCode = {
  FollowCodeResultSuccess: 1,
  FollowCodeResultReject: 2,
  FollowCodeResultOverMaxUserCount: 3,
  TypeApp: 1,
  TypeTopic: 2,
} as const;
