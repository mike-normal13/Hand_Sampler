//
//  PadConfigViewController.swift
//  Sampler_App
//
//  Created by mike on 2/27/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

//  TODO:
//     PadConfigVC -> CallDelegatePassSelectedFile
//          this method makes an AVAudioFile,
//              can we avoid doing this.....?
//  TODO:
//        FileSelectorTVC -> GetFileDuration
//          this method makes an AVAudioFile,
//              can we avoid doing this.....?
//                      have the PadModel pass the Duration back once it makes its AVAudioFile......
//  19: PadConfigVC
//          Next time see if the memory leak accounts for an entire audio file
//          when we repeatedly load and then clear,
//              the memory usage inches up and up,
//                  there is no drop in memory when we clear a pad.
//          on 12/29/2017 we repeated cleared a pad with the sound bird.wav,
//              each time we seem to be accumulating about 1 mb
//          on 1/2/2018 we kept loading a file of 32 MB,
//              we saw a leak of about 1 MB per...
//          on 1/4/2018 we did some work with some deintis,
//              did not make a difference.
//  DEBUG:  1/19/2018
//              rotated view is not acceptable
//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

import UIKit
import AVFoundation

protocol PitchVCParentProtocol: class
{
    func passPitchPreview()
    func dismissPitchVC();
    func passSemitones(tones: Int);
    func passCents(cents: Float);
}

protocol EndPointsVCParentProtocol: class
{
    func passStartPoint(start: Double);
    func passEndPoint(end: Double);
    func passEndPointsPreview();
    func dismissEndPointsVC();
    func cancelEndPointPreview();
    func presentInfoScreen();
}

protocol VolumeContainerViewParentProtocol: class
{   func present(id: String);   }

protocol VolumeVCParentProtocol: class
{
    func passVolume(volume: Float)
    func passVolumePreview();
    func dismissVolumeVC();
}

protocol RecordVCParentProtocol: class
{
    func passRecordedFile(file: URL, pad: Int, fileName: String);
    func sendConnectRecordedPadToMixer(pad: Int);
    func startMasterSoundMod();
    func stopMasterSoundMod();
    func setRecordedSoundIsLoaded(isLoaded: Bool);
    func setRecordedSoundEndPointToFileDuration(duration: Float);
    func sendRecordDetachPad(pad: Int, erase: Bool);
    func sendRecordedInitialStartingPointToPadModel(pad: Int);
    func sendRecordedInitialEndPointToPadModel(pad: Int, endPoint: Double);
    func sendIsRecording(isRecording: Bool);
    /** this method ends up calling the cancelPlayThrough() method in Song */
    func recordCancelPreview();
}

protocol FileSelectorTVCParentProtocol: class
{
    /** once a file is selected for a pad,
            pass info up to the sound mod */
    func passSelectedFile(file: URL, pad: Int, section: Int, row: Int);
    func sendConnectSelectedPadToMixer(pad: Int);
    func setChosenSoundIsLoaded(isLoaded: Bool);
    func setChosenSoundEndPointToFileDuration(duration: Float);
    func sendSelectDetachPad(padNumber: Int, erase: Bool);
    func sendInitialStartingPointToPadModel(pad: Int);
    func sendInitialEndPointToPadModel(pad: Int, endpoint: Double)
    func dismissFileSelectorVC();
    func passEraseFile(file: URL);
    /** this method ends up calling the cancelPlayThrough() method in Song */
    func selectorCancelPreview();
}

/** responsible for letting the user configure settings for a pad,
        also lets the user choose to either load or record a sound into the pad */
class PadConfigViewControler: SamplerVC
{
    private let _debugFlag = true;
    
    @IBOutlet weak var _fileContainerView: UIView!
    @IBOutlet weak var _settingsContainerView: UIView!
    
    /** clear the pad of any loaded sounds and reset UI to all default settings */
    @IBOutlet weak var _clearButton: UIButton!
    /** move to the RecordVC */
    @IBOutlet weak var _recordButton: UIButton!
    
    @IBOutlet weak var _volumeContainerView: PadConfigControlView!
    @IBOutlet weak var _endPointsContainerView: PadConfigControlView!;
    @IBOutlet weak var _pitchContainerView: PadConfigControlView!;
    
    /** displays the name of the file loaded into the pad that owns this VC, 
            also plays the current configuration of the sound by pressing the button. */
    @IBOutlet weak var _fileNameButton: UIButton!
    
    /** pushes a file chooser menu so the user can choose the file to load into the pad */
    @IBOutlet weak var _fileLoadButton: UIButton!
    
    @IBOutlet weak var _volumeLabel: UILabel!
    @IBOutlet weak var _volumeValueLable: UILabel!
    @IBOutlet weak var _dbLabel: UILabel!
    
    //  TODO: pan control makes sense if we have stereo output,
    //          e.g. headphones, bluetooth, airplay...
//    @IBOutlet weak var _panContainerView: UIView!
//    @IBOutlet weak var _panValueLabel: UILabel!
    
    @IBOutlet weak var _startLabel: UILabel!
    @IBOutlet weak var _startingPointValueLabel: UILabel!
    
    @IBOutlet weak var _endLabel: UILabel!
    @IBOutlet weak var _endingPointValueLabel: UILabel!
    
