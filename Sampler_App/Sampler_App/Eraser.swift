//
//  Eraser.swift
//  Sampler_App
//
//  Created by mike on 3/12/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

/** this class is responsible for erasing directories, songs, audio files, etc on disk/storage */
class Eraser: SamplerFileManager
{
    private let _debugFlag = false;
    
    override init(){    super.init();    }
    
    deinit
    {
        _fileManager = nil;
        _appDir = nil;
        if(_debugFlag){ print("*** Eraser deinitialized");  }
    }
    
    /** sometimes you just need to start fresh */
    func clearAllStorageFiles()
    {
        var contentsOfLibrayDirectory: [String] = [];
        
        // if the App plist exists
        if(!_fileManager.fileExists(atPath: _appDir.appending("/App.plist")))
        {
            if(_debugFlag){ print("clearAllStorageFiles in Eraser has found that the App plist is not preset"); }
        }
        
        do{ contentsOfLibrayDirectory = try _fileManager.contentsOfDirectory(atPath: _appDir as String);   }
        catch{  print("clearAllStorageFiles() in Eraser failed to load the contents of the application's library directory")    }
        
        if(contentsOfLibrayDirectory.count > 0)
        {
            for i in 0..<contentsOfLibrayDirectory.count
            {
                do
                {
                    try _fileManager.removeItem(atPath: _appDir.appending("/" + contentsOfLibrayDirectory[i]))
                    if(_debugFlag)
                    {   print("clearAllStorageFiles in Eraser removed song directory: " + contentsOfLibrayDirectory[i].description);    }
                }
                catch{  print("clearAllStorageFiles()  in Eraser failed to remove file: " + contentsOfLibrayDirectory[i]);   }
            }
        }
        else
        {
            if(_debugFlag){ print("clearAllStorageFiles in Eraser did not find any song directories to erase"); }
        }
    }
    
    func eraseAppDirectory() -> Bool
    {
        // if the app directory exists
        if(_fileManager.fileExists(atPath: _appDir as String, isDirectory: nil))
        {
            do
            {
                try _fileManager.removeItem(atPath: _appDir as String);
                return true;
            }
            catch
            {
                print("eraseAppDirectory() in Eraser failed to erase the app directory")
                return false;
            }
        }
        else
        {
            if(_debugFlag){ print("eraseAppDirectory in Eraser found no application directory to erase");   }
            return true;
        }
    }
    
    /** erase a pad's plist from disk */
    func erasePad(name: String, bank: Int, pad: Int)
    {
        if(_fileManager.fileExists(atPath: appDir.appending("/" + name.description + "/" + bank.description + "/" + pad.description + ".plist")))
        {
            do
            {
                try _fileManager.removeItem(atPath: appDir.appending("/" + name.description + "/" + bank.description + "/" + pad.description + ".plist"));
            }
            catch
            {
                print("erasePad() in Eraser could not erase pad: " + pad.description + " in bank: " + bank.description + " in song: " + name + "\n");
                print(error.localizedDescription);
            }
        }
        else
        {
            if(_debugFlag)
            {
                print("erasePad() in Eraser could not find pad: " + pad.description + " in bank: " + bank.description + " in song: " + name + "\n");
            }
        }
    }
    
    /** erase a song from current and persistent memory */
    func eraseSong(name: String, number: Int)
    {
        assert(number > 0); // songs are not zero indexed in App.plist
        
        if(_fileManager.fileExists(atPath: appDir.appending("/" + name.description)))
        {
            var tempAppPlist: NSMutableDictionary = NSMutableDictionary(contentsOfFile: _appDir.appending("/App.plist"))!;
            
            /**     This block of code is similarily implemented in other places    ***********************************************/
            // get the current number of songs from the app.plist
            let nSongs = tempAppPlist["nSongs"] as! Int;
            
            tempAppPlist = [:];
            
            var songPaths = getSongPathsFromAppPlist();
            
            songPaths.remove(at: number - 1);
            
            // update new number of songs
            tempAppPlist.setValue(nSongs - 1,  forKey: "nSongs");
            
            for i in 0 ..< songPaths.count
            {
                tempAppPlist.setValue(songPaths[i], forKey: (i + 1).description);
            }
            /**************************************************************************************************************/
            
            if(tempAppPlist.write(toFile: _appDir.appending("/App.plist"), atomically: false))
            {
                if(_debugFlag){ print("eraseSong() in Eraser successfully updated app.plist with removal of song: " + name);    }
                printAppPlist();
            }
            
            // now erase the acutal song directory
            do{ try _fileManager.removeItem(atPath: appDir.appending("/" + name.description)); }
            catch
            {
                print("eraseSong() in Eraser was unable to erase song: " + name);
                print(error.localizedDescription);
            }
            
            updateSongPlistSongNumbers();
        }
        else
        {
            if(_debugFlag){ print("eraseSong() in Eraser could not find the song to erase.");   }
        }
    }
    
    /** mostly added as debug tool */
    private func printAppPlist()
    {
        let appDict = getAppPlist()
        let nSongs = appDict!["nSongs"] as! Int;
        
        print("***App.plist contents:");
        
        print("nSongs: "   + (appDict!["nSongs"]! as AnyObject).debugDescription);
        
        if(nSongs > 0)
        {
            for i in 1 ... nSongs
            {
                print("number: " + i.description + ", song: " + (appDict![i.description]! as AnyObject).lastPathComponent.description);
            }
        }
    }
    
    /** erase an audio file off of the phone,
            this is called as a result of pressing the "erase" button in the FileSelectorCell class */
    func eraseFile(file: URL)
    {
        do
        {
            try _fileManager.removeItem(at: file);
            if(_debugFlag){ print("eraseFile() in Eraser sucessfully erased file: " + file.description);    }
        }
        catch
        {
            print("eraseFile() in Eraser could not remove file: " + file.description);
            print(error.localizedDescription);
        }
    }
}
