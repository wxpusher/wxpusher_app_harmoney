/**
 * 服务端 /api/device/version-update 的响应结构。
 * 注：鸿蒙无 TBS，忽略后端可能下发的 downgradeToTbs 字段（JSON 解析自动忽略多余字段）。
 */
export interface AppVersionCheckResp {
  hasUpdate: boolean;
  forceUpdate: boolean;
  title: string;
  content: string;
  latestVersion: string;
  downloadUrl: string;
}
