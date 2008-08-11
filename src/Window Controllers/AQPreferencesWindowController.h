// AQPreferencesWindowController.h
// PreferencesWindowController handles the Preferences window, used to set various options
//
// Created Aug 11, 2008 by nwaite

@interface AQPreferencesWindowController : NSObject
{
	IBOutlet NSWindow	*_preferencesWindow;
}

- (id)init;
- (void)dealloc;

- (void)openPreferencesWindowAndBringToFront;
- (void)closePreferencesWindow;
@end
