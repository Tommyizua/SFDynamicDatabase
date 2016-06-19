//
//  Constants.h
//  ZKSforce_Test
//
//  Created by Yaroslav Chyzh on 6/1/16.
//  Copyright © 2016 Yaroslav Chyzh. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

//#define kConsumerKey        @"3MVG98_Psg5cppybTR3JDj8QtOJ0iRhuiPQE4pdWBRlONKpiFiWxLwu7Y3WEqO317dufkTF.XDJ1dYNv.B9ZF"
#define kConsumerKey        @"3MVG98_Psg5cppybwtygu9gelDobB5tnyu3GwSU4A2Yno6LwHB5bre3V4OsM5Nivwrf_bkv7Z2Tw0FckpOcIJ"        //  a@com.ua
//#define kConsumerKey        @"3MVG98_Psg5cppyaT1V33WZ0U06TGu974NRe6ksKOrWHWVlG6PjT8J.q1xkcuxZOAdtRo7HIHTpNTLJYsiEDe"      //  c@com.ua


#define kCallbackURL        @"zksforcetest:///done"

#define kUrlTemplate        @"https://login.salesforce.com/services/oauth2/authorize?response_type=token&client_id=%@&redirect_uri=%@&display=%@"

#define kInstanceUrl        @"instance_url"
#define kRefreshToken       @"refresh_token"
#define kAccessToken        @"access_token"
#define kTouch              @"touch"
#define kRedirectUrl        @"https://login.salesforce.com/services/oauth2/success"

#define kEntityModel        @"EntityModelArray"
#define kType               @"type"

#define kId                 @"id"
#define kName               @"Name"
#define kLastName           @"LastName"
#define kFields             @"fields"
#define kRelationshipNames   @"RelationshipNames"
#endif /* Constants_h */
