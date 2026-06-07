import { router } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { inputMethod } from '@kit.IMEKit';
import { notificationManager } from '@kit.NotificationKit';
import { emitter } from '@kit.BasicServicesKit';
import { WxpPushEventId } from '../../push/WxpPushEventId';
import { WxpJumpPageUtils } from '../../common/WxpJumpPageUtils';
import { WxpAppDataService, WxpSaveService } from '@wxpusher/shared';
import { USER_HAS_AGREEMENT_KEY } from '../../common/WxpAppGateKeys';
import {
  WxpMessageListPresenter,
  IWxpMessageListPresenter,
  WxpMessageListMessage,
  WxpCheckAppMsgReasonResp,
  WxpListBannerResp,
  WxpMessageListReqScene,
  WxpConfig,
  WxpDialogUtils,
  WxpDialogParams,
  WxpDateTimeUtils,
  WxpToastUtils,
} from '@wxpusher/shared';

// ─────────────────────────────────────────────────────────
// 消息列表 Tab（对齐 Android MessageListFragment）
// ─────────────────────────────────────────────────────────

@Component
export struct MessageListTab {
  /** 父级传入的当前 Tab 索引，用于感知 resume（切回本 Tab） */
  @Prop @Watch('onTabIndexChanged') currentTabIndex: number = 0;

  // ── 列表数据 ──
  @State messageList: WxpMessageListMessage[] = [];
  @State isRefreshing: boolean = false;
  @State isEmpty: boolean = false;
  @State hasMore: boolean = true;
  @State isLoadingMore: boolean = false;

  // ── 搜索栏 ──
  @State searchKey: string = '';
  @State showSearchCancel: boolean = false;

  // ── 通知/检查原因 Banner ──
  @State notePermissionVisible: boolean = false;
  @State notePermissionText: string = '';
  @State notePermissionBtnVisible: boolean = false;   // "去打开" 按钮（仅无通知权限时显示）
  @State notePermissionBtnText: string = '去打开';

  // ── 公告 Banner ──
  @State listBannerVisible: boolean = false;
  @State listBannerText: string = '';

  // ── 多选态（对齐 Android MessageListFragment 批量操作）──
  @State isSelectionMode: boolean = false;
  @State selectedIds: number[] = [];
  private static readonly MAX_BATCH_SELECT = 200;

  // ── 私有字段 ──
  private presenter: WxpMessageListPresenter | null = null;
  private openAppFirstRefresh: boolean = true;
  private notePermissionClickUrl: string = '';
  private listBannerData: WxpListBannerResp | null = null;
  /** Tab 切换保护标志：切回本 Tab 时屏蔽搜索框自动聚焦 */
  private isTabSwitching: boolean = false;

  // ── 通知点击跳转（AppAbility 写入 AppStorage，由此监听）──
  @StorageProp('pendingPushUrl') @Watch('onPendingPushUrlChanged') pendingPushUrl: string = '';

  // ── MVP 接口 ──

  createPresenter(): IWxpMessageListPresenter {
    return new WxpMessageListPresenter(this);
  }

  // ── 生命周期 ──

  aboutToAppear(): void {
    this.presenter = this.createPresenter() as WxpMessageListPresenter;
    if (!WxpSaveService.getBoolean(USER_HAS_AGREEMENT_KEY, false)) {
      return;
    }
    // 用本地缓存先渲染，再网络刷新（对齐 Android onViewCreated：先 init 后 autoRefresh）
    this.presenter.init();
    this.isRefreshing = true;
    this.doRefresh();
    this.refreshNotePermissionBanner();
    this.presenter.fetchListBanner();

    // 订阅 Push 新消息事件，App 在前台收到推送时刷新列表
    emitter.on({ eventId: WxpPushEventId.NEW_MESSAGE }, () => {
      this.openAppFirstRefresh = false;
      this.isRefreshing = true;
      this.presenter?.refresh(WxpMessageListReqScene.SceneManual);
    });

    // 处理冷启动时通知点击携带的 pendingPushUrl
    this.handlePendingPushUrl(this.pendingPushUrl);
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
    this.presenter = null;
    emitter.off(WxpPushEventId.NEW_MESSAGE);
  }

