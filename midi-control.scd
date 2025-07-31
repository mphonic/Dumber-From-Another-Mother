( // ONLY RUN THIS IF DFAM ISN'T ALREADY RUNNING
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
)
// Wait til you see "Ready to go."
~dfam.loadSettings(Document.current.dir ++ "/presets/twoiyiiink");
// or
// ~dfam.loadSettings(Document.current.dir ++ "/presets/dyowng");
~dfam.makeGui();

MIDIIn.connectAll;

( // Keyboard
var notes = List.new, noteOn;
~keytrack = 1; // keytrack for filt -- 0 = none, 1 = full
~velocitySensitivity = 0; // 0 = none, 1 = full
~bendRange = 2.0; // semitones
~legato = true;

noteOn = {|num, val, doTrig = false|
	var i = ~dfam,
	m = num.midicps,
	d = num - 60 * ~keytrack;

	s.bind({
		i.osc1.setParams(\freq, m);
		i.osc2.setParams(\freq, m);
		val !? { i.v.setParams(\amp, val.linlin(0, 127, -96 * ~velocitySensitivity, 0).dbamp); };
		i.filt.setParams(\ffreqmul, d.midiratio);
		(doTrig).if({ i.trigger() });
	});
};

MIDIdef.noteOn(\dfamkeyson, {|val, num, chan, src|
	var doTrig = (~legato.not.or(notes.size == 0));

	notes.add(num);
	noteOn.value(num, val, doTrig);
});
MIDIdef.noteOff(\dfamkeysoff, {|val, num, chan, src|
	notes.removeAt(notes.indexOf(num));
	(notes.size > 0).if({ noteOn.value(notes[notes.size - 1]) });
});
MIDIdef.bend(\dfambend, {|val, chan, src|
	var bend = val.linlin(0, 16256, ~bendRange.neg, ~bendRange),
	n = notes[notes.size - 1],
	d = n !? {|v| v + bend };

	(d.notNil).if({
		noteOn.value(d)
	});
});
)

~velocitySensitivity = 1 // full velocity sensitivity
~keytrack = 0 // keytrack off
~keytrack = 0.5
~keytrack = 1.0
~legato = false
~legato = true

( // controller knobs
MIDIdef.cc(\dfamcc, {|val, num, chan, src|
	var i = ~dfam;
	switch(num)
	{ 1 } {
		var v = val / 127;
		s.bind({
			i.osc1.setParams(\fmLevel, v);
			i.osc2.setParams(\fmLevel, v);
		});
	}
	{ 74 } { i.filt.setParams(\ffreq, val.linexp(0, 127, 20, 20000.0)) }
	{ 75 } { i.filtEnv.setParams(\dec, val.linlin(0, 127, 0, 3.0)) }
	{ 76 } {
		s.bind({
			var v = val.linlin(0, 127, 0, 3.0);
			i.osc1Env.setParams(\dec, v);
			i.osc2Env.setParams(\dec, v);
		});
	}
});
)

MIDIdef.freeAll