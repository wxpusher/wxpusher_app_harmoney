/**
 * 对应 KMP WxpLoginBean.kt
 */

export interface WxpLoginSendVerifyCodeReq {
  justCreateAccount: boolean;
  phone: string;
  code: string;
  deviceId?: string;
  deviceName?: string;
  pushToken?: string;
}

/**
 * 无论哪种登录方式，都一定会返回的信息
 */
export interface WxpBaseLoginResp {
  version?: number;
  deviceToken?: string;
  deviceId?: string;
  uid?: string;
  spt?: string;
  openId?: string;
  nickName?: string;
  phone?: string;
  wxBind?: boolean;
  appleBind?: boolean;
  huaweiBind?: boolean;
}

export interface WxpLoginSendVerifyCodeResp extends WxpBaseLoginResp {
  phoneHasRegister?: boolean;
  phoneVerifyCode?: string;
}

/**
 * 微信登录请求
 */
export interface WxpWeixinLoginReq {
  code: string;
  bindCode?: string;
  appleLoginJwtCode?: string;
  appleName?: string;
  // 华为账号登录（鸿蒙）绑定信息：手机/微信绑定时把华为账号关联到微信账号
  huaweiLoginIdToken?: string;
  deviceId?: string;
  deviceName?: string;
  pushToken?: string;
}

/**
 * 微信登录结果
 */
export interface WxpWeixinLoginResp extends WxpBaseLoginResp {
}

/**
 * 苹果登录请求
 */
export interface WxpAppleLoginReq {
  justCreateAccount: boolean;
  code?: string;
  name?: string;
  deviceId?: string;
  deviceName?: string;
  pushToken?: string;
}

/**
 * 苹果登录结果
 */
export interface WxpAppleLoginResp extends WxpBaseLoginResp {
  hasRegister?: boolean;
}

/**
 * 华为账号登录请求（鸿蒙 Account Kit ID Token 模式）
 */
export interface WxpHuaweiLoginReq {
  justCreateAccount: boolean;
  code?: string;
  deviceId?: string;
  deviceName?: string;
  pushToken?: string;
}

/**
 * 华为账号登录结果
 */
export interface WxpHuaweiLoginResp extends WxpBaseLoginResp {
  hasRegister?: boolean;
}
