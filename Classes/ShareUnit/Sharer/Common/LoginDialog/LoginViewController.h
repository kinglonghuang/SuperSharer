//
//  LoginViewController.h
//  SnapAndRun
//
//  Created by kinglong on 11-2-28.
//  Copyright 2011 wondershare. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoginViewDelegate

- (void) loginWithUserName:(NSString*)userName andPwd:(NSString*)pwd;

- (void) cancelBtnClicked;

@end

@interface LoginViewController : UIViewController <UITextFieldDelegate> {
	id							loginViewDelegate;
	IBOutlet					UITextField * userNameTextField_;
	IBOutlet					UITextField * pwdTextField_;
	IBOutlet					UILabel * feedbackLabel_;
}

@property (nonatomic,assign)IBOutlet UILabel * feedbackLabel;

@property (nonatomic,retain)id <LoginViewDelegate> loginViewDelegate;

- (IBAction)onLogin;

- (IBAction)onCancel;
@end
