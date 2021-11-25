# HadesRando
HadesRando is a randomizer mod for the game [Hades](https://store.steampowered.com/app/1145360/Hades/). The randomizer offers a whole new experience compared to vanilla hades, often making the game a bit more challenging.
It requires you think in a completely different way than you normally would, often requiring you to come up with strategies on the fly.

**Please make a backup of your save file or use a clean file before using this mod! ([Click here for a 100% save file](https://www.speedrun.com/resourceasset/hshp9))**

### What can be randomized?
The following parts of the game can currently be randomized:
- All enemies and minibosses can be shuffled, so they will appear in different levels than usual. (Some logic is applied to make sure this isn't too difficult)
- Boon offerings of gods will be shuffled. This means that, for example, Poseidon may offer a Zeus attack and an Artemis attack, instead of the usual boons.
- Keepsakes and companions can be randomized on run start and after level transitions.
- Your weapon can be randomized every run. The aspect of the weapon will also be randomized.
- The chambers you will encounter can be randomized. In one chamber you might be in Tartarus, but the next chamber could lead to elysium, a miniboss in asphodel or maybe even the lernie bossfight. The main bossfights still happen in the same order, but they may appear earlier or later than normal.

### Installation Instructions
1. If you don't have Mod Importer installed yet, download it from: https://www.nexusmods.com/hades/mods/26 and follow the instructions on that page for installation instructions for your operating system.
2. In the folder where you installed Mod Importer, create another folder called "Mods" (Without the quotes, but with the capital letter).
3. Download ModUtil from here: https://www.nexusmods.com/hades/mods/27 and follow the instructions on the page.
4. Put the whole HadesRando folder in the Mods folder (the same folder as the ModUtil folder).
5. Run the modimporter executable and you should be good to go! If you want to uninstall the mod, just remove the HadesRando folder and run ModImporter again.

### Configuration
All features of this randomizer can be turned on or off by opening the Mods/HadesRando/Scripts/HadesRando.lua file.
At the top of this file you should see `local config`. In here you can change anything from true to false or the other way around.
For example, if you want to disable room randomization, you can set `randomizeRooms = true` to `randomizeRooms = false`

### TODO
- Randomize the Mirror of Night every run
- Randomize the Pact of Punishment
- Randomize sounds
- Randomize text
- Look into other things that can be randomized

### I found a bug or my game crashed, what do I do?
Please create an issue with the following details:
1. A detailed and clear description of what you were doing and what exactly happened.
2. The seed of the run
3. Any steps to reproduce the bug/crash, if possible.
4. A video showing the bug, if possible.
