import { WxpBaseLoginResp } from '../../../page/login/WxpLoginBean';

/**
 * 对应 KMP WxpLoginInfo.kt
 * 登录信息
 */
export interface WxpLoginInfo {
  version?: number;
  deviceToken?: string;
  deviceId?: string;
  uid?: string;
  spt?: string;
  openId?: string;
  nickName?: string;
  phone?: string;
  weiXinBind?: boolean;
  appleBind?: boolean;
  huaweiBind?: boolean;
}

export function createWxpLoginInfoFromResp(resp: WxpBaseLoginResp): WxpLoginInfo {
  return {
    version: resp.version,
    deviceToken: resp.deviceToken,
    deviceId: resp.deviceId,
    uid: resp.uid,
    spt: resp.spt,
    openId: resp.openId,
    nickName: resp.nickName,
    phone: resp.phone,
    weiXinBind: resp.wxBind,
    appleBind: resp.appleBind,
    huaweiBind: resp.huaweiBind,
  };
}
