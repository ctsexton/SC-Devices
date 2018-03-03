This is a polyphonic harmonizer taking advantage of Miller Puckette's [sigmund~] object for pitch analysis in Pure Data and SuperCollider's multichannel expansion for the re-synthesis.

To do:
Build the GUI that allows the user to select their MIDI device. At the moment my keyboard is hardcoded into the SC document (easy to edit though!).

To run, execute: ./start_harmonizer in a shell.

Requirements:
Pd-Vanilla
SuperCollider 3.x

In linux obviously you need jack to be running before you start. 
It should work fine on Mac and Windows, you might need to adjust audio settings manually in Pd and SC though. 
On Windows you'll need a bash shell in order to run the startup file.
I'm assuming that since you're on github you know what you're doing though so it shouldn't be hard to get this up and running on any OS that runs Pd and SC.

One day when I learn enough C++ I'll write a SC Ugen equivalent of [sigmund~]. I'm surprised it doesn't seem to exist yet!


