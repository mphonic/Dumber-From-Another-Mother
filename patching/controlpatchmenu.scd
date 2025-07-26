var extension, sortModules;

(~controlPatchbay.isNil).if({
	(Document.current.dir ++ "/base/controlpatchbay.scd").loadPaths;
});

sortModules = {|modules, dict|
	dict.keys.asSortedList({|a, b|
		var nameA = dict[a][\moduleName],
		nameB = dict[b][\moduleName],
		amod = modules.select({|v| v.name == nameA }).pop(),
		bmod = modules.select({|v| v.name == nameB }).pop(),
		ia = modules.indexOf(amod),
		ib = modules.indexOf(bmod);
		(ia == ib).if({
			a < b;
		}, {
			ia < ib;
		});
	});
};

extension = (
	modView: {|self, parent, inputs, outputs, selected, ignoreInputs, ignoreOutputs|
		var mw = 90,
		mh = 25,
		ks = 25,
		g = 4,
		v = View(parent, (mw + ks + g)@(mh * 2)),
		f = FlowLayout(v.bounds, 0@0, g@0),
		iItems = inputs.asArray,
		oItems = outputs.asArray,
		pin,
		pou,
		sl,
		id,
		input,
		output,
		spec = \pan.asSpec;

		v.decorator_(f);

		(ignoreInputs.notNil).if({
			iItems = iItems.select({|v| ignoreInputs.includes(v).not });
		});
		(ignoreOutputs.notNil).if({
			oItems = oItems.select({|v| ignoreOutputs.includes(v).not });
		});

		(selected.notNil).if({
			var in = iItems.indexOf(selected[0].asSymbol),
			out = oItems.indexOf(selected[1].asSymbol);
			id = selected[2];
			(
				in.notNil
				&&
				out.notNil
				&&
				id.notNil
			).if({
				input = selected[0];
				output = selected[1];
				id = selected[2];
			}, {
				selected = nil;
			});
		});

		pin = PopUpMenu(v, mw@mh)
		.items_([" "] ++ iItems)
		.action_({|v|
			var i = v.items[v.value];
			(v.value == 0).if({
				(id.notNil).if({
					self.unpatch(output.asString, id);
					id = nil;
				});
				input = nil;
			}, {
				input = i;
				(output.notNil).if({
					(id.notNil).if({
						self.unpatch(output.asString, id);
					});
					id = self.patch(output.asString, input.asString, spec.map(sl.value));
				});
			});
		})
		.value_((input.isNil).if({ 0 }, { iItems.indexOf(input) + 1 }));
		sl = Knob(v, ks@ks)
		.action_({|v|
			(id.notNil).if({
				self.setPatch(output.asString, id, spec.map(v.value));
			});
		})
		.value_((selected.isNil).if({ 0.5 }, { spec.unmap(selected[3]) ? 0.5 }));
		f.nextLine;
		pou = PopUpMenu(v, mw@mh)
		.items_([" "] ++ oItems)
		.action_({|v|
			var i = v.items[v.value];
			(v.value == 0).if({
				(id.notNil).if({
					self.unpatch(output.asString, id);
					id = nil;
				});
				output = nil;
			}, {
				(input.notNil).if({
					(id.notNil).if({
						self.unpatch(output.asString, id);
					});
					output = i;
					id = self.patch(output.asString, input.asString, spec.map(sl.value));
				}, {
					output = i;
				});
			});
		})
		.value_((output.isNil).if({ 0 }, { oItems.indexOf(output) + 1 }));
		v;
	},
	makeGui: {|self, parent, mods = 1, excludeInputs|
		var o = sortModules.value(self.modulators, self.io[\outputs])
		.collect({|v| v.asSymbol }),
		i = sortModules.value(self.modules, self.io[\inputs])
		.collect({|v| v.asSymbol }),
		view = View(parent, parent.bounds),
		f = FlowLayout(view.bounds, 0@0, 12@0),
		patches = self.getAllPatches();

		view.decorator_(f);

		StaticText(view).string_("Mod Pod").fixedWidth_(60);
		f.nextLine;

		// ignore t_ and i_ rate inputs
		i = i.select({|v| " t_".matchRegexp(v.asString).not });
		(excludeInputs.notNil).if({
			excludeInputs = excludeInputs.collect({|v| v.asSymbol });
			i = i.select({|v| excludeInputs.includes(v).not });
			patches = patches.select({|v|
				excludeInputs.includes(v[\inputKey].asSymbol).not
			});
		});
		self.views = Dictionary.new;
		self.views[\modulations] = List.new;

		(patches.size > 0).if({
			self.addExistingPatches(patches, view, i, o, mods);
		}, {
			self.addNewModViews(mods, view, i, o);
		});
		self.views[\view] = view;
		view;
	},
	addExistingPatches: {|self, patches, view, i, o, total|
		var count = 0,
		cond = Condition(false);

		patches.do({|p|
			var ok = p[\outputKey],
			id = p[\id];
			self.getPatchInfo(ok, id, {|v|
				(v.notNil).if({
					p[\mul] = v[\mul];
					p[\add] = v[\add];
				});
				count = count + 1;
				(count >= patches.size).if({
					cond.test = true;
					cond.signal;
				});
			});
		});
		{
			cond.wait;
			{
				patches.do({|p|
					self.views[\modulations].add(
						self.modView(view, i, o, [
							p[\inputKey].asSymbol,
							p[\outputKey].asSymbol,
							p[\id],
							p[\mul],
							p[\add]
						])
					);
				});
				self.addNewModViews((total - patches.size).max(0), view, i, o);
			}.defer;
		}.fork;
	},
	addNewModViews: {|self, num, view, i, o|
		num.do({
			self.views[\modulations].add(self.modView(view, i, o));
		});
	},
	updateGui: {|self|
		var o = self.io[\outputs],
		v = self.views;
		o.keys.do({|key|
			var p = o[key][\patches];
			(v[key].notNil).if({
				v[key].keys.do({|k| v[key][k].value_(0) });
				p.keys.do({|ikey|
					(v[key][ikey].notNil).if({
						v[key][ikey].value_(1);
					});
				});
			});
		});
	}
);

~controlPatchbay = ~controlPatchbay ++ extension;