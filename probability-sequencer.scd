(
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
)
// Wait til you see "Ready to go."
~dfam.loadSettings(Document.current.dir ++ "/presets/chiit");
~dfam.makeGui();

( // One measure of probabilistic "drums", looped
t = 140;
k = Dictionary[
	\k -> [45, 90, { rrand(0.8, 1.0) }, { 60/t }],
	\s -> [20000, 7000, { rrand(0.67, 1.0) }, { 60/3/t }],
	\b -> [{ rrand(38, 64).midicps }, { rrand(38, 64).midicps }, { rrand(0.4, 0.8).squared }, { 60/t } ],
	\g -> [45, 45, { rrand(0.35, 0.5) }, 0.4, { 60/2/t }],
	\p -> [20000, 4000, { rrand(0.45, 0.55) }, { 60/4/t }]
];
p = [
	\k, \b, { [\p, \b, \g].choose }, { [\b, \g].choose },
	{ [\k, \s].choose }, \b, { [\p, \b].choose }, { [\g, \b].choose },
	\k, \b, { [\k, \b].wchoose([0.3, 0.7]) }, { [\b, \p].choose },
	{ [\k, \s].wchoose([0.3, 0.7]) }, \b, { [\b, \p].choose }, { [\b, \g].choose }
];
r = Routine({
	loop {
		p.do({|e|
			var params = k[e.value.asSymbol];
			(params.notNil).if({
				var f = params[0].value,
				ff = params[1].value,
				a = params[2].value,
				d = params[3].value,
				i = ~dfam;
				i.osc1.setParams(\freq, f);
				i.osc2.setParams(\freq, f);
				i.filt.setParams(\ffreq, ff);
				i.v.setParams(\amp, a);
				i.vcaEnv.setParams(\dec, d);
				(a > 0.5).if({ i.trigger(); });
			});
			(60/4/t).wait;
		});
	}
});
r.play;
)
// stop playing while dfam keeps running
r.stop;

// slow it down
t = 120
// speed it up
t = 160
// back to orig
t = 140

( // add some delay
{
	SynthDef(\delay, {|in = 0, out = 0, dt = 1, fb = 0.8, lp = 3000, hp = 200, mix = 0.2|
		var dry, wet, fbIn;
		dry = In.ar(in, 2);
		fbIn = LocalIn.ar(2);
		wet = LPF.ar(HPF.ar(dry, hp), lp);
		wet = DelayC.ar(fbIn * fb + wet, 4, dt).softclip;
		LocalOut.ar(Rotate2.ar(wet[0], wet[1], LFNoise2.kr(0.1)));
		ReplaceOut.ar(out, mix * wet + (1 - mix * dry));
	}).send(s);
	s.sync;
	d = Synth(\delay, [\dt, 60/4/t, \hp, 2000], ~dfam.groups.outputs, 'addToTail');
}.fork
)
d.free

~dfam.syncGui();
~dfam.stopSyncGui();