//
//  StartingPointVC.swift
//  Sampler_App
//
//  Created by Budge on 10/31/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit
import AVFoundation

//  TODO: implement the handling of the _isVisible
//  DEBUG:  1/19/2018
//              rotated view is not acceptable
//  TODO: 1/24/2018 revise all try catch blocks

protocol InfoScreenParentProtocol: class
{   func popInfoScreen();   }

protocol StartingPointControlContainerViewParentProtocol: class
{
    func startPointTouchBegan(y: CGFloat);
    func passStartPointVerticalTouchMoves(y: CGFloat);
    func startPointTouchEnded(y: CGFloat);
    func setStartPointIsBeingAdjusted(adjusted: Bool);
}

protocol EndingPointControlContainerViewParentProtocol: class
{
    func endPointTouchBegan(y: CGFloat);
    func passEndPointVerticalTouchMoves(y: CGFloat);
    func endPointTouchEnded(y: CGFloat);
    func setEndPointIsBeingAdjusted(adjusted: Bool);
}

/** alows the user to set where a pad ends and begins playback */
class EndPointsViewController: PadSettingVC
{
    private let _debugFlag = false;
    
    @IBOutlet weak var _backButton: UIButton!
    @IBOutlet weak var _infoButton: UIButton!
    @IBOutlet weak var _previewButton: UIButton!
    
    @IBOutlet weak var _start10thDecrementButton: UIButton!
    @IBOutlet weak var _start10thIncrementButton: UIButton!
    @IBOutlet weak var _start100thDecrementButon: UIButton!
    @IBOutlet weak var _start100thIncrementButton: UIButton!
    @IBOutlet weak var _startPointValueLabel: UILabel!
    
    @IBOutlet weak var _end10thDecrementButton: UIButton!
    @IBOutlet weak var _end10thIncrementButton: UIButton!
    @IBOutlet weak var _end100thDecrementButton: UIButton!
    @IBOutlet weak var _end100thIncrementButton: UIButton!
    @IBOutlet weak var _endPointValueLabel: UILabel!
    
    @IBOutlet weak var _activityIndicator: UIActivityIndicatorView!
    
    /** gray rectangle which contains the white rectangle,
            lets the user adjust the starting point */
    @IBOutlet weak var _startPointControlContainerView: StartingPointControlContainerView!
    /** gray rectangle which contains the white rectangle which corresponds to the enpoint of playback */
    @IBOutlet weak var _endPointControlContainerView: EndingPointControlContainerView!
    
    private var _startPointTouchStartingY: CGFloat = -1;
    private var _endPointTouchStartingY: CGFloat = -1;
    
    /** the smallest allowable difference between the end and start points for a pad
     we found that letting the user have endPoint == startPoint made things go haywire. */
    private let _minimumInterval: Double = 0.01;
    
    private var _numberFormatter: NumberFormatter! = nil; // for labels
    
    weak var _delegate: EndPointsVCParentProtocol! = nil;
    
    /** we need this value in order to set the max and min values for the the start/end point sliders */
    private var _fileLength: Double! = nil;
    var fileLength: Double
    {
        get{    return _fileLength; }
        set{    _fileLength = newValue; }
    }
    
