// AQGame.m
//
// Created May 28, 2008 by nwaite

#ifndef DEBUG_ALLOW_PLAYING_OF_ANY_TILE
#define DEBUG_ALLOW_PLAYING_OF_ANY_TILE 0
#endif

#import "AQGame.h"
#import "AQGameArrayController.h"

#pragma mark -

@interface AQGame (Private)
#pragma mark Private interface

#pragma mark 
#pragma mark init/dealloc

- (id)_initGameWithArrayController:(id)arrayController;

#pragma mark 
#pragma mark UI

- (void)_updateGameWindow;
- (void)_tilePlayed:(AQTile *)tile;

#pragma mark 
#pragma mark Sheet showings

- (void)_showPurchaseSharesSheetWithHotels:(NSArray *)hotels;
- (void)_showCreateNewHotelSheetWithHotels:(NSArray *)hotels tile:(AQTile *)tile;
- (void)_showChooseMergerSurvivorSheetWithMergingHotels:(NSArray *)mergingHotels potentialSurvivors:(NSArray *)potentialSurvivors mergeTile:(AQTile *)mergeTile;
- (void)_showAllocateMergingHotelSharesSheetForMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player sharePrice:(int)sharePrice;
@end

#pragma mark -

@implementation AQGame
#pragma mark Implementation

#pragma mark 
#pragma mark init/dealloc

