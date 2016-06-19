// Copyright (c) 2010 Rick Fillion
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy of this software and associated documentation files (the "Software"), 
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the 
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
// THE SOFTWARE.
//

#import "ZKServerSwitchboard+Utility.h"
#import "ZKServerSwitchboard+Private.h"
#import "NSObject+Additions.h"
#import "NSDate+Additions.h"
#import "ZKEmailMessage.h"
#import "ZKMessageEnvelope.h"
#import "ZKMessageElement.h"

@interface ZKServerSwitchboard (UtilityWrappers)

- (NSNumber *)_processSetPasswordResponse:(zkElement *)setPasswordResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSDate *)_processGetServerTimestampResponse:(zkElement *)getServerTimestampResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (ZKUserInfo *)_processGetUserInfoResponse:(zkElement *)getUserInfoResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSArray *)_processEmptyRecycleBinResponse:(zkElement *)emptyRecycleBinResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSNumber *)_processSendEmailResponse:(zkElement *)sendEmailResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSString *)_processResetPasswordResponse:(zkElement *)resetPasswordResponseElement error:(NSError *)error context:(NSDictionary *)context;

@end


@implementation ZKServerSwitchboard (Utility)

- (void)emptyRecycleBin:(NSArray *)objectIDs target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];

    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    [envelope addBodyElementNamed:@"emptyRecycleBin" withChildNamed:@"ids" value:objectIDs];
    NSString *xml = [envelope stringRepresentation];  
	
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processEmptyRecycleBinResponse:error:context:) context: wrapperContext];
}

- (void)getServerTimestampWithTarget:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    [envelope addBodyElement:[ZKMessageElement elementWithName:@"getServerTimestamp" value:nil]];
    NSString *xml = [envelope stringRepresentation];  
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processGetServerTimestampResponse:error:context:) context: wrapperContext];
}

- (void)getUserInfoWithTarget:(id)target selector:(SEL)selector context:(id)context
{
    
    [self _checkSession];
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    [envelope addBodyElement:[ZKMessageElement elementWithName:@"getUserInfo" value:nil]];
    NSString *xml = [envelope stringRepresentation];  
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processGetUserInfoResponse:error:context:) context: wrapperContext];
}

- (void)resetPasswordForUserId:(NSString *)userId triggerUserEmail:(BOOL)triggerUserEmail target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:sessionId clientId:clientId];
    if (triggerUserEmail)
        [envelope addEmailHeader];
    [envelope addBodyElementNamed:@"resetPassword" withChildNamed:@"userId" value:userId];
    NSString *xml = [envelope stringRepresentation];  
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processResetPasswordResponse:error:context:) context: wrapperContext];
}

- (void)sendEmail:(NSArray *)emails target:(id)target selector:(SEL)selector context:(id)context
{
    NSLog(@"Warning sendEmail doesn't seem to work just yet.");
    [self _checkSession];
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:self.sessionId clientId:self.clientId];
    ZKMessageElement *sendEmailElement = [ZKMessageElement elementWithName:@"sendEmail" value:nil];
    for (ZKSObject *message in emails)
    {
        ZKMessageElement *messageElement = [ZKMessageElement elementWithName:@"messages" value:nil];
        [messageElement addAttribute:@"urn:SingleEmailMessage" value:@"type"];
        for (NSString *key in [[message fields] allKeys])
        {
            id value = [[message fields] valueForKey:key];
            [messageElement addChildElement:[ZKMessageElement elementWithName:key value:value]];
        }
        [sendEmailElement addChildElement:messageElement];
    }
    [envelope addBodyElement:sendEmailElement];
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processSendEmailResponse:error:context:) context: wrapperContext];
}

- (void)setPassword:(NSString *)password forUserId:(NSString *)userId target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:self.sessionId clientId:self.clientId];
    ZKMessageElement *setPasswordElement = [ZKMessageElement elementWithName:@"setPassword" value:nil];
    [setPasswordElement addChildElement:[ZKMessageElement elementWithName:@"userId" value:userId]];
    [setPasswordElement addChildElement:[ZKMessageElement elementWithName:@"password" value:password]];
    [envelope addBodyElement:setPasswordElement];
    NSString *xml = [envelope stringRepresentation];  
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processSetPasswordResponse:error:context:) context: wrapperContext];
}


@end


@implementation ZKServerSwitchboard (UtilityWrappers)

- (NSNumber *)_processSetPasswordResponse:(zkElement *)setPasswordResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    // A fault would happen (and an error prepped) if it wasn't successful.
    NSNumber *response = [NSNumber numberWithBool: (error ? NO : YES)];
    [self unwrapContext:context andCallSelectorWithResponse:response error:error];
	return response;
}

- (NSDate *)_processGetServerTimestampResponse:(YCElement *)getServerTimestampResponseElement error:(NSError *)error context:(NSDictionary *)context
{
	YCElement *result = [getServerTimestampResponseElement childElement:@"result"];
    YCElement *timestampElement = [result childElement:@"timestamp"];
    NSString *timestampString = [timestampElement stringValue];
    NSDate *timestamp = [NSDate dateWithLongFormatString:timestampString];
    [self unwrapContext:context andCallSelectorWithResponse:timestamp error:error];
	
    return timestamp;
}

- (ZKUserInfo *)_processGetUserInfoResponse:(YCElement *)getUserInfoResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    YCElement *result = [getUserInfoResponseElement childElement:@"result"];
    ZKUserInfo *info = [[ZKUserInfo alloc] initWithXmlElement:(zkElement *)result];
    [self unwrapContext:context andCallSelectorWithResponse:info error:error];
	
    return info;
}

- (NSArray *)_processEmptyRecycleBinResponse:(YCElement *)emptyRecycleBinResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    NSArray *resArr = [emptyRecycleBinResponseElement childElements:@"result"];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resArr count]];
	for (YCElement *saveResultElement in resArr) {
		ZKSaveResult *sr = [[ZKSaveResult alloc] initWithXmlElement:(zkElement *)saveResultElement];
		[results addObject:sr];
	} 
    [self unwrapContext:context andCallSelectorWithResponse:results error:error];
	
    return results;
}

- (NSNumber *)_processSendEmailResponse:(YCElement *)sendEmailResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    // A fault would happen (and an error prepped) if it wasn't successful.
    NSNumber *response = [NSNumber numberWithBool: (error ? NO : YES)];
    [self unwrapContext:context andCallSelectorWithResponse:response error:error];
	return response;
}

- (NSString *)_processResetPasswordResponse:(YCElement *)resetPasswordResponseElement error:(NSError *)error context:(NSDictionary *)context {
    
    YCElement *result = [resetPasswordResponseElement childElement:@"result"];
    YCElement *passwordElement = [result childElement:@"password"];
    NSString *password = [passwordElement stringValue];
    
    [self unwrapContext:context andCallSelectorWithResponse:password error:error];
	
    return password;
}

@end

