//
//  SamplerConfigViewController.swift
//  Sampler_App
//
//  Created by mike on 2/27/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit
import AVFoundation

protocol SongParentProtocol: class
{
    func switchToBank(switchToBank: Int);
    func passLoad(load: Bool, songNumber: Int, bankNumber: Int, padNumber: Int);
    func switchSequenceBank(bank: Int);
    func alertAndStopRecording(bank: Int, pad: Int);
    func presentBadConnectionChainAlert();
    func passEraseFile(file: URL);
}

protocol SamplerSettingsParentProtocol: class
{   func popSettingsVC()    }

protocol SamplerConfigInfoScreenParentProtocol: class
{   func infoScreenWasPopped(); }

class SamplerConfigViewController: SamplerVC, UITextFieldDelegate
{
    private var _debugFlag = false;
    
    /** number of hardware out puts provided by the device */
    private  var _hardwareOutputs = -1
    var hardwareOutputs: Int
    {
        get{    return _hardwareOutputs;    }
        set{    _hardwareOutputs = newValue;    }
    }
    
    override var songNumber: Int
    {
        get{    return _songNumber; }
        set
        {
            _songNumber = newValue;
            if(_song != nil){   _song.songNumber = _songNumber; }
        }
    }
    
    private var _dateCreated: String = "";
    var dateCreated: String
    {
        get{    return _dateCreated;    }
        set{    _dateCreated = newValue;    }
    }
    
    private var _song: Song! = nil;
    var song: Song!
    {
        get{    return _song;   }
        set{    _song = newValue;   }
    }
    
    /** we are settling on 3 banks per song for now */
    private var _maxNBanks: Int = 3;
    var maxNBanks: Int{ get{    return _maxNBanks;  }   }
    
    /** we are settling on 8 pads per bank for now */
    private var _maxNPads: Int = 8;
    var maxNPads: Int{  get{    return _maxNPads;   }   }
    
    weak var _delegate: SamplerConfigParentProtocol! = nil;
    
    @IBOutlet weak var _nameLabel: UILabel!
    
    /** used to name a song */
    @IBOutlet weak var _nameTextField: UITextField!
    
    /** updated when a song is created or renamed */
    @IBOutlet weak var _dateCreatedLabel: UILabel!
    @IBOutlet weak var _warningLabel: UILabel!
    /** indicates that a song is being loaded */
    @IBOutlet weak var _loadActivityIndicator: UIActivityIndicatorView!
    
    /** removes a song from the app */
    @IBOutlet weak var _eraseSongButton: UIButton!
    /** move to settingsVC */
    @IBOutlet weak var _settingsButtons: UIButton!
    
    /** release this song's memory */
    @IBOutlet weak var _releaseButton: UIButton!
    
    /** go to a song's first bankVC */
    @IBOutlet weak var _goToSongButton: UIButton!
    
    /** store or modify data in storage */
    private lazy var _saver: Saver! = Saver();
    
    /** networking module for this class,
         primarily concerned with establishing connections between this phone and the host application. */
    private var _transmitter: SongVCTransmitter! = nil
    var transmitter: SongVCTransmitter{ get{return _transmitter;}    }
    
    /** need current date in case we rename a song */
    private lazy var _dateFormatter: DateFormatter! = DateFormatter();
    
    /** disables song launching while the user is naming a song */
    private var _keyboardIsVisible = false;
    
    /** indicates whether this song is currently being looked at by the user
            used to handle a media services reset */
    private var _isVisibleSong = false
    var isVisibleSong: Bool
    {
        get{    return _isVisibleSong;  }
        set{    _isVisibleSong = newValue;  }
    }
    
    /** we were seeing instnaces where the removedUnamedSong() method was getting called in the SongVC
            if the InfoScreen was preseneted before the user named the song */
    private var _infoScreenIsPresented = false;
    
    /** indicates whether this VC is in the process of loading a song after the Go To Song button was pressed */
    private var _isLoading = false;
    
