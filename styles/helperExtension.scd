var helperExtension;

(~style.isNil).if({
	(Document.current.dir ++ "/styles/module.scd").loadPaths;
});

helperExtension = (
	viewWithTopLabel: {|self, parent, bounds, label, thing|
		var v = View(parent, bounds),
		l = VLayout().margins_(0).spacing_(0),
		t = StaticText()
		.string_(label)
		.align_(\center);

		l.add(t, align: \top);
		l.add(thing, align: \top);
		v.layout_(l);
		v;
	},
	calculateViewWidth: {|self, p, g, ne, ew|
		p * 2 + (g * ne - 1) + ew;
	},
	calculateViewHeight: {|self, p, lh, eh|
		p * 2 + eh + lh
	},
	knobRow: {|self, view, knobConf, module, ks|
		ks = ks ? self.knobSize;
		knobConf.do({|e|
			var spec = (e[2] ? \unipolar).asSpec,
			k = Knob().action_({|v|
				module.setParams(e[1], spec.map(v.value));
			});
			self.viewWithTopLabel(view, ks@ks, e[0], k);
			module.views[e[1]] = [k, spec];
			module[\controls][e[1]].get({|v| { k.value_(spec.unmap(v)) }.defer });
		});
	}
);

~style = ~style ++ helperExtension;