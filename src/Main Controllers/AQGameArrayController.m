// AQGameArrayController.m
//
// Created May 26, 2008 by nwaite

#import "AQGameArrayController.h"

@implementation AQGameArrayController
- (id)init;
{
	if (![super init])
		return nil;
	
	_gameArray = [[NSMutableArray arrayWithCapacity:1] retain];
	_activeGame = nil;

	return self;
}

- (void)dealloc;
{
	[_gameArray release];
	_gameArray = nil;
	
	[super dealloc];
}


// Accessors/setters/etc.
- (AQGame *)startNewGame;
{
	[_gameArray addObject:[[[AQGame alloc] initWithArrayController:self] autorelease]];
	return [_gameArray lastObject];
}

- (AQGame *)startNewGameAndMakeActive;
{
	AQGame *newGame = [self startNewGame];
	_activeGame = newGame;
	return newGame;
}

- (void)removeGame:(AQGame *)game;
{
	if (game == [self activeGame])
		_activeGame = nil;
	[_gameArray removeObject:game];
}

- (AQGame *)activeGame;
{
	return _activeGame;
}

- (AQGame *)gameAtIndex:(int)index;
{
	if (index < 0 || index >= [_gameArray count])
		return nil;
	
	return [_gameArray objectAtIndex:index];
}
@end
