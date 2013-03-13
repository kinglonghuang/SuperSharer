//
//  SNSBase.m
//  ShareTest
//
//  Created by kinglong on 11-3-30.
//  Copyright 2011 Wondershare. All rights reserved.
//

#import "ShareItem.h"

#ifdef	FacebookID
#import "Facebook.h"
#endif
#ifdef	TwitterID
#import "Twitter.h"
#endif
#ifdef	FlickrID
#import "Flickr.h"
#endif
#ifdef	SinaMBID
#import "SinaMB.h"
#endif
#ifdef	TencentMBID
#import "TencentMB.h"
#endif
#ifdef	SohuMBID
#import "SohuMB.h"
#endif
#ifdef	RenRenID
#import "Renren.h"
#endif
#ifdef	ReadItLaterID
#import "ReadItLater.h"
#endif
#ifdef	InstapaperID
#import "Instapaper.h"
#endif


@interface ShareItem(Private)

- (void) initShareInstance:(NSString *)snsID delegate:(id)delegate;

@end


@implementation ShareItem

- (void)dealloc
{
	[shareInvocation_ release];shareInvocation_ = nil;
	[shareInstance_ release];shareInstance_ = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Interface

- (id) initForItem:(NSString *)snsID delegate:(id)delegate;
{
	if(self = [super init])
	{
		shareInstance_ = nil;
		shareInvocation_ = nil;
		[self initShareInstance:snsID delegate:delegate];
	}
	return self;
}


- (BOOL) isUserLogged
{
	return [shareInstance_ isUserLogged];
}


- (void) login
{
	if ([self isUserLogged]) {
		return;
	}else {
		[shareInstance_ login];
	}
}


- (void) logout
{
	[shareInstance_ logout];
}


- (BOOL) canShareVideo
{
	return [shareInstance_ canShareVideo];
}


- (BOOL) canShareImage
{
	return [shareInstance_ canShareImage];
}


- (BOOL) canShareStatus
{
	return [shareInstance_ canShareStatus];
}


- (BOOL) canShareLink
{
	return [shareInstance_ canShareLink];
}


- (void) shareStatus:(NSString *)status
{
	if ([self canShareStatus]) {
		if ([self isUserLogged]) {
			[shareInstance_ shareStatus:status];
		}else {		
			//we save the invocation ,after user login,we invoke it;
			SEL selector = @selector(shareStatus:);
			NSMethodSignature * sig = [self methodSignatureForSelector:selector];
			shareInvocation_ = [NSInvocation invocationWithMethodSignature:sig];
			[shareInvocation_ setSelector:selector];
			[shareInvocation_ setTarget:self];
			[shareInvocation_ setArgument:&status atIndex:2];
			[shareInvocation_ retain];
			
			[self login];
		}
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
		NSString * errorDomain  = [NSString stringWithFormat:@"%@ErrDomainDomain",[shareInstance_ itemName]];
		NSError * error = [NSError errorWithDomain:errorDomain code:dataTypeNotSupportedError userInfo:errorData];
		[[shareInstance_ delegate] shareItem:self shareFailed:error];
	}
}


- (void) shareLink:(NSString *)linkStr
{
	if ([self canShareLink]) {
		if ([self isUserLogged]) {
			[shareInstance_ shareLink:linkStr];
		}else {
			//we save the invocation ,after user login,we invoke it;
			SEL selector = @selector(shareLink:);
			NSMethodSignature *sig = [self methodSignatureForSelector:selector];
			shareInvocation_ = [NSInvocation invocationWithMethodSignature:sig];
			[shareInvocation_ setSelector:selector];
			[shareInvocation_ setTarget:self];
			[shareInvocation_ setArgument:&linkStr atIndex:2];
			[shareInvocation_ retain];
			
			[self login];
		}
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
		NSString * errorDomain  = [NSString stringWithFormat:@"%@ErrDomainDomain",[shareInstance_ itemName]];
		NSError * error = [NSError errorWithDomain:errorDomain code:dataTypeNotSupportedError userInfo:errorData];
		[[shareInstance_ delegate] shareItem:self shareFailed:error];
	}
}


- (void) shareImage:(UIImage *)image withDescription:(NSString *)description
{
	if ([self canShareImage]) {
		if ([self isUserLogged]) {
			[shareInstance_ shareImage:image withDescription:description];
		}else {
			//we save the invocation ,after user login,we invoke it;
			SEL selector = @selector(shareImage:withDescription:);
			NSMethodSignature *sig = [self methodSignatureForSelector:selector];
			shareInvocation_ = [NSInvocation invocationWithMethodSignature:sig];
			[shareInvocation_ setSelector:selector];
			[shareInvocation_ setTarget:self];
			[shareInvocation_ setArgument:&image atIndex:2];
			[shareInvocation_ setArgument:&description atIndex:3];
			[shareInvocation_ retain];
			
			[self login];
			
		}
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
		NSString * errorDomain  = [NSString stringWithFormat:@"%@ErrDomainDomain",[shareInstance_ itemName]];
		NSError * error = [NSError errorWithDomain:errorDomain code:dataTypeNotSupportedError userInfo:errorData];
		[[shareInstance_ delegate] shareItem:self shareFailed:error];
	}
}


- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description
{
	if ([self canShareVideo]) {
		if ([self isUserLogged]) {
			[shareInstance_ shareVideo:videoData withDescription:description];
		}else {
			//we save the invocation ,after user login,we invoke it;
			SEL selector = @selector(shareVideo:withDescription:);
			NSMethodSignature *sig = [self methodSignatureForSelector:selector];
			shareInvocation_ = [NSInvocation invocationWithMethodSignature:sig];
			[shareInvocation_ setSelector:selector];
			[shareInvocation_ setTarget:self];
			[shareInvocation_ setArgument:&videoData atIndex:2];
			[shareInvocation_ setArgument:&description atIndex:3];
			[shareInvocation_ retain];
			
			[self login];
		}
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
		NSString * errorDomain  = [NSString stringWithFormat:@"%@ErrDomainDomain",[shareInstance_ itemName]];
		NSError * error = [NSError errorWithDomain:errorDomain code:dataTypeNotSupportedError userInfo:errorData];
		[[shareInstance_ delegate] shareItem:self shareFailed:error];
	}
}


- (void) cancelShare
{
	[shareInstance_ cancelShare];
}


- (NSInteger) maxStatusLength
{
	return [shareInstance_ maxStatusLength];
}


- (NSString *) itemName
{
	return [shareInstance_ itemName];
}


#pragma mark -
#pragma mark Private Method

- (void) initShareInstance:(NSString *)sharerID delegate:(id)delegate
{

#ifdef FacebookID
	if ([sharerID isEqualToString:FacebookID]) {
		
		shareInstance_ = [[Facebook alloc] initWithAppId:FACEBOOK_APP_ID];
	}
#endif
	
#ifdef TwitterID
	if ([sharerID isEqualToString:TwitterID]) {
		shareInstance_ = [[Twitter alloc] init];
	}
#endif
	
#ifdef FlickrID	
	if ([sharerID isEqualToString:FlickrID]) {
		shareInstance_ = [[Flickr alloc] init];
	} 
#endif
	
#ifdef SinaMBID			
	if ([sharerID isEqualToString:SinaMBID]) {
		shareInstance_ = [[SinaMB alloc] init];
	}
#endif
	
#ifdef TencentMBID
	if ([sharerID isEqualToString:TencentMBID]) {
		shareInstance_ = [[TencentMB alloc] init];
	}
#endif
	
#ifdef RenRenID
	if ([sharerID isEqualToString:RenRenID]) {
		shareInstance_ = [[Renren alloc] init];
	} 
#endif
	
#ifdef SohuMBID
	if ([sharerID isEqualToString:SohuMBID]) {
		shareInstance_ = [[SohuMB alloc] init];
	}
#endif
	
#ifdef ReadItLaterID
	if ([sharerID isEqualToString:ReadItLaterID]) {
		shareInstance_ = [[ReadItLater alloc] init];
	}
#endif
	
#ifdef InstapaperID
	if ([sharerID isEqualToString:InstapaperID]) {
		shareInstance_ = [[Instapaper alloc] init];
	}
#endif
	
	[shareInstance_ setDelegate:delegate];
	[shareInstance_ setLoginDelegate:self];
}

- (void) itemLoginSucceed:(id)item
{
	if (shareInvocation_) {
		[shareInvocation_ invoke];
	}else {
		[[shareInstance_ delegate] shareItemLoginSucceed:item];
	}
}

@end
