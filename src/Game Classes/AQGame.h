// AQGame.h
// Game represents a game of Acquire.
//
// Created May 28, 2008 by nwaite

#import "AQGameWindowController.h"
#import "AQConnectionController.h"
#import "AQBoard.h"
#import "AQHotel.h"
#import "AQPlayer.h"
#import "AQTile.h"

#pragma mark -
#pragma mark Interface
@interface AQGame : NSObject
{
	id						_arrayController;
	AQConnectionController	*_associatedConnection;
	
	AQGameWindowController	*_gameWindowController;
	
	AQBoard			*_board;
	NSArray			*_hotels;
	NSMutableArray	*_players;
	BOOL			_isNetworkGame;
	NSString		*_localPlayerName;
	int				_activePlayerIndex;
	BOOL			_tilePlayedThisTurn;
	NSArray			*_finalTurnSharesPurchased;
	NSArray			*_finalTurnHotelNames;
	BOOL			_isReadyToStart;
	BOOL			_isOn;
	int				_localPlayerTilesDrawn;
	BOOL			_isInTestMode;
}

// init/dealloc
/*
	* DO NOT CALL -init DIRECTLY!
	* Use one of the init methods in LocalGame or NetworkGame.
*/
- (void)dealloc;

// Players
- (int)numberOfPlayers;
- (AQPlayer *)playerAtIndex:(int)index;
- (AQPlayer *)activePlayer;
- (int)activePlayerIndex;
- (AQPlayer *)playerNamed:(NSString *)name;
- (void)addPlayerNamed:(NSString *)playerName;
- (void)clearPlayers;

// Hotels
- (NSArray *)initialHotelsArray;
- (AQHotel *)hotelNamed:(NSString *)hotelName;
- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames sender:(id)sender;
- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames endGame:(BOOL)endGame sender:(id)sender;
- (int)sharesAvailableOfHotelNamed:(NSString *)hotelName;
- (NSArray *)hotelsAdjacentToTile:(AQTile *)tile;
- (NSArray *)hotelsNotOnBoard;
- (NSArray *)hotelsOnBoard;
- (NSArray *)hotelsWithPurchaseableShares;

// UI
- (void)loadGameWindow;
- (void)tileClickedString:(NSString *)tileClickedString;

// Game actions
- (void)endCurrentTurn;
- (BOOL)gameCanEnd;
- (void)endGame;
- (NSArray *)winningPlayers;

// Turn actions
- (BOOL)tileIsUnplayable:(AQTile *)tile;
- (AQHotel *)playedTileAddsToAHotel:(AQTile *)playedTile;
- (BOOL)playedTileCreatesNewHotel:(AQTile *)playedTile;
- (void)createHotelNamed:(NSString *)hotelName atTile:(id)tile;
- (BOOL)playedTileTriggersAMerger:(AQTile *)playedTile;
- (void)hotelSurvives:(AQHotel *)hotel mergingHotels:(NSArray *)mergingHotels mergeTile:(AQTile *)mergeTile;
- (void)sellSharesOfHotel:(AQHotel *)hotel numberOfShares:(int)numberOfShares player:(AQPlayer *)player sharePrice:(int)sharePrice;
- (void)tradeSharesOfHotel:(AQHotel *)fromHotel forSharesInHotel:(AQHotel *)toHotel numberOfShares:(int)numberOfShares player:(AQPlayer *)player;

// Passthrus
- (NSColor *)tileNotInHotelColor;
- (NSColor *)tilePlayableColor;
- (NSColor *)tileUnplayedColor;
- (AQTile *)tileOnBoardByString:(NSString *)tileString;
- (void)disableBoardAndTileRack;
- (void)closeGameWindow;
- (void)bringGameWindowToFront;
@end

#pragma mark -
#pragma mark LocalGame interface
@interface AQGame (LocalGame)
// init/dealloc
- (id)initLocalGameWithArrayController:(id)arrayController;

// Accessors/setters
- (BOOL)isLocalGame;

// Pre-game fun
- (void)determineStartingOrder;
- (void)drawTilesForEveryone;

// Game actions
- (void)startGame;
- (void)payPlayersForSharesInHotels:(NSArray *)hotels;

// Turn actions
- (void)mergerHappeningAtTile:(AQTile *)tile;
- (void)payShareholderBonusesForHotels:(NSArray *)hotels;
- (void)showPurchaseSharesSheetIfNeededOrAdvanceTurn;
- (void)checkTileRacksForUnplayableTiles;
@end

#pragma mark -
#pragma mark NetworkGame interface
@interface AQGame (NetworkGame)
// init/dealloc
- (id)initNetworkGameWithArrayController:(id)arrayController associatedConnection:(AQConnectionController *)associatedConnection;

// Accessors/setters
- (BOOL)isNetworkGame;
- (BOOL)isReadyToStart;
- (void)setIsReadyToStart:(BOOL)isReadyToStart;
- (BOOL)isOn;

// Game actions
- (void)determineAndCongratulateWinner;
- (void)enteringTestMode;
- (void)exitingTestMode;

// Turn actions
- (void)showCreateNewHotelSheet;
- (void)chooseMergeSurvivorFromHotelIndexes:(NSArray *)hotelIndexes;
- (void)showAllocateMergingHotelSharesSheetForHotelWithNetacquireID:(int)mergingHotelNetacquireID survivingHotelNetacquireID:(int)survivingHotelNetacquireID;
- (void)mergerSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
- (void)getPurchaseWithGameEndFlag:(int)gameEndFlag cash:(int)cash;

// Board
- (void)boardTile:(AQTile *)tile isNetacquireChainID:(int)netacquireChainID;
- (void)boardTileAtNetacquireID:(int)netacquireID isNetacquireChainID:(int)netacquireChainID;
- (AQTileState)tileStateFromChainID:(int)chainID;

// Hotels
- (void)getChainFromHotelIndexes:(NSArray *)hotelIndexes;
- (AQHotel *)hotelFromChainID:(int)chainID;
- (AQHotel *)hotelWithNetacquireID:(int)netacquireID;

// Players
- (AQPlayer *)localPlayer;
- (NSString *)localPlayerName;
- (void)setLocalPlayerName:(NSString *)localPlayerName;
- (void)setActivePlayerName:(NSString *)activePlayerName isPurchasing:(BOOL)isPurchasing;
- (void)playerAtIndex:(int)playerIndex isNamed:(NSString *)name;
- (void)playerAtIndex:(int)playerIndex hasCash:(int)cash;
- (void)playerAtIndex:(int)playerIndex hasSacksonShares:(int)sacksonShares;
- (void)playerAtIndex:(int)playerIndex hasZetaShares:(int)zetaShares;
- (void)playerAtIndex:(int)playerIndex hasAmericaShares:(int)americaShares;
- (void)playerAtIndex:(int)playerIndex hasFusionShares:(int)fusionShares;
- (void)playerAtIndex:(int)playerIndex hasHydraShares:(int)hydraShares;
- (void)playerAtIndex:(int)playerIndex hasQuantumShares:(int)quantumShares;
- (void)playerAtIndex:(int)playerIndex hasPhoenixShares:(int)phoenixShares;
- (void)rackTileAtIndex:(int)index isNetacquireID:(int)netacquireID netacquireChainID:(int)netacquireChainID;

// passthrus
- (void)incomingGameMessage:(NSString *)gameMessage;
- (void)outgoingGameMessage:(NSString *)gameMessage;
- (void)incomingGameLogEntry:(NSString *)gameLogEntry;
@end
