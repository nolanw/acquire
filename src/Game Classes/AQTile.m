// AQTile.m
//
// Created April 23, 2008 by nwaite

#import "AQTile.h"

#pragma mark -
@implementation AQTile
#pragma mark Implementation
// Class methods
+ (int)rowIntFromString:(NSString *)rowString;
{
	if ([rowString isEqualToString:@"A"])
		return 0;
	if ([rowString isEqualToString:@"B"])
		return 1;
	if ([rowString isEqualToString:@"C"])
		return 2;
	if ([rowString isEqualToString:@"D"])
		return 3;
	if ([rowString isEqualToString:@"E"])
		return 4;
	if ([rowString isEqualToString:@"F"])
		return 5;
	if ([rowString isEqualToString:@"G"])
		return 6;
	if ([rowString isEqualToString:@"H"])
		return 7;
	if ([rowString isEqualToString:@"I"])
		return 8;
	
	return -1;
}

+ (NSString *)rowStringFromInt:(int)rowInt;
{
	if (rowInt == 0)
		return @"A";
	if (rowInt == 1)
		return @"B";
	if (rowInt == 2)
		return @"C";
	if (rowInt == 3)
		return @"D";
	if (rowInt == 4)
		return @"E";
	if (rowInt == 5)
		return @"F";
	if (rowInt == 6)
		return @"G";
	if (rowInt == 7)
		return @"H";
	if (rowInt == 8)
		return @"I";
	
	return nil;
}


// Instance methods
// init/dealloc
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


// NSObject
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
	return [AQTile rowIntFromString:[self row]];
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

#pragma mark -
@implementation AQTile (NetworkGame)
#pragma mark NetworkGame implementation
// Class methods
+ (int)netacquireIDFromTile:(AQTile *)tile;
{
	return ([tile column] * 9) - (8 - [tile rowInt]);
}

+ (int)columnFromNetacquireID:(int)netacquireID;
{
	return ((netacquireID - 1) / 9) + 1;
}

+ (NSString *)rowFromNetacquireID:(int)netacquireID;
{
	return [AQTile rowStringFromInt:((netacquireID - 1) % 9)];
}


// Accessors/setters
- (int)netacquireID;
{
	return [AQTile netacquireIDFromTile:self];
}
@end
