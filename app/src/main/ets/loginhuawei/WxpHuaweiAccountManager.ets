import { authentication } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { WxpLogUtils } from '@wxpusher/shared';

// ─────────────────────────────────────────────────────────
// 常量
// ─────────────────────────────────────────────────────────

const TAG = 'WxpHuaweiAccountManager';

/** 用户取消华为账号授权登录的错误码（1001502012 - The user canceled the authorization） */
const ERROR_CODE_LOGIN_CANCEL = 1001502012;

// ─────────────────────────────────────────────────────────
// 回调类型（对齐微信管理器风格）
// ─────────────────────────────────────────────────────────

export interface HuaweiAuthResult {
  /** 华为账号 ID Token，上报后端进行 JWT 校验 */
  idToken: string;
  /** 用户昵称：登录请求不返回昵称，恒为空（如需昵称头像要另走授权 profile 流程） */
  name?: string;
}

export type HuaweiAuthCompletion = (result: HuaweiAuthResult | null, error: string | null) => void;

// ─────────────────────────────────────────────────────────
// Manager 实现
// ─────────────────────────────────────────────────────────

/**
 * 华为账号登录管理类（鸿蒙 Account Kit，ID Token 模式）。
 *
 * 与微信不同，Account Kit 无需在 AppAbility.onCreate 全局 init，按需拉起授权即可。
 * 流程对标 iOS 的 Apple 登录：拿到 idToken 后上报后端校验。
 */
class WxpHuaweiAccountManagerImpl {
  /**
   * 发起华为账号授权登录（ID Token 模式）。
   *
   * @param context 当前 UIAbility 上下文
   * @param completion 结果回调：成功返回 idToken（+昵称），用户取消时 result 与 error 均为 null
   */
  requestHuaweiAuth(context: common.UIAbilityContext, completion: HuaweiAuthCompletion): void {
    try {
      // 用「登录请求」而非「授权请求」：登录请求直接返回 idToken（授权请求主要返回 scope/头像昵称，不稳定带 idToken）
      const request: authentication.LoginWithHuaweiIDRequest =
        new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();
      // 未登录时拉起登录 UI
      request.forceLogin = true;
      // 防 CSRF 的随机 state
      request.state = util.generateRandomUUID();
      // 指定 RS256 签名 idToken，匹配后端 auth0 Algorithm.RSA256；默认 PS256 后端无法验证
      request.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.RS256;

      const controller = new authentication.AuthenticationController(context);
      controller.executeRequest(request,
        (err: BusinessError<Record<string, Object>>, data?: authentication.AuthenticationResponse) => {
          if (err) {
            if (err.code === ERROR_CODE_LOGIN_CANCEL) {
              WxpLogUtils.i(TAG, '用户取消华为账号登录');
              completion(null, null);
              return;
            }
            WxpLogUtils.e(TAG, `华为账号登录失败: code=${err.code}, msg=${err.message}`);
            completion(null, err.message ?? '华为账号登录失败');
            return;
          }
          const response = data as authentication.LoginWithHuaweiIDResponse;
          const credential = response?.data;
          const idToken = credential?.idToken;
          if (!idToken || idToken.length === 0) {
            completion(null, '未获取到华为登录凭证(idToken为空)');
            return;
          }
          // 登录凭证不含昵称/头像，name 留空（后端可空）
          completion({ idToken: idToken }, null);
        });
    } catch (e) {
      const error = e as BusinessError;
      WxpLogUtils.e(TAG, `华为账号登录异常: ${error?.message}`);
      completion(null, error?.message ?? '华为账号登录异常');
    }
  }
}

// ─────────────────────────────────────────────────────────
// 模块级单例
// ─────────────────────────────────────────────────────────
export const WxpHuaweiAccountManager: WxpHuaweiAccountManagerImpl = new WxpHuaweiAccountManagerImpl();
