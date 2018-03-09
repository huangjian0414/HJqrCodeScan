//
//  HJScanViewStyle.h
//  HJqrCodeScan
//
//  Created by 黄坚 on 2018/2/16.
//  Copyright © 2018年 黄坚. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 扫码区域4个角位置类型
 */
typedef NS_ENUM(NSInteger, HJScanViewPhotoframeAngleStyle)
{
    HJScanViewPhotoframeAngleStyle_Inner,//内嵌，一般不显示矩形框情况下
    HJScanViewPhotoframeAngleStyle_Outer,//外嵌,包围在矩形框的4个角
    HJScanViewPhotoframeAngleStyle_On   //在矩形框的4个角上，覆盖
};
@interface HJScanViewStyle : NSObject

/**
 @brief  是否需要绘制扫码矩形框，默认YES
 */
@property (nonatomic, assign) BOOL isNeedShowRetangle;

/**
    矩形框移动偏移量，0表示扫码透明区域在当前视图中心位置，< 0 表示扫码区域下移, >0 表示扫码区域上移
 */
@property (nonatomic, assign) CGFloat centerUpOffset;

/**
 *  矩形框(视频显示透明区)域离界面左边及右边距离，默认60
 */
@property (nonatomic, assign) CGFloat xScanRetangleOffset;

/**
 @brief  矩形框线条颜色
 */
@property (nonatomic, strong) UIColor *colorRetangleLine;

/**
 矩形框线条宽度
 */
@property (nonatomic,assign)CGFloat retangleW;
/**
 扫码区域的4个角类型
 */
@property (nonatomic, assign) HJScanViewPhotoframeAngleStyle photoframeAngleStyle;

//4个角的颜色
@property (nonatomic, strong) UIColor* colorAngle;

//扫码区域4个角的宽度和高度
@property (nonatomic, assign) CGFloat photoframeAngleW;

/**
 扫码区域4个角的线条宽度,默认6，建议8到4之间
 */
@property (nonatomic, assign) CGFloat photoframeLineW;

/**
 非识别区域颜色,默认 RGBA (0,0,0,0.5)
 */
@property (nonatomic, strong) UIColor *notRecoginitonArea;

/**
 扫描线条高度
 */
@property (nonatomic,assign)CGFloat scanLineH;

/**
 是否需要扫描动画
 */
@property (nonatomic,assign)BOOL isNeedScanAnim;

/**
 扫描图片
 */
@property (nonatomic,strong)UIImage *scanImage;
@end
