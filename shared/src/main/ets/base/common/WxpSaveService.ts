/**
 * 对应 KMP WxpSaveService.kt
 * 数据存储服务，通过接口注入平台实现
 */
export interface IWxpSaveServiceBackend {
  get(key: string): string | null;
  set(key: string, value: string | null): void;
  getDouble(key: string): number | null;
  setDouble(key: string, value: number): void;
  remove(key: string): void;
  init(): void;
}

export class WxpSaveService {
  private static backend: IWxpSaveServiceBackend | null = null;

  static setBackend(backend: IWxpSaveServiceBackend): void {
    WxpSaveService.backend = backend;
  }

  static init(): void {
    WxpSaveService.backend?.init();
  }

  static getString(key: string, defaultValue: string): string {
    return WxpSaveService.backend?.get(key) ?? defaultValue;
  }

  static setString(key: string, value: string | null): void {
    WxpSaveService.backend?.set(key, value);
  }

  static getBoolean(key: string, defaultValue: boolean): boolean {
    const bStr = WxpSaveService.getString(key, '');
    if (bStr.length === 0) {
      return defaultValue;
    }
    return bStr === 'true';
  }

  static setBoolean(key: string, value: boolean): void {
    WxpSaveService.backend?.set(key, String(value));
  }

  static getInt(key: string, defaultValue: number): number {
    const bStr = WxpSaveService.getString(key, '');
    if (bStr.length === 0) {
      return defaultValue;
    }
    return parseInt(bStr, 10);
  }

  static setInt(key: string, value: number): void {
    WxpSaveService.backend?.set(key, String(value));
  }

  static getDouble(key: string, defaultValue: number): number {
    return WxpSaveService.backend?.getDouble(key) ?? defaultValue;
  }

  static setDouble(key: string, value: number): void {
    WxpSaveService.backend?.setDouble(key, value);
  }

  static remove(key: string): void {
    WxpSaveService.backend?.remove(key);
  }
}
