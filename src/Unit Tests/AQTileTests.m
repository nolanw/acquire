//
//  AQTileTests.m
//  Acquire
//
//  Created by Nolan Waite on 01/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AQTileTests.h"


@implementation AQTileTests
- (void)setUp;
{
	tile = [[AQTile alloc] initWithRow:@"A" column:1];
}

- (void)tearDown;
{
	[tile release]; tile = nil;
}

- (void)testTileMethods;
{
	// Object creation
	STAssertNotNil(tile, @"tile creation");
	
	// Class methods
	// rowIntFromString
	STAssertEquals([AQTile rowIntFromString:@"A"], 0, @"rowIntFromString valid string");
	STAssertEquals([AQTile rowIntFromString:@"B"], 1, @"rowIntFromString valid string");
	STAssertEquals([AQTile rowIntFromString:@"H"], 7, @"rowIntFromString valid string");
	STAssertEquals([AQTile rowIntFromString:@"I"], 8, @"rowIntFromString valid string");
	STAssertEquals([AQTile rowIntFromString:@"J"], -1, @"rowIntFromString invalid string");
	STAssertEquals([AQTile rowIntFromString:@"ASDF"], -1, @"rowIntFromString invalid string");
	
	// rowStringFromInt
	STAssertEqualObjects([AQTile rowStringFromInt:0], @"A", @"rowStringFromInt valid string");
	STAssertEqualObjects([AQTile rowStringFromInt:1], @"B", @"rowStringFromInt valid string");
	STAssertEqualObjects([AQTile rowStringFromInt:7], @"H", @"rowStringFromInt valid string");
	STAssertEqualObjects([AQTile rowStringFromInt:8], @"I", @"rowStringFromInt valid string");
	STAssertEqualObjects([AQTile rowStringFromInt:9], nil, @"rowStringFromInt invalid int");
	STAssertEqualObjects([AQTile rowStringFromInt:11], nil, @"rowStringFromInt invalid int");
	
	// Network methods
	// netacquireIDFromTile
	STAssertEquals([AQTile netacquireIDFromTile:tile], 1, @"netacquireIDFromTile valid tile");
	
	// columnFromNetacquireID
	STAssertEquals([AQTile columnFromNetacquireID:1], 1, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:9], 1, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:10], 2, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:18], 2, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:19], 3, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:27], 3, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:28], 4, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:36], 4, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:37], 5, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:45], 5, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:46], 6, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:54], 6, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:55], 7, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:63], 7, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:64], 8, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:72], 8, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:73], 9, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:81], 9, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:82], 10, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:90], 10, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:91], 11, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:99], 11, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:100], 12, @"columnFromNetacquireID valid ID");
	STAssertEquals([AQTile columnFromNetacquireID:108], 12, @"columnFromNetacquireID valid ID");
	
	// rowFromNetacquireID
	NSArray *rows = [NSArray arrayWithObjects:@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", nil];
	int i, j;
	for (j = 1; j < 10; ++j) {
		for (i = j; i < 109; i += 9) {
			STAssertEqualObjects([AQTile rowFromNetacquireID:i], [rows objectAtIndex:(j - 1)], @"rowFromNetacquireID valid ID");
		}	
	}
	
	// Accessors/setters
	STAssertEqualObjects([tile row], @"A", @"row");
	STAssertEquals([tile column], 1, @"column");
	STAssertEquals([tile netacquireID], 1, @"netacquireID");
	STAssertEquals([tile state], AQTileUnplayed, @"state");
	[tile setState:AQTileMerging];
	STAssertEquals([tile state], AQTileMerging, @"state after setState");
}
@end
