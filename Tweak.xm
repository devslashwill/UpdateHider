#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SA_ActionSheet.h"
#import "HeaderView.h"

#define PrefsPath @"/var/mobile/Library/Preferences/com.whomer.UpdateHider.plist"

@interface SUItem : NSObject
- (NSString *)bundleVersion;
- (NSString *)bundleIdentifier;
- (NSString *)title;
@end

@interface ASUpdatesViewController : UITableViewController
- (SUItem *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (void)reload;
@end

@interface UITableView (Private)
- (NSArray *)indexPathsForSelectedRows;
@end

NSMutableArray *hiddenItems = nil;
ASUpdatesViewController *updatesViewController = nil;
BOOL wasDragged = NO;

BOOL isUpdateBlocked(NSDictionary *update)
{
	BOOL blocked = NO;
	
	NSString *itemID = [update objectForKey:@"bundle-id"];
	NSString *version = [update objectForKey:@"version"];
	
	for (NSDictionary *blockedItem in hiddenItems)
	{
		if ([itemID isEqualToString:[blockedItem objectForKey:@"id"]] && [version isEqualToString:[blockedItem objectForKey:@"version"]])
		{
			blocked = YES;
			break;
		}
	}
	
	return blocked;
}

%hook SSSoftwareUpdatesResponse

- (id)initWithDictionaryResponse:(NSDictionary *)response
{	
	if ([hiddenItems count] == 0)
		return %orig;
		
	NSMutableDictionary *dict = [response mutableCopy];
	NSMutableArray *items = [[dict objectForKey:@"2"] mutableCopy];
	NSMutableArray *itemsToKeep = [[NSMutableArray alloc] init];
	
	for (NSDictionary *updateItem in items)
	{
		if (!isUpdateBlocked(updateItem))
			[itemsToKeep addObject:updateItem];
	}
	
	[dict setObject:itemsToKeep forKey:@"2"];
	[items release];
	[itemsToKeep release];
	
	return %orig([dict autorelease]);
}

%end

%hook ASUpdatesViewController

- (id)init
{
	id orig = %orig;
	updatesViewController = orig;
	return orig;
}

- (void)loadView
{
	%orig;
	
	HeaderView *header = [[HeaderView alloc] initWithFrame:CGRectMake(0, -480, 320, 480)];
	[self.tableView addSubview:header];
	[header release];
}

- (void)setLoading:(BOOL)loading
{
	self.tableView.scrollEnabled = !loading;
	%orig;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger numOfRows = %orig;
	self.tableView.scrollEnabled = (numOfRows != 0);
	return numOfRows;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView.editing)
	{
		[[self tableView:tableView cellForRowAtIndexPath:indexPath] setSelected:YES animated:YES];
		return;
	}
	
	%orig;
}

%new(v@::) - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (NSInteger)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (wasDragged)
	{
		if (indexPath.row == ([self tableView:tableView numberOfRowsInSection:0] - 1))
			wasDragged = NO;
		
		return 3;
	}
	
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NSLocalizedStringFromTableInBundle(@"IGNORE", @"ManagedConfigurationUI", [NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/ManagedConfigurationUI.bundle"], @"");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath
{
	SA_ActionSheet *sheet = [[SA_ActionSheet alloc] initWithTitle:@"Are you sure you want to hide this update?\nOnly this version will be hidden, future versions will still be shown." delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Hide", nil];
	
	[sheet showFromTabBar:self.tabBarController.tabBar buttonBlock:^(int buttonIndex){
		if (buttonIndex == 0)
		{
			SUItem *item = [self itemAtIndexPath:indexPath];
			
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[item bundleIdentifier], @"id", [item bundleVersion], @"version", [item title], @"title", nil];
			[hiddenItems addObject:dict];
			
			[hiddenItems writeToFile:PrefsPath atomically:YES];
			
			[self reload];
		}
	}];
	
	[sheet release];
}

%new(v@::) - (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{	
	if (scrollView.contentOffset.y <= -65.0f)
	{
		wasDragged = YES;
		[self setEditing:!self.tableView.editing];
	}
}

%new(v@:) - (void)setEditing:(BOOL)editing
{
	[self.tableView setEditing:editing animated:YES];
	self.navigationItem.rightBarButtonItem.enabled = !editing;
	
	if (editing)
	{
		UIBarButtonItem *ignoreButton = [[UIBarButtonItem alloc] initWithTitle:@"Hide" style:UIBarButtonItemStyleBordered target:self action:@selector(ignoreButtonPressed:)];
		[self.navigationItem setLeftBarButtonItem:ignoreButton animated:YES];
		[ignoreButton release];
	}
	else
	{
		[self.navigationItem setLeftBarButtonItem:nil animated:YES];
	}
}

%new(v@:) - (void)ignoreButtonPressed:(UIBarButtonItem *)sender
{
	NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
	NSUInteger count = [selectedIndexPaths count];
	
	if (count)
	{
		NSString *title = [NSString stringWithFormat:@"Are you sure you want to hide th%@ update%@?\nOnly this version will be hidden, future versions will still be shown.", count > 1 ? @"ese" : @"is", count > 1 ? @"s" : @""];
		
		SA_ActionSheet *sheet = [[SA_ActionSheet alloc] initWithTitle:title delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Hide", nil];
		
		[sheet showFromTabBar:self.tabBarController.tabBar buttonBlock:^(int buttonIndex){
			if (buttonIndex == 0)
			{
				for (NSIndexPath *indexPath in selectedIndexPaths)
				{
					SUItem *item = [self itemAtIndexPath:indexPath];
					
					NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[item bundleIdentifier], @"id", [item bundleVersion], @"version", [item title], @"title", nil];
					[hiddenItems addObject:dict];
				}
				
				[hiddenItems writeToFile:PrefsPath atomically:YES];
				
				[self setEditing:!self.tableView.editing];
				
				[self reload];
			}
		}];
		
		[sheet release];
	}
}

%end

%hook UITabBarItem

- (void)setBadgeValue:(NSString *)value
{
	if (self == updatesViewController.tabBarItem)
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:[value intValue]];
	
	%orig;
}

%end

%hook ASApplication

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	%orig;
	
	[hiddenItems release];
	
	hiddenItems = [[NSMutableArray alloc] initWithContentsOfFile:PrefsPath];
	
	if (hiddenItems == nil)
		hiddenItems = [[NSMutableArray alloc] init];
}

%new(v@:) - (void)applicationWillEnterBackground:(UIApplication *)application
{
	[application setApplicationIconBadgeNumber:[updatesViewController.tabBarItem.badgeValue intValue]];
}

%end

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	%init;
	
	hiddenItems = [[NSMutableArray alloc] initWithContentsOfFile:PrefsPath];
	
	if (hiddenItems == nil)
		hiddenItems = [[NSMutableArray alloc] init];
	
	[pool drain];
}