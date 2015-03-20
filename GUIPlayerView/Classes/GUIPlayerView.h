//
//  GUIPlayerView.h
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 08/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GUIPlayerView;

@protocol GUIPlayerViewDelegate <NSObject>

@optional
- (void)playerDidPause:(GUIPlayerView *)playerView;
- (void)playerDidResume:(GUIPlayerView *)playerView;
- (void)playerDidEndPlaying:(GUIPlayerView *)playerView;
- (void)playerWillEnterFullScreen:(GUIPlayerView *)playerView;
- (void)playerDidEnterFullScreen:(GUIPlayerView *)playerView;
- (void)playerWillLeaveFullScreen:(GUIPlayerView *)playerView;
- (void)playerDidLeaveFullScreen:(GUIPlayerView *)playerView;

- (void)playerFailedToPlayToEnd:(GUIPlayerView *)playerView error:(NSError *)error;
- (void)playerStalled:(GUIPlayerView *)playerView;

@end


@interface GUIPlayerView : UIView

@property (strong, nonatomic) NSURL *videoURL;
@property (assign, nonatomic) NSInteger controlTimeoutPeriod;
@property (weak, nonatomic) id<GUIPlayerViewDelegate> delegate;
@property (nonatomic, assign) BOOL controlsHidden;

- (void)prepareAndPlayAutomatically:(BOOL)playAutomatically;
- (void)play;
- (void)pause;
- (void)stop;

- (BOOL)isPlaying;

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)setBufferTintColor:(UIColor *)tintColor;

- (void)setLiveStreamText:(NSString *)text;

- (void)setAirPlayText:(NSString *)text;

@end
