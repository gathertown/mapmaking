import { rimraf } from "rimraf";
import { asepriteScriptsOutputDir } from "./config.js";

rimraf(asepriteScriptsOutputDir, {
  filter: (path) => path.toLowerCase().includes("gather"),
});
