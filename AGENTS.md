# wxpusher-app-harmony — HarmonyOS 客户端

## 固定首句

- 每次回复的第一句话必须是：`【识别到wxpusher-app-harmony/AGENTS.md】`

## 技术栈

- **平台**：HarmonyOS NEXT（API 12 / SDK 6.0.2）
- **语言**：ArkTS / ETS（TypeScript 方言）
- **构建**：hvigor（鸿蒙专用构建工具）
- **推送**：华为 Push Kit（`com.huawei.service.push.base_service`）
- **包名**：`com.smjcco.wxpusher.hm`

## 项目定位

鸿蒙平台的 WxPusher 客户端，架构设计与 Android/iOS 端对齐：

1. **消息接收与展示**：通过华为 Push Kit 接收推送
2. **WebView 桥接**：与 Android/iOS 端一致的桥接协议（`WxpWebBridgeManager`）
3. **用户交互**：登录、扫码、消息列表、个人中心

## 详细功能

- **推送管理**：`WxpPushManager` 管理华为 Push Kit 注册与消息接收，`WxpPushExtensionAbility` 处理后台推送
- **WebView 桥接**：`WxpWebBridgeManager.ets` 注册与 Android/iOS 端一致的 action（`getLoginInfo`、`getEnvBaseUrl`、`showToast`、`openUrl`、`payRequest`、`setWebBottomBar`、`setWebOptionMenu`）
- **MVP 架构**：shared 模块 `WxpBaseMvp` + `Contract + Presenter` 模式，与其他端对齐
- **网络层**：`WxpNetworkService`，与其他端对齐的 REST API 封装（`WxpApiService`）
- **环境切换**：`TestPanelPage` 可动态修改 `WxpConfig` 中的 API/WS/H5 地址
- **H5 资源版本管理**：`AppFeVersionManager` 对比版本决定是否清理 WebView 缓存

## 目录结构

