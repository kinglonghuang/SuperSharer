//
//  SohuConnection.h
//  SuperShare
//
//  Created by WS12316 on 4/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "SohuConnect.h"

@interface SohuConnection : Sharer
{
	OAToken				* accessToken_;
	OAToken				* requestToken_;
	NSURLConnection		* connection_;
	NSMutableData		* receivedData_;
	NSInteger			statusCode_;
}

- (void)get:(NSString*)URL;

- (void) publishStatus:(NSString *)status;

- (void) publishLink:(NSString *)linkStr;

- (void) uploadImage:(UIImage *)image withDescription:(NSString *)description;

- (void) cancelSharing;

@end
