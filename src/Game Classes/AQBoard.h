// AQBoard.h
// Board represents the Acquire board and all tiles in the game, as well as the tile bag from which new tiles are drawn.
// 
// Created April 23, 2008 by nwaite

#import "AQTile.h"

#pragma mark -
@interface AQBoard : NSObject
#pragma mark Interface
{
	NSArray         *_tileMatrix;   // The actual board of tiles
	NSMutableArray  *_tileBag;      // The bag of tiles to draw from
    NSArray         *_rowNames;     // Handy array mapping rowAsInt to rowName
}

- (id)init;
- (void)dealloc;

// Tile accessors
- (AQTile *)tileOnBoardAtColumn:(int)col row:(NSString *)row;
- (AQTile *)tileOnBoardByString:(NSString *)tileString;
- (AQTile *)tileFromTileBag;

// Lists of tiles
- (NSArray *)tilesOrthogonalToTile:(AQTile *)tile;
@end

#pragma mark -
@interface AQBoard (NetworkGame)
#pragma mark NetworkGame interface
// Accessors
- (AQTile *)tileFromNetacquireID:(int)netacquireID;
@end
