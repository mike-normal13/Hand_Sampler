//
//  Plans.swift
//  Sampler_App
//
//  Created by Budge on 11/1/17.
//  Copyright © 2018 Michael Grant Fleming. All rights reserved.
//

//  As of 9/18/2017 we had around 6000 lines of code
//  As of 11/8/2017 we have 8,456 lines of code.
//  As of 12/22/2017 we have 11,543 lines of code(counted network code).

// look up status error codes:
//  https://www.osstatus.com/search/results?platform=all&framework=all&search=-50

//----------------------------------------------------------------------------------------------------------------------
// Ultimate check list for christmas release:
//----------------------------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------------------------
// Last added todo class: FileSelectorVC
//----------------------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------------------------------------
//  1:  App Delegate:
//          1/24/2018 revise all try catch blocks
//  2: naming a song with a matching prefix as the demo song is problematic....
//  5: Tomorrow start the day by testing things,
//          spend the entire first half the day testing things,
//              test no less than three things!!!
//  6: how to beta test the app:
//          https://stackoverflow.com/questions/40154/how-do-you-beta-test-an-iphone-app
//  7: resolve any random things that get printed out to the console...
//              LIST OF THINGS PRINTED OUT IS BELOW....
//  8: give the app a test run on dad's iPad.
//          last time was on 1/11/2018 -- wait three days
//  11: how do we make some views rotatable and other views not?
//--------------------------------------------------------------------------------------------------------------------------
//*******************************************************************************************************************************
//*******************************************************************************************************************************
//--------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------
//  Future features:

//  1: Choose number of pads per bank
//  2: More than one possible recorded sequence per bank
//  3: IN the padConfigVC,
//      have an option for a pad to stop any or all other pads on touch down
//  4: let users choose format for recorded sounds
//  5:  Don't forget about the multiroute audiosession mode
//          we could have playback ocurring on the speaker and bluetooth at the same time....
//  6: decible increment/decrement buttons in PadConfigVC
//  7: apparently there is a comes with Limiter:
//      https://stackoverflow.com/questions/35011702/matching-input-output-hardware-settings-for-avaudioengine
//------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------
//  Ghost Buggs:

//  1: 10/21/2017 11:02 pm
//          When phone was disconnected,
//              App was crashing repeatedly once the go to song button was pressed on multiple songs.
//              When we connected the phone to the computer the crashing stopped.
//
//  2:  10/22/2017
//        Declining a call with ongoing bluetooth connection made the app crash,
//            but not consistently…
//              we tested again the day after and had a 5 for 5 sucess rate...
//------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------
//  Random errors that get printed out to the Console

//  1:  "UIColor created with component values far outside the expected range.
//          Set a breakpoint on UIColorBreakForOutOfRangeColorComponents to debug.
//              This message will only be logged once."
//                  https://stackoverflow.com/questions/39557590/graphics-uicolor-created-with-component-values-far-outside-the-expected-range
//  2: 11/26/2017:
//          [Common] _BSMachError: port bb23; (os/kern) invalid capability (0x14) "Unable to insert COPY_SEND"
//                      we were testing interrupting recordings with home button
//                          happened more than once while testting the scenario 20 times
//           11/30/20176: this might be non-issue:
//                      https://stackoverflow.com/questions/37800790/hide-strange-unwanted-xcode-logs
//           we consitently see the _BSMachError in all VCs capable of producing audio playback
//                      when we interrrupt playback to move to SIRI.
//  3:  11/26/2017:
//                  The operation couldn’t be completed. (OSStatus error 560030580.)
//                      we were testing interrupting recordings with home button
//                            560030580: kAudioSessionNotActiveError
//                              we are probably trying to do something while the audioSession is inactive....
//  4:  11/26/2017:
//                  [Snapshotting] Snapshotting a view (0x15e890600, UIKeyboardImpl) that is not in a visible window requires afterScreenUpdates:YES.
//                      we were testing interrupting recordings with home button
//  5:  11/27/2017:
//              if we interrupt a recording with an incoming call we get:
//                   Warning: Attempt to present <UIAlertController: 0x1028c9000>  on <UINavigationController: 0x102807200>
//                          which is already presenting <UIAlertController: 0x1020e3400>
//------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------
//  Test cases that seemed to be a non issue

