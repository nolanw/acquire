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
}

- (id)init;
- (void)dealloc;

// NSObject (NSNibAwakening)
- (void)awakeFromNib;

- (void)updateScoreboard;
- (void)tilesChanged:(NSArray *)changedTiles;
- (void)incomingGameMessage:(NSString *)gameMessage;
- (IBOutlet)sendGameMessage:(id)sender;

// Window visibility
- (void)closeGameWindow;
- (void)bringGameWindowToFront;
@end
