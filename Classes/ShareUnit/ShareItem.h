//
//  SNSBase.h
//  ShareTest
//
//  Created by kinglong on 11-3-30.
//  Copyright 2011 Wondershare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sharer.h"

@interface ShareItem : NSObject <LoginDelegate> {
	Sharer			* shareInstance_;
	NSInvocation	* shareInvocation_;
}

#pragma mark Interface

- (id) initForItem:(NSString *)sharerID delegate:(id)delegate;

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
