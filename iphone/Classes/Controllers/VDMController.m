#import "VDMController.h"
#import "VDMEntryCell.h"
#import "VDMEntry.h"
#import "RSTLTintedBarButtonItem.h"
#import "VDMSettings.h"
#import "RSTLRoundedView.h"
#import "VDMInfoView.h"
#import "GATracker.h"
#import "VDMAddEntryController.h"
#import "VDMLoadingView.h"
#import "VDMReadEntryController.h"
#import "VDMThemeChooserController.h"
#import "VDMEntryTheme.h"

#define RECENTS_VDMS_PATH [NSString stringWithFormat:@"/page/%d.xml", currentPage]
#define CATEGORY_VDMS_PATH [NSString stringWithFormat:@"/%@.xml?page=%d", currentCategory, currentPage]
#define RANDOM_VDMS_PATH @"/many_randoms.xml"

@interface VDMController()
-(void) fetchEntriesXML:(NSString *) path;
-(void) setActiveButton:(UIButton *) newActiveButton;
-(void) createToolbarItems;
-(UIView *) createLoadingView;
-(void) removeOldEntries;
-(void) addNavigationButtons;
-(void) trackPageView;
@end

@implementation VDMController

-(void) viewDidLoad {
	currentPage = 1;
	isFirstLoad = YES;
	[self createToolbarItems];
	[self setActiveButton:(UIButton *)[(UIBarButtonItem *)[self.toolbarItems objectAtIndex:1] customView]];
	[self addNavigationButtons];
	currentEntryType = VDMEntryTypeRecent;
	[self fetchEntriesXML:RECENTS_VDMS_PATH];
	selectedThemeId = 9;
}

-(void) addNavigationButtons {
	// Logo
	self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"vdm_logo_small.png"]] autorelease];
	
	// Application info
	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight]; 
	[infoButton addTarget:self action:@selector(infoButtonTouch:) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:infoButton] autorelease];
	
	// Add VDM
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
		target:self action:@selector(addEntry)] autorelease];
}

-(void) addEntry {
	VDMAddEntryController *c = [[VDMAddEntryController alloc] init];
	self.title = @"Back";
	[self.navigationController pushViewController:c animated:YES];
	SafeRelease(c);
}

-(void) infoButtonTouch:(id) sender {
	VDMInfoView *infoView = LoadViewNib(@"VDMInfoView");
	infoView.center = self.view.center;
	[self.view addSubview:infoView];
}

-(void) trackPageView {
	if (currentEntryType == VDMEntryTypeRecent) {
		[GATracker trackPageView:[NSString stringWithFormat:@"/recentes/%d", currentPage]];
	}
	else if (currentEntryType == VDMEntryTypeRandom) {
		[GATracker trackPageView:[NSString stringWithFormat:@"/aleatorias/%d", currentPage]];
	}
	else if (currentEntryType == VDMEntryTypeCategory) {
		[GATracker trackPageView:[NSString stringWithFormat:@"/categoria/%@/%d", currentCategory, currentPage]];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)dealloc {
	SafeRelease(tableView);
	SafeRelease(vdmFetcher);
	SafeRelease(currentCategory);
	[super dealloc];
}

-(void) createToolbarItems {
	// Recents
	UIButton *recentsButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 75, 31)] autorelease];
	[recentsButton setBackgroundImage:[UIImage imageNamed:@"black_button.png"] forState:UIControlStateNormal];
	[recentsButton addTarget:self action:@selector(recentsDidSelect:) forControlEvents:UIControlEventTouchUpInside];
	[recentsButton setTitle:@"Recentes" forState:UIControlStateNormal];
	recentsButton.titleLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
	UIBarButtonItem *recentsItem = [[[UIBarButtonItem alloc] initWithCustomView:recentsButton] autorelease];
	
	// Random
	UIButton *randomButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 75, 31)] autorelease];
	[randomButton setBackgroundImage:[UIImage imageNamed:@"black_button.png"] forState:UIControlStateNormal];
	[randomButton addTarget:self action:@selector(randomDidSelect:) forControlEvents:UIControlEventTouchUpInside];
	[randomButton setTitle:@"Aleatórias" forState:UIControlStateNormal];
	randomButton.titleLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
	UIBarButtonItem *randomItem = [[[UIBarButtonItem alloc] initWithCustomView:randomButton] autorelease];

	// Themes
	UIButton *themeButton = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 75, 31)] autorelease];
	[themeButton setBackgroundImage:[UIImage imageNamed:@"black_button.png"] forState:UIControlStateNormal];
	[themeButton addTarget:self action:@selector(categoryDidSelect:) forControlEvents:UIControlEventTouchUpInside];
	[themeButton setTitle:@"Temas" forState:UIControlStateNormal];
	themeButton.titleLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:12];
	UIBarButtonItem *themeItem = [[[UIBarButtonItem alloc] initWithCustomView:themeButton] autorelease];
														
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[self setToolbarItems:[NSArray arrayWithObjects:flexibleSpace, recentsItem, randomItem, themeItem, flexibleSpace, nil]];
}

-(UIView *) createLoadingView {
	float height = isFirstLoad ? 100 : 50;
	VDMLoadingView *v = [VDMLoadingView loadingViewWithSize:CGSizeMake(self.view.width - 100, height) message:@"Carregando VDMs"];
	float y = isFirstLoad ? (self.view.height - v.height) / 2 : 10;
	[v setOrigin:CGPointMake((self.view.width - v.width) / 2, y)];
	return v;
}

-(IBAction) recentsDidSelect:(id) sender {
	currentEntryType = VDMEntryTypeRecent;
	currentPage = 1;
	SafeRelease(currentCategory);
	isFirstLoad = YES;
	[self removeOldEntries];
	[self fetchEntriesXML:RECENTS_VDMS_PATH];
	[self setActiveButton:sender];
}

