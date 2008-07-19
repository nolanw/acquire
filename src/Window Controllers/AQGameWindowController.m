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
		if ([curChangedTile state] == AQTileNotInHotel)
			[(CCDColoredButtonCell *)[_boardMatrix cellAtRow:[curChangedTile rowInt] column:([curChangedTile column] - 1)] setButtonColor:[_game tileNotInHotelColor]];
		else if ([curChangedTile state] == AQTileInHotel)
			[(CCDColoredButtonCell *)[_boardMatrix cellAtRow:[curChangedTile rowInt] column:([curChangedTile column] - 1)] setButtonColor:[[curChangedTile hotel] color]];
	}
}

- (void)incomingGameMessage:(NSString *)gameMessage;
{
	if ([[_gameChatTextView textStorage] length] > 0)
		[[_gameChatTextView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];

	NSAttributedString *attributedGameMessage = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", gameMessage]] autorelease];
	[[_gameChatTextView textStorage] appendAttributedString:attributedGameMessage];
	
	// Scroll to bottom found in Cocoa docs
	// http://developer.apple.com/documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/Scrolling.html
	NSPoint newScrollOrigin;

    if ([[_gameChatScrollView documentView] isFlipped]) {
        newScrollOrigin = NSMakePoint(0.0, NSHeight([[_gameChatScrollView documentView] frame]) - NSHeight([[_gameChatScrollView contentView] bounds]));
    } else {
        newScrollOrigin=NSMakePoint(0.0, 0.0);
    }

    [[_gameChatScrollView documentView] scrollPoint:newScrollOrigin];
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
	
	// Scroll to bottom found in Cocoa docs
	// http://developer.apple.com/documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/Scrolling.html
	NSPoint newScrollOrigin;

    if ([[_gameLogScrollView documentView] isFlipped]) {
        newScrollOrigin = NSMakePoint(0.0, NSHeight([[_gameLogScrollView documentView] frame]) - NSHeight([[_gameLogScrollView contentView] bounds]));
    } else {
        newScrollOrigin=NSMakePoint(0.0, 0.0);
    }

    [[_gameLogScrollView documentView] scrollPoint:newScrollOrigin];
}

- (void)updateTileRack:(NSArray *)tiles;
{
	int i;
	for (i = 0; i < [tiles count]; ++i) {
		NSLog(@"%s %@", _cmd, [tiles objectAtIndex:i]);
		[[_tileRackMatrix cellAtRow:0 column:i] setTitle:[[tiles objectAtIndex:i] description]];
	}
	
	for (; i < 6; ++i) {
		[[_tileRackMatrix cellAtRow:0 column:i] setTitle:@""];
		[[_tileRackMatrix cellAtRow:0 column:i] setEnabled:NO];
		[[_tileRackMatrix cellAtRow:0 column:i] setTransparent:YES];
	}
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
			return [NSString stringWithFormat:@"* %@", [[_game playerAtIndex:rowIndex] name]];
		else
			return [[_game playerAtIndex:rowIndex] name];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfSackson"])
		return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Sackson"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfZeta"])
		return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Zeta"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfAmerica"])
		return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"America"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfFusion"])
		return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Fusion"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfHydra"])
		return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Hydra"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfPhoenix"])
		return [NSString stringWithFormat:@"%d", [[_game playerAtIndex:rowIndex] numberOfSharesOfHotelNamed:@"Phoenix"]];
	else if ([[aTableColumn identifier] isEqualToString:@"sharesOfQuantum"])
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
