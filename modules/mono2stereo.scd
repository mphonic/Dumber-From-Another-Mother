(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~mono2Stereo = (
	parent: ~module,
	synthDef: SynthDef(\output12, {|in = 32, out = 0, amp = 1.0, pan = 0.0, panmod = 1|
		Out.ar(
			out,
			Pan2.ar(
				LeakDC.ar(In.ar(in, 1)),
				pan + (panmod - 1),
				amp
			)
		);
	}),
	defaults: Dictionary[\out -> 0],
	inputConfig: Dictionary[\in -> \a],
	makeGui: {|self, parent, styles|
		var style = styles ? Event.new,
		ks = style.knobSize ? 50,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		knobConf = [
			["Amp", \amp, \amp],
			["Pan", \pan, \pan]
		],
		ne = 2,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks),
		view = View(parent, width@height),
		f = FlowLayout(view.bounds, pl@pt, gl@gt);

		self.views = Dictionary.new;

		view.decorator_(f);
		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		style.knobRow(view, knobConf, self);
		self.views[\view] = view;
		view;
	}
);