//
//  Loader.swift
//  Sampler_App
//
//  Created by mike on 3/12/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

/** this class is responsible for loading high level aspects of the song,
 e.g. song name,  etc.
 this class also take care of file managment tasks neccessary to set up the app on the phone upon the app's first launch on the phone.
 An instance of this class is owned by the SongVC. */
class Loader: SamplerFileManager
{
    private let _debugFlag = false;
    
    override init(){    super.init();   }
    
    deinit
    {
        self._appDir = nil;
        self._fileManager = nil;
        self._libDir = nil;
        if(_debugFlag){ print("***Loader deinitialized");   }
    }
    
    /** if the application's Directory needs to be created
     Returns true if the  Application Directory is successfully created, otherwise false */
    func createAppDirectory() -> Bool
    {
        var ret = false;
        
        // if the application's directory is not present, create it
        do
        {
            if(!_fileManager.fileExists(atPath: _appDir as String, isDirectory: nil))
            {
                try _fileManager.createDirectory(atPath: _appDir as String, withIntermediateDirectories: true, attributes: nil);
                
                if(_debugFlag){ print("Application Dir was successfully created");  }
                ret = true;
            }
            else
            {
                if(_debugFlag){ print("createAppDirectory in Loader found that Application Dir was allready present");  }
            }
        }
        catch{  print("Error creating app directory");  }
        
        return ret;
    }
    
    /** returns whether the App plist exists in the Application directory */
    func checkForAppPlist() -> Bool
    {
        // if the App plist exists...
        if(_fileManager.fileExists(atPath: _appDir.appending("/App.plist"), isDirectory: nil)){ return true;    }
        else
        {
            if(_debugFlag){ print("checkForExistingData in Loader found no App plist"); }
            return false;
        }
    }
    
    /** creates the top level application storage file. */
    func createAppPlist() -> Bool
    {
        let appPlistPath = _appDir.appending("/App.plist");
        
        //  if the app's directory is empty,
        //          we need to create the App file.
        if(_fileManager.createFile(atPath: appPlistPath, contents: nil, attributes: nil))
        {
            if(_debugFlag){ print("createAppPlist in Loader created App.plist");    }
            return true;
        }
        else
        {
            if(_debugFlag){ print("createAppPlist in Loader Did not create App.plist"); }
            return false;
        }
    }
    
    /** make initial write to app plist
     set a KVP for the number of songs */
    func initialAppPlistWrite() -> Bool
    {
        let outerDict: NSMutableDictionary = [:];
        
        // set number of songs,
        //  which in this case will always be zero
        outerDict.setValue(0, forKey: "nSongs");
        
        if(outerDict.write(toFile: _appDir.appending("/App.plist"), atomically: false))
        {
            if(_debugFlag){ print("initialAppPlistWrite in Loader succesfully made initial write to App plist");    }
            let tempAppDict: NSMutableDictionary = NSMutableDictionary(contentsOfFile: _appDir.appending("/App.plist"))!;
            assert(tempAppDict.count == 1)
            assert(tempAppDict["nSongs"] as! NSInteger == 0);
            return true;
        }
        else
        {
            if(_debugFlag){ print("did not make intial write to App plist");    }
            return false;
        }
    }
    
    /** song name, song number, date created/renamed. */
    func getSongDictionary(songName: String) -> NSMutableDictionary
    {   return NSMutableDictionary(contentsOfFile: _appDir.appending("/" + songName + "/" + songName + ".plist"))!;   }
    
    //  http://stackoverflow.com/questions/31389689/ios-how-to-get-music-file-from-shared-folder-with-use-swift
    /** get all the wav, mp3, or aiff sound files loaded onto the phone in the shared documents directory */
    func getAllMusicFiles() -> [URL?]
    {        
        var allFiles: [URL] = [];
        var musicFiles: [URL?] = [];
        
        var enumerator: FileManager.DirectoryEnumerator! = nil;
        
        //  https://stackoverflow.com/questions/25285016/iterate-through-files-in-a-folder-and-its-subfolders-using-swifts-filemanager
        do
        {
            let resourceKeys: [URLResourceKey] = [.isDirectoryKey];
            let documentDirectory = try _fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false);
            enumerator = _fileManager.enumerator(at: documentDirectory, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles]);
            
