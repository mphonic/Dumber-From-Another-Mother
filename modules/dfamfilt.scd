(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~dfamFilt = (
	parent: ~module,
	synthDef: [
		SynthDef(\moogVcf, {|in = 30,
			ffreq = 440,
			ffreqmul = 1,
			res = 0.0,
			fmIn = 30
			fmLevel = 0.0,
			envIn = 32,
			envLevel = 0.0,
			amp = 1,
			out = 0|
			var signalInput, fm, filt;
			signalInput = In.ar(in, 1);
			fm = Mix([
				In.ar(fmIn, 1) * fmLevel,
				In.ar(envIn, 1) * envLevel
			]);
			ffreq = Select.ar(fm < 0, [
				fm.linexp(0.0, 1.0, ffreq, 20000.0),
				fm.linexp(-1.0, 0.0, 20.0, ffreq)
			]).lag(0.01) * ffreqmul;
			filt = MoogVCF.ar(
				signalInput,
				ffreq.max(20).min(20000),
				res,
				mul: amp
			);
			Out.ar(out, filt);
		}),
		SynthDef(\bhipass4, {|in = 30,
			ffreq = 440,
			ffreqmul = 1,
			res = 0.0,
			fmIn = 30
			fmLevel = 0.0,
			envIn = 32,
			envLevel = 0.0,
			amp = 1,
			out = 0|
			var signalInput, fm, filt;
			signalInput = In.ar(in, 1);
			fm = Mix([
				In.ar(fmIn, 1) * fmLevel,
				In.ar(envIn, 1) * envLevel
			]);
			ffreq = Select.ar(fm < 0, [
				fm.linexp(0.0, 1.0, ffreq, 20000.0),
				fm.linexp(-1.0, 0.0, 20.0, ffreq)
			]).lag(0.01) * ffreqmul;
			filt = BHiPass4.ar(
				signalInput,
				ffreq.ring1(fm).max(20).min(20000),
				res.linlin(0.0, 1.0, 1.0, 0.01),
				mul: amp
			);
			Out.ar(out, filt);
		})
	],
	inputConfig: Dictionary[\in -> \a, \fmIn -> \a, \envIn -> \a],
	lo: {|self|
		self.updateSynth(0);
	},
	hi: {|self|
		self.updateSynth(1);
	},
	updateSynth: {|self, index|
		var gui = self.views;
		self.switchSynthDef(index);
		(gui.notNil.and(self.keepGuiUpdated)).if({
			{ gui[\mode].value_(index); }.defer;
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
		bw = style.toggleButtonWidth ? 50,
		bh = style.toggleButtonHeight ? 25,
		knobConf = [
			["Cutoff", \ffreq, \freq],
			["Res", \res],
			["Env", \envLevel, \pan],
			["Fm", \fmLevel, \amp]
		],
		width = style.calculateViewWidth(pl, gl, 5, ks * 5),
		height = style.calculateViewHeight(pt, lh, ks),
		l = Button(bounds: bw@bh)
		.states_([["Lo"], ["Hi"]])
		.action_({|v|
			self.switchSynthDef(v.value);
		})
		.value_(self.selectedSynthDef ? 0),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt);

		self.views = Dictionary.new;
		self.views[\mode] = l;
		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		style.viewWithTopLabel(view, ks@ks, "Type", l);
		style.knobRow(view, knobConf, self);
		self[\controls][\mode].get({|v| { l.value_(v.round) }.defer });
		self.views[\view] = view;
		view;
	}
);