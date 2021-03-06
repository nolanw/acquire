// AQAllocateMergingHotelSharesSheetController.m
//
// Created August 04, 2008 by nwaite

#import "AQAllocateMergingHotelSharesSheetController.h"
#import "AQGameWindowController.h"

@interface AQAllocateMergingHotelSharesSheetController (Private)
- (void)_updateTextFieldsAndSteppers;
@end

@implementation AQAllocateMergingHotelSharesSheetController
- (id)initWithGameWindowController:(AQGameWindowController *)gameWindowController;
{
	if (![super init])
		return nil;
	
	_gameWindowController = [gameWindowController retain];
	
	_mergingHotel = nil;
	_survivingHotel = nil;
	_player = nil;

	return self;
}

- (void)dealloc;
{
	[_gameWindowController release];
	_gameWindowController = nil;
	[_mergingHotel release];
	_mergingHotel = nil;
	[_survivingHotel release];
	_survivingHotel = nil;
	[_player release];
	_player = nil;
	
	[super dealloc];
}


- (IBAction)allocate:(id)sender;
{
	[_gameWindowController mergerSharesSold:(int)_sharesSold
                             sharesTraded:((int)_sharesTraded * 2)];
	[NSApp stopModal];
}


- (void)sharesSoldStepperChanged:(id)sender;
{
	double newValue = [_sharesSoldStepper doubleValue];
	if (newValue == _sharesSold)
		return;
	
	if (newValue > _sharesSold) {
		if (_sharesKeptInMergingHotel + _sharesTraded < 1.0) {
			[self _updateTextFieldsAndSteppers];
			return;
		}
		_sharesSold += 1.0;
		if (_sharesKeptInMergingHotel > 0.0)
			_sharesKeptInMergingHotel -= 1.0;
		else {
			_sharesTraded -= 2.0;
			_sharesKeptInMergingHotel += 1.0;
		}
	} else {
		if (_sharesSold < 1.0) {
			[self _updateTextFieldsAndSteppers];
			return;
		}
		_sharesSold -= 1.0;
		_sharesKeptInMergingHotel += 1.0;
	}
	
	[self _updateTextFieldsAndSteppers];
}

- (void)sharesTradedStepperChanged:(id)sender;
{
	double newValue = [_sharesTradedStepper doubleValue];
	if (newValue > _sharesTraded) {
		if (_sharesKeptInMergingHotel + _sharesSold < 2.0) {
			[self _updateTextFieldsAndSteppers];
			return;
		}
		if ((int)newValue > [_survivingHotel sharesInBank]) {
			[self _updateTextFieldsAndSteppers];
			return;
		}
		_sharesTraded += 1.0;
		if (_sharesKeptInMergingHotel >= 2.0)
			_sharesKeptInMergingHotel -= 2.0;
		else if (_sharesKeptInMergingHotel == 1.0) {
			_sharesKeptInMergingHotel -= 1.0;
			_sharesSold -= 1.0;
		}
		else
			_sharesSold -= 2.0;
	} else {
		if (_sharesTraded < 1.0) {
			[self _updateTextFieldsAndSteppers];
			return;
		}
		_sharesTraded -= 1.0;
		_sharesKeptInMergingHotel += 2.0;
	}
	
	[self _updateTextFieldsAndSteppers];
}


- (void)showAllocateMergingHotelSharesSheet:(NSWindow *)window forMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player sharePrice:(int)sharePrice;
{
	if (window == nil || mergingHotel == nil || survivingHotel == nil || player == nil)
		return;
	
	_sharesKeptInMergingHotel = (double)[player numberOfSharesOfHotelNamed:[mergingHotel name]];
	_sharesSold = 0.0;
	_sharesTraded = 0.0;
	
	if (!_allocateMergingHotelSharesSheet)
        [NSBundle loadNibNamed:@"AllocateMergingHotelSharesSheet" owner:self];
	
	[_mergingHotel release];
	_mergingHotel = [mergingHotel retain];
	[_survivingHotel release];
	_survivingHotel = [survivingHotel retain];
	[_player release];
	_player = [player retain];
	_sharePrice = sharePrice;
	
	[_playerNameTextField setStringValue:[player name]];
	[_mergingHotelNameTextField setStringValue:[mergingHotel oldName]];
	[_survivingHotelNameTextField setStringValue:[survivingHotel oldName]];
	[_sharesSoldTextField takeIntValueFrom:_sharesSoldStepper];
	[_sharesSoldStepper setMinValue:0.0];
	[_sharesSoldStepper setMaxValue:_sharesKeptInMergingHotel];
	[_sharesSoldStepper setIntValue:0];
	[_sharesSoldStepper setIncrement:1.0];
	[_sharesSoldStepper setAutorepeat:NO];
	[_sharesSoldStepper setValueWraps:NO];
	[_sharesSoldStepper setTarget:self];
	[_sharesSoldStepper setAction:@selector(sharesSoldStepperChanged:)];
	[_sharesTradedStepper setMinValue:0.0];
	[_sharesTradedStepper setMaxValue:_sharesKeptInMergingHotel];
	[_sharesTradedStepper setIntValue:0];
	[_sharesTradedStepper setIncrement:1.0];
	[_sharesTradedStepper setAutorepeat:NO];
	[_sharesTradedStepper setValueWraps:NO];
	[_sharesTradedStepper setTarget:self];
	[_sharesTradedStepper setAction:@selector(sharesTradedStepperChanged:)];
	
	[self _updateTextFieldsAndSteppers];
	
	[_allocateMergingHotelSharesSheet makeFirstResponder:_allocateButton];
	
	[NSApp beginSheet:_allocateMergingHotelSharesSheet modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[NSApp runModalForWindow:_allocateMergingHotelSharesSheet];
	
	[NSApp endSheet:_allocateMergingHotelSharesSheet];
	[_allocateMergingHotelSharesSheet orderOut:self];
}
@end

@implementation AQAllocateMergingHotelSharesSheetController (Private)
- (void)_updateTextFieldsAndSteppers;
{
	[_sharesKeptInMergingHotelTextField setIntValue:(int)_sharesKeptInMergingHotel];
	[_sharesSoldTextField setIntValue:(int)_sharesSold];
	[_sharesTradedTextField setIntValue:(int)_sharesTraded];
	[_sharesSoldStepper setDoubleValue:_sharesSold];
	[_sharesTradedStepper setDoubleValue:_sharesTraded];
}
@end
