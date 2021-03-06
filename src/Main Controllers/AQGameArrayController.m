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
- (AQGame *)startNewGameWithAssociatedConnection:(AQConnectionController *)associatedConnection;
{
	[_gameArray addObject:[[[AQGame alloc] initWithArrayController:self associatedConnection:associatedConnection] autorelease]];
	
	return [_gameArray lastObject];
}

- (void)startNewGameAndMakeActiveWithAssociatedConnection:(AQConnectionController *)associatedConnection;
{
	if ([_gameArray count] == 0)
		[self startNewGameWithAssociatedConnection:associatedConnection];
	else if ([_gameArray objectAtIndex:0] == [NSNull null])
		[_gameArray replaceObjectAtIndex:0 withObject:[[AQGame alloc] initWithArrayController:self associatedConnection:associatedConnection]];
	else
		[_gameArray insertObject:[[[AQGame alloc] initWithArrayController:self associatedConnection:associatedConnection] autorelease] atIndex:0];
}

- (BOOL)isGameInArray:(AQGame *)game;
{
	return [_gameArray containsObject:game];
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
