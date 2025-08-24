(
~makeADfam = {|cb, outputBus = 0|
	var dfam;
	s.waitForBoot({
		dfam = Environment.make({
			var docDir = Document.current.dir,
			base = [
				"modules/base/module",
				"modules/base/controlextension",
				"patching/base/patchbay",
				"styles/defaults",
				"styles/helperExtension"
			],
			modules = [
				"modules/dfamosc",
				"modules/dfamfilt",
				"modules/whitenoise",
				"modules/volume",
				"modules/softclipvca",
				"modules/envperc",
				"modules/mono2stereo",
				"modules/dfamseq",
				"modules/multilfo"
			],
			patching = [
				"patching/synthdefs",
				"patching/audiopatchbay",
				"patching/audiopatchpinmatrixgui",
				"patching/controlpatchbay",
				"patching/controlpatchmenu"
			],
			groups = [
				\outputs,
				\effects,
				\mixers,
				\oscs,
				\envs
			],
			outputs,
			effects,
			mixers,
			oscs,
			envs;

			~sortedModules = List.new;
			// s.freeAll;

			[base, modules, patching].do({|e|
				e.do({|v|
					(docDir ++ "/" ++ v ++ ".scd").loadPaths;
				});
			});
			"Creating modules...".postln;
			~sendPatchDefs.value;
			[
				~dfamOsc,
				~whiteNoise,
				~dfamFilt,
				~volume,
				~envPerc,
				~softclipVca,
				~mono2Stereo,
				~dfamSeq,
				~multilfo
			].do({|e, c|
				(e.isNil).if({ c.postln; }); // debug
				e.sendSynthDefs();
			});

			~out = ~mono2Stereo.create('O');
			~v = ~softclipVca.create('A');
			~filt = ~dfamFilt.create('F');
			~osc1Mix = ~volume.create('M1');
			~osc2Mix = ~volume.create('M2');
			~noiseMix = ~volume.create('MN');
			~osc1 = ~dfamOsc.create('O1');
			~osc2 = ~dfamOsc.create('O2');
			~noise = ~whiteNoise.create('N');
			~osc1Env = ~envPerc.create('E1');
			~osc2Env = ~envPerc.create('E2');
			~filtEnv = ~envPerc.create('EF');
			~vcaEnv = ~envPerc.create('EA');
			~seq = ~dfamSeq.create('SE');
			~lfo = ~multilfo.create('LFO');

			s.sync;
			"Modules created".postln;

			~groups = (
				main: Group.new
			);

			groups.do({|e|
				~groups[e] = Group.new(~groups.main);
			});

			groups = ~groups; // we do this for trigFunc closure
			// trigger func for "outside" use
			~trigger = { groups.envs.set(\t_gate, 1); };

			s.sync;

			outputs = (
				modules: [~out, ~v],
				defaults: [[\out, outputBus, \amp, 0.5]],
				g: ~groups.outputs
			);
			effects = (
				modules: [~filt],
				g: ~groups.effects
			);
			mixers = (
				modules: [~noiseMix, ~osc2Mix, ~osc1Mix],
				g: ~groups.mixers
			);
			oscs = (
				modules: [~noise, ~osc2, ~osc1],
				defaults: [nil, nil, [\fmLevel, 1.0]],
				g: ~groups.oscs
			);
			envs = (
				modules: [~vcaEnv, ~filtEnv, ~osc2Env, ~osc1Env, ~seq, ~lfo],
				defaults: [[\att, 0.01]],
				g: ~groups.envs
			);
			"Starting synths...".postln;
			[outputs, effects, mixers, oscs, envs].do({|e|
				e.modules.do({|m, c|
					var a = e.defaults ? Array.new;
					m.go(a[c], e.g);
				});
				~sortedModules = ~sortedModules ++ e.modules;
			});
			~seq.setTrigFunc({|msg|
				groups.envs.set(\t_gate, 1)
			});

			s.sync;
			"Synths started".postln;

			~patcher = ~audioPatchbay.create(~sortedModules);
			~modPod = ~controlPatchbay.create(~sortedModules, envs.modules);
			s.sync;

			~makeGui = {|self, bounds, keepUpdated, knobMode = \vert|
				var w = Window("dfam", bounds ? Rect(80, 250, 1090, 553)),
				pl = self.style.paddingLeft ? 20,
				pt = self.style.paddingTop ? 20,
				gl = self.style.gapLeft ? 4,
				gt = self.style.gapTop ? 4,
				f = w.addFlowLayout(pl@pt, gl@gt),
				cvh = 220,
				mc = View(w, w.bounds), // main container
				mf = mc.addFlowLayout(0@0, 0@0),

				dv = View(mc, mc.bounds.width@28), // l / s buttons
				df = dv.addFlowLayout(0@0, gl@gt),

				cv = View(mc, 746@(w.bounds.height - 150)), // controls container
				cf = cv.addFlowLayout(0@0, gl@gt),

				pv = View(mc, 340@(cv.bounds.height)), // patch container
				pf = pv.addFlowLayout(0@0, 0@0),

				mpv = View(mc, w.bounds.width@150), // modpod container
				mpf = mpv.addFlowLayout(0@0, 0@0),

				ov = View(cv, 358@cvh), // osc container
				of = ov.addFlowLayout(0@0, 0@0),

				xv = View(cv, 50@cvh), // mixer container
				xf = xv.addFlowLayout(0@0, 0@0),

				fv = View(cv, 330@cvh), // filt container
				ff = fv.addFlowLayout(0@0, 0@0),

				sv = View(cv, cv.bounds.width@cvh), // lower container
				sf = sv.addFlowLayout(0@0, 0@0),

				lv, // lfo container
				lf,

				sc, // sequence container
				o1m, // pitch mappers
				o2m,
				gui;

				knobMode = knobMode ? self.knobMode ? \vert;
				keepUpdated = keepUpdated ? self.keepGuiUpdated ? true;
				Knob.defaultMode_(knobMode);

				gui = (
					matrix: { self.patcher.makeGui(pv, nil, ["O"]) },
					modpod: {
						self.modPod.makeGui(
							mpv,
							8,
							[
								'O1 pitchmod',
								'O2 pitchmod',
								'F ffreqmul',
								'A amp',
								'SE pitch',
								'SE velocity',
								'SE step',
								'SE play',
								'O pan'
							],
							[
								'SE tk'
							]
						)
					},
					filt: { self.filt.makeGui(fv, self.style) },
					osc1: { self.osc1.makeGui(ov, self.style) },
					osc2: { self.osc2.makeGui(ov, self.style, true, self.osc1) },
					osc1Env: { self.osc1Env.makeGui(ov, self.style, true) },
					osc2Env: { self.osc2Env.makeGui(ov, self.style, true) },
					filtEnv: { self.filtEnv.makeGui(fv, self.style, true) },
					vcaEnv: { self.vcaEnv.makeGui(fv, self.style, true, true) },
					mix1: { self.osc1Mix.makeGui(xv, self.style) },
					mix2: { self.osc2Mix.makeGui(xv, self.style) },
					mixN: { self.noiseMix.makeGui(xv, self.style) },
					m2s: { self.out.makeGui(fv, self.style) },
					seq: { self.seq.makeGui(sc, self.style) },
					lfo: { self.lfo.makeGui(sv, self.style) },
				);
				// Donate please
				Button(dv, 75@20)
				.states_([["Donate"]])
				.action_({
					"open https://github.com/mphonic/Dumber-From-Another-Mother/blob/master/README.md#donate".unixCmd();
"explorer https://github.com/mphonic/Dumber-From-Another-Mother/blob/master/README.md#donate".unixCmd();
				});

				// load / save
				Button(dv, 20@20)
				.states_([["L"]])
				.action_({
					FileDialog({|p|
						self.loadSettings(p[0]);
					}, nil, 1, 0, path: "presets");
				});
				Button(dv, 20@20)
				.states_([["S"]])
				.action_({
					FileDialog({|p|
						self.saveSettings(p[0]);
					}, nil, 1, 1, path: "presets");
				});
				Button(dv, 20@20)
				.states_([["R"], ["O", Color.white, Color.red]])
				.action_({|v|
					(v.value == 1).if({
						s.record(
							Document.current.dir ++
							"/recordings/sc-dfam_" ++
							Date.getDate().stamp ++
							".aiff"
						);
					}, {
						s.stopRecording;
					});
				});
				self.presetNameView = StaticText(dv, 100@20)
				.string_("Patch: " ++ (self.presetName ? "default"))
				.align_(\right);
				StaticText(dv, 500@20).string_("  <Dumber From Another Mother>");

				gui.osc1Env();
				gui.osc1();
				of.nextLine;
				gui.osc2Env();
				gui.osc2();

				gui.mix1();
				xf.nextLine;
				gui.mix2();
				xf.nextLine;
				gui.mixN();

				gui.filt();
				ff.nextLine();
				gui.filtEnv();
				gui.vcaEnv();
				gui.m2s();

				gui.lfo();

				lv = View(sv, (self.lfo[\views][\view].bounds.width + 12)@(sv.bounds.height));
				lf = lv.addFlowLayout(pl@pt, gl@gt);

				// seq to oscs
				StaticText(lv).fixedWidth_(50)
				.string_("Map Pitch");
				lf.nextLine;
				o1m = Button(lv, 50@20)
				.states_([["O1 off"], ["O1 on"]])
				.action_({|v|
					{
						(v.value == 1).if({
							self.modPod.patch("SE pk", "O1 pitchmod");
						},  {
							self.modPod.unpatch("SE pk", "SE pk2O1 pitchmod");
						});
					}.defer
				})
				.value_((self.modPod.getPatchById("SE pk", "SE pk2O1 pitchmod").notNil).if({
					1 },
				{ 0 }));
				lf.nextLine;
				o2m = Button(lv, 50@20)
				.states_([["O2 off"], ["O2 on"]])
				.action_({|v|
					{
						(v.value == 1).if({
							self.modPod.patch("SE pk", "O2 pitchmod");
						},  {
							self.modPod.unpatch("SE pk", "SE pk2O2 pitchmod");
						});
					}.defer
				})
				.value_((self.modPod.getPatchById("SE pk", "SE pk2O2 pitchmod").notNil).if({ 1 }, { 0 }));

				sc = View(sv, (sv.bounds.width - (self.lfo[\views][\view].bounds.width + lv.bounds.width))@(sv.bounds.height));
				sc.addFlowLayout(pl@0, 0@0);

				gui.seq();
				self.seq.views[\osc1Map] = o1m;
				self.seq.views[\osc2Map] = o2m;

				gui.matrix();
				gui.modpod();

				self.guiWindow = w;

				CmdPeriod.doOnce { w.close };
				w.view.palette_(QPalette.dark);
				self.sortedModules.do({|e|
					e.keepGuiUpdated = keepUpdated;
				});
				self.keepGuiUpdated = keepUpdated;
				w.front;
			};

			~syncGui = {|self|
				self.sortedModules.do({|e|
					e.syncGui();
				});
			};

			~stopSyncGui = {|self|
				self.sortedModules.do({|e|
					e.stopSyncGui();
				});
			};

			~dumpSettings = {|self, cb|
				var set = Dictionary.new,
				modules = self.sortedModules,
				mc = Condition.new(false),
				pc = Condition.new(false),
				ms = 0,
				ps = 0,
				size = modules.size;
				modules.do({|m, c|
					m.dumpSettings({|v|
						set[m.name] = v;
						ms = ms + 1;
						(ms >= size).if({
							mc.test = true;
							mc.signal;
						});
					});
				});
				self.patcher.dumpSettings({|v|
					set[\patcher] = v;
					ps = ps + 1;
					(ps >= 2).if({
						pc.test = true;
						pc.signal;
					});
				});
				self.modPod.dumpSettings({|v|
					set[\modPod] = v;
					ps = ps + 1;
					(ps >= 2).if({
						pc.test = true;
						pc.signal;
					});
				});
				{
					mc.wait;
					pc.wait;
					cb.value(set);
				}.fork;
			};

			~setFromSettings = {|self, settings, name = "default"|
				settings.keys.do({|key|
					var module = self.sortedModules.select({|m|
						m.name == key
					});
					(module.size > 0).if({
						module[0].setFromSettings(settings[key]);
					});
				});
				{
					// syncable oscs
					s.sync;
					self.osc1.setSyncFromSettings(
						settings[self.osc1.name] ? Dictionary.new,
						self.osc2
					);
					self.osc2.setSyncFromSettings(
						settings[self.osc2.name] ? Dictionary.new,
						self.osc1
					);
				}.fork;
				self.patcher.setFromSettings(
					settings[\patcher] ? Dictionary.new
				);
				self.modPod.setFromSettings(
					settings[\modPod] ? Dictionary.new
				);
				self.presetName = name;
				(self.guiWindow.notNil).if({
					{
						s.sync;
						{
							var b = self.guiWindow.bounds;
							self.guiWindow.close;
							self.makeGui(b);
							self.presetNameView.string_("Patch: " ++ name);
						}.defer;
					}.fork;
				});
			};

			~saveSettings = {|self, path, cb|
				self.dumpSettings({|v|
					v.writeTextArchive(path);
					{
						self.presetNameView.string_("Patch: " ++ path.split($/).pop());
					}.defer;
					("Settings saved to " ++ path).postln;
					cb.value(v);
				});
			};

			~loadSettings = {|self, path, cb|
				var settings = Object.readTextArchive(path);
				(settings.notNil).if({
					self.setFromSettings(settings, path.split($/).pop());
					cb.value(settings);
				}, {
					"Settings not found".postln;
				});
			};

			"Loading settings...".postln;
		});

		dfam.know = true;
		dfam.loadSettings(Document.current.dir ++ "/presets/default", {
			"Settings loaded.".postln;
			"Ready to go.".postln;
		});
		cb.value(dfam);
	});
}
)