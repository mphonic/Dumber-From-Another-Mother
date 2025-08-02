( // ONLY RUN THIS IF DFAM ISN'T ALREADY RUNNING
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
)
// Wait til you see "Ready to go."
~dfam.loadSettings(Document.current.dir ++ "/presets/dumbmachine");
~dfam.makeGui();

(
var patt = Pseq([
	0,
	nil,
	4,
	5,
	{ [2, 3, nil].choose },
	{ [4, 4, 4, 5, 5].choose },
	nil,
	5,
	0,
	2,
	3,
	4,
	{ [5, 5, 5, 2].choose },
	{ [nil, 6, 7].choose },
	{ [1, 3, 5, nil].choose },
	{ [nil, 4].choose }
], inf).asStream,
hipan = -1;
~tempo = 140;
~dfam.seq.stopSeq();
t.stop;
t = Task({
	inf.do({|c|
		var ind = patt.next.value,
		wait = 60/~tempo/4;
		(ind.notNil).if({
			~dfam.seq.currentStep = ind;
			s.bind({
				(ind > 3).if({
					~dfam.out.setParams(\pan, hipan);
					hipan = hipan.neg;
				}, {
					~dfam.out.setParams(\pan, 0);
				});
				~dfam.seq.trigger();
			});
		});
		wait.wait;
	});
});
t.play
)
t.stop

// play it with midi

MIDIIn.connectAll;

( // controller knobs
// mess with these while the sequence above plays
MIDIdef.cc(\dfamcc, {|val, num, chan, src|
	var i = ~dfam;
	switch(num)
	{ 74 } { i.filt.setParams(\ffreq, val.linexp(0, 127, 20, 20000.0)) }
	{ 75 } { i.filtEnv.setParams(\dec, val.linlin(0, 127, 0, 3.0)) }
	{ 76 } {i.vcaEnv.setParams(\dec, val.linlin(0, 127, 0, 3.0)); }
});
)

( // Keyboard / drum pads
var noteOn;

noteOn = {|num, val, doTrig = false|
	var i = ~dfam,
	m = num % 12;

	(m < 8).if({
		i.seq.currentStep = m;
		i.seq.trigger();
	});
};

MIDIdef.noteOn(\dfamkeyson, {|val, num, chan, src|
	noteOn.value(num, val);
});
)

MIDIdef.freeAll