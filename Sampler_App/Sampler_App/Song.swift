//
//  Song.swift
//  Sampler_App
//
//  Created by mike on 3/12/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit

//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

protocol SyncTransmitterParentProtocol: class
{
    /** makes initial song state sync to the host once a tcp connection to the host has been made */
    func syncCurrentPad();
    func callSendFile(bank: Int, pad: Int, fileName: String);
    func sendVolume();
    func sendPan();
    func sendStartingPoint();
    func sendEndPoint();
    func sendTriggerMode(); // false means Play-through mode, true means start/stop mode
    func getCurrentPatToLoad() -> Int;
    func incrementCurrentPadToLoad()
    func resetCurrentPadToLoad()
    func getCurrentBankToLoad() -> Int;
    func incrementCurrentBankToLoad();
    func resetCurrentBankToLoad();
}

/** the protocol is concerned with a BankVC class*/
protocol BankParentProtocol: class
{
    func switchBank(switchToBank: Int);
    func play(bank: Int, pad: Int, preview: Bool, sequenceTouch: Bool); /** sequence touch arg added on 1/7/2018 */
    func stop(bank: Int, pad: Int, preview: Bool);
    func passSelectedFileToMasterSoundMod(file: URL, bank: Int, pad: Int, section: Int, row: Int);
    //func passSelectedFileToMasterSoundMod(file: URL, bank: Int, pad: Int, index: Int);
    func sendConnectPadToMixer(bank: Int, pad: Int);
    func sendConnectLoadedPadToMixer(bank: Int, pad: Int);
    func sendDetachPad(bank: Int, pad: Int, erase: Bool);
    func sendResetSoundMod();
    func startMasterSoundMod();
    func stopMasterSoundMod();
    func setVolume(bank: Int, pad: Int, volume: Double);
    func setStartingPoint(bank: Int, pad: Int, startingPoint: Double, load: Bool);
    func setEndPoint(bank: Int, pad: Int, endPoint: Double);
    func setTriggerMode(bank: Int, pad: Int, triggerMode: Bool);
    func setPitch(bank: Int, pad: Int, pitch: Float);
    func sendVolume(bank: Int, pad: Int, volume: Double);
    func sendStartingPoint(bank: Int, pad: Int, startingPoint: Double);
    func sendEndPoint(bank: Int, pad: Int, endPoint: Double);
    func sendTriggerMode(bank: Int, pad: Int, triggerMode: Bool);
    func passLoad(load: Bool, bank: Int, pad: Int);
    func switchSequenceBank(bank: Int);
    func sendIsRecording(isRecording: Bool, bank: Int, pad: Int);
    func passInvalidateFadeOutTimers();
    func passEraseFile(file: URL);
    /** this function serves to cancel a playThrough sound if either the BankVC or SequenceVC disappear,
                as of 1/6/2018 this call is no longer a pathway to canceling previewing */
    func cancelPlayThrough(bank: Int);
    func cancelPreview(bank: Int, pad: Int);
}

protocol MasterSoundModParentProtocol: class
{
    /** pass volume data to a padView instance in order to color it based upon the current volume */
    func passCurrentVolumeToPadView(bank: Int, pad: Int, volume: Float);
    /** if an audio route change occurs while we are making a recording,
            we need to alert the user,
                stop the recording,
                    and discard the recording */
    func alertAndStopRecording(bank: Int, pad: Int);
    func routeChangeResetPadColors();
    func passPresentBadConnectionChainAlert();
    //func passFileDurationBackToView(bank: Int, pad: Int, duration: Double);
}

/** this is the model for a Song object,
 songs for the most part, consist of a collection of Banks.
    The SongTVC will keep an array of Song objects*/
class Song: Sampler
{
    private let _debugFlag = false;
    
    /** indicates whether the app is connected to an available host */
    private var _isConnected: Bool = false;
    var isConnected: Bool
        {
        get{return _isConnected;}
        set{_isConnected = newValue;}
    }
    
    /** number of banks for the song,
        This value is set at 3 in the SongTVC, for now.. */
    private var _nBanks: Int = -1;
    var nBanks: Int
    {
        get{return _nBanks;}
        set{_nBanks = newValue;}
    }
    
    /** 3 banks */
    private var _bankViewStackControllerArray: [BankViewStackController?] = [];
    var bankViewStackControllerArray: [BankViewStackController?]
    {
        get{    return _bankViewStackControllerArray;   }
        set{    _bankViewStackControllerArray = newValue;   }
    }
    
