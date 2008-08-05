// AQGameWindowController.h
// GameWindowController handles the connection between the game window and the game.
//
// Created May 28, 2008 by nwaite

#import "AQCreateNewHotelSheetController.h"
#import "AQPurchaseSharesSheetController.h"

@interface AQGameWindowController : NSObject
{
	IBOutlet id				_game;
	IBOutlet NSWindow		*_gameWindow;
	IBOutlet NSMatrix		*_boardMatrix;
	IBOutlet NSMatrix		*_tileRackMatrix;
	IBOutlet NSTableView	*_scoreboardTableView;
	IBOutlet NSTabView		*_gameChatAndLogTabView;
	IBOutlet NSTextView		*_gameChatTextView;
	IBOutlet NSTextView		*_gameLogTextView;
	IBOutlet NSTextField	*_messageToGameTextField;
	IBOutlet NSButton		*_purchaseSharesButton;
	IBOutlet NSButton		*_endGameButton;
	
	AQCreateNewHotelSheetController	*_createNewHotelSheetController;
	AQPurchaseSharesSheetController	*_purchaseSharesSheetController;
	
	NSColor	*_tileUnplayedColor;
}

- (id)init;
- (void)dealloc;

// NSObject (NSNibAwakening)
- (void)awakeFromNib;

- (IBAction)showPurchaseSharesSheet:(id)sender;
- (void)showPurchaseSharesButton;

- (void)reloadScoreboard;
- (void)tilesChanged:(NSArray *)changedTiles;
- (IBAction)tileClicked:(id)sender;
- (void)incomingGameMessage:(NSString *)gameMessage;
- (IBAction)sendGameMessage:(id)sender;
- (void)incomingGameLogEntry:(NSString *)gameLogEntry;
- (void)updateTileRack:(NSArray *)tiles;
- (void)highlightTilesOnBoard:(NSArray *)tilesToHighlight;

// NSTableDataSource informal protocol
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

// Window visibility
- (void)closeGameWindow;
- (void)bringGameWindowToFront;
- (void)setWindowTitle:(NSString *)windowTitle;
- (void)removeGameChatTabViewItem;

// Passthrus
- (void)showPurchaseSharesSheetWithHotels:(NSArray *)hotels availableCash:(int)availableCash;
- (void)showCreateNewHotelSheetWithHotels:(NSArray *)hotels;
- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames;
- (void)createHotelNamed:(NSString *)hotelName;
@end
