//
//  FileSelectorTableViewController.swift
//  Sampler_App
//
//  Created by mike on 3/16/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

// This file represents the TVC which enables users to preview and choose a sound for a selected pad,
//  this file also represents the cells that will populate each row in the TVC.

import UIKit
import AVFoundation

//  TODO: sweep up this class,
//          update comments
//  TODO:   1/11/2018
//              pretty sure teh _demoIndex member is no longer needed
//  TODO:   1/11/2018
//              remove any code in the cellForRowAt indexPath() method that distingushes between demo and non demo files.
//  TODO: 1/11/2018
//          if you press the home button whil previewing,
//              once you come back to the app you can't get any of the cell's to preview again until after you scroll the table view a bit...
//                  you do have to be previewing while you press the home button for the bug to manifest
//  TODO: how many audio files are initialized every time we load a sound from the FileSelectorVC?
//          what about recording?
//              For loading a file:
//                  init() in PadModel makes an AudioFile which is expected.
//                  passSelectedSound() in FileSelectorTVC makes a file
//                  callDelegatePassSelectedFile in PadConfigVC makes a file
//              For Recording a File:
//                  init() in PadModel makes an AudioFile which is expected.
//                  callDelegatePassSelectedFile in PadConfigVC makes a file
//                  submitName in RecordVC
//          we should abstract it somewhow.
//  TODO:   FileSelectorTVC -> PassSelectedSound
//              this method makes an AVAudioFile,
//                  can we avoid doing this......?
//                      30 mins!!!!!
//  TODO: 1/12/2018
//          look into if and where _nPreviews is still begin utilized,
//              and whether or not we can get rid of it.
//  16: FileSelectorVC
//          1/11/2018
//          is there a way to make the side index menu font size bigger...?
//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

protocol FileSelectorCellParentProtocol: class
{
    func startPreview(section: Int, row: Int);
    func stopPreview();
    func selectSound(section: Int, row: Int);
    func eraseFile(section: Int, row: Int);
}

/** Gives users the ability to choose a sound for a selected Pad 
        One instance of this class is owned by the PadConfigVC
            User can also erase files off of the phone here as well*/
class FileSelectorTableViewController: UITableViewController
{
    let _debugFlag = false;
    
    private var _padNumber: Int = -1;
    var padNumber: Int
    {
        get{    return _padNumber;  }
        set{    _padNumber = newValue;  }
    }
    
    internal var _isVisible = false
    var isVisible: Bool
    {
        get{    return _isVisible;  }
        set{    _isVisible = newValue;  }
    }
    
    /** added on 1/9/2018 */
    private var _player: AVAudioPlayer! = nil; 
    
    /** full paths to all music files in the shared Documents directory */
    private var _musicFileArray: [URL?] = [];
    
    private var _demoFileArray: [URL?] = [];
    
    /** indicates which position in the musicFile/Name arrays the demo files begin to be appeneded,
     this way we can determine which cells in the FileSelectorTVC to hide and disable the Erase button in */
    private var _demoIndex = -1;
    
    /** names of all the music files in the shared Documents directory
            for display purposes    */
    private var _musicFileNameArray: [String]! = nil;
    
    private var _indexList: [String]! = nil;
    
    /** (FileName, FilePath) */
    private var _indexDictionary: [String : [(String, URL)]] = [:]
    
    private var _musicFileLoader: Loader! = nil;
    private lazy var _musicFileEraser: Eraser! = Eraser();
    
    /** the sound index selected by the user */
    private var _chosenSound: URL! = nil;
    var chosenSound: URL!
    {
        get{    return _chosenSound;    }
        set{    _chosenSound = newValue;    }
    }
    
    private var _chosenSoundSection: Int = -1;
    var chosenSoundSection: Int{    get{    return _chosenSoundSection} }
    
    private var _chosenSoundRow: Int = -1;
    var chosenSoundRow: Int{    get{    return _chosenSoundRow; }   }
    
    /** name of file chosen by user */
    private var _chosenSoundName: String! = nil;
    var chosenSoundName: String!
    {
        get{    return _chosenSoundName; }
        set{    _chosenSoundName = nil; }
    }
    
    /** reflects whether the pad corresponding to this VC is part of a recorded sequence. */
    private var _isPartOfSequence = false;
    var isPartOfSequence: Bool
    {
        get{    return _isPartOfSequence;   }
        set{    _isPartOfSequence = newValue;   }
    }
    
