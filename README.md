# mapmaking
Maps, tilesets, and assets oh my!


## Use
### Basic Usage
**"I just want one thing"**
1. Find the tileset(s) or map(s) you want, assume it'll be up to date. Download it.
2. Expect it will get out of date.
   ^ probably best for background/foreground image files. If you're planning on modifying something, pls clone the repo!
If you have any questions or troubles, let me know.

### MAP GURU USAGE
**"I'm want to change something"**
0. (recommended) use some sort of git management program (I use Fork), or be a boss and go comand-line.
1. Clone this repo: https://github.com/gathertown/mapmaking.git
( I put it in my local "Gather" directory as "mapmaking". )
2. Before you start at the beginning of the day, Fetch.
3. If you make a change to the repo, Merge and Push.

Because all the tiled files (TMX / TSX) use relative paths, we're golden. Everything is self-contained in the repo, or even if you have side-projects that reference this repo, it should still work.

## File Structure
### mapmaking
#### 📁 maps
map files (.tmx) / background files (.png) / foreground files (.png) / photoshop files (.psd)
divided into project-based directories
#### 📁 tilesets
tileset files (.tml) and source files (.png)
#### 📁 assets
individual asset files (.png) and photoshop source files (.psd)

## Tileset Naming Convention
### for tilesets (.tsx)
`Group Name #.#.tsx`
Where
- `Group` is likely "Gather"
- `Name` is the tileset name, like "Castle" or "University"
- `#` is the major version number. Like all versioning systems, the anything contained in a "major version" (to the left of the .) are compatable with themselves. Consider these small changes like little refinements or adding more items without moving anything around.
- `x` is literally "x"


### for tilesheets (".png")
`group_name_#.#.png`
- we should actually change the value incrementally, and point the corresponding tileset to this as it changes.
