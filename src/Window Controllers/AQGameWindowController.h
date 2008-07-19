// AQGameWindowController.h
// GameWindowController handles the connection between the game window and the game.
//
// Created May 28, 2008 by nwaite

@interface AQGameWindowController : NSObject
{
	IBOutlet id				_game;
	IBOutlet NSWindow		*_gameWindow;
	IBOutlet NSMatrix		*_boardMatrix;
	IBOutlet NSMatrix		*_tileRackMatrix;
	IBOutlet NSTableView	*_scoreboardTableView;
	IBOutlet NSTabView		*_gameChatAndLogTabView;
	IBOutlet NSScrollView	*_gameChatScrollView;
	IBOutlet NSTextView		*_gameChatTextView;
	IBOutlet NSScrollView	*_gameLogScrollView;
	IBOutlet NSTextView		*_gameLogTextView;
	IBOutlet NSTextField	*_messageToGameTextField;
}

- (id)init;
- (void)dealloc;

// NSObject (NSNibAwakening)
- (void)awakeFromNib;

- (void)reloadScoreboard;
- (void)tilesChanged:(NSArray *)changedTiles;
- (void)incomingGameMessage:(NSString *)gameMessage;
- (IBAction)sendGameMessage:(id)sender;
- (void)incomingGameLogEntry:(NSString *)gameLogEntry;
- (void)updateTileRack:(NSArray *)tiles;

// NSTableDataSource informal protocol
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

// Window visibility
- (void)closeGameWindow;
- (void)bringGameWindowToFront;
- (void)setWindowTitle:(NSString *)windowTitle;
- (void)removeGameChatTabViewItem;
@end
