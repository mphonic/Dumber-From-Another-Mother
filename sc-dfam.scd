(
~makeADfam = {|cb, outputBus = 0|
	var dfam;
	s.waitForBoot({
		dfam = Environment.make({
			var docDir = Document.current.dir,
			base = [
				"modules/base/module",
				"modules/base/controlExtension",
				"patching/base/patchbay",
				"styles/defaults",
				"styles/helperExtension"
			],
			modules = [
				"modules/dfamosc",
				"modules/dfamfilt",
				"modules/whitenoise",
				"modules/volume",
				"modules/softclipVca",
				"modules/envperc",
				"modules/mono2stereo",
				"modules/dfamseq"
			],
			patching = [
				"patching/synthdefs",
				"patching/audiopatchbay",
				"patching/audiopatchpinmatrixgui",
				"patching/controlpatchbay"],
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
				~dfamSeq
			].do({|e, c|
				(e.isNil).if({ c.postln; }); // debug
				e.sendSynthDefs();
			});

			~out = ~mono2Stereo.create('S');
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

			s.sync;
			"Modules created".postln;

			~groups = (
				main: Group.new
			);

			groups.do({|e|
				~groups[e] = Group.new(~groups.main);
			});

			groups = ~groups; // we do this for trigFunc closure

			s.sync;

			outputs = (
				modules: [~out, ~v],
				defaults: [[\out, outputBus]],
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
				g: ~groups.oscs
			);
			envs = (
				modules: [~vcaEnv, ~filtEnv, ~osc2Env, ~osc1Env, ~seq],
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
			~sortedModules.add(~seq);

			s.sync;
			"Synths started".postln;

			~patcher = ~audioPatchbay.create(~sortedModules);
			~modPod = ~controlPatchbay.create(~sortedModules, envs.modules);
			s.sync;
			// Osc1 has secret FM input with no scaling
			~osc1.setParams(\fmLevel, 1.0);
			// Scale down the volume for three signals
			~out.setParams(\amp, 0.25);
			// Patch the sequencer amp
			~modPod.patch("SE vk", "A amp", 1.0);

			~makeGui = {|self, bounds|
				var w = Window("dfam", bounds ? Rect(80, 250, 1090, 448)),
				pl = self.style.paddingLeft ? 20,
				pt = self.style.paddingTop ? 20,
				gl = self.style.gapLeft ? 4,
				gt = self.style.gapTop ? 4,
				mc, mf, dv, df, cv, cf, xv, xf, pv, pf, ov, of, fv, ff, sv, sf,
				cvh = 220,
				gui;

				w.addFlowLayout(pl@pt, gl@gt);
				mc = View(w, w.bounds); // main container
				mf = FlowLayout(mc.bounds, 0@0, 0@0);
				mc.decorator_(mf);
				dv = View(mc, mc.bounds.width@28); // l / s buttons
				df = FlowLayout(dv.bounds, 0@0, gl@gt);
				dv.decorator_(df);
				cv = View(mc, 746@(w.bounds.height - 28)); // controls container
				cf = FlowLayout(cv.bounds, 0@0, gl@gt);
				cv.decorator_(cf);
				pv = View(mc, 340@(w.bounds.height - 28)); // patch container
				pf = FlowLayout(pv.bounds, 0@0, 0@0);
				pv.decorator_(pf);
				ov = View(cv, 358@cvh); // osc container
				of = FlowLayout(ov.bounds, 0@0, 0@0);
				ov.decorator_(of);
				xv = View(cv, 50@cvh); // mixer container
				xf = FlowLayout(xv.bounds, 0@0, 0@0);
				xv.decorator_(xf);
				fv = View(cv, 330@cvh); // filt container
				ff = FlowLayout(fv.bounds, 0@0, 0@0);
				fv.decorator_(ff);
				sv = View(cv, cv.bounds.width@cvh); // sequence container
				sf = FlowLayout(sv.bounds, 0@0, 0@0);
				sv.decorator_(sf);

				gui = (
					matrix: { self.patcher.makeGui(pv) },
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
					seq: { self.seq.makeGui(sv, self.style) }
				);

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

				View(sv, 80@60).layout_(VLayout(
					StaticText()
					.string_("Map Pitch"),
					Button()
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
					{ 0 }))
					.fixedSize_(60@20),
					Button()
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
					.value_((self.modPod.getPatchById("SE pk", "SE pk2O2 pitchmod").notNil).if({ 1 }, { 0 }))
					.fixedSize_(60@20)
				).margins_(0).spacing_(0)
				);
				gui.seq();

				gui.matrix();

				self.guiWindow = w;

				w.onClose_({ self.seq.guiOsc.free });

				CmdPeriod.doOnce { w.close };
				w.view.palette_(QPalette.dark);
				w.front;
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
					var module = self.sortedModules.select({|m| m.name == key });
					(module.size > 0).if({
						// [key, settings[key]].postln;
						module[0].setFromSettings(settings[key]);
					});
				});
				{
					// syncable oscs
					s.sync;
					self.osc1.setSyncFromSettings(settings[self.osc1.name], self.osc2);
					self.osc2.setSyncFromSettings(settings[self.osc2.name], self.osc1);
				}.fork;
				self.patcher.setFromSettings(settings[\patcher]);
				self.modPod.setFromSettings(settings[\modPod]);
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
			/*{ Window.closeAll }.defer;
			{ ~makeGui.value }.defer;*/
		});
		cb.value(dfam);
	});
}
)