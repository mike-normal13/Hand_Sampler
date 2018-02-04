//
//  AppDelegate.swift
//  Sampler_App
//
//  Created by mike on 2/27/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import CallKit
import CoreBluetooth

/** notification keys help deal with handling incoming calls */
let interruptStartedNotifyKey = "co.budge.start";
let interruptEndedNotifyKey = "co.budge.end";
/** file selector cell notification key */
let fileSelectorCellLoadWasCancelledKey = "co.budge.resetFileSelectorCell";
let fileCellBeganPreviewKey = "co.budge.FileCellBeganPreview";
let fileCellEndedPreviewKey = "co.budge.FileCellEndedPreview";
let songCellTouchedDownKey = "co.budge.SongCellTouchedDown";
let songCellTouchedUpKey = "co.budge.SongCellTouchedUp";

// we need this definition
class SplashViewController: UIViewController{}

@available(iOS 10.0, *)
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var _debugFlag = false;
    
    var window: UIWindow?
    var _rootVC: UINavigationController! = nil;
    var _songTVC: SongViewController! = nil;
    
    private var _audioSession: AVAudioSession! = nil;
    private var _callObserver: CXCallObserver!;
    
    /** a selection of audio beffer durations which will be selected based upon the device */
    private enum _bufferDurations: Double
    {
        case ten = 0.006; // this case is used by iOS 11 as well
        case nine = 0.007;
        case eight = 0.071;
        case seven = 0.0711;
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        UIApplication.shared.isStatusBarHidden = false;
        
        _callObserver = CXCallObserver();
        _callObserver.setDelegate(self, queue: nil);
        
        _audioSession = AVAudioSession.sharedInstance()
        configureAudioSession();
        
        // AppDelegate does not come with a storyboard 
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        _rootVC = mainStoryboard.instantiateViewController(withIdentifier: "RootNavVC") as! UINavigationController;
        
        window?.rootViewController = _rootVC;
        self.window?.makeKeyAndVisible();
        
        setUpAudioInturruptNotification();
        setupMediaServicesWereResetNotification();
    
        _songTVC = mainStoryboard.instantiateViewController(withIdentifier: "SongTVC") as! SongViewController
        _songTVC.hardwareOutputs = _audioSession.maximumOutputNumberOfChannels;
        
        let splashVC = mainStoryboard.instantiateViewController(withIdentifier: "SplashVC") as! SplashViewController;
        
        // this is necessaty to prevent the nav bar from flashing while the splash screen is visible.
        _rootVC.isNavigationBarHidden = true;
        
        _rootVC.present(splashVC, animated: true, completion: nil);
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute:
        {   self._rootVC.dismiss(animated: true, completion: nil);  })
        
        _rootVC.pushViewController(_songTVC, animated: true);
        
        return true
    }
    
    private func configureAudioSession()
    {
        setBufferDuration();
        
        do
        {
            try _audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: [.defaultToSpeaker, .allowBluetoothA2DP]);
        }
        catch
        {
            print("AppDelegate could not set audio session catagory .defaultToSpeaker.\n");
            print(error.localizedDescription);
        }
    }
    
    /** set buffer duration based upon device */
    private func setBufferDuration()
    {
        if(_debugFlag)
        {
            print("Buffer Duration prior to setting: " + _audioSession.ioBufferDuration.description);
        }
        
        if #available(iOS 11.0, *)
        {
            //http://stackoverflow.com/questions/34680007/answer/submit#
            do
            {
                try _audioSession.setPreferredIOBufferDuration(_bufferDurations.ten.rawValue);
                if(_debugFlag)
                {
                    print("Buffer duration was set for iOS 11.0");
                    print("Actual Buffer duration: " + _audioSession.ioBufferDuration.description);
                }
            }
            catch{  print("Trouble with setting audio session's buffer duration for iOS 11.0!");    }
            return;
        }
        
        if #available(iOS 10.0, *)
        {
            //http://stackoverflow.com/questions/34680007/answer/submit#
            do
            {
                try _audioSession.setPreferredIOBufferDuration(_bufferDurations.ten.rawValue);
                if(_debugFlag)
                {
                    print("Buffer duration was set for iOS 10.0");
                    print("Actual Buffer duration: " + _audioSession.ioBufferDuration.description);
                }
            }
            catch{  print("Trouble with setting audio session's buffer duration for iOS 10.0!");    }
            return;
        }
        
        if #available(iOS 9.0, *)
        {
            do
            {
                try _audioSession.setPreferredIOBufferDuration(_bufferDurations.nine.rawValue);
                if(_debugFlag){ print("Buffer duration was set for iOS 9.0");   }
            }
            catch{  print("Trouble with setting audio session's buffer duration for iOS 9.0!"); }
            return;
        }

        if #available(iOS 8.0, *)
        {
            do{ try _audioSession.setPreferredIOBufferDuration(_bufferDurations.eight.rawValue); }
            catch{  print("Trouble with setting audio session's buffer duration for iOS 8.0!"); }
            return;
        }

         if #available(iOS 7.0, *)
        {
            do{ try _audioSession.setPreferredIOBufferDuration(_bufferDurations.seven.rawValue); }
            catch{  print("Trouble with setting audio session's buffer duration for iOS 7.0!"); }
            return;
        }
    }
    
    private func setUpAudioInturruptNotification()
    {
        //  TODO: the apple guide for handling audio inturuptions has this code inside of a function.
        NotificationCenter.default.addObserver(forName: .AVAudioSessionInterruption, object: nil, queue: nil)
        {
            n in
                let why = AVAudioSessionInterruptionType(rawValue: n.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt)!
                if why == .began
                {
                    if(self._debugFlag){ print("interruption began:\n\(n.userInfo!)");   }
                    
                    UIApplication.shared.beginIgnoringInteractionEvents();
                    if(self._debugFlag)
                    {
                        print("setUpAudioInterruptionNotification() in AppDelegate Application began ignoring interaction events. Thread: " + Thread.current.name!);
                        print("session catagory: " + AVAudioSession.sharedInstance().category.debugDescription);
                        print("input number of channels: " + AVAudioSession.sharedInstance().inputNumberOfChannels.description);
                        print("is other audio playing: " + AVAudioSession.sharedInstance().isOtherAudioPlaying.description);
                        print("mode: " + AVAudioSession.sharedInstance().mode.debugDescription);
                        print("outputNUmberOfChannels: " + AVAudioSession.sharedInstance().outputNumberOfChannels.description);
                        print("sampleRate: " + AVAudioSession.sharedInstance().sampleRate.debugDescription)
                    }
                    
                    let name = Notification.Name(rawValue: interruptStartedNotifyKey);
                    
                    NotificationCenter.default.post(name: name, object: nil);
                }
                // else if the interruption ended
                else
                {
                    if(self._debugFlag){ print("interruption ended:\n\(n.userInfo!)");   }
                    
                    let name = Notification.Name(rawValue: interruptEndedNotifyKey);
                    NotificationCenter.default.post(name: name, object: nil);
                
                    guard let opt = n.userInfo![AVAudioSessionInterruptionOptionKey] as? UInt else{ return  }
                
                    if AVAudioSessionInterruptionOptions(rawValue:opt).contains(.shouldResume)
                    {
                        if(self._debugFlag){ print("should resume"); }
                        self.setAudioSession(active: true);
                    }
                    else{   if(self._debugFlag){ print("not should resume"); }  }
                    
                    if(UIApplication.shared.isIgnoringInteractionEvents){   UIApplication.shared.endIgnoringInteractionEvents();    }
                    if(self._debugFlag)
                    {
                        print("setUpAudioInterruptionNotification() in AppDelegate Application stopped ignoring interaction events");
                    }
            }
        }
    }
    
    // as of 11/14/2017 this is not fully implemented
    private func setupMediaServicesWereResetNotification()
    {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVAudioSessionMediaServicesWereReset, object: nil, queue: nil)
        {
            n in
            
            let visibleSongNumber = self.killSoundModsAndBankVCs();
            let mediaServicesResetAlert = UIAlertController(title: "Media Server Reset", message: "Debug findVisibleVC()!", preferredStyle: .alert);
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler:
            {
                (action:UIAlertAction) in
                
                self.handleMediaServerReset(visibleSongNumber: visibleSongNumber);
            });
            
            mediaServicesResetAlert.addAction(okAction);
            
            self._rootVC.present(mediaServicesResetAlert, animated: true, completion: nil);
            
            //  TODO:  whole bunch of stuff needs to happen here...
            //              https://developer.apple.com/library/content/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/HandlingAudioInterruptions/HandlingAudioInterruptions.html
        }
    }
    
    /** meant to help with handling a media services reset.
            returns the song number of the visible song */
    private func killSoundModsAndBankVCs() -> Int
    {
        var visibleSongNumber = -1;
        
        // destroy all sound mods and bankVCs regardless of which song or vc is visible
        for i in 0 ..< _songTVC.nSongs
        {
            if(_songTVC.samplerConfigVCArray[i]?.isVisibleSong)!
            {
                visibleSongNumber = (_songTVC.samplerConfigVCArray[i]?.songNumber)!;
                
                _songTVC.navigationController?.popToViewController(_songTVC.samplerConfigVCArray[visibleSongNumber - 1]!, animated: false);
            }
            
            if(_songTVC.samplerConfigVCArray[i]?.song != nil)
            {
                _songTVC.samplerConfigVCArray[i]?.song.masterSoundMod = nil;
                
                for j in 0 ..< _songTVC.maxNBanks where _songTVC.samplerConfigVCArray[i]?.song.bankViewStackControllerArray != nil
                {   _songTVC.samplerConfigVCArray[i]?.song.bankViewStackControllerArray[j] = nil    }
            }
        }
        return visibleSongNumber;
    }
    
    //  TODO: this method is called when a call comes but before it is answered.
    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    
        // stop any previewing in an FileSelectorVC;
        //stopFileSelectorPreview();
        
        setAudioSession(active: false);
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        //  TODO: this reuslted in error printed out to the console
        //              when the media server was reset
        setAudioSession(active: true);
    }

    //  TODO: this is called when a phone call is ended
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        //  TODO: this seems problematic.....
        if(UIApplication.shared.isIgnoringInteractionEvents)
        {
            UIApplication.shared.endIgnoringInteractionEvents();
            if(_debugFlag){ print("+++++++applicationDidBecomeActive in AppDelegate stopped ignoring application interaction events");  }
        }
    
        //  in your app delegate’s applicationDidBecomeActive: method,
        //      inspect the audio session’s secondaryAudioShouldBeSilencedHint property to determine if audio is already playing.
        //      The value is true when another app with a nonmixable audio session is playing audio.
        //      Apps should use this property as a hint to silence audio that is secondary to the functioning of the app.
        //      For example,
        //          a game using AVAudioSessionCategoryAmbient can use this property to determine
        //              if it should mute its soundtrack while leaving its sound effects unmuted.
    }

    //  BE aware 1/18/2018 this method is not called if the app is terminated while the app is in a Suspended state....
    //  TODO: as of 10/16/2017 this code is very old.
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
        // look for any visible songs which are currently connected to the host
        if(_songTVC != nil)
        {
            if(_songTVC.samplerConfigVCArray.count > 0)
            {
                for i in 0 ..< _songTVC.samplerConfigVCArray.count
                {
                    if(_songTVC.samplerConfigVCArray[i]?.song.isConnected)!
                    {   _songTVC.samplerConfigVCArray[i]?.song.syncTransmitter.sendSongWillDisconnect();  }
                }
            }
        }
        
        self.saveContext()
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Sampler_App")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    /** activate or deactivate the audio session */
    private func setAudioSession(active: Bool)
    {
        if(!_songTVC.isRecordingTakingPlace())
        {
            UIApplication.shared.beginIgnoringInteractionEvents();
            if(_debugFlag){ print("setAudioSession() in AppDelegate began ignoring interaction events");    }
            setAllRunningSoundMods(stop: !active);
        
            if(UIApplication.shared.applicationState != .inactive && UIApplication.shared.applicationState != .background)
            {
                do{ try _audioSession.setActive(active);    }
                catch
                {
                    if(active){   print("App Delegate could not activate audio session.\n");  }
                    else{   print("App Delegate could not deactivate audio session.\n");    }
                    print(error.localizedDescription);
                }
            }
            else
            {
                if(_debugFlag)
                {
                    print("setAudioSession() in AppDelegate could not set the audio session to: " + active.description + " because the application was either inactive or in the background");
                }
            }
            
            UIApplication.shared.endIgnoringInteractionEvents();
            if(_debugFlag){ print("setAudioSession() in AppDelegate stopped ignoring interaction events");  }
        }
        else
        {
            if(_debugFlag){ print("<<<<<<<<< setAudioSession() in Appdelegate failed to set audio session due to recording taking place");  }
        }
    }
    
    /** when the app moves to and from the background we need to start/stop all active sounds engines */
    private func setAllRunningSoundMods(stop: Bool)
    {
        UIApplication.shared.beginIgnoringInteractionEvents();
        if(_debugFlag){ print("setAllRunningSoundMods in AppDelegate began ignoring interaction events");   }
        
        for sampler in _songTVC.samplerConfigVCArray where sampler != nil && sampler?.song != nil && sampler?.song.masterSoundMod != nil
        {
                if(stop && (sampler?.song.masterSoundMod.isRunning)!){  sampler?.song.masterSoundMod.stopMod(); }
                else if(!stop && !(sampler?.song.masterSoundMod.isRunning)!)
                {   sampler?.song.masterSoundMod.startMod();    }
        }
        
        UIApplication.shared.endIgnoringInteractionEvents();
        if(_debugFlag){ print("setAllRunningSoundMods in AppDelegate stopped ignoring interaction events"); }
    }
    
    //  TODO: as of 12/14/2017 this does not actually work,
    //          we should use an observer/notification...
    /** if the app enters the background while a song is being loaded due to the Go To Song Button being pushed in the SamplerConfigVC,
            once the app re enters the foreground we need to start animating the activity indicator again */
    func reanimateSamplerConfigVC(){    _songTVC.reanimateSamplerConfigVC();    }
}

/** This observer is triggered whenever a call is accepted and then ended.
     There were some instances where the user ending the call,
        or the call being disconnected would not trigger the AVAudioSessionInterruption observer above.
    We implemented this extension to specifically deal with the case where
                the phone is connected to bluetooth while a call is accepted and then disconnected,
                    either by the user or the other end of the call. */
//  https://stackoverflow.com/questions/40021317/get-phone-call-states-in-ios-10
@available(iOS 10.0, *)
extension AppDelegate: CXCallObserverDelegate
{
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall)
    {
        if call.hasEnded == true
        {
            if(_debugFlag){ print("Call Disconnected"); }
            
            let name = Notification.Name(rawValue: interruptEndedNotifyKey);
            NotificationCenter.default.post(name: name, object: nil);
            
            if(UIApplication.shared.isIgnoringInteractionEvents)
            {
                UIApplication.shared.endIgnoringInteractionEvents();
                if(_debugFlag){ print("CXCallObserverDelegate in AppDelegate stopped ignoring interaction events"); }
            }
        }

        if(call.hasConnected == true && call.hasEnded == false)
        {
            if(_debugFlag){ print("Call Connected");    }
        }
    }
}
