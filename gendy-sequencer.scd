(
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
)
// Wait til you see "Ready to go."
~dfam.loadSettings(Document.current.dir ++ "/presets/dyowng");
~dfam.makeGui();

// You'll need SCPlugins installed for this example https://github.com/supercollider/sc3-plugins/releases
( // Use a Gendy to generate freq patterns that evolve
g = {|minfreq = 6, maxfreq = 12, drift = 0.2, steps = 16|
	var p, v, t;
	p = Gendy5.kr(minfreq: minfreq / steps, maxfreq: maxfreq / steps, ampscale: drift, durscale: drift, initCPs: 16, knum: steps);
	t = HPZ2.kr(p);
	v = Select.kr(
		PulseCount.kr(t) - 1 % steps,
		TBrownRand.kr(0.0, 1.0 ! 16, drift, 1, trig: t)
	).squared;
	SendReply.kr(t, '/xseq', [p, v]);
}.play;

o = OSCFunc({|msg|
	var p = msg[3],
	v = msg[4],
	f = (p
		.linlin(-1.0, 1, 0, 24)
		.round
		.degreeToKey([0, 1, 4, 5, 7, 11])
	+ 42).midicps,
	a = v.squared,
	g = (a > 0.1).if({ 1 }, { 0 });
	s.bind({
		~dfam.osc1.setParams(\freq, f);
		~dfam.osc2.setParams(\freq, f);
		~dfam.filt.setParams(\ffreq, f * a.linlin(0.0, 1.0, 2, 6.0));
		~dfam.v.setParams(\amp, a);
		~dfam.out.setParams(\pan, rrand(-1.0, 1.0));
		~dfam.groups.envs.set(\t_gate, g);
	});
}, '/xseq');
)
// In the GUI, move the active "p" knob to detune oscs

// speed up the change
g.set(\drift, 1);
// ease up again
g.set(\drift, 0.2);
// double speed
g.set(\minfreq, 12, \maxfreq, 24);
// stretch the rhythm
g.set(\minfreq, 0.1, \maxfreq, 24);
// steady the rhythm
g.set(\minfreq, 8, \maxfreq, 8);
// change number of steps
g.set(\steps, 4);
g.set(\steps, 6);
g.set(\steps, 2);
g.set(\steps, 16);
// see what's happening by syncing the GUI
~dfam.syncGui();
// stop syncing the GUI
~dfam.stopSyncGui();
// stop the silliness, but keep the dfam running
g.free; o.free;
