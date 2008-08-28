// AQBoard.m
//
// Created April 23, 2008 by nwaite

#import "AQBoard.h"

@interface AQBoard (Private)
- (void)_createTileMatrixAndFillTileBag;
@end


@implementation AQBoard
- (id)init;
{
    if (![super init])
		return nil;
	
	srand([[NSDate date] timeIntervalSince1970]);

	_rowNames = [[NSArray arrayWithObjects: 
	              [NSString stringWithString:@"A"], 
	              [NSString stringWithString:@"B"], 
	              [NSString stringWithString:@"C"],
	              [NSString stringWithString:@"D"],
	              [NSString stringWithString:@"E"],
	              [NSString stringWithString:@"F"],
	              [NSString stringWithString:@"G"],
	              [NSString stringWithString:@"H"],
	              [NSString stringWithString:@"I"],
	              nil] retain];
      
	_tileBag = [[NSMutableArray alloc] init];
	[self _createTileMatrixAndFillTileBag];

    return self;
}

- (void)dealloc;
{
	[_tileMatrix release];
	_tileMatrix = nil;
	[_tileBag release];
	_tileBag = nil;
	[_rowNames release];
	_rowNames = nil;
	
	[super dealloc];
}


// Row letter <-> integer conversion (A = 0th row, B = 1st row, ..., I = 8th row)
- (int)rowIntFromString: (NSString *)row;
{
    return [_rowNames indexOfObject:row];
}

- (NSString *)rowStringFromInt:(int)row;
{
	return [_rowNames objectAtIndex:row];
}


// Tile accessors
- (AQTile *)tileOnBoardAtColumn:(int)col row:(NSString *)row;
{
    int rowNameAsInt = [_rowNames indexOfObject:row];

    if (rowNameAsInt == NSNotFound || col < 1 || col > 12)
        return nil;

    return [[_tileMatrix objectAtIndex:(col - 1)] objectAtIndex:rowNameAsInt];
}

- (AQTile *)tileOnBoardByString:(NSString *)tile;
{
    if ([tile length] < 2 || [tile length] > 3)
        return nil;
    
	NSString *row;
	int col;
	
	if ([tile length] == 2) {
		col = [[tile substringToIndex:1] intValue];
		row = [tile substringFromIndex:1];
	} else {
		col = [[tile substringToIndex:2] intValue];
		row = [tile substringFromIndex:2];
	}

    return [self tileOnBoardAtColumn:col row:row];
}

- (AQTile *)tileFromTileBag;
{
    int randomTileIndex = rand() % [_tileBag count];
    AQTile *randomTile = [_tileBag objectAtIndex:randomTileIndex];
    [_tileBag removeObjectAtIndex:randomTileIndex];
    
    return randomTile;
}


// Lists of tiles
- (NSArray *)tilesOrthogonalToTile:(AQTile *)tile;
{
	NSMutableArray *ret = [NSMutableArray array];
	int rowAsInt = [_rowNames indexOfObject:[tile row]];
	if (rowAsInt == NSNotFound)
		return nil;
	
	if (rowAsInt > 0)
		[ret addObject:[self tileOnBoardAtColumn:[tile column] row:[_rowNames objectAtIndex:(rowAsInt - 1)]]];

	if (rowAsInt < 8)
		[ret addObject:[self tileOnBoardAtColumn:[tile column] row:[_rowNames objectAtIndex:(rowAsInt + 1)]]];

	if ([tile column] > 1)
		[ret addObject:[self tileOnBoardAtColumn:([tile column] - 1) row:[tile row]]];

	if ([tile column] < 12)
		[ret addObject:[self tileOnBoardAtColumn:([tile column] + 1) row:[tile row]]];

	return ret;
}


// Netacquire selectors
- (AQTile *)tileFromNetacquireID:(int)netacquireID;
{
	// Figure out what tile we're talking about.
	int column = ((netacquireID - 1) / 9) + 1;
	int rowInt = (netacquireID - 1) % 9;
	if (rowInt == -1)
		rowInt = 8;
	
	return [self tileOnBoardAtColumn:column row:[self rowStringFromInt:rowInt]];
}
@end


@implementation AQBoard (Private)
- (void)_createTileMatrixAndFillTileBag;
{
    NSMutableArray  *columns = [NSMutableArray array];
    NSMutableArray  *currentRow;
    AQTile          *currentTile;
    int             currentColumnAsInt;
    int             currentRowAsInt;

	for (currentColumnAsInt = 1; currentColumnAsInt < 13; ++currentColumnAsInt) {
		currentRow = [NSMutableArray array];
		
		for (currentRowAsInt = 0; currentRowAsInt < [_rowNames count]; ++currentRowAsInt) {
			currentTile = [[AQTile alloc] initWithColumn:currentColumnAsInt row:[_rowNames objectAtIndex:currentRowAsInt]];
			[currentRow addObject:currentTile];
			[_tileBag addObject:currentTile];
		}
		
		[columns addObject:[NSArray arrayWithArray:currentRow]];
	}
	
	_tileMatrix = [[NSArray arrayWithArray:columns] retain];
}
@end
