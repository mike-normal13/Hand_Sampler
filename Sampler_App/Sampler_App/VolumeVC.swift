//
//  VolumeVC.swift
//  Sampler_App
//
//  Created by Budge on 10/31/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit
import Foundation

//  TODO: implement the handling of the _isVisible
//  DEBUG:  1/19/2018
//              rotated view is not acceptable
//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

protocol VolumeControlContainerViewParentProtocol: class
{
    func volumeTouchBegan(y: CGFloat);
    func passVerticalTouchMoves(y: CGFloat);
    func volumeTouchEnded(y: CGFloat);
}

/** lets the user adjust the volume for a given pad */
class VolumeViewController: UIViewController
{
    private let _debugFlag = false;
    
    @IBOutlet weak var _previewButton: UIButton!
    @IBOutlet weak var _volumeValueLabel: UILabel!
    @IBOutlet weak var _dbDecrementButton: UIButton!
    @IBOutlet weak var _dbIncrementButton: UIButton!
    @IBOutlet weak var _backButton: UIButton!
    @IBOutlet weak var _volumeResetButton: UIButton!
    
    @IBOutlet weak var _volumeControlContainerView: VolumeControlContainerView!;
    
    /** reflects the top position of the volume rectangle */
    private var _innerVolumePosition: CGFloat! = nil;
    private var _volumeViewOriginY: CGFloat! = nil;
    
    /** the position where we touch down when starting to drag the volume control */
    private var _volumeTouchStartingY: CGFloat! = nil;
    
    private let _maxVolume = 12;
    private let _minVolume = -48;
    
    private var _conversionFactor: CGFloat = -1
    
    private var _volume: Double! = nil;
    var volume: Double!
    {
        get{    return _volume;   }
        set{    _volume = newValue; }
    }

    weak var _delegate: VolumeVCParentProtocol! = nil;
    
    private var _numberFormatter: NumberFormatter! = nil;
    
    override func loadView()
    {
        super.loadView()
        
        _conversionFactor = _volumeControlContainerView.frame.height / CGFloat(_maxVolume + 1 + abs(_minVolume));
        
        _numberFormatter = NumberFormatter();
        _numberFormatter.numberStyle = .decimal;
        _numberFormatter.minimumFractionDigits = 2;
        _numberFormatter.maximumFractionDigits = 2;
        
        _volumeControlContainerView.layer.cornerRadius = 10;
        _volumeControlContainerView.clipsToBounds = true;
        
        var blurEffect = UIBlurEffect()

        //  http://belka.us/en/modal-uiviewcontroller-blur-background-swift/
        if #available(iOS 10.0, *){ blurEffect = UIBlurEffect(style: .prominent)  }
        else{   blurEffect = UIBlurEffect(style: .light);    }
        
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.frame
        view.backgroundColor = .clear

        self.view.insertSubview(blurEffectView, at: 0)
        
        _volumeControlContainerView._delegate = self;
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        // be defualt set the rectangel's y origin value to correspond to 0 DBs
        let zeroDBYPosition = dbsToYPosition(dbs: 0.0);
        
        //  we could not do this earlier for some reason....
        _volumeControlContainerView.volumePosition = zeroDBYPosition;
        _volumeControlContainerView.zeroDBReferencePoint = zeroDBYPosition;
    }
    
    deinit
    {
        _delegate = nil;
        _numberFormatter = nil;
        
        if(_debugFlag){ print("****** VolumeVC deinitialized")  }
    }
    
    @IBAction func handlePreviewButton(_ sender: UIButton){ _delegate.passVolumePreview();    }
   
    /** touch up */
    @IBAction func handleDbDecrementButton(_ sender: UIButton)
    {
        if (_volume >= Double(_minVolume + 1))
        {
            _volume! -= 1.0;
            intervalButtonSetVolume();
        }
    }
    
    /** touch up */
    @IBAction func handleDbIncrementButton(_ sender: UIButton)
    {
        if(_volume <= Double(_maxVolume - 1))
        {
            _volume! += 1.0;
            intervalButtonSetVolume();
        }
    }
    
