// AQPreferencesWindowController.m
//
// Created Aug 11, 2008 by nwaite

#import "AQPreferencesWindowController.h"

@implementation AQPreferencesWindowController
- (id)init;
{
	if (![super init])
		return nil;

	return self;
}

- (void)dealloc;
{
	[_preferencesWindow close];
	_preferencesWindow = nil;
	
	[super dealloc];
}


- (void)openPreferencesWindowAndBringToFront;
{
	if (_preferencesWindow == nil) {
		if (![NSBundle loadNibNamed:@"PreferencesWindow" owner:self]) {
			NSLog(@"%@ failed loading PreferencesWindow.nib", 
			                                              NSStringFromSelector(_cmd));
			return;
		}
	}
	
	[_preferencesWindow makeKeyAndOrderFront:self];
}

- (void)closePreferencesWindow;
{
	[_preferencesWindow close];
}
@end
