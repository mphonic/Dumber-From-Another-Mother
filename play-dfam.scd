( // ONLY RUN THIS IF DFAM ISN'T ALREADY RUNNING
(Document.current.dir ++ "/sc-dfam.scd").loadPaths;
~makeADfam.value({|d| ~dfam = d });
)
// Wait til you see "Ready to go."
~dfam.makeGui();
