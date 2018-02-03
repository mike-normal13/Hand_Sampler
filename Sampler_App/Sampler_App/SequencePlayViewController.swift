//
//  SequencePlayViewController.swift
//  Sampler_App
//
//  Created by mike on 2/27/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit

//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

class SequencePlayViewController: SamplerVC
{
    private let _debugFlag = false;
    
    //  TODO: this value is not passed down!
    private var _nBanks = 3;
    
    private var _sequenceArray: [Int]! = nil;
    
    /** loads a recorded sample sequence from disk */
    private var _sequenceLoader: SequenceLoader! = SequenceLoader();
    
    @IBOutlet weak var _infoButton: UIButton!
    
    @IBOutlet weak var _buttonStackView: UIStackView!
    @IBOutlet weak var _resetButton: UIButton!
    
    @IBOutlet weak var _bank1Button: UIButton!
    @IBOutlet weak var _bank2Button: UIButton!
    @IBOutlet weak var _bank3Button: UIButton!
    
    /** aids with locking */
    private var _button1TouchDown = false;
    private var _button2TouchDown = false;
    private var _button3TouchDown = false;
    
    private var _currentPlayIndex: Int = 0;
    
    weak var _delegate: SequencePlayParentProtocol! = nil;
    
    var _combinedColors: UIColor! = UIColor();
    
    private var _backToBankVCSwipeGestureRecognizer: UISwipeGestureRecognizer! = nil
    private var _bankButtonLockGestureArray: [UILongPressGestureRecognizer?] = [];
    
    /** the bank which is currently locked */
    private var _lockIndex = -1;
    /** required time for lock to activate via touch */
    private let _lockDuration: Double = 0.35
    
