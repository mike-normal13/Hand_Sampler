//
//  SamplerVC.swift
//  Sampler_App
//
//  Created by Budge on 10/23/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit

/** with the excpetion of the SongTVC and FileSelectorTVC classes,
         all VC classes inherit from this.  */
class SamplerVC: UIViewController
{
    internal var _opQueue: OperationQueue! = OperationQueue();
    
    internal var _songName: String = ""
    var songName: String
    {
        get{    return _songName;  }
        set{    _songName = newValue}
    }
    
    internal var _songNumber = -1;
    var songNumber: Int
    {
        get{    return _songNumber; }
        set{    _songNumber = newValue; }
    }
    
    internal var _bankNumber = -1
    var bankNumber: Int
    {
        get{    return _bankNumber;  }
        set{    _bankNumber = newValue; }
    }
    
    internal var _padNumber = -1
    var padNumber: Int
    {
        get{    return _padNumber;  }
        set{    _padNumber = newValue;  }
    }
    
    /** reflects whether the song corresponding to this VC is connected to the host application.
     this member will not be saved to disk,
     it is only here to help pass down connection status to classes owned by the SongVC.*/
    internal var _isConnected = false;
    var isConnected: Bool
    {
        get{    return _isConnected;    }
        set{    _isConnected = newValue;    }
    }
    
    /** indicates whether this VC is visible to the user,
         used to handle a media services reset */
    internal var _isVisible = false
    var isVisible: Bool
    {
        get{    return _isVisible;  }
        set{    _isVisible = newValue;  }
    }
    
    /** flag helps prevent the user from triggering pads while an audio route change is taking place. */
    internal var _routeIsChanging = false
    var routeIsChanging: Bool
    {
        get{    return _routeIsChanging;    }
        set{    _routeIsChanging = newValue;    }
    }
    
    /** Name of the demo song which comes with a small library of sounds for the user's convenience */
    internal let _demoSongName = "Splash! Demo Song";
    
    /** removed on 1/18/2018 */
    //internal lazy var _storyBoard: UIStoryboard! = UIStoryboard.init(name: "Main", bundle: nil);
}
