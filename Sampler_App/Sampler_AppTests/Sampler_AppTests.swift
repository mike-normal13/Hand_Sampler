//
//  Sampler_AppTests.swift
//  Sampler_AppTests
//
//  Created by mike on 2/27/17.
//  Copyright © 2017 Team_Audio_Mobile. All rights reserved.
//

import XCTest
@testable import Sampler_App

class Sampler_AppTests: XCTestCase {
    
    let _saver = Saver();
    let _loader = Loader();
    let _eraser = Eraser()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        _eraser.eraseAppDirectory();
        _eraser.clearAllStorageFiles();

        _loader.createAppDirectory();
        _loader.createAppPlist();
        _loader.initialAppPlistWrite();
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        
    }
    
    /** create and erase one song and verify song count */
    func test1()
    {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        _saver.saveNewSongEntry(name: "first", number: 1);
        
        XCTAssert(_loader.getSongNumber(name: "first") == 1);
        
        _saver.createNewSongDirectory(name: "first");
        
        XCTAssert(_loader.getNumberOfSongs() == 1);
        XCTAssert(_loader.getSongNumber(name: "first") == 1);
        
        _eraser.eraseSong(name: "first", number: 1);
        
        XCTAssert(_loader.getNumberOfSongs() == 0);
        
        XCTAssert(_loader.checkForAppPlist());
    }
    
    /** confirm that the firt song added will have song number matching the number of songs etc */
    func test2()
    {
        _saver.saveNewSongEntry(name: "first", number: _loader.getNumberOfSongs() + 1);
        _saver.createNewSongDirectory(name: "first");
        XCTAssert(_loader.getSongNumber(name: "first") == _loader.getNumberOfSongs())
        
        _saver.saveNewSongEntry(name: "second", number: _loader.getNumberOfSongs() + 1);
        _saver.createNewSongDirectory(name: "second");
        XCTAssert(_loader.getNumberOfSongs() == 2)
        XCTAssert(_loader.getSongNumber(name: "second") == _loader.getNumberOfSongs());
        
        _saver.saveNewSongEntry(name: "third", number: _loader.getNumberOfSongs() + 1);
        _saver.createNewSongDirectory(name: "third");
        XCTAssert(_loader.getSongNumber(name: "third") == _loader.getNumberOfSongs());
        
        _eraser.eraseSong(name: "third", number: _loader.getNumberOfSongs());
        
        XCTAssert(_loader.getSongNumber(name: "second") == _loader.getNumberOfSongs());
        _eraser.eraseSong(name: "second", number: _loader.getNumberOfSongs());
        
        XCTAssert(_loader.getSongNumber(name: "first") == _loader.getNumberOfSongs())
        _eraser.eraseSong(name: "first", number: _loader.getNumberOfSongs());
        
        XCTAssert(_loader.getNumberOfSongs() == 0);
    }
    
    func test3()
    {
        _saver.saveNewSongEntry(name: "first", number: _loader.getNumberOfSongs() + 1);
        _saver.createNewSongDirectory(name: "first");
        XCTAssert(_loader.getSongNumber(name: "first") == _loader.getNumberOfSongs())
        
        _saver.saveNewSongEntry(name: "second", number: _loader.getNumberOfSongs() + 1);
        _saver.createNewSongDirectory(name: "second");
        XCTAssert(_loader.getNumberOfSongs() == 2)
        XCTAssert(_loader.getSongNumber(name: "second") == _loader.getNumberOfSongs());
        
        _saver.saveNewSongEntry(name: "third", number: _loader.getNumberOfSongs() + 1);
        _saver.createNewSongDirectory(name: "third");
        XCTAssert(_loader.getSongNumber(name: "third") == _loader.getNumberOfSongs());
        
        _eraser.eraseSong(name: "first", number: _loader.getSongNumber(name: "first"));
        XCTAssert(_loader.getNumberOfSongs() == 2);
        
        XCTAssert(_loader.getSongNumber(name: "second") == _loader.getNumberOfSongs() - 1);
        XCTAssert(_loader.getSongNumber(name: "third") == _loader.getNumberOfSongs());
        
        _eraser.eraseSong(name: "second", number: _loader.getSongNumber(name: "second"));
        
        XCTAssert(_loader.getSongNumber(name: "third") == _loader.getNumberOfSongs());
        
        _eraser.eraseSong(name: "third", number: _loader.getSongNumber(name: "third"));
        
        XCTAssert(_loader.getNumberOfSongs() == 0);
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
