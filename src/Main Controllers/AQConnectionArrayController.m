// AQConnectionArrayController.m
//
// Created May 26, 2008 by nwaite

#import "AQConnectionArrayController.h"

@interface AQConnectionArrayController (Private)
- (AQConnectionController *)_createConnectionToHost:(NSString *)host port:(UInt16)port for:(id)sender;
@end

@implementation AQConnectionArrayController
- (id)init;
{
	if (![super init])
		return nil;
	
	_connectionArray = [[NSMutableArray arrayWithCapacity:1] retain];
	_serverConnection = nil;

	return self;
}

- (void)dealloc;
{
	[_connectionArray release];
	[_serverConnection release];
	
	[super dealloc];
}


// Accessors/setters/etc.
- (AQConnectionController *)serverConnection;
{
	return _serverConnection;
}


// Let everyone else make connections
- (void)connectToServer:(NSString *)hostOrIPAddress port:(int)port for:(id)sender;
{
	if (port < 1 || port > 65535)
		return;
	
	if ([hostOrIPAddress length] == 0)
		return;
	
	_serverConnection = [self _createConnectionToHost:hostOrIPAddress port:port for:sender];
}

- (void)closeConnection:(AQConnectionController *)connection;
{
	[connection close];
}


// Called by individual connection controllers to update status
- (void)connectionClosed:(AQConnectionController *)sender;
{
	[_connectionArray removeObject:sender];
}
@end

@implementation AQConnectionArrayController (Private)
- (AQConnectionController *)_createConnectionToHost:(NSString *)host port:(UInt16)port for:(id)sender;
{
	[_connectionArray addObject:[[[AQConnectionController alloc] initWithHost:host port:port for:sender arrayController:self] autorelease]];
	return [_connectionArray lastObject];
}
@end