    private var _startingPoint: Double! = nil
    var startingPoint: Double
    {
        get{    return _startingPoint; }
        set
        {
            _startingPoint = newValue
            _startPointValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _startingPoint))! + " s"
        }
    }
    
    private var _endPoint: Double! = nil
    var endPoint: Double
    {
        get{    return _endPoint; }
        set
        {
            _endPoint = newValue
            _endPointValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _endPoint))! + " s"
        }
    }
    
    private var _previewIsCanceled = false;
    
    private enum _Intervals: Double
    {
        case hundredth = 0.01;
        case tenth = 0.1;
        case half = 0.5; // unused as of 12/15/2017
        case one = 1.0; // unused as of 12/15/2017
    }
    
    override func loadView()
    {
        super.loadView();
        
        _activityIndicator.hidesWhenStopped = true;
        _activityIndicator.color = .black
        
        _numberFormatter = NumberFormatter();
        _numberFormatter.numberStyle = .decimal;
        _numberFormatter.minimumFractionDigits = 2;
        _numberFormatter.maximumFractionDigits = 2;
        
        var blurEffect = UIBlurEffect();
        
        //  http://belka.us/en/modal-uiviewcontroller-blur-background-swift/
        if #available(iOS 10.0, *){ blurEffect = UIBlurEffect(style: .prominent)  }
        else{   blurEffect = UIBlurEffect(style: .light);   }
        
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.frame
        
        view.backgroundColor = .clear;
        
        self.view.insertSubview(blurEffectView, at: 0)
        
        _startPointControlContainerView._delegate = self;
        _endPointControlContainerView._delegate = self;
        
        _startPointControlContainerView.clipsToBounds = true
        _endPointControlContainerView.clipsToBounds = true
        
        _startPointControlContainerView.layer.cornerRadius = 10;
        _endPointControlContainerView.layer.cornerRadius = 10;
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        _startPointControlContainerView.minimumYInterval = Double(startingPointSecondsToYPosition(seconds: _minimumInterval));
        _endPointControlContainerView.minimumYInterval = Double(endingPointSecondsToYPosition(seconds: _minimumInterval));
    }
    
    deinit
    {
        _opQueue = nil;
        _delegate = nil;
        _numberFormatter = nil;
        _startPointControlContainerView = nil;
        _endPointControlContainerView = nil;
        _activityIndicator = nil;
        
        if(_debugFlag){ print("**** EndpointsVC deintialized"); }
    }
    
    @IBAction func handleBackButton(_ sender: UIButton){    _delegate.dismissEndPointsVC(); }
    @IBAction func handleInfoButton(_ sender: UIButton)
    {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil);
        let infoScreen = storyBoard.instantiateViewController(withIdentifier: "EndpointsInfoVC") as! EndpointsInfoScreenViewController;
        
        infoScreen._delegate = self;
        
        present(infoScreen, animated: true, completion: nil);
    }
    
    @IBAction func handlePreviewButton(_ sender: UIButton){ _delegate.passEndPointsPreview();   }
    
    /** adjust the starting point via the starting point control.
     We are only alowing the starting point,
     via control manipulation,
     to come within no less of the _minimumInterval of the end point. */
    private func handleStartingPointControl(y: CGFloat)
    {
        if(_opQueue == nil){    _opQueue = OperationQueue();    }

        cancelPreview();
        
        // value of _startingPoint is adjusted in checkForMinimumInterval()
        checkForMinimumInterval(adjustment: Double(y), start: true, button: false);
        
        _startPointValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _startingPoint))! + " s";
    }

    private func handleStartPointControlRelease(y: CGFloat)
    {
        _previewIsCanceled = false;
        
        if(_opQueue == nil){    _opQueue = OperationQueue();    }
        
        _opQueue.addOperation
        {
            DispatchQueue.main.async
            {
                UIApplication.shared.beginIgnoringInteractionEvents();
                self._activityIndicator.startAnimating();
            }
        }
        
        // update model
        // pass new value up to the sound mod
        //  Thread for faster UI Updating
        _opQueue.addOperation
        {
            self._delegate.passStartPoint(start: self._startingPoint);
            
            DispatchQueue.main.async
            {
                self._activityIndicator.stopAnimating();
                UIApplication.shared.endIgnoringInteractionEvents();
            }
        }
    }
    
    /** adjust start point label
     send call up chain.
     THis method is called when ever one of the increment or decrement buttons is called for the starting point.
     manipulating the starting point slider does not result in this method being called.*/
    private func updateStartPoint()
    {
        //make it so the endpoint slider cannot be manipulated while the file buffer is being adjusted.
        _endPointControlContainerView.startPointIsBeingAdjusted = true;
        
        _startPointControlContainerView.startPointHeight = startingPointSecondsToYPosition(seconds: _startingPoint);
        _startPointControlContainerView.stopStartPointPosition = _startPointControlContainerView.startPointHeight;

        if(_opQueue == nil){    _opQueue = OperationQueue();    }

        _opQueue.addOperation
        {
            DispatchQueue.main.async
            {
                UIApplication.shared.beginIgnoringInteractionEvents();
                self._activityIndicator.startAnimating();
            }
        }

        _opQueue.addOperation
        {
            self._delegate.passStartPoint(start: self._startingPoint);

            DispatchQueue.main.async
            {
                self._activityIndicator.stopAnimating();
                UIApplication.shared.endIgnoringInteractionEvents();
            }
        }
        
        _previewIsCanceled = false;
        _endPointControlContainerView.startPointIsBeingAdjusted = false;
    }
    
    /** handle both 10th and 100th decrements */
    private func handleStartingPointDecrementButton(interval: Double)
    {
        guard(_startingPoint - interval >= 0)   else    {   return; }
        
        cancelPreview();
        
        // public setter updates label
        startingPoint -= interval;
        updateStartPoint();
    }
    
    /** handle both 10th and 100th increments */
    private func handleStartingPointIncrementButton(interval: Double)
    {
        // only increment the starting point by 0.01 seconds if the current interval between start and enpoints is greater than 0.01 seconds
        guard(_startingPoint + interval <= _endPoint)   else{   return; }
        
        cancelPreview();
    
        startingPoint += interval;
        checkForMinimumInterval(adjustment: _startingPoint, start: true, button: true);
        updateStartPoint();
    }
    
    /** Touch Down */
    @IBAction func handleStart10thDecrementButtonTouchDown(_ sender: UIButton)
    {
        setBothDragControlsEnabled(enabled: true);
        
        _start10thIncrementButton.isEnabled = false;
        _start100thDecrementButon.isEnabled = false;
        _start100thIncrementButton.isEnabled = false;
        
        setAllEndpointButtonsEnabled(enabled: false);
    }
    
    /** Touch up */
    @IBAction func handleStart10thDecrementButton(_ sender: UIButton)
    {
        handleStartingPointDecrementButton(interval: (_Intervals.tenth.rawValue));
        
        setBothDragControlsEnabled(enabled: false);
        
        _start10thIncrementButton.isEnabled = true;
        _start100thDecrementButon.isEnabled = true;
        _start100thIncrementButton.isEnabled = true;
        
        setAllEndpointButtonsEnabled(enabled: true);
    }
    
    
    /** Touch Down */
    @IBAction func handleStart10thIncrementButtonTouchDown(_ sender: UIButton)
    {
        setBothDragControlsEnabled(enabled: true);
        
        _start10thDecrementButton.isEnabled = false;
        _start100thDecrementButon.isEnabled = false;
        _start100thIncrementButton.isEnabled = false;
        
        setAllEndpointButtonsEnabled(enabled: false);
    }
    
    /** Touch up */
    @IBAction func handleStart10thIncrementButton(_ sender: UIButton)
    {
        handleStartingPointIncrementButton(interval: (_Intervals.tenth.rawValue));
        
        setBothDragControlsEnabled(enabled: false);
        
        _start10thDecrementButton.isEnabled = true;
        _start100thDecrementButon.isEnabled = true;
        _start100thIncrementButton.isEnabled = true;
        
        setAllEndpointButtonsEnabled(enabled: true);
    }
    
    
    /** Touch Down */
    @IBAction func handleStart100thDecrementButtonTouchDown(_ sender: UIButton)
    {
        setBothDragControlsEnabled(enabled: true);
        
        _start10thDecrementButton.isEnabled = false;
        _start10thIncrementButton.isEnabled = false;
        
        _start100thIncrementButton.isEnabled = false;
        
        setAllEndpointButtonsEnabled(enabled: false)
    }
    
    /** Touch up */
    @IBAction func handleStart100thDecrementButton(_ sender: UIButton)
    {
        handleStartingPointDecrementButton(interval: (_Intervals.hundredth.rawValue));
        
        setBothDragControlsEnabled(enabled: false);
        
        _start10thDecrementButton.isEnabled = true;
        _start10thIncrementButton.isEnabled = true;
        _start100thIncrementButton.isEnabled = true;
        
        setAllEndpointButtonsEnabled(enabled: true);
    }
    
    /** Touch Down */
    @IBAction func handleStart100thIncrementButtonTouchDown(_ sender: UIButton)
    {
        setBothDragControlsEnabled(enabled: true);
        
        _start10thDecrementButton.isEnabled = false;
        _start10thIncrementButton.isEnabled = false;
        _start100thDecrementButon.isEnabled = false;
        
        setAllEndpointButtonsEnabled(enabled: false);
    }
    
    /** Touch up */
    @IBAction func handleStart100thIncrementButton(_ sender: UIButton)
    {
        handleStartingPointIncrementButton(interval: (_Intervals.hundredth.rawValue));
        
        setBothDragControlsEnabled(enabled: false);
        
        _start10thDecrementButton.isEnabled = true;
        _start10thIncrementButton.isEnabled = true;
        _start100thDecrementButon.isEnabled = true;
        
        setAllEndpointButtonsEnabled(enabled: true);
    }
    
    /** takes in a y position */
    private func handleEndingPointControl(y: CGFloat)
    {
        if(_opQueue == nil){    _opQueue = OperationQueue();    }

        cancelPreview();
                
        checkForMinimumInterval(adjustment: Double(y), start: false, button: false);
        _endPointValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _endPoint))! + " s";
    }
    
    private func handleEndingPointControlRelease(y: CGFloat)
    {
        _previewIsCanceled = false;
        
        if(_opQueue == nil){    _opQueue = OperationQueue() }
        
        _opQueue.addOperation
        {
            DispatchQueue.main.async
            {
                UIApplication.shared.beginIgnoringInteractionEvents();
                self._activityIndicator.startAnimating();
            }
        }

        _opQueue.addOperation
        {
            self._delegate.passEndPoint(end: self.endPoint)

            DispatchQueue.main.async
            {
                self._activityIndicator.stopAnimating();
                UIApplication.shared.endIgnoringInteractionEvents();
            }
        }
    }
    
    /** called as a result of one of the endpoint buttons being pressed */
    private func updateEndPoint()
    {
        // make it so the start point drag control cannot be manipiulated while the file buffer is being adjusted on the model side.
        _startPointControlContainerView.endPointIsBeingAdjusted = true;
        
        _endPointControlContainerView.endPointPosition = endingPointSecondsToYPosition(seconds: _endPoint);
        _endPointControlContainerView.stopEndPointPosition = _endPointControlContainerView.endPointPosition;
        _endPointControlContainerView.endPointHeight = _endPointControlContainerView.frame.height - _endPointControlContainerView.stopEndPointPosition;
        
        if(_opQueue == nil){    _opQueue = OperationQueue();    }

        _opQueue.addOperation
        {
            DispatchQueue.main.async
            {
                UIApplication.shared.beginIgnoringInteractionEvents();
                self._activityIndicator.startAnimating();
            }
        }

        _opQueue.addOperation
        {
            self._delegate.passStartPoint(start: self._startingPoint);

            DispatchQueue.main.async
            {
                self._activityIndicator.stopAnimating();
                UIApplication.shared.endIgnoringInteractionEvents();
            }
        }
        
        _previewIsCanceled = false;
        _startPointControlContainerView.endPointIsBeingAdjusted = false;
    }
    
    private func handleEndingPointDecrementButton(interval: Double)
    {
        guard(_endPoint - interval >= _startingPoint)   else{  return; }
        
        cancelPreview();
        
        // public setter updates UI
        endPoint -= interval;
        checkForMinimumInterval(adjustment: _endPoint, start: false, button: true);
        updateEndPoint();
    }
    
    private func handleEndingPointIncrementButton(interval: Double)
    {
        guard(_endPoint + interval <= _fileLength)  else{   return; }
        
        cancelPreview();
        
        // public setter updates UI
        endPoint += interval;
        updateEndPoint();
    }

    /** Touch Down */
    @IBAction func handleEnd10thDecrementButtonTouchDown(_ sender: UIButton)
    {
        setBothDragControlsEnabled(enabled: true);
        setAllStartPointButtonsEnabled(enabled: false);
        
        _end10thIncrementButton.isEnabled = false;
        _end100thDecrementButton.isEnabled = false;
        _end100thIncrementButton.isEnabled = false;
    }
    
    /** touch up */
    @IBAction func handleEnd10thDecrementButton(_ sender: UIButton)
    {
        handleEndingPointDecrementButton(interval: _Intervals.tenth.rawValue);
        
        setBothDragControlsEnabled(enabled: false);
        setAllStartPointButtonsEnabled(enabled: true);

        _end10thIncrementButton.isEnabled = true;
        _end100thDecrementButton.isEnabled = true;
        _end100thIncrementButton.isEnabled = true;
    }
    
    /** Touch Down */
    @IBAction func handleEnd10thIncrementButtonTouchDown(_ sender: UIButton)
    {
        setBothDragControlsEnabled(enabled: true);
        setAllStartPointButtonsEnabled(enabled: false);

        _end10thDecrementButton.isEnabled = false;
        _end100thDecrementButton.isEnabled = false;
        _end100thIncrementButton.isEnabled = false;
    }
    
    /** touch up */
    @IBAction func handleEnd10thIncrementButton(_ sender: UIButton)
    {
        handleEndingPointIncrementButton(interval: _Intervals.tenth.rawValue);
        
        setBothDragControlsEnabled(enabled: false);
        setAllStartPointButtonsEnabled(enabled: true);

        _end10thDecrementButton.isEnabled = true;
        _end100thDecrementButton.isEnabled = true;
        _end100thIncrementButton.isEnabled = true;
    }
    
    /** Touch Down */
    @IBAction func handleEnd100thDecrementButtonTouchDown(_ sender: UIButton)
    {
        setBothDragControlsEnabled(enabled: true);
        setAllStartPointButtonsEnabled(enabled: false);

        _end10thDecrementButton.isEnabled = false;
        _end10thIncrementButton.isEnabled = false;
        _end100thIncrementButton.isEnabled = false;
    }
    
    /** touch up */
    @IBAction func handleEnd100thDecrementButton(_ sender: UIButton)
    {
        handleEndingPointDecrementButton(interval: _Intervals.hundredth.rawValue);
        
        setBothDragControlsEnabled(enabled: false);
        setAllStartPointButtonsEnabled(enabled: true);

        _end10thDecrementButton.isEnabled = true;
        _end10thIncrementButton.isEnabled = true;
        _end100thIncrementButton.isEnabled = true;
    }
    
    /** Touch Down */
    @IBAction func handleEnd100thIncrementButtonTouchDown(_ sender: UIButton)
    {
        setBothDragControlsEnabled(enabled: true);
        setAllStartPointButtonsEnabled(enabled: false);

        _end10thDecrementButton.isEnabled = false;
        _end10thIncrementButton.isEnabled = false;
        _end100thDecrementButton.isEnabled = false;
    }
    
    /** touch up */
    @IBAction func handleEnd100thIncrementButton(_ sender: UIButton)
    {
        handleEndingPointIncrementButton(interval: _Intervals.hundredth.rawValue);
        
        setBothDragControlsEnabled(enabled: false);
        setAllStartPointButtonsEnabled(enabled: true);

        _end10thDecrementButton.isEnabled = true;
        _end10thIncrementButton.isEnabled = true;
        _end100thDecrementButton.isEnabled = true;
    }
    
    
    private func setBothDragControlsEnabled(enabled: Bool)
    {
        _startPointControlContainerView.endPointIsBeingAdjusted = enabled;
        _endPointControlContainerView.startPointIsBeingAdjusted = enabled;
    }
    
    private func setAllStartPointButtonsEnabled(enabled: Bool)
    {
        _start10thDecrementButton.isEnabled = enabled;
        _start10thIncrementButton.isEnabled = enabled;
        _start100thDecrementButon.isEnabled = enabled;
        _start100thIncrementButton.isEnabled = enabled;
    }
    
    private func setAllEndpointButtonsEnabled(enabled: Bool)
    {
        _end10thDecrementButton.isEnabled = enabled;
        _end10thIncrementButton.isEnabled = enabled;
        _end100thDecrementButton.isEnabled = enabled;
        _end100thIncrementButton.isEnabled = enabled;
    }
    
    private func setAllPointButtonsEnabled(enabled: Bool)
    {
        _start10thDecrementButton.isEnabled = !enabled;
        _start100thDecrementButon.isEnabled = !enabled;
        _start10thIncrementButton.isEnabled = !enabled;
        _start100thIncrementButton.isEnabled = !enabled;
        
        _end10thDecrementButton.isEnabled = !enabled;
        _end100thDecrementButton.isEnabled = !enabled;
        _end10thIncrementButton.isEnabled = !enabled;
        _end100thIncrementButton.isEnabled = !enabled;
    }
    
    /** we enforce a minimum interval between the start and endpoints for a pad.
     Not doing so seemed to have strange and unintended consequences */
    private func checkForMinimumInterval(adjustment: Double, start: Bool, button: Bool)
    {
        // if we're adjusting the start point
        if(start)
        {
            //  if the proposed starting point adjustment yields an interval smaller than the minimum interval...
            if(_endPoint - adjustment < _minimumInterval)
            {
                // enforce minimum interval,
                //  public setter updates view
                startingPoint = _endPoint - _minimumInterval;
            }
                // else if the proposed adjustment does not fall within the minimum interval...
            else
            {
                if(!button){    _startingPoint = adjustment;    }
            }
        }
            // else if we're adjusting the end point
        else
        {
            if(adjustment - _startingPoint < _minimumInterval)
            {
                //  public setter updates view.
                endPoint = _startingPoint + _minimumInterval;
            }
            else{   if(!button){    _endPoint = adjustment; }   }
        }
    }
    
    private func startingPointYPositionToSeconds(y: CGFloat) -> Double
    {
        return _fileLength * Double(y/_startPointControlContainerView.frame.height); // non snazzy
        //return _endPoint * Double(y/_startPointControlContainerView.frame.height);    // snazzy
    }
    
    private func startingPointSecondsToYPosition(seconds: Double) -> CGFloat
    {
        return _startPointControlContainerView.frame.height * CGFloat(seconds/_fileLength); // non snazzy
        //return _startPointControlContainerView.frame.height * CGFloat(seconds/_endPoint); // snazzy
    }
    
    private func endingPointYPositionToSeconds(y: CGFloat) -> Double
    {   return _fileLength * Double(y/_endPointControlContainerView.frame.height);  }
    
    private func endingPointSecondsToYPosition(seconds: Double) -> CGFloat
    {   return _endPointControlContainerView.frame.height * CGFloat(seconds/_fileLength);   }
    
    /** this funciton is called by padConfig as it is presenting this VC,
            assumes that the start point has been set by the PadConfigVC */
    func setStartPoint()
    {
        let yPosition = startingPointSecondsToYPosition(seconds: _startingPoint);
        _startPointControlContainerView.startPointHeight = yPosition
        _startPointControlContainerView.stopStartPointPosition = yPosition;
        _startPointValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _startingPoint))! + " s";
    }
    /** this funciton is called by padConfig as it is presenting this VC
            assumes that the start point has been set by the PadConfigVC*/
    func setEndPoint()
    {
        let yPosition = endingPointSecondsToYPosition(seconds: _endPoint);
        _endPointControlContainerView.endPointHeight = _endPointControlContainerView.frame.height - yPosition;
        _endPointControlContainerView.endPointPosition = yPosition;
        _endPointControlContainerView.stopEndPointPosition = yPosition;
        _endPointValueLabel.text = _numberFormatter.string(from: NSNumber(floatLiteral: _endPoint))! + " s";
    }
    
    /** if we are currently previewing a sound,
            cancel the preview,
                this call is made whenever one of the slide controls is manipulated,
                    or when one of the increment/decrement buttons is pushed */
    private func cancelPreview()
    {
        if(!_previewIsCanceled)
        {
            _previewIsCanceled = true;
            self._delegate.cancelEndPointPreview();
        }
    }
}//*************************************************** end of EndPointsViewController ********************************************
//**********************************************************************************************************************************

