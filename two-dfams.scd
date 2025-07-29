(
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam1 = d });
~makeADfam.value({|d| ~dfam2 = d });
)
// Wait til you see "Ready to go."
(
~dfam1.loadSettings(Document.current.dir ++ "/presets/shoike");
~dfam2.loadSettings(Document.current.dir ++ "/presets/hormp");
)

(
~dfam1.makeGui();
~dfam2.makeGui();
)

( // First DFAM plays and causes second to advance
o = OSCFunc({|msg|
	var v = msg[msg.size - 2],
	a = msg[msg.size - 1];
	(msg[1] == ~dfam1.seq.node.nodeID).if({
		(v > -0.7).if({
			(a.notNil).if({
				(a < 1).if({
					~dfam2.trigger();
					~dfam2.seq.setParams(\t_advance, 1);
				});
			}, {
				~dfam2.trigger();
				~dfam2.seq.setParams(\t_advance, 1);
			});
		});
	});
}, '/dfamseq');
~dfam2.seq.setParams(\t_reset, 1);
~dfam1.seq.setParams(\t_reset, 1, \play, 1);
)
o.free

( // First DFAM plays and causes second to advance at half time
var count = 0;
o = OSCFunc({|msg|
	var v = msg[msg.size - 2],
	a = msg[msg.size - 1];
	(msg[1] == ~dfam1.seq.node.nodeID).if({
		(count.even).if({
			(v > -0.7).if({
				(a.notNil).if({
					(a < 1).if({
						~dfam2.trigger();
						~dfam2.seq.setParams(\t_advance, 1);
					});
				}, {
					~dfam2.trigger();
					~dfam2.seq.setParams(\t_advance, 1);
				});
			});
		});
		count = count + 1;
	});
}, '/dfamseq');
~dfam2.seq.setParams(\t_reset, 1);
~dfam1.seq.setParams(\t_reset, 1, \play, 1);
)
o.free

( // First DFAM plays and causes second to advance every three trigs
var count = 0,
beats = 0;
o = OSCFunc({|msg|
	var v = msg[msg.size - 2],
	a = msg[msg.size - 1];
	(msg[1] == ~dfam1.seq.node.nodeID).if({
		(count % 3 == 0).if({
			(v > -0.7).if({
				(a.notNil).if({
					(a < 1).if({
						~dfam2.trigger();
						~dfam2.seq.setParams(\t_advance, 1);
					});
				}, {
					~dfam2.trigger();
					~dfam2.seq.setParams(\t_advance, 1);
				});
			});
			beats = beats + 1;
			// uncomment to reset 2 after 7 steps
			// (beats % 7 == 0).if({ ~dfam2.setParams(\t_reset, 1); });
		});
		count = count + 1;
	});
}, '/dfamseq');
~dfam2.seq.setParams(\t_reset, 1);
~dfam1.seq.setParams(\t_reset, 1, \play, 1);
)
o.free