// AQBoard.h
// Board represents the Acquire board and all tiles in the game, as well as the tile bag from which new tiles are drawn.
// 
// Created April 23, 2008 by nwaite

#import "AQTile.h"

@interface AQBoard : NSObject {
	NSArray         *_tileMatrix;   // The actual board of tiles
	NSMutableArray  *_tileBag;      // The bag of tiles to draw from
    NSArray         *_rowNames;     // Handy array mapping rowAsInt to rowName
}

- (id)init;
- (void)dealloc;

// Row letter <-> integer conversion (A = 0th row, B = 1st row, ..., I = 8th row)
- (int)rowIntFromString:(NSString *)row;
- (NSString *)rowStringFromInt:(int)row;

// Tile accessors
- (AQTile *)tileOnBoardAtColumn:(int)col row:(NSString *)row;
- (AQTile *)tileOnBoardByString:(NSString *)tile;
- (AQTile *)tileFromTileBag;

// Lists of tiles
- (NSArray *)tilesOrthogonalToTile:(AQTile *)tile;

// Netacquire selectors
- (AQTile *)getTileByNetacquireID:(int)tileID;
@end
