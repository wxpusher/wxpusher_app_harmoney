import {
  WXAPIFactory,
  WXApi,
  WXApiEventHandler,
  BaseReq,
  BaseResp,
  ErrCode,
  SendAuthReq,
  SendAuthResp,
  SendMessageToWXReq,
  SendMessageToWXResp,
  WXMediaMessage,
  WXTextObject,
  WXImageObject,
  PayReq,
  PayResp,
} from '@tencent/wechat_open_sdk';
import { common, Want } from '@kit.AbilityKit';
import { WxpLogUtils } from '@wxpusher/shared';

// ─────────────────────────────────────────────────────────
// 常量
// ─────────────────────────────────────────────────────────

const TAG = 'WxpWeixinOpenManager';

/** 微信开放平台 AppID，与 Android/iOS 保持一致 */
export const WECHAT_APP_ID = 'wx906c2d32c1b1a115';

// ─────────────────────────────────────────────────────────
// 公共数据模型（对齐 Android WeChatAuthResponse / WeChatError）
// ─────────────────────────────────────────────────────────

export interface WeChatAuthResponse {
  code: string;
  state: string;
}

export interface WeChatError {
  message: string;
  errCode: number;
}

function makeWeChatError(message: string, errCode: number = -1): WeChatError {
  return { message, errCode };
}

function errorFromCode(errCode: number, errStr?: string): WeChatError {
  switch (errCode) {
    case ErrCode.ERR_USER_CANCEL:
      return makeWeChatError('用户取消', errCode);
    case ErrCode.ERR_AUTH_DENIED:
      return makeWeChatError('授权被拒绝', errCode);
    case ErrCode.ERR_BAN:
      return makeWeChatError(`签名错误: ${errStr ?? ''}`, errCode);
    default:
      return makeWeChatError(errStr ?? `未知错误: ${errCode}`, errCode);
  }
}

// ─────────────────────────────────────────────────────────
// 回调类型（对齐 Android typealias）
// ─────────────────────────────────────────────────────────

export type AuthCompletion = (response: WeChatAuthResponse | null, error: WeChatError | null) => void;
export type ShareCompletion = (success: boolean, error: WeChatError | null) => void;
export type PayCompletion = (success: boolean, error: WeChatError | null) => void;

// ─────────────────────────────────────────────────────────
// 微信场景常量（对应 Android SendMessageToWX.Req.WXScenexxx）
// ─────────────────────────────────────────────────────────

/** 微信场景：发送到聊天界面（对应 Android WXSceneSession = 0） */
export const WX_SCENE_SESSION = SendMessageToWXReq.WXSceneSession;

// ─────────────────────────────────────────────────────────
// Manager 实现
// ─────────────────────────────────────────────────────────

/**
 * 微信 OpenSDK 管理类（鸿蒙版）。
 *
 * 对应 Android WxpWeixinOpenManager（Kotlin object 单例）。
 *
 * 鸿蒙 SDK（1.0.0）与 Android 的主要差异：
 * - 无 registerApp / isWXAppInstalled，WXAPIFactory.createWXAPI(appId) 即完成初始化
 * - 无 WXWebpageObject，网页分享改为 WXTextObject（URL 作为文本）
 * - WXMediaMessage 无 description 字段
 * - sendReq 返回 SendReqResultWrap（boolean | Promise<boolean>）
 * - 回调通过 AppAbility.onNewWant → handleWant 而非 WXEntryActivity
 */
class WxpWeixinOpenManagerImpl implements WXApiEventHandler {
  private wxApi: WXApi | null = null;
  private abilityContext: common.UIAbilityContext | null = null;

  // ── 待处理回调（同时只有一个同类型请求） ──
  private authCompletion: AuthCompletion | null = null;
  private shareCompletion: ShareCompletion | null = null;
  private payCompletion: PayCompletion | null = null;

  // ════════════════════════════════════════════════════════
  // 初始化（在 AppAbility.onCreate 调用）
  // ════════════════════════════════════════════════════════

  /**
   * 初始化微信 SDK。
   * 对应 Android WxpWeixinOpenManager.init(context)。
   * 应在 AppAbility.onCreate 中调用。
   */
  init(context: common.UIAbilityContext): void {
    this.abilityContext = context;
    if (this.wxApi === null) {
      // HarmonyOS SDK 不需要 registerApp，createWXAPI 即完成初始化
      this.wxApi = WXAPIFactory.createWXAPI(WECHAT_APP_ID);
      WxpLogUtils.i(TAG, '微信SDK初始化完成');
    }
  }

