//
// Created by Todd Brannam on 3/19/15.
// Copyright (c) 2015 Guilherme Araújo. All rights reserved.
//


#import <UIKit/UIKit.h>

@class AVPlayerLayer;

@interface PlayerView : UIView
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@end


@interface GUIFullScreenPlayerController : UIViewController<UIViewControllerTransitioningDelegate>
@property (nonatomic, readonly) PlayerView *playerView;
@property (nonatomic, weak) GUIPlayerView *ownerPlayerView;
@end

@interface GUIFullScreenAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic, strong) UIView *sourceView;
@property (nonatomic, assign) UIInterfaceOrientation sourceInterfaceOrientation;
@end

@interface GUINavigationController  : UINavigationController
@property (nonatomic, assign) UIInterfaceOrientation guiPreferredInterfaceOrientation;
@end

