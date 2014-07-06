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

@infix func + ( left:AVURLAsset,
                right:(asset:AVURLAsset, range:Range<Int>)) -> AVURLAsset! {

                    var fullRange:Range<Int> = Range(start: 0, end: Int(CMTimeGetSeconds(left.duration)))
                    return (left, fullRange) + right
}

@infix func + ( left:(asset: AVURLAsset, range:Range<Int>),
                right:(asset:AVURLAsset, range:Range<Int>)) -> AVURLAsset! {
    
    // ------------------------------------------------- //
    func merge() -> AVURLAsset! {
        var composition = AVMutableComposition()
        
        var trackId = CMPersistentTrackID(kCMPersistentTrackID_Invalid)
        let compositionVideoTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo,
            preferredTrackID:CMPersistentTrackID(kCMPersistentTrackID_Invalid))
        
        var t = kCMTimeZero;
        
        let clips = [left.asset.URL, right.asset.URL]
        let ranges = [left.range, right.range]
        
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
            
            let range = ranges[i]
            var startSeconds:Float64 = Float64(range.startIndex)
            var durationSeconds:Float64 = Float64(range.endIndex - range.startIndex)
            
            let timeRange:CMTimeRange = CMTimeRange(start: CMTimeMakeWithSeconds(startSeconds, 600),
                                        duration: CMTimeMakeWithSeconds(durationSeconds, 600))
            
            
            ok = compositionVideoTrack.insertTimeRange(timeRange,
                                        ofTrack: sourceVideoTrack,
                                        atTime: composition.duration,
                                        error: error)
            if !ok {
                NSLog("something went wrong");
            }
            
            // Audio
            if sourceAsset.tracksWithMediaType(AVMediaTypeAudio).count > 0 {
                let audioTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))
                
                audioTrack.insertTimeRange(timeRange,
                    ofTrack: sourceAsset.tracksWithMediaType(AVMediaTypeAudio)[0] as AVAssetTrack,
                    atTime: t,
                    error: nil)
            }
            

            t = CMTimeAdd(t, timeRange.duration);
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
            NSFileManager.defaultManager().removeItemAtURL(left.asset.URL, error: nil)
            NSFileManager.defaultManager().removeItemAtURL(right.asset.URL, error: nil)
            
            println("FINISH")
            
            finished = true
            })

        // Wait for exporter to finish
        while !finished {}
        
        // Bleh, fuj. Exporter is deallocated. How to keep it?
        println("\(exporter)")
        
        return AVURLAsset(URL: outputURL, options: nil)
    }
    
    return merge()
}


class ViewController: UIViewController {
    
    let player = MPMoviePlayerViewController()

    @IBAction func didTapButton(sender : UIButton) {
        var bundle = NSBundle.mainBundle()
        
        let movie1 = AVURLAsset(URL: bundle.URLForResource("jamie1", withExtension: "mov"), options: nil);
        let movie2 = AVURLAsset(URL: bundle.URLForResource("jamie2", withExtension: "mov"), options: nil);
        let movie3 = AVURLAsset(URL: bundle.URLForResource("dave", withExtension: "mov"), options: nil);
        
        let mergedAsset:AVURLAsset = (movie1, 0..2) + (movie2, 0..2) + (movie3, 4..6)
        self.player.moviePlayer.contentURL = mergedAsset.URL
    }

    @IBAction func play(sender : UIButton) {
        self.presentViewController(self.player, animated: true, completion: nil)
    }
    
}

