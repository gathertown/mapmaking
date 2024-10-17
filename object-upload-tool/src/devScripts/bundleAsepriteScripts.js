import path from "path";
import { bundle } from "luabundle";
import {
  localAsepriteScriptsSrcDir,
  localAsepriteScriptsDir,
  packagePath,
} from "./config.js";
import { readFile, writeFile } from "fs/promises";

const packageInfoRaw = await readFile(packagePath, "utf8");
const packageInfo = JSON.parse(packageInfoRaw);

const entrypoint = "parse_tilesheet.lua";

const entrypointPath = path.join(localAsepriteScriptsSrcDir, entrypoint);
const bundledLua = bundle(entrypointPath, {
  paths: [
    path.join(localAsepriteScriptsSrcDir, "?.lua"),
    path.join(localAsepriteScriptsSrcDir, "deps", "?.lua"),
  ],
});

const outputFilePath = path.join(
  localAsepriteScriptsDir,
  `Gather Parse Tilesheet v${packageInfo.version}.lua`
);

await writeFile(outputFilePath, bundledLua);
