//
//  HJScanViewController.h
//  HJqrCodeScan
//
//  Created by 黄坚 on 2018/3/9.
//  Copyright © 2018年 黄坚. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HJScanViewStyle;
@class HJScanResult;
typedef void(^ScanResult)(NSArray<HJScanResult *>*);
@interface HJScanViewController : UIViewController

-(instancetype)initWithHJScanViewStyle:(HJScanViewStyle *)style;
@property (nonatomic,strong)HJScanViewStyle *scanStyle;

@property (nonatomic,assign)ScanResult scanResult;

-(void)startScan;
-(void)stopScan;
@end
