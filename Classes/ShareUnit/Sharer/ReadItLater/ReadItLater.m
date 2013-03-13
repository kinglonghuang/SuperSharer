//
//  ReadItLater.m
//  SuperShare
//
//  Created by WS12316 on 4/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ReadItLater.h"

@interface ReadItLater (Private)

- (void) storeUserInfoInUserDefault;

- (void)loginWithUserInfo:(NSDictionary *)userInfoDic;

@end


@implementation ReadItLater

- (id) init
{
	if (self = [super init]) {
		readItLater_ = [[ReadItLaterEngine alloc] init];
	}
	return self;
}


- (void) dealloc
{
	[readItLater_ release];readItLater_ = nil;
	[userName_ release];[pwd_ release];
	userName_ = pwd_ = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark Private

- (void) storeUserInfoInUserDefault
{
	[[NSUserDefaults standardUserDefaults] setObject:userName_ forKey:RIL_StoredUserName];
	[[NSUserDefaults standardUserDefaults] setObject:pwd_ forKey:RIL_StoredPwd];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)loginWithUserInfo:(NSDictionary *)userInfoDic
{
	NSString * encryptUserName = [DES_Base64Helper tripleDES:[userInfoDic objectForKey:@"userName"] encryptOrDecrypt:kCCEncrypt key:RIL_EncryptKey];
	NSString * encryptPwd = [DES_Base64Helper tripleDES:[userInfoDic objectForKey:@"pwd"] encryptOrDecrypt:kCCEncrypt key:RIL_EncryptKey];
	if (encryptUserName && encryptPwd) {
		userName_ = [encryptUserName copy];
		pwd_ = [encryptPwd copy];
	}
	[readItLater_ authWithUsername:[userInfoDic objectForKey:@"userName"] password:[userInfoDic objectForKey:@"pwd"] delegate:self];
}

#pragma mark -
#pragma mark Interface

- (BOOL) isUserLogged
{
	if ([[NSUserDefaults standardUserDefaults] objectForKey:RIL_StoredUserName] && [[NSUserDefaults standardUserDefaults] objectForKey:RIL_StoredPwd]) {
		return YES;
	}
	else {
		return NO;
	}
}


- (void) login
{
	loginDialog_ = [[LoginDialog alloc] initWithURLStr:nil params:nil delegate:self];
	[loginDialog_ setNeedWebView:NO];
	[loginDialog_ setConnectTitle:@"ReadItLater Login"];
	[loginDialog_ setIconImg:[UIImage imageNamed:@"LoginDialog.bundle/icons/readitlater.png"]];
	[loginDialog_ setLoginViewBgImage:[UIImage imageNamed:@"LoginDialog.bundle/icons/readitlaterLoginBgImage.png"]];
	[loginDialog_ show];
}


- (void) logout
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:RIL_StoredUserName];
	[defaults removeObjectForKey:RIL_StoredPwd];
	[defaults synchronize];
	
	[delegate_ shareItemLogoutSucceed:self];
}


- (BOOL) canShareStatus
{
	return NO;
}


- (BOOL) canShareLink
{
	return YES;
}


- (BOOL) canShareImage
{
	return NO;
}


- (BOOL) canShareVideo
{
	return NO;
}


- (void) shareStatus:(NSString *)status
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"ReadItLaterErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) shareLink:(NSString *)linkStr
{
	NSURL * url = [NSURL URLWithString:linkStr];
	[readItLater_ save:url title:nil delegate:self];
}


- (void) shareImage:(UIImage *)image withDescription:(NSString *)description
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"ReadItLaterErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"ReadItLaterErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) cancelShare
{
	[readItLater_ cancelUpload];
}


- (NSInteger) maxStatusLength
{
	return -1;
}


- (NSString *) itemName
{
	return @"ReadItLater";
}

#pragma mark -
#pragma mark ReadItLaterDelegate

- (void) readItLaterLoginFinished:(NSString *)stringResponse error:(NSError *)error
{
	if (!error) {
		[loginDialog_ authrizeFeedbackStatus:YES error:nil]; //finished ,close the loginDialog
		[self storeUserInfoInUserDefault];
		[loginDelegate_ itemLoginSucceed:self];//ask the delegate whether should upload after login
	}else {
		[userName_ release];[pwd_ release];
		userName_ = pwd_ = nil;
		[loginDialog_ authrizeFeedbackStatus:NO error:error]; //not finished ,feedback the error description
		[delegate_ shareItem:self loginFailed:error];
	}
}


- (void) readItLaterSignupFinished:(NSString *)stringResponse error:(NSError *)error
{
	
}


- (void) readItLaterSaveFinished:(NSString *)stringResponse error:(NSError *)error
{
	if (!error) {
		[delegate_ shareItemShareSucceed:self];
	}else {
		[delegate_ shareItem:self shareFailed:error];
	}
}


- (void) readItLaterShareCancelled
{
	[delegate_ shareItemShareCancelled:self];
}

#pragma mark -
#pragma mark LoginDialogDelegate
/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url
{
	[delegate_ shareItemLoginCancelled:self];
}


- (void)dialog:(LoginDialog*)dialog loginWithUserName:(NSString*)userName andPwd:(NSString*)pwd
{
	NSDictionary * userInfoDic = [NSDictionary dictionaryWithObjectsAndKeys:userName,@"userName",pwd,@"pwd",nil];
	[self performSelector:@selector(loginWithUserInfo:) withObject:userInfoDic afterDelay:0.0];
}


- (void)dialogCancelBtnClicked;
{
	[delegate_ shareItemLoginCancelled:self];
}


- (BOOL)dialog:(LoginDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url
{
	return NO;
}


- (BOOL)dialogShouldClose
{
	return YES;
}


- (BOOL)dialogShouldLoadLinkURL:(NSURL *)url
{
	return YES;
}

@end