    @IBOutlet weak var _triggerModeContainerView: UIView!
    @IBOutlet weak var _triggerModeLabel: UILabel!
    @IBOutlet weak var _startStopTriggerModeButton: UIButton!
    @IBOutlet weak var _playThroughTriggerModeButton: UIButton!
    
    @IBOutlet weak var _pitchLabel: UILabel!
    @IBOutlet weak var _pitchSemiToneValueLavel: UILabel!
    @IBOutlet weak var _pitchCentValueLavel: UILabel!
    
    override var songNumber: Int
    {
        get{    return _songNumber; }
        set
        {
            _songNumber = newValue;
            if(_recordVC != nil){   _recordVC.songNumber = _songNumber; }
        }
    }
    
    private var _volume: Double = 0.0;
    var volume: Double
    {
        get{    return _volume; }
        set{    _volume = newValue; }
    }

    //  TODO: have to write the host first!
//    private var _pan: Double = 1;
//    var pan: Double
//    {
//        get{    return _pan;    }
//        set{    _pan = newValue;    }
//    }
    
    /** where in the file playback begins */
    private var _startingPoint: Double = 0;
    var startingPoint: Double
    {
        get{    return _startingPoint;  }
        set{    _startingPoint = newValue;  }
    }
    
    /** where in the file playback ends */
    private var _endPoint: Double = 0;
    var endPoint: Double
    {
        get{    return _endPoint;   }
        set{    _endPoint = newValue;   }
    }
    
    private var _numberFormatter: NumberFormatter! = nil;
    
    /** we need this value in order to set the max and min values for the the start/end point sliders */
    private var _fileLength: Double! = nil;
    var fileLength: Double!                  /** added optional to public on 1/7/2018 */
    {
        get{    return _fileLength; }
        set{    _fileLength = newValue; }
    }
    
    /** if this is set to false,
     Play Through trigger mode is selected.
     Start/Stop trigger mode means the sound stops as soon as touch up occurs
     Play Through tirgger mode means touch up does not stop the sound from playing,
     the sound sill stop playing when it reaches the end of the file or the end point,
     whichever happens first */
    private var _startStopTriggerMode: Bool = true;
    var startStopTriggerMode: Bool
    {
        get{    return _startStopTriggerMode;   }
        set{    _startStopTriggerMode = newValue;   }
    }
    
    /** any given sound can be raised in pitch by a maximum of 48 semitones - 4 octaves */
    private let _semitoneMax = 48;
    /** any given sound can be lowered in pitch by a maximum of 48 semitones - 4 octaves */
    private let _semitoneMin = -48;
    
    /** any given sound can be raised in pitch by a maximum of 100 cent increments */
    private let _centMax: Float = 0.99;
    /** any given sound can be lowered in pitch by a maximum of 100 cent decrements */
    private let _centMin: Float = -0.99;
    
    /** pitch semitone value */
    private var _semitone: Int = 0;
    var semitone: Int
    {
        get{    return _semitone;   }
        set
        {
            _semitone = newValue;
            _pitch = Float(_semitone) + _cent;
        }
    }
    
    /** pitch cent value */
    private var _cent: Float = 0;
    var cent: Float
    {
        get{    return _cent;   }
        set
        {
            _cent = newValue;
            _pitch = Float(_semitone) + _cent;
        }
    }
    
    /** the pitch current sound.
            this value is a combination of the current semiton and pitch values*/
    private var _pitch: Float = 0;
    var pitch: Float{   get{    return _pitch;  }   }
    
    private var _pitchNumberFormatter: NumberFormatter! = nil;
    
    private var _fileSelectorTVC: FileSelectorTableViewController! = nil;
 
    /** this needs to be a member so we can check for is recording taking place */
    private var _recordVC: RecordViewController! = nil;
    var recordVC: RecordViewController!{    get{    return _recordVC;   }   }
    
    weak var _delegate: PadConfigVCParentProtocol! = nil;
    
    /** reflects whether the pad has a sound loaded */
    private var _isLoaded: Bool = false;
    var isLoaded: Bool
    {
        get{    return _isLoaded;   }
        set{    _isLoaded = newValue;   }
    }
    
    /** name of the file which is loaded into this pad */
    private var _loadedFileName: String = "";
    var loadedFileName: String
    {
        get{    return _loadedFileName; }
        set{    _loadedFileName = newValue; }
    }
    
    /** saves state of pad to disk */
    private var _padSaver: PadSaver! = nil;
    var padSaver: PadSaver
    {
        get{    return _padSaver;   }
        set{    _padSaver = newValue;   }
    }
    
    /** used only to erase pads via the clear button */
    private lazy var _padEraser: Eraser! = Eraser();
    
    /** reflects whether the pad corresponding to this VC is part of a recorded sequence. */
    private var _isPartOfSequence = false;
    var isPartOfSequence: Bool
    {
        get{    return _isPartOfSequence;   }
        set{    _isPartOfSequence = newValue;   }
    }
    
    private enum _SubVCs: String
    {
        case file = "file";         // this value might not ever be used...
        case record = "record";     // this value might not ever be used...
        case volume = "volume";
        case endpoints = "endpoints";
        case pitch = "pitch";
    }
    
    /** indicates which VC presented by this VC is visible,
         if this VC is visible value is "" */
    private var _visibleSubVC = "";
    var visibleSubVC: String{   return _visibleSubVC;   }
    
