// AQAllocateMergingHotelSharesSheetController.m
//
// Created August 04, 2008 by nwaite

#import "AQGameWindowController.h"

@implementation AQAllocateMergingHotelSharesSheetController
- (id)initWithGameWindowController:(id)gameWindowController;
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
	[NSApp endSheet:_allocateMergingHotelSharesSheet returnCode:0];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	[sheet orderOut:self];
	
	[(AQGameWindowController *)_gameWindowController sellSharesOfHotel:_mergingHotel numberOfShares:[_sharesSoldStepper intValue] byPlayer:_player];
	[(AQGameWindowController *)_gameWindowController tradeSharesOfHotel:_mergingHotel forSharesInHotel:_survivingHotel numberOfShares:[_sharesTradedStepper intValue] byPlayer:_player];
}


- (void)sharesSoldStepperChanged:(id)sender;
{
	int oldValue = [_sharesSoldTextField intValue];
	int newValue = [sender intValue];
	
	if (newValue > oldValue) {
		[_sharesKeptInMergingHotelTextField setIntValue:([_sharesKeptInMergingHotelTextField intValue] - 1)];
		int newMaximumTraded = [_player numberOfSharesOfHotelNamed:[_mergingHotel name]] - newValue;
		newMaximumTraded -= newMaximumTraded % 2;
		[_sharesTradedStepper setMaxValue:newMaximumTraded];
	} else {
		[_sharesKeptInMergingHotelTextField setIntValue:([_sharesKeptInMergingHotelTextField intValue] + 1)];
		int newMaximumTraded = [_player numberOfSharesOfHotelNamed:[_mergingHotel name]] - newValue;
		newMaximumTraded -= newMaximumTraded % 2;
		[_sharesTradedStepper setMaxValue:newMaximumTraded];
	}
}

- (void)sharesTradedStepperChanged:(id)sender;
{
	int oldValue = [_sharesTradedTextField intValue];
	int newValue = [sender intValue];
	
	if (newValue > oldValue)
		[_sharesKeptInMergingHotelTextField setIntValue:([_sharesKeptInMergingHotelTextField intValue] - 2)];
	else
		[_sharesKeptInMergingHotelTextField setIntValue:([_sharesKeptInMergingHotelTextField intValue] + 2)];
}


- (void)showAllocateMergingHotelSharesSheet:(NSWindow *)window forMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player;
{
	if (!_allocateMergingHotelSharesSheet)
        [NSBundle loadNibNamed:@"AllocateMergingHotelSharesSheet" owner:self];
	
	[_mergingHotel release];
	_mergingHotel = mergingHotel;
	[_survivingHotel release];
	_survivingHotel = survivingHotel;
	[_player release];
	_player = player;
	
	[_playerNameTextField setStringValue:[player name]];
	[_mergingHotelNameTextField setStringValue:[mergingHotel name]];
	[_mergingHotelSharePriceTextField setStringValue:[NSString stringWithFormat:@"$%d", [mergingHotel sharePrice]]];
	[_survivingHotelNameTextField setStringValue:[survivingHotel name]];
	[_sharesSoldTextField takeIntValueFrom:_sharesSoldStepper];
	[_sharesSoldStepper setMinValue:0.0];
	[_sharesSoldStepper setMaxValue:(float)[player numberOfSharesOfHotelNamed:[mergingHotel name]]];
	[_sharesSoldStepper setTarget:self];
	[_sharesSoldStepper setAction:@selector(sharesSoldtepperChanged:)];
	[_sharesTradedTextField takeIntValueFrom:_sharesTradedStepper];
	[_sharesTradedStepper setMinValue:0.0];
	[_sharesTradedStepper setMaxValue:(float)([player numberOfSharesOfHotelNamed:[mergingHotel name]] - [player numberOfSharesOfHotelNamed:[mergingHotel name]] % 2)];
	[_sharesTradedStepper setTarget:self];
	[_sharesTradedStepper setAction:@selector(sharesTradedStepperChanged:)];
	[_sharesKeptInMergingHotelTextField setIntValue:[player numberOfSharesOfHotelNamed:[mergingHotel name]]];
	
	[NSApp beginSheet:_allocateMergingHotelSharesSheet modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
}
@end
