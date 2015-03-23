//
// Created by Todd Brannam on 3/19/15.
// Copyright (c) 2015 Guilherme Araújo. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "GUIPlayerView.h"
#include "GUIFullScreenPlayerController.h"


@implementation GUINavigationController

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return self.guiPreferredInterfaceOrientation;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

@end

@implementation GUIFullScreenAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    GUIFullScreenPlayerController * toViewController = (GUIFullScreenPlayerController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    [[transitionContext containerView] addSubview:toViewController.view];

    CGRect sourceRect = [self.sourceView convertRect:self.sourceView.frame toView:self.sourceView.window];
    
    UIInterfaceOrientation fromInterfaceOrientation = self.sourceInterfaceOrientation;
    UIInterfaceOrientation toInterfaceOrientation = toViewController.preferredInterfaceOrientationForPresentation;
    
    if (!((UIInterfaceOrientationIsPortrait(fromInterfaceOrientation) && UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) ||
        (UIInterfaceOrientationIsLandscape(fromInterfaceOrientation) && UIInterfaceOrientationIsLandscape(toInterfaceOrientation)))){
        // no rotation is needed
        toViewController.view.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    
    toViewController.view.frame = sourceRect;
    
    CGRect windowRect = [self.sourceView.window frame];

    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        
        toViewController.view.transform = CGAffineTransformIdentity;
        toViewController.view.frame = windowRect;
        
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}
@end


@implementation GUIFullScreenPlayerController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self.automaticallyAdjustsScrollViewInsets = NO;
    return self;
}

- (void)loadView{
    self.view = [[GUIFullScreenPlayerView alloc] init];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
}

- (GUIFullScreenPlayerView *)playerView{
    return (GUIFullScreenPlayerView *)self.view;
}

// iOS7
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{

    [self.ownerPlayerView setControlsHidden:NO animated:YES];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

// iOS8
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    
    [self.ownerPlayerView setControlsHidden:NO animated:YES];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

@end


@implementation GUIFullScreenPlayerView

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    self.backgroundColor = [UIColor blackColor];
    return self;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    [super layoutSublayersOfLayer:layer];
    
    if (layer == self.layer) {
        self.playerLayer.frame = self.layer.bounds;
    }
}

- (void)setPlayerLayer:(AVPlayerLayer *)playerLayer {
    
    if (_playerLayer != playerLayer) {
        [_playerLayer removeFromSuperlayer];
        
        _playerLayer = playerLayer;
        
        if (playerLayer) {
            [self.layer addSublayer:playerLayer];
        }
    }
}

@end