  /**
   * 监听 AppStorage 中 pendingPushUrl 的变化（热启动通知点击）
   */
  onPendingPushUrlChanged(): void {
    this.handlePendingPushUrl(this.pendingPushUrl);
  }

  private handlePendingPushUrl(url: string): void {
    if (!url || url.length === 0) {
      return;
    }
    // 消费后清空，避免重复跳转
    AppStorage.setOrCreate<string>('pendingPushUrl', '');
    router.pushUrl({ url: 'pages/WebViewPage', params: { url } });
    // 同时刷新消息列表
    this.openAppFirstRefresh = false;
    this.isRefreshing = true;
    this.presenter?.refresh(WxpMessageListReqScene.SceneManual);
  }

  /**
   * 当本 Tab 重新变为活动 Tab 时触发（对齐 Android onResume）
   */
  onTabIndexChanged(): void {
    if (this.currentTabIndex === 0) {
      // 防止切回本 Tab 时搜索框自动聚焦并弹起键盘
      this.isTabSwitching = true;
      this.showSearchCancel = false;
      inputMethod.getController().stopInputSession();
      setTimeout(() => {
        this.isTabSwitching = false;
      }, 500);
      this.presenter?.fetchListBanner();
      this.refreshNotePermissionBanner();
    }
  }

  // ── 通知权限检查（对齐 Android refreshNotePermissionBanner）──

  /**
   * 先检查 OS 通知权限：
   *   无权限 → 显示权限提示 banner + "去打开" 按钮
   *   有权限 → 隐藏权限 banner，转由 presenter.fetchCheckReason() 检查服务端消息原因
   */
  private refreshNotePermissionBanner(): void {
    notificationManager.isNotificationEnabled().then((enabled: boolean) => {
      if (!enabled) {
        this.notePermissionVisible = true;
        this.notePermissionText = '无消息通知权限，无法接收提醒';
        this.notePermissionBtnVisible = true;
        this.notePermissionClickUrl = '';
      } else {
        this.notePermissionBtnVisible = false;
        this.presenter?.fetchCheckReason();
      }
    }).catch(() => {
      // 权限查询失败时降级为服务端原因检查
      this.presenter?.fetchCheckReason();
    });
  }

  // ── 下拉刷新入口 ──

  private doRefresh(): void {
    // 首次（打开 App 时自动刷新）使用 SceneAutoRefresh；之后手动下拉使用 SceneManual（对齐 Android）
    const scene = this.openAppFirstRefresh
      ? WxpMessageListReqScene.SceneAutoRefresh
      : WxpMessageListReqScene.SceneManual;
    this.presenter?.refresh(scene);
    this.openAppFirstRefresh = false;
  }

  // ────────────────────────────────────────
  // IWxpMessageListView 实现
  // ────────────────────────────────────────

  showMessageRefreshing(refreshing: boolean): void {
    this.isRefreshing = refreshing;
  }

  showMessageMoreLoading(loading: boolean, hasMore: boolean): void {
    this.isLoadingMore = loading;
    this.hasMore = hasMore;
  }

  onMessageList(data: WxpMessageListMessage[]): void {
    this.messageList = data;
    this.isEmpty = data.length === 0;
    this.isRefreshing = false;
  }

  onFeedback(): void {
    try {
      vibrator.startVibration(
        { type: 'time', duration: 50 },
        { id: 0, usage: 'notification' }
      );
    } catch (_e) {
      // 不支持震动或权限不足时忽略
    }
  }

  /**
   * 对齐 Android onCheckReason：
   *   code <= 0 → 隐藏 banner
   *   code > 0  → 显示 reason 文本，可点击跳转 no-message 页面
   */
  onCheckReason(data: WxpCheckAppMsgReasonResp | null): void {
    if (data === null || data.code <= 0) {
      this.notePermissionVisible = false;
      return;
    }
    this.notePermissionVisible = true;
    this.notePermissionText = data.reason ?? '';
    this.notePermissionBtnVisible = false;
    this.notePermissionClickUrl =
      `${WxpConfig.appFeUrl}/app/?code=${data.code}#/no-message`;
  }

