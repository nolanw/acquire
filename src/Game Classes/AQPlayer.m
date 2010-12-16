// AQPlayer.m
//
// Created May 16, 2008 by nwaite

#import "AQPlayer.h"

#pragma mark -
@implementation AQPlayer
#pragma mark Implementation
// Class methods
+ (AQPlayer *)playerWithName:(NSString *)playerName;
{
	return [[[self alloc] initWithName:playerName] autorelease];
}


// Instance methods
// init/dealloc
- (id)initWithName:(NSString *)newName;
{
    if (![super init])
		return nil;
	
	_name = [newName copy];
	_cash = 6000;
	_sharesByHotelName = [[NSMutableDictionary alloc] initWithCapacity:7];
  _tiles = [[NSMutableArray alloc] init];
  for (NSInteger i = 0; i < 6; i++)
    [_tiles addObject:[NSNull null]];

    return self;
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

- (void)setCash:(int)dollars;
{
	_cash = dollars;
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
	if (_tiles == nil || [_tiles count] == 0)
		return NO;
	
	NSEnumerator *tileEnum = [_tiles objectEnumerator];
	id curTile;
	while (curTile = [tileEnum nextObject])
	{
		if (curTile != [NSNull null] && 
		    [[curTile description] isEqualToString:tileName])
			return YES;
	}
	
	return NO;
}

- (void)playedTileNamed:(NSString *)tileName;
{
	int i;
	for (i = 0; i < [_tiles count]; ++i) {
		if ([_tiles objectAtIndex:i] != [NSNull null] && 
		    [[[_tiles objectAtIndex:i] description] isEqualToString:tileName])
		{
			[_tiles replaceObjectAtIndex:i withObject:[NSNull null]];
			break;
		}
	}
}

- (NSArray *)tiles;
{
	return _tiles;
}

- (int)numberOfTiles;
{
	if (_tiles == nil)
		return -1;
	
	int numberOfTiles = 0;
	NSEnumerator *tileEnumerator = [_tiles objectEnumerator];
	id curTile;
	while (curTile = [tileEnumerator nextObject])
	{
		if (curTile != [NSNull null])
			++numberOfTiles;
	}
	
	return numberOfTiles;
}

- (void)drewTile:(AQTile *)tile atRackIndex:(int)rackIndex;
{
	if (tile == nil)
		return;
	
	[_tiles replaceObjectAtIndex:(rackIndex - 1) withObject:tile];
}

- (int)rackIndexOfTileNamed:(NSString *)tileName;
{
	int i;
	for (i = 0; i < [_tiles count]; ++i)
	{
    if ([[_tiles objectAtIndex:i] isEqual:[NSNull null]])
			continue;
		if ([[[_tiles objectAtIndex:i] description] isEqualToString:tileName])
			return i;
	}
    
  return -1;
}


// Shares
- (BOOL)hasSharesOfHotelNamed:(NSString *)hotelName;
{
  NSArray *hotelsWithShares = [_sharesByHotelName allKeys];
  if (![hotelsWithShares containsObject:hotelName])
	  return NO;
	else
    return ([_sharesByHotelName objectForKey:hotelName] != nil);
}

- (int)numberOfSharesOfHotelNamed:(NSString *)hotelName;
{
  if (![self hasSharesOfHotelNamed:hotelName])
		return 0;
	else
	  return [(NSNumber *)[_sharesByHotelName objectForKey:hotelName] intValue];
}

- (void)addSharesOfHotelNamed:(NSString *)hotelName numberOfShares:(int)numShares;
{
  if ([self hasSharesOfHotelNamed:hotelName])
  {
    NSNumber *shares = [_sharesByHotelName objectForKey:hotelName];
    int newNumShares = numShares + [shares intValue];
    [_sharesByHotelName setObject:[NSNumber numberWithInt:newNumShares]
                           forKey:hotelName];
  }
  else
  {
    [_sharesByHotelName setObject:[NSNumber numberWithInt:numShares]
                           forKey:hotelName];
  }
}

- (void)subtractSharesOfHotelNamed:(NSString *)hotelName numberOfShares:(int)numShares;
{
	if (![self hasSharesOfHotelNamed:hotelName])
		return;
	
  NSNumber *shares = [_sharesByHotelName objectForKey:hotelName];
	int newNumShares = [shares intValue] - numShares;

	if (newNumShares < 1)
	    [_sharesByHotelName removeObjectForKey:hotelName];
	else
	{
	    [_sharesByHotelName setObject:[NSNumber numberWithInt:newNumShares]
                             forKey:hotelName];
  }
}

- (NSEnumerator *)namesOfHotelsInWhichAShareIsOwnedEnumerator;
{
	return [_sharesByHotelName keyEnumerator];
}

@end
