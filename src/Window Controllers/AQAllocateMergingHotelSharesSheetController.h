// AQAllocateMergingHotelSharesSheetController.h
// AllocateMergingHotelSharesSheetController handles the Allocate Merging Hotel Shares Sheet and tells the Game Window Controller what's up.
//
// Created August 04, 2008 by nwaite

#import "AQHotel.h"
#import "AQPlayer.h"

@class AQGameWindowController;

@interface AQAllocateMergingHotelSharesSheetController : NSObject
{
	IBOutlet NSWindow		*_allocateMergingHotelSharesSheet;
	IBOutlet NSTextField	*_playerNameTextField;
	IBOutlet NSTextField	*_mergingHotelNameTextField;
	IBOutlet NSTextField	*_survivingHotelNameTextField;
	IBOutlet NSTextField	*_sharesSoldTextField;
	IBOutlet NSStepper		*_sharesSoldStepper;
	IBOutlet NSTextField	*_sharesTradedTextField;
	IBOutlet NSStepper		*_sharesTradedStepper;
	IBOutlet NSTextField	*_sharesKeptInMergingHotelTextField;
	IBOutlet NSButton		*_allocateButton;
	
	AQGameWindowController *_gameWindowController;
	id		_mergingHotel;
	id		_survivingHotel;
	id		_player;
	int		_sharePrice;
	double	_sharesKeptInMergingHotel;
	double	_sharesSold;
	double	_sharesTraded;
}

- (id)initWithGameWindowController:(AQGameWindowController *)gameWindowController;
- (void)dealloc;

- (IBAction)allocate:(id)sender;

- (void)sharesSoldStepperChanged:(id)sender;
- (void)sharesTradedStepperChanged:(id)sender;

- (void)showAllocateMergingHotelSharesSheet:(NSWindow *)window forMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player sharePrice:(int)sharePrice;
@end
