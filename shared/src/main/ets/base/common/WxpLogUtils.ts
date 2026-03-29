import { WxpDateTimeUtils } from './WxpDateTimeUtils';

/**
 * 对应 KMP WxpLogUtils.kt
 * 跨平台日志工具类
 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

const LogLevelTag: Record<LogLevel, string> = {
  [LogLevel.DEBUG]: 'DEBUG',
  [LogLevel.INFO]: 'INFO',
  [LogLevel.WARN]: 'WARN',
  [LogLevel.ERROR]: 'ERROR',
};

export interface IWxpPlatformLog {
  log(level: LogLevel, tag: string, message: string, error?: Error): void;
}

export class WxpLogUtils {
  private static currentLogLevel: LogLevel = LogLevel.DEBUG;
  private static isEnabled: boolean = true;
  private static platformLog: IWxpPlatformLog | null = null;

  static setPlatformLog(impl: IWxpPlatformLog): void {
    WxpLogUtils.platformLog = impl;
  }

  static setLogLevel(level: LogLevel): void {
    WxpLogUtils.currentLogLevel = level;
  }

  static setEnabled(enabled: boolean): void {
    WxpLogUtils.isEnabled = enabled;
  }

  static d(tag: string = 'WxPusher', message: string, throwable?: Error): void {
    WxpLogUtils.log(LogLevel.DEBUG, tag, message, throwable);
  }

  static i(tag: string = 'WxPusher', message: string, throwable?: Error): void {
    WxpLogUtils.log(LogLevel.INFO, tag, message, throwable);
  }

  static w(tag: string = 'WxPusher', message: string, throwable?: Error): void {
    WxpLogUtils.log(LogLevel.WARN, tag, message, throwable);
  }

  static e(tag: string = 'WxPusher', message: string, throwable?: Error): void {
    WxpLogUtils.log(LogLevel.ERROR, tag, message, throwable);
  }

  private static log(level: LogLevel, tag: string, message: string, throwable?: Error): void {
    if (!WxpLogUtils.isEnabled || level < WxpLogUtils.currentLogLevel) {
      return;
    }

    const timestamp = WxpDateTimeUtils.getDateTime();
    const formattedMessage = `[${timestamp}] [${LogLevelTag[level]}] [${tag}] - ${message}`;

    if (WxpLogUtils.platformLog) {
      WxpLogUtils.platformLog.log(level, tag, formattedMessage, throwable);
    } else {
      console.log(formattedMessage);
      if (throwable) {
        console.error(throwable.message);
      }
    }
  }

  /**
   * 支持 {} 占位符的模板格式化
   */
  static formatMessage(template: string, ...args: Object[]): string {
    if (args.length === 0) {
      return template;
    }
    let result = template;
    let argIndex = 0;
    while (result.includes('{}') && argIndex < args.length) {
      result = result.replace('{}', String(args[argIndex]));
      argIndex++;
    }
    return result;
  }
}
