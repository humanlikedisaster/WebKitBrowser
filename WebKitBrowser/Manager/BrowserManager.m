//
//  BrowserManager.m
//  WebKitBrowser
//
//  Created by hereiam on 28.07.16.
//  Copyright © 2016 WebKitBrowser. All rights reserved.
//

#import "BrowserManager.h"

@interface BrowserManager()

@end

@implementation BrowserManager

#pragma mark - Class Methods

/**
 Sets scheme for URL. If forceHTTPs is on - sets SSL connection.
*/

+ (NSURL *)urlByAddingDefaultScheme:(NSURL *)anUrl forceHTTPs:(BOOL)anForceHTTPs
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:anUrl resolvingAgainstBaseURL:NO];
    if (anForceHTTPs)
    {
        components.scheme = @"https";
    }
    else
    {
        components.scheme = @"http";
    }
    anUrl = components.URL;

    return anUrl;
}

#pragma mark - Private


/**
 Handles loading request for URL.
 Checks scheme and saves URL in current
*/
- (BOOL)loadRequestForURL:(NSURL *)anURL
{
    if (nil != anURL)
    {
        if (anURL.scheme == nil)
        {
            anURL = [[self class] urlByAddingDefaultScheme:anURL forceHTTPs:YES];
        }

        self.currentURL = anURL;
        [self.delegate loadRequest:[NSURLRequest requestWithURL:anURL]];
        return YES;
    }
    return NO;
}

/**
 Validates URL with NSDataDetector.
*/
- (BOOL)isValidURL:(NSString *)aString {
    NSUInteger length = [aString length];

    if (length > 0) {
        NSError *error = nil;
        NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
        if (dataDetector && !error) {
            NSRange range = NSMakeRange(0, length);
            NSRange notFoundRange = (NSRange){NSNotFound, 0};
            NSRange linkRange = [dataDetector rangeOfFirstMatchInString:aString options:0 range:range];
            return !NSEqualRanges(notFoundRange, linkRange) && NSEqualRanges(range, linkRange);
        }
        else {
            NSLog(@"Could not create link data detector: %@ %@", [error localizedDescription], [error userInfo]);
        }
    }
    return NO;
}

/**
 Repaired URL from current.
 Returns HTTP URL for unsecure connection. Used in situation, then server has unsigned HTTP sertificate.
 */
- (NSURL *)repairedURLFromCurrent
{
    NSURL *newURL = [[self class] urlByAddingDefaultScheme:self.currentURL forceHTTPs:NO];

    return newURL;
}

/**
Wrapps error string in HTML tags and returns it wrapped.
*/
- (NSString *)wrapErrorInHTML: (NSString *)anErrorText needContinueReference:(BOOL)anContinueReference
{
    NSString *webHTMLString = [NSString stringWithFormat:@"%@%@%@",@"<p><center><font size=\"100\">",anErrorText,@"</font></center></p>"];

    if (anContinueReference)
    {
        NSString *continueURL = [NSString stringWithFormat:@"%@%@%@",@"<p><center><font size=\"100\"><a href=\"",[self repairedURLFromCurrent],@"\">Continue</a></font></center></p>"];
        webHTMLString = [webHTMLString stringByAppendingString:continueURL];
    }

    return webHTMLString;
}

#pragma mark - Public Methods

- (BOOL)loadRequest:(NSString *)aString
{
    if ([self isValidURL:aString])
    {
        return [self loadRequestForURL:[NSURL URLWithString:aString]];
    }

    return NO;
}

- (void)processError:(NSError *)anError;
{
    if (anError.code == -1202)
    {
        if (self.secureMode)
        {
            NSString *errorStr = @"It might be, that server have no signed SSL sertificate. Do you want to continue to HTTP version?";
            [self.delegate showError:[self wrapErrorInHTML:errorStr needContinueReference:YES]];
        }
        else
        {
            [self loadRequestForURL:[self repairedURLFromCurrent]];
        }
    }
    else
    {
        NSString *errorStr = [NSString stringWithFormat:@"Something went wrong!\nCheck web adress.\n\nError code: %ld\nResponse: %@", anError.code, anError.localizedDescription];
        [self.delegate showError:[self wrapErrorInHTML:errorStr needContinueReference:NO]];
    }
}

@end
