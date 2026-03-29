import { router } from '@kit.ArkUI';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import {
  WxpScanPresenter,
  IWxpScanPresenter,
} from '@wxpusher/shared';

@Entry
@Component
struct ScanPage {
  private presenter: WxpScanPresenter | null = null;

  createPresenter(): IWxpScanPresenter {
    return new WxpScanPresenter(this);
  }

  aboutToAppear(): void {
    this.presenter = this.createPresenter() as WxpScanPresenter;
    // 启动扫码
    this.startScan();
  }

  aboutToDisappear(): void {
    this.presenter?.onDestroy();
  }

  private startScan(): void {
    try {
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE],
        enableMultiMode: false,
        enableAlbum: true,
      };
      scanBarcode.startScanForResult(getContext(this), options).then((result) => {
        if (result.originalValue) {
          this.presenter?.scan(result.originalValue);
        } else {
          router.back();
        }
      }).catch(() => {
        router.back();
      });
    } catch {
      router.back();
    }
  }

  onClosePage(): void {
    router.back();
  }

  onOpenWebPage(url: string): void {
    router.pushUrl({
      url: 'pages/WebViewPage',
      params: { url: url },
    });
  }

  onCopy(data: string): void {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, data);
    pasteboard.getSystemPasteboard().setDataSync(pasteData);
    promptAction.showToast({ message: '已复制' });
  }

  build() {
    Column() {
      Text('扫描中...')
        .fontSize(16)
        .fontColor('#999999')
        .margin({ top: 200 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }
}
