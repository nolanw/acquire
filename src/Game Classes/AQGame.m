// AQGame.m
//
// Created May 28, 2008 by nwaite

#ifndef DEBUG_ALLOW_PLAYING_OF_ANY_TILE
#define DEBUG_ALLOW_PLAYING_OF_ANY_TILE 0
#endif

#import "AQGame.h"
#import "AQGameArrayController.h"

@interface AQGame (Private)
- (id)_initGameWithArrayController:(id)arrayController;

- (void)_updateGameWindow;

- (NSArray *)_initialHotelsArray;
- (NSArray *)_hotelsWithPurchaseableShares;

- (void)_determineStartingOrder;
- (void)_drawTilesForEveryone;
- (void)_showPurchaseSharesSheetWithHotels:(NSArray *)hotels;
- (void)_showCreateNewHotelSheetWithHotels:(NSArray *)hotels tile:(AQTile *)tile;
- (void)_showChooseMergerSurvivorSheetWithMergingHotels:(NSArray *)mergingHotels potentialSurvivors:(NSArray *)potentialSurvivors mergeTile:(AQTile *)mergeTile;
- (void)_showAllocateMergingHotelSharesSheetForMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player sharePrice:(int)sharePrice;

- (NSArray *)_hotelsAdjacentToTile:(AQTile *)tile;
- (NSArray *)_hotelsNotOnBoard;
- (NSArray *)_hotelsOnBoard;
- (void)_tilePlayed:(AQTile *)tile;
- (void)_checkTileRacksForUnplayableTiles;
- (void)_showPurchaseSharesSheetIfNeededOrAdvanceTurn;
- (void)_mergerHappeningAtTile:(AQTile *)tile;
- (void)_payShareholderBonusesForHotels:(NSArray *)hotels;
- (void)_payPlayersForSharesInHotels:(NSArray *)hotels;
- (NSArray *)_winningPlayers;
- (BOOL)_gameCanEnd;
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
	if (_gameWindowController == nil)
		_gameWindowController = [[AQGameWindowController alloc] initWithGame:self];
	
	[self _updateGameWindow];
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

- (AQPlayer *)localPlayer;
{
	if ([self isLocalGame])
		return nil;
	
	NSEnumerator *playerEnumerator = [_players objectEnumerator];
	id curPlayer;
	while (curPlayer = [playerEnumerator nextObject])
		if ([[curPlayer name] isEqualToString:_localPlayerName])
			return curPlayer;
	
	return nil;
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

- (AQHotel *)hotelNamed:(NSString *)hotelName;
{
	NSEnumerator *hotelEnumerator = [_hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject])
		if ([[curHotel name] isEqualToString:hotelName])
			return curHotel;
	
	return nil;
}

- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames;
{
	NSMutableString *purchaseLog = [NSMutableString stringWithFormat:@"* %@ purchased:", [[self activePlayer] name]];
	
	int hotelsWithNoSharesPurchased = 0;
	int i;
	for (i = 0; i < [sharesPurchased count]; ++i) {
		if ([[sharesPurchased objectAtIndex:i] intValue] == 0) {
			++hotelsWithNoSharesPurchased;
			continue;
		}
		
		[[self activePlayer] addSharesOfHotelNamed:[hotelNames objectAtIndex:i] numberOfShares:[[sharesPurchased objectAtIndex:i] intValue]];
		[[self activePlayer] subtractCash:([[sharesPurchased objectAtIndex:i] intValue] * [[self hotelNamed:[hotelNames objectAtIndex:i]] sharePrice])];
		[purchaseLog appendString:[NSString stringWithFormat:@"\n\t• %d shares of %@ at $%d each.", [[sharesPurchased objectAtIndex:i] intValue], [hotelNames objectAtIndex:i], [[self hotelNamed:[hotelNames objectAtIndex:i]] sharePrice]]];
	}
	
	[_gameWindowController reloadScoreboard];
	
	if (hotelsWithNoSharesPurchased == [hotelNames count])
		[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ purchased no shares.", [[self activePlayer] name]]];
	else
		[_gameWindowController incomingGameLogEntry:purchaseLog];
	
	if ([self isLocalGame]) {
		if ([self _gameCanEnd]) {
			[_gameWindowController showEndGameButton];
			[_gameWindowController showEndCurrentTurnButton];
		} else {
			[self endCurrentTurn];
		}
	}
}

- (int)sharesAvailableOfHotelNamed:(NSString *)hotelName;
{
	return [(AQHotel *)[self hotelNamed:hotelName] sharesInBank];
}


- (void)tileClickedString:(NSString *)tileClickedString;
{
	NSLog(@"%s called", _cmd);
	if ([self isNetworkGame] && [self localPlayer] != [self activePlayer])
		return;
	
	if (![[self activePlayer] hasTileNamed:tileClickedString] && !DEBUG_ALLOW_PLAYING_OF_ANY_TILE)
		return;
	
	if (_tilePlayedThisTurn)
		return;
	
	if ([self isNetworkGame])
		return;
	
	NSLog(@"%s continuing execution", _cmd);
	
	AQTile *clickedTile = [_board tileOnBoardByString:tileClickedString];
	if ([self playedTileCreatesNewHotel:clickedTile]) {
		NSLog(@"%s creates new hotel", _cmd);
		NSArray *hotelsNotOnBoard = [self _hotelsNotOnBoard];
		if ([hotelsNotOnBoard count] == 0) {
			NSLog(@"%s all hotels on board", _cmd);
			return;
		}
		
		[self _showCreateNewHotelSheetWithHotels:hotelsNotOnBoard tile:clickedTile];
		
		return;
	} else if ([self playedTileTriggersAMerger:clickedTile]) {
		[self _mergerHappeningAtTile:clickedTile];
		return;
	} else if ([self playedTileAddsToAHotel:clickedTile]) {
		[[self playedTileAddsToAHotel:clickedTile] addTile:clickedTile];
		NSArray *orthogonalTiles = [_board tilesOrthogonalToTile:clickedTile];
		NSEnumerator *orthogonalTilesEnumerator = [orthogonalTiles objectEnumerator];
		id curOrthogonalTile;
		while (curOrthogonalTile = [orthogonalTilesEnumerator nextObject])
			if ([curOrthogonalTile state] == AQTileNotInHotel)
				[[self playedTileAddsToAHotel:clickedTile] addTile:curOrthogonalTile];
		
		[_gameWindowController tilesChanged:orthogonalTiles];
	} else {
		[clickedTile setState:AQTileNotInHotel];
	}
	
	[self _tilePlayed:clickedTile];
	[self _showPurchaseSharesSheetIfNeededOrAdvanceTurn];
}

- (void)createHotelNamed:(NSString *)hotelName atTile:(id)tile;
{
	if (tile == nil || ![tile isKindOfClass:[AQTile class]])
		return;
	
	tile = (AQTile *)tile;
	AQHotel *hotel = [self hotelNamed:hotelName];
	
	NSMutableArray *tilesToAddToHotel = [NSMutableArray arrayWithCapacity:10];
	[tile setState:AQTileNotInHotel];
	[tilesToAddToHotel addObject:tile];

	id curTileToAdd;
	int i;
	for (i = 0; i < [tilesToAddToHotel count]; ++i) {
		curTileToAdd = [tilesToAddToHotel objectAtIndex:i];
		if ([curTileToAdd state] != AQTileNotInHotel)
			continue;
		
		[hotel addTile:curTileToAdd];
		NSArray *orthogonalTiles = [_board tilesOrthogonalToTile:curTileToAdd];
		NSEnumerator *orthogonalTileEnumerator = [orthogonalTiles objectEnumerator];
		id curOrthogonalTile;
		while (curOrthogonalTile = [orthogonalTileEnumerator nextObject])
			if (![tilesToAddToHotel containsObject:curOrthogonalTile]) {
				[tilesToAddToHotel addObject:curOrthogonalTile];
			}
	}
	[_gameWindowController tilesChanged:[hotel tiles]];
	[[self activePlayer] addSharesOfHotelNamed:[hotel name] numberOfShares:1];
	[_gameWindowController reloadScoreboard];
	[self _tilePlayed:tile];
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ was created.", [hotel name]]];
	[self _showPurchaseSharesSheetIfNeededOrAdvanceTurn];
}

- (void)hotelSurvives:(AQHotel *)hotel mergingHotels:(NSArray *)mergingHotels mergeTile:(AQTile *)mergeTile;
{
	[self _tilePlayed:mergeTile];
	[_gameWindowController incomingGameLogEntry:@"* Hotel merger occuring!"];
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ is the surviving hotel.", [hotel name]]];
	
	NSMutableArray *disappearingHotels = [NSMutableArray arrayWithArray:mergingHotels];
	[disappearingHotels removeObject:hotel];
	
	[self _payShareholderBonusesForHotels:disappearingHotels];
	
	id curPlayer;
	int i;
	for (i = [self activePlayerIndex]; i < [_players count]; ++i) {
		curPlayer = [_players objectAtIndex:i];
		NSEnumerator *hotelEnumerator = [disappearingHotels objectEnumerator];
		id curHotel;
		while (curHotel = [hotelEnumerator nextObject])
			if ([curPlayer hasSharesOfHotelNamed:[curHotel name]])
				[self _showAllocateMergingHotelSharesSheetForMergingHotel:curHotel survivingHotel:hotel player:curPlayer sharePrice:[curHotel sharePrice]];
	}
	
	for (i = 0; i < [self activePlayerIndex]; ++i) {
		curPlayer = [_players objectAtIndex:i];
		NSEnumerator *hotelEnumerator = [disappearingHotels objectEnumerator];
		id curHotel;
		while (curHotel = [hotelEnumerator nextObject])
			if ([curPlayer hasSharesOfHotelNamed:[curHotel name]])
				[self _showAllocateMergingHotelSharesSheetForMergingHotel:curHotel survivingHotel:hotel player:curPlayer sharePrice:[curHotel sharePrice]];
	}
	
	NSEnumerator *hotelEnumerator = [disappearingHotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject]) {
		[hotel addTiles:[curHotel tiles]];
		[curHotel removeTilesFromBoard];
	}
	[hotel addTile:mergeTile];
	NSEnumerator *orthogonalMergeTilesEnumerator = [[_board tilesOrthogonalToTile:mergeTile] objectEnumerator];
	id curTile;
	while (curTile = [orthogonalMergeTilesEnumerator nextObject])
		if ([curTile state] == AQTileNotInHotel)
			[hotel addTile:curTile];
	
	
	[_gameWindowController tilesChanged:[hotel tiles]];
	
	[self _showPurchaseSharesSheetIfNeededOrAdvanceTurn];
}

