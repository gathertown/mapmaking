import fs from "fs";
import { asepriteScriptsOutputDir, localAsepriteScriptsDir } from "./config.js";

function syncScriptDirectory() {
  fs.cpSync(localAsepriteScriptsDir, asepriteScriptsOutputDir, {
    recursive: true,
  });
}

export default syncScriptDirectory;
