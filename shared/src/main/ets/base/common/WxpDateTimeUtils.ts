/**
 * 对应 KMP WxpDateTimeUtils.kt
 * 日期时间工具类
 */
export class WxpDateTimeUtils {
  /**
   * 将时间戳转换为相对时间描述
   */
  static getRelativeDateTime(timeStamp: number): string {
    const nowInMillis = Date.now();
    const duration = Math.floor(Math.abs(nowInMillis - timeStamp) / 1000);
    if (duration < 60) {
      return '刚刚';
    } else if (duration < 3600) {
      return `${Math.floor(duration / 60)}分钟前`;
    } else if (duration < 86400) {
      return `${Math.floor(duration / 3600)}小时前`;
    } else if (duration < 604800) {
      return `${Math.floor(duration / 86400)}天前`;
    } else {
      return WxpDateTimeUtils.toDateTimeString(timeStamp);
    }
  }

  static formatDateTime(timeStamp: number): string {
    return WxpDateTimeUtils.toDateTimeString(timeStamp);
  }

  static getDate(): string {
    return WxpDateTimeUtils.toDateString(Date.now());
  }

  static getDateTime(): string {
    return WxpDateTimeUtils.toDateTimeString(Date.now());
  }

  static getTimestamp(): number {
    return Date.now();
  }

  /**
   * 毫秒时间戳 → "yyyy-MM-dd HH:mm:ss"
   */
  static toDateTimeString(millis: number): string {
    const date = new Date(millis);
    const y = date.getFullYear();
    const M = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    const H = String(date.getHours()).padStart(2, '0');
    const m = String(date.getMinutes()).padStart(2, '0');
    const s = String(date.getSeconds()).padStart(2, '0');
    return `${y}-${M}-${d} ${H}:${m}:${s}`;
  }

  /**
   * 毫秒时间戳 → "yyyy-MM-dd"
   */
  static toDateString(millis: number): string {
    const date = new Date(millis);
    const y = date.getFullYear();
    const M = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${M}-${d}`;
  }
}
