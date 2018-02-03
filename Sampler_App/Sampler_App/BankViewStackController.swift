//
//  SamplerViewController.swift
//  Sampler_App
//
//  Created by mike on 2/27/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit
import AVFoundation

//  1: BankVC
//          1/11/2018
//              retry loading the demo song pads in parallel again...
//       1/11/2018
//          files are inconsistently coming blank
//              when we move to the padConfigVC,
//                  blank pads are displaying the proper file name....
//  DEBUG:  1/19/2018
//              rotated view is not acceptable
//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

/** pass sound triggering info up the class hierarchy eventually bound for the master sound mod */
protocol ParentPadViewProtocol: class
{
    func padTouchDown(number: Int, isLoaded: Bool); // play
    func padTouchUp(number: Int, isLoaded: Bool);   // stop play
    func sixthTouch(number: Int, isLoaded: Bool);
    func panMoveToPadConfig(number: Int);
    func passResetPadColors();
}

/** pass sound selected for pad info up the class hierarchy eventually bound for the sound mod */
protocol PadConfigVCParentProtocol: class
{
    func passSelectedFile(file: URL, pad: Int, section: Int, row: Int);
    func sendConnectPadToMixer(pad: Int);
    func sendDetachPad(pad: Int, erase: Bool);
    func preview(pad: Int);
    //  Pass methods update the model
    func passVolume(pad: Int, volume: Double);
    func passStartingPoint(pad: Int, startPoint:  Double, load: Bool);// init flag determines whether updateBuffers() is called
    func passEndPoint(pad: Int, endPoint: Double);
    func passTriggerMode(pad: Int, mode: Bool);
    func passPitch(pad: Int, pitch: Float);
    func startMasterSoundMod();
    func stopMasterSoundMod();
    //  Send methods are used with connection to host
    func sendVolume(pad: Int, volume: Double)
    func sendStartingPoint(pad: Int, startingPoint: Double);
    func sendEndPoint(pad: Int, endPoint: Double);
    func sendTriggerMode(pad: Int, triggerMode: Bool);
    // helps determine how to handle a memory warning specific to the user loading a sound vs loading a song.
    func passLoadFlag(load: Bool, pad: Int);
    func sendIsRecording(isRecording: Bool, pad: Int);
    func swipePreviousPadConfigVC(pad: Int);
    func swipeNextPadConfigVC(pad: Int);
    func passInvalidateFadeOutTimers();
    func passEraseFile(file: URL);
    func cancelPreview(pad: Int);
    func clearSequence();
    func resetPadViewIsLoaded(pad: Int);
}

/** pass sequence sound triggering info up the class ownership chain to the master sound mod */
protocol SequencePlayParentProtocol: class
{
    func sequenceTouch(pad: Int);
    func sequenceStop(pad: Int);
    func switchSequenceBank(bank: Int);
    func sequenceStopAllPads();
    func cancelPlayThrough();
}

/** instance of this class is owned by the Song class,
 responsible for letting the user perform with and configure a bank */
class BankViewStackController: SamplerVC, UIAlertViewDelegate
{
    private let _debugFlag = false;
    
    private var _nPads: Int = -1;
    var nPads: Int
    {
        get{    return _nPads;  }
        set
        {
            _nPads = newValue;
            assert(_nPads != -1);
        }
    }
    
    /** displays the info screen */
    @IBOutlet weak var _infoButton: UIButton!
    
    /** the pads */
    @IBOutlet var _stackPadViewArray: [PadView]!

    @IBOutlet weak var _bankPadStackView: UIStackView!
    @IBOutlet weak var _upperRowPadStackContainter: UIStackView!
    @IBOutlet weak var _lowerRowPadStackContainter: UIStackView!
    
    @IBOutlet weak var _bankSelectorButton1: UIButton!
    @IBOutlet weak var _bankSelectorButton2: UIButton!
    @IBOutlet weak var _bankSelectorButton3: UIButton!
    
    private var _button1TouchDown = false;
    private var _button2TouchDown = false;
    private var _button3TouchDown = false;
    
    @IBOutlet weak var _padContainerView: UIView!
    
    /** record a sequence of pad touches */
    @IBOutlet weak var _recordButton: UIButton!
    
    private var _recordButtonCircle: UIView! = nil;
    
    /** move to the sequenceVC if a pad sequence has been recorded */
    @IBOutlet weak var _forwardButton: UIButton!
    
    private var _nBanks = 3;        //  TODO: this value is not passed down...
    
    override var songName: String // private member in superclass
    {
        get{    return _songName;   }
        set
        {
            _songName = newValue;
            
            if(_sequencePlayVC != nil){ _sequencePlayVC.songName = _songName;   }
            
            if(_padConfigVCArray != nil)
            {
                for padConfigVC in 0 ..< _nPads where _padConfigVCArray[padConfigVC] != nil
                {
                    _padConfigVCArray[padConfigVC]?.songName = _songName;
                }
            }
        }
    }
    
    override var songNumber: Int
    {
        get{    return _songNumber; }
        set
        {
            _songNumber = newValue;
            
            if(_padConfigVCArray != nil)
            {
                for i in 0 ..< _nPads where _padConfigVCArray[i] != nil
                {
                    _padConfigVCArray[i]?.songNumber = _songNumber;
                }
            }
        }
    }
    
    /** reflects whether the user is recording a sequence of pad strikes */
    private var _isRecording: Bool = false;
    
    /** array which stores sequence record info in the form of Ints corresponding to pad numbers */
    private var _seqRecordArray: [Int]! = nil;
    
    /** in case the user toggles recording on and then off again without recording a play sequence,
            we can store the sequence in this,
                and then set _seqRecordArray back to what it was before.*/
    private var _oldSeqRecordArray: [Int] = []
    
    /** index of the pad which was touched last.
     This is not the index of the pad that was just touched!
     This is the index of the pad that was touched immediatly before the pad that was just touched.
     This will aid in determining which PadConfigVC to push.*/
    private var _lastTouchedPadIndex: Int = 0;
    
    /** index of the pad that was just touched */
    private var _currentlyTouchedPadIndex: Int = 0;
    
    /** the number of pads that are currently being touched by the user */
    private var _numberOfCurrentlyTouchedPads: Int = 0;
    
    weak var _delegate: BankParentProtocol! = nil;
    
    /** holds a PadConfigVC for every pad in the Bank/View */
    private var _padConfigVCArray: [PadConfigViewControler?]! = nil;
    var padConfigVCArray: [PadConfigViewControler?]!
    {
        get{    return _padConfigVCArray;   }
        set{    _padConfigVCArray = newValue;   }
    }
    
    /** saves a recorded sequence to disk */
    private var _sequenceSaver: SequenceSaver! = SequenceSaver();
    /** loads a recorded sequence from disk */
    private var _sequenceLoader: SequenceLoader! = SequenceLoader();
    
    /** VC that lets the user play a recorded sequence */
    private var _sequencePlayVC: SequencePlayViewController! = nil;
    var sequencePlayVC: SequencePlayViewController!
    {
        get{    return _sequencePlayVC; }
        set{    _sequencePlayVC = newValue; }
    }
    
