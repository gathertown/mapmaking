# mapmaking
Maps, tilesets, and assets oh my!


## Use
### Basic Usage
**"I just want one thing"**
1. Find the tileset(s) or map(s) you want. Download it.
2. Expect it will get out of date.
3. Download it again.

**"I want all the tilesets"**
1. Click the green [Code] button
2. Click [Download Zip]
3. Extract the tileset folder to somewhere nice on your computer.
4. Expect it will get out of date.
5. Download it again.

### Git Guru Usage
**"I want to stay up-to-date"**
0. (recommended) use some sort of git management program (Fork recommended, Github Desktop also works).
1. Clone this repo: https://github.com/gathertown/mapmaking.git
2. To check for changes: [Fetch/Pull]

If you want to contribute you're welcome to make pull requests. Tilesheets 

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
`Group Name #.x.tsx`
Where
- `Group` is likely "Gather"
- `Name` is the tileset name, like "Floors" or "Decoration"
- `#` is the major version number. Like all versioning systems, the anything contained in a "major version" (to the left of the .) are compatable with themselves.
- `x` is literally "x"

### for tilesheets (".png")
`group_name_#.#.png`
- `group` is likely "gather"
- `name` is the tilesheet name, like 'floors' or 'decoration'
- `#` is the major version number. Like all versioning systems, the anything contained in a "major version" (to the left of the .) are compatable with themselves.
- `#` is the minor version number. Consider these small changes like little refinements or adding more items without moving anything around.

example:
- `Gather Floors 1.x.tsx` points to `gather_floors_1.3.png`. If the tilesheet is updated (from 1.3 to 1.4) then
- `Gather Floors 1.x.tsx` poitns to `gather_floors_1.4.png`.
