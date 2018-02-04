//
//  ViewController.swift
//  Sampler_App
//
//  Created by mike on 2/27/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

// This file defines the view controller which lets users add/select/edit/remove song entries,
//      which are persistent in the phone's memory.
import UIKit
import AVFoundation

//  TODO: rotatable view....?
//  4: SongVC -- 1/11/2018
//                  it is possible to move to more than one SamplerConfigVC at a time
//              by pressing more than one cell at a time,
//                  make it so this can't happen.
//          0n 1/11/2018 we tried adopting a scheme similar to what we do with the FileSelectorCells,
//              the touch up post notification was not getting received by our observer selector method for some reason.
//                  WE DO HAVE THE TABLE data array....
//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

protocol SamplerConfigParentProtocol: class
{
    /** if the user moves to the SamplerConfigVC and then moves back to this VC,
            remove the unamed song's entry in the table data array */
    func removeUnamedSong(songNumber: Int);
    func namingUpdate(previousSongNumber: Int, name: String);
    func eraseSong(name: String, number: Int);
    func setLoadFlag(load: Bool, songNumber: Int, bank: Int, pad: Int);
    func eraseFile(file: URL);
}

protocol SongCellParentProtocol: class{ func selectCell(index: Int);    }

/** this is the base view controller,
 Allows users to create and select new song instances
 one instance of this view controller is owned by the AppDelegate */
class SongViewController: UITableViewController, UINavigationControllerDelegate
{
    private var _debugFlag = false;
    
    /** number of hardware audio outputs availible to the device,
            this number can change for a few reasong,
                e.g. making a bluetooth connection */
    private var _hardwareOutputs = -1
    var hardwareOutputs: Int
    {
        get{    return _hardwareOutputs;    }
        set{    _hardwareOutputs = newValue}
    }
    
    /** get data from storage */
    private lazy var _loader: Loader! =  Loader()
    /** store or modify data in storage */
    private lazy var _saver: Saver! = Saver();
    /** erase data in storage */
    private lazy var _eraser: Eraser! = Eraser();
    
    /** Source for table rows.
             (Name, Song Number, Date of Creation/Rename) */
    private lazy var _tableDataSource: [(String,  Int, String)] = [] ;

    private var _samplerConfigVCArray: [SamplerConfigViewController?] = [];
    var samplerConfigVCArray: [SamplerConfigViewController?]{   get{    return _samplerConfigVCArray;   }   }

    /** number of Song objects currently loaded into the app.
     this value is following a zero indexed convention scheme,
     i.e. the first Song created will be numbered as zero.
     However, in storage, the first song saved will have 1 as an id */
    private var _nSongs: Int = 0;
    var nSongs: Int{  return _nSongs; }
    
    /**the current song being used by the user.
        used to determine which songs to deallocate in case of memory warning.*/
    private var _currentSong: Int = -1;
    
    /** we are settling on 3 banks per song for now */
    private var _maxNBanks: Int = 3;
    var maxNBanks: Int{ return _maxNBanks;  }
    
    private var _maxNPads: Int = 8;
    
    //private lazy var _storyBoard: UIStoryboard! = UIStoryboard.init(name: "Main", bundle: nil);
    private lazy var _dateFormatter: DateFormatter! = DateFormatter();
    
    /** relfects whether the last load action was from a song, or from a file/recording
         false for song loading, true for file loading/recording.   */
    private var _fileLoadFlag = false;
    
    /** keep track whenever a file is loaded or recorded,
             so that if the file causes a memory warning,
                 we know which file to deallocate if the user chooses to do so */
    private var _lastLoadedPad: (Int, Int, Int) = (-1, -1, -1); //   (song number, bank number, pad number)
    
    internal var _isVisible = false
    var isVisible: Bool
    {
        get{    return _isVisible;  }
        set{    _isVisible = newValue;  }
    }
    
    private let _demoSongName = "Splash! Demo Song";
    
    private lazy var _opQueue: OperationQueue! = OperationQueue();
    
