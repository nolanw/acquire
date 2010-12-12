// AQPurchaseSharesSheetController.m
//
// Created July 20, 2008 by nwaite

#import "AQPurchaseSharesSheetController.h"
#import "AQGameWindowController.h"
#import "AQHotel.h"

@interface AQPurchaseSharesSheetController (Private)
- (void)_updatePurchaseSharesButtonTitle;
@end

@implementation AQPurchaseSharesSheetController
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
	_originalPurchaseSharesSheetFrame = [_purchaseSharesSheet contentRectForFrameRect:[_purchaseSharesSheet frame]];
}


- (IBAction)letMeSeeTheBoard:(id)sender;
{
	[NSApp endSheet:_purchaseSharesSheet returnCode:1];
}

- (IBAction)purchaseShares:(id)sender;
{
	[NSApp endSheet:_purchaseSharesSheet returnCode:0];
}

- (void)didEndSheet:(NSWindow*)sheet
         returnCode:(int)returnCode
        contextInfo:(void*)contextInfo;
{
	if (returnCode == 1)
	{
		[sheet orderOut:self];
		[_gameWindowController purchaseSharesSheetDismissed];
		return;
	}
	
	NSMutableArray *hotelNames = [NSMutableArray arrayWithCapacity:7];
	NSMutableArray *sharesPurchased = [NSMutableArray arrayWithCapacity:7];
	int i;
	for (i = 0; i < [_hotelNamesMatrix numberOfRows]; ++i)
	{
		[hotelNames addObject:[[_hotels objectAtIndex:i] oldName]];
    int s = [[_shareNumbersAndSteppersMatrix cellAtRow:i column:0] intValue];
		[sharesPurchased addObject:[NSNumber numberWithInt:s]];
	}
	[sheet orderOut:self];
	[_gameWindowController purchaseShares:sharesPurchased
                          ofHotelsNamed:hotelNames
                                 sender:_purchaseSharesButton];
}

- (void)stepperChanged:(id)sender;
{
	int row = [[_shareNumbersAndSteppersMatrix selectedCell] tag];
	int newValue = [[_shareNumbersAndSteppersMatrix selectedCell] intValue];
	int oldValue = [[_shareNumbersAndSteppersMatrix cellAtRow:row column:0] intValue];
	
	if (newValue > oldValue) {
		if (_sharesBeingPurchased >= 3) {
			[[_shareNumbersAndSteppersMatrix selectedCell] setIntValue:oldValue];
			return;
		}
		
		if (([[_hotels objectAtIndex:row] sharePrice] + _cashSpent) > _availableCash) {
			[[_shareNumbersAndSteppersMatrix selectedCell] setIntValue:oldValue];
			return;
		}
		
		++_sharesBeingPurchased;
		_cashSpent += [[_hotels objectAtIndex:row] sharePrice];
		[[_shareNumbersAndSteppersMatrix cellAtRow:row column:0] setIntValue:newValue];
	} else {
		--_sharesBeingPurchased;
		_cashSpent -= [[_hotels objectAtIndex:row] sharePrice];
		[[_shareNumbersAndSteppersMatrix cellAtRow:row column:0] setIntValue:newValue];
	}
	
	[self _updatePurchaseSharesButtonTitle];
}


