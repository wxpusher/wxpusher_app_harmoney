import { router, promptAction } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { inputMethod } from '@kit.IMEKit';
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
} from '@wxpusher/shared';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  @Builder
  tabBuilder(title: string, index: number, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? '#B300B3' : '#999999')
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#B300B3' : '#999999')
        .margin({ top: 2 })
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = index;
      this.tabsController.changeIndex(index);
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
      TabContent() {
        MessageListTab({ currentTabIndex: this.currentIndex })
      }
      .tabBar(this.tabBuilder('消息列表', 0, $r('app.media.ic_paperplane')))

      TabContent() {
        ProviderListTab()
      }
      .tabBar(this.tabBuilder('消息市场', 1, $r('app.media.ic_cloud')))

      TabContent() {
        ProfileTab()
      }
      .tabBar(this.tabBuilder('我的', 2, $r('app.media.ic_person')))
    }
    .scrollable(false)
    .barHeight(56)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}

// ─────────────────────────────────────────────────────────
// 消息列表 Tab（对齐 Android MessageListFragment）
// ─────────────────────────────────────────────────────────

@Component
struct MessageListTab {
  /** 父级传入的当前 Tab 索引，用于感知 resume（切回本 Tab） */
  @Prop @Watch('onTabIndexChanged') currentTabIndex: number = 0;

  // ── 列表数据 ──
  @State messageList: WxpMessageListMessage[] = [];
  @State isRefreshing: boolean = false;
  @State isEmpty: boolean = false;
  @State hasMore: boolean = true;

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
    this.presenter.fetchCheckReason();
    this.presenter.fetchListBanner();
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
    this.presenter = null;
  }

  /**
   * 当本 Tab 重新变为活动 Tab 时触发（对齐 Android onResume）
   */
  onTabIndexChanged(): void {
    if (this.currentTabIndex === 0) {
      this.presenter?.fetchListBanner();
      this.presenter?.fetchCheckReason();
    }
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

  showMessageMoreLoading(_loading: boolean, hasMore: boolean): void {
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
      const found = this.messageList.find(m => m.messageId === message.messageId);
      if (found && !found.read) {
        found.read = true;
        this.messageList = [...this.messageList];
      }
    }
  }

  /**
   * 长按消息：弹出 ActionSheet（对齐 Android ActionSheetDialogFragment）
   */
  private showMessageOptions(message: WxpMessageListMessage): void {
    const readOptText = message.read ? '标记未读' : '标记已读';
    const buttons: [promptAction.Button, promptAction.Button] = [
      { text: readOptText, color: '#333333' },
      { text: '删除', color: '#FF3B30' },
    ];
    promptAction.showActionMenu({ title: '', buttons })
      .then((result: promptAction.ActionMenuSuccessResponse) => {
        if (result.index === 0) {
          this.presenter?.markMessageReadStatus(message.messageId, !message.read);
        } else if (result.index === 1) {
          this.presenter?.deleteById(message.messageId);
        }
      })
      .catch(() => {});
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
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          this.showMessageOptions(message);
        })
    )
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
            Button(this.notePermissionBtnText)
              .height(30)
              .fontSize(12)
              .backgroundColor('#B300B3')
              .fontColor(Color.White)
              .borderRadius(4)
              .padding({ left: 8, right: 8 })
              .margin({ left: 8 })
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
              (message: WxpMessageListMessage) => String(message.messageId)
            )
          }
          .width('100%')
          .height('100%')
          .onReachEnd(() => {
            // 加载更多（对齐 Android setOnLoadMoreListener）
            if (this.hasMore && !this.isRefreshing) {
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

// ─────────────────────────────────────────────────────────
// 消息市场 Tab
// ─────────────────────────────────────────────────────────

@Component
struct ProviderListTab {
  build() {
    Column() {
      Row() {
        Text('消息市场')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      // WebView 加载市场 H5
      Text('市场页面（WebView）')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 100 })
    }
    .width('100%')
    .height('100%')
  }
}

// ─────────────────────────────────────────────────────────
// 我的 Tab
// ─────────────────────────────────────────────────────────

@Component
struct ProfileTab {
  build() {
    Column() {
      Row() {
        Text('我的')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16 })
      .alignItems(VerticalAlign.Center)

      List() {
        ListItem() {
          Row() {
            Text('账号详情')
            Blank()
            Text('>')
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/AccountDetailPage' });
          })
        }

        ListItem() {
          Row() {
            Text('换绑手机号')
            Blank()
            Text('>')
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/ChangePhonePage' });
          })
        }

        ListItem() {
          Row() {
            Text('关于 WxPusher')
            Blank()
            Text('>')
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(52)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            router.pushUrl({
              url: 'pages/WebViewPage',
              params: { url: 'https://wxpusher.zjiecode.com/docs' },
            });
          })
        }
      }
      .divider({ strokeWidth: 0.5, color: '#F0F0F0' })
    }
    .width('100%')
    .height('100%')
  }
}
