// AQHotel.m
// Hotel represents an Acquire hotel, and also keeps track of available shares in that hotel.
//
// Created April 23, 2008 by nwaite

#import "AQTile.h"

#pragma mark -
@interface AQHotel : NSObject
#pragma mark Interface
{
	NSString		*_name;
	NSString		*_oldName;
	NSColor			*_color;
	NSMutableArray 	*_tilesInHotel;
	int				_sharesInBank;
	int				_tier;
	int				_netacquireID;
}

// Class methods
// Standard hotel creators
+ (AQHotel *)sacksonHotel;
+ (AQHotel *)zetaHotel;
+ (AQHotel *)americaHotel;
+ (AQHotel *)fusionHotel;
+ (AQHotel *)hydraHotel;
+ (AQHotel *)quantumHotel;
+ (AQHotel *)phoenixHotel;

// Special colors
+ (NSColor *)tileNotInHotelColor;
+ (NSColor *)tilePlayableColor;
+ (NSColor *)tileUnplayedColor;

// Instance methods
// init/dealloc
/*
	* DO NOT CALL -init DIRECTLY!
	* Use one of the init methods in LocalGame or NetworkGame.
*/
- (void)dealloc;

// Physical characteristics
- (NSString *)name;
- (NSString *)oldName;
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

// Money, shares and bonuses
- (int)sharesInBank;
- (void)addSharesToBank:(int)shares;
- (void)removeSharesFromBank:(int)shares;
- (int)sharePrice;
- (int)majorityShareholderBonus;
- (int)minorityShareholderBonus;
@end

#pragma mark -
@interface AQHotel (LocalGame)
#pragma mark LocalGame interface
// init/dealloc
- (id)initWithName:(NSString *)name oldName:(NSString *)oldName tier:(int)tier color:(NSColor *)color;
@end

#pragma mark -
@interface AQHotel (NetworkGame)
#pragma mark NetworkGame interface
// init/dealloc
- (id)initWithName:(NSString *)name oldName:(NSString *)oldName tier:(int)tier color:(NSColor *)color netacquireID:(int)netacquireID;

// Accessors/setters
- (int)netacquireID;
- (void)setNetacquireID:(int)netacquireID;
@end
