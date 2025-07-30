(
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
)
// Wait til you see "Ready to go."
~dfam.loadSettings(Document.current.dir ++ "/presets/neoonblo");
~dfam.makeGui();

( // stutter w/probability
var len = 16, // probability increases over this number of steps
probEnv = Env([0.001, 0.9], [len], [\exp]), // to a max of 0.9
subdivs = [2, 3, 4], // possible beat subdivs
subweight = Array.geom(subdivs.size, subdivs.size + 1, 0.5).normalizeSum,
lastTime,
i = ~dfam,
count = 0;
i.seq.setParams(\play, 1, \t_reset, 1);
o.free;
o = OSCFunc({
	var time = SystemClock.seconds;
	(lastTime.notNil).if({
		var diff = time - lastTime,
		prob = probEnv.at(count % len);
		(prob.coin).if({
			var sub = subdivs.wchoose(subweight),
			len = diff / sub;
			"Stutter".postln;
			[sub, len].postln;
			{
				len.wait;
				(sub - 1).do({
					i.trigger();
					len.wait;
				});
			}.fork;
		});
	});
	lastTime = time;
	count = count + 1;
}, '/dfamseq');
)
o.free