//
//  PadModel.swift
//  Sampler_App
//
//  Created by Budge on 10/11/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import Foundation
import AVFoundation

//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

/** represents the model for the Pad concept
 several arrays of these will be owned by the master sound mod */
class PadModel: Sampler
{
    private let _debugFlag = false;
    
    private var _padNumber: Int = -1;
    private var _bankNumber: Int = -1;
    
    /** name of the file loaded into this */
    private var _fileName: String! = "";
    var fileName: String{   get{    return _fileName;   }   }
    
    /** actual audio file*/
    private var _file: AVAudioFile! = AVAudioFile();
    var file: AVAudioFile!
    {
        get{    return _file;   }
        set
        {
            let proposedFile = newValue;
            
            // return if the new file is the same as the one which is currently loaded.
            if(_file == proposedFile){  return; }
            else
            {
                if(newValue == nil)
                {
                    _file = newValue;
                    _fileBuffer = nil;
                }
                else
                {
                    _file = newValue;
                    _fadeSampleCount = ((_file.fileFormat.sampleRate) * _fadeTime) / 1000.0;
            
                    _startingFrame = 0;
                    _endingFrame = _file.length;
            
                    if(_fileBuffer == nil){ initBuffers();   }
            
                    _releaseFadeTime = Double(_fadeReleaseResolution) * (1/(_file.fileFormat.sampleRate));
                    
                    // set file duration
                    _fileDuration = Double(_file.length)/_file.fileFormat.sampleRate;
                }
            }
        }
    }
    
    /** path to loaded audio file */
    var filePath: URL!
    {
        get
        {
            if(_file != nil){   return _file.url.appendingPathComponent("/" + _fileName);   }
            else{   return nil; }
        }
    }
    
    /** length in seconds of the pad's audio file
            this private member is set by the public setter for the _file member*/
    var _fileDuration: Double = -1
    var fileDuration: Double
    {
        get{    return _fileDuration;   }
        set{    _fileDuration = newValue;   }
    }
    
    /** reflects whether a thread is currently inside of the updateBuffers() method */
    private var _updatingBuffers: Bool = false;
    
    //  TODO: to be shared amongst all player nodes in playerNodeArray
    private  var _fileBuffer: AVAudioPCMBuffer! = nil;

    /** number of frames in the file buffer */
    private var _totalFrameCount: AVAudioFramePosition! = nil;
    
    /** starting of position for buffer playback */
    private var _startingFrame: AVAudioFramePosition! = nil;
    
    /** ending position for buffer playback */
    private var _endingFrame: AVAudioFramePosition! = nil;
    
    /** fade time in miliseconds */
    private let _fadeTime = 10.0;
    
    /** based upon the sample rate of the loaded audio file */
    private let _fadeIncrement = -1;
    
    //  TODO: we are assuming that 10ms will consist of 441 samples IF the sample rate is 44100
    /** = (file's sample frequency * _fadeTime) / 1000 ms */
    private var _fadeSampleCount = -1.0;
    
    //  TODO: 441 positions?
    private var _fadeInArray: [Float]! = [];
    private var _fadeOutArray: [Float]! = [];
    
    /** values held in this aray will affect a fade when the user releases a pad before the end of the file or end set point */
    private var _fadeReleaseArray: [Float]! = [];
    private let _fadeReleaseResolution = 32;
    
    /** 32 samples */
    private var _releaseFadeTime = 0.0;
    
    /** responsibile for updating the release fade */
    private lazy var _playTimer: Timer! = Timer();
    
    private var _playtimerInterval: TimeInterval! = 0.0;
    
    /** the frame number where the fade out envelope designated by the end of the file or the set end point begins */
    private var _fadeOutStartPosition: Int = -1;
    
    /** on 1/6/2018 we went down to 2 player nodes per padModel */
    private var _playerNodeArrayCount: Int = 2;
    var playerNodeArrayCount: Int{    get{    return _playerNodeArrayCount; }   }
    
    /** iterating through an array of player nodes per start command has a number of musical adavantages */
    private var _playerNodeArray: [AVAudioPlayerNode?]! = nil;
    var playerNodeArray: [AVAudioPlayerNode?]
    {
        get{    return _playerNodeArray;    }
        set{    _playerNodeArray = newValue; }
    }
    
