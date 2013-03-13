/*
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#import "LoginDialog.h"
#import "KLProtocol.h"
#import "ShareConfig.h"

#define WebViewTag		10

//static NSString* kDefaultTitle = @"Connect to Facebook";
static CGFloat kFacebookBlue[4] = {0.42578125, 0.515625, 0.703125, 1.0};
static CGFloat kBorderGray[4] = {0.3, 0.3, 0.3, 0.8};
static CGFloat kBorderBlack[4] = {0.3, 0.3, 0.3, 1};
static CGFloat kBorderBlue[4] = {0.23, 0.35, 0.6, 1.0};

static CGFloat kTransitionDuration = 0.3;

static CGFloat kTitleMarginX = 8;
static CGFloat kTitleMarginY = 4;
static CGFloat kPadding = 10;
static CGFloat kBorderWidth = 10;

///////////////////////////////////////////////////////////////////////////////////////////////////

//BOOL FBIsDeviceIPad() {
//#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
//  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//    return YES;
//  }
//#endif
//  return NO;
//}

@implementation LoginDialog

@synthesize delegate = _delegate,
params   = _params;

#pragma mark -
#pragma mark Private

- (BOOL)FBIsDeviceIPad{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return YES;
	}
#endif
	return NO;
}
- (void)addRoundedRectToPath:(CGContextRef)context rect:(CGRect)rect radius:(float)radius {
	CGContextBeginPath(context);
	CGContextSaveGState(context);
	
	if (radius == 0) {
		CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
		CGContextAddRect(context, rect);
	} else {
		rect = CGRectOffset(CGRectInset(rect, 0.5, 0.5), 0.5, 0.5);
		CGContextTranslateCTM(context, CGRectGetMinX(rect)-0.5, CGRectGetMinY(rect)-0.5);
		CGContextScaleCTM(context, radius, radius);
		float fw = CGRectGetWidth(rect) / radius;
		float fh = CGRectGetHeight(rect) / radius;
		
		CGContextMoveToPoint(context, fw, fh/2);
		CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
		CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
		CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
		CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
	}
	
	CGContextClosePath(context);
	CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)rect fill:(const CGFloat*)fillColors radius:(CGFloat)radius {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	
	if (fillColors) {
		CGContextSaveGState(context);
		CGContextSetFillColor(context, fillColors);
		if (radius) {
			[self addRoundedRectToPath:context rect:rect radius:radius];
			CGContextFillPath(context);
		} else {
			CGContextFillRect(context, rect);
		}
		CGContextRestoreGState(context);
	}
	
	CGColorSpaceRelease(space);
}

- (void)strokeLines:(CGRect)rect stroke:(const CGFloat*)strokeColor {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	
	CGContextSaveGState(context);
	CGContextSetStrokeColorSpace(context, space);
	CGContextSetStrokeColor(context, strokeColor);
	CGContextSetLineWidth(context, 1.0);
	
	{
		CGPoint points[] = {{rect.origin.x+0.5, rect.origin.y-0.5},
			{rect.origin.x+rect.size.width, rect.origin.y-0.5}};
		CGContextStrokeLineSegments(context, points, 2);
	}
	{
		CGPoint points[] = {{rect.origin.x+0.5, rect.origin.y+rect.size.height-0.5},
			{rect.origin.x+rect.size.width-0.5, rect.origin.y+rect.size.height-0.5}};
		CGContextStrokeLineSegments(context, points, 2);
	}
	{
		CGPoint points[] = {{rect.origin.x+rect.size.width-0.5, rect.origin.y},
			{rect.origin.x+rect.size.width-0.5, rect.origin.y+rect.size.height}};
		CGContextStrokeLineSegments(context, points, 2);
	}
	{
		CGPoint points[] = {{rect.origin.x+0.5, rect.origin.y},
			{rect.origin.x+0.5, rect.origin.y+rect.size.height}};
		CGContextStrokeLineSegments(context, points, 2);
	}
	
	CGContextRestoreGState(context);
	
	CGColorSpaceRelease(space);
}

- (BOOL)shouldRotateToOrientation:(UIDeviceOrientation)orientation {
	if (orientation == _orientation) {
		return NO;
	} else {
		return orientation == UIDeviceOrientationLandscapeLeft
		|| orientation == UIDeviceOrientationLandscapeRight
		|| orientation == UIDeviceOrientationPortrait
		|| orientation == UIDeviceOrientationPortraitUpsideDown;
	}
}

- (CGAffineTransform)transformForOrientation {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (orientation == UIInterfaceOrientationLandscapeLeft) {
		return CGAffineTransformMakeRotation(M_PI*1.5);
	} else if (orientation == UIInterfaceOrientationLandscapeRight) {
		return CGAffineTransformMakeRotation(M_PI/2);
	} else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
		return CGAffineTransformMakeRotation(-M_PI);
	} else {
		return CGAffineTransformIdentity;
	}
}

- (void)sizeToFitOrientation:(BOOL)transform {
	if (transform) {
		self.transform = CGAffineTransformIdentity;
	}
	
	CGRect frame = [UIScreen mainScreen].applicationFrame;
	CGPoint center = CGPointMake(
								 frame.origin.x + ceil(frame.size.width/2),
								 frame.origin.y + ceil(frame.size.height/2));
	
	CGFloat scale_factor = 1.0f;
	if ([self FBIsDeviceIPad]) {
		// On the iPad the dialog's dimensions should only be 60% of the screen's
		scale_factor = 0.6f;
	}
	
	CGFloat width = floor(scale_factor * frame.size.width) - kPadding * 2;
	CGFloat height = floor(scale_factor * frame.size.height) - kPadding * 2;
	
	_orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsLandscape(_orientation)) {
		self.frame = CGRectMake(kPadding, kPadding, height, width);
	} else {
		self.frame = CGRectMake(kPadding, kPadding, width, height);
	}
	self.center = center;
	
	if (transform) {
		self.transform = [self transformForOrientation];
	}
}

- (void)updateWebOrientation {
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		[_webView stringByEvaluatingJavaScriptFromString:
		 @"document.body.setAttribute('orientation', 90);"];
	} else {
		[_webView stringByEvaluatingJavaScriptFromString:
		 @"document.body.removeAttribute('orientation');"];
	}
}

- (void)bounce1AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/2];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
	self.transform = CGAffineTransformScale([self transformForOrientation], 0.9, 0.9);
	[UIView commitAnimations];
}

- (void)bounce2AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/2];
	self.transform = [self transformForOrientation];
	[UIView commitAnimations];
}

- (NSURL*)generateURL:(NSString*)baseURL params:(NSDictionary*)params {
	if (params) {
		NSMutableArray* pairs = [NSMutableArray array];
		for (NSString* key in params.keyEnumerator) {
			NSString* value = [params objectForKey:key];
			NSString* escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(
																						  NULL, /* allocator */
																						  (CFStringRef)value,
																						  NULL, /* charactersToLeaveUnescaped */
																						  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
																						  kCFStringEncodingUTF8);
			
			[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
			[escaped_value release];
		}
		
		NSString* query = [pairs componentsJoinedByString:@"&"];
		NSString* url = [NSString stringWithFormat:@"%@?%@", baseURL, query];
		return [NSURL URLWithString:url];
	} else {
		return [NSURL URLWithString:baseURL];
	}
}

