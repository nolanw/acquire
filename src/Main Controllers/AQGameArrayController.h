// AQGameArrayController.h
// GameArrayController manages instances of Game, each of which represent a game of Acquire.
//
// Created May 26, 2008 by nwaite

@interface AQGameArrayController : NSObject
{
	NSMutableArray	*_gameArray;
}

- (id)init;
@end