    /** assign song numbers to help the SongVC distinguish between child view controllers */
    private var _songNumber: Int = -1;
    var songNumber: Int
    {
        get{    return _songNumber; }
        set
        {
            _songNumber = newValue;
            
            for i in 0 ..< nBanks
            {
                if(_bankViewStackControllerArray[i] != nil){    _bankViewStackControllerArray[i]?.songNumber = _songNumber; }
            }
        }
    }
    
    private var _name: String! = nil;
    var name: String
    {
        get{    return _name;  }
        set
        {
            _name = newValue;
            
            for i in 0 ..< _nBanks where _bankViewStackControllerArray[i] != nil
            {
                //if(_bankViewStackControllerArray[i] != nil)   /** 2/2/2018 */
                //{
                    _bankViewStackControllerArray[i]?.songName = newValue;
                //}
            }
        }
    }
    
    private var _dateCreated: Date! = nil;
    var dateCreated: Date
    {
        get{    return _dateCreated;    }
        set{    _dateCreated = newValue;    }
    }
    
    /** sound engine for this song.
            one per song    */
    private var _masterSoundMod: MasterSoundMod! = nil;
    var masterSoundMod: MasterSoundMod!
    {
        get{    return _masterSoundMod; }
        set{   _masterSoundMod = newValue;  }
    }
    
    /** sends play signals to the host via UDP */
    private var _soundTransmitter: SoundTransmitter! = nil;
    var soundTransmitter: SoundTransmitter
    {
        get{    return _soundTransmitter;   }
        set{    _soundTransmitter = newValue;   }
    }
    
    /** sends state update messages to the host via TCP */
    private var _syncTransmitter: SyncTransmitter! = nil;
    var syncTransmitter: SyncTransmitter!
    {
        get{    return _syncTransmitter;    }
        set{    _syncTransmitter = newValue;    }
    }
    
    weak var _delegate: SongParentProtocol! = nil;
    
    private var _currentBankToLoad: Int = 1;
    var currentBankToLoad: Int { get{    return _currentBankToLoad;   }   }
    
    private var _currentPadToLoad: Int = 0;
    var currentPadToLoad: Int { get{    return _currentPadToLoad;   }   }
    
    /** this intializer is for brand new songs,
     it also initializes the bank array. */
    init(songNumber: Int, hardwareOutputs: Int)
    {
        super.init();
        
        _hardwareOutputs = hardwareOutputs;
        _bankViewStackControllerArray = [BankViewStackController]();
        _songNumber = songNumber;
    }
    
    /** for loaded songs */
    init(name: String, songNumber: Int, hardwareOutputs: Int, nBanks: Int, bankArray: [BankViewStackController])
    {
        super.init();
        
        _hardwareOutputs = hardwareOutputs;
        _name = name;
        _songNumber = songNumber;
        _nBanks = nBanks;
        _bankViewStackControllerArray = bankArray;
        
        for bank in _bankViewStackControllerArray
        {
            bank?._delegate = self;
        }
    }
    
    deinit
    {
        if(_masterSoundMod != nil){ _masterSoundMod.disconnectEngine();  }
        
        _masterSoundMod = nil;
        _syncTransmitter = nil;
        _soundTransmitter = nil;
        
        for bank in 0 ..< _nBanks
        {
            _bankViewStackControllerArray[bank] = nil;
        }
        
        _delegate = nil;
        _opQueue = nil;
        
        _dateCreated = nil;
        
        if(_debugFlag){ print("***Song deinitialized"); }
    }
    
    /** increment the _currentBankToLoad and _currentPadToLoad members appropriately.
            this method should only be called if an unloaded pad is encountered while synching a song,
                if the method detects that the last empty pad has been reached,
                    it signals the host that we are done syncing pads*/
    private func incrementCurrentBankAndPad()
    {
        // if the current empty pad is the last pad in a bank
        if(_currentPadToLoad == 7)
        {
            // if the current empty pad is the last pad in the last bank
            if(_currentBankToLoad == 3)
            {
                //  TODO: don't reset members,
                //          it will probably be better to reset these right when the _syncTransmitter's _syncSocket connects to the host.
                _syncTransmitter.currentlySyncing = false;
                _syncTransmitter.sendSyncEnd();
            }
                // if the current empty pad is the last pad in not the last bank
            else
            {
                _currentPadToLoad = 0;
                _currentBankToLoad += 1;
            }
        }
            // if the current empty pad is not the last pad in a bank.
        else{   _currentPadToLoad += 1; }
    }

