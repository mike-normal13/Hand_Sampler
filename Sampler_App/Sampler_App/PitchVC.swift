//
//  PitchVC.swift
//  Sampler_App
//
//  Created by Budge on 10/31/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit

class PitchViewController: PadSettingVC
{
    let _debugFlag = false;
    
    @IBOutlet weak var _backButton: UIButton!
    
    @IBOutlet weak var _previewButton: UIButton!
    
    @IBOutlet weak var _semitoneDecrementButton: UIButton!
    @IBOutlet weak var _semitoneIncrementButton: UIButton!
    @IBOutlet weak var _semitoneValueLable: UILabel!
    
    @IBOutlet weak var _centDecrementButton: UIButton!
    @IBOutlet weak var _centIncrementButton: UIButton!
    @IBOutlet weak var _centValueLabel: UILabel!
    
    @IBOutlet weak var _resetPitchButton: UIButton!
    
    private var _semitoneIncrementButtonTouchedUp = false;
    private var _semitoneDecrementButtonTouchedUp = false;
    private var _centIncrementButtonTouchedUp = false;
    private var _centDecrementButtonTouchedUp = false;
    
    weak var _delegate: PitchVCParentProtocol! = nil;
    
    private var _semitones: Int = 0;
    var semitones: Int
    {
        get{    return _semitones;  }
        set{    _semitones = newValue;  }
    }
    
    private var _cents: Float = 0.0;
    var cents: Float
    {
        get{    return _cents;  }
        set{    _cents = newValue;  }
    }
    
    private var _semitoneMax: Int = 0;
    var semitoneMax: Int
    {
        get{    return _semitoneMax;  }
        set{    _semitoneMax = newValue;  }
    }
    
    private var _semitoneMin: Int = 0;
    var semitoneMin: Int
    {
        get{    return _semitoneMin;  }
        set{    _semitoneMin = newValue;  }
    }
    
    private var _centMax: Float = 0;
    var centMax: Float
    {
        get{    return _centMax;  }
        set{    _centMax = newValue;  }
    }
    
    private var _centMin: Float = 0;
    var centMin: Float
    {
        get{    return _centMin;  }
        set{    _centMin = newValue;  }
    }
    
    /** press and hold */
    private let _buttonSleepInterval = 0.2;
    
    override func loadView()
    {
        super.loadView()
    
        var blurEffect = UIBlurEffect();
        
        //  TODO: this is duplicate code,
        //          we should abstract this.
        //  http://belka.us/en/modal-uiviewcontroller-blur-background-swift/
        if #available(iOS 10.0, *){ blurEffect = UIBlurEffect(style: .prominent);   }
        else
        {
            // Fallback on earlier versions
        }
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.frame
        
        view.backgroundColor = .clear;
        
        self.view.insertSubview(blurEffectView, at: 0)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        if(_semitones > 0){ _semitoneValueLable.text = "+" + _semitones.description;    }
        else{   _semitoneValueLable.text = _semitones.description;  }
        
        if(_cents > 0){ _centValueLabel.text = "+" + Int(_cents * 100.0).description;   }
        else{   _centValueLabel.text = Int(_cents * 100.0).description; }
    }
    
    deinit
    {
        _delegate =  nil;
        if(_debugFlag){ print("******PitchVC deinitialized");   }
    }
    
    @IBAction func handleBackButton(_ sender: UIButton){    _delegate.dismissPitchVC(); }
    @IBAction func handlePreviewButton(_ sender: UIButton){ _delegate.passPitchPreview();   }
    
    /** press and hold */
    @IBAction func handleSemitoneDecrementButtonTouchDown(_ sender: UIButton)
    {
        guard((Float(_semitones) + _cents) >= Float(_semitoneMin + 1))    else{   return; }
        
        _semitoneDecrementButtonTouchedUp = false
        
        OperationQueue().addOperation
        {
            self.semitones -= 1;
            DispatchQueue.main.async{   self.updateSemitone();  }
            Thread.sleep(forTimeInterval: TimeInterval(self._buttonSleepInterval));
            if(!self._semitoneDecrementButtonTouchedUp){    self.handleSemitoneDecrementButtonTouchDown(sender);    }
        }
    }
    
