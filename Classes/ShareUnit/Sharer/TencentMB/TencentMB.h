//
//  TencentConnect.h
//  TwitterConnect
//
//  Created by kinglong on 10/11/30.
//  Copyright 2010 wondershare. All rights reserved.
//

#import "TencentMBConnect.h"

#define VERIFY_URL @"https://open.t.qq.com/cgi-bin/authorize?oauth_token="

@interface TencentMB : Sharer <LoginDialogDelegate> {
	OAToken				* accessToken_;
	OAToken				* requestToken_;
	NSURLConnection		* connection_;
	NSMutableData		* responseData_;
}

@property (nonatomic, retain)NSMutableData *responseData;

- (void)storeTencentMBToken:(OAToken *)access_token;

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
