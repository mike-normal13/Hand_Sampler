//
//  RecordViewController.swift
//  Sampler_App
//
//  Created by mike on 4/16/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit
import AVFoundation

//  TODO: RecordVC
//       RecordVC -> Submit name
//          This method makes an AVAudioFile,
//              can we avoid doing this....?
//  TODO: 1/24/2018 revise all try catch blocks

class RecordViewController: SamplerVC, AVAudioRecorderDelegate
{
    let _debugFlag = true;
    
    @IBOutlet weak var _recordButton: UIButton!
    @IBOutlet weak var _activityIndicator: UIActivityIndicatorView!
    
    /** placed inside of the record button */
    private var _recordCircle: RecordVCCircle! = nil;
    
    private var _isRecording: Bool = false;
    var isRecording: Bool{  return _isRecording;    }
    
    /** indicates if an audio route change occurred while a recording was being made */
    private var _isInterrupted: Bool = false;
    var isInterrupted: Bool
    {
        get{    return _isInterrupted;  }
        set{    _isInterrupted = newValue;  }
    }
    
    private var _avMic: AVAudioRecorder! = nil;
    var avMic: AVAudioRecorder{ return _avMic;  }
    
    private var _newRecordedFileUrl: URL! = nil;
    private var _fileManager: FileManager! = FileManager();
    private var _recordedFilePath: URL! = nil;
    private var _userNameForFile: String = "";
    private var _documentFolder: URL! = nil
    private var _defaultRecordedFileWritePath: URL! = nil
    
    weak var _delegate: RecordVCParentProtocol! = nil;
    
    private var _defaultFileName: String = "";
    
    //  TODO: this should be local....
   private var _nameFileAlertController: UIAlertController! = nil;
    
    private var _musicFileLoader: Loader! = Loader();
    
    /** reflects whether the pad corresponding to this VC is part of a recorded sequence. */
    private var _isPartOfSequence = false;
    var isPartOfSequence: Bool
    {
        get{    return _isPartOfSequence;   }
        set{    _isPartOfSequence = newValue;   }
    }
    
    /** reflects whether the owning padConfigVC has a sound loaded,
            if it does we warn the user of a potential overwrite. */
    private var _isLoaded: Bool = false;
    var isLoaded: Bool
    {
        get{    return _isLoaded;   }
        set{    _isLoaded = newValue;   }
    }
    
