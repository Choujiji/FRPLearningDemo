//
//  FRPCell.m
//  FunctionReactivePixels
//
//  Created by mac on 15/5/6.
//  Copyright (c) 2015年 jiji. All rights reserved.
//

#import "FRPCell.h"
#import "FRPPhotoModel.h"

@interface FRPCell ()

@property (nonatomic, weak) UIImageView *imageView;

//@property (nonatomic, strong) RACDisposable *subScription;//一次性的可释放的预订者对象

@end

@implementation FRPCell

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor darkGrayColor];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.contentView addSubview:imageView];
        
        self.imageView = imageView;
        
        //使用KVO监听photoModel的thumbnailData来绑定imageView的image
        RAC(self.imageView, image) = [[RACObserve(self, photoModel.thumbnailData) ignore:nil] map:^id(NSData *value) {
            return [UIImage imageWithData:value];
        }];
        
        
    }
    
    return self;
}


/*
- (void)setPhotoModel:(FRPPhotoModel *)photoModel
{
    
    RACSignal *validSignal = [RACObserve(photoModel, thumbnailData) filter:^BOOL(NSData *value) {
        return (value != nil);
    }];//监听photoModel的thumbnailData属性，有值才返回
    
    
    RACSignal *imageSignal = [validSignal map:^id(NSData *value) {
        return [UIImage imageWithData:value];
    }];//将data转换为image
    
    self.subScription = [imageSignal setKeyPath:@keypath(self.imageView, image) onObject:self.imageView];//self.imageView = image，以后会用RAC进行绑定替换（这种用keyPath的绑定方式不太常用，RACDisaposable对象会在onObject的对象被释放后自动释放）
    
//    RAC(self.imageView, image)
}

#pragma mark - 需要重用cell前调用
- (void)prepareForReuse
{
    [super prepareForReuse];
    
    //在重用前，手动将DACDisaposable释放掉，以备下次调用setPhotoModel方法时重新赋值
    [self.subScription dispose];
    self.subScription = nil;
}
 */

@end