    /** file managment for loading pads */
    private var _padLoader: PadLoader! = nil
    var padLoader: PadLoader!
    {
        get{    return _padLoader;   }
        set{    _padLoader = newValue;  }
    }
    
    /** indicates whether the bank has at least one sound loaded into a pad */
    private var _isLoaded: Bool = false;
    
    /** flag helps prevent the user from tirggering pads while an audio route change is taking place. */
    override var routeIsChanging: Bool
    {
        get{    return _routeIsChanging;    }
        set
        {
            _routeIsChanging = newValue;
            
            if(_sequencePlayVC != nil){ _sequencePlayVC.routeIsChanging = _routeIsChanging; }
            
            for i in 0 ..< _nPads
            {
                if(_stackPadViewArray != nil){  _stackPadViewArray[i].routeIsChanging = _routeIsChanging;   }
                
                if(_padConfigVCArray != nil)
                {   if(_padConfigVCArray[i] != nil){    _padConfigVCArray[i]?.routeIsChanging = _routeIsChanging;   }   }
            }
        }
    }
    
    private var _backToSamplerConfigSwipeGestureRecognizer: UISwipeGestureRecognizer! = nil
    
    private var _bankButtonLockGestureArray: [UILongPressGestureRecognizer?] = [];
    
    /** the bank which is currently locked */
    private var _lockIndex = -1;
    /** required time for lock to activate via touch */
    private let _lockDuration: Double = 0.35
    
