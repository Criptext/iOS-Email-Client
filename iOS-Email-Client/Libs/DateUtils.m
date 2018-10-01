//
//  DateUtils.m
//  Criptext Secure Email
//
//  Created by Daniel Tigse on 4/13/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

#import "DateUtils.h"

@implementation DateUtils
@synthesize gregorianCalendar, today;
static DateUtils *dateUtilsInstance = nil;

+ (DateUtils*)instance {
    if (dateUtilsInstance == nil) {
        dateUtilsInstance = [[DateUtils alloc] init];
    }
    return dateUtilsInstance;
}

static NSString *dateTimeFormat = @"MM/dd/yyyy hh:mm:ssaa";
static NSString *dateTimeConv1Format = @"MM/dd/yyyy";
static NSString *dateTimeConv2Format = @"EEEE";
static NSString *dateTimedayOfWeekFormat = @"EEEE 'at' h:mm aa";
static NSString *dateTimeMonthFormat = @"d MMM 'at' hh:mm aa";
static NSString *dateTimeConv3Format = @"h:mm aa";//MMMM dd
static NSString *dateTimeConv4Format = @"dd-MM-yyyy";
static NSString *dateTimeConv5Format = @"MMM d, yyyy hh:mm aa";
static NSString *dateTimeConv6Format = @"HH:mm";
static NSString *serverDateFormat = @"yyyy-MM-dd";

- (void)reInit {
    curentTimezoneFormatter = [[NSDateFormatter alloc] init];
    [curentTimezoneFormatter setDateFormat:dateTimeFormat];
    
}

- (id)init {
    if (self = [super init]) {
        self.gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        [self reInit];
    }
    return self;
}

- (NSString*)dateToString:(NSDate*)date withFormat:(NSString*)format {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:format];
    NSString *theDate = [dateFormat stringFromDate:date];
    return theDate;
}

- (NSString*)dateToServerString:(NSDate*)date {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:serverDateFormat];
    NSString *theDate = [dateFormat stringFromDate:date];
    return theDate;
}
- (NSDate*)stringToServerDate:(NSString*)dateString {
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:serverDateFormat];
    NSDate *theDate = [dateFormatter dateFromString:dateString];
    return theDate;
}

