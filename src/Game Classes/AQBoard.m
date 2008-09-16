// AQBoard.m
//
// Created April 23, 2008 by nwaite

#import "AQBoard.h"

#pragma mark -
@interface AQBoard (Private)
#pragma mark Private interface
- (void)_createTileMatrixAndFillTileBag;
@end

#pragma mark -
@implementation AQBoard
#pragma mark Implementation
- (id)init;
{
    if (![super init])
		return nil;
	
	srand([[NSDate date] timeIntervalSince1970]);
      
	_tileBag = [[NSMutableArray alloc] initWithCapacity:108];
	[self _createTileMatrixAndFillTileBag];

    return self;
}

- (void)dealloc;
{
	[_tileMatrix release];
	_tileMatrix = nil;
	[_tileBag release];
	_tileBag = nil;
	
	[super dealloc];
}


// Tile accessors
- (AQTile *)tileOnBoardAtColumn:(int)col row:(NSString *)row;
{
    int rowNameAsInt = [AQTile rowIntFromString:row];

    if (rowNameAsInt == -1 || col < 1 || col > 12)
        return nil;

    return [[_tileMatrix objectAtIndex:(col - 1)] objectAtIndex:rowNameAsInt];
}

- (AQTile *)tileOnBoardByString:(NSString *)tileString;
{
    if ([tileString length] < 2 || [tileString length] > 3)
        return nil;
	
	if ([tileString length] == 2)
		return [self tileOnBoardAtColumn:[[tileString substringToIndex:1] intValue] row:[tileString substringFromIndex:1]];

    return [self tileOnBoardAtColumn:[[tileString substringToIndex:2] intValue] row:[tileString substringFromIndex:2]];
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
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity:4];
	int rowAsInt = [tile rowInt];
	if (rowAsInt == -1)
		return nil;
	
	if (rowAsInt > 0)
		[ret addObject:[self tileOnBoardAtColumn:[tile column] row:[AQTile rowStringFromInt:(rowAsInt - 1)]]];

	if (rowAsInt < 8)
		[ret addObject:[self tileOnBoardAtColumn:[tile column] row:[AQTile rowStringFromInt:(rowAsInt + 1)]]];

	if ([tile column] > 1)
		[ret addObject:[self tileOnBoardAtColumn:([tile column] - 1) row:[tile row]]];

	if ([tile column] < 12)
		[ret addObject:[self tileOnBoardAtColumn:([tile column] + 1) row:[tile row]]];

	return ret;
}
@end

#pragma mark -
@implementation AQBoard (NetworkGame)
#pragma mark NetworkGame implementation
// Accessors
- (AQTile *)tileFromNetacquireID:(int)netacquireID;
{	
	return [self tileOnBoardAtColumn:[AQTile columnFromNetacquireID:netacquireID] row:[AQTile rowFromNetacquireID:netacquireID]];
}
@end

#pragma mark -
@implementation AQBoard (Private)
#pragma mark Private implementation
- (void)_createTileMatrixAndFillTileBag;
{
    NSMutableArray  *columns = [NSMutableArray array];
    NSMutableArray  *currentRow;
    AQTile          *currentTile;
    int             currentColumnAsInt;
    int             currentRowAsInt;

	for (currentColumnAsInt = 1; currentColumnAsInt < 13; ++currentColumnAsInt) {
		currentRow = [NSMutableArray array];
		
		for (currentRowAsInt = 0; currentRowAsInt < 9; ++currentRowAsInt) {
			currentTile = [[AQTile alloc] initWithColumn:currentColumnAsInt row:[AQTile rowStringFromInt:currentRowAsInt]];
			[currentRow addObject:currentTile];
			[_tileBag addObject:currentTile];
		}
		
		[columns addObject:[NSArray arrayWithArray:currentRow]];
	}
	
	_tileMatrix = [[NSArray arrayWithArray:columns] retain];
}
@end
