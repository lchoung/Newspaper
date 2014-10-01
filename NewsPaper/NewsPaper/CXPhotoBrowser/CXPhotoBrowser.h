//
//  CXPhotoBrowser.h
//  CXPhotoBrowserDemo
//
//  Created by ChrisXu on 13/4/19.
//  Copyright (c) 2013年 ChrisXu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CXPhoto.h"
#import "CXPhotoProtocol.h"
#import "CXPhotoLoadingView.h"


@protocol CXPhotoBrowserDataSource;
@protocol CXPhotoBrowserDelegate;
@interface CXPhotoBrowser : UIViewController
<UIScrollViewDelegate>
{
}
//@property (nonatomic, assign) id<CXPhotoBrowserDataSource> dataSource;
//@property (nonatomic, assign) id<CXPhotoBrowserDelegate> delegate;
@property (nonatomic, readonly) NSUInteger photoCount;
@property (nonatomic, readonly) NSUInteger currentPageIndex;
@property (nonatomic, readonly) id<CXPhotoBrowserDelegate> delegate;
- (id)initWithDataSource:(id <CXPhotoBrowserDataSource>)dataSource  delegate:(id <CXPhotoBrowserDelegate>)delegate;

// Reloads the photo browser and refetches data
- (void)reloadData;

// Set page that photo browser starts on
- (void)setInitialPageIndex:(NSUInteger)index;


//Reload
@end

@protocol CXPhotoBrowserDataSource <NSObject>
@required

/**
 @param photoBrower The current photobrowser to present.
 
 @return number of photos.
 */
- (NSUInteger)numberOfPhotosInPhotoBrowser:(CXPhotoBrowser *)photoBrowser;

/**
 @param photoBrower The current photobrowser to present.
 @param index 
 
 @return CXPhoto for showing.
 */
- (id <CXPhotoProtocol>)photoBrowser:(CXPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;
@end

@protocol CXPhotoBrowserDelegate <NSObject>

@optional

/**
 *  called when currentIndex will change
 *
 *  @param photoBrowser The current photobrowser to present.
 *  @param index        The current showing index in photoBrowser.
 */
- (void)photoBrowser:(CXPhotoBrowser *)photoBrowser didChangedToPageAtIndex:(NSUInteger)index;

/**
 *  called when the current image is finished loading.
 *
 *  @param photoBrowser The current photobrowser to present.
 *  @param currentImage currentImage
 */
- (void)photoBrowser:(CXPhotoBrowser *)photoBrowser didFinishLoadingWithCurrentImage:(UIImage *)currentImage;

/**
 *  called to check if support reload.
 *
 *  @return supportReload
 */
- (BOOL)supportReload;
@end