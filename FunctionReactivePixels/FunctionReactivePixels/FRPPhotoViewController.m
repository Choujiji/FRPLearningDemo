//
//  FRPPhotoViewController.m
//  FunctionReactivePixels
//
//  Created by mac on 15/5/6.
//  Copyright (c) 2015年 jiji. All rights reserved.
//

#import "FRPPhotoViewController.h"

//model
#import "FRPPhotoModel.h"

//Utilities
#import "FRPPhotoImporter.h"
#import <SVProgressHUD.h>

@interface FRPPhotoViewController ()

@property (nonatomic, assign) NSInteger photoIndex;
@property (nonatomic, strong) FRPPhotoModel *photoModel;

@property (nonatomic, weak) UIImageView *imageView;//self.view会保留子视图，所以weak

@end

@implementation FRPPhotoViewController

- (instancetype)initWithPhotoModel:(FRPPhotoModel *)photoModel index:(NSInteger)photoIndex
{
    if (self = [super init])
    {
        self.photoIndex = photoIndex;
        self.photoModel = photoModel;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    
    RAC(imageView, image) = [RACObserve(self.photoModel, fullsizedData) map:^id(NSData *value) {
        
        return [UIImage imageWithData:value];
        
    }];//监听photoModel的fullSizedData，得到后setImage
    
    imageView.contentMode = UIViewContentModeScaleAspectFit;//平铺

    [self.view addSubview:imageView];
    
    self.imageView = imageView;
    
    
//    NSLog(@"didload -=- %@", selfr);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [SVProgressHUD show];
    
    //请求下载图片数据
    [[FRPPhotoImporter fetchPhotoDetails:self.photoModel] subscribeError:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"error"];
    } completed:^{
        
        [SVProgressHUD dismiss];
        
        //此时，对应的photoModel的fullsizedData就有了，这时候RAC绑定的ImageView会立即调用setImage来设置图片
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
