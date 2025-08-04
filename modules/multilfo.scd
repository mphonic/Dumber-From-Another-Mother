(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~multilfo = (
	parent: ~module,
	synthDef: [
		SynthDef(\lftri, {|freq = 4, out = 0|
			Out.kr(out, LFTri.kr(freq));
		}),
		SynthDef(\lfpulse, {|freq = 4, out = 0|
			Out.kr(out, LFPulse.kr(freq, mul: 2, add: -1));
		}),
		SynthDef(\lfsaw, {|freq = 4, out = 0|
			Out.kr(out, LFSaw.kr(freq));
		}),
		SynthDef(\lfsh, {|freq = 4, out = 0|
			Out.kr(out, LFDNoise0.kr(freq).lag(0.02));
		}),
		SynthDef(\lfnoise, {|freq = 4, out = 0|
			Out.kr(out, LFDNoise3.kr(freq));
		}),
		SynthDef(\lfdust, {|freq = 4, out = 0|
			var trig = Dust.kr(freq);
			Out.kr(out, Latch.kr(trig, trig).lag(0.02) * 2 - 1);
		}),
		SynthDef(\trigff, {|t_gate, out = 0|
			Out.kr(out, ToggleFF.kr(t_gate) * 2 - 1);
		}),
		SynthDef(\trigrand, {|t_gate, out = 0|
			Out.kr(out, TRand.kr(-1.0, 1.0, t_gate));
		})
	],
	outputConfig: Dictionary[\out -> \k],
	tri: {|self|
		self.updateSynth(0);
	},
	pulse: {|self|
		self.updateSynth(1);
	},
	saw: {|self|
		self.updateSynth(2);
	},
	sh: {|self|
		self.updateSynth(3);
	},
	noise: {|self|
		self.updateSynth(4);
	},
	dust: {|self|
		self.updateSynth(5);
	},
	trigFF: {|self|
		self.updateSynth(6);
	},
	trigRand: {|self|
		self.updateSynth(7);
	},
	updateSynth: {|self, index|
		var gui = self.views;
		self.switchSynthDef(index);
		(gui.notNil.and(self.keepGuiUpdated)).if({
			{
				gui[\synth].value_(index);
				gui[\freq][0].enabled_(index < 6);
			}.defer;
		});
	},
	makeGui: {|self, parent, styles|
		var style = styles ? Event.new,
		ks = style.knobSize ? 50,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		ne = 1,
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		view = View(parent, width@parent.bounds.height),
		f = view.addFlowLayout(pl@pt, gl@gt),
		spec = \lofreq.asSpec,
		k = Knob()
		.action_({|v|
			self.setParams(\freq, spec.map(v.value));
		}).enabled_([6, 7].includes(self.selectedSynthDef).not),
		m;

		self.views = Dictionary.new;
		self.views[\freq] = [k, spec];

		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		m = PopUpMenu(view, ks@20)
		.items_([
			"Tri",
			"Pul",
			"Saw",
			"SH",
			"LF Noise",
			"Dust",
			"Trig FF",
			"Trig Rand"
		])
		.action_({|v|
			self.switchSynthDef(v.value);
			[6, 7].includes(v.value).if({
				k.enabled_(false);
			}, {
				k.enabled_(true);
			});
		})
		.value_(self.selectedSynthDef ? 0);
		self.views[\synth] = m;

		style.viewWithTopLabel(view, ks@ks, "Freq", k);
		self[\controls][\freq].get({|v| { k.value_(spec.unmap(v)) }.defer });
		self.views[\view] = view;
		view;
	}
);