extension EndPointsViewController: StartingPointControlContainerViewParentProtocol
{
    func startPointTouchBegan(y: CGFloat){  _startPointTouchStartingY = y;  }
    func passStartPointVerticalTouchMoves(y: CGFloat)
    {
        handleStartingPointControl(y: CGFloat(startingPointYPositionToSeconds(y: y)));
        if(_startingPoint == _endPoint - _minimumInterval){ setStartPoint();    }
    }
    func startPointTouchEnded(y: CGFloat){  handleStartPointControlRelease(y: y);   }
    func setStartPointIsBeingAdjusted(adjusted: Bool)
    {
        _endPointControlContainerView.startPointIsBeingAdjusted = adjusted;
        setAllPointButtonsEnabled(enabled: adjusted);
    }
}

extension EndPointsViewController: EndingPointControlContainerViewParentProtocol
{
    func endPointTouchBegan(y: CGFloat){    _endPointTouchStartingY = y;    }
    func passEndPointVerticalTouchMoves(y: CGFloat)
    {
        // this call ultimately only afects bounds check with regards to the end point value label,
        //      it does not concern itself with the white ending point rectangle.
        handleEndingPointControl(y: CGFloat(endingPointYPositionToSeconds(y: y)));
        
        // prevent the drag control from going beyond the minimum interval
        if(_endPoint == _startingPoint + _minimumInterval){ setEndPoint();  }
    }
    