    /** swipe to the previous padConfigVC */
    private var _previousPanGestureRecognizer: UIScreenEdgePanGestureRecognizer! = nil;
    /** swipe to the next padConfigVC */
    private var _nextPanGestureRecognizer: UIScreenEdgePanGestureRecognizer! = nil;
    
    override func loadView()
    {
        super.loadView();
        
        navigationItem.setRightBarButton(UIBarButtonItem(title: "?", style: .plain, target: self, action: #selector(handleNavBarInfoButton)), animated: false);
        
        _numberFormatter = NumberFormatter();
        _numberFormatter.numberStyle = .decimal;
        _numberFormatter.minimumFractionDigits = 2;
        _numberFormatter.maximumFractionDigits = 2;
        
        _pitchNumberFormatter = NumberFormatter();
        _pitchNumberFormatter.numberStyle = .decimal;
        _pitchNumberFormatter.minimumFractionDigits = 0;
        _pitchNumberFormatter.maximumFractionDigits = 0;
        
        _previousPanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePreviousSwipe));
        _previousPanGestureRecognizer.edges = .left;
        
        _nextPanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleNextSwipe));
        _nextPanGestureRecognizer.edges = .right;
    
        view.addGestureRecognizer(_previousPanGestureRecognizer);
        view.addGestureRecognizer(_nextPanGestureRecognizer);
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
        
        _volumeContainerView.layer.cornerRadius = 5;
        _volumeLabel.adjustsFontSizeToFitWidth = true;
        _volumeValueLable.adjustsFontSizeToFitWidth = true;
        _dbLabel.adjustsFontSizeToFitWidth = true;
        _volumeContainerView.id = "volume";
        _volumeContainerView._delegate = self;
        
        _settingsContainerView.layer.cornerRadius = 5;
       
        _endPointsContainerView.id = "endPoints";
        _startLabel.adjustsFontSizeToFitWidth = true;
        _startingPointValueLabel.adjustsFontSizeToFitWidth = true;
        _endLabel.adjustsFontSizeToFitWidth = true;
        _endingPointValueLabel.adjustsFontSizeToFitWidth = true;
        _endPointsContainerView._delegate = self;
        _endPointsContainerView.layer.cornerRadius = 5;
        
        _triggerModeContainerView.layer.cornerRadius = 5;
        
        _pitchContainerView.id = "pitch";
        _pitchLabel.adjustsFontSizeToFitWidth = true;
        _pitchSemiToneValueLavel.adjustsFontSizeToFitWidth = true;
        _pitchCentValueLavel.adjustsFontSizeToFitWidth = true;
        _pitchContainerView._delegate = self;
        _pitchContainerView.layer.cornerRadius = 5;
        
        _triggerModeLabel.adjustsFontSizeToFitWidth = true
        _startStopTriggerModeButton.layer.cornerRadius = 5;
        _startStopTriggerModeButton.titleLabel?.adjustsFontSizeToFitWidth = true;
        _playThroughTriggerModeButton.layer.cornerRadius = 5;
        _playThroughTriggerModeButton.titleLabel?.adjustsFontSizeToFitWidth = true;
        
        _padSaver = PadSaver(songName: _songName, songNumber: _songNumber, bankNumber: _bankNumber, padNumber: _padNumber);
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        navigationController?.isNavigationBarHidden = false;
        navigationController?.navigationBar.topItem?.title = "Pad " + (_padNumber + 1).description;
        
        UIApplication.shared.isIdleTimerDisabled = false;
        
        _isVisible = true;
        
        toggleSettingsControlActivation(activate: _isLoaded);
        
        // set file name label
        if(_fileSelectorTVC == nil || _fileSelectorTVC.chosenSoundName == nil)
        {   _fileNameButton.setTitle("No Sound Loaded", for: .normal);  }
        else{   _fileNameButton.setTitle(_fileSelectorTVC.chosenSoundName, for: .normal);   }
        
        // we instantiate the fileSelectorVC when the Load button is pressed,
        //          we deinit whenever this VC will appear.
        _fileSelectorTVC = nil;
        
        if(_isLoaded)
        {
            _fileNameButton.setTitle(_loadedFileName, for: .normal)
            _volumeValueLable.text = _numberFormatter.string(from: NSNumber(floatLiteral: _volume))!;
           _startingPointValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _startingPoint))! + " s";
            _endingPointValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _endPoint))! + " s";
            
            _startStopTriggerModeButton.backgroundColor = _startStopTriggerMode ? .yellow : .black;
            _startStopTriggerModeButton.setTitleColor(_startStopTriggerMode ? .black : .yellow, for: .normal);
            
            _playThroughTriggerModeButton.backgroundColor = !_startStopTriggerMode ? .yellow : .black;
            _playThroughTriggerModeButton.setTitleColor(!_startStopTriggerMode ? .black : .yellow, for: .normal);
            
            _pitchSemiToneValueLavel.text = (_semitone > 0) ? ("+" + _semitone.description + " st") : (_semitone.description + " st");
            _pitchCentValueLavel.text = (_cent > 0) ? ("+" + (Int(_cent * 100)).description + " ct") : (Int(_cent * 100).description + " ct");
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        // don't do this any earlier...
        //  Make it so we can't swipe back to the BankVC from this VC.
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false;
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        _isVisible = false;
        // if the view dissapears while previewing is taking place,
        //      make sure no fade out timers are not left hanging...
        _delegate.passInvalidateFadeOutTimers();
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        //  don't do this any earlier...
        //      make it so we can swipe back to this VC from the RecordVC or the FileSelectorVC
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true;
    }
    
    deinit
    {
        _numberFormatter = nil;
        _pitchNumberFormatter = nil;
        _fileSelectorTVC = nil;
        _recordVC = nil;
        _delegate = nil;
        _padSaver = nil;
        _padEraser = nil;
        _previousPanGestureRecognizer = nil;
        _nextPanGestureRecognizer = nil;
        
        if(_debugFlag){ print("***PadConfigVC deinitialized");  }
    }
    
    /** move to info screen */
    @objc func handleNavBarInfoButton()
    {
        let infoScreen = self.storyboard?.instantiateViewController(withIdentifier: "PadConfigInfoVC") as! PadConfigInfoScreenViewController;
        navigationController?.pushViewController(infoScreen, animated: true);
    }
    
    /** move to previous pad in bank padConfig */
    @objc func handlePreviousSwipe()
    {
        _delegate.swipePreviousPadConfigVC(pad: _padNumber);
        _delegate.cancelPreview(pad: _padNumber);
    }
    
    /** move to next pad in bank padConfig */
    @objc func handleNextSwipe()
    {
        _delegate.swipeNextPadConfigVC(pad: _padNumber);
        _delegate.cancelPreview(pad: _padNumber);
    }
    
    /** play the current configuration of the loaded sound */
    @IBAction func handleFileNameButton(_ sender: UIButton)
    {   if(!_routeIsChanging && _isLoaded){ _delegate.preview(pad: _padNumber); }   }
    
    /** pushes a file chooser menu enabling the user to choose the file to load into this pad */
    @IBAction func handleFileLoadButton(_ sender: UIButton)
    {
        if(_songName == _demoSongName)
        {
            if(_bankNumber == 1)
            {
                noDemoPadChangeAlert(action: "load");
                return
            }
        }
        
        _fileSelectorTVC = self.storyboard?.instantiateViewController(withIdentifier: "FileSelector") as! FileSelectorTableViewController;
        
        _fileSelectorTVC.isLoaded = _isLoaded;
        _fileSelectorTVC.isPartOfSequence = _isPartOfSequence;
        _visibleSubVC = _SubVCs.file.rawValue;                  // media services reset...
        
        _fileSelectorTVC._delegate = self;
        _fileSelectorTVC.padNumber = _padNumber
        
        navigationController?.pushViewController(_fileSelectorTVC, animated: true);
    }
    
    private func noDemoPadChangeAlert(action: String)
    {
        let loadMessage = "Loading Into A Demo Pad Is Not Allowed";
        let clearMessge = "Clearing A Demo Pad Is Not Allowed";
        let recordMessage = "Recording Into A Demo Pad Is Not Allowed"
        
        var usedMessage = "";
        
        if(action == "load"){   usedMessage = loadMessage;  }
        else if(action == "clear"){ usedMessage = clearMessge;  }
        else if(action == "record"){    usedMessage = recordMessage;    }
        
        let noDemoPadClearAlert = UIAlertController(title: "Not Allowed", message: usedMessage, preferredStyle: .alert);
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil);
        
        noDemoPadClearAlert.addAction(okAction);
        
        navigationController?.present(noDemoPadClearAlert, animated: true, completion: nil);
    }
    
    @IBAction func handleClearButton(_ sender: UIButton)
    {
        guard(_isLoaded)    else{   return; }
        
        if(_songName == _demoSongName)
        {
            if(_bankNumber == 1)
            {
                noDemoPadChangeAlert(action: "clear");
                return
            }
        }
        
        // first check to see if clear will affect a sequence
        if(checkForSequenceBeforeClearing()){   return; }
        else
        {
            let clearAlertController = UIAlertController(title: "Clear Pad", message: "Do You Want to Erase This Pad?",  preferredStyle: .alert);

            let clearAction = UIAlertAction(title: "Clear", style: .destructive,
                                                handler: {[weak self](paramAction:UIAlertAction!) in
                                                    self?.erasePad();
            })

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);

            clearAlertController.addAction(cancelAction);
            clearAlertController.addAction(clearAction);
        
            self.present(clearAlertController, animated: true, completion: nil)
        }
    }
    
    /** returns true if the user chooses to clear the sequence,
            false otherwise */
    private func checkForSequenceBeforeClearing() -> Bool
    {
        if(_isPartOfSequence){  return alterSequenceAlert();    }
        return false;
    }
    
    /** erase pad from disk */
    func erasePad()
    {
        //  update the model,
        callDelegateSendDetachPad(pad: _padNumber, erase: true);
        // Update disk
        _padEraser.erasePad(name: _songName, bank: _bankNumber, pad: _padNumber);
        
        _isLoaded = false;
        // update UI
        resetUIToDefaultValuesAfterClear();
        
        //      we also need to reset the _isLoaded member in the corresponding PadView.
        _delegate.resetPadViewIsLoaded(pad: _padNumber);
    }
    
    /** returns whether the user chooses to clear the sequence,
            false otherwise */
    private func alterSequenceAlert() -> Bool
    {
        var ret = false;
        
        let alterSequenceAlert = UIAlertController(title: "Clear Sequence?", message: "Clearing This Pad Will Erase The Currently Configured Sequence. Proceed?", preferredStyle: .alert);
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil);
        
        let clearAction = UIAlertAction(title: "Clear", style: .destructive, handler:
        {   (action: UIAlertAction)
            in
            self.erasePad();
            self._delegate.clearSequence();
            ret = true;
        })
        
        alterSequenceAlert.addAction(cancelAction);
        alterSequenceAlert.addAction(clearAction);
        
        navigationController?.present(alterSequenceAlert, animated: true, completion: nil);
        
        return ret;
    }
    
    /** update view to reflect deafault non loaded values */
    private func resetUIToDefaultValuesAfterClear()
    {
        assert(!_isLoaded)
        
        _fileNameButton.setTitle("No Sound Loaded", for: .normal);
        
        _volumeValueLable.text = "0.00";
        
        _startingPointValueLabel.text = "0.00 s";
        _endingPointValueLabel.text = "0.00 s";
        
        _startStopTriggerModeButton.backgroundColor = .lightGray;
        _startStopTriggerModeButton.setTitleColor(.gray, for: .disabled);
        _startStopTriggerModeButton.isEnabled = false;
        
        _playThroughTriggerModeButton.backgroundColor = .lightGray;
        _playThroughTriggerModeButton.setTitleColor(.gray, for: .disabled);
        _playThroughTriggerModeButton.isEnabled = false;
        
        _pitchSemiToneValueLavel.text = "0 st";
        _pitchCentValueLavel.text = "0 ct";
        
        //  make any controls innopperable that need to be.
        toggleSettingsControlActivation(activate: _isLoaded);
    }
    
    /** move to recordVC */
    @IBAction func handleRecordButton(_ sender: UIButton)
    {
        if(_songName == _demoSongName)
        {
            if(_bankNumber == 1)
            {
                noDemoPadChangeAlert(action: "record");
                return
            }
        }
        
        _visibleSubVC = _SubVCs.record.rawValue;
        
        if(_recordVC == nil)
        {   _recordVC = self.storyboard?.instantiateViewController(withIdentifier: "RecordVC") as! RecordViewController;    }
        
        _recordVC.songName = _songName;
        _recordVC.songNumber = _songNumber;
        _recordVC.bankNumber = _bankNumber;
        _recordVC.padNumber = _padNumber;
        _recordVC._delegate = self;
        _recordVC.isLoaded = _isLoaded;
        _recordVC.isPartOfSequence = _isPartOfSequence;
        
        navigationController?.pushViewController(_recordVC, animated: true);
    }
    
    /** enable/disable the configuration controlls based upon whether a sound has been chosen for the pad */
    private func toggleSettingsControlActivation(activate: Bool)
    {
        _startStopTriggerModeButton.isEnabled = activate;
        _playThroughTriggerModeButton.isEnabled = activate;
    }
        
    private func updateVolume(vol: Double)
    {
        _volume = Double(vol);
        _volumeValueLable.text = _numberFormatter.string(from: NSNumber(floatLiteral: _volume))!
        _delegate.passVolume(pad: _padNumber, volume: _volume);
        _padSaver.savePadVolume(songName: _songName, bank: _bankNumber, pad: _padNumber, volume: _volume)
        
        if(_isConnected){   _delegate.sendVolume(pad: _padNumber, volume: _volume)    }
    }
    
    /** set trigger mode to start/stop */
    @IBAction func handleStartStopTriggerModeButton(_ sender: UIButton)
    {
        _startStopTriggerMode = true;
        
        _startStopTriggerModeButton.backgroundColor = UIColor.yellow;
        _startStopTriggerModeButton.setTitleColor(UIColor.black, for: .normal);
        
        _playThroughTriggerModeButton.backgroundColor = UIColor.black;
        _playThroughTriggerModeButton.setTitleColor(UIColor.yellow, for: .normal);
        
        _delegate.passTriggerMode(pad: _padNumber, mode: _startStopTriggerMode);
        
        // save
        _padSaver.savePadTriggerMode(songName: _songName, bank: _bankNumber, pad: _padNumber, triggerMode: _startStopTriggerMode);
        
        if(_isConnected){   _delegate.sendTriggerMode(pad: _padNumber, triggerMode: _startStopTriggerMode);    }
        
        _delegate.cancelPreview(pad: _padNumber);
    }
    
    /** set trigger mode to play through */
    @IBAction func handlePlayThroughTriggerModeButton(_ sender: UIButton)
    {
        _startStopTriggerMode = false;
        
        _playThroughTriggerModeButton.backgroundColor = UIColor.yellow;
        _playThroughTriggerModeButton.setTitleColor(.black, for: .normal);
        
        _startStopTriggerModeButton.backgroundColor = .black;
        _startStopTriggerModeButton.setTitleColor(.yellow, for: .normal);
        
        _delegate.passTriggerMode(pad: _padNumber, mode: _startStopTriggerMode);
        
        // save
        _padSaver.savePadTriggerMode(songName: _songName, bank: _bankNumber, pad: _padNumber, triggerMode: _startStopTriggerMode);
        
        if(_isConnected){   _delegate.sendTriggerMode(pad: _padNumber, triggerMode: _startStopTriggerMode);    }
    }
    
    /** update label, save new value to disk, update model */
    private func updateCent()
    {
        if(_cent > 0){  _pitchCentValueLavel.text = "+" + (Int(_cent * 100)).description + " ct";    }
        else{   _pitchCentValueLavel.text = (Int(_cent * 100)).description + " ct";  }
        
        //  save to disk
        _padSaver.savePadCent(songName: _songName, bank: _bankNumber, pad: _padNumber, cent: _cent);
        
        // update model
        _delegate.passPitch(pad: _padNumber, pitch: _pitch);
        
        // TODO: if connected, update host
        if(_isConnected){}
    }
    
    private func updateSemitone()
    {
        if(_semitone > 0){  _pitchSemiToneValueLavel.text = "+" + _semitone.description + " st";    }
        else{   _pitchSemiToneValueLavel.text = _semitone.description + " st";  }
        
        _padSaver.savePadSemitone(songName: _songName, bank: _bankNumber, pad: _padNumber, semitone: _semitone); // disk
        _delegate.passPitch(pad: _padNumber, pitch: _pitch);    // model
        
        // TODO:    if connected, update host
        if(_isConnected){}
    }
    
    /** Set cent and semitone values back to 0 */
    @IBAction func handlePitchResetButton(_ sender: UIButton)
    {
        semitone = 0;
        cent = 0;
        
        updateCent();
        updateSemitone();
    }

    /** handling app moving to and from background....*/
    func isRecordingTakingPlace() -> Bool
    {
        var ret = false;

        if(_recordVC != nil)
        {
            if(_recordVC.isRecording)
            {
                ret = true;
                
                _recordVC.resetRecord();
                //  stop recording
                _recordVC.avMic.stop();
                
                // TODO: we might want to do this before we stop the mic.....
                self._opQueue.addOperation
                    {   self._recordVC.isInterrupted = true; }
                self._opQueue.waitUntilAllOperationsAreFinished();
            }
        }

        return ret;
    }
    
    /** handling app moving to and from background....*/
    func resetFileSelectorCellIsLoading(section: Int, row: Int)
    {
        if(_fileSelectorTVC != nil){    _fileSelectorTVC.resetFileSelectorCellIsLoading(section: section, row: row);    }
    }
    
    /** pass selected file info up the class hierarchy,
            bound for the sound mod */
    func callDelegatePassSelectedFile(file: URL, pad: Int, section: Int, row: Int)
    {
        _loadedFileName = file.lastPathComponent;
        
        // we have to pass the sound file up in order for the preview to work
        _delegate.passSelectedFile(file: file, pad: pad, section: section, row: row);
        _padSaver.savePadFile(songName: _songName, bank: _bankNumber, pad: _padNumber, file: file);
        
        var tempAudioFile: AVAudioFile! = nil
        
        do
        {
            /** EXTRANEOUS AUIDO FILE INIT ALERT */
            // make a temporary file out of the selected file so we can set our fileLength member
            tempAudioFile = try AVAudioFile(forReading: file);
            
            if(_debugFlag){  print("callDelegatePassSelectedFile() in PadConfigVC initialized AVAudioFile");  }
            
            _fileLength = Double(tempAudioFile.length) / tempAudioFile.fileFormat.sampleRate;
            
            // might as well save the end point while we are at it
            _padSaver.savePadEndPoint(songName: _songName, bank: _bankNumber, pad: _padNumber, endPoint: Double(_fileLength));
        }
        catch
        {
            print("callDelegatePassSelectedFile() in PadConfigVC could not make temporary sound file out of chosen sound");
            print(error.localizedDescription);
        }
        
        tempAudioFile = nil;
        
        // signal the SongTVC that the last load action was from a file and not a song for proper memory warning handling
        _delegate.passLoadFlag(load: true, pad: _padNumber);
    }
    
    // Both these methods are untilized by the FileSelctorVC and the RecordVC
    func callDelegateSendConnectPadToMixer(pad: Int){ _delegate.sendConnectPadToMixer(pad: pad);  }
    
    /** we need to make adustments to the node graph whenever we swap sounds.
            also we should reset pad settings to default values for the model, view, and disk */
    func callDelegateSendDetachPad(pad: Int, erase: Bool)
    {
       // only send the signal to detach the pad if the pad is not blank
        if(_isLoaded)
        {
            _delegate.sendDetachPad(pad: pad, erase: erase);
            
            // reset view
            _volume = 0
            _startingPoint = 0;
            _endPoint = _fileLength;
            _startStopTriggerMode = true;
            // adjusting public cent and semitone setters adjusts private _pitch member.
            cent = 0;
            semitone = 0
            
            // if we are not erasing the pad
            if(!erase)
            {
                //reset model
                _delegate.passVolume(pad: _padNumber, volume: 0)
                _delegate.passStartingPoint(pad: _padNumber, startPoint: 0, load: true);
                callDelegateSetEndPointToFileDuration(duration: Float(_fileLength))
                _delegate.passTriggerMode(pad: _padNumber, mode: true);
                _delegate.passPitch(pad: _padNumber, pitch: _pitch);
                // save
                _padSaver.savePadVolume(songName: _songName, bank: _bankNumber, pad: _padNumber, volume: _volume)
                _padSaver.savePadStartingPoint(songName: _songName, bank: _bankNumber, pad: _padNumber, startingPoint: _startingPoint);
                _padSaver.savePadEndPoint(songName: _songName, bank: bankNumber, pad: pad, endPoint: _fileLength);
                _padSaver.savePadTriggerMode(songName: _songName, bank: bankNumber, pad: pad, triggerMode: _startStopTriggerMode);
                _padSaver.savePadCent(songName: _songName, bank: _bankNumber, pad: _padNumber, cent: _cent);
                _padSaver.savePadSemitone(songName: _songName, bank: _bankNumber, pad: _padNumber, semitone: _semitone);
            }
        }
    }
    
    /** 12/12/2017 this method is an attempt to eliminate a call to the AVAudioFile init in the PadLoader's getFileDuration() Method,
     This method is called in the BankVC by a method of the same name
     it would be nice to have this in place by the release,
     but it might cause more problems than it is worth */
