// AQGame.h
//
// Created May 28, 2008 by nwaite

#import "AQGame.h"
#import "AQGameArrayController.h"

@interface AQGame (Private)
- (NSArray *)_initialHotelsArray;
@end

@implementation AQGame
- (id)initWithArrayController:(id)arrayController;
{
	if (![super init])
		return nil;
	
	_arrayController = [arrayController retain];
	_gameWindowController = nil;
	
	_board = [[AQBoard alloc] init];
	_hotels = [self _initialHotelsArray];
	_players = [NSArray array];

	return self;
}

- (void)dealloc;
{
	[_arrayController release];
	[_gameWindowController release];
	_gameWindowController = nil;
	
	[super dealloc];
}


- (void)loadGameWindow;
{
	if (_gameWindowController != nil) {
		NSLog(@"%s GameWindow already loaded", _cmd);
		return;
	}
	
	if (![NSBundle loadNibNamed:@"GameWindow" owner:self]) {
		NSLog(@"%s failed to load GameWindow.nib", _cmd);
	}
}

- (void)bringGameWindowToFront;
{
	[_gameWindowController bringGameWindowToFront];
}


- (void)addPlayerNamed:(NSString *)playerName;
{
	NSArray *newPlayerArray = [_players arrayByAddingObject:[AQPlayer playerWithName:playerName]];
	[_players release];
	_players = [newPlayerArray retain];
}


- (void)endGame:(id)sender;
{
	[_arrayController removeGame:self];
}


// Allow objects in loaded nibs to say hi
- (void)registerGameWindowController:(AQGameWindowController *)gameWindowController;
{
	if (_gameWindowController != nil) {
		NSLog(@"%s another GameWindowController is already registered", _cmd);
		return;
	}

	_gameWindowController = gameWindowController;
}
@end

@implementation AQGame (Private)
- (NSArray *)_initialHotelsArray;
{
	return [NSArray arrayWithObjects:[AQHotel sacksonHotel], [AQHotel zetaHotel], [AQHotel americaHotel], [AQHotel fusionHotel], [AQHotel hydraHotel], [AQHotel phoenixHotel], [AQHotel quantumHotel], nil];
}
@end
