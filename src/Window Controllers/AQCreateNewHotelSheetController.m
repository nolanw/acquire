// AQCreateNewHotelSheetController.m
//
// Created August 02, 2008 by nwaite

#import "AQCreateNewHotelSheetController.h"
#import "AQGameWindowController.h"
#import "AQHotel.h"

@implementation AQCreateNewHotelSheetController
- (id)initWithGameWindowController:(id)gameWindowController;
{
	if (![super init])
		return nil;
	
	_gameWindowController = [gameWindowController retain];
	_hotels = nil;
	
	return self;
}

- (void)dealloc;
{
	[_gameWindowController release];
	_gameWindowController = nil;
	[_hotels release];
	_hotels = nil;
	
	[super dealloc];
}


- (void)awakeFromNib;
{
	_originalHotelNamesMatrixFrame = [_hotelNamesMatrix frame];
	_originalCreateNewHotelSheetFrame = [_createNewHotelSheet contentRectForFrameRect:[_createNewHotelSheet frame]];
}


- (IBAction)letMeThinkAboutIt:(id)sender;
{
	[NSApp endSheet:_createNewHotelSheet returnCode:1];
}

- (IBAction)createNewHotel:(id)sender;
{
	[NSApp endSheet:_createNewHotelSheet returnCode:0];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	if (returnCode == 1) {
		[sheet orderOut:self];
		return;
	}
	
	[sheet orderOut:self];
	
	[(AQGameWindowController *)_gameWindowController createHotelNamed:[[_hotelNamesMatrix selectedCell] title]];
}

- (void)resizeAndPopulateMatricesWithHotels:(NSArray *)hotels;
{
	if (!_createNewHotelSheet)
        [NSBundle loadNibNamed:@"CreateNewHotelSheet" owner:self];
	
	[_hotels release];
	_hotels = [[NSArray arrayWithArray:hotels] retain];
	
	NSButtonCell *prototype = [[[NSButtonCell alloc] init] autorelease];
	[prototype setButtonType:NSRadioButton];
	
	[_hotelNamesMatrix setPrototype:prototype];
	[_hotelNamesMatrix setAllowsEmptySelection:NO];
	[_hotelNamesMatrix setIntercellSpacing:NSMakeSize(4.0f, 2.0f)];
	[_hotelNamesMatrix setCellSize:NSMakeSize(122.0f, 18.0f)];
	[_hotelNamesMatrix setMode:NSRadioModeMatrix];
	
	[_hotelNamesMatrix renewRows:[hotels count] columns:1];
    
    int i;
	for (i = 0; i < [hotels count]; ++i)
		[[_hotelNamesMatrix cellAtRow:i column:0] setTitle:[[hotels objectAtIndex:i] name]];
	
	[_hotelNamesMatrix sizeToCells];
	
	float matrixHeightShouldBe = NSHeight([_hotelNamesMatrix frame]);
	
	// window resizing code adapted from code by Wil Shipley
	// retrieved 10 Apr 2008 from http://www.wilshipley.com/blog/2006/07/pimp-my-code-part-11-this-sheet-is.html
	NSRect sheetFrame = [_createNewHotelSheet contentRectForFrameRect:[_createNewHotelSheet frame]];

	float heightAdjustment = NSHeight(_originalHotelNamesMatrixFrame) - NSHeight([_hotelNamesMatrix frame]);
	sheetFrame.origin.y += heightAdjustment;
	sheetFrame.size.height = NSHeight(_originalCreateNewHotelSheetFrame) - heightAdjustment;
	
	[_createNewHotelSheet setFrame:[_createNewHotelSheet frameRectForContentRect:sheetFrame] display:[_createNewHotelSheet isVisible] animate:[_createNewHotelSheet isVisible]];
	// end window resizing code
	
	// After resizing the sheet frame, sometimes the matrix magically shrinks. Let's fix that.
	NSRect matrixFrame = [_hotelNamesMatrix frame];
	if (NSHeight(matrixFrame) != matrixHeightShouldBe) {
		matrixFrame.size.height = matrixHeightShouldBe;
		[_hotelNamesMatrix setFrame:matrixFrame];
	}
}

- (void)showCreateNewHotelSheet:(NSWindow *)window;
{
	if (!_createNewHotelSheet)
        [NSBundle loadNibNamed:@"CreateNewHotelSheet" owner:self];
	
	[NSApp beginSheet:_createNewHotelSheet modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}
@end