    /** touch up */
    @IBAction func handleSemitoneDecrementButton(_ sender: UIButton)
    {
        updateSemitone();
        _semitoneDecrementButtonTouchedUp = true;
    }
    
    /** press and hold */
    @IBAction func handleSemitoneInccrementButtonTouchDown(_ sender: UIButton)
    {
        guard((Float(_semitones) + _cents) <= Float(_semitoneMax - 1))    else{   return; }
        
        _semitoneIncrementButtonTouchedUp = false;
        
        OperationQueue().addOperation
        {
            self._semitones += 1;
            DispatchQueue.main.async{   self.updateSemitone();  }
            Thread.sleep(forTimeInterval: TimeInterval(self._buttonSleepInterval));
            if(!self._semitoneIncrementButtonTouchedUp){    self.handleSemitoneInccrementButtonTouchDown(sender);   }
        }
    }
    
    /** touch up */
    @IBAction func handleSemitoneInccrementButton(_ sender: UIButton)
    {
        updateSemitone();
        _semitoneIncrementButtonTouchedUp = true;
    }
    
    private func updateSemitone()
    {
        if(_semitones > 0){  _semitoneValueLable.text = "+" + _semitones.description;    }
        else{   _semitoneValueLable.text = _semitones.description;  }
        
        _delegate.passSemitones(tones: _semitones);
    }
    
    /** press and hold */
    @IBAction func handleCentDecrementButtonTouchDown(_ sender: UIButton)
    {
        //        // can't go beyond the minimum semitone boundry
        //        //      /can't go beyond the minimum cent boundry
        guard(_semitones > _semitoneMin && _cents > _centMin) else{   return; }
        
        _centDecrementButtonTouchedUp = false
        
        OperationQueue().addOperation
        {
            self.cents -= 0.01;
            DispatchQueue.main.async{   self.updateCent();  }
            Thread.sleep(forTimeInterval: TimeInterval(self._buttonSleepInterval));
            if(!self._centDecrementButtonTouchedUp){    self.handleCentDecrementButtonTouchDown(sender);    }
        }
    }
    
    /** touch up */
    @IBAction func handleCentDecrementButton(_ sender: UIButton)
    {
        updateCent();
        _centDecrementButtonTouchedUp = true;
    }
    
    /** press and hold */
    @IBAction func handleCentIncrementButtonTouchDown(_ sender: UIButton)
    {
        guard(_semitones < _semitoneMax && _cents < _centMax) else{   return; }
        
        _centIncrementButtonTouchedUp = false;
        
        OperationQueue().addOperation
        {
            self._cents += 0.01;
            DispatchQueue.main.async{   self.updateCent();  }
            Thread.sleep(forTimeInterval: TimeInterval(self._buttonSleepInterval));
            if(!self._centIncrementButtonTouchedUp){    self.handleCentIncrementButtonTouchDown(sender);   }
        }
    }
    
    /** touch up */
    @IBAction func handleCentInccrementButton(_ sender: UIButton)
    {
        guard(_semitones < _semitoneMax && _cents < _centMax) else{   return; }
        
        // use public getter/setter to set private _pitch member
        updateCent();
        _centIncrementButtonTouchedUp = true;
    }
    
    private func updateCent()
    {
        if(_cents > 0){  _centValueLabel.text = "+" + (Int(_cents * 100)).description;    }
        else{   _centValueLabel.text = (Int(_cents * 100)).description;  }
        
        _delegate.passCents(cents: _cents);
    }
    
    @IBAction func _handleResetButton(_ sender: UIButton)
    {
        _semitones = 0;
        _cents = 0.0;
        
        _semitoneValueLable.text = "0";
        _centValueLabel.text = "0";
        _delegate.passCents(cents: _cents);
        _delegate.passSemitones(tones: _semitones);
    }
}
