// AQNetacquireDirective.h
// NetacquireDirective wraps up a Netacquire directive, providing readable and ready-to-send formats of the directive, as well as helping build new directives.
//
// Created June 26, 2008 by nwaite

#pragma mark -
@interface AQNetacquireDirective : NSObject
#pragma mark Interface
{
	NSString 		*_directiveCode;
	NSMutableArray 	*_parameters;
	NSData 			*_protocolData;
}

// Class methods
+ (id)directiveWithData:(NSData *)data;
+ (id)directiveWithString:(NSString *)string;
+ (id)directiveWithCode:(NSString *)code parameters:(NSString *)firstParameter, ...;
+ (NSArray *)directivesWithData:(NSData *)data;

// init/dealloc
- (id)init;
- (id)initWithData:(NSData *)data;
- (id)initWithString:(NSString *)string;
- (void)dealloc;

// Accessors/setters/etc.
- (NSString *)description;
- (NSString *)directiveCode;
- (void)setDirectiveCode:(NSString *)directiveCode;
- (NSArray *)parameters;
- (void)addParameter:(NSString *)parameter;
- (void)addParameters:(NSArray *)parameters;
- (void)setParameters:(NSArray *)parameters;
- (NSData *)protocolData;
- (void)setProtocolData:(NSData *)protocolData;
@end
