//
//  GUIPlayerView.m
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 08/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import "GUIPlayerView.h"
#import "GUISlider.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "GUIFullScreenPlayerController.h"

#import "UIView+UpdateAutoLayoutConstraints.h"

@interface GUIPlayerView () <AVAssetResourceLoaderDelegate, UIViewControllerTransitioningDelegate>

@property(strong, nonatomic) AVPlayer *player;
@property(strong, nonatomic) AVPlayerLayer *playerLayer;
@property(strong, nonatomic) AVPlayerItem *currentItem;

@property(strong, nonatomic) NSTimer *progressTimer;
@property(strong, nonatomic) NSTimer *controllersTimer;
@property(assign, nonatomic) BOOL seeking;
@property(assign, nonatomic) BOOL fullScreen;

@property(nonatomic, strong) GUIFullScreenPlayerController *fullScreenController;
@property(nonatomic, strong) GUINavigationController *navigationController;

@property(strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property(strong, nonatomic) UIView *controlsView;

@property(nonatomic, strong) MPVolumeView *volumeView;

@property(nonatomic, strong) UIButton *playButton;
@property(nonatomic, strong) UIButton *fullScreenButton;

@property(nonatomic, strong) GUISlider *progressIndicator;
@property(nonatomic, strong) UILabel *airPlayLabel;
@property(nonatomic, strong) UILabel *liveLabel;

@property(nonatomic, strong) UILabel *remainingTimeLabel;
@property(nonatomic, strong) UILabel *currentTimeLabel;

@property(nonatomic, strong) UIView *spacerView;

@property(nonatomic, strong) UIColor *controlBackgroundColor;
@end





@implementation GUIPlayerView

#pragma mark - View Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self setup];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self setup];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPVolumeViewWirelessRouteActiveDidChangeNotification object:nil];

    self.currentItem = nil;

    [self.player setAllowsExternalPlayback:NO];
    [self stop];
    [self.player removeObserver:self forKeyPath:@"rate"];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];

    if (layer == self.layer) {
        self.playerLayer.frame = self.layer.bounds;
    }
}

