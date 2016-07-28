//
//  ViewController.m
//  WebKitBrowser
//
//  Created by hereiam on 28.07.16.
//  Copyright © 2016 WebKitBrowser. All rights reserved.
//

#import "BrowserViewController.h"
#import "BrowserManager.h"

@import WebKit;

@interface BrowserViewController () <WKNavigationDelegate, UITextFieldDelegate, BrowserManagerDelegate>

/** 
 Progress view: view to display loading status. Become visible only then request is send. After that - hides.
*/
@property (nonatomic, weak) IBOutlet UIView *progressView;

/** 
 Progress view constraint, to stretch to to width of superview.
 */
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *progressViewWidth;

/** 
 URL Text Field is command line of browser. Delegate of TextField is BrowserViewController
*/
@property (nonatomic, weak) IBOutlet UITextField *urlTextField;

/** 
 Back button for history navigation.
*/
@property (nonatomic, strong) IBOutlet UIBarButtonItem *backButton;

/** 
 Forward button for history navigation.
*/
@property (nonatomic, strong) IBOutlet UIBarButtonItem *forwardButton;

/** 
 Refresh button for refreshing page.
*/

@property (nonatomic, strong) IBOutlet UIBarButtonItem *refreshButton;

/** 
 Web Kit WebView. It has great performance and has KVO-compliant properties to watch status of loading content, disallow to connect some websites, has history functionality in it.
*/
@property (nonatomic, strong) WKWebView *webView;

/** 
 Browser Manager. 
 It's hold current URL in it, loading request and processes error. Uses delegate for callbacks (to show error in web view or load request). Can use secure mode.
 */
@property (nonatomic, strong) BrowserManager *manager;

@end

@implementation BrowserViewController

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.manager = [[BrowserManager alloc] init];
    self.manager.delegate = self;

    self.webView = [[WKWebView alloc] init];
    self.webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.webView];
    NSArray *constraintsForWebView = [NSLayoutConstraint constraintsWithVisualFormat:
                            @"V:[_progressView]-1-[_webView]|"
                            options:kNilOptions metrics:nil
                            views:NSDictionaryOfVariableBindings(_progressView, _webView)];
    [self.view addConstraints:constraintsForWebView];
    
    constraintsForWebView = [NSLayoutConstraint constraintsWithVisualFormat:
                            @"|[_webView]|"
                            options:kNilOptions metrics:nil
                            views:NSDictionaryOfVariableBindings(_webView)];
    [self.view addConstraints:constraintsForWebView];

    self.webView.navigationDelegate = self;
    [self.webView addObserver:self forKeyPath:@"estimatedProgress"
      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
    [self.webView addObserver:self forKeyPath:@"canGoBack"
      options:NSKeyValueObservingOptionNew context:NULL];
    [self.webView addObserver:self forKeyPath:@"canGoForward"
      options:NSKeyValueObservingOptionNew context:NULL];
      
    [self updateToolbarButtons];
}

- (void)viewDidAppear:(BOOL)anAnimated
{
    [super viewDidAppear:anAnimated];

    [self.urlTextField becomeFirstResponder];
}

// KVO cleanup in dealloc
- (void)dealloc {
   [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
   [self.webView removeObserver:self forKeyPath:@"canGoBack"];
   [self.webView removeObserver:self forKeyPath:@"canGoForward"];
}

#pragma mark - IBActions

// Reload button pressed and web view reloads
- (IBAction)reloadButtonPressed:(id)aSender
{
    if (self.webView.loading)
    {
        [self.webView stopLoading];
    }

    [self.webView reload];
}

// Go back button press
- (IBAction)goBackButtonPressed:(id)aSender
{
    if ([self.webView canGoBack])
    {
        [self.webView goBack];
    }
}

// Go forward button press
- (IBAction)goForwardButtonPressed:(id)aSender
{
    if ([self.webView canGoForward])
    {
        [self.webView goForward];
    }
}

#pragma mark - KVO

// Observing of web kit properties: estimateProgress - loading content, canGoBack and canGoForward for history availability
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"])
    {
        [self updateLoadingView];
    }
    else if ([keyPath isEqualToString:@"canGoBack"] || [keyPath isEqualToString:@"canGoForward"])
    {
        [self updateToolbarButtons];
    }
}