//    func passFileDurationBackToView(duration: Double)
//    {
//        _endingPointValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: duration))! + " s";
//
//        _endPoint = duration;
//
//         //{   self._endingPointValueLabel.text = self._numberFormatter.string(from: NSNumber(floatLiteral: end))! + " s"; }
//
//        _padSaver.savePadEndPoint(songName: _songName, bank: _bankNumber, pad: _padNumber, endPoint: duration);
//    }
    
    /** present a VC deicated to configuration control */
    private func presentPadControlVC(id: String)
    {
        if(_isLoaded)
        {
            switch id
            {
            case "volume":  presentVolumeVC();
            //case "pan": presentPanVC();
            case "endPoints": presentEndPointsVC();
            //case "trigger": presentTriggerModeVC();
            case "pitch":   presentPitchVC()
            default:    return;
            }
        }
    }
    
    private func dismissSubVC()
    {
        _visibleSubVC = "";
        navigationController?.dismiss(animated: true, completion: nil);
    }
    
    private func presentVolumeVC()
    {
        _visibleSubVC = _SubVCs.volume.rawValue;
        
        let volumeVC = self.storyboard?.instantiateViewController(withIdentifier: "VolumeVC") as! VolumeViewController;
    
        volumeVC._delegate = self;
        navigationController?.present(volumeVC, animated: true, completion:
        {
            volumeVC.volume = self._volume;
            volumeVC.setVolume();
        });
    }
    
    private func presentEndPointsVC()
    {
        _visibleSubVC = _SubVCs.endpoints.rawValue;
        
        let endPointsVC = self.storyboard?.instantiateViewController(withIdentifier: "EndPointsVC") as! EndPointsViewController;
        
        endPointsVC._delegate = self;
        
        endPointsVC.loadViewIfNeeded();
        
        endPointsVC.startingPoint = self._startingPoint;
        endPointsVC.endPoint = self._endPoint;
        endPointsVC.fileLength = self._fileLength;
        
        navigationController?.present(endPointsVC, animated: true, completion:
        {
            endPointsVC.setStartPoint();
            endPointsVC.setEndPoint();
        })
    }
    
    //  TODO: Implement this
    private func presentPitchVC()
    {
        _visibleSubVC = _SubVCs.pitch.rawValue;
        
        let pitchVC = self.storyboard?.instantiateViewController(withIdentifier: "PitchVC") as! PitchViewController;
        
        pitchVC._delegate = self;
        
        pitchVC.semitones = _semitone;
        pitchVC.cents = _cent;
        
        pitchVC.semitoneMax = _semitoneMax;
        pitchVC.semitoneMin = _semitoneMin;
        
        pitchVC.centMax = _centMax;
        pitchVC.centMin = _centMin;
        
        navigationController?.present(pitchVC, animated: true, completion: nil);
    }
    
    //--------------------------- methods for FileSelectorTVCParentProtocol -----------------------------------------------------
    // UI Update
    func callDelegateSetEndPointToFileDuration(duration: Float) {   _endPoint = Double(duration);  }
    func callDelegateSendInitialStartingPointToPadModel(pad: Int)
    {   _delegate.passStartingPoint(pad: pad, startPoint: 0.0, load: true);  }
    //--------------------------- end of methods for FileSelectorTVCParentProtocol -----------------------------------------------
    
    
    //--------------------------- methods for RecordVCParentProtocol -------------------------------------------------------------
    func setRecordedFileNameToLable(fileName: String){  _fileNameButton.setTitle(fileName, for: .normal);   }
    //--------------------------- end of methods for RecordVCParentProtocol -------------------------------------------------------
}