    override func loadView()
    {
        super.loadView();
        
        _recordButtonCircle = UIView(frame: CGRect(x: _recordButton.frame.width * 0.1, y: _recordButton.frame.height * 0.1, width: _recordButton.frame.width * 0.8, height: _recordButton.frame.height * 0.8));
        
        _recordButtonCircle.layer.cornerRadius = _recordButtonCircle.frame.height/2;
        _recordButtonCircle.backgroundColor = .gray;
        _recordButtonCircle.isUserInteractionEnabled = false;
        
        _recordButton.addSubview(_recordButtonCircle);
        
        initLongPressGestureArray();
    
        self._backToSamplerConfigSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.handleBackToSamplerConfigSwipeGestureRecognizer))
            
        self._bankPadStackView.addGestureRecognizer(self._backToSamplerConfigSwipeGestureRecognizer);
        
        _infoButton.layer.borderWidth = 2;
        _infoButton.layer.borderColor = UIColor.black.cgColor;
        _infoButton.layer.cornerRadius = 5;
        _infoButton.transform = CGAffineTransform(rotationAngle: .pi/2);
            
        self._bankSelectorButton1.layer.borderWidth = 2;
        self._bankSelectorButton1.layer.borderColor = UIColor.black.cgColor;
        self._bankSelectorButton1.layer.cornerRadius = 5;
        _bankSelectorButton1.addGestureRecognizer(_bankButtonLockGestureArray[_bankSelectorButton1.tag]!);
        
        self._bankSelectorButton2.layer.borderWidth = 2;
        self._bankSelectorButton2.layer.borderColor = UIColor.black.cgColor;
        self._bankSelectorButton2.layer.cornerRadius = 5;
        _bankSelectorButton2.addGestureRecognizer(_bankButtonLockGestureArray[_bankSelectorButton2.tag]!);

        self._bankSelectorButton3.layer.borderWidth = 2;
        self._bankSelectorButton3.layer.borderColor = UIColor.black.cgColor;
        self._bankSelectorButton3.layer.cornerRadius = 5;
        _bankSelectorButton3.addGestureRecognizer(_bankButtonLockGestureArray[_bankSelectorButton3.tag]!);
        
        _recordButton.layer.borderWidth = 2;
        _recordButton.layer.borderColor = UIColor.black.cgColor;
        _recordButton.layer.cornerRadius = 5;
        _recordButton.transform = CGAffineTransform(rotationAngle: .pi/2);
        
        _forwardButton.layer.borderWidth = 2;
        _forwardButton.layer.borderColor = UIColor.black.cgColor;
        _forwardButton.layer.cornerRadius = 5;
        _forwardButton.transform = CGAffineTransform(rotationAngle: .pi/2);
            
            // lay out pad UIs -- not sounds
        self.layoutPads();
        
        _padConfigVCArray = [PadConfigViewControler!](repeating: nil, count: 8);
    }
    
    override func viewDidLoad()
    {
        _padLoader = PadLoader(songName: _songName, songNumber: _songNumber, bank: _bankNumber);
        
        if(_songName == _demoSongName){ loadDemoPadFiles(); }
        else{   loadPadFiles(); }
        
        loadPadSettings();
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        if(UIApplication.shared.isIgnoringInteractionEvents){   UIApplication.shared.endIgnoringInteractionEvents();    }
        
        navigationController?.isNavigationBarHidden = true;
        UIApplication.shared.isIdleTimerDisabled = true;
        _delegate.startMasterSoundMod();
        _isVisible = true;
        
        // load saved sequence
        _seqRecordArray =  _sequenceLoader.loadSequence(songName: _songName, bank: _bankNumber);
        
        if(_seqRecordArray.count > 0){  _forwardButton.backgroundColor = .yellow;   }
        else{   _forwardButton.backgroundColor = .gray; }
        
        loadPadSettings();
        
        _numberOfCurrentlyTouchedPads = 0;
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true;
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        stopAllPads();
        
            //  TODO: this code is duplicated in the SequenceVC
            // adjust current bank button color
            if(self._bankNumber == 1)
            {
                self._bankSelectorButton1.backgroundColor = .darkGray;
                self._bankSelectorButton2.backgroundColor = .lightGray;
                self._bankSelectorButton3.backgroundColor = .lightGray;
            }
            else if(self._bankNumber == 2)
            {
                self._bankSelectorButton1.backgroundColor = .lightGray;
                self._bankSelectorButton2.backgroundColor = .darkGray;
                self._bankSelectorButton3.backgroundColor = .lightGray;
            }
            else
            {
                assert(self._bankNumber == 3);
                self._bankSelectorButton1.backgroundColor = .lightGray;
                self._bankSelectorButton2.backgroundColor = .lightGray;
                self._bankSelectorButton3.backgroundColor = .darkGray;
            }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        _isVisible = false;
        
        // if we leave the VC while we were making a sequence recording...
        if(_isRecording){   toggleRecordOff();  }
        
        // if any sound is playing from this bank while we are about to navigate away from this VC,
        //      stop it from playing
        stopAllPads();
        resetPadColors();
        _delegate.cancelPlayThrough(bank: _bankNumber);
    }
    
    deinit
    {
        if(_padConfigVCArray != nil)
        {
            for i in 0 ..< _nPads
            {
                _padConfigVCArray[i] = nil;
            }
        }
        
        _recordButtonCircle = nil;
        _oldSeqRecordArray = [];
        
        _delegate = nil;
        
        _sequenceSaver = nil;
        _sequenceLoader = nil;
        _padLoader = nil;
        
        _backToSamplerConfigSwipeGestureRecognizer = nil;
        
        if(_bankButtonLockGestureArray.count > 0)
        {
            for bank in 0 ..< _nBanks
            {
                _bankButtonLockGestureArray[bank] = nil;
            }
        }
        
        print("*** BanKVC deinitialized, name: " + _songName.description + " , songNumber: " + _songNumber.description + " , bankNumber: " + _bankNumber.description);
    }
    
    private func initLongPressGestureArray()    // duplicate, same code is in SequenceVC
    {
        _bankButtonLockGestureArray.append(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressButton1(_:))));//duplicate
        _bankButtonLockGestureArray.append(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressButton2(_:))));//duplicate
        _bankButtonLockGestureArray.append(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressButton3(_:))));//duplicate
        
        for bank in 0 ..<  _nBanks  //duplicate
        {
            _bankButtonLockGestureArray[bank]?.minimumPressDuration = _lockDuration;                //duplicate
        }
    }
    
    /** lock/unlock bank 1 */
    @objc func handleLongPressButton1(_ sender: UILongPressGestureRecognizer)//duplicate
    {
        if(_bankNumber == 1)    //duplicate
        {
            if(sender.state == .began)  //duplicate
            {
                _bankSelectorButton1.backgroundColor = .orange; //duplicate
            }
            
            if(sender.state == .ended)  //duplicate
            {
                if(!_button1TouchDown)  //duplicate
                {
                    if(_lockIndex == -1)    //duplicate
                    {
                        _bankSelectorButton2.isEnabled = false; //duplicate
                        _bankSelectorButton2.isHidden = true;   //duplicate
                        _bankSelectorButton3.isEnabled = false; //duplicate
                        _bankSelectorButton3.isHidden = true;   //duplicate
                        _backToSamplerConfigSwipeGestureRecognizer.isEnabled = false;  //duplicate
                        setNonBankButtonControls(enabled: false);
                        _lockIndex = 0;                                         // zero indexed //duplicate
                    }
                    else    //duplicate
                    {
                        _bankSelectorButton2.isEnabled = true;  //duplicate
                        _bankSelectorButton2.isHidden = false;  //duplicate
                        _bankSelectorButton3.isEnabled = true;  //duplicate
                        _bankSelectorButton3.isHidden = false;  //duplicate
                        _backToSamplerConfigSwipeGestureRecognizer.isEnabled = true;   //duplicate
                        setNonBankButtonControls(enabled: true);
                        _lockIndex = -1;    //duplicate
                    }
                }
                
                _bankSelectorButton1.backgroundColor = .darkGray;   //duplicate
            }
        }
    }
    
    /** lock/unlock bank 2 */
    @objc func handleLongPressButton2(_ sender: UILongPressGestureRecognizer)   //duplicate
    {
        if(_bankNumber == 2)    //duplicate
        {
            if(sender.state == .began)  //duplicate
            {
                _bankSelectorButton2.backgroundColor = .orange; //duplicate
            }
            
            if(sender.state == .ended)  //duplicate
            {
                if(!_button1TouchDown)  //duplicate
                {
                    if(_lockIndex == -1)    //duplicate
                    {
                        _bankSelectorButton1.isEnabled = false; //duplicate
                        _bankSelectorButton1.isHidden = true;   //duplicate
                        _bankSelectorButton3.isEnabled = false; //duplicate
                        _bankSelectorButton3.isHidden = true;   //duplicate
                        _backToSamplerConfigSwipeGestureRecognizer.isEnabled = false;  //duplicate
                        setNonBankButtonControls(enabled: false);
                        _lockIndex = 0;                                         // zero indexed //duplicate
                    }
                    else    //duplicate
                    {
                        _bankSelectorButton1.isEnabled = true;  //duplicate
                        _bankSelectorButton1.isHidden = false;  //duplicate
                        _bankSelectorButton3.isEnabled = true;  //duplicate
                        _bankSelectorButton3.isHidden = false;  //duplicate
                        _backToSamplerConfigSwipeGestureRecognizer.isEnabled = true;   //duplicate
                        setNonBankButtonControls(enabled: true);
                        _lockIndex = -1;    //duplicate
                    }
                }
                
                _bankSelectorButton2.backgroundColor = .darkGray;   //duplicate
            }
        }
    }
    
    /** lock/unlock bank 3 */
    @objc func handleLongPressButton3(_ sender: UILongPressGestureRecognizer)   //duplicate
    {
        if(_bankNumber == 3)    //duplicate
        {
            if(sender.state == .began)  //duplicate
            {
                _bankSelectorButton3.backgroundColor = .orange; //duplicate
            }
            
            if(sender.state == .ended)  //duplicate
            {
                if(!_button3TouchDown)  //duplicate
                {
                    if(_lockIndex == -1)    //duplicate
                    {
                        _bankSelectorButton1.isEnabled = false; //duplicate
                        _bankSelectorButton1.isHidden = true;   //duplicate
                        _bankSelectorButton2.isEnabled = false; //duplicate
                        _bankSelectorButton2.isHidden = true;   //duplicate
                        _backToSamplerConfigSwipeGestureRecognizer.isEnabled = false;  //duplicate
                        setNonBankButtonControls(enabled: false);
                        _lockIndex = 0;                                         // zero indexed //duplicate
                    }
                    else    //duplicate
                    {
                        _bankSelectorButton1.isEnabled = true;  //duplicate
                        _bankSelectorButton1.isHidden = false;  //duplicate
                        _bankSelectorButton2.isEnabled = true;  //duplicate
                        _bankSelectorButton2.isHidden = false;  //duplicate
                        _backToSamplerConfigSwipeGestureRecognizer.isEnabled = true;   //duplicate
                        setNonBankButtonControls(enabled: true);
                        _lockIndex = -1;    //duplicate
                    }
                }
                
                _bankSelectorButton3.backgroundColor = .darkGray;   //duplicate
            }
        }
    }
    
    /** set the info, record, and sequence button controls enabled state.
            also set the pan gesture recognizers in all the pad views */
    private func setNonBankButtonControls(enabled: Bool)
    {
        _infoButton.isEnabled = enabled;
        _infoButton.isHidden = !enabled;
        _recordButton.isEnabled = enabled;
        _recordButton.isHidden = !enabled;
        _forwardButton.isEnabled = enabled;
        _forwardButton.isHidden = !enabled;
        
        for pad in 0 ..< _nPads
        {
            _stackPadViewArray[pad].panGestureRecognizer.isEnabled = enabled;
        }
    }
    
    /** lay out the pads for this bank */
    func layoutPads()
    {
        // make pads from partitioned frames
        for i in 0 ..< _nPads
        {
            _stackPadViewArray[i].padNumber = _stackPadViewArray[i].tag;
            
            self._stackPadViewArray[i].backgroundColor = .black;
            self._stackPadViewArray[i].layer.borderWidth = 2;
            self._stackPadViewArray[i].layer.borderColor = UIColor.white.cgColor;
            self._stackPadViewArray[i].layer.cornerRadius = 5;
            
            _stackPadViewArray[i].delegate = self;
        }
    }
    
    /** load any saved files for each pad
     this method is called in viewDidLoad()  */
    func loadPadFiles()
    {
        loadFilesForNPads();
        connectAllLoadedPads();
        initAllPadConfigVCs();
    }
    
    /** moved out of loadPadFiles() on 12/10/2017 */
    private func loadFilesForNPads()
    {
        // get all the music files in the shared Documents directory
        let allMuiscFiles = _padLoader.getAllMusicFiles();
        
        // load all files for each of the 8 pads here if they exist
        for i in 0 ..< _nPads
        {
            // if loading the file for the current pad does not return nil...
            if(_padLoader.loadFile(padNumber: i) != nil)
            {
                let currentFileName = _padLoader.loadFile(padNumber: i);
                var fileFound = false;
                
                // compare the current file name to all the last path components in the music file array
                for file in 0 ..< allMuiscFiles.count where allMuiscFiles[file]?.lastPathComponent == currentFileName
                {
                    // if the current url's last path compenent matches the loaded file name....
                    
                    fileFound = true;
                        
                    // any time we load a file,
                    //  either from selection/recording or loading from disk
                    //      the start and end points get set as well,
                    //          so there is no reason to pass the load arg here like we do with the starting point call method.
                    _opQueue.addOperation
                    {   self.callDelegatePassSelectedFile(file: allMuiscFiles[file]!, pad: i, section: -1, row: -1);    }
                        
                    self._stackPadViewArray[i].isLoaded = true;
                    break;
                }
                _opQueue.waitUntilAllOperationsAreFinished();   // TODO: having this fence here gave much better results(20/20),
                
                // if the file matching the file name was not found
                if(!fileFound)
                {
                    _opQueue.addOperation
                    {
                        DispatchQueue.main.async
                        {
                            //  DEBUG: how do we not make this call untill the previous file missing alert has been dismissed...?
                            self.alertUserOfMissingFile(name: currentFileName!, bank: self._bankNumber, pad: i);
                            //self._opQueue.waitUntilAllOperationsAreFinished();
                        }
                        //self._opQueue.waitUntilAllOperationsAreFinished();
                    }
                    //_opQueue.waitUntilAllOperationsAreFinished();
                }
            }
        }
    }
    
    /** moved out of loadPadFiles() on 12/10/2017
        this method's block of code was preceeded by the code in loadFilesFor8Pads() */
    private func connectAllLoadedPads()
    {
        // connect all loaded pads to the master sound mod's mixer
        for i in 0 ..< _nPads where self._stackPadViewArray[i].isLoaded
        {
            self.callDelegateConnectLoadedPadToMixer(pad: i);
            self._isLoaded = true;
        }
    }
    
    /** moved out of loadPadFiles() on 12/10/2017
        this method's block of code was preceeded by the code in connectAllLoadedPads() */
    private func initAllPadConfigVCs()
    {
        /** Band Aid */
        if(_songName == _demoSongName && _bankNumber != 1){ return; }
        
        // init each loaded pad's configVC
        for i in 0 ..< _nPads where self._stackPadViewArray[i].isLoaded
        {
            // this only inits a config VC if a file has been saved into the pad in question
            if(self._padConfigVCArray[i] == nil)
            {
                _padConfigVCArray[i] = self.storyboard?.instantiateViewController(withIdentifier: "PadConfig") as? PadConfigViewControler;
                self._padConfigVCArray[i]?.isLoaded = true;
                    
                // for some reason the instantiation above is leaving a bunch of values nil,
                //  requesting a VC's view will cause loadView() & viewDidLoad() to be called if the view is nil.
                let _ = self._padConfigVCArray[i]?.view;  // this is absoloutly necessary
                    
                self._padConfigVCArray[i]?.songName = self._songName;
                self._padConfigVCArray[i]?.songNumber = self._songNumber;
                self._padConfigVCArray[i]?.bankNumber = self._bankNumber;
                self._padConfigVCArray[i]?._delegate = self;
                self._padConfigVCArray[i]?.padNumber = i;
                _padConfigVCArray[i]?.padSaver = PadSaver(songName: _songName, songNumber: _songNumber, bankNumber: _bankNumber, padNumber: i);
                self._padConfigVCArray[i]?.isConnected = self._isConnected;
            }
        }
    }
    
    /** load files for the demo song,
            as of 12/10/2017 we are assuming these files are in a different place than files which the user either records,
                or imports via iTunes */
    private func loadDemoPadFiles()
    {
        loadDemoFilesForNPads();
        connectAllLoadedPads();
        initAllPadConfigVCs()
    }
    
    private func loadDemoFilesForNPads()
    {
        //  demo files for the demo song are included in the first bank.
        if(_songName == _demoSongName && _bankNumber != 1){ return; }
    
        // load all files for each of the 8 pads here,
        //      if they exist
        for i in 0 ..< _nPads
        {
            let currentDemoFileName = _padLoader.loadDemoFile(padNumber: i);
            self.callDelegatePassSelectedFile(file: currentDemoFileName! as URL, pad: i, section: -1, row: -1);
            self._stackPadViewArray[i].isLoaded = true;
        }
    }
    
    /** alert the user that a file to be loaded into the song was not found on disk */
    private func alertUserOfMissingFile(name: String, bank: Int, pad: Int)
    {
        let missingFileAlert = UIAlertController(title: "Missing File", message: "One Or More Files Including \"" + name + "\" In Bank " + bank.description + " And Pad " + (pad + 1).description + " Could Not Be Found.", preferredStyle: .alert);
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil);
        
        missingFileAlert.addAction(okAction);
        
        //  DEBUG:  12/28/2017
        //              code does not halt on account of an alert being presented.
        //                  when we have multiple files missing,
        //                      this call is made in quick succession before we actually see the presentation of the first alert...
        //              maybe we could make this call outside of this method...???
        //                  maybe have this method return the alertVC....????
        navigationController?.present(missingFileAlert, animated: true, completion: nil);
    }
    
    /** load all saved settings associated with each pad    */
    private func loadPadSettings()
    {
        // update title of preview button
        for i in 0 ..<  _nPads where _padConfigVCArray[i]?.isLoaded == true
        {
            // for each pad,
            //  if any setting has not been saved assign a default value,
            var fileName: String?
            var fileDuration = 0.0;
                
            // if we are loading from the first bank in the demo song.
            if(_songName == _demoSongName && _bankNumber == 1)
            {
                fileName = _padLoader.loadDemoFile(padNumber: i).absoluteURL?.lastPathComponent;    // suspect
                    
                //help speed up bank switching
                if(_padConfigVCArray[i]?.fileLength == nil)
                {   fileDuration = _padLoader.getDemoFileDuration(index: i);    }
            }
            else
            {
                fileName = _padLoader.loadFile(padNumber: i);
                    
                //help speed up bank switching
                if(_padConfigVCArray[i]?.fileLength == nil)
                {   fileDuration = _padLoader.getFileDuration(name: fileName!);  }
            }
                
            _padConfigVCArray[i]?.loadedFileName = (fileName == nil) ? "No File Loaded" : fileName!;
                
            // volume
            let volume = _padLoader.loadVolume(pad: i);
            _padConfigVCArray[i]?.volume = Double((volume == nil) ? 0.0 : volume!)
            if(volume != nil){  passVolume(pad: i, volume: Double(volume!));    }
                
            // pan
            //                let pan = _padLoader.loadPan(padNumber: i);
            //                _padConfigVCArray[i]?.pan = Double((pan == nil) ? 0.0 : pan!);
            // TODO: we don't have a ladder for the pan set up yet!!!
                
            /** band aid added on 1/8/2018 to deal with the fallout of not making an AVAudioFile every time we switch banks */
            if(_padConfigVCArray[i]?.fileLength == nil || fileDuration != 0)
            {
                // grab the loaded file's duration so we can set the range of the start and end sliders
                _padConfigVCArray[i]?.fileLength = fileDuration;
            }
                
            let triggerMode = _padLoader.loadTriggerMode(pad: i);
            // true means start/stop, false means play through
            _padConfigVCArray[i]?.startStopTriggerMode = (triggerMode == nil) ? true : triggerMode!;
            callDelegatePassTriggerMode(pad: i, mode: (triggerMode == nil) ? true : triggerMode!)
            _stackPadViewArray[i].startStopTriggerMode = (triggerMode == nil) ? true : triggerMode!
                
            // pitch
            let cent = _padLoader.loadCent(padNumber: i);
            let semitone = _padLoader.loadSemitone(pad: i);
            // adjust pitch member via public cent and semitone setters
            _padConfigVCArray[i]?.cent = (cent == nil) ? 0 : cent!;
            _padConfigVCArray[i]?.semitone = (semitone == nil) ? 0 : semitone!;
            callDelegatePassPitch(pad: i, pitch: (_padConfigVCArray[i]?.pitch)!);
        }
        
        //  5: handle start point
        for i in 0 ..<  _nPads where _padConfigVCArray[i]?.isLoaded == true
        {
            let startingPoint = _padLoader.loadStartingPoint(pad: i);
            _padConfigVCArray[i]?.startingPoint = Double((startingPoint == nil) ? 0 : startingPoint!);
                
            _opQueue.addOperation
            {
                self.callDelegatePassStartingPoint(pad: i, startingPoint: Double((startingPoint == nil) ? 0 : startingPoint!), load: true);
            }
        }
        
        //  6: handle endpoint
        for i in 0 ..<  _nPads where _padConfigVCArray[i]?.isLoaded == true
        {
            let endPoint = _padLoader.loadEndPoint(pad: i);
                
            _padConfigVCArray[i]?.endPoint = Double((endPoint == nil) ? 0.0 : endPoint!);
                
            _opQueue.addOperation
            {
                //  DEBUG: on 1/8/2018 endPoint came up nil when we tried to load the demo on song on old iPad,
                //              this does not happen consistently
                self.callDelegatePassEndPoint(pad: i, endPoint: Double((endPoint!)));
            }
        }
        _opQueue.waitUntilAllOperationsAreFinished();
    }
    
    /** If we navigate away from this VC,
     stop any pads from playing */
    private func stopAllPads()
    {
        for pad in 0 ..< _nPads
        {
            _delegate.stop(bank: _bankNumber - 1, pad: pad, preview: false);
        }
        
        if(_debugFlag){ print("stopAllPads() complete----------");   }
    }
    
    /** neccessary to resolve the corner case where the user has a pad(s) pressed down
     while simultaneously choosing an action causing this VC to dissapear.
     e.g. pressing any number of pads while choosing to move to the PadConfigVC */
    func resetPadColors()
    {
        if(_stackPadViewArray != nil)
        {
            UIApplication.shared.beginIgnoringInteractionEvents();
            if(_debugFlag){ print("resetPadColors() in BankVC began ignoring interaction events");  }
            
            _lastTouchedPadIndex = _currentlyTouchedPadIndex;
            
            for pad in 0 ..< _nPads
            {
                if(_stackPadViewArray[pad].isTouched){  self._stackPadViewArray[pad].backgroundColor = .black   }
                // DEBUG: as of 1/4/2018
                //          this else statement partially solves playthrough pads not going black when they get cancelled by another pad,
                //              with this else statement,
                //                  the playthrough pad will stay red until the other canceling pad is released..
                else
                {
                    if(!_stackPadViewArray[pad].startStopTriggerMode)
                    {   self._stackPadViewArray[pad].backgroundColor = .black   }
                }
            
                _stackPadViewArray[pad].isTouched = false;
            }
            
            UIApplication.shared.endIgnoringInteractionEvents();
            
            if(_debugFlag){ print("resetPadColors() in BankVC stopped ignoring interaction events");    }
        }
    }
    
    /** display the info screen */
    @IBAction func handleInfoButton(_ sender: UIButton)
    {
        let infoScreen =  self.storyboard?.instantiateViewController(withIdentifier: "BankInfoVC") as! BankInfoScreenViewController;
        navigationController?.pushViewController(infoScreen, animated: true);
    }
    
    /** switch to first bank */
    @IBAction func handleBankSelector1Button(_ sender: UIButton)
    {
        guard(_bankNumber != 1) else{   return; }
        
        // if we leave the VC while we were making a sequence recording...
        if(_isRecording){   toggleRecordOff();  }
        
        navigationController?.popViewController(animated: false);
        _delegate.switchBank(switchToBank: 1);
    }
    
    /** switch to second bank */
    @IBAction func handleBankSelector2Button(_ sender: UIButton)
    {
        guard(_bankNumber != 2) else{   return; }
        
        if(_isRecording){   toggleRecordOff();  }
        
        navigationController?.popViewController(animated: false);
        _delegate.switchBank(switchToBank: 2);
    }
    
    /** switch to third bank */
    @IBAction func handleBankSelector3Button(_ sender: UIButton)
    {
        guard(_bankNumber != 3) else{   return; }
        
        if(_isRecording){   toggleRecordOff();  }
        
        navigationController?.popViewController(animated: false);
        _delegate.switchBank(switchToBank: 3);
    }
    
    /** move back to the samplerConfigVC if swipe originates from one of the bank buttons */
    @objc func handleBackToSamplerConfigSwipeGestureRecognizer(){   navigationController?.popViewController(animated: true);    }
    
    /** move to the selected pad's configVC */
    private func handleConfigButton(_ sender: UIButton)
    {
        if(_padConfigVCArray[_currentlyTouchedPadIndex] == nil)
        {
            _padConfigVCArray[_currentlyTouchedPadIndex] = self.storyboard?.instantiateViewController(withIdentifier: "PadConfig") as? PadConfigViewControler;
        }
        
        _padConfigVCArray[_currentlyTouchedPadIndex]?.padNumber = _currentlyTouchedPadIndex;
        _padConfigVCArray[_currentlyTouchedPadIndex]?._delegate = self;
        
        _padConfigVCArray[_currentlyTouchedPadIndex]?.songName = _songName;
        _padConfigVCArray[_currentlyTouchedPadIndex]?.songNumber = _songNumber;
        _padConfigVCArray[_currentlyTouchedPadIndex]?.bankNumber = _bankNumber;
        _padConfigVCArray[_currentlyTouchedPadIndex]?.isConnected = _isConnected;
        
        //  set _isPartOfSequence
        _padConfigVCArray[_currentlyTouchedPadIndex]?.isPartOfSequence = checkIfPadConfigVCIsPartOfSequence(index: _currentlyTouchedPadIndex)
        
        // pan gesture recognizer will call this method any number of times per pinch.
        //  if we try to push the desired padConfigVC while it is visible we get a run time error.
        //  https://stackoverflow.com/questions/37829721/pushing-view-controller-twice
        if(navigationController?.topViewController != _padConfigVCArray[_currentlyTouchedPadIndex])
        {
            //  TODO: this is a very, very un snazzy way of doing things...
            if(sender.tag == -654)
            {   navigationController?.pushViewController(_padConfigVCArray[_currentlyTouchedPadIndex]!, animated: false);   }
            else{   navigationController?.pushViewController(_padConfigVCArray[_currentlyTouchedPadIndex]!, animated: true);    }
        }
    }
    
    /** before pushing recently initialized padConfigVC,
         check to see if its corresponding pad is part of the recorded sequence */
    private func checkIfPadConfigVCIsPartOfSequence(index: Int) -> Bool
    {
        guard(_seqRecordArray != nil)   else{   return false;    }
        guard(_seqRecordArray.count > 0)    else{   return false;   }
        
        for i in 0 ..< _seqRecordArray.count
        {
            if(_seqRecordArray[i] == index){    return true;    }
        }
        return false;
    }
    
    /** Toggle record mode.
            On: record a sequence of pad touches
            Off: save recorded sequence */
    @IBAction func handleRecordButtonUp(_ sender: UIButton)
    {
        // if we are toggling recording on....
        if(!_isRecording)
        {
            storeSequenceArray();

            // if there is a recorded sequence present,
            //      alert user of potential overwrite
            if(_seqRecordArray.count > 0){  handleRecordOverwrite();    }
            // else if there is not a recorded sequence present..
            else
            {
                toggleRecordModeOn();
                _seqRecordArray = [];
                _forwardButton.backgroundColor = .gray;
            }
        }
            //else if we are toggling recording off..
        else{   toggleRecordOff();  }
        
        stopAllPads();
        cancelPlayThrough();
    }
    
    private func toggleRecordOff()
    {
        _isRecording = false;
        
        //  if there was a sequence recorded
        if(_seqRecordArray.count > 0)
        {
            saveSequenceAndStopRecording();
            alertRecordingWasSaved();
        }
        // if no sequence was recorded
        else
        {
            retreiveSequenceArray();
            alertNoSequenceWasSaved();
        }
    }
    
    private func storeSequenceArray()
    {
        _oldSeqRecordArray = [];
        
        for note in 0 ..< _seqRecordArray.count
        {
            _oldSeqRecordArray.append(_seqRecordArray[note]);
        }
    }
    
    private func retreiveSequenceArray()
    {
        for note in 0 ..< _oldSeqRecordArray.count
        {
            _seqRecordArray.append(_oldSeqRecordArray[note]);
        }
        
        if(_seqRecordArray.count > 0) // Duplicate
        {
            _forwardButton.backgroundColor = .yellow; // Duplicate
        }
        else
        {
            _forwardButton.backgroundColor = .gray; // Duplicate
        }
    }
    
    /** ask the user if they wants to overwrite an existing recorded play sequence */
    private func handleRecordOverwrite()
    {
        var overwriteAlertController = UIAlertController(title: "Sequence Exists", message: "Do You Want To Overwrite the Existing Sequence?",  preferredStyle: .alert);
        
        let overWriteAction = UIAlertAction(title: "Overwrite", style: .destructive,
                                            handler: {[weak self](paramAction:UIAlertAction!) in
                                                
                                                self?.toggleRecordModeOn();
                                                self?._seqRecordArray = [];
                                                self?._forwardButton.backgroundColor = .gray;
                                                self?.resetPadConfigsIsPartOfSequence();
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel,
                                         handler: {[weak self](paramAction:UIAlertAction!) in
                                            return;
        })
        
        overwriteAlertController.addAction(overWriteAction);
        overwriteAlertController.addAction(cancelAction);
        self.present(overwriteAlertController, animated: true, completion: nil)
    }
    
    /** reset each padConfigVc's _isPartOfSequence flag to false */
    private func resetPadConfigsIsPartOfSequence()
    {
        for i in 0 ..< _padConfigVCArray.count
        {
            _padConfigVCArray[i]?.isPartOfSequence = false;
        }
    }
    
    /** alert the user that a sequence recording was saved */
    private func alertRecordingWasSaved()
    {
        let savedAlertController = UIAlertController(title: "Saved", message: "Your Play Sequence Was Saved", preferredStyle: .alert);
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil);
        savedAlertController.addAction(okAction);
        navigationController?.present(savedAlertController, animated: true, completion: nil);
    }
    
    private func alertNoSequenceWasSaved()
    {
        let noSequenceRecordedAlert = UIAlertController(title: "No Recording", message: "No Sequence Was Recorded, Would You Like To Clear The Current Sequence?", preferredStyle: .alert);
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        let clearAction = UIAlertAction(title: "Clear", style: .destructive, handler:
        {
            (action:UIAlertAction)
            in
                self.clearSequence();
        })
        
        noSequenceRecordedAlert.addAction(cancelAction);
        noSequenceRecordedAlert.addAction(clearAction);
        
        navigationController?.present(noSequenceRecordedAlert, animated: true, completion:
        {   self._recordButtonCircle.backgroundColor = .gray;   });
    }
    
    private func toggleRecordModeOn()
    {
        _isRecording = true;
        _recordButtonCircle.backgroundColor = .red;
    }
    
    /** move to the sequencePlayVC if a pad sequence has been recorded */
    @IBAction func handleForwardButton(_ sender: UIButton)
    {
        guard(_seqRecordArray.count > 0) else{  return; }
        
        saveSequenceAndStopRecording();
            
        if(_sequencePlayVC == nil)
        {
            _sequencePlayVC = self.storyboard?.instantiateViewController(withIdentifier: "SequenceVC") as! SequencePlayViewController;
            _sequencePlayVC.songName = _songName;
            _sequencePlayVC.bankNumber = _bankNumber;
            _sequencePlayVC._delegate = self;
        }
            
        navigationController?.pushViewController(_sequencePlayVC, animated: true);
    }//------------------------- end of Side bar button handlers --------------------------------------------
    
    /** Reset record button.
             Save the recorded sequence to disk.
         This method also sets all the padConfgVCs whose corresponding pad is part of the sequence _isPartOfSequence flag to true.*/
    private func saveSequenceAndStopRecording()
    {
        _recordButtonCircle.backgroundColor = .gray;
        
        // save the recorded sequence to disk
        if(!_sequenceSaver.saveSequence(songName: _songName, bank: _bankNumber, nSeqNotes: _seqRecordArray.count, sequence: _seqRecordArray))
        {
            if(_debugFlag){ print("in BankVC saving the recorded sequence to disk returned false"); }
        }
        
        // also set all padConfigVC's _isPartOfSequence members to true for all notes that are in the sequence
        setPadConfigVCsIsPartOfSequence();
    }
    
    /** This method also sets all the padConfgVCs whose corresponding pad is part of the sequence _isPartOfSequence flag to true. */
    private func setPadConfigVCsIsPartOfSequence()
    {
        for i in 0 ..< _seqRecordArray.count
        {
            _padConfigVCArray[_seqRecordArray[i]]?.isPartOfSequence = true;
        }
    }

    func isRecordingTakingPlace() -> Bool
    {
        var ret = false;

        if(_padConfigVCArray != nil)
        {
            if(_padConfigVCArray.count != 0)
            {
                for pad in 0 ..< _nPads where _padConfigVCArray[pad] != nil
                {
                    if(_padConfigVCArray[pad]?.isRecordingTakingPlace())!
                    {
                        ret = true;
                        break;
                    }
                }
            }
        }

        return ret;
    }
    
    /** set the isLoading flag in the file selector cell with the corresponding index back to false after a file is loaded into a padModel
            not exactly sure why we are doing this,
                it seems to have something to do with the app moving to and from the background*/
    func resetFileSelectorCellIsLoading(pad: Int, section: Int, row: Int)
    {
        if(_padConfigVCArray[pad] != nil)
        {   _padConfigVCArray[pad]?.resetFileSelectorCellIsLoading(section: section, row: row); }
    }
    
    /** reset any untouched playthrough pads background colors to black */
    private func resetPlaythroughPadColors()
    {
        for pad in 0 ..< _nPads where !_stackPadViewArray[pad].startStopTriggerMode
        {
            if(!_stackPadViewArray[pad].isTouched){ _stackPadViewArray[pad].backgroundColor = .black;   }
        }
    }
    
    /** this method is an attempt to eliminate a call to the AVAudioFile init in the PadLoader's getFileDuration() Method,
            This method is called in the Song's passSelectedFileToMasterSoundMod() method
     it would be nice to have this in place by the release,
     but it might cause more problems than it is worth */
