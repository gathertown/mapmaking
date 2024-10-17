# Object Upload Tool

Top level folders in this project:

- `output` - this is where the image and metadata generated output of the tool lives
- `src` - this is where all of the development tooling needed to work on the tool lives
- `asepriteScripts` - these are all of the Aseprite scripts that need to be put into your [Aseprite scripts folder](https://community.aseprite.org/t/locate-user-scripts-folder/2170) to use the tool

## Using the Script

### Setup

- Open your Aseprite Config directory: https://www.aseprite.org/docs/preferences-folder/
- Create a `.gather_config.json` file
- Set your outputDirectory value
  - TODO: we could maybe actually automate this whole process via dialog inputs/file picker
- In Aseprite, hit `rescan scripts` to make sure you get the script to show up in Aseprite dropdown

### Aseprite File Format

This script expects an Aseprite file to have 3 layers:

- Sprite - layer with artwork on it
- Fold - layer with fold (depth sort line) information on it
- Origin - layer with origin of each sprite direction on it

### Usage

- Select `Gather Parse Tilesheet vX.X.X` from your scripts dropdown in Aseprite
- Fill out data in the popup
- Verify data looks as expected in `output` folder in this repository
- Commit this change in git and push to GitHub on the `main` branch
- GitHub will sync those changes over to staging automatically

## Developing the Script

- Use `.nvmrc` specified version of node
- Setup `.env` file based on the `.env.example` file
