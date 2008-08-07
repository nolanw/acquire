// AQChooseMergerSurvivorSheetController.h
// ChooseMergerSurviviorSheetController handles the Choose Merger Survivor Sheet and tells the Game Window Controller what's up.
//
// Created August 07, 2008 by nwaite

#import "AQHotel.h"

@interface AQChooseMergerSurvivorSheetController : NSObject
{
	IBOutlet NSWindow	*_chooseMergerSurvivorSheet;
	IBOutlet NSMatrix	*_hotelNamesMatrix;
	
	id		_gameWindowController;
	
	NSArray	*_mergingHotels;
	id 		_mergeTile;
	
	NSRect	_originalHotelNamesMatrixFrame;
    NSRect	_originalChooseMergerSurvivorSheetFrame;
}

- (id)initWithGameWindowController:(id)gameWindowController;
- (void)dealloc;

- (void)awakeFromNib;

- (IBAction)reconsider:(id)sender;
- (IBAction)chooseSurvivor:(id)sender;
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)resizeAndPopulateMatricesWithMergingHotels:(NSArray *)mergingHotels potentialSurvivors:(NSArray *)potentialSurvivors mergeTile:(id)mergeTile;
- (void)showChooseMergerSurvivorSheet:(NSWindow *)window;
@end