- (void)setup {

    _player = [[AVPlayer alloc] initWithPlayerItem:nil];
    _playerLayer = [[AVPlayerLayer alloc] init];
    _playerLayer.player = self.player;
    
    _controlBackgroundColor = [UIColor colorWithWhite:0.0f alpha:0.45f];
    
    [self.layer addSublayer:_playerLayer];
    
    // Set up notification observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFailedToPlayToEnd:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStalled:)
                                                 name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airPlayAvailabilityChanged:)
                                                 name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airPlayActivityChanged:)
                                                 name:MPVolumeViewWirelessRouteActiveDidChangeNotification object:nil];
    
    [self setBackgroundColor:[UIColor blackColor]];
    
    /** Container View **************************************************************************************************/
    _controlsView = [UIView new];
    [_controlsView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_controlsView setBackgroundColor:self.controlBackgroundColor];
    
    [self addSubview:_controlsView];
    
    /** Loading Indicator ***********************************************************************************************/
    _activityIndicator = [UIActivityIndicatorView new];
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [_activityIndicator stopAnimating];
    
    [self addSubview:_activityIndicator];

    
    // set constraints on activityIndicator and controlsView
    [self updateControlsConstraints];
    
    /** AirPlay View ****************************************************************************************************/
    
    _airPlayLabel = [UILabel new];
    [_airPlayLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_airPlayLabel setText:@"AirPlay is enabled"];
    [_airPlayLabel setTextColor:[UIColor lightGrayColor]];
    [_airPlayLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [_airPlayLabel setTextAlignment:NSTextAlignmentCenter];
    [_airPlayLabel setNumberOfLines:0];
    [_airPlayLabel setHidden:YES];
    
    [self addSubview:_airPlayLabel];
    
    
    NSArray *horizontalConstraints;
    NSArray *verticalConstraints;
    
    horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[AP]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"AP" : _airPlayLabel}];
    verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[AP]-40@250-|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{@"AP" : _airPlayLabel}];
    [self addConstraints:horizontalConstraints];
    [self addConstraints:verticalConstraints];
    
    
    
    /** UI Controllers **************************************************************************************************/
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_playButton setImage:[UIImage imageNamed:@"gui_play"] forState:UIControlStateNormal];
    [_playButton setImage:[UIImage imageNamed:@"gui_pause"] forState:UIControlStateSelected];
    
    _volumeView = [MPVolumeView new];
    [_volumeView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_volumeView setShowsRouteButton:YES];
    [_volumeView setShowsVolumeSlider:NO];
    [_volumeView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_fullScreenButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_fullScreenButton setImage:[UIImage imageNamed:@"gui_expand"] forState:UIControlStateNormal];
    [_fullScreenButton setImage:[UIImage imageNamed:@"gui_shrink"] forState:UIControlStateSelected];
    
    _currentTimeLabel = [UILabel new];
    [_currentTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_currentTimeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [_currentTimeLabel setTextAlignment:NSTextAlignmentCenter];
    [_currentTimeLabel setTextColor:[UIColor whiteColor]];
    
    _remainingTimeLabel = [UILabel new];
    [_remainingTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_remainingTimeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [_remainingTimeLabel setTextAlignment:NSTextAlignmentCenter];
    [_remainingTimeLabel setTextColor:[UIColor whiteColor]];
    
    _progressIndicator = [GUISlider new];
    [_progressIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_progressIndicator setContinuous:YES];
    
    _liveLabel = [UILabel new];
    [_liveLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_liveLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [_liveLabel setTextAlignment:NSTextAlignmentCenter];
    [_liveLabel setTextColor:[UIColor whiteColor]];
    [_liveLabel setText:@"Live"];
    [_liveLabel setHidden:YES];
    
    _spacerView = [UIView new];
    [_spacerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [_controlsView addSubview:self.playButton];
    [_controlsView addSubview:self.fullScreenButton];
    [_controlsView addSubview:self.volumeView];
    [_controlsView addSubview:self.currentTimeLabel];
    [_controlsView addSubview:self.progressIndicator];
    [_controlsView addSubview:self.remainingTimeLabel];
    [_controlsView addSubview:self.liveLabel];
    [_controlsView addSubview:self.spacerView];
    
    horizontalConstraints = [NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|[P(40@750)][S(10@750)][C]-5@250-[I]-5@250-[R][F(40@750)][V(40@750)]|"
                             options:0
                             metrics:nil
                             views:@{@"P" : self.playButton,
                                     @"S" : self.spacerView,
                                     @"C" : self.currentTimeLabel,
                                     @"I" : self.progressIndicator,
                                     @"R" : self.remainingTimeLabel,
                                     @"V" : self.volumeView,
                                     @"F" : self.fullScreenButton}];
    
    [self.controlsView addConstraints:horizontalConstraints];
    
    
    [self.volumeView hideByWidth:YES];
    [self.spacerView hideByWidth:YES];
    
    horizontalConstraints = [NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|-5@250-[L]-5@250-|"
                             options:0
                             metrics:nil
                             views:@{@"L" : self.liveLabel}];
    
    [self.controlsView addConstraints:horizontalConstraints];
    
    for (UIView *view in [_controlsView subviews]) {
        verticalConstraints = [NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-0-[V(40@850)]"
                               options:NSLayoutFormatAlignAllCenterY
                               metrics:nil
                               views:@{@"V" : view}];
        [self.controlsView addConstraints:verticalConstraints];
    }
    

    
    
    /** Actions Setup ***************************************************************************************************/
    
    [_playButton addTarget:self action:@selector(togglePlay:) forControlEvents:UIControlEventTouchUpInside];
    [_fullScreenButton addTarget:self action:@selector(toggleFullScreen:) forControlEvents:UIControlEventTouchUpInside];
    
    [_progressIndicator addTarget:self action:@selector(seek:) forControlEvents:UIControlEventValueChanged];
    [_progressIndicator addTarget:self action:@selector(pauseRefreshing) forControlEvents:UIControlEventTouchDown];
    [_progressIndicator addTarget:self action:@selector(resumeRefreshing) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showControls:)]];
    
    self.controlTimeoutPeriod = 3;
    
    [self setControlsHidden:NO animated:NO];
}

// updateControllerConstraints gets called after the controls are moved from the embedded view to the fullScreen view
// callers should be careful to ensure that is is called only after a view has been added to a new superview

- (void)updateControlsConstraints {

    NSArray *horizontalConstraints;
    NSArray *verticalConstraints;

    horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[CV]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"CV" : self.controlsView}];

    verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[CV(40)]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{@"CV" : self.controlsView}];

    [self.controlsView.superview addConstraints:horizontalConstraints];
    [self.controlsView.superview addConstraints:verticalConstraints];
    
    [self.activityIndicator.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[superview]-(<=1)-[activityIndicator]"
                                                                 options:NSLayoutFormatAlignAllCenterY
                                                                 metrics:nil
                                                                   views:@{@"superview":self.activityIndicator.superview, @"activityIndicator":self.activityIndicator}]];
    
    [self.activityIndicator.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[activityIndicator]"
                                                                 options:NSLayoutFormatAlignAllCenterX
                                                                 metrics:nil
                                                                   views:@{@"superview":self.activityIndicator.superview, @"activityIndicator":self.activityIndicator}]];
}


