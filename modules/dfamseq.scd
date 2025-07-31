(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});

~dfamSeq = (
	parent: ~module,
	synthDef: SynthDef(\dfamSeq, {|
		pitch = 0,
		velocity = 0,
		tempo = 4,
		step = 0,
		t_trig = 0,
		pOut = 12,
		vOut = 13,
		pkOut = 32,
		vkOut = 33,
		tkOut = 34|
		var p = pitch,
		v = velocity;
		SendReply.ar(K2A.ar(t_trig), '/dfamseq', [step, pitch, velocity]);
		Out.ar(pOut, K2A.ar(p));
		Out.ar(vOut, K2A.ar(v));
		Out.kr(pkOut, p);
		Out.kr(vkOut, v);
		Out.kr(tkOut, tempo);
	}),
	outputConfig: Dictionary[
		\pOut -> \a,
		\vOut -> \a,
		\pkOut -> \k,
		\vkOut -> \k,
		\tkOut -> \k
	],
	pitches: Array.fill(8, 0),
	velocities: Array.fill(8, 0),
	currentStep: 0,
	previousStep: 0,
	isSeqPlaying: 0,
	tempo: 0.25,
	runningTempo: 0.25,
	startTasks: {|self|
		(self.seqTask.isNil).if({ self.createSeqTask() });
		(self.tempoTask.isNil).if({ self.createTempoTask() });
		self.seqTask.start;
		self.tempoTask.start;
	},
	pauseTasks: {|self|
		(self.seqTask.isNil).if({ self.createSeqTask() });
		(self.tempoTask.isNil).if({ self.createTempoTask() });
		self.seqTask.pause;
		self.tempoTask.pause;
	},
	createSeqTask: {|self|
		self.seqTask = Task({
			var checkInterval = 0.0025;
			loop {
				var count = 0,
				cur = self.currentStep,
				prev = self.previousStep;
				self.trigger();
				(self.views.notNil).if({
					self.updateActiveStepView(prev, cur);
				});
				// Try to catch tempo modulations
				while({ count < self.runningTempo }, {
					count = count + checkInterval;
					checkInterval.wait;
				});
				self.previousStep = self.currentStep;
				self.currentStep = self.currentStep + 1 % 8;
			}
		}, SystemClock)
	},
	createTempoTask: {|self|
		var cond = Condition.new(false);
		self.tempoTask = Task({
			loop {
				var b = self[\outputs][\tkOut];
				b.get({|v|
					self.runningTempo = (v.notNil.and(v > 0)).if({
						v.reciprocal;
					}, {
						0.25;
					});
					cond.test = true;
					cond.signal;
				});
				cond.wait;
				0.04.wait;
				cond.test = false;
				cond.signal;
			}
		}, SystemClock);
	},
	trigger: {|self|
		var step = self.currentStep;
		s.bind({
			self.setParams(
				\pitch, self.pitches[step],
				\velocity, self.velocities[step],
				\t_trig, 1
			);
			self.trigFunc();
		});
	},
	setTrigFunc: {|self, trigFunc|
		self.trigFunc = trigFunc;
	},
	stopOnSettingsChange: false,
	resetOnSettingsChange: false,
	stopAndResetOnSettingsChange: {|self, b|
		self.stopOnSettingsChange = b;
		self.resetOnSettingsChange = b;
	},
	customDumpSettings: {|self, dict, cb|
		dict[\play] = self.isSeqPlaying;
		dict[\p] = self.pitches;
		dict[\v] = self.velocities;
		cb.value(dict);
	},
	customSetFromSettings: {|self, dict, cb|
		self.isSeqPlaying = dict[\play];
		self.tempo = dict[\tempo].reciprocal;
		self.pitches = dict[\p];
		self.velocities = dict[\v];
		(self.stopOnSettingsChange).if(
			{ self.stopSeq(); },
			(self.isSeqPlaying > 0).if({
				self.startSeq(self.resetOnSettingsChange ? false);
			}, {
				self.stopSeq();
			});
		);
		(self.resetOnSettingsChange).if({ self.resetSeq(); });
		self.setParams(
			\pitch, self.pitches[self.currentStep ? 0],
			\velocity, self.velocities[self.currentStep ? 0]
		);
		cb.value(dict);
	},
	startSeq: {|self, andReset = false|
		self.currentStep = (andReset).if({
			self.resetSeq();
			0
		}, { self.currentStep });
		(self.seqTask.isPlaying.not).if({ self.startTasks(); });
		self.setParams(\play, 1);
	},
	stopSeq: {|self|
		self.pauseTasks();
		self.setParams(\play, 0);
	},
	resetSeq: {|self|
		var gui = self.views,
		prev = self.currentStep ? 0;
		self.currentStep = 0;
		self.previousStep = 0;
		(gui.notNil
			.and(self.keepGuiUpdated
				.and(prev > 0))).if({
			self.updateActiveStepView(prev, 0);
		});
		self.seqTask.reset;
	},
	advanceSeq: {|self|
		var gui = self.views;
		self.previousStep = self.currentStep;
		self.currentStep = self.currentStep + 1 % 8;
		(gui.notNil
			.and(self.keepGuiUpdated)).if({
			var prev = self.previousStep,
			cur = self.currentStep;
			self.updateActiveStepView(prev, cur);
		});
	},
	updateActiveStepView: {|self, prev, cur|
		var gui = self.views;
		{
			gui[\v][prev][0].background_(self.offColor);
			gui[\p][prev][0].background_(self.offColor);
			gui[\v][cur][0].background_(self.onColor);
			gui[\p][cur][0].background_(self.onColor);
		}.defer;
	},
	onColor: Color(0.75,0.7,0.7),
	offColor: Color(0.42745098039216, 0.42745098039216, 0.42745098039216),
	makeGui: {|self, parent, styles|
		var style = styles ? Event.new,
		ks = style.knobSize ? 50,
		sks = style.smallKnobSize ? 25,
		pl = style.paddingLeft ? 20,
		pt = style.paddingTop ? 20,
		gl = style.gapLeft ? 4,
		gt = style.gapRight ? 4,
		lh = style.lineHeight ? 11,
		bw = style.toggleButtonWidth ? 50,
		bh = style.toggleButtonHeight ? 25,
		tSpec = ControlSpec(1.0, 20, \exp),
		t = Knob(bounds: ks@ks)
		.action_({|v|
			var val = tSpec.map(v.value);
			self.setParams(\tempo, val);
			self.tempo = val.reciprocal;
		}),
		r,
		tb,
		p,
		view = View(parent, (parent.bounds.width)@parent.bounds.height),
		f = view.addFlowLayout(0@0, 0@0),
		tview = View(view, (view.bounds.width * 0.25)@view.bounds.height),
		td = tview.addFlowLayout(0@0, 4@4),
		kview = View(view, (view.bounds.width * 0.75)@view.bounds.height),
		kd = kview.addFlowLayout(0@0, 0@0),
		spec = \pan.asSpec,
		offColor = self.offColor,
		onColor = self.onColor;

		self.views = Dictionary.new;
		/*StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;*/
		style.viewWithTopLabel(tview, ks@(ks + lh), "Tempo", t);
		self[\controls][\tempo].get({|v|
			{ t.value_(tSpec.unmap(v)) }.defer
		});
		self.views[\tempo] = [t, tSpec];
		td.nextLine;
		tb = Button(tview, bw@bh)
		.states_([["Trigger"]])
		.action_({
			self.trigger();
		});
		p = Button(tview, bw@bh)
		.states_([["Play"], ["Stop"]])
		.action_({|v|
			(v.value == 0).if({ self.stopSeq() }, { self.startSeq() });
		})
		.value_(self.isSeqPlaying);
		td.nextLine;
		r = Button(tview, bw@bh)
		.states_([["Reset"]])
		.action_({|v|
			self.views[\ind].do({|e| e.background_(offColor) });
			self.resetSeq();
		});
		Button(tview, bw@bh)
		.states_([["Adv"]])
		.action_({|v|
			self.advanceSeq();
		});

		self.views[\reset] = r;
		self.views[\play] = p;

		self.views[\p] = Array.newClear(8);
		self.views[\v] = Array.newClear(8);

		[self.views[\p], self.views[\v]].do({|a, i|
			var params = [\pitch, \velocity],
			properties = Dictionary[\pitch -> \pitches, \velocity -> \velocities],
			param = params[i],
			prop = properties[param],
			labels = ["Pitch", "Vel"];
			StaticText(kview, 40@(lh + 4)).string_(labels[i]);
			kd.nextLine;
			8.do({|c|
				a[c] = [
					Knob(kview)
					.action_({|v|
						var val = spec.map(v.value);
						(c == self.currentStep).if({
							self.setParams(param, val);
						});
						self[prop][c] = val;
					})
					.value_(spec.unmap(self[prop][c]))
					.fixedSize_(sks@sks)
					.background_((c == self.currentStep).if(
						{ onColor },
						{ offColor }
					)),
					spec];
			});
			kd.nextLine;
		});

		self.views[\view] = view;
		view;
	},
	updateView: {|self, key, value|
		var views = self.views ? Dictionary.new,
		gui = views[key];
		(gui.notNil).if({
			([\pitch, \velocity].includes(key.asSymbol).not).if({
				var view = (gui.isArray).if({ gui[0] }, { gui }),
				spec = (gui.isArray).if({ gui[1] }, { nil });
				(spec.notNil).if({
					view.value_(spec.unmap(value));
				}, {
					view.value_(value);
				});
			}, {
				var spec = \pan.asSpec;
				gui[self.currentStep][0].value_(spec.unmap(e));
			});
		});
	}
);
