// AQPurchaseSharesSheetController.h
// PurchaseSharesSheetController handles the Purchase Shares Sheet and tells the Game Window Controller what's up.
//
// Created July 20, 2008 by nwaite

@interface AQPurchaseSharesSheetController : NSObject
{
	IBOutlet NSWindow	*_purchaseSharesSheet;
	IBOutlet NSMatrix	*_hotelNamesMatrix;
	IBOutlet NSMatrix	*_shareNumbersAndSteppersMatrix;
	IBOutlet NSButton	*_letMeSeeTheBoardButton;
	IBOutlet NSButton	*_purchaseSharesButton;
	
	id		_gameWindowController;
	int		_availableCash;
	int		_cashSpent;
	int		_sharesBeingPurchased;
	NSArray	*_hotels;
	
	NSRect	_originalHotelNamesMatrixFrame;
    NSRect	_originalPurchaseSharesSheetFrame;
}

- (id)initWithGameWindowController:(id)gameWindowController;
- (void)dealloc;

- (void)awakeFromNib;

- (IBAction)letMeSeeTheBoard:(id)sender;
- (IBAction)purchaseShares:(id)sender;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)stepperChanged:(id)sender;

- (void)resizeAndPopulateMatricesWithHotels:(NSArray *)hotels availableCash:(int)availableCash;
- (void)showPurchaseSharesSheet:(NSWindow *)window;
@end
