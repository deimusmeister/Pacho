//
//  GameScene.m
//  Pacho
//
//  Created by Levon Poghosyan on 10/1/16.
//  Copyright (c) 2016 Levon Poghosyan. All rights reserved.
//

#import "GameScene.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreGraphics/CoreGraphics.h>

@implementation GameScene
{
    SKSpriteNode*   mPacho;
    SKSpriteNode*   mWeapon;
    SKLabelNode*    mTimerLabel;
    NSTimer*        mTimer;
    BOOL            mRunning;
    NSDate*         mStartDate;
    
    NSTimer*        mPachoTimer;
    NSInteger       mLevel;
    NSInteger       mShots;
    
    UIView*         mLooserDialogue;
    UIView*         mWinnerDialogue;
    UIView*         mStartupDialogue;
    
    UIButton*       pbutton;
    
    UILabel*        mPower;
    UILabel*        startlabel;
    NSTimer*        mStartTimer;
    NSInteger       mStartupCounter;
    
    UIImage*        mScreeshot;
    
    SKSpriteNode*   mDummy1;
    SKSpriteNode*   mDummy2;
    SKSpriteNode*   mDummy3;
}

-(void)didMoveToView:(SKView *)view {
    // Initialize dialuges
    [self startCounter];
    [self youLooser];
    [self youWinner];
    mLooserDialogue.hidden = YES;
    mWinnerDialogue.hidden = YES;
    
    // Background color
    self.backgroundColor = [UIColor whiteColor];
    
    // Add spotwatch
    mTimerLabel = [SKLabelNode labelNodeWithFontNamed:@"Verdana"];
    mTimerLabel.text = @"00.00.00.000";
    mTimerLabel.fontColor = [UIColor blackColor];
    mTimerLabel.fontSize = 35;
    mTimerLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetMaxY(self.frame) - 50);
    [self addChild:mTimerLabel];
    mRunning = FALSE;
    
    // Pacho
    mPacho = [SKSpriteNode spriteNodeWithImageNamed:@"PachoTable"];
    CGFloat scaleFactor = 1.15;
    mPacho.xScale = scaleFactor;
    mPacho.yScale = scaleFactor;
    mPacho.position = CGPointMake(CGRectGetMidX(self.frame), self.view.frame.size.height - 375 / 2);
    mPacho.zPosition = -1;
    [self addChild:mPacho];
    
    // Weaspon
    mWeapon = [SKSpriteNode spriteNodeWithImageNamed:@"WeaponAdapted"];
    mWeapon.xScale = scaleFactor;
    mWeapon.yScale = scaleFactor;
    mWeapon.position = CGPointMake(CGRectGetMidX(self.frame), 200);
    [self addChild:mWeapon];
    
    // Set the number of shots
    mShots = 3;
    
    // Power Label
    mPower = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 125,
                                                       self.view.frame.size.height - 110, 250, 110)];
    mPower.text = [NSString stringWithFormat:@"SHOT %ld!", (long)mShots];
    mPower.textAlignment = NSTextAlignmentCenter;
    mPower.font = [UIFont boldSystemFontOfSize:50];
    mPower.tintColor = [UIColor blackColor];
    mPower.backgroundColor = [UIColor whiteColor];
    mPower.layer.cornerRadius = 10.f;
    mPower.layer.borderWidth = 3.f;
    [self.view addSubview:mPower];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (mRunning)
    {
        // Touch color
        UIColor* color = nil;
        
        for (UITouch *touch in touches) {
            
            int x = [touch locationInView:self.view].x - 1;
            int y = [touch locationInView:self.view].y - 1;
            
            // Take a screenshot
            [self takeScreenshot];
            
            // Probe the color on touch coordinate
            color  = [self colorAtPixel:CGPointMake(x, y) inImage:mScreeshot];
            
            // Dummy
            SKSpriteNode* dummy = [SKSpriteNode spriteNodeWithImageNamed:@"Dummy"];
            CGFloat scaleFactor = 1.15;
            dummy.xScale = scaleFactor;
            dummy.yScale = scaleFactor;
            dummy.position = CGPointMake(CGRectGetMidX(self.frame), self.view.frame.size.height - 375 / 2);
            [self addChild:dummy];
            
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"WeaponFiredAdapted"];
            CGPoint location = [touch locationInNode:dummy];
            sprite.position = location;
            
            [dummy addChild:sprite];
            
            if (mShots == 3)
            {
                mDummy1 = dummy;
            }
            else if(mShots == 2)
            {
                mDummy2 = dummy;
            }
            else if(mShots == 1)
            {
                mDummy3 = dummy;
            }
            
            // Start animating
            SKAction *action = [SKAction rotateByAngle:-M_PI duration:4.f / mLevel];
            [dummy runAction:[SKAction repeatActionForever:action]];
            
            // Check hitting Pacho
            if (color != nil)
            {
                UIColor* exampleColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
                if ([self color:color isEqualToColor:exampleColor withTolerance:0.005]) {
                    [self pachoWins];
                    return;
                }
            }
        }
        
        // Hide the weapon
        mWeapon.hidden = YES;
        mShots = mShots - 1;
    
        mPower.textColor = [UIColor redColor];
        mPower.text = [NSString stringWithFormat:@"SHOT %ld!", (long)mShots];
        
        if (mShots == 0)
        {
            mRunning = FALSE;
            
            // Make a screenshot
            [self takeScreenshot];
            
            [mTimer invalidate];
            [mPachoTimer invalidate];
            
            [mPacho removeAllActions];
            [mDummy1 removeAllActions];
            [mDummy2 removeAllActions];
            [mDummy3 removeAllActions];
            
            mWinnerDialogue.hidden = NO;
        }
    }
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    mPower.textColor = [UIColor blackColor];
    
    // Show the weapon
    mWeapon.hidden = NO;
}

