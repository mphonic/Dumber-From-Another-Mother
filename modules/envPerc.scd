(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~envPerc = (
	parent: ~module,
	synthDef: SynthDef(\envPerc, {|
		att = 0.0,
		dec = 1.0,
		curve = -4.0,
		t_gate = 0,
		kOut = 30,
		out = 30|
		var env = EnvGen.ar(Env.perc(att, dec, curve: curve), t_gate);
		Out.kr(kOut, A2K.kr(env));
		Out.ar(
			out,
			env
		);
	}),
	outputConfig: Dictionary[\out -> \a, \kOut -> \k],
	trigger: {|self|
		self.setParams(\t_gate, 1);
	},
	longAtt: {|self|
		var gui = self.views;
		self.setParams(\att, 0.1);
		(gui.notNil
			.and(self.keepGuiUpdated
				.and(gui[\att].class == Button))).if({
			{ gui[\att].value_(1); }.defer;
		});
	},
	shortAtt: {|self|
		var gui = self.views;
		self.setParams(\att, 0.01);
		(gui.notNil
			.and(self.keepGuiUpdated
				.and(gui[\att].class == Button))).if({
			{ gui[\att].value_(0); }.defer;
		});
	},
	makeGui: {|self, parent, styles, hideAtt = false, showAttSwitch = false|
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
			["Att", \att, ControlSpec(0.0, 10.0, 4)],
			["Dec", \dec, ControlSpec(0.0, 10.0, 4)]
		],
		ne = (hideAtt).if({
			1 + (showAttSwitch).if({ 1 }, { 0 })
		}, {
			2
		}),
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt);

		self.views = Dictionary.new;

		(hideAtt).if({ knobConf.removeAt(0) });

		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		(showAttSwitch && hideAtt).if({
			var a = Button(bounds: bw@bh)
			.states_([["S"], ["L"]])
			.action_({|v|
				self.setParams(\att, (v.value == 0).if({ 0.01 }, { 0.1 }));
			});
			style.viewWithTopLabel(view, ks@ks, "Att", a);
			self[\controls][\att].get({|v| {
				(v < 0.1).if({ a.value_(0) }, { a.value_(1) });
			}.defer;
			});
			self.views[\att] = [a, ControlSpec(0.0, 10.0, 4)];
		});

		style.knobRow(view, knobConf, self);
		self.views[\view] = view;
		view;
	},
	updateView: {|self, key, value|
		var views = self.views ? Dictionary.new,
		gui = views[key];
		(gui.notNil).if({
			var view = (gui.isArray).if({ gui[0] }, { gui }),
			spec = (gui.isArray).if({ gui[1] }, { nil });
			((view.class != Button).and(key != 'att')).if({
				(spec.notNil).if({
					view.value_(spec.unmap(value));
				}, {
					view.value_(value);
				});
			}, {
				view.value_((value < 0.1).if({ 0 }, { 1 }));
			});
		});
	},
	syncGui: {|self|
		(self.guiTask.notNil).if({
			(self.guiTask.isPlaying.not).if({ self.guiTask.play });
		}, {
			(self.views.notNil).if({
				var keys = self[\controls].keys
				.select({|key| self.views[key].notNil });

				self.guiTask = Task({
					loop {
						keys.do({|key|
							var gui = self.views[key],
							view = (gui.isArray).if({ gui[0] }, { gui }),
							spec = (gui.isArray).if({ gui[1] }, { nil });
							self[\controls][key].get({|v|
								var val = v;
								(key == 'att' && view.class == Button).if({
									val = (v < 0.1).if({ 0 }, { 1 });
									spec = nil;
								});
								{
									(spec.notNil).if({
										view.value_(spec.unmap(val));
									}, {
										view.value_(val);
									});
								}.defer;
							});
						});
						0.09.wait;
					}
				});
				self.guiTask.play;
			});
		});
	}
);