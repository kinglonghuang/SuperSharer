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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LoginViewController.h"

@protocol LoginDialogDelegate;

/**
 * Do not use this interface directly, instead, use dialog in Facebook.h
 *
 * Facebook dialog interface for start the facebook webView UIServer Dialog.
 */

@interface LoginDialog : UIView <UIWebViewDelegate,LoginViewDelegate> {
	id						_delegate;
	NSMutableDictionary		*_params;
	NSString				* _serverURL;
	NSURL					* _loadingURL;
	UIWebView				* _webView;
	UIImageView				* _iconView;
	UILabel					* _titleLabel;
	UIButton				* _closeButton;
	UIDeviceOrientation		_orientation;
	BOOL					_showingKeyboard;
	UIActivityIndicatorView	* _spinner;

	UIView					* _modalBackgroundView;
		
	BOOL					shouldLoadWebView_;
	UIView					* customizedView_;
	LoginViewController		* loginViewCtr_;
}

@property(nonatomic,assign) id<LoginDialogDelegate> delegate;

@property(nonatomic, retain) NSMutableDictionary* params;

@property(nonatomic,copy) NSString* title;


- (NSString *) getStringFromUrl: (NSString*) url needle:(NSString *) needle;

- (id)initWithURLStr: (NSString *) loadingURL
           params: (NSMutableDictionary *) params
         delegate: (id <LoginDialogDelegate>) delegate;

- (void)show;

- (void)load;

- (void)loadURL:(NSString*)url
            get:(NSDictionary*)getParams;

- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated;

- (void)dismissWithError:(NSError*)error animated:(BOOL)animated;

- (void)dismiss:(BOOL)animated;

- (void)dialogWillAppear;

- (void)dialogWillDisappear;

- (void)dialogDidSucceed:(NSURL *)url;

- (void)dialogDidCancel:(NSURL *)url;

- (void)addCustomizedView;

- (void)authrizeFeedbackStatus:(BOOL)finished error:(NSError *)error;

- (NSString*)valueForIdentify:(NSString *)indentfy ofQuery:(NSString*)query;

//Customize

- (void) setNeedWebView:(BOOL)needWebView;

- (void) setServerURL:(NSString*)url;

- (void) setConnectTitle:(NSString *)defautTitle;

- (void) setIconImg:(UIImage *)iconImg;

- (void) setLoginViewBgImage:(UIImage *)bgImg;

- (void) addCustomizedView;

- (NSString *) locateAuthPinInWebView: (UIWebView *) webView;

@end


@protocol LoginDialogDelegate <NSObject>

@optional

/**
 * Called when the dialog succeeds and is about to be dismissed.
 */
- (void)dialogDidComplete:(LoginDialog *)dialog;

/**
 * Called when the dialog succeeds with a returning url.
 */
- (void)dialogCompleteWithUrl:(NSURL *)url;

/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url;

/**
 * Called when the dialog is cancelled and is about to be dismissed.
 */
- (void)dialogDidNotComplete:(LoginDialog *)dialog;

/**
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(LoginDialog*)dialog didFailWithError:(NSError *)error;

- (BOOL)dialog:(LoginDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url;

- (void)dialog:(LoginDialog*)dialog getAccessTokenWithAuthorizeCode:(NSString *)code;

- (BOOL)dialogShouldClose;// a chance to detemine whether close the loginDialog

- (BOOL)dialogShouldLoadLinkURL:(NSURL *)url; //tell the loginDialog whether should load the request from linkClicked

//the customise loginView delegate Method
- (void)dialog:(LoginDialog*)dialog loginWithUserName:(NSString*)userName andPwd:(NSString*)pwd;

- (void)dialogCancelBtnClicked;

@end