extension PadConfigViewControler: PitchVCParentProtocol
{
    func passPitchPreview(){    _delegate.preview(pad: _padNumber); }
    func dismissPitchVC(){  dismissSubVC();  }
    
    func passSemitones(tones: Int)
    {
        semitone = tones;
        updateSemitone();
    }
    
    func passCents(cents: Float)
    {
        cent = cents;
        updateCent();
    }
}

extension PadConfigViewControler: EndPointsVCParentProtocol
{
    func passStartPoint(start: Double)
    {
        _delegate.passStartingPoint(pad: _padNumber, startPoint: start, load: false);
        _startingPoint = start;
        _padSaver.savePadStartingPoint(songName: _songName, bank: _bankNumber, pad: _padNumber, startingPoint: start);
        
        DispatchQueue.main.async
        {   self._startingPointValueLabel.text = self._numberFormatter.string(from: NSNumber(floatLiteral: start))! + " s"; }
        
        /** in the future when we write the host,
                here might be a good place to send info over the network */
    }
    func passEndPoint(end: Double)
    {
        _delegate.passEndPoint(pad: _padNumber, endPoint: end);
        _endPoint = end;
        _padSaver.savePadEndPoint(songName: _songName, bank: _bankNumber, pad: _padNumber, endPoint: end);
        
        DispatchQueue.main.async
        {   self._endingPointValueLabel.text = self._numberFormatter.string(from: NSNumber(floatLiteral: end))! + " s"; }
        
        /** in the future when we write the host,
         here might be a good place to send info over the network */
    }
    /** previewing originating from the EndpointsVC */
    func passEndPointsPreview(){    if(!routeIsChanging){   _delegate.preview(pad: _padNumber); }   }
    func dismissEndPointsVC(){ dismissSubVC();  }
    func cancelEndPointPreview(){   _delegate.cancelPreview(pad: _padNumber);   }
    