    private func intervalButtonSetVolume()
    {
        _volumeValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _volume))! + " db";
        _delegate.passVolume(volume: Float(_volume));
    
        _volumeControlContainerView.volumePosition = dbsToYPosition(dbs: _volume)
        _volumeControlContainerView.volumeHeight =  _volumeControlContainerView.frame.height - _volumeControlContainerView.volumePosition;
        _volumeControlContainerView.stopVolumePosition = _volumeControlContainerView.volumePosition;
    }
    
    /** touch up */
    @IBAction func handleVolumeResetButton(_ sender: UIButton)
    {
         let zeroY = dbsToYPosition(dbs: 0.0);
        
        _volume = 0;
        _volumeValueLabel.text = "0.0 db";
        _delegate.passVolume(volume: Float(0));
        
        _volumeControlContainerView.volumePosition = zeroY;
        _volumeControlContainerView.volumeHeight =  _volumeControlContainerView.frame.height - _volumeControlContainerView.volumePosition;
        _volumeControlContainerView.stopVolumePosition = _volumeControlContainerView.volumePosition;
    }
    
    @IBAction func handleBackButton(_ sender: UIButton){    _delegate.dismissVolumeVC();  }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {   print("y: " + (touches.first?.location(in: self.view).y.description)!); }
    
    /** convert a vertical y position to a decible value */
    private func yPositionToDBs(position: CGFloat) -> Double
    {
        let decibleSpan = _maxVolume + 1 + abs(_minVolume)
        let volumeContainerHeight = _volumeControlContainerView.frame.height;
        
        var rawVolume = (volumeContainerHeight - position) * (CGFloat(decibleSpan)/volumeContainerHeight);
        
        if(rawVolume > CGFloat(decibleSpan - _maxVolume))
        {   rawVolume = CGFloat(_maxVolume) - (CGFloat(decibleSpan) - rawVolume);   }
        else if(rawVolume < CGFloat(1 + decibleSpan - _maxVolume))
        {   rawVolume = -(CGFloat(decibleSpan) - rawVolume - CGFloat(_maxVolume + 1));   }
        else{   rawVolume = 0;   }
        
        return Double(rawVolume);
    }
    
    /** convert a decible to a vertical y position */
    func dbsToYPosition(dbs: Double) -> CGFloat
    {
        // +12 dbs to -48 dbs
        let decibleSpan = _maxVolume + 1 + abs(_minVolume)
        var volumeContainerHeight: CGFloat = 0;
        
        volumeContainerHeight = _volumeControlContainerView.frame.height;
        
        if(dbs == 0)
        {
            let uVolume = CGFloat(decibleSpan - _maxVolume - 1);
            return volumeContainerHeight - (uVolume/(CGFloat(decibleSpan)/volumeContainerHeight));
        }
        else if(dbs >= 12){ return 0;   }
        else if(dbs <= -48){    return volumeContainerHeight;   }
        // else if volume is not min or max or zero dbs
        else
        {
            var tempVolume = 0.0;
            
            if(dbs > 0){    tempVolume = Double(decibleSpan) - (Double(_maxVolume) - dbs);  }
            if(dbs < 0){    tempVolume = Double(decibleSpan) - (Double(_maxVolume) + 1 - dbs);  }
            
            return volumeContainerHeight - (CGFloat(tempVolume)/(CGFloat(decibleSpan)/volumeContainerHeight));
        }
    }
    
    /** this function assumes that the _volume member has been set from the outside by the padConfigVC
            set the volume control and label*/
    func setVolume()
    {
        let yPosition = dbsToYPosition(dbs: _volume);
        
        _volumeControlContainerView.volumeHeight = _volumeControlContainerView.frame.height - yPosition;
        _volumeControlContainerView.volumePosition = yPosition;
        _volumeControlContainerView.stopVolumePosition = yPosition;
        
        _volumeValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _volume))! + " db";
    }
}//************************************************** END OF VOLUME VIEW CONTROLLER **********************************************
//********************************************************************************************************************************