    private var _varispeedNodeArray: [AVAudioUnitVarispeed?]! = nil;
    var varispeedNodeArray: [AVAudioUnitVarispeed?]
    {
        get{    return _varispeedNodeArray;  }
        set{    _varispeedNodeArray = newValue; }
    }
    
    /** reflects whether this has a sound loaded */
    private var _isLoaded: Bool = false;
    var isLoaded: Bool
    {
        get{    return _isLoaded;   }
        set{    _isLoaded = newValue;   }
    }
    
    /** index of player node to play in array */
    private var _currentPlayIndex: Int = 1;
    var currentPlayIndex: Int{  get{    return _currentPlayIndex;    }   }
    
    /** added on 11/28/2017 to help cope with the decreasing volume problem while in playthrough mode.
            Take Special Note!
                This value does not adhere to a decible scale!
                    This value reflects the value of the PadMixer's volume property.
                        This value must not be adjusted during fade out regardless of trigger mode */
    private var _volume: Float = 1;
    var volume: Float
    {
        get{    return _volume; }
        set{    _volume = newValue; }
    }
    
    /** where the loaded sound starts playing in frame number index.
     Public setter also sets _playFrameCount */
    private var _startPoint: Float! = nil;
    var startPoint: Float!
    {
        get{    return _startPoint;  }
        set
        {
            let proposedStartPoint = Float(newValue) * Float((_file.fileFormat.sampleRate));
            
            if(_startPoint == proposedStartPoint){  return; }
            else
            {
                _startPoint = proposedStartPoint;
                if(_endPoint == nil || _startPoint == nil){ _playFrameCount = AVAudioFrameCount(0); }
                else{   _playFrameCount = AVAudioFrameCount(_endPoint - _startPoint);   }
            
                _startingFrame = AVAudioFramePosition(_startPoint);
            }
        }
    }
    
    /** where the loaded sound stops playing in frame number index.
     Public setter also sets _playFrameCount */
    private var _endPoint: Float! = nil;
    var endPoint: Float!
    {
        get{    return _endPoint;  }
        set
        {
            let proposedEndpoint = Float(newValue) * Float((_file.fileFormat.sampleRate));
            
            // don't call updateBuffers if we dont have to...
            if(proposedEndpoint == _endPoint){  return; }
            else
            {
                _endPoint = proposedEndpoint
                if(_endPoint == nil || _startPoint == nil){ _playFrameCount = AVAudioFrameCount(0); }
                else{   _playFrameCount = AVAudioFrameCount(_endPoint - _startPoint);   }
            
                _endingFrame = AVAudioFramePosition(_endPoint);
            
                self.updateBuffers();
            }
        }
    }
    
    /** the number of frames to play,
     calculated as endPoint - startPoint whenever either the start and end point members are set */
    private var _playFrameCount: AVAudioFrameCount! = AVAudioFrameCount();
    
    /** if this is set to false,
     Play Through trigger mode is selected.
     Start/Stop trigger mode means the sound stops as soon as touch up occurs
     Play Through trigger mode means touch up does not stop the sound from playing,
     instead the sound will stop playing upon a subsequent touch or when it reaches the end of the file or the end point,
     whichever happens first */
    private var _startStopTriggerMode: Bool = true;
    var startStopTriggerMode: Bool
    {
        get{    return _startStopTriggerMode;   }
        set{    _startStopTriggerMode = newValue;   }
    }
    
    /** the rate at which the sound will playback,
      affecting the sound's pitch */
    private var _rate: Float! = nil;
    var rate: Float
    {
        get{    return _rate;   }
        set{    _rate = newValue;   }
    }
    //  TODO: unimplemented
    // TODO: we need to enforce a strict range here
    /** right to left position of the sound in the stereo field */
    private var _pan: Float! = 0;
    var pan: Float
    {
        get{    return _pan;    }
        set{    _pan = newValue;    }
    }
    
    //  TODO: implement this at some point
    /** determines whether the sound will be played in mono or stereo mode */
    private var _stereo: Bool = true;
    var stereo: Bool
    {
        get{    return _stereo; }
        set{    _stereo = newValue; }
    }
    
    /** For some reason the audio route change observer in the Master sound mod gets called many time per route change.
            This bool prevents taps being installed multiple time which seems to be causing a run time error */
    private var _tapInstalled = false
    var tapInstalled: Bool
    {
        get{    return _tapInstalled;   }
        set{    _tapInstalled = newValue;   }
    }
    
    /** reflects whether the buffer was recently updated,
            helps to filter out redundant calls */
    private var _buffersUpdated = false;
    
