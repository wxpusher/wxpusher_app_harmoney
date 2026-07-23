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
  // 变更观察者：任意 set/remove 写入后按 key 通知 listener（ArkWeb UI 线程直接同步回调）
  private static listeners: Map<number, (key: string) => void> = new Map();
  private static nextListenerId: number = 0;

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
    WxpSaveService.notifyChanged(key);
  }

  static getBoolean(key: string, defaultValue: boolean): boolean {
    const bStr = WxpSaveService.getString(key, '');
    if (bStr.length === 0) {
      return defaultValue;
    }
    return bStr === 'true';
  }

  static setBoolean(key: string, value: boolean): void {
    WxpSaveService.setString(key, String(value));
  }

  static getInt(key: string, defaultValue: number): number {
    const bStr = WxpSaveService.getString(key, '');
    if (bStr.length === 0) {
      return defaultValue;
    }
    return parseInt(bStr, 10);
  }

  static setInt(key: string, value: number): void {
    WxpSaveService.setString(key, String(value));
  }

  static getDouble(key: string, defaultValue: number): number {
    return WxpSaveService.backend?.getDouble(key) ?? defaultValue;
  }

  static setDouble(key: string, value: number): void {
    WxpSaveService.backend?.setDouble(key, value);
    WxpSaveService.notifyChanged(key);
  }

  static remove(key: string): void {
    WxpSaveService.backend?.remove(key);
    WxpSaveService.notifyChanged(key);
  }

  /**
   * 注册存储变更监听，返回用于注销的 id。回调参数为变更的 key。
   */
  static addListener(listener: (key: string) => void): number {
    const id = WxpSaveService.nextListenerId++;
    WxpSaveService.listeners.set(id, listener);
    return id;
  }

  static removeListener(id: number): void {
    WxpSaveService.listeners.delete(id);
  }

  private static notifyChanged(key: string): void {
    WxpSaveService.listeners.forEach((listener: (key: string) => void) => {
      listener(key);
    });
  }
}