- (UIColor *)colorAtPixel:(CGPoint)point inImage:(UIImage *)image
{
    if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, image.size.width, image.size.height), point)) {
        return nil;
    }
    
    // Create a 1x1 pixel byte array and bitmap context to draw the pixel into.
    NSInteger pointX = trunc(point.x);
    NSInteger pointY = trunc(point.y);
    CGImageRef cgImage = image.CGImage;
    NSUInteger width = image.size.width;
    NSUInteger height = image.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    unsigned char pixelData[4] = { 0, 0, 0, 0 };
    CGContextRef context = CGBitmapContextCreate(pixelData, 1, 1, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    // Draw the pixel we are interested in onto the bitmap context
    CGContextTranslateCTM(context, -pointX, pointY-(CGFloat)height);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
    CGContextRelease(context);
    
    // Convert color values [0..255] to floats [0.0..1.0]
    CGFloat red   = (CGFloat)pixelData[0] / 255.0f;
    CGFloat green = (CGFloat)pixelData[1] / 255.0f;
    CGFloat blue  = (CGFloat)pixelData[2] / 255.0f;
    CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (bool)color:(UIColor *)color1 isEqualToColor:(UIColor *)color2 withTolerance:(CGFloat)tolerance
{
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    [color1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [color2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    return
    fabs(r1 - r2) <= tolerance &&
    fabs(g1 - g2) <= tolerance &&
    fabs(b1 - b2) <= tolerance &&
    fabs(a1 - a2) <= tolerance;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

-(void)startCounter
{
    mStartupDialogue = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 150,100,300,300)];
    mStartupDialogue.layer.borderColor = [UIColor blackColor].CGColor;
    mStartupDialogue.layer.cornerRadius = 10.0f;
    mStartupDialogue.layer.borderWidth = 3.0f;
    mStartupDialogue.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:mStartupDialogue];
    
    startlabel = [[UILabel alloc] init];
    [startlabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    startlabel.text = @"The Match\nStarts in\n 5 seconds";
    startlabel.numberOfLines = 3;
    startlabel.textAlignment = NSTextAlignmentCenter;
    startlabel.font = [UIFont boldSystemFontOfSize:35];
    startlabel.tintColor = [UIColor blackColor];
    [mStartupDialogue addSubview:startlabel];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(startlabel);
    
    NSArray *lhorizontalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[startlabel]-20-|" options:0 metrics:nil views:views];
    NSArray *verticalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[startlabel]-20-|" options:0 metrics:nil views:views];
    
    [mStartupDialogue addConstraints:verticalConstraints];
    [mStartupDialogue addConstraints:lhorizontalConstraints];
    
    mStartTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                   target:self
                                                 selector:@selector(startupTimer)
                                                 userInfo:nil
                                                  repeats:YES];
    mStartupCounter = 5;
}

-(void)startupTimer
{
    mStartupCounter = mStartupCounter - 1;
    startlabel.text = [NSString stringWithFormat:@"The Match\nStarts in\n %ld seconds", mStartupCounter];
    if (mStartupCounter == 0)
    {
        [mStartTimer invalidate];
        mStartupDialogue.hidden = YES;
        // Start with level 1
        [self play:1];
    }
}

-(void)takeScreenshot
{
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, 1);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    mScreeshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

-(void)youLooser
{
    mLooserDialogue = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 150, 200,300,300)];
    mLooserDialogue.layer.borderColor = [UIColor blackColor].CGColor;
    mLooserDialogue.layer.cornerRadius = 10.0f;
    mLooserDialogue.layer.borderWidth = 3.0f;
    mLooserDialogue.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:mLooserDialogue];
    
    UILabel* label = [[UILabel alloc] init];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    label.text = @"HAHA ! Looser !";
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:35];
    label.tintColor = [UIColor blackColor];
    [mLooserDialogue addSubview:label];
    
    UIButton* button =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [button setTitle:@"Replay!" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button.titleLabel setFont: [button.titleLabel.font fontWithSize:30]];
    button.layer.borderColor = [UIColor blackColor].CGColor;
    button.layer.borderWidth = 2.f;
    button.layer.cornerRadius = 20.f;
    [button addTarget:self action:@selector(replay) forControlEvents:UIControlEventTouchUpInside];
    [mLooserDialogue addSubview:button];
    
    pbutton =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [pbutton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [pbutton setTitle:@"Previous lvl ;-(" forState:UIControlStateNormal];
    [pbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [pbutton.titleLabel setFont: [button.titleLabel.font fontWithSize:30]];
    pbutton.layer.borderColor = [UIColor blackColor].CGColor;
    pbutton.layer.borderWidth = 2.f;
    pbutton.layer.cornerRadius = 20.f;
    [pbutton addTarget:self action:@selector(previousPlay) forControlEvents:UIControlEventTouchUpInside];
    [mLooserDialogue addSubview:pbutton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(label, pbutton, button);
    
    NSArray *lhorizontalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[label]-20-|" options:0 metrics:nil views:views];
    NSArray *bhorizontalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[button]-20-|" options:0 metrics:nil views:views];
    NSArray *phorizontalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[pbutton]-20-|" options:0 metrics:nil views:views];
    NSArray *verticalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[label]-20-[pbutton]-20-[button]-20-|" options:0 metrics:nil views:views];
    
    [mLooserDialogue addConstraints:verticalConstraints];
    [mLooserDialogue addConstraints:bhorizontalConstraints];
    [mLooserDialogue addConstraints:phorizontalConstraints];
    [mLooserDialogue addConstraints:lhorizontalConstraints];
}

-(void)replay
{
    // Hide the dialogues
    mLooserDialogue.hidden = YES;
    mWinnerDialogue.hidden = YES;
    // Replay with the current level
    [self play:mLevel];
}

-(void)youWinner
{
    mWinnerDialogue = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 150,100,300,300)];
    mWinnerDialogue.layer.borderColor = [UIColor blackColor].CGColor;
    mWinnerDialogue.layer.cornerRadius = 10.0f;
    mWinnerDialogue.layer.borderWidth = 3.0f;
    mWinnerDialogue.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:mWinnerDialogue];
    
    UILabel* label = [[UILabel alloc] init];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    label.text = @"You Won !";
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:35];
    label.tintColor = [UIColor blackColor];
    [mWinnerDialogue addSubview:label];
    
    UIButton* nbutton =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [nbutton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [nbutton setTitle:@"Next lvl!" forState:UIControlStateNormal];
    [nbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [nbutton.titleLabel setFont: [nbutton.titleLabel.font fontWithSize:30]];
    nbutton.layer.borderColor = [UIColor blackColor].CGColor;
    nbutton.layer.borderWidth = 2.f;
    nbutton.layer.cornerRadius = 20.f;
    [nbutton addTarget:self action:@selector(nextPlay) forControlEvents:UIControlEventTouchUpInside];
    [mWinnerDialogue addSubview:nbutton];
    
    UIButton* rbutton =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [rbutton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [rbutton setTitle:@"Replay" forState:UIControlStateNormal];
    [rbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [rbutton.titleLabel setFont: [rbutton.titleLabel.font fontWithSize:30]];
    rbutton.layer.borderColor = [UIColor blackColor].CGColor;
    rbutton.layer.borderWidth = 2.f;
    rbutton.layer.cornerRadius = 20.f;
    [rbutton addTarget:self action:@selector(replay) forControlEvents:UIControlEventTouchUpInside];
    [mWinnerDialogue addSubview:rbutton];
    
    UIButton* sbutton =[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sbutton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [sbutton setTitle:@"Share" forState:UIControlStateNormal];
    [sbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [sbutton.titleLabel setFont: [rbutton.titleLabel.font fontWithSize:30]];
    sbutton.layer.borderColor = [UIColor blackColor].CGColor;
    sbutton.layer.borderWidth = 2.f;
    sbutton.layer.cornerRadius = 20.f;
    [sbutton addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
    [mWinnerDialogue addSubview:sbutton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(label, nbutton, rbutton, sbutton);
    
    NSArray *lhorizontalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[label]-20-|" options:0 metrics:nil views:views];
    NSArray *bhorizontalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[nbutton]-20-|" options:0 metrics:nil views:views];
    NSArray *rhorizontalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[rbutton]-20-|" options:0 metrics:nil views:views];
    NSArray *shorizontalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[sbutton]-20-|" options:0 metrics:nil views:views];
    NSArray *verticalConstraints =[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[label]-20-[nbutton]-20-[rbutton]-20-[sbutton]-20-|" options:0 metrics:nil views:views];
    
    [mWinnerDialogue addConstraints:verticalConstraints];
    [mWinnerDialogue addConstraints:bhorizontalConstraints];
    [mWinnerDialogue addConstraints:rhorizontalConstraints];
    [mWinnerDialogue addConstraints:shorizontalConstraints];
    [mWinnerDialogue addConstraints:lhorizontalConstraints];
}

-(void)nextPlay
{
    // Hide the dilogues
    mWinnerDialogue.hidden = YES;
    mLooserDialogue.hidden = YES;
    
    // Increase the difficulty level
    [self play:mLevel + 1];
}

-(void)previousPlay
{
    // Hide the dilogues
    mWinnerDialogue.hidden = YES;
    mLooserDialogue.hidden = YES;
    
    if (mLevel > 1)
    {
        // Decrease the difficulty level
        mLevel = mLevel - 1;
    }
    [self play:mLevel];
}

-(void)share
{
    // Facebook share
    NSString* text= [NSString stringWithFormat:@"I beat Pacho in %ld lvl", mLevel];
    //NSURL *myWebsite = [NSURL URLWithString:@"http://www.website.com/"];
    //  UIImage * myImage =[UIImage imageNamed:@"myImage.png"];
    NSArray* sharedObjects=@[text, mScreeshot];
    UIActivityViewController * activityViewController=[[UIActivityViewController alloc]initWithActivityItems:sharedObjects applicationActivities:nil];
    
    activityViewController.popoverPresentationController.sourceView = self.view;
    [self.view.window.rootViewController presentViewController:activityViewController animated:YES completion:nil];
}

-(void)play:(NSInteger)level {
    mShots = 3;
    mLevel = level;
    
    // Set the shots number
    mPower.text = [NSString stringWithFormat:@"SHOT %ld!", (long)mShots];
    
    // Remove shots
    [mDummy1 removeAllActions];
    [mDummy1 removeAllChildren];
    [mDummy1 removeFromParent];
    [mDummy2 removeAllActions];
    [mDummy2 removeAllChildren];
    [mDummy2 removeFromParent];
    [mDummy3 removeAllActions];
    [mDummy3 removeAllChildren];
    [mDummy3 removeFromParent];
    
    
    // Moved Pacho to starting position and start the play
    [mPacho removeAllActions];
    [mPacho runAction:[SKAction rotateByAngle:0.0 duration:0.0]];

    // Start turning Pacho
    SKAction *action = [SKAction rotateByAngle:-M_PI duration:4.f / mLevel];
    [mPacho runAction:[SKAction repeatActionForever:action]];
    
    mTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                              target:self
                                            selector:@selector(timerCalled)
                                            userInfo:nil
                                             repeats:YES];
    mRunning = YES;
    mStartDate = [NSDate date];
    
    mPachoTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                    target:self
                                                  selector:@selector(pachoWins)
                                                  userInfo:nil
                                                   repeats:NO];
    
}

-(void)timerCalled
{
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:mStartDate];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss.SSS"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    NSString *timeString=[dateFormatter stringFromDate:timerDate];
    mTimerLabel.text = [NSString stringWithFormat:@"Lvl %ld - %@", mLevel, timeString ];
}

-(void)playHAHA
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"haha" ofType:@"m4a"];
                       SystemSoundID soundID;
                       AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
                       AudioServicesPlaySystemSound (soundID);
                   });
}

-(void)playYOOHOO
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"yoohoo" ofType:@"m4a"];
                       SystemSoundID soundID;
                       AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
                       AudioServicesPlaySystemSound (soundID);
                   });
}

-(void)pachoWins
{
    // Update game status
    mRunning = FALSE;
    
    // Invalidate the running status timer
    [mTimer invalidate];
    [mPachoTimer invalidate];
    
    // Stop Pacho
    [mPacho removeAllActions];
    
    // Stop shots
    [mDummy1 removeAllActions];
    [mDummy2 removeAllActions];
    [mDummy3 removeAllActions];
    
    // Show looser's dialogue
    mLooserDialogue.hidden = NO;

    // HAHA sound
    [self playHAHA];

    if (mLevel > 1)
        pbutton.hidden = NO;
    else
        pbutton.hidden = YES;
}

@end