- (void)addObservers {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:) name:@"UIKeyboardWillShowNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:) name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)removeObservers {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIKeyboardWillShowNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIKeyboardWillHideNotification" object:nil];
}


- (void)postDismissCleanup {
	[self removeObservers];
	[self removeFromSuperview];
	[_modalBackgroundView removeFromSuperview];
}

- (void)dismiss:(BOOL)animated
{
	BOOL shouldColseDialog = YES;
	if (_delegate && [_delegate respondsToSelector:@selector(dialogShouldClose)]) {
		shouldColseDialog = [_delegate dialogShouldClose];
	}
	
	if (shouldColseDialog) {
		[self dialogWillDisappear];
		
		[_loadingURL release];
		_loadingURL = nil;
		
		if (animated) {
			[UIView beginAnimations:nil context:nil];
			[UIView setAnimationDuration:kTransitionDuration];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(postDismissCleanup)];
			[self removeFromSuperview];
			[UIView commitAnimations];
		} else {
			[self postDismissCleanup];
		}
	}else {
		return;
	}


}

- (void)cancel {
	[_webView stopLoading];
	_webView.delegate = nil;
	[_webView release];
	_webView = nil;
	[self dialogDidCancel:nil];
}

#pragma mark -
#pragma mark LifeCircle

- (id)init {
	if (self = [super initWithFrame:CGRectZero]) {
		_spinner = nil; //default
		customizedView_ = nil; //nil stands for the default webView
		_loadingURL = nil;
		_orientation = UIDeviceOrientationUnknown;
		_showingKeyboard = NO;
		
		self.backgroundColor = [UIColor clearColor];
		self.autoresizesSubviews = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.contentMode = UIViewContentModeRedraw;
		
		_iconView = [[UIImageView alloc] init];
		[self addSubview:_iconView];
		
		UIImage* closeImage = [UIImage imageNamed:@"LoginDialog.bundle/icons/closeButton.png"];
		UIColor* color = [UIColor colorWithRed:167.0/255 green:184.0/255 blue:216.0/255 alpha:1];
		_closeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		[_closeButton setImage:closeImage forState:UIControlStateNormal];
		[_closeButton setTitleColor:color forState:UIControlStateNormal];
		[_closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
		[_closeButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
		_closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
		_closeButton.showsTouchWhenHighlighted = YES;
		_closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin 
		| UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview:_closeButton];
		
		CGFloat titleLabelFontSize = ([self FBIsDeviceIPad]? 18 : 14);
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_titleLabel.text = @"Connecting";//default
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.textColor = [UIColor whiteColor];
		_titleLabel.font = [UIFont boldSystemFontOfSize:titleLabelFontSize];
		_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin
		| UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview:_titleLabel];
		
		_webView = nil;// when invok the fun:setNeedWebView,we init the webView as needed
		
		_modalBackgroundView = [[UIView alloc] init];
		
	}
	return self;
}


