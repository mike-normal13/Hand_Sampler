//
//  PadSaver.swift
//  Sampler_App
//
//  Created by mike on 3/26/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

/** responsible for saving pads and associated pad settings to disk */
class PadSaver: SamplerFileManager
{
    private let _debugFlag = false;
    
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
    
    private var _padNumber: Int = -1
    var padNumber: Int
    {
        get{    return _padNumber;  }
        set{    _padNumber = newValue;  }
    }
    
    init(songName: String, songNumber: Int, bankNumber: Int, padNumber: Int)
    {
        super.init()
        
        _songName = songName;
        _songNumber = songNumber;
        _bankNumber = bankNumber;
        _padNumber = padNumber;
    }
    
    deinit
    {
        _fileManager = nil;
        _appDir = nil;
        if(_debugFlag){ print("***PadSaver deinitialized"); }
    }
    
    private func getPadDict(songName: String, bank: Int, pad: Int) -> NSMutableDictionary
    {
        if(!padPlistExists(songName: _songName, bank: bank, pad: pad))
        {   var _ = createPadPlist(songName: _songName, songNumber: _songNumber, bank: _bankNumber, pad: pad);  }
        
        let padDictPath = _appDir.appending("/" + songName + "/" + bank.description + "/" + pad.description + ".plist");
        return NSMutableDictionary(contentsOfFile: padDictPath)!;
    }
    
    func savePadFile(songName: String, bank: Int, pad: Int, file: URL)
    {
        let padDict = getPadDict(songName: songName, bank: bank, pad: pad);
        padDict.setValue(file.lastPathComponent, forKey: "filePath");
        var _ = writeConfigDictToFile(songName: songName, bank: bank, pad: pad, dict: padDict, param: "File");
    }
    
    func savePadVolume(songName: String, bank: Int, pad: Int, volume: Double)
    {
        let padDict = getPadDict(songName: songName, bank: bank, pad: pad);
        padDict.setValue(volume.description, forKey: "volume");
        var _ = writeConfigDictToFile(songName: songName, bank: bank, pad: pad, dict: padDict, param: "Volume");
    }
    
    // 1/11/2018 no panning is implemented in the app
    func savePadPan(songName: String, bank: Int, pad: Int, pan: Double)
    {
        let padDict = getPadDict(songName: songName, bank: bank, pad: pad);
        padDict.setValue(pan.description, forKey: "pan");
        var _ = writeConfigDictToFile(songName: songName, bank: bank, pad: pad, dict: padDict, param: "Pan");
    }
    
    func savePadStartingPoint(songName: String, bank: Int, pad: Int, startingPoint: Double)
    {
        let padDict = getPadDict(songName: songName, bank: bank, pad: pad);
        padDict.setValue(startingPoint.description, forKey: "startingPoint");
        var _ = writeConfigDictToFile(songName: songName, bank: bank, pad: pad, dict: padDict, param: "Starting Point");
    }
    
    func savePadEndPoint(songName: String, bank: Int, pad: Int, endPoint: Double)
    {
        let padDict = getPadDict(songName: songName, bank: bank, pad: pad);
        padDict.setValue(endPoint.description, forKey: "endPoint");
        var _ = writeConfigDictToFile(songName: songName, bank: bank, pad: pad, dict: padDict, param: "End Point");
    }
    
    /** pass in true to indicate start/stop mode,
            false to indicate PlayThrough mode. */
    func savePadTriggerMode(songName: String, bank: Int, pad: Int, triggerMode: Bool)
    {
        let padDict = getPadDict(songName: songName, bank: bank, pad: pad);
        padDict.setValue(triggerMode.description, forKey: "triggerMode");
        var _ = writeConfigDictToFile(songName: songName, bank: bank, pad: pad, dict: padDict, param: "Trigger Mode");
    }
    
    func savePadSemitone(songName: String, bank: Int, pad: Int, semitone: Int)
    {
        let padDict = getPadDict(songName: songName, bank: bank, pad: pad);
        padDict.setValue(semitone.description, forKey: "semitone");
        var _ = writeConfigDictToFile(songName: songName, bank: bank, pad: pad, dict: padDict, param: "Semitone");
    }
    
    func savePadCent(songName: String, bank: Int, pad: Int, cent: Float)
    {
        let padDict = getPadDict(songName: songName, bank: bank, pad: pad);
        padDict.setValue(cent.description, forKey: "cent");
        var _ = writeConfigDictToFile(songName: songName, bank: bank, pad: pad, dict: padDict, param: "Cent");
    }
    
    private func writeConfigDictToFile(songName: String, bank: Int, pad: Int, dict: NSMutableDictionary , param: String) -> Bool
    {
        var ret = false;
        let padDictPath = _appDir.appending("/" + songName + "/" + bank.description + "/" + pad.description + ".plist");
        if(dict.write(toFile: padDictPath, atomically: true)){  ret = true;    }
        else
        {
            if(_debugFlag){ print("ConfigSaver could not write " + param + " to plist");    }
        }
        return ret;
    }
}
