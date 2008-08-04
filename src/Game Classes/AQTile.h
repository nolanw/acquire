// AQTile.m
// Tile represents a tile that could be on the board, in the bag, or on a player's tile rack.
//
// Created April 23, 2008 by nwaite

typedef enum _AQTileState {
    AQTileUnplayed,			// Tile's not even on the board
    AQTileNotInHotel,		// Tile's on the board, but not in a hotel
    AQTileMakingNewHotel,	// Tile just got played and is making a new hotel
    AQTileMerging,			// Tile just got played and is merging hotels
    AQTileInHotel			// Tile is on board and in a hotel
} AQTileState;

@interface AQTile : NSObject {
	int			_col;
	NSString	*_row;
	AQTileState	_state;
	id			_hotel;
}

- (id)initWithColumn:(int)newCol row:(NSString *)newRow;
- (void)dealloc;

- (NSString *)description;

// Accessors/setters
- (int)column;
- (NSString *)row;
- (int)rowInt;
- (AQTileState)state;
- (void)setState:(AQTileState)newState;
- (id)hotel;
- (void)setHotel:(id)newHotel;

// Equality
- (BOOL)isEqualToTile:(AQTile *)otherTile;
@end
