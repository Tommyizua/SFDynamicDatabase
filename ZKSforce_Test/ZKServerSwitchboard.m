

#import "ZKServerSwitchboard.h"
#import "ZKServerSwitchboard+Private.h"
#import "NSObject+Additions.h"
#import "NSDate+Additions.h"
#import "ZKMessageEnvelope.h"
#import "ZKMessageElement.h"

static const int MAX_SESSION_AGE = 10000000 * 60; // 10 minutes.  15 minutes is the minimum length that you can set sessions to last to, so 10 should be safe.
static ZKServerSwitchboard * sharedSwitchboard =  nil;

@interface ZKServerSwitchboard (CoreWrappers)

- (ZKLoginResult *)_processLoginResponse:(zkElement *)loginResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (ZKQueryResult *)_processQueryResponse:(zkElement *)queryResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSArray *)_processSaveResponse:(zkElement *)saveResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSArray *)_processDeleteResponse:(zkElement *)saveResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (ZKGetDeletedResult *)_processGetDeletedResponse:(zkElement *)getDeletedResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (ZKGetUpdatedResult *)_processGetUpdatedResponse:(zkElement *)getUpdatedResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSArray *)_processSearchResponse:(zkElement *)searchResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSArray *)_processUnDeleteResponse:(zkElement *)saveResponseElement error:(NSError *)error context:(NSDictionary *)context;

@end

@implementation ZKServerSwitchboard

@synthesize apiUrl;
@synthesize clientId;
@synthesize sessionId;
@synthesize oAuthRefreshToken;
@synthesize userInfo;
@synthesize updatesMostRecentlyUsed;
@synthesize logXMLInOut;

+ (ZKServerSwitchboard *)switchboard
{
    if (sharedSwitchboard == nil)
    {
        sharedSwitchboard = [[super allocWithZone:NULL] init];
    }
    
    return sharedSwitchboard;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self switchboard];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- init
{
    if (!(self = [super init])) 
        return nil;
    
    connections = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                            &kCFTypeDictionaryValueCallBacks);
    connectionsData = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                                &kCFTypeDictionaryValueCallBacks);
    preferredApiVersion = 36;

    self.logXMLInOut = NO;
    
    return self;
}

+ (NSString *)baseURL
{
    return @"https://www.salesforce.com";
}

#pragma mark Properties

- (NSString *)apiUrl
{
    if (apiUrl)
        return apiUrl;
    return [self authenticationUrl];
}

- (void)setOAuthRefreshToken:(NSString *)refreshToken
{
    NSString *copy = [refreshToken copy];
    oAuthRefreshToken = copy;
    
    // Disable whatever timer existed before
    if (_oAuthRefreshTimer)
    {
        [_oAuthRefreshTimer invalidate];
    }
    if (oAuthRefreshToken)
    {
    // Reschedule a new timer
        _oAuthRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:MAX_SESSION_AGE target:self selector:@selector(_oauthRefreshAccessToken:) userInfo:nil repeats:YES];
    }
}

#pragma mark Methods

- (NSString *)authenticationUrl
{
    NSString *url = [NSString stringWithFormat:@"%@/services/Soap/u/%ld.0", [[self class] baseURL], (long)preferredApiVersion];
    return url;
}


- (void)setApiUrlFromOAuthInstanceUrl:(NSString *)instanceUrl
{
    self.apiUrl = [instanceUrl stringByAppendingFormat:@"/services/Soap/u/%ld.0", (long)preferredApiVersion];
}

- (NSDictionary *)contextWrapperDictionaryForTarget:(id)target selector:(SEL)selector context:(id)context
{
    NSValue *selectorValue = [NSValue value: &selector withObjCType: @encode(SEL)];
    return [NSDictionary dictionaryWithObjectsAndKeys:
            selectorValue, @"selector",
            target, @"target",
            context ? context: [NSNull null], @"context",
            nil];
}

