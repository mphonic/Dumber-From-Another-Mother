# SC DFAM
## Dumber from Another Mother

A SuperCollider instrument inspired by the Moog DFAM. It's similar, but it's... more.

## Requirements

This software needs to be run in [Supercollider](https://supercollider.github.io/downloads.html), which is free. You don't need to know anything about Supercollider to use it, but if you know Supercollider, you can do a whole lot of extra wild stuff.

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
Then hit shift-enter. The DFAM interface should open (it may open in a background window, so check your app tray / dock for a grey cube icon). Hit "L" on the interface to load presets. Some presets are meant for the included code examples. If all of the "Pitch" and "Vel" knobs are at center, you're probably looking at one of those presets. For any other preset, hit the "Play" button and start messing around. 

"S" allows you to save the current state as a preset. "R" records the audio into the `/recordings` folder (remember to hit it again to stop recording). Hitting ctrl-. (cmd-. on Mac) will stop everything and close the interface window. Just repeat the steps above to start again.

Much more documentation coming soon... (See [Donate](#donate) below to help carve out time for such intense labor)

## Controlling with SC Code
There are a few code examples that show how the DFAM can be controlled with regular Supercollider programming. See `probability-sequence.scd`, `gendy-sequence.scd` (you'll need [sc3-plugins](https://github.com/supercollider/sc3-plugins/releases) for that example), and `two-dfams.scd`.  

Details on how to access DFAM properties coming soon...

# Donate
[Venmo](https://account.venmo.com/u/Bhob-Rainey)

[PayPal](https://paypal.me/bhobrainey)

This is a one-person operation. Please enjoy the fruits of open source software and share your own efforts. Also consider donating to help offset the massive effort and swaths of time eaten up in the creation, testing, and documenting of these wild tools. It really, really helps!


