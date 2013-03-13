//
//  RootViewController.m
//  SuperSharer
//
//  Created by kinglong on 4/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"

@implementation RootViewController


#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.title = @"SuperSharer";
	
	tableViewDataSource_ = [[NSArray alloc]initWithObjects:FacebookID,TwitterID,FlickrID,RenRenID,SinaMBID,TencentMBID,SohuMBID,ReadItLaterID,InstapaperID,nil];
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
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
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableViewDataSource_ count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// Configure the cell.
    cell.textLabel.text = [tableViewDataSource_ objectAtIndex:indexPath.row];
    return cell;
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    	
	NSString * shareID = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];

	//start share your image
	shareItem_  = [[ShareItem alloc] initForItem:shareID delegate:self];
	UIImage * image = [UIImage imageNamed:@"test.png"];
	[shareItem_ logout];
	[shareItem_ shareImage:image withDescription:@"Final Test"];
}


#pragma mark -
#pragma mark ShareDelegate

- (void) shareItemLoginSucceed:(id)item
{
	NSLog(@"shareItemLoginSucceed: %@",item);
	
}


- (void) shareItemLoginCancelled:(id)item
{
	NSLog(@"shareItemLoginCancelled: %@",item);
}


- (void) shareItem:(id)item loginFailed:(NSError *)error
{
	NSLog(@"shareItem %@,loginFailed:%@",item,error);
}


- (void) shareItemLogoutSucceed:(id)item
{
	NSLog(@"shareItemLogoutSucceed: %@",item);
}

- (void) shareItemShareBegin:(id)item
{
	NSLog(@"shareItemShareBegin: %@",item);
}

- (void) shareItemShareSucceed:(id)item
{
	NSLog(@"shareItemShareSucceed: %@",item);
}

- (void) shareItemShareCancelled:(id)item
{
	NSLog(@"shareItemShareCancelled: %@",item);
}

- (void) shareItem:(id)item shareFailed:(NSError*)error
{
	NSLog(@"shareItem %@,shareFailed:%@",item,error);
}

- (void) shareItem:(id)item feedbackStatus:(NSString *)status
{
	NSLog(@"shareItem %@,feedbackStatus:%@",item,status);
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[shareItem_ release];
	[tableViewDataSource_ release];
    [super dealloc];
}


@end