- (void)unwrapContext:(NSDictionary *)wrapperContext andCallSelectorWithResponse:(id)response error:(NSError *)error
{
    SEL selector;
    [[wrapperContext valueForKey: @"selector"] getValue: &selector];
    id target = [wrapperContext valueForKey:@"target"];
    id context = [wrapperContext valueForKey:@"context"];
    if ([context isEqual:[NSNull null]])
        context = nil;
    
    [target performSelector:selector withObject:response withObject:error withObject: context];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password target:(id)target selector:(SEL)selector
{
    // Save Username and Password for session management stuff

    _username = username;

    _password = password;
    
    // Reset session management stuff

	sessionExpiry = [NSDate dateWithTimeIntervalSinceNow:MAX_SESSION_AGE];
	
    /*
	ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionHeader:nil clientId:clientId] autorelease];
	[env startElement:@"login"];
	[env addElement:@"username" elemValue:username];
	[env addElement:@"password" elemValue:password]; 
	[env endElement:@"login"];
	[env endElement:@"s:Body"];
	NSString *xml = [env end]; */
    
    ZKMessageEnvelope *envelop = [ZKMessageEnvelope envelopeWithSessionId:nil clientId:clientId];
    ZKMessageElement *loginElement = [ZKMessageElement elementWithName:@"login" value:nil];
    [loginElement addChildElement:[ZKMessageElement elementWithName:@"username" value:username]];
    [loginElement addChildElement:[ZKMessageElement elementWithName:@"password" value:password]];
    [envelop addBodyElement:loginElement];
    NSString *alternativeXML = [envelop stringRepresentation];    
	
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:nil];
    [self _sendRequestWithData:alternativeXML target:self selector:@selector(_processLoginResponse:error:context:) context: wrapperContext];
}

- (void)create:(NSArray *)objects target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    // if more than we can do in one go, break it up. DC - Ignoring this case.
    /*
	ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionId:sessionId updateMru:self.updatesMostRecentlyUsed clientId:clientId] autorelease];
	[env startElement:@"create"];
	for (ZKSObject *object in objects)
    {
        [env addElement:@"sobject" elemValue:object];
    }
	[env endElement:@"create"];
	[env endElement:@"s:Body"];
    NSString *xml = [env end]; */
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    if (self.updatesMostRecentlyUsed)
        [envelope addUpdatesMostRecentlyUsedHeader];
    [envelope addBodyElementNamed:@"create" withChildNamed:@"sobject" value:objects];
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processSaveResponse:error:context:) context: wrapperContext];
}

- (void)delete:(NSArray *)objectIDs target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    /*
    ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionId:sessionId updateMru:self.updatesMostRecentlyUsed clientId:clientId] autorelease];
	[env startElement:@"delete"];
	[env addElement:@"ids" elemValue:objectIDs];
	[env endElement:@"delete"];
	[env endElement:@"s:Body"];
    NSString *xml = [env end]; */
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    if (self.updatesMostRecentlyUsed)
        [envelope addUpdatesMostRecentlyUsedHeader];
    [envelope addBodyElementNamed:@"delete" withChildNamed:@"ids" value:objectIDs];
    NSString *xml = [envelope stringRepresentation]; 
	
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processDeleteResponse:error:context:) context: wrapperContext];
}

- (void)getDeleted:(NSString *)sObjectType fromDate:(NSDate *)startDate toDate:(NSDate *)endDate target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    if (!startDate)
        startDate = [NSDate dateWithTimeIntervalSinceNow: - (29 * 60 * 60 * 24)];
    if (!endDate)
        endDate = [NSDate date];
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    if (self.updatesMostRecentlyUsed)
        [envelope addUpdatesMostRecentlyUsedHeader];
    ZKMessageElement *getDeletedElement = [ZKMessageElement elementWithName:@"getDeleted" value:nil];
    [getDeletedElement addChildElement:[ZKMessageElement elementWithName:@"sObjectType" value:sObjectType]];
    [getDeletedElement addChildElement:[ZKMessageElement elementWithName:@"startDate" value:[startDate longFormatString]]];
    [getDeletedElement addChildElement:[ZKMessageElement elementWithName:@"endDate" value:[endDate longFormatString]]];
    [envelope addBodyElement:getDeletedElement];
    NSString *xml = [envelope stringRepresentation]; 
	
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processGetDeletedResponse:error:context:) context: wrapperContext];
}

