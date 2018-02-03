//
//  Saver.swift
//  Sampler_App
//
//  Created by mike on 3/12/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

/** 12/15/2017 Primarily responsible for saving base files and directories concerned with the app.
        Also saves files and directories concerned with the Bank level of the app
            instance of this class will be owned by the SongVC */
class Saver: SamplerFileManager
{
    private let _debugFlag = false;
    
    private var _sequenceSaver: SequenceSaver! = nil
    
    override init()
    {
        super.init()
        _sequenceSaver = SequenceSaver();
    }
    
    deinit
    {
        _appDir = nil;
        _libDir = nil;
        _fileManager = nil;
        _sequenceSaver  = nil;
        
        if(_debugFlag){ print("*** Saver deinitialized");   }
    }
    
    /**  save a song entry once the user has chosen to name a NEW song.
             return the index the song was inserted into the App.plist*/
    func saveNewSongEntry(name: String) -> Int
    {
        var tempAppPlist: NSMutableDictionary = getAppPlist();
        let preNumberOfSongs = getNumberOfSongs();
        var insertIndex = -1;
        
        if(tempAppPlist.count != 0)
        {
            // if this is the first song created
            if(preNumberOfSongs == 0)
            {
                // no zero indexing
                // update the number of songs
                tempAppPlist.setValue(preNumberOfSongs + 1, forKey: "nSongs");
                
                //  save the FILE PATH to the new song's directory,
                tempAppPlist.setValue(_appDir.appending("/" + name), forKey: (preNumberOfSongs + 1).description);
                
                insertIndex = preNumberOfSongs + 1;
            }
            // else if this is not the first song created
            else
            {
                //  get path array representation of songs stored in app.plist
                var songPaths = getSongPathsFromAppPlist();
                
                //  find where the new song will fit into the song name array
                insertIndex = songPaths.pathIndexSearch(element: name)! + 1;
                
                songPaths.insert(_appDir.appending("/" +  name), at: insertIndex - 1);
                
                tempAppPlist = [:];
                tempAppPlist.setValue(preNumberOfSongs + 1, forKey: "nSongs");
                
                for i in 0 ..< songPaths.count
                {
                    tempAppPlist.setValue(songPaths[i], forKey: (i + 1).description);
                }
            }
            
            createNewSongDirectory(name: name);
            
            // write updated app plist back to disk.
            if(tempAppPlist.write(toFile: self._appDir.appending("/App.plist"), atomically: false))
            {
                if(_debugFlag){ print("saveNewSongEntry in Saver succesfully update the App plist with a new song entry"); }
            }
            else
            {
                if(_debugFlag){ print("saveNewSongEntry() in Saver could not update App plist");    }
            }
        }
        else
        {
            if(_debugFlag){ print("saveNewSongEntry in Saver appears to have retreived and blank App.plist");   }
        }
        
        // this value will help the SongTVC organize the tableDataArray.
        return insertIndex;
    }
    
    /** called if a user chooses to rename a song entry in the SongVC */
    func renameSongEntry(oldName: String, newName: String) -> Int
    {
        var ret = -1
        var tempAppPlist: NSMutableDictionary = NSMutableDictionary(contentsOfFile: _appDir.appending("/App.plist"))!;
        
        let nSongs = getNumberOfSongs();
        
        if(tempAppPlist.count > 1) //<- don't count the "nSongs" kvp
        {
            var oldSongIndex = 0;
            
            // find the index of the old song
            for i in 1 ..< tempAppPlist.count
            {
                let currentNamePath = tempAppPlist[i.description] as! NSString;
                let currentNamePathComponents = currentNamePath.components(separatedBy: "/");
                
                if(currentNamePathComponents[currentNamePathComponents.count - 1] == oldName){  oldSongIndex = i - 1;   }
            }
            
            //  get path array representation of songs stored in app.plist
            var songPaths = getSongPathsFromAppPlist();                             // duplicate
            
            // remove old song entry from song path array
            songPaths.remove(at: oldSongIndex)
            
            //  find where the new song will fit into the song name array
            ret = songPaths.pathIndexSearch(element: newName)! + 1;                         // duplicate
            
            songPaths.insert(_appDir.appending("/" +  newName), at: ret - 1); // duplicate
            
            tempAppPlist = [:]
            
            tempAppPlist.setValue(nSongs, forKey: "nSongs");
            
            for i in 0 ..< songPaths.count
            {
                tempAppPlist.setValue(songPaths[i], forKey: (i + 1).description);
            }
            
            // write updated app plist back to disk.
            if(tempAppPlist.write(toFile: _appDir.appending("/App.plist"), atomically: false))
            {
                // now rename the song directory
                if(renameSongDirectory(oldName: oldName, newName: newName))
                {
                    //return oldSongIndex;
                    return ret;
                }
                else
                {
                    if(_debugFlag){ print("renameSongEntry() in Saver failed to rename song directory");    }
                }
            }
            else
            {
                if(_debugFlag){ print("renameSongEntry() in Saver could not update App plist"); }
            }
        }
        else
        {
            if(_debugFlag){ print("Error loading App plist from function renameSongEntry in class Saver");  }
        }
        
        return ret;
    }
    
