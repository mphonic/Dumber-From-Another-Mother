# Dumber from Another Mother

A SuperCollider instrument inspired by the [Moog DFAM](https://www.moogmusic.com/synthesizers/dfam/). It's similar, but it's... more. More modules, more patching, more modulation, more idiosyncrasies.

![Screenshot of Dumber from Another Mother](https://github.com/mphonic/SC-DFAM/blob/master/images/dumber-gui.png)

# Donate
[Venmo](https://account.venmo.com/u/Bhob-Rainey)

[PayPal](https://paypal.me/bhobrainey)

This is a one-person operation. Please enjoy the fruits of open source software and share your own efforts. Also consider donating to help offset the massive effort and swaths of time eaten up in the creation, testing, and documenting of these wild tools. It really, really helps!

## Requirements

This software needs to be run in [Supercollider](https://supercollider.github.io/downloads.html), which is free. You don't need to know anything about Supercollider to use the Dumber from Another Mother, but if you know Supercollider, you can do a whole lot of extra wild stuff.

If you've successfully installed another of my Supercollider pieces, you probably already have sc3-plugins and do not need to do anything else. If not, after installing Supercollider, you'll need to download and install [sc3-plugins](https://github.com/supercollider/sc3-plugins/releases). There are instructions in the download package that explain how to install (you'll need to move some files to a folder), but, to repeat:

1. Download the package that corrensponds to your OS.
2. Unzip the package and read the README file (it's short).
3. To find your Supercollider extensions folder (if the README file doesn't help), open Supercollider and enter `Platform.userExtensionDir.openOs`. Keep your cursor on the line with that code and hit shift-Return (Mac) or Shift-Enter. Your extensions folder should open up in your OS's file explorer.
4. Move the unzipped SC3Plugins folder to the Extensions folder. 
5. Quit and restart Supercollider. You should be good to go.

If you're using a Mac and find that your OS has put extensions in "quarantine", you can open `unquarantine-mac-extensions.scd` and run the code there.
 
If you followed instructions and wind up with an error akin to "Can't find MoogVCF", then you probably didn't quite succeed at installing sc3-plugins. 

## Getting Started

In Supercollider, open the `play-dfam.scd` file. Put your cursor somewhere within this block of code:
```
(
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
)
```
Then hit ctrl-enter. In the Post Window (bottom right panel), you should see some text spitting out. At the end of that text, you should see:
```
Creating modules...
Modules created
Starting synths...
Synths started
Loading settings...
Settings loaded.
Ready to go.
```
The DFAM is now running, but you'll probably want an interface. Put your cursor on this line:
```
~dfam.makeGui();
```
Then hit shift-enter. The DFAM interface should open (it may open in a background window, so check your app tray / dock for a grey cube icon). Hit "L" on the interface to load presets. Some presets are meant for the included code examples. If all of the "Pitch" and "Vel" knobs are at center, you're probably looking at one of those presets. For any other preset, hit the "Play" button and start messing around. When the sequencer is stopped, you can hit "Trigger" to launch the sound at the current step.

"S" allows you to save the current state as a preset. "R" records the audio into the `/recordings` folder (remember to hit it again to stop recording). Hitting ctrl-. (cmd-. on Mac) will stop everything and close the interface window. Just repeat the steps above to start again.

The [Donate](#donate) button reminds you to donate. Did I mention that it really, really helps?

Just like the Moog DFAM, this instrument can produce a vast array of sounds from only a few sources. A single patch can play the role of kick, snare, bass, and bizarre animal squelch, and a single tweak to a single patch can change things drastically.

More documentation may be coming soon. If you have used [xynthii](https://github.com/mphonic/xynthii), many of the same principles apply, though DFAM does not have as many features as xynthii -- it is designed to be quick and dirty and fluid and fun.

## MIDI Control
See the `midi-control.scd` file for an example. You can use a keyboard, set legato, keytrack, and velocity sensitivity. You can map cc to different parameters.

## Controlling with SC Code
There are a few code examples that show how the DFAM can be controlled with regular Supercollider programming. See `probability-sequence.scd`, `randomize-settings.scd`, `stutter.scd`, `gendy-sequence.scd`, `dumb-machine.scd`, and `two-dfams.scd`.  

For more granular detail, see `sc-dfam-guide.scd`.