//  1: having a timer or alarm in the Clock app go off does not seem to cause any sort of crash regardless of which VC is visible.
//          it will prbably be a good idea to test this again in a simulator.
//          Also with a timer going the timer sounding was not always consistent.
//          With the Alarm going off we did not see an instance where the alarm produced any sound.
//  2: if we are connected to bluetooth and have headphones plugged in at the same time,
//      if we unplugg the headphones,
//              sound from the bluetooth speaker suddenly goes about half as loud and then ramps back up again.
//          I suspect that bluetooth modes are geting switched some how..
//              A2DP seems to be louder than the other modes.
//      11/4/2017 NOW that we are exclusivly using A2DP,
//          the issue seems to have dissappeared
//  3:  On 11/27/2016 we decided this was no longer an issue due to the check we added to the MasterSoundMod's startMod() method
//                      we tested for 30/30
//          on 11/20/2017 we were unable to get the bug to manifest,
//              regardless of whether a pad was being played when the interruption occurred.
//      NEXT TIME GO FOR 20 FOR 20!!!!
//      this bug has nothing to do with which visible when it happens.
//              BankVC: on 10/15/2017 we were moving to the timer screen as soon as the timer went off via the little pop over view.
//                          at one point we pressed the pop over view right as the alarm was starting to sound,
//                              at this point we saw a print out indicating that a start/stop on the master sound mode failed.
//                                  we repeated having an alarm go off,
//                                      move to the alarm screen,
//                                          set the timer,
//                                              then move back to the BankVC a few times until we got this run time exception:
//                                                  2017-11-15 15:06:31.163266-0700 Sampler_App[509:129112] [aurioc] 918: failed:
//                                                      '!pla' (enable 3, outf< 2 ch,  48000 Hz, Float32, non-inter> inf< 1 ch,  48000 Hz, Float32>)
//                                                  2017-11-15 15:06:31.190427-0700 Sampler_App[509:129112] [avae] AVAEInternal.h:77:_AVAE_CheckNoErr:
//                                                         [AVAudioEngineGraph.mm:1209:Initialize:
//                                                              (err = PerformCommand(*outputNode, kAUInitialize, NULL, 0)): error 561015905
//                                                  2017-11-15 15:06:31.191296-0700 Sampler_App[509:129112]
//                                                      *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:
//                                                          'error 561015905'
//                                                                 aparrently error number 561015905 is AVAudioSessionErrorCodeCannotStartPlaying.
//                     on 11/21/2017:
//                             the excpetion was thrown on the 19th try!!!
//                                  the app is more solid than before...
//                                      maybe looking into the __CXA_throw will make things better...
//             I AM WILLING TO BET THIS EXCEPTION HAS NOTHING TO DO WITH WHICH VC IS SHOWN WHEN IT OCCURRED.
//                                      we were able to produce the same exception with the same actions taken with the padConfigVC visible.
//                                          ... and the FileSelectorVC in and out of silent mode ...
//                                              ... and the RecordVC ....
//                              The exception is being thrown in the MasterSoundMod's startMod() method.
//                                  the exception is always thrown when we bring the app back to the foreground.
//          on 11/25/2017 the excpetion popped up on the 16th try in the sequenceVC
//              we were testing moving back and forth from the back ground due to a timer going off while audio was playing.
//          on 11/25/2017 we added a check to the startMod() method in master sound mod to help solve the problem....
//   4: On 11/27/2017 we added a check to the handleAduioRouteChange() method in masterSoundMod,
//          which maded it so we did not disconnect and reconnect the sound graph if the app was not active,
//              we successfully tested an incomming call interrupting audioo playback 30/30 times.
//          Next time we test this,
//              test for touching the little timer tab at the top of the screen which automatically presents the Timer screen.
//                  see if the app is still viable once we move back to it.
//          SequenceVC: 11/15/2017
//                  this exception happens immediatley,
//                              before we are able to move the app back to the foreground.
//                      the very first time we pressed the clock pop over menue before the alarm sounded and got this run time exception:
//                          2017-11-15 15:25:39.709422-0700 Sampler_App[515:137715] [aurioc] 918: failed:
//                              '!pla' (enable 3, outf< 2 ch,  48000 Hz, Float32, non-inter> inf< 1 ch,  48000 Hz, Float32>)
//                          2017-11-15 15:25:39.751582-0700 Sampler_App[515:137715] [aurioc] 918: failed:
//                              '!pla' (enable 3, outf< 2 ch,  48000 Hz, Float32, non-inter> inf< 1 ch,  48000 Hz, Float32>)
//                          2017-11-15 15:25:39.752725-0700 Sampler_App[515:137715] [avae] AVAEInternal.h:69:_AVAE_Check:
//                              required condition is false:
//                                  [AVAudioEngineGraph.mm:1894:_Connect: (IsFormatSampleRateAndChannelCountValid(format))]
//                          2017-11-15 15:25:39.753531-0700 Sampler_App[515:137715]
//                              *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:
//                                      'required condition is false: IsFormatSampleRateAndChannelCountValid(format)'
//                              WE WERE ABLE TO have the same result in the bankVC while phone was in silent mode
//                                  ... and the PadCOnfigVC while the phone was in silent mode .....
//                                      ... and the SequenceVC while the phone was in silent mode ...
//                                          ... and the RecordVC while the phone is in silent mode ...
//                           if we stop the alarm without the app moving to the background,
//                              the app does not crash
//                  on 11/21/2017 we tried to recreate throwing IsFormatSampleRateAndChannelCountValid,
//                      by pressing the timer pop over view before any sound
//                          the exception was not thrown in 20 tries.....
//      on 11/15/2017 we were testing moving back and forth from the background while NOT producing any audio via previewing
//      FileSelectorVC: WE WERE MOVING BACK AND FORTH FROM THE BACKGROUND AT FASTER RATE THAN the previous test runs!
//          on 11/15/2017 on the eleventh try:
//              2017-11-15 14:00:18.586542-0700 Sampler_App[469:103434] [aurioc] 918: failed:
//                  '!pla' (enable 3, outf< 2 ch,  48000 Hz, Float32, non-inter> inf< 1 ch,  48000 Hz, Float32>)
//              2017-11-15 14:00:18.615945-0700 Sampler_App[469:103434] [aurioc] 918: failed:
//                  '!pla' (enable 3, outf< 2 ch,  48000 Hz, Float32, non-inter> inf< 1 ch,  48000 Hz, Float32>)
//              2017-11-15 14:00:18.616446-0700 Sampler_App[469:103434] [avae] AVAEInternal.h:69:_AVAE_Check:
//                  required condition is false: [AVAudioEngineGraph.mm:1894:_Connect: (IsFormatSampleRateAndChannelCountValid(format))]
//              2017-11-15 14:00:18.616952-0700 Sampler_App[469:103434]
//                  *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',
//      BankVC: 11/19/2017:
//                  we saw the bugg pop up after pressing the home button while playing a pad.
//                      on 11/21/2017 we tried testing the issue again:
//                          the bugg did not pop up after 20 tries
//      11/20/2017:
//              we might want to consider setting a prefered format.....
//                  you can set a preferred sample rate on the AVAudioEngine.....
//                      we called setPreferredSampleRate on the AVAudioSession member in the AppDelegate,
//                          we set the preferred sample rate to 44100.
//      11/17/2017:
//              we were playing sounds in the BankVC,
//                  a text came in,
//                      we put the app in the background to respond to the text,
//                          and when we came back to the BankVC the app threw the exception.
//      on 11/25/2017 we were unable to make the error pop up,
//          we tested the SequenceVC
//              and the fileSelectorVC
//      on 11/26/2017 WE WERE TESTING FOR AUDIO being interrupted by an incomming call,
//          this exception popped up on all VCs which were able to produce audio playback,
//              including the FileSelectorVC

