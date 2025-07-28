~module = (
	name: 'module',
	synthDef: {},
	outputConfig: Dictionary[\out -> \a],
	defaults: Dictionary.new,
	gui: {|self, view| view.postln; },
	hasInit: false,
	releaseable: false,
	rateMap: Dictionary[\a -> 'audio', \k -> 'control'],
	create: {|self, name, skipDef = true|
		(self.hasInit).if({
			self;
		}, {
			var o = self.deepCopy;
			o.name = name;
			o.outputConfig = o.outputConfig ? Dictionary[\out -> \a];
			// set up io busses
			o.createIoBusses();
			// set up control and mod busses
			o.createControlBusses();
			// generate defaults from SynthDef
			o.generateDefaults();
			(skipDef.not).if({
				{
					self.sendSynthDefs();
					s.sync;
					o.hasInit = true;
				}.fork;
			}, {
				o.hasInit = true;
			});
			o
		});
	},
	sendSynthDefs: {|self|
		var defs = self.synthDef;
		(defs.isArray.not).if({ defs = [defs] });
		defs.do({|e|
			e.send(s);
		});
	},
	getSynthDef: {|self|
		(self.synthDef.isArray).if({
			self.synthDef[self.selectedSynthDef ? 0]
		}, {
			self.synthDef
		});
	},
	createIoBusses: {|self|
		var rates = self.rateMap,
		i = self.inputConfig ? Dictionary.new,
		o = self.outputConfig ? Dictionary.new,
		io = [Dictionary.new, Dictionary.new];
		[i, o].do({|dict, c|
			dict.keys.do({|key|
				var conf = dict[key];
				io[c][key] = self.getBusFromConfig(conf, 'audio');
			});
		});
		self.inputs = io[0];
		self.outputs = io[1];
	},
	createControlBusses: {|self|
		var c = self.controlConfig ? Dictionary.new,
		m = Dictionary.new, // modbusses
		a = self.getSynthDef().func.argNames,
		o = self.outputs.keys,
		i = self.inputs.keys,
		io = o ++ i,
		rates = self.rateMap;
		a.do({|key|
			(io.includes(key).not).if({
				var conf = c[key] ? \k;
				c[key] = self.getBusFromConfig(conf);
				m[key] = Dictionary[
					\in -> self.getBusFromConfig(conf),
					\out -> self.getBusFromConfig(conf)
				];
			});
		});
		self.controls = c;
		self.modbusses = m;
	},
	getBusFromConfig: {|self, conf, defaultRate = 'control'|
		var rate, channels, rates = self.rateMap;
		(conf.isArray.not).if({
			channels = 1;
			rate = rates[conf] ? defaultRate;
		}, {
			rate = rates[conf[0]] ? defaultRate;
			channels = conf[1] ? 1;
		});
		(rate == 'audio').if({
			Bus.audio(numChannels: channels);
		}, {
			Bus.control(numChannels: channels);
		});
	},
	generateDefaults: {|self|
		var f = self.getSynthDef().func,
		a = f.argNames,
		d = f.defaultArgs,
		defaults = Dictionary.new;
		a.do({|e, c|
			defaults[e] = d[c];
		});
		self.defaults = defaults;
	},
	generateSynthArgs: {|self, args|
		var a = Dictionary.newFrom(args),
		i = self.inputs,
		o = self.outputs,
		d = self.defaults;
		// set i/o bus args
		[i, o].do({|dict|
			dict.keys.do({|key|
				a[key] = a[key] ? dict[key];
			});
		});
		// set defaults if not present
		d.keys.do({|key|
			a[key] = a[key] ? d[key];
		});
		a;
	},
	go: {|self, args, target, action = 'addToHead'|
		(self.hasInit).if({
			var c = self.controls,
			a = self.generateSynthArgs(args ? []),
			n = Synth(self.getSynthDef().name, a.asPairs, target ? s, action).register;
			// set control busses and map to node
			c.keys.do({|key|
				(a[key].notNil).if({
					c[key].set(a[key]);
				});
				n.map(key, c[key]);
			});
			self.node = n;
			n;
		}, {
			"Error: Module has not been initialized. Run [module].create".postln;
			nil;
		});
	},
	switchSynthDef: {|self, defIndex, cb|
		self.selectedSynthDef = defIndex;
		self.replace(cb);
	},
	replace: {|self, cb|
		(self.hasInit).if({
			var c = self.controls,
			args = Dictionary.new,
			cond = Condition.new(false),
			count = 0;
			c.keys.do({|key|
				c[key].get({|v|
					args[key] = v;
					count = count + 1;
					(count >= c.size).if({
						cond.test = true;
						cond.signal;
					});
				});
			});
			{
				var a, n,
				m = self.modsummers ? Dictionary.new,
				b = self.modbusses,
				modded = List.new;
				cond.wait;
				a = self.generateSynthArgs(args);
				n = Synth.replace(self.node, self.getSynthDef().name, a.asPairs, true);
				s.sync;
				m.keys.do({|key|
					modded.add(key);
					n.map(key, b[key][\out]);
				});
				c.keys
				.select({|key| modded.includes(key).not })
				.do({|key|
					n.map(key, c[key]);
				});
				self.node = n;
				cb.value(self.node);
			}.fork;
		}, {
			"Error: Module has not been initialized. Run [module].create".postln;
		});
	},
	setParams: {|...args|
		var self = args.removeAt(0),
		a = Dictionary.newFrom(args);
		a.keys.do({|key|
			var c = self.controls[key];
			(c.notNil).if({
				var chan = c.numChannels;
				(chan < 2).if({ c.set(a[key]); }, { c.setn(a[key]) });
			}, {
				self.node.set(key, a[key]);
			});
		});
	},
	end: {|self, kill = false|
		(self.releaseable.asBoolean && kill.not).if(
			{ self.node.release; },
			{ self.node.free }
		);
		// TO-DO: What if we want to wait for the release to end?
		self.unpatchAll();
		[self.inputs, self.outputs, self.controls].do({|dict|
			dict.values.do({|bus| bus.free; });
		});
		self.modbusses.values.do({|dict|
			dict.values.do({|d| d.free });
		});
		self.hasInit = false;
	},
	updateGui: {|self|
		var keys = self[\controls].keys
		.select({|key| self.views[key].notNil });

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
								{
									(spec.notNil).if({
										view.value_(spec.unmap(v));
									}, {
										view.value_(v);
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
	},
	stopSyncGui: {|self|
		self.guiTask !? {|v| v.stop };
	},
	dumpControls: {|self|
		self.controls.keys.asArray;
	},
	dumpSettings: {|self, cb|
		var count = 0,
		c = self.controls,
		o = Dictionary.new,
		cond = Condition.new(false);
		o[\selectedSynthDef] = self.selectedSynthDef;
		c.keys.do({|key|
			var chan = c[key].numChannels;
			(chan < 2).if({
				c[key].get({|v|
					o[key] = v;
					count = count + 1;
					(count >= c.size).if({
						cond.test = true;
						cond.signal;
					});
				});
			}, {
				c[key].getn(chan, {|v|
					o[key] = v;
					count = count + 1;
					(count >= c.size).if({
						cond.test = true;
						cond.signal;
					});
				});
			});
		});
		{
			cond.wait;
			(self.customDumpSettings(o, cb).isNil).if({
				cb.value(o);
			});
		}.fork;
	},
	saveSettings: {|self, path, cb|
		self.dumpSettings({|v|
			v.writeTextArchive(path);
			cb.value(v);
		});
	},
	setFromSettings: {|self, dict, cb|
		var c = self.controls;
		(dict[\selectedSynthDef] != self.selectedSynthDef).if({
			self.switchSynthDef(dict[\selectedSynthDef]);
		});

		dict.keys.do({|key|
			var b = c[key];
			(b.notNil).if({
				(b.numChannels < 2).if({
					b.set(dict[key]);
				}, {
					b.setn(dict[key]);
				});
			});
		});
		(self.customSetFromSettings(dict, cb).isNil).if({
			cb.value(dict);
		});
	},
	loadSettings: {|self, path, cb|
		var settings = Object.readTextArchive(path);
		self.setFromSettings(settings, cb);
	}
);