//
//  FRPFullsizeViewController.m
//  FunctionReactivePixels
//
//  Created by mac on 15/5/6.
//  Copyright (c) 2015年 jiji. All rights reserved.
//

#import "FRPFullsizeViewController.h"
#import "FRPPhotoModel.h"
#import "FRPPhotoViewController.h"//元素视图控制器

@interface FRPFullsizeViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, strong) NSArray *photoModelArray;

@property (nonatomic, strong) UIPageViewController *pageViewController;

/**
 *  根据索引得到指定的PhotoViewController元素对象
 *
 *  @param index 索引
 *
 *  @return PhotoViewController对象
 */
- (FRPPhotoViewController *)photoViewControllerForIndex:(NSInteger)index;

@end

@implementation FRPFullsizeViewController

- (instancetype)initWIthPhotoModels:(NSArray *)photoModelArray currentPhotoIndex:(NSInteger)photoIndex
{
    if (self = [super init])
    {
        self.photoModelArray = photoModelArray;
        
        FRPPhotoModel *currentPhotoModel = self.photoModelArray[photoIndex];
        self.title = currentPhotoModel.photoName;
        
        self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:@{UIPageViewControllerOptionInterPageSpacingKey: @30}];//配置为：每页之间的间距
        
        self.pageViewController.delegate = self;
        self.pageViewController.dataSource = self;
        
        
        //设置显示处于当前位置的PhotoViewController
        FRPPhotoViewController *currentPhotoVC = [self photoViewControllerForIndex:photoIndex];
        [self.pageViewController setViewControllers:@[currentPhotoVC] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.pageViewController.view.frame = self.view.bounds;
    [self.view addSubview:self.pageViewController.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - photoViewController对象生成
- (FRPPhotoViewController *)photoViewControllerForIndex:(NSInteger)index
{
    //index为photoModel数据源范围内，则创建对应的viewController元素
    if ((index >= 0) && index < (self.photoModelArray.count))
    {
        FRPPhotoModel *photoModel = self.photoModelArray[index];
        
        FRPPhotoViewController *vc = [[FRPPhotoViewController alloc] initWithPhotoModel:photoModel index:index];
        
        return vc;
    }
    
    return nil;
}

#pragma mark - UIPageViewController delegate
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    //使用当前的子元素对应的photoModel的photoName更新标题
    FRPPhotoViewController *currentPhotoVC = [pageViewController.viewControllers firstObject];
    self.title = currentPhotoVC.photoModel.photoName;
    
    
    //控制主页列表定位到此位置
    if (self.delegate && [self.delegate respondsToSelector:@selector(userDidScroll:toPhotoAtIndex:)])
    {
        [self.delegate userDidScroll:self toPhotoAtIndex:currentPhotoVC.photoIndex];//photoIndex为list、self和photoVC共同拥有的属性
    }
}

//以下两个方法为实时创建photoVC元素

//前一个viewController
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    FRPPhotoViewController *currentPhotoVC = (FRPPhotoViewController *)viewController;
    
    //返回前一个index的photoViewController
    return [self photoViewControllerForIndex:(currentPhotoVC.photoIndex - 1)];
}

//后一个viewController
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    FRPPhotoViewController *currentPhotoVC = (FRPPhotoViewController *)viewController;

    //返回后一个index的photoViewController
    return [self photoViewControllerForIndex:(currentPhotoVC.photoIndex + 1)];
}





//- (NSArray *)photoViewController

@end
