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
@end

@implementation AQGame
- (id)initNetworkGameWithArrayController:(id)arrayController associatedConnection:(AQConnectionController *)associatedConnection;
{
	if (![self _initGameWithArrayController:arrayController])
		return nil;
	
	_associatedConnection = [associatedConnection retain];
	_localPlayerName = nil;

	return self;
}

- (id)initLocalGameWithArrayController:(id)arrayController;
{
	if (![self _initGameWithArrayController:arrayController])
		return nil;
	
	_associatedConnection = nil;
	_localPlayerName = nil;
	
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
	if (_activePlayerIndex < 0 || _activePlayerIndex >= [_players count])
		return nil;
	
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
	
	return [self playerNamed:_localPlayerName];
}

- (AQPlayer *)playerNamed:(NSString *)name;
{
	if (name == nil || _players == nil || [_players count] == 0)
		return nil;
	
	NSEnumerator *playerEnumerator = [_players objectEnumerator];
	id curPlayer;
	while (curPlayer = [playerEnumerator nextObject]) {
		if ([[curPlayer name] length] != [name length])
			continue;
		
		if ([[curPlayer name] compare:name options:NSCaseInsensitiveSearch range:NSMakeRange(0, [name length])] == NSOrderedSame)
			return curPlayer;
	}
	
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
	if (hotelName == nil)
		return nil;
	
	NSEnumerator *hotelEnumerator = [_hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject])
		if ([[curHotel name] isEqualToString:hotelName])
			return curHotel;
	
	return nil;
}

- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames sender:(id)sender;
{
	[self purchaseShares:sharesPurchased ofHotelsNamed:hotelNames endGame:NO sender:sender];
}

- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames endGame:(BOOL)endGame sender:(id)sender;
{
	if ([self isNetworkGame]) {
		if (!endGame && [self gameCanEnd] && [sender isKindOfClass:[NSButton class]]) {
			_finalTurnSharesPurchased = [[NSArray arrayWithArray:sharesPurchased] retain];
			_finalTurnHotelNames = [[NSArray arrayWithArray:hotelNames] retain];
			[_gameWindowController showPurchaseSharesButton];
			[_gameWindowController showEndCurrentTurnButton];
			[_gameWindowController showEndGameButton];
			
			return;
		}
		
		NSMutableArray *pDirectiveParameters = [NSMutableArray arrayWithCapacity:7];
		NSEnumerator *hotelEnumerator = [_hotels objectEnumerator];
		id curHotel;
		while (curHotel = [hotelEnumerator nextObject]) {
			BOOL foundIt = NO;
			int i;
			for (i = 0; i < [hotelNames count]; ++i) {
				if ([[hotelNames objectAtIndex:i] isEqualToString:[curHotel name]]) {
					[pDirectiveParameters addObject:[sharesPurchased objectAtIndex:i]];
					foundIt = YES;
					break;
				}
			}
			
			if (!foundIt)
				[pDirectiveParameters addObject:[NSNumber numberWithInt:0]];
		}
		
		if (endGame && [self gameCanEnd])
			[_associatedConnection purchaseSharesAndEndGame:pDirectiveParameters];
		else
			[_associatedConnection purchaseShares:pDirectiveParameters];
		
		[_gameWindowController tilesChanged:[[self localPlayer] tiles]];
		[_gameWindowController hidePurchaseSharesButton];
		return;
	}
	
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
		if ([self gameCanEnd]) {
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
	if ([self isNetworkGame] && [self localPlayer] != [self activePlayer])
		return;
	
	if (![[self activePlayer] hasTileNamed:tileClickedString] && !DEBUG_ALLOW_PLAYING_OF_ANY_TILE)
		return;
	
	if (_tilePlayedThisTurn)
		return;
	
	AQTile *clickedTile = [_board tileOnBoardByString:tileClickedString];
	
	if ([self isNetworkGame]) {
		if ([self playedTileCreatesNewHotel:clickedTile] && [[self _hotelsNotOnBoard] count] == 0)
			return;
		
		if ([self tileIsUnplayable:clickedTile])
			return;
		
		[_associatedConnection playTileAtRackIndex:([[self activePlayer] rackIndexOfTileNamed:tileClickedString] + 1)];
		_tilePlayedThisTurn = YES;
		
		if (![self gameCanEnd]) {
			[_gameWindowController hideEndCurrentTurnButton];
			[_gameWindowController hideEndGameButton];
		}
		
		return;
	}
	

	if ([self playedTileCreatesNewHotel:clickedTile]) {
		NSArray *hotelsNotOnBoard = [self _hotelsNotOnBoard];
		if ([hotelsNotOnBoard count] == 0)
			return;
		
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
	if ([self isNetworkGame]) {
		[_associatedConnection choseHotelToCreate:[[self hotelNamed:hotelName] netacquireID]];
		return;
	}
	
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
	if ([self isNetworkGame]) {
		[_associatedConnection selectedMergeSurvivor:[hotel netacquireID]];
		return;
	}
	
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
	if ([self isNetworkGame]) {
		[self purchaseShares:_finalTurnSharesPurchased ofHotelsNamed:_finalTurnHotelNames endGame:NO sender:self];
		
		[_gameWindowController hidePurchaseSharesButton];
		[_gameWindowController hideEndCurrentTurnButton];
		[_gameWindowController hideEndGameButton];
		return;
	}
	
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
	
	if ([self gameCanEnd])
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

- (BOOL)gameCanEnd;
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

- (void)endGame;
{
	if ([self isNetworkGame]) {
		[self purchaseShares:_finalTurnSharesPurchased ofHotelsNamed:_finalTurnHotelNames endGame:YES sender:self];
		
		[_gameWindowController hidePurchaseSharesButton];
		[_gameWindowController hideEndCurrentTurnButton];
		[_gameWindowController hideEndGameButton];
		return;
	}
	
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

- (void)incomingGameMessage:(NSString *)gameMessage;
{
	[_gameWindowController incomingGameMessage:gameMessage];
}

- (void)incomingGameLogEntry:(NSString *)gameLogEntry;
{
	[_gameWindowController incomingGameLogEntry:gameLogEntry];
}

- (void)disableBoardAndTileRack;
{
	[_gameWindowController disableBoardAndTileRack];
}

- (void)closeGameWindow;
{
	[_gameWindowController closeGameWindow];
}

- (void)showGameWindow;
{
	[_gameWindowController bringGameWindowToFront];
}
@end

@implementation AQGame (NetworkGame)
- (AQPlayer *)localPlayer;
{
	if (_localPlayerName == nil)
		return nil;
	
	return [self playerNamed:_localPlayerName];
}

- (NSString *)localPlayerName;
{
	return _localPlayerName;
}

- (BOOL)isOn;
{
	return _isOn;
}

- (void)setLocalPlayerName:(NSString *)localPlayerName;
{
	[_localPlayerName release];
	_localPlayerName = [localPlayerName copy];
}

- (void)setActivePlayerName:(NSString *)activePlayerName;
{
	int i;
	for (i = 0; i < [_players count]; ++i) {
		if ([[[_players objectAtIndex:i] name] isEqualToString:activePlayerName]) {
			_activePlayerIndex = i;
			[_gameWindowController reloadScoreboard];
			break;
		}
	}
	
	if ([self activePlayer] == [self localPlayer]) {
		_tilePlayedThisTurn = NO;
		[_gameWindowController highlightTilesOnBoard:[[self activePlayer] tiles]];
		
		if ([self gameCanEnd])
			[_gameWindowController showEndGameButton];
		
		[_gameWindowController announceLocalPlayersTurn];
	} else {
		[_gameWindowController tilesChanged:[[self activePlayer] tiles]];
		[_gameWindowController hideEndCurrentTurnButton];
		[_gameWindowController hideEndGameButton];
	}
}

- (void)boardTile:(AQTile *)tile isNetacquireChainID:(int)netacquireChainID;
{
	if ([[self activePlayer] hasTileNamed:[tile description]]) {
		[[self activePlayer] playedTileNamed:[tile description]];
		[_gameWindowController updateTileRack:[[self activePlayer] tiles]];
	}
	
	AQTileState tileState = [self tileStateFromChainID:netacquireChainID];
	if (tileState == AQTileInHotel) {
		[[self hotelFromChainID:netacquireChainID] addTile:tile];
	}
	else
		[tile setState:tileState];
	
	[_gameWindowController tilesChanged:[NSArray arrayWithObject:tile]];
}

- (void)boardTileAtNetacquireID:(int)netacquireID isNetacquireChainID:(int)netacquireChainID;
{
	[self boardTile:[_board tileFromNetacquireID:netacquireID] isNetacquireChainID:netacquireChainID];
}

- (void)rackTileAtIndex:(int)index isNetacquireID:(int)netacquireID netacquireChainID:(int)netacquireChainID;
{
	if (netacquireChainID == 8421504) {
		[[self localPlayer] playedTileNamed:[[_board tileFromNetacquireID:netacquireID] description]];
		[_gameWindowController updateTileRack:[[self localPlayer] tiles]];
		return;
	}
	
	++_localPlayerTilesDrawn;
	[[self localPlayer] drewTile:[_board tileFromNetacquireID:netacquireID] atRackIndex:index];
	[_gameWindowController updateTileRack:[[self localPlayer] tiles]];
	if (_localPlayerTilesDrawn > 1)
		_isOn = YES;
}

- (void)outgoingGameMessage:(NSString *)gameMessage;
{
	[_associatedConnection outgoingGameMessage:gameMessage];
}

- (void)playerAtIndex:(int)playerIndex isNamed:(NSString *)name;
{
	if ([_players count] < playerIndex) {
		[_players addObject:[AQPlayer playerWithName:name]];
	} else if (![[[_players objectAtIndex:(playerIndex - 1)] name] isEqualToString:name]) {
		// The only time the names will change are when we have shells of empty player objects anyway, so it's not a huge deal to just wholesale replace the object. In theory, we should rearrange this more appropriately.
		[_players replaceObjectAtIndex:(playerIndex - 1) withObject:[AQPlayer playerWithName:name]];
	}
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasCash:(int)cash;
{
	if (playerIndex < 0 || playerIndex >= [_players count])
		return;
	
	[[_players objectAtIndex:playerIndex] setCash:cash];
}

- (void)playerAtIndex:(int)playerIndex hasSacksonShares:(int)sacksonShares;
{
	int diff = sacksonShares - [[_players objectAtIndex:playerIndex] numberOfSharesOfHotelNamed:@"Sackson"];
	[[_players objectAtIndex:playerIndex] addSharesOfHotelNamed:@"Sackson" numberOfShares:diff];
	[[self hotelNamed:@"Sackson"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasZetaShares:(int)zetaShares;
{
	int diff = zetaShares - [[_players objectAtIndex:playerIndex] numberOfSharesOfHotelNamed:@"Zeta"];
	[[_players objectAtIndex:playerIndex] addSharesOfHotelNamed:@"Zeta" numberOfShares:diff];
	[[self hotelNamed:@"Zeta"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasAmericaShares:(int)americaShares;
{
	int diff = americaShares - [[_players objectAtIndex:playerIndex] numberOfSharesOfHotelNamed:@"America"];
	[[_players objectAtIndex:playerIndex] addSharesOfHotelNamed:@"America" numberOfShares:diff];
	[[self hotelNamed:@"America"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasFusionShares:(int)fusionShares;
{
	int diff = fusionShares - [[_players objectAtIndex:playerIndex] numberOfSharesOfHotelNamed:@"Fusion"];
	[[_players objectAtIndex:playerIndex] addSharesOfHotelNamed:@"Fusion" numberOfShares:diff];
	[[self hotelNamed:@"Fusion"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasHydraShares:(int)hydraShares;
{
	int diff = hydraShares - [[_players objectAtIndex:playerIndex] numberOfSharesOfHotelNamed:@"Hydra"];
	[[_players objectAtIndex:playerIndex] addSharesOfHotelNamed:@"Hydra" numberOfShares:diff];
	[[self hotelNamed:@"Hydra"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasPhoenixShares:(int)phoenixShares;
{
	int diff = phoenixShares - [[_players objectAtIndex:playerIndex] numberOfSharesOfHotelNamed:@"Phoenix"];
	[[_players objectAtIndex:playerIndex] addSharesOfHotelNamed:@"Phoenix" numberOfShares:diff];
	[[self hotelNamed:@"Phoenix"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasQuantumShares:(int)quantumShares;
{
	int diff = quantumShares - [[_players objectAtIndex:playerIndex] numberOfSharesOfHotelNamed:@"Quantum"];
	[[_players objectAtIndex:playerIndex] addSharesOfHotelNamed:@"Quantum" numberOfShares:diff];
	[[self hotelNamed:@"Quantum"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}


- (void)getChainFromHotelIndexes:(NSArray *)hotelIndexes;
{
	NSMutableArray *hotels = [NSMutableArray arrayWithCapacity:[hotelIndexes count]];
	hotelIndexes = [NSArray arrayWithArray:hotelIndexes];
	NSEnumerator *indexesEnumerator = [hotelIndexes objectEnumerator];
	id curIndex;
	while (curIndex = [indexesEnumerator nextObject])
		[hotels addObject:[_hotels objectAtIndex:[curIndex intValue]]];
	
	[self _showCreateNewHotelSheetWithHotels:hotels tile:nil];
}

- (void)chooseMergeSurvivorFromHotelIndexes:(NSArray *)hotelIndexes;
{
	NSMutableArray *hotels = [NSMutableArray arrayWithCapacity:[hotelIndexes count]];
	hotelIndexes = [NSArray arrayWithArray:hotelIndexes];
	NSEnumerator *indexesEnumerator = [hotelIndexes objectEnumerator];
	id curIndex;
	while (curIndex = [indexesEnumerator nextObject])
		[hotels addObject:[_hotels objectAtIndex:[curIndex intValue]]];
	
	[self _showChooseMergerSurvivorSheetWithMergingHotels:hotels potentialSurvivors:hotels mergeTile:nil];
}

- (void)getPurchaseWithGameEndFlag:(int)gameEndFlag cash:(int)cash;
{
	[_gameWindowController tilesChanged:[[self localPlayer] tiles]];
	[[self localPlayer] setCash:cash];
	[self _showPurchaseSharesSheetWithHotels:[self _hotelsWithPurchaseableShares]];
}

- (AQTileState)tileStateFromChainID:(int)chainID;
{
	if (chainID == 0 || chainID == 12632256)
		return AQTileNotInHotel;
	
	if ([self hotelFromChainID:chainID] != nil)
		return AQTileInHotel;
	
	return AQTileUnplayed;
}

- (AQHotel *)hotelFromChainID:(int)chainID;
{
	NSEnumerator *hotelEnumerator = [_hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject]) {
		if ([curHotel netacquireID] == chainID)
			return curHotel;
	}
	
	return nil;
}

- (void)showAllocateMergingHotelSharesSheetForHotelWithNetacquireID:(int)mergingHotelNetacquireID survivingHotelNetacquireID:(int)survivingHotelNetacquireID;
{
	[self _showAllocateMergingHotelSharesSheetForMergingHotel:[self hotelWithNetacquireID:mergingHotelNetacquireID] survivingHotel:[self hotelWithNetacquireID:survivingHotelNetacquireID] player:[self localPlayer] sharePrice:[[self hotelWithNetacquireID:mergingHotelNetacquireID] sharePrice]];
}

- (void)closeGameWindow;
{
	[_gameWindowController closeGameWindow];
}

- (AQHotel *)hotelWithNetacquireID:(int)netacquireID;
{
	NSEnumerator *hotelEnumerator = [_hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject])
		if ([curHotel netacquireID] == netacquireID)
			return curHotel;
	
	return nil;
}

- (void)mergerSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
{
	[_associatedConnection mergerSharesSold:sharesSold sharesTraded:sharesTraded];
}

- (void)showCreateNewHotelSheet;
{
	[self _showCreateNewHotelSheetWithHotels:[self _hotelsNotOnBoard] tile:nil];
}

- (void)determineAndCongratulateWinner;
{
	_isOn = NO;
	[_gameWindowController congratulateWinnersByName:[self _winningPlayers]];
	
	[_gameWindowController disableBoardAndTileRack];
}

- (BOOL)isReadyToStart;
{
	return _isReadyToStart;
}

- (void)setIsReadyToStart:(BOOL)isReadyToStart;
{
	_isReadyToStart = isReadyToStart;
}

- (void)enteringTestMode;
{
	[_gameWindowController enteringTestMode];
}

- (void)exitingTestMode;
{
	[_gameWindowController exitingTestMode];
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
	_finalTurnSharesPurchased = nil;
	_finalTurnHotelNames = nil;
	_isReadyToStart = NO;
	_isOn = NO;
	_localPlayerTilesDrawn = 0;

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
	return [NSArray arrayWithObjects:[AQHotel sacksonHotel], [AQHotel zetaHotel], [AQHotel americaHotel], [AQHotel fusionHotel], [AQHotel hydraHotel], [AQHotel quantumHotel], [AQHotel phoenixHotel], nil];
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
		if (![self gameCanEnd])
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
	
	if ([self gameCanEnd]) {
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
@end
