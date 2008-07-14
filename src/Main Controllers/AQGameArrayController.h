// AQGameArrayController.h
// GameArrayController manages instances of Game, each of which represent a game of Acquire.
//
// Created May 26, 2008 by nwaite

#import "AQGame.h"
#import "AQGameWindowController.h"

@interface AQGameArrayController : NSObject
{
	NSMutableArray	*_gameArray;
}

- (id)init;
- (void)dealloc;

// Accessors/setters/etc.
- (AQGame *)startNewGame;
- (void)startNewGameAndMakeActive;
- (void)removeGame:(AQGame *)game;
- (AQGame *)activeGame;
- (AQGame *)gameAtIndex:(int)index;
@end