    /** see if song with the given id is present in the App plist file */
    func checkIfSongExists(key: Int) -> Bool
    {
        var ret = false;
        let tempAppPlist: NSMutableDictionary = NSMutableDictionary(contentsOfFile: _appDir.appending("/App.plist"))!;
        
        if(tempAppPlist.count > 1)
        {
            let value = tempAppPlist[key.description];
            
            if(_debugFlag){ print("checkIfSongExists() found value: " + value.debugDescription + " mathching key: " + key.description); }
            ret = true;
        }
        else
        {
            if(_debugFlag){ print("checkIfSongExists() in Saver detected no songs present in App plist");   }
        }
        
        return ret;
    }
    
    /** make a directory in the ...../Sampler directory for a newly named song.
     this method should be called as result of the user pressing the return button when naming a song. */
    func createNewSongDirectory(name: String) -> Bool
    {
        let fullDirectoryPath = _appDir.appending("/" + name);
        
        do
        {
            try _fileManager.createDirectory(atPath: fullDirectoryPath, withIntermediateDirectories: false, attributes: nil);
            return true;
        }
        catch
        {
            print("Could not make new song directory for path: " + name + " in createNewSongDirectory() in Saver class");
            print(error.localizedDescription)
            return false;
        }
    }
    
    /** returns whether the provided name,
             either used to create a new song,
                 or to rename an existing song,
                     already exists in the App plist songs dict. */
    func nameIsTaken(name: String) -> (Bool, Int)
    {
        let tempAppPlist: NSMutableDictionary = NSMutableDictionary(contentsOfFile: _appDir.appending("/App.plist"))! as NSMutableDictionary;
        
        if(tempAppPlist.count > 1) // <- there will always be the "nSongs" kvp at position 0
        {
            for index in tempAppPlist
            {
                // skip the nSongs entry in the dictionary
                if(index.key as! String == "nSongs"){   continue;   }
                
                let indexLasrPathComponent = URL(fileURLWithPath: index.value as! String).lastPathComponent
                
                if((indexLasrPathComponent).uppercased() == name.uppercased()){   return (true, Int(index.key as! String)!);  }
            }
            // iterations revealed no matching name
            return (false, -1);
        }
        //  this case could either mean there are currently no songs stored in persistent memory,
        //          or there was an error,
        //              if there was an error hopefully the assertion will fail.
        else
        {
            if(_debugFlag){ print("nameIsTaken() in Saver could not retreive any song paths from App plist");   }
            
            // get number of songs from the App plist
            let nSongs = tempAppPlist["nSongs"] as! NSInteger
            assert(nSongs == 0);
            return (false, -1);
        }
    }
    
    /** returns true if the operation was successful, false otherwise
     the operation is successful if all items in the old directory are copied to the new directory and the old directory is erased */
    private func renameSongDirectory(oldName: String, newName: String) -> Bool
    {
        guard(oldName != newName)else{  return true;    }
        
        do
        {
            try _fileManager.createDirectory(atPath: _appDir.appending("/" + newName), withIntermediateDirectories: false, attributes: nil);
        }
        catch
        {
            print("renameSongDirectory in Saver could not create new, renamed directory");
            return false;
        }
        
        let newDirectoryPath = _appDir.appending("/" + newName);
        let oldDirectoryPath = _appDir.appending("/" + oldName);
        var oldDirectoryContents: [NSString] = [];
        
        do{ oldDirectoryContents = try _fileManager.contentsOfDirectory(atPath: oldDirectoryPath as String) as [NSString];   }
        catch{  print("renameSongDirectory in Saver could not retreive the contents of directory: " + (oldDirectoryPath as String));    }
        
        // for each of the files in the old directory
        for index in 0..<oldDirectoryContents.count
        {
            do
            {
                try _fileManager.moveItem(atPath: oldDirectoryPath.appending("/" + (oldDirectoryContents[index] as String)), toPath: newDirectoryPath.appending("/" + (oldDirectoryContents[index] as String)));
            }
            catch
            {
                print("renameSongDirectory() could not copy file at: " + oldDirectoryContents[index].description + " to new directory at: " + newDirectoryPath);
                return false;
            }
        }
        do
        {
            try _fileManager.removeItem(atPath: oldDirectoryPath.description);
            return true;
        }
        catch
        {
            print("renameSongDirectory() in Saver could not erase old directory at: " + oldDirectoryPath.description);
            print(error.localizedDescription);
            return false;
        }
    }
    
