// AQNetacquireDirective.m
//
// Created June 26, 2008 by nwaite

#import "AQNetacquireDirective.h"
#import "RegexKitLite.h"

#pragma mark -

@interface AQNetacquireDirective (Private)
#pragma mark Private interface

- (void)_setDirectiveCodeWithoutUpdate:(NSString *)directiveCode;
- (void)_setParametersWithoutUpdate:(NSArray *)parameters;

- (void)_updateUsingProtocolData;
- (NSString *)_directiveCodeFromProtocolData;
- (NSArray *)_parametersFromProtocolData;

- (void)_updateUsingDirectiveCodeAndParameters;
@end

#pragma mark -
@implementation AQNetacquireDirective
#pragma mark Implementation

+ (id)directiveWithData:(NSData *)data;
{
	return [[[self alloc] initWithData:data] autorelease];
}

+ (id)directiveWithString:(NSString *)string;
{
	return [[[self alloc] initWithString:string] autorelease];
}

+ (id)directiveWithCode:(NSString *)code parameters:(NSString *)firstParameter, ...;
{
	AQNetacquireDirective *newDirective = [[self alloc] init];
	
	id curParameter;
	va_list parameterList;
	if (firstParameter) {
		[newDirective addParameter:firstParameter];
		va_start(parameterList, firstParameter);
		while ((curParameter = va_arg(parameterList, NSString *)))
			[newDirective addParameter:curParameter];
		va_end(parameterList);
	}
	
	return newDirective;
}

+ (NSArray *)directivesWithDataString:(NSString *)dataString
{
  // With words:
  //   - One or two uppercase letters.
  //   - Followed by a semicolon.
  //   - Followed by any number of 
  //       - quoted parameters with escaped quotes, or
  //       - unquoted parameters with no quotes, commas, colons, or semicolons.
  //   - Followed by a semicolon and then a colon.
  NSString *regex = @"[A-Z]{1,2};(((\"([^\"]|\"\")*\"|[^\",;:]+),?)*);:";
  NSArray *strings = [dataString componentsMatchedByRegex:regex];
  NSMutableArray *directives = [NSMutableArray array];
  NSEnumerator *stringEnumerator = [strings objectEnumerator];
  NSString *cur;
  while ((cur = [stringEnumerator nextObject]))
    [directives addObject:[AQNetacquireDirective directiveWithString:cur]];
  return directives;
}


// init/dealloc
- (id)init;
{
	if (![super init])
		return nil;
	
	_directiveCode = nil;
	_parameters = [[NSMutableArray alloc] initWithCapacity:5];
	_protocolData = nil;

	return self;
}

- (id)initWithData:(NSData *)data;
{
    if (![self init])
        return nil;
	
	[self setProtocolData:data];
	
	return self;
}

- (id)initWithString:(NSString *)string;
{
    if (![self init])
        return nil;
	
	[self setProtocolData:[string dataUsingEncoding:NSASCIIStringEncoding]];
	
	return self;
}

- (void)dealloc;
{
	[_directiveCode release];
	[_parameters release];
	[_protocolData release];
	
	[super dealloc];
}


// Accessors/setters/etc.
- (NSString *)description;
{
	NSMutableString *ret = [NSMutableString stringWithCapacity:20];
	if (_directiveCode != nil)
		[ret appendFormat:@"%@ directive", _directiveCode];
	
	if ([_parameters count] > 0) {
		[ret appendString:@" with parameters: "];
		NSEnumerator *parameterEnumerator = [_parameters objectEnumerator];
		id curParameter;
		while (curParameter = [parameterEnumerator nextObject]) {
			[ret appendFormat:@"%@, ", curParameter];
		}
	}
	
	return [ret substringWithRange:NSMakeRange(0, [ret length] - 2)];
}

- (NSString *)directiveCode;
{
	return _directiveCode;
}

