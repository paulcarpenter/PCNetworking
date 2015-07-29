//
//  NSString+PCNetworking.m
//  PCNetworking
//
//  Created by Paul Carpenter on 6/3/14.
//  Copyright (c) 2014 Paul Carpenter. All rights reserved.
//

#import "NSString+PCNetworking.h"

@implementation NSString (PCNetworking)

- (NSString*)naiveCamelCaseString
{
    NSMutableString *output = [NSMutableString string];
    BOOL makeNextCharacterUpperCase = NO;
    for (NSInteger idx = 0; idx < self.length; idx += 1) {
        unichar c = [self characterAtIndex:idx];
        if (c == '_') {
            makeNextCharacterUpperCase = YES;
        } else if (makeNextCharacterUpperCase) {
            [output appendString:[[NSString stringWithCharacters:&c length:1] uppercaseString]];
            makeNextCharacterUpperCase = NO;
        } else {
            [output appendFormat:@"%C", c];
        }
    }
    return output;
}

- (NSString *)naiveSnakeCaseString
{
    NSMutableString *output = [NSMutableString string];
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    for (NSInteger idx = 0; idx < self.length; idx += 1) {
        unichar c = [self characterAtIndex:idx];
        if (idx < self.length - 1)
        {
            unichar nextC = [self characterAtIndex:idx + 1];
            if ([uppercase characterIsMember:nextC])
            {
                [output appendFormat:@"%@", [[NSString stringWithCharacters:&c length:1] lowercaseString]];
                continue;
            }
        }
        if ([uppercase characterIsMember:c]) {
            [output appendFormat:@"_%@", [[NSString stringWithCharacters:&c length:1] lowercaseString]];
        } else {
            [output appendFormat:@"%C", c];
        }
    }
    return output;
}

@end
