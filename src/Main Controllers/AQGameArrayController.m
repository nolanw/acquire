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
@end
