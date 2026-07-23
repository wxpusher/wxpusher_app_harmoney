// Shared HAR module barrel export
// Config
export { WxpConfig } from './src/main/ets/config/WxpConfig';

// Base common utilities
export { WxpCommonExt } from './src/main/ets/base/common/WxpCommonExt';
export { WxpMaskUtils } from './src/main/ets/base/common/WxpMaskUtils';
export { WxpRandomUtils } from './src/main/ets/base/common/WxpRandomUtils';
export { WxpDateTimeUtils } from './src/main/ets/base/common/WxpDateTimeUtils';
export { WxpSerializationUtils } from './src/main/ets/base/common/WxpSerializationUtils';
export { WxpLogUtils, LogLevel } from './src/main/ets/base/common/WxpLogUtils';
export type { IWxpPlatformLog } from './src/main/ets/base/common/WxpLogUtils';
export { WxpSaveService } from './src/main/ets/base/common/WxpSaveService';
export type { IWxpSaveServiceBackend } from './src/main/ets/base/common/WxpSaveService';
export { WxpTabConfigStore } from './src/main/ets/biz/tab/WxpTabConfig';
export type { WxpTabConfig } from './src/main/ets/biz/tab/WxpTabConfig';
export { WxpToastUtils } from './src/main/ets/base/common/WxpToastUtils';
export type { IWxpToastBackend } from './src/main/ets/base/common/WxpToastUtils';
export { WxpDialogUtils } from './src/main/ets/base/common/WxpDialogUtils';
export type { IWxpDialogBackend, WxpDialogParams } from './src/main/ets/base/common/WxpDialogUtils';
export { WxpLoadingUtils } from './src/main/ets/base/common/WxpLoadingUtils';
export type { IWxpLoading } from './src/main/ets/base/common/WxpLoadingUtils';
export { WxpBaseInfoService } from './src/main/ets/base/common/WxpBaseInfoService';
export type { IWxpBaseInfoServiceBackend } from './src/main/ets/base/common/WxpBaseInfoService';
export { WxpScopeUtils } from './src/main/ets/base/common/WxpScopeUtils';
export { WxpBaseMvpPresenter } from './src/main/ets/base/common/WxpBaseMvp';
export type { IWxpBaseMvpView, IWxpBaseMvpPresenter } from './src/main/ets/base/common/WxpBaseMvp';

// Network
export { WxpNetworkService } from './src/main/ets/base/common/WxpNetworkService';
export type { BaseResp } from './src/main/ets/base/common/WxpNetworkService';

// API
export { WxpApiService } from './src/main/ets/api/WxpApiService';

// Biz services
export { WxpAppDataService } from './src/main/ets/base/biz/WxpAppDataService';
export { WxpAppPageService } from './src/main/ets/base/biz/WxpAppPageService';
export type { IWxpAppPageService } from './src/main/ets/base/biz/WxpAppPageService';

// Beans
export type { WxpLoginInfo } from './src/main/ets/base/biz/bean/WxpLoginInfo';
export { createWxpLoginInfoFromResp } from './src/main/ets/base/biz/bean/WxpLoginInfo';
export { WxpPlatformEnum } from './src/main/ets/base/biz/bean/WxpPlatformEnum';
export type { WxpUpdateInfoReq } from './src/main/ets/base/biz/bean/WxpUpdateInfoBean';

// Page contracts & presenters
export type {
  IWxpLoginView,
  IWxpLoginPresenter
} from './src/main/ets/page/login/WxpLoginPageContract';
export { WxpLoginPresenter } from './src/main/ets/page/login/WxpLoginPresenter';
export type {
  WxpLoginSendVerifyCodeReq,
  WxpLoginSendVerifyCodeResp,
  WxpBaseLoginResp,
  WxpWeixinLoginReq,
  WxpWeixinLoginResp
} from './src/main/ets/page/login/WxpLoginBean';
export type {
  WxpPhoneBind,
  WxpAppleBind,
  WxpBindPageData
} from './src/main/ets/page/login/WxpLoginBindOrCreateAccountBean';
export {
  WxpBindPageDataUtils
} from './src/main/ets/page/login/WxpLoginBindOrCreateAccountBean';

export type {
  IWxpMessageListView,
  IWxpMessageListPresenter
} from './src/main/ets/page/messagelist/WxpMessageListPageContract';
export { WxpMessageListPresenter } from './src/main/ets/page/messagelist/WxpMessageListPresenter';
export type {
  WxpMessageListReq,
  WxpMessageListMessage,
  WxpCheckAppMsgReasonResp,
  WxpListBannerResp
} from './src/main/ets/page/messagelist/WxpMessageListBean';
export { WxpMessageListReqScene } from './src/main/ets/page/messagelist/WxpMessageListBean';

export type {
  IWxpScanView,
  IWxpScanPresenter
} from './src/main/ets/page/scan/WxpScanContract';
export { WxpScanPresenter } from './src/main/ets/page/scan/WxpScanPresenter';
export type { WxpScanQrcodeResp, WxpFollowResult } from './src/main/ets/page/scan/WxpScanBean';

export type {
  IWxpAccountDetailView,
  IWxpAccountDetailPresenter
} from './src/main/ets/page/accountdetail/WxpAccountDetailPageContract';
export { WxpAccountDetailPresenter } from './src/main/ets/page/accountdetail/WxpAccountDetailPresenter';

export type {
  IWxpBindView,
  IWxpBindPresenter
} from './src/main/ets/page/bind/WxpBindPageContract';
export { WxpBindPresenter } from './src/main/ets/page/bind/WxpBindPresenter';

export type {
  IWxpChangePhoneView,
  IWxpChangePhonePresenter
} from './src/main/ets/page/changephone/WxpChangePhonePageContract';
export { WxpChangePhonePresenter } from './src/main/ets/page/changephone/WxpChangePhonePresenter';

export type {
  IWxpProviderListView,
  IWxpProviderListPresenter
} from './src/main/ets/page/providerlist/WxpProviderListContract';
export { WxpProviderListPresenter } from './src/main/ets/page/providerlist/WxpProviderListPresenter';

export type {
  IWxpRegisterOrBindView,
  IWxpRegisterOrBindPresenter
} from './src/main/ets/page/registerorbind/WxpRegisterOrBindPageContract';
export { WxpRegisterOrBindPresenter } from './src/main/ets/page/registerorbind/WxpRegisterOrBindPresenter';

// Biz - version check
export type { AppVersionCheckResp } from './src/main/ets/biz/version/AppVersionCheckResp';
export type { WxpAppMarketNavigator } from './src/main/ets/biz/version/WxpAppMarketNavigator';
export { WxpVersionCheckManager } from './src/main/ets/biz/version/WxpVersionCheckManager';

// Web
export { WxpWebHostPolicy } from './src/main/ets/web/WxpWebHostPolicy';
export { AppFeVersionManager } from './src/main/ets/web/AppFeVersionManager';
