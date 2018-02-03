//
//  Pad.swift
//  Sampler_App
//
//  Created by mike on 3/12/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit

//  TODO: 1/24/2018 revise all try catch blocks
//  TODO: 2/2/2018 you can do this:  [1,2,3,4].forEach{print($0)}

/** represents the view and control component of the Pad concept 
        An array of this class will be owned by the BankVC*/
class PadView: UIView, UIGestureRecognizerDelegate
{
    let _debugFlag = false;
    
    /** Yellow, Blue, Orange, Purple, Green.
            5 possible RGB colors for five possible simultaneous touches. */
    private var _colorArray = ([CGFloat(255.0), CGFloat(255.0), CGFloat(5.0)], // yellow
                               [CGFloat(5.0), CGFloat(5.0), CGFloat(255.0)],    // blue
                               [CGFloat(255.0), CGFloat(128.0), CGFloat(5.0)],  // orange
                               [CGFloat(127.0), CGFloat(5.0), CGFloat(255.0)],  //Purple
                               [CGFloat(5.0), CGFloat(255.0), CGFloat(5.0)], //Green
                                [CGFloat(255.0), CGFloat(5.0), CGFloat(5.0)]); // Red
    
    private var _bgcRed: CGFloat = 255;
    var bgcRed: CGFloat
    {
        get{    return _bgcRed;    }
        set
        {
            _bgcRed = newValue;
            backgroundColor = UIColor(red: _bgcRed, green: _bgcGreen, blue: _bgcBlue, alpha: 1.0);
        }
    }
    
    private var _bgcGreen: CGFloat = 255;
    var bgcGreen: CGFloat
    {
        get{    return _bgcGreen;   }
        set
        {
            _bgcGreen = newValue;
            backgroundColor = UIColor(red: _bgcRed, green: _bgcGreen, blue: _bgcBlue, alpha: 1.0);
        }
    }
    
    private var _bgcBlue: CGFloat = 255;
    var bgcBlue: CGFloat
    {
        get{    return _bgcBlue;    }
        set
        {
            _bgcBlue = newValue;
            backgroundColor = UIColor(red: _bgcRed, green: _bgcGreen, blue: _bgcBlue, alpha: 1.0);
        }
    }
    
    /** displays the name of the file loaded into the pad */
    private var _fileLabel: UILabel! = nil;
    var fileLabel: UILabel!
    {
        get{    return _fileLabel;  }
        set{    _fileLabel = newValue;  }
    }
    
    /** denotes whether self was the last touched pad */
    private var _lastTouched: Bool = false;
    var lastTouched: Bool{    get{    return _lastTouched;    }   }
    
    /** reflects whether this has a sound loaded */
    private var _isLoaded: Bool = false;
    var isLoaded: Bool
    {
        get{    return _isLoaded;   }
        set{    _isLoaded = newValue;   }
    }
    
    private var _padNumber: Int = -1;
    var padNumber: Int
    {
        get{    return _padNumber;  }
        set{    _padNumber = newValue;  }
    }
    
    private var _startStopTriggerMode = true;
    var startStopTriggerMode: Bool
    {
        get{    return _startStopTriggerMode;   }
        set{    _startStopTriggerMode = newValue;   }
    }
    
    weak var delegate: ParentPadViewProtocol! = nil;
    private var _opQueue: OperationQueue! = OperationQueue();
    var opQueue: OperationQueue!
    {
        get{    return _opQueue;    }
        set{    _opQueue = newValue;    }
    }
    
    /** users may touch more than one pad at a time in any given bankVC,
        the first touched pad will have an index of 0,
            the second simultenously touched pad will have an index of 1,
                and so on */
    private var _touchIndex: Int = 0;
    var touchIndex: Int
    {
        get{    return _touchIndex; }
        set{    _touchIndex = newValue; }
    }
    
    /** the current play volume of this Pad's corresponding model passed down by the MasterSoundMod,
            used to adjust the View's color */
    private var _currentPlayVolume: Float = 0;
    var currentPlayVolume: Float
    {
        get{    return _currentPlayVolume;  }
        set{    _currentPlayVolume = newValue;  }
    }
    
    /** helps with reseting pad color schemes in case the user has a pad pressed in the bankVC while,
            at the same time choosing an action which will cause the bank VC to dissapear.
                e.g. pressing a pad and a bank switch button at the same time */
    private var _isTouched: Bool = false;
    var isTouched: Bool
    {
        get{    return _isTouched;  }
        set{    _isTouched = newValue;  }
    }

