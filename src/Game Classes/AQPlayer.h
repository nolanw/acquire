// AQPlayer.h
// Player represents an Acquire player: his name, cash, shares and tiles.
//
// Created May 16, 2008 by nwaite

#import "AQTile.h"

@interface AQPlayer : NSObject {
    NSString            *_name;
    int                 _cash;
    NSMutableDictionary *_sharesByHotelName;
	NSMutableArray		*_tiles;
}

- (id)initWithName:(NSString *)newName;
+ (AQPlayer *)playerWithName:(NSString *)playerName;
- (void)dealloc;

// Identifying characteristics
- (NSString *)name;

// Money
- (int)cash;
- (void)addCash:(int)dollars;
- (void)subtractCash:(int)dollars;

// Tiles
- (BOOL)hasTileNamed:(NSString *)tileName;
- (void)playedTileNamed:(NSString *)tileName;
- (void)drewTile:(AQTile *)tileName;
- (NSArray *)tilesAsStrings;
- (int)numberOfTiles;

// Shares
- (BOOL)hasSharesOfHotelNamed:(NSString *)hotelName;
- (int)numberOfSharesOfHotelNamed:(NSString *)hotelName;
- (void)addSharesOfHotelNamed:(NSString *)hotelName numberOfShares:(int)numShares;
- (void)subtractSharesOfHotelNamed:(NSString *)hotelName numberOfShares:(int)numShares;
- (NSEnumerator *)namesOfHotelsInWhichAShareIsOwnedEnumerator;

// Netacquire selectors
- (void)drewTile:(AQTile *)tile atRackIndex:(int)rackIndex;
- (int)rackIndexOfTileNamed:(NSString *)tileName;
@end
