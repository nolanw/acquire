// AQCreateNewHotelSheetController.h
// CreateNewHotelSheetController handles the Create New Hotel Sheet and tells the Game Window Controller what's up.
//
// Created August 02, 2008 by nwaite

@interface AQCreateNewHotelSheetController : NSObject
{
	IBOutlet NSWindow	*_createNewHotelSheet;
	IBOutlet NSMatrix	*_hotelNamesMatrix;
	IBOutlet NSButton	*_reconsiderButton;
	IBOutlet NSButton	*_createHotelButton;
	
	id		_gameWindowController;
	
	id _tile;
	
	NSRect	_originalHotelNamesMatrixFrame;
    NSRect	_originalCreateNewHotelSheetFrame;
}

- (id)initWithGameWindowController:(id)gameWindowController;
- (void)dealloc;

- (void)awakeFromNib;

- (IBAction)reconsider:(id)sender;
- (IBAction)createNewHotel:(id)sender;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)resizeAndPopulateMatricesWithHotels:(NSArray *)hotels tile:(id)tile;
- (void)showCreateNewHotelSheet:(NSWindow *)window;
@end
