/**
 * 对应 KMP WxpCommonExt.kt
 * 当值非 null 且非空字符串时执行回调
 */
export class WxpCommonExt {
  static letOnNotEmpty<T>(value: T | null | undefined, run: (v: T) => void): void {
    if (value === null || value === undefined) {
      return;
    }
    if (typeof value === 'string' && value.length === 0) {
      return;
    }
    run(value);
  }
}
