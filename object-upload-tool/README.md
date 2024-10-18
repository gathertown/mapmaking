# Object Upload Tool

Top level folders in this project:

- `src` - this is where all of the development tooling needed to work on the tool lives
- `asepriteScripts` - these are all of the Aseprite scripts that need to be put into your [Aseprite scripts folder](https://community.aseprite.org/t/locate-user-scripts-folder/2170) to use the tool
- `objects` - where all aseprite source and generated output files live
- `reference` - extra reference data

## Using the Script

### Setup

- Open your Aseprite Config directory: https://www.aseprite.org/docs/preferences-folder/
- Create a `.gather_config.json` file
- Set your outputDirectory value
  - TODO: we could maybe actually automate this whole process via dialog inputs/file picker
- In Aseprite, hit `rescan scripts` to make sure you get the script to show up in Aseprite dropdown

### File structure

Example:

```txt
objects
- Seating
  - Couch
    - Chaise
      - Chaise.aseprite
      - Chaise_generated.png
      - manifest.json
```

All object data lives in the root `objects` folder.

1. `Category` - these correspond to tabs/sections in the Catalog
2. `Family` - objects in the same family are swappable by changing `Type` in Studio
3. `Type` - specific type of object in a given family, the available Type options
<!-- 4. `Style` - visual variations per catalog item not tied specifically to color -->

### Aseprite File Format

This script expects an Aseprite file to have 3 layers:

- Sprite - layer with artwork on it
- Fold - layer with fold (depth sort line) information on it
- Origin - layer with origin of each sprite direction on it
- Collision - layer to specify which tiles block movement
- Sittable - layer to specify which tiles are able to be sat on by players

### Usage

- Select `Gather Parse Tilesheet vX.X.X` from your scripts dropdown in Aseprite
- Fill out data in the popups
- Verify data looks as expected in `objects` folder of this repository
- Commit this change in git and push to GitHub on the `master` branch
- GitHub will sync those changes over to staging automatically

## Developing the Script

- Use `.nvmrc` specified version of node
- Setup `.env` file based on the `.env.example` file
- `npm install` dependencies
- Install [Aseprite](https://www.aseprite.org/) to run the script
- `npm run watch` will build the script locally and sync it to your local Aseprite's script directory (this script will crash if you save invalid lua right now)

### Bundling

Source code for the script lives in `src/asepriteScripts`. `asepriteScripts` contains lua source code that is bundled by `luabundle` and exported to root `asepriteScripts` directory.

### Versioning

- Script name includes a version number pulled from `package.json` version field
- This version number should be incremented if script changes occur to ensure the art team is producing correctly formatted data
