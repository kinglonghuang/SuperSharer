//
//  TwitterConnect.h
//  TwitterConnect
//
//  Created by kinglong on 10/11/30.
//  Copyright 2010 wondershare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterConnect.h"

@interface Twitter: Sharer <LoginDialogDelegate> {
	OAToken				* accessToken_;
	OAToken				* requestToken_;
	GSTwitPicEngine		* twitterEngine_;
}

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
