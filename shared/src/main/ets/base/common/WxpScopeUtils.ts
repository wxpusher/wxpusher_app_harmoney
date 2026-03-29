/**
 * 对应 KMP WxpScopeUtils.kt
 *
 * 在 ArkTS 中没有 IO/Main dispatcher 的区分，
 * 所有异步操作都通过 async/await + Promise 处理。
 * 这里提供与 KMP 对齐的辅助方法。
 */
export class WxpScopeUtils {
  /**
   * 在主线程执行（ArkTS 中即当前线程）
   */
  static runAtMainSuspend(block: () => Promise<void>): void {
    block().catch((e: Error) => {
      console.error('runAtMainSuspend error:', e?.message);
    });
  }

  /**
   * 在 IO 线程执行（ArkTS 中等价于异步执行）
   */
  static runAtIOSuspend(block: () => Promise<void>): void {
    block().catch((e: Error) => {
      console.error('runAtIOSuspend error:', e?.message);
    });
  }

  /**
   * delay 辅助方法，对应 Kotlin 的 delay(ms)
   */
  static delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(resolve, ms);
    });
  }
}
