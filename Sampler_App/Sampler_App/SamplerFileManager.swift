//
//  SamplerFileManager.swift
//  Sampler_App
//
//  Created by Budge on 10/27/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import Foundation

//  2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

class SamplerFileManager
{
    private let _superDebugFlag = false;
    
    internal var _fileManager: FileManager! = nil;
    /** path to the application's Library directory */
    internal var _libDir: [NSString]! = nil;
    /** full Path where the app's data is stored */
    internal var _appDir: NSString! = nil
    var appDir: NSString{   get{    return _appDir; } } 
    
    init()
    {
        _fileManager = FileManager();
        _libDir  = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true) as [NSString]!;
        _appDir = _libDir[0].appending("/Application Support/Sampler") as NSString;
    }
        
    internal func getAppPlist() -> NSMutableDictionary!{ return NSMutableDictionary(contentsOfFile: _appDir.appending("/App.plist"));    }
    
    /** get the number of songs value stored in the app.plist */
    internal func getNumberOfSongs() -> Int
    {
        var ret = -1;
        
        if(_fileManager.fileExists(atPath: _appDir.appending("/App.plist")))
        {
            let outerDict = NSMutableDictionary(contentsOfFile: _appDir.appending("/App.plist"));
            
            if(outerDict != nil)
            {
                if((outerDict?.count)! > 1)
                {
                    let ret = outerDict!["nSongs"];
                    return ret as! Int;
                }
                else{   ret = 0;   }
            }
            else
            {
                if(_superDebugFlag)
                {   print("getNumberOfSongs in InSamplerFileManager could not retreive the outer dictionary from the App.plist");   }
            }
        }
        else
        {
            if(_superDebugFlag){ print("getNumberOfSongs in InSamplerFileManager found no App.plist");   }
        }
        
        return ret;
    }
    
    /** return true if a pad exists,
     false otherwise */
    internal func padPlistExists(songName: String, bank: Int, pad: Int) -> Bool
    {
        let padDictPath = _appDir.appending("/" + songName + "/" + bank.description + "/" + pad.description + ".plist");
        return _fileManager.fileExists(atPath: padDictPath);
    }
    
    /** create a pad's plist with default values */
    func createPadPlist(songName: String, songNumber: Int, bank: Int, pad: Int) -> Bool
    {
        let padDictPath = _appDir.appending("/" + songName + "/" + bank.description + "/" + pad.description + ".plist");
        let configDict = NSMutableDictionary();
        
        configDict.setValue(songName, forKey: "name");
        configDict.setValue(songNumber.description, forKey: "songNumber");
        configDict.setValue(bank.description, forKey: "bankNumber");
        
        if(configDict.write(toFile: padDictPath, atomically: false)){   return true;    }
        else
        {
            if(_superDebugFlag)
            {
                print("createPadPlist in PadSaver failed to write initial Config plist file for name: " + songName + ", songNumber: " + songNumber.description + ", bankNumber: " + bank.description + ", padNumber: " + pad.description);
            }
            return false;
        }
    }
    
    internal func getSongPathsFromAppPlist() -> [String]
    {
        let appDict = getAppPlist();
        var songNames: [String] = [];
        
        for i in 1 ..< appDict!.count
        {
            // pretty sure we need to keep the whole paths here....
            songNames.append(((appDict![i.description]! as AnyObject) as! String));
        }
        
        return songNames
    }
    
    internal func updateSongPlistSongNumbers()
    {
        let appDict = getAppPlist();
        
        // if there is only one song on disk,
        //      there is no reason to update anything.
        guard(appDict!.count > 2) else{   return; }
        
        // for each song in the app.plist
        for i in 1 ..< ((appDict?.count)!)
        {
            let currentName = URL(fileURLWithPath: ((appDict![i.description] as AnyObject) as! String), isDirectory: true).lastPathComponent;
            
            let currentSongDict = getSongPlist(name: currentName);
            
            // update song plist song number key
            currentSongDict.setValue(i.description, forKey: "number");
            
            if(currentSongDict.write(toFile: _appDir.appending("/" + currentName + "/" + currentName + ".plist"), atomically: false))
            {
                if(_superDebugFlag)
                {
                    print("updateSongPlistSongNumbers() in Saver successfully updated song number to: " + i.description + " for song: " + currentName);
                }
            }
            else
            {
                if(_superDebugFlag)
                {
                    print("updateSongPlistSongNumbers() in Saver failed to updated song number to: " + i.description + " for song: " + currentName);
                }
            }
        }
    }
    
    internal func getSongPlist(name: String) -> NSMutableDictionary
    {   return NSMutableDictionary(contentsOfFile: _appDir.appending("/" + name + "/" + name + ".plist"))!; }
}
