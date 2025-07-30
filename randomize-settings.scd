(
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
)
// Wait til you see "Ready to go."
~dfam.makeGui();

( // set this as a reference
~allModules = [
	\osc1Env,
	\osc2Env,
	\filtEnv,
	\vcaEnv,
	\osc1,
	\osc2,
	\osc1Mix,
	\osc2Mix,
	\noiseMix,
	\filt,
	\v,
	\out,
	\seq,
	\lfo,
	\modPod
];
)

// We can totally randomize, or just nudge

// 1. Randomize
( // randomize everything but audio patches, play, and tempo
var changeSelectView = {|view|
	var size = (view.class == Button).if({ view.states.size }, { view.items.size }),
	new = rrand(0, size - 1);
	(new != view.value).if({
		view.valueAction_(new);
	});
};
~randomize = {|exclude|
	var m = ~allModules,
	c,
	e = exclude ? Array.new;
	m = m.select({|v| e.includes(v).not });
	m.do({|e|
		var views = ~dfam[e].views;
		(e == \modPod).if({
			var mods = views[\modulations],
			v = mods.collect({|e| e.children }).flat();
			{
				v.do({|e, c|
					(e.class == Knob).if({
						{ e.valueAction_(rrand(0.0, 1.0)); }.defer;
					}, {
						{ changeSelectView.value(e); }.defer;
					});
					s.sync;
				});
			}.fork;
		}, {
			(views.notNil).if({
				views.keys.do({|k|
					v = views[k];
					(v.isArray && (v.size > 2)).if({ // sequencer or modpod
						v.do({|e|
							var view = e[0];
							view.valueAction_(rrand(0.0, 1.0));
						});
					}, {
						var view = (v.isArray).if({ v[0] }, { v });
						switch(view.class)
						{ Button } {
							(k != \play).if({ // leave play alone
								changeSelectView.value(view);
							});
						}
						{ PopUpMenu } {
							changeSelectView.value(view);
						}
						{ Knob } {
							(k != \tempo).if({ // leave tempo
								view.valueAction_(rrand(0.0, 1.0));
							});
						}
					});
				});
			});
		});
	});
};
)

// randomize all the modules
~randomize.value([\modPod]);
// everything but the sequencer and output
// try loading a preset with a sequence you like
~randomize.value([\seq, \out]);
// only the sequencer
~randomize.value(~allModules.select({|v| v != \seq }))


// 2. Nudge
( // same, but just nudge the existing values
var changeSelectView = {|view, dev = 0|
	var size = (view.class == Button).if({ view.states.size }, { view.items.size }),
	val = view.value,
	step = (dev.coin).if({ [-1, 1].choose }, { 0 }),
	new = (val + step).fold(0, size - 1);
	(new != val).if({
		view.valueAction_(new);
	});
},
nudgeView = {|view, dev = 0|
	var val = view.value,
	new = (val + rrand(dev.neg, dev)).fold(0.0, 1.0);
	view.valueAction_(new);
};
~nudge = {|dev = 0.1, exclude, excludeButtons = false|
	var m = ~allModules,
	c,
	e = exclude ? Array.new;
	m = m.select({|v| e.includes(v).not });
	m.do({|e|
		var views = ~dfam[e].views;
		(e == \modPod).if({
			var mods = views[\modulations],
			v = mods.collect({|e| e.children }).flat();
			{
				v.do({|e, c|
					(e.class == Knob).if({
						{ nudgeView.value(e, dev) }.defer;
					}, {
						{ changeSelectView.value(e, dev); }.defer;
					});
					s.sync;
				});
			}.fork;
		}, {
			(views.notNil).if({
				views.keys.do({|k|
					v = views[k];
					(v.isArray && (v.size > 2)).if({ // sequencer or modpod
						v.do({|e|
							var view = e[0];
							nudgeView.value(view, dev);
						});
					}, {
						var view = (v.isArray).if({ v[0] }, { v });
						switch(view.class)
						{ Button } {
							((k != \play).and(excludeButtons.not)).if({ // leave play alone
								changeSelectView.value(view, dev);
							});
						}
						{ PopUpMenu } {
							changeSelectView.value(view, dev);
						}
						{ Knob } {
							(k != \tempo).if({ // leave tempo
								nudgeView.value(view, dev);
							});
						}
					});
				});
			});
		});
	});
};
)

// Try different presets with these
// nudge everything a little bit
~nudge.value(0.05);

( // nudge seq every 8 steps
var count = 0;
o.free;
~dfam.seq.setParams(\t_reset, 1, \play, 1);
o = OSCFunc({|msg|
	(count % 8 == 0).if({
		{ ~nudge.value(0.1, ~allModules.select({|v| v != \seq })); }.defer;
	});
	count = count + 1;
}, '/dfamseq');
)
o.free

( // nudge everything but seq and oscs every 8 steps, exclude buttons
var count = 0;
o.free;
~dfam.seq.setParams(\t_reset, 1, \play, 1);
o = OSCFunc({|msg|
	(count % 8 == 0).if({
		{ ~nudge.value(0.05, [\seq, \modPod, \osc1, \osc2, \out], true); }.defer;
	});
	count = count + 1;
}, '/dfamseq');
)
o.free

( // *maybe* nudge everything but output on a step, exlude buttons
o.free;
~dfam.seq.setParams(\t_reset, 1, \play, 1);
o = OSCFunc({|msg|
	(0.1.coin).if({
		{ ~nudge.value(0.05, [\out], true); }.defer;
	});
}, '/dfamseq');
)
o.free
