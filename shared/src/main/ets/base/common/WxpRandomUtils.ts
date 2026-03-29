/**
 * 对应 KMP WxpRandomUtils.kt
 */
export class WxpRandomUtils {
  static generateRandomString(length: number): string {
    const charPool = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += charPool.charAt(Math.floor(Math.random() * charPool.length));
    }
    return result;
  }
}
