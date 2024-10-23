import path from "path";
import simpleGit from "simple-git";

const pathToObjectsDir = path.join("object-upload-tool", "objects");

const commits = await simpleGit().log();

const [latestCommit, secondLatestCommit] = commits.all;

const diff = await simpleGit().diffSummary([
  latestCommit.hash,
  secondLatestCommit.hash,
]);

const changedFiles = diff.files.map((fileDiff) => fileDiff.file);

const data = changedFiles
  .map(getPathMetadata)
  .filter((data) => data.isObjectsPath);

/**
 * TODO:
 *
 * Next steps:
 * - Filter out .aseprite files. (or only care about .png and .json files?)
 * - Validate the data format of manifest.json file. Use yup for this I guess?
 *
 * Once all data is valid:
 * - Iterate over each file, create CatalogItem formatted data
 * - Can we pull these types from gather-town-v2...?
 * - I think I should experiment moving this script into gather-town-v2 as an action there and then just using it a workflow over here?
 */

function isObjectsPath(filePath) {
  return filePath.startsWith(pathToObjectsDir);
}

function getPathRelativeToObjectsDir(filePath) {
  return filePath.replace(pathToObjectsDir + path.sep, "");
}

function getObjectPathParts(filePath) {
  const parts = filePath.split(path.sep);

  const [category, family, type, fileName] = parts;

  return {
    category,
    family,
    type,
    fileName,
  };
}

function getPathMetadata(path) {
  if (!isObjectsPath(path)) {
    return { isObjectsPath: false };
  }

  const relativePath = getPathRelativeToObjectsDir(path);
  const parts = getObjectPathParts(relativePath);

  const validationResult = isValidPath(parts);
  if (validationResult.error) {
    return {
      isObjectsPath: true,
      isValidPath: false,
      error: validationResult.error,
    };
  }

  return {
    isObjectsPath: true,
    filePath: path,
    ...parts,
  };
}

function isValidPath(parts) {
  const { category, family, type, fileName } = parts;

  if (!category)
    return { error: true, message: `Path is missing category: ${path}` };
  if (!family)
    return { error: true, message: `Path is missing family: ${path}` };
  if (!type) return { error: true, message: `Path is missing type: ${path}` };
  if (!fileName)
    return { error: true, message: `Path is missing fileName: ${path}` };

  return { error: false };
}
