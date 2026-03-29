/**
 * 对应 KMP WxpMessageListBean.kt
 */

export class WxpMessageListReqScene {
  static readonly SceneManual = 1;
  static readonly SceneAutoRefresh = 2;
  static readonly SceneFetchResume = 3;
  static readonly SceneSearch = 4;
  static readonly SceneLoadMore = 5;
}

export interface WxpMessageListReq {
  messageId: number;
  key?: string;
  scene?: number;
}

export interface WxpMessageListMessage {
  messageId: number;
  url: string;
  sourceUrl?: string;
  summary: string;
  name?: string;
  read: boolean;
  createTime: number;
}

export interface WxpCheckAppMsgReasonResp {
  code: number;
  hasMsg: boolean;
  hasPush: boolean;
  reason?: string;
  url?: string;
}

export interface WxpListBannerResp {
  id?: number;
  title?: string;
  desc?: string;
  url?: string;
}