//  5:  TOP***:     Thread 1: EXC_BAD_ACCESS (code=1, address=0x55555555555550)
//              Thread 1: EXC_BAD_ACCESS (code=1, address=0x9c9c3170)
//          updateVolumeData() in master sound mod occasionaly will throw bad access,
//              definitely a threading issue
//                  I'm having a very hard time triggering the exception while the phone is not being run via xcode.
//          as of 10/30/2017 we are invalidating the timer whenever and audio route change occurs,
//              we have not seen the bug in a while,
//          Keep this bug at the top with the "blank pad" bug.
//        ON 11/4/2017 this bug was triggered while trying to navigate to the PadConfigVC with a newly implemented swipe Gestuer.
//      thrown on 11/5/2017 when testing audio route changes in the sequenceVC,
//              prior to the exception being thrown,
//                  we saw the old issue of all pads turning gray and staying gray.....
//      on 11/6/2017 we saw the bug happen during just regular play in the BankVC,
//          we may have dragged a touch out of a pad,
//              but we tried this behavior over and over again and the but did not reappear
//      on 11/8/2017 the bug appeared two times in a row when we made changes to the volume in the volumeVC,
//          and then previewed the changes in the volumeVC,
//              and then move back to the BankVC,
//                  once we played the pad that volume's was alterd the exception was thrown.
//      on 11/9/2017 we made the volumeDataTimer an array,
//          so each pad gets its own timer,
//              WE ARE VERY MUCH ANTICIPATING THIS BUGG BEING FIXED WITH THIS ADJUSTMENT!
//      on 11/14/2017 the bug popped up
//          we trying to trigger the 6th touch I think.
//              we were tyring very hard to break the app...
//      on 11/17/2017
//          we loaded avery pad in every bank,
//              and played pads many, many, many, many times
//                  and the bugg popped up.
//      on 11/17/2017 we changed this:
//              private lazy var _padMixerVolumeDataArray: [[Float?]?]! = [];
//          To this:
//              private lazy var _padMixerVolumeDataArray: [[Float]] = [];
//                  this did not fix the problem
//      on 11/17/2017 WE HAVE SURRENDERED!
//          we have disabled installing taps on mixer nodes,
//              and we are no longer passing volume data to the padViews
//      on 11/18/2017:
//          we stopped declaring the _volumeDataArray as lazy,
//              we mashed pads for 55 minutes straight and were not able to produce the exception.
//  6:  TOP****:  KEEP THIS ITEM AT THE TOP!
//      If a "Blank Pad" scenario pops up,
//              drop what your are doing and debug!!!!
//      it appears that the "Blank pad" problem has to do with the masterSoundMod's startMod() method not getting called during audio route changes.
//      on 10/24/2017 we observed this behavior after we launched the app when in the previous launch of the app we made a recording...
//      ALSO it looks like the bad memory access to the data array goes hand in hand with this scenario.
//      In the past it seemed like a good way to trigger this was to intiate an audio route change
//          and pressing the Go TO Song button very close to each other.
//      ON 11/15/2017:
//          we saw a blank pad when moved to the background while the bankVC was playing a sound and then moved to the foreground again.
//              in this instance the code reached all the way to the play() call on the current AVPlayerNode in the Pad Model.
//                  it might be a start/endpoint issue.
//      ON 11/16/2017:
//          we may have found the source of the problem,
//              in BankVC sixthTouch() has a for loop that calls padTouchUp(),
//                  effectivly calling stop on all pads in the current bank.
//              getting rid of the call let us pass the test of pressing the home button while a sound was playing 20/20 times......
//      On 11/17/2017:
//          we had every pad in each bank loaded,
//              we were spastically playing pads,
//                  and switching between banks and the SequenceVC
//                      and a pad came up blank,
//                          we tried loading a new sound into the blank pad,
//                              and the pad stayed blank
//               RELEASE TIMER!!!!!!!!
//  7:     'required condition is false: !srcNodeMixerConns.empty() && !isSrcNodeConnectedToIONode'
//          This bug may have had to do with the way we were previously handling the activity indicator in the SamplerConfigVC....
//          on 11/10/2017 we saw this runtime exception,
//          it might have happened first thing,
//              the BankVC had not yet appeared...
//                  [avae] AVAEInternal.h:69:_AVAE_Check: required condition is false:
//                      [AVAudioEngineGraph.mm:1961:_Connect: (!srcNodeMixerConns.empty() && !isSrcNodeConnectedToIONode)]
//                           *** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason:
//                                  'required condition is false: !srcNodeMixerConns.empty() && !isSrcNodeConnectedToIONode'
//          https://forums.developer.apple.com/thread/44833
//        on 11/14/2017 the excpetion was thrown again after we presssed the Go To Song button in the samplerConfigVC.
//          the exception seemed to be originating from master sound mod,
//              at the bottom of the for loop in connectPadToMixer()....
//          on 11/16/2017
//              the app on the 6s had 5 songs to choose from,
//                  we launched each of the 5 songs per app launch 20/20 times without the bugg manifesting.
//          On 11/17/2017
//              we launched a song with every pad loaded in each bank and the exception was thrown when we pressed the go to song button.
//                  I THINK THAT WHEN WE LAUNCH SONGS BECUASE OF THE THREADS WE USE,
//                      it is possible for some things to be done out of intended order.......
//                          this happend a second time on the same day.
//------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------
//  Some things we'll probably need to inform users of

