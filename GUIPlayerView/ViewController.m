//
//  ViewController.m
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 09/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import "ViewController.h"

#import "GUIPlayerView.h"

@interface ViewController () <GUIPlayerViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addPlayerButton;
@property (weak, nonatomic) IBOutlet UIButton *removePlayerButton;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;

@property (strong, nonatomic) GUIPlayerView *playerView;

- (IBAction)addPlayer:(UIButton *)sender;
- (IBAction)removePlayer:(UIButton *)sender;

@end

@implementation ViewController

#pragma mark - Interface Builder Actions

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (IBAction)addPlayer:(UIButton *)sender {
  [self.copyrightLabel setHidden:NO];

  self.playerView = [[GUIPlayerView alloc] initWithFrame:CGRectZero];
  [self.playerView setDelegate:self];

  [self.view addSubview:self.playerView];
  
//  NSURL *URL = [NSURL URLWithString:@"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4"];
  NSURL *URL = [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
    
  [self.playerView setVideoURL:URL];
  [self.playerView prepareAndPlayAutomatically:YES];
  
  [self.addPlayerButton setEnabled:NO];
  [self.removePlayerButton setEnabled:YES];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    CGFloat width = self.view.bounds.size.width;
    CGRect frame =CGRectMake(0, self.topLayoutGuide.length, width, width * 9.0f / 16.0f);
    
    self.playerView.frame = frame;
}

- (IBAction)removePlayer:(UIButton *)sender {
  [self.copyrightLabel setHidden:YES];
  
  [self.playerView removeFromSuperview];
  self.playerView = nil;
    
  [self.addPlayerButton setEnabled:YES];
  [self.removePlayerButton setEnabled:NO];
}

#pragma mark - GUI Player View Delegate Methods

- (void)playerWillEnterFullScreen:(GUIPlayerView *)playerView {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, playerView);
}

- (void)playerWillLeaveFullScreen:(GUIPlayerView *)playerView {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, playerView);
}

- (void)playerDidEndPlaying:(GUIPlayerView *)playerView {
    [self removePlayer:nil];
}

- (void)playerFailedToPlayToEnd:(GUIPlayerView *)playerView {
    
    NSLog(@"Error: could not play video");
    [self removePlayer:nil];
}

@end
