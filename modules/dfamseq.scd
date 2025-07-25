(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});

~dfamSeq = (
	parent: ~module,
	synthDef: SynthDef(\dfamSeq, {|p = #[0, 0, 0, 0, 0, 0, 0, 0],
		v = #[0, 0, 0, 0, 0, 0, 0, 0],
		trigRate = 2,
		play = 0,
		t_advance = 0,
		t_repeat = 0,
		t_reset = 0,
		pOut = 12,
		vOut = 13,
		pkOut = 32,
		vkOut = 33|
		var pseq, vseq, trig, count;
		trig = Impulse.kr(trigRate) * play + t_advance;
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
			a = msg[msg.size - 1];
			(v > -0.7).if({
				(a.notNil).if({
					(a < 1).if({ self.trigFunc(msg) });
				}, {
					self.trigFunc(msg);
				});
			});
		}, '/dfamseq');
	},
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
		width = 746,
		height = 175,
		t = Knob()
		.action_({|v|
			{
				self.setParams(\trigRate, ControlSpec(1.0, 20, \exp).map(v.value));
			}.defer;
		})
		.fixedSize_(ks@ks),
		r,
		tb,
		p,
		view = View(parent, (parent.bounds.width - 80)@parent.bounds.height),
		tview = View(bounds: (view.bounds.width * 0.5)@view.bounds.height),
		td = FlowLayout(tview.bounds, 0@0, 4@4),
		kview = View(bounds: (view.bounds.width * 0.5)@view.bounds.height),
		kd = FlowLayout(kview.bounds, 0@0, 0@0),
		hl = HLayout().margins_(0).spacing_(0),
		spec = \pan.asSpec;

		tview.decorator_(td);
		kview.decorator_(kd);

		self.views = Dictionary.new;
		/*StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;*/
		style.viewWithTopLabel(tview, ks@(ks + lh), "Tempo", t);
		self[\controls][\trigRate].get({|v|
			{ t.value_(ControlSpec(1, 20.0, \exp).unmap(v)) }.defer
		});
		self.views[\trigRate] = t;
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
			self.node.setn(\t_reset, 1);
		});
		Button(tview, bw@bh)
		.states_([["Adv"]])
		.action_({|v|
			self.node.set(\t_advance, 1);
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
				a[c] = Knob(kview)
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
				.fixedSize_(sks@sks);
				(c == 0).if({ a[c].background_(Color.green) });
			});
			kd.nextLine;
		});
		self[\controls][\p].getn(8, {|v|
			{
				v.do({|e, c|
					self.views[\p][c].value_(spec.unmap(e));
				});
			}.defer;
		});
		self[\controls][\v].getn(8, {|v|
			{
				v.do({|e, c|
					self.views[\v][c].value_(spec.unmap(e));
				});
			}.defer;
		});
		self.guiOsc = OSCFunc({|msg|
			var step = (msg[3] ? 0).max(0);
			{
				var v = self.views[\v][step],
				p = self.views[\p][step],
				prev = self.previousInd ? 0;
				self.views[\v][prev].background_(Color.white);
				self.views[\p][prev].background_(Color.white);
				v.background_(Color.green);
				p.background_(Color.green);
				self.previousInd = step;
			}.defer;
		}, '/dfamseq');

		hl.add(tview);
		hl.add(kview);
		view.layout_(hl);
		self.views[\view] = view;
		view;
	}
);