    override func loadView()
    {
        super.loadView();
        
        _recordCircle = RecordVCCircle(frame: CGRect(x: 0, y: 0, width: _recordButton.frame.width, height: _recordButton.frame.height));
        _recordButton.addSubview(_recordCircle);
        
        _recordCircle.addTarget(self, action: #selector(handleRecordButtonDown(_:)), for: UIControlEvents.touchDown);
        _recordCircle.addTarget(self, action: #selector(handleRecordButtonUp(_:)), for: UIControlEvents.touchUpInside);
        
         _documentFolder = _fileManager.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first;
        
        _defaultRecordedFileWritePath = _documentFolder?.appendingPathComponent("rec " + _songName + " " + _bankNumber.description + " " + _padNumber.description + ".wav");
        
        // default
        _recordedFilePath = _defaultRecordedFileWritePath;
        
        navigationItem.setRightBarButton(UIBarButtonItem(title: "?", style: .plain, target: self, action: #selector(handleNavBarInfoButton)), animated: false);
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
        
        //  DEBUG: recordings interrupted under certain circumstances are getting saved to disk under this name unintendidly.....
        // in case the user does not name the recorded file
        _defaultFileName = " rec " + _songName + " " + _bankNumber.description + " " + _padNumber.description + ".wav"
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        navigationController?.isNavigationBarHidden = false;
        _isVisible = true;
        
        // the app can go to sleep on this VC
        UIApplication.shared.isIdleTimerDisabled = false;
        
        _delegate.stopMasterSoundMod();
        
        //http://stackoverflow.com/questions/34275577/how-to-record-audio-in-wav-format-in-swift
        //http://www.techotopia.com/index.php/Recording_Audio_on_iOS_8_with_AVAudioRecorder_in_Swift
        let recordSettings =
            [AVFormatIDKey:Int(kAudioFormatLinearPCM),
                AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                AVEncoderBitRateKey: 16,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey:8,
                AVLinearPCMIsFloatKey:false,
                AVLinearPCMIsBigEndianKey:false,
                AVSampleRateKey: 44100.0] as [String : Any]
        
        do{ try _avMic = AVAudioRecorder(url: _defaultRecordedFileWritePath!, settings: recordSettings as [String : AnyObject]); }
        catch let error as NSError {print("RecordVC failed to init audio recorder: \(error.localizedDescription)"); }
        
        _avMic.delegate = self;
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        if(_isLoaded){  warnOverwrite();    }
        else{   checkRecordPermission();    }
        // if the owning padConfigVC was previewing, stop the preview
        _delegate.recordCancelPreview();
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        _isVisible = false;
        if(_avMic.isRecording){ self._avMic.stop(); }
        self._delegate.startMasterSoundMod();
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        if(_activityIndicator.isAnimating){ _activityIndicator.stopAnimating(); }
        _nameFileAlertController = nil;
    }

    deinit
    {
        _avMic = nil;
        _defaultRecordedFileWritePath = nil;
        _delegate = nil;
        _documentFolder = nil;
        _musicFileLoader = nil;
        _nameFileAlertController = nil;
        _newRecordedFileUrl = nil;
        _recordCircle = nil;
        _recordedFilePath = nil;
        _opQueue = nil;
        _fileManager = nil;
        
        if(_debugFlag){ print("*** RecordVC deinitialized");    }
    }
    
    @objc func handleNavBarInfoButton()
    {
        let infoScreen = storyboard?.instantiateViewController(withIdentifier: "RecordInfoVC");
        navigationController?.pushViewController(infoScreen!, animated: true);
    }
    
    /** alert user of potential overwrite if recording is made */
    private func warnOverwrite()
    {
        let overwriteAlert = UIAlertController(title: "Potential Overwrite", message: "Making This Recording Will Overwrite The Sound Currently Loaded Into This Pad. Proceed?", preferredStyle: .alert);
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:
        {
            (action: UIAlertAction) in
            self.navigationController?.popViewController(animated: true);
        })
        
        let okAction = UIAlertAction(title: "OK", style: .destructive, handler:
        {
            (action: UIAlertAction) in
            self.checkRecordPermission();
        })
        
        overwriteAlert.addAction(cancelAction);
        overwriteAlert.addAction(okAction);
        
        navigationController?.present(overwriteAlert, animated: true, completion: nil);
    }
    
    /** tell the user how to turn record permissions back on if they are currently denied */
    private func checkRecordPermission()
    {
        if(AVAudioSession.sharedInstance().recordPermission() == .denied)
        {
            let recordPermissionAlertVC = UIAlertController(title: "Denied", message: "Recording Is Currently Denied. You Can Change This By Going To HandSampler In Settings And Switching Microphone Back On. Until This This Action Is Taken, Any Recording Made Will Result In Silence. Changing The Record Permission In Settings Will Require The App To Be Restarted.", preferredStyle: .alert);
            
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil);
            recordPermissionAlertVC.addAction(okAction);
            navigationController?.present(recordPermissionAlertVC, animated: true, completion: nil);
        }
    }

    /** start recording -- touch down */
    @IBAction func handleRecordButtonDown(_ sender: UIButton)
    {
        _opQueue.addOperation{  self._delegate.sendIsRecording(isRecording: true);  }
        _opQueue.waitUntilAllOperationsAreFinished();
        
        // there was a lag with the record button turning red,
        //  so we did this
        _opQueue.addOperation
        {
            self._avMic.prepareToRecord();
            self._avMic.record();
        }
        
        _isRecording = true;
        _recordCircle.recording = _isRecording;
        _recordCircle.setNeedsDisplay();
        _recordButton.backgroundColor = .gray;
    }
    
    //  TODO: this method needs to account for if the touch up happens after the audio route change alert...
    /** stop recording and prompt user to name the file */
    @IBAction func handleRecordButtonUp(_ sender: UIButton)
    {
        _activityIndicator.startAnimating(); // no threading needed here for some reason.....
        
        resetRecord();

        if(_avMic.isRecording){ _avMic.stop();  }
        
        //  an interrupted recording should preempt any notification of a potential sequence change.
        // alert user of potentially unintended change to currently configured play sequence
        if(_isPartOfSequence)
        {            
            //  This call calls nameRecordedFile() if the user chooses to record inspite of the sequence.
            alterSequenceAlert(sender: sender);
            return;
        }
        
        nameRecordedFile(sender: sender);
    }
    
    private func nameRecordedFile(sender: UIButton)
    {
        //https://peterwitham.com/swift-archives/intermediate/alert-with-user-entry/
        _nameFileAlertController = UIAlertController(title: "Name File", message: "Name The Recorded File",  preferredStyle: .alert);
        
        _nameFileAlertController!.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Name Your Recorded File"
        })
        
        let submitAction = UIAlertAction(title: "Submit", style: .default,
                                         handler: {[weak self](paramAction: UIAlertAction!) in
                                            self?.submitName(sender: sender);
        })
        
        //  http://stackoverflow.com/questions/26956016/cancel-button-in-uialertcontroller-with-uialertcontrollerstyle-actionsheet
        //  attempt to discard the recorded file.
        let cancelAction = UIAlertAction(title: "Discard", style: .destructive, handler:
            {[weak self](paramAction:UIAlertAction!)
                in
                self?.submitCancel();
            })
        
        self._nameFileAlertController?.addAction(cancelAction);
        self._nameFileAlertController?.addAction(submitAction);
        self.present(self._nameFileAlertController!, animated: true, completion: nil)
    }
    
