// AQGameArrayController.h
// GameArrayController manages instances of Game, each of which represent a game of Acquire.
//
// Created May 26, 2008 by nwaite

#import "AQGame.h"

@interface AQGameArrayController : NSObject
{
	NSMutableArray	*_gameArray;
	AQGame			*_activeGame;
}

- (id)init;
- (void)dealloc;

// Accessors/setters/etc.
- (AQGame *)activeGame;
@end
