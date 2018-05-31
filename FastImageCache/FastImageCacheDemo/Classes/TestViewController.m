//
//  TestViewController.m
//  FastImageCacheDemo
//
//  Created by chengshun on 2018/5/31.
//  Copyright © 2018年 Path. All rights reserved.
//

#import "TestViewController.h"
#import "FICImageCache.h"
#import "FICDPhoto.h"
#import "FICImageFormat.h"

@interface TestViewController ()
{
    NSArray *_photos;
    UIImageView *_imgView;
}

@property (nonatomic, strong) FICImageCache *imageCache;

@end

@implementation TestViewController

- (id)init {
    self = [super init];
    
    if (self != nil) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSArray *imageURLs = [mainBundle URLsForResourcesWithExtension:@"jpg" subdirectory:@"Demo Images"];
        
        if ([imageURLs count] > 0) {
            NSMutableArray <FICDPhoto *> *photos = [[NSMutableArray alloc] init];
            for (NSURL *imageURL in imageURLs) {
                FICDPhoto *photo = [[FICDPhoto alloc] init];
                [photo setSourceImageURL:imageURL];
                [photos addObject:photo];
            }
            
            photos[3].imageSize = CGSizeMake(100, 200);
            photos[4].imageSize = CGSizeMake(150, 300);
            
            while ([photos count] < 5000) {
                [photos addObjectsFromArray:photos]; // Create lots of photos to scroll through
            }
            
            _photos = photos;
        }
        
        _imageCache = [[FICImageCache alloc] initWithNameSpace:@"123312"];
        _imageCache.delegate = self;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _imgView = [[UIImageView alloc] init];
    [self.view addSubview:_imgView];
    
    // Square image formats...
    NSInteger squareImageFormatMaximumCount = 400;
    FICImageFormatDevices squareImageFormatDevices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
    
    // ...32-bit BGR
    FICImageFormat *squareImageFormat32BitBGRA = [FICImageFormat formatWithName:@"test_format"
                                                                         family:FICDPhotoImageFormatFamily
                                                                      imageSize:CGSizeMake(3000, 3000)
                                                                          style:FICImageFormatStyle32BitBGRA
                                                                   maximumCount:squareImageFormatMaximumCount
                                                                        devices:squareImageFormatDevices
                                                                 protectionMode:FICImageFormatProtectionModeNone];
    [_imageCache setFormats:@[squareImageFormat32BitBGRA]];
    
    [self test:_photos[3] andBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self test:_photos[4] andBlock:^{
            }];
        });
    }];
}

- (void)test:(FICDPhoto *)photo andBlock:(void(^)())block
{
    [_imageCache retrieveImageForEntity:photo
                         withFormatName:@"test_format"
                        completionBlock:^(id<FICEntity>  _Nullable entity,
                                          NSString * _Nonnull formatName,
                                          UIImage * _Nullable image) {
                            _imgView.image = image;
                            _imgView.frame = CGRectMake(100, 100, image.size.width, image.size.height);
                            block();
                        }];
}


- (void)imageCache:(FICImageCache *)imageCache wantsSourceImageForEntity:(id<FICEntity>)entity withFormatName:(NSString *)formatName completionBlock:(FICImageRequestCompletionBlock)completionBlock {
    // Images typically come from the Internet rather than from the app bundle directly, so this would be the place to fire off a network request to download the image.
    // For the purposes of this demo app, we'll just access images stored locally on disk.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *sourceImage = [(FICDPhoto *)entity sourceImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(sourceImage);
        });
    });
}

- (BOOL)imageCache:(FICImageCache *)imageCache shouldProcessAllFormatsInFamily:(NSString *)formatFamily forEntity:(id<FICEntity>)entity {
    return NO;
}

- (void)imageCache:(FICImageCache *)imageCache errorDidOccurWithMessage:(NSString *)errorMessage {
    NSLog(@"%@", errorMessage);
}

@end
