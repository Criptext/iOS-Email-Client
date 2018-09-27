//
//  DateUtils.h
//  Criptext Secure Email
//
//  Created by Daniel Tigse on 4/13/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateUtils : NSObject {
    NSCalendar *gregorianCalendar;
    NSDate *today;
    NSDateFormatter *curentTimezoneFormatter;
}

@property (nonatomic,strong) NSCalendar *gregorianCalendar;
@property (nonatomic,strong) NSDate *today;

+ (DateUtils*)instance;
- (NSDate*)stringToDate:(NSString*)dateString withFormat:(NSString*)format;
- (NSString*)dateToString:(NSDate*)date withFormat:(NSString*)format;
- (BOOL)date:(NSDate*)date1 sameWithDate:(NSDate*)date2;
- (NSString*)stringFromTimestampConv1:(NSDate *)date;
- (NSString*)stringFromTimestampConv2:(NSDate *)date;
- (NSString*)stringFromTimestampConv3:(NSDate *)date;
- (NSString*)stringFromTimestampConv4:(NSDate *)date;
- (NSString*)dateToServerString:(NSDate*)date;
- (NSDate*)stringToServerDate:(NSString*)dateString;
- (void)reInit;

+ (NSString*)beautyDate:(NSDate*)date;
+ (NSString*)prettyDate:(NSDate*)date;
+ (NSString*)conversationTime:(NSDate *)date;

@end