    override func loadView()
    {
        super.loadView();
        
        initLongPressGestureArray();
        
        _backToBankVCSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleBackToBankVCSwipeGestureRecognizer))
        
        _buttonStackView.addGestureRecognizer(_backToBankVCSwipeGestureRecognizer)
        
        _infoButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2);
        _infoButton.layer.borderWidth = 1;
        _infoButton.layer.borderColor = UIColor.black.cgColor;
        _infoButton.layer.cornerRadius = 5;
        
        _resetButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2);
        _resetButton.layer.borderWidth = 1;
        _resetButton.layer.borderColor = UIColor.black.cgColor;
        _resetButton.layer.cornerRadius = 5;
        
        _bank1Button.layer.borderWidth = 1;
        _bank1Button.layer.borderColor = UIColor.black.cgColor;
        _bank1Button.layer.cornerRadius = 5;
        _bank1Button.addGestureRecognizer(_bankButtonLockGestureArray[_bank1Button.tag]!);
        
        _bank2Button.layer.borderWidth = 1;
        _bank2Button.layer.borderColor = UIColor.black.cgColor;
        _bank2Button.layer.cornerRadius = 5;
        _bank2Button.addGestureRecognizer(_bankButtonLockGestureArray[_bank2Button.tag]!);
        
        _bank3Button.layer.borderWidth = 1;
        _bank3Button.layer.borderColor = UIColor.black.cgColor;
        _bank3Button.layer.cornerRadius = 5;
        _bank3Button.addGestureRecognizer(_bankButtonLockGestureArray[_bank3Button.tag]!);
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        _isVisible = true;
        
        UIApplication.shared.isIdleTimerDisabled = true;
        
        _sequenceArray = _sequenceLoader.loadSequence(songName: _songName, bank: _bankNumber);
        _currentPlayIndex = 0;
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        // adjust current bank button color
        if(self._bankNumber == 1)   // duplicate
        {
            self._bank1Button.backgroundColor = .darkGray;  // duplicate
            self._bank2Button.backgroundColor = .lightGray; // duplicate
            self._bank3Button.backgroundColor = .lightGray; // duplicate
        }
        else if(self._bankNumber == 2)  // duplicate
        {
            self._bank1Button.backgroundColor = .lightGray; // duplicate
            self._bank2Button.backgroundColor = .darkGray;  // duplicate
            self._bank3Button.backgroundColor = .lightGray; // duplicate
        }
        else    // duplicate
        {
            assert(self._bankNumber == 3);  // duplicate
            self._bank1Button.backgroundColor = .lightGray; // duplicate
            self._bank2Button.backgroundColor = .lightGray; // duplicate
            self._bank3Button.backgroundColor = .darkGray;  // duplicate
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        _isVisible = false;
        _delegate.sequenceStopAllPads();
        _delegate.cancelPlayThrough();
    }
    
    deinit
    {
        _combinedColors = nil;
        _sequenceArray = nil;
        _sequenceLoader = nil;
        
        _delegate = nil;
        _backToBankVCSwipeGestureRecognizer = nil;
        
        for bank in 0 ..< _nBanks
        {
            _bankButtonLockGestureArray[bank] = nil;
        }
        
        _bankButtonLockGestureArray = [];
        
        if(_debugFlag){ print("*** SequencePlayVC deinitialized");  }
    }
    
    private func initLongPressGestureArray()
    {
        _bankButtonLockGestureArray.append(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressButton1(_:))));
        _bankButtonLockGestureArray.append(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressButton2(_:))));
        _bankButtonLockGestureArray.append(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressButton3(_:))));
        
        for bank in 0 ..< _nBanks
        {
            _bankButtonLockGestureArray[bank]?.minimumPressDuration = _lockDuration;
        }
    }
    
    /** lock/unlock bank 1 */
    @objc func handleLongPressButton1(_ sender: UILongPressGestureRecognizer)
    {
        if(_bankNumber == 1)
        {
            if(sender.state == .began){ _bank1Button.backgroundColor = .orange; }
            
            if(sender.state == .ended)
            {
                if(!_button1TouchDown)
                {
                    if(_lockIndex == -1)
                    {
                        _bank2Button.isEnabled = false;
                        _bank2Button.isHidden = true;
                        _bank3Button.isEnabled = false;
                        _bank3Button.isHidden = true;
                        _backToBankVCSwipeGestureRecognizer.isEnabled = false;
                        _lockIndex = 0;                                         // zero indexed
                        toggleInfoButtonEnabled(enabled: false);
                    }
                    else
                    {
                        _bank2Button.isEnabled = true;
                        _bank2Button.isHidden = false;
                        _bank3Button.isEnabled = true;
                        _bank3Button.isHidden = false;
                        _backToBankVCSwipeGestureRecognizer.isEnabled = true;
                        _lockIndex = -1;
                        toggleInfoButtonEnabled(enabled: true);
                    }
                }
                
                _bank1Button.backgroundColor = .darkGray;
            }
        }
    }
    
    @objc func handleLongPressButton2(_ sender: UILongPressGestureRecognizer)
    {
        if(_bankNumber == 2)
        {
            if(sender.state == .began){ _bank2Button.backgroundColor = .orange; }
            
            if(sender.state == .ended)
            {
                if(!_button2TouchDown)
                {
                    if(_lockIndex == -1)
                    {
                        _bank1Button.isEnabled = false;
                        _bank1Button.isHidden = true;
                        _bank3Button.isEnabled = false;
                        _bank3Button.isHidden = true;
                        _backToBankVCSwipeGestureRecognizer.isEnabled = false;
                        _lockIndex = 0;                                         // zero indexed
                        toggleInfoButtonEnabled(enabled: false);
                    }
                    else
                    {
                        _bank1Button.isEnabled = true;
                        _bank1Button.isHidden = false;
                        _bank3Button.isEnabled = true;
                        _bank3Button.isHidden = false;
                        _backToBankVCSwipeGestureRecognizer.isEnabled = true;
                        _lockIndex = -1;
                        toggleInfoButtonEnabled(enabled: true);
                    }
                }
                
                _bank2Button.backgroundColor = .darkGray;
            }
        }
    }
    
    @objc func handleLongPressButton3(_ sender: UILongPressGestureRecognizer)
    {
        if(_bankNumber == 3)
        {
            if(sender.state == .began)
            {
                _bank3Button.backgroundColor = .orange;
            }
            
            if(sender.state == .ended)
            {
                if(!_button3TouchDown)
                {
                    if(_lockIndex == -1)
                    {
                        _bank1Button.isEnabled = false;
                        _bank1Button.isHidden = true;
                        _bank2Button.isEnabled = false;
                        _bank2Button.isHidden = true;
                        _backToBankVCSwipeGestureRecognizer.isEnabled = false;
                        _lockIndex = 0;                                         // zero indexed
                        toggleInfoButtonEnabled(enabled: false);
                    }
                    else
                    {
                        _bank1Button.isEnabled = true;
                        _bank1Button.isHidden = false;
                        _bank2Button.isEnabled = true;
                        _bank2Button.isHidden = false;
                        _backToBankVCSwipeGestureRecognizer.isEnabled = true;
                        _lockIndex = -1;
                        toggleInfoButtonEnabled(enabled: true);
                    }
                }
                
                _bank3Button.backgroundColor = .darkGray;
            }
        }
    }
    
    private func toggleInfoButtonEnabled(enabled: Bool){    _infoButton.isHidden = !enabled;    }
    
    /** present the info screen for this VC */
    @IBAction func handleInfoButton(_ sender: UIButton)
    {
        let sequenceInfoVC = self.storyboard?.instantiateViewController(withIdentifier: "SequenceInfoVC") as! SequenceInfoScreenViewController;
        navigationController?.pushViewController(sequenceInfoVC, animated: true);
    }
    
    @IBAction func _handleResetButton(_ sender: UIButton) { _currentPlayIndex = 0;  }
    
    /** corresponds to touch up */
    @IBAction func _handleBank1Button(_ sender: UIButton){  if(_bankNumber != 1){   _delegate.switchSequenceBank(bank: 1);  }   }
    /** corresponds to touch up */
    @IBAction func _handleBank2Button(_ sender: UIButton){  if(_bankNumber != 2){   _delegate.switchSequenceBank(bank: 2);    } }
    /** corresponds to touch up */
    @IBAction func _handleBank3Button(_ sender: UIButton){  if(_bankNumber != 3){   _delegate.switchSequenceBank(bank: 3);    } }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(!_routeIsChanging)
        {
            self._delegate.sequenceTouch(pad: self._sequenceArray[self._currentPlayIndex]);
            
            if(_currentPlayIndex == 0){ view.backgroundColor = .red;    }
            else{   view.backgroundColor = .blue;   }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(!routeIsChanging)
        {
            self._currentPlayIndex = self._currentPlayIndex == (self._sequenceArray.count - 1) ? 0 : self._currentPlayIndex + 1;
        
            if(self._currentPlayIndex == 0){    self._delegate.sequenceStop(pad: self._sequenceArray[self._sequenceArray.count - 1]);   }
            else{   self._delegate.sequenceStop(pad: self._sequenceArray[self._currentPlayIndex - 1]);  }
            
            view.backgroundColor = .yellow;
        }
    }
    
    @objc func handleBackToBankVCSwipeGestureRecognizer(){  navigationController?.popViewController(animated: true)    }
    
    //  TODO: as of 1/11/2018
    //          this might be a useful strategy in the future
    //              but we are not going to use it in the intial submission.
    //    //  https://stackoverflow.com/questions/34383678/animate-uiview-background-color-swift
    //    @objc func getRandomColor()
    //    {
    //        let red   = CGFloat((arc4random() % 256)) / 255.0;
    //        let green = CGFloat((arc4random() % 256)) / 255.0;
    //        let blue  = CGFloat((arc4random() % 256)) / 255.0;
    //        let alpha = CGFloat(1.0);
    //
    //        UIView.animate(withDuration: 0.1, delay: 0.0, options:[/*.repeat,*/ .autoreverse], animations:
    //        {
    //            //DispatchQueue.main.async
    //            //{
    //                self.view.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
    //            //}
    //        }, completion: nil)
    //    }
}