- (NSDate*)stringToDate:(NSString*)dateString withFormat:(NSString*)format {
    [NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    NSDate *theDate = [dateFormatter dateFromString:dateString];
    return theDate;
}

- (BOOL)date:(NSDate*)date1 sameWithDate:(NSDate*)date2 {
    unsigned units = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents *comps1 = [gregorianCalendar components:units fromDate:date1];
    NSDateComponents *comps2 = [gregorianCalendar components:units fromDate:date2];
    return comps1.day == comps2.day && comps1.month == comps2.month && comps1.year == comps2.year;
}

- (NSString*)stringFromTimestampConv1:(NSDate *)date {
    NSString *result;
    [curentTimezoneFormatter setDateFormat:dateTimeConv1Format];
    result = [curentTimezoneFormatter stringFromDate:date];
    return result;
}

- (NSString*)stringFromTimestampConv2:(NSDate *)date {
    NSString *result;
    [curentTimezoneFormatter setDateFormat:dateTimeConv2Format];
    result = [curentTimezoneFormatter stringFromDate:date];
    return result;
}

- (NSString*)stringFromTimestampConv3:(NSDate *)date {
    NSString *result;
    [curentTimezoneFormatter setDateFormat:dateTimeConv3Format];
    result = [curentTimezoneFormatter stringFromDate:date];
    return result;
}

- (NSString*)stringFromTimestampConv4:(NSDate *)date {
    NSString *result;
    [curentTimezoneFormatter setDateFormat:dateTimeConv4Format];
    result = [curentTimezoneFormatter stringFromDate:date];
    return result;
}

- (NSString*)stringFromTimestampConv5:(NSDate *)date {
    NSString *result;
    [curentTimezoneFormatter setDateFormat:dateTimeConv5Format];
    result = [curentTimezoneFormatter stringFromDate:date];
    return result;
}

- (NSString*)stringFromTimestamp:(NSDate *)date format:(NSString *)format {
    NSString *result;
    [curentTimezoneFormatter setDateFormat:format];
    result = [curentTimezoneFormatter stringFromDate:date];
    return result;
}

- (NSString*)stringFromTimestampWeekDay:(NSDate *)date {
    NSString *result;
    [curentTimezoneFormatter setDateFormat:dateTimedayOfWeekFormat];
    result = [curentTimezoneFormatter stringFromDate:date];
    return result;
}

- (NSString*)stringFromTimestampMonth:(NSDate *)date {
    NSString *result;
    [curentTimezoneFormatter setDateFormat:dateTimeMonthFormat];
    result = [curentTimezoneFormatter stringFromDate:date];
    return result;
}

+ (NSString*)beautyDate:(NSDate*)date{
    
    NSString *fechaFinal;
    NSDate *now = [NSDate date];
    
    // format: YYYY-MM-DD HH:MM:SS ±HHMM
    NSString *dateStr = [date description];
    NSString *dateNowStr = [now description];
    NSRange range;
    
    //month
    range.location = 5;
    range.length = 2;
    NSString *monthStr = [dateStr substringWithRange:range];
    NSString *monthNowStr = [dateNowStr substringWithRange:range];
    int month = [monthStr intValue];
    int month0 = [monthNowStr intValue];
    
    NSString *fechaservidor;
    fechaservidor=[[DateUtils instance] stringFromTimestampConv4:date];
    // This just sets up the two dates you want to compare
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy"];
    NSDate *startDate = [formatter dateFromString:fechaservidor];
    NSDate *endDate = [NSDate date];
    
    // This performs the difference calculation
    unsigned flags = NSCalendarUnitDay;
    NSDateComponents *difference = [[NSCalendar currentCalendar] components:flags fromDate:startDate toDate:endDate options:0];
    
    if((month-month0)==0){
        if([difference day]==0){
            fechaFinal=[NSString stringWithFormat:@"at %@",[[DateUtils instance] stringFromTimestampConv3:date]];
        }
        else if ([difference day]==1 || [difference day]==-1){
            fechaFinal=[NSString stringWithFormat:@"Yesterday at %@",[[DateUtils instance] stringFromTimestampConv3:date]];
        }
        else if ([difference day]<7 && [difference day]>0)
            fechaFinal=[[DateUtils instance] stringFromTimestampWeekDay:date];
        else
            fechaFinal=[[DateUtils instance] stringFromTimestampMonth:date];
    }
    else
        fechaFinal=[[DateUtils instance] stringFromTimestampMonth:date];
    
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"a.m." withString:@"AM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"a. m." withString:@"AM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"p.m." withString:@"PM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"p. m." withString:@"PM"];
    
    return fechaFinal;
    
}

+ (NSString*)prettyDate:(NSDate*)date{
    
    NSString *fechaFinal;
    NSDate *now = [NSDate date];
    
    // format: YYYY-MM-DD HH:MM:SS ±HHMM
    NSString *dateStr = [date description];
    NSString *dateNowStr = [now description];
    NSRange range;
    
    //month
    range.location = 5;
    range.length = 2;
    NSString *monthStr = [dateStr substringWithRange:range];
    NSString *monthNowStr = [dateNowStr substringWithRange:range];
    int month = [monthStr intValue];
    int month0 = [monthNowStr intValue];
    
    NSString *fechaservidor;
    fechaservidor=[[DateUtils instance] stringFromTimestampConv4:date];
    // This just sets up the two dates you want to compare
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy"];
    NSDate *startDate = [formatter dateFromString:fechaservidor];
    NSDate *endDate = [NSDate date];
    
    // This performs the difference calculation
    unsigned flags = NSCalendarUnitDay;
    NSDateComponents *difference = [[NSCalendar currentCalendar] components:flags fromDate:startDate toDate:endDate options:0];
    
    if((month-month0)==0){
        if([difference day]==0){
            fechaFinal=[NSString stringWithFormat:@"%@",[[DateUtils instance] stringFromTimestampConv3:date]];
        }
        else if ([difference day]==1 || [difference day]==-1){
            fechaFinal=[NSString stringWithFormat:@"Yesterday %@",[[DateUtils instance] stringFromTimestampConv3:date]];
        }
        else
            fechaFinal=[[DateUtils instance] stringFromTimestampConv5:date];
    }
    else
        fechaFinal=[[DateUtils instance] stringFromTimestampConv5:date];
    
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"a.m." withString:@"AM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"a. m." withString:@"AM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"p.m." withString:@"PM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"p. m." withString:@"PM"];
    
    return fechaFinal;
    
}

+ (NSString*)conversationTime:(NSDate *)date {
    
    NSString *fechaFinal;
    
    NSDate *now = [NSDate date];
    
    // format: YYYY-MM-DD HH:MM:SS ±HHMM
    NSString *dateStr = [date description];
    NSString *dateNowStr = [now description];
    NSRange range;
    
    //month
    range.location = 5;
    range.length = 2;
    NSString *monthStr = [dateStr substringWithRange:range];
    NSString *monthNowStr = [dateNowStr substringWithRange:range];
    int month = [monthStr intValue];
    int month0 = [monthNowStr intValue];
    
    NSString *fechaservidor;
    
    
    fechaservidor=[[DateUtils instance] stringFromTimestampConv4:date];
    // This just sets up the two dates you want to compare
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy"];
    NSDate *startDate = [formatter dateFromString:fechaservidor];
    NSDate *endDate = [NSDate date];
    
    // This performs the difference calculation
    unsigned flags = NSCalendarUnitDay;
    NSDateComponents *difference = [[NSCalendar currentCalendar] components:flags fromDate:startDate toDate:endDate options:0];
    
    
    if((month-month0)==0){
        if([difference day]==0){
            fechaFinal=[[DateUtils instance] stringFromTimestampConv3:date];
        }
        else if ([difference day]==1 || [difference day]==-1)
        fechaFinal=@"Yesterday";
        else if ([difference day]<7 && [difference day]>0)
        fechaFinal=[[DateUtils instance] stringFromTimestampConv2:date];
        else
        fechaFinal=[[DateUtils instance] stringFromTimestamp:date format:@"MMM d"];
    }else if(month-month0 < 12){
        fechaFinal=[[DateUtils instance] stringFromTimestamp:date format:@"MMM d"];
    } else {
    fechaFinal=[[DateUtils instance] stringFromTimestampConv1:date];
    }
    
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"a.m." withString:@"AM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"a. m." withString:@"AM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"p.m." withString:@"PM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"p. m." withString:@"PM"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"2015" withString:@"15"];
    fechaFinal=[fechaFinal stringByReplacingOccurrencesOfString:@"1969" withString:@"15"];
    
    return fechaFinal;
}

@end
