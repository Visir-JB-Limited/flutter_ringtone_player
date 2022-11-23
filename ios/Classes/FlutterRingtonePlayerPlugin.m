#import "FlutterRingtonePlayerPlugin.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

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

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"play" isEqualToString:call.method]) {        
        SystemSoundID soundId = nil;
        CFURLRef soundFileURLRef = nil;
        NSLog(@"content: %@", call.arguments);
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
                audioPlayer.numberOfLoops = 1;
                audioPlayer.delegate = self;
                [audioPlayer setVolume:1.0];
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
    NSLog(@"%d",flag);
}

@end