- (id)initWithURLStr: (NSString *) serverURL
			  params: (NSMutableDictionary *) params
			delegate: (id <LoginDialogDelegate>) delegate {
	
	self = [self init];
	_serverURL = [serverURL retain];
	_params = [params retain];
	_delegate = delegate;
	
	return self;
}


- (void)dealloc {
	_webView.delegate = nil;
	[_webView release];
	[_params release];
	[_serverURL release];
	[_spinner release];
	[_titleLabel release];
	[_iconView release];
	[_closeButton release];
	[_loadingURL release];
	[_modalBackgroundView release];
	[super dealloc];
}


- (void)drawRect:(CGRect)rect {
	CGRect grayRect = CGRectOffset(rect, -0.5, -0.5);
	[self drawRect:grayRect fill:kBorderGray radius:10];
	
	CGRect headerRect = CGRectMake(
								   ceil(rect.origin.x + kBorderWidth), ceil(rect.origin.y + kBorderWidth),
								   rect.size.width - kBorderWidth*2, _titleLabel.frame.size.height);
	[self drawRect:headerRect fill:kFacebookBlue radius:0];
	[self strokeLines:headerRect stroke:kBorderBlue];
	
	CGRect webRect = CGRectMake(
								ceil(rect.origin.x + kBorderWidth), headerRect.origin.y + headerRect.size.height,
								rect.size.width - kBorderWidth*2, _webView.frame.size.height+1);
	[self strokeLines:webRect stroke:kBorderBlack];
}


#pragma mark -
#pragma mark Helper

- (NSString*)valueForIdentify:(NSString *)indentfy ofQuery:(NSString*)query
{
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	for(NSString *aPair in pairs){
		NSArray *keyAndValue = [aPair componentsSeparatedByString:@"="];
		if([keyAndValue count] != 2) continue;
		if([[keyAndValue objectAtIndex:0] isEqualToString:indentfy]){
			return [keyAndValue objectAtIndex:1];
		}
	}
	return nil;
}