    func endPointTouchEnded(y: CGFloat){    handleEndingPointControlRelease(y: y)   }
    
    func setEndPointIsBeingAdjusted(adjusted: Bool)
    {
        _startPointControlContainerView.endPointIsBeingAdjusted = adjusted;
        setAllPointButtonsEnabled(enabled: adjusted)
    }
}//*************************************************** end of EndPointsViewController extensions *************************************
//**********************************************************************************************************************************

class StartingPointControlContainerView: UIView
{
    private let _debugFlag = true;
    
    @IBOutlet weak var _startingPointControlView: UIView!
    
    private var _minimumYInterval: Double = -1;
    var minimumYInterval: Double
    {
        get{    return _minimumYInterval;    }
        set{    _minimumYInterval = newValue;    }
    }
    
    /** the starting position of the user's drag touch */
    private var _startingYTouch: CGFloat!

    private var _startPointHeight: CGFloat = 0;
    var startPointHeight: CGFloat
    {
        get{    return _startPointHeight;   }
        set
        {
            //  Counterintuitive that this needs to be here,
            //      but we were seeing the case that if we dragged the start point to zero,
            //          we could not get the white rectangle to drag down again...
            _startingPointControlView.frame.origin.y = 0.0;
            
            _startPointHeight = newValue
            _startingPointControlView.frame.size.height = _startPointHeight;
            
            if(newValue <= 0)
            {
                _startPointHeight = 0
               _startingPointControlView.frame.size.height = 0
            }
            
            if(newValue >= frame.height - CGFloat(_minimumYInterval))
            {
                _startPointHeight = frame.height - CGFloat(_minimumYInterval);
                _startingPointControlView.frame.size.height = _startPointHeight
            }
        }
    }
    
