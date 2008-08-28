// AQPlayer.m
//
// Created May 16, 2008 by nwaite

#import "AQPlayer.h"

@interface AQPlayer (Private)
- (int)_rowIntFromString:(NSString *)row;
- (NSString *)_rowStringFromInt:(int)row;
@end

@implementation AQPlayer
- (id)initWithName:(NSString *)newName;
{
    if (![super init])
		return nil;
	
	_name = [newName copy];
	_cash = 6000;
	_sharesByHotelName = [[NSMutableDictionary alloc] initWithCapacity:7];
	_tiles = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];

    return self;
}

+ (AQPlayer *)playerWithName:(NSString *)playerName;
{
	return [[[self alloc] initWithName:playerName] autorelease];
}

- (void)dealloc;
{
	[_name release];
	_name = nil;
	[_sharesByHotelName release];
	_sharesByHotelName = nil;
	[_tiles release];
	_tiles = nil;
	
	[super dealloc];
}


// Identifying characteristics
- (NSString *)name;
{
    return _name;
}


// Money
- (int)cash;
{
    return _cash;
}

- (void)addCash:(int)dollars;
{
    _cash += dollars;
}

- (void)subtractCash:(int)dollars;
{
    _cash -= dollars;
}


// Tiles
- (BOOL)hasTileNamed:(NSString *)tileName;
{
	if (_tiles == nil)
		return NO;
	
	NSEnumerator *tileEnum = [_tiles objectEnumerator];
	id curTile;
	while (curTile = [tileEnum nextObject]) {
		if (curTile != [NSNull null] && [[curTile description] isEqualToString:tileName]) {
			return YES;
		}
	}
	return NO;
}

- (void)playedTileNamed:(NSString *)tileName;
{
	int i;
	for (i = 0; i < [_tiles count]; ++i) {
		if ([_tiles objectAtIndex:i] != [NSNull null] && [[[_tiles objectAtIndex:i] description] isEqualToString:tileName]) {
			[_tiles replaceObjectAtIndex:i withObject:[NSNull null]];
			break;
		}
	}
}

- (void)drewTile:(AQTile *)tile;
{
	if ([_tiles indexOfObject:[NSNull null]] == NSNotFound) {
		NSLog(@"%s player drew a tile when they already had six; this tile has been removed from the game", _cmd);
		return;
	}
	
	[_tiles replaceObjectAtIndex:[_tiles indexOfObject:[NSNull null]] withObject:tile];
}

- (NSArray *)tiles;
{
	return _tiles;
}

- (int)numberOfTiles;
{
	int numberOfTiles = 0;
	NSEnumerator *tileEnumerator = [_tiles objectEnumerator];
	id curTile;
	while (curTile = [tileEnumerator nextObject])
		if (curTile != [NSNull null])
			++numberOfTiles;
	return numberOfTiles;
}


// Shares
- (BOOL)hasSharesOfHotelNamed:(NSString *)hotelName;
{
    NSArray *hotelsWithShares = [_sharesByHotelName allKeys];
    if (![hotelsWithShares containsObject:hotelName])
		return NO;
	
	if ([_sharesByHotelName objectForKey:hotelName] == nil) {
	    return NO;
	} else {
	    return YES;
	}
}

- (int)numberOfSharesOfHotelNamed:(NSString *)hotelName;
{
    if (![self hasSharesOfHotelNamed:hotelName])
		return 0;
	
	return [(NSNumber *)[_sharesByHotelName objectForKey:hotelName] intValue];
}

- (void)addSharesOfHotelNamed:(NSString *)hotelName numberOfShares:(int)numShares;
{
    if ([self hasSharesOfHotelNamed:hotelName]) {
        int newNumShares = numShares + [(NSNumber *) [_sharesByHotelName objectForKey:hotelName] intValue];
        [_sharesByHotelName setObject: [NSNumber numberWithInt:newNumShares] forKey:hotelName];
    } else {
        [_sharesByHotelName setObject: [NSNumber numberWithInt:numShares] forKey:hotelName];
    }
}

- (void)subtractSharesOfHotelNamed:(NSString *)hotelName numberOfShares:(int)numShares;
{
	if (![self hasSharesOfHotelNamed:hotelName])
		return;
	
	int newNumShares = [(NSNumber *)[_sharesByHotelName objectForKey:hotelName] intValue] - numShares;

	if (newNumShares < 1) {
	    [_sharesByHotelName removeObjectForKey:hotelName];
	} else {
	    [_sharesByHotelName setObject:[NSNumber numberWithInt:newNumShares] forKey:hotelName];
	}
}

- (NSEnumerator *)namesOfHotelsInWhichAShareIsOwnedEnumerator;
{
	return [_sharesByHotelName keyEnumerator];
}


// Netacquire selectors
- (void)drewTile:(AQTile *)tile atRackIndex:(int)rackIndex;
{
	if (tile == nil) {
		NSLog(@"%s tried to draw nil tile", _cmd);
		return;
	}
	
	[_tiles replaceObjectAtIndex:rackIndex withObject:tile];
}

- (int)rackIndexOfTileNamed:(NSString *)tileName;
{
	int i;
	for (i = 0; i < [_tiles count]; ++i) {
		if ([_tiles objectAtIndex:i] == [NSNull null])
			continue;
		if ([[[_tiles objectAtIndex:i] description] isEqualToString:tileName])
			return i;
	}
    
    return -1;
}
@end

@implementation AQPlayer (Private)
- (int)_rowIntFromString:(NSString *)row;
{
	unichar rowChar = [row characterAtIndex:0];
	if (rowChar == 'A')
		return 0;
	if (rowChar == 'B')
		return 1;
	if (rowChar == 'C')
		return 2;
	if (rowChar == 'D')
		return 3;
	if (rowChar == 'E')
		return 4;
	if (rowChar == 'F')
		return 5;
	if (rowChar == 'G')
		return 6;
	if (rowChar == 'H')
		return 7;
	if (rowChar == 'I')
		return 8;

	return -1;
}

- (NSString *)_rowStringFromInt:(int)row;
{
	if (row == 0)
		return @"A";
	if (row == 1)
		return @"B";
	if (row == 2)
		return @"C";
	if (row == 3)
		return @"D";
	if (row == 4)
		return @"E";
	if (row == 5)
		return @"F";
	if (row == 6)
		return @"G";
	if (row == 7)
		return @"H";
	if (row == 8)
		return @"I";
	
	return nil;
}
@end
