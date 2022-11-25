#import "FlutterRingtonePlayerPlugin.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface FlutterRingtonePlayerPlugin()<AVAudioPlayerDelegate>

@end

@implementation FlutterRingtonePlayerPlugin
NSObject <FlutterPluginRegistrar> *pluginRegistrar = nil;
AVAudioPlayer *audioPlayer;

+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    pluginRegistrar = registrar;
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"flutter_ringtone_player"
                  binaryMessenger:[registrar messenger]];
    FlutterRingtonePlayerPlugin *instance = [[FlutterRingtonePlayerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void) increaseVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
      UISlider *volumeViewSlider = nil;

      for (UIView *view in volumeView.subviews) {
        if ([view isKindOfClass:[UISlider class]]) {
          volumeViewSlider = (UISlider *)view;
          break;
        }
      }

      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        volumeViewSlider.value = 1.0f;
      });
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"play" isEqualToString:call.method]) {
        SystemSoundID soundId = nil;
        CFURLRef soundFileURLRef = nil;
        // NSLog(@"content: %@", call.arguments);
        if (call.arguments[@"uri"] != nil) {
            NSString *key = [pluginRegistrar lookupKeyForAsset:call.arguments[@"uri"]];
            NSURL *path = [[NSBundle mainBundle] URLForResource:key withExtension:nil];
            NSError *error = nil;
//            soundFileURLRef = CFBridgingRetain(path);
//            AudioServicesCreateSystemSoundID(soundFileURLRef, &soundId);
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:path error:&error];
            if (error != nil) {
                NSLog(@"AVAudioPlayer error: %@", [error localizedDescription]);
            } else {
                
                // Setting sound
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    // NSLog(@"userNotificationCenter willPresentNotification");
                    NSError *error = nil;
                    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionDuckOthers error:&error];
                    [[AVAudioSession sharedInstance] setActive:TRUE error:&error];
                    if (nil != error) {
                        NSLog(@"%@", [error localizedDescription]);
                    }
                });
                
                //vibrate phone first
                [self increaseVolume];
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
                
                // Play sound
                audioPlayer.numberOfLoops = 0;
                audioPlayer.volume = 1.0;
                audioPlayer.delegate = self;
                [audioPlayer prepareToPlay];
                [audioPlayer play];
            }
        }

        // The iosSound overrides fromAsset if exists
        if (call.arguments[@"ios"] != nil) {
            soundId = (SystemSoundID) [call.arguments[@"ios"] integerValue];
        }

        AudioServicesPlaySystemSound(soundId);
        if (soundFileURLRef != nil) {
            CFRelease(soundFileURLRef);
        }

        result(nil);
    } else if ([@"stop" isEqualToString:call.method]) {
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // NSLog(@"userNotificationCenter willPresentNotification");
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive:FALSE error:&error];
        if (nil != error) {
            NSLog(@"%@", [error localizedDescription]);
        }
    });
}

@end