    /** each song has a plist which stores its name, number, and date created.
            this plist will reside in a directory named after the song in question */
    func createNewSongPlist(name: String, number: Int, date: String) -> Bool
    {
        var ret = false;
        let songPlistFilePath = _appDir.appending("/" + name + "/" + name + ".plist");
        let dict: NSMutableDictionary = NSMutableDictionary();
        
        dict.setValue(name, forKey: "name");
        dict.setValue(number.description, forKey: "number");
        dict.setValue(date, forKey: "date");                   
        
        if(dict.write(toFile: songPlistFilePath, atomically: false))
        {
            if(_debugFlag){ print("createSongPlist in Saver successfully wrote plist for song: " + name);   }
            ret = true;
        }
        else
        {
            if(_debugFlag){ print("createSongPlist failed to write plist for song: " + name);   }
        }
        
        return ret;
    }
    
    /** this method is called after the plist in question has been moved to a renamed directory
     not only does this method rename the plist in question,
     but also updates the song value in the plist.
     THis method is called by handleEntryModelUpdate() in SongVC */
    func renameSongPlist(oldName: String, newName: String, newDate: String, newNumber: Int) -> Bool
    {
        let newPlist: NSMutableDictionary = NSMutableDictionary();
        
        if(oldName == newName){ return true;    }
        
        newPlist.setValue(newName, forKey: "name");
        newPlist.setValue(newNumber.description, forKey: "number");
        newPlist.setValue(newDate, forKey: "date");                     
        
        do
        {
            // erase the old plist
            try _fileManager.removeItem(atPath: _appDir.appending("/" + newName + "/" + oldName + ".plist"));
        }
        catch
        {
            print("renameSongPlist in Saver could not erase the old list with name: " + oldName);
            return false;
        }
        
        // write the new plist to the recently renamed directory
        if(newPlist.write(toFile: _appDir.appending("/" + newName + "/" + newName + ".plist"), atomically: false))
        {
            if(_debugFlag){ print("renameSongPlist in Saver successfully wrote renamed plist from: " + oldName + " to: " + newName);    }
            return true;
        }
        else
        {
            if(_debugFlag){ print("renameSongPlist in Saver falied to write plist from: " + oldName + " to: " + newName);   }
            return false;
        }
    }

    /** create a bank directory inside of a Song's directory.*/
    func createBankDirectory(name: String, number: Int) -> Bool
    {
        let bankPath = _appDir.appending("/" + name + "/" + number.description);
        
        do
        {
            try _fileManager.createDirectory(atPath: bankPath, withIntermediateDirectories: false, attributes: nil);
            return true;
        }
        catch
        {
            print("createBankDirectory in Saver failed to create bank directory for song: " + name + ", and number: " + number.description);
            print(error.localizedDescription);
            return false;
        }
    }
    
    /** write the default plists for each of the four VCs to disk with designated song and movement numbers */
    func createInitialBankPlistFiles(path: String, songNumber: Int, bank: Int) -> Bool
    {   return _sequenceSaver.createSeqRecPlist(path: path, songNumber: songNumber, bank: bank);    }
    
    /** check to see if a song is brand new by seeing if it has any existing bank directories */
    func checkIfSongHasBankDirectories(name: String) -> Bool
    {
        let bank1 = _fileManager.fileExists(atPath: _appDir.appending("/" + name + "/" + "1"), isDirectory: nil);
        let bank2 = _fileManager.fileExists(atPath: _appDir.appending("/" + name + "/" + "2"), isDirectory: nil);
        let bank3 = _fileManager.fileExists(atPath: _appDir.appending("/" + name + "/" + "3"), isDirectory: nil);
        
        return (bank1 && bank2 && bank3);
    }
    
    //  TODO: this method needs to be abstracted
    /** mostly added for testing purposes
     if song cannot be found returns -1. */
    func getSongNumber(name: String) -> Int
    {
        let appDict =  getAppPlist();
        
        for i in 1 ..< appDict!.count where (appDict![i.description]! as AnyObject).debugDescription.hasSuffix(name)
        {
            return i;
        }
        
        return -1;
    }
}

/** search for a new song's point of insertion in the App.plist */
extension Array where Element: Comparable
{
    // elements must be URLs
    func pathIndexSearch(element: Element) -> Int?
    {
        let elementString = element as! String;
        
        for i in 0 ... self.count
        {
            if(i == self.count){    return i;   }
            if(elementString.uppercased() > URL(fileURLWithPath: self[i] as! String).lastPathComponent.uppercased())
            {   continue;   }
            else if(elementString.uppercased() <= URL(fileURLWithPath: self[i] as! String).lastPathComponent.uppercased())
            {   return i;   }
        }
        return -1;
    }
}