    override func loadView()
    {
        super.loadView();
        
        _nameTextField.delegate = self;
        
        _dateFormatter.dateStyle = .short;
        _dateFormatter.timeStyle = .medium;
        
        _warningLabel.isHidden = true;
        _loadActivityIndicator.hidesWhenStopped = true;
        
        //  https://stackoverflow.com/questions/43836317/swift-uibutton-how-to-left-align-the-title
        _eraseSongButton.contentHorizontalAlignment = .left;
        _eraseSongButton.titleLabel?.adjustsFontSizeToFitWidth = true;
        
        _settingsButtons.titleLabel?.adjustsFontSizeToFitWidth = true;
        
        _releaseButton.titleLabel?.adjustsFontSizeToFitWidth = true;
        _releaseButton.contentHorizontalAlignment = .right;
        
        navigationItem.setRightBarButton(UIBarButtonItem(title: "?", style: .plain, target: self, action: #selector(handleNavBarInfoButton)), animated: false);
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        navigationController?.isNavigationBarHidden = false;
        UIApplication.shared.isIdleTimerDisabled = false;    // sleeps
        
        _isVisible = true;
        
        // if this is not a song that we just barely created via the add song button in the SongTVC....
        if(_songName != "No Name")
        {
            _nameTextField.backgroundColor = .black
            _nameTextField.textColor = .white;
            _nameTextField.text = _songName
            
            _goToSongButton.isHidden = false;
        }
        else{   _goToSongButton.isHidden = true;    }
        
        _dateCreatedLabel.text = _dateCreated;
        
        if(!_warningLabel.isHidden){    _warningLabel.isHidden = true;  }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        // doing this earlier(viewWillAppear) makes the previous(SongTVC) VC's title adopt this assignment......
        navigationController?.navigationBar.topItem?.title = _songName;
        
        _isVisibleSong = true;
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        _isVisible = false;
        
        let tempSongName = _songName.uppercased();
        if(tempSongName == "NO NAME" || tempSongName == "" || tempSongName == "APP.PLIST")
        {
            //  DEBUG: make it so this call does not happen if the info screen is getting presented.
            // send signal to the SongTVC to update number of songs and remove any table data with "no name".
                
            if(!_infoScreenIsPresented) // this prevents an out of bounds error in the SongVC
            {   _delegate.removeUnamedSong(songNumber: _songNumber);    }
        }
    
        _isLoading = false;
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        _loadActivityIndicator.stopAnimating();
        
        if(!_warningLabel.isHidden){    _warningLabel.isHidden = true;  }
    }
    
    deinit
    {
        _song = nil;
        _saver = nil;
        _transmitter = nil;
        _dateFormatter = nil;
        _delegate = nil;
        if(_debugFlag){ print("***SamplerConfigVC deinitialized");  }
    }
    
    @objc func handleNavBarInfoButton()
    {
        let infoScreen = self.storyboard?.instantiateViewController(withIdentifier: "SamplerConfigInfoVC") as! SamplerConfigInfoScreenViewController;
        infoScreen._delegate = self;
        navigationController?.pushViewController(infoScreen, animated: true);
        
        _infoScreenIsPresented = true;
    }
    
    @IBAction func handleGoToSongButton(_ sender: UIButton)
    {
        // only alow a song launch if no other app is using audio,
        //      e.g. a timer in the clock app
        /** this check is a bank aid */
        if(!AVAudioSession.sharedInstance().isOtherAudioPlaying)
        {
            // indicate that this VC is in the process of loading a song.
            //  this is here so that if the app enters the background during a song load,
            //      once it re enters the foreground the activity animator can be animated again.
            _isLoading = true;
            
            _warningLabel.isHidden = false;
            _loadActivityIndicator.startAnimating();
            
            /** acording to our exception break point,
                    this call is responsible or relat4ed to the __cxa_throw exception....*/
            //  https://stackoverflow.com/questions/40660913/start-and-stop-activity-indicator-swift3
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01)
            {   self.handleSongLaunch();    }
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool
    {
        if(_songName == _demoSongName)
        {
            handleDemoSongRename();
            return false;
        }
        
        return true;
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        setAllButtonsEnabled(enabled: false);
        _nameTextField.backgroundColor = .white;
        _nameTextField.textColor = .black;
    }
    
    private func handleDemoSongRename()
    {
        let demoRenameAlertVC = UIAlertController(title: "Not Allowed", message: "Renaming The Demo Song Is Not Allowed", preferredStyle: .alert);
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil);
        demoRenameAlertVC.addAction(okAction);
        navigationController?.present(demoRenameAlertVC, animated: true, completion: nil);
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        if(string == ""){   navigationController?.navigationBar.topItem?.title = "No Name"; }
        return true;
    }
    
    /** triggered by clear(x) button on right hand side */
    func textFieldShouldClear(_ textField: UITextField) -> Bool
    {
        navigationController?.navigationBar.topItem?.title = "No Name";
        return true;
    }

    /** handles when the user presses the return button on the keyboard */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{   return applyNameToSong(textField: textField);   }
    
    private func applyNameToSong(textField: UITextField) -> Bool
    {
        let proposedName = textField.text?.trimmingCharacters(in: CharacterSet.whitespaces);
        var nameTaken: Bool;
        var takenSongNumber: Int;
        // indicates whether we are naming a brand new song or renaming a song which was loaded from disk.
        var rename: Bool;
        let oldName = _songName;
        let oldSongNumber = _saver.getSongNumber(name: oldName);
        
        _keyboardIsVisible = true;
        
        _nameTextField.backgroundColor = .black;
        _nameTextField.textColor = .white;
        
        //  Check for invalid names
        if(proposedName?.uppercased() == "APP.PLIST" || proposedName?.uppercased() == "NO NAME" || proposedName == "" || proposedName?.uppercased() == _demoSongName.uppercased())
        {
            if(oldName != "No Name")
            {
                // have previous name appear if invalid name is entered.
                _nameTextField.text = oldName;
            }
            else
            {
                // make placeholder reappear.
                _nameTextField.text = ""
            }
            handleInvalidSongName(name: proposedName!);
            return false;
        }
        
        (nameTaken, takenSongNumber) = _saver.nameIsTaken(name: proposedName!);  // non duplicate names yield songNumber == -1
        
        if(nameTaken)
        {
            // if the user mostlikely brought up the keyboard by accident,
            //      and just wants to dismiss it by pressing return.....
            if(oldName == proposedName)
            {
                textField.resignFirstResponder();      // do nothing
                return true;
            }
            
            alertUserOfDuplicateName(tag: takenSongNumber, name: proposedName!)  //  tag arg is suspect here......
            
            // display previous name or make the placholder reappear
            if(oldName != "No Name"){   _nameTextField.text = oldName;  }
            else{   _nameTextField.text = "";   }
            
            return false;
        }
            // else if the proposed name is not already taken...
        else
        {
            _nameTextField.text = proposedName;
            
            //  if at this point,
            //      _name == "No Name" we can be certain that we are not renaming a song.
            rename = (_songName == "No Name") ? false : true;
            
            _songName = proposedName!;
            
            ///  TODO: updating the transmitter's song name member here is probably haphazard,
            ///             there is probably a better place to do this...
            // update the transmitter's song name member.
            //_transmitter.songName = proposedName!;
            //_transmitter.songName = _nameLabel.text!;
            
            rename ? saveRenamedSong(oldName: oldName, newName: _songName, oldNumber: oldSongNumber) : saveNewSong();
            
            textField.resignFirstResponder();
            _goToSongButton.isHidden = false;
            return true;
        }
    }
    
    /** display an alert box if the user chooses an invalid name */
    private func handleInvalidSongName(name: String)
    {
        let noSongsAlertView: UIAlertController = UIAlertController(title: "Invalid Song Name", message: "Please Choose Another Song Name Besides \"" + name + "\" .", preferredStyle: UIAlertControllerStyle.alert);
        let okAction = UIAlertAction(title: "OK", style: .default, handler:
        {   (action:UIAlertAction) in
            self.navigationController?.navigationBar.topItem?.title = self._songName;
        })
        noSongsAlertView.addAction(okAction);
        present(noSongsAlertView, animated: true, completion: nil);
    }
    
    /** handles alerting the user of the entering of a duplicate name */
    private func alertUserOfDuplicateName(tag: Int, name: String)
    {
        let duplicateNameAlertView: UIAlertController = UIAlertController(title: "Name Is Taken", message: "A song named \"" + name +  "\" already exists, please choose a different name.", preferredStyle: .alert);
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        duplicateNameAlertView.addAction(okAction);
        present(duplicateNameAlertView, animated: true, completion: nil);
    }
    
    @IBAction func handleEraseSongButton(_ sender: UIButton)
    {
        // must name song first
        if(checkAndAlertUnnamedSong()){ return; }
        
        let eraseSongAlert: UIAlertController = UIAlertController(title: "Erase Song?", message: "This Action Cannot Be Undone.", preferredStyle: .alert);
        
        let eraseAction = UIAlertAction(title: "Erase", style: .destructive, handler:
        {[weak self](paramAction:UIAlertAction!) in
            self?.eraseSong(name: (self?._songName)!, number: (self?._songNumber)!);
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        eraseSongAlert.addAction(cancelAction);
        eraseSongAlert.addAction(eraseAction);
        present(eraseSongAlert, animated: true, completion: nil);
    }
    
    private func eraseSong(name: String, number: Int)
    {
        _delegate.eraseSong(name: name, number: number);
        navigationController?.popViewController(animated: true);
    }
    
    @IBAction func handleSettingsButton(_ sender: UIButton)
    {
        // must name song first
        if(checkAndAlertUnnamedSong()){ return; }
        
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "SamplerSettingsVC") as! SamplerSettingsViewController;
        settingsVC._delegate = self;
        
        navigationController?.present(settingsVC, animated: true, completion: nil);
    }
    
    @IBAction func handleReleaseButton(_ sender: UIButton)
    {
        // must name song first
        if(checkAndAlertUnnamedSong()){ return; }
        
        if(_song != nil)
        {
            _song = nil;
            
            let releaseAlert = UIAlertController(title: "Released", message: "Memory For This Song Was Released", preferredStyle: .alert);
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil);
            
            releaseAlert.addAction(okAction);
            navigationController?.present(releaseAlert, animated: true, completion: nil);
        }
    }
    
    private func checkAndAlertUnnamedSong() -> Bool
    {
        if(_songName == "No Name") // must name song first
        {
            alertSongIsUnnamed();
            return true;
        }
        
        return false;
    }
    
    /** save a brand newly created song */
    private func saveNewSong()
    {
        assert(_songNumber != 0);   //  no zero indexing on disk
        
        let insertIndex = _saver.saveNewSongEntry(name: _songName /*, number: _songNumber)*/)
        
        // save name, and song number to the App plist
        //new song id matches _nSongs,
        //  as of 12/21/2017 this should mean that the first song ceated by the user should have a song number of 2,
        //      because the demo song will have a song number of 1...
        if(insertIndex != -1)
        {
            _songNumber = insertIndex;
    
            // create new plist for new song in new song's directory
            var _ = _saver.createNewSongPlist(name: _songName, number: _songNumber, date: _dateCreated);
            
            //  after this each songPlist in each song directory needs to have its song number value updated
            _saver.updateSongPlistSongNumbers();
            
            //  update the SongTVC's table data array
            //       and update this VC's title
            _delegate.namingUpdate(previousSongNumber: _songNumber, name: _songName);
            navigationController?.navigationBar.topItem?.title = _songName;
        }
        else{   if(_debugFlag){ print("saveNewSong in SongTVC could not create new song");  }   }
    }
    
    /** save a song that has been renamed.  */
    private func saveRenamedSong(oldName: String, newName: String, oldNumber: Int)
    {
        // 12/24/2017 we added this case to fix the scenario of launching a song, renaming it,
        //          and then launching it again.
        if(_song != nil){   _song = nil;    }
        
        let newDate = Date();
        
        _songNumber = _saver.renameSongEntry(oldName: oldName, newName: newName);
        var _ = _saver.renameSongPlist(oldName: oldName, newName: newName, newDate: _dateFormatter.string(from: newDate), newNumber: _songNumber);
        _saver.updateSongPlistSongNumbers();
        
        _dateCreatedLabel.text = _dateFormatter.string(from: newDate);
        
        // updates the corresponding cell in the SongTVC,
        //  and update the the SongTVC's table data array.
        _delegate.namingUpdate(previousSongNumber: oldNumber, name: _songName);
        navigationController?.navigationBar.topItem?.title = _songName;
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        let textFieldName = textField.text;
        
        if(textFieldName != "" && _songName == "No Name"){  var _ = applyNameToSong(textField: textField);  }
        
        // prevent users from launching a song while the keyboards is visible
        _keyboardIsVisible = false;
        
        setAllButtonsEnabled(enabled: true);
    }
    
    /** handle launching songs, new or otherwise */
    func handleSongLaunch()
    {
        // if we are currently naming or renaming a song, disable song launching
        if(_keyboardIsVisible){ return; }
        
        if(!UIApplication.shared.isIgnoringInteractionEvents){  UIApplication.shared.beginIgnoringInteractionEvents();  }
        
        var isLoadedSong = false
        
        isLoadedSong = _saver.checkIfSongHasBankDirectories(name: _songName);
        
        // if this is a brand new song we are launching for the first time
        if(!isLoadedSong)
        {
            initBrandNewSong(songNumber: _songNumber, songName: _songName)
            // set load flag in SongTVC to indicate that the last loading action was a song and not a file
            _delegate.setLoadFlag(load: false, songNumber: -1, bank: -1, pad: -1);
        }
        
        initSongAndBanks();
    }
    
    /** added on 12/10/2017
            helps with the loading of the demo song,
                this code was moved out the handleSongLaunch() method */
    private func initSongAndBanks()
    {
        self.initAllBankVCs(songNumber: self._songNumber, songName: self._songName);
        
        if(_song._delegate == nil){    _song._delegate = self;    }
        if(_song.masterSoundMod == nil){   _song.masterSoundMod = MasterSoundMod(hardwareOutputs: _hardwareOutputs);    }
        if(_song.masterSoundMod._delegate == nil){  _song.masterSoundMod._delegate = _song; }
        
        // in case of a recent rename,
        //  update the song's name and evrything that the song owns with a song name member
        _song.name = _songName;
        
        // Load all of the three bank's views if not already done so
        //  this will result in all three of the bank's sounds being loaded.
        //  This way there will be no delay caused by waiting for sounds to load when we switch to banks two or three
        for i in 0 ..< _song.nBanks
        {
            self._song.bankViewStackControllerArray[i]?.loadViewIfNeeded();
        }
        
        self.navigationController?.pushViewController(self._song.bankViewStackControllerArray[0]!, animated: true);
    }
    
    /** launches a song that is brand new and was not loaded from memory
     This method is called once in handleSongLanuch() */
    private func initBrandNewSong(songNumber: Int, songName: String)
    {
        let tempBankArray = getNewBankArray(name: songName, songNumber: songNumber)
        
        _song = Song(name: songName, songNumber: songNumber, hardwareOutputs: _hardwareOutputs,  nBanks: _maxNBanks, bankArray: tempBankArray);
        
        _song._delegate = self;
        
        // File management
        //  create all three bank directories
        for i in 1 ... _song.nBanks
        {
            var _ = _saver.createBankDirectory(name: songName, number: i);
            
            //  create plists for each of the 4 VCs
            var _ = _saver.createInitialBankPlistFiles(path: _saver.appDir.appending("/" + songName + "/" + i.description), songNumber: songNumber, bank: i);
        }
    }
    
    private func getNewBankArray(name: String, songNumber: Int) -> [BankViewStackController]
    {
        var tempBankVCArray = [BankViewStackController]();
        
        // create all three banks for new song
        for i in 1 ... _maxNBanks
        {
            let tempInitialBankVC = self.storyboard?.instantiateViewController(withIdentifier: "BankStackViewController") as! BankViewStackController;
            tempBankVCArray.append(tempInitialBankVC);
        }
        
        return tempBankVCArray;
    }
    
    /** initializes all bankVCs and sets their delegates */
    private func initAllBankVCs(songNumber: Int, songName: String)
    {
        for i in 1 ... _maxNBanks
        {
            // a song might be nil here in the case of a memory warning having taken place
            if(_song == nil)
            {
                let tempBankArray = getNewBankArray(name: songName, songNumber: songNumber);
                _song = Song(name: songName, songNumber: songNumber, hardwareOutputs: _hardwareOutputs, nBanks: _maxNBanks, bankArray: tempBankArray);
            }
            
            if(_song.bankViewStackControllerArray[i - 1] == nil)
            {
                _song.bankViewStackControllerArray[i - 1] = (self.storyboard?.instantiateViewController(withIdentifier: "BankStackViewController") as! BankViewStackController);
               
                _song.bankViewStackControllerArray[i - 1]?._delegate = _song;
            }
            
            // pass song name, song number and bank number down to all three BankVCs
            _song.bankViewStackControllerArray[i - 1]?.songName = songName;
            _song.bankViewStackControllerArray[i - 1]?.songNumber = songNumber;
            _song.bankViewStackControllerArray[i - 1]?.bankNumber = i
            _song.bankViewStackControllerArray[i - 1]?.nPads = _maxNPads;
        }
        
        // set all three bankVC delegates
        for i in 0 ..< _song.nBanks
        {
            _song.bankViewStackControllerArray[i]?._delegate = _song;
        }
    }
    
    /** disabel/enabel all controls not releated to naming the song */
    private func setAllButtonsEnabled(enabled: Bool)
    {
        navigationItem.rightBarButtonItem?.isEnabled = enabled;
        navigationItem.hidesBackButton = !enabled;
        
        _eraseSongButton.isEnabled = enabled;
        _settingsButtons.isEnabled = enabled;
        _releaseButton.isEnabled = enabled;
    }

    func isRecordingTakingPlace() -> Bool
    {
        if(_song != nil){   return _song.isRecordingTakingPlace()   }
        return false;
    }
    
    /** returns true if the master sound mod contains the file in question */
    func eraseFileFromDisk(file: URL) -> Bool
    {
        if(_song != nil){   return _song.eraseFileFromDisk(file: file);  }
        return false;
    }
    
    /** 1/11/2017 presented if the user pushes either the Erase, Settings, or Release button before naming the song */
    private func alertSongIsUnnamed()
    {
        let unnamedSongAlert = UIAlertController(title: "Song Unnamed", message: "Please Name The Song First", preferredStyle: .alert);
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil);
        unnamedSongAlert.addAction(okAction);
        navigationController?.present(unnamedSongAlert, animated: true, completion: nil);
    }
    
    //  DEBUG: as of 12/21/2017 this still does not work...
    //          need to use an Observer/Notification instead...
    func reanimateSamplerConfigVC()
    {
        if(_isLoading)
        {
            if(!_loadActivityIndicator.isAnimating)
            {
                // this method is not called on the main thread.
                DispatchQueue.main.async{   self._loadActivityIndicator.startAnimating();   }
            }
        }
    }
}

extension SamplerConfigViewController: SongParentProtocol
{
    func switchToBank(switchToBank: Int)
    {
        if(_song.bankViewStackControllerArray[switchToBank - 1]?._delegate == nil)
        {   _song.bankViewStackControllerArray[switchToBank - 1]?._delegate = _song;    }
        
        navigationController?.pushViewController(_song.bankViewStackControllerArray[switchToBank - 1]!, animated: false);
    }
    
