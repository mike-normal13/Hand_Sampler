//
//  MasterSoundMod.swift
//  Sampler_App
//
//  Created by mike on 3/13/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import AVFoundation
import UIKit

//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

protocol PadModelParentProtocol: class
{
    func playthroughStop(bank: Int, pad: Int, index: Int, preview: Bool);
    /** once a playthrough pad's sound finishes playing we need to invalidate its volume data timer */
    func passPlaythroughEndedInvalidateVolumeTimer(bank: Int, pad: Int);
}

/** Sound Engine Model for a Song,
        One instance of this class will be owned by the Song class */
class MasterSoundMod: Sampler
{
    private var _debugFlag = true;
    
    private var _nBanks: Int = 3;
    private var _nPads: Int = 8;
    
    /** represents _nBanks X _nPads */
    private lazy var _soundCollection: [[PadModel?]?]! = [];
    var soundCollection: [[PadModel?]]!
    {
        get{    return _soundCollection as! [[PadModel?]]   }
        set{ _soundCollection = newValue;   }
    }
    
    private var _isRunning: Bool = false;
    var isRunning: Bool{    get{return _isRunning}  }
    
    /** this input format is based upon the format provided by the hardware */
    private var _inputFormat: AVAudioFormat! = nil;
    
    /** this output format is based upon the format provided by the hardware */
    private var _outputFormat: AVAudioFormat! = nil;
    
    /** every pad will have its own mixer,
            i.e. each of the player nodes associtaed with a pad will connect to a mixer node,
            thereby making it easier to adjust settings such as volume for all player nodes at once.
            each pad mixer node will be attached to the mixer node assigned to each bank */
    private var _padMixerArray: [[AVAudioMixerNode?]] = [];
    
    /** stores current play volume data for each pad mixer
         intended to be used for ui enhancements*/
    private var _padMixerVolumeDataArray: [[Float]] = [];
    
    /** used to get the current volume out of a player node at any given time,
            intended to aid in making UI enhancements */
    private var _volumeDataTimerArray: [[Timer?]] = [];
    
    /** frequency by which this class sends the signal to any given PadView to update its color */
    private var _volumeUpdateInterval = 0.01;
   
    /** used to apply instant fade out when a pad is released by the user */
    private var _releaseTimerArray: [[Timer?]] = [];
    var releaseTimerArray: [[Timer?]]{  get{    return _releaseTimerArray;  }   }
    
    private var _fadeCountArray: [[Int]] = [];
    private var _fadeScalarArray: [[Double]] = [];
    
    /** indicates whether the app is connected to the host. */
    private var _isConnected: Bool = false;
    var isConnected: Bool
    {
        get{    return _isConnected;    }
        set{    _isConnected = newValue;    }
    }
    
    /** reflects whether we are currently dealing with an audio route change in this class */
    private var _routeChanging = false;
    var routeChanging: Bool
    {
        get{    return _routeChanging;  }
        set{    _routeChanging = newValue;  }
    }
    
    private var _engine: AVAudioEngine! = nil;
    
    private var _interruptStartedName: Notification.Name! = Notification.Name(rawValue: interruptStartedNotifyKey);
    private var _interruptEndedName: Notification.Name! = Notification.Name(rawValue: interruptEndedNotifyKey);
    
    private var _interruptIsOnGoing = false;
    
    /** indicates whether a recording is ongoing,
            helpful to know in case an audio route occurs during a recording */
    private var _isRecording = false
    var isRecording: Bool
    {
        get{    return _isRecording;    }
        set{    _isRecording = newValue;    }
    }
    
    /** (bankNumber, padNumber) index of the pad that is currently recording */
    private var _recordingPad = (-1, -1)
    var recordingPad: (Int, Int)
    {
        get{    return _recordingPad;   }
        set{    _recordingPad = newValue;   }
    }
    
    private var _fadeOutTimerInterval = 0.001;
    
    private var _fadeDecrement = 0.03125; // 1/32
    
    /** on the spot fade consists of 32 frames */
    private var _fadeSpan = 32;
    
    /** reflects whether any given pad is properly connected to the sound engine.
            In many cases involving state changes to the app,
                e.g. the app moving to the background, or the off button being pressed,
                the sound graph will have to be disconnected and then reconnected again,
                    sometimes when the app is ready to go again there will be pads that were not correctly connected to the sound engine,
                        we have a method checkForPadConnection() which can check to see if a triggered pad is properly connected.
                            we don't want to trigger this method every time we press a pad,
                                it is a potential for latency.
                                    especially in older devices.
                    This array will help us not call the checkForPadConnection() method every time a pad is pressed. */
    private var _padConnectionStatusArray: [[Bool]] = [[]];
    
    /** an array of band aids for dangling timers */
    private var _danglingTimerCounterArray: [[Int]] = [];
    
    weak var _delegate: MasterSoundModParentProtocol! = nil;
    
