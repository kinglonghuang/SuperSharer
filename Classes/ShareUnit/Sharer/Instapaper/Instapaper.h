//
//  Instapaper.h
//  SuperShare
//
//  Created by WS12316 on 4/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InstapaperConnect.h"

@interface Instapaper : Sharer <LoginDialogDelegate> {
	OAToken		* accessToken_;
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
