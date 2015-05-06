//
//  FRPPhotoImporter.m
//  FunctionReactivePixels
//
//  Created by mac on 15/5/5.
//  Copyright (c) 2015年 jiji. All rights reserved.
//

#import "FRPPhotoImporter.h"
#import "FRPPhotoModel.h"

@implementation FRPPhotoImporter

#pragma mark - 基本数据请求解析生成
+ (RACSignal *)importPhotos
{
    //创建对象（是RACSignal的子类，可以作为异步对象返回）
    RACReplaySubject *subject = [RACReplaySubject new];
    
    //发送异步请求并解析处理数据
    NSURLRequest *request = [self popularURLRequest];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (data)
        {
            id results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            RACSequence *resultsSequence = [results[@"photos"] rac_sequence];//将结果解析转换成sequence（RACStream的子类），给sequence即可用RAC进行操作
            
            
            //使用map，遍历sequence内的每个对象（这里是字典对象），生成包含photoModel对象的新sequence
            RACSequence *photoModelSequence = [resultsSequence map:^id(NSDictionary *photoDictionary) {
                
                //用每个字典来转换成photoModel对象
                FRPPhotoModel *model = [FRPPhotoModel new];
                
                
                [self configPhotoModel:model withDictionary:photoDictionary];
                [self downloadThumbnailForPhotoModel:model];
                
                
                return model;
            }];
            
            //转换为OC数组
            NSArray *photoModelArray = [photoModelSequence array];
            
            //作为完成后的对象，发送给订阅者
            [subject sendNext:photoModelArray];
            
            //告知订阅者，此流完成
            [subject sendCompleted];
        }
        else
        {
            //发送错误消息
            [subject sendError:connectionError];
        }
        
        
    }];
    
    //异步返回对象
    return subject;
}

+ (NSURLRequest *)popularURLRequest
{
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    NSURLRequest *request = [delegate.apiHelper urlRequestForPhotoFeature:PXAPIHelperPhotoFeaturePopular resultsPerPage:100 page:0 photoSizes:PXPhotoModelSizeThumbnail sortOrder:PXAPIHelperSortOrderRating except:PXPhotoModelCategoryNude];
    
    return request;
}

+ (void)configPhotoModel:(FRPPhotoModel *)photoModel withDictionary:(NSDictionary *)dictionary
{
    photoModel.photoName = dictionary[@"name"];
    photoModel.identifier = dictionary[@"id"];
    photoModel.photographerName = (dictionary[@"user"])[@"username"];
    photoModel.rating = dictionary[@"rating"];
    photoModel.thumbnailURL = [self urlFirImageSize:3 inDictionary:dictionary[@"images"]];
    
    if (dictionary[@"comments_count"])
    {
        photoModel.fullsizedURL = [self urlFirImageSize:4 inDictionary:dictionary[@"images"]];
    }
}

+ (void)downloadThumbnailForPhotoModel:(FRPPhotoModel *)photoModel
{
    NSAssert(photoModel.thumbnailURL, @"Thumb URL must not be nil");
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:photoModel.thumbnailURL]];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        photoModel.thumbnailData = data;
        
    }];
}

+ (NSString *)urlFirImageSize:(NSInteger)size inDictionary:(NSArray *)array
{
    RACSequence *validSequence = [[array rac_sequence] filter:^BOOL(NSDictionary *value) {
        
        return ([value[@"size"] integerValue] == size);
    }];//过滤，得到指定size组成的字典数组
    
    RACSequence *validUrlSequence = [validSequence map:^id(NSDictionary *value) {
        return value[@"url"];
    }];//将其中每个字典的url组成数组返回
    
    return [[validUrlSequence array] firstObject];//调用firstObject可以防止空数组访问越界
}


#pragma mark - 图片详情数据请求

+ (NSURLRequest *)photoURLRequest:(FRPPhotoModel *)photoModel
{
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    
    return [delegate.apiHelper urlRequestForPhotoID:photoModel.identifier.integerValue];
}

+ (RACReplaySubject *)fetchPhotoDetails:(FRPPhotoModel *)photoModel
{
    RACReplaySubject *subject = [RACReplaySubject subject];
    
    NSURLRequest *request = [self photoURLRequest:photoModel];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (data)
        {
            id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            NSDictionary *photoDataDic = result[@"photo"];
            
            [self configPhotoModel:photoModel withDictionary:photoDataDic];
            
            //下载缩略图和完整图数据
            [self downloadThumbnailForPhotoModel:photoModel];
            [self downloadFullsizedImageForPhotoModel:photoModel];
            
            [subject sendNext:photoModel];
            
            [subject sendCompleted];
        }
        else
        {
            [subject sendError:connectionError];
        }
        
    }];
    
    return subject;
}

+ (void)download:(NSString *)urlString withCompletion:(void (^)(NSData *data))completion
{
    NSAssert(urlString, @"URL must not be nil!");
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (completion)
        {
            completion(data);
        }
        
    }];
}


+ (void)downloadFullsizedImageForPhotoModel:(FRPPhotoModel *)photoModel
{
    [self download:photoModel.fullsizedURL withCompletion:^(NSData *data) {
        photoModel.fullsizedData = data;
    }];
}

+ (void)downloadThumbnailImageForPhotoModel:(FRPPhotoModel *)photoModel
{
    [self download:photoModel.thumbnailURL withCompletion:^(NSData *data) {
        photoModel.thumbnailData = data;
    }];
}
@end
