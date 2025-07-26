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
		var v = View(parent, 50@60),
		f = FlowLayout(v.bounds, 0@0, 0@0),
		iItems = inputs.asArray,
		oItems = outputs.asArray,
		pin,
		pou,
		id,
		input,
		output;

		v.decorator_(f);

		(ignoreInputs.notNil).if({
			iItems = iItems.select({|v| ignoreInputs.includes(v).not });
		});
		(ignoreOutputs.notNil).if({
			oItems = oItems.select({|v| ignoreOutputs.includes(v).not });
		});

		(selected.notNil).if({
			input = selected[0];
			output = selected[1];
			id = selected[2];
		});

		pin = PopUpMenu(v, 50@20)
		.items_([" "] ++ iItems)
		.action_({|v|
			var i = v.items[v.value];
			(i == " ").if({
				(id.notNil).if({
					self.unpatch(output, id);
					id = nil;
				});
				input = nil;
			}, {
				input = i;
				(output.notNil).if({
					(id.notNil).if({
						self.unpatch(output, id);
					});
					id = self.patch(output, input);
				});
			});
		})
		.value_((input.isNil).if({ 0 }, { iItems.indexOf(input) }));
		f.nextLine;
		pou = PopUpMenu(v, 50@20)
		.items_([" "] ++ oItems)
		.action_({|v|
			var i = v.items[v.value];
			(i == " ").if({
				(id.notNil).if({
					self.unpatch(output, id);
					id = nil;
				});
				output = nil;
			}, {
				(input.notNil).if({
					(id.notNil).if({
						self.unpatch(output, id);
					});
					output = i;
					id = self.patch(output, input);
				}, {
					output = i;
				});
			});
		})
		.value_((output.isNil).if({ 0 }, { oItems.indexOf(output) }));
		v;
	},
	makeGui: {|self, parent|
		var o = sortModules.value(self.modulators, self.io[\outputs]),
		i = sortModules.value(self.modules, self.io[\inputs]),
		view = View(parent, parent.bounds),
		f = FlowLayout(view.bounds, 0@0, 12@0);
		view.decorator_(f);

		StaticText(view).string_("Mod Pod");
		f.nextLine;

		// ignore t_ and i_ rate inputs
		i = i.select({|v| " t_".matchRegexp(v.asString).not });

		self.views = Dictionary.new;
		self.views[\modulations] = List.new;
		self.views[\modulations].add(self.modView(view, i, o));
		self.views[\view] = view;
		view;
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