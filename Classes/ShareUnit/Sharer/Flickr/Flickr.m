//
//  Flickr.m
//  SnapAndRun
//
//  Created by kinglong on 11-2-28.
//  Copyright 2011 wondershare. All rights reserved.
//

#import "Flickr.h"

NSString *getAuthTokenStep = @"klGetAuthTokenStep";
NSString *checkTokenStep = @"klCheckTokenStep";
NSString *kUploadImageStep = @"kUploadImageStep";
NSString *kSetImagePropertiesStep = @"kSetImagePropertiesStep";

@interface Flickr(Private)

- (void)uploadImage:(NSDictionary*)dateDic;

- (void)uploadVideo:(NSDictionary*)dateDic;

@end

@implementation Flickr

@synthesize flickrContext = flickrContext_;

- (id)init
{
	if(self = [super init])
	{
		descriptionMsg_ = nil;
	}
	return self;
}


- (OFFlickrAPIRequest *)flickrRequest
{
	if (!flickrRequest_) {
		flickrRequest_ = [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
		flickrRequest_.delegate = self;		
	}
	
	return flickrRequest_;
}


- (OFFlickrAPIContext *)flickrContext
{
    if (!flickrContext_) {
        flickrContext_ = [[OFFlickrAPIContext alloc] initWithAPIKey:FLICKR_API_KEY sharedSecret:FLICKR_API_SECRET];
        
        NSString *authToken = [[NSUserDefaults standardUserDefaults] objectForKey:FLICKR_STORED_TOKEN_NAME];
        if (authToken) {
            flickrContext_.authToken = authToken;
        }
    }
    
    return flickrContext_;
}


- (BOOL)isSessionValid
{
	if ([self.flickrContext.authToken length]) {
		return YES ;
	}else {
		return NO;
	}
}


- (void)uploadImage:(NSDictionary*)dateDic
{
	UIImage *img = [dateDic objectForKey:@"image"];
	NSString *description = [dateDic objectForKey:@"description"];
	NSData *JPEGData = UIImageJPEGRepresentation(img, 1.0);
    self.flickrRequest.sessionInfo = kUploadImageStep;
	NSDictionary * argumentDic = [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"is_public",description,@"description",nil];
    [self.flickrRequest uploadImageStream:[NSInputStream inputStreamWithData:JPEGData] suggestedFilename:DEFAULT_PIC_NAME MIMEType:@"image/jpeg" arguments:argumentDic];
	[UIApplication sharedApplication].idleTimerDisabled = YES;
}


- (void)uploadVideo:(NSDictionary*)dateDic
{
	NSData * videoData = [dateDic objectForKey:@"videoData"];
	NSString *description = [dateDic objectForKey:@"description"];
    self.flickrRequest.sessionInfo = kUploadImageStep;
	NSDictionary * argumentDic = [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"is_public",description,@"description",nil];
    [self.flickrRequest uploadImageStream:[NSInputStream inputStreamWithData:videoData] suggestedFilename:DEFAULT_PIC_NAME MIMEType:@"image/jpeg" arguments:argumentDic];
	[UIApplication sharedApplication].idleTimerDisabled = YES;
}

#pragma mark -
#pragma mark Interface

- (BOOL) isUserLogged
{
	return [self isSessionValid];
}


- (void)login
{
	NSURL *loginURL = [self.flickrContext loginURLFromFrobDictionary:nil requestedPermission:OFFlickrWritePermission];
	NSString *loginUrlStr = [NSString stringWithFormat:@"%@",loginURL];
	
	loginDialog_ = [[LoginDialog alloc] initWithURLStr:loginUrlStr params:nil delegate:self];
	[loginDialog_ setNeedWebView:YES];
	[loginDialog_ setConnectTitle:@"Connect to Flickr"];
	[loginDialog_ setIconImg:[UIImage imageNamed:@"LoginDialog.bundle/icons/flickr.png"]];
	[loginDialog_ show];
}


- (void)logout
{
	NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray* facebookCookies = [cookies cookiesForURL:
								[NSURL URLWithString:@"http://www.flickr.com/"]];
	
	for (NSHTTPCookie* cookie in facebookCookies) {
		[cookies deleteCookie:cookie];
	}
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:FLICKR_STORED_TOKEN_NAME];
	[[NSUserDefaults standardUserDefaults] synchronize];
	self.flickrContext.authToken = nil ;
	[delegate_ shareItemLogoutSucceed:self];
}


- (BOOL) canShareStatus
{
	return NO;
}