    /** the EndpointsVC can't present its info screen directly because it is presented by this VC modally */
    func presentInfoScreen()
    {
        let infoScreen  = self.storyboard?.instantiateViewController(withIdentifier: "EndpointsInfoVC") as! EndpointsInfoScreenViewController;
        navigationController?.pushViewController(infoScreen, animated: true);
    }
}

extension PadConfigViewControler: VolumeContainerViewParentProtocol
{   func present(id: String){   presentPadControlVC(id: id);    }   }

extension PadConfigViewControler: VolumeVCParentProtocol
{
    func passVolume(volume: Float){ updateVolume(vol: Double(volume));  }
    func passVolumePreview(){   if(!routeIsChanging){   _delegate.preview(pad: _padNumber); }   }
    func dismissVolumeVC(){   dismissSubVC();    }
}

/** among other things allows this class to pass info up the ownership hierarchy relating to selected files for pads */
extension PadConfigViewControler: FileSelectorTVCParentProtocol
{
    /** once a file is selected for a pad,
     pass info up to the sound mod */
    internal func passSelectedFile(file: URL,  pad: Int, section: Int, row: Int)
    {
        callDelegatePassSelectedFile(file: file, pad: pad, section: section, row: row);
        navigationController?.dismiss(animated: true, completion: nil);
    }
    func sendConnectSelectedPadToMixer(pad: Int){ callDelegateSendConnectPadToMixer(pad: pad);    }
    internal func setChosenSoundIsLoaded(isLoaded: Bool){   _isLoaded = isLoaded;   }
    internal func setChosenSoundEndPointToFileDuration(duration: Float) {  callDelegateSetEndPointToFileDuration(duration: duration);   }
    func sendSelectDetachPad(padNumber: Int, erase: Bool) {  callDelegateSendDetachPad(pad: padNumber, erase: erase) }
    func sendInitialStartingPointToPadModel(pad: Int) {   callDelegateSendInitialStartingPointToPadModel(pad: pad);   }
    func sendInitialEndPointToPadModel(pad: Int, endpoint: Double)
    {   _delegate.passEndPoint(pad: pad, endPoint: endpoint);   }
    func dismissFileSelectorVC() {  dismissSubVC();  }
    func passEraseFile(file: URL) { _delegate.passEraseFile(file: file);    }
    func selectorCancelPreview(){   _delegate.cancelPreview(pad: _padNumber);   }
}

