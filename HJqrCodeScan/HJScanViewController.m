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

@interface HJScanViewController ()<AVCaptureMetadataOutputObjectsDelegate>
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
@end

@implementation HJScanViewController

-(instancetype)initWithHJScanViewStyle:(HJScanViewStyle *)style
{
    if (self=[super init]) {
        self.scanViewStyle=style;
    }
    return self;
}
- (void)lineAction{
    
    [UIView animateWithDuration:2.4f animations:^{
        CGRect frame = CGRectMake(self.scanFrame.origin.x+_scanViewStyle.retangleW/2, self.scanFrame.origin.y+_scanViewStyle.retangleW/2+self.scanFrame.size.width-_scanViewStyle.retangleW, self.scanFrame.size.width-_scanViewStyle.retangleW/2, _scanViewStyle.scanLineH);
        self.lineImage.frame = frame;
    } completion:^(BOOL finished) {
        CGRect frame =CGRectMake(self.scanFrame.origin.x+self.scanViewStyle.retangleW/2, self.scanFrame.origin.y+self.scanViewStyle.retangleW/2,self.scanFrame.size.width-self.scanViewStyle.retangleW, self.scanViewStyle.scanLineH);
        self.lineImage.frame = frame;
    }];
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
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeTimer];
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
    [self.view.layer insertSublayer:_preview atIndex:0];
    [_session startRunning];
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
    _timer = [NSTimer scheduledTimerWithTimeInterval:2.5f
                                              target:self
                                            selector:@selector(lineAction)
                                            userInfo:nil
                                             repeats:YES];
    [_timer setFireDate:[NSDate distantPast]];
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
-(void)removeTimer
{
    if (_timer) {
        [_timer invalidate];
        _timer=nil;
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    [self stopScan];
    NSMutableArray *resultArray=[NSMutableArray array];
    [metadataObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AVMetadataMachineReadableCodeObject *codeObj=obj;
        HJScanResult *result=[[HJScanResult alloc]init];
        result.strScanned=codeObj.stringValue;
        result.strBarCodeType=codeObj.type;
    }];
    if (_scanResult) {
        _scanResult(resultArray);
    }
    
}
-(void)startScan
{
    [self.session startRunning];
}
-(void)stopScan
{
    [self.session stopRunning];
}


@end