//  1:  as of 10/17/2017 the app will play sound out of the speaker regardless of the position of the silent switch.
//          however if a call comes in while the phone is not set to silent the ring tone will come out of the phone speaker
//              But if a call comes in while the phone is set to silent the ring tone will not play.

//  2:  In silent mode,
//          we did not see a wake up alarm make any noise.
//              11/20/2017:
//                  I doubt this is still the case....

//  3: if connected to airplay,
//          we witnessed audio glitches as long as the blue bar was visble,
//              once the blue bar turns gray the audio glitches stopped.

//  4: if an airplay connection is established,
//      if multiroute mode is not enabled and the user pluggs in the headphones the airplay connection will be killed.

//  5: if multiroute mode is not enabled,
//        the current audio route will be prempted by a change in audio route.
//          e.g. if current route is Speaker and headphones are plugged in,
//              the audio route will change to headphones.
//              Or if current route is Airplay and headphones are plugged in,
//                  Airplay connection will be severed and audio route will be changed to headphones..
//                      etc.

//  6: Airplay -> bluetooth -> call -> speaker -> headphone
//            If we launch while mirroing Airplay and then make a bluetooth connection,
//                the audio route changes to bluetooth.
//                If we accept and then disconnect from a call the audio route changes back to airplay.
//                Disconnecting from airplay results in  route change to speaker and not bluetooth
//            if we decline the call the audio route stays on bluetooth,
//                once we turn off the blue tooth speaker the audio route changes back to airplay

