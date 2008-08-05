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


- (NSString *)description;
{
	return [NSString stringWithFormat:@"%d%@", [self column], [self row]];
}


// Accessors/setters
- (int)column {
	return _col;
}

- (NSString *)row {
	return _row;
}

- (int)rowInt;
{
	if ([[self row] isEqualToString:@"A"])
		return 0;
	if ([[self row] isEqualToString:@"B"])
		return 1;
	if ([[self row] isEqualToString:@"C"])
		return 2;
	if ([[self row] isEqualToString:@"D"])
		return 3;
	if ([[self row] isEqualToString:@"E"])
		return 4;
	if ([[self row] isEqualToString:@"F"])
		return 5;
	if ([[self row] isEqualToString:@"G"])
		return 6;
	if ([[self row] isEqualToString:@"H"])
		return 7;
	if ([[self row] isEqualToString:@"I"])
		return 8;
	
	return -1;
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
	if (newHotel != nil)
		_state = AQTileInHotel;
}


// Equality
- (BOOL)isEqualToTile:(AQTile *)otherTile;
{
	return [[self description] isEqualToString:[otherTile description]];
}
@end
