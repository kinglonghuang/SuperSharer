//
//  Flickr.h
//  SnapAndRun
//
//  Created by kinglong on 11-2-28.
//  Copyright 2011 wondershare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlickrConnect.h"


@interface Flickr : Sharer <OFFlickrAPIRequestDelegate,LoginDialogDelegate>{
	OFFlickrAPIContext		* flickrContext_;
	OFFlickrAPIRequest		* flickrRequest_;
	NSString				* descriptionMsg_;
}

@property (nonatomic, readonly) OFFlickrAPIContext * flickrContext;

- (void)setAndStoreFlickrAuthToken:(NSString *) inAuthToken;

#pragma mark Interface

- (BOOL) isUserLogged;

- (void) login;

- (void) logout;

- (BOOL) canShareStatus;

- (BOOL) canShareLink;

- (BOOL) canShareImage;

- (BOOL) canShareVideo;

- (void) shareStatus:(NSString *)status;

- (void) shareLink:(NSString *)linkStr;

- (void) shareImage:(UIImage *)image withDescription:(NSString *)description;

- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description;

- (void) cancelShare;

- (NSInteger) maxStatusLength;

- (NSString *) itemName;

@end