extension PadConfigViewControler: RecordVCParentProtocol
{
    func passRecordedFile(file: URL, pad: Int, fileName: String)
    {
        // pass recorded filee further up the chain just like we would if we had chosen a file from the FileSelectorTVC
        callDelegatePassSelectedFile(file: file, pad: pad, section: -1, row: -1);
        // set the preview button's title to the name of the recorded file.
        setRecordedFileNameToLable(fileName: fileName);
    }
    func sendConnectRecordedPadToMixer(pad: Int) {    callDelegateSendConnectPadToMixer(pad: pad);    }
    func startMasterSoundMod()
    {   _delegate.startMasterSoundMod();    }
    func stopMasterSoundMod(){  _delegate.stopMasterSoundMod(); }
    func setRecordedSoundIsLoaded(isLoaded: Bool){  _isLoaded = isLoaded;   }
    func setRecordedSoundEndPointToFileDuration(duration: Float) {  callDelegateSetEndPointToFileDuration(duration: duration);    }
    func sendRecordDetachPad(pad: Int, erase: Bool) {  callDelegateSendDetachPad(pad: pad, erase: erase) }
    func sendRecordedInitialStartingPointToPadModel(pad: Int){    callDelegateSendInitialStartingPointToPadModel(pad: pad);   }
    func sendRecordedInitialEndPointToPadModel(pad: Int, endPoint: Double)
    {   _delegate.passEndPoint(pad: pad, endPoint: endPoint);   }
    func sendIsRecording(isRecording: Bool)
    {
        if(isRecording){    _delegate.sendIsRecording(isRecording: isRecording, pad: _padNumber); }
        else{   _delegate.sendIsRecording(isRecording: isRecording, pad: -1); }
    }
    func recordCancelPreview(){ _delegate.cancelPreview(pad: _padNumber);   }
}