  /**
   * 对齐 Android onListBanner：
   *   null  → 隐藏
   *   有数据 → 显示 title，点击弹出带"不再显示"和"查看详情/我知道了"的 Dialog
   */
  onListBanner(data: WxpListBannerResp | null): void {
    if (data === null) {
      this.listBannerVisible = false;
      this.listBannerData = null;
      return;
    }
    this.listBannerVisible = true;
    this.listBannerText = data.title ?? '';
    this.listBannerData = data;
  }

  // ────────────────────────────────────────
  // 私有交互逻辑
  // ────────────────────────────────────────

  /**
   * 点击消息项：打开 URL，本地标记已读（对齐 Android openMessage）
   */
  private openMessage(message: WxpMessageListMessage): void {
    const urlString = message.url.trim();
    if (urlString.length > 0) {
      router.pushUrl({ url: 'pages/WebViewPage', params: { url: urlString } });
      // 本地标记已读（与 Android 一致：不调用网络接口，直接改内存并通知刷新）
      // 创建新对象而非原地修改，确保 ArkUI ForEach key（messageId_read）检测到变化并重渲染
      if (!message.read) {
        this.messageList = this.messageList.map((m: WxpMessageListMessage) => {
          if (m.messageId !== message.messageId) {
            return m;
          }
          const updated: WxpMessageListMessage = {
            messageId: m.messageId,
            url: m.url,
            sourceUrl: m.sourceUrl,
            summary: m.summary,
            name: m.name,
            read: true,
            createTime: m.createTime,
          };
          return updated;
        });
      }
    }
  }

  /**
   * 长按消息：浮动上下文菜单（对齐文件管理器长按菜单风格）
   */
  @Builder
  MessageOptionsMenu(message: WxpMessageListMessage) {
    Menu() {
      MenuItem({ content: message.read ? '标记未读' : '标记已读' })
        .onClick(() => {
          this.presenter?.markMessageReadStatus(message.messageId, !message.read);
        })
      MenuItem({ content: '删除' })
        .onClick(() => {
          // bindContextMenu 关闭后全局 promptAction UI 上下文失效，须用 UIContext 绑定的实例
          const pa = this.getUIContext().getPromptAction();
          pa.showDialog({
            title: '确认删除消息',
            message: '你确认删除此消息吗？删除后不可恢复。',
            buttons: [
              { text: '取消', color: '#666666' },
              { text: '删除', color: '#B300B3' },
            ],
          }).then((result) => {
            if (result.index === 1) {
              this.presenter?.executeDeleteById(message.messageId);
            }
          }).catch(() => {});
        })
      MenuItem({ content: '多选' })
        .onClick(() => {
          // 进入多选态并预选当前长按的这条（对齐 Android enterSelectionMode(preselectId)）
          this.enterSelectionMode(message.messageId);
        })
    }
  }

  // ────────────────────────────────────────
  // 多选态交互（对齐 Android MessageListFragment 批量操作）
  // ────────────────────────────────────────

  private enterSelectionMode(preselectId: number | null): void {
    this.selectedIds = (preselectId !== null && preselectId !== undefined) ? [preselectId] : [];
    this.isSelectionMode = true;
    // 进入多选态时收起搜索面板（隐藏 banner / 搜索 / 禁用下拉刷新在 build 中按 isSelectionMode 处理）
    this.showSearchCancel = false;
    inputMethod.getController().stopInputSession();
  }

  private exitSelectionMode(): void {
    this.isSelectionMode = false;
    this.selectedIds = [];
  }

  private isSelected(id: number): boolean {
    return this.selectedIds.includes(id);
  }