  /**
   * 更新 context（在 AppAbility.onNewWant 中调用，确保 context 最新）。
   */
  setContext(context: common.UIAbilityContext): void {
    this.abilityContext = context;
  }

  /**
   * 处理来自微信的 Want 回调。
   * 对应 Android WXEntryActivity 中的 api.handleIntent(intent, handler)。
   * 在 AppAbility.onCreate / onNewWant 中调用。
   */
  handleWant(want: Want): void {
    this.wxApi?.handleWant(want, this);
  }

  // ════════════════════════════════════════════════════════
  // 授权登录（对应 Android requestAuth）
  // ════════════════════════════════════════════════════════

  /**
   * 发起微信授权登录。
   * 对应 Android WxpWeixinOpenManager.requestAuth(scope, state, completion)。
   */
  requestAuth(
    scope: string = 'snsapi_userinfo',
    state: string = 'wechat_auth',
    completion: AuthCompletion
  ): void {
    this.doRequestAuth(scope, state, completion).catch(() => {
      WxpLogUtils.e(TAG, '微信授权异常');
    });
  }

  private async doRequestAuth(scope: string, state: string, completion: AuthCompletion): Promise<void> {
    const ctx = this.abilityContext;
    if (ctx === null) {
      completion(null, makeWeChatError('SDK未初始化'));
      return;
    }
    this.authCompletion = completion;
    const req = new SendAuthReq();
    req.scope = scope;
    req.state = state;
    req.nonAutomatic = true;
    req.transaction = `auth_${Date.now()}`;
    const success = await this.wxApi!.sendReq(ctx, req);
    if (!success) {
      this.authCompletion = null;
      completion(null, makeWeChatError('启动微信失败，请确认已安装微信'));
    }
  }

  // ════════════════════════════════════════════════════════
  // 分享（对应 Android shareWebPage / shareText）
  // ════════════════════════════════════════════════════════

  /**
   * 分享网页链接到微信。
   * 对应 Android shareWebPage。
   * 注意：HarmonyOS SDK 1.0.0 无 WXWebpageObject，
   * 改为将标题+URL 以 WXTextObject 方式分享。
   */
  shareWebPage(
    url: string,
    title: string,
    scene: number,
    completion: ShareCompletion
  ): void {
    this.doShareWebPage(url, title, scene, completion).catch(() => {
      WxpLogUtils.e(TAG, '微信分享网页异常');
    });
  }

  private async doShareWebPage(
    url: string,
    title: string,
    scene: number,
    completion: ShareCompletion
  ): Promise<void> {
    const ctx = this.abilityContext;
    if (ctx === null) {
      completion(false, makeWeChatError('SDK未初始化'));
      return;
    }
    this.shareCompletion = completion;

    // WXTextObject 承载 URL，title 放在 WXMediaMessage.title
    const textObj = new WXTextObject();
    textObj.text = url;

    const msg = new WXMediaMessage();
    msg.mediaObject = textObj;
    msg.title = title;

    const req = new SendMessageToWXReq();
    req.scene = scene;
    req.message = msg;
    req.transaction = `share_${Date.now()}`;

    const success = await this.wxApi!.sendReq(ctx, req);
    if (!success) {
      this.shareCompletion = null;
      completion(false, makeWeChatError('启动微信失败，请确认已安装微信'));
    }
  }

  /**
   * 分享图片到微信（对应 Android shareImage）。
   * imageUri 为 HarmonyOS 的 file:// 或 content:// URI。
   */
  shareImage(imageUri: string, scene: number, completion: ShareCompletion): void {
    this.doShareImage(imageUri, scene, completion).catch(() => {
      WxpLogUtils.e(TAG, '微信分享图片异常');
    });
  }

  private async doShareImage(imageUri: string, scene: number, completion: ShareCompletion): Promise<void> {
    const ctx = this.abilityContext;
    if (ctx === null) {
      completion(false, makeWeChatError('SDK未初始化'));
      return;
    }
    this.shareCompletion = completion;

    const imageObj = new WXImageObject();
    imageObj.uri = imageUri;

    const msg = new WXMediaMessage();
    msg.mediaObject = imageObj;

    const req = new SendMessageToWXReq();
    req.scene = scene;
    req.message = msg;
    req.transaction = `image_${Date.now()}`;

    const success = await this.wxApi!.sendReq(ctx, req);
    if (!success) {
      this.shareCompletion = null;
      completion(false, makeWeChatError('启动微信失败，请确认已安装微信'));
    }
  }