    func isRecordingTakingPlace() -> Bool
    {
        var ret = false;

        if(_bankViewStackControllerArray.count != 0)
        {
            for bank in 0 ..< _nBanks where _bankViewStackControllerArray[bank] != nil
            {
                if(_bankViewStackControllerArray[bank]?.isRecordingTakingPlace())!
                {
                    ret = true;
                    break;
                }
            }
        }
        
        return ret;
    }
    
    /** returns true if the file was found in the master sound mod's sound collection */
    func eraseFileFromDisk(file: URL) -> Bool
    {
        if(_masterSoundMod != nil){ return _masterSoundMod.eraseFileFromDisk(file: file);   }
        return false
    }

    //----------------------------------    SyncTransmitterParentProtocol callee methods ----------------------------------------------------
    /** Once we have made a tcp connection to the host,
     sync the entire state of the song one pad at a time
        This method should only be called as a means of making the initial sync to the host.
        This method is eventually called as a result to calls made in the SyncTransmitter's didConnectToHost()
            and didRead with tag() delegate methods,
        This method calls _syncTransmitter's sendFileName(),
            which calls other methods */
    func callDelegateSyncCurrentPad()// -> Bool
    {
        //  we don't lazy init banks
        var padLoader = PadLoader(songName: _name, songNumber: _songNumber, bank: _currentBankToLoad);
        //  get file name loaded into current pad
        let fileName = padLoader.loadFile(padNumber: _currentPadToLoad);
        
        if(fileName == nil)
        {
            if(_syncTransmitter.currentlySyncing)
            {
                incrementCurrentBankAndPad();
                callDelegateSyncCurrentPad();
            }
        }
        // else if the pad is loaded
        else{   _syncTransmitter.sendFileName(bankNumber: _currentBankToLoad, padNumber: _currentPadToLoad, fileName: fileName!);   }
    }
    
    func callDelegateCallSendFile(bank: Int, pad: Int, fileName: String)
    {
        var _ = _syncTransmitter.sendFile(songName: _name, songNumber: _songNumber, bankNumber: bank, padNumber: pad, fileName: fileName);
    }
    
    func callDelegateSendVolume()
    {
        let padLoader = PadLoader(songName: _name, songNumber: _songNumber, bank: _currentBankToLoad);
        let volume = padLoader.loadVolume(pad: _currentPadToLoad);
        
        // send default volume if no volume has been saved to disk
        if(volume == nil){  _syncTransmitter.sendPadVolume(bankNumber: _currentBankToLoad, padNumber: _currentPadToLoad, volume: 1);    }
        else
        {   _syncTransmitter.sendPadVolume(bankNumber: _currentBankToLoad, padNumber: _currentPadToLoad, volume: Double(volume!));  }
    }
    
    func callDelegateSendPan()
    {
        let padLoader = PadLoader(songName: _name, songNumber: _songNumber, bank: _currentBankToLoad);
        let pan = padLoader.loadPan(padNumber: _currentPadToLoad);
        
        // send default pan value if now pan setting has been saved to disk.
        if(pan == nil){ _syncTransmitter.sendPadPan(bankNumber: _currentBankToLoad, padNumber: _currentPadToLoad, pan: 0);  }
        else{   _syncTransmitter.sendPadPan(bankNumber: _currentBankToLoad, padNumber: _currentPadToLoad, pan: Double(pan!));   }
    }
    
    func callDelegateSendStartingPoint()
    {
        let padLoader = PadLoader(songName: _name, songNumber: _songNumber, bank: _currentBankToLoad);
        let startingPoint = padLoader.loadStartingPoint(pad: _currentPadToLoad);
        
        if(startingPoint == nil)
        {   _syncTransmitter.sendPadStartingPoint(bankNumber: _currentBankToLoad, padNumber: _currentPadToLoad, startingPoint: 0);  }
        else
        {
            _syncTransmitter.sendPadStartingPoint(bankNumber: _currentBankToLoad, padNumber: _currentPadToLoad, startingPoint: Double(startingPoint!));
        }
    }
    