            for case let fileURL as URL in enumerator
            {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys));
                
                if(fileURL.lastPathComponent.uppercased().hasSuffix(".WAV") || fileURL.lastPathComponent.uppercased().hasSuffix(".MP3") || fileURL.lastPathComponent.uppercased().hasSuffix(".AIFF") || fileURL.lastPathComponent.uppercased().hasSuffix(".AIF"))
                {   musicFiles.append(fileURL); }
            }
        }
        catch
        {
            print("getAllMusicFiles() in Loader threw error while trying to files from the app's documents directory");
            print(error.localizedDescription);
        }
        
        
        // number of demo files.
        var nPads = 8;
        
        // nab files from demo library
        for file in 0 ..< nPads
        {
            musicFiles.append(nabDemoFileURL(index: file));
        }

        musicFiles.sort(by: {$0!.lastPathComponent.uppercased() < $1!.lastPathComponent.uppercased()})
        
        return musicFiles;
    }

    /** get all the sound files loaded onto the phone in the shared documents directory */
    func getAllMusicFileNames() -> [String]
    {
        let folder = _fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first;
        
        var allFiles: [URL] = [];
        var musicFileNames: [String] = [];
        
        // number of demo files.
        var nPads = 8;
        
        do
        {
            allFiles = try _fileManager.contentsOfDirectory(at: folder!, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
        }
        catch
        {
            print("getAllWavFiles() could not retreive contents of shared document directory");
            print(error.localizedDescription);
        }
        
        // place any mp3, wav, or aiff files in the return value.
        for url in allFiles
        {
            if(url.lastPathComponent.uppercased().hasSuffix(".WAV") || url.lastPathComponent.uppercased().hasSuffix(".MP3") || url.lastPathComponent.uppercased().hasSuffix(".AIFF") || url.lastPathComponent.uppercased().hasSuffix(".AIF"))
            {   musicFileNames.append(url.lastPathComponent);   }
        }
        
        for name in 0 ..< nPads
        {
            musicFileNames.append(nabDemoFileName(index: name));
        }
        
        return musicFileNames;
    }
    
    /** mostly added for testing purposes
         if song cannot be found returns -1. */
    func getSongNumber(name: String) -> Int
    {
        let appDict = NSMutableDictionary(contentsOfFile: _appDir.appending("/App.plist"))!;
        
        for i in 1 ..< appDict.count
        {
            if(appDict[i.description]! as AnyObject).debugDescription.hasSuffix(name){  return i;   }
        }

        return -1;
    }
    
    /** retreive all song names from the app plist. */
    func getSongNames() -> [String]
    {
        let appDict = getAppPlist();
        var ret: [String] = [];
        
        for i in 1 ..< appDict!.count
        {
            let currentName = URL(fileURLWithPath: (appDict![i.description] as Any) as! String).lastPathComponent
            ret.append(currentName);
        }
        
        return ret;
    }
    
    private func nabDemoFileURL(index: Int) -> URL
    {
        var filePath: URL! // duplicate
        
        //  TODO: this is a super amature way of doing things!
        switch index // duplicate
        {
        case 0: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p04.wav", ofType: nil)!) // duplicate
        case 1: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p05.wav", ofType: nil)!) // duplicate
        case 2: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p07.wav", ofType: nil)!) // duplicate
        case 3: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p13.wav", ofType: nil)!) // duplicate
        case 4: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p18.wav", ofType: nil)!) // duplicate
        case 5: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p29.wav", ofType: nil)!) // duplicate
        case 6: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p40.wav", ofType: nil)!) // duplicate
        case 7: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p32.wav", ofType: nil)!) // duplicate
        default: var t = 0;
        }
        
        return filePath;
    }
    
    private func nabDemoFileName(index: Int) -> String
    {
        var filePath: URL! // duplicate
        
        //  TODO: this is a super amature way of doing things!
        switch index // duplicate
        {
        case 0: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p04.wav", ofType: nil)!) // duplicate
        case 1: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p05.wav", ofType: nil)!) // duplicate
        case 2: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p07.wav", ofType: nil)!) // duplicate
        case 3: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p13.wav", ofType: nil)!) // duplicate
        case 4: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p18.wav", ofType: nil)!) // duplicate
        case 5: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p29.wav", ofType: nil)!) // duplicate
        case 6: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p40.wav", ofType: nil)!) // duplicate
        case 7: filePath = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p32.wav", ofType: nil)!) // duplicate
        default: var t = 0;
        }
        
        return filePath.lastPathComponent;
    }
}