  // ════════════════════════════════════════════════════════
  // 微信支付（对应 Android requestPayment）
  // ════════════════════════════════════════════════════════

  /**
   * 发起微信支付。
   * 对应 Android WxpWeixinOpenManager.requestPayment(paymentParams, completion)。
   * 参数 Map 键名与 Android 保持一致：prepayid / paySign / timeStamp / nonceStr / partnerid / package。
   */
  requestPayment(params: Record<string, Object>, completion: PayCompletion): void {
    this.doRequestPayment(params, completion).catch(() => {
      WxpLogUtils.e(TAG, '微信支付异常');
    });
  }

  private async doRequestPayment(params: Record<string, Object>, completion: PayCompletion): Promise<void> {
    const ctx = this.abilityContext;
    if (ctx === null) {
      completion(false, makeWeChatError('SDK未初始化'));
      return;
    }

    // 与 Android 对齐的参数键名
    const prepayId = params['prepayid'] as string;
    const sign = params['paySign'] as string;
    const timeStamp = params['timeStamp'] as string;
    const nonceStr = params['nonceStr'] as string;
    const partnerId = params['partnerid'] as string;
    const packageValue = params['package'] as string;

    if (!prepayId || !sign || !timeStamp || !nonceStr || !partnerId || !packageValue) {
      completion(false, makeWeChatError('支付参数格式错误'));
      return;
    }

    this.payCompletion = completion;

    const req = new PayReq();
    req.appId = WECHAT_APP_ID;
    req.partnerId = partnerId;
    req.prepayId = prepayId;
    req.nonceStr = nonceStr;
    req.timeStamp = timeStamp;
    req.packageValue = packageValue;
    req.sign = sign;

    const success = await this.wxApi!.sendReq(ctx, req);
    if (!success) {
      this.payCompletion = null;
      completion(false, makeWeChatError('启动微信失败，请确认已安装微信'));
    }
  }

  // ════════════════════════════════════════════════════════
  // WXApiEventHandler 实现（对应 Android IWXAPIEventHandler）
  // ════════════════════════════════════════════════════════

  onReq(req: BaseReq): void {
    WxpLogUtils.d(TAG, `收到微信请求: ${req.name}`);
  }

  onResp(resp: BaseResp): void {
    WxpLogUtils.d(TAG, `收到微信响应: errCode=${resp.errCode}`);
    if (resp instanceof SendAuthResp) {
      this.handleAuthResponse(resp as SendAuthResp);
    } else if (resp instanceof SendMessageToWXResp) {
      this.handleShareResponse(resp as SendMessageToWXResp);
    } else if (resp instanceof PayResp) {
      this.handlePayResponse(resp as PayResp);
    } else {
      WxpLogUtils.d(TAG, '未知类型的微信响应');
    }
  }

  private handleAuthResponse(resp: SendAuthResp): void {
    if (resp.errCode === ErrCode.ERR_OK && resp.code) {
      const response: WeChatAuthResponse = {
        code: resp.code,
        state: resp.state ?? '',
      };
      this.authCompletion?.(response, null);
    } else {
      this.authCompletion?.(null, errorFromCode(resp.errCode, resp.errStr));
    }
    this.authCompletion = null;
  }

  private handleShareResponse(resp: SendMessageToWXResp): void {
    if (resp.errCode === ErrCode.ERR_OK) {
      this.shareCompletion?.(true, null);
    } else {
      this.shareCompletion?.(false, errorFromCode(resp.errCode, resp.errStr));
    }
    this.shareCompletion = null;
  }

  private handlePayResponse(resp: PayResp): void {
    if (resp.errCode === ErrCode.ERR_OK) {
      this.payCompletion?.(true, null);
    } else {
      this.payCompletion?.(false, errorFromCode(resp.errCode, resp.errStr));
    }
    this.payCompletion = null;
  }
}

// ─────────────────────────────────────────────────────────
// 模块级单例（对应 Android object WxpWeixinOpenManager）
// ─────────────────────────────────────────────────────────
export const WxpWeixinOpenManager: WxpWeixinOpenManagerImpl = new WxpWeixinOpenManagerImpl();
