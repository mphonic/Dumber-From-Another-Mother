(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~volume = (
	parent: ~module,
	synthDef: SynthDef(\volume1, {|in = 32, out = 0, amp = 1.0|
		Out.ar(
			out,
			In.ar(in, 1) * amp
		);
	}),
	inputConfig: Dictionary[\in -> \a],
	makeGui: {|self, parent, styles|
		var style = styles ? Event.new,
		ks = style.smallKnobSize ? 25,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		ne = 1,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks + lh),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		spec = \amp.asSpec,
		k = Knob()
		.action_({|v|
			self.setParams(\amp, spec.map(v.value));
		})
		.fixedSize_(ks@ks);

		self.views = Dictionary.new;
		self.views[\amp] = [k, spec];

		style.viewWithTopLabel(view, ks@(ks * 2), self.name, k);
		self[\controls][\amp].get({|v| { k.value_(spec.unmap(v)) }.defer });
		self.views[\view] = view;
		view;
	}
);