// AQGameWindowController.m
//
// Created May 28, 2008 by nwaite

#import "AQGameWindowController.h"
#import "AQGame.h"
#import "AQTile.h"
#import "CCDColoredButtonCell.h"

@interface AQGameWindowController (Private)
- (void)_labelBoard;
@end

@implementation AQGameWindowController
- (id)init;
{
	if (![super init])
		return nil;
	
	_allocateMergingHotelSharesSheetController = [[AQAllocateMergingHotelSharesSheetController alloc] initWithGameWindowController:self];
	_createNewHotelSheetController = [[AQCreateNewHotelSheetController alloc] initWithGameWindowController:self];
	_purchaseSharesSheetController = [[AQPurchaseSharesSheetController alloc] initWithGameWindowController:self];

	return self;
}

- (void)dealloc;
{
	[_gameWindow close];
	[_gameWindow release];
	_gameWindow = nil;
	
	[_game endGame];
	
	[super dealloc];
}


// NSObject (NSNibAwakening)
- (void)awakeFromNib;
{
	// Tell the Game about us
	[[_gameChatTextView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	[[_gameLogTextView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	[(AQGame *)_game registerGameWindowController:self];
	[self _labelBoard];
	[_scoreboardTableView setDataSource:self];
	
	_tileUnplayedColor = [(CCDColoredButtonCell *)[_boardMatrix cellAtRow:0 column:0] buttonColor];
	
	[_purchaseSharesButton setEnabled:NO];
	[_purchaseSharesButton setTransparent:YES];
	[_endGameButton setEnabled:NO];
	[_endGameButton setTransparent:YES];
}


- (IBAction)showPurchaseSharesSheet:(id)sender;
{	
	[_purchaseSharesSheetController showPurchaseSharesSheet:_gameWindow];
}

- (void)showPurchaseSharesButton;
{
	[_purchaseSharesButton setEnabled:YES];
	[_purchaseSharesButton setTransparent:NO];
}

- (void)hidePurchaseSharesButton;
{
	[_purchaseSharesButton setTransparent:YES];
	[_purchaseSharesButton setEnabled:NO];
}

- (void)registerPurchaseSharesSheetController:(AQPurchaseSharesSheetController *)purchaseSharesSheetController;
{
	if (_purchaseSharesSheetController != nil) {
		NSLog(@"%s Purchase Shares Sheet Controller already registered.", _cmd);
		return;
	}
	
	_purchaseSharesSheetController = purchaseSharesSheetController;
}




- (void)reloadScoreboard;
{
	[_scoreboardTableView reloadData];
}

- (void)tilesChanged:(NSArray *)changedTiles;
{
	NSEnumerator *changedTileEnumerator = [changedTiles objectEnumerator];
	id curChangedTile;
	while (curChangedTile = [changedTileEnumerator nextObject]) {
		if (curChangedTile == [NSNull null])
			continue;
		
		if ([curChangedTile state] == AQTileNotInHotel)
			[[_boardMatrix cellAtRow:[curChangedTile rowInt] column:([curChangedTile column] - 1)] setButtonColor:[_game tileNotInHotelColor]];
		else if ([curChangedTile state] == AQTileInHotel)
			[[_boardMatrix cellAtRow:[curChangedTile rowInt] column:([curChangedTile column] - 1)] setButtonColor:[[curChangedTile hotel] color]];
		else if ([curChangedTile state] == AQTileUnplayed)
			[[_boardMatrix cellAtRow:[curChangedTile rowInt] column:([curChangedTile column] - 1)] setButtonColor:[_game tileUnplayedColor]];
	}
}

- (IBAction)tileClicked:(id)sender;
{
	[_game tileClickedString:[[sender selectedCell] title]];
}

- (void)incomingGameMessage:(NSString *)gameMessage;
{
	if ([[_gameChatTextView textStorage] length] > 0)
		[[_gameChatTextView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];

	NSAttributedString *attributedGameMessage = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", gameMessage]] autorelease];
	[[_gameChatTextView textStorage] appendAttributedString:attributedGameMessage];
	
	[_gameChatTextView scrollRangeToVisible:NSMakeRange([[_gameChatTextView string] length], 0)];
}

- (IBAction)sendGameMessage:(id)sender;
{
	NSString *trimmedGameChatMessage = [[_messageToGameTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if ([trimmedGameChatMessage length] == 0)
		return;

	[_messageToGameTextField setStringValue:@""];

	[_game outgoingGameChatMessage:trimmedGameChatMessage];
}

- (void)incomingGameLogEntry:(NSString *)gameLogEntry;
{
	if ([[_gameLogTextView textStorage] length] > 0)
		[[_gameLogTextView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];

	NSAttributedString *attributedGameLogEntry = [[[NSAttributedString alloc] initWithString:gameLogEntry] autorelease];
	[[_gameLogTextView textStorage] appendAttributedString:attributedGameLogEntry];
	
	[_gameLogTextView scrollRangeToVisible:NSMakeRange([[_gameLogTextView string] length], 0)];
}

- (void)updateTileRack:(NSArray *)tiles;
{
	id curTile;
	int i;
	for (i = 0; i < [tiles count]; ++i) {
		curTile = [tiles objectAtIndex:i];
		if (curTile == [NSNull null]) {
			[[_tileRackMatrix cellAtRow:0 column:i] setEnabled:NO];
			[[_tileRackMatrix cellAtRow:0 column:i] setTransparent:YES];
			[[_tileRackMatrix cellAtRow:0 column:i] setTitle:@""];
		} else {
			[[_tileRackMatrix cellAtRow:0 column:i] setEnabled:YES];
			[[_tileRackMatrix cellAtRow:0 column:i] setTransparent:NO];
			[[_tileRackMatrix cellAtRow:0 column:i] setTitle:[curTile description]];
		}
	}
}

- (void)highlightTilesOnBoard:(NSArray *)tilesToHighlight;
{
	NSEnumerator *tilesToHighlightEnumerator = [tilesToHighlight objectEnumerator];
	id curTile;
	while (curTile = [tilesToHighlightEnumerator nextObject])
		[[_boardMatrix cellAtRow:[curTile rowInt] column:([curTile column] - 1)] setButtonColor:[_game tilePlayableColor]];
}


// NSTableDataSource informal protocol
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
{
	return [_game numberOfPlayers];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
{	
	if (rowIndex >= [_game numberOfPlayers])
		return @"";
	
	if ([[aTableColumn identifier] isEqualToString:@"playerName"])
		if ([_game activePlayerIndex] == rowIndex)
			return [NSString stringWithFormat:@"• %@", [[_game playerAtIndex:rowIndex] name]];
		else
			return [[_game playerAtIndex:rowIndex] name];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfSackson"])
		if ([[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Sackson"] == 0)
			return @"";
		else
			return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Sackson"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfZeta"])
		if ([[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Zeta"] == 0)
			return @"";
		else
			return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Zeta"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfAmerica"])
		if ([[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"America"] == 0)
			return @"";
		else
			return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"America"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfFusion"])
		if ([[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Fusion"] == 0)
			return @"";
		else
			return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Fusion"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfHydra"])
		if ([[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Hydra"] == 0)
			return @"";
		else
			return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Hydra"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfPhoenix"])
		if ([[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Phoenix"] == 0)
			return @"";
		else
			return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Phoenix"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfQuantum"])
		if ([[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Quantum"] == 0)
			return @"";
		else
			return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Quantum"]];
	else if ([[aTableColumn identifier] isEqualToString:@"cash"])
		return [NSString stringWithFormat:@"$%d", [[_game playerAtIndex:rowIndex] cash]];
	
	return @"";
}


// Window visibility
- (void)closeGameWindow;
{
	[_gameWindow close];
}

- (void)bringGameWindowToFront;
{
	[_gameWindow makeKeyAndOrderFront:self];
}

- (void)setWindowTitle:(NSString *)windowTitle;
{
	[_gameWindow setTitle:windowTitle];
}

- (void)removeGameChatTabViewItem;
{
	[_gameChatAndLogTabView removeTabViewItem:[_gameChatAndLogTabView tabViewItemAtIndex:0]];
}


// Passthrus
- (void)showPurchaseSharesSheetWithHotels:(NSArray *)hotels availableCash:(int)availableCash;
{
	[_purchaseSharesSheetController resizeAndPopulateMatricesWithHotels:hotels availableCash:availableCash];
	[_purchaseSharesSheetController showPurchaseSharesSheet:_gameWindow];
}

- (void)showCreateNewHotelSheetWithHotels:(NSArray *)hotels;
{
	[_createNewHotelSheetController resizeAndPopulateMatricesWithHotels:hotels];
	[_createNewHotelSheetController showCreateNewHotelSheet:_gameWindow];
}

- (void)showAllocateMergingHotelSharesSheetForMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player;
{
	[_allocateMergingHotelSharesSheetController showAllocateMergingHotelSharesSheet:_gameWindow forMergingHotel:mergingHotel survivingHotel:survivingHotel player:player];
}

- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames;
{
	[_game purchaseShares:sharesPurchased ofHotelsNamed:hotelNames];
	[self hidePurchaseSharesButton];
}

- (void)createHotelNamed:(NSString *)hotelName;
{
	[_game createHotel:[_game hotelNamed:hotelName]];
}

- (void)sellSharesOfHotel:(AQHotel *)hotel numberOfShares:(int)numberOfShares byPlayer:(AQPlayer *)player;
{
	[_game sellSharesOfHotel:hotel numberOfShares:numberOfShares byPlayer:player];
}

- (void)tradeSharesOfHotel:(AQHotel *)fromHotel forSharesInHotel:(AQHotel *)toHotel numberOfShares:(int)numberOfShares byPlayer:(AQPlayer *)player;
{
	[_game tradeSharesOfHotel:fromHotel forSharesInHotel:toHotel numberOfShares:numberOfShares byPlayer:player];
}
@end

@implementation AQGameWindowController (Private)
- (void)_labelBoard;
{
	NSArray *rowNames = [NSArray arrayWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", nil];
	int x, y;
	for (x = 0; x < [rowNames count]; ++x)
		for (y = 0; y < 12; ++y)
			[[_boardMatrix cellAtRow:x column:y] setTitle:[NSString stringWithFormat:@"%d%@", y + 1, [rowNames objectAtIndex:x]]];
}
@end
