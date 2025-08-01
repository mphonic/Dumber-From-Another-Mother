// To start a DFAM, run this from a file in the same directory as sc-dfam.scd:
(
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
)
// Wait until you see "Ready to go." in the Post Window.
// You will now have a global variable, ~dfam, that contains the instrument.

// Load settings from a file:
// ~dfam.loadSettings("/path/to/file", callbackFunc);
// Save settings to a file:
// ~dfam.saveSettings("/path/to/file", callbackFunc);
// In both cases, the callbackFunc provides a dictionary of settings as an argument:

~dfam.loadSettings(Document.current.dir ++ "/presets/default", {|dict| ~settings1 = dict });
~settings1.keys.postln;

// Set settings from a dictionary:
// ~dfam.setFromSettings(dictionary, settingsName), e.g.
~dfam.setFromSettings(~settings1, "mysettingsname");
// You could use the above if you want to store a bunch of settings in variables (using, e.g., setting = Object.readTextArchive("/path/to/setting")) and cycle through them without reading from disk each time

// Open a gui:
~dfam.makeGui();
/*
.makeGui(bounds: nil, keepUpdated: true, knobMode: \vert);
args:
bounds - nil or an instance of Rect
keepUpdated - boolean, determines whether setParams on any module will also update the gui
knobMode - default mode for all Knobs
*/

// Trigger all of the envelopes:
~dfam.trigger();

// MODULES
// You can access individual modules with the appropriate property; e.g.,
~dfam.osc1

/* Module list
Oscillators:
.osc1
.osc2
.noise

Filter:
.filt

Envelopes:
.osc1Env
.osc2Env
.filtEnv
.vcaEnv

Mix:
.osc1Mix
.osc2Mix
.noiseMix

Sequencer:
.seq

LFO:
.lfo

VCA:
.v

Output:
.out
*/

// A list of modules sorted by their order in the Node Tree (bottom to top) is available with .sortedModules
~dfam.sortedModules;
~dfam.sortedModules.collect({|m| m.name });

// MODULE CONTROLS
/*
Each module has a .setParams method that works the same as Node.set: (\arg1, a, \arg2, b, ...)
*/
~dfam.osc2.setParams(\freq, 60, \fmLevel, 0.5);

/*
Some modules have convenience methods to perform common parameter setting, like starting / stopping the sequencer, changing the filter type, etc. Below is a list of controls and convenience methods for each module type.
*/

// OSCILLATORS
/*
args for setParams:
\freq - oscillator frequency, 0.1 - 20000
\pw - pulse width, 0.0 - 1.0
\envLevel - intensity of envelope modulation of frequency, -1.0 - 1.0
\fmLevel - intensity of frequency modulation from fm input, 0.0 - 1.0
\pitchmod - additional scaling of frequency up to 5 octaves, -1.0 - 1.0 (used specifically when linking the sequencer pitch values to the oscillator)
\amp - amplitude, 0.0 - 1.0
*/
~dfam.osc1.setParams(\freq, 440, \pw, 0.25);

// Convenience methods
// Change waveforms
~dfam.osc1.pulse();
~dfam.osc1.tri();

// Sync / unsync
~dfam.osc2.sync(~dfam.osc1); // argument is the sync source -- it should always be the other oscillator
~dfam.osc2.unsync();

// FILTER
/*
args for setParams:
\ffreq - cutoff frequency, 20 - 20000
\res - resonance, 0.0 - 1.0
\envLevel - intensity of envelope modulation of cutoff, -1.0 - 1.0
\fmLevel - intensity of frequency modulation from fm input, 0.0 - 1.0
\ffreqmul - additional scaling of cutoff (direct multiplication, useful for implementing keytracking)
\amp - amplitude, 0.0 - 1.0
*/

// Convenience methods
// Switch between lowpass and highpass
~dfam.filt.hi();
~dfam.filt.lo();

// ENVELOPES
/*
args for setParams:
\att - Attack
\dec - Decay
\curve - Curve (default: -4)
\t_gate - Trigger-rate gate, 0 or 1
*/

// Convenience methods
// Trigger envelope
~dfam.filtEnv.trigger(); ~dfam.vcaEnv.trigger();
// For the VCA envelope's Short / Long attack settings
~dfam.vcaEnv.longAtt();
~dfam.vcaEnv.shortAtt();

// SEQUENCER
/*
args for setParams:
\p - An array of size 8 that sets the pitch values of the sequence, -1.0 - 1.0
\v - An array of size 8 that sets the velocity values of the sequence, -1.0 - 1.0
\tempo - The trigger rate in hz; e.g., 8th notes at 120bpm = (60/2/120).reciprocal
\play - Play or not, 1 or 0
\t_advance - Advance a step without triggering
\t_repeat - Retrigger the current step
\t_reset - Reset to step 1
*/

// Convenience methods
// startSeq has optional argument andReset
// set it to true if you want to reset at step 1
~dfam.seq.startSeq();
~dfam.seq.startSeq(true);
~dfam.seq.stopSeq();
~dfam.seq.advanceSeq();
~dfam.seq.resetSeq();

// LFO
/*
args for setParams:
\freq - the frequency (when appropriate to the LFO type)
\t_gate - trigger input for LFOs that operate on a trigger (Trig FF and Trig Rand)
*/

// Convenience methods
~dfam.lfo.tri();
~dfam.lfo.pulse();
~dfam.lfo.saw();
~dfam.lfo.sh();
~dfam.lfo.noise();
~dfam.lfo.dust();
~dfam.lfo.trigFF();
~dfam.lfo.trigRand();

// MIXERS and VCA
/*
args for setParams:
\amp - Amplitude
*/

// Note that the VCA softclips its output. Gain staging via the mixers and the VCA amp setting can change the overtones of the output.

// OUT
/*
args for setParams:
\amp - Amplitude, 0 - 1.0
\pan - Pan, -1.0 - 1.0
\panmod - a convenience param to make moduluating via ring1 easy. Direct multiplication with pan value, 0 - 2, default 1
*/
~dfam.out.setParams(\amp, 0.5, \pan, 1.0);