- (void)resizeAndPopulateMatricesWithHotels:(NSArray*)hotels
                              availableCash:(int)availableCash;
{
	if (!_purchaseSharesSheet)
        [NSBundle loadNibNamed:@"PurchaseSharesSheet" owner:self];
	
	[_hotels release];
	_hotels = [[NSArray arrayWithArray:hotels] retain];
	NSTextFieldCell *prototype = [[[NSTextFieldCell alloc] init] autorelease];
	
	[_hotelNamesMatrix setPrototype:prototype];
	[_hotelNamesMatrix setIntercellSpacing:NSMakeSize(4.0f, 2.0f)];
	[_hotelNamesMatrix setCellSize:NSMakeSize(139.0f, 22.0f)];
	[_hotelNamesMatrix setMode:NSTrackModeMatrix];
	
	[_hotelNamesMatrix renewRows:[hotels count] columns:1];
    
  int i;
	for (i = 0; i < [hotels count]; ++i)
	{
    NSTextFieldCell *cell = [_hotelNamesMatrix cellAtRow:i column:0];
    NSString *hotelName = [[hotels objectAtIndex:i] oldName];
		[cell setStringValue:hotelName];
		[cell setAlignment:NSRightTextAlignment];
	}
	
	[_hotelNamesMatrix sizeToCells];
	
	[_shareNumbersAndSteppersMatrix setPrototype:prototype];
	[_shareNumbersAndSteppersMatrix setIntercellSpacing:NSMakeSize(4.0f, 2.0f)];
	[_shareNumbersAndSteppersMatrix setCellSize:NSMakeSize(20.0f, 22.0f)];
	[_shareNumbersAndSteppersMatrix setMode:NSTrackModeMatrix];
	
	[_shareNumbersAndSteppersMatrix renewRows:[hotels count] columns:2];
	

	NSStepperCell *stepperCell;
	
	for (i = 0; i < [hotels count]; ++i)
	{
    NSTextFieldCell *cell = [_shareNumbersAndSteppersMatrix cellAtRow:i
                                                               column:0];
		[cell setType:NSTextCellType];
		[cell setIntValue:0];
		
		stepperCell = [[[NSStepperCell alloc] init] autorelease];
		[stepperCell setMaxValue:(double)[[hotels objectAtIndex:i] sharesInBank]];
		[stepperCell setMinValue:0.0];
		[stepperCell setIntValue:0];
		[stepperCell setIncrement:1.0];
		[stepperCell setAutorepeat:NO];
		[stepperCell setValueWraps:NO];
		[stepperCell setTarget:self];
		[stepperCell setAction:@selector(stepperChanged:)];
		[stepperCell setTag:i];
		[_shareNumbersAndSteppersMatrix putCell:stepperCell atRow:i column:1];
	}

	[_shareNumbersAndSteppersMatrix sizeToCells];
	
	_sharesBeingPurchased = 0;
	_availableCash = availableCash;
	_cashSpent = 0;
	
	float matrixHeightShouldBe = NSHeight([_hotelNamesMatrix frame]);
	
	// window resizing code adapted from code by Wil Shipley
	// retrieved 10 Apr 2008 from http://www.wilshipley.com/blog/2006/07/pimp-my-code-part-11-this-sheet-is.html
	NSRect sheetFrame = [_purchaseSharesSheet contentRectForFrameRect:[_purchaseSharesSheet frame]];

	float heightAdjustment = NSHeight(_originalHotelNamesMatrixFrame) - NSHeight([_hotelNamesMatrix frame]);
	sheetFrame.origin.y += heightAdjustment;
	
	sheetFrame.size.height = NSHeight(_originalPurchaseSharesSheetFrame) - heightAdjustment;
	
	[_purchaseSharesSheet setFrame:[_purchaseSharesSheet frameRectForContentRect:sheetFrame] display:[_purchaseSharesSheet isVisible] animate:[_purchaseSharesSheet isVisible]];
	// end window resizing code
	
	// After resizing the sheet frame, sometimes the matrix magically shrinks. Let's fix that.
	NSRect matrixFrame = [_hotelNamesMatrix frame];
	if (NSHeight(matrixFrame) != matrixHeightShouldBe) {
		matrixFrame.size.height = matrixHeightShouldBe;
		[_hotelNamesMatrix setFrame:matrixFrame];
	}
	
	matrixFrame = [_shareNumbersAndSteppersMatrix frame];
	if (NSHeight(matrixFrame) != matrixHeightShouldBe) {
		matrixFrame.size.height = matrixHeightShouldBe;
		[_shareNumbersAndSteppersMatrix setFrame:matrixFrame];
	}
	
	[self _updatePurchaseSharesButtonTitle];
}

- (void)showPurchaseSharesSheet:(NSWindow *)window;
{
	if (!_purchaseSharesSheet)
        [NSBundle loadNibNamed:@"PurchaseSharesSheet" owner:self];
	
	[_purchaseSharesSheet makeFirstResponder:_letMeSeeTheBoardButton];
	
	[NSApp beginSheet:_purchaseSharesSheet modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}
@end

@implementation AQPurchaseSharesSheetController (Private)
- (void)_updatePurchaseSharesButtonTitle;
{
	int i;
	for (i = 0; i < [_shareNumbersAndSteppersMatrix numberOfRows]; ++i) {
		if ([[_shareNumbersAndSteppersMatrix cellAtRow:i column:1] intValue] != 0) {
			[_purchaseSharesButton setTitle:NSLocalizedStringFromTable(@"Purchase Shares", @"Acquire", @"A button that, when clicked, purchases shares in the amounts specified.")];
			return;
		}
	}
	
	[_purchaseSharesButton setTitle:NSLocalizedStringFromTable(@"End Turn", @"Acquire", @"A button that, when clicked, ends the player's turn.")];
}
@end
