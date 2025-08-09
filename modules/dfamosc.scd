(~module.isNil).if({
	(Document.current.dir ++ "/base/module.scd").loadPaths;
});
~dfamOsc = (
	parent: ~module,
	synthDef: [
		SynthDef(\tri, {|freq = 100,
			fmIn = 30
			fmLevel = 0.0,
			envIn = 32,
			envLevel = 0.0,
			pitchmod = 1,
			pw = 0.5,
			amp = 1.0,
			out = 0|
			var sig,
			fm = Mix([
				In.ar(fmIn, 1) * fmLevel,
				In.ar(envIn, 1) * envLevel
			]);
			freq = Select.ar(fm < 0, [
				fm.linexp(0.0, 1.0, freq, 20000.0),
				fm.linexp(-1.0, 0.0, 20.0.min(freq), freq)
			]).lag(0.01);
			freq = freq * (pitchmod - 1 * 72).midiratio;
			sig = VarSaw.ar(
				freq.max(0.01).min(20000),
				width: pw,
				mul: amp
			);
			Out.ar(out, sig);
		}),
		SynthDef(\pulse, {|freq = 100,
			fmIn = 30
			fmLevel = 0.0,
			envIn = 32,
			envLevel = 0.0,
			pitchmod = 1,
			pw = 0.5,
			amp = 1.0,
			out = 0|
			var sig,
			fm = Mix([
				In.ar(fmIn, 1) * fmLevel,
				In.ar(envIn, 1) * envLevel
			]);
			freq = Select.ar(fm < 0, [
				fm.linexp(0.0, 1.0, freq, 20000.0),
				fm.linexp(-1.0, 0.0, 20.0.min(freq), freq)
			]).lag(0.01);
			freq = freq * (pitchmod - 1 * 72).midiratio;
			sig = Pulse.ar(
				freq.max(0.01).min(20000),
				pw,
				amp
			);
			Out.ar(out, sig);
		}),
		SynthDef(\sync, {|freq = 100,
			basefreq = 100,
			fmIn = 30
			fmLevel = 0.0,
			envIn = 32,
			envLevel = 0.0,
			pitchmod = 1,
			amp = 1.0,
			out = 0|
			var sig,
			fm = Mix([
				In.ar(fmIn, 1) * fmLevel,
				In.ar(envIn, 1) * envLevel
			]);
			freq = Select.ar(fm < 0, [
				fm.linexp(0.0, 1.0, freq, 20000.0),
				fm.linexp(-1.0, 0.0, basefreq, freq)
			]).lag(0.01);
			freq = freq * (pitchmod - 1 * 72).midiratio;
			sig = SyncSaw.ar(
				basefreq,
				freq.max(basefreq).min(20000),
				mul: amp
			);
			Out.ar(out, sig);
		}),
	],
	inputConfig: Dictionary[\fmIn -> \a, \envIn -> \a],
	sync: {|self, source|
		var sourceBus,
		summers = source.modsummers ? Dictionary.new,
		gui = self.views;
		(summers[\freq].notNil).if({
			sourceBus = source.modbusses[\freq][\out];
		}, {
			sourceBus = source.controls[\freq];
		});
		source.syncedWith = self;
		self.syncedFrom = source;
		{
			(self.selectedSynthDef != 2).if({
				self.lastSelectedSynthDef = self.selectedSynthDef.copy;
				self.switchSynthDef(2);
			});
			s.sync;
			self.node.map(\basefreq, sourceBus);
		}.fork;
		(gui.notNil.and(self.keepGuiUpdated)).if({
			(gui[\sync].notNil).if({
				{ gui[\sync].value_(1); }.defer;
			});
		});
	},
	unsync: {|self, defIndex|
		(self.syncedFrom.notNil).if({
			var i = defIndex ? self.lastSelectedSynthDef,
			gui = self.views;
			self.switchSynthDef(i ? 0);
			self.syncedFrom.syncedWith = nil;
			self.syncedFrom = nil;
			(gui.notNil.and(self.keepGuiUpdated)).if({
				(gui[\sync].notNil).if({
					{ gui[\sync].value_(0); }.defer;
				});
			});
		});
	},
	handleSync: {|self, param|
		(self.syncedWith.notNil && (param == \freq)).if({
			self.syncedWith.sync(self);
		});
	},
	tri: {|self|
		self.updateSynth(0);
	},
	pulse: {|self|
		self.updateSynth(1);
	},
	updateSynth: {|self, index|
		var gui = self.views;
		self.switchSynthDef(index);
		self.unsync();
		(gui.notNil.and(self.keepGuiUpdated)).if({
			{
				gui[\type].value_(index);
				(gui[\sync].notNil).if({
					gui[\sync].value_(0);
				});
			}.defer;
		});
	},
	customDumpSettings: {|self, o, cb|
		o[\lastSelectedSynthDef] = self.lastSelectedSynthDef ? self.selectedSynthDef;
		o[\syncedWith] = (self.syncedWith ? Event.new).name;
		o[\syncedFrom] = (self.syncedFrom ? Event.new).name;
		cb.value(o);
	},
	customSetFromSettings: {|self, dict, cb|
		self.lastSelectedSynthDef = dict[\lastSelectedSynthDef];
		cb.value(dict, (dict[\syncedWith].notNil || dict[\syncedFrom].notNil));
	},
	setSyncFromSettings: {|self, settings, modules|
		var sf = settings[\syncedFrom],
		sw = settings[\syncedWith];
		modules = (modules.isArray).if({ modules }, { [modules] });
		(sf.notNil).if({
			var m = modules.select({|e| e.name == sf }).pop();
			(m.notNil).if({ self.sync(m) }, { self.unsync() });
		}, {
			self.unsync();
			(sw.notNil).if({
				var m = modules.select({|e| e.name == sf }).pop();
				(m.notNil).if({ self.syncedWith = m }, { self.syncedWith = nil });
			}, {
				self.syncedWith = nil;
			});
		});
	},
	makeGui: {|self, parent, styles, canSync = false, syncSource|
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
			["Freq", \freq, \freq],
			["Env", \envLevel, \pan]
		],
		ne = (canSync).if({ 5 }, { 3 }),
		width = style.calculateViewWidth(pl, gl, ne, ks * ne),
		height = style.calculateViewHeight(pt, lh, ks),
		o = Button(bounds: bw@bh)
		.states_([["/\\"], ["_|"]])
		.action_({|v|
			(v.value == 0).if({
				self.tri();
			}, {
				self.pulse();
			});
		})
		.value_((self.syncedFrom.isNil).if(
			{ self.selectedSynthDef ? 0 },
			{ self.lastSelectedSynthDef ? 0 }
		)),
		view = View(parent, width@height),
		f = view.addFlowLayout(pl@pt, gl@gt);

		self.views = Dictionary.new;

		view.decorator_(f);
		(canSync).if({
			knobConf.add(["Fm", \fmLevel, \amp]);
		});

		StaticText(view).string_(self.name).fixedWidth_(ks);
		f.nextLine;
		style.knobRow(view, knobConf, self);
		style.viewWithTopLabel(view, ks@ks, "Type", o);
		self.views[\type] = o;
		(canSync).if({
			var x = Button(bounds: bw@bh)
			.states_([["Off"], ["On"]])
			.action_({|v|
				(v.value == 0).if({
					self.unsync();
				}, {
					self.sync(syncSource);
				});
			})
			.value_((self.syncedFrom.notNil).if({ 1 }, { 0 }));
			style.viewWithTopLabel(view, ks@ks, "Sync", x);
			self.views[\sync] = x;
		});
		self.views[\view] = view;
		view;
	}
);