/**
 * Find a specific parameter from the url
 */
- (NSString *) getStringFromUrl: (NSString*) url needle:(NSString *) needle {
	NSString * str = nil;
	NSRange start = [url rangeOfString:needle];
	if (start.location != NSNotFound) {
		NSRange end = [[url substringFromIndex:start.location+start.length] rangeOfString:@"&"];
		NSUInteger offset = start.location+start.length;
		str = end.location == NSNotFound
		? [url substringFromIndex:offset]
		: [url substringWithRange:NSMakeRange(offset, end.location)];
		str = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	
	return str;
}


- (NSString *) locateAuthPinInWebView: (UIWebView *) webView
{
	NSString * js = @"var d = document.getElementById('oauth-pin'); if (d == null) \
	d = document.getElementById('oauth_pin'); if (d) d = d.innerHTML; if (d == null) \
	{var r = new RegExp('\\\\s[0-9]+\\\\s'); d = r.exec(document.body.innerHTML); if (d.length > 0)\
	d = d[0];} d.replace(/^\\s*/, '').replace(/\\s*$/, ''); d;";
	NSString * pin = [webView stringByEvaluatingJavaScriptFromString: js];
	NSLog(@"webview html is %@",[webView stringByEvaluatingJavaScriptFromString: @"document.body"]);
	//if (pin.length > 0) return pin;
	
	NSString			*html = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerText"];
	
	if (html.length == 0) return nil;
	
	const char			*rawHTML = (const char *) [html UTF8String];
	int					length = strlen(rawHTML), chunkLength = 0;
	
	for (int i = 0; i < length; i++) {
		if (rawHTML[i] < '0' || rawHTML[i] > '9') {
			if (chunkLength == 6) {
				char				*buffer = (char *) malloc(chunkLength + 1);
				
				memmove(buffer, &rawHTML[i - chunkLength], chunkLength);
				buffer[chunkLength] = 0;
				
				pin = [NSString stringWithUTF8String: buffer];
				free(buffer);
				return [pin autorelease];
			}
			chunkLength = 0;
		} else
			chunkLength++;
	}
	
	return nil;
}

#pragma mark -
#pragma mark WebViewProces

- (BOOL) facebookWebProcess:(NSURL *)url
{
	NSString * error = [self getStringFromUrl:[url absoluteString] needle:@"error="];
	if (error) {
		if ([error isEqualToString:@"access_denied"]) {
			[self dialogDidCancel:url];
		}else {
			NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
			NSError * error = [NSError errorWithDomain:@"FacebookErrorDomain" code:unknownError userInfo:errorData];
			[self dismissWithError:error animated:YES];
		}			
	}else {
		[self dialogDidSucceed:url];
	}
	return NO;
}


- (BOOL) renrenWebProcess:(NSURL *)url
{
//	NSLog(@"url res %@",url.resourceSpecifier);
//	if ([[url absoluteString] rangeOfString:@"error=login_denied"].location != NSNotFound) {
//		[self dialogDidCancel:url];
//	} else {
//		[self dialogDidSucceed:url];
//	}
	if ([[url absoluteString] rangeOfString:@"access_token="].location != NSNotFound) {
		[self dialogDidSucceed:url];
	}else {
		[self dialogDidCancel:url];
	}

	return NO;
}


- (BOOL) flickrWebProcess:(NSURL *)url denied:(BOOL)userDenied
{
	if (userDenied) {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"User denided" forKey:@"error_msg"];
		NSError * error = [NSError errorWithDomain:@"flickrErrDomain" code:userDeniedError userInfo:errorData];
		[self dismissWithError:error animated:YES];
		return NO;
	}else {
		if ([[url absoluteString] rangeOfString:@"frob="].length != 0) {
			[self dialogDidSucceed:url];
		}else {
			NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error_msg"];
			NSError * error = [NSError errorWithDomain:@"flickrErrDomain" code:unknownError userInfo:errorData];
			[self dismissWithError:error animated:YES];
		}
		return NO;
	}
}