    /** play signal to send to the host if the song is connected */
    private var _playSignalData: Data! = nil;
    var playSignalData: Data{   get{    return _playSignalData; }   }
    
    /** stop signal to send to the host if the song is connected */
    private var _stopSignalData: Data! = nil;
    var stopSignalData: Data{   get{    return _stopSignalData; }   }
    
    /** we've found that we cannot trust an AVAudioPlayerNode's .isPlaying property,
            using it with previewing was causing us having to press a preview button more than once to preview a sound.
                we fixed this problem by implementing this member. */
    private var _isPlaying: Bool = false;
    var isPlaying: Bool
    {
        get{    return _isPlaying;  }
        set{    _isPlaying = newValue;  }
    }
    
    /** intended to help prevent playthrough pads from getting stopped if they are still being pressed */
    private var _isTouched: Bool = false;
    var isTouched: Bool
    {
        get{    return _isTouched;  }
        set{    _isTouched = newValue;  }
    }
    
    weak var _delegate: PadModelParentProtocol! = nil;
    
    /** the index arg is here so we can signal the fileSelectorCell to set its _isLoading flag back to false */
    init(file: URL, bank: Int, pad: Int, hardwareOutputs: Int)
    {
        super.init()
        
        assert(hardwareOutputs != -1)
        _hardwareOutputs = hardwareOutputs;
        
        // one twentieth of a millisecond.. for now
        _playtimerInterval = 0.001/Double(_fadeReleaseResolution);
        
        do
        {
            // use public setter to set up start and end frame counts and positions
            self.file = try AVAudioFile(forReading: file);
            if(_debugFlag){  print("init() in PadModel initialized AVAudioFile");  }
        }
        catch
        {
            print("PadModel for bankNumber: " + bank.description + " and padNumber: " + pad.description + " could not intialize audio file: " + file.lastPathComponent);
            print(error.localizedDescription);
        }
        
        _bankNumber = bank;
        _padNumber = pad;
        
        _fileName = file.lastPathComponent;
        
        _playerNodeArray = [AVAudioPlayerNode?](repeating: nil, count: _playerNodeArrayCount);
        _varispeedNodeArray = [AVAudioUnitVarispeed?](repeating: nil, count: _playerNodeArrayCount);
        
        setNodeArray(audiofile: _file);
        
        let playSignalString = "play: " + bank.description + " " + pad.description;
        _playSignalData = playSignalString.data(using: .ascii);
        
        let stopSignalString = "stop: " + bank.description + " " + pad.description;
        _stopSignalData = stopSignalString.data(using: .ascii);
    }
    
    deinit
    {
        if(_debugFlag)
        {
            print("*** PadModel deinitialized, bankNumber: " + _bankNumber.description + " , padNumber: " + _padNumber.description + " , file name: " + _fileName);
        }
        
        _file = nil;
        _fileName = nil;
        _fileBuffer = nil;
        
        for i in 0 ..< _playerNodeArrayCount
        {
            _playerNodeArray[i] = nil;
            _varispeedNodeArray[i] = nil;
        }
        
        _totalFrameCount = nil;
        _startingFrame = nil;
        _endingFrame = nil;
        
        _playTimer = nil;
        
        _playSignalData = nil
        _stopSignalData = nil;
        
        _opQueue = nil;
        
        _delegate = nil;
        _playtimerInterval = nil;
    }
    
    /** set the starting point,
         if this call is not a result of a file being loaded or recorded,
                update the buffer(s) */
    func setStartPoint(startPoint: Float!, load: Bool)
    {
        self.startPoint = startPoint;
        if(!load){   updateBuffers(); }
    }
    
    /** init all player and varispeed nodes in their respective arrays */
    func setNodeArray(audiofile: AVAudioFile)
    {
        for i in 0 ..< _playerNodeArrayCount
        {
            if(_playerNodeArray[i] == nil)
            {
                var tempNode: AVAudioPlayerNode! = nil;
                tempNode = AVAudioPlayerNode();
                _playerNodeArray[i] = tempNode;
            }
            
            if(_varispeedNodeArray[i] == nil)
            {
                var tempNode: AVAudioUnitVarispeed! = nil;
                tempNode = AVAudioUnitVarispeed();
                _varispeedNodeArray[i] = tempNode;
            }
        }
        
        _isLoaded = true;
    }
    
