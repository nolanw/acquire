// AQGame.h
// Game represents a game of Acquire.
//
// Created May 28, 2008 by nwaite

#import "AQGameWindowController.h"

@interface AQGame : NSObject
{
	id						_arrayController;
	AQGameWindowController	*_gameWindowController;
}

- (id)initWithArrayController:(id)gameController;
- (void)dealloc;

- (void)endGame:(id)sender;

// Allow objects in loaded nibs to say hi
- (void)registerGameWindowController:(AQGameWindowController *)gameWindowController;
@end
