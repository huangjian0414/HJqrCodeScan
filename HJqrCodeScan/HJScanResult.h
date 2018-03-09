//
//  HJScanResult.h
//  HJqrCodeScan
//
//  Created by 黄坚 on 2018/3/3.
//  Copyright © 2018年 黄坚. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface HJScanResult : NSObject
/**
 条码字符串
 */
@property (nonatomic, copy) NSString* strScanned;

/**
 扫码码的类型,AVMetadataObjectType  
 */
@property (nonatomic, copy) NSString* strBarCodeType;
@end
