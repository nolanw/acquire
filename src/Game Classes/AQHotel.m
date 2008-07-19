// AQHotel.m
//
// Created April 23, 2008 by nwaite

#import "AQHotel.h"

@implementation AQHotel
- (id)initWithName:(NSString *)name tier:(int)tier color:(NSColor *)color;
{
	if (![super init])
		return nil;
	
	_name = [name copy];
	_oldName = _name;
	_color = [color retain];
	_tilesInHotel = [[NSMutableArray alloc] init];
	_sharesInBank = 25;
	_tier = tier;
	_netacquireID = -1;

	return self;
}

- (id)initWithName:(NSString *)name tier:(int)tier color:(NSColor *)color oldName:(NSString *)oldName;
{
	if (![super init])
		return nil;
	
	[self initWithName:name tier:tier color:color];
	_oldName = [oldName copy];
	
	return self;
}


+ (AQHotel *)sacksonHotel;
{
	return [[[self alloc] initWithName:@"Sackson" tier:0 color:[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0] oldName:@"Luxor"] autorelease];
}

+ (AQHotel *)zetaHotel;
{
	return [[[self alloc] initWithName:@"Zeta" tier:0 color:[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0] oldName:@"Tower"] autorelease];
}

+ (AQHotel *)americaHotel;
{
	return [[[self alloc] initWithName:@"America" tier:0 color:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0] oldName:@"America"] autorelease];
}

+ (AQHotel *)fusionHotel;
{
	return [[[self alloc] initWithName:@"Fusion" tier:0 color:[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.0] oldName:@"Fusion"] autorelease];
}

+ (AQHotel *)hydraHotel;
{
	return [[[self alloc] initWithName:@"Hydra" tier:0 color:[NSColor colorWithCalibratedRed:1.0 green:0.5 blue:0.0 alpha:1.0] oldName:@"Worldwide"] autorelease];
}

+ (AQHotel *)phoenixHotel;
{
	return [[[self alloc] initWithName:@"Phoenix" tier:0 color:[NSColor colorWithCalibratedRed:1.0 green:0.25 blue:1.0 alpha:1.0] oldName:@"Imperial"] autorelease];
}

+ (AQHotel *)quantumHotel;
{
	return [[[self alloc] initWithName:@"Quantum" tier:0 color:[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:1.0 alpha:1.0] oldName:@"Continental"] autorelease];
}


+ (NSColor *)tileNotInHotelColor;
{
	return [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1.0];
}


- (void)dealloc;
{
	[_name release];
	_name = nil;
	[_color release];
	_color = nil;
	[_tilesInHotel release];
	_tilesInHotel = nil;
	
	[super dealloc];
}


// Identifying characteristics
- (NSString *)name;
{
	return _name;
}

- (NSColor *)color;
{
	return _color;
}


// Tiles and board
- (BOOL)isOnBoard;
{
	return ([_tilesInHotel count] > 0);
}

- (void)removeTilesFromBoard;
{
	[_tilesInHotel removeAllObjects];
}

- (int)size;
{
	return [_tilesInHotel count];
}

- (int)tier;
{
	return _tier;
}

- (BOOL)isSafe;
{
	return ([self size] > 10);
}

- (NSArray *)tiles;
{
	return [NSArray arrayWithArray:_tilesInHotel];
}

- (void)addTile:(AQTile *)tile;
{
	[_tilesInHotel addObject:tile];
	[tile setHotel:self];
}

- (void)addTiles:(NSArray *)tileArray;
{
	NSEnumerator *tileEnumerator = [tileArray objectEnumerator];
	id curTile;
	while (curTile = [tileEnumerator nextObject]) {
		[self addTile:curTile];
	}
}


// Money and shares
- (int)sharesInBank;
{
	return _sharesInBank;
}

- (void)addSharesToBank:(int)shares;
{
	_sharesInBank += shares;
}

- (void)removeSharesFromBank:(int)shares;
{
	_sharesInBank -= shares;
}

- (int)sharePrice;
{
	if (![self isOnBoard])
		return 0;

	if ([self size] < 2)
		return 0;
	
	if ([self size] < 6)
		return (([self size] + [self tier]) * 100);

	if ([self size] < 11)
		return ((6 + [self tier]) * 100);
	
	if ([self size] < 21)
		return ((7 + [self tier]) * 100);
	
	if ([self size] < 31)
		return ((8 + [self tier]) * 100);
	
	if ([self size] < 41)
		return ((9 + [self tier]) * 100);
	
	return ((10 + [self tier]) * 100);
}

- (int)majorityShareholderBonus;
{
	if (![self isOnBoard])
		return 0;
	
	if ([self size] < 2)
		return 0;
	
	return ([self sharePrice] * 10);
}

- (int)minorityShareholderBonus;
{
	if (![self isOnBoard])
		return 0;
	
	if ([self size] < 2)
		return 0;
	
	return ([self sharePrice] * 5);
}


// Netacquire selectors
- (int)netacquireID;
{
	return _netacquireID;
}

- (void)setNetacquireID:(int)netacquireID;
{
	_netacquireID = netacquireID;
}


// Equality
- (BOOL)isEqualToHotel:(AQHotel *)hotel;
{
	return [_name isEqualToString:[hotel name]];
}
@end
