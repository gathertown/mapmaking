import chokidar from "chokidar";
import { localAsepriteScriptsSrcDir } from "./config.js";
import bundleScripts from "./bundleScripts.js";
import syncScriptDirectory from "./syncScriptDirectory.js";

chokidar.watch(localAsepriteScriptsSrcDir).on("all", async (event, path) => {
  await bundleScripts();
  syncScriptDirectory();
});
