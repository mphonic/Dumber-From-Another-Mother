(~patchbay.isNil).if({
	(Document.current.dir ++ "/base/patchbay.scd").loadPaths;
});

~controlPatchbay = (
	parent: ~patchbay,
	create: {|self, modules, modulators|
		var o = self.deepCopy,
		confKeys = [\controls, \outputs],
		ioKeys = [\inputs, \outputs],
		toReplace = ["in", "out"];
		o.modules = modules;
		o.modulators = modulators;
		o.io = Dictionary[
			\inputs -> Dictionary.new,
			\outputs -> Dictionary.new
		];
		[modules, modulators].do({|e, c|
			e.do({|i|
				o.generateIoSet(i, ioKeys[c], confKeys[c], toReplace[c]);
			});
		});
		o;
	},
	generateIoSet: {|self, module, ioKey, confKey, replaceString|
		(module[confKey].notNil).if({
			var n = module.name;
			module[confKey].keys.do({|key|
				var bus = module[confKey][key];
				(bus.rate != 'audio').if({
					var paramName = key.asString.toLower().replace(replaceString, ""),
					spacer = "",
					name;
					(paramName.size > 0).if({ spacer = " " });
					name = module.name ++ spacer ++ paramName;
					self.io[ioKey][name] = Dictionary[
						\param -> key,
						\bus -> bus,
						\module -> module
					];
				});
			});
		});
	},
	patch: {|self, outputKey, inputKey, mul = 1.0, add = 0.0|
		var outputSource = self.io[\outputs][outputKey],
		inputSource = self.io[\inputs][inputKey],
		id = outputKey ++ "2" ++ inputKey,
		param = inputSource[\param],
		patches = outputSource[\patches] ? Dictionary.new,
		module = inputSource[\module],
		node;
		while({ patches[id].notNil }, {
			id = id ++ Date.getDate().secStamp().asString;
		});
		node = module.addMod(id, param, outputSource[\bus], mul, add);
		patches[id] = Dictionary[
			\setPatch -> {|mul = 1.0, add = 0.0|
				module.setMod(param, id, mul, add);
			},
			\unpatch -> {
				module.removeMod(param, id);
				self.io[\outputs][outputKey][\patches].removeAt(id);
			},
			\moduleName -> module.name,
			\node -> node,
			\param -> param,
			\id -> id,
			\inputKey -> inputKey
		];
		outputSource[\patches] = patches;
		id;
	},
	unpatch: {|self, outputKey, id|
		var patch = self.getPatchById(outputKey, id);
		(patch.notNil).if({
			patch[\unpatch].value;
		});
	},
	setPatch: {|self, outputKey, id, mul, add|
		var patch = self.getPatchById(outputKey, id);
		patch[\setPatch].value(mul, add);
	},
	getPatchById: {|self, outputKey, id|
		var p = self.io[\outputs][outputKey][\patches];
		(p.notNil).if({
			p[id];
		}, {
			nil;
		});
	},
	getPatchInfo: {|self, outputKey, id, cb|
		var patch = self.getPatchById(outputKey, id);
		(patch.notNil).if({
			var node = patch[\node],
			name = patch[\moduleName],
			param = patch[\param],
			info = Dictionary[\name -> name, \param -> param],
			cond = Condition.new(false),
			count = 0,
			params = [\mul, \add];
			params.do({|e|
				node.get(e, {|v|
					info[e] = v;
					count = count + 1;
					(count >= params.size).if({
						cond.test = true;
						cond.signal;
					});
				});
			});
			{
				cond.wait;
				cb.value(info);
			}.fork;
		}, {
			("Warning: no patch with id " ++ id ++ " at " ++ outputKey).postln;
			cb.value(nil);
		});
	},
	getInputKeyFromPatch: {|self, patch|
		patch[\inputKey];
	},
	getNodeFromPatch: {|self, patch|
		patch[\node];
	},
	getPatchInputId: {|self, patch, key|
		patch[\id];
	},
	getAllPatches: {|self|
		var o = self.io[\outputs],
		patches = List.new;
		o.keys.do({|k|
			(o[k][\patches].notNil).if({
				o[k][\patches].keys.do({|id|
					var p = o[k][\patches][id];
					patches.add(Dictionary[
						\outputKey -> k,
						\inputKey -> self.getInputKeyFromPatch(p),
						\id -> id,
						\patch -> p
					]);
				});
			});
		});
		patches;
	};
);