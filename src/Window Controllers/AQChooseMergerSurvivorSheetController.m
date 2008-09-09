// AQChooseMergerSurvivorSheetController.m
//
// Created August 07, 2008 by nwaite

#import "AQChooseMergerSurvivorSheetController.h"
#import "AQGameWindowController.h"
#import "AQHotel.h"

@implementation AQChooseMergerSurvivorSheetController
- (id)initWithGameWindowController:(id)gameWindowController;
{
	if (![super init])
		return nil;
	
	_gameWindowController = [gameWindowController retain];
	_mergingHotels = nil;
	_mergeTile = nil;
	
	return self;
}

- (void)dealloc;
{
	[_gameWindowController release];
	_gameWindowController = nil;
	[_mergingHotels release];
	_mergingHotels = nil;
	[_mergeTile release];
	_mergeTile = nil;
	
	[super dealloc];
}


- (void)awakeFromNib;
{
	_originalHotelNamesMatrixFrame = [_hotelNamesMatrix frame];
	_originalChooseMergerSurvivorSheetFrame = [_chooseMergerSurvivorSheet contentRectForFrameRect:[_chooseMergerSurvivorSheet frame]];
}


- (IBAction)reconsider:(id)sender;
{
	[NSApp endSheet:_chooseMergerSurvivorSheet returnCode:1];
}

- (IBAction)chooseSurvivor:(id)sender;
{
	[NSApp endSheet:_chooseMergerSurvivorSheet returnCode:0];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	if (returnCode == 1) {
		[sheet orderOut:self];
		return;
	}
	
	[sheet orderOut:self];
	
	AQHotel *survivingHotel = nil;
	NSEnumerator *hotelEnumerator = [_mergingHotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject]) {
		if ([[(AQHotel *)curHotel name] isEqualToString:[[_hotelNamesMatrix selectedCell] title]]) {
			survivingHotel = curHotel;
			break;
		}
	}
	
	if (survivingHotel == nil) {
		NSLog(@"%s couldn't match the surviving hotel's name with a merging hotel", _cmd);
		return;
	}
	[_gameWindowController hotelSurvives:survivingHotel mergingHotels:_mergingHotels mergeTile:_mergeTile];
}

- (void)resizeAndPopulateMatricesWithMergingHotels:(NSArray *)mergingHotels potentialSurvivors:(NSArray *)potentialSurvivors mergeTile:(id)mergeTile;
{	
	[_mergingHotels release];
	_mergingHotels = [[NSArray arrayWithArray:mergingHotels] retain];
	[_mergeTile release];
	_mergeTile = [mergeTile retain];
	
	if (!_chooseMergerSurvivorSheet)
        [NSBundle loadNibNamed:@"ChooseMergerSurvivorSheet" owner:self];
	
	NSButtonCell *prototype = [[[NSButtonCell alloc] init] autorelease];
	[prototype setButtonType:NSRadioButton];
	
	[_hotelNamesMatrix setPrototype:prototype];
	[_hotelNamesMatrix setAllowsEmptySelection:NO];
	[_hotelNamesMatrix setIntercellSpacing:NSMakeSize(4.0f, 2.0f)];
	[_hotelNamesMatrix setCellSize:NSMakeSize(122.0f, 18.0f)];
	[_hotelNamesMatrix setMode:NSRadioModeMatrix];
	
	[_hotelNamesMatrix renewRows:[potentialSurvivors count] columns:1];
    
    int i;
	for (i = 0; i < [potentialSurvivors count]; ++i)
		[[_hotelNamesMatrix cellAtRow:i column:0] setTitle:[[potentialSurvivors objectAtIndex:i] name]];
	
	[_hotelNamesMatrix sizeToCells];
	
	float matrixHeightShouldBe = NSHeight([_hotelNamesMatrix frame]);
	
	// window resizing code adapted from code by Wil Shipley
	// retrieved 10 Apr 2008 from http://www.wilshipley.com/blog/2006/07/pimp-my-code-part-11-this-sheet-is.html
	NSRect sheetFrame = [_chooseMergerSurvivorSheet contentRectForFrameRect:[_chooseMergerSurvivorSheet frame]];

	float heightAdjustment = NSHeight(_originalHotelNamesMatrixFrame) - NSHeight([_hotelNamesMatrix frame]);
	sheetFrame.origin.y += heightAdjustment;
	sheetFrame.size.height = NSHeight(_originalChooseMergerSurvivorSheetFrame) - heightAdjustment;
	
	[_chooseMergerSurvivorSheet setFrame:[_chooseMergerSurvivorSheet frameRectForContentRect:sheetFrame] display:[_chooseMergerSurvivorSheet isVisible] animate:[_chooseMergerSurvivorSheet isVisible]];
	// end window resizing code
	
	// After resizing the sheet frame, sometimes the matrix magically shrinks. Let's fix that.
	NSRect matrixFrame = [_hotelNamesMatrix frame];
	if (NSHeight(matrixFrame) != matrixHeightShouldBe) {
		matrixFrame.size.height = matrixHeightShouldBe;
		[_hotelNamesMatrix setFrame:matrixFrame];
	}
}

- (void)showChooseMergerSurvivorSheet:(NSWindow *)window isNetworkGame:(BOOL)isNetworkGame;
{
	if (!_chooseMergerSurvivorSheet)
		[NSBundle loadNibNamed:@"ChooseMergerSurvivorSheet" owner:self];
	
	if (isNetworkGame) {
		[_reconsiderButton setTransparent:YES];
		[_reconsiderButton setEnabled:NO];
		[_chooseMergerSurvivorSheet makeFirstResponder:_chooseSurvivorButton];
	} else {
		[_reconsiderButton setEnabled:YES];
		[_reconsiderButton setTransparent:NO];
		[_chooseMergerSurvivorSheet makeFirstResponder:_reconsiderButton];
	}
	
	[NSApp beginSheet:_chooseMergerSurvivorSheet modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}
@end