- (void)getUpdated:(NSString *)sObjectType fromDate:(NSDate *)startDate toDate:(NSDate *)endDate target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    if (!startDate)
        startDate = [NSDate dateWithTimeIntervalSinceNow: - (29 * 60 * 60 * 24)];
    if (!endDate)
        endDate = [NSDate date];
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    ZKMessageElement *getUpdatedElement = [ZKMessageElement elementWithName:@"getUpdated" value:nil];
    [getUpdatedElement addChildElement:[ZKMessageElement elementWithName:@"sObjectType" value:sObjectType]];
    [getUpdatedElement addChildElement:[ZKMessageElement elementWithName:@"startDate" value:[startDate longFormatString]]];
    [getUpdatedElement addChildElement:[ZKMessageElement elementWithName:@"endDate" value:[endDate longFormatString]]];
    [envelope addBodyElement:getUpdatedElement];
    NSString *xml = [envelope stringRepresentation]; 
	
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processGetUpdatedResponse:error:context:) context: wrapperContext];
}

- (void)query:(NSString *)soqlQuery target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];

    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    [envelope addBodyElementNamed:@"query" withChildNamed:@"queryString" value:soqlQuery];
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processQueryResponse:error:context:) context: wrapperContext];
}

- (void)queryAll:(NSString *)soqlQuery target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    [envelope addBodyElementNamed:@"queryAll" withChildNamed:@"queryString" value:soqlQuery];
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processQueryResponse:error:context:) context: wrapperContext];
}

- (void)queryMore:(NSString *)queryLocator target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    [envelope addBodyElementNamed:@"queryMore" withChildNamed:@"queryLocator" value:queryLocator];
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processQueryResponse:error:context:) context: wrapperContext];
}

- (void)search:(NSString *)soslQuery target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];

    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    [envelope addBodyElementNamed:@"search" withChildNamed:@"searchString" value:soslQuery];
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processSearchResponse:error:context:) context: wrapperContext];
}

- (void)unDelete:(NSArray *)objectIDs target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];

    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    
    if (self.updatesMostRecentlyUsed)
        [envelope addUpdatesMostRecentlyUsedHeader];
   
    [envelope addBodyElementNamed:@"undelete" withChildNamed:@"ids" value:objectIDs];
    NSString *xml = [envelope stringRepresentation]; 
	
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processUnDeleteResponse:error:context:) context: wrapperContext];
}

- (void)update:(NSArray *)objects target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    if (self.updatesMostRecentlyUsed)
        [envelope addUpdatesMostRecentlyUsedHeader];
    [envelope addBodyElementNamed:@"update" withChildNamed:@"sobject" value:objects];
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processSaveResponse:error:context:) context: wrapperContext];
}


#pragma mark -
#pragma mark Apex Calls

- (void)sendApexRequestToURL:(NSString *)webServiceLocation
                    withData:(NSString *)payload
                      target:(id)target
                    selector:(SEL)sel
                     context:(id)context
{
    // The method is equivalent to ZKServerSwitchboard+Private's _sendRequestWithData:target:selector:context
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:webServiceLocation]];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"text/xml; charset=UTF-8" forHTTPHeaderField:@"content-type"];	
	[request addValue:@"\"\"" forHTTPHeaderField:@"SOAPAction"];
    NSLog(@"request = %@", request);
	NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
	[request setHTTPBody:data];
    
	if(self.logXMLInOut) {
		NSLog(@"OutputHeaders:\n%@", [request allHTTPHeaderFields]);
		NSLog(@"OutputBody:\n%@", payload);
	}
    
    [self _sendRequest:request target:target selector:sel context:context];
}