#pragma mark - UI Customization

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];

    [self.progressIndicator setTintColor:tintColor];
}

- (void)setBufferTintColor:(UIColor *)tintColor {
    [self.progressIndicator setSecondaryTintColor:tintColor];
}

- (void)setLiveStreamText:(NSString *)text {
    [self.liveLabel setText:text];
}

- (void)setAirPlayText:(NSString *)text {
    [self.airPlayLabel setText:text];
}

#pragma mark - Actions

- (void)togglePlay:(UIButton *)button {

    if ([button isSelected]) {
        [button setSelected:NO];
        [self.player pause];

        if ([self.delegate respondsToSelector:@selector(playerDidPause:)]) {
            [self.delegate playerDidPause:self];
        }
    } else {
        [button setSelected:YES];
        [self play];

        if ([self.delegate respondsToSelector:@selector(playerDidResume:)]) {
            [self.delegate playerDidResume:self];
        }
    }

    [self setControlsHidden:NO animated:YES];
}

- (void)toggleFullScreen:(UIButton *)button {

    if (self.fullScreen) {

        if ([self.delegate respondsToSelector:@selector(playerWillLeaveFullScreen:)]) {
            [self.delegate playerWillLeaveFullScreen:self];
        }

        [self.playerLayer removeFromSuperlayer];
        self.playerLayer.frame = self.bounds;
        [self.layer addSublayer:self.playerLayer];
        [self.layer setNeedsLayout];

        [self addSubview:self.controlsView];
        [self addSubview:self.activityIndicator];

        [self updateControlsConstraints];

        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            self.navigationController = nil;
            self.fullScreenController = nil;
            self.fullScreen = NO;

            if ([self.delegate respondsToSelector:@selector(playerDidLeaveFullScreen:)]) {
                [self.delegate playerDidLeaveFullScreen:self];
            }
        }];

        [button setSelected:NO];
    } else {

        if ([self.delegate respondsToSelector:@selector(playerWillEnterFullScreen:)]) {
            [self.delegate playerWillEnterFullScreen:self];
        }

        self.fullScreenController = [[GUIFullScreenPlayerController alloc] initWithNibName:nil bundle:nil];

        self.fullScreenController.ownerPlayerView = self;
        self.fullScreenController.playerView.playerLayer = self.playerLayer;

        self.fullScreenController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toggleFullScreen:)];

        [self.fullScreenController.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showControls:)]];

        [self.fullScreenController.playerView addSubview:self.controlsView];
        [self.fullScreenController.playerView addSubview:self.activityIndicator];
        
        [self updateControlsConstraints];

        self.navigationController = [[GUINavigationController alloc] initWithRootViewController:self.fullScreenController];

        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        self.navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        self.navigationController.transitioningDelegate = self;
        
        UIInterfaceOrientation currentInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            if (UIInterfaceOrientationIsLandscape(currentInterfaceOrientation)){
                self.navigationController.guiPreferredInterfaceOrientation = currentInterfaceOrientation;
            } else {
                self.navigationController.guiPreferredInterfaceOrientation = UIInterfaceOrientationLandscapeLeft;
            }
        } else {
            self.navigationController.guiPreferredInterfaceOrientation = currentInterfaceOrientation;
        }

        UIViewController *topViewController =[UIApplication sharedApplication].keyWindow.rootViewController;
        
        // find a viewController that can present a new viewcontroller
        while (topViewController.presentedViewController) {
            topViewController = topViewController.presentedViewController;
        }
        
        [topViewController presentViewController:self.navigationController animated:YES completion:^{
            self.navigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            self.navigationController.transitioningDelegate = nil;
            
            self.fullScreen = YES;
            
            if ([self.delegate respondsToSelector:@selector(playerDidEnterFullScreen:)]) {
                [self.delegate playerDidEnterFullScreen:self];
            }
        }];
        
        [button setSelected:YES];
    }

    [self setControlsHidden:NO animated:NO];
}

