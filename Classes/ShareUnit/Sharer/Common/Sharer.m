//
//  Sharer.m
//  SuperShare
//
//  Created by WS12316 on 4/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Sharer.h"


@implementation Sharer

@synthesize delegate = delegate_,
			loginDelegate = loginDelegate_;

#pragma mark Interface

- (BOOL) isUserLogged
{
	return NO;
}


- (void) login
{
	//subClass implement
}


- (void) logout
{
	//subClass implement
}


- (BOOL) canShareStatus
{
	return YES;
}


- (BOOL) canShareLink
{
	return YES;
}
- (BOOL) canShareImage
{
	return YES;
}


- (BOOL) canShareVideo
{
	return YES;
}


- (void) shareStatus:(NSString *)status
{
	//subClass implement
}


- (void) shareLink:(NSString *)linkStr
{
	//subClass implement
}


- (void) shareImage:(UIImage *)image withDescription:(NSString *)description
{
	//subClass implement
}


- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description
{
	//subClass implement
}


- (void) cancelShare
{
	//subClass implement
}


- (NSInteger) maxStatusLength
{
	return 140;
}


- (NSString *) itemName
{
	return @"ShareItem";
}

- (void) dealloc
{
	[loginDialog_ release];
	[super dealloc];
}

@end
