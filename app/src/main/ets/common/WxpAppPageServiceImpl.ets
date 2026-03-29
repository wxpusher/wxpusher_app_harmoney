import { router } from '@kit.ArkUI';
import { IWxpAppPageService } from '@wxpusher/shared';

/**
 * HarmonyOS 平台 AppPageService 实现
 */
export class WxpAppPageServiceImpl implements IWxpAppPageService {
  jumpToLogin(): void {
    try {
      router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (e) {
      console.error('jumpToLogin error:', (e as Error).message);
    }
  }
}