- (void)sellSharesOfHotel:(AQHotel *)hotel numberOfShares:(int)numberOfShares player:(AQPlayer *)player sharePrice:(int)sharePrice;
{
	[player subtractSharesOfHotelNamed:[hotel name] numberOfShares:numberOfShares];
	[player addCash:(sharePrice * numberOfShares)];
	[hotel addSharesToBank:numberOfShares];
	
	NSString *plural = (numberOfShares > 1) ? [NSString stringWithString:@"s"] : [NSString stringWithString:@""];
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ sold %d share%@ of %@ for $%d", [player name], numberOfShares, plural, [hotel name], (sharePrice * numberOfShares)]];
	
	[_gameWindowController reloadScoreboard];
}

- (void)tradeSharesOfHotel:(AQHotel *)fromHotel forSharesInHotel:(AQHotel *)toHotel numberOfShares:(int)numberOfShares player:(AQPlayer *)player;
{
	[fromHotel addSharesToBank:numberOfShares];
	[toHotel removeSharesFromBank:(numberOfShares / 2)];
	[player addSharesOfHotelNamed:[toHotel name] numberOfShares:(numberOfShares / 2)];
	
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ traded %d shares of %@ for %d shares of %@", [player name], numberOfShares, [fromHotel name], (numberOfShares / 2), [toHotel name]]];
	
	[_gameWindowController reloadScoreboard];
}

