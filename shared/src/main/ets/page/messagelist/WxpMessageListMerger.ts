import { WxpMessageListMessage } from './WxpMessageListBean';

/**
 * 增量拉取的合并结果
 */
export interface WxpMessageListMergeResult {
  /** 合并后的列表，按 messageId 降序 */
  list: WxpMessageListMessage[];
  /** 是否判定为断层，整个列表被第一页替换了 */
  replaced: boolean;
  /** 合并后新的同步锚点 */
  syncedMaxId: number;
}

/**
 * 消息列表的合并规则，对应 KMP WxpMessageListMerger.kt，纯函数。
 */
export class WxpMessageListMerger {
  /** 后端一页固定返回30条（UserReceiveRecordMapper.findUserMessageHistoryList 的 LIMIT 0,30） */
  static readonly SERVER_PAGE_SIZE = 30;

  /**
   * 增量拉取后，把服务端第一页合并进本地列表
   *
   * 同步锚点 syncedMaxId 是最近一次从服务端拉到的最大 id，推送插入的消息不会推进它，
   * 用它判断拉到的第一页和本地数据有没有重叠。
   *
   * @param local 本地当前列表，按 messageId 降序
   * @param serverPage 服务端返回的第一页，按 messageId 降序
   * @param syncedMaxId 同步锚点，0 表示还没有同步过
   */
  static merge(
    local: WxpMessageListMessage[],
    serverPage: WxpMessageListMessage[],
    syncedMaxId: number,
  ): WxpMessageListMergeResult {
    const serverMaxId = serverPage.length > 0 ? WxpMessageListMerger.maxId(serverPage) : syncedMaxId;
    // 本地为空，直接用服务端数据
    if (local.length === 0) {
      return { list: [...serverPage], replaced: true, syncedMaxId: serverMaxId };
    }
    // 服务端为空，可能是暂时的，不能因此清空本地列表
    if (serverPage.length === 0) {
      return { list: [...local], replaced: false, syncedMaxId: syncedMaxId };
    }
    // 拉满一页，并且最小的 id 都比锚点大，说明锚点之后的新消息超过一页，中间有丢失，直接替换
    const serverMinId = Math.min(...serverPage.map(m => m.messageId));
    if (serverPage.length >= WxpMessageListMerger.SERVER_PAGE_SIZE && serverMinId > syncedMaxId) {
      return { list: [...serverPage], replaced: true, syncedMaxId: serverMaxId };
    }
    // 有重叠：本地没有的按 id 补进来，本地已有的只把未读同步成已读，不反向改
    // （列表里点开消息时本地先标记已读，服务端要等详情页加载后才标记，反向同步会把刚看过的消息改回未读）
    const serverById = new Map<number, WxpMessageListMessage>();
    serverPage.forEach(m => serverById.set(m.messageId, m));
    // 创建新对象而非原地修改：ArkUI ForEach 的 key 带 read，原地修改不会重渲染
    const merged: WxpMessageListMessage[] = local.map(localMessage => {
      const serverMessage = serverById.get(localMessage.messageId);
      if (serverMessage && serverMessage.read && !localMessage.read) {
        return { ...localMessage, read: true };
      }
      return localMessage;
    });
    const localIds = new Set<number>(local.map(m => m.messageId));
    serverPage.forEach(m => {
      if (!localIds.has(m.messageId)) {
        merged.push(m);
      }
    });
    merged.sort((a, b) => b.messageId - a.messageId);
    return { list: merged, replaced: false, syncedMaxId: Math.max(syncedMaxId, serverMaxId) };
  }

  private static maxId(list: WxpMessageListMessage[]): number {
    return Math.max(...list.map(m => m.messageId));
  }
}