//    func passFileDurationBackToView(pad: Int, duration: Double)
//    {
//        if(_padConfigVCArray.count != 0)
//        {
//            if(_padConfigVCArray[pad] != nil)
//            {
//                _padConfigVCArray[pad]?.passFileDurationBackToView(duration: duration);
//            }
//        }
//    }
    
    /** send play call up the class hierarchy,
     send play signal to host if this song is connected to host(currently depricated)
     and adjust the UI accordingly. */
    internal func delegatePadTouchDown(number: Int, isLoaded: Bool, sequenceTouch: Bool)
    {
        _delegate.play(bank: _bankNumber - 1, pad: number, preview: false, sequenceTouch: sequenceTouch); /** added sequence touch arg on 1/7/2018*/
        
        //don't updata BankVC if the SequenceVC is responsible for the sound */
        if(sequenceTouch){  return  }
        
        if(_isRecording)
        {
            _seqRecordArray.append(number);
            
            if(_forwardButton.backgroundColor != .yellow){  _forwardButton.backgroundColor = .yellow;   }
        }
        
        _lastTouchedPadIndex = _currentlyTouchedPadIndex;
        _currentlyTouchedPadIndex = number;
        
        //  DEBUG: this assignment is vunerable to corruption if the user spastically pressses pads...
        _numberOfCurrentlyTouchedPads += 1;
        
        if(_lastTouchedPadIndex != _currentlyTouchedPadIndex && _numberOfCurrentlyTouchedPads == 1)
        {   _stackPadViewArray[_lastTouchedPadIndex].backgroundColor = .black;  }
        
        _stackPadViewArray[number].touchIndex = _numberOfCurrentlyTouchedPads;
    }
    
    /** send stop call up the class hierarchy,
     send stop signal to host if this song is connected to host
     and adjust the UI accordingly */
    internal func delegatePadTouchUp(number: Int, isLoaded: Bool, sequenceTouch: Bool)
    {
        // if the pad is not nil
        if(_padConfigVCArray[number] != nil)
        {
            if(isLoaded)
            {
                // pass stop play signal on up the class hierarchy
                _delegate.stop(bank: _bankNumber - 1, pad: number, preview: false);
            }
        }
        
        _stackPadViewArray[_currentlyTouchedPadIndex].backgroundColor = .black;
        
        if(number != _currentlyTouchedPadIndex){    _stackPadViewArray[number].backgroundColor = .black; }
        
        //  DEBUG: this assignment is vunerable to corruption if the user spastically pressses pads,
        //          I'm not sure how to remedy this.....
        //           This might be an angle:
        //              http://en.swifter.tips/lock/
        //                      sceptical....
        //           I think an array of some sort would work best,
        _numberOfCurrentlyTouchedPads -= 1;
        
        _stackPadViewArray[number].touchIndex = 0;

        if(_numberOfCurrentlyTouchedPads == 0)
        {
            if(!sequenceTouch){ resetPadColors();   }
        }
    }
        
    /** --------------------------  SPAGHETTI ALERT -----------------------------------------------
     because of the abhorrent design decision by the person who wrote this code --
     myself,
     michael fleming
     --  to not have member _bankNumbers be Zero indexed,
     any _bankNumber passed to any of these Pass methods needs to be - 1
         whithout a doubt,
             this was the worst design decision for the entire app....
     -----------------------------------------------------------------------------------------*/
    /** this method is called regardless of whether a file is being loaded from disk for a song load,
             if the User selected a file from the fileSelectorVC,
                 or if the user has recorded a sound into a pad.
             If this method is called as result of a song load this method is called on a seperate thread.*/
    func callDelegatePassSelectedFile(file: URL, pad: Int, section: Int, row: Int)
    {   _delegate.passSelectedFileToMasterSoundMod(file: file, bank: bankNumber - 1, pad: pad, section: section, row: row); }
    func callDelegateConnectLoadedPadToMixer(pad: Int)
    {
        _delegate.sendConnectLoadedPadToMixer(bank: _bankNumber - 1, pad: pad);
        _isLoaded = true;
    }
    func callDelegateResetSoundMod(){   _delegate.sendResetSoundMod();  }
    func callDelegatePassStartingPoint(pad: Int, startingPoint: Double, load: Bool)
    {   _delegate.setStartingPoint(bank: bankNumber - 1, pad: pad, startingPoint: startingPoint, load: load); }
    func callDelegatePassEndPoint(pad: Int, endPoint: Double)
    {   _delegate.setEndPoint(bank: bankNumber - 1, pad: pad, endPoint: endPoint);    }
    func callDelegatePassTriggerMode(pad: Int, mode: Bool)
    {   _delegate.setTriggerMode(bank: bankNumber - 1, pad: pad, triggerMode: mode);   }
    func callDelegatePassPitch(pad: Int, pitch: Float)
    {   _delegate.setPitch(bank: bankNumber - 1, pad: pad, pitch: pitch); }
    func callDelegateStartMasterSoundMod(){ _delegate.startMasterSoundMod();    }
    func callDelegateStopMasterSoundMod(){  _delegate.stopMasterSoundMod(); }
}