-(IBAction) randomDidSelect:(id) sender {
	currentEntryType = VDMEntryTypeRandom;
	[self setActiveButton:sender];
	SafeRelease(currentCategory);
	currentPage = 1;
	isFirstLoad = YES;
	[self removeOldEntries];
	[self fetchEntriesXML:RANDOM_VDMS_PATH];
}

-(IBAction) categoryDidSelect:(id) sender {
	VDMThemeChooserController *c = [[VDMThemeChooserController alloc] init];

	c.didChooseThemeAction = ^(void *context) {
		VDMEntryTheme *t = context;
		selectedThemeId = t.themeId;
		currentCategory = t.name;
		currentPage = 1;
		currentEntryType = VDMEntryTypeCategory;
		isFirstLoad = YES;
		[categoriesPopover dismissPopoverAnimated:YES];
		categoriesPopover = nil;
		[self setActiveButton:sender];
		[self removeOldEntries];
		[self fetchEntriesXML:CATEGORY_VDMS_PATH];
	};
	
	c.selectedThemeId = selectedThemeId;
	c.contentSizeForViewInPopover = CGSizeMake(220, self.view.height - 50);
	categoriesPopover = [[WEPopoverController alloc] initWithContentViewController:c];
	[categoriesPopover presentPopoverFromRect:CGRectMake(self.view.width - 100, self.view.height
	, 50, 50) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
	SafeRelease(c);
}

-(void) setActiveButton:(UIButton *) newActiveButton {
	for (UIBarButtonItem *b in self.toolbarItems) {
		[(UIButton *)b.customView setBackgroundImage:[UIImage imageNamed:@"black_button.png"] forState:UIControlStateNormal];
	}
	
	[newActiveButton setBackgroundImage:[UIImage imageNamed:@"red_button.png"] forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark VDMs download
-(void) removeOldEntries {
	NSMutableArray *indexPaths = [NSMutableArray array];
	
	for (int i = 0; i < entries.count; i++) {
		[indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
	}
	
	SafeRelease(entries);
	[tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationRight];
}

-(void) addNewEntries:(BOOL) animated {
	NSMutableArray *indexPaths = [NSMutableArray array];
	
	for (int i = [tableView numberOfRowsInSection:0]; i < entries.count; i++) {
		[indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
	}

	[tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:animated ? UITableViewRowAnimationLeft : UITableViewRowAnimationNone];
}

-(void) fetchEntriesXML:(NSString *) path {
	if (!vdmFetcher) {
		vdmFetcher = [[VDMFetcher alloc] init];
	}
	
	if (loadingView) {
		[loadingView removeFromSuperview];
		loadingView = nil;
	}
	
	loadingView = [self createLoadingView];
	[self.view addSubviewAnimated:loadingView];
		
	NSURL *url = [[NSString stringWithFormat:@"%@%@%@bypass_mobile=1", [[VDMSettings instance] baseURL], 
		path, [path contains:@"?"] ? @"&" : @"?"] toURL];
		
	[vdmFetcher fetchFromURL:url
		withCompletionBlock:^(NSString *errorMessage, NSArray *result) {
			if (![NSString isStringEmpty:errorMessage]) {
				ShowAlert(@"Erro", errorMessage);
			}
			else {
				if (entries) {
					[entries addObjectsFromArray:result];
					[self addNewEntries:NO];
				}
				else {
					entries = [result retain];
					[self addNewEntries:YES];
				}
				
				[self trackPageView];
			}
			
			[loadingView removeFromSuperviewAnimated];
			loadingView = nil;
			isFirstLoad = NO;
			loadingExtra = NO;
	}];
}

#pragma mark -
#pragma mark UITableViewDelegate
-(void) tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	VDMReadEntryController *c = [[VDMReadEntryController alloc] init];
	c.entry = [entries objectAtIndex:indexPath.row];
	[self.navigationController pushViewController:c animated:YES];
	SafeRelease(c);
}

-(CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	VDMEntry *entry = [entries objectAtIndex:indexPath.row];
	return [entry.contents sizeWithFont:[UIFont systemFontOfSize:16] 
		constrainedToSize:CGSizeMake(tableView.width, 250) 
		lineBreakMode:UILineBreakModeWordWrap].height + 30;
}

#pragma mark -
#pragma mark UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return entries.count;
}

-(UITableViewCell *) tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellId = @"CellId";
	
	VDMEntryCell *cell = (VDMEntryCell *)[tableView dequeueReusableCellWithIdentifier:CellId];
	
	if (!cell) {
		cell = LoadViewNib(@"VDMEntryCell");
		cell.textView.font = [UIFont fontWithName:@"Verdana" size:12];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	VDMEntry *entry = [entries objectAtIndex:indexPath.row];
	cell.entry = entry;
	cell.textView.text = entry.contents;
	[cell setDeserveCount:entry.deserveCount];
	[cell setLifeSucksCount:entry.agreeCount];
	
	if ((float)indexPath.row / (float)entries.count >= 0.8 && !loadingExtra && !isFirstLoad) {
		loadingExtra = YES;
		currentPage++;
				
		if (currentEntryType == VDMEntryTypeRecent) {
			[self fetchEntriesXML:RECENTS_VDMS_PATH];
		}
		else if (currentEntryType == VDMEntryTypeRandom) {
			[self fetchEntriesXML:RANDOM_VDMS_PATH];
		}
		else if (currentEntryType == VDMEntryTypeCategory) {
			[self fetchEntriesXML:CATEGORY_VDMS_PATH];
		}
	}

	return cell;
}

@end
