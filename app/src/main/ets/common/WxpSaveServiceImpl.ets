import { preferences } from '@kit.ArkData';
import { IWxpSaveServiceBackend } from '@wxpusher/shared';
import { Context } from '@kit.AbilityKit';

/**
 * HarmonyOS 平台 WxpSaveService 实现
 * 使用 @ohos.data.preferences
 */
export class WxpSaveServiceImpl implements IWxpSaveServiceBackend {
  private prefs: preferences.Preferences | null = null;
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  init(): void {
    try {
      this.prefs = preferences.getPreferencesSync(this.context, { name: 'wxpusher_prefs' });
    } catch (e) {
      console.error('WxpSaveServiceImpl init error:', (e as Error).message);
    }
  }

  get(key: string): string | null {
    try {
      const value = this.prefs?.getSync(key, '');
      return value as string || null;
    } catch {
      return null;
    }
  }

  set(key: string, value: string | null): void {
    try {
      if (value === null) {
        this.prefs?.deleteSync(key);
      } else {
        this.prefs?.putSync(key, value);
      }
      this.prefs?.flush();
    } catch (e) {
      console.error('WxpSaveServiceImpl set error:', (e as Error).message);
    }
  }

  getDouble(key: string): number | null {
    try {
      const value = this.prefs?.getSync(key, 0.0);
      return value as number;
    } catch {
      return null;
    }
  }

  setDouble(key: string, value: number): void {
    try {
      this.prefs?.putSync(key, value);
      this.prefs?.flush();
    } catch (e) {
      console.error('WxpSaveServiceImpl setDouble error:', (e as Error).message);
    }
  }

  remove(key: string): void {
    try {
      this.prefs?.deleteSync(key);
      this.prefs?.flush();
    } catch (e) {
      console.error('WxpSaveServiceImpl remove error:', (e as Error).message);
    }
  }
}
