// AQHotel.m
// Hotel represents an Acquire hotel, and also keeps track of available shares in that hotel.
//
// Created April 23, 2008 by nwaite

#import "AQTile.h"

@interface AQHotel : NSObject
{
	NSString		*_name;
	NSString		*_oldName;
	NSColor			*_color;
	NSMutableArray 	*_tilesInHotel;
	int				_sharesInBank;
	int				_tier;
	int				_netacquireID;
}

- (id)initWithName:(NSString *)name tier:(int)tier color:(NSColor *)color;

+ (AQHotel *)sacksonHotel;
+ (AQHotel *)zetaHotel;
+ (AQHotel *)americaHotel;
+ (AQHotel *)fusionHotel;
+ (AQHotel *)hydraHotel;
+ (AQHotel *)phoenixHotel;
+ (AQHotel *)quantumHotel;

+ (NSColor *)tileNotInHotelColor;

- (void)dealloc;

// Identifying characteristics
- (NSString *)name;
- (NSColor *)color;

// Tiles and board
- (BOOL)isOnBoard;
- (void)removeTilesFromBoard;
- (int)size;
- (int)tier;
- (BOOL)isSafe;
- (NSArray *)tiles;
- (void)addTile:(AQTile *)tile;
- (void)addTiles:(NSArray *)tileArray;

// Money and shares
- (int)sharesInBank;
- (void)addSharesToBank:(int)shares;
- (void)removeSharesFromBank:(int)shares;
- (int)sharePrice;
- (int)majorityShareholderBonus;
- (int)minorityShareholderBonus;

// Netacquire selectors
- (int)netacquireID;
- (void)setNetacquireID:(int)netacquireID;

// Equality
- (BOOL)isEqualToHotel:(AQHotel *)hotel;
@end