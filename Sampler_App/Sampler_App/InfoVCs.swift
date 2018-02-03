//
//  SongTableInfoScreenVC.swift
//  Sampler_App
//
//  Created by Budge on 12/3/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

import UIKit

class SongTableInfoScreenViewController: UIViewController
{
    @IBOutlet weak var _textView: UITextView!
    
    override func viewDidLoad()
    {
        //  http://iphonedevsdk.com/forum/iphone-sdk-development/121626-uitextview-scrolls-to-middle-when-it-first-appears.html
        _textView.isScrollEnabled = false;
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        navigationController?.navigationBar.topItem?.title = "App Info";
        _textView.setContentOffset(.zero, animated: true);
        _textView.isScrollEnabled = true;
    }
}

class SamplerConfigInfoScreenViewController: UIViewController
{
    weak var _delegate: SamplerConfigInfoScreenParentProtocol! = nil
    
    @IBOutlet weak var _textView: UITextView!
    override func viewDidLoad(){    _textView.isScrollEnabled = false;  }
    override func viewDidAppear(_ animated: Bool)
    {
        navigationController?.navigationBar.topItem?.title = "Sampler Info";
        _textView.setContentOffset(.zero, animated: true);
        _textView.isScrollEnabled = true;
    }
    
    override func viewDidDisappear(_ animated: Bool){   _delegate.infoScreenWasPopped() }
}

class BankInfoScreenViewController: UIViewController
{
    @IBOutlet weak var _textView: UITextView!
    override func viewDidLoad(){    _textView.isScrollEnabled = false;  }
    override func viewWillAppear(_ animated: Bool)
    {
        navigationController?.isNavigationBarHidden = false;
        UIApplication.shared.isIdleTimerDisabled = false;
    }
    override func viewDidAppear(_ animated: Bool)
    {
        navigationController?.navigationBar.topItem?.title = "Multi Pad Info";
        _textView.setContentOffset(.zero, animated: false);
        _textView.isScrollEnabled = true;
    }
    
    override func viewWillDisappear(_ animated: Bool){  navigationController?.isNavigationBarHidden = true; }
}

class SequenceInfoScreenViewController: UIViewController
{
    @IBOutlet weak var _textView: UITextView!
    override func viewDidLoad(){    _textView.isScrollEnabled = false;  }
    override func viewWillAppear(_ animated: Bool)
    {
        navigationController?.isNavigationBarHidden = false;
        UIApplication.shared.isIdleTimerDisabled = false;
    }
    override func viewDidAppear(_ animated: Bool)
    {
        navigationController?.navigationBar.topItem?.title = "Sequence Info";
        _textView.setContentOffset(.zero, animated: true);
        _textView.isScrollEnabled = true;
    }
    
    override func viewWillDisappear(_ animated: Bool){  navigationController?.isNavigationBarHidden = true; }
}

class PadConfigInfoScreenViewController: UIViewController
{
    @IBOutlet weak var _textView: UITextView!
    override func viewDidLoad(){    _textView.isScrollEnabled = false;  }
    override func viewDidAppear(_ animated: Bool)
    {
        navigationController?.navigationBar.topItem?.title = "Pad Settings Info";
        _textView.setContentOffset(.zero, animated: true);
        _textView.isScrollEnabled = true;
    }
}

class EndpointsInfoScreenViewController: UIViewController
{
    weak var _delegate: InfoScreenParentProtocol! = nil;
    @IBOutlet weak var _textView: UITextView!
    @IBOutlet weak var _backButton: UIButton!
    
    override func viewDidLoad(){    _textView.isScrollEnabled = false;  }
    
    override func viewDidAppear(_ animated: Bool)
    {
        navigationController?.navigationBar.topItem?.title = "Endpoints Info";
        _textView.setContentOffset(.zero, animated: true);
        _textView.isScrollEnabled = true;
    }
    
    @IBAction func handleBackButton(_ sender: UIButton){    _delegate.popInfoScreen();  }
}

class FileSelectorInfoScreenViewController: UIViewController
{
    @IBOutlet weak var _textView: UITextView!
    override func viewDidLoad(){    _textView.isScrollEnabled = false;  }
    override func viewDidAppear(_ animated: Bool)
    {
        navigationController?.navigationBar.topItem?.title = "File Chooser Info";
        _textView.setContentOffset(.zero, animated: true);
        _textView.isScrollEnabled = true;
    }
}

class RecordInfoScreenViewController: UIViewController
{
    @IBOutlet weak var _textView: UITextView!
    override func viewDidLoad(){    _textView.isScrollEnabled = false;  }
    override func viewDidAppear(_ animated: Bool)
    {
        navigationController?.navigationBar.topItem?.title = "Record Info";
        _textView.setContentOffset(.zero, animated: true);
        _textView.isScrollEnabled = true;
    }
}