- (BOOL)playedTileCreatesNewHotel:(AQTile *)playedTile;
{
	NSArray *orthogonalTiles = [_board tilesOrthogonalToTile:playedTile];
	BOOL isATileNotInHotel = NO;
	NSEnumerator *adjacentTileEnumerator = [orthogonalTiles objectEnumerator];
	id curOrthogonalTile;
	while (curOrthogonalTile = [adjacentTileEnumerator nextObject]) {
		if ([curOrthogonalTile state] == AQTileNotInHotel)
			isATileNotInHotel = YES;
		else if ([curOrthogonalTile state] == AQTileInHotel)
			return NO;
	}
	
	return isATileNotInHotel;
}

- (BOOL)playedTileTriggersAMerger:(AQTile *)playedTile;
{
	NSArray *adjacentHotels = [self _hotelsAdjacentToTile:playedTile];
	return ([adjacentHotels count] > 1);
}

- (AQHotel *)playedTileAddsToAHotel:(AQTile *)playedTile;
{
	NSArray *adjacentHotels = [self _hotelsAdjacentToTile:playedTile];
	return (([adjacentHotels count] == 1) ? [adjacentHotels objectAtIndex:0] : nil);
}

- (BOOL)tileIsUnplayable:(AQTile *)tile;
{
	NSArray *adjacentHotels = [self _hotelsAdjacentToTile:tile];
	if ([adjacentHotels count] < 2)
		return NO;
	
	int safeAdjacentHotels = 0;
	NSEnumerator *hotelEnumerator = [adjacentHotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject])
		if ([curHotel isSafe])
			++safeAdjacentHotels;
	
	return (safeAdjacentHotels > 1);
}


- (void)endCurrentTurn;
{
	int i;
	for (i = [[self activePlayer] numberOfTiles]; i < 6; ++i)
		[[self activePlayer] drewTile:[_board tileFromTileBag]];
	
	++_activePlayerIndex;
	if (_activePlayerIndex >= [_players count])
		_activePlayerIndex = 0;
	
	[_gameWindowController reloadScoreboard];
	[_gameWindowController updateTileRack:[[self activePlayer] tiles]];
	[_gameWindowController highlightTilesOnBoard:[[self activePlayer] tiles]];
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* It's %@'s turn.", [[self activePlayer] name]]];
	
	_tilePlayedThisTurn = NO;
	
	[_gameWindowController hideEndCurrentTurnButton];
	
	if ([self _gameCanEnd])
		[_gameWindowController showEndGameButton];
	else
		[_gameWindowController hideEndGameButton];
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
	
	[_gameWindowController hidePurchaseSharesButton];
	[_gameWindowController hideEndCurrentTurnButton];
	[_gameWindowController hideEndGameButton];	
	[_gameWindowController disableBoardAndTileRack];
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ has ended the game", [[self activePlayer] name]]];
	[self _payShareholderBonusesForHotels:[self _hotelsOnBoard]];
	[self _payPlayersForSharesInHotels:[self _hotelsOnBoard]];
	
	NSArray *winners = [NSArray arrayWithArray:[self _winningPlayers]];
	NSMutableString *winnersLogText = [NSMutableString stringWithString:@"* "];
	if ([winners count] == 1) {
		[winnersLogText appendString:[[winners objectAtIndex:0] name]];
		[winnersLogText appendString:@" is the winner! Congratulations!"];
	} else {
		[winnersLogText appendString:[[winners objectAtIndex:0] name]];
		int i;
		for (i = 1; i < ([winners count] - 1); ++i) {
			[winnersLogText appendString:@", "];
			[winnersLogText appendString:[[winners objectAtIndex:i] name]];
		}
		[winnersLogText appendString:@" and "];
		[winnersLogText appendString:[[winners objectAtIndex:i] name]];
		[winnersLogText appendString:@" are the winners! Congratulations!"];
	}
	[_gameWindowController incomingGameLogEntry:winnersLogText];
	[_gameWindowController congratulateWinnersByName:winners];
}

