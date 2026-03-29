/**
 * 对应 KMP WxpMaskUtils.kt
 * 数据脱敏工具，中间用 * 填充
 */
export class WxpMaskUtils {
  /**
   * 对数据进行脱敏，中间用 * 填充
   * @param text 原始文本
   * @param pre 前面保留的长度
   * @param end 后面保留的长度
   */
  static mask(text: string, pre: number, end: number): string {
    const length = text.length;
    let preStr = '';
    let endStr = '';

    if (length > pre) {
      preStr = text.substring(0, pre);
    }

    if (length > end) {
      endStr = text.substring(length - end);
    }

    const rest = length - preStr.length - endStr.length;
    let result = preStr;
    for (let i = 0; i < rest; i++) {
      result += '*';
    }
    result += endStr;
    return result;
  }
}
