//
//  RSCViewController.m
//  TweetApp
//
//  Created by Daniel Mayo on 18/04/2013.
//  Copyright (c) 2013 Daniel Mayo. All rights reserved.
//

#import "RSCViewController.h"

@interface RSCViewController ()
@property (nonatomic, strong) IBOutlet UITextView *twitterWebView;
- (void)reloadTweets;
- (void)handleTwitterData: (NSData*) responseData
              urlResponse: (NSHTTPURLResponse*) urlResponse
                    error: (NSError*) error;
@end

@implementation RSCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tweetButtonPressed:(id)sender {
    if ([SLComposeViewController isAvailableForServiceType: SLServiceTypeTwitter]) {
        SLComposeViewController *twitterViewController =
            [SLComposeViewController composeViewControllerForServiceType: SLServiceTypeTwitter];
        
        NSLog(@"SLComposedViewController is a %@", [twitterViewController class]);
        
        [twitterViewController setInitialText:
            NSLocalizedString(@"This is a tweet from my first social iOS app. #pragsios", nil)];
        
        twitterViewController.completionHandler = ^(SLComposeViewControllerResult result) {
            NSLog(@"Completion Handler Invoked");
            [self dismissViewControllerAnimated:YES completion:nil];
            
            if (result == SLComposeViewControllerResultDone) {
                NSLog(@"Tweet Sent...");
                [self reloadTweets];
            }
        };
        
        [self presentViewController:twitterViewController animated:YES completion:nil];
    } else {
        NSLog (@"Twitter service not available!");
    }
}

- (IBAction)showMyTweetsButtonPressed:(id)sender {
    NSLog(@"showMyTweetsButtonPressed");
    
    [self reloadTweets];
}

- (void)reloadTweets {
    NSLog(@"(Re)loading tweets");
    
    SLRequest *loadRequest = [SLRequest requestForServiceType: SLServiceTypeTwitter
                                                requestMethod: SLRequestMethodGET
                                                          URL: [NSURL URLWithString:@"http://api.twitter.com/1/statuses/user_timeline.json"]
                                                   parameters: @{ @"screen_name": @"dmayo3" }];
    
    [loadRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        [self handleTwitterData:responseData
                    urlResponse:urlResponse
                          error:error];
    }];
}

- (void)handleTwitterData:(NSData*)responseData urlResponse:(NSHTTPURLResponse*)urlResponse error:(NSError*)error {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *jsonError = nil;
        
        NSJSONSerialization *jsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
        
        if (jsonError) {
            NSLog(@"JSON deserialisation error: %@", [jsonError description]);
        } else if (![jsonResponse isKindOfClass:[NSArray class]]) {
            NSLog(@"Unexpected JSON response type: %@", [jsonResponse class]);
        } else {
            NSLog(@"JSON response: ");
            
            NSArray *tweets = (NSArray*) jsonResponse;
            NSSortDescriptor *tweetSortDescriptor =
                [NSSortDescriptor sortDescriptorWithKey:@"text" ascending:YES];
            NSArray *tweetSortDescriptors = @[tweetSortDescriptor];
            
            tweets = [tweets sortedArrayUsingDescriptors:tweetSortDescriptors];
                        
            NSMutableString *text = [NSMutableString new];
            
            for (NSDictionary *tweet in tweets) {
                [text appendFormat:@"@%@ %@ (%@)\n\n", [tweet valueForKeyPath:@"user.screen_name"], [tweet valueForKey:@"text"], [tweet valueForKey:@"created_at"]];
            }
            
            [self.twitterWebView setText: text];
        }
    });
    
}

@end
