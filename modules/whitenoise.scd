(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~whiteNoise = (
	parent: ~module,
	synthDef: SynthDef(\whiteNoise1, {|out = 0, amp = 1.0|
		Out.ar(
			out,
			WhiteNoise.ar(amp)
		);
	})
);