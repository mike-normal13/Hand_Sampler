//
//  BackBurner.swift
//  Sampler_App
//
//  Created by Budge on 11/7/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

//  1:      DON'T DEAL WITH FILE LOADING MEMORY UNTIL THE PADCONFIG NO LONGER INUNDATES THE CONSOLE WITH CONSTRTAINT ERRORS.
//      we have memory warning handling due to file loading/recording in place,
//      however much like when we try to deallocate songs,
//          we do not see an immediate dip in memory usage...
//              MEMORY LEAK!
//  2:      as of 11/1/2017 the app seems to be less leaky than it was before....
//      we have songs being deallocated when the memory warning ocurrs,
//          however the deallocation does not seem to have any impact on the apps memory usage....
//          https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/AutomaticReferenceCounting.html
//          we are anticipating three scenarios which will result in didRecieveMemoryWarning() being called:
//              1:  The user chooses to launch a song which results in running out of memory.
//              2:  The user loads a sound into a pad which results in running out of memory.
//              3:  The user records a sound into a pad which results in running out of memory.
//          There are two possible ways of handling these three scenarios:
//              1:  release the memory of any songs that are currently loaded besides the current song
//              2:  Alert the user that the sound being loaded or recorded is too large,
//                      and skip loading it into the pad.
//          We currently do not have any code in play which handels warning in case of loading or recording a file.
//              having the didReceiveMemoryWarning() method in a seperate class lower in the heirarchy might be an option...
//          Which VCs could be visible when a warning ocurrs
//              1:  SamplerConfigVC -> bankVC
//                      warning would happen here as a result of the user loading a song.
//                          WE PRETTY much have this case handled..
//              2:  fileSelctorVC -> padConfigVC
//                      warning would happen here as a result of the user loading a sound.
//              3:  recordVC -> PadConfigVC
//                      warning would happen here as a result of the user recording a sound.
//          IF YOU have VC class with didReceiveMemoryWarning() defined,
//              and if said class is not nil when the memory warning occurs
//                  then didReceiveMemoryWarning() will be called in that class.
//              Yes,
//                  for each memory warning that occurrs,
//                      each non nil class with didReceiveMemoryWarning() defined will have its didReceiveMemoryWarning() called.
//          RIGHT NOW 10/23/2017,
//              there is an issue of inconsistency as to which definition of didReceiveMemoryWarning gets called first....
//                  And we are hanving trouble handling .isVisible in the PadConfigVC because the SongTVC immediatly shows an AlerVC....
//          IF WE ditch the didREceive in the PadConfigVC,
//              we could have a _loadFile flag
//                  which indicates whether the the current load action is a result of song loading or file/recording loading.
//                      and then just have that flag be adjusted every time either a song is loaded, or a file is loaded or recorded.
//                          and we couyld have said adjust ment take place via observers and notifications....
//  3: Media Server Reset?
//          WE SHOULD SPEND NO MORE THAN 1 HOUR AT A TIME ON THIS!
//              IT IS NOT NEARLY AS HIGH A PRIORITY AS OTHER THINGS!
//          My guess is that we are not disposing of things properly when the reset ocurrs.
//          https://developer.apple.com/library/content/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/HandlingAudioInterruptions/HandlingAudioInterruptions.html
//              Handling the reset on each VC:
//                  SongTVC: if the reset occurs before moving to any SamplerConfigVC the app does not crash
//                            IF the reset occurs after we have moved back from a SamplerConfigVC without moving to a BankVC the app does not crash.
//                          The app crashes if we have moved to a BankVC with or without loaded sounds
//                              and then we move back to the SongTVC as soon as the alert is dismissed.
//                  SamplerConfigVC:
//                          If the reset occurrs before moving to a BankVC the app does not crash
//      WE LEFT OFF on implementing the popToSamplerConfigVCIfNeeded() method....
//      11/9/2017: we get a run time exception after we try to present the AlertVC,
//                  try stepping into the present call.
//      on 11/15/2017:
//          we saw the media server reset alert screen pop up by itself when we disconected the phone from the machine
//              while the app was running from a launch initiated by the machine........
//  9: look into those two exceptions uncoverd by the exception break point
//          __cxa_throw and objc_exception_throw
//              for __cxa_throw:
//                  in the master sound mod,
//                      it might be a good idea to get rid of the _mainMixer member and simply just refer to,
//                          self._engine.mainMixerNode.....
//                              but once this is done we need to test for a variety of things....
//                      the call in connectPadToMixer in MasterSoundMod to connect a padMixer to the engine is hanging up on __cxa_throw,
//                              I have no idea why......
//          for objc_exception_throw:
//                  on 11/21/2017 we launched a song and when we got to the bankVC the exception was not thrown,
//                      the padCOnfigVC was broken at the time so we were unable to dig deeper.
//                  on 11/25/2017 we explored all screens,
//                      the exception was not thrown,
//                          we did NOT load a file or make a recording.......
//  10: SamplerConfigVC
//          THE FROZEN APP BUG
//          11/30/2017
//          YOU NEED TO BE COMPLETELY FOCUSED TO SOLVE THIS!!!
//              We were testing moving to and from SIRI while a song was loading.
//                  once we got the the bankVC the app was frozen and seems to be ignoring interaction events,
//                      the weird thing is that the last print out about interaction events is this:
//                          resetPadColors() in BankVC began ignoring interaction events
//                          resetPadColors() in BankVC stopped ignoring interaction events
//                          applicationDidBecomeActive in AppDelegate stopped ignoring application interaction events
//                              we were able to get the app to snap out of it via the home button.
//              12/10/2017:
//                  this bug seems to be harder to trigger now,
//                      however we did see it happen and we saw the printout:
//                          [AnyHashable("AVAudioSessionInterruptionTypeKey"): 1]
//                              setUpAudioInterruptionNotification() in AppDelegate Application began ignoring interaction events. Thread:
//                       the print out:
//                          [AnyHashable("AVAudioSessionInterruptionTypeKey"): 1] seems to be invloved with the halting
//  11: DEBUG: MasterSoundMod
//          11/30/2017 -- we need to retest this due some recent changes to the master sound mod....
//              We were testing moving the app to and from teh back ground via the home button while a song was loading(go to song button)
//                  On the 16th try we moved the app to and from the background a few time while the app was loading,
//                      we moved to the third bank,
//                          we presssed one of the pads and started seeing the bad connection alert,
//                              the reconnection process did not seem to work after several tries,
//                                  and we kept getting bad connection alerts over and over again
//                                      the case being triggered in the checkForPadConnection() method is:
//                                          if(padMixerInConnectionPoint == nil)
//                                      In this if statement there is no call to try to reconnect the node......
//                  On 12/2/2017 we 20/20 passes....
//         12/10/2017:
//              THIS IS NO LONGER BULLET PROOF!
//                  IT SEEMS LIKE A CALL TO STARTMOD() IN MASTER SOUND MODE IS CAUSING THE AVAudioSessionErrorCodeCannotStartPlaying ERROR...
//          12/11/2017:
//              in startMod in MasterSoundMod we now check to see if the engine is running before we attempt to start it,
//                  ON THE 22ND TRY we saw the 561015905 error
//                      print out:
//                          +++++++applicationDidBecomeActive in AppDelegate stopped ignoring application interaction events
//                              +==========++==startMod() in masterSoundMod began
//                              !!!!!!!!!!!!reconnectPadMixersAfterRouteChange() in MasterSoundMod connected padMixer
//                                  bank: 2 and pad: 0 to engine's main mixer node
//                              [aurioc] 918: failed: '!pla' (enable 3, outf< 2 ch,  48000 Hz, Float32, non-inter> inf< 1 ch,  48000 Hz, Float32>)
//                              [avae] AVAEInternal.h:77:_AVAE_CheckNoErr:
//                                  [AVAudioEngineGraph.mm:1209:Initialize:
//                                      (err = PerformCommand(*outputNode, kAUInitialize, NULL, 0)): error 561015905
//                              *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason: 'error 561015905'
//                          SO IT LOOKS AS though a call to reconnectPadMixersAfterRouteChange()
//                              and a call to startMod() are happening at the same time on separate threads.....
//  14: TODO:   RecordVC
//              the binary search extension at the bottom of SyncTransmitter did not work for us when checking for duplicate names.
//              the high variable would get stuck and we enter an infinite loop.
//                  it would be nice to not to have to do a linear search when checking for duplicte file names
//                      maybe the array we get from the loader is not sorted.....
//  16: MasterSoundMod:
//          calculating a exponential fade:
//          for(i = 0; i < 10ms i++)
//          {
//              table[i] = 1 - (start * pow((end/start), (i/10ms)))
//          }
//  17: TODO: FileSelectorVC
//          11/30/2017
//          if you load a big file,
//          move to SIRI or press the home button,
//              and then comback to the app,
//                  the activity indicator stops animating.
//                      this seems to be happening insonsistently
//          11/4/2017:
//              we have the code in place
//                  there is a delay in the activity indicator starting reanimating.
//                  My guess is that we need to do the same sort of thing that we did in starting the activity indicator in the samplerConfigVC...
//          11/9/2017:
//              scrap the call that trickles down from the appDelegate
//                  Instead have the FileSelectorCell class have an observer which waits for the UIApplicationWillEnterForegroundNotification...
//                      //              once we get this working remove the code starting in the AppDelegate.
//          12/10/2017:
//              it seems that even the observer-notifiaction method does not work
//                  because the observer method does not get called until after the sound mod is restarted and reconnected,
//                      by this time the file is already loaded......
//          This is not a huge priority
//  20: FileSelectorCell -- go 20/20
//          on 12/9/2017,
//          we lanuched the app while not connected to the machine,
//              we tried to load the dilla beat,
//                  presssed the home button while the file was loading and the app crashed.
//                      don't know why.....
//                  It happened three times(with the dilla beat),
//                          one or more times the activity indicator was not stopped
//                      having trouble triggering the bug while connected...
//          12/23/2017 -- we pressed the home and off button a couple of times,
//                          when we moved back to the bankVC and tried to trigger the pad we saw:
//                              *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:
//                                  'player started when engine not running'
//  21: DEBUG: RecordVC
//          as of 11/29/2017
//          if a recording is interrupted by either the home button, the off button, or an incoming call
//              the recording is canceled but the user is not alerted that the recording was canceled.
//                  if we want to fix this
//                      the isRecordingTakingPlace() call chain will need to return the bank and pad numbers
//                          so that the SongTVC will be able to properly call alertAndStopRecording() in SamplerConfigVC.....
//  22: DEBUG: RecordVC
//          12/13/2017
//              If we move the app to the background while the RecordVC is visible to say, access the timer app,
//                  once we bring the app to the foreground again,
//                      it does not seem to matter how long we wait for the app to get on its feet again,
//                          no matter how long we wait,
//                              once we press the record button we see the recording-interrupted-by-audio-route-change alert.
//  23: RecordVC:
//      Interrupting a recording ---
//              Alarm, Homb Button, Call:    12/13/2017
//                      once we dissmiss the timer the record button goes gray,
//                          no audio route change alert appears,
//                              and no naming dialogue appears either.
//                                  I'm willing to bet that the recording is still being stored however....
//                                      I'm pretty much positive of this,
//                                          the good news is that the file keeps getting overwritten...
//  24: RecordVC:
//      Interrupting a recording ---
//        Bluetooth, Headphone:    12/13/2017:
//                          we consistently see the printout:
//                              Warning: Attempt to present <UIAlertController: 0x1028c3400>  on <UINavigationController:
//                                  0x102842e00> which is already presenting <UIAlertController: 0x102902400>
//                          App did not crash in 20 tries.
//                              WE ONLY HAD FOUR SOUNDS LOADED THOUGH!!!!
//  25: RecordVC:
//      Interrupting a recording ---
//        Siri: 12/13/2017
//                  once the app comes back to foreground,
//                      regardless of how long we wait,
//                          once the record button is pressed -- AND HELD -- we see the audio route changed alert.
//                          IF HOWEVER,
//                              the record button is only breifly held and then released,
//                                  we see the naming dialogue...
//                      The app did not crash in 20 tries.
//  26: RecordVC:
//      Interrupting a recording ---
//        Off:  12/13/2017
//                  the audio route change alert did not preset untill 10th try....
//                      it seems to depend how quickly we press the off button after the record button is pressed
//                      The app did not crash in 20 tries.
//  27: RecordVC: if this VC appears and the potential overwrite alert is presented,
//          and if we press the cancel button,
//              it is possible to press the back button before the VC is popped,
//                  which will result in the padConfigVC getting popped as well....
//  28: DEBUG: SequenceVC -- THIS BUG IS REAL
//          on 11/26/2017 we moved the app to the background,
//          when we came back we spastically pressed the SequenceVC and we saw in the console that the app began ignoring interaction events,
//              but the call to end ignoring interaction events never came and the app freezes.
//                  it is not easy to reproduce this bug,
//                      might want to go for 30/30
//                          it might help to have longer sounds be part of the sequence.
//          On 11/29/2017 we made the bugg appear,
//              we had pressed the off button.
//                  the app was frozen on the blue screen.
//  29:  SamplerConfigVC
//          try going for 20/20 when having a call interrupt a song being loaded.
//          we made significant changes to the MasterSoundMod on 12/10/2017....
//              12/10/2017 the checkForPadConnection() method now calls connectPadToMixer() if a nil pad mixer is encountered.
//         ON 12/11/2017 on the eighteenth try we got the invalid channel count and sample rate excpetion,
//              here is the tail end of the print out:
//                  ..............connectPadToMixer() in masterSoundMod began
//                      *$*$*$*$* handleAduioRouteChange() in masterSoundMod passed outDescription check
//                      [aurioc] 918: failed: '!pri' (enable 3, outf< 2 ch,  48000 Hz, Float32, non-inter> inf< 1 ch,  48000 Hz, Float32>)
//                      ~~~~~~~installReadTapOnPadMixer() in masterSoundMod began
//                      ~~~~~~~installReadTapOnPadMixer() in masterSoundMod returned
//                      ..............connectPadToMixer() in masterSoundMod returned
//                      ..............connectPadToMixer() in masterSoundMod began
//                      *$*$*$*$* handleAduioRouteChange() in masterSoundMod set _inputFormat
//                      ~~~~~~~installReadTapOnPadMixer() in masterSoundMod began
//                      ~~~~~~~installReadTapOnPadMixer() in masterSoundMod returned
//                      ..............connectPadToMixer() in masterSoundMod returned
//                      ..............connectPadToMixer() in masterSoundMod began
//                      [aurioc] 918: failed: '!pri' (enable 3, outf< 2 ch,  48000 Hz, Float32, non-inter> inf< 1 ch,  48000 Hz, Float32>)
//                      *$*$*$*$* handleAduioRouteChange() in masterSoundMod set _outputFormat
//                      +_)+)+_)+_)reconnectEngineAfterAudioRouteChange() in masterSoundMod began
//                      ))))()()))))()))))reconnectEngineAfterAudioRouteChange() in masterSoundMod returned early due to invalid output format.
//                      ``***``````stopAllCurrentPlayerNodes() in masterSound node began.
//                      [avae] AVAEInternal.h:69:_AVAE_Check: required condition is false:
//                          [AVAudioEngineGraph.mm:1894:_Connect:   (IsFormatSampleRateAndChannelCountValid(format))]
//                      *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:
//                          'required condition is false: IsFormatSampleRateAndChannelCountValid(format)'
//  30: DEBUG: BankVC
//          on 11/19/2017 we were trying to solve the bug of a playing pad being interrupted by the home button being pressed.
//                  and then after the app returns to the foreground,
//                      the interrupted pad has to be pressed at least twice before it will sound again.
//                          reseting all the player nodes in the player node array did not fix the problem
//          BankVC
//          if we play a sound and then interrupt the sound by either a call or pressing the home button,
//          once we come back to the BankVC we have to press the pad that was interrupted twice before it will play again.
//              also the exact color of the interrupted pad remains when come back to the BankVC.
//          12/3/2017:
//              now when the app comes back from the background,
//                  stop is called on every node in the pad's playerNodeArray.
//              However,
//                  we observed that when the app comes back from the background,
//                       upon the first touch play() does not seem to be getting called in the padModel.
//         12/7/2017
//          we are seeing instances where after we come back from the background,
//              and the call to play() on an actual AVAudioPlayerNode in the padModel is producing silence....
//  32: TODO:   BankVC
//          we could possibly implement a mechanism for disntinguishing for why the touchesCanceled method is being called in the PadView here,
//          once the TouchesCanceled() method is called in the PadView,
//              the delegate method called in this class could check to see how many touches are down in the view which contains all the pads.....
//                  not a high priority!
//                      But it should not be too difficult to implement either.
//  33: DEBUG:  BankVC
//          if we are pressing multiple pads while the home button is pressed,
//              once we come back sometimes the pads are the same coloring as when the home button is pressed....
//  35: TODO:   BankVC
//          as of 12/15/2017
//          the demo song does not load its pads in parallel,
//              for some reason pads for the first bank in the demo song were coming up nil...
//                  we could try moving the .waitUntilAllOperationsHaveFinished() call into a narrower scope...
//  36: TODO: BankVC
//          11/16/2017
//          we changed the sixthTouch() method to get rid of the blank pad problem...
//          have not tested pressing the BankVC with 6 fingers yet.
//              as of 11/29/2017:
//                  if we press 6 fingers to the BankVC no sort of canceling action takes place,
//                      and in fact once we let up all fingers,
//                          any pad that is still playing is not stopped.
//  39: TODO:   PadView
//           down the road have option to show file names in a label for each pad
//          12/27/2017 -- Pretty sure the labels are being placed, far, far off screen.
//          1: place the label in the middle if the padview,
//              have the label's width be the width of the pad view
//          2: rotate the label
//          3: adjust the label's origin to be in the upper right corner.
//  41: DEBUG: FilesSelectorCell
//          12/21/2017
//          if we choose one of the demo files,
//              all the labels disappear while the sound loads,
//                  only the activity indicator remains visible
//          It might be easier to make all cells behave like this......
//  42: DEBUG: FileSelectorCell
//          12/28/2017
//          the library sounds choose button is not visible on Dad's iPad....
//         12/29/2017:
//              the choose button is visible on the iPad simulators....
//  43: TODO:   RecordVC
//              a timer becoming visible during a recording would make the app actually appear as professional.....
//  44: TODO:   RecordVC
//               giving the user the ability to choose the format of the recorded file would be nice......
//  45: TODO:   SeqeunceVC
//              refactoring the locking code will reduce many lines of code.....
//  47: TODO:   SongTVC
//              figure out how to get an array representaion of the Splash_lib so we don't have to use that giant switch statement in SaveDemo()...
//  48:TODO:   SongTVC
//          energy saver mode in SettingsVC...
//          make it so all VCs will go to sleep.
//  49: DEBUG:  SongTVC
//              12/28/2017
//              if you erase every song,
//                  the next time you launch the app you get the brand new app alert and the demo song appears in the list.
//  50: TODO:   SongCell
//          need to look into table cells in the SongTVC being more snazzy,
//          like the cells in the Mail TVC
//              You Know,
//                  like those extra little options that appear on the right hand side when you swipe left on the cell
//                      https://developer.apple.com/documentation/uikit/uitableviewcell
//                          swipeable cell?
//                              erasing a song by swiping a cell left?
//                  https://developer.apple.com/videos/play/wwdc2014/236/
//                      https://developer.apple.com/documentation/uikit/uiviewpropertyanimator
//                          https://github.com/SwipeCellKit/SwipeCellKit
//              We could possibly have one of the swipable options by a connect to host button...
//  51: TODO:   Loader
//              getAllMusicFiles() and getAllMusicFilesNames() are virtually the same method...
//              But they have diferent return types...
//                      we could return Any.....?
//  52: DEBUG:  MasterSoundMod
//          12/11/2017 not a huge priority
//          we were testing moving the app to and from the background while a song was being loaded,
//              we got to a state where the app was producing silence,
//                  the startMod() method was reporting that the engine could not be started due to other audio playing,
//                      we closed many other apps,
//                          YouTube, perc app, mail, etc...,
//                              when we closed to only other remaining app which was the timer,
//                                  the app began making noise again...
//  53: TODO:   MasterSoundMod
//          make it so older devices just display a solid, static color when playing via the BankVC.
//          we might be able to not worry about latency if this has the desired affect.
//  54: DEBUG: MasterSOundMod
//          12/22/2017
//          playthroughFadeout() is getting called when a playthrough pad is not getting canceled by itself,
//          i.e. the first time it is pressed,
//              this is not the worst thing that can happen,
//                  but it is unintended nonetheless...
//  54: TODO:   FileSelectorVC
//          the alterSequenceAlert() method is virtually identical to the same method in the RecordVC,
//  55: TODO:   SongCell
//          we need to display somthing else in the cells,
//          either the number of files loaded,
//              or the size total of all the files loaded,
//                  or both.
//  56: TODO:    Song -- ANCIENT PROBLEM!!
//          the pad [2][7] problem still persists,
//          but we can still play pads in the first and second banks.
//  57: TODO: PadView
//          it would be awesome if playthrough pads maintained their color after  being released...
//              only spend 30 mins on this....
//  58: DEBUG:  PadConfigVC
//              12/3/2017:
//              still having to press the preview button more than twice
//                  in some cases to get the preview to sound after returning from the background
//  59: DEBUG:  SamplerConfigVC
//      plugging in headphones during VC transistion.
//      SamplerConfigVC -> BankVC
//          headphone:
//                  12/21/2017: Third Try
//                  we connected and diconnected the head phones a few times while the song was loading and we got:
//                      *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:
//                          '[[busArray objectAtIndexedSubscript:(NSUInteger)element] setFormat:
//                              format error:&nsErr]:
//                                  returned false, error Error Domain=NSOSStatusErrorDomain Code=-10865 "(null)"'
//                                      10865 = kAudioUnitErr_PropertyNotWritable
//  60: DEBUG: SamplerConfigVC
//              11/30/2017: if a call comes in while a song is being loaded we consistently see:
//                  *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:
//                      'required condition is false: IsFormatSampleRateAndChannelCountValid(format)'
//                              THIS HAPPENED 3/3 TRIES
//          12/9/2017:
//              on the 13th try we got this:
//                  *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:
//                      'required condition is false: node != nil && [_nodes containsObject: node]'
//                          we added some early returns to the checkForPadConnection() in the masterSoundMod
//                              we did not verify that this is where the exception was coming from however....
//          on 12/10/2017 we added code to the masterSoundMod's checkForPadConnection() method,
//              if this method encounters a nil padMixer,
//                  it just calls connectPadToMixer() for the pad with its pad mixer missing,
//                      we are seeing good results with.
//              WE HAVE NOT SEEN 20/20 AS YET,
//                  GO FOR IT NEXT TIME!
//          on 12/21/2017 on the 16th try we saw:
//              IsFormatSampleRateAndChannelCountValid(format)
//  61: TODO:   SamplerConfigVC
//              global settings, e.g. file labels in pads, etc
//  62: DEBUG: SamplerConfigVC
//          11/30/2017 pressing the off button while a song is loading repeatedly can cause this:
//              *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason: 'error 561015905'
//                          were moving the app to and from the back ground during song loading multiple times.
//  63: TODO:   SamplerConfigVC
//          instead of having the activity indicator being renaimated by a call from the app delegate,
//          add an observer to this class which listens for the UIApplicationWillEnterForegroundNotification.......
//              once we get this working remove the code starting in the AppDelegate.
//  64: DEBUG: FileSelectorCell
//          12/4/2017          GO 20/20!!!!!!!!!!!!!!!!!!!
//              we interrupted loading a large file via the choose button,
//                  when we came back from the background,
//                      it took a little while but the app did crash.
//                          'required condition is false: IsFormatSampleRateAndChannelCountValid(format)'
//                               the error was thrown before we had a chance to bring the app back from the background.
//                                  we were trying to load the dilla beat which is an .aif file
//                  We tried doing the same thing with .wav files and the bugg would not manifest
//                          this bugg does not happen consistently
//                              file format is probably not the issue.
//              on 12/9/2017 we found the cause of the problem,
//                  it is the connecteing and reconnecting of the sound engine whenever a route change occurs....
//              12/12/2017
//                  we interrupted a file load with a phone call,
//                      we got the insuficient priority exception: 561017449
//  65: BankVC
//          12/20/2017
//          when we wiped dad's iPad,
//              and then when we launch the demo song the pads are lighting up,
//                  but no sound is being produced.
//          1/2/2018:
//              demo sounds still not sounding
//  67: TODO: PitchVC
//          1/2/2018
//          add an info screen informing the user about the double tap phenominom.
//  68: TODO: SongTVC
//          if adding a song's cell to the table view results in the table being scrolled automatically,
//          it might be nice to highlight said cell.....
//          Look at how the mail app highlights its cells....
//  70: TODO: BankVC & SequenceVC:  we're probably going to have to make our own custom button class if we want activity indicators
//      if we are to have the bank buttons display an activity indicator,
//          we're probably going to have to make our own custom button class
//                  https://stackoverflow.com/questions/36539650/display-activity-indicator-inside-uibutton
//  4:  TODO: BankVC
//          make sure the bank button images look good in a variety of screens
//                  on all these screens the color seems to be idfferent than the color on my 6s,
//                      I'm not sure if I trust it......
//      iphone 6 plus -- iffy
//      iphone 6s plus -- iffy
//      iphone 7 plus -- iffy
//      iphone 8 plus -- Iffy
//      iphone x -- Iffy
//  5: TODO:   BankVC
//          we need to rescale our 100X100 number images down to around 50X50,
//          or at least experiment,
//              the numbers look pixelated on dad's iPad....
//  6:  BankVC
//          as of 1/4/2018
//          in resetPadColors()
//              we added an else statement in the for loop
//                  which partially solves playthrough pads not going black when they get cancelled by another pad,
//                      with this else statement,
//                          the playthrough pad will stay red until the other canceling pad is released..
//  7: DEBUG: BankVC 11/30/2018
//          when we move to this VC and if there are multiple files missing due to eraser,
//              when only get one alert for one file.....
//  8: BankVC - TODO: 1/7/2018
//          it is difficult to trigger a playthrough pad with other pads at the same time....
//              we'll live with it for now....
//  9: BankVC
//          11/29/2017
//          if you spastically press pads for a while,
//              you can get this class to a state where the _numberOfCurrentlyTouchedPads variable gets corrupted,
//                  we saw a case where the variable reported 4 when there was only one pad pressed.....
//  10: BankVC
//          swiping between PadConfigVCs is handled in the handleConfigButton() method around line 1000
//              AND in swipePreviousPadConfigVC() around line 1453
//  11: PadConfigVC
//          TODO: 1/11/2018
//          on smaller screens
//              we could possible make the font size bigger on the trigger mode label by making the label multi line,
//                  we'd have to adjust some constraints to make this work though....
//  5: FileSelectorVC
//        on 1/11/2018 we went 30/30 and the app did not crash.
//          1/9/2018
//              GO 30/30 first before trying to resolve this it may not be worth while to fix this..
//              if we are previewing while we press the home button we consistently see this printout that does not cause the app to crash,
//                  but is concerning none the less:
//                      [avas] AVAudioSession.mm:1177:-[AVAudioSession setActive:withOptions:error:]:
//                          Deactivating an audio session that has running I/O.
//                              All I/O should be stopped or paused prior to deactivating the audio session.
//                                  App Delegate could not deactivate audio session.
//                                      The operation couldn’t be completed. (OSStatus error 560030580.)
//  6:  SamplerConfiVC:
//          the top portion of the view is very small on the ipads....
//          we might want to increase its height...
//  7:  EndPointsVC
//          it would be nice if for the wider screen devices (iPads),
//              each of the four vertical stack views in the outer horizontal stack view could adjust their widths
//                  depending on the width of the device's screen.....
//  8: SamplerSettingsVC -- 1/7/2018
//          on the smaller devices(5s and SE),
//          the container view does not have rounded corners and has no margines.
//  9: 1/8/2018
//          PitchVC
//              make only one button pressable at a time
//                  is it possible to corrupt the pitch by doing this...?
//  10: EndpointsVC
//          1/5/2018 mutual exclusion of endpoint adjustment is not 100%,
//          but we at least make it plain in the UI that it is not intended for the user to be able to do so.
//  11: BankVC
//          12/28/2017
//          it is possible to spastically press pads and accedentally move to the padConfigVC twice,
//              we saw an instance where this made the app crash due to runtime error
//                  complaining about pushing the same VC twice.....
//          on 12/29/2017 we were unable to get the bug to manifest even when we decreased the pan velocity threshold fro the padView...
//          on 1/12/2018 we wer again unseccuessful in torggering the bug
//  1: FileSelectorVC
//          1/9/2018
//          some of the atari sounds take too long to start previewing,
//              don't know why,
//                  there is an AVAudioFile or AVAudioPlayer init that takes in a hint arg,
//                      we should look into faster previewing
//                          because at this point the access to the _indexDictionary should be constant!!!!
//  2: SongVC
//          1/10/2018
//          momentary highligthing of the selected cell will be easy to pull off with a notificationt/observer
//          once any SamplerConfigVC appears just post a notification telling the cells to set their background color back to black,
//  3: SamplerConfigVC
//          12/28/2017
//              something is up with renaming a song that has missing files.
//                  we see the missing file alert,
//                      but the pads that have the missing files have sounds in them...
//                          I think the sounds are the sounds which were loaded before we switched to the sounds that were erased....
//  18: DEBUG: FileSelectorCell
//          12/20/2017
//          On Dad's iPad.
//          the cells are white as soon as the FileSelectorVC appears,
//              they turn yellow during previewing,
//                  once they are released they turn gray
