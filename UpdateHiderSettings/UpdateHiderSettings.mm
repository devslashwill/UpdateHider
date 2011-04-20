#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define PrefsPath @"/var/mobile/Library/Preferences/com.whomer.UpdateHider.plist"

@interface PSViewController : UIViewController
@end

@interface UpdateHiderSettingsController : PSViewController <UITableViewDelegate, UITableViewDataSource>
{
	UITableView *_tableView;
	NSMutableArray *blockedUpdates;
}

@end

@implementation UpdateHiderSettingsController

- (void)dealloc
{
	[super dealloc];
	[_tableView release];
	[blockedUpdates release];
}

- (void)loadData
{
	[blockedUpdates release];
	blockedUpdates = [[NSMutableArray alloc] initWithContentsOfFile:PrefsPath];
	
	if (blockedUpdates == nil)
		blockedUpdates = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad
{	
	self.title = @"Update Hider";

	[self loadData];
	
	_tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] bounds] style:UITableViewStyleGrouped];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	[self.view addSubview:_tableView];
}

- (void)willBecomeActive
{
	[self loadData];
	
	//[_tableView reloadData];
	[_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([blockedUpdates count])
		return [blockedUpdates count];
	
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 50.0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Hidden Updates";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return @"©2011 Will Homer";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	if ([blockedUpdates count])
	{
		cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		
		if (cell == nil)
		{
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
		NSDictionary *item = [blockedUpdates objectAtIndex:indexPath.row];
		NSString *title = [item objectForKey:@"title"];
		
		if (title == nil)
			title = [item objectForKey:@"id"];
		
		cell.textLabel.text = title;
		cell.detailTextLabel.text = [item objectForKey:@"version"];
	}
	else
	{
		cell = [tableView dequeueReusableCellWithIdentifier:@"BlankCell"];
		
		if (cell == nil)
		{
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BlankCell"] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.textLabel.textAlignment = UITextAlignmentCenter;
		}
		
		cell.textLabel.text = @"No updates";
	}
	
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([blockedUpdates count])
		return YES;
	
	return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView beginUpdates];
	
	[blockedUpdates removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	
	if ([blockedUpdates count] == 0)
		[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
	
	[tableView endUpdates];
	
	[blockedUpdates writeToFile:PrefsPath atomically:YES];
}

@end