```
wxpusher-app-harmony/
├── oh-package.json5              # 鸿蒙包配置
├── oh-package-lock.json5         # 依赖锁定
├── build-profile.json5           # 构建配置（签名/SDK 版本/模块声明）
├── code-linter.json5             # 代码检查配置
├── hvigorfile.ts                 # 构建脚本入口
├── hvigor/                       # 构建工具配置
├── .github/
│   └── workflows/
│       └── release-harmony-app.yml  # CI/CD 发布流程
├── AppScope/                     # 应用级配置
│   ├── app.json5                 # 应用信息
│   └── resources/                # 图标资源
├── app/                          # 主模块
│   ├── oh-package.json5
│   ├── build-profile.json5
│   └── src/main/
│       ├── module.json5          # 模块配置
│       ├── ets/
│       │   ├── appability/
│       │   │   └── AppAbility.ets            # 应用入口 Ability
│       │   ├── appbackupability/
│       │   │   └── AppBackupAbility.ets      # 备份 Ability
│       │   ├── pages/
│       │   │   ├── Index.ets                 # 首页
│       │   │   ├── MainPage.ets              # 主页面（Tab 容器）
│       │   │   ├── LoginPage.ets             # 登录
│       │   │   ├── BindPage.ets              # 绑定
│       │   │   ├── RegisterOrBindPage.ets    # 注册或绑定
│       │   │   ├── ScanPage.ets              # 扫码
│       │   │   ├── WebViewPage.ets           # WebView 容器
│       │   │   ├── AccountDetailPage.ets     # 账户详情
│       │   │   ├── ChangePhonePage.ets       # 换绑手机
│       │   │   ├── RemoveAccountPage.ets     # 注销账户
│       │   │   ├── UserAgreementPage.ets     # 用户协议
│       │   │   ├── TestPanelPage.ets         # 测试面板（环境切换）
│       │   │   └── tabs/
│       │   │       ├── MessageListTab.ets    # 消息列表 Tab
│       │   │       ├── ProfileTab.ets        # 个人中心 Tab
│       │   │       └── ProviderListTab.ets   # 服务商列表 Tab
│       │   ├── push/
│       │   │   ├── WxpPushManager.ets        # 推送管理器
│       │   │   ├── WxpPushExtensionAbility.ets  # 推送扩展 Ability
│       │   │   └── WxpPushEventId.ets        # 推送事件 ID 常量
│       │   ├── webbridge/                    # WebView 桥接（与 Android/iOS 对齐）
│       │   │   ├── WxpWebBridgeManager.ets   # 桥接管理器
│       │   │   ├── WxpBridgeContracts.ets    # 桥接协议定义
│       │   │   ├── WxpBridgeEmitter.ets      # 事件发射
│       │   │   ├── WxpBridgeMessageParser.ets  # 消息解析
│       │   │   └── handlers/                 # 各 action 处理器
│       │   │       ├── GetLoginInfoBridgeHandler.ets
│       │   │       ├── WxpGetEnvBaseUrlBridgeHandler.ets
│       │   │       ├── ShowToastBridgeHandler.ets
│       │   │       ├── OpenUrlBridgeHandler.ets
│       │   │       ├── PayRequestBridgeHandler.ets
│       │   │       ├── SetWebBottomBarBridgeHandler.ets
│       │   │       └── SetWebOptionMenuBridgeHandler.ets
│       │   ├── common/                       # 公共服务实现
│       │   │   ├── WxpAppGateKeys.ets
│       │   │   ├── WxpAppPageServiceImpl.ets
│       │   │   ├── WxpBaseInfoServiceImpl.ets
│       │   │   ├── WxpDialogUtilsImpl.ets
│       │   │   ├── WxpJumpPageUtils.ets
│       │   │   ├── WxpLogUtilsImpl.ets
│       │   │   ├── WxpSaveServiceImpl.ets
│       │   │   └── WxpToastUtilsImpl.ets
│       │   ├── components/
│       │   │   └── WxpWebViewComponent.ets   # WebView 封装组件
│       │   └── wxapi/
│       │       └── WxpWeixinOpenManager.ets  # 微信开放平台
│       └── resources/                        # 图片/字符串/颜色等资源
└── shared/                       # 共享模块（跨模块复用业务逻辑）
    ├── oh-package.json5
    ├── build-profile.json5
    ├── Index.ets                 # 模块导出入口
    ├── BuildProfile.ets
    └── src/main/ets/
        ├── config/
        │   └── WxpConfig.ts                  # 全局配置（baseUrl/wsUrl/appFeUrl）
        ├── api/
        │   └── WxpApiService.ts              # REST API 封装
        ├── base/
        │   ├── biz/                          # 业务服务
        │   │   ├── WxpAppDataService.ts      # 应用数据服务
        │   │   ├── WxpAppPageService.ts      # 页面路由服务
        │   │   └── bean/                     # 数据模型
        │   │       ├── WxpLoginInfo.ts
        │   │       ├── WxpPlatformEnum.ts
        │   │       └── WxpUpdateInfoBean.ts
        │   └── common/                       # 公共工具
        │       ├── WxpNetworkService.ts      # 网络请求
        │       ├── WxpBaseMvp.ts             # MVP 基类
        │       ├── WxpBaseInfoService.ts     # 基础信息
        │       ├── WxpSaveService.ts         # 持久化
        │       ├── WxpDialogUtils.ts / WxpToastUtils.ts / WxpLoadingUtils.ts
        │       ├── WxpLogUtils.ts / WxpDateTimeUtils.ts / WxpRandomUtils.ts
        │       ├── WxpCommonExt.ts / WxpScopeUtils.ts / WxpMaskUtils.ts
        │       └── WxpSerializationUtils.ts
        ├── page/                             # MVP Presenter + Contract（各业务页面）
        │   ├── login/                        # 登录
        │   ├── bind/                         # 绑定
        │   ├── scan/                         # 扫码
        │   ├── messagelist/                  # 消息列表
        │   ├── providerlist/                 # 服务商列表
        │   ├── accountdetail/                # 账户详情
        │   ├── changephone/                  # 换绑手机
        │   └── registerorbind/               # 注册或绑定
        └── web/
            ├── AppFeVersionManager.ts        # H5 资源版本管理
            └── WxpWebHostPolicy.ts           # WebView Host 白名单
```

## 注意事项

- 需要 HarmonyOS DevEco Studio 开发环境，Cloud Agent 环境中无法构建
- 签名配置在 `build-profile.json5`，release 签名使用占位符（CI 替换）
- `targetSdkVersion` 和 `compatibleSdkVersion` 均为 `6.0.2(22)`
- 与 Android/iOS 端共享相同的桥接 action 集合，改动时四端须同步
