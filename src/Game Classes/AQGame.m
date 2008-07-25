// AQGame.m
//
// Created May 28, 2008 by nwaite

#import "AQGame.h"
#import "AQGameArrayController.h"
#import "AQTile.h"

@interface AQGame (Private)
- (id)_initGameWithArrayController:(id)arrayController;

- (void)_updateGameWindow;

- (NSArray *)_initialHotelsArray;
- (NSArray *)_hotelsWithPurchaseableShares;

- (void)_determineStartingOrder;
- (void)_drawTilesForEveryone;
- (void)_showPurchaseSharesSheetWithHotels:(NSArray *)hotels;
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

- (BOOL)isLocalGame;
{
	return (_associatedConnection == nil);
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


- (int)numberOfPlayers;
{
	return [_players count];
}

- (AQPlayer *)playerAtIndex:(int)index;
{
	if (index < 0 || index >= [self numberOfPlayers])
		return nil;
	
	return [_players objectAtIndex:index];
}

- (AQPlayer *)activePlayer;
{
	return [_players objectAtIndex:_activePlayerIndex];
}

- (int)activePlayerIndex;
{
	return _activePlayerIndex;
}

- (void)addPlayerNamed:(NSString *)playerName;
{
	[_players addObject:[AQPlayer playerWithName:playerName]];
	[_gameWindowController reloadScoreboard];
}

- (void)clearPlayers;
{
	[_players release];
	_players = [[NSMutableArray arrayWithCapacity:6] retain];
	[_gameWindowController reloadScoreboard];
}

- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames;
{
	int i;
	for (i = 0; i < [sharesPurchased count]; ++i) {
		if ([[sharesPurchased objectAtIndex:i] intValue] == 0)
			continue;
		
		[[self activePlayer] addSharesOfHotelNamed:[hotelNames objectAtIndex:i] numberOfShares:[[sharesPurchased objectAtIndex:i] intValue]];
	}
	
	[_gameWindowController reloadScoreboard];
	
	if ([self isLocalGame])
		[self endCurrentTurn];
}


- (void)tileClickedString:(NSString *)tileClickedString;
{
	if (![[self activePlayer] hasTileNamed:tileClickedString])
		return;
	
	if (_tilePlayed)
		return;
	
	[[_board tileOnBoardByString:tileClickedString] setState:AQTileNotInHotel];
	[_gameWindowController tilesChanged:[[self activePlayer] tiles]];
	[[self activePlayer] playedTileNamed:tileClickedString];
	[_gameWindowController updateTileRack:[[self activePlayer] tiles]];
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ played tile %@.", [[self activePlayer] name], tileClickedString]];
	
	_tilePlayed = YES;
	
	if ([self isLocalGame]) {
		NSArray *hotelsWithPurchaseableShares = [self _hotelsWithPurchaseableShares];
		if ([hotelsWithPurchaseableShares count] > 0)
			[self _showPurchaseSharesSheetWithHotels:hotelsWithPurchaseableShares];
		else
			[self endCurrentTurn];
	}
}


- (void)endCurrentTurn;
{
	[[self activePlayer] drewTile:[_board tileFromTileBag]];
	++_activePlayerIndex;
	if (_activePlayerIndex >= [_players count])
		_activePlayerIndex = 0;
	
	[_gameWindowController reloadScoreboard];
	[_gameWindowController updateTileRack:[[self activePlayer] tiles]];
	[_gameWindowController highlightTilesOnBoard:[[self activePlayer] tiles]];
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* It's %@'s turn.", [[self activePlayer] name]]];
	
	_tilePlayed = NO;
}

- (void)startGame;
{
	if ([self isLocalGame]) {
		[self _determineStartingOrder];
		
		[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* It's %@'s turn.", [[self activePlayer] name]]];
		
		[_gameWindowController reloadScoreboard];
		
		[self _drawTilesForEveryone];
		
		[_gameWindowController updateTileRack:[[self activePlayer] tiles]];
		[_gameWindowController highlightTilesOnBoard:[[self activePlayer] tiles]];
	}
}

- (void)endGame;
{
	if ([self isNetworkGame])
		[_associatedConnection leaveGame];
	
	[_arrayController removeGame:self];
}


// Passthrus
- (NSColor *)tileNotInHotelColor;
{
	return [AQHotel tileNotInHotelColor];
}

- (NSColor *)tilePlayableColor;
{
	return [AQHotel tilePlayableColor];
}

- (NSColor *)tileUnplayedColor;
{
	return [AQHotel tileUnplayedColor];
}

- (AQTile *)tileOnBoardByString:(NSString *)tileString;
{
	return [_board tileOnBoardByString:tileString];
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
	_hotels = [[self _initialHotelsArray] retain];
	_players = [[NSMutableArray arrayWithCapacity:6] retain];
	_localPlayerName = nil;

	return self;
}


- (void)_updateGameWindow;
{
	if ([self isNetworkGame])
		[_gameWindowController setWindowTitle:[NSString stringWithFormat:@"Acquire Game hosted at %@", [_associatedConnection connectedHostOrIPAddress]]];
	else {
		[_gameWindowController removeGameChatTabViewItem];
		[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* Welcome to Acquire!\n* Game started at %@.", [NSDate date]]];
	}
}


- (NSArray *)_initialHotelsArray;
{
	return [NSArray arrayWithObjects:[AQHotel sacksonHotel], [AQHotel zetaHotel], [AQHotel americaHotel], [AQHotel fusionHotel], [AQHotel hydraHotel], [AQHotel phoenixHotel], [AQHotel quantumHotel], nil];
}

- (NSArray *)_hotelsWithPurchaseableShares;
{
	NSLog(@"%s [hotels count]=%d", _cmd, [_hotels count]);
	NSMutableArray *hotelsWithPurchaseableShares = [NSMutableArray arrayWithCapacity:7];
	NSLog(@"%s hey", _cmd);
	NSEnumerator *hotelsEnumerator = [_hotels objectEnumerator];
	id curHotel;
	NSLog(@"%s about to start loop", _cmd);
	while (curHotel = [hotelsEnumerator nextObject]) {
		NSLog(@"%s loop start", _cmd);
		if ([curHotel isOnBoard] && [curHotel sharesInBank] > 0) {
			NSLog(@"%s if == YES", _cmd);
			[hotelsWithPurchaseableShares addObject:curHotel];
		}
	}
	
	NSLog(@"%s about to return", _cmd);
	
	return hotelsWithPurchaseableShares;
}


- (void)_determineStartingOrder;
{
	NSMutableArray *startingTiles = [NSMutableArray arrayWithCapacity:[self numberOfPlayers]];
	NSEnumerator *playerEnumerator = [_players objectEnumerator];
	id curPlayer;
	while (curPlayer = [playerEnumerator nextObject]) {
		[startingTiles addObject:[_board tileFromTileBag]];
		[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ drew initial tile %@.", [curPlayer name], [startingTiles lastObject]]];
		[[startingTiles lastObject] setState:AQTileNotInHotel];
	}
	[_gameWindowController tilesChanged:startingTiles];
	
	int topmostRow = 9;
	int leftmostColumn = 12;
	NSEnumerator *startingTilesEnumerator = [startingTiles objectEnumerator];
	id curStartingTile;
	while (curStartingTile = [startingTilesEnumerator nextObject]) {
		if ([curStartingTile rowInt] < topmostRow) {
			topmostRow = [curStartingTile rowInt];
			leftmostColumn = [curStartingTile column];
		} else if ([curStartingTile rowInt] == topmostRow && [curStartingTile column] < leftmostColumn)
			leftmostColumn = [curStartingTile column];
	}
	
	_activePlayerIndex = [startingTiles indexOfObject:[_board tileOnBoardAtColumn:leftmostColumn row:[_board rowStringFromInt:topmostRow]]];
}

- (void)_drawTilesForEveryone;
{
	NSEnumerator *playerEnumerator = [_players objectEnumerator];
	id curPlayer;
	int i;
	while (curPlayer = [playerEnumerator nextObject])
		for (i = 0; i < 6; ++i)
			[curPlayer drewTile:[_board tileFromTileBag]];
}

- (void)_showPurchaseSharesSheetWithHotels:(NSArray *)hotels;
{
	[_gameWindowController showPurchaseSharesSheetWithHotels:hotels availableCash:[[self activePlayer] cash]];
}
@end
