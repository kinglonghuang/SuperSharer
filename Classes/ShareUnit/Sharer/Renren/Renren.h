//
//  Renren.h
//  tabDemo
//
//  Created by kinglong on 11-3-25.
//  Copyright 2011 Wondershare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RenrenConnect.h"

#define LOGIN_URL	@"https://graph.renren.com/oauth/authorize"

@interface Renren : Sharer <SessionDelegate,LoginDialogDelegate,RequestDelegate> {
	Session			* session_;
	BOOL			isAuthorizationStep;
	Request			* request_;
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