- (BOOL) canShareLink
{
	return NO;
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
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"FlickrErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}

- (void) shareLink:(NSString *)linkStr
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"FlickrErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) shareImage:(UIImage *)image withDescription:(NSString *)description
{
	descriptionMsg_ = [description copy];
	[delegate_ shareItemShareBegin:self];
	NSDictionary * metaDic = [NSDictionary dictionaryWithObjectsAndKeys:image,@"image",descriptionMsg_,@"description",nil];
	[self performSelector:@selector(uploadImage:) withObject:metaDic afterDelay:0.0];
}


- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description;
{
	descriptionMsg_ = [description copy];
	[delegate_ shareItemShareBegin:self];
	NSDictionary * metaDic = [NSDictionary dictionaryWithObjectsAndKeys:videoData,@"videoData",descriptionMsg_,@"description",nil];
	[self performSelector:@selector(uploadVideo:) withObject:metaDic afterDelay:0.0];
}


- (void) cancelShare
{
	[self.flickrRequest cancel];
	[delegate_ shareItemShareCancelled:self];
}


- (NSInteger) maxStatusLength
{
	return -1;
}


- (NSString *) itemName
{
	return @"flickr";
}


#pragma mark -
#pragma mark LoginDialogDelegate
/**
 * Called when the dialog succeeds with a returning url.
 */
- (void)dialogCompleteWithUrl:(NSURL *)url
{
	NSString *frob = [[url query] substringFromIndex:9];
	[self flickrRequest].sessionInfo = getAuthTokenStep;
	[self.flickrRequest callAPIMethodWithGET:@"flickr.auth.getToken" arguments:[NSDictionary dictionaryWithObjectsAndKeys:frob, @"frob", nil]];
}

/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url
{
	[delegate_ shareItemLoginCancelled:self];
}

- (void)dialog:(LoginDialog*)dialog didFailWithError:(NSError *)error
{
	if ([loginDialog_ alpha]) {
		[delegate_ shareItem:self loginFailed:error];
	}
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

#pragma mark OFFlickrAPIRequest delegate methods
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
	if (inRequest.sessionInfo == getAuthTokenStep){
		[self setAndStoreFlickrAuthToken:[[inResponseDictionary valueForKeyPath:@"auth.token"] textContent]];
		[loginDelegate_ itemLoginSucceed:self];//ask the delegate whether should upload after login
	}else if (inRequest.sessionInfo == kUploadImageStep) {
		[delegate_ shareItem:self feedbackStatus:@"Setting Property"];
        NSString *photoID = [[inResponseDictionary valueForKeyPath:@"photoid"] textContent];
        self.flickrRequest.sessionInfo = kSetImagePropertiesStep;
        [self.flickrRequest callAPIMethodWithPOST:@"flickr.photos.setMeta" arguments:[NSDictionary dictionaryWithObjectsAndKeys:photoID, @"photo_id", DEFAULT_PIC_NAME, @"title", descriptionMsg_, @"description", nil]];        		        
	}else if (inRequest.sessionInfo == kSetImagePropertiesStep) {	
		[delegate_ shareItemShareSucceed:self];
		[UIApplication sharedApplication].idleTimerDisabled = NO;		
        
    }
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
	if (inRequest.sessionInfo == getAuthTokenStep)
	{
		[delegate_ shareItem:self loginFailed:inError];
		
	}else if (inRequest.sessionInfo == kUploadImageStep)
	{
		[delegate_ shareItem:self shareFailed:inError];
	}

}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest imageUploadSentBytes:(NSUInteger)inSentBytes totalBytes:(NSUInteger)inTotalBytes
{
	if (inSentBytes == inTotalBytes) {
		[delegate_ shareItem:self feedbackStatus:@"Waiting for Flickr..."];
	}
	else {
		NSString * status = [NSString stringWithFormat:@"%u/%u (KB)", inSentBytes / 1024, inTotalBytes / 1024];
		[delegate_ shareItem:self feedbackStatus:status];
	}
}

#pragma mark -
#pragma mark Helper
- (void)setAndStoreFlickrAuthToken:(NSString *)inAuthToken
{
	if (![inAuthToken length]) {
		return;
	}
	else {
		self.flickrContext.authToken = inAuthToken;
		[[NSUserDefaults standardUserDefaults] setObject:inAuthToken forKey:FLICKR_STORED_TOKEN_NAME];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}
/**
 * Called when the dialog is cancelled and is about to be dismissed.
 */
//- (void)dialogDidNotComplete:(LoginDialog *)dialog;

/**
 * Called when dialog failed to load due to an error.
 */
//- (void)dialog:(LoginDialog*)dialog didFailWithError:(NSError *)error;

//- (BOOL)dialog:(LoginDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url;

- (void)dealloc
{
	[descriptionMsg_ release];
	[self.flickrContext release];
	[self.flickrRequest release];
	[super dealloc];
}

@end
