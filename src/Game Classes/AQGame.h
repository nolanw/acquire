// AQGame.h
// Game represents a game of Acquire.
//
// Created May 28, 2008 by nwaite

#import "AQGameWindowController.h"
#import "AQBoard.h"
#import "AQHotel.h"
#import "AQPlayer.h"

@interface AQGame : NSObject
{
	id						_arrayController;
	AQGameWindowController	*_gameWindowController;
	
	AQBoard	*_board;
	NSArray	*_hotels;
	NSArray	*_players;
	BOOL	_isNetworkGame;
}

- (id)initNetworkGameWithArrayController:(id)gameController;
- (id)initLocalGameWithArrayController:(id)gameController;
- (void)dealloc;

- (BOOL)isNetworkGame;

- (void)loadGameWindow;
- (void)bringGameWindowToFront;

- (void)addPlayerNamed:(NSString *)playerName;

- (void)endGame;

// Allow objects in loaded nibs to say hi
- (void)registerGameWindowController:(AQGameWindowController *)gameWindowController;
@end
