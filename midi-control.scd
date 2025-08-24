( // ONLY RUN THIS IF DFAM ISN'T ALREADY RUNNING
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
MIDIIn.connectAll;
)
// Wait til you see "Ready to go."
~dfam.loadSettings(Document.current.dir ++ "/presets/twoiyiiink");
// or
// ~dfam.loadSettings(Document.current.dir ++ "/presets/dyowng");

( // Keyboard control
var notes = List.new,
noteOn,
keytrack = 1, // keytrack for filt -- 0 = none, 1 = full
velocitySensitivity = 0, // 0 = none, 1 = full
bendRange = 2.0, // semitones
bend = 0,
legato = true,
silent = false,
i = ~dfam,
turnKeysOn,
turnKeysOff,
turnRecordOn,
turnRecordOff,
target = \p,
recordVelocity = true,
advanceOnKeyUp = true,
w;

i.makeGui();

noteOn = {|num, val, doTrig = false|
	(silent.not).if({
		var m = (num + bend).midicps,
		d = num - 64 * keytrack;

		i.osc1.setParams(\freq, m);
		i.osc2.setParams(\freq, m);
		val !? { i.v.setParams(\amp, val.linlin(0, 127, -96 * velocitySensitivity, 0).dbamp); };
		i.filt.setParams(\ffreqmul, d.midiratio);
		(doTrig).if({ i.trigger() });
	});
};

turnKeysOn = {
	MIDIdef.noteOn(\dfamkeyson, {|val, num, chan, src|
		(silent.not).if({
			var doTrig = ((legato.not).or(notes.size == 0));

			notes.add(num);
			noteOn.value(num, val, doTrig);
		});
	});
	MIDIdef.noteOff(\dfamkeysoff, {|val, num, chan, src|
		(silent.not).if({
			notes.removeAt(notes.indexOf(num));
			(notes.size > 0).if({
				(legato.not).if({ i.trigger(0) });
				noteOn.value(notes[notes.size - 1])
			});
		});
	});
	MIDIdef.bend(\dfambend, {|val, chan, src|
		var b = val.linlin(0, 16256, bendRange.neg, bendRange),
		n = notes[notes.size - 1],
		d = n !? {|v| v };
		bend = b;

		(d.notNil).if({
			noteOn.value(d)
		});
	});
};

turnKeysOff = {
	MIDIdef(\dfamkeyson).free;
	MIDIdef(\dfamkeysoff).free;
	MIDIdef(\dfambend).free;
};

w = Window("MIDI Control", Rect(100, 500, 400, 100));
w.view.layout_(
	VLayout(
		HLayout(
			VLayout(
				StaticText().string_("Keytrack"),
				Knob().value_(1).action_({|v| keytrack = v.value })
			),
			VLayout(
				StaticText().string_("Vel Sens"),
				Knob().value_(0).action_({|v| velocitySensitivity = v.value })
			),
			Button().states_([["Legato: On"], ["Legato: Off"]])
			.action_({|v| legato = v.value.asBoolean.not }),
			HLayout(
				StaticText().string_("Bend Range"),
				TextField().value_("2")
				.action_({|v| bendRange = v.value.asFloat })
			),
		)
	)
);

turnKeysOn.value();
w.onClose_({
	turnKeysOff.value;
	turnRecordOff.value;
});
w.view.palette_(QPalette.dark);
CmdPeriod.doOnce({
	w.close();
	turnKeysOff.value;
	turnRecordOff.value;
});
w.front;
)

( // controller knobs example
MIDIdef.cc(\dfamcc, {|val, num, chan, src|
	var i = ~dfam;
	switch(num)
	{ 1 } {
		var v = val / 127;
		i.osc1.setParams(\fmLevel, v);
		i.osc2.setParams(\fmLevel, v);
	}
	{ 74 } { i.filt.setParams(\ffreq, val.linexp(0, 127, 20, 20000.0)) }
	{ 75 } { i.filtEnv.setParams(\dec, val.linlin(0, 127, 0, 3.0)) }
	{ 76 } {
		var v = val.linlin(0, 127, 0, 3.0);
		i.osc1Env.setParams(\dec, v);
		i.osc2Env.setParams(\dec, v);
	}
});
)

MIDIdef.freeAll