  private toggleSelect(id: number): void {
    if (this.selectedIds.includes(id)) {
      this.selectedIds = this.selectedIds.filter((x: number) => x !== id);
      return;
    }
    if (this.selectedIds.length >= MessageListTab.MAX_BATCH_SELECT) {
      WxpToastUtils.showToast(`一次最多选择 ${MessageListTab.MAX_BATCH_SELECT} 条消息`);
      return;
    }
    this.selectedIds = [...this.selectedIds, id];
  }

  private isAllSelected(): boolean {
    if (this.messageList.length === 0) {
      return false;
    }
    const limit = Math.min(this.messageList.length, MessageListTab.MAX_BATCH_SELECT);
    return this.selectedIds.length >= limit;
  }

  private toggleSelectAll(): void {
    if (this.isAllSelected()) {
      this.selectedIds = [];
      return;
    }
    if (this.messageList.length > MessageListTab.MAX_BATCH_SELECT) {
      WxpToastUtils.showToast(`一次最多选择 ${MessageListTab.MAX_BATCH_SELECT} 条消息`);
    }
    this.selectedIds = this.messageList
      .slice(0, MessageListTab.MAX_BATCH_SELECT)
      .map((m: WxpMessageListMessage) => m.messageId);
  }

  private batchMarkRead(read: boolean): void {
    if (this.selectedIds.length === 0) {
      WxpToastUtils.showToast('请先选择要操作的消息');
      return;
    }
    this.presenter?.markMessageReadStatusBatch([...this.selectedIds], read);
    this.exitSelectionMode();
  }