- (id)initNetworkGameWithArrayController:(id)arrayController associatedConnection:(AQConnectionController *)associatedConnection;
{
	if (![self _initGameWithArrayController:arrayController])
		return nil;
	
	_associatedConnection = [associatedConnection retain];
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

#pragma mark 
#pragma mark Accessors/setters

- (BOOL)isReadyToStart;
{
	return _isReadyToStart;
}

- (void)setIsReadyToStart:(BOOL)isReadyToStart;
{
	_isReadyToStart = isReadyToStart;
}

- (BOOL)isOn;
{
	return _isOn;
}

#pragma mark 
#pragma mark Player accessors/setters

- (int)numberOfPlayers;
{
	return [_players count];
}

- (AQPlayer *)playerAtIndex:(int)index;
{
	if (index < 0 || index >= [self numberOfPlayers])
		return nil;
	else
	  return [_players objectAtIndex:index];
}

- (AQPlayer *)activePlayer;
{
	if (_activePlayerIndex < 0 || _activePlayerIndex >= [_players count])
		return nil;
	else
	  return [_players objectAtIndex:_activePlayerIndex];
}

- (int)activePlayerIndex;
{
	return _activePlayerIndex;
}

- (AQPlayer *)playerNamed:(NSString *)name;
{
	if (name == nil || _players == nil || [_players count] == 0)
		return nil;
	
	NSEnumerator *playerEnumerator = [_players objectEnumerator];
	id curPlayer;
	while (curPlayer = [playerEnumerator nextObject])
	{
		if ([[curPlayer name] length] != [name length])
			continue;
		
    NSRange range = NSMakeRange(0, [name length]);
		if ([[curPlayer name] compare:name
                          options:NSCaseInsensitiveSearch
                            range:range] == NSOrderedSame)
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

- (void)setLocalPlayerName:(NSString *)localPlayerName;
{
	[_localPlayerName release];
	_localPlayerName = [localPlayerName copy];
}

- (void)setActivePlayerName:(NSString *)activePlayerName isPurchasing:(BOOL)isPurchasing;
{
	int i;
	for (i = 0; i < [_players count]; ++i) {
		if ([[[_players objectAtIndex:i] name] isEqualToString:activePlayerName]) {
			_activePlayerIndex = i;
			[_gameWindowController reloadScoreboard];
			break;
		}
	}
	
	if ([self activePlayer] == [self localPlayer] && [self activePlayer] != nil) {
		_tilePlayedThisTurn = NO;
		
		if ([self gameCanEnd])
			[_gameWindowController showEndGameButton];
		
		if (!isPurchasing) {
			[_gameWindowController highlightTilesOnBoard:[[self localPlayer] tiles]];
			[_gameWindowController enableTileRack];
		}
		
		[_gameWindowController announceLocalPlayersTurn];
	} else {
		[_gameWindowController tilesChanged:[[self activePlayer] tiles]];
		[_gameWindowController hideEndCurrentTurnButton];
		[_gameWindowController hideEndGameButton];
		[_gameWindowController highlightTilesOnBoard:[[self localPlayer] tiles]];
		[_gameWindowController disableTileRack];
	}
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

- (void)playerAtIndex:(int)playerIndex hasCash:(int)cash;
{
	if (playerIndex < 0 || playerIndex >= [_players count])
		return;
	
	[[_players objectAtIndex:playerIndex] setCash:cash];
}

- (void)playerAtIndex:(int)playerIndex hasSacksonShares:(int)sacksonShares;
{
	AQPlayer *player = [_players objectAtIndex:playerIndex];
	if (player == nil)
		return;
	
	int diff = sacksonShares - [player numberOfSharesOfHotelNamed:@"Sackson"];
	[player addSharesOfHotelNamed:@"Sackson" numberOfShares:diff];
	[[self hotelNamed:@"Sackson"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasZetaShares:(int)zetaShares;
{
	AQPlayer *player = [_players objectAtIndex:playerIndex];
	if (player == nil)
		return;
	
	int diff = zetaShares - [player numberOfSharesOfHotelNamed:@"Zeta"];
	[player addSharesOfHotelNamed:@"Zeta" numberOfShares:diff];
	[[self hotelNamed:@"Zeta"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasAmericaShares:(int)americaShares;
{
	AQPlayer *player = [_players objectAtIndex:playerIndex];
	if (player == nil)
		return;
	
	int diff = americaShares - [player numberOfSharesOfHotelNamed:@"America"];
	[player addSharesOfHotelNamed:@"America" numberOfShares:diff];
	[[self hotelNamed:@"America"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasFusionShares:(int)fusionShares;
{
	AQPlayer *player = [_players objectAtIndex:playerIndex];
	if (player == nil)
		return;
	
	int diff = fusionShares - [player numberOfSharesOfHotelNamed:@"Fusion"];
	[player addSharesOfHotelNamed:@"Fusion" numberOfShares:diff];
	[[self hotelNamed:@"Fusion"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasHydraShares:(int)hydraShares;
{
	AQPlayer *player = [_players objectAtIndex:playerIndex];
	if (player == nil)
		return;
	
	int diff = hydraShares - [player numberOfSharesOfHotelNamed:@"Hydra"];
	[player addSharesOfHotelNamed:@"Hydra" numberOfShares:diff];
	[[self hotelNamed:@"Hydra"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasQuantumShares:(int)quantumShares;
{
	AQPlayer *player = [_players objectAtIndex:playerIndex];
	if (player == nil)
		return;
	
	int diff = quantumShares - [player numberOfSharesOfHotelNamed:@"Quantum"];
	[player addSharesOfHotelNamed:@"Quantum" numberOfShares:diff];
	[[self hotelNamed:@"Quantum"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

- (void)playerAtIndex:(int)playerIndex hasPhoenixShares:(int)phoenixShares;
{
	AQPlayer *player = [_players objectAtIndex:playerIndex];
	if (player == nil)
		return;
	
	int diff = phoenixShares - [player numberOfSharesOfHotelNamed:@"Phoenix"];
	[player addSharesOfHotelNamed:@"Phoenix" numberOfShares:diff];
	[[self hotelNamed:@"Phoenix"] removeSharesFromBank:diff];
	
	[_gameWindowController reloadScoreboard];
}

#pragma mark 
#pragma mark Hotel accessors/setters

+ (NSArray *)initialHotelsArray;
{
	return [NSArray arrayWithObjects:
	  [AQHotel sacksonHotel], 
	  [AQHotel zetaHotel], 
	  [AQHotel americaHotel], 
	  [AQHotel fusionHotel], 
	  [AQHotel hydraHotel], 
	  [AQHotel quantumHotel], 
	  [AQHotel phoenixHotel], 
	  nil];
}

- (AQHotel *)hotelNamed:(NSString *)hotelName;
{
	if (hotelName == nil)
		return nil;
	
	NSEnumerator *hotelEnumerator = [_hotels objectEnumerator];
	AQHotel *curHotel;
	while (curHotel = [hotelEnumerator nextObject])
	{
		if ([[curHotel name] isEqualToString:hotelName])
			return curHotel;
    else if ([[curHotel oldName] isEqualToString:hotelName])
      return curHotel;
  }
	return nil;
}

- (void)purchaseShares:(NSArray*)sharesPurchased
         ofHotelsNamed:(NSArray*)hotelNames
                sender:(id)sender;
{
	[self purchaseShares:sharesPurchased
         ofHotelsNamed:hotelNames
               endGame:NO
                sender:sender];
}

- (void)purchaseShares:(NSArray*)sharesPurchased
         ofHotelsNamed:(NSArray*)hotelNames
               endGame:(BOOL)endGame
                sender:(id)sender;
{
	if (!endGame && [self gameCanEnd] && [sender isKindOfClass:[NSButton class]])
	{
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
	while (curHotel = [hotelEnumerator nextObject])
	{
		BOOL foundIt = NO;
		int i;
		for (i = 0; i < [hotelNames count]; ++i)
		{
			if ([[hotelNames objectAtIndex:i] isEqualToString:[curHotel oldName]])
			{
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
}

- (int)sharesAvailableOfHotelNamed:(NSString *)hotelName;
{
	return [(AQHotel *)[self hotelNamed:hotelName] sharesInBank];
}

- (NSArray *)hotelsAdjacentToTile:(AQTile *)tile;
{
	NSArray *orthogonalTiles = [_board tilesOrthogonalToTile:tile];
	NSMutableArray *adjacentHotels = [NSMutableArray arrayWithCapacity:4];
	NSEnumerator *adjacentTileEnumerator = [orthogonalTiles objectEnumerator];
	AQTile *curOrthogonalTile;
	while (curOrthogonalTile = [adjacentTileEnumerator nextObject])
	{
		if ([curOrthogonalTile state] == AQTileInHotel && 
		    ![adjacentHotels containsObject:[curOrthogonalTile hotel]])
			[adjacentHotels addObject:[curOrthogonalTile hotel]];
	}

	return adjacentHotels;
}

- (NSArray *)hotelsNotOnBoard;
{
	NSMutableArray *hotelsNotOnBoard = [NSMutableArray arrayWithCapacity:7];
	NSEnumerator *hotelsEnumerator = [_hotels objectEnumerator];
	AQHotel *curHotel;
	while (curHotel = [hotelsEnumerator nextObject])
	{
		if (![curHotel isOnBoard])
			[hotelsNotOnBoard addObject:curHotel];
	}
	return hotelsNotOnBoard;
}

- (NSArray *)hotelsOnBoard;
{
	NSMutableArray *hotelsOnBoard = [NSMutableArray arrayWithCapacity:7];
	NSEnumerator *hotelEnumerator = [_hotels objectEnumerator];
	AQHotel *curHotel;
	while (curHotel = [hotelEnumerator nextObject])
	{
		if ([curHotel isOnBoard])
			[hotelsOnBoard addObject:curHotel];
	}
	return hotelsOnBoard;
}

- (NSArray *)hotelsWithPurchaseableShares;
{
	NSMutableArray *hotelsWithPurchaseableShares = [NSMutableArray arrayWithCapacity:7];
	NSEnumerator *hotelsEnumerator = [_hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelsEnumerator nextObject])
	{
		if ([curHotel isOnBoard] && [curHotel sharesInBank] > 0)
			[hotelsWithPurchaseableShares addObject:curHotel];
	}
	return hotelsWithPurchaseableShares;
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

- (AQHotel *)hotelWithNetacquireID:(int)netacquireID;
{
	NSEnumerator *hotelEnumerator = [_hotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject])
		if ([curHotel netacquireID] == netacquireID)
			return curHotel;
	
	return nil;
}

#pragma mark 
#pragma mark Board accessors/setters

- (void)boardTile:(AQTile *)tile isNetacquireChainID:(int)netacquireChainID;
{
	if ([[self activePlayer] hasTileNamed:[tile description]]) {
		[[self activePlayer] playedTileNamed:[tile description]];
		[_gameWindowController updateTileRack:[[self activePlayer] tiles]];
	}
	
	AQTileState newTileState = [self tileStateFromChainID:netacquireChainID];
	if ([tile state] == AQTileInHotel && [tile hotel] != [self hotelFromChainID:netacquireChainID])
		[[tile hotel] removeTilesFromBoard];
	
	if (newTileState == AQTileInHotel) {
		[[self hotelFromChainID:netacquireChainID] addTile:tile];
	}
	else
		[tile setState:newTileState];
	
	[_gameWindowController tilesChanged:[NSArray arrayWithObject:tile]];
}

- (void)boardTileAtNetacquireID:(int)netacquireID isNetacquireChainID:(int)netacquireChainID;
{
	[self boardTile:[_board tileFromNetacquireID:netacquireID] isNetacquireChainID:netacquireChainID];
}

- (AQTileState)tileStateFromChainID:(int)chainID;
{
	if (chainID == 0 || chainID == 12632256)
		return AQTileNotInHotel;
	
	if ([self hotelFromChainID:chainID] != nil)
		return AQTileInHotel;
	
	return AQTileUnplayed;
}

#pragma mark 
#pragma mark UI

- (void)loadGameWindow;
{
	if (_gameWindowController == nil)
		_gameWindowController = [[AQGameWindowController alloc] initWithGame:self];
	[self _updateGameWindow];
}

- (void)tileClickedString:(NSString *)tileClickedString;
{
  if (![[self localPlayer] isEqual:[self activePlayer]])
		return;
	
	if (![[self activePlayer] hasTileNamed:tileClickedString] && !DEBUG_ALLOW_PLAYING_OF_ANY_TILE)
		return;
	
	if (_tilePlayedThisTurn)
		return;
	
	[_gameWindowController tilesChanged:[[self activePlayer] tiles]];
	[_gameWindowController disableTileRack];
	
	AQTile *clickedTile = [_board tileOnBoardByString:tileClickedString];
	
	if ([self playedTileCreatesNewHotel:clickedTile] && 
	    [[self hotelsNotOnBoard] count] == 0)
		return;
	
	if ([self tileIsUnplayable:clickedTile])
		return;
	
	[_associatedConnection playTileAtRackIndex:([[self activePlayer] rackIndexOfTileNamed:tileClickedString] + 1)];
	_tilePlayedThisTurn = YES;
	
	if (![self gameCanEnd])
	{
		[_gameWindowController hideEndCurrentTurnButton];
		[_gameWindowController hideEndGameButton];
	}
}

#pragma mark 
#pragma mark Game actions

- (void)endCurrentTurn;
{
	[self purchaseShares:_finalTurnSharesPurchased
         ofHotelsNamed:_finalTurnHotelNames
               endGame:NO
                sender:self];
	
	[_gameWindowController hidePurchaseSharesButton];
	[_gameWindowController hideEndCurrentTurnButton];
	[_gameWindowController hideEndGameButton];
}

- (BOOL)gameCanEnd;
{
	NSArray *hotelsOnBoard = [self hotelsOnBoard];
	NSEnumerator *hotelEnumerator = [hotelsOnBoard objectEnumerator];
	AQHotel *curHotel;
	int safeHotels = 0;
	while (curHotel = [hotelEnumerator nextObject])
	{
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
	[self purchaseShares:_finalTurnSharesPurchased
         ofHotelsNamed:_finalTurnHotelNames
               endGame:YES
                sender:self];
	
	[_gameWindowController hidePurchaseSharesButton];
	[_gameWindowController hideEndCurrentTurnButton];
	[_gameWindowController hideEndGameButton];
}

- (NSArray *)winningPlayers;
{
	NSMutableArray *playersWithMostCash = [NSMutableArray arrayWithCapacity:6];
	NSEnumerator *playerEnumerator = [_players objectEnumerator];
	AQPlayer *curPlayer;
	while (curPlayer = [playerEnumerator nextObject])
	{
		if ([playersWithMostCash count] == 0)
		{
			[playersWithMostCash addObject:curPlayer];
			continue;
		}
		if ([curPlayer cash] > [[playersWithMostCash objectAtIndex:0] cash])
		{
			playersWithMostCash = [NSMutableArray arrayWithCapacity:5];
			[playersWithMostCash addObject:curPlayer];
			continue;
		}
		if ([curPlayer cash] == [[playersWithMostCash objectAtIndex:0] cash])
			[playersWithMostCash addObject:curPlayer];
	}
	return playersWithMostCash;
}

- (void)determineAndCongratulateWinner;
{
	if (_winnerCongratulated)
		return;
	
	_winnerCongratulated = YES;
	_isOn = NO;
	[_gameWindowController congratulateWinnersByName:[self winningPlayers]];
	
	[_gameWindowController disableBoardAndTileRack];
}

- (void)enteringTestMode;
{
	_isInTestMode = YES;
	[_gameWindowController enteringTestMode];
	[self _updateGameWindow];
}

- (void)exitingTestMode;
{
	_isInTestMode = NO;
	[_gameWindowController exitingTestMode];
	[self _updateGameWindow];
}

#pragma mark 
#pragma mark Turn actions

- (BOOL)tileIsUnplayable:(AQTile *)tile;
{
	NSArray *adjacentHotels = [self hotelsAdjacentToTile:tile];
	if ([adjacentHotels count] < 2)
		return NO;
	
	int safeAdjacentHotels = 0;
	NSEnumerator *hotelEnumerator = [adjacentHotels objectEnumerator];
	AQHotel *curHotel;
	while (curHotel = [hotelEnumerator nextObject])
	{
		if ([curHotel isSafe])
			++safeAdjacentHotels;
	}
	return (safeAdjacentHotels > 1);
}

- (AQHotel *)playedTileAddsToAHotel:(AQTile *)playedTile;
{
	NSArray *adjacentHotels = [self hotelsAdjacentToTile:playedTile];
	if ([adjacentHotels count] == 1)
    return [adjacentHotels objectAtIndex:0];
	else
    return nil;
}

- (BOOL)playedTileCreatesNewHotel:(AQTile *)playedTile;
{
	NSArray *orthogonalTiles = [_board tilesOrthogonalToTile:playedTile];
	BOOL isATileNotInHotel = NO;
	NSEnumerator *adjacentTileEnumerator = [orthogonalTiles objectEnumerator];
	AQTile *curOrthogonalTile;
	while (curOrthogonalTile = [adjacentTileEnumerator nextObject])
	{
		if ([curOrthogonalTile state] == AQTileNotInHotel)
			isATileNotInHotel = YES;
		else if ([curOrthogonalTile state] == AQTileInHotel)
			return NO;
	}
	return isATileNotInHotel;
}

- (void)createHotelNamed:(NSString *)hotelName atTile:(AQTile *)tile;
{
  AQHotel *hotel = [self hotelNamed:hotelName];
	[_associatedConnection choseHotelToCreate:[hotel netacquireID]];
}

- (BOOL)playedTileTriggersAMerger:(AQTile *)playedTile;
{
	return ([[self hotelsAdjacentToTile:playedTile] count] > 1);
}

- (void)hotelSurvives:(AQHotel*)hotel
        mergingHotels:(NSArray*)mergingHotels
            mergeTile:(AQTile*)mergeTile;
{
	[_associatedConnection selectedMergeSurvivor:[hotel netacquireID]];
}

- (void)sellSharesOfHotel:(AQHotel*)hotel
           numberOfShares:(int)numberOfShares
                   player:(AQPlayer*)player
               sharePrice:(int)sharePrice;
{
	[player subtractSharesOfHotelNamed:[hotel name] numberOfShares:numberOfShares];
	[player addCash:(sharePrice * numberOfShares)];
	[hotel addSharesToBank:numberOfShares];
	
	NSString *plural = (numberOfShares > 1) ? @"s" : @"";
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ sold %d share%@ of %@ for $%d", [player name], numberOfShares, plural, [hotel oldName], (sharePrice * numberOfShares)]];
	
	[_gameWindowController reloadScoreboard];
}

- (void)tradeSharesOfHotel:(AQHotel*)fromHotel
          forSharesInHotel:(AQHotel*)toHotel
            numberOfShares:(int)numberOfShares
                    player:(AQPlayer*)player;
{
	[fromHotel addSharesToBank:numberOfShares];
	[toHotel removeSharesFromBank:(numberOfShares / 2)];
	[player addSharesOfHotelNamed:[toHotel name]
                 numberOfShares:(numberOfShares / 2)];
	
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ traded %d shares of %@ for %d shares of %@", [player name], numberOfShares, [fromHotel oldName], (numberOfShares / 2), [toHotel oldName]]];
	
	[_gameWindowController reloadScoreboard];
}

- (void)showCreateNewHotelSheet;
{
	[self _showCreateNewHotelSheetWithHotels:[self hotelsNotOnBoard] tile:nil];
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

- (void)showAllocateMergingHotelSharesSheetForHotelWithNetacquireID:(int)mergingHotelNetacquireID survivingHotelNetacquireID:(int)survivingHotelNetacquireID;
{
	[self _showAllocateMergingHotelSharesSheetForMergingHotel:[self hotelWithNetacquireID:mergingHotelNetacquireID] survivingHotel:[self hotelWithNetacquireID:survivingHotelNetacquireID] player:[self localPlayer] sharePrice:0];
}

- (void)mergerSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
{
	[_associatedConnection mergerSharesSold:sharesSold sharesTraded:sharesTraded];
}

- (void)getPurchaseWithGameEndFlag:(int)gameEndFlag cash:(int)cash;
{
	[_gameWindowController tilesChanged:[[self localPlayer] tiles]];
	[[self localPlayer] setCash:cash];
	[self _showPurchaseSharesSheetWithHotels:[self hotelsWithPurchaseableShares]];
}

#pragma mark 
#pragma mark Passthrus

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

- (void)disableBoardAndTileRack;
{
	[_gameWindowController disableBoardAndTileRack];
}

- (void)closeGameWindow;
{
	[_gameWindowController closeGameWindow];
}

- (void)bringGameWindowToFront;
{
	[_gameWindowController bringGameWindowToFront];
}

- (void)incomingGameMessage:(NSString *)gameMessage;
{
	[_gameWindowController incomingGameMessage:gameMessage];
}

- (void)outgoingGameMessage:(NSString *)gameMessage;
{
	[_associatedConnection outgoingGameMessage:gameMessage];
}

- (void)incomingGameLogEntry:(NSString *)gameLogEntry;
{
	[_gameWindowController incomingGameLogEntry:gameLogEntry];
}

@end


#pragma mark -

@implementation AQGame (Private)
#pragma mark Private implementation

#pragma mark 
#pragma mark init/dealloc

// This init method gets called by both init methods in the LocalGame and NetworkGame categories.
- (id)_initGameWithArrayController:(id)arrayController;
{
	if (![super init])
		return nil;
	
	_arrayController = [arrayController retain];
	_gameWindowController = nil;
	
	_board = [[AQBoard alloc] init];
	_hotels = [[AQGame initialHotelsArray] retain];
	_players = [[NSMutableArray arrayWithCapacity:6] retain];
	_localPlayerName = nil;
	_tilePlayedThisTurn = NO;
	_finalTurnSharesPurchased = nil;
	_finalTurnHotelNames = nil;
	_isReadyToStart = NO;
	_isOn = NO;
	_localPlayerTilesDrawn = 0;
	_winnerCongratulated = NO;

	return self;
}

#pragma mark 
#pragma mark UI

- (void)_updateGameWindow;
{
	if (_isInTestMode)
		[_gameWindowController setWindowTitle:[NSString stringWithFormat:@"Acquire Game hosted at %@ – Test Mode", [_associatedConnection connectedHostOrIPAddress]]];
	else
		[_gameWindowController setWindowTitle:[NSString stringWithFormat:@"Acquire Game hosted at %@", [_associatedConnection connectedHostOrIPAddress]]];
}

- (void)_tilePlayed:(AQTile *)tile;
{
	_tilePlayedThisTurn = YES;
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ played tile %@.", [[self activePlayer] name], [tile description]]];
	
	[_gameWindowController tilesChanged:[[self activePlayer] tiles]];
	[_gameWindowController tilesChanged:[NSArray arrayWithObject:tile]];
	[[self activePlayer] playedTileNamed:[tile description]];
	[_gameWindowController updateTileRack:[[self activePlayer] tiles]];
}

#pragma mark 
#pragma mark Sheet showings

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
	[_gameWindowController showAllocateMergingHotelSharesSheetForMergingHotel:mergingHotel survivingHotel:survivingHotel player:player sharePrice:(int)sharePrice];
}

- (void)_showPurchaseSharesSheetWithHotels:(NSArray *)hotels;
{
	[_gameWindowController showPurchaseSharesSheetWithHotels:hotels availableCash:[[self activePlayer] cash]];
}
@end
