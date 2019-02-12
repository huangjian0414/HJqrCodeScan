//
//  HJScanViewStyle.m
//  HJqrCodeScan
//
//  Created by 黄坚 on 2018/2/16.
//  Copyright © 2018年 黄坚. All rights reserved.
//

#import "HJScanViewStyle.h"

@implementation HJScanViewStyle
-(instancetype)init
{
    if (self=[super init]) {
        _isNeedShowRetangle = YES;
        
        _colorRetangleLine = [UIColor whiteColor];
        
        _centerUpOffset = 60;
        _xScanRetangleOffset = 100;
        _photoframeAngleStyle = HJScanViewPhotoframeAngleStyle_Inner;
        _colorAngle = [UIColor blueColor];
        _retangleW = 6;
        _notRecoginitonArea = [UIColor colorWithRed:0. green:.0 blue:.0 alpha:.5];
        
        _photoframeAngleW = 12;

        _photoframeLineW = 2;
        _scanLineH= 8;
        _isNeedScanAnim=YES;
        _scanImage=[UIImage imageNamed:@"qrcode_scan_light_green@2x"];
        
        _isVideoZoom=NO;
        _isGesZoom=NO;
        _isAutoFlash=NO;
        _autoFlashBrightness=-2;
    }
    return self;
}
-(void)setIsGesZoom:(BOOL)isGesZoom
{
    _isGesZoom=isGesZoom;
    _isVideoZoom=!isGesZoom;
}
-(void)setIsVideoZoom:(BOOL)isVideoZoom
{
    _isVideoZoom=isVideoZoom;
    _isGesZoom=!isVideoZoom;
}
@end