  private batchDelete(): void {
    if (this.selectedIds.length === 0) {
      WxpToastUtils.showToast('请先选择要操作的消息');
      return;
    }
    const ids = [...this.selectedIds];
    const pa = this.getUIContext().getPromptAction();
    pa.showDialog({
      title: '确认删除消息',
      message: `你确认删除选中的 ${ids.length} 条消息吗？删除后不可恢复。`,
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#B300B3' },
      ],
    }).then((result) => {
      if (result.index === 1) {
        // 确认后再退出多选态，保证用户在确认弹窗上仍能看到已选条目数
        this.exitSelectionMode();
        this.presenter?.executeDeleteByIds(ids);
      }
    }).catch(() => {});
  }

  private deleteAllMessages(): void {
    const pa = this.getUIContext().getPromptAction();
    pa.showDialog({
      title: '确认删除全部消息',
      message: '此操作会删除你的全部消息，删除后不可恢复，确认继续吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '全部删除', color: '#B300B3' },
      ],
    }).then((result) => {
      if (result.index === 1) {
        this.presenter?.executeDeleteAll();
      }
    }).catch(() => {});
  }

  /**
   * 点击公告 Banner：弹出对话框（对齐 Android onListBanner click）
   */
  private showListBannerDialog(): void {
    const data = this.listBannerData;
    if (!data) {
      return;
    }
    const params: WxpDialogParams = {
      title: data.title ?? '',
      message: data.desc ?? '',
      leftText: '不再显示',
      leftBlock: () => {
        this.presenter?.closeListBanner(data.id ?? null);
      },
      rightText: (data.url && data.url.length > 0) ? '查看详情' : '我知道了',
      rightBlock: (data.url && data.url.length > 0) ? () => {
        router.pushUrl({ url: 'pages/WebViewPage', params: { url: data.url! } });
      } : undefined,
    };
    WxpDialogUtils.showDialog(params);
  }

  // ────────────────────────────────────────
  // 消息列表 Item Builder
  // ────────────────────────────────────────

  @Builder
  MessageItemView(message: WxpMessageListMessage) {
    Column() {
      Row() {
        // 多选框（对齐 Android 多选态左侧 CheckBox，仅多选态显示）
        if (this.isSelectionMode) {
          Text(this.isSelected(message.messageId) ? '✓' : '')
            .fontSize(13)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width(20)
            .height(20)
            .borderRadius(10)
            .borderWidth(1.5)
            .borderColor(this.isSelected(message.messageId)
              ? $r('app.color.wxp_brand') : $r('sys.color.font_secondary'))
            .backgroundColor(this.isSelected(message.messageId)
              ? $r('app.color.wxp_brand') : Color.Transparent)
            .margin({ top: 4, left: 10, right: 2 })
            .alignSelf(ItemAlign.Start)
        }

        // 未读圆点（对齐 Android unread_dot）
        Column()
          .width(6)
          .height(6)
          .borderRadius(3)
          .backgroundColor(message.read ? Color.Transparent : $r('app.color.wxp_brand'))
          .margin({ top: 8, left: 6, right: 6 })
          .alignSelf(ItemAlign.Start)

        Column() {
          // 消息标题行（对齐 Android message_title + link_icon）
          Row() {
            Text(message.summary)
              .fontSize(16)
              .fontColor($r('sys.color.font_primary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .lineHeight(22)
              .layoutWeight(1)

            // 来源链接图标（对齐 Android link_icon，sourceUrl 非空时显示；多选态隐藏）
            if (!this.isSelectionMode && message.sourceUrl && message.sourceUrl.trim().length > 0) {
              Text('🔗')
                .fontSize(13)
                .margin({ left: 4, top: 2 })
                .alignSelf(ItemAlign.Start)
                .onClick(() => {
                  const src = message.sourceUrl?.trim() ?? '';
                  if (src.length > 0) {
                    router.pushUrl({ url: 'pages/WebViewPage', params: { url: src } });
                  }
                })
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          // 来源 + 时间行（对齐 Android source_label + date_label）
          Row() {
            Text(`来源: ${message.name ?? '未知'}`)
              .fontSize(12)
              .fontColor($r('sys.color.font_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            Text(WxpDateTimeUtils.formatDateTime(message.createTime))
              .fontSize(12)
              .fontColor($r('sys.color.font_secondary'))
              .margin({ left: 8 })
          }
          .width('100%')
          .margin({ top: 4, bottom: 12 })
        }
        .layoutWeight(1)
        .padding({ right: 12 })
      }
      .width('100%')
      .padding({ top: 12 })
      .alignItems(VerticalAlign.Top)

      // 分割线
      Divider()
        .strokeWidth(0.5)
        .color($r('sys.color.ohos_id_color_list_separator'))
        .margin({ left: 18 })
    }
    .width('100%')
    .onClick(() => {
      if (this.isSelectionMode) {
        this.toggleSelect(message.messageId);
      } else {
        this.openMessage(message);
      }
    })
    .bindContextMenu(this.MessageOptionsMenu(message), ResponseType.LongPress)
  }

  // ────────────────────────────────────────
  // build
  // ────────────────────────────────────────

  build() {
    Column() {

      // ── 顶部标题栏 / 多选态顶部栏（对齐 Android Toolbar / batch_top_bar）──
      if (this.isSelectionMode) {
        Row() {
          // 关闭多选态
          Text('✕')
            .fontSize(20)
            .fontColor($r('sys.color.font_primary'))
            .width(44)
            .height(44)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.exitSelectionMode(); })

          Text(`已选 ${this.selectedIds.length}`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .layoutWeight(1)

          // 全选 / 取消全选
          Text(this.isAllSelected() ? '取消全选' : '全选')
            .fontSize(15)
            .fontColor($r('app.color.wxp_brand'))
            .padding({ left: 12, right: 16 })
            .height(44)
            .onClick(() => { this.toggleSelectAll(); })
        }
        .width('100%')
        .height(56)
        .padding({ left: 4 })
        .alignItems(VerticalAlign.Center)
      } else {
        Row() {
          Text('消息列表')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))

          Blank()

          // 更多菜单：HarmonyOS 卡片式下拉，系统自动处理深色模式 / 阴影 / 圆角
          Text('⋮')
            .fontSize(24)
            .fontColor($r('sys.color.font_primary'))
            .width(44)
            .height(44)
            .textAlign(TextAlign.Center)
            .bindMenu([
              {
                value: '订阅管理',
                action: () => {
                  router.pushUrl({
                    url: 'pages/WebViewPage',
                    params: { url: `${WxpConfig.appFeUrl}/app/#/subscribe-list` },
                  });
                },
              },
              {
                value: '扫码添加',
                action: () => { router.pushUrl({ url: 'pages/ScanPage' }); },
              },
              {
                value: '多选',
                action: () => { this.enterSelectionMode(null); },
              },
              {
                value: '标记全部已读',
                action: () => { this.presenter?.markMessageReadStatus(null, true); },
              },
              {
                value: '删除全部消息',
                action: () => { this.deleteAllMessages(); },
              },
            ])
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 4 })
        .alignItems(VerticalAlign.Center)
      }

      // ── 通知/原因检查 Banner（对齐 Android note_permission_banner + onCheckReason）──
      if (!this.isSelectionMode && this.notePermissionVisible) {
        Row() {
          Text('🔔')
            .fontSize(15)
            .margin({ right: 8 })

          Text(this.notePermissionText)
            .fontSize(12)
            .fontColor($r('sys.color.font_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.notePermissionBtnVisible) {
            Text(this.notePermissionBtnText)
              .fontSize(12)
              .fontColor($r('app.color.wxp_brand'))
              .fontWeight(FontWeight.Medium)
              .margin({ left: 8 })
              .onClick(async () => {
                await WxpJumpPageUtils.requestNotificationPermission();
                // 请求完成后刷新 banner 状态
                this.refreshNotePermissionBanner();
              })
          }

          // 关闭/跳转箭头（对齐 Android notePermissionCloseImg）
          Text('›')
            .fontSize(22)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ left: 8 })
            .onClick(() => {
              this.notePermissionVisible = false;
              this.presenter?.fetchCheckReason();
            })
        }
        .width('100%')
        .padding({ left: 12, right: 8, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.wxp_banner_warn_bg'))
        .borderRadius(6)
        .margin({ left: 4, right: 4, top: 2 })
        .onClick(() => {
          if (this.notePermissionClickUrl.length > 0) {
            router.pushUrl({
              url: 'pages/WebViewPage',
              params: { url: this.notePermissionClickUrl },
            });
          }
        })
      }

      // ── 公告 Banner（对齐 Android list_banner + onListBanner）──
      if (!this.isSelectionMode && this.listBannerVisible) {
        Row() {
          Text('ℹ')
            .fontSize(15)
            .fontColor($r('app.color.wxp_danger'))
            .margin({ right: 8 })

          Text(this.listBannerText)
            .fontSize(12)
            .fontColor($r('sys.color.font_primary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text('›')
            .fontSize(22)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 12, right: 8, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.wxp_banner_info_bg'))
        .borderRadius(6)
        .margin({ left: 4, right: 4, top: 2 })
        .onClick(() => {
          this.showListBannerDialog();
        })
      }

      // ── 搜索栏（对齐 Android search_bar_container，多选态隐藏）──
      if (!this.isSelectionMode) {
        Row() {
        Row() {
          Text('🔍')
            .fontSize(13)
            .fontColor($r('sys.color.font_tertiary'))
            .margin({ left: 10, right: 2 })

          TextInput({ placeholder: '请输入关键字搜索消息', text: this.searchKey })
            .layoutWeight(1)
            .height(34)
            .backgroundColor(Color.Transparent)
            .fontSize(14)
            .placeholderColor($r('sys.color.font_tertiary'))
            .placeholderFont({ size: 14 })
            .padding({ left: 4, right: 8, top: 0, bottom: 0 })
            .enterKeyType(EnterKeyType.Search)
            .onChange((value: string) => {
              this.searchKey = value;
            })
            .onSubmit(() => {
              // 键盘搜索按钮（对齐 Android IME_ACTION_SEARCH）
              const key = this.searchKey.trim();
              this.presenter?.searchIfChanged(key.length > 0 ? key : null);
              inputMethod.getController().stopInputSession();
            })
            .onFocus(() => {
              // Tab 切换期间忽略自动聚焦，避免拉起键盘
              if (this.isTabSwitching) {
                inputMethod.getController().stopInputSession();
                return;
              }
              this.showSearchCancel = true;
            })
            .onBlur(() => {
              this.showSearchCancel = false;
            })
        }
        .layoutWeight(1)
        .height(36)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .borderRadius(8)
        .alignItems(VerticalAlign.Center)

        // 取消按钮（对齐 Android search_cancel_btn）
        if (this.showSearchCancel) {
          Text('取消')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.wxp_brand'))
            .margin({ left: 12 })
            .onClick(() => {
              this.searchKey = '';
              this.presenter?.searchIfChanged(null);
              inputMethod.getController().stopInputSession();
            })
        }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 4 })
      }

      // ── 消息列表区域（下拉刷新 + 上拉加载更多）──
      Refresh({ refreshing: $$this.isRefreshing }) {
        Stack() {
          // 消息列表（对齐 Android RecyclerView + SmartRefreshLayout）
          List() {
            ForEach(
              this.messageList,
              (message: WxpMessageListMessage) => {
                ListItem() {
                  this.MessageItemView(message)
                }
              },
              (message: WxpMessageListMessage) => `${message.messageId}_${message.read}`
            )

            // 底部加载更多 / 没有更多数据（对齐 Android ClassicsFooter + setNoMoreData）
            if (!this.isEmpty) {
              ListItem() {
                Row() {
                  if (this.isLoadingMore) {
                    LoadingProgress()
                      .width(20)
                      .height(20)
                      .margin({ right: 8 })
                    Text('加载中...')
                      .fontSize(13)
                      .fontColor($r('sys.color.font_secondary'))
                  } else if (!this.hasMore) {
                    Text('只保留最近7天消息，没有数据了')
                      .fontSize(13)
                      .fontColor($r('sys.color.font_secondary'))
                  }
                }
                .width('100%')
                .height(48)
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
              }
            }
          }
          .width('100%')
          .height('100%')
          .onReachEnd(() => {
            // 加载更多（对齐 Android setOnLoadMoreListener）
            if (this.hasMore && !this.isRefreshing && !this.isLoadingMore) {
              this.isLoadingMore = true;
              this.presenter?.loadMore();
            }
          })
          .visibility(this.isEmpty ? Visibility.Hidden : Visibility.Visible)

          // 空状态（对齐 Android empty_text）
          Text('暂无消息')
            .fontSize(16)
            .fontColor($r('sys.color.font_secondary'))
            .visibility(this.isEmpty && !this.isRefreshing ? Visibility.Visible : Visibility.Hidden)
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Center)
      }
      .onRefreshing(() => {
        // 多选态下禁用下拉刷新（对齐 Android refreshLayout.isEnabled = false）
        if (this.isSelectionMode) {
          this.isRefreshing = false;
          return;
        }
        // 手动下拉刷新（对齐 Android OnRefreshListener）
        this.doRefresh();
      })
      .layoutWeight(1)

      // ── 底部批量操作栏（对齐 Android view_batch_action_bar，仅多选态显示）──
      if (this.isSelectionMode) {
        Row() {
          this.BatchActionItem('标记已读', $r('app.media.ic_done'),
            $r('sys.color.font_primary'), () => { this.batchMarkRead(true); })
          this.BatchActionItem('标记未读', $r('app.media.ic_mark_as_unread'),
            $r('sys.color.font_primary'), () => { this.batchMarkRead(false); })
          this.BatchActionItem('删除', $r('app.media.ic_delete'),
            $r('app.color.wxp_danger'), () => { this.batchDelete(); })
        }
        .width('100%')
        .height(64)
        .padding({ top: 6, bottom: 6 })
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .border({ width: { top: 0.5 }, color: $r('sys.color.ohos_id_color_list_separator') })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }

  /**
   * 底部批量操作项（图标在上、文字在下，无选中时禁用 + 0.4 透明度，对齐 Android view_batch_action_bar）
   */
  @Builder
  BatchActionItem(label: string, icon: Resource, color: Resource, action: () => void) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(color)

      Text(label)
        .fontSize(12)
        .fontColor(color)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .opacity(this.selectedIds.length > 0 ? 1 : 0.4)
    .enabled(this.selectedIds.length > 0)
    .onClick(() => { action(); })
  }
}
