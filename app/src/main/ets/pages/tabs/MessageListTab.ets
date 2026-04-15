import { router } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { inputMethod } from '@kit.IMEKit';
import { notificationManager } from '@kit.NotificationKit';
import { emitter } from '@kit.BasicServicesKit';
import { WxpPushEventId } from '../../push/WxpPushEventId';
import { WxpJumpPageUtils } from '../../common/WxpJumpPageUtils';
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

  onOpenSubscribeManagerPage(url: string): void {
    router.pushUrl({ url: 'pages/WebViewPage', params: { url } });
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
    }
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
        // 未读圆点（对齐 Android unread_dot）
        Column()
          .width(6)
          .height(6)
          .borderRadius(3)
          .backgroundColor(message.read ? Color.Transparent : '#B300B3')
          .margin({ top: 8, left: 6, right: 6 })
          .alignSelf(ItemAlign.Start)

        Column() {
          // 消息标题行（对齐 Android message_title + link_icon）
          Row() {
            Text(message.summary)
              .fontSize(16)
              .fontColor('#1A1A1A')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .lineHeight(22)
              .layoutWeight(1)

            // 来源链接图标（对齐 Android link_icon，sourceUrl 非空时显示）
            if (message.sourceUrl && message.sourceUrl.trim().length > 0) {
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
              .fontColor('#999999')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            Text(WxpDateTimeUtils.formatDateTime(message.createTime))
              .fontSize(12)
              .fontColor('#999999')
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
        .color('#EBEBEB')
        .margin({ left: 18 })
    }
    .width('100%')
    .onClick(() => {
      this.openMessage(message);
    })
    .bindContextMenu(this.MessageOptionsMenu(message), ResponseType.LongPress)
  }

  // ────────────────────────────────────────
  // build
  // ────────────────────────────────────────

  build() {
    Column() {

      // ── 顶部标题栏（右上角单个「更多」按钮，对齐 Android Toolbar）──
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
              action: () => { this.presenter?.openSubscribeManagerPage(); },
            },
            {
              value: '扫码添加',
              action: () => { router.pushUrl({ url: 'pages/ScanPage' }); },
            },
            {
              value: '标记全部已读',
              action: () => { this.presenter?.markMessageReadStatus(null, true); },
            },
          ])
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 4 })
      .alignItems(VerticalAlign.Center)

      // ── 通知/原因检查 Banner（对齐 Android note_permission_banner + onCheckReason）──
      if (this.notePermissionVisible) {
        Row() {
          Text('🔔')
            .fontSize(15)
            .margin({ right: 8 })

          Text(this.notePermissionText)
            .fontSize(12)
            .fontColor('#333333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.notePermissionBtnVisible) {
            Text(this.notePermissionBtnText)
              .fontSize(12)
              .fontColor('#B300B3')
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
            .fontColor('#999999')
            .margin({ left: 8 })
            .onClick(() => {
              this.notePermissionVisible = false;
              this.presenter?.fetchCheckReason();
            })
        }
        .width('100%')
        .padding({ left: 12, right: 8, top: 8, bottom: 8 })
        .backgroundColor('#FFF9C4')
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
      if (this.listBannerVisible) {
        Row() {
          Text('ℹ')
            .fontSize(15)
            .fontColor('#F44336')
            .margin({ right: 8 })

          Text(this.listBannerText)
            .fontSize(12)
            .fontColor('#333333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text('›')
            .fontSize(22)
            .fontColor('#999999')
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 12, right: 8, top: 8, bottom: 8 })
        .backgroundColor('#FFF3E0')
        .borderRadius(6)
        .margin({ left: 4, right: 4, top: 2 })
        .onClick(() => {
          this.showListBannerDialog();
        })
      }

      // ── 搜索栏（对齐 Android search_bar_container）──
      Row() {
        Row() {
          Text('🔍')
            .fontSize(13)
            .fontColor('#AAAAAA')
            .margin({ left: 10, right: 2 })

          TextInput({ placeholder: '请输入关键字搜索消息', text: this.searchKey })
            .layoutWeight(1)
            .height(34)
            .backgroundColor(Color.Transparent)
            .fontSize(14)
            .placeholderColor('#AAAAAA')
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
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .alignItems(VerticalAlign.Center)

        // 取消按钮（对齐 Android search_cancel_btn）
        if (this.showSearchCancel) {
          Text('取消')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#B300B3')
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
                      .fontColor('#999999')
                  } else if (!this.hasMore) {
                    Text('只保留最近7天消息，没有数据了')
                      .fontSize(13)
                      .fontColor('#999999')
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
            .fontColor('#999999')
            .visibility(this.isEmpty && !this.isRefreshing ? Visibility.Visible : Visibility.Hidden)
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.Center)
      }
      .onRefreshing(() => {
        // 手动下拉刷新（对齐 Android OnRefreshListener）
        this.doRefresh();
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
