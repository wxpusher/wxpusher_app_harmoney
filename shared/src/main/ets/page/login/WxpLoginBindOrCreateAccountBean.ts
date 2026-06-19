/**
 * 对应 KMP WxpLoginBindOrCreateAccountBean.kt
 */

export interface WxpPhoneBind {
  phone: string;
  code: string;
  phoneVerifyCode?: string;
}

export interface WxpAppleBind {
  code?: string;
  name?: string;
}

export interface WxpHuaweiBind {
  // 华为登录的 id token
  code?: string;
}

export interface WxpBindPageData {
  appleLogin?: WxpAppleBind;
  huaweiLogin?: WxpHuaweiBind;
  phoneLogin?: WxpPhoneBind;
}

export class WxpBindPageDataUtils {
  static toJson(data: WxpBindPageData): string {
    return JSON.stringify(data);
  }

  static fromJson(json: string | null | undefined): WxpBindPageData | null {
    if (!json || json.length === 0) {
      return null;
    }
    try {
      return JSON.parse(json) as WxpBindPageData;
    } catch {
      return null;
    }
  }

  static phoneBindToJson(data: WxpPhoneBind): string {
    return JSON.stringify(data);
  }

  static phoneBindFromJson(json: string | null | undefined): WxpPhoneBind | null {
    if (!json || json.length === 0) {
      return null;
    }
    try {
      return JSON.parse(json) as WxpPhoneBind;
    } catch {
      return null;
    }
  }
}
