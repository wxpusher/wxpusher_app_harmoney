import { WxpLogUtils } from './WxpLogUtils';

/**
 * 对应 KMP WxpSerializationUtils.kt
 * JSON 序列化/反序列化工具
 */
export class WxpSerializationUtils {
  private static readonly TAG = 'WxpSerialization';

  static toJson<T>(value: T): string | null {
    try {
      return JSON.stringify(value);
    } catch (e) {
      WxpLogUtils.w(WxpSerializationUtils.TAG, '对象序列化失败', e as Error);
      return null;
    }
  }

  static fromJson<T>(jsonString: string | null | undefined): T | null {
    if (!jsonString || jsonString.trim().length === 0) {
      return null;
    }
    try {
      return JSON.parse(jsonString) as T;
    } catch (e) {
      WxpLogUtils.w(WxpSerializationUtils.TAG, '对象反序列化失败', e as Error);
      return null;
    }
  }
}