- (BOOL) tencentWebProcess:(NSURL *)url
{
	if ([self valueForIdentify:@"oauth_verifier" ofQuery:[url query]]) {
		[self dialogDidSucceed:url];
		return NO;
	}
	return YES;
}


- (BOOL) twitterWebProcess:(NSURL *)url
{
	[self dialogDidSucceed:url];														//set the application type as Browser
	return NO;	
}


- (BOOL) sohuWebProcess:(NSURL *)url
{
	if ([[url path] isEqualToString:@"/oauth/oob"]) {
		[self dialogDidSucceed:url];
		return NO;
	}else {
		return YES;
	}
}

- (BOOL)sinaWeiboProcess:(NSURL*)url {
    NSRange range = [url.absoluteString rangeOfString:@"code="];
    
    if (range.location != NSNotFound) {
        NSString *code = [url.absoluteString substringFromIndex:range.location + range.length];
        if (_delegate && [_delegate respondsToSelector:@selector(dialog:getAccessTokenWithAuthorizeCode:)]) {
            [_delegate dialog:self getAccessTokenWithAuthorizeCode:code];
        }
        [self dismissWithSuccess:YES animated:YES];
        return NO;
    }
    return YES;
}

- (BOOL) linkClickedProcess:(NSURL *)url
{
	if ([_delegate respondsToSelector:@selector(dialog:shouldOpenURLInExternalBrowser:)]) {
		if (![_delegate dialog:self shouldOpenURLInExternalBrowser:url]) {
			if ([_delegate respondsToSelector:@selector(dialogShouldLoadLinkURL:)]){
				if ([_delegate dialogShouldLoadLinkURL:url]) {
					return YES;
				}
				return NO;
			}else {
				return YES;
			}
				
		}else {
			[[UIApplication sharedApplication] openURL:url];
			return NO;
		}
	}else {
		return YES;
	}
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {

	NSURL* url = request.URL;
	NSLog(@"url is %@",url);
	if ([url.scheme isEqualToString:@"fbconnect"]) {					//This is for Facebook Connection					
		return [self facebookWebProcess:url];
	} else if ([[url path] isEqualToString:@"/oauth/login_success.html"]) {				//This is for renren Connection
		return [self renrenWebProcess:url];
	} else if ([url.scheme isEqualToString:FLICKR_WEB_DOMAIN]) {		//This is for flickr Connection
		return [self flickrWebProcess:url denied:NO];
	} else if ([[url absoluteString] isEqualToString:@"http://m.flickr.com/#/home"]) { //This is for flickr when user denided
		return [self flickrWebProcess:url denied:YES];
	} else if ([[url absoluteString] rangeOfString:@"qq.com"].length !=0) {
		return [self tencentWebProcess:url];
	}else if ([[url host] isEqualToString:TWITTER_WEB_DOMAIN]){			//This is for Twitter connection,you can set the callback URL as http://twitterLoginSucceed.com/
		return [self twitterWebProcess:url];						
	}else if ([[url host] isEqualToString:@"api.t.sohu.com"]) {			//This is for SohuMB Connection
		return [self sohuWebProcess:url];
    }else if ([url.host isEqualToString:SINA_CALLBACK_HOST]) {
        return [self sinaWeiboProcess:url];
    }else if ([_loadingURL isEqual:url]) {
		return YES;
	} else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		return [self linkClickedProcess:url];
	}
	return YES;
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	// 102 == WebKitErrorFrameLoadInterruptedByPolicyChange
	if (!([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102)) {
		[self dismissWithError:error animated:YES];
	}
}


- (void) webViewDidFinishLoad: (UIWebView *) webView {
	
	[_spinner stopAnimating];
	_spinner.hidden = YES;
	self.title = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
	[self updateWebOrientation];
}


// UIDeviceOrientationDidChangeNotification

- (void)deviceOrientationDidChange:(void*)object {
	UIDeviceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (!_showingKeyboard && [self shouldRotateToOrientation:orientation]) {
		[self updateWebOrientation];
		
		CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:duration];
		[self sizeToFitOrientation:YES];
		[UIView commitAnimations];
	}
}

