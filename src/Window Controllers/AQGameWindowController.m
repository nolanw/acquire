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
- (id)initWithGame:(id)game;
{
	if (![super init])
		return nil;
	
	_game = [game retain];
	
	_allocateMergingHotelSharesSheetController = [[AQAllocateMergingHotelSharesSheetController alloc] initWithGameWindowController:self];
	_chooseMergerSurvivorSheetController = [[AQChooseMergerSurvivorSheetController alloc] initWithGameWindowController:self];
	_createNewHotelSheetController = [[AQCreateNewHotelSheetController alloc] initWithGameWindowController:self];
	_purchaseSharesSheetController = [[AQPurchaseSharesSheetController alloc] initWithGameWindowController:self];
	
	if (_gameWindow == nil) {
		if (![NSBundle loadNibNamed:@"GameWindow" owner:self]) {
			NSLog(@"%s failed to load GameWindow.nib", _cmd);
			return nil;
		}
		
		[_messageToGameTextField setTarget:self];
		[_messageToGameTextField setAction:@selector(sendGameMessage:)];
		
		int i;
		for (i = 0; i < 6; ++i) {
			[[_tileRackMatrix cellAtRow:0 column:i] setTransparent:YES];
			[[_tileRackMatrix cellAtRow:0 column:i] setEnabled:NO];
			[[_tileRackMatrix cellAtRow:0 column:i] setTitle:@""];
		}
	}
	
	[[_gameChatTextView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	[[_gameLogTextView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	[self _labelBoard];
	[_scoreboardTableView setDataSource:self];
	
	_tileUnplayedColor = [(CCDColoredButtonCell *)[_boardMatrix cellAtRow:0 column:0] buttonColor];
	
	[self hidePurchaseSharesButton];
	[self hideEndCurrentTurnButton];
	[self hideEndGameButton];

	return self;
}

- (void)dealloc;
{
	[_gameWindow close];
	[_gameWindow release];
	_gameWindow = nil;
	
	[_game release];
	_game = nil;
	
	[super dealloc];
}


- (IBAction)showPurchaseSharesSheet:(id)sender;
{	
	[_purchaseSharesSheetController showPurchaseSharesSheet:_gameWindow];
}

- (void)showPurchaseSharesButton;
{
	[_purchaseSharesButton setState:NSOffState];
	[_purchaseSharesButton setEnabled:YES];
	[_purchaseSharesButton setTransparent:NO];
	[self updateFirstResponderAndKeyEquivalents];
}

- (void)hidePurchaseSharesButton;
{
	[_purchaseSharesButton setTransparent:YES];
	[_purchaseSharesButton setEnabled:NO];
	[self updateFirstResponderAndKeyEquivalents];
}

- (IBAction)endCurrentTurn:(id)sender;
{
	[_game endCurrentTurn];
}

- (void)showEndCurrentTurnButton;
{
	[_endCurrentTurnButton setState:NSOffState];
	[_endCurrentTurnButton setEnabled:YES];
	[_endCurrentTurnButton setTransparent:NO];
	[self updateFirstResponderAndKeyEquivalents];
}

- (void)hideEndCurrentTurnButton;
{
	[_endCurrentTurnButton setTransparent:YES];
	[_endCurrentTurnButton setEnabled:NO];
	[self updateFirstResponderAndKeyEquivalents];
}

- (IBAction)endGame:(id)sender;
{
	[_game endGame];
}

- (void)showEndGameButton;
{
	[_endGameButton setState:NSOffState];
	[_endGameButton setEnabled:YES];
	[_endGameButton setTransparent:NO];
	[self updateFirstResponderAndKeyEquivalents];
}

- (void)hideEndGameButton;
{
	[_endGameButton setTransparent:YES];
	[_endGameButton setEnabled:NO];
	[self updateFirstResponderAndKeyEquivalents];
}

- (void)disableBoardAndTileRack;
{
	[_boardMatrix setEnabled:NO];
	[_tileRackMatrix setEnabled:NO];
}

- (void)updateFirstResponderAndKeyEquivalents;
{
	[_purchaseSharesButton setKeyEquivalent:@""];
	[_endCurrentTurnButton setKeyEquivalent:@""];
	[_endGameButton setKeyEquivalent:@""];
	
	if ([_purchaseSharesButton isEnabled] && ![_endCurrentTurnButton isEnabled]) {
		[_purchaseSharesButton setKeyEquivalent:@"\r"];
		[_gameWindow makeFirstResponder:_purchaseSharesButton];
		return;
	}
	
	if ([_purchaseSharesButton isEnabled] && [_endCurrentTurnButton isEnabled]) {
		[_purchaseSharesButton setKeyEquivalent:@"\r"];
		[_gameWindow makeFirstResponder:_endCurrentTurnButton];
		return;
	}
	
	if ([_endCurrentTurnButton isEnabled]) {
		[_endCurrentTurnButton setKeyEquivalent:@"\r"];
		[_gameWindow makeFirstResponder:_endCurrentTurnButton];
		return;
	}
	
	if ([_endGameButton isEnabled]) {
		[_endGameButton setKeyEquivalent:@"\r"];
		return;
	}
}

- (void)purchaseSharesSheetDismissed;
{
	[self showPurchaseSharesButton];
	if ([_game gameCanEnd]) {
		[self showEndCurrentTurnButton];
		[self showEndGameButton];
	}
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
	NSString *trimmedGameMessage = [[_messageToGameTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if ([trimmedGameMessage length] == 0)
		return;

	[_messageToGameTextField setStringValue:@""];

	[_game outgoingGameMessage:trimmedGameMessage];
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
	if (tiles == nil)
		return;
	
	id curTile;
	int i;
	for (i = 0; i < [tiles count]; ++i) {
		curTile = [tiles objectAtIndex:i];
		if (curTile == [NSNull null]) {
			[[_tileRackMatrix cellAtRow:0 column:i] setTransparent:YES];
			[[_tileRackMatrix cellAtRow:0 column:i] setEnabled:NO];
			[[_tileRackMatrix cellAtRow:0 column:i] setTitle:@""];
		} else {
			[[_tileRackMatrix cellAtRow:0 column:i] setEnabled:YES];
			[[_tileRackMatrix cellAtRow:0 column:i] setTransparent:NO];
			[[_tileRackMatrix cellAtRow:0 column:i] setTitle:[curTile description]];
		}
	}
	
	for (; i < 6; ++i) {
		[[_tileRackMatrix cellAtRow:0 column:i] setTransparent:YES];
		[[_tileRackMatrix cellAtRow:0 column:i] setEnabled:NO];
		[[_tileRackMatrix cellAtRow:0 column:i] setTitle:@""];
	}
}

- (void)highlightTilesOnBoard:(NSArray *)tilesToHighlight;
{
	NSEnumerator *tilesToHighlightEnumerator = [tilesToHighlight objectEnumerator];
	id curTile;
	while (curTile = [tilesToHighlightEnumerator nextObject]) {
		if (curTile != [NSNull null])
			[[_boardMatrix cellAtRow:[curTile rowInt] column:([curTile column] - 1)] setButtonColor:[_game tilePlayableColor]];
	}
}

- (void)congratulateWinnersByName:(NSArray *)winners;
{
	NSAlert *congratulateWinnerAlert = [[[NSAlert alloc] init] autorelease];
	if ([_game isNetworkGame] && ![winners containsObject:[_game localPlayer]])
		[congratulateWinnerAlert addButtonWithTitle:@"Fiddlesticks."];
	else
		[congratulateWinnerAlert addButtonWithTitle:@"Congratulations!"];
	
	if ([winners count] == 1) {
		[congratulateWinnerAlert setMessageText:NSLocalizedStringFromTable(@"We have a winner!", @"Acquire", @"An announcement that we have a winner.")];
		[congratulateWinnerAlert setInformativeText:[NSString stringWithFormat:@"%@ %@", [[winners objectAtIndex:0] name], NSLocalizedStringFromTable(@"has won the game!", @"Acquire", @"Text saying someone has won the game")]];
	} else {
		[congratulateWinnerAlert setMessageText:NSLocalizedStringFromTable(@"We have a tie!", @"Acquire", @"An announcement that we have a tie.")];
		NSMutableString *listOfWinners = [NSMutableString stringWithString:[[winners objectAtIndex:0] name]];
		int i;
		for (i = 1; i < ([winners count] - 1); ++i) {
			[listOfWinners appendString:[NSString stringWithFormat:@", %@", [winners objectAtIndex:i]]];
		}
		[listOfWinners appendString:@" and "];
		[listOfWinners appendString:[winners lastObject]];
		[congratulateWinnerAlert setInformativeText:[NSString stringWithFormat:@"%@ %@", listOfWinners, NSLocalizedStringFromTable(@"have won the game!", @"Acquire", @"Text saying multiple people have won the game.")]];
	}
	[congratulateWinnerAlert setAlertStyle:NSInformationalAlertStyle];

	[congratulateWinnerAlert beginSheetModalForWindow:_gameWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
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


// Window delegate
- (void)windowWillClose:(NSNotification *)notification;
{
	if ([notification object] != _gameWindow) {
		NSLog(@"%s wrong window", _cmd);
		return;
	}
	
	[_game removeGameFromArrayController];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"LocalGameWindowClosed" object:self];
}


// Passthrus
- (void)showPurchaseSharesSheetWithHotels:(NSArray *)hotels availableCash:(int)availableCash;
{
	[_purchaseSharesSheetController resizeAndPopulateMatricesWithHotels:hotels availableCash:availableCash];
	[_purchaseSharesSheetController showPurchaseSharesSheet:_gameWindow];
}

- (void)showCreateNewHotelSheetWithHotels:(NSArray *)hotels atTile:(id)tile;
{
	[_createNewHotelSheetController resizeAndPopulateMatricesWithHotels:hotels tile:tile];
	[_createNewHotelSheetController showCreateNewHotelSheet:_gameWindow isNetworkGame:[_game isNetworkGame]];
}

- (void)showChooseMergerSurvivorSheetWithMergingHotels:(NSArray *)mergingHotels potentialSurvivors:(NSArray *)potentialSurvivors mergeTile:(id)mergeTile;
{
	[_chooseMergerSurvivorSheetController resizeAndPopulateMatricesWithMergingHotels:mergingHotels potentialSurvivors:potentialSurvivors mergeTile:mergeTile];
	[_chooseMergerSurvivorSheetController showChooseMergerSurvivorSheet:_gameWindow];
}

- (void)showAllocateMergingHotelSharesSheetForMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player sharePrice:(int)sharePrice;
{
	[_allocateMergingHotelSharesSheetController showAllocateMergingHotelSharesSheet:_gameWindow forMergingHotel:mergingHotel survivingHotel:survivingHotel player:player sharePrice:sharePrice];
}

- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames sender:(id)sender;
{
	[_game purchaseShares:sharesPurchased ofHotelsNamed:hotelNames sender:sender];
}

- (void)createHotelNamed:(NSString *)hotelName atTile:(id)tile;
{
	[_game createHotelNamed:hotelName atTile:tile];
}

- (void)sellSharesOfHotel:(AQHotel *)hotel numberOfShares:(int)numberOfShares byPlayer:(AQPlayer *)player;
{
	[_game sellSharesOfHotel:hotel numberOfShares:numberOfShares byPlayer:player];
}

- (void)tradeSharesOfHotel:(AQHotel *)fromHotel forSharesInHotel:(AQHotel *)toHotel numberOfShares:(int)numberOfShares byPlayer:(AQPlayer *)player;
{
	[_game tradeSharesOfHotel:fromHotel forSharesInHotel:toHotel numberOfShares:numberOfShares byPlayer:player];
}

- (void)hotelSurvives:(AQHotel *)hotel mergingHotels:(NSArray *)mergingHotels mergeTile:(AQTile *)mergeTile;
{
	[_game hotelSurvives:hotel mergingHotels:mergingHotels mergeTile:mergeTile];
}

- (void)sellSharesOfHotel:(AQHotel *)hotel numberOfShares:(int)numberOfShares player:(AQPlayer *)player sharePrice:(int)sharePrice;
{
	[_game sellSharesOfHotel:hotel numberOfShares:numberOfShares player:player sharePrice:sharePrice];
}

- (void)tradeSharesOfHotel:(AQHotel *)fromHotel forSharesInHotel:(AQHotel *)toHotel numberOfShares:(int)numberOfShares player:(AQPlayer *)player;
{
	[_game tradeSharesOfHotel:fromHotel forSharesInHotel:toHotel numberOfShares:numberOfShares player:player];
}

- (BOOL)isNetworkGame;
{
	return [_game isNetworkGame];
}

- (void)mergerSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
{
	[_game mergerSharesSold:sharesSold sharesTraded:sharesTraded];
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
