/**
 * Push 相关的 emitter 事件 ID 常量
 * 同进程内用 @kit.BasicServicesKit emitter 传递，与 PushExtensionAbility 共享同一套 ID。
 */
export class WxpPushEventId {
  /** 收到新推送消息，消息列表需要刷新 */
  static readonly NEW_MESSAGE: number = 10001;
}
