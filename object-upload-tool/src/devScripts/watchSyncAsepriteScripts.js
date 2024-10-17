import chokidar from "chokidar";
import { localAsepriteScriptsDir } from "./config.js";
import syncScriptDirectory from "./syncScriptDirectory.js";

chokidar.watch(localAsepriteScriptsDir).on("all", (event, path) => {
  syncScriptDirectory();
});