    /** play the loaded sound from its start point to its end point */
    func play(preview:  Bool)
    {
        /** add around 12/10/2017
                Demo song band aid */
        if(_fileBuffer == nil){ return; }
        
        //  having both start point == 0 and end point == nil here should mean
        //          that we are trying to preview the sound immediatley after choosing it in the FileSelectorVC
        if(_startPoint == 0 && _endPoint == nil)
        {
            // use the public setter in order to set _playFrameCount
            endPoint = Float(Double((_file.length))/(_file.fileFormat.sampleRate));
        }
        
        if(!_startStopTriggerMode){ incrementCurrentPlayIndex();    }
        
        /** 1/11/2018
                if we move down to 1 player node per PadModel,
                    we get an out of bound exception here */
        _playerNodeArray[_currentPlayIndex]?.scheduleBuffer(_fileBuffer, completionHandler: playCompletionHandler);
        
        _playerNodeArray[_currentPlayIndex]?.play();
        
        _isPlaying = true;
        
        // if current triggerMode is  play through,
        // stop the previous player node in the playerNode array from playing
        if(!_startStopTriggerMode)
        {
            if(_currentPlayIndex == 0)
            {
                // if we need to stop the last node in the player node array because it is currently playing
                if(_playerNodeArray[_playerNodeArray.count - 1]?.isPlaying)!
                {   _delegate.playthroughStop(bank: _bankNumber, pad: _padNumber, index: _currentPlayIndex, preview: preview);  }
            }
            else
            {
                // if we need to stop the previous node in the player node array because it is currently playing
                if(_playerNodeArray[_currentPlayIndex - 1]?.isPlaying)!
                {
                    self._delegate.playthroughStop(bank: self._bankNumber, pad: self._padNumber, index: self._currentPlayIndex, preview: preview);
                }
            }
        }
    }
    
    func playCompletionHandler()
    {
        _isPlaying = false;
        
        // if a play through pad is stopped prematurely or if its sound plays to completion,
        //      we need to invalidate its corresponding volume data timer in the master sound mod.
        if(!_startStopTriggerMode)
        {   self._delegate.passPlaythroughEndedInvalidateVolumeTimer(bank: self._bankNumber, pad: self._padNumber); }
    }
    
    func stop(preview: Bool)
    {
        // only stop if trigger mode is start/stop,
        //  or if the call is a result of a preview.
        if(_startStopTriggerMode){  stopCurrentPlayerNode();    }
        else
        {
            if(preview){    stopCurrentPlayerNode();    }
        }
    }
    
    private func stopCurrentPlayerNode()
    {
        playerNodeArray[_currentPlayIndex]?.stop();
        _isPlaying = false;
        incrementCurrentPlayIndex();
    }
    
    func incrementCurrentPlayIndex()
    {   _currentPlayIndex = _currentPlayIndex == (_playerNodeArrayCount - 1) ? 0 : _currentPlayIndex + 1;   }
    
    //https://github.com/AudioKit/AudioKit/blob/master/AudioKit/Common/Nodes/Playback/Player/AKAudioPlayer.swift
    private func initBuffers()
    {
        _fileBuffer = nil;
        _totalFrameCount = _file.length
        _startingFrame = 0;
        _endingFrame = _totalFrameCount;
    }
    
    //  TODO: the does not get called when the app moves back and forth from the foreground..... which is a good thing.....
    //  https://github.com/AudioKit/AudioKit/blob/master/AudioKit/Common/Nodes/Playback/Player/AKAudioPlayer.swift
    private func updateBuffers()
    {
        let tempStartFrame = _startingFrame;
        let tempEndFrame = _endingFrame;
        
        let fileSize = _file.length;
        
        // if the loaded file has more than 0 samples
        if(_file.length > 0)
        {
            _file.framePosition = Int64(tempStartFrame!);
            _playFrameCount = AVAudioFrameCount(tempEndFrame! - tempStartFrame!);

            _fileBuffer = AVAudioPCMBuffer(pcmFormat: (_file.processingFormat), frameCapacity: AVAudioFrameCount(_playFrameCount));

            if(_playFrameCount > _fileBuffer.frameCapacity){    _playFrameCount = _fileBuffer.frameCapacity;    }
            
            //  this is the expensive portion of this method...
            do  {   try self._file.read(into: self._fileBuffer, frameCount: self._playFrameCount); }
            catch
            {
                print("updateBuffer() could not read data into _fileBuffer: " + error.localizedDescription);
                return;
            }
            
            // reset frame position so we can read file into _referenceBuffer at same point as _fileBuffer
            _file.framePosition = Int64(tempStartFrame!);

            self.applyFadeToBuffer();
        }
        else
        {
            if(_debugFlag){ print("updateBuffer in PadModle could not update with empty file.");    }
        }
    }
    
