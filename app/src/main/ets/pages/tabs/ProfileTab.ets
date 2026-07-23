import { router } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import {
  WxpConfig,
  WxpDialogUtils,
  WxpAppDataService,
  WxpBaseInfoService,
  WxpToastUtils,
  WxpVersionCheckManager,
} from '@wxpusher/shared';

// ─────────────────────────────────────────────────────────
// 我的 Tab（对齐 Android ProfileFragment）
// ─────────────────────────────────────────────────────────

@Component
export struct ProfileTab {
  @State private uid: string = '';
  @State private spt: string = '';
  @State private deviceId: string = '';
  @State private appVersion: string = '';

  // ── 生命周期 ──

  aboutToAppear(): void {
    const loginInfo = WxpAppDataService.getLoginInfo();
    this.uid = loginInfo?.uid ?? '';
    this.spt = loginInfo?.spt ?? '';
    this.deviceId = loginInfo?.deviceId ?? '';
    this.appVersion = WxpBaseInfoService.getAppVersionName();
  }

  // ── 剪贴板复制（对齐 Android copyToClipboard）──

  private copyToClipboard(text: string, msg: string): void {
    if (!text || text.length === 0) {
      return;
    }
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      pasteboard.getSystemPasteboard().setDataSync(data);
      WxpToastUtils.showToast(msg);
    } catch {
      WxpToastUtils.showToast('复制失败');
    }
  }

  // ── WebView 跳转 ──

  private openUrl(url: string): void {
    router.pushUrl({ url: 'pages/WebViewPage', params: { url } });
  }

  // ── 通知权限检查（对齐 Android checkNotificationPermission）──

  private checkNotificationPermission(): void {
    notificationManager.isNotificationEnabled()
      .then((enabled: boolean) => {
        if (enabled) {
          WxpDialogUtils.showDialog({
            title: '提醒方式设置',
            message: '当前已经打开通知权限，你还可以设置锁屏显示、通知中心显示、横幅显示等，还可以设置通知的铃声。是否前往设置？',
            leftText: '取消',
            rightText: '去设置',
            rightBlock: () => { this.openNotificationSettings(); },
          });
        } else {
          WxpDialogUtils.showDialog({
            title: '异常提醒',
            message: 'WxPusher必须要推送权限才能正常工作，请在【设置-WxPusher消息推送平台-通知】打开相关开关',
            leftText: '取消',
            rightText: '去设置',
            rightBlock: () => { this.openNotificationSettings(); },
          });
        }
      })
      .catch(() => {});
  }

  private openNotificationSettings(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      notificationManager.openNotificationSettings(ctx).catch(() => {});
    } catch {
      WxpToastUtils.showToast('无法打开通知设置');
    }
  }

  // ── 中间省略（用于 UID/SPT/设备ID 等长串）──

  private midEllipsis(text: string): string {
    const maxLen = 20;
    if (text.length <= maxLen) {
      return text;
    }
    const half = Math.floor((maxLen - 3) / 2);
    return text.substring(0, half) + '...' + text.substring(text.length - half);
  }

  // ── 检查更新（统一版本检测，手动触发绕过节流）──

  private checkForUpdate(): void {
    WxpVersionCheckManager.onAppForeground(true);
  }

  // ── section 标题 Builder ──

  @Builder
  SectionLabel(title: string) {
    Text(title)
      .fontSize(12)
      .fontColor($r('sys.color.font_secondary'))
      .padding({ left: 16, top: 16, bottom: 8 })
      .width('100%')
  }

  // ── item 行 Builder（仅视觉，点击由外层 Column 承载）──

  @Builder
  ItemRow(title: string, subtitle: string, showDivider: boolean) {
    Column() {
      Row() {
        Text(title)
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        Text(subtitle)
          .fontSize(14)
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 200 })
          .margin({ right: 4 })

        Text('›')
          .fontSize(22)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      if (showDivider) {
        Divider()
          .strokeWidth(0.5)
          .color($r('sys.color.ohos_id_color_list_separator'))
          .margin({ left: 16 })
      }
    }
    .width('100%')
  }

  // ── build ──

  build() {
    Column() {

      // ── 顶部标题栏（对齐 Android Toolbar）──
      Row() {
        Text('我的')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {

          // ── 设备和账号 ──
          this.SectionLabel('设备和账号')
          Column() {
            Column() { this.ItemRow('UID', this.uid.length > 0 ? this.midEllipsis(this.uid) : '未登录', true) }
            .width('100%')
            .onClick(() => { this.copyToClipboard(this.uid, 'UID复制成功'); })

            Column() { this.ItemRow('SPT', this.spt.length > 0 ? this.midEllipsis(this.spt) : '未登录', true) }
            .width('100%')
            .onClick(() => { this.copyToClipboard(this.spt, 'SPT复制成功'); })

            Column() { this.ItemRow('设备ID', this.deviceId.length > 0 ? this.midEllipsis(this.deviceId) : '-', true) }
            .width('100%')
            .onClick(() => { this.copyToClipboard(this.deviceId, '设备ID复制成功'); })

            Column() { this.ItemRow('账号信息', '管理账号', true) }
            .width('100%')
            .onClick(() => { router.pushUrl({ url: 'pages/AccountDetailPage' }); })

            Column() { this.ItemRow('推送渠道', '管理消息接收渠道', false) }
            .width('100%')
            .onClick(() => { this.openUrl(`${WxpConfig.appFeUrl}/app/#/push-channel`); })
          }
          .width('100%')
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius(12)
          .clip(true)

          // ── 消息管理 ──
          this.SectionLabel('消息管理')
          Column() {
            Column() { this.ItemRow('我的订阅', '订阅的消息内容', true) }
            .width('100%')
            .onClick(() => { this.openUrl(`${WxpConfig.appFeUrl}/app/#/subscribe-list`); })

            Column() { this.ItemRow('添加订阅', '扫描添加订阅', true) }
            .width('100%')
            .onClick(() => { router.pushUrl({ url: 'pages/ScanPage' }); })

            Column() { this.ItemRow('代理赚钱', '推广消息产品赚佣金', true) }
            .width('100%')
            .onClick(() => { this.openUrl(`${WxpConfig.appFeUrl}/app/#/agent-overview`); })

            Column() { this.ItemRow('消息开关', '管理消息接收开关', true) }
            .width('100%')
            .onClick(() => { this.openUrl(`${WxpConfig.appFeUrl}/app/#/user-enable`); })

            Column() { this.ItemRow('发送测试消息', '体验发送一条消息', false) }
            .width('100%')
            .onClick(() => { this.openUrl(`${WxpConfig.appFeUrl}/app/#/send-test-guide`); })
          }
          .width('100%')
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius(12)
          .clip(true)

          // ── 通知提醒 ──
          this.SectionLabel('通知提醒')
          Column() {
            Column() { this.ItemRow('通知设置', '检查通知权限', true) }
            .width('100%')
            .onClick(() => { this.checkNotificationPermission(); })

            Column() { this.ItemRow('推送检查', '收不到消息的异常排查', false) }
            .width('100%')
            .onClick(() => {
              this.openUrl('https://wxpusher.zjiecode.com/docs/open-app-note/index.html?brand=HarmonyOS');
            })
          }
          .width('100%')
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius(12)
          .clip(true)

          // ── 通用 ──
          this.SectionLabel('通用')
          Column() {
            Column() { this.ItemRow('底部标签设置', '自定义底部导航标签的显示', true) }
            .width('100%')
            .onClick(() => { this.openUrl(`${WxpConfig.appFeUrl}/app/#/tab-setting`); })

            Column() { this.ItemRow('反馈建议', '欢迎你指导我们进步', true) }
            .width('100%')
            .onClick(() => { this.openUrl('https://wj.qq.com/s2/22198188/cc95/'); })

            Column() { this.ItemRow('软件更新', this.appVersion, true) }
            .width('100%')
            .onClick(() => { this.checkForUpdate(); })

            Column() { this.ItemRow('用户协议', '查看用户和隐私协议', true) }
            .width('100%')
            .onClick(() => {
              this.openUrl(`${WxpConfig.appFeUrl}/admin/agreement/index-argeement.html`);
            })

            Column() { this.ItemRow('联系我们', '咨询和反馈问题', true) }
            .width('100%')
            .onClick(() => { this.openUrl(`${WxpConfig.appFeUrl}/app/#/contact`); })

            Column() { this.ItemRow('备案号', '蜀ICP备14025423号-2A', false) }
            .width('100%')
            .onClick(() => { this.openUrl('https://beian.miit.gov.cn/'); })
          }
          .width('100%')
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius(12)
          .clip(true)

        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ bottom: 32 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }
}