    func passLoad(load: Bool, songNumber: Int, bankNumber: Int, padNumber: Int)
    {   _delegate.setLoadFlag(load: load, songNumber: songNumber, bank: bankNumber, pad: padNumber);    }
    
    /** we can only switch to a sequenceVC if there actually a sequence loaded */
    func switchSequenceBank(bank: Int)
    {
        // if there is no sequence stored on disk for desired bank, return
        if(SequenceLoader().loadSequence(songName: _songName, bank: bank).count == 0){    return; }
        else
        {
            if(_song.bankViewStackControllerArray[bank - 1]?._delegate == nil)
            {   _song.bankViewStackControllerArray[bank - 1]?._delegate = _song;  }
    
            if(_song.bankViewStackControllerArray[bank - 1]?.sequencePlayVC == nil)
            {
                _song.bankViewStackControllerArray[bank - 1]?.sequencePlayVC = self.storyboard?.instantiateViewController(withIdentifier: "SequenceVC") as! SequencePlayViewController;
                
                _song.bankViewStackControllerArray[bank - 1]?.sequencePlayVC.songName = (_song.bankViewStackControllerArray[bank - 1]?.songName)!
                _song.bankViewStackControllerArray[bank - 1]?.sequencePlayVC.songNumber = (_song.bankViewStackControllerArray[bank - 1]?.songNumber)!
                _song.bankViewStackControllerArray[bank - 1]?.sequencePlayVC.bankNumber = (_song.bankViewStackControllerArray[bank - 1]?.bankNumber)!
            }
            
            if(_song.bankViewStackControllerArray[bank - 1]?.sequencePlayVC._delegate == nil)
            {   _song.bankViewStackControllerArray[bank - 1]?.sequencePlayVC._delegate = _song.bankViewStackControllerArray[bank - 1];  }
            
            //  TODO: we should use popToVC here instead....
            // pop previous sequenceVC
            navigationController?.popViewController(animated: false);
            // pop previous bankVC
            navigationController?.popViewController(animated: false);
        
            // push bankVC
            navigationController?.pushViewController(_song.bankViewStackControllerArray[bank - 1]!, animated: false);
            // push sequenceVC
            navigationController?.pushViewController((_song.bankViewStackControllerArray[bank - 1]?.sequencePlayVC)!, animated: false);
        }
    }
    