    /** actions taken if user names a recording */
    private func submitName(sender: UIButton)
    {
        if let textFields = self._nameFileAlertController.textFields
        {
            let theTextFields = textFields as [UITextField]
            let enteredText = theTextFields[0].text
            self._userNameForFile = enteredText! + ".wav"
            
            if(self.checkForDuplicateName(fileName: (self._userNameForFile)))
            {
                self.alertUserOfDuplicateFileName(sender: sender);
                return;
            }
            
            var tempFile: AVAudioFile! = nil;
            
            // hopefully valid name
            if(enteredText != "")
            {
                //  prevent the user from accessing the back button on the nav bar.
                UIApplication.shared.beginIgnoringInteractionEvents();
                
                let userNamedFile = self._documentFolder.appendingPathComponent((self._userNameForFile));
                
                do
                {
                    // copy the recorded file into a file that matches the user supplied name
                    try self._fileManager.copyItem(at: (self._defaultRecordedFileWritePath)!, to: userNamedFile);
                }
                catch
                {   print("RecordVC could not copy original default file to file named by user: " + error.localizedDescription);    }
                
                // delete the original recorded file
                do{ try self._fileManager.removeItem(at: (self._defaultRecordedFileWritePath)!); }
                catch{   print("RecordVC could not delete original default recorded file: " + error.localizedDescription);  }
                
                // pass the user recorded and named file up the chain
                self._delegate.passRecordedFile(file: userNamedFile, pad: self.padNumber, fileName: self._userNameForFile);
                
                // detach so we don't get runtime !nodeimpl->HasEngineImpl() error
                self._delegate.sendRecordDetachPad(pad: self.padNumber, erase: false);
                
                self._delegate.sendConnectRecordedPadToMixer(pad: self.padNumber);
                
                // temp audio file for duration
                do
                {
                    if(_debugFlag){  print("submitName() in RecordVC initialized AVAudioFile");  }
                    tempFile = try AVAudioFile(forReading: userNamedFile);
                    
                }
                catch{  print("RecVC could not intialize named file for file duration: " + error.localizedDescription); }
                
                // update view
                self._delegate.setRecordedSoundEndPointToFileDuration(duration: Float(Double(tempFile.length) / tempFile.fileFormat.sampleRate));
                
                // update model
                self._delegate.sendRecordedInitialStartingPointToPadModel(pad: self._padNumber);
                self._delegate.sendRecordedInitialEndPointToPadModel(pad: self._padNumber, endPoint: Double(tempFile.length) / tempFile.fileFormat.sampleRate);
                
                // regardless of file name
                self._delegate.setRecordedSoundIsLoaded(isLoaded: true);
                
                // once we've recorded a sound,
                //     move back to the configVC
                self.navigationController?.popViewController(animated: true);
                
                UIApplication.shared.endIgnoringInteractionEvents();
            }
                // else if the user did not name the file
            else
            {
                // alert the user to name the file before proceeding.
                self.handleBlankName();
            }
            
            tempFile = nil;
        }
    }
    
    /** action taken if user cancels a recording */
    private func submitCancel()
    {
        if(_activityIndicator.isAnimating){ _activityIndicator.stopAnimating(); }
        
        //  erase the file just recorded with the default name
        do{ try _fileManager.removeItem(at: _defaultRecordedFileWritePath);  }
        catch{  print("RecVC could not erase the recorded file when user canceled: " + error.localizedDescription); }
    }
    