    private var _isPreviewing: Bool = false
    var isPreviewing: Bool
    {
        get{    return _isPreviewing;   }
        set{    _isPreviewing = newValue;   }
    }
    
    /** number of cells currently previewing */
    private var _nPreviews: Int = 0
    var nPreviews: Int
    {
        get{    return _nPreviews;  }
        set{    _nPreviews = newValue;  }
    }
    
    /** reflects whether the owning padConfigVC has a sound loaded,
     if it does we warn the user of a potential overwrite. */
    private var _isLoaded: Bool = false;    // Duplicate
    var isLoaded: Bool                      // Duplicate
    {
        get{    return _isLoaded;   }       // Duplicate
        set{    _isLoaded = newValue;   }   // Duplicate
    }

    weak var _delegate: FileSelectorTVCParentProtocol! = nil;
    
    override func loadView()
    {
        super.loadView()
        view.backgroundColor = .gray;
        
        navigationItem.setRightBarButton(UIBarButtonItem(title: "?", style: .plain, target: self, action: #selector(handleNavBarInfoButton)), animated: false);
        
        tableView.sectionIndexColor = .yellow;
        
        createObservers();
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
        
        // Uncomment the following line to preserve selection between presentations
        //self.clearsSelectionOnViewWillAppear = false;

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        tableView.rowHeight = 90;
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        UIApplication.shared.isIdleTimerDisabled = false;
        _isVisible = true;
        _musicFileLoader = Loader();
        
        _musicFileArray = _musicFileLoader.getAllMusicFiles();
        
        //  .getAllMusicFiles() sets its _demoIndex member...
        //_demoIndex = _musicFileLoader.getDemoIndex();         // <-- 1/10/2018 not sure if this is still a valid approach
        
        getFileNamesForDisplay();
        populateIndexDictionary();
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        // if the owning padConfigVC was previewing, stop the preview
        _delegate.selectorCancelPreview();
        
        navigationController?.isNavigationBarHidden = false;
        navigationController?.navigationBar.topItem?.title = "Choose Pad " + (_padNumber + 1).description + "'s Sound";
        
        if(_isLoaded){  warnOverwrite();    }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        _isVisible = false;
        if(UIApplication.shared.isIgnoringInteractionEvents)
        {
            UIApplication.shared.endIgnoringInteractionEvents();
            if(_debugFlag){ print("viewWillDisappear() in FileSelectorVC stopped ignoring Application interaction events"); }
        }
        
        cancelAnyPreview();
    }
    
    deinit
    {
        self._chosenSound = nil;
        self._delegate = nil;
        self._musicFileLoader = nil;
        
        for file in 0 ..< _musicFileArray.count
        {
            _musicFileArray[file] = nil;
        }
        
        for file in 0 ..< _demoFileArray.count
        {
            _demoFileArray[file] = nil;
        }
        
        for name in 0 ..< _musicFileNameArray.count
        {
            _musicFileNameArray[name] = "";
        }
        
        _musicFileArray = [];
        _demoFileArray = [];
        _musicFileNameArray = [];
        _musicFileNameArray = nil;
        
        _musicFileEraser = nil;
        
        _chosenSoundName = "";
        _chosenSoundName = nil;
        
        _player = nil;
        
        _indexList = [];
        _indexDictionary = [:];
        
        NotificationCenter.default.removeObserver(self);
        
        if(_debugFlag){ print("*** FileSelectorVC deinitialized");  }
    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
    
    @objc func handleNavBarInfoButton()
    {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil);
        let infoScreen = storyBoard.instantiateViewController(withIdentifier: "FileSelectorInfoVC") as! FileSelectorInfoScreenViewController;
        navigationController?.pushViewController(infoScreen, animated: true);
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        cancelAnyPreview();
        let otherCellEndedPreviewName = Notification.Name(rawValue: fileCellEndedPreviewKey);
        NotificationCenter.default.post(name: otherCellEndedPreviewName, object: nil);
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {   return _indexList.count;    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sectionLetter = _indexList[section]
        if let sectionValues = _indexDictionary[sectionLetter]{ return sectionValues.count  }
        else{   return 0;   }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell: FileSelectorCell = tableView.dequeueReusableCell(withIdentifier: "FileSelector") as! FileSelectorCell;
        
        cell._delegate = self;
        
        /** Band aid */
        if(_musicFileNameArray.count == 0){ return cell;    }
        
        let key = _indexList[indexPath.section]
    
        let sectionValues = _indexDictionary[key];
            
        cell._fileNameLable.text = sectionValues?[indexPath.row].0
        
        cell._loadActivityIndicator.hidesWhenStopped = true;
        
        cell.section = indexPath.section;
        cell.row = indexPath.row;

        let fileSize = getFileSize(file: (sectionValues?[indexPath.row].1)!)
        let fileSizeString = formatFileSize(size: fileSize);
        
        cell._fileSizeValueLabel.text = fileSizeString;
        
        let fileDuration = getFileDuration(file: (sectionValues?[indexPath.row].1)!);
        
        cell._fileDurationValueLabel.text = fileDuration;
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {   return _indexList[section]; }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]?{  return _indexList   }
    
    private func createObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillMoveToBackground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil);
    }
    
    @objc func handleAppWillMoveToBackground(){ cancelAnyPreview(); }
    
    private func formatFileSize(size: UInt64) -> String
    {
        var ret = ""
        var tempSize = size;
        
        if(size < 1000000)
        {
            tempSize = tempSize/1000;
            ret = tempSize.description + " KB";
        }
        else
        {
            tempSize = tempSize/1000000;
            ret = tempSize.description + " MB";
        }
        
        return ret;
    }
    
//    // Override to support conditional editing of the table view.
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        // Return false if you do not want the specified item to be editable.
//        return true
//    }

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {}
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    /** parse file names from all the URLs in the _musicFileArray */
    private func getFileNamesForDisplay()
    {
        if(_musicFileNameArray == nil){ _musicFileNameArray = [String]();   }
        
        _musicFileNameArray = _musicFileArray.map(){ $0?.lastPathComponent } as! [String]
    }
    
    //  https://www.youtube.com/watch?v=xYSKHna1KJk
    private func populateIndexDictionary()
    {
        _indexDictionary = [:];
        
        for name in  0 ..< _musicFileNameArray.count
        {
            let key = _musicFileNameArray[name].first
            
            if var nameValues = _indexDictionary[(key?.description.uppercased())!]
            {
                nameValues.append((_musicFileNameArray[name], _musicFileArray[name]!))
                _indexDictionary[(key?.description.uppercased())!] = nameValues;
            }
            else{   _indexDictionary[(key?.description.uppercased())!] = [(_musicFileNameArray[name], _musicFileArray[name]!)]; }
            
            _indexList = [String](_indexDictionary.keys);
            _indexList = _indexList.sorted();
        }
    }
    
    //  TODO: this method is virtually identical to the same method in the RecordVC,
    //          we should abstract it somewhow.
    /** returns true for user choosing to alter the sequence,
     false otherwise. */
    private func alterSequenceAlert(section: Int, row: Int)
    {
        let alterSequenceAlert = UIAlertController(title: "Change Sequence?", message: "Choosing This File Will Alter The Current Play Sequence. Proceed?", preferredStyle: .alert);
       
        let loadAction = UIAlertAction(title: "Load", style: .destructive, handler:
        {
            (action: UIAlertAction) in  self.passSelectedSound(section: section, row: row);
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:
        {   (action: UIAlertAction)
            in
            self.handleLoadCancel(section: section, row: row);
        })
        
        alterSequenceAlert.addAction(loadAction);
        alterSequenceAlert.addAction(cancelAction);
        
        navigationController?.present(alterSequenceAlert, animated: true, completion: nil);
    }
    
    /** this call should originate from the FileCell,
            in order to make the activity indicator present immediately in the FileCell,
                this method is called on a seperate thread  */
    private func passSelectedSound(section: Int, row: Int)
    {
        // no pressing the choose button twice,
        //  no swiping right to get back to the padConfigVC.
        UIApplication.shared.beginIgnoringInteractionEvents();
        if(_debugFlag){ print("passSelectedSound in FileSelectorVC began ignoring Application interaction events"); }
        
        let indexSounds = _indexDictionary[_indexList[section]];
        
        _chosenSound = indexSounds![row].1
        
        var tempAudioFile: AVAudioFile! = nil;
        
        do
        {
            // make a temp audio file so we can derive its duration
            tempAudioFile = try AVAudioFile(forReading: _chosenSound);
            if(_debugFlag){  print("passSelectedSound() in FileSelectorTVC initialized AVAudioFile");  }
        }
        catch
        {
            print("selectSound() in FileSelectorTVC failed to make an audio file out of the selected sound.");
            print(error.localizedDescription);
        }
        
        _chosenSoundSection = section;
        _chosenSoundRow = row;
        
        let sectionSounds = _indexDictionary[_indexList[section]];
        
        _chosenSoundName = sectionSounds![row].0;
        
        _delegate.passSelectedFile(file: _chosenSound,  pad: _padNumber, section: section, row: row);
        
        // if the pad has a sound in it,
        //  we have to detach it from the master sound mod.
        _delegate.sendSelectDetachPad(padNumber: _padNumber, erase: false);
        
        _delegate.sendConnectSelectedPadToMixer(pad: _padNumber);
        _delegate.setChosenSoundIsLoaded(isLoaded: true);
        
        DispatchQueue.main.async
        {
            // update view
            self._delegate.setChosenSoundEndPointToFileDuration(duration: Float(Double(tempAudioFile.length) / tempAudioFile.fileFormat.sampleRate));
        }
        
        // update model
        _delegate.sendInitialStartingPointToPadModel(pad: _padNumber);
        _delegate.sendInitialEndPointToPadModel(pad: _padNumber, endpoint: Double(tempAudioFile.length) / tempAudioFile.fileFormat.sampleRate)
        
        DispatchQueue.main.async{   self.navigationController?.popViewController(animated: true);   }
    }
    
    /** if the user cancels choosing the sound upon being warned of altering a play sequence */
    private func handleLoadCancel(section: Int, row: Int)
    {
        let name = Notification.Name(rawValue: fileSelectorCellLoadWasCancelledKey);
        NotificationCenter.default.post(name: name, object: nil);
    }
    
    /** navigate back to the PadConfigVC */
    @objc func handleSwipe(){   _delegate.dismissFileSelectorVC();   }
    
    /** erase a file from disk and update the table data */
    internal func eraseFileFromDisk(section: Int, row: Int)
    //internal func eraseFileFromDisk(index: Int)
    {
        // dissalow erasing any of the demo files
        if(checkForDemoFile(section: section, row: row)){   return; }
        
        let sectionValues = _indexDictionary[_indexList[section]];
        
        //  we can't erase a file from disk if any loaded song is using it,
        //      have the SongTVC verify that the file is safe to erase.
        _delegate.passEraseFile(file: sectionValues![row].1);
        
        _musicFileArray = _musicFileLoader.getAllMusicFiles();  // <- I think this is stil the right approach
        
        //  TODO: this methods might need to be updated in light of the new index dictionary
        getFileNamesForDisplay();
        
        populateIndexDictionary();
        
        tableView.reloadData();
    }
    
    /** see if the file in question is located in the demo file library,
            return true if it is */
    private func checkForDemoFile(section: Int, row: Int) -> Bool
    {
        let sectionValues = _indexDictionary[_indexList[section]];
        let file = sectionValues![row].1
        
        if(file.pathComponents.contains("Bundle"))  // 1/11/2018 is there a way to get pass this..... Is this check sufficient...?
        {
            alertUserOfDemoFileErase();
            return true
        }
        
        return false;
    }
    
    private func alertUserOfDemoFileErase()
    {
        let demoFileEraseAlertVC = UIAlertController(title: "Demo File", message: "Files Included In The Demo Song May Not Be Erased.", preferredStyle: .alert);
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil);
        demoFileEraseAlertVC.addAction(okAction);
        navigationController?.present(demoFileEraseAlertVC, animated: true, completion: nil);
    }
    
    private func getFileSize(file: URL) -> UInt64
    {
        let fileString = file.path;
        
        var fileSize: UInt64 = 0;
        
        //  https://stackoverflow.com/questions/28268145/get-file-size-in-swift
        do
        {
            //return [FileAttributeKey : Any]
            let attr = try FileManager.default.attributesOfItem(atPath: file.path);
            fileSize = attr[FileAttributeKey.size] as! UInt64
            
            //if you convert to NSDictionary, you can get file size old way as well.
            let dict = attr as NSDictionary
            
            fileSize = dict.fileSize()
        }
        catch
        {
            print("getFileSize() in FileSelectorVC failed.")
            print(error.localizedDescription);
        }
        
        return fileSize;
    }
    
    /** returns minutes:seconds */
    private func getFileDuration(file: URL) -> String
    {
        var minutes = 0;
        var seconds = 0;
        
        let audioFile: AVAudioFile!
        
        //  TODO:   we should only create one AVAudioFile per sound load.....
        do
        {
            audioFile = try AVAudioFile(forReading: file);
            if(_debugFlag){  print("getFileDuration() in FileSelectorTVC initialized AVAudioFile");  }
        }
        catch
        {
            print("getAudioFile() in FileSelectorVC could not initilize file for: " + file.lastPathComponent);
            print(error.localizedDescription);
            return "N/A";
        }
        
        let frameCount = audioFile.length;
        let sampleRate = audioFile.processingFormat.sampleRate;
        
        var duration = Double(frameCount)/sampleRate;
        
        while duration >= 60
        {
            duration = duration - 60
            minutes += 1;
        }
        
        seconds = Int(duration);
        
        var minuteString = ""
        var secondString = "";
        
        if(minutes == 0){   minuteString = "00";    }
        else{   minuteString = minutes.description; }
        
        if(seconds < 10){   secondString = "0" + seconds.description    }
        else{   secondString = seconds.description; }
        
        return minuteString + ":" + secondString;
    }
    
    private func cancelAnyPreview()
    {
        if(_player != nil && _player.isPlaying)
        {
            _player.stop();
            _player = nil;
        }
    }
    
    //  TODO: this method was copied and pasted from the RecordVC...
    /** alert user of potential overwrite if recording is made */       // duplicate
    private func warnOverwrite()    // duplicate
    {
        let overwriteAlert = UIAlertController(title: "Potential Overwrite", message: "Loading A File Will Overwrite The Sound Currently Loaded Into This Pad. Proceed?", preferredStyle: .alert);       
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:  // duplicate
        {
            (action: UIAlertAction) in                                      // duplicate
            self.navigationController?.popViewController(animated: true);   // duplicate
        })
        
        let okAction = UIAlertAction(title: "OK", style: .destructive, handler:         // duplicate
        {
            (action: UIAlertAction) in                                              // duplicate
            return;                                                                 // duplicate
        })
        
        overwriteAlert.addAction(cancelAction);                                         // duplicate
        overwriteAlert.addAction(okAction);                                             // duplicate
        
        navigationController?.present(overwriteAlert, animated: true, completion: nil);         // duplicate
    }
    
}//------------------------------------- END OF FileSelectorTVC -----------------------------------------------------------

