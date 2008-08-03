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
	AQGameWindowController	*_gameWindowController;
	AQConnectionController	*_associatedConnection;
	
	AQBoard			*_board;
	NSArray			*_hotels;
	NSMutableArray	*_players;
	BOOL			_isNetworkGame;
	NSString		*_localPlayerName;
	int				_activePlayerIndex;
	BOOL			_tilePlayedThisTurn;
	AQTile			*_tileCreatingNewHotel;
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
- (AQPlayer *)localPlayer;
- (void)addPlayerNamed:(NSString *)playerName;
- (void)clearPlayers;
- (AQHotel *)hotelNamed:(NSString *)hotelName;
- (void)purchaseShares:(NSArray *)sharesPurchased ofHotelsNamed:(NSArray *)hotelNames;
- (int)sharesAvailableOfHotelNamed:(NSString *)hotelName;
- (void)tileClickedString:(NSString *)tileClickedString;
- (void)createHotel:(AQHotel *)hotel;

- (void)endCurrentTurn;
- (void)startGame;
- (void)endGame;

// Passthrus
- (NSColor *)tileNotInHotelColor;
- (NSColor *)tilePlayableColor;
- (NSColor *)tileUnplayedColor;
- (AQTile *)tileOnBoardByString:(NSString *)tileString;

// Allow objects in loaded nibs to say hi
- (void)registerGameWindowController:(AQGameWindowController *)gameWindowController;
@end

@interface AQGame (NetworkGame)
- (NSString *)localPlayerName;
- (void)setLocalPlayerName:(NSString *)localPlayerName;
- (void)boardTileAtRow:(NSString *)row column:(int)column changedStateTo:(int)newState;
- (void)rackTileAtIndex:(int)index changedStateTo:(int)newState;
- (void)outgoingGameChatMessage:(NSString *)chatMessage;
@end

@interface AQGame (LocalGame)

@end
