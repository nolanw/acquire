// AQGame.m
//
// Created May 28, 2008 by nwaite

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
- (void)_showChooseMergerSurvivorSheetWithHotels:(NSArray *)hotels mergeTile:(AQTile *)mergeTile;
- (void)_showAllocateMergingHotelSharesSheetForMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player;

- (NSArray *)_hotelsAdjacentToTile:(AQTile *)tile;
- (NSArray *)_hotelsNotOnBoard;
- (void)_tilePlayed:(AQTile *)tile;
- (void)_mergerHappeningAtTile:(AQTile *)tile;
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
	
	if (![NSBundle loadNibNamed:@"GameWindow" owner:self])
		NSLog(@"%s failed to load GameWindow.nib", _cmd);
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
	
	if ([self isLocalGame])
		[self endCurrentTurn];
}

- (int)sharesAvailableOfHotelNamed:(NSString *)hotelName;
{
	return [(AQHotel *)[self hotelNamed:hotelName] sharesInBank];
}


- (void)tileClickedString:(NSString *)tileClickedString;
{
	if ([self isNetworkGame] && [self localPlayer] != [self activePlayer])
		return;
	
	if (![[self activePlayer] hasTileNamed:tileClickedString])
		return;
	
	if (_tilePlayedThisTurn)
		return;
	
	if ([self isNetworkGame])
		return;
	
	AQTile *clickedTile = [_board tileOnBoardByString:tileClickedString];
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
		[clickedTile setHotel:[self playedTileAddsToAHotel:clickedTile]];
		NSArray *orthogonalTiles = [_board tilesOrthogonalToTile:clickedTile];
		NSEnumerator *orthogonalTilesEnumerator = [orthogonalTiles objectEnumerator];
		id curOrthogonalTile;
		while (curOrthogonalTile = [orthogonalTilesEnumerator nextObject])
			if ([curOrthogonalTile state] == AQTileNotInHotel)
				[curOrthogonalTile setHotel:[self playedTileAddsToAHotel:clickedTile]];
		
		[_gameWindowController tilesChanged:orthogonalTiles];
	} else {
		[clickedTile setState:AQTileNotInHotel];
	}
	
	[self _tilePlayed:clickedTile];
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
}

- (void)hotelSurvives:(AQHotel *)hotel mergingHotels:(NSArray *)mergingHotels mergeTile:(AQTile *)mergeTile;
{
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* %@ is the surviving hotel.", [hotel name]]];
	
	NSMutableArray *disappearingHotels = [NSMutableArray arrayWithArray:mergingHotels];
	[disappearingHotels removeObject:hotel];
	
	id curPlayer;
	int i;
	for (i = [self activePlayerIndex]; i < [_players count]; ++i) {
		curPlayer = [_players objectAtIndex:i];
		NSEnumerator *hotelEnumerator = [disappearingHotels objectEnumerator];
		id curHotel;
		while (curHotel = [hotelEnumerator nextObject])
			if ([curPlayer hasSharesOfHotelNamed:[curHotel name]])
				[self _showAllocateMergingHotelSharesSheetForMergingHotel:curHotel survivingHotel:hotel player:curPlayer];
	}
	
	for (i = 0; i < [self activePlayerIndex]; ++i) {
		curPlayer = [_players objectAtIndex:i];
		NSEnumerator *hotelEnumerator = [disappearingHotels objectEnumerator];
		id curHotel;
		while (curHotel = [hotelEnumerator nextObject])
			if ([curPlayer hasSharesOfHotelNamed:[curHotel name]])
				[self _showAllocateMergingHotelSharesSheetForMergingHotel:curHotel survivingHotel:hotel player:curPlayer];
	}
	
	[self _tilePlayed:mergeTile];
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
	if ([adjacentHotels count] < 2)
		return NO;
	
	int safeAdjacentHotels = 0;
	NSEnumerator *hotelEnumerator = [adjacentHotels objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject])
		if ([curHotel isSafe])
			++safeAdjacentHotels;
	
	return (safeAdjacentHotels < 2);
}

