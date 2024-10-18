import simpleGit from "simple-git";

const commits = await simpleGit().log();

const [latestCommit, secondLatestCommit] = commits.all;

const diff = await simpleGit().diffSummary([
  latestCommit.hash,
  secondLatestCommit.hash,
]);

const changedFiles = diff.files.map((fileDiff) => fileDiff.file);

console.log(changedFiles);