    /** when we touch up,
     this value is set to the position of the max y of the white rectangle */
    private var _stopStartPointPosition: CGFloat! = nil
    var stopStartPointPosition: CGFloat
    {
        get{    return _stopStartPointPosition; }
        set{    _stopStartPointPosition = newValue; }
    }
    
    /** as of 1/5/2018
            trying to adjust the start and endpoints at the same time is a great way to make the app crash */
    private var _endPointIsBeingAdjusted = false;
    var endPointIsBeingAdjusted: Bool
    {
        get{    return _endPointIsBeingAdjusted;    }
        set{    _endPointIsBeingAdjusted = newValue;    }
    }
    
    weak var _delegate: StartingPointControlContainerViewParentProtocol! = nil;
    
    deinit
    {
        _delegate = nil;
        _startingPointControlView = nil;
        if(_debugFlag){ print("**** StartingPointControlContainerView deintialized");   }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(!_endPointIsBeingAdjusted)
        {
            _delegate.setStartPointIsBeingAdjusted(adjusted: true);
            _startingYTouch = touches.first?.location(in: self).y;
            _delegate.startPointTouchBegan(y: _startingYTouch);
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(!_endPointIsBeingAdjusted)
        {
            if(touches.first?.location(in: self).y != _startingYTouch)
            {
                let startingDiff = (touches.first?.location(in: self).y)! - _startingYTouch;
                startPointHeight = startingDiff + _stopStartPointPosition;
                _delegate.passStartPointVerticalTouchMoves(y: startPointHeight);
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(!_endPointIsBeingAdjusted)
        {
            _stopStartPointPosition = _startPointHeight
            _delegate.startPointTouchEnded(y: _startPointHeight);
        
            if(_debugFlag)
            {
                print("ended y in start point control: " + (touches.first?.location(in: self).y.description)!);
                print("startPointPosition at touch up: " + _startPointHeight.description);
            }
            
            _delegate.setStartPointIsBeingAdjusted(adjusted: false);
        }
    }
}//*************************************************** end of StartingPointControlContainerView ********************************************
//**********************************************************************************************************************************

class EndingPointControlContainerView: UIView
{
    private let _debugFlag = false;
    
    @IBOutlet weak var _endingPointControlView: UIView!
    
    private var _minimumYInterval: Double = -1;
    var minimumYInterval: Double
    {
        get{    return _minimumYInterval;    }
        set{    _minimumYInterval = newValue;    }
    }
    
    /** the starting position of the user's drag touch */
    private var _startingYTouch: CGFloat!
    
    private var _endPointPosition: CGFloat = 0;
    var endPointPosition: CGFloat
    {
        get{    return _endPointPosition; }
        set
        {
            _endPointPosition = newValue;
            _endingPointControlView.frame.origin.y = _endPointPosition;
            
            // max
            if(_endPointPosition <= CGFloat(_minimumYInterval))
            {
                _endPointPosition = CGFloat(_minimumYInterval)
                _endingPointControlView.frame.origin.y = CGFloat(_minimumYInterval);
            }
                // min
            else if(_endPointPosition >= frame.height)
            {
                _endPointPosition = frame.height;
                _endingPointControlView.frame.origin.y = frame.height;
            }
        }
    }
    
    private var _endPointHeight: CGFloat = 0;
    var endPointHeight: CGFloat
    {
        get{    return _endPointHeight;   }
        set
        {
            _endPointHeight = newValue;
            _endingPointControlView.frame.size.height = newValue;
        }
    }
    
    /** when we touch up,
     this value is set to the position of the origin of the white rectangle */
    private var _stopEndPointPosition: CGFloat! = nil
    var stopEndPointPosition: CGFloat
    {
        get{    return _stopEndPointPosition; }
        set{    _stopEndPointPosition = newValue; }
    }
    
    /** as of 1/5/2018
     trying to adjust the start and endpoints at the same time is a great way to make the app crash */
    private var _startPointIsBeingAdjusted = false;
    var startPointIsBeingAdjusted: Bool
    {
        get{    return _startPointIsBeingAdjusted;    }
        set{    _startPointIsBeingAdjusted = newValue;  }
    }
    
    weak var _delegate: EndingPointControlContainerViewParentProtocol! = nil;
    
    deinit
    {
        _delegate = nil;
        _endingPointControlView = nil;
        if(_debugFlag){ print("**** EndingPointControlContainerView deintialized");   }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(!_startPointIsBeingAdjusted)
        {
            _delegate.setEndPointIsBeingAdjusted(adjusted: true);
            _startingYTouch = touches.first?.location(in: self).y;
            _delegate.endPointTouchBegan(y: _startingYTouch);
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(!_startPointIsBeingAdjusted)
        {
            if(touches.first?.location(in: self).y != _startingYTouch)
            {
                let containerHeight = frame.height;
                let endPointHeight = _endingPointControlView.frame.height;
                let startingDiff = (touches.first?.location(in: self).y)! - _startingYTouch;
                let containerDiff = containerHeight - (endPointHeight  - (containerHeight - _endPointPosition));
            
                //  DEBUG: i'm pretty sure this calculation is the cause of the little jump.....
                //              as of 1/5/2018 we still have not resolved the little jump...
                var referenceDiff: CGFloat =  -1.0;
            
                if(_stopEndPointPosition == nil){   referenceDiff = 0   }
                else{   referenceDiff =  _stopEndPointPosition - containerHeight;   }
            
                //public setter adjusts the white rectangle's y origin point.
                endPointPosition = startingDiff + containerDiff + referenceDiff;
                self.endPointHeight = containerHeight - endPointPosition;
            
                _delegate.passEndPointVerticalTouchMoves(y: endPointPosition);
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(!_startPointIsBeingAdjusted)
        {
            _stopEndPointPosition = _endPointPosition;
        
            _delegate.endPointTouchEnded(y: _endPointPosition);
        
            if(_debugFlag)
            {
                print("ended y in end point control: " + (touches.first?.location(in: self).y.description)!);
                print("endPointPosition at touch up: " + _endPointPosition.description);
            }
            
            _delegate.setEndPointIsBeingAdjusted(adjusted: false);
        }
    }
}

extension EndPointsViewController: InfoScreenParentProtocol
{
    func popInfoScreen(){   dismiss(animated: true, completion: nil);   }
}