    init(hardwareOutputs: Int)
    {
        super.init();
        
        assert(hardwareOutputs != -1)
        _engine = AVAudioEngine();
        _hardwareOutputs = hardwareOutputs;
        createObservers();
        
        // initialize the 2D sound collection and mixer arrays
        for i in 0 ..< _nBanks
        {
            _soundCollection.append([]);
            _padMixerArray.append([]);
            _padMixerVolumeDataArray.append([]);
            _volumeDataTimerArray.append([]);
            _releaseTimerArray.append([]);
            _fadeCountArray.append([]);
            _fadeScalarArray.append([]);
            _padConnectionStatusArray.append([])
            _danglingTimerCounterArray.append([]);
            
            for _ in 0 ..< _nPads
            {
                _soundCollection[i]!.append(nil);
                _padMixerArray[i].append(nil);
                _padMixerVolumeDataArray[i].append(0);
                _volumeDataTimerArray[i].append(nil);
                _releaseTimerArray[i].append(nil);
                _fadeCountArray[i].append(0);
                _fadeScalarArray[i].append(1.0);
                /** this assumes that every song will get launched with every pad perfectly connected*/
                _padConnectionStatusArray[i].append(true);
                _danglingTimerCounterArray[i].append(0);
            }
        }
        
        _inputFormat = _engine.inputNode.inputFormat(forBus: 0);
        _outputFormat = _engine.outputNode.outputFormat(forBus: 0);
    }
    
    //  DEBUG: this is getting called when we press the Go to Song button in SamplerConfigVC,
    //              which is wierd....
    deinit
    {
        for bank in 0 ..< _nBanks
        {
            for pad in 0 ..< _nPads
            {
                if(_soundCollection[bank]?.count != 0){ _soundCollection[bank]![pad] = nil; }
                if(_volumeDataTimerArray[bank].count != 0){ _volumeDataTimerArray[bank][pad] = nil; }
                if(_releaseTimerArray[bank].count != 0){    _releaseTimerArray[bank][pad] = nil;    }
                if(_padMixerArray[bank].count != 0){    _padMixerArray[bank][pad] = nil;    }
            }
            
            _soundCollection[bank] = nil;
            _volumeDataTimerArray[bank] = [];
            _releaseTimerArray[bank] = [];
            _padMixerArray[bank] = [];
            _releaseTimerArray[bank] = [];
            _danglingTimerCounterArray[bank] = [];
        }
    
        NotificationCenter.default.removeObserver(self);
        
        _inputFormat = nil;
        _outputFormat = nil;
        _engine = nil;
        _opQueue = nil;
        _delegate = nil;
        _interruptStartedName = nil;
        _interruptEndedName = nil;
        
        if(_debugFlag){ print("***MasterSoundMod deinitialized");   }
    }
    
    /** disconnect all nodes attached to the engine,
         this method is called in order to get the deinit method for this class called */
    func disconnectEngine()
    {
        // remove any present taps in the padMixerArray.
        for i in 0 ..< _nBanks
        {
            for j in 0 ..< _nPads where _soundCollection[i]![j] != nil
            {
                if(_soundCollection[i]![j]?.tapInstalled)!{ _padMixerArray[i][j]?.removeTap(onBus: 0);  }
            }
        }
        
        for i in 0 ..< _nBanks
        {
            for j in 0 ..< _nPads
            {
                if(_padMixerArray[i][j] != nil)  
                {
                    _engine.detach(_padMixerArray[i][j]!)
                    
                    if(_soundCollection[i]![j] != nil)
                    {
                        for k in 0 ..< _soundCollection[i]![j]!.playerNodeArrayCount
                        {
                            _engine.detach(_soundCollection[i]![j]!.varispeedNodeArray[k]!);
                            _engine.detach(_soundCollection[i]![j]!.playerNodeArray[k]!);
                        }
                    }
                }
                
                _padMixerArray[i][j] = nil;
                _padMixerVolumeDataArray[i][j] = 0;
            }
            
            _padMixerArray[i] = [];
            _padMixerVolumeDataArray[i] = [];
        }
    }
    