    /** apply the fade in and out envelopes(based upon the upper quadrants of the unit circle) to the buffer
     this method does not account for a fade out envelope if the user releases a pad before the end of the file or the set endpoint.*/
    private func applyFadeToBuffer()
    {
        var tempFadeBuffer: AVAudioPCMBuffer! = AVAudioPCMBuffer(pcmFormat: (_file.processingFormat), frameCapacity: _fileBuffer.frameCapacity);
        let tempLength: UInt32 = _fileBuffer!.frameLength;
        
        _fadeOutStartPosition = Int(Double(tempLength) - ((_file.processingFormat.sampleRate) * (_fadeTime/1000)));
        
        var scalar: Float = 0.0;
        var fadeOutIndex = 0;
        
        if(_fadeInArray.count == 0) {   initFadeArrays();   }
        
        // i is the index in the buffer
        for i in 0 ..< Int(tempLength)
        {
            // n is the channel
            for n in 0 ..< Int(_fileBuffer.format.channelCount)
            {
                // if we are in the fade in region
                if(i < Int(_fadeSampleCount))
                {
                    scalar = _fadeInArray[i];
                    
                    let sample = _fileBuffer!.floatChannelData![n][i] * scalar
                    tempFadeBuffer?.floatChannelData![n][i] = sample;
                }
                    
                // else if we are not in either fade region
                else if(i >= Int(_fadeSampleCount) && i <= _fadeOutStartPosition)
                {
                    // just copy the buffer straight over
                    tempFadeBuffer?.floatChannelData![n][i] = _fileBuffer.floatChannelData![n][i]
                }
                    // else if we are in the fade out region
                else
                {
                    scalar = _fadeOutArray[fadeOutIndex]
                    
                    if(n == _fileBuffer.format.channelCount - 1)
                    {
                        fadeOutIndex += 1;
                        if(fadeOutIndex >= _fadeOutArray.count){    break;  }
                    }
                    
                    let sample = _fileBuffer!.floatChannelData![n][i] * scalar
                    tempFadeBuffer?.floatChannelData![n][i] = sample;
                }
            }
            
            if(fadeOutIndex >= _fadeOutArray.count){    break;  }
        }
        
        // set the member buffer now to be the faded one
        _fileBuffer = tempFadeBuffer;
        _fileBuffer.frameLength = tempLength;
        
        tempFadeBuffer = nil;
    }
    
    /** makes arrays of values corresponding to 10 ms.
     current implementation has fades modeled after the upper quadrants of the unit circle. */
    private func initFadeArrays()
    {
        var currentFadeInValue = (1/_fadeSampleCount) - 1;
        var currentFadeOutValue = 1/_fadeSampleCount;
        
        let fadeReleaseIncrement = 1.0/Double(_fadeReleaseResolution);
        var currentFadeReleaseValue = fadeReleaseIncrement;
        
        // start and end arrays
        for _ in 0 ..< Int(_fadeSampleCount)
        {
            _fadeInArray.append(Float(sqrt(1 - pow(currentFadeInValue, 2))))
            _fadeOutArray.append(Float(sqrt(1 - pow(currentFadeOutValue, 2))))
            
            currentFadeInValue += 1/_fadeSampleCount;
            currentFadeOutValue += 1/_fadeSampleCount;
        }
        
        //  linear fade
        for i in 0 ..< _fadeReleaseResolution
        {
            _fadeReleaseArray.append(Float(_fadeReleaseResolution - (i + 1))/Float(_fadeReleaseResolution));
        }
    }
    
    /** this call originates in either the BankVC or SequenceVC,
            if a sound in playthrough mode is playing while the BankVC or SequenceVC disappears,
                stop it. */
    func cancelPlayThrough()
    {
        incrementCurrentPlayIndex();
        // this is a convoluted code path,
        //  however we need to apply the fade out any playthrough pads which are cancled by antother pad.
        _delegate.playthroughStop(bank: _bankNumber, pad: _padNumber, index: _currentPlayIndex, preview: false);
        _isPlaying = false;
    }
}
