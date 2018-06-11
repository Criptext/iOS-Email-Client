//
//  ExceptionCatcher.h
//  iOS-Email-Client
//
//  Created by Pedro Aim on 6/8/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

#ifndef ExceptionCatcher_h
#define ExceptionCatcher_h

#import <Foundation/Foundation.h>

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

#endif /* ExceptionCatcher_h */