//  7:  11/20/2017
//      there is no reason to press either the BankVC or the Sequence with 6 fingers!!
//                  IT'S NOT A PIANO!!!
//          currently as of 11/20/2017 if you press 6 fingers against either the BankVC or the SequenceVC
//              the app will give undesireable results,
//                  but it will not crash.
//          there is a problem with distinguishing between why the touchesCanceled() is getting called,
//

//  8: on 11/24/2017
//      we saw an instance where the phone's battery was very low(below 10%),
//          and when we played sounds there were bad noises...

//  9: if you preview in one of the settings VCs and then dissmiss the VC while the preview is ongoing,
//          you can stop the preview in the PadConfigVC.

//  10: we did not test for incoming calls happening during any VC transitions
//          all bets are off....
//------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------
//  THINGs to read up on:

//  1: memory safety
//      https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/MemorySafety.html#//apple_ref/doc/uid/TP40014097-CH46-ID567
//  2: @IBDesignable, @IBInspectable
//  3: property observers
//  4:  peek and pop
//          https://developer.apple.com/documentation/uikit/peek_and_pop
//                  https://www.youtube.com/watch?v=31U9A30ZApE
//              if(traitCollection.forceTouchCapability == UIForceTouchCapability.availible)
//------------------------------------------------------------------------------------------