/** extension for Pad */
extension BankViewStackController: ParentPadViewProtocol
{
    internal func padTouchDown(number: Int, isLoaded: Bool)
    {
        delegatePadTouchDown(number: number, isLoaded: isLoaded, sequenceTouch: false);
        resetPlaythroughPadColors();
    }
    
    internal func padTouchUp(number: Int, isLoaded: Bool){  delegatePadTouchUp(number: number, isLoaded: isLoaded, sequenceTouch: false); }
    /** bad things happen if you try to put down 6 touches at the same time,
     for now if a sixth touch is down we just stop everything */
    func sixthTouch(number: Int, isLoaded: Bool)
    {
        for i in 0 ..< _stackPadViewArray.count
        {
            _stackPadViewArray[i].backgroundColor = .black;
        }
            
        _numberOfCurrentlyTouchedPads = 0;
    }
    
    func panMoveToPadConfig(number: Int){   handleConfigButton(UIButton()); }
    func passResetPadColors(){  resetPadColors();   }
}

/** extension for PadConfigVC */
extension BankViewStackController: PadConfigVCParentProtocol
{
    internal func passSelectedFile(file: URL, pad: Int, section: Int, row: Int)
    {   callDelegatePassSelectedFile(file: file, pad: pad, section: section, row: row); }
    func sendConnectPadToMixer(pad: Int)
    {
        _delegate.sendConnectPadToMixer(bank: _bankNumber - 1, pad: pad);
        
        _stackPadViewArray[pad].isLoaded = true;
        
        // this call will only happen if the user,
        //  at some point in time choses to load a sound into the bank.
        _isLoaded = true;
    }
    func sendDetachPad(pad: Int, erase: Bool)
    {   _delegate.sendDetachPad(bank: _bankNumber - 1, pad: pad, erase: erase);   }
    internal func preview(pad: Int)
    {   _delegate.play(bank: _bankNumber - 1, pad: pad, preview: true, sequenceTouch: false);   }
    internal func passVolume(pad: Int, volume: Double)
    {   _delegate.setVolume(bank: bankNumber - 1, pad: pad, volume: volume);  }
    internal func passStartingPoint(pad: Int, startPoint: Double, load: Bool)
    {   callDelegatePassStartingPoint(pad: pad,  startingPoint: startPoint, load: load);    }
    internal func passEndPoint(pad: Int, endPoint: Double){   callDelegatePassEndPoint(pad: pad, endPoint: endPoint); }
    func passTriggerMode(pad: Int, mode: Bool){    callDelegatePassTriggerMode(pad: pad, mode: mode);    }
    func passPitch(pad: Int, pitch: Float){   callDelegatePassPitch(pad: pad, pitch: pitch);  }
    func startMasterSoundMod(){   _delegate.startMasterSoundMod();  }
    func stopMasterSoundMod(){  _delegate.stopMasterSoundMod(); }
    func sendVolume(pad: Int, volume: Double)
    {   _delegate.sendVolume(bank: _bankNumber, pad: pad, volume: volume);    }
    func sendStartingPoint(pad: Int, startingPoint: Double)
    {   _delegate.sendStartingPoint(bank: _bankNumber, pad: pad, startingPoint: startingPoint);   }
    func sendEndPoint(pad: Int, endPoint: Double)
    {   _delegate.sendEndPoint(bank: _bankNumber, pad: pad, endPoint: endPoint);  }
    func sendTriggerMode(pad: Int, triggerMode: Bool)
    {
        _delegate.sendTriggerMode(bank: _bankNumber, pad: pad, triggerMode: triggerMode);
        _stackPadViewArray[pad].startStopTriggerMode = triggerMode;
    }
    func passLoadFlag(load: Bool, pad: Int){   _delegate.passLoad(load: load, bank: _bankNumber, pad: pad); }
    func sendIsRecording(isRecording: Bool, pad: Int)
    {
        if(isRecording){   _delegate.sendIsRecording(isRecording: isRecording, bank: _bankNumber, pad: pad); }
        else{   _delegate.sendIsRecording(isRecording: isRecording, bank: -1, pad: pad);  }
    }
    func swipePreviousPadConfigVC(pad: Int)
    {
        if(pad != 0)
        {
            _lastTouchedPadIndex = pad;
            _currentlyTouchedPadIndex = pad - 1;
        
            _stackPadViewArray[pad].backgroundColor = .black;
            
            navigationController?.popViewController(animated: false);
    
            let someButton = UIButton();
            someButton.tag = -666;
            handleConfigButton(someButton);
        }
    }
    