- (void)seek:(UISlider *)slider {
    int timescale = self.currentItem.asset.duration.timescale;
    CGFloat time = slider.value * (self.currentItem.asset.duration.value / timescale);
    [self.player seekToTime:CMTimeMakeWithSeconds(time, timescale)];

    [self setControlsHidden:NO animated:NO];
}

- (void)pauseRefreshing {
    self.seeking = YES;
}

- (void)resumeRefreshing {
    self.seeking = NO;
}

- (NSTimeInterval)availableDuration {
    NSTimeInterval result = 0;
    NSArray *loadedTimeRanges = self.player.currentItem.loadedTimeRanges;

    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [loadedTimeRanges[0] CMTimeRangeValue];
        Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
        Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
        result = startSeconds + durationSeconds;
    }

    return result;
}

- (void)refreshProgressIndicator:(id)timer {
    Float64 duration = CMTimeGetSeconds(self.currentItem.asset.duration);

    if (duration == 0 || isnan(duration)) {
        // Video is a live stream
        [self.currentTimeLabel setText:nil];
        [self.remainingTimeLabel setText:nil];
        [self.progressIndicator setHidden:YES];
        [self.liveLabel setHidden:NO];
    } else {
        Float64 current = self.seeking ?
                self.progressIndicator.value * duration :         // If seeking, reflects the position of the slider
                CMTimeGetSeconds(self.player.currentTime); // Otherwise, use the actual video position

        [self.progressIndicator setValue:(CGFloat) (current / duration)];
        [self.progressIndicator setSecondaryValue:(CGFloat) ([self availableDuration] / duration)];

        // Set time labels
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:(duration >= 3600 ? @"hh:mm:ss" : @"mm:ss")];

        NSDate *currentTime = [NSDate dateWithTimeIntervalSince1970:current];
        NSDate *remainingTime = [NSDate dateWithTimeIntervalSince1970:(duration - current)];

        [self.currentTimeLabel setText:[formatter stringFromDate:currentTime]];
        [self.remainingTimeLabel setText:[NSString stringWithFormat:@"-%@", [formatter stringFromDate:remainingTime]]];

        [self.progressIndicator setHidden:NO];
        [self.liveLabel setHidden:YES];
    }
}


- (void)setControlsHidden:(BOOL)hidden{
    [self setControlsHidden:hidden animated:NO];
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated{

    if (hidden) {

        [UIView animateWithDuration:(animated?0.5f:0.0f) animations:^{

            [self.controlsView setAlpha:0.0f];

            //if we have a fullScreen NavigationController
            self.navigationController.navigationBar.alpha = 0.0;
        }];

    } else {

        [UIView animateWithDuration:(animated?0.2f:0.0f) animations:^{

            [self.controlsView setAlpha:1.0f];

            //if we have a fullScreen NavigationController
            self.navigationController.navigationBar.alpha = 1.0;

        } completion:^(BOOL finished) {

            [self.controllersTimer invalidate];

            // auto hide threshold
            if ([self.volumeView isWirelessRouteActive]==NO && self.controlTimeoutPeriod > 0) {

                self.controllersTimer = [NSTimer scheduledTimerWithTimeInterval:self.controlTimeoutPeriod
                                                                         target:self
                                                                       selector:@selector(hideControls:)
                                                                       userInfo:nil
                                                                        repeats:NO];
            }
        }];

    }
}

- (void)hideControls:(id)sender {
    [self setControlsHidden:YES animated:YES];
}

- (void)showControls:(id)sender {
    [self setControlsHidden:NO animated:YES];
}

- (BOOL)controlsHidden {
    return self.controlsView.alpha > 0;
}


#pragma mark - Public Methods

- (void)prepareAndPlayAutomatically:(BOOL)playAutomatically {

    if (self.player) {
        [self stop];
    }

    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.videoURL options:nil];
    NSArray *keys = @[@"playable"];

    [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{

        self.currentItem = [AVPlayerItem playerItemWithAsset:asset];

        [self.player replaceCurrentItemWithPlayerItem:self.currentItem];
        if (playAutomatically) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self play];
            });
        }
    }];

    [self.player setAllowsExternalPlayback:YES];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

    [self.player addObserver:self forKeyPath:@"rate" options:0 context:nil];

    [self.player seekToTime:kCMTimeZero];
    [self.player setRate:0.0f];
    [self.playButton setSelected:YES];

    if (playAutomatically) {
        [self.activityIndicator startAnimating];
    }
}

