/**
 * Push 相关的 emitter 事件 ID 常量
 * 同进程内用 @kit.BasicServicesKit emitter 传递，与 PushExtensionAbility 共享同一套 ID。
 */
export class WxpPushEventId {
  /** 收到新推送消息，消息列表需要刷新 */
  static readonly NEW_MESSAGE: number = 10001;
  /** App 回到前台（AppAbility.onForeground），消息列表增量拉取一次 */
  static readonly APP_FOREGROUND: number = 10002;
}