    override func loadView()
    {
        super.loadView();
        navigationController?.delegate = self;
        
        navigationItem.setLeftBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleNavBarAddSongButton)) , animated: false);
        
        navigationItem.setRightBarButton(UIBarButtonItem(title: "?", style: .plain, target: self, action: #selector(handleNavBarInfoButton)), animated: false)
        
        _dateFormatter.dateStyle = .short;
        _dateFormatter.timeStyle = .medium;
        
        //  Along with constraints set in the storyboard for each of the labels in the prototype cell,
        //      these two lines make it so cell height will match the height of the cell defined in the storyboard.
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.estimatedRowHeight = 200;
        //  make it so no blank cells will show in the table view.
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0));
        
        //***** A DEBUG MEASURE ******************************************
        //nuke
        // if you need to erase all saved files un comment these two lines.
        //_eraser.clearAllStorageFiles();
        //_eraser.eraseAppDirectory();
        //***** A DEBUG MEASURE *******************************************
        
        setupRouteChangeNotifications();
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
        
        var songCount: Int;
        
        // create the application directory if it is not already present.
        var _ = _loader.createAppDirectory();
        
        // if the App.plist is not preset in storage...
        if(!_loader.checkForAppPlist())
        {
            // make and save the plist to disk
            var _ = _loader.createAppPlist();
            // initialize the App plist
            var _ = _loader.initialAppPlistWrite();
            
            songCount = 0
        }
            // else if the App plist is present in storage,
            //  retreive its song count
        else{   songCount = _loader.getNumberOfSongs(); }
        
        // if there was a problem finding or creating the base files for the app..
        if(songCount == -1)
        {
            //  TODO: what should we do here???
            if(_debugFlag){ print("could not find or create the neccessary files to set up the application");   }
            _nSongs = 0;
        }
        // if the app files are present but no songs are present on disk...
        else if(songCount == 0)
        {
            if(_debugFlag){ print("SongTVC found no songs in storage"); }
            
            saveDemo();
            loadDemo();
            
            alertUserToCreateSong();
            /** changed to = 1 on 12/7/2017,
                    was 0 */
            _nSongs = 1;
        }
        // if there are songs ready to load...
        else
        {
            if(_debugFlag){ print("Songs are present and ready to be loaded from storage"); }
            _nSongs = songCount;
            //  load song entries from storage
            loadEntries();
        }
    }
    
    deinit
    {
        self._dateFormatter = nil;
        self._eraser = nil;
        self._loader = nil;
        self._opQueue = nil;
        self._samplerConfigVCArray = [];
        self._saver = nil;
        self._tableDataSource = [];
        
        for song in 0 ..< _nSongs
        {
            _samplerConfigVCArray[song] = nil;
        }

        if(_debugFlag){ print("*** SongTVC deinitialized"); }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        navigationController?.isNavigationBarHidden = false;
        UIApplication.shared.isIdleTimerDisabled = false;
        
        navigationController?.navigationBar.topItem?.title = "Songs";
        
        // only one sound mod should be active at a time
        stopAllOtherSoundMods();
        
        _isVisible = true;
    }
    
    override func viewDidAppear(_ animated: Bool){  clearVisibleSong(); }
    
    override func viewWillDisappear(_ animated: Bool){  _isVisible = false  }
        
    //  TODO: we did see an instance of the memory warning popping up out of nowhere when there were no other songs to deallocate.
    //          we could have have a seperate case for this......
    //  TODO: there are two different scenarios we need to handle.
    //          1:  if this is a result of a song being loaded
    //                  then just deallocated all other songs
    //          2:  if this is a result of a file being loaded or recorded
    //                  just deallocate the file that was loaded or recorded
    //      In either case the user should be alerted.
    //      Currently I'm not sure how we are going to tell the difference between the two cases.....
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning();
        
        //  if the memory warning was a result of a single file being loaded or recorded...
        if(_fileLoadFlag)
        {
            let fileMemoryAlert = UIAlertController(title: "Low Memory", message: "The File You Just Loaded Caused a Memory Alert, Do You Want To Keep It?", preferredStyle: .alert);
            
            let discardAction = UIAlertAction(title: "Discard", style: .destructive, handler:
            {   (action: UIAlertAction) in  self.releaseLastLoadedPad();    }   )
            
            let keepAction = UIAlertAction(title: "Keep", style: .cancel, handler: nil);
            
            fileMemoryAlert.addAction(discardAction);
            fileMemoryAlert.addAction(keepAction);
            
            navigationController?.present(fileMemoryAlert, animated: true, completion: nil);
        }
        
        //  regardless of whether the warning happened becuase of a file load or song load,
        //      give the user the option to release any memory from any loaded songs which are not currently visible.
        let memoryAlert = UIAlertController(title: "Low Memory", message: "Do You Want To Free Up Any Available Loaded Memory In Other Loaded Songs?", preferredStyle: .alert);

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        let discardAction = UIAlertAction(title: "OK", style: .destructive, handler:{    (action:UIAlertAction) in   self.releaseOtherSongs();    })
        
        memoryAlert.addAction(cancelAction);
        memoryAlert.addAction(discardAction);
        
        navigationController?.present(memoryAlert, animated: true, completion: nil);
    }
    
    /** release memory for all other songs which are not currently visible */
    private func releaseOtherSongs()
    {
        // release the memory for all but the current song
        for i in 0 ..< _nSongs where i != _currentSong
        {
            if(_samplerConfigVCArray[i]?.song.masterSoundMod != nil)
            {
                _samplerConfigVCArray[i]?._delegate = nil
                _samplerConfigVCArray[i] = nil;
            }
        }
    }
    
    /** if a file being loaded or recorded triggers a memory warning,
             and if the user chooses to discard the file after being warned,
                 this method will be called */
    private func releaseLastLoadedPad()
    {
        //  DEBUG: when we do this the console prints out that a padModel was deintialized,
        //              however we do not see the expected dip in memory usage..
        _samplerConfigVCArray[_lastLoadedPad.0 - 1]?.song.masterSoundMod.soundCollection[_lastLoadedPad.1 - 1][_lastLoadedPad.2] = nil;
        
        if(_samplerConfigVCArray[_lastLoadedPad.0 - 1]?.song.bankViewStackControllerArray[_lastLoadedPad.1 - 1]?.padConfigVCArray != nil)
        {
            // set the preview button back to default text
            _samplerConfigVCArray[_lastLoadedPad.0 - 1]?.song.bankViewStackControllerArray[_lastLoadedPad.1 - 1]?.padConfigVCArray[_lastLoadedPad.2]?.erasePad();
        }
        else
        {
            if(_debugFlag){ print("*************releaseLastLoadedPad() failed, _padConfigVCArray was nil"); }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{   return _nSongs; }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell: SongCell = tableView.dequeueReusableCell(withIdentifier: "SongCell") as! SongCell;
        
        (cell.songName, cell.songNumber, cell.dateCreated) = _tableDataSource[indexPath.row];
        cell._delegate = self;
        
        cell.layer.borderWidth = 2;
        cell.layer.borderColor = UIColor.white.cgColor;
        cell.layer.cornerRadius = 5;
        
        return cell;
    }
    
    /** by default,
            the demo song will always be the first song created */
    private func saveDemo()
    {
        let nonZeroIndexedBankNumber = 1;
        let insertIndex = _saver.saveNewSongEntry(name: _demoSongName);
        
        _saver.createNewSongPlist(name: _demoSongName, number: insertIndex, date: _dateFormatter.string(from: Date()));
        _saver.createBankDirectory(name: _demoSongName, number: nonZeroIndexedBankNumber);
        _tableDataSource.append((_demoSongName, 1, _dateFormatter.string(from: Date())));
        
        assert(insertIndex == 1);
        
        _samplerConfigVCArray.append(self.storyboard?.instantiateViewController(withIdentifier: "SamplerConfigVC") as? SamplerConfigViewController);
        
        _samplerConfigVCArray[insertIndex - 1]?._delegate = self;                                   // duplicate
        _samplerConfigVCArray[insertIndex - 1]?.songName = _tableDataSource[insertIndex - 1].0;     //  duplicate
        _samplerConfigVCArray[insertIndex - 1]?.songNumber = _tableDataSource[insertIndex - 1].1;   //  duplicate
        _samplerConfigVCArray[insertIndex - 1]?.dateCreated = _tableDataSource[insertIndex - 1].2;  //  duplicate
        _samplerConfigVCArray[insertIndex - 1]?.hardwareOutputs = _hardwareOutputs;                     //  duplicate

        for demoPad in 0 ..< _maxNPads
        {
            var file: URL!
            
            //  TODO: this is a clumsy way of doing things
            //          it would be much better to get an array of the files in the Splash_lib....
            switch demoPad
            {
            case 0: file = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p04.wav", ofType: nil)!)
            case 1: file = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p05.wav", ofType: nil)!)
            case 2: file = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p07.wav", ofType: nil)!)
            case 3: file = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p13.wav", ofType: nil)!)
            case 4: file = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p18.wav", ofType: nil)!)
            case 5: file = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p29.wav", ofType: nil)!)
            case 6: file = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p40.wav", ofType: nil)!)
            case 7: file = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash_lib/splsh_p32.wav", ofType: nil)!)
            default:
                return;
            }
            
            saveDemoPadFileAndDurationAndEndPoint(pad: demoPad, file: file, index: insertIndex);
        }
    }
    
    private func saveDemoPadFileAndDurationAndEndPoint(pad: Int, file: URL, index: Int)
    {
        let nonZeroIndexedBankNumber = 1
        
        let padSaver = PadSaver(songName: _demoSongName, songNumber: index, bankNumber: nonZeroIndexedBankNumber, padNumber: pad);
        
        padSaver.savePadFile(songName: _demoSongName, bank: nonZeroIndexedBankNumber, pad: pad, file: file);
        
        var audioFile = AVAudioFile();
        
        do
        {
            try audioFile = AVAudioFile(forReading: file);
            if(_debugFlag){ print("saveDemoPadFileAndDurationAndEndPoint() in SongTVC initialized AVAudioFile");    }
        }
        catch
        {
            print("saveDemoPadFileAndDuration() in SongTVC could not init demo file for pad: " + pad.description);
            print(error.localizedDescription);
        }
       
        // default endpoint is file's duration
        let endpoint = Double(audioFile.length)/audioFile.fileFormat.sampleRate;
       
        padSaver.savePadEndPoint(songName: _demoSongName, bank: nonZeroIndexedBankNumber, pad: pad, endPoint: Double(endpoint));
    }
    
    private func loadDemo()
    {
        var demoBankArray: [BankViewStackController] = [];
        
        // populate current bank array based upon curent song's number of banks
        for _ in 0 ..< _maxNBanks                                                       // duplicate
        {
            let tempBankVC = self.storyboard?.instantiateViewController(withIdentifier: "BankStackViewController") as! BankViewStackController//
            // blank banks
            demoBankArray.append(tempBankVC);      // duplicate
        }
        
        _samplerConfigVCArray[0]?.song = Song(name: _demoSongName, songNumber: 1, hardwareOutputs: (_samplerConfigVCArray[0]?.hardwareOutputs)!, nBanks: _maxNBanks, bankArray: demoBankArray);
        
        tableView.reloadData();
    }
    
    /** load entries from storage */
    private func loadEntries()
    {
        let sortedSongNames = _loader.getSongNames();
        
        // first position in this array will always be the App.plist, skip it
        //  initialize songs based upon the contents of the designated app directory
        for index in 0 ..< sortedSongNames.count
        {
            let currentSongDict = _loader.getSongDictionary(songName: sortedSongNames[index]);
            
            var currentSongName: String! = "";
            currentSongName = currentSongDict["name"] as! String;
            let currentSongNumber = Int(currentSongDict["number"] as! String);
            let currentDateCreated = currentSongDict["date"] as! String;
            
            //    name of song, song number, and bank number.
            var currentBankVCArray: [BankViewStackController] = [];
            
            // populate current bank array based upon curent song's number of banks
            for _ in 0 ..< _maxNBanks
            {
                let tempBankVC = self.storyboard?.instantiateViewController(withIdentifier: "BankStackViewController") as! BankViewStackController;
                // blank banks
                currentBankVCArray.append(tempBankVC);
            }
            
            let tempSamplerConfigVC = self.storyboard?.instantiateViewController(withIdentifier: "SamplerConfigVC") as! SamplerConfigViewController;
            tempSamplerConfigVC._delegate = self;
            tempSamplerConfigVC.hardwareOutputs = _hardwareOutputs;
            
            tempSamplerConfigVC.song = Song(name: currentSongName, songNumber: currentSongNumber!, hardwareOutputs: _hardwareOutputs, nBanks: tempSamplerConfigVC.maxNBanks, bankArray: currentBankVCArray);
            
            tempSamplerConfigVC.song._delegate = tempSamplerConfigVC;
            
            _samplerConfigVCArray.append(tempSamplerConfigVC);
            
            _tableDataSource.append((currentSongName, index + 1, currentDateCreated));
            
            //  TODO: soon to be obsolete
            // set the entryView transmitter's songName member
            //_songEntryArray[index - 1].entryView.transmitter.songName = _songEntryArray[index - 1].entryModel.name;
            //_songEntryArray[index - 1].delegate = self;
        }
    }
    
    /** results in a new song being created and saved to disk
         a new row in the table view should result as well */
    @IBAction func handleNavBarAddSongButton(_ sender: UIBarButtonItem)
    {
        _nSongs += 1;
        
        let newSongName = "No Name";
        let newSongNumber = _nSongs;                                                // remember app.plist is always [0]....
        let newSongDateCreated = Date();
        
        _tableDataSource.append((newSongName, newSongNumber, _dateFormatter.string(from: newSongDateCreated)));
        _samplerConfigVCArray.append(nil);
        
        tableView.reloadData();
        
        //  pressing the new song button results in automatically moving to the new song's SamplerConfigVC
        selectCell(index: newSongNumber/* - 1*/);
    }
    
    /** present the info screen for this VC */
    @objc func handleNavBarInfoButton()
    {
        let infoScreen = self.storyboard?.instantiateViewController(withIdentifier: "SongTVCInfoVC") as! SongTableInfoScreenViewController;
        navigationController?.pushViewController(infoScreen, animated: true);
    }
    
    /** alerts the user that no songs besides the demo song are persitent in storage and to create a new song */
    private func alertUserToCreateSong()
    {
        let noSongsAlertView: UIAlertController = UIAlertController(title: "First Time?", message: "Welcome! Please Create a Song. Or You Can Play Around With The Demo Song.", preferredStyle: UIAlertControllerStyle.alert);
        let okAction = UIAlertAction(title: "OK", style: .default, handler:
        {   (action:UIAlertAction) in
            self.triggerAccessMicrophoneAlert();
        })
        noSongsAlertView.addAction(okAction);
        
        navigationController?.present(noSongsAlertView, animated: true, completion: nil);
    }
    
    /** the access microphone alert which is triggered upon a fresh install of the app makes the app go into the background,
            as of 1/19/2018 this alert was being preseneted as soon as the BankVC appeared in the demo,
                which means the user potentially would be exposed to the dirty reconnect bug first thing,
                    NOT A GOOD LOOK!
            This method attempts to trigger the access microphone alert right after the welcome screen is dismissed */
    private func triggerAccessMicrophoneAlert()
    {
        var dummyEngine: AVAudioEngine! = AVAudioEngine();
        let _ = dummyEngine.inputNode.inputFormat(forBus: 0);
        dummyEngine = nil;
    }
    
    /** Stop any and all active sound mods owned by any Song */
    private func stopAllOtherSoundMods()
    {
        guard (_samplerConfigVCArray.count > 0) else{   return; }
        
        for samplerConfig in _samplerConfigVCArray where samplerConfig?.song != nil
        {
            if (samplerConfig?.song.masterSoundMod != nil && (samplerConfig?.song.masterSoundMod.isRunning)!)
            {   samplerConfig?.song.masterSoundMod.stopMod();  }
        }
    }
    
    private func setupRouteChangeNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: .AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())
    }
    
    @objc func handleRouteChange(_ notification: Notification)
    {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue)
            else{   return; }
        
        switch reason
        {
        case .newDeviceAvailable:   print("******new device availible")
        case .oldDeviceUnavailable: print("******old device removed")
        case .categoryChange:
            print("******Catagory Change");
            print("****Catagory: " + AVAudioSession.sharedInstance().category)
        case .noSuitableRouteForCategory: print("****** no suitable route for catagory");
        case .override: print("******override");
        case .routeConfigurationChange: print("******route configuration change");
        case .unknown: print("****** unknown");
        case.wakeFromSleep: print("****** wake from sleep")
        }
        
        for i in 0 ..< _samplerConfigVCArray.count
        {
            if(_samplerConfigVCArray[i]?.song != nil)
            {
                // only handle changing routes if a song has been launched.
                if(_samplerConfigVCArray[i]?.song.masterSoundMod != nil)
                {
                    /** in the case of an route change due to the headphones being disconnected,
                     it is possible to trigger a pad before it has been reconnected to the engine.
                     This is meant to prevent this happening.
                     THIS flag needs to be set immediatly!   */
                    _opQueue.addOperation
                    {
                        self._samplerConfigVCArray[i]?.song.masterSoundMod.routeChanging = true;
                        self.setBankVCsRouteIsChanging(samplerConfigIndex: i, changing: true);
                    }
                    _opQueue.waitUntilAllOperationsAreFinished();
                    
                    // this call only handles master sound mods that are currently present and loaded in memory
                    _samplerConfigVCArray[i]?.song.masterSoundMod.handleAduioRouteChange(notification: notification);
                    
                    DispatchQueue.main.async    /** added on 1/14/2018 at the behest of the main thread checker */
                    {   self.resetVisibleBankVCPadColors(); }
                    
                    _samplerConfigVCArray[i]?.song.masterSoundMod.routeChanging = false;
                    
                    self.setBankVCsRouteIsChanging(samplerConfigIndex: i, changing: false);
                    
                    DispatchQueue.main.async    /** added on 1/14/2018 at the behest of the main thread checker */
                    {
                        if(UIApplication.shared.isIgnoringInteractionEvents)
                        {
                            // this check makes it so the app will remain unresponsive if the timer is ringing
                            if(!AVAudioSession.sharedInstance().isOtherAudioPlaying)
                            {
                                UIApplication.shared.endIgnoringInteractionEvents();
                            
                                if(self._debugFlag)
                                {
                                    print("handleRouteChange() in SongTVC stopped ignoring interaction events once masterSoundMod's _routeChanging flag was set to false");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /** TODO:   as of 1/10/2018 this method is only called by the handleRouteChange() method in this class,
            at some point we should try doing this with an observer/notification instead.
                .. less code...*/
    private func resetVisibleBankVCPadColors()
    {
        for sampler in 0 ..< _samplerConfigVCArray.count
        {
            if(_samplerConfigVCArray[sampler] != nil)
            {
                if(_samplerConfigVCArray[sampler]?.isVisibleSong)!
                {
                    if(_samplerConfigVCArray[sampler]?.song != nil)
                    {
                        if(_samplerConfigVCArray[sampler]?.song.bankViewStackControllerArray != nil)
                        {
                            for bank in 0 ..< (_samplerConfigVCArray[sampler]?.song.nBanks)!
                            {
                                if(_samplerConfigVCArray[sampler]?.song.bankViewStackControllerArray[bank] != nil)
                                {
                                    if(_samplerConfigVCArray[sampler]?.song.bankViewStackControllerArray[bank]?.isVisible)!
                                    {   _samplerConfigVCArray[sampler]?.song.bankViewStackControllerArray[bank]?.resetPadColors();  }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /** once this VC appears no song is visible */
    private func clearVisibleSong()
    {
        if(_samplerConfigVCArray.count != 0)
        {
            for samplerConfig in _samplerConfigVCArray where samplerConfig != nil && (samplerConfig?.isVisibleSong)!
            {
                samplerConfig?.isVisibleSong = false;
                return;
            }
        }
    }
    
    private func setBankVCsRouteIsChanging(samplerConfigIndex: Int, changing: Bool)
    {
        if(self._samplerConfigVCArray[samplerConfigIndex]?.song.bankViewStackControllerArray != nil)
        {
            for j in 0 ..< self._maxNBanks where _samplerConfigVCArray[samplerConfigIndex]?.song.bankViewStackControllerArray[j] != nil
            {
                _samplerConfigVCArray[samplerConfigIndex]?.song.bankViewStackControllerArray[j]?.routeIsChanging = changing;
            }
        }
    }

    func isRecordingTakingPlace() -> Bool
    {
        var ret = false
        
        if(_samplerConfigVCArray.count != 0)
        {
            for sampler in 0 ..< _nSongs where _samplerConfigVCArray[sampler] != nil
            {
                if(_samplerConfigVCArray[sampler]?.isRecordingTakingPlace())!
                {
                    ret = true;
                    break;
                }
            }
        }
        
        return ret;
    }
    
    //  TODO:   use an observer/notification instead
    func reanimateSamplerConfigVC()
    {
        if(_samplerConfigVCArray.count != 0)
        {
            for sampler in 0 ..< _nSongs where _samplerConfigVCArray[sampler] != nil
            {
                _samplerConfigVCArray[sampler]?.reanimateSamplerConfigVC();
            }
        }
    }
    
    //----------------------------- SongEntryParentProtocol callee methods -- Will be implmented way down the road.... -----------------------
    //  TODO: this method will probably need to be moved to SamplerConfigVC
    /** once the transmitter corresponding to the passed in song number establishes a connection with the host application,
     it will begin passing connection status info up the chain of class ownership,
     finally arrving at this method,
     which sets the corresponding sound mod's connection status. */
    func delegateUpdateSoundModConnectionStatus(connected: Bool, songNumber: Int)
    {
        // set song's connection status
        _samplerConfigVCArray[songNumber]!.song.isConnected = connected;
        
        if(_samplerConfigVCArray[songNumber]!.song.masterSoundMod == nil)
        {
            _samplerConfigVCArray[songNumber]!.song.masterSoundMod = MasterSoundMod(hardwareOutputs: _hardwareOutputs);
        }
        
        _samplerConfigVCArray[songNumber]!.song.masterSoundMod.isConnected = connected;
        
        // set all banks and bankVCs in the song as connected
        //for bank in _songArray[songNumber].bankArray
        for i in 0 ..< _maxNBanks
        {
            if(_samplerConfigVCArray[songNumber]!.song.bankViewStackControllerArray[i] == nil)
            {
                _samplerConfigVCArray[songNumber]!.song.bankViewStackControllerArray[i] = (self.storyboard?.instantiateViewController(withIdentifier: "BankStackViewController") as! BankViewStackController);
            }
            
            _samplerConfigVCArray[songNumber]!.song.bankViewStackControllerArray[i]?.isConnected = connected;
            
            if(_samplerConfigVCArray[songNumber]!.song.bankViewStackControllerArray[i]?.padConfigVCArray != nil)
            {
                // set any non nil padConfigVCs to connected
                for j in 0 ..< _samplerConfigVCArray[songNumber]!.maxNPads
                {
                    if(_samplerConfigVCArray[songNumber]!.song.bankViewStackControllerArray[i]?.padConfigVCArray[j] != nil)
                    {
                        _samplerConfigVCArray[songNumber]!.song.bankViewStackControllerArray[i]?.padConfigVCArray[j]?.isConnected = connected;
                    }
                }
            }
        }
    }
    
    //  TODO: this method will probably need to be moved to SamplerConfigVC
    /** pass connection info from the SongVCTransmitter to the song in question's sound and sync transmitters.
            Also have the connecting Song's SyncTransmitter connect its sync socket to the host.
                And finally have the Song sync its state with the host  */
    func delgateUpdateSoundModConnectionInfo(info: [String], songNumber: Int)
    {
        _samplerConfigVCArray[songNumber]!.song.soundTransmitter = SoundTransmitter(playPort: Int(info[0])! /*, syncPort: Int(info[1])! */, hostIp: info[2]);
        
        _samplerConfigVCArray[songNumber]!.song.syncTransmitter = SyncTransmitter(syncPort: Int(info[1])!, hostIP: info[2]);
        
        _samplerConfigVCArray[songNumber]!.song.syncTransmitter._delegate = _samplerConfigVCArray[songNumber]!.song;
        
        // now that the host has notified us that it has a dedicated tcp port listneing for us,
        //      we might as well try to connect to it
        _samplerConfigVCArray[songNumber]!.song.syncTransmitter.connectSyncSocket();
    }//----------------------------- end of SongEntryParentProtocol callee methods --------------------------------------------------
}

extension SongViewController: SamplerConfigParentProtocol
{
    //  DEBUG: 1/11/2018
    //          this is getting called when the info screen button is pressed in the SamplerConfigVC...
    func removeUnamedSong(songNumber: Int)
    {
        _nSongs -= 1;
        _tableDataSource.remove(at: songNumber - 1);
        tableView.reloadData();
    }
    
    func namingUpdate(previousSongNumber: Int, name: String)
    {
        _tableDataSource = [];
        
        let songNames = _loader.getSongNames();
        
        for i in 0 ..< songNames.count
        {
            let currentSongDict = _loader.getSongDictionary(songName: songNames[i]);
            let currentTableEntry = (currentSongDict["name"] as! String, Int(currentSongDict["number"] as! String), currentSongDict["date"] as! String);
            
            _tableDataSource.append(currentTableEntry as! (String, Int, String));
        }
        
        // now update the order of the _samplerConfigVCArray
        let namedSamplerConfigVC = _samplerConfigVCArray.remove(at: previousSongNumber - 1);
        let newSongNumber = _loader.getSongNumber(name: name)
        let newIndexPath = IndexPath(row: newSongNumber - 1, section: 0);
        
        _samplerConfigVCArray.insert(namedSamplerConfigVC, at: newSongNumber - 1);
        
        tableView.reloadData();
        tableView.scrollToRow(at: newIndexPath, at: .middle, animated: false);
    }
    
    func eraseSong(name: String, number: Int)
    {
        _eraser.eraseSong(name: name, number: number);
        _nSongs -= 1;
        _tableDataSource.remove(at: number - 1);
        _samplerConfigVCArray.remove(at: number - 1);
        
        for i in (number - 1) ..< _nSongs
        {
            _tableDataSource[i].1 = i + 1;
            _samplerConfigVCArray[i]?.songNumber = i + 1;
        }
        
        tableView.reloadData();
    }

    /** aids in distinguishing between potential causes of a memory warning */
    func setLoadFlag(load: Bool, songNumber: Int, bank: Int, pad: Int)
    {
        _fileLoadFlag = load;
        _lastLoadedPad = (songNumber, bank, pad);
    }
    
    /** this method is called as a result of the user choosing to erase a file via the fileSelectorVC,
            before the file is erased we must check to make sure that it is not in use in any loaded song */
    func eraseFile(file: URL)
    {
        var fileFoundInLoadedSong = false;
        
        if(_samplerConfigVCArray.count != 0)
        {
            for sampler in 0 ..< _nSongs
            {
                fileFoundInLoadedSong = (_samplerConfigVCArray[sampler]?.eraseFileFromDisk(file: file))!
                if(fileFoundInLoadedSong){  break;  }
            }
            
            if(fileFoundInLoadedSong)
            {
                let failedFileEraseAlert = UIAlertController(title: "File In Use", message: "The File You Are Trying To Erase Is Currently In Use.", preferredStyle: .alert);
                
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil);
                failedFileEraseAlert.addAction(okAction);
                navigationController?.present(failedFileEraseAlert, animated: true, completion: nil);
            }
            else{   _eraser.eraseFile(file: file);  }
        }
    }
}

extension SongViewController: SongCellParentProtocol
{
    func selectCell(index: Int)
    {
        if(_samplerConfigVCArray[index - 1] == nil)
        {
            _samplerConfigVCArray[index - 1] = self.storyboard?.instantiateViewController(withIdentifier: "SamplerConfigVC") as? SamplerConfigViewController;
        }

        _samplerConfigVCArray[index - 1]?._delegate = self;
        _samplerConfigVCArray[index - 1]?.songName = _tableDataSource[index - 1].0;
        _samplerConfigVCArray[index - 1]?.songNumber = _tableDataSource[index - 1].1;
        _samplerConfigVCArray[index - 1]?.dateCreated = _tableDataSource[index - 1].2;
        _samplerConfigVCArray[index - 1]?.hardwareOutputs = _hardwareOutputs;
        _samplerConfigVCArray[index - 1]?.isVisibleSong = true;

        _currentSong = index - 1;
        
        navigationController?.pushViewController(_samplerConfigVCArray[index - 1]!, animated: true);
    }
}