#pragma mark - Private Methods 

/**
 Sets URL for textfield and sets it for BrowserManager
*/
- (void)setBrowsingURL:(NSURL *)anURL
{
    self.manager.currentURL = anURL;
    if (!self.urlTextField.isEditing)
    {
        self.urlTextField.text = anURL.absoluteString;
    }
    [self updateToolbarButtons];
}

/**
 Hides loading view animated.
*/
- (void)hideLoadingView {
   [UIView animateWithDuration:.1f
                    animations:^
                    {
                       self.progressView.alpha = 0;
                    }
                    completion:^(BOOL finished)
                    {
                       if (finished && self.webView.estimatedProgress == 1)
                       {
                          self.progressView.hidden = YES;
                          self.progressViewWidth.constant = 0;
                          [self.view layoutIfNeeded];
                       }
                    }];
}

/**
 Update loading view with estimatedProgress property in web view. Used in KVO.
*/
- (void)updateLoadingView
{
    double estimatedProgress = self.webView.estimatedProgress;
    self.progressView.alpha = 1;
    self.progressView.hidden = NO;
    self.progressViewWidth.constant = CGRectGetWidth(self.view.frame) * estimatedProgress;

    [UIView animateWithDuration:.2f
                         delay:0
                       options:UIViewAnimationOptionBeginFromCurrentState
                    animations:^
                    {
                       [self.view layoutIfNeeded];
                    }
                    completion:^(BOOL finished)
                    {
                       if (finished && self.webView.estimatedProgress == 1)
                       {
                          [self hideLoadingView];
                       }
                    }];
}

/**
 Updates toolbar, uses canGoBack, canGoForward properties in WebView. Refresh shows then current URL is not nil. Used in KVO.
*/
- (void)updateToolbarButtons
{
    NSMutableArray* toolbarItems = [NSMutableArray array];

    if ([self.webView canGoBack])
    {
      [toolbarItems addObject:self.backButton];
    }

    UIBarButtonItem* theFlexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    [toolbarItems addObject:theFlexibleItem];

    if ([self.webView canGoForward])
    {
      [toolbarItems addObject:self.forwardButton];
    }

    if (nil != self.manager.currentURL)
    {
        [toolbarItems addObject:self.refreshButton];
    }

    self.toolbarItems = toolbarItems;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)aTextField
{
    BOOL result = [self.manager loadRequest:aTextField.text];
    if (result)
    {
        [aTextField resignFirstResponder];
    }
    else
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Enter valid URL" message:@"Please, enter valid URL!" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction: [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDestructive handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    return result;
}

#pragma mark - WKWebViewDelegate

- (void)webView:(WKWebView *)aWebView decidePolicyForNavigationAction:(WKNavigationAction *)aNavigationAction
   decisionHandler:(void (^)(WKNavigationActionPolicy))aDecisionHandler
{
   NSURL *URL = aNavigationAction.request.URL;

   NSString* scheme = URL.scheme;
   if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"])
   {
      aDecisionHandler(WKNavigationActionPolicyCancel);
      return;
   }
   
   aDecisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)aWebView decidePolicyForNavigationResponse:(WKNavigationResponse *)aNavigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))aDecisionHandler
{
    [self setBrowsingURL:aWebView.URL];

    aDecisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)aWebView didFinishNavigation:(null_unspecified WKNavigation *)aNavigation
{
    [self setBrowsingURL:aWebView.URL];
}

- (void)webView:(WKWebView *)aWebView didFailProvisionalNavigation:(null_unspecified WKNavigation *)aNavigation withError:(NSError *)anError
{
    [self.manager processError:anError];
}

#pragma mark - BrowserManagerDelegate

- (void)loadRequest:(NSURLRequest *)anRequest
{
    [self.webView loadRequest:anRequest];
}

- (void)showError:(NSString *)anErrorHTMLString
{
    [self.webView loadHTMLString:anErrorHTMLString baseURL:self.manager.currentURL];
}


@end
