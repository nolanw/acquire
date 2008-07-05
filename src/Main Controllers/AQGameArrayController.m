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
}


// Accessors/setters/etc.
- (AQGame *)activeGame;
{
	return _activeGame;
}
@end