    func callDelegateSendEndPoint()
    {
        let padLoader = PadLoader(songName: _name, songNumber: _songNumber, bank: _currentBankToLoad);
        let endPoint = padLoader.loadEndPoint(pad: _currentPadToLoad);
        
        _syncTransmitter.sendPadEndingPoint(bankNumber: _currentBankToLoad, padNumber: _currentPadToLoad, endPoint: Double(endPoint!));
    }
    
    /** false for play-through, 
            true for start/stop */
    func callDelegateSendTriggerMode()
    {
        let padLoader = PadLoader(songName: _name, songNumber: _songNumber, bank: _currentBankToLoad);
        let triggerMode = padLoader.loadTriggerMode(pad: _currentPadToLoad);
        
        // send default if nill
        if(triggerMode == nil)
        {   _syncTransmitter.sendPadTriggerMode(bankNumber: _currentBankToLoad, padNumber: _currentPadToLoad, mode: true);  }
        else
        {   _syncTransmitter.sendPadTriggerMode(bankNumber: _currentBankToLoad, padNumber: _currentPadToLoad, mode: triggerMode!);  }
    }
    
    /** called in the syncTransmitter's didRead() delegate method */
    func callDelegateGetCurrentPadToLoad() -> Int{  return _currentPadToLoad;   }
    /** called in the syncTransmitter's didRead() delegate method */
    func callDelegateIncrementCurrentPadToLoad(){ _currentPadToLoad += 1;   }
    /** called in the syncTransmitter's didRead() delegate method */
    func callDelegateResetCurrentPadToLoad(){ _currentPadToLoad = 0;    }
    /** called in the syncTransmitter's didRead() delegate method */
    func callDelegateGetCurrentBankToLoad() -> Int{ return _currentBankToLoad;  }
    /** called in the syncTransmitter's didRead() delegate method */
    func callDelegateIncrementCurrentBankToLoad(){ _currentBankToLoad += 1; }
    /** called in the syncTransmitter's didRead() delegate method */
    func callDelegateResetCurrentBankToLoad(){ _currentBankToLoad = 0;  }
    //---------------------------------- end of SyncTransmitterParentProtocol callee methods ------------------------------------------
}

extension Song: BankParentProtocol
{
    func switchBank(switchToBank: Int){ _delegate.switchToBank(switchToBank: switchToBank); }
    
    internal func play(bank: Int, pad: Int, preview: Bool, sequenceTouch: Bool)
    {
        if(_debugFlag)
        {
            print("play() in Song was called with bank: " + bank.description + " and pad: " + pad.description + " preview: " + preview.description);
        }
        // play sound from phone if not connected to host
        if(!_isConnected)
        {
            // call as a result of preview button in padConfigVC
            if(preview)
            {
                // stop previewing if the sound is currently being previewed
                if(_masterSoundMod.soundCollection[bank][pad]?.isPlaying)!
                {   _masterSoundMod.stop(bank: bank, pad: pad, preview: preview);   }
                else{   _masterSoundMod.play(bank: bank, pad: pad, preview: preview, sequenceTouch: sequenceTouch); }
            }
                // pad touch -- non-preview
            else{   _masterSoundMod.play(bank: bank, pad: pad, preview: preview, sequenceTouch: sequenceTouch);   }
        }
            // send signal to host if connected
        else
        {
            // only send play signal if the pad to be triggerd is not nil,
            if(_masterSoundMod.soundCollection[bank][pad] != nil)
            {
                _soundTransmitter.sendStartPlaySignal(playSignal: (_masterSoundMod.soundCollection[bank][pad]?.playSignalData)!, stopSignal: (_masterSoundMod.soundCollection[bank][pad]?.stopSignalData)!);
            }
        }
    }
    
    internal func stop(bank: Int, pad: Int, preview: Bool)
    {
        if(_debugFlag)
        {
            print("call delegate stop in Song was called with bankNumber: " + bank.description + " and padnumber: " + pad.description);
        }
            
        if(_masterSoundMod != nil)
        {
            // stop phone from playing sound if not connected to host
            if(!_isConnected){  _masterSoundMod.stop(bank: bank, pad: pad, preview: preview); }
            // send stop signal to host if connected
            else
            {
                // only send stop signal if the pad to be triggerd is not nil,
                if(_masterSoundMod.soundCollection[bank][pad] != nil)
                {   _soundTransmitter.sendStopPlaySignal(stopSignal: (_masterSoundMod.soundCollection[bank][pad]?.stopSignalData)!);    }
            }
        }
    }
    