    /** lets the user move to the corresponding PadConfigVC */
    private var _panGestureRecognizer: UIPanGestureRecognizer! = nil;
    var panGestureRecognizer: UIPanGestureRecognizer!
    {
        get{    return _panGestureRecognizer;    }
        set{    _panGestureRecognizer = newValue;   }
    }
    
    // changed on 12/21/2017 from 3700 to 3000 -> little too sensitive
    //  changed on 1/11/2018 from 3000 to 3200
    private var _panVelocityThreshold: CGFloat = 3200;
    
    //TODO: enable setting this value in SamplerConfigVC or a GlobalSettings View.
    private var _gestureEnabled = true;
    var gestureEnabled: Bool
    {
        get{    return _gestureEnabled; }
        set{    _gestureEnabled = newValue; }
    }
    
    /** flag helps prevent the user from tirggering pads while an audio route change is taking place. */
    private var _routeIsChanging = false
    var routeIsChanging: Bool
    {
        get{    return _routeIsChanging;    }
        set{    _routeIsChanging = newValue;    }
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder);
        
        backgroundColor = .black
        
        _panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)));
        _panGestureRecognizer.delegate = self;
        _panGestureRecognizer.cancelsTouchesInView = false;
        addGestureRecognizer(_panGestureRecognizer)
    }
    
    deinit
    {
        _fileLabel = nil;
        delegate = nil;
        _panGestureRecognizer = nil;
        
        if(_debugFlag){ print("***PadView deinitialized");  }
    }
    
    func placeLabel(name: String)
    {
        let labelHeight = frame.height * 0.1; // suspect
        
        _fileLabel = UILabel(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: labelHeight));
        _fileLabel.text = name;
        _fileLabel.textColor = .white
        _fileLabel.isUserInteractionEnabled = false;
        
        addSubview(_fileLabel);
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(!_routeIsChanging)
        {
            _isTouched = true;
            delegate.padTouchDown(number: self._padNumber, isLoaded: _isLoaded);
        }
        else{   delegate.passResetPadColors();  }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if(!_routeIsChanging)
        {
            _isTouched = false;
            self.delegate.padTouchUp(number: self._padNumber, isLoaded: _isLoaded);
        }
    }
    
    /** we are curretnly expecting this to be called upon the 6th siumltaneous touch */
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        _isTouched = false;
        
        self.delegate.sixthTouch(number: self._padNumber, isLoaded: _isLoaded);
    }
    
    func setBackgroundColor(volumeLevel: Float)
    {
        // only one pad touched
        if(_touchIndex == 1)    // yellow
        {
            bgcRed = _colorArray.0[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.0[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.0[2] * CGFloat(volumeLevel)// 255, 255, 5.0
            if(_debugFlag){ print("yellow color triggered, touch index: " + _touchIndex.description);   }
        }
        // two separate pads touched at once
        else if(_touchIndex == 2)   //blue
        {
            bgcRed = _colorArray.1[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.1[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.1[2] * CGFloat(volumeLevel)// 5, 5, 255
            if(_debugFlag){ print("blue color triggered, touch index: " + _touchIndex.description);   }
        }
        // three separate pads touched at once
        else if(_touchIndex == 3)   // orange
        {
            bgcRed = _colorArray.2[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.2[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.2[2] * CGFloat(volumeLevel)// 255, 128, 5
            if(_debugFlag){ print("orange color triggered, touch index: " + _touchIndex.description);   }
        }
        else if(_touchIndex == 4) // purple
        {
            bgcRed = _colorArray.3[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.3[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.3[2] * CGFloat(volumeLevel)// 127, 5, 255
            if(_debugFlag){ print("purple color triggered, touch index: " + _touchIndex.description);   }
        }
        else if(_touchIndex == 5)   // green
        {
            bgcRed = _colorArray.4[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.4[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.4[2] * CGFloat(volumeLevel)// 5, 255, 5
            if(_debugFlag){ print("green color triggered, touch index: " + _touchIndex.description);   }
        }
        else if(_touchIndex == 0)
        {
            bgcRed = _colorArray.5[0] * CGFloat(volumeLevel)
            bgcGreen = _colorArray.5[1] * CGFloat(volumeLevel)
            bgcBlue = _colorArray.5[2] * CGFloat(volumeLevel)
            if(_debugFlag){ print("???? color triggered, touch index: " + _touchIndex.description);   }
        }
    }
    
    /** gesture that moves to the corresponding PadConfigVC */
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer)
    {
        if(_gestureEnabled)
        {
            if(abs(_panGestureRecognizer.velocity(in: self).x) > _panVelocityThreshold || abs(_panGestureRecognizer.velocity(in: self).y) > _panVelocityThreshold)
            {   delegate.panMoveToPadConfig(number: _padNumber);  }
        }
    }
}
