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
}

- (id)initNetworkGameWithArrayController:(id)arrayController associatedConnection:(AQConnectionController *)associatedConnection;
- (id)initLocalGameWithArrayController:(id)arrayController;
- (void)dealloc;

- (BOOL)isNetworkGame;
- (BOOL)isLocalGame;

- (void)loadGameWindow;
- (void)bringGameWindowToFront;

- (int)numberOfPlayers;
- (AQPlayer *)playerAtIndex:(int)index;
- (AQPlayer *)activePlayer;
- (int)activePlayerIndex;
- (AQPlayer *)playerNamed:(NSString *)name;
- (void)addPlayerNamed:(NSString *)playerName;
- (void)clearPlayers;
- (AQHotel *)hotelNamed:(NSString *)hotelName;
- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames sender:(id)sender;
- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames endGame:(BOOL)endGame sender:(id)sender;
- (int)sharesAvailableOfHotelNamed:(NSString *)hotelName;
- (void)tileClickedString:(NSString *)tileClickedString;
- (void)createHotelNamed:(NSString *)hotelName atTile:(id)tile;
- (void)hotelSurvives:(AQHotel *)hotel mergingHotels:(NSArray *)mergingHotels mergeTile:(AQTile *)mergeTile;
- (void)sellSharesOfHotel:(AQHotel *)hotel numberOfShares:(int)numberOfShares player:(AQPlayer *)player sharePrice:(int)sharePrice;
- (void)tradeSharesOfHotel:(AQHotel *)fromHotel forSharesInHotel:(AQHotel *)toHotel numberOfShares:(int)numberOfShares player:(AQPlayer *)player;
- (BOOL)playedTileCreatesNewHotel:(AQTile *)playedTile;
- (BOOL)playedTileTriggersAMerger:(AQTile *)playedTile;
- (AQHotel *)playedTileAddsToAHotel:(AQTile *)playedTile;
- (BOOL)tileIsUnplayable:(AQTile *)tile;

- (void)endCurrentTurn;
- (void)startGame;
- (BOOL)gameCanEnd;
- (void)endGame;
- (void)removeGameFromArrayController;

// Passthrus
- (NSColor *)tileNotInHotelColor;
- (NSColor *)tilePlayableColor;
- (NSColor *)tileUnplayedColor;
- (AQTile *)tileOnBoardByString:(NSString *)tileString;
- (void)incomingGameMessage:(NSString *)gameMessage;
- (void)incomingGameLogEntry:(NSString *)gameLogEntry;
- (void)disableBoardAndTileRack;
- (void)closeGameWindow;
- (void)showGameWindow;
@end

@interface AQGame (NetworkGame)
- (AQPlayer *)localPlayer;
- (NSString *)localPlayerName;
- (BOOL)isOn;
- (void)setLocalPlayerName:(NSString *)localPlayerName;
- (void)setActivePlayerName:(NSString *)activePlayerName;
- (void)boardTile:(AQTile *)tile isNetacquireChainID:(int)netacquireChainID;
- (void)boardTileAtNetacquireID:(int)netacquireID isNetacquireChainID:(int)netacquireChainID;
- (void)rackTileAtIndex:(int)index isNetacquireID:(int)netacquireID netacquireChainID:(int)netacquireChainID;
- (void)outgoingGameMessage:(NSString *)gameMessage;
- (void)playerAtIndex:(int)playerIndex isNamed:(NSString *)name;
- (void)playerAtIndex:(int)playerIndex hasCash:(int)cash;
- (void)playerAtIndex:(int)playerIndex hasSacksonShares:(int)sacksonShares;
- (void)playerAtIndex:(int)playerIndex hasZetaShares:(int)zetaShares;
- (void)playerAtIndex:(int)playerIndex hasAmericaShares:(int)americaShares;
- (void)playerAtIndex:(int)playerIndex hasFusionShares:(int)fusionShares;
- (void)playerAtIndex:(int)playerIndex hasHydraShares:(int)hydraShares;
- (void)playerAtIndex:(int)playerIndex hasPhoenixShares:(int)phoenixShares;
- (void)playerAtIndex:(int)playerIndex hasQuantumShares:(int)quantumShares;
- (void)getChainFromHotelIndexes:(NSArray *)hotelIndexes;
- (void)chooseMergeSurvivorFromHotelIndexes:(NSArray *)hotelIndexes;
- (void)getPurchaseWithGameEndFlag:(int)gameEndFlag cash:(int)cash;
- (AQTileState)tileStateFromChainID:(int)chainID;
- (AQHotel *)hotelFromChainID:(int)chainID;
- (void)showAllocateMergingHotelSharesSheetForHotelWithNetacquireID:(int)mergingHotelNetacquireID survivingHotelNetacquireID:(int)survivingHotelNetacquireID;
- (void)showCreateNewHotelSheet;
- (void)closeGameWindow;
- (AQHotel *)hotelWithNetacquireID:(int)netacquireID;
- (void)mergerSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
- (void)determineAndCongratulateWinner;
- (BOOL)isReadyToStart;
- (void)setIsReadyToStart:(BOOL)isReadyToStart;
- (void)enteringTestMode;
- (void)exitingTestMode;
@end

@interface AQGame (LocalGame)

@end
