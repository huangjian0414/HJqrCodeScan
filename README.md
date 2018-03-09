# HJqrCodeScan
一个简单的扫码

用法：

    HJScanViewStyle *style=[[HJScanViewStyle alloc]init];
    style.xScanRetangleOffset=100;
    style.colorRetangleLine = [UIColor whiteColor];
    
    style.centerUpOffset = -100;
    
    style.photoframeAngleStyle = HJScanViewPhotoframeAngleStyle_Inner;
    style.colorAngle = [UIColor redColor];
    style.retangleW = 14;
    style.notRecoginitonArea = [UIColor colorWithRed:0. green:.0 blue:.0 alpha:.5];
    
    style.photoframeAngleW = 20;
    
    style.photoframeLineW = 2;
    style.scanLineH= 8;

    HJScanViewController *vc=[[HJScanViewController alloc]initWithHJScanViewStyle:style];
