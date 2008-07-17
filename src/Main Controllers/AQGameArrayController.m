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

	return self;
}

- (void)dealloc;
{
	[_gameArray release];
	_gameArray = nil;
	
	[super dealloc];
}


// Accessors/setters/etc.
- (AQGame *)startNewNetworkGame;
{
	[_gameArray addObject:[[AQGame alloc] initNetworkGameWithArrayController:self]];
	
	return [_gameArray lastObject];
}

- (AQGame *)startNewLocalGame;
{
	[_gameArray addObject:[[AQGame alloc] initLocalGameWithArrayController:self]];
	
	return [_gameArray lastObject];
}

- (void)startNewNetworkGameAndMakeActive;
{
	if ([_gameArray count] == 0)
		[self startNewNetworkGame];
	else
		[_gameArray insertObject:[[AQGame alloc] initNetworkGameWithArrayController:self] atIndex:0];
}

- (void)startNewLocalGameAndMakeActive;
{
	if ([_gameArray count] == 0)
		[self startNewLocalGame];
	else
		[_gameArray insertObject:[[AQGame alloc] initLocalGameWithArrayController:self] atIndex:0];
}

- (void)removeGame:(AQGame *)game;
{
	[_gameArray removeObject:game];
}

- (AQGame *)activeGame;
{
	if ([_gameArray count] == 0)
		return nil;
	
	return [_gameArray objectAtIndex:0];
}

- (AQGame *)gameAtIndex:(int)index;
{
	if (index < 0 || index >= [_gameArray count])
		return nil;
	
	return [_gameArray objectAtIndex:index];
}
@end
