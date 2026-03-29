import { hilog } from '@kit.PerformanceAnalysisKit';
import { IWxpPlatformLog, LogLevel } from '@wxpusher/shared';

/**
 * HarmonyOS 平台日志实现
 */
export class WxpLogUtilsImpl implements IWxpPlatformLog {
  private static readonly DOMAIN = 0x0000;

  log(level: LogLevel, tag: string, message: string, error?: Error): void {
    const logMessage = error ? `${message}\nError: ${error.message}` : message;
    switch (level) {
      case LogLevel.DEBUG:
        hilog.debug(WxpLogUtilsImpl.DOMAIN, tag, logMessage);
        break;
      case LogLevel.INFO:
        hilog.info(WxpLogUtilsImpl.DOMAIN, tag, logMessage);
        break;
      case LogLevel.WARN:
        hilog.warn(WxpLogUtilsImpl.DOMAIN, tag, logMessage);
        break;
      case LogLevel.ERROR:
        hilog.error(WxpLogUtilsImpl.DOMAIN, tag, logMessage);
        break;
    }
  }
}
