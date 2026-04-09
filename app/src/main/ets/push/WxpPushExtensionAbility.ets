import { PushExtensionAbility, pushCommon } from '@kit.PushKit';
import { wantAgent, Want, WantAgent } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { emitter, BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WxpPushEventId } from './WxpPushEventId';

const TAG = 'WxpPushExtensionAbility';
const DOMAIN = 0x0000;

/** 通知 ID 自增，避免多条通知互相覆盖 */
let notificationIdCounter = 1;

/**
 * 服务端在 PushPayload.data 中下发的业务字段
 */
interface WxpPushData {
  title?: string;
  summary?: string;
  url?: string;
}

/**
 * HarmonyOS Push 消息接收扩展，对齐 Android HuaweiHmsMessageService。
 *
 * 触发时机：
 *   - App 在前台：onReceiveMessage 被调用，通过 emitter 通知消息列表刷新，
 *     同时发出本地通知（系统会根据前台状态决定是否显示通知栏）。
 *   - App 在后台或被杀死：onReceiveMessage 仍会被调用，发出本地通知，
 *     用户点击通知后系统通过 Want 启动 AppAbility 并携带 pushUrl 参数。
 */
export default class WxpPushExtensionAbility extends PushExtensionAbility {

  /**
   * 收到透传推送消息（对齐 Android HuaweiHmsMessageService.onMessageReceived）。
   * PushPayload.data 为服务端下发的 JSON 字符串，约定字段：
   *   - title   : 通知标题
   *   - summary : 通知摘要/正文
   *   - url     : 点击后打开的链接（可选）
   */
  onReceiveMessage(payload: pushCommon.PushPayload): void {
    hilog.info(DOMAIN, TAG, `收到 Push 消息: type=${payload.type}, data=${payload.data}`);

    let pushData: WxpPushData = {};
    try {
      pushData = JSON.parse(payload.data) as WxpPushData;
    } catch (e) {
      hilog.warn(DOMAIN, TAG, `Push data 解析失败: ${payload.data}`);
    }

    const title = pushData.title ?? '新消息';
    const summary = pushData.summary ?? '';
    const url = pushData.url ?? '';

    // 1. 触发同进程内 emitter 事件，通知消息列表页面刷新
    emitter.emit({ eventId: WxpPushEventId.NEW_MESSAGE });

    // 2. 发出本地通知
    WxpPushExtensionAbility.publishLocalNotification(title, summary, url);
  }

  /**
   * 构建本地通知并发布。
   * 点击通知时通过 WantAgent 唤起 AppAbility，并将 pushUrl 写入 Want.parameters，
   * AppAbility.onNewWant / onCreate 中读取后跳转到对应 WebView 页面。
   */
  private static publishLocalNotification(title: string, summary: string, url: string): void {
    const notifId = notificationIdCounter++;

    const params: Record<string, Object> = {};
    if (url.length > 0) {
      params['pushUrl'] = url;
    }

    const targetWant: Want = {
      bundleName: 'com.smjcco.wxpusher.hm',
      abilityName: 'AppAbility',
      parameters: params
    };

    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [targetWant],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: notifId,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    wantAgent.getWantAgent(wantAgentInfo).then((agent: WantAgent) => {
      const request: notificationManager.NotificationRequest = {
        id: notifId,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: summary,
            additionalText: ''
          }
        },
        wantAgent: agent
      };

      notificationManager.publish(request).catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, `发布通知失败: code=${err.code}, message=${err.message}`);
      });
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, `创建 WantAgent 失败: code=${err.code}, message=${err.message}`);
    });
  }
}