    /** alerts the user to choose a different name for a recorded file besides an empty string */
    private func handleBlankName()
    {
        let blankNameAlertVC = UIAlertController(title: "Invalid Name", message: "Please Give Your Recorded Flie A Name ", preferredStyle: .alert);
        let okAction = UIAlertAction(title: "OK", style: .default, handler:
        {
            [weak self](paramAction:UIAlertAction!)
                in
                    self?.present((self?._nameFileAlertController)!, animated: true, completion: nil);
        })
        
        blankNameAlertVC.addAction(okAction);
        present(blankNameAlertVC, animated: true, completion: nil);
    }
    
    /** returns true if a duplicate file name is found */
    private func checkForDuplicateName(fileName: String) ->    Bool
    {
        let fileNames = _musicFileLoader.getAllMusicFileNames();
        
        for name in fileNames where name == fileName{   return true;    }
        
        return false;
    }
    
    /** choose another name or discard the recording */
    private func alertUserOfDuplicateFileName(sender: UIButton)
    {
        let duplicateAlert = UIAlertController(title: "Duplicte Name", message: "Please Choose Another Name", preferredStyle: .alert);
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler:
        {    (action:UIAlertAction) in
            
            self.handleRecordButtonUp(sender);       
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:{ (action:UIAlertAction) in return;   })
        
        duplicateAlert.addAction(okAction);
        duplicateAlert.addAction(cancelAction);
        
        self.navigationController?.present(duplicateAlert, animated: true, completion: nil);
    }
    
    //  TODO: this method is virtually identical to the same method in the FileSelectorVC,
    //          we should abstract it somewhow.
    /** returns true for user choosing to alter the sequence,
         false otherwise. */
    private func alterSequenceAlert(sender: UIButton)// -> Bool
    {
        let alterSequenceAlert = UIAlertController(title: "Change Sequence?", message: "Recording This File Will Alter The Currently Configured Sequence For This Bank. Proceed?", preferredStyle: .alert);
        
        let loadAction = UIAlertAction(title: "Record", style: .destructive, handler:
        {
            (action: UIAlertAction) in
            self.nameRecordedFile(sender: sender);
            
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:
        {
            (action: UIAlertAction)
            in
            self._activityIndicator.stopAnimating();
        })
        
        alterSequenceAlert.addAction(loadAction);
        alterSequenceAlert.addAction(cancelAction);
        
        navigationController?.present(alterSequenceAlert, animated: true, completion: nil);
    }
    
    /** reset the recording state of the VC.
            i.e. the state of the VC when it first appears */
    func resetRecord()
    {
        _isRecording = false;                       
        _recordCircle.recording = _isRecording;
        _recordCircle.setNeedsDisplay();
        _recordButton.backgroundColor = .black;
        
        _opQueue.addOperation{  self._delegate.sendIsRecording(isRecording: false); }
        _opQueue.waitUntilAllOperationsAreFinished();
        
        //  TODO: the appearance of the alertVC may end up in a touch up event not occurring.....
        // if the user lifts finger after the recording was interrupted by an audio route change...
        if(_isInterrupted){ _isInterrupted = false; }
    }
}

/** this class represents the circle which will be placed within the record button.
 activating this button lets the user record a sound via the phone's mic*/
class RecordVCCircle: UIControl
{
    private var _recording: Bool = false;
    var recording: Bool
    {
        get { return _recording;}
        set{_recording = newValue;}
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame);
        self.frame = frame;
        backgroundColor = UIColor.black;
        
        layer.borderWidth = 1;
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = 5;
        clipsToBounds = true;
    }
    
    required init(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func draw(_ rect: CGRect){ drawCircle(rect: rect); }
    
    private func drawCircle(rect: CGRect)
    {
        let context = UIGraphicsGetCurrentContext();
        
        var circleBound: CGRect = rect;
        circleBound.size.width = min(rect.width, rect.height) * 0.8;
        circleBound.size.height = circleBound.width;
        circleBound.origin.x = (rect.width - circleBound.width) / 2;
        circleBound.origin.y = (rect.height - circleBound.height) / 2;
        
        if(_recording){ context!.setFillColor(UIColor.red.cgColor); }
        else{   context!.setFillColor(UIColor.gray.cgColor);   }
        context!.fillEllipse(in: circleBound);
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?){  sendActions(for: UIControlEvents.touchUpInside);    }
}