extension FileSelectorTableViewController: FileSelectorCellParentProtocol
{
    /** play the sound corresponding to the pressed button.
            index corresponds to the section in the table view */
    func startPreview(section: Int, row: Int)
    {
        // only one preview at a time as of 1/9/2018
        if(_player != nil && (_player?.isPlaying)!){  return; }
        
        let indexSounds = _indexDictionary[_indexList[section]];
        
        do{ _player = try AVAudioPlayer(contentsOf: indexSounds![row].1);   }
        catch
        {
            print("startPreview() in FileSelectorVC failed to initialize player for file: " + indexSounds![row].0);
            print(error.localizedDescription);
        }
        
        // play the selected sound
        _player?.prepareToPlay();
        _player?.play();
        
        _nPreviews += 1;
        _isPreviewing = true;
    }
    
    func stopPreview()
    {
        if(_player != nil && (_player?.isPlaying)!)
        {
            _player?.stop();
            _player = nil;
        }
    }
    
    /** once sound is chosen pop back to the config view
     This method is called when the user presses the choose button */
    func selectSound(section: Int, row: Int)
    //func selectSound(index: Int, fileName: String)
    {
        // alert user of potentially unintended change to recorded sequence
        if(_isPartOfSequence)
        {
            DispatchQueue.main.async
            {
                // TODO: as of 1/9/2018 this is probably broken...
                self.alterSequenceAlert(section: section, row: row);
            }
        }
        else{   passSelectedSound(section: section, row: row);  }
    }
    
    func eraseFile(section: Int, row: Int)
    //func eraseFile(index: Int)
    {
        // warn the user
        let eraseAlert = UIAlertController(title: "Erase?", message: "Other Songs May Depend Upon This File. This Action Cannot Be Undone.", preferredStyle: .alert);
        
        let eraseAction = UIAlertAction(title: "Erase", style: .destructive, handler:
        {
            (action: UIAlertAction) in
            self.eraseFileFromDisk(section: section, row: row);
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:{ (action: UIAlertAction) in  return; });
        
        eraseAlert.addAction(eraseAction);
        eraseAlert.addAction(cancelAction);
        present(eraseAlert, animated: true, completion: nil);
    }
}
