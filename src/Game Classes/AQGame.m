// AQGame.h
//
// Created May 28, 2008 by nwaite

#import "AQGame.h"
#import "AQGameArrayController.h"

@interface AQGame (Private)
- (id)_initGameWithArrayController:(id)arrayController;

- (void)_updateGameWindow;

- (NSArray *)_initialHotelsArray;
@end

@implementation AQGame
- (id)initNetworkGameWithArrayController:(id)arrayController associatedConnection:(AQConnectionController *)associatedConnection;
{
	if (![self _initGameWithArrayController:arrayController])
		return nil;
	
	_associatedConnection = [associatedConnection retain];

	return self;
}

- (id)initLocalGameWithArrayController:(id)arrayController;
{
	if (![self _initGameWithArrayController:arrayController])
		return nil;
	
	_associatedConnection = nil;
	
	return self;
}

- (void)dealloc;
{
	[_arrayController release];
	_arrayController = nil;
	[_gameWindowController release];
	_gameWindowController = nil;
	[_associatedConnection release];
	_associatedConnection = nil;
	
	[super dealloc];
}


- (BOOL)isNetworkGame;
{
	return (_associatedConnection != nil);
}

- (NSString *)localPlayerName;
{
	return _localPlayerName;
}

- (void)setLocalPlayerName:(NSString *)localPlayerName;
{
	[_localPlayerName release];
	_localPlayerName = [localPlayerName copy];
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

- (void)clearPlayers;
{
	[_players release];
	_players = [NSArray array];
}


- (void)endGame;
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
	
	[self _updateGameWindow];
}
@end

@implementation AQGame (Private)
- (id)_initGameWithArrayController:(id)arrayController;
{
	if (![super init])
		return nil;
	
	_arrayController = [arrayController retain];
	_gameWindowController = nil;
	
	_board = [[AQBoard alloc] init];
	_hotels = [self _initialHotelsArray];
	_players = [NSArray array];
	_localPlayerName = nil;

	return self;
}


- (void)_updateGameWindow;
{
	if ([self isNetworkGame])
		[_gameWindowController setWindowTitle:[NSString stringWithFormat:@"Acquire Game hosted at %@", [_associatedConnection connectedHostOrIPAddress]]];
	else
		[_gameWindowController removeGameChatTabViewItem];
}


- (NSArray *)_initialHotelsArray;
{
	return [NSArray arrayWithObjects:[AQHotel sacksonHotel], [AQHotel zetaHotel], [AQHotel americaHotel], [AQHotel fusionHotel], [AQHotel hydraHotel], [AQHotel phoenixHotel], [AQHotel quantumHotel], nil];
}
@end