- (void)removeGameFromArrayController;
{
	if ([_arrayController isGameInArray:self])
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
	_tilePlayedThisTurn = NO;

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
	NSMutableArray *hotelsWithPurchaseableShares = [NSMutableArray arrayWithCapacity:7];
	NSEnumerator *hotelsEnumerator = [_hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelsEnumerator nextObject])
		if ([curHotel isOnBoard] && [curHotel sharesInBank] > 0)
			[hotelsWithPurchaseableShares addObject:curHotel];
	
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

- (void)_showCreateNewHotelSheetWithHotels:(NSArray *)hotels tile:(AQTile *)tile;
{
	NSLog(@"%s called", _cmd);
	[_gameWindowController showCreateNewHotelSheetWithHotels:hotels atTile:tile];
}

- (void)_showChooseMergerSurvivorSheetWithMergingHotels:(NSArray *)mergingHotels potentialSurvivors:(NSArray *)potentialSurvivors mergeTile:(AQTile *)mergeTile;
{
	[_gameWindowController showChooseMergerSurvivorSheetWithMergingHotels:mergingHotels potentialSurvivors:potentialSurvivors mergeTile:mergeTile];
}

- (void)_showAllocateMergingHotelSharesSheetForMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player sharePrice:(int)sharePrice;
{
	[_gameWindowController showAllocateMergingHotelSharesSheetForMergingHotel:mergingHotel survivingHotel:survivingHotel player:player sharePrice:sharePrice];
}


- (NSArray *)_hotelsAdjacentToTile:(AQTile *)tile;
{
	NSArray *orthogonalTiles = [_board tilesOrthogonalToTile:tile];
	NSMutableArray *adjacentHotels = [NSMutableArray arrayWithCapacity:4];
	NSEnumerator *adjacentTileEnumerator = [orthogonalTiles objectEnumerator];
	id curOrthogonalTile;
	while (curOrthogonalTile = [adjacentTileEnumerator nextObject])
		if ([curOrthogonalTile state] == AQTileInHotel && ![adjacentHotels containsObject:[curOrthogonalTile hotel]])
			[adjacentHotels addObject:[curOrthogonalTile hotel]];

	return adjacentHotels;
}

- (NSArray *)_hotelsNotOnBoard;
{
	NSMutableArray *hotelsNotOnBoard = [NSMutableArray arrayWithCapacity:7];
	NSEnumerator *hotelsEnumerator = [_hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelsEnumerator nextObject])
		if (![curHotel isOnBoard])
			[hotelsNotOnBoard addObject:curHotel];
	
	return hotelsNotOnBoard;
}

- (void)_tilePlayed:(AQTile *)tile;
{
	_tilePlayedThisTurn = YES;
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ played tile %@.", [[self activePlayer] name], [tile description]]];
	
	[self _checkTileRacksForUnplayableTiles];
	[_gameWindowController tilesChanged:[[self activePlayer] tiles]];
	[_gameWindowController tilesChanged:[NSArray arrayWithObject:tile]];
	[[self activePlayer] playedTileNamed:[tile description]];
	[_gameWindowController updateTileRack:[[self activePlayer] tiles]];
}

