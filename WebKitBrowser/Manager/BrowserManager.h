//
//  BrowserManager.h
//  WebKitBrowser
//
//  Created by hereiam on 28.07.16.
//  Copyright © 2016 WebKitBrowser. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BrowserManagerDelegate;

@interface BrowserManager: NSObject

/**
 Delegate for manager. Recieve errors and request after they was generated.
*/
@property (nonatomic, weak) id<BrowserManagerDelegate> delegate;

/**
 Holds current URL
*/
@property (nonatomic, strong) NSURL *currentURL;

/** 
 In secure mode browser uses only https, on http throws an error and ask user to coninue
*/
@property (nonatomic, assign) BOOL secureMode;

/**
 Loads request for URL string.
 Loads NSURLRequest and saves current URL. Delegate loading to BrowserManagerDelegate. Returns NO if string not valid.
 */
- (BOOL)loadRequest:(NSString *)aString;

/** 
 Processes error from request.
 Processes error and make reload page in http if needed or shows error.
*/
- (void)processError:(NSError *)anError;

@end

@protocol BrowserManagerDelegate <NSObject>

@required
/** 
 Sends request to delegate.
 Sends request to delegate after it need to be performed.
*/
- (void)loadRequest:(NSURLRequest *)anRequest;

/** 
 Show error to user.
 Show in WebView error. Uses HTML parse and tags.
*/
- (void)showError:(NSString *)anErrorHTMLString;

@end