// AQPurchaseSharesSheetController.m
//
// Created July 20, 2008 by nwaite

#import "AQPurchaseSharesSheetController.h"
#import "AQGameWindowController.h"

@implementation AQPurchaseSharesSheetController
- (id)initWithGameWindowController:(id)gameWindowController;
{
	if (![super init])
		return nil;
	
	_gameWindowController = [gameWindowController retain];
	
	return self;
}

- (void)dealloc;
{
	[_gameWindowController release];
	_gameWindowController = nil;
	
	[super dealloc];
}


- (void)awakeFromNib;
{
	_originalHotelNamesMatrixFrame = [_hotelNamesMatrix frame];
	_originalPurchaseSharesSheetFrame = [_purchaseSharesSheet contentRectForFrameRect:[_purchaseSharesSheet frame]];
}


- (IBAction)giveMeAMinute:(id)sender;
{
	[NSApp endSheet:_purchaseSharesSheet returnCode:1];
}

- (IBAction)purchaseShares:(id)sender;
{
	[NSApp endSheet:_purchaseSharesSheet returnCode:0];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	if (returnCode == 1) {
		[sheet orderOut:self];
		return;
	}
	
	NSMutableArray *hotelNames = [NSMutableArray arrayWithCapacity:7];
	NSMutableArray *sharesPurchased = [NSMutableArray arrayWithCapacity:7];
	int i;
	for (i = 0; i < [_hotelNamesMatrix numberOfRows]; ++i) {
		[hotelNames addObject:[[_hotelNamesMatrix cellAtRow:i column:0] title]];
		[sharesPurchased addObject:[NSNumber numberWithInt:[[_shareNumbersAndSteppersMatrix cellAtRow:i column:0] intValue]]];
	}
	
	[(AQGameWindowController *)_gameWindowController purchaseShares:sharesPurchased ofHotelsNamed:hotelNames];
	
	[sheet orderOut:self];
}


- (void)resizeAndPopulateMatricesWithHotels:(NSArray *)hotels availableCash:(int)availableCash;
{
	
}

- (void)showPurchaseSharesSheet:(NSWindow *)window;
{
	if (!_purchaseSharesSheet)
        [NSBundle loadNibNamed:@"PurchaseSharesSheet" owner:self];
	
	[NSApp beginSheet:_purchaseSharesSheet modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}
@end