@end

@implementation ZKServerSwitchboard (CoreWrappers)

- (ZKLoginResult *)_processLoginResponse:(YCElement *)loginResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    ZKLoginResult *loginResult = nil;
    if (!error)
    {
        YCElement *result = [[loginResponseElement childElements:@"result"] objectAtIndex:0];
        loginResult = [[ZKLoginResult alloc] initWithXmlElement:(zkElement *)result];
        self.apiUrl = [loginResult serverUrl];
        self.sessionId = [loginResult sessionId];
        self.userInfo = [loginResult userInfo];
    }

    [self unwrapContext:context andCallSelectorWithResponse:loginResult error:error];
    
    return loginResult;
}

- (ZKQueryResult *)_processQueryResponse:(YCElement *)queryResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    ZKQueryResult *result = nil;
    
    if (!error) {
        
        result = [[ZKQueryResult alloc] initWithXmlElement:[[queryResponseElement childElements] objectAtIndex:0]];
    }
    
    [self unwrapContext:context andCallSelectorWithResponse:result error:error];
    return result;
}

- (NSArray *)_processSaveResponse:(YCElement *)saveResponseElement error:(NSError *)error context:(NSDictionary *)context
{
	NSArray *resultsArr = [saveResponseElement childElements:@"result"];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resultsArr count]];
	
	for (YCElement *result in resultsArr) {
		ZKSaveResult * saveResult = [[ZKSaveResult alloc] initWithXmlElement:(zkElement *)result];
		[results addObject:saveResult];
	}
    [self unwrapContext:context andCallSelectorWithResponse:results error:error];
    return results;
}

- (NSArray *)_processDeleteResponse:(YCElement *)saveResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    NSArray *resArr = [saveResponseElement childElements:@"result"];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resArr count]];
	for (YCElement *saveResultElement in resArr) {
		ZKSaveResult *sr = [[ZKSaveResult alloc] initWithXmlElement:(zkElement *)saveResultElement];
		[results addObject:sr];
	} 
    [self unwrapContext:context andCallSelectorWithResponse:results error:error];
	return results;
}

- (NSArray *)_processSearchResponse:(YCElement *)searchResponseElement error:(NSError *)error context:(NSDictionary *)context;
{
  NSArray *searchRecords = [[searchResponseElement childElement:@"result"] childElements:@"searchRecords"];
  NSMutableArray *results = [NSMutableArray arrayWithCapacity:[searchRecords count]];

  for (YCElement *sRecord in searchRecords ) {
     ZKSObject *record = [[ZKSObject alloc] initWithXmlElement:(zkElement *)[sRecord childElement:@"record"] ];
     [results addObject:record];
  }
  [self unwrapContext:context andCallSelectorWithResponse:results error:error];
  return results;
}



- (ZKGetDeletedResult *)_processGetDeletedResponse:(YCElement *)getDeletedResponseElement error:(NSError *)error context:(NSDictionary *)context;
{
    ZKGetDeletedResult *result = nil;
    if (!error)
    {
        result = [[ZKGetDeletedResult alloc] initWithXmlElement:[[getDeletedResponseElement childElements] objectAtIndex:0]];
    }
    
    [self unwrapContext:context andCallSelectorWithResponse:result error:error];
    
    return result;
}

- (ZKGetUpdatedResult *)_processGetUpdatedResponse:(YCElement *)getUpdatedResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    ZKGetUpdatedResult *result = nil;
    if (!error)
    {
        result = [[ZKGetUpdatedResult alloc] initWithXmlElement:[[getUpdatedResponseElement childElements] objectAtIndex:0]];
    }
    [self unwrapContext:context andCallSelectorWithResponse:result error:error];
    return result;
}

- (NSArray *)_processUnDeleteResponse:(zkElement *)saveResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    return [self _processDeleteResponse:saveResponseElement error:error context:context];
}

@end
