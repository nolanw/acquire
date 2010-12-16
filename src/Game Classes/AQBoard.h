// AQBoard.h
// Board represents the Acquire board and all tiles in the game, as well as the tile bag from which new tiles are drawn.
// 
// Created April 23, 2008 by nwaite

#import "AQTile.h"

#pragma mark -

@interface AQBoard : NSObject
#pragma mark Interface

{
	NSArray *_tileMatrix;   // The actual board of tiles
  NSArray *_rowNames;     // Handy array mapping rowAsInt to rowName
}

#pragma mark 
#pragma mark Tile accessors

- (AQTile *)tileOnBoardAtColumn:(int)col row:(NSString *)row;
- (AQTile *)tileOnBoardByString:(NSString *)tileString;
- (AQTile *)tileFromNetacquireID:(int)netacquireID;

#pragma mark 
#pragma mark Lists of tiles

- (NSArray *)tilesOrthogonalToTile:(AQTile *)tile;

@end
