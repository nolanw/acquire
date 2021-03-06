// AQGameWindowController.h
// GameWindowController handles the connection between the game window and the game.
//
// Created May 28, 2008 by nwaite

#import "AQAllocateMergingHotelSharesSheetController.h"
#import "AQChooseMergerSurvivorSheetController.h"
#import "AQCreateNewHotelSheetController.h"
#import "AQPurchaseSharesSheetController.h"
#import "AQHotel.h"
#import "AQPlayer.h"

@interface AQGameWindowController : NSObject
{
	id	_game;
	
	IBOutlet NSWindow		*_gameWindow;
	IBOutlet NSMatrix		*_boardMatrix;
	IBOutlet NSMatrix		*_tileRackMatrix;
	IBOutlet NSTableView	*_scoreboardTableView;
	IBOutlet NSTextView		*_gameChatTextView;
	IBOutlet NSTextField	*_messageToGameTextField;
	IBOutlet NSButton		*_purchaseSharesButton;
	IBOutlet NSButton		*_endCurrentTurnButton;
	IBOutlet NSButton		*_endGameButton;
	
	AQAllocateMergingHotelSharesSheetController	*_allocateMergingHotelSharesSheetController;
	AQChooseMergerSurvivorSheetController		*_chooseMergerSurvivorSheetController;
	AQCreateNewHotelSheetController				*_createNewHotelSheetController;
	AQPurchaseSharesSheetController				*_purchaseSharesSheetController;
	
	NSColor	*_tileUnplayedColor;
	BOOL	_justAnnouncedLocalPlayersTurn;
}

- (id)initWithGame:(id)game;
- (void)dealloc;

// NSObject (NSNibAwakening)
- (void)awakeFromNib;

- (IBAction)showPurchaseSharesSheet:(id)sender;
- (void)showPurchaseSharesButton;
- (void)hidePurchaseSharesButton;
- (IBAction)endCurrentTurn:(id)sender;
- (void)showEndCurrentTurnButton;
- (void)hideEndCurrentTurnButton;
- (IBAction)endGame:(id)sender;
- (void)showEndGameButton;
- (void)hideEndGameButton;
- (void)disableBoardAndTileRack;
- (void)enableTileRack;
- (void)disableTileRack;
- (void)updateFirstResponderAndKeyEquivalents;
- (void)purchaseSharesSheetDismissed;

- (void)reloadScoreboard;
- (void)tilesChanged:(NSArray *)changedTiles;
- (IBAction)tileClicked:(id)sender;
- (void)incomingGameMessage:(NSString *)gameMessage;
- (IBAction)sendGameMessage:(id)sender;
- (void)incomingGameLogEntry:(NSString *)gameLogEntry;
- (void)updateTileRack:(NSArray *)tiles;
- (void)highlightTilesOnBoard:(NSArray *)tilesToHighlight;
- (void)congratulateWinnersByName:(NSArray *)winners;
- (void)announceLocalPlayersTurn;
- (void)enteringTestMode;
- (void)exitingTestMode;

// NSTableDataSource informal protocol
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

// Window visibility
- (void)closeGameWindow;
- (void)bringGameWindowToFront;
- (void)setWindowTitle:(NSString *)windowTitle;

// Passthrus
- (void)showPurchaseSharesSheetWithHotels:(NSArray *)hotels availableCash:(int)availableCash;
- (void)showCreateNewHotelSheetWithHotels:(NSArray *)hotels atTile:(id)tile;
- (void)showChooseMergerSurvivorSheetWithMergingHotels:(NSArray *)mergingHotels potentialSurvivors:(NSArray *)potentialSurvivors mergeTile:(id)mergeTile;
- (void)showAllocateMergingHotelSharesSheetForMergingHotel:(AQHotel *)mergingHotel survivingHotel:(AQHotel *)survivingHotel player:(AQPlayer *)player sharePrice:(int)sharePrice;
- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames sender:(id)sender;
- (void)createHotelNamed:(NSString *)hotelName atTile:(id)tile;
- (void)sellSharesOfHotel:(AQHotel *)hotel numberOfShares:(int)numberOfShares player:(AQPlayer *)player sharePrice:(int)sharePrice;
- (void)tradeSharesOfHotel:(AQHotel *)fromHotel forSharesInHotel:(AQHotel *)toHotel numberOfShares:(int)numberOfShares player:(AQPlayer *)player;
- (void)hotelSurvives:(AQHotel *)hotel mergingHotels:(NSArray *)mergingHotels mergeTile:(AQTile *)mergeTile;
- (void)mergerSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
@end
