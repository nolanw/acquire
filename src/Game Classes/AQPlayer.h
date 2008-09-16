// AQPlayer.h
// Player represents an Acquire player: his name, cash, shares and tiles.
//
// Created May 16, 2008 by nwaite

#import "AQTile.h"

#pragma mark -
@interface AQPlayer : NSObject
#pragma mark Interface
{
    NSString            *_name;
    int                 _cash;
    NSMutableDictionary *_sharesByHotelName;
	NSMutableArray		*_tiles;
}

// Class methods
+ (AQPlayer *)playerWithName:(NSString *)playerName;

// Instance methods
// init/dealloc
- (id)initWithName:(NSString *)newName;
- (void)dealloc;

// Identifying characteristics
- (NSString *)name;

// Money
- (int)cash;
- (void)setCash:(int)dollars;
- (void)addCash:(int)dollars;
- (void)subtractCash:(int)dollars;

// Tiles
- (BOOL)hasTileNamed:(NSString *)tileName;
- (void)playedTileNamed:(NSString *)tileName;
- (NSArray *)tiles;
- (int)numberOfTiles;

// Shares
- (BOOL)hasSharesOfHotelNamed:(NSString *)hotelName;
- (int)numberOfSharesOfHotelNamed:(NSString *)hotelName;
- (void)addSharesOfHotelNamed:(NSString *)hotelName numberOfShares:(int)numShares;
- (void)subtractSharesOfHotelNamed:(NSString *)hotelName numberOfShares:(int)numShares;
- (NSEnumerator *)namesOfHotelsInWhichAShareIsOwnedEnumerator;
@end

#pragma mark -
@interface AQPlayer (LocalGame)
#pragma mark LocalGame interface
// Tiles
- (void)drewTile:(AQTile *)tileName;
@end

#pragma mark -
@interface AQPlayer (NetworkGame)
#pragma mark NetworkGame interface
// Tiles
- (void)drewTile:(AQTile *)tile atRackIndex:(int)rackIndex;
- (int)rackIndexOfTileNamed:(NSString *)tileName;
@end