    /** this call is passed up from the FileSelectorTVC when ever a file is chosen for a pad
     or whenever we load a song */
    internal func passSelectedFileToMasterSoundMod(file: URL, bank: Int, pad: Int, section: Int, row: Int)
    {
        // if this method was not called as a result of a recording being made or file being loaded due to a song being launched.
        if(section != -1 && row != -1)                            
        {
            _opQueue.addOperation{  self.resetFileSelectorCellIsLoading(bank: bank, pad: pad, section: section, row: row);  }
        }
        
        _masterSoundMod.soundCollection[bank][pad] = PadModel(file: file, bank: bank, pad: pad, hardwareOutputs: _hardwareOutputs);
        _masterSoundMod.soundCollection[bank][pad]?._delegate = _masterSoundMod;
        
        /** this call is an attempt to eliminate a call to the AVAudioFile init in the PadLoader's getFileDuration() Method,
                it would be nice to have this in place by the release,
                    but it might cause more problems than it is worth */
        //_bankViewStackControllerArray[bank]?.passFileDurationBackToView(pad: pad, duration: (_masterSoundMod.soundCollection[bank][pad]?.fileDuration)!);
    }
    
    /** this method is not defined in the corresponding protocol
            set the _isLoading flag in the FileSelector cell which corresponds to the loaded sound back to false
                1/9/2018 i'm pretty sure this was part of an attempt to reanimate the Cell's activity indicator,
                    if the app moves to and from the background while a sound is being loaded ..*/
    func resetFileSelectorCellIsLoading(bank: Int, pad: Int, section: Int, row: Int)
    {
        if(_bankViewStackControllerArray[bank] != nil)
        {   _bankViewStackControllerArray[bank]?.resetFileSelectorCellIsLoading(pad: pad, section: section, row: row);  }
    }
    
    func sendConnectPadToMixer(bank: Int, pad: Int){   _masterSoundMod.connectPadToMixer(bank: bank, pad: pad);    }
    
    /** connect a loaded pad in the master sound mod as a result of a Song being launched */
    func sendConnectLoadedPadToMixer(bank: Int, pad: Int){   _masterSoundMod.connectPadToMixer(bank: bank, pad: pad);    }
    
    /** detach a node chain from the master sound mod engine as a result of a sound being switched for a pad.
     Also reset pad model and view settings to default values. */
    func sendDetachPad(bank: Int, pad: Int, erase: Bool){   _masterSoundMod.detachAndResetOrErasePad(bank: bank, pad: pad, erase: erase);   }
    
    /** Any BankVC passes up this call as soon as it appears */
    internal func startMasterSoundMod(){   _masterSoundMod.startMod(); }
    
    func stopMasterSoundMod(){   if(_masterSoundMod.isRunning){  _masterSoundMod.stopMod();  }   }
    
    internal func setVolume(bank: Int, pad: Int, volume: Double)
    {   _masterSoundMod.setVolume(bankNumber: bank, padNumber: pad, volume: volume);    }
    
    internal func setStartingPoint(bank: Int, pad: Int, startingPoint: Double, load: Bool)
    {
        // if we're connected send the signal to the host
        //        if(_isConnected)
        //        {
        //            syncTransmitter.sendPadStartingPoint(bankNumber: bankNumber, padNumber: padNumber, startingPoint: startingPoint);
        //        }
        _masterSoundMod.setStartingPoint(bankNumber: bank, padNumber: pad, startingPoint: startingPoint, load: load);
    }
    
    internal func setEndPoint(bank: Int, pad: Int, endPoint: Double)
    {
        //if(_isConnected){   syncTransmitter.sendPadEndingPoint(bankNumber: bankNumber, padNumber: padNumber, endPoint: endPoint);   }
        _masterSoundMod.setEndPoint(bankNumber: bank, padNumber: pad, endPoint: endPoint);
    }
    
    func setTriggerMode(bank: Int, pad: Int, triggerMode: Bool)
    {
        //if(_isConnected){   syncTransmitter.sendPadTriggerMode(bankNumber: bankNumber, padNumber: padNumber, mode: triggerMode);    }
        _masterSoundMod.setTriggerMode(bankNumber: bank, padNumber: pad, triggerMode: triggerMode);
    }
    
