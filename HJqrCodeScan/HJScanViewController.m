//
//  HJScanViewController.m
//  HJqrCodeScan
//
//  Created by 黄坚 on 2018/3/9.
//  Copyright © 2018年 黄坚. All rights reserved.
//

#import "HJScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HJScanViewStyle.h"
#import "HJScanResult.h"
#define Size_W [UIScreen mainScreen].bounds.size.width
#define Size_H [UIScreen mainScreen].bounds.size.height

@interface HJScanViewController ()<AVCaptureMetadataOutputObjectsDelegate,UIGestureRecognizerDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate>
@property (strong,nonatomic)AVCaptureDevice * device;
@property (strong,nonatomic)AVCaptureDeviceInput * input;
@property (strong,nonatomic)AVCaptureMetadataOutput * output;
@property (strong,nonatomic)AVCaptureSession * session;
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;
@property (strong, nonatomic) NSTimer * timer;//为了做扫描动画的定时器
@property (strong, nonatomic) UIImageView * lineImage;//扫描动画的横线

@property (nonatomic,assign)CGRect scanFrame;

@property (nonatomic,weak)UIView *outputView;

@property (nonatomic,strong)HJScanViewStyle *scanViewStyle;

@property (nonatomic,assign)BOOL isAutoOpen;//闪光灯是否开着

@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;

@property (nonatomic, assign) CGPoint centerPoint;//二维码的中心点

@property (nonatomic, strong) UIView *videoPreView;

@property (nonatomic,assign)BOOL bHadAutoVideoZoom;//是否已经放大


///记录开始的缩放比例
@property(nonatomic,assign)CGFloat beginGestureScale;
///最后的缩放比例
@property(nonatomic,assign)CGFloat effectiveScale;

@property(nonatomic,strong)UIPinchGestureRecognizer *pinch;

@end

@implementation HJScanViewController

-(instancetype)initWithHJScanViewStyle:(HJScanViewStyle *)style
{
    if (self=[super init]) {
        self.scanViewStyle=style;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.scanViewStyle) {
        self.scanViewStyle=[[HJScanViewStyle alloc]init];
    }
    
    self.view.backgroundColor=[UIColor blackColor];
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                [self setConfiger];
                [self setUI];
            }else
            {
                NSLog(@"没权限");
            }
        });
    }];
   
}