- (void)setCurrentItem:(AVPlayerItem *)currentItem {

    if (_currentItem != currentItem) {
        [_currentItem removeObserver:self forKeyPath:@"status"];

        _currentItem = currentItem;

        [_currentItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    }
}


- (void)didMoveToSuperview {

    [super didMoveToSuperview];

    if (!self.superview) {
        [self.progressTimer invalidate];
        self.progressTimer = nil;

        [self.controllersTimer invalidate];
        self.controllersTimer = nil;
    }
}

- (void)play {

    [self.player play];

    [self.playButton setSelected:YES];

    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                          target:self
                                                        selector:@selector(refreshProgressIndicator:)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)pause {

    [self.player pause];
    [self.playButton setSelected:NO];

    if ([self.delegate respondsToSelector:@selector(playerDidPause:)]) {
        [self.delegate playerDidPause:self];
    }
}

- (void)stop {

    if (self.player) {

        [self.player pause];
        [self.player seekToTime:kCMTimeZero];

        [self.playButton setSelected:NO];
    }
}

- (BOOL)isPlaying {

    return [self.player rate] > 0.0f;
}

#pragma mark - AV Player Notifications and Observers

- (void)playerDidFinishPlaying:(NSNotification *)notification {

    if (notification.object == self.currentItem) {

        [self stop];

        if ([self.delegate respondsToSelector:@selector(playerDidEndPlaying:)]) {
            [self.delegate playerDidEndPlaying:self];
        }
    }
}

- (void)playerFailedToPlayToEnd:(NSNotification *)notification {
    if (notification.object == self.currentItem) {

        [self stop];

        if ([self.delegate respondsToSelector:@selector(playerFailedToPlayToEnd:error:)]) {
            [self.delegate playerFailedToPlayToEnd:self error:[notification userInfo][@"AVPlayerItemFailedToPlayToEndTimeErrorKey"]] ;
        }
    }
}

- (void)playerStalled:(NSNotification *)notification {

    if (notification.object == self.currentItem) {

        [self togglePlay:self.playButton];

        if ([self.delegate respondsToSelector:@selector(playerStalled:)]) {
            [self.delegate playerStalled:self];
        }
    }
}


- (void)airPlayAvailabilityChanged:(NSNotification *)notification {

    [UIView animateWithDuration:0.4f
                     animations:^{

                         if ([self.volumeView areWirelessRoutesAvailable]) {
                             [self.volumeView hideByWidth:NO];
                         } else if (![self.volumeView isWirelessRouteActive]) {
                             [self.volumeView hideByWidth:YES];
                         }

                         [self layoutIfNeeded];

                     }];
}

- (void)airPlayActivityChanged:(NSNotification *)notification {

    [UIView animateWithDuration:0.4f
                     animations:^{
                         if ([self.volumeView isWirelessRouteActive]) {

                             [self.playButton hideByWidth:YES];
                             [self.fullScreenButton hideByWidth:YES];
                             [self.spacerView hideByWidth:NO];

                             [self.airPlayLabel setHidden:NO];

                             [self setControlsHidden:NO animated:YES];
                         } else {
                             [self.playButton hideByWidth:NO];
                             [self.fullScreenButton hideByWidth:NO];
                             [self.spacerView hideByWidth:YES];

                             [self.airPlayLabel setHidden:YES];

                             [self setControlsHidden:NO animated:YES];
                         }
                         [self layoutIfNeeded];
                     }];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if (self.currentItem == object && [keyPath isEqualToString:@"status"]) {
        if (self.currentItem.status == AVPlayerItemStatusFailed) {
            if ([self.delegate respondsToSelector:@selector(playerFailedToPlayToEnd:error:)]) {
                [self.delegate playerFailedToPlayToEnd:self error:nil];
            }
        }
    }

    if (self.player == object && [keyPath isEqualToString:@"rate"]) {
        CGFloat rate = [self.player rate];
        if (rate > 0) {
            [self.activityIndicator stopAnimating];
        }
    }
}


#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                   presentingController:(UIViewController *)presenting
                                                                       sourceController:(UIViewController *)source {
    
    GUIFullScreenAnimator *animator = [[GUIFullScreenAnimator alloc] init];
    animator.sourceView = self;
    animator.sourceInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    return animator;
}


@end
