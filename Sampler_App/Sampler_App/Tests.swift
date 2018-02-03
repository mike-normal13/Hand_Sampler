//
//  Tests.swift
//  Sampler_App
//
//  Created by Budge on 11/5/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

//************************************************************************
//  Things we need to exhaustively test
//************************************************************************
//--------------------------------------------------------------------------------------------------------------------------
//  1: handling the media services reset gracefully.
//------------------------------------------------------------------------------------------------------------------
//  2: test and debug findVisibleVC() in app delegate.
//---------------------------------------------------------------------------------------------------------------------------------------
//  47: test the EndPointsVC on all screens -- last tested on 1/7/2018
//      ipad 5th gen -- Good -- 1/7/2018
//      ipad air -- Good -- 1/7/2018
//      ipad air 2 -- Good -- 1/7/2018
//      ipad pro 9.7 -- Good -- 1/7/2018
//      ipad pro 10.5 -- Good -- 1/7/2018
//      ipad pro 12.9 -- Good -- 1/7/2018
//      ipad pro 12.9 2nd -- Good -- 1/7/2018
//      iphone 5s: -- Good -- 1/7/2018
//      iphone 6 -- Good -- 1/7/2018
//      iphone 6 plus -- Good -- 1/7/2018
//      iphone 6s plus -- Good -- 1/7/2018
//      iphone 7 -- Good -- 1/7/2018
//      iphone 7 plus -- Good -- 1/7/2018
//      iphone 8 -- Good -- 1/7/2018
//      iphone 8 plus -- Good -- 1/7/2018
//      iphone se -- Good -- 1/7/2018
//      iphone x -- good -- 1/7/2018
//      Dad's iPad -- good -- 1/7/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  48: preview every sound in the FileSelectorVC,
//          make sure that no sound makes the app crash.
//---------------------------------------------------------------------------------------------------------------------------------------
//  49: FileSelectorVC:
//          test avery manner of audio interruption whilt previewing, go 20/20 in each case:
//              Back Button
//              Info Button
//              Home Button
//              Off Button
//              Timer
//              Siri
//              Call
//              Headphone
//              Bluetooth
//---------------------------------------------------------------------------------------------------------------------------------------
//  50: FileSelectorVC:
//          make sure that previewing gets cancelled in every way we want it to.
//----------------------------------------------------------------------------------------------------------
//  3: test the FileSelectorVC on all screens
//              last tested on 1/10/2018
//      ipad 5th gen -- 1/10/2018 -- Erase button is not visible on non demo files
//      ipad air -- 1/10/2018 -- Erase button is not visible on non demo files
//      ipad air 2 -- 1/10/2018 -- Erase button is not visible on non demo files
//      ipad pro 9.7 -- 1/10/2018 -- Erase button is not visible on non demo files
//      ipad pro 10.5 -- 1/10/2018 -- Erase button is not visible on non demo files
//      ipad pro 12.9 -- 1/10/2018 -- Erase button is not visible on non demo files
//      ipad pro 12.9 2nd -- 1/10/2018 -- Erase button is not visible on non demo files
//      iphone 5s -- 1/10/2018 -- Erase button is not visible on non demo files
//      iphone 6 -- 1/10/2018 -- Erase button is not visible on non demo files
//      iphone 6 plus -- 1/10/2018 -- Erase button is not visible on non demo files
//      iphone 6s plus -- 1/10/2018 -- Erase button is not visible on non demo files
//      iphone 7 -- 1/10/2018 -- Erase button is not visible on non demo files
//      iphone 7 plus -- skipped on 1/10/2018
//      iphone 8 -- skipped on 1/10/2018
//      iphone 8 plus -- skipped on 1/10/2018
//      iphone se -- skipped on 1/10/2018
//      iphone x -- skipped on 1/10/2018
//      Dad's iPad -- bad -- logged on 1/10/2018
//----------------------------------------------------------------------------------------------
//  4: test the PitchVC on all screens -- last tested on 1/10/2018
//      ipad 5th gen -- good -- 1/10/2018
//      ipad air -- good -- 1/10/2018
//      ipad air 2 -- good -- 1/10/2018
//      ipad pro 9.7 -- skipped on -- 1/10/2018
//      ipad pro 10.5 -- skipped on -- 1/10/2018
//      ipad pro 12.9 -- skipped on -- 1/10/2018
//      ipad pro 12.9 2nd -- good -- 1/10/2018
//      iphone 5s -- good -- 1/10/2018
//      iphone 6 -- skipped on 1/10/2018
//      iphone 6 plus -- skipped on 1/10/2018
//      iphone 6s plus -- skipped on 1/10/2018
//      iphone 7 -- skipped on 1/10/2018
//      iphone 7 plus -- skipped on 1/10/2018
//      iphone 8 -- good -- 1/10/2018
//      iphone 8 plus -- good -- 1/10/2018
//      iphone se -- good -- 1/10/2018
//      iphone x -- good -- 1/10/2018
//      Dad's iPad -- good -- 1/10/2018
//----------------------------------------------------------------------------------------------
//  5: test the BankInfoScreen on all available devices -- last tested on 1/10/2018
//      ipad 5th gen -- Good -- 1/10/2018
//      ipad air -- skipped on 1/10/2018
//      ipad air 2 -- skipped on 1/10/2018
//      ipad pro 9.7 -- skipped on 1/10/2018
//      ipad pro 10.5 -- skipped on 1/10/2018
//      ipad pro 12.9 -- Good -- 1/10/2018
//      ipad pro 12.9 2nd -- Good -- 1/10/2018
//      iphone 5s -- Good -- 1/10/2018
//      iphone 6 -- skipped on 1/10/2018
//      iphone 6 plus -- skipped on 1/10/2018
//      my iPhone -- Good -- 1/10/2018
//      iphone 6s plus -- skipped on 1/10/2018
//      iphone 7 -- skipped on 1/10/2018
//      iphone 7 plus -- skipped on 1/10/2018
//      iphone 8 -- skipped on 1/10/2018
//      iphone 8 plus -- skipped on 1/10/2018
//      iphone se -- Good -- 1/10/2018
//      iphone x -- Good -- 1/10/2018
//----------------------------------------------------------------------------------------------
//  6: test the SequenceInfoScreen on all available devices -- last tested on 1/10/2018
//      ipad 5th gen -- Good on 1/10/2018
//      ipad air -- Skipped on 1/10/2018
//      ipad air 2 -- Skipped on 1/10/2018
//      ipad pro 9.7 -- Skipped on 1/10/2018
//      ipad pro 10.5 -- Skipped on 1/10/2018
//      ipad pro 12.9 -- Skipped on 1/10/2018
//      ipad pro 12.9 2nd -- Skipped on 1/10/2018
//      iphone 5s -- Skipped on 1/10/2018
//      iphone 6 -- Skipped on 1/10/2018
//      iphone 6 plus -- Skipped on 1/10/2018
//      iphone 6s plus -- Skipped on 1/10/2018
//      iphone 7 -- Skipped on 1/10/2018
//      iphone 7 plus -- Skipped on 1/10/2018
//      iphone 8 -- Skipped on 1/10/2018
//      iphone 8 plus -- Skipped on 1/10/2018
//      iphone se -- Skipped on 1/10/2018
//      iphone x -- Skipped on 1/10/2018
//----------------------------------------------------------------------------------------------
//  7: test the sequenceVC on all screens  -- last tested on 1/10/2018
//          TEST LOCKING
//      ipad 5th gen -- Good -- 1/10/2018
//      ipad air -- Good -- 1/10/2018
//      ipad air 2 -- Good -- 1/10/2018
//      ipad pro 9.7 -- Good -- 1/10/2018
//      ipad pro 10.5 -- Good -- 1/10/2018
//      ipad pro 12.9 -- Good -- 1/10/2018
//      ipad pro 12.9 2nd -- Good -- 1/10/2018
//      iphone 5s -- Good -- 1/10/2018
//      iphone 6 -- Good -- 1/10/2018
//      iphone 6 plus -- Good -- 1/10/2018
//      iPhone 6s -- Good -- 1/10/2018
//      iphone 6s plus -- Good -- 1/10/2018
//      iphone 7 -- Good -- 1/10/2018
//      iphone 7 plus -- Good -- 1/10/2018
//      iphone 8 -- Good -- 1/10/2018
//      iphone 8 plus -- Good -- 1/10/2018
//      iphone se -- Good -- 1/10/2018
//      iphone x -- Good -- 1/10/2018
//      Dad's iPad -- Good -- 1/10/2018
//----------------------------------------------------------------------------------------------
//  8: the padconfigVC on all available screens
//      ipad 5th gen: -- good - 1/11/2018
//      ipad air: -- good - 1/11/2018
//      ipad air 2: -- Skipped on 1/11/2018
//      ipad pro 9.7 -- Skipped on 1/11/2018
//      ipad pro 10.5 -- Skipped on 1/11/2018
//      ipad pro 12.9 -- Skipped on 1/11/2018
//      ipad pro 12.9 2nd -- Everything is still too small - 1/11/2018
//      iphone 5s -- Trigger Mode label is too small - 1/11/2018
//      iphone 6 -- Good - 1/11/2018
//      iphone 6 plus -- Good - 1/11/2018
//      my phone -- Good - 1/11/2018
//      iphone 6s plus -- Skipped on 1/11/2018
//      iphone 7 -- Skipped on 1/11/2018
//      iphone 7 plus -- Skipped on 1/11/2018
//      iphone 8 -- Skipped on 1/11/2018
//      iphone 8 plus -- good - 1/10/2018
//      iphone se -- good - 1/10/2018
//      iphone x -- good - 1/10/2018
//      Dad's iPad -- good - 1/10/2018
//---------------------------------------------------------------------------------------------------------------------
//  9: triggering audio route changes during various VC transistions
//       on 10/24/2017 we exposed a bug:
//          if you press the go to song button and then immediatly switch off the bluetooth speaker,
//              there is a pronounced lag in getting to the Bankvc,
//                  once the bankVC appears if pads are pressed the toogle between black and grey a few times
//                      before becomming unresponsive and the app crashes.
//          AND after the happened when we tried to launch the app like normal unconnected,
//              the app would crash after a lag when pressing the go to song button.
//                  this happened more than once and stopped happening once we connected the phone to the machine.
//       On 11/8/2017 we were able to get the bug to manifest
//          it does not happen every time....
//      FileSelectorVC(With Load) -> PadConfigVC  -- Skipped on 12/21/2017
//          headphone
//          Home button
//          Off Button
//          Call
//      SamplerConfigVC -> BankVC
//          headphone:
//                  12/21/2017: Third Try
//                  we connected and diconnected the head phones a few times while the song was loading and we got:
//                      *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:
//                          '[[busArray objectAtIndexedSubscript:(NSUInteger)element] setFormat:
//                              format error:&nsErr]:
//                                  returned false, error Error Domain=NSOSStatusErrorDomain Code=-10865 "(null)"'
//                                      10865 = kAudioUnitErr_PropertyNotWritable
//          Home button:
//              12/21/2017: First try
//                  we moved to and from the background with the home button while the song was loading,
//                      and the app was making fart noises with delay
//          Off Button
//              12/21/2017: went 10/10
//                  various standard errors were printed out to console,
//                      app never crashed.
//          Call
//              12/21/2017: went 10/10
//                  app never crashed
//      RecordVC(With Recording) -> PadConfigVC -- Skipped on 12/21/2017
//          headphone -- Skipped on 1/11/2018
//          Home button -- passed 10/10 - 1/11/2018
//          Off Button -- Skipped on 1/11/2018
//          Call -- Skipped on 1/11/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  10:  Can we write a unit test for pressing the home or off button..???
//          spend no more than an hour researching this.
//              https://stackoverflow.com/questions/32853818/simulating-pressing-the-home-button-in-xcode-7-ui-automation/33087217#33087217
//                  it appears to be possible,
//                      off button..?
//                          Siri....?
//---------------------------------------------------------------------------------------------------------------------------------------
//  11: verify that we can't load, clear, or record into the demo pads,  -- last tested on 1/11/2018
//          make sure all the alert messages look good.
//              Loading alertVC appears - 1/11/2018
//              Recording alertVC appears - 1/11/2018
//              Clearing alertVC appears - 1/11/2018
//-----------------------------------------------------------------------------------------------------------------------------------------
//  12: Song removals AND Additions
//      1:  Test for adding and removing songs a bunch of times in the same launch and make sure the list does not get corrupted,
//              intermitently launch songs before removing them.
//                  Skipped on 1/11/2018
//      2:  Test for erasing a song that has been launched. -- Skipped on 1/11/2018
//      3:  Test for erasing a song with a missing file. -- Skipped on 1/11/2018
//      4: test for erasing a song with every pad loaded. -- Skipped on 1/11/2018
//      5:  test erasing the first song in list(loaded) -- Skipped on 1/11/2018
//      6:  test erasing the last song in the list(loaded) -- Skipped on 1/11/2018
//      7: test erasing a song that has not been launched -- Skipped on 1/11/2018
//      8:  Test for having many, many songs present - more than 26
//              and then do removals.. and additions
//                 Failed -- Logged around three bugs on 1/11/2018
//----------------------------------------------------------------------------------------------------------------------------------
//  13: the samplerSettingsVC on all available screens -- last tested on 1/11/2018
//      ipad 5th gen: -- Good on 1/11/2018 -- small...
//      ipad air: -- Skipped on 1/11/2018
//      ipad air 2: -- Skipped on 1/11/2018
//      ipad pro 9.7 -- Skipped on 1/11/2018
//      ipad pro 10.5 -- Skipped on 1/11/2018
//      ipad pro 12.9 -- Skipped on 1/11/2018
//      ipad pro 12.9 2nd -- Good on 1/11/2018 - Too small though
//      iphone 5s -- Failed on 1/11/2018 -- Container view extends beyond screen, no rounded corners
//      iphone 6 -- Good on 1/11/2018
//      iphone 6 plus -- Good on 1/11/2018
//      iphone 6s plus -- Skipped on 1/11/2018
//      iphone 7 -- Skipped on 1/11/2018
//      iphone 7 plus -- Skipped on 1/11/2018
//      iphone 8 -- Skipped on 1/11/2018
//      iphone 8 plus -- Skipped on 1/11/2018
//      iphone se -- Failed on 1/11/2018 -- Container view extends beyond screen, no rounded corners
//      iphone x -- Good on 1/11/2018
//      Dad's iPad -- Good on 1/11/2018
//------------------------------------------------------------------------------------------------------------------------------------
//  14: how many songs/files do we have to have loaded in memory at the same time for the 6s's playback to start become corrupted...?
//------------------------------------------------------------------------------------------------------------------------------------
//  14:  SONG renaming. -- Laste tested on 1/12/2018
//          Rename then do a bunch of stuff with the song like loading and adjusting pad settings, -- failed on 1/12/2018 - logged
//              on seperated banks
//          Do a bunch of stuff with a song then rename.
//              on seperate banks
//          on 12/14/2017 we made a change to duplicate name checking..... -- looks good on 1/12/2018
//          1: standard rename -- good on 1/12/2018
//          2: rename to a taken name -- Good on 1/12/2018
//          3: rename a loaded song -- Good on 1/12/2018
//          4: rename song with a missing file -- Failed on 12/28/2017 - Logged -- SKIPPED on 1/12/2018
//-----------------------------------------------------------------------------------------------------------------------
//  16: confirm that the way we handle alerting the user of a potential unintended change to the recorded sequence
//          in the FileSelctorVC and RecordVC actually works.
//              1/12/2018 -- Good for FileSelectorVC and RecordVC
//-----------------------------------------------------------------------------------------------------------------------
//  17: test swiping between padConfigVCs
//          1/12/2018 -- Good.
//--------------------------------------------------------------------------------------------------------------------------
//  15: airplay conecting/disconecting
//          WORK THE SILENT SWITCH INTO THE MIX!
//          WORK CHANGING THE VOLUME INTO THE MIX!
//          WORK THE POWER OFF BUTTON INTO THE MIX!
//          WORK SIRI INTO THE MIX
//          just generally using the app while airplay mirroring.
//        last time on 10/29/2017 we just did a general run through of the app,
//                  nothing crashed.
//          11/15/2017: The only bugg we found was when we preview a few sounds in the FileSelectorVC without selecting a sound,
//                          when we moved back to the PadConfigVC via the back button the app crashed.
//                              the crash does not happen consistently.
//          12/2/2017: we messed around with all avialble songs,
//                       nothing crashed.
//                          recorded a file
//                          loaded a file
//                          cleared a pad
//                          added a song
//                          erased a song
//                          recorded a sequence
//                          moved to and from the back ground through various means
//                          had a timer go off
//---------------------------------------------------------------------------------------------------------------------------------------
//  18: test moving the app between background and foreground on all VCs,
//      SamplerSettingsVC:
//      SongInfoVC:
//      SamplerInfoVC:
//      BankInfoVC:
//      PadConfigInfoVC:
//      SequenceInfoVC:
//      EndpointsInfoVC
//      FileSelectorInfoVC:
//      RecordInfoVC:
//      SongTVC: on 11/15/2017 passed 20/20
//                      12/3/2017 - passed 20/20
//                          12/29/2017 -- passed 15/15
//      SamplerConfigVC: on 11/15/2017 passed 20/20
//                          12/3/2017 - passed 20/20 -- same launch as previous SongTVC
//                              12/29/2017 - passed 15/15
//      BankVC: 12/3/2017 -- passed 20/20 -- same launch as previous SongTVC
//                              12/29/217 - passed 15/15
//      SequenceVC: on 11/15/2017 passed 20/20
//                  12/3/2017 -- passed 20/20 - same launch as previous SongTVC
//                      12/29/2017 - passed 15/15
//      PadCOnfigVC: on 11/15/2017 passed 20/20
//                  12/3/2017 -- passed 20/20 - same launch as previous SongTVC
//      RecordVC: on 11/15/2017 - passed 20/20
//      VolumeVC:   broken on 11/15/2017 - can't present
//                  12/3/2017 -- passed 20/20 - same launch as previous SongTVC
//      EndpointsVC:    broken on 11/15/2017 - can't present
//                  12/3/2017 -- passed 20/20 - same launch as previous SongTVC
//      FileSelectorVC:
//                  12/3/2017 -- passed 20/20 - same launch as previous SongTVC
//      PitchVC:    failed -- app was unresponsive on 9th try - moving the app to and from the background snapped the app out of it. 1/14/2018
//---------------------------------------------------------------------------------------------------------------------------------------------
//  19: test proper handling of a file not being found at song load time,
//          make sure the alert shows and that the app does not crash.
//              test for more than one file not being found.
//          12/23/2017
//              in the bankVC we're calling loadPadFiles() in viewDidLoad(),
//                  which is probably part of the reason why we only see one alert if multiple files are missing.
//------------------------------------------------------------------------------------------------------------------------------------------
//  20:  On 12/3/2017 and then again on 1/3/2018 we skipped testing this.......
//          Next time we test this,
//              test for touching the little timer tab at the top of the screen witch automatically presents the Timer screen.
//                  see if the app is still viable once we move back to it.
//              SongTVC: 10/15/2017 - passed 20/20
//              SamplerConfigVC:    10/15/2017 - passed 20/20
//              RecordVC:
//     TEST THE TIMER IN SILENT MODE!!!
//              WILL THE isOtherAudioPlaying fix still work if the phone is in silent mode.....?
//              SongTVC: 11/15/2017 - passed 20/20
//                          it was impossible to press the pop over menu before the alarm sounded...
//                                 maybe no active audio sessions needing to be deactivated....?
//              SamplerConfigVC: 11/15/2017 - passed 20/20
//                          it was impossible to press the pop over menu before the alarm sounded...
//                                 maybe no active audio sessions needingto be deactivated....?
//      the only place we ran into a problem was recording a sound and then trying to preview the sound.
//          we tested this once on 11/15/2017 and there was no issue.
//      and file Loading after a timer goes off.
//          we tested this once on 11/15/2017 and there was no issue.
//---------------------------------------------------------------------------------------------------------------------------------------
//  21:  On 12/3/2017 we skipped testing this
//      previewing sounds in padConfigVC and PadSettingsVCs under all circumstances....
//          remember to test this when making audio route changes
//              PitchVC
//                 start/stop: headphones -> off -> bluetooth -> home -> speaker -> Siri -- Good - 1/3/2018
//                  through: headphones -> off -> bluetooth -> home -> speaker -> Siri -- Good - 1/3/2018
//              VolumeVC:
//                 start/stop: headphones -> off -> bluetooth -> home -> speaker -> Siri -- Good - 1/3/2018
//                  through: headphones -> off -> bluetooth -> home -> speaker -> Siri -- Good - 1/3/2018
//              EndPointsVC:
//                 start/stop: headphones -> off -> bluetooth -> home -> speaker -> Siri -- Good - 1/3/2018
//                  through: headphones -> off -> bluetooth -> home -> speaker -> Siri -- Good - 1/3/2018
//              PadConfigVC:
//                 start/stop: headphones -> off -> bluetooth -> home -> speaker -> Siri -- Good - 1/3/2018
//                  through: headphones -> off -> bluetooth -> home -> speaker -> Siri -- Good - 1/3/2018
//      on 12/18/2017 we added code to fix previewing pads in playthrough mode,
//-------------------------------------------------------------------------------------------------------------------------------
//  22:  on 12/3/2017 this did not seem to show any sort of issues...
//          on 1/3/2018 this did not seem to show any sort of issues...
//      bank switching in the SequenceVC.
//          make sure buttons color correctly.
//          load a bunch of sounds up into each of the banks and make sure there is no noticible delay with switching banks.
//          make sure that if we switch banks,
//              we can navigate back to the BankVC without throwing nil.
//------------------------------------------------------------------------------------------------------------------------------------------
//  23: test the songTVCInfo screen on all availible devices
//      ipad 5th gen -- 1/3/2018 -- Good
//      ipad air -- 1/3/2018 -- Good
//      ipad air 2 -- 1/3/2018 -- Good
//      ipad pro 9.7 -- 1/3/2018 -- Good
//      ipad pro 10.5 -- 1/3/2018 -- Good
//      ipad pro 12.9 -- 1/3/2018 -- Good
//      ipad pro 12.9 2nd -- 1/3/2018 -- Good
//      iphone 5s -- 1/3/2018 -- Good
//      iphone 6 -- 1/3/2018 -- Good
//      iphone 6 plus  -- 1/3/2018 -- Good
//      iphone 6s plus -- 1/3/2018 -- Good
//      iphone 7 -- 1/3/2018 -- Good
//      iphone 7 plus -- 1/3/2018 -- Good
//      iphone 8 -- 1/3/2018 -- Good
//      iphone 8 plus -- 1/3/2018 -- Good
//      iphone se -- 1/3/2018 -- Good
//      iphone x -- 1/3/2018 -- Good
//---------------------------------------------------------------------------------------------------------------------------------------
//  24: test the SamplerConfigInfoScreen screen on all availible devices -- Skimmed over on 1/3/2018
//      ipad 5th gen -- 1/3/2018 -- Good
//      ipad air
//      ipad air 2
//      ipad pro 9.7
//      ipad pro 10.5
//      ipad pro 12.9
//      ipad pro 12.9 2nd
//      iphone 5s
//      iphone 6
//      iphone 6 plus
//      iphone 6s plus
//      iphone 7
//      iphone 7 plus
//      iphone 8
//      iphone 8 plus
//      iphone se
//      iphone x
//---------------------------------------------------------------------------------------------------------------------------------------
//  25: adjusting start and end points -- Looks Good on 1/3/2018
//          small file
//          medium file
//          huge file: there were some issues with moderatly to very large files,
//                          we made a few fixes
//                              needs further testing.
//          Make sure that the minimum interval is being enforced regardless of the control used
//---------------------------------------------------------------------------------------------------------------------------------
//  26: Skipped on 1/3/2018
//          11/20/2017  we made a significant change to the handleAduioRouteChange() method in the master sound mod,
//              TEST THIS AGAIN!!!!!!   ->
//          test audio route changes amongst different soureces across different VCs
//      1:  SequenceVC
//          Call -> timer -> Off -> HeadPhone -> Siri -> Airplay -> Switch -> Speaker -> Bluetooth -- good
//          Speaker -> Airplay -> timer -> Switch -> Bluetooth -> Off -> Call -> Siri -> HeadPhone -- Good
//          Bluetooth -> Siri -> Speaker -> timer -> HeadPhone -> Switch -> Call -> Off -> Airplay -- Good
//      2:  EndPointsVC
//          Airplay -> Switch -> timer -> Siri -> HeadPhone -> Speaker -> Call -> Off -> Bluetooth -- Good
//          Speaker -> timer -> Bluetooth -> Switch -> Airplay -> Off -> Call -> Siri -> HeadPhone -- Good
//          Bluetooth -> Siri -> Switch -> Speaker -> Off -> timer -> Airplay -> HeadPhone -> Call -- Good
//      3:  RecordVC
//          HeadPhone -> Off -> Speaker -> Airplay -> Switch -> Call -> Bluetooth -> Siri -> timer -- Good
//          Airplay -> Siri -> Speaker -> Off -> Bluetooth -> Switch -> Call -> timer -> HeadPhone -- FAIL
//             12/8/2017:
//                  we interrupted a recording with Siri,
//                      when we came back to the app from the for ground the nameing dialoge was present,
//                          we successfully name the file and the recording was made,
//                              it appears that the recording was stopped as soon as the phone moved to Siri.
//          Bluetooth -> Speaker -> timer -> Off -> HeadPhone -> Switch -> Airplay -> Siri -> Call -- Good
//      4: Song TVC Info
//          HeadPhone -> Off -> Speaker -> Airplay -> Switch -> Call -> Bluetooth -> Siri -> timer -- Good
//          Bluetooth -> Siri -> Speaker -> timer -> HeadPhone -> Switch -> Call -> Off -> Airplay -- Good
//          timer -> off -> Bluetooth -> Switch -> Speaker -> Airplay -> Siri -> HeadPhone -> Call -- Good
//      5: SamplerConfig Info
//          Bluetooth -> Siri -> Speaker -> timer -> HeadPhone -> Switch -> Call -> Off -> Airplay -- Good
//          HeadPhone -> Siri -> timer -> Airplay -> Off -> Bluetooth -> Call -> Switch -> Speaker -- Good
//          Bluetooth -> Siri -> timer -> Call -> Speaker -> Off -> Airplay -> Switch -> HeadPhone -- Good
//      6: SongTVC
//          Speaker -> HeadPhone -> Switch -> timer -> Siri -> Off -> Airplay -> Bluetooth -> Call -- Good
//          HeadPhone -> Switch -> Airplay -> Siri -> timer -> Bluetooth -> Call -> Off -> Speaker -- Good
//          Call -> Siri -> Speaker -> Switch -> HeadPhone -> off -> Bluetooth -> Airplay -> timer -- Good
//      7:  SamplerConfigVC
//          timer -> off -> Bluetooth -> Switch -> Speaker -> Airplay -> Siri -> HeadPhone -> Call -- Good
//          HeadPhone -> Siri -> timer -> Airplay -> Off -> Bluetooth -> Call -> Switch -> Speaker -- Good
//          Call -> HeadPhone -> Off -> Bluetooth -> timer -> Switch -> Airplay -> Siri -> Speaker -- Good
//      8:  BankVC
//          Airplay -> Siri -> Bluetooth -> Switch -> Speaker -> timer -> Call Off -> -> HeadPhone
//              2017-11-05 14:17:20.420253-0700 Sampler_App[7950:9234206] [aurioc] 918: failed: '!pla' (enable 3, outf< 2 ch,  48000 Hz, Float32, non-inter> inf< 1 ch,  48000 Hz, Float32>)
//              2017-11-05 14:17:20.504101-0700 Sampler_App[7950:9234206] [avae] AVAEInternal.h:77:_AVAE_CheckNoErr: [AVAudioEngineGraph.mm:1209:Initialize: (err = PerformCommand(*outputNode, kAUInitialize, NULL, 0)): error 561015905
//              2017-11-05 14:17:20.508389-0700 Sampler_App[7950:9234206] *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason: 'error 561015905'
//                    AVAudioSessionErrorCodeCannotStartPlaying == 561015905
//                      I think we were switching between VCs when the error was thrown
//                          maybe we were trying to play a node....
//                              The pan gesture recognizer in the padView class may be a factor.
//          HeadPhone -> timer -> Off -> Bluetooth -> Siri -> Call -> switch -> Speaker -> Airplay
//          timer -> HeadPhone -> Airplay -> Off -> Siri -> Bluetooth -> Speaker -> Switch -> Call
//      9: PadConfigVC
//          Airplay -> off -> Speaker -> Call -> Switch -> timer -> HeadPhone -> Siri -> Bluetooth
//          Bluetooth -> Siri -> timer -> Call -> Speaker -> Off -> Airplay -> Switch -> HeadPhone
//          HeadPhone -> Bluetooth -> Off -> Speaker -> timer -> Switch -> Call -> Airplay -> Siri
//      10:  VolumeVC
//          HeadPhone -> Off -> Airplay -> timer -> Switch -> Speaker -> Call -> Bluetooth -> Siri
//          Speaker -> Bluetooth -> Call -> Switch -> Airplay -> Off -> timer -> Siri -> HeadPhone
//          Bluetooth -> Siri -> Airplay -> Speaker -> Off -> Switch -> timer -> HeadPhone -> Call
//      11: FileSelectorVC
//          Call -> Off -> timer -> Switch -> HeadPhone -> Siri -> Airplay -> Speaker -> Bluetooth
//          Speaker -> Switch -> timer -> Siri -> Bluetooth -> Airplay -> Call -> Off -> HeadPhone
//          Bluetooth -> Speaker -> Off -> timer -> Siri -> Airplay -> Switch -> HeadPhone -> Call
//---------------------------------------------------------------------------------------------------------------------------------------
//  28: File erasing via the FileSelectorTVC
//          test for erasing a file being used in the current song. -- passed on 1/15/2018
//          test for erasing a file that is being used in another loaded song besides the current visible song. -- passed on 1/15/2018
//          test for erasing a file in use by the current pad  -- passed on 1/15/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  27: test to make sure that volume data timers are always getting invalidated,
//          Last tested on 1/3/2018
//         on 12/8/2017 we were seeing what seemed to be some instances where calling .invalidate() on a given timer was not enough to stop it.
//          we might want to always set the timer to nil immediatly after callin invalidate().
//              1:  mash pads until colors get skewed -- 1/3/2018 -- Looks good
//              2:  Playthrough pads
//                      does the timer get canceled upon a black touch?
//                      does the timer get canceled upon a non black touch?
//              3: do timers get canceled when the app goes to the back ground while audio is running? -- 1/3/2018 - Fixed
//                  start/stop pads?
//                  through pads?
//              4: do timers get canceled when the off button is pressed while audio is running? -- 1/3/2018 - Fixed
//                  start/stop pads?
//                  through pads?
//              5: do timers get canceled when SIRI is launched while audio is running? 1/3/2018 -- Looks good
//                  start/stop pads?
//                  through pads?
//---------------------------------------------------------------------------------------------------------------------------------------------
//  29: with any VC that can preivew,
//          test navigating away from the VC while previewing,
//              make sure that invalidating the fade out timers does not make the app crash.
//                  EndpointsVC
//                  PitchVC
//                  PadConfigVC - 12/11/2017 - 20/20
//                  VolumeVC -- Skimmed over on 1/3/2018
//--------------------------------------------------------------------------------------------------------------------------
//  30: test song loading getting interrupted: Skipped on 1/3/2018
//          SIRI
//          Phone Call:
//          TImer:
//          Home Button:
//          WORK THE SILENT SWITCH INTO THE MIX!
//          WORK CHANGING THE VOLUME INTO THE MIX!
//          WORK THE POWER OFF BUTTON INTO THE MIX!
//---------------------------------------------------------------------------------------------------------------------------------------------
//  31: Hammer playthrough mode!!!!
//          make suure that a playthrough pad interrupted by an audio route change,
//              plays on the first press after the route change finishes.
//          12/18/2017 - we implemented new canceling rules to the playthrough mode.
//          Test for canceling more than one playthrough pad at a time,
//              i.e. have more than one playthrough pad playing and then cancel..
//--------------------------------------------------------------------------------------------------------------------------
//  32: test for duplicate song name checking not being case sensitive. -- Good on 1/3/2018
//--------------------------------------------------------------------------------------------------------------------------
//  34: recordings interrupted by audio route changes
//          the very first time we tried our implementation,
//              a minute or so after we successfully made a recording after we were warned of the audio route interruption,
//                  we got a file load memory alert.....
//                       as of 11/7/2017 this is only the second time we've seen the memory alert out side of a simulator.
//               When we immediatly tried the process again,
//                  after naming a file after the interrupt,
//                      we got the volumeDataArray Exception
//                          this was part of the console output:
//                              2017-11-07 22:15:05.599013-0700 Sampler_App[9029:10696050] [Common] _BSMachError:
//                              port a60b; (os/kern) invalid capability (0x14) "Unable to insert COPY_SEND"
//        Alarm:        we did not test this last time because of laundry.
//        home button:
//        Bluetooth:
//        Headphone:
//        call:
//        Siri:
//        Switch:
//        Off:
//--------------------------------------------------------------------------------------------------------------------------------------------
//  33: Test for loading a sound into a loaded pad
//          Go 30/30
//              on 12/11/2017 we saw BAD_ACCESS exeption on dad's ipad while connected to the machine,
//                  we were no able to reproduce the bug while iPad was not connected,
//                      and we did not see in on the 6s while phone was not connected.
//          No issues on 1/3/2018 -- we did not test on dad's old iPad.
//---------------------------------------------------------------------------------------------------------------------------------------
//  35: test for loading and configuring sounds in the second and third banks in the demo song.
//              TRy to do anything and everything you can with the demo song.
//          Seems fine on 1/3/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  36: test for how the app runs over all on half charged or below battery
//---------------------------------------------------------------------------------------------------------------------------------------
//  37: audio inturruptions in all VCs capable of producing audio playback:
//              incoming phone call
//                  BankVC -- 1/5/2018 - 5/5
//                  SequenceVC -- 1/5/2018 - 5/5
//                  PadConfigVC -- 1/5/2018 - 5/5
//                  VolumeVC -- 1/5/2018 - 5/5
//                  EndpointsVC -- 1/5/2018 - 5/5
//                  PitchVC -- Skipped on 1/5/2018
//                  FileSelectorVC -- 1/5/2018 - 5/5
//              timer alarm
//                  BankVC -- 1/5/2018 - 5/5
//                  SequenceVC -- 1/5/2018 - 5/5
//                  PadConfigVC -- 1/5/2018 - 5/5
//                  VolumeVC -- 1/5/2018 - 5/5
//                  EndpointsVC -- Skipped on 1/5/2018
//                  PitchVC -- skipped on 1/5/2018
//                  FileSelectorVC -- 1/5/2018 - 5/5
//              Off
//                  BankVC -- 1/5/2018 - 5/5
//                  SequenceVC -- 1/5/2018 - 5/5
//                  PadConfigVC -- 1/5/2018 - 5/5
//                  VolumeVC -- Skipped on 1/5/2018
//                  EndpointsVC -- Skipped on 1/5/2018
//                  PitchVC -- 1/5/2018 - 5/5
//                  FileSelectorVC -- 1/5/2018 - 5/5
//              SIRI
//                  BankVC:  -- 1/5/2018 - 20/20
//                              12/13/2017
//                              on the THIRD try we saw the frozen app bug,
//                                  we tried moving the app back and forth from the fore ground,
//                                      once the app returned to the foreground the app was no longer unresponsive but producing silence.
//                                          we even tried loading a new sound into a pad and the pad still prduced silence.
//                              on another run we saw no major issues after 10 tries.
//                  SequenceVC -- 1/5/2018 - 10/10
//                  PadConfigVC -- 12/13/2017 -- Good, no issues in 20 tries
//                  VolumeVC -- 12/13/2017 -- Good in 10 tries
//                  EndpointsVC -- 12/13/2017 - good in 10 tries
//                  PitchVC -- 12/13/2017 - good in 10 tries.
//                  FileSelectorVC -- 12/13/2017 -- good in 20 tries.
//---------------------------------------------------------------------------------------------------------------------------------------------
//  38: make sure the bank button images look good in a variety of screens for both the BankVC and the SequenceVC
//          skipped on 1/25/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  39: test the songTVC on all screens:
//      ipad 5th gen -- good on 1/5/2018
//      ipad air -- skipped on 1/5/2018
//      ipad air 2 -- skipped on 1/5/2018
//      ipad pro 9.7 -- skipped on 1/5/2018
//      ipad pro 10.5 -- skipped on 1/5/2018
//      ipad pro 12.9 -- skipped on 1/5/2018
//      ipad pro 12.9 2nd -- skipped on 1/5/2018
//      iphone 5s -- good on 1/5/2018
//      iphone 6 -- good on 1/5/2018
//      iphone 6 plus -- skipped on 1/5/2018
//      iphone 6s plus -- skipped on 1/5/2018
//      iphone 7 -- skipped on 1/5/2018
//      iphone 7 plus -- good on 1/5/2018
//      iphone 8 -- good on 1/5/2018
//      iphone 8 plus -- good on 1/5/2018
//      iphone se -- good on 1/5/2018
//      iphone x  -- good on 1/5/2018
//      Dad's iPad -- good on 1/5/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  40: test the SamplerConfigVC on all screens: Last tested on 12/16/2017
//          NEXT TIME MAKE SURE TO LAUNCH A SONG SO WE CAN MAKE SURE THE WARNING LABEL LOOKS GOOD.
//      ipad 5th gen -- good on 1/5/2018
//      ipad air -- Skipped on 1/5/2018
//      ipad air 2 -- Skipped on 1/5/2018
//      ipad pro 9.7 -- Skipped on 1/5/2018
//      ipad pro 10.5 -- Skipped on 1/5/2018
//      ipad pro 12.9 -- Skipped on 1/5/2018
//      ipad pro 12.9 2nd -- good on 1/5/2018
//      iphone 5s -- Settings and Release buttons are truncated - 1/5/2018
//      iphone 6 -- good on 1/5/2018
//      iphone 6 plus -- Skipped on 1/5/2018
//      iphone 6s plus -- Skipped on 1/5/2018
//      iphone 7 -- Good on 1/5/2018
//      iphone 7 plus -- Skipped on 1/5/2018
//      iphone 8 -- Skipped on 1/5/2018
//      iphone 8 plus -- Skipped on 1/5/2018
//      iphone se -- Settings and Release buttons are truncated - 1/5/2018
//      iphone x -- Good on 1/5/2018
//      Dad's iPad -- Good on 1/5/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  41: test the BankVC on all screens
//      ipad 5th gen -- Good on 1/5/2018
//      ipad air -- Good on 1/5/2018
//      ipad air 2 -- Good on 1/5/2018
//      ipad pro 9.7 -- Good on 1/5/2018
//      ipad pro 10.5 -- Good on 1/5/2018
//      ipad pro 12.9 -- Good on 1/5/2018
//      ipad pro 12.9 2nd -- Good on 1/5/2018
//      iphone 5s -- Good on 1/5/2018
//      iphone 6 -- Good on 1/5/2018
//      iphone 6 plus -- Good on 1/5/2018
//      iphone 6s plus -- Good on 1/5/2018
//      iphone 7 -- Good on 1/5/2018
//      iphone 7 plus -- Good on 1/5/2018
//      iphone 8 -- Good on 1/5/2018
//      iphone 8 plus -- Good on 1/5/2018
//      iphone se -- Good on 1/5/2018
//      iphone x -- Good on 1/5/2018
//      Dad's iPad -- Good on 1/5/2018 -- Still not making any sounds
//---------------------------------------------------------------------------------------------------------------------------------------
//  42: Test for dragging in large directory heirarchies into itunes and see if all the files show up in the fileSelectorTVC - Passed on 1/15/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  43:  Test for audio route changes during playback,
//          NEXT TIME do a little bit of shuffeling of the order of things her and there...
//          WORK CHANGING THE VOLUME INTO THE MIX!
//          make sure nothing crashes
//              test a variety of route change scenarios
//      2: Airplay -> Power Button -> bluetooth -> Switch -> call -> speaker -> Siri -> headphone
//              BankVC
//              SequenceVC
//              PadConfigVC
//              FileselectorVC
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      3:  Speaker -> Switch -> headphone -> SIRI -> bluetooth -> call -> Airplay -> Power Button
//              BankVC
//              SequenceVC
//              PadConfigVC
//              FileselectorVC
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      4:  Speaker -> power button -> bluetooth -> SIRI -> calls -> Switch -> Airplay -> Headphone
//              BankVC
//              SequenceVC
//              PadConfigVC
//              FileselectorVC
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      5:  Speaker -> Siri -> calls -> Power Button -> Airplay -> Switch -> headphone -> bluetooth
//              BankVC
//              SequenceVC
//              PadConfigVC
//              FileselectorVC
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      6:  Bluetooth -> Switch -> call -> Power Button -> headphone -> Siri -> speaker -> Airplay
//              BankVC
//              SequenceVC
//              PadConfigVC
//              FileselectorVC
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      7:  Bluetooth -> Power Button -> Switch -> headphone -> call -> Siri -> speaker -> Airplay
//              BankVC
//              SequenceVC
//              PadConfigVC
//              FileselectorVC
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      8:  Bluetooth -> Siri -> Speaker -> Switch -> call -> headphone -> Power Button -> Airplay
//              BankVC
//              SequenceVC
//              PadConfigVC
//              FileselectorVC
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      9:  Headphone -> Switch -> bluetooth -> Power Button -> call -> speaker -> Siri -> airplay
//              BankVC
//              SequenceVC
//              PadConfigVC
//              FileselectorVC
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      10:  Headphone -> Power Button -> call -> Siri -> speaker -> bluetooth -> Switch -> airplay
//              BankVC -- Good
//              SequenceVC -- Good
//              PadConfigVC -- Good
//              FileselectorVC -- Good
//              VolumeVC -- Good
//              EndpointsVC -- Good
//              PitchVC -- Good
//      11:  Headphone -> Siri -> speaker -> Power Button -> bluetooth -> call -> Switch -> airplay
//              BankVC -- Good
//              SequenceVC -- Good
//              PadConfigVC -- Good
//              FileselectorVC -- Good
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      12: Airplay -> Switch -> call -> Power Button -> speaker -> bluetooth -> Siri -> headphone
//              BankVC -- Good
//              SequenceVC -- Good
//              PadConfigVC -- Good
//              FileselectorVC -- Good
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      13: Airplay -> Siri -> headphone -> Power Button -> call -> speaker -> Switch -> bluetooth
//              BankVC -- Good
//              SequenceVC -- Good
//              PadConfigVC -- Good
//              FileselectorVC -- Good
//              VolumeVC
//              EndpointsVC
//              PitchVC
//      1: Airplay -> Switch -> speaker -> headphone -> Siri -> call -> Power Button -> bluetooth
//              BankVC -- 1/7/2018: app crahsed when we after we pressed the off button and came back to the app. Phone was not connected
//              SequenceVC -- 1/7/2018: Good
//              PadConfigVC -- 1/7/2018 -- Good
//              FileselectorVC -- 1/7/2018 -- Good
//              VolumeVC -- 1/7/2018 -- Good
//              EndpointsVC -- Skipped on 1/7/2018
//              PitchVC -- Skipped on 1/7/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  44: test the PadConfigVC on all screens
//      ipad 5th gen -- Good -- 1/7/2018
//      ipad air -- Good -- 1/7/2018
//      ipad air 2 -- Good -- 1/7/2018
//      ipad pro 9.7 -- Good -- 1/7/2018
//      ipad pro 10.5 -- Good -- 1/7/2018
//      ipad pro 12.9 -- Good -- 1/7/2018
//      ipad pro 12.9 2nd -- Good -- 1/7/2018
//      iphone 5s -- Good -- 1/7/2018
//      iphone 6 -- Good -- 1/7/2018
//      iphone 6 plus -- Good -- 1/7/2018
//      iphone 6s plus -- Good -- 1/7/2018
//      iphone 7 -- Good -- 1/7/2018
//      iphone 7 plus -- Good -- 1/7/2018
//      iphone 8 -- Good -- 1/7/2018
//      iphone 8 plus -- Good -- 1/7/2018
//      iphone se -- Good -- 1/7/2018
//      iphone x -- Good -- 1/7/2018
//      Dad's iPad -- Good -- 1/7/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  45: test the RecordVC on all screens: -- Last Tested on 1/7/2018
//      ipad 5th gen -- Good -- 1/7/2018
//      ipad air -- Good -- 1/7/2018
//      ipad air 2 -- Good -- 1/7/2018
//      ipad pro 9.7 -- skipped -- 1/7/2018
//      ipad pro 10.5 -- skipped -- 1/7/2018
//      ipad pro 12.9 -- skipped -- 1/7/2018
//      ipad pro 12.9 2nd -- Good -- 1/7/2018
//      iphone 5s -- Good -- 1/7/2018
//      iphone 6 -- skipped -- 1/7/2018
//      iphone 6 plus -- skipped -- 1/7/2018
//      iphone 6s plus -- skipped -- 1/7/2018
//      iphone 7 -- skipped -- 1/7/2018
//      iphone 7 plus -- skipped -- 1/7/2018
//      iphone 8 -- skipped -- 1/7/2018
//      iphone 8 plus -- skipped -- 1/7/2018
//      iphone se -- Good -- 1/7/2018
//      iphone x -- Good -- 1/7/2018
//      Dad's iPad -- Good -- 1/7/2018
//---------------------------------------------------------------------------------------------------------------------------------------
//  46: test the VolumeVC on all Screens:  -- last tested in 1/7/2018
//      ipad 5th gen -- Bad Logged 1/7/2018
//      ipad air -- Bad Logged 1/7/2018
//      ipad air 2 -- Bad Logged 1/7/2018
//      ipad pro 9.7 -- Bad Logged 1/7/2018
//      ipad pro 10.5 -- Bad Logged 1/7/2018
//      ipad pro 12.9 -- Bad Logged 1/7/2018
//      ipad pro 12.9 2nd -- Bad Logged 1/7/2018
//      iphone 5s -- Good -- 1/7/2018
//      iphone 6 -- Good -- 1/7/2018
//      iphone 6 plus -- Good -- 1/7/2018
//      iphone 6s plus -- Good -- 1/7/2018
//      iphone 7 -- Good -- 1/7/2018
//      iphone 7 plus -- Good -- 1/7/2018
//      iphone 8 -- Good -- 1/7/2018
//      iphone 8 plus -- Good -- 1/7/2018
//      iphone se -- Good -- 1/7/2018
//      iphone x -- Bad Logged 1/7/2018
//      Dad's iPad -- Bad Logged 1/7/2018
//--------------------------------------------------------------------------------------------------------------------------------