    /** if an audio route change occurrs while a recording is ongoing alert the user and stop the recording */
    func alertAndStopRecording(bank: Int, pad: Int)
    {
        // in the event that the user interrupts a recording by pressing the off button,
        //  this avenue will not be triggered until the phone is lit up again...
        //      therefore if the call to stopActiveRecording() is called by the appDelegate instead,
        //          once this method is called we should not make the mistake of ending the recording twice
        if(self.song.bankViewStackControllerArray[bank - 1]?.padConfigVCArray[pad]?.recordVC.isRecording)!
        {   stopActiveRecording(bank: bank, pad: pad);   }
        
        let abortRecordingAlert = UIAlertController(title: "Stop Recording", message: "An Audio Route Change Occurred While A Recording Was Being Made. Please Try Again.", preferredStyle: .alert);
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler:
        {
            (action: UIAlertAction)
            in
            self.handleStopRecordingOK(bank: bank, pad: pad);
        });
        
        abortRecordingAlert.addAction(okAction);

        navigationController?.present(abortRecordingAlert, animated: true, completion: nil);
    }
    
    func stopActiveRecording(bank: Int, pad: Int)
    {
        //  DEBUG ///////////////////////////////////////////////////////////////////////////////////////////////////
        //              this block of code is happening too late in the game.
        //                  its possible for the user to press the off button while a recording is taking place,
        //                      and this code will not get called until the phone lights up again....
        //                            we could end up having a huge file recorded in the process.....
        // reset record state
        self.song.bankViewStackControllerArray[bank - 1]?.padConfigVCArray[pad]?.recordVC.resetRecord();
        //  stop recording
        self.song.bankViewStackControllerArray[bank - 1]?.padConfigVCArray[pad]?.recordVC.avMic.stop();
        
        // TODO: we might want to do this before we stop the mic.....
        self._opQueue.addOperation
            {   self.song.bankViewStackControllerArray[bank - 1]?.padConfigVCArray[pad]?.recordVC.isInterrupted = true; }
        self._opQueue.waitUntilAllOperationsAreFinished();
        //  DEBUG ///////////////////////////////////////////////////////////////////////////////////////////////////
    }
    
