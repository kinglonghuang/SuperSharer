//
//  Sharer.h
//  SuperShare
//
//  Created by WS12316 on 4/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LoginDialog.h"
#import "KLProtocol.h"
#import "ShareConfig.h"


@interface Sharer : NSObject {
	id				delegate_;
	id				loginDelegate_;
	LoginDialog		* loginDialog_;
}

@property (nonatomic ,assign) id <ShareDelegate> delegate;

@property (nonatomic ,assign) id <LoginDelegate> loginDelegate;

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
