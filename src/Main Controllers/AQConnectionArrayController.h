// AQConnectionArrayController.h
// ConnectionArrayController manages instances of ConnectionController, which represent individual network connections.
//
// Created May 26, 2008 by nwaite

#include "AQConnectionController.h"

@interface AQConnectionArrayController : NSObject
{
	NSMutableArray 			*_connectionArray;
	AQConnectionController 	*_serverConnection;
}

- (id)init;
- (void)dealloc;

// Accessors/setters/etc.
- (AQConnectionController *)serverConnection;

// Let everyone else make connections
- (void)connectToServer:(NSString *)hostOrIPAddress port:(int)port for:(id)sender;
- (void)closeConnection:(AQConnectionController *)connection;

// Called by individual connection controllers to update status
- (void)connectionClosed:(AQConnectionController *)sender;
@end
