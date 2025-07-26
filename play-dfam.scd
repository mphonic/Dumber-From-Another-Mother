(Document.current.dir ++ "/sc-dfam.scd").loadPaths;

~makeADfam.value({|d| ~dfam = d });
~dfam.makeGui();