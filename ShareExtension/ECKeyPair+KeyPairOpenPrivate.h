//
//  ECKeyPair+KeyPairOpenPrivate.h
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

#import <SignalProtocolFramework/SignalProtocolFramework.h>

@interface ECKeyPair (KeyPairOpenPrivate)

-(NSData*) privateKey;

@end
