(
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
)
// Wait til you see "Ready to go."
~dfam.makeGui();