//MARK: - 扫描style
-(void)setScanStyle:(HJScanViewStyle *)scanStyle
{
    _scanStyle=scanStyle;
    self.scanViewStyle=scanStyle;
    
}
//MARK: - UI
-(void)setUI
{
    //设置条码位置
    CGFloat X = self.scanViewStyle.xScanRetangleOffset/Size_W;
    CGFloat Y = (Size_H/2-(Size_W-self.scanViewStyle.xScanRetangleOffset*2)/2-self.scanViewStyle.centerUpOffset)/Size_H;
    CGFloat W = (Size_W-self.scanViewStyle.xScanRetangleOffset*2)/Size_W;
    CGFloat H = (Size_W-self.scanViewStyle.xScanRetangleOffset*2)/Size_H;
    
    self.scanFrame=CGRectMake(X*Size_W, Y*Size_H, W*Size_W, H*Size_H);
    //设置扫描范围（注意，X与Y交互，W与H交换）
    [_output setRectOfInterest:CGRectMake(Y, X, H, W)];
    if (self.scanViewStyle.isNeedScanAnim) {
        [self setAnimotionLine];
    }
    if (self.scanViewStyle.isNeedShowRetangle) {
        [self setScanView];
    }
    [self addAngel];
}
//MARK: - 扫描device配置
-(void)setConfiger
{
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:nil];
    
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //闪光灯
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

    self.photoOutput = [[AVCapturePhotoOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecTypeJPEG, AVVideoCodecKey,nil];
    [self.photoOutput setPhotoSettingsForSceneMonitoring:[AVCapturePhotoSettings photoSettingsWithFormat:outputSettings]];
    
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:_input])
    {
        [_session addInput:_input];
    }
    
    if ([_session canAddOutput:_output])
    {
        [_session addOutput:_output];
    }
    if ([_session canAddOutput:dataOutput])
    {
        [_session addOutput:dataOutput];
    }
    if ([_session canAddOutput:self.photoOutput])
    {
        [_session addOutput:self.photoOutput];
    }
    
    if ([_device lockForConfiguration:nil])
    {
        //自动白平衡
        if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
        {
            [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        //自动对焦
        if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            [_device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        //自动曝光
        if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
        {
            [_device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        [_device unlockForConfiguration];
    }
    
    if (TARGET_IPHONE_SIMULATOR != 1 || TARGET_OS_IPHONE != 1) {
        _output.metadataObjectTypes = @[AVMetadataObjectTypeEAN13Code,
                                        AVMetadataObjectTypeEAN8Code,
                                        AVMetadataObjectTypeCode128Code,
                                        AVMetadataObjectTypeQRCode];
    }
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preview.videoGravity =AVLayerVideoGravityResizeAspectFill;
    [_preview setFrame:self.view.bounds];
    
    [self.view insertSubview:self.videoPreView atIndex:0];
    [self.videoPreView.layer insertSublayer:_preview atIndex:0];
    
//    [self.view.layer insertSublayer:_preview atIndex:0];
    [self startScan];
}
//MARK: - 设置动画的线条
-(void)setAnimotionLine
{
    if (!self.lineImage) {
        self.lineImage=[[UIImageView alloc]init];
    }
    self.lineImage.frame = CGRectMake(self.scanFrame.origin.x+self.scanViewStyle.retangleW/2, self.scanFrame.origin.y+self.scanViewStyle.retangleW/2,self.scanFrame.size.width-self.scanViewStyle.retangleW, self.scanViewStyle.scanLineH);

    self.lineImage.image = self.scanViewStyle.scanImage;
    [self.view addSubview:self.lineImage];
    self.lineImage.hidden=YES;

}
//扫描动画
-(CABasicAnimation*)moveAnimation
{
    CGPoint starPoint = CGPointMake(self.lineImage.center.x , self.scanFrame.origin.y+self.scanViewStyle.retangleW/2);
    CGPoint endPoint = CGPointMake(self.lineImage.center.x, self.scanFrame.origin.y+self.scanViewStyle.retangleW/2+self.scanFrame.size.width-self.scanViewStyle.retangleW);
    
    CABasicAnimation *translation = [CABasicAnimation animationWithKeyPath:@"position"];
    translation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    translation.fromValue = [NSValue valueWithCGPoint:starPoint];
    translation.toValue = [NSValue valueWithCGPoint:endPoint];
    translation.duration = 2.5f;
    translation.repeatCount = CGFLOAT_MAX;
    //translation.autoreverses = YES;
    
    return translation;
}
//开始扫描动画
-(void)startAnimotion
{
    if (!self.scanViewStyle.isNeedScanAnim) {
        return;
    }
    [self.lineImage.layer addAnimation:[self moveAnimation] forKey:@"moveAnim"];
    self.lineImage.hidden=NO;
}
-(void)stopAnimotion
{
    if (!self.scanViewStyle.isNeedScanAnim) {
        return;
    }
    self.lineImage.hidden=YES;
    [self.lineImage.layer removeAnimationForKey:@"moveAnim"];
}

//MARK: - 添加扫描view 图层
-(void)setScanView
{
    CAShapeLayer *layer=[CAShapeLayer layer];
    layer.frame=_preview.bounds;
    layer.backgroundColor=self.scanViewStyle.notRecoginitonArea.CGColor;
    [self.view.layer addSublayer:layer];
    
    CAShapeLayer *scanLayer=[CAShapeLayer layer];
    scanLayer.backgroundColor=[UIColor clearColor].CGColor;
    scanLayer.frame=self.scanFrame;
    scanLayer.fillColor=[UIColor clearColor].CGColor;
    scanLayer.strokeColor=self.scanViewStyle.colorRetangleLine.CGColor;
    scanLayer.lineWidth=self.scanViewStyle.retangleW;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.scanFrame.size.width, self.scanFrame.size.height)];
    scanLayer.path = path.CGPath;
    [self.view.layer addSublayer:scanLayer];
}
//MARK: - 添加4个角
-(void)addAngel
{
    CGRect leftUpFrame=CGRectMake(self.scanFrame.origin.x+self.scanViewStyle.retangleW/2, self.scanFrame.origin.y+self.scanViewStyle.retangleW/2, self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeAngleW);
    UIBezierPath *leftUpPath=[self setPathWithP1:CGPointMake(0, 0) P2:CGPointMake(self.scanViewStyle.photoframeAngleW, 0) P3:CGPointMake(self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeLineW) P4:CGPointMake(self.scanViewStyle.photoframeLineW, self.scanViewStyle.photoframeLineW) P5:CGPointMake(self.scanViewStyle.photoframeLineW, self.scanViewStyle.photoframeAngleW) P6:CGPointMake(0, self.scanViewStyle.photoframeAngleW)];
    [self setAngleWithFrame:leftUpFrame path:leftUpPath];
    
    CGRect rightUpFrame=CGRectMake(self.scanFrame.origin.x+self.scanFrame.size.width-self.scanViewStyle.retangleW/2-self.scanViewStyle.photoframeAngleW, self.scanFrame.origin.y+self.scanViewStyle.retangleW/2, self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeAngleW);
    UIBezierPath *rightUpPath=[self setPathWithP1:CGPointMake(0, 0) P2:CGPointMake(self.scanViewStyle.photoframeAngleW, 0) P3:CGPointMake(self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeAngleW) P4:CGPointMake(self.scanViewStyle.photoframeAngleW-self.scanViewStyle.photoframeLineW, self.scanViewStyle.photoframeAngleW) P5:CGPointMake(self.scanViewStyle.photoframeAngleW-self.scanViewStyle.photoframeLineW, self.scanViewStyle.photoframeLineW) P6:CGPointMake(0, self.scanViewStyle.photoframeLineW)];
    [self setAngleWithFrame:rightUpFrame path:rightUpPath];
    
    CGRect leftDownFrame=CGRectMake(self.scanFrame.origin.x+self.scanViewStyle.retangleW/2, self.scanFrame.origin.y-self.scanViewStyle.retangleW/2+self.scanFrame.size.height-self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeAngleW);
    UIBezierPath *leftDownPath=[self setPathWithP1:CGPointMake(0, 0) P2:CGPointMake(self.scanViewStyle.photoframeLineW, 0) P3:CGPointMake(self.scanViewStyle.photoframeLineW, self.scanViewStyle.photoframeAngleW-self.scanViewStyle.photoframeLineW) P4:CGPointMake(self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeAngleW-self.scanViewStyle.photoframeLineW) P5:CGPointMake(self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeAngleW) P6:CGPointMake(0, self.scanViewStyle.photoframeAngleW)];
    [self setAngleWithFrame:leftDownFrame path:leftDownPath];
    
    CGRect rightDownFrame=CGRectMake(self.scanFrame.origin.x+self.scanFrame.size.width-self.scanViewStyle.retangleW/2-self.scanViewStyle.photoframeAngleW, self.scanFrame.origin.y-self.scanViewStyle.retangleW/2+self.scanFrame.size.height-self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeAngleW);
    UIBezierPath *rightDownPath=[self setPathWithP1:CGPointMake(self.scanViewStyle.photoframeAngleW-self.scanViewStyle.photoframeLineW, 0) P2:CGPointMake(self.scanViewStyle.photoframeAngleW, 0) P3:CGPointMake(self.scanViewStyle.photoframeAngleW, self.scanViewStyle.photoframeAngleW) P4:CGPointMake(0, self.scanViewStyle.photoframeAngleW) P5:CGPointMake(0, self.scanViewStyle.photoframeAngleW-self.scanViewStyle.photoframeLineW) P6:CGPointMake(self.scanViewStyle.photoframeAngleW-self.scanViewStyle.photoframeLineW, self.scanViewStyle.photoframeAngleW-self.scanViewStyle.photoframeLineW)];
    [self setAngleWithFrame:rightDownFrame path:rightDownPath];
    
}
//MARK: - 4个角路径
-(UIBezierPath *)setPathWithP1:(CGPoint)p1 P2:(CGPoint)p2 P3:(CGPoint)p3 P4:(CGPoint)p4 P5:(CGPoint)p5 P6:(CGPoint)p6{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:p1];
    [path addLineToPoint:p2];
    [path addLineToPoint:p3];
    [path addLineToPoint:p4];
    [path addLineToPoint:p5];
    [path addLineToPoint:p6];
    [path closePath];
    return path;
}
//MARK: - 添加4个角图层
-(void)setAngleWithFrame:(CGRect)frame path:(UIBezierPath *)path
{
    CAShapeLayer *shapeLayer=[CAShapeLayer layer];
    shapeLayer.frame=frame;
    shapeLayer.fillColor=self.scanViewStyle.colorAngle.CGColor;
    shapeLayer.strokeColor=[UIColor clearColor].CGColor;
    shapeLayer.lineWidth=self.scanViewStyle.photoframeLineW;
    shapeLayer.path=path.CGPath;
    [self.view.layer addSublayer:shapeLayer];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (self.scanViewStyle.isVideoZoom&&!_bHadAutoVideoZoom) {
        AVMetadataMachineReadableCodeObject *obj = (AVMetadataMachineReadableCodeObject *)[self.preview transformedMetadataObjectForMetadataObject:metadataObjects.lastObject];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self changeVideoScale:obj];
        });
        _bHadAutoVideoZoom  =YES;
        return;
    }
    [self stopScan];
    NSMutableArray *resultArray=[NSMutableArray array];
    [metadataObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AVMetadataMachineReadableCodeObject *codeObj=obj;
        HJScanResult *result=[[HJScanResult alloc]init];
        result.strScanned=codeObj.stringValue;
        result.strBarCodeType=codeObj.type;
        [resultArray addObject:result];
    }];
    if (_scanResult) {
        _scanResult(resultArray);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startScan];
    });
}
#pragma mark - 二维码自动拉近

