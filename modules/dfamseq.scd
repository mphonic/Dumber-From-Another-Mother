(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});

~dfamSeq = (
	parent: ~module,
	synthDef: SynthDef(\dfamSeq, {|p = #[0, 0, 0, 0, 0, 0, 0, 0],
		v = #[0, 0, 0, 0, 0, 0, 0, 0],
		tempo = 2,
		play = 0,
		t_advance = 0,
		t_repeat = 0,
		t_reset = 0,
		pOut = 12,
		vOut = 13,
		pkOut = 32,
		vkOut = 33|
		var pseq, vseq, trig, count;
		trig = Impulse.kr(tempo) * play + t_advance;
		count = Stepper.kr(trig, t_reset, 1, 8, resetval: 0);
		pseq = Select.kr(count - 1, p);
		vseq = Select.kr(count - 1, v);
		SendReply.kr(trig + t_repeat, '/dfamseq', [count - 1, pseq, vseq, t_advance]);
		Out.ar(pOut, K2A.ar(pseq));
		Out.ar(vOut, K2A.ar(vseq));
		Out.kr(pkOut, pseq);
		Out.kr(vkOut, vseq);
	}),
	outputConfig: Dictionary[
		\pOut -> \a,
		\vOut -> \a,
		\pkOut -> \k,
		\vkOut -> \k],
	controlConfig: Dictionary[\p -> [\k, 8], \v -> [\k, 8]],
	setTrigFunc: {|self, trigFunc|
		self.trigFunc = trigFunc;
		self.responder = OSCFunc({|msg|
			var v = msg[msg.size - 2],
			a = msg[msg.size - 1],
			n = msg[1];
			((n == self.node.nodeID).and(v > -0.7)).if({
				(a.notNil).if({
					(a < 1).if({ self.trigFunc(msg) });
				}, {
					self.trigFunc(msg);
				});
			});
		}, '/dfamseq');
	},
	stopOnSettingsChange: false,
	resetOnSettingsChange: false,
	stopAndResetOnSettingsChange: {|self, b|
		self.stopOnSettingsChange = b;
		self.resetOnSettingsChange = b;
	},
	customSetFromSettings: {|self, dict, cb|
		(self.stopOnSettingsChange).if({ self.stopSeq(); });
		(self.resetOnSettingsChange).if({ self.resetSeq(); });
		cb.value(dict);
	},
	startSeq: {|self, andReset = false|
		self.setParams(\play, 1, \t_reset, (andReset).if({ 1 }, { 0 }));
	},
	stopSeq: {|self|
		self.setParams(\play, 0);
	},
	resetSeq: {|self|
		var gui = self.views,
		prev = self.previousInd ? 0;
		self.setParams(\t_reset, 1);
		(gui.notNil
			.and(self.keepGuiUpdated
				.and(prev > 0))).if({
			{
				gui[\v][prev][0].background_(self.offColor);
				gui[\p][prev][0].background_(self.offColor);
				gui[\v][7][0].background_(self.onColor);
				gui[\p][7][0].background_(self.onColor);
			}.defer;
		});
		self.previousInd = 7;
	},
	advanceSeq: {|self|
		self.setParams(\t_advance, 1);
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
			{
				self.setParams(\tempo, tSpec.map(v.value));
			}.defer;
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
			self.node.set(\t_repeat, 1);
			self.trigFunc();
		});
		p = Button(tview, bw@bh)
		.states_([["Play"], ["Stop"]])
		.action_({|v|
			self.setParams(\play, v.value);
		});
		self[\controls][\play].get({|v|
			{ p.value_(v) }.defer;
		});
		td.nextLine;
		r = Button(tview, bw@bh)
		.states_([["Reset"]])
		.action_({|v|
			self.views[\ind].do({|e| e.background_(Color.clear) });
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
			var params = [\p, \v],
			labels = ["Pitch", "Vel"];
			StaticText(kview, 40@(lh + 4)).string_(labels[i]);
			kd.nextLine;
			8.do({|c|
				a[c] = [
					Knob(kview)
					.action_({|v|
						{
							self[\controls][params[i]].getn(8, {|val|
								{
									val[c] = spec.map(v.value);
									// self.node.setn(params[i], val);
									self[\controls][params[i]].setn(val);
								}.defer
							});
						}.defer;
					})
					.value_(0.5)
					.fixedSize_(sks@sks),
					spec];
				(c == 0).if({ a[c][0].background_(onColor) });
			});
			kd.nextLine;
		});
		self[\controls][\p].getn(8, {|v|
			{
				v.do({|e, c|
					self.views[\p][c][0].value_(spec.unmap(e));
				});
			}.defer;
		});
		self[\controls][\v].getn(8, {|v|
			{
				v.do({|e, c|
					self.views[\v][c][0].value_(spec.unmap(e));
				});
			}.defer;
		});
		self.guiOsc = OSCFunc({|msg|
			(self.views.isNil).if({
				self.guiOsc.free;
			}, {
				(msg[1] == self.node.nodeID).if({
					var step = (msg[3] ? 0).max(0);
					{
						var v = self.views[\v][step][0],
						p = self.views[\p][step][0],
						prev = self.previousInd ? 0;
						self.views[\v][prev][0].background_(offColor);
						self.views[\p][prev][0].background_(offColor);
						v.background_(onColor);
						p.background_(onColor);
						self.previousInd = step;
					}.defer;
				});
			});
		}, '/dfamseq');

		/*hl.add(tview);
		hl.add(kview);
		view.layout_(hl);*/
		self.views[\view] = view;
		view;
	},
	updateView: {|self, key, value|
		var views = self.views ? Dictionary.new,
		gui = views[key];
		(gui.notNil).if({
			([\p, \v].includes(key.asSymbol).not).if({
				var view = (gui.isArray).if({ gui[0] }, { gui }),
				spec = (gui.isArray).if({ gui[1] }, { nil });
				(spec.notNil).if({
					view.value_(spec.unmap(value));
				}, {
					view.value_(value);
				});
			}, {
				var spec = \pan.asSpec;
				value.do({|e, c|
					gui[c][0].value_(spec.unmap(e));
				});
			});
		});
	},
	syncGui: {|self|
		(self.guiTask.notNil).if({
			(self.guiTask.isPlaying.not).if({ self.guiTask.play });
		}, {
			(self.views.notNil).if({
				var keys = self[\controls].keys
				.select({|key|
					self.views[key].notNil
					.and([\v, \p].includes(key.asSymbol).not)
				});

				self.guiTask = Task({
					loop {
						keys.do({|key|
							var gui = self.views[key],
							view = (gui.isArray).if({ gui[0] }, { gui }),
							spec = (gui.isArray).if({ gui[1] }, { nil });
							self[\controls][key].get({|v|
								{
									(spec.notNil).if({
										view.value_(spec.unmap(v));
									}, {
										view.value_(v);
									});
								}.defer;
							});
						});
						[\v, \p].do({|key|
							var spec = \pan.asSpec,
							gui = self.views[key];
							self[\controls][key].getn(8, {|v|
								v.do({|e, c|
									{ gui[c][0].value_(spec.unmap(e)); }.defer
								});
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
