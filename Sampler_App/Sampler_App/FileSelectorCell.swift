//
//  FileSelectorCell.swift
//  Sampler_App
//
//  Created by mike on 10/2/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit
import AVFoundation

//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

/** represents the cell which will populate the FileSelectorTVC.
         Users can preview the sound by pressing on the cell.
             Users can stop previewing the sound by releasing the cell,
                Users can also erase an audio file off of the phone. */
class FileSelectorCell: UITableViewCell
{
    private let _debugFlag = false;
    
    @IBOutlet weak var _fileNameLable: UILabel!
    @IBOutlet weak var _selectButton: UIButton!
    @IBOutlet weak var _eraseButton: UIButton!
    
    @IBOutlet weak var _fileSizeValueLabel: UILabel!
    @IBOutlet weak var _fileDurationValueLabel: UILabel!
    
    /** longer files might need a little special attention. */
    @IBOutlet weak var _loadActivityIndicator: UIActivityIndicatorView!
    
    weak var _delegate: FileSelectorCellParentProtocol!
    
    private var _resetCellName: Notification.Name! = Notification.Name(rawValue: fileSelectorCellLoadWasCancelledKey);
    
    /** not exactly sure why we are doing this,
            it seems to have something to do with the app moving to and from the background */
    private var _isLoading = false;
    var isLoading: Bool
    {
        get{    return _isLoading;  }
        set{    _isLoading = newValue;  }
    }
    
    /** corresponds to key in the _indexDictionary in the FileSelectorVC */
    private var _section: Int = -1;
    var section: Int
    {
        get{    return _section;    }
        set{    _section = newValue;    }
    }
    
    /** corresponds to value index in the _indexDictionary in the FileSelectorVC */
    private var _row: Int = -1;
    var row: Int
    {
        get{    return _row;    }
        set{    _row = newValue;    }
    }
    
    /** indicates whether another cell in the FileSelectorVC is currently previewing thereby preventing more than one preview at a time */
    private var _otherCellIsPreviewing = false;
    
    /** indicates whether this cell's sound is currently being previewe by the player in the FileSelectorVC */
    private var _thisCellIsPreviewing = false;
    
    private lazy var _opQueue: OperationQueue! = OperationQueue();
    
    /** added on 12/21/2017
            indicates whether the sound associated with this cell is from the included demo library */
    private var _demoSound = false;
    var demoSound: Bool
    {
        get{    return _demoSound;  }
        set{    _demoSound = newValue;  }
    }
    
    //  TODO: this init is the one that seems to be getting called,
    //          not the override one.......
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder);
        
        backgroundColor = .gray;
        createObservers();
    }
    
    deinit
    {
        _opQueue = nil;
        _loadActivityIndicator = nil;
        _delegate = nil;
        
        if(_debugFlag){ print("*** FileSelectorCell deinitialized");    }
        
        NotificationCenter.default.removeObserver(self);
    }
    
    /** preview sound */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(_otherCellIsPreviewing){ return; }
        
        self.backgroundColor = .yellow
        
        self._delegate.startPreview(section: _section, row: _row);
        
        let otherCellBeganPreviewingName = Notification.Name(rawValue: fileCellBeganPreviewKey);
        NotificationCenter.default.post(name: otherCellBeganPreviewingName, object: nil);
        
        _thisCellIsPreviewing = true;
    }
    /** stop previewing sound */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(_otherCellIsPreviewing && !_thisCellIsPreviewing){   return; }
        
        if(_thisCellIsPreviewing)
        {
            backgroundColor = .gray;
            _delegate.stopPreview();
            
            let otherCellEndedPreviewingName = Notification.Name(rawValue: fileCellEndedPreviewKey);
            NotificationCenter.default.post(name: otherCellEndedPreviewingName, object: nil);
            
            _thisCellIsPreviewing = false;
        }
        
    }
    /** stop previewing sound if touch leaves cell */
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        backgroundColor = .gray;
        _delegate.stopPreview();
        _thisCellIsPreviewing = false;
    }
    
    /** select audio file for current pad */
    @IBAction func handleChooseButton(_ sender: UIButton)
    {
        _selectButton.isEnabled = false;
        
        self._loadActivityIndicator.isHidden = false;
        self._loadActivityIndicator.startAnimating();
        
        //  https://stackoverflow.com/questions/40660913/start-and-stop-activity-indicator-swift3
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01)
        {   self._delegate.selectSound(section: self._section, row: self._row); }
        
        _fileSizeValueLabel.isHidden = true;
        _eraseButton.isHidden = true;
        _selectButton.isHidden = true;
        
        _isLoading = true;
    }
    
    /** erase a file from disk */
    @IBAction func handleEraseButton(_ sender: UIButton)
    {
        _delegate.eraseFile(section: _section, row: _row);
        //_delegate.eraseFile(index: tag);
    }
    
    private func createObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppReenteredForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil);
        
        let resetCellName = Notification.Name(rawValue: fileSelectorCellLoadWasCancelledKey);
        NotificationCenter.default.addObserver(self, selector: #selector(resetCell), name: resetCellName, object: nil);
        
        let otherCellBeganPreviewingName = Notification.Name(rawValue: fileCellBeganPreviewKey);
        NotificationCenter.default.addObserver(self, selector: #selector(handleOtherCellIsPreviewing), name: otherCellBeganPreviewingName, object: nil);
        
        let otherCellEndedPreviewingName = Notification.Name(rawValue: fileCellEndedPreviewKey);
        NotificationCenter.default.addObserver(self, selector: #selector(handleOtherCellIsNotPreviewing), name: otherCellEndedPreviewingName, object: nil);
    }
    
    //  TODO: this is the right approach,
    //          however it does not have the desired affect because the reconnecting and restarting of the sound module seems to preempt this call,
    //              and by the time the call to startAnimating() occurs the file is already loaded.....
    @objc func handleAppReenteredForeground()
    {
        if(!_loadActivityIndicator.isHidden && _loadActivityIndicator.isAnimating){   _loadActivityIndicator.startAnimating();    }
    }
    
    /** if the user cancels loading a cell,
     reset its UI */
    @objc func resetCell()
    {
        if(_loadActivityIndicator.isAnimating)
        {
            _loadActivityIndicator.stopAnimating();
            
            _eraseButton.isHidden = false;
            _fileSizeValueLabel.isHidden = false;
            _fileDurationValueLabel.isHidden = false;
            _selectButton.isHidden = false;
        }
    }
    
    @objc func handleOtherCellIsPreviewing(){   _otherCellIsPreviewing = true;  }
    @objc func handleOtherCellIsNotPreviewing(){    _otherCellIsPreviewing = false; }
}
