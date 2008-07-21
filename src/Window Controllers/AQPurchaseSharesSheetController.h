// AQPurchaseSharesSheetController.h
// PurchaseSharesSheetController handles the Purchase Shares Sheet and tells the Game Window Controller what's up.
//
// Created July 20, 2008 by nwaite

@interface AQPurchaseSharesSheetController : NSObject
{
	IBOutlet NSWindow	*_purchaseSharesSheet;
	IBOutlet NSMatrix	*_hotelNamesMatrix;
	IBOutlet NSMatrix	*_shareNumbersAndSteppersMatrix;
	
	id	_gameWindowController;
}

- (id)initWithGameWindowController:(id)gameWindowController;
- (void)dealloc;

- (IBAction)giveMeAMinute:(id)sender;
- (IBAction)purchaseShares:(id)sender;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)resizeAndPopulateMatricesWithHotelNames:(NSArray *)hotelNames availableSharesPerHotel:(NSArray *)availableShares availableCash:(int)availableCash;
- (void)showPurchaseSharesSheet:(NSWindow *)window;
@end
