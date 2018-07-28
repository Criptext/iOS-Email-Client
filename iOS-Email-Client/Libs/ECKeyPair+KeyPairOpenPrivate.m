//
//  ECKeyPair+KeyPairOpenPrivate.m
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

#import "ECKeyPair+KeyPairOpenPrivate.h"

@implementation ECKeyPair (KeyPairOpenPrivate)

-(NSData*) privateKey {
    return [NSData dataWithBytes:self->privateKey length:ECCKeyLength];
}

@end
