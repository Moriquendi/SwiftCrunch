//
//  ViewController.swift
//  MMSVideoFun
//
//  Created by Michal Smialko on 7/5/14.
//  Copyright (c) 2014 NSSpot. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import MediaPlayer

@infix func + (left: AVURLAsset, right: AVURLAsset) -> AVURLAsset! {
 
    // ------------------------------------------------- //
    
    func merge() -> AVURLAsset! {
        var composition = AVMutableComposition()
        
        var trackId = CMPersistentTrackID(kCMPersistentTrackID_Invalid)
        let compositionVideoTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo,
            preferredTrackID:CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        
        var t = kCMTimeZero;
        
        let clips = [left.URL, right.URL]

        for i in 0..2 {
            let sourceAsset = AVURLAsset(URL: clips[i], options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
            
            // Video
            var sourceVideoTrack:AVAssetTrack
            if sourceAsset.tracksWithMediaType(AVMediaTypeVideo).count > 0 {
                sourceVideoTrack = (sourceAsset.tracksWithMediaType(AVMediaTypeVideo))[0] as AVAssetTrack
            }
            else {
                break
            }
         
            var error:NSErrorPointer = nil
            var ok = false;
            ok = compositionVideoTrack.insertTimeRange(sourceVideoTrack.timeRange,
                                        ofTrack: sourceVideoTrack,
                                        atTime: composition.duration,
                                        error: error)
            
            if !ok {
                NSLog("something went wrong");
            }
            
            // Audio
            
            if sourceAsset.tracksWithMediaType(AVMediaTypeAudio).count > 0 {
                let audioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
                
                audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero,
                    sourceVideoTrack.timeRange.duration),
                    ofTrack: sourceAsset.tracksWithMediaType(AVMediaTypeAudio)[0] as AVAssetTrack,
                    atTime: t,
                    error: nil)
            }
            

            t = CMTimeAdd(t, sourceVideoTrack.timeRange.duration);
        }
        

        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.AllDomainsMask, true);
        
        var outputPath:NSString = ""
        while true {
            outputPath = paths[0] as NSString
            let prefix:Int = random()
            outputPath = outputPath.stringByAppendingPathComponent("out\(prefix).mov")
            
            if !NSFileManager.defaultManager().fileExistsAtPath(outputPath) {
                break
            }
        }
        let outputURL = NSURL(fileURLWithPath: outputPath)

        // First cleanup
        var error:NSErrorPointer = nil
        NSFileManager.defaultManager().removeItemAtURL(outputURL, error: error)
        
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter.outputURL = outputURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        
        var finished = false
        exporter.exportAsynchronouslyWithCompletionHandler({
            
            if exporter.status != AVAssetExportSessionStatus.Completed {
                println("Merge error \(exporter.error)")
            }

            // Remove old assetes
            NSFileManager.defaultManager().removeItemAtURL(left.URL, error: nil)
            NSFileManager.defaultManager().removeItemAtURL(right.URL, error: nil)
            
            println("FINISH")
            
            finished = true
            })

        // Wait for exporter to finish
        while !finished {}
        
        return AVURLAsset(URL: outputURL, options: nil)
    }
    
    return merge()
}


class ViewController: UIViewController {
    
    let player = MPMoviePlayerViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func didTapButton(sender : UIButton) {
        let clipURL1 = NSBundle.mainBundle().URLForResource("jamie1", withExtension: "mov");
        let clipURL2 = NSBundle.mainBundle().URLForResource("jamie2", withExtension: "mov");
        let clipURL3 = NSBundle.mainBundle().URLForResource("dave", withExtension: "mov");
        
        let movie1 = AVURLAsset(URL: clipURL1, options: nil)
        let movie2 = AVURLAsset(URL: clipURL2, options: nil)
        let movie3 = AVURLAsset(URL: clipURL3, options: nil)
        
        let asset:AVURLAsset = movie1 + movie2 + movie3
        self.player.moviePlayer.contentURL = asset.URL
    }

    @IBAction func play(sender : UIButton) {
        self.presentViewController(self.player, animated: true, completion: nil)
    }
    
}

