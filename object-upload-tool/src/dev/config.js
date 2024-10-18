import path from "path";
import "dotenv/config";

export const asepriteScriptsOutputDir =
  process.env.ASEPRITE_SCRIPTS_DIRECTORY_PATH;

export const localAsepriteScriptsDir = path.join(
  import.meta.dirname, // devScripts
  "..", // src
  "..", // object-upload-tool
  "asepriteScripts"
);

export const localAsepriteScriptsSrcDir = path.join(
  import.meta.dirname, // devScripts
  "..", // src
  "asepriteScripts"
);

export const packagePath = path.join(
  import.meta.dirname,
  "..",
  "..",
  "package.json"
);