#pragma mark -
#pragma mark UI

- (void)keyboardWillShow:(NSNotification*)notification {
	
	_showingKeyboard = YES;
	
	if ([self FBIsDeviceIPad]) {
		// On the iPad the screen is large enough that we don't need to
		// resize the dialog to accomodate the keyboard popping up
		return;
	}
	
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		_webView.frame = CGRectInset(_webView.frame,
									 -(kPadding + kBorderWidth),
									 -(kPadding + kBorderWidth) - _titleLabel.frame.size.height);
	}
}

- (void)keyboardWillHide:(NSNotification*)notification {
	_showingKeyboard = NO;
	
	if ([self FBIsDeviceIPad]) {
		return;
	}
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		_webView.frame = CGRectInset(_webView.frame,
									 kPadding + kBorderWidth,
									 kPadding + kBorderWidth + _titleLabel.frame.size.height);
	}
}





- (NSString*)title {
	return _titleLabel.text;
}

- (void)setTitle:(NSString*)title {
	_titleLabel.text = title;
}

- (void)load {
	[self loadURL:_serverURL get:_params];
}

- (void)loadURL:(NSString*)url get:(NSDictionary*)getParams {
	if (url) {
		[_loadingURL release];
		_loadingURL = [[self generateURL:url params:getParams] retain];
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_loadingURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
		[_webView loadRequest:request];
	}
}

- (void)show {
	
	if (_webView) {
		[self load];
	}
	[self sizeToFitOrientation:NO];
	
	CGFloat innerWidth = self.frame.size.width - (kBorderWidth+1)*2;
	[_iconView sizeToFit];
	[_titleLabel sizeToFit];
	[_closeButton sizeToFit];
	
	_titleLabel.frame = CGRectMake(
								   kBorderWidth + kTitleMarginX + _iconView.frame.size.width + kTitleMarginX,
								   kBorderWidth,
								   innerWidth - (_titleLabel.frame.size.height + _iconView.frame.size.width + kTitleMarginX*2),
								   _titleLabel.frame.size.height + kTitleMarginY*2);
	
	_iconView.frame = CGRectMake(
								 kBorderWidth + kTitleMarginX,
								 kBorderWidth + floor(_titleLabel.frame.size.height/2 - _iconView.frame.size.height/2),
								 _iconView.frame.size.width,
								 _iconView.frame.size.height);
	
	_closeButton.frame = CGRectMake(
									self.frame.size.width - (_titleLabel.frame.size.height + kBorderWidth),
									kBorderWidth,
									_titleLabel.frame.size.height,
									_titleLabel.frame.size.height);
	if (_webView) {
		_webView.frame = CGRectMake(
									kBorderWidth+1,
									kBorderWidth + _titleLabel.frame.size.height,
									innerWidth,
									self.frame.size.height - (_titleLabel.frame.size.height + 1 + kBorderWidth*2));
	}else {
		loginViewCtr_.view.frame = CGRectMake(
													kBorderWidth+1,
													kBorderWidth + _titleLabel.frame.size.height,
													innerWidth,
													self.frame.size.height - (_titleLabel.frame.size.height + 1 + kBorderWidth*2));
		
		[[[loginViewCtr_.view subviews] objectAtIndex:0] setFrame:loginViewCtr_.view.bounds];
	}
	
	
	if (_webView) {
		[_spinner sizeToFit];
		[_spinner startAnimating];
		_spinner.center = _webView.center;
	}
	
	UIWindow* window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	
	_modalBackgroundView.frame = window.frame;
	[_modalBackgroundView addSubview:self];
	[window addSubview:_modalBackgroundView];
	
	[window addSubview:self];
	
	[self dialogWillAppear];
	
	self.transform = CGAffineTransformScale([self transformForOrientation], 0.001, 0.001);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/1.5];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
	self.transform = CGAffineTransformScale([self transformForOrientation], 1.1, 1.1);
	[UIView commitAnimations];
	[self addObservers];
}

- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated {
	if (success) {
		if ([_delegate respondsToSelector:@selector(dialogDidComplete:)]) {
			[_delegate dialogDidComplete:self];
		}
	} else {
		if ([_delegate respondsToSelector:@selector(dialogDidNotComplete:)]) {
			[_delegate dialogDidNotComplete:self];
		}
	}
	
	[self dismiss:animated];
}

- (void)dismissWithError:(NSError*)error animated:(BOOL)animated {
	if ([_delegate respondsToSelector:@selector(dialog:didFailWithError:)]) {
		[_delegate dialog:self didFailWithError:error];
	}
	
	[self dismiss:animated];
}

- (void)dialogWillAppear {
}

- (void)dialogWillDisappear {
}

- (void)dialogDidSucceed:(NSURL *)url {
	
	if ([_delegate respondsToSelector:@selector(dialogCompleteWithUrl:)]) {
		[_delegate dialogCompleteWithUrl:url];
	}
	[self dismissWithSuccess:YES animated:YES];
}

- (void)dialogDidCancel:(NSURL *)url {
	if ([_delegate respondsToSelector:@selector(dialogDidNotCompleteWithUrl:)]) {
		[_delegate dialogDidNotCompleteWithUrl:url];
	}
	[self dismissWithSuccess:NO animated:YES];
}

- (void)authrizeFeedbackStatus:(BOOL)finished error:(NSError *)error
{
	if (finished) {
		[self dismiss:YES];
		return;
	}else if (error) {
		NSString * errMsg;
		if ((errMsg = [[error userInfo] objectForKey:@"error_msg"])) {
			;
		}else if ((errMsg = [[error userInfo] objectForKey:@"error"])) {
			;
		}else {
			errMsg = @"Invalid UserName or Password"; //this is the last choice
		}
		
		loginViewCtr_.feedbackLabel.text = errMsg;
	}
	
	[_spinner stopAnimating];
}

#pragma mark -
#pragma mark LoginViewDelegate

- (void) loginWithUserName:(NSString*)userName andPwd:(NSString*)pwd
{
	[_spinner sizeToFit];
	[_spinner startAnimating];
	_spinner.center = loginViewCtr_.view.center;
	[_delegate dialog:self loginWithUserName:userName andPwd:pwd];
}

- (void) cancelBtnClicked
{
	[_delegate dialogCancelBtnClicked];
	[self dismiss:YES];
}

#pragma mark -
#pragma mark Customize

- (void) setNeedWebView:(BOOL)needWebView
{
	if (needWebView) {
		_webView = [[UIWebView alloc] initWithFrame:CGRectMake(kPadding, kPadding, 480, 480)];
		_webView.delegate = self;
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:_webView];
	}else {
		[self addCustomizedView];
	}
	_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	_spinner.autoresizingMask =UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
	| UIViewAutoresizingFlexibleLeftMargin	| UIViewAutoresizingFlexibleRightMargin;
	[self addSubview:_spinner];
}


- (void)setServerURL:(NSString*)url
{
	_serverURL = [url retain];
}


- (void)setConnectTitle:(NSString *)defautTitle
{
	_titleLabel.text = defautTitle;
}


- (void)setIconImg:(UIImage *)iconImg;
{
	[_iconView setImage:iconImg];	
}


- (void)setLoginViewBgImage:(UIImage *)bgImg
{
	UIImageView * bgImgView = [[UIImageView alloc] initWithImage:bgImg];
	[loginViewCtr_.view insertSubview:bgImgView atIndex:0];
	[bgImgView release];
}


- (void)addCustomizedView
{
	loginViewCtr_ = [[LoginViewController alloc] init];
	[loginViewCtr_.view setFrame:CGRectMake(kPadding, kPadding, 480, 480)];
	loginViewCtr_.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self addSubview:loginViewCtr_.view];
	loginViewCtr_.loginViewDelegate = self;
}

@end