- (void)changeVideoScale:(AVMetadataMachineReadableCodeObject *)objc
{
    NSArray *array = objc.corners;
    NSLog(@"cornersArray = %@",array);
    CGPoint point = CGPointZero;
    // 把字典转换为点，存在point里，成功返回true 其他false
    CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)array[0], &point);
    
    NSLog(@"X:%f -- Y:%f",point.x,point.y);
    CGPoint point2 = CGPointZero;
    CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)array[2], &point2);
    NSLog(@"X:%f -- Y:%f",point2.x,point2.y);
    
    self.centerPoint = CGPointMake((point.x + point2.x) / 2, (point.y + point2.y) / 2);
    CGFloat scace = 150 / (point2.x - point.x); //当二维码图片宽小于150，进行放大
    [self setVideoScale:scace];
}
- (void)setVideoScale:(CGFloat)scale
{
    [self.input.device lockForConfiguration:nil];
    
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self photoOutput] connections]];
    CGFloat maxScaleAndCropFactor = ([[self.photoOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor])/16;
    
    if (scale > maxScaleAndCropFactor){
        scale = maxScaleAndCropFactor;
    }else if (scale < 1){
        scale = 1;
    }
    
    CGFloat zoom = scale / videoConnection.videoScaleAndCropFactor;
    videoConnection.videoScaleAndCropFactor = scale;
    
    [self.input.device unlockForConfiguration];
    
    CGAffineTransform transform = self.videoPreView.transform;
    
    //自动拉近放大
    if (scale == 1) {
        self.videoPreView.transform = CGAffineTransformScale(transform, zoom, zoom);
        CGRect rect = self.videoPreView.frame;
        rect.origin = CGPointZero;
        self.videoPreView.frame = rect;
    } else {
        CGFloat x = self.videoPreView.center.x - self.centerPoint.x;
        CGFloat y = self.videoPreView.center.y - self.centerPoint.y;
        CGRect rect = self.videoPreView.frame;
        rect.origin.x = rect.size.width / 2.0 * (1 - scale);
        rect.origin.y = rect.size.height / 2.0 * (1 - scale);
        rect.origin.x += x * zoom;
        rect.origin.y += y * zoom;
        rect.size.width = rect.size.width * scale;
        rect.size.height = rect.size.height * scale;
        
        rect.origin.y-=self.scanViewStyle.centerUpOffset;
        
        [UIView animateWithDuration:.5f animations:^{
            self.videoPreView.transform = CGAffineTransformScale(transform, zoom, zoom);
            self.videoPreView.frame = rect;
        } completion:^(BOOL finished) {
        }];
        NSLog(@"hehe -- %lf,%lf,%lf,%lf",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
    }
    
    NSLog(@"放大%f",zoom);
}
- (UIView *)videoPreView{
    if (!_videoPreView) {
        UIView *videoView = [[UIView alloc]initWithFrame:self.view.bounds];
        videoView.backgroundColor = [UIColor clearColor];
        _videoPreView = videoView;
    }
    return _videoPreView;
}
- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
    for ( AVCaptureConnection *connection in connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:mediaType] ) {
                return connection;
            }
        }
    }
    return nil;
}
//MARK: - 开始/停止扫描
-(void)startScan
{
    [self.session startRunning];
    [self startAnimotion];
    _bHadAutoVideoZoom=NO;
    if (self.scanViewStyle.isVideoZoom) {
        [self setVideoScale:1];
    }
    if (self.scanViewStyle.isGesZoom) {
        [self cameraInitOver];
        [self setVideoScale1:1];
        self.effectiveScale=1;
        self.beginGestureScale=0;
    }
    if (self.videoPreView) {
        self.videoPreView.frame=self.view.bounds;
    }
}
-(void)stopScan
{
    [self.session stopRunning];
    [self stopAnimotion];
    if (self.pinch) {
        [self.videoPreView removeGestureRecognizer:self.pinch];
        self.pinch=nil;
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    
    if (!self.scanViewStyle.isAutoFlash) {
        return;
    }
    // brightnessValue 值代表光线强度，值越小代表光线越暗
    if (brightnessValue <= self.scanViewStyle.autoFlashBrightness && !_isAutoOpen) {
        [self turnTorchOn:YES];
    }else if(brightnessValue > self.scanViewStyle.autoFlashBrightness && _isAutoOpen)
    {
        [self turnTorchOn:NO];
    }
    NSLog(@"brightness --  %lf",brightnessValue);
}
// 打开/关闭手电筒
- (void)turnTorchOn:(BOOL)on{
    if ([self.device hasTorch] && [self.device hasFlash]){
        
        [self.device lockForConfiguration:nil];
        if (on) {
            [self.device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [self.device setTorchMode:AVCaptureTorchModeOff];
        }
        _isAutoOpen=on;
        [self.device unlockForConfiguration];
    } else {
        NSLog(@"当前设备没有闪光灯，不能提供手电筒功能");
    }
}

//MARK: - 手势拉近放大
- (void)cameraInitOver
{
    if (self.scanViewStyle.isGesZoom) {
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDetected:)];
        pinch.delegate = self;
        [self.videoPreView addGestureRecognizer:pinch];
        self.pinch=pinch;
    }
}

- (void)pinchDetected:(UIPinchGestureRecognizer*)recogniser
{
    self.effectiveScale = self.beginGestureScale * recogniser.scale;
    if (self.effectiveScale < 1.0){
        self.effectiveScale = 1.0;
    }
    [self setVideoScale1:self.effectiveScale];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        _beginGestureScale = _effectiveScale;
    }
    return YES;
}
- (void)setVideoScale1:(CGFloat)scale
{
    [_input.device lockForConfiguration:nil];
    
    AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self photoOutput] connections]];
    CGFloat maxScaleAndCropFactor = ([[self.photoOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor])/16;
    
    if (scale > maxScaleAndCropFactor)
        scale = maxScaleAndCropFactor;
    
    CGFloat zoom = scale / videoConnection.videoScaleAndCropFactor;
    
    videoConnection.videoScaleAndCropFactor = scale;
    
    [_input.device unlockForConfiguration];
    
    CGAffineTransform transform = _videoPreView.transform;
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    _videoPreView.transform = CGAffineTransformScale(transform, zoom, zoom);
    [CATransaction commit];
    
}

@end
