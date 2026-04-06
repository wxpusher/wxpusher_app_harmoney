// ─────────────────────────────────────────────────────────
// 消息市场 Tab
// ─────────────────────────────────────────────────────────

@Component
export struct ProviderListTab {
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