    /** connect each pad in the pad array to a mixer node,
            and then connect each mixer node for each pad to a single mixer node
                FYI: THE BANK NUMBER INDEX PASSED TO THIS METHOD IS ZERO INDEXED */
    func connectPadToMixer(bank: Int, pad: Int)
    {
        if(_outputFormat.channelCount == 0 && _outputFormat.sampleRate == 0.0)
        {
            if(_debugFlag){ print("!!!!!!! connectPadToMixer returned prematurely due to invalid _outputFormat");   }
            return;
        }
        // initialize pad's mixer node
        if(_padMixerArray[bank][pad] == nil){   _padMixerArray[bank][pad] = AVAudioMixerNode(); }
        
        /** the exception breakpoint is saying __cxa_throw is related to this */
        _engine.attach(_padMixerArray[bank][pad]!)
        
        if(_soundCollection[bank]![pad] != nil)
        {
            // we need to connect both the player nodes and varispeed nodes to the sound graph
            //  with formats based upon the format of the file loaded into the player nodes
            let tempPadSampleRate = _soundCollection[bank]![pad]?.file.fileFormat.sampleRate;
            let tempFileChannelCount = _soundCollection[bank]![pad]?.file.fileFormat.channelCount
            
            for i in 0 ..< (_soundCollection[bank]![pad]?.playerNodeArrayCount)!
            {
                // attach and connect varispeed nodes to the pad mixer
                _engine.attach((_soundCollection[bank]![pad]?.varispeedNodeArray[i])!);
                _engine.attach((_soundCollection[bank]![pad]?.playerNodeArray[i])!);
                _engine.connect((_soundCollection[bank]![pad]?.varispeedNodeArray[i])!, to: _padMixerArray[bank][pad]!, format: AVAudioFormat(standardFormatWithSampleRate: tempPadSampleRate!, channels: tempFileChannelCount!));
                
                _engine.connect((_soundCollection[bank]![pad]?.playerNodeArray[i])!, to: (_soundCollection[bank]![pad]?.varispeedNodeArray[i])!, format: AVAudioFormat(standardFormatWithSampleRate: tempPadSampleRate!, channels: tempFileChannelCount!));
            }
        }
        
        /** remember, 
                when swapping out sounds we found that the only way we could get this to work 
                    was to have all attach calls precede all connect calls.
                AND the call to connect to the pad mixer to the main mixer had to happen last!
                We had to start at the very end of the connection chain... */
        /** also,
                the format of the pad's mixer node will most likely differ from the format of the player and varispeed nodes attached to it
                    if any channel summing needs to happen,
                        this mixer node will take care of it.
                    this mixer node's number of channels is set based upon the number of channesl provided by the hard ware. */
        _engine.connect(_padMixerArray[bank][pad]!, to: _engine.mainMixerNode, format: _outputFormat);
        
        
        installReadTapOnPadMixer(bank: bank, pad: pad);
    }
    
    /** ui enhancements,
         gets the current play volume of the player node */
    private func installReadTapOnPadMixer(bank: Int, pad: Int)
    {
        if(_outputFormat.channelCount == 0 && _outputFormat.sampleRate == 0.0)
        {
            if(_debugFlag){ print("!!!!!!! installReadTapOnPadMixer() returned prematurely due to invalid _outputFormat");  }
            return;
        }
        
        // installing taps twice seems to be causing run time errors
        //  and the route change observer gets called any number of times per route change.
        guard(_soundCollection[bank]![pad]?.tapInstalled == false) else{ return;  }
        
        // https://miguelsaldana.me/2017/03/18/how-to-create-a-volume-meter-in-swift-3/
        _padMixerArray[bank][pad]?.installTap(onBus: 0, bufferSize: 1024, format: _outputFormat)
        {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) in
                let dataptrptr = buffer.floatChannelData!;
                let dataptr = dataptrptr.pointee;
                let datum = dataptr[Int(buffer.frameLength) - 1];
                self._padMixerVolumeDataArray[bank][pad] = fabs(datum);
        }
        