- (void)_checkTileRacksForUnplayableTiles;
{
	NSEnumerator *playerEnumerator = [_players objectEnumerator];
	id curPlayer;
	while (curPlayer = [playerEnumerator nextObject]) {
		NSEnumerator *tileEnumerator = [[NSArray arrayWithArray:[curPlayer tiles]] objectEnumerator];
		id curTile;
		while (curTile = [tileEnumerator nextObject]) {
			if (curTile == [NSNull null])
				continue;
			
			if ([self tileIsUnplayable:curTile]) {
				[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ discarded unplayable tile %@", [curPlayer name], [curTile description]]];
				[curPlayer playedTileNamed:[curTile description]];
				[_gameWindowController tilesChanged:[NSArray arrayWithObject:curTile]];
			}
		}
	}
}

- (void)_showPurchaseSharesSheetIfNeededOrAdvanceTurn;
{
	NSArray *hotelsWithPurchaseableShares = [self _hotelsWithPurchaseableShares];
	if ([hotelsWithPurchaseableShares count] == 0) {
		if (![self _gameCanEnd])
			[self endCurrentTurn];
		return;
	}
	
	int cheapestSharePrice = 100000;
	NSEnumerator *hotelEnumerator = [hotelsWithPurchaseableShares objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject])
		if ([curHotel sharePrice] < cheapestSharePrice)
			cheapestSharePrice = [curHotel sharePrice];

	if (cheapestSharePrice <= [[self activePlayer] cash]) {
		[self _showPurchaseSharesSheetWithHotels:hotelsWithPurchaseableShares];
		return;
	}
	
	if ([self _gameCanEnd]) {
		[_gameWindowController showEndCurrentTurnButton];
		[_gameWindowController showEndGameButton];
	} else {
		[_gameWindowController hideEndCurrentTurnButton];
		[_gameWindowController hideEndGameButton];
		[self endCurrentTurn];
	}
}

- (void)_mergerHappeningAtTile:(AQTile *)tile;
{
	if ([self tileIsUnplayable:tile])
		return;
	
	NSMutableArray *hotelsInvolvedWithMerger = [NSMutableArray arrayWithCapacity:4];
	NSArray *tilesOrthogonalToMergerTile = [_board tilesOrthogonalToTile:tile];
	NSEnumerator *orthogonalTilesEnumerator = [tilesOrthogonalToMergerTile objectEnumerator];
	id curOrthogonalTile;
	while (curOrthogonalTile = [orthogonalTilesEnumerator nextObject])
		if ([curOrthogonalTile state] == AQTileInHotel)
			if (![hotelsInvolvedWithMerger containsObject:[curOrthogonalTile hotel]])
				[hotelsInvolvedWithMerger addObject:[curOrthogonalTile hotel]];
	
	NSMutableArray *biggestHotels = [[NSMutableArray arrayWithCapacity:4] retain];
	NSEnumerator *hotelsEnumerator = [hotelsInvolvedWithMerger objectEnumerator];
	AQHotel *curHotel;
	while (curHotel = (AQHotel *)[hotelsEnumerator nextObject]) {
		if ([biggestHotels count] == 0) {
			[biggestHotels addObject:curHotel];
			continue;
		}
		if ([curHotel size] < [(AQHotel *)[biggestHotels objectAtIndex:0] size])
			continue;
		if ([curHotel size] == [(AQHotel *)[biggestHotels objectAtIndex:0] size]) {
			[biggestHotels addObject:curHotel];
			continue;
		}
		[biggestHotels release];
		biggestHotels = [[NSMutableArray arrayWithCapacity:3] retain];
		[biggestHotels addObject:curHotel];	
	}
	
	if ([biggestHotels count] == 1)
		[self hotelSurvives:[biggestHotels objectAtIndex:0] mergingHotels:hotelsInvolvedWithMerger mergeTile:tile];
	else
		[self _showChooseMergerSurvivorSheetWithMergingHotels:hotelsInvolvedWithMerger potentialSurvivors:biggestHotels mergeTile:tile];
	
	// I'm not entirely sure why I have to retain biggestHotels earlier, and release it here; for some reason, it tends to get autoreleased before we're done with it (possibly due to the app-modal sheets triggered sometimes several times). Anyway, no harm done retaining/releasing it here. Maybe more investigation will reveal the cause. It seems to come up when no new biggestHotels array is created within the while loop (i.e. when the one created outside the loop is used).
	[biggestHotels release];
}