    func setPitch(bank: Int, pad: Int, pitch: Float){   _masterSoundMod.setPitch(bankNumber: bank, padNumber: pad, pitch: pitch);   }
    func sendVolume(bank: Int, pad: Int, volume: Double){   _syncTransmitter.sendPadVolume(bankNumber: bank, padNumber: pad, volume: volume);   }
    func sendStartingPoint(bank: Int, pad: Int, startingPoint: Double)
    {   _syncTransmitter.sendPadStartingPoint(bankNumber: bank, padNumber: pad, startingPoint: startingPoint);  }
    func sendEndPoint(bank: Int, pad: Int, endPoint: Double)
    {   _syncTransmitter.sendPadEndingPoint(bankNumber: bank, padNumber: pad, endPoint: endPoint);  }
    func sendTriggerMode(bank: Int, pad: Int, triggerMode: Bool)
    {   _syncTransmitter.sendPadTriggerMode(bankNumber: bank, padNumber: pad, mode: triggerMode);   }
    func passLoad(load: Bool, bank: Int, pad: Int)
    {   _delegate.passLoad(load: load, songNumber: _songNumber, bankNumber: bank, padNumber: pad);   }
    func switchSequenceBank(bank: Int){   _delegate.switchSequenceBank(bank: bank);   }

    /** alert the masterSoundMod that a recording is ongoing in case there is an audio route change */
    func sendIsRecording(isRecording: Bool, bank: Int, pad: Int)
    {
        _masterSoundMod.isRecording = isRecording;
        _masterSoundMod.recordingPad = (bank, pad);
    }
    
    func passInvalidateFadeOutTimers(){ _masterSoundMod.invalidateValidFadeOutTimers(); }
    func passEraseFile(file: URL) { _delegate.passEraseFile(file: file); }
    
    func cancelPlayThrough(bank: Int)
    {   if(_masterSoundMod != nil){ _masterSoundMod.cancelPlayThrough(bank: bank);   }  }
    
    func cancelPreview(bank: Int, pad: Int){    _masterSoundMod.cancelPreview(bank: bank, pad: pad);    }
}

extension Song: SyncTransmitterParentProtocol
{
    /** helps to make the initial phone state sync to the host once a tcp connection to the host has been made
            This method syncs the state of single pad to the host.
            Returns true if there are more pads to sync,
                false otherwise */
    func syncCurrentPad() /*-> Bool*/ {  /* return */callDelegateSyncCurrentPad(); }
    func callSendFile(bank: Int, pad: Int, fileName: String)
    {   callDelegateCallSendFile(bank: bank, pad: pad, fileName: fileName); }
    func sendVolume(){  callDelegateSendVolume();   }
    func sendPan(){  callDelegateSendPan();  }
    func sendStartingPoint(){  callDelegateSendStartingPoint();    }
    func sendEndPoint(){    callDelegateSendEndPoint(); }
    func sendTriggerMode(){ callDelegateSendTriggerMode();  }
    func getCurrentPatToLoad() -> Int { return callDelegateGetCurrentPadToLoad();   }
    func incrementCurrentPadToLoad() {  callDelegateIncrementCurrentPadToLoad();    }
    func resetCurrentPadToLoad() { callDelegateResetCurrentPadToLoad(); }
    func getCurrentBankToLoad() -> Int { return callDelegateGetCurrentBankToLoad(); }
    func incrementCurrentBankToLoad() { callDelegateIncrementCurrentBankToLoad();   }
    func resetCurrentBankToLoad() { callDelegateResetCurrentBankToLoad();   }
}

extension Song: MasterSoundModParentProtocol
{
    /** set padView's back ground color based upon current volume. */
    func passCurrentVolumeToPadView(bank: Int, pad: Int, volume: Float)
    {   _bankViewStackControllerArray[bank]?._stackPadViewArray[pad].setBackgroundColor(volumeLevel: volume * 0.1); }
    func alertAndStopRecording(bank: Int, pad: Int){   _delegate.alertAndStopRecording(bank: bank, pad: pad);  }
    
    func routeChangeResetPadColors()
    {
        for bank in 0 ..< _nBanks where _bankViewStackControllerArray.count > 0
        {
            if(_bankViewStackControllerArray[bank] != nil)
            {
                if(_bankViewStackControllerArray[bank]?._stackPadViewArray != nil)
                {   _bankViewStackControllerArray[bank]?.resetPadColors();  }
            }
        }
    }

    func passPresentBadConnectionChainAlert(){  _delegate.presentBadConnectionChainAlert(); }
}
