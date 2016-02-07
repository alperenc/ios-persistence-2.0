//
//  RecordSoundsViewController.swift
//  Pick Your Pitch
//
//  Created by Udacity on 1/5/15.
//  Copyright (c) 2014 Udacity. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {

    @IBOutlet weak var recordingInProgress: UILabel!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    
    var audioRecorder:AVAudioRecorder!
    var recordedAudio:RecordedAudio!
    var shouldSegueToSoundPlayer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if a previous recording exists
        if NSFileManager.defaultManager().fileExistsAtPath(audioFileURL().path!) {
            print("The file already exists!")
            shouldSegueToSoundPlayer = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        //Hide the stop button
        stopButton.hidden = true
        recordButton.enabled = true
        
        // Segue to sound player if a recording exists from previous runs of the app
        if shouldSegueToSoundPlayer {
            shouldSegueToSoundPlayer = false
            performSegueWithIdentifier("stopRecording", sender: self)
        }
    }

    @IBAction func recordAudio(sender: UIButton) {
        // Update the UI
        stopButton.hidden = false
        recordingInProgress.hidden = false
        recordButton.enabled = false
        
        // Setup audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch _ {
        }

        do {
            // Initialize and prepare the recorder
            audioRecorder = try AVAudioRecorder(URL: audioFileURL(), settings: [String : AnyObject]())
        } catch _ {
            audioRecorder = nil
        }
        audioRecorder.delegate = self
        audioRecorder.meteringEnabled = true;
        audioRecorder.prepareToRecord()

        audioRecorder.record()
    }
    
    // Returns a URL to the audio file.
    // This is the code that was refactored out of the
    // recordAudio() method in this step.
    func audioFileURL() ->  NSURL {
        let filename = "usersVoice.wav"
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let pathArray = [dirPath, filename]
        let fileURL =  NSURL.fileURLWithPathComponents(pathArray)!
        
        return fileURL
    }

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {

        if flag {
            self.performSegueWithIdentifier("stopRecording", sender: self)
        } else {
            print("Recording was not successful")
            recordButton.enabled = true
            stopButton.hidden = true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "stopRecording" {
            let pathUrl = audioFileURL()
            recordedAudio = RecordedAudio(filePathUrl: pathUrl, title: pathUrl.pathExtension)
            
            let playSoundsVC:PlaySoundsViewController = segue.destinationViewController as! PlaySoundsViewController
            let data = recordedAudio
            playSoundsVC.receivedAudio = data
        }
    }
    
    @IBAction func stopAudio(sender: UIButton) {
        recordingInProgress.hidden = true
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance();
        do {
            try audioSession.setActive(false)
        } catch _ {
        }
        
        // This function stops the audio. We will then wait to hear back from the recorder, 
        // through the audioRecorderDidFinishRecording method
    }
}