    func swipeNextPadConfigVC(pad: Int)
    {
        if(pad != _nPads - 1)
        {
            _lastTouchedPadIndex = pad;
            _currentlyTouchedPadIndex = pad + 1;
        
            _stackPadViewArray[pad].backgroundColor = .black;
            
            navigationController?.popViewController(animated: false);
    
            let someButton = UIButton();
            someButton.tag = -666;
            handleConfigButton(someButton);
        }
    }
    
    func passInvalidateFadeOutTimers(){ _delegate.passInvalidateFadeOutTimers(); }
    func passEraseFile(file: URL) { _delegate.passEraseFile(file: file); }
    func cancelPreview(pad: Int){   _delegate.cancelPreview(bank: _bankNumber - 1, pad: pad);   }
    func clearSequence()
    {
        resetPadConfigsIsPartOfSequence();
        _seqRecordArray = [];
        _forwardButton.backgroundColor = .gray;
        var _ = _sequenceSaver.saveSequence(songName: _songName, bank: _bankNumber, nSeqNotes: 0, sequence: []);
    }
    
    func resetPadViewIsLoaded(pad: Int){    _stackPadViewArray[pad].isLoaded = false;   }
}

/** extension for SequencePlayVC */
extension BankViewStackController: SequencePlayParentProtocol
{
    internal func sequenceTouch(pad: Int)
    {
        // impossible to trigger an unloaded pad from the SequenceVC
        delegatePadTouchDown(number: pad, isLoaded: true, sequenceTouch: true);
    }
    internal func sequenceStop(pad: Int)
    {
        // impossible to stop an unloaded pad from the SequenceVC
        delegatePadTouchUp(number: pad, isLoaded: true, sequenceTouch: true);
    }
    func switchSequenceBank(bank: Int){ _delegate.switchSequenceBank(bank: bank);   }
    func sequenceStopAllPads() {    stopAllPads();   }
    func cancelPlayThrough(){   _delegate.cancelPlayThrough(bank: _bankNumber); }
}
