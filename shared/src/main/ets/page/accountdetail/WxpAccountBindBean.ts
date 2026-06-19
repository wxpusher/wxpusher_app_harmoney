/**
 * 对应 KMP WxpAccountBindBean.kt
 */

export interface WxpWeixinBindReq {
  code?: string;
}

export interface WxpAppleBindReq {
  jwtCode?: string;
  name?: string;
}

export interface WxpHuaweiBindReq {
  idToken?: string;
}