extension VolumeViewController: VolumeControlContainerViewParentProtocol
{
    func volumeTouchBegan(y: CGFloat){  _volumeTouchStartingY = y;  }
    
    func passVerticalTouchMoves(y: CGFloat){    setVolume(y: y);    }
    func volumeTouchEnded(y: CGFloat){  setVolume(y: y);    }
    
    /** this method is not define in the corresponding protocol above */
    private func setVolume(y: CGFloat)
    {
        // set control view
        _volume = yPositionToDBs(position: y);
        _volumeValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _volume))! + " db";
        //  This call results in saving to disk and adjusting the model
        _delegate.passVolume(volume: Float(_volume));
    }
}//********************************************************************************************************************************
//********************************************************************************************************************************

class VolumeControlContainerView: UIView
{
    let _debugFlag = true;
    
    private let _maxDB = 12;
    private let _minDB = -48;
    
    private var _zeroDBReferencePoint: CGFloat! = nil;
    var zeroDBReferencePoint: CGFloat!
    {
        get{    return _zeroDBReferencePoint;   }
        set{    _zeroDBReferencePoint = newValue;   }
    }
    
    /** the starting position of the user's drag touch */
    private var _startingYTouch: CGFloat!
    
    /** corresponds to the y origin position of the white rectangle */
    private var _volumePosition: CGFloat! = nil
    var volumePosition: CGFloat!
    {
        get{    return _volumePosition; }
        set
        {
            _volumePosition = newValue;
            _volumeControlView.frame.origin.y = _volumePosition;
            
            // max
            if(_volumePosition <= 0)
            {
                _volumePosition = 0
                _volumeControlView.frame.origin.y = 0
            }
                // min
            else if(_volumePosition >= frame.height)
            {
                _volumePosition = frame.height;
                _volumeControlView.frame.origin.y = frame.height;
            }
        }
    }
    
    /** height of the white volume rectangle */
    private var _volumeHeight: CGFloat! = nil
    var volumeHeight: CGFloat
    {
        get{    return _volumeHeight;   }
        set
        {
            _volumeHeight = newValue;
            _volumeControlView.frame.size.height = newValue;
        }
    }

    /** when we touch up,
            this value is set to the position of the origin of the white rectangle */
    private var _stopVolumePosition: CGFloat! = nil
    var stopVolumePosition: CGFloat
    {
        get{    return _stopVolumePosition; }
        set{    _stopVolumePosition = newValue; }
    }
    
    /** white rectangle
            top edge indicates the current volume level in decibles */
    @IBOutlet weak var _volumeControlView: UIView!;
    
    weak var _delegate: VolumeControlContainerViewParentProtocol! = nil;
    
    deinit{ _delegate = nil;    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        _startingYTouch = touches.first?.location(in: self).y;
        _delegate.volumeTouchBegan(y: _startingYTouch);
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(touches.first?.location(in: self).y != _startingYTouch)
        {
            let containerHeight = frame.height;
            let volumeHeight = _volumeControlView.frame.height;
            let localStopVolumePosition: CGFloat;
            let startingDiff = (touches.first?.location(in: self).y)! - _startingYTouch;
            let containerDiff = containerHeight - (volumeHeight - (_zeroDBReferencePoint - _volumePosition));
        
            localStopVolumePosition = _stopVolumePosition;
    
            //  DEBUG: i'm pretty sure this calculation is the cause of the little jump.....
            let referenceDiff = localStopVolumePosition - _zeroDBReferencePoint
            
            //public setter adjusts the white rectangle's y origin point.
            volumePosition = startingDiff + containerDiff + referenceDiff;
            self.volumeHeight = containerHeight - volumePosition;
            
            _delegate.passVerticalTouchMoves(y: volumePosition);
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        _stopVolumePosition = _volumePosition;
        _delegate.volumeTouchEnded(y: volumePosition);
        
        if(_debugFlag)
        {
            print("ended y in volume control: " + (touches.first?.location(in: self).y.description)!);
            print("volumePosition at touch up: " + _volumePosition.description);
        }
    }
}