- (void)setDirectiveCode:(NSString *)directiveCode;
{
	[_directiveCode release];
	_directiveCode = [directiveCode copy];
	
	[self _updateUsingDirectiveCodeAndParameters];
}

- (NSArray *)parameters;
{
	return _parameters;
}

- (void)addParameter:(NSString *)parameter;
{
	NSString *parameterCopy = [[parameter copy] autorelease];
	[_parameters addObject:parameterCopy];
	[self _updateUsingDirectiveCodeAndParameters];
}

- (void)addParameters:(NSArray *)parameters;
{
	[_parameters addObjectsFromArray:parameters];
	[self _updateUsingDirectiveCodeAndParameters];
}

- (void)setParameters:(NSArray *)parameters;
{
	[_parameters release];
	_parameters = [[NSMutableArray arrayWithArray:parameters] retain];
	[self _updateUsingDirectiveCodeAndParameters];
}

- (NSData *)protocolData;
{
	return _protocolData;
}

- (void)setProtocolData:(NSData *)protocolData;
{
	[_protocolData release];
	_protocolData = [protocolData retain];
	
	[self _updateUsingProtocolData];
}
@end

#pragma mark -

@implementation AQNetacquireDirective (Private)
#pragma mark Private implementation

- (void)_setDirectiveCodeWithoutUpdate:(NSString *)directiveCode;
{
	[_directiveCode release];
	_directiveCode = [directiveCode copy];
}

- (void)_setParametersWithoutUpdate:(NSArray *)parameters;
{
	[_parameters release];
	_parameters = [[NSMutableArray arrayWithArray:parameters] retain];
}

- (void)_setProtocolDataWithoutUpdate:(NSData *)protocolData;
{
	[_protocolData release];
	_protocolData = [protocolData retain];
}


- (void)_updateUsingProtocolData;
{	
	[self _setDirectiveCodeWithoutUpdate:[self _directiveCodeFromProtocolData]];
	[self _setParametersWithoutUpdate:[self _parametersFromProtocolData]];
}

- (NSString *)_directiveCodeFromProtocolData;
{
	NSString *dataAsString = [[[NSString alloc] initWithData:_protocolData encoding:NSASCIIStringEncoding] autorelease];
  return [dataAsString stringByMatching:@"([A-Z]{1,2});" capture:1];
}

- (NSArray *)_parametersFromProtocolData;
{
	NSString *dataAsString = [[[NSString alloc] initWithData:_protocolData encoding:NSASCIIStringEncoding] autorelease];
  NSRange chopRange = NSMakeRange(2, [dataAsString length] - 2);
  NSString *chopped = [dataAsString substringWithRange:chopRange];
  NSString *regex = @"\"([^\"]|\"\")*\"|[^\",;:]+";
  NSArray *parameters = [chopped componentsMatchedByRegex:regex];
	return parameters;
}

- (void)_updateUsingDirectiveCodeAndParameters;
{
	if ([self directiveCode] == nil)
		return;
	
	NSMutableString *protocolDataAsString = [NSMutableString stringWithCapacity:50];
	if ([[self parameters] count] == 0) {
		[protocolDataAsString appendFormat:@"%@;;:", [self directiveCode]];
		[self _setProtocolDataWithoutUpdate:[protocolDataAsString dataUsingEncoding:NSASCIIStringEncoding]];
		return;
	}
	
	[protocolDataAsString appendFormat:@"%@;", [self directiveCode]];
	
	NSEnumerator *parameterEnumerator = [_parameters objectEnumerator];
	id curParameter;
	while (curParameter = [parameterEnumerator nextObject]) {
		[protocolDataAsString appendFormat:@"%@,", curParameter];
	}

	[protocolDataAsString deleteCharactersInRange:NSMakeRange([protocolDataAsString length] - 1, 1)];
	[protocolDataAsString appendString:@";:"];

	[self _setProtocolDataWithoutUpdate:[protocolDataAsString dataUsingEncoding:NSASCIIStringEncoding]];
}
@end