- (void)_payShareholderBonusesForHotels:(NSArray *)hotels;
{
	NSEnumerator *hotelEnumerator = [hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject]) {
		NSMutableArray *playersWithShares = [NSMutableArray arrayWithCapacity:6];
		NSEnumerator *playerEnumerator = [_players objectEnumerator];
		id curPlayer;
		while (curPlayer = [playerEnumerator nextObject])
			if ([curPlayer hasSharesOfHotelNamed:[curHotel name]])
				[playersWithShares addObject:curPlayer];
		
		NSMutableArray *majorityShareholders = [NSMutableArray arrayWithCapacity:6];
		NSMutableArray *minorityShareholders = nil;
		
		NSEnumerator *playersWithSharesEnumerator = [playersWithShares objectEnumerator];
		id curPlayerWithShares;
		while (curPlayerWithShares = [playersWithSharesEnumerator nextObject]) {
			if ([majorityShareholders count] == 0) {
				[majorityShareholders addObject:curPlayerWithShares];
				continue;
			}
			if ([curPlayerWithShares numberOfSharesOfHotelNamed:[curHotel name]] > [[majorityShareholders objectAtIndex:0] numberOfSharesOfHotelNamed:[curHotel name]]) {
				minorityShareholders = majorityShareholders;
				majorityShareholders = [NSMutableArray arrayWithCapacity:5];
				[majorityShareholders addObject:curPlayerWithShares];
				continue;
			}
			if ([curPlayerWithShares numberOfSharesOfHotelNamed:[curHotel name]] == [[majorityShareholders objectAtIndex:0] numberOfSharesOfHotelNamed:[curHotel name]]) {
				[majorityShareholders addObject:curPlayerWithShares];
				continue;
			}
			if ([minorityShareholders count] == 0) {
				[minorityShareholders addObject:curPlayerWithShares];
				continue;
			}
			if ([curPlayerWithShares numberOfSharesOfHotelNamed:[curHotel name]] > [[minorityShareholders objectAtIndex:0] numberOfSharesOfHotelNamed:[curHotel name]]) {
				minorityShareholders = [NSMutableArray arrayWithCapacity:6];
				[minorityShareholders addObject:curPlayerWithShares];
				continue;
			}
			if ([curPlayerWithShares numberOfSharesOfHotelNamed:[curHotel name]] == [[minorityShareholders objectAtIndex:0] numberOfSharesOfHotelNamed:[curHotel name]]) {
				[minorityShareholders addObject:curPlayerWithShares];
				continue;
			}
		}
		
		if ([majorityShareholders count] > 1) {
			int cashToDistribute = ([curHotel sharePrice] * 15);
			int cashPerPlayer = (cashToDistribute / [majorityShareholders count]);
			cashPerPlayer -= (cashPerPlayer % 100);
			
			NSEnumerator *majorityShareholderEnumerator = [majorityShareholders objectEnumerator];
			id curMajorityShareholder;
			while (curMajorityShareholder = [majorityShareholderEnumerator nextObject]) {
				[curMajorityShareholder addCash:cashPerPlayer];
				[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ gets $%d as tied majority shareholder of %@", [curMajorityShareholder name], cashPerPlayer, [curHotel name]]];
			}
		} else if (minorityShareholders == nil) {
			[[majorityShareholders objectAtIndex:0] addCash:([curHotel sharePrice] * 15)];
			[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ gets $%d as sole shareholder of %@", [[majorityShareholders objectAtIndex:0] name], ([curHotel sharePrice] * 15), [curHotel name]]];
		} else {
			[[majorityShareholders objectAtIndex:0] addCash:([curHotel sharePrice] * 10)];
			[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ gets $%d as majority shareholder of %@", [[majorityShareholders objectAtIndex:0] name], ([curHotel sharePrice] * 10), [curHotel name]]];
		
			int cashPerPlayer = ([curHotel sharePrice] * 5);
			cashPerPlayer /= [minorityShareholders count];
			cashPerPlayer -= (cashPerPlayer % 100);
		
			NSEnumerator *minorityShareholderEnumerator = [minorityShareholders objectEnumerator];
			id curMinorityShareholder;
			while (curMinorityShareholder = [minorityShareholderEnumerator nextObject]) {
				[curMinorityShareholder addCash:cashPerPlayer];
				[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ gets $%d as minority shareholder of %@", [curMinorityShareholder name], cashPerPlayer, [curHotel name]]];
			}
		}
	}
	
	[_gameWindowController reloadScoreboard];
}

- (void)_payPlayersForSharesInHotels:(NSArray *)hotelsToPay;
{
	NSArray *hotels = [NSArray arrayWithArray:hotelsToPay];
	NSEnumerator *hotelEnumerator = [hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject]) {
		NSEnumerator *playerEnumerator = [_players objectEnumerator];
		id curPlayer;
		while (curPlayer = [playerEnumerator nextObject]) {
			if ([curPlayer hasSharesOfHotelNamed:[curHotel name]]) {
				int cashAdded = ([curPlayer numberOfSharesOfHotelNamed:[curHotel name]] * [curHotel sharePrice]);
				[curPlayer addCash:cashAdded];
				NSString *plural = ([curPlayer numberOfSharesOfHotelNamed:[curHotel name]] > 1) ? [NSString stringWithString:@"S"] : [NSString stringWithString:@""];
				[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ got $%d for %d share%@ of %@", [curPlayer name], cashAdded, [curPlayer numberOfSharesOfHotelNamed:[curHotel name]], plural, [curHotel name]]];
			}
		}
	}
	
	[_gameWindowController reloadScoreboard];
}

- (NSArray *)_hotelsOnBoard;
{
	NSMutableArray *hotelsOnBoard = [NSMutableArray arrayWithCapacity:7];
	NSEnumerator *hotelEnumerator = [_hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject]) {
		if ([curHotel isOnBoard])
			[hotelsOnBoard addObject:curHotel];
	}
	
	return hotelsOnBoard;
}

- (NSArray *)_winningPlayers;
{
	NSMutableArray *playersWithMostCash = [NSMutableArray arrayWithCapacity:6];
	NSEnumerator *playerEnumerator = [_players objectEnumerator];
	id curPlayer;
	while (curPlayer = [playerEnumerator nextObject]) {
		if ([playersWithMostCash count] == 0) {
			[playersWithMostCash addObject:curPlayer];
			continue;
		}
		if ([curPlayer cash] > [[playersWithMostCash objectAtIndex:0] cash]) {
			playersWithMostCash = [NSMutableArray arrayWithCapacity:5];
			[playersWithMostCash addObject:curPlayer];
			continue;
		}
		if ([curPlayer cash] == [[playersWithMostCash objectAtIndex:0] cash])
			[playersWithMostCash addObject:curPlayer];
	}
	
	return playersWithMostCash;
}

- (BOOL)_gameCanEnd;
{
	NSArray *hotelsOnBoard = [self _hotelsOnBoard];
	NSEnumerator *hotelEnumerator = [hotelsOnBoard objectEnumerator];
	id curHotel;
	int safeHotels = 0;
	while (curHotel = [hotelEnumerator nextObject]) {
		if ([(AQHotel *)curHotel size] > 40)
			return YES;
		if ([curHotel isSafe])
			++safeHotels;
	}
	
	if ([hotelsOnBoard count] == 0)
		return NO;
	
	return (safeHotels == [hotelsOnBoard count]);
}
@end
