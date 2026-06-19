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
  /** 华为账号 ID Token（含 openid+profile 信息），上报后端，由后端从 idToken 解析昵称/头像 */
  idToken: string;
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
      // 用「授权请求」(openid+profile)：一次同时拿 idToken + 昵称 + 头像
      const request: authentication.AuthorizationWithHuaweiIDRequest =
        new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      // openid：返回 idToken；profile：返回昵称/头像
      request.scopes = ['openid', 'profile'];
      request.permissions = ['idtoken'];
      // 未登录时拉起登录 UI
      request.forceAuthorization = true;
      // 防 CSRF 的随机 state
      request.state = util.generateRandomUUID();
      // 指定 RS256 签名 idToken，匹配后端 auth0 Algorithm.RSA256；默认 PS256 后端无法验证。
      // 显式设置签名算法也是让授权请求返回 idToken 的关键
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
          const response = data as authentication.AuthorizationWithHuaweiIDResponse;
          const credential = response?.data;
          const idToken = credential?.idToken;
          // 验证用日志：确认授权请求是否返回了 idToken（昵称/头像由后端从 idToken 解析）
          WxpLogUtils.i(TAG, `华为授权返回: idToken存在=${!!idToken}`);
          if (!idToken || idToken.length === 0) {
            completion(null, '未获取到华为登录凭证(idToken为空)');
            return;
          }
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
