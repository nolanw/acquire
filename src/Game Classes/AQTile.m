// AQTile.m
//
// Created April 23, 2008 by nwaite

#import "AQTile.h"


@implementation AQTile
- (id)initWithColumn:(int)newCol row:(NSString *)newRow;
{
	if (![super init])
		return nil;
		
	_col = newCol;
	_row = [newRow copy];
	_state = AQTileUnplayed;
	_hotel = nil;

	return self;
}

- (void)dealloc;
{
	[_row release];
	_row = nil;
	
	[super dealloc];
}


// Accessors/setters
- (int)column {
	return _col;
}

- (NSString *)row {
	return _row;
}

- (AQTileState)state {
	return _state;
}

- (void)setState:(AQTileState)newState {
	_state = newState;
}

- (id)hotel {
	return _hotel;
}

- (void)setHotel:(id)newHotel {
	if (newHotel == _hotel)
		return;

	[_hotel release];
	_hotel = [newHotel retain];
	if (newHotel != nil) {
		_state = AQTileInHotel;
	} else {
		_state = AQTileNotInHotel;
	}
}


// String representation
- (NSString *) string {
    return [NSString stringWithFormat:@"%u%@", _col, _row];
}


// Equality
- (BOOL)isEqualToTile:(AQTile *)otherTile;
{
	return [[self string] isEqualToString:[otherTile string]];
}
@end
