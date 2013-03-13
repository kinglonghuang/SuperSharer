//
//  LoginViewController.m
//  SnapAndRun
//
//  Created by kinglong on 11-2-28.
//  Copyright 2011 wondershare. All rights reserved.
//

#import "LoginViewController.h"

static BOOL shouldUpTheInputView = YES;

@implementation LoginViewController

@synthesize loginViewDelegate;

@synthesize feedbackLabel = feedbackLabel_;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark -
#pragma mark textfieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if(textField == pwdTextField_)
	{
		[pwdTextField_ resignFirstResponder];
		[UIView beginAnimations:@"textFiled Animation" context:nil];
		[[self.view superview] setCenter:CGPointMake([self.view superview].center.x, [self.view superview].center.y + 80)];
		[UIView commitAnimations];
		shouldUpTheInputView = YES;
	}else if (textField ==  userNameTextField_) {
		[userNameTextField_ resignFirstResponder];
		[pwdTextField_ becomeFirstResponder];
	}


	return YES;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	if (textField == userNameTextField_) {
		if (shouldUpTheInputView) {
			[UIView beginAnimations:@"textFiled Animation" context:nil];
			[[self.view superview] setCenter:CGPointMake([self.view superview].center.x, [self.view superview].center.y - 80)];
			[UIView commitAnimations];
			shouldUpTheInputView = NO;
		}
	}else if (textField == pwdTextField_) {
		if (shouldUpTheInputView) {
			[UIView beginAnimations:@"textFiled Animation" context:nil];
			[[self.view superview] setCenter:CGPointMake([self.view superview].center.x, [self.view superview].center.y - 80)];
			[UIView commitAnimations];
			shouldUpTheInputView = NO;
		}
	}

	return YES;
}


#pragma mark -
#pragma mark IBActions

- (IBAction)onLogin
{
	NSString * userName = [userNameTextField_ text];
	NSString * pwd = [pwdTextField_ text];
	NSAssert(loginViewDelegate,@"You must set the loginview delegate before load it");
	[loginViewDelegate loginWithUserName:userName andPwd:pwd];
}


- (IBAction)onCancel
{
	NSAssert(loginViewDelegate,@"You must set the loginview delegate befor load it");
	[loginViewDelegate cancelBtnClicked];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
