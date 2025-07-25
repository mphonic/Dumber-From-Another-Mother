(
var defs = List.new;
(1..4).do({|n|
	var c = n.asString;
	defs.add(
		SynthDef(\kmodsum ++ c, {|param, in, out|
			Out.kr(out, param.ring1(In.kr(in, n)));
		})
	);

	defs.add(
		SynthDef(\kpatch ++ c, {|in, out, mul = 1.0, add = 0.0|
			Out.kr(out, In.kr(in, n) * mul + add);
		});
	);
	defs.add(
		SynthDef(\patch ++ c, {|in, out, mul = 1.0, add = 0.0|
			Out.ar(out, In.ar(in, n) * mul + add);
		});
	);

	defs.add(
		SynthDef(\patchFb ++ c, {|in, out, mul = 1.0, add = 0.0|
		Out.ar(out, InFeedback.ar(in, n) * mul + add);
	});
	);
});

~sendPatchDefs = {
	defs.do({|e| e.send(s); });
};
~patchDefs = defs;
)