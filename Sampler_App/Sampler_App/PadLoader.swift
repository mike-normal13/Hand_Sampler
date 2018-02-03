//
//  PadLoader.swift
//  Sampler_App
//
//  Created by mike on 3/28/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

//  TODO:   PadLoader -> GetFileDuration
//          this method makes an AVAudioFile,
//              can we avoid doing this.....?
//          12/12/2017  we have a pathway in place extending from the Song to the PadConfigVC,
//              we tried it out but some things will have to change for it to work....
//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

import AVFoundation

/** responsible for loading a Pad's settings,
    an instance of this class will be owned by each of the BankVCs,
        the Song class and the SyncTransmitter class will own local instances.
    We're having this class inherit from the loader class just to cut down on some duplicate coded*/
class PadLoader: Loader
{
    private let _debugFlag = false;
    
    private var _loadFileManager: FileManager! = nil;   
    
    private var _songName: String = "";
    var songName: String
    {
        get{    return _songName;   }
        set{    _songName = newValue;   }
    }
    
    private var _songNumber: Int = -1;
    var songNumber: Int
    {
        get{    return _songNumber; }
        set{    _songNumber = newValue; }
    }
    
    private var _bankNumber: Int = -1;
    var bankNumber: Int
    {
        get{    return _bankNumber; }
        set{    _bankNumber = newValue; }
    }
    
    init(songName: String, songNumber: Int, bank: Int)
    {
        super.init();
        
        _songName = songName;
        _songNumber = songNumber;
        _bankNumber = bank;
        
        _loadFileManager = FileManager();
    }
    
    deinit
    {
        _loadFileManager = nil;
        
        if(_debugFlag)
        {
            print("*** PadLoader deinitialized, name: " + _songName + ", song number: " + _songNumber.description  + " , bank number: " + _bankNumber.description);
        }
    }
    
    /** returns the pad's file name if it has been saved,
        nil otherwise */
    func loadFile(padNumber: Int) -> String?
    {
        let padDict = getPadDict(songName: _songName, bank: _bankNumber, pad: padNumber);
        if(padDict == nil){ return nil; }
        
        let fileName = padDict?["filePath"] as? String; // <- a more appropriate key would be "fileName"
        
        if(fileName == nil){    return nil; }
        
        return fileName;
    }
    
    /** load a file into the first bank of the demo song */
    func loadDemoFile(padNumber: Int) -> NSURL!
    {
        //  TODO:   Amature!
        switch padNumber
        {
        case 0: return NSURL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p04.wav", ofType: nil)!);
        case 1: return NSURL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p05.wav", ofType: nil)!);
        case 2: return NSURL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p07.wav", ofType: nil)!);
        case 3: return NSURL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p13.wav", ofType: nil)!);
        case 4: return NSURL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p18.wav", ofType: nil)!);
        case 5: return NSURL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p29.wav", ofType: nil)!);
        case 6: return NSURL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p40.wav", ofType: nil)!);
        case 7: return NSURL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p32.wav", ofType: nil)!);
        default:    return nil;
        }
    }
    
    /** returns the pad's volume if it has been saved,
     nil otherwise */
    func loadVolume(pad: Int) -> Float?
    {
        let padDict = getPadDict(songName: _songName, bank: _bankNumber, pad: pad);
        if(padDict == nil){ return nil; }
        
        let volume = padDict?["volume"] as? String;
        
        if(volume == nil){  return nil; }
        
        return Float(volume!);
    }
    
    /** returns the pad's pan if it has been saved,
     nil otherwise */
    func loadPan(padNumber: Int) -> Float?
    {
        let padDict = getPadDict(songName: _songName, bank: _bankNumber, pad: padNumber);
        if(padDict == nil){ return nil; }
        
        let pan = padDict?["pan"] as? String;
        
        if(pan == nil){ return nil; }
        
        return Float(pan!);
    }
    
    /** returns the pad's starting point if it has been saved,
     nil otherwise */
    func loadStartingPoint(pad: Int) -> Float?
    {
        let padDict = getPadDict(songName: _songName, bank: _bankNumber, pad: pad);
        if(padDict == nil){ return nil; }
        
        let startingPoint = padDict?["startingPoint"] as? String;
        
        if(startingPoint == nil){   return nil; }
        
        return Float(startingPoint!);
    }
    