    /** this method is not part of the protocol defined near the top of this file */
    func handleStopRecordingOK(bank: Int, pad: Int)
    {
        //  this can't happen earlier,
        //      if it does the indicator will not have started alerting yet,
        //          and thus this call will have no effect.
        if(song.bankViewStackControllerArray[bank - 1]?.padConfigVCArray[pad]?.recordVC._activityIndicator.isAnimating)!
        {   song.bankViewStackControllerArray[bank - 1]?.padConfigVCArray[pad]?.recordVC._activityIndicator.stopAnimating();    }
    }
    
    func presentBadConnectionChainAlert()
    {
        let badConnectionChainAlert = UIAlertController(title: "Pad Connection Error", message: "The Pad You Just Pressed Was Not Connected Properly, Attempting To Reconnect.", preferredStyle: .alert);
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil);
        badConnectionChainAlert.addAction(okAction);
        navigationController?.present(badConnectionChainAlert, animated: true, completion: nil);
    }
    
    func passEraseFile(file: URL){  _delegate.eraseFile(file: file);    }
}

extension SamplerConfigViewController: SamplerSettingsParentProtocol
{   func popSettingsVC(){   navigationController?.dismiss(animated: true, completion: nil); }   }

extension SamplerConfigViewController: SamplerConfigInfoScreenParentProtocol
{   func infoScreenWasPopped(){ _infoScreenIsPresented = false; }   }