- (AQHotel *)playedTileAddsToAHotel:(AQTile *)playedTile;
{
	NSArray *adjacentHotels = [self _hotelsAdjacentToTile:playedTile];
	return ([adjacentHotels count] == 1) ? [adjacentHotels objectAtIndex:0] : nil;
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
	[[self activePlayer] drewTile:[_board tileFromTileBag]];
	++_activePlayerIndex;
	if (_activePlayerIndex >= [_players count])
		_activePlayerIndex = 0;
	
	[_gameWindowController reloadScoreboard];
	[_gameWindowController updateTileRack:[[self activePlayer] tiles]];
	[_gameWindowController highlightTilesOnBoard:[[self activePlayer] tiles]];
	[_gameWindowController incomingGameLogEntry:[NSString stringWithFormat:@"* It's %@'s turn.", [[self activePlayer] name]]];
	
	_tilePlayedThisTurn = NO;
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
	[_gameWindowController showCreateNewHotelSheetWithHotels:hotels atTile:tile];
}

- (void)_showChooseMergerSurvivorSheetWithHotels:(NSArray *)hotels mergeTile:(AQTile *)mergeTile;
{
	[_gameWindowController showChooseMergerSurvivorSheetWithHotels:hotels mergeTile:mergeTile];
}

- (void)_showAllocateMergingHotelSharesSheetForMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player;
{
	[_gameWindowController showAllocateMergingHotelSharesSheetForMergingHotel:mergingHotel survivingHotel:survivingHotel player:player];
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
	
	[_gameWindowController tilesChanged:[[self activePlayer] tiles]];
	[[self activePlayer] playedTileNamed:[tile description]];
	[_gameWindowController updateTileRack:[[self activePlayer] tiles]];
	
	NSArray *hotelsWithPurchaseableShares = [self _hotelsWithPurchaseableShares];
	if ([hotelsWithPurchaseableShares count] > 0) {
		[self _showPurchaseSharesSheetWithHotels:hotelsWithPurchaseableShares];
		return;
	}
	
	int cheapestSharePrice = 10000;
	NSEnumerator *hotelEnumerator = [hotelsWithPurchaseableShares objectEnumerator];
	id curHotel;
	while (curHotel = [hotelEnumerator nextObject])
		if ([curHotel sharePrice] < cheapestSharePrice)
			cheapestSharePrice = [curHotel sharePrice];

	if (cheapestSharePrice <= [[self activePlayer] cash])
		[self _showPurchaseSharesSheetWithHotels:hotelsWithPurchaseableShares];
	else
		[self endCurrentTurn];
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
	
	NSMutableArray *biggestHotels = [NSMutableArray arrayWithCapacity:4];
	NSEnumerator *hotelsEnumerator = [hotelsInvolvedWithMerger objectEnumerator];
	AQHotel *curHotel;
	while (curHotel = (AQHotel *)[hotelsEnumerator nextObject]) {
		if ([curHotel size] < [(AQHotel *)[biggestHotels objectAtIndex:0] size])
			continue;
		if ([curHotel size] == [(AQHotel *)[biggestHotels objectAtIndex:0] size]) {
			[biggestHotels addObject:curHotel];
			continue;
		}
		[biggestHotels release];
		biggestHotels = [NSMutableArray arrayWithCapacity:3];
		[biggestHotels addObject:curHotel];	
	}
	
	if ([biggestHotels count] == 1) {
		[self hotelSurvives:[biggestHotels objectAtIndex:0] mergingHotels:hotelsInvolvedWithMerger mergeTile:tile];
	} else
		[self _showChooseMergerSurvivorSheetWithHotels:biggestHotels mergingHotels:hotelsInvolvedWithMerger mergeTile:tile];
}
@end