    /** returns the pad's ending point if it has been saved,
     nil otherwise */
    func loadEndPoint(pad: Int) -> Float?
    {
        let padDict = getPadDict(songName: _songName, bank: _bankNumber, pad: pad);
        if(padDict == nil){ return nil; }
        
        let endPoint = padDict?["endPoint"] as? String;
        
        if(endPoint == nil){    return nil; }
        
        return Float(endPoint!);
    }
    
    func loadTriggerMode(pad: Int) -> Bool?
    {
        let padDict = getPadDict(songName: _songName, bank: _bankNumber, pad: pad);
        if(padDict == nil){ return nil; }
        
        let triggerMode = padDict?["triggerMode"] as? String;
        
        if(triggerMode == nil){ return nil; }
        
        if(triggerMode == "true"){  return true;    }
        else
        {
            assert(triggerMode == "false");
            return false;
        }
    }
    
    func loadSemitone(pad: Int) -> Int?
    {
        let padDict = getPadDict(songName: _songName, bank: _bankNumber, pad: pad);
        if(padDict == nil){ return nil; }
        
        let semitone = padDict?["semitone"] as? String;
        return (semitone == nil) ? nil : Int(semitone!);
    }
    
    func loadCent(padNumber: Int) -> Float?
    {
        let padDict = getPadDict(songName: _songName, bank: _bankNumber, pad: padNumber);
        if(padDict == nil){ return nil; }
        
        let cent = padDict?["cent"] as? String;
        return (cent == nil) ? nil : Float(cent!);
    }
    
    /** returns the pad's dictionary from disk if it exists,
            nil otherwise */
    private func getPadDict(songName: String, bank: Int, pad: Int) -> NSMutableDictionary?
    {
        if(!padPlistExists(songName: _songName, bank: bank, pad: pad)){ return nil; }
        
        let padDictPath = _appDir.appending("/" + songName + "/" + bank.description + "/" + pad.description + ".plist");
        let padDict = NSMutableDictionary(contentsOfFile: padDictPath)!;
        
        return padDict;
    }
    
    /** gets the length in seconds of a file corrresponding to a passed in file name,
        if file can not be initialized from name or file cannont be found,
            returns -1
                This method is not used to retrieve info about demo song files */
    func getFileDuration(name: String) -> Double
    {
        let musicFileArray = getAllMusicFiles();
        
        for i in 0 ..< musicFileArray.count where name == musicFileArray[i]?.lastPathComponent
        {
            do
            {
                let tempFile = try AVAudioFile(forReading: musicFileArray[i]!);
    
                if(_debugFlag){  print("getFileDuration() in PadLoader initialized AVAudioFile");  }
                    
                return Double(tempFile.length) / tempFile.fileFormat.sampleRate; // frame count!!!!
            }
            catch
            {
                print("getFileDuration() in PadLoader could not make temp AudioFile: " + name);
                print(error.localizedDescription);
                return -1;
            }
        }
        if(_debugFlag){ print("getFileDuration() in PadLoader could not find the file: " + name);   }
        return -1;
    }
    
    // TODO: yet another method that inits an AVAudioFile.....
    /** get length of time in seconds for a demo file used in the demo song */
    func getDemoFileDuration(index: Int) -> Double
    {
        var audioFile = AVAudioFile()
        var filePath: URL!
        
        //  TODO: this is a super amature way of doing things!
        switch index
        {
        case 0: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p04.wav", ofType: nil)!)
        case 1: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p05.wav", ofType: nil)!)
        case 2: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p07.wav", ofType: nil)!)
        case 3: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p13.wav", ofType: nil)!)
        case 4: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p18.wav", ofType: nil)!)
        case 5: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p29.wav", ofType: nil)!)
        case 6: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p40.wav", ofType: nil)!)
        case 7: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p32.wav", ofType: nil)!)
        default: var t = 0;
        }
        
        do
        {
            audioFile = try AVAudioFile(forReading: filePath);
            if(_debugFlag){  print("getDemoFileDuration() in PadLoader initialized AVAudioFile");  }
        }
        catch
        {
            print("getDemoFileDuration() in PadLoader could not open file for pad: " + index.description);
            print(error.localizedDescription);
        }
        
        return Double(audioFile.length)/audioFile.fileFormat.sampleRate;
    }
}