        _soundCollection[bank]![pad]?.tapInstalled = true;
    }
    
    /** detach a pad from the audio graph/engine in order to swap a new sound in,
            or to erasse the pad from memory. */
    func detachAndResetOrErasePad(bank: Int, pad: Int, erase: Bool)
    {
        _padMixerArray[bank][pad]?.removeTap(onBus: 0);
        _soundCollection[bank]![pad]?.tapInstalled = false;
        
        _engine.detach(_padMixerArray[bank][pad]!);
     
        // if we are erasing the pad
        if(erase)
        {
            _padMixerArray[bank][pad] = nil;
            _soundCollection[bank]![pad]?.file = nil;
            _soundCollection[bank]![pad] = nil;
        }
    }
    
    /** play a pad's current sound configuration */
    func play(bank: Int, pad: Int, preview: Bool, sequenceTouch: Bool)
    {
        cancelUntouchedPlaythroughPads(bank: bank, pad: pad);
        
        if(!_padConnectionStatusArray[bank][pad]){  var _ = checkForPadConnection(bank: bank, pad: pad);    }
        else
        {
            // no player node triggering while audio route change is in progress.
            if(!_isConnected && !_routeChanging && _engine.isRunning)      /** <- added check for _engine.isRunning on 11/28/2017 */
            {
                if((_soundCollection[bank]![pad]) != nil && (_soundCollection[bank]![pad])!.isLoaded)
                {
                    _soundCollection[bank]![pad]?.isTouched = true;
                    (_soundCollection[bank]![pad])!.play(preview: preview);
                }
            }

            if(!_engine.isRunning){ startMod(); }
        
            // the timer must not be scheduled for any preview or any blank pad
            if(!preview && !sequenceTouch)
            {
                if(_volumeDataTimerArray[bank][pad] == nil)
                {   triggerVolumeTimer(bank: bank, pad: pad);   }
            }
        }
    }
    
    private func triggerVolumeTimer(bank: Int, pad: Int)
    {
        if(_soundCollection[bank]![pad] != nil)
        {
            //      this is the only place in the entire code base where updateVolumeData() is called
            _volumeDataTimerArray[bank][pad] = Timer.scheduledTimer(timeInterval: _volumeUpdateInterval, target: self, selector: #selector(updateVolumeData(timer:)), userInfo: (bank, pad), repeats: true);
        }
    }
    
    /** stop playing the pad corresponding to the bank and pad number */
    func stop(bank: Int, pad: Int, preview: Bool)
    {
        _releaseTimerArray[bank][pad] = Timer()
        
        var preFadeVolume: Float = 0.0;
        
        if(_padMixerArray[bank][pad] != nil)
        {
            if(_soundCollection[bank]![pad] !=  nil){   preFadeVolume = (_soundCollection[bank]![pad]?.volume)! }
        }
        
        // no player node manipulation while audio route change is in progress.
        //      otherwise there is a run time exception.
        if(!_isConnected && !_routeChanging)
        {
            if((_soundCollection[bank]![pad]) != nil && (_soundCollection[bank]![pad])!.isLoaded)
            {
                _soundCollection[bank]![pad]?.isTouched = false;
                
                if((_releaseTimerArray[bank][pad] == nil) /*|| !(_releaseTimerArray[bankNumber][padNumber]?.isValid)!*/)
                {
                    if((_soundCollection[bank]![pad]?.startStopTriggerMode)!)
                    {
                        _releaseTimerArray[bank][pad] = Timer.scheduledTimer(timeInterval: _fadeOutTimerInterval, target: self, selector: #selector(self.fadeout(timer:)), userInfo: (bank, pad, preFadeVolume, preview), repeats: true);
                    }
                        // else if we are in through mode...
                    else
                    {   //  ... and previewing ....
                        if(preview)
                        {
                           _releaseTimerArray[bank][pad] = Timer.scheduledTimer(timeInterval: _fadeOutTimerInterval, target: self, selector: #selector(self.fadeout(timer:)), userInfo: (bank, pad, preFadeVolume, preview), repeats: true);
                        }
                    }
                }
            }
            
            if(_soundCollection[bank]![pad] != nil)
            {
                if((_soundCollection[bank]![pad]?.startStopTriggerMode)!)
                {
                    _volumeDataTimerArray[bank][pad]?.invalidate();
                    _volumeDataTimerArray[bank][pad] = nil;
            
                    if(_debugFlag)
                    {
                        print("_volumeDataTimer bank: " + bank.description + " pad: " + pad.description + " invalidated in stop() in masterSoundMod");
                    }
                }
           }
        }
    }
    
    private func cancelUntouchedPlaythroughPads(bank: Int, pad: Int)
    {
        if(_soundCollection != nil)
        {
            if(_soundCollection[bank] != nil)
            {
                for index in 0 ..< _nPads
                {
                    if(index == pad){   continue;   }
                    
                    if(_soundCollection[bank]![index] != nil)
                    {
                        if(!(_soundCollection[bank]![index]?.startStopTriggerMode)!)
                        {
                            if(!(_soundCollection[bank]![index]?.isTouched)!){  _soundCollection[bank]![index]?.cancelPlayThrough();    }
                        }
                    }
                }
            }
        }
    }
    
    /** pass the currently touched pad's current volume from here,
            up to the owning Song,
                and then down the line to the PadView object that corresponds to the Pad model which is currently playing
                    this method is used by a timer*/
    @objc func updateVolumeData(timer: Timer)
    {
        let userInfo = timer.userInfo as! (Int, Int);
        
        let bank = userInfo.0;
        let pad = userInfo.1;
        
            /** band aid added on 12/28/2017
                    had something to do with loaded song renaming,
                        and sending data concerning a blank pad,
                            but when we made this call,
                                the bank slots in the _padMixerVolumeDataArray had counts of zero*/
        if(_padMixerArray[bank].count > 0)
        {   _delegate!.passCurrentVolumeToPadView(bank: bank, pad: pad, volume: _padMixerVolumeDataArray[bank][pad]);   }
        
        if(_padMixerVolumeDataArray[bank][pad] == 0){   _danglingTimerCounterArray[bank][pad] += 1; }
        else{   _danglingTimerCounterArray[bank][pad] = 0;  }
        
        if(_danglingTimerCounterArray[bank][pad] == 500)
        {
            _volumeDataTimerArray[bank][pad]?.invalidate();
            _volumeDataTimerArray[bank][pad] = nil;
            
            if(_debugFlag)
            {
                print("updateVolumeData() in MasterSoundMod canceled dangling timer for bank: " + bank.description + ", pad: " + pad.description);
            }
        }
    }
    
    
    /** fade out method ommitted */
    
    
    /** volumes passed into this method are in decibles,
         we convert from decibles to 0 - 1 range here */
    func setVolume(bankNumber: Int, padNumber: Int, volume: Double)
    {
        // set acutal volume
        _padMixerArray[bankNumber][padNumber]?.volume = pow(10, (Float(volume)/20));
        
        //      trying to solve runtime exceptions due to incomming calls during song loading
        if(_padMixerArray[bankNumber][padNumber] != nil)
        {   _soundCollection[bankNumber]![padNumber]?.volume = (_padMixerArray[bankNumber][padNumber]?.volume)! }
            //      trying to solve runtime exceptions due to incomming calls during song loading
        else{   _soundCollection[bankNumber]![padNumber]?.volume = pow(10, (Float(volume)/20)); }
    }
    
    func setStartingPoint(bankNumber: Int, padNumber: Int, startingPoint: Double, load: Bool)
    {
        if(_soundCollection[bankNumber]![padNumber] != nil)
        {   (_soundCollection[bankNumber]![padNumber])!.setStartPoint(startPoint: Float(startingPoint), load: load);   }
    }
    
    func setEndPoint(bankNumber: Int, padNumber: Int, endPoint: Double)
    {
        if(_soundCollection[bankNumber]![padNumber] != nil)
        {   (_soundCollection[bankNumber]![padNumber])!.endPoint = Float(endPoint);  }
    }
    
    /** true indicates start/Stop mode,
            false indicates play through mode */
    func setTriggerMode(bankNumber: Int, padNumber: Int, triggerMode: Bool)
    {
        if(_soundCollection[bankNumber]![padNumber] != nil)
        {   (_soundCollection[bankNumber]![padNumber])!.startStopTriggerMode = triggerMode;  }
    }
    
    func setPitch(bankNumber: Int, padNumber: Int, pitch: Float)
    {
        guard(_soundCollection[bankNumber]![padNumber] != nil) else {    return; }
        
        for i in 0 ..< (_soundCollection[bankNumber]![padNumber]?.playerNodeArrayCount)!
        {
            _soundCollection[bankNumber]![padNumber]?.varispeedNodeArray[i]?.rate = pow(2,  (pitch * 100)/1200);
        }
    }
    
    func startMod()
    {
        if(UIApplication.shared.applicationState == .active)//  this check is an attempt to get rid of the 561015905 exception
        {
            //  https://forums.developer.apple.com/thread/44833
            //      this might help us avoid a ghost bug....
            _engine!.mainMixerNode;
            
            if(!AVAudioSession.sharedInstance().isOtherAudioPlaying)
            {
                do
                {
                    if(!_engine.isRunning){ try _engine.start();    }
                    else
                    {
                        if(_debugFlag){ print("startMod() in MasterSoundMod did not start engine because it was already running");  }
                    }
                }
                catch
                {
                    if(_debugFlag){ print("MasterSoundMod could not start sound engine: " + error.localizedDescription);    }
                }
            }
            else
            {
                if(_debugFlag)
                {
                    print("startMod() in masterSoundMod returned early and failed to start the engine due to another application producing audio");
                }
                return;
            }
            
            _isRunning = true;
        }
        else
        {
            _isRunning = false;
            if(_debugFlag){ print("startMod() in MasterSoundMod did not start sound mode becuase app was not active");   }
        }
    }
    
    func stopMod()
    {
        _engine.stop();
        _isRunning = false;
    }
    
    func handleAduioRouteChange(notification: Notification)
    {
        /** switched to this call on 1/4/2018
                this call sets the timers to nil though.....*/
        invalidateAllVolumeDataTimers();
        
        //  Guard against an ongoing phone call
        if(_interruptIsOnGoing)
        {
            if(_debugFlag){ print("route change ocurred while interruption was taking place."); }
            return;
        }

        // guard against route change while recording is ongoing
        if(_isRecording)
        {
            if(_debugFlag){ print("route change occurred while recording was ongoing;");    }
            _delegate.alertAndStopRecording(bank: _recordingPad.0, pad: _recordingPad.1);
            return;
        }

        let session = AVAudioSession.sharedInstance();
        let currentRoute = session.currentRoute;
    
        for outDescription in currentRoute.outputs
        {
            if outDescription.portType == AVAudioSessionPortLineOut{}
            else if outDescription.portType == AVAudioSessionPortHeadphones{}
            else if outDescription.portType == AVAudioSessionPortBuiltInReceiver{   outPortOverride();  }
            else if outDescription.portType == AVAudioSessionPortBuiltInSpeaker{}
            else if outDescription.portType == AVAudioSessionPortHDMI{}
            else if outDescription.portType == AVAudioSessionPortAirPlay{}
            else if outDescription.portType == AVAudioSessionPortBluetoothLE{}
            else if outDescription.portType == AVAudioSessionPortBluetoothHFP{}
            else if(outDescription.portType == AVAudioSessionPortBluetoothA2DP){}
            
            if(_debugFlag){ print("route change was triggered for type: " + outDescription.portType.description);   }
        }

        _inputFormat = _engine.inputNode.inputFormat(forBus: 0);

        //  after the lines above,
        //      if an audio route has just changed,
        //          _outputFormat should now reflect the number of output channels of the new audio route.
        _outputFormat = _engine.outputNode.outputFormat(forBus: 0);

        DispatchQueue.main.async    /** added on 1/14/2018 */
        {
            if(UIApplication.shared.applicationState == .active)
            {   self.reconnectEngineAfterAudioRouteChange(notification: notification);  }
            else
            {
                if(self._debugFlag)
                {
                    print("^^^^^^^^^^^ handleAduioRouteChange() in masterSoundMod did not reset the sound graph because the app was inactive");
                }
            }
        }
        
        stopAllCurrentPlayerNodes();
    }

    /** prevent audio output to the earpiece */
    func outPortOverride()
    {
        let session = AVAudioSession.sharedInstance();
        
        do
        {
            try session.setActive(false);
            if(_debugFlag){ print("outPortOverride() in MasterSoundMod set audio session to inactive");    }
        }
        catch
        {
            print("outPortOverride() in MasterSoundMod could not deactivate audio session.\n")
            print(error.localizedDescription);
        }
        
        do{ try session.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker);    }
        catch
        {
            print("outPortOverride() in masterSoundMod could not override output route change to Speaker.\n")
            print(error.localizedDescription);
        }
        
        do
        {
            try session.setActive(true);
            if(_debugFlag){ print("outPortOverride() in MasterSoundMod set audio session to active");  }
        }
        catch
        {
            print("outPortOverride() in MasterSoundMod could not reactivate audio session.\n")
            print(error.localizedDescription);
        }
    }
    
    /** an audio route change will most likely result in a change of output channel count.
            in order to handle this we need to disconnect and reconnect all the pad mixers. */
    private func reconnectEngineAfterAudioRouteChange(notification: Notification)
    {
        if(UIApplication.shared.applicationState == .inactive) /***12/9/2017 this might be causing more trouble than it is worth **/
        {
            if(_debugFlag)
            {
                print("reconnectEngineAfterAudioRouteChange() in masterSoundMod returned early because app was inactive.");
            }
            return;
        }
        
        if(_outputFormat.channelCount == 0 && _outputFormat.sampleRate == 0.0)
        {
            if(_debugFlag)
            {
                print(" reconnectEngineAfterAudioRouteChange() in masterSoundMod returned early due to invalid output format.");
            }
            return;
        }
        
        UIApplication.shared.beginIgnoringInteractionEvents();
        if(_debugFlag){ print("reconnectEngineAfterAudioRouteChange() in MasterSoundMod began ignoring interaction events");    }
        
        disconnectPadMixersAfterRouteChange();
        reconnectPadMixersAfterRouteChange();
        
        if(!AVAudioSession.sharedInstance().isOtherAudioPlaying)
        {   startMod(); }
        else
        {
            if(_debugFlag)
            {
                print("reconnectEngineAfterAudioRouteChange() in masterSoundMod falied to start sound mod due to other audio");
            }
        }
        
        UIApplication.shared.endIgnoringInteractionEvents();
        if(_debugFlag){ print("reconnectEngineAfterAudioRouteChange() in MasterSoundMod stopped ignoring interaction events");  }
    }
    
    private func disconnectPadMixersAfterRouteChange()
    {
        for bank in 0 ..< _padMixerArray.count
        {
            for pad in 0 ..< _padMixerArray[bank].count where _padMixerArray[bank][pad] != nil
            {
                _engine.disconnectNodeOutput(_padMixerArray[bank][pad]!);
            }
        }
    }
    
    private func reconnectPadMixersAfterRouteChange()
    {
        for bank in 0 ..< _padMixerArray.count
        {
            for pad in 0 ..< _padMixerArray[bank].count where _padMixerArray[bank][pad] != nil
            {
                if(_outputFormat.channelCount != 0 && _outputFormat.sampleRate != 0.0) /**12/9/2017 this might be causing more trouble than it is worth **/
                {
                    // reconnect pad mixers with updated format after route change.
                        _engine.connect(_padMixerArray[bank][pad]!, to: _engine.mainMixerNode, format: _outputFormat);
                        
                    if(_debugFlag)
                    {
                        print("reconnectPadMixersAfterRouteChange() in MasterSoundMod connected padMixer bank: " + bank.description + " and pad: " + pad.description + " to engine's main mixer node");
                    }
                }
                else
                {
                    if(_debugFlag)
                    {
                        print("reconnectPadMixersAfterRouteChange() in MasterSoundMod failed to reconnect pad mixer for bank: " + bank.description + ", pad: " + pad.description + " due to channel count: " + _outputFormat.channelCount.description + " , sampleRate: " + _outputFormat.sampleRate.description);
                    }
                }
            }
        }
    }
    
    private func createObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(interruptStarted), name: _interruptStartedName, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(interruptEnded), name: _interruptEndedName, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(appFinishedComingBackFromBackground), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil);
        // use this to invalidate any valid timers
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil);
    }
    
    @objc func interruptStarted(){  _interruptIsOnGoing = true; }
    @objc func interruptEnded(){    _interruptIsOnGoing = false;    }
    
    @objc func appFinishedComingBackFromBackground()
    {
        for bank in 0 ..< _nBanks
        {
            for pad in 0 ..< _nPads
            {
                _padConnectionStatusArray[bank][pad] = false;
            }
        }
    }
    
    /** 1/3/2018 invalidate all valid timers whenever the app goes to background
            this method DOES get called when the pff button is pressed.*/
    @objc func appDidEnterBackground()
    {
        invalidateAllVolumeDataTimers();
        invalidateValidFadeOutTimers();
    }
    
    private func invalidateAllVolumeDataTimers()
    {
        for bank in 0 ..< _nBanks
        {
            for pad in 0 ..< _nPads where _volumeDataTimerArray.count > 0
            {
                if(_volumeDataTimerArray[bank].count > 0)
                {
                    if(_volumeDataTimerArray[bank][pad] != nil)
                    {
                        if(_volumeDataTimerArray[bank][pad]?.isValid)!
                        {
                            _volumeDataTimerArray[bank][pad]?.invalidate();
                            _volumeDataTimerArray[bank][pad] = nil;
                        }
                    }
                }
            }
        }
    }
    
    func invalidateValidFadeOutTimers()
    {
        for bank in 0 ..< _nBanks
        {
            for pad in 0 ..< _nPads where _releaseTimerArray.count != 0
            {
                if(_releaseTimerArray[bank].count != 0)
                {
                    if(_releaseTimerArray[bank][pad] != nil)
                    {
                        if(_releaseTimerArray[bank][pad]?.isValid)!
                        {
                            _releaseTimerArray[bank][pad]?.invalidate();
                            if(_debugFlag){ print("fade out timer was invalidated for bank: " + bank.description + " and pad: " + pad.description); }
                        }
                    }
                }
            }
        }
    }
    
    /** see if a pad's connection chain is valid */
    private func checkForPadConnection(bank: Int, pad: Int) -> Bool
    {
        if(_soundCollection[bank]![pad] == nil){    return false;   }
        // don't check for connection if the pad is not loaded
        if(!(_soundCollection[bank]![pad]?.isLoaded)!){ return false;   }
        
        var connectionIsValid = true;
        let currentIndex = _soundCollection[bank]![pad]?.currentPlayIndex;
        
        if(_soundCollection[bank]![pad]?.playerNodeArray[currentIndex!]! == nil)
        {
            if(_debugFlag)
            {
                print("checkForPadConnection() returned false due to nil AVAudioPlayerNode for bank: " + bank.description + ", pad: " + pad.description + ", current index: " + currentIndex!.description);
            }
            return false;
        }
    
        if(_soundCollection[bank]![pad]?.varispeedNodeArray[currentIndex!]! == nil)
        {
            if(_debugFlag)
            {
                print("checkForPadConnection() returned false due to nil VarispeedNode for bank: " + bank.description + ", pad: " + pad.description + ", current index: " + currentIndex!.description);
            }
            return false;
        }
        
        if(_padMixerArray[bank][pad] == nil)
        {
            if(_debugFlag)
            {
                print("checkForPadConnection() found nil padMixer and called connectPadToMixer() for bank: " + bank.description + ", pad: " + pad.description);
            }
            
            connectPadToMixer(bank: bank, pad: pad);
            _padMixerArray[bank][pad]?.volume = (_soundCollection[bank]![pad]?.volume)!;
        }
        
        let playerNodeOutConnectionPoints = _engine.outputConnectionPoints(for: (_soundCollection[bank]![pad]?.playerNodeArray[currentIndex!])!, outputBus: 0);
        let varispeedInConnectionPoint = _engine.inputConnectionPoint(for: (_soundCollection[bank]![pad]?.varispeedNodeArray[currentIndex!])!, inputBus: 0)
        let varispeedOutConnectionPoints = _engine.outputConnectionPoints(for: (_soundCollection[bank]![pad]?.varispeedNodeArray[currentIndex!])!, outputBus: 0);
        let padMixerInConnectionPoint = _engine.inputConnectionPoint(for: _padMixerArray[bank][pad]!, inputBus: 0);
        let padMixerOutConnectionPoints = _engine.outputConnectionPoints(for: _padMixerArray[bank][pad]!, outputBus: 0);
        
        let mainMixerInConnectionPoint = _engine.inputConnectionPoint(for: _engine.mainMixerNode, inputBus: 0);
        let mainMixerOutConnectionPoints = _engine.outputConnectionPoints(for: _engine.mainMixerNode, outputBus: 0);
        
        if(playerNodeOutConnectionPoints.count == 0)
        {
            if(_debugFlag)
            {
                print("checkForPadConnection() in MasterSoundMod found no OUT connection for bank: " + bank.description + " pad: " +  pad.description + " player node");
            }
            connectionIsValid = false;
        }
        
        if(varispeedInConnectionPoint == nil)
        {
            if(_debugFlag)
            {
                print("checkForPadConnection() in MasterSoundMod found no IN connection for bank: " + bank.description + " pad: " +  pad.description + " varispeed node");
            }
            connectionIsValid = false;
        }
        
        if(varispeedOutConnectionPoints.count == 0)
        {
            if(_debugFlag)
            {
                print("checkForPadConnection() in MasterSoundMod found no OUT connection for bank: " + bank.description + " pad: " +  pad.description + " varispeed node");
            }
            
            tryReconnectingVarispeedNodeToPadMixerNode(bank: bank, pad: pad);
            connectionIsValid = false;
        }
        
        if(padMixerInConnectionPoint == nil)
        {
            if(_debugFlag)
            {
                print("checkForPadConnection() in MasterSoundMod found no IN connection for bank: " + bank.description + " pad: " +  pad.description + " pad mixer node");
            }
            
            tryReconnectingVarispeedNodeToPadMixerNode(bank: bank, pad: pad);
            connectionIsValid = false;
        }
        
        if(padMixerOutConnectionPoints.count == 0)
        {
            if(_debugFlag)
            {
                print("checkForPadConnection() in MasterSoundMod found no OUT connection for bank: " + bank.description + " pad: " +  pad.description + " pad mixer node");
            }
            
            tryReconnectingPadMixerNodeToMainMixerNode(bank: bank, pad: pad);
            connectionIsValid = false;
        }
        
        if(mainMixerInConnectionPoint == nil)
        {
            if(_debugFlag)
            {
                print("checkForPadConnection() in MasterSoundMod found no IN connection for bank: " + bank.description + " pad: " +  pad.description + " main mixer node");
            }
            connectionIsValid = false;
        }
        
        if(mainMixerOutConnectionPoints.count == 0)
        {
            if(_debugFlag)
            {
                print("checkForPadConnection() in MasterSoundMod found no OUT connection for bank: " + bank.description + " pad: " +  pad.description + " main mixer node");
            }
            connectionIsValid = false;
        }
        
        if(!connectionIsValid){ _delegate.passPresentBadConnectionChainAlert(); }
        
        _padConnectionStatusArray[bank][pad] = connectionIsValid;
        return connectionIsValid;
    }
    
    private func tryReconnectingVarispeedNodeToPadMixerNode(bank: Int, pad: Int)
    {
        let tempPadSampleRate = _soundCollection[bank]![pad]?.file.fileFormat.sampleRate;
        let tempFileChannelCount = _soundCollection[bank]![pad]?.file.fileFormat.channelCount;
        
        for i in 0 ..< _soundCollection[bank]![pad]!.playerNodeArrayCount
        {
            _engine.connect((_soundCollection[bank]![pad]?.varispeedNodeArray[i])!, to: _padMixerArray[bank][pad]!, format: AVAudioFormat(standardFormatWithSampleRate: tempPadSampleRate!, channels: tempFileChannelCount!));
        }
    }
    
    private func tryReconnectingPadMixerNodeToMainMixerNode(bank: Int, pad: Int)
    {
        if(_outputFormat.channelCount == 0 && _outputFormat.sampleRate == 0.0)
        {
            if(_debugFlag)
            {
                print("tryReconnectingPadMixerNodeToMainMixerNode() in masterSoundMod returned early due to invalid outputFormat for bank: " + bank.description + ", pad: " + pad.description);
            }
            return;
        }

        _engine.connect(_padMixerArray[bank][pad]!, to: _engine.mainMixerNode, format: _outputFormat);
    }
    
    /** returns true if the file to be erased is found in the sound collection */
    func eraseFileFromDisk(file: URL) -> Bool
    {
        if(_soundCollection != nil)
        {
            for bank in 0 ..< _nBanks where _soundCollection[bank]?.count != 0
            {
                for pad in 0 ..< _nPads where _soundCollection[bank]![pad] != nil
                {
                    if(_soundCollection[bank]![pad]?.isLoaded)!
                    {
                        if(_soundCollection[bank]![pad]?.filePath.lastPathComponent == file.lastPathComponent){   return true;    }
                    }
                }
            }
        }
        
        return false;
    }
    
    
    func cancelPlayThrough(bank: Int)
    {
        if(_soundCollection != nil)
        {
            for bank in 0 ..< _nBanks
            {
                if(_soundCollection[bank] != nil && _soundCollection[bank]?.count != 0)
                {
                    for pad in 0 ..< _nPads where _soundCollection[bank]![pad] != nil
                    {
                        _soundCollection[bank]![pad]!.cancelPlayThrough();
                    }
                }
            }
        }
    }
    
    func cancelPreview(bank: Int, pad: Int){    _soundCollection[bank]![pad]?.stop(preview: true);  }
}//----------------------------------------------   END OF MASTER SOUND MOD --------------------------------------------------------------

extension MasterSoundMod: PadModelParentProtocol
{
    /** index is the current play index passed up by the PadModel */
    func playthroughStop(bank: Int, pad: Int, index: Int, preview: Bool)
    {
        _releaseTimerArray[bank][pad] = Timer();    //Duplicate
        
        var preFadeVolume: Float = 0.0; //Duplicate
        
        if(_padMixerArray[bank][pad] != nil)    //Duplicate
        {   preFadeVolume = (_soundCollection[bank]![pad]?.volume)!;    }
        
        // no player node manipulation while audio route change is in progress.
        //      otherwise there is a run time exception.
        if(!_isConnected && !_routeChanging)                                        //Duplicate
        {
            if((_soundCollection[bank]![pad]) != nil && (_soundCollection[bank]![pad])!.isLoaded)       //Duplicate
            {
                if((_releaseTimerArray[bank][pad] == nil))                                          //Duplicate
                {
                    self._releaseTimerArray[bank][pad] = Timer.scheduledTimer(timeInterval: _fadeOutTimerInterval, target: self, selector: #selector(self.playthroughFadeout(timer:)), userInfo: (bank, pad, preFadeVolume, index), repeats: true);  //Duplicate
                }
            }
        }
    }
}
