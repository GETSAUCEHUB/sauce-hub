-- ============================================================
-- PLACE LOCK - this script only runs in the intended game
-- ============================================================
local ALLOWED_PLACE_ID = 93079655337537
if game.PlaceId ~= ALLOWED_PLACE_ID then
    warn(("[SAUCE] Wrong place (PlaceId %d). This script is locked to place %d.")
        :format(game.PlaceId, ALLOWED_PLACE_ID))
    if game:GetService("StarterGui") then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "SAUCE Locked",
                Text = "This script only works in its intended game.",
                Duration = 6,
            })
        end)
    end
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Wait for ItemFunctionality to fully load (CRITICAL FOR PERSISTENCE)
local itemFunc = ReplicatedFirst:WaitForChild("ItemFunctionality", 5)
if not itemFunc then
    warn("ItemFunctionality missing - equip may not persist")
end

-- SAVE DATA
local saveData = {
    toggleKey = "RightShift",
    walkSpeed = 16,
    jumpPower = 50,
    walkEnabled = false,    -- Config tab: whether the Walk Speed override switch is ON
    jumpEnabled = false,    -- Config tab: whether the Jump Power override switch is ON
    antiAFK = false,
    espMobs = false,
    espRadius = 50,
    currentTab = "Farm",
    currentBossTab = "Common",
    selectedItem = nil,
    farmMobs = {},          -- multi-select list of mob names for the Farm tab
    windowSize = {700, 550},
    windowPos = {0.5, -350, 0.5, -275},
    sidebarWidth = 120,
    sidebarCollapsed = false,   -- whether the side tab rail is collapsed (toggled from the search bar)
    autoEquipWeapon = nil,      -- the weapon chosen for the Farm-tab auto-equip
    autoEquipEnabled = false,   -- whether the auto-equip toggle slider is ON
    autoEquipStrongest = false, -- keep the highest-damage owned weapon equipped
    autoEquipArmor = false,     -- Armor-tab toggle: keep all owned armor equipped (auto re-equip after death)
    farmOffsetX = 0,            -- sideways stud nudge while hovering above the mob (0-25; 0 = centered directly over it)
    farmOffsetY = 0,            -- extra studs to hover ABOVE the mob while auto-farming (0-25; added on top of the weapon's base lift)
    farmDodgeAoE = false,       -- Farm tab: auto-dash the character out of boss ability AoE hitboxes while farming
    autoFitGui = false,         -- scale the whole window to the player's screen resolution (prevents too-big/too-small GUI)
    merchantStock = {},         -- Shops tab: cached daily merchant stock [{name, cost}], captured live via OpenMerchantShop
    questAutoAccept = false,    -- Quest tab: auto-accept available Daily/Weekly/Monthly bounties (refreshes offers from the Quest Master)
    questAutoTurnin = false,    -- Quest tab: keep quests flowing -- flush completed ones and pull the next bounty the moment it's off cooldown
    questAutoFarm = false,      -- Quest tab: drive the farm engine onto the current active quest's kill target(s)
}

-- Load saved data (player-specific file)
local function getSaveFileName()
    local player = game:GetService("Players").LocalPlayer
    local userId = player and player.UserId or "unknown"
    return "SAUCE_Data_" .. userId .. ".json"
end

local function loadData()
    local fileName = getSaveFileName()
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(fileName))
    end)
    if success and data then
        for key, value in pairs(data) do
            if key == "toggleKey" then saveData.toggleKey = value
            elseif key == "walkSpeed" and type(value) == "number" then saveData.walkSpeed = value
            elseif key == "jumpPower" and type(value) == "number" then saveData.jumpPower = value
            elseif key == "walkEnabled" then saveData.walkEnabled = value
            elseif key == "jumpEnabled" then saveData.jumpEnabled = value
            elseif key == "antiAFK" then saveData.antiAFK = value
            elseif key == "espMobs" then saveData.espMobs = value
            elseif key == "espRadius" and type(value) == "number" then saveData.espRadius = value
            elseif key == "currentTab" then saveData.currentTab = value
            elseif key == "currentBossTab" then saveData.currentBossTab = value
            elseif key == "selectedItem" then saveData.selectedItem = value
            elseif key == "farmMobs" and type(value) == "table" then saveData.farmMobs = value
            elseif key == "windowSize" and type(value) == "table" then saveData.windowSize = value
            elseif key == "windowPos" and type(value) == "table" then saveData.windowPos = value
            elseif key == "sidebarWidth" and type(value) == "number" then saveData.sidebarWidth = value
            elseif key == "sidebarCollapsed" then saveData.sidebarCollapsed = value
            elseif key == "autoEquipWeapon" then saveData.autoEquipWeapon = value
            elseif key == "autoEquipEnabled" then saveData.autoEquipEnabled = value
            elseif key == "autoEquipStrongest" then saveData.autoEquipStrongest = value
            elseif key == "autoEquipArmor" then saveData.autoEquipArmor = value
            elseif key == "farmOffsetX" and type(value) == "number" then saveData.farmOffsetX = math.clamp(math.floor(value), 0, 25)
            elseif key == "farmOffsetY" and type(value) == "number" then saveData.farmOffsetY = math.clamp(math.floor(value), 0, 25)
            elseif key == "farmDodgeAoE" then saveData.farmDodgeAoE = value
            elseif key == "autoFitGui" then saveData.autoFitGui = value
            elseif key == "merchantStock" and type(value) == "table" then saveData.merchantStock = value
            elseif key == "questAutoAccept" then saveData.questAutoAccept = value
            elseif key == "questAutoTurnin" then saveData.questAutoTurnin = value
            elseif key == "questAutoFarm" then saveData.questAutoFarm = value
            end
        end
    end
end

local function saveDataToFile()
    local data = {
        toggleKey = saveData.toggleKey,
        walkSpeed = saveData.walkSpeed,
        jumpPower = saveData.jumpPower,
        walkEnabled = saveData.walkEnabled,
        jumpEnabled = saveData.jumpEnabled,
        antiAFK = saveData.antiAFK,
        espMobs = saveData.espMobs,
        espRadius = saveData.espRadius,
        currentTab = saveData.currentTab,
        currentBossTab = saveData.currentBossTab,
        selectedItem = saveData.selectedItem,
        farmMobs = saveData.farmMobs,
        windowSize = saveData.windowSize,
        windowPos = saveData.windowPos,
        sidebarWidth = saveData.sidebarWidth,
        sidebarCollapsed = saveData.sidebarCollapsed,
        autoEquipWeapon = saveData.autoEquipWeapon,
        autoEquipEnabled = saveData.autoEquipEnabled,
        autoEquipStrongest = saveData.autoEquipStrongest,
        autoEquipArmor = saveData.autoEquipArmor,
        farmOffsetX = saveData.farmOffsetX,
        farmOffsetY = saveData.farmOffsetY,
        farmDodgeAoE = saveData.farmDodgeAoE,
        autoFitGui = saveData.autoFitGui,
        merchantStock = saveData.merchantStock,
        questAutoAccept = saveData.questAutoAccept,
        questAutoTurnin = saveData.questAutoTurnin,
        questAutoFarm = saveData.questAutoFarm,
    }
    local fileName = getSaveFileName()
    pcall(function()
        writefile(fileName, game:GetService("HttpService"):JSONEncode(data))
    end)
end

loadData()

-- Colors
local colors = {
    background = Color3.fromRGB(10, 10, 18),
    backgroundDark = Color3.fromRGB(6, 6, 12),
    accent = Color3.fromRGB(120, 80, 255),
    text = Color3.fromRGB(255, 255, 255),
    textDim = Color3.fromRGB(180, 180, 200),
    border = Color3.fromRGB(60, 60, 80),
    danger = Color3.fromRGB(255, 50, 80),
    success = Color3.fromRGB(0, 255, 150),
    warning = Color3.fromRGB(255, 200, 0),
}

-- BOSS DATA
local bossData = {
    Common = {
        "(?) Darkness Howler (Common Boss)",
        "(?) Skeleton King (Common Boss)",
        "Gold Cluster (Common Boss)",
        "XP Cluster (Common Boss)"
    },
    Rare = {
        "(?) Ghastly Spirit (Rare Boss)",
        "(?) Master Wizard (Rare Boss)",
        "(?) Terminator (Rare Boss)",
        "(?) Zombae (Rare Boss)"
    },
    Epic = {
        "(?) Dragon Lord (Epic Boss)",
        "(?) Jane Doe (Epic Boss)",
        "(?) John Doe (Epic Boss)",
        "(?) Poltergeist (Epic Boss)",
        "(?) R0b0t (Epic Boss)"
    },
    Legendary = {
        "(?) Anubis (Legendary Boss)",
        "(?) Jolly Robber (Legendary Boss)",
        "(?) The Destroyer (Legendary Boss)",
        "(?) c00lkidd (Legendary Boss)"
    },
    Secret = {
        "(?) Atam, The Planck (Secret Boss)",
        "(?) Cosmos, The Infinity (Secret Boss)",
        "(?) Invis, The Invisible (Secret Boss)",
        "(?) The True Thief (Secret Boss)",
        "(?) Shrouding Vantablack (Secret Boss)",
        "(?) Blinding Everlight (Secret Boss)"
    }
}

-- ============================================================
-- ITEM DATA (PARSED FROM PROVIDED LIST)
-- ============================================================
local itemNames = {
	".err",
	"10,000 Degree Sword",
	"101001110001",
	"2019BloxyAward",
	"3tcyGDh8a57eKYasvw2haG9tWAr8qpZsXc8WGwT17s",
	"4th Of July Black Flash",
	"A Million Cries",
	"AbominusHelmet",
	"Abyssal Key",
	"Accelerant Clover",
	"Affection",
	"Affinity",
	"Agna",
	"Agnar",
	"Aleksanteri",
	"Aliens' Creation",
	"All-Seeing Golem's Hammer",
	"Aloke",
	"Amerigun",
	"Ancestral Makana",
	"Ancestral Metamorphosis",
	"Ancestral Transformation",
	"Ancestral Wrath",
	"Anchor",
	"AncientHeroSword",
	"AngelsBlessing",
	"Annihilation",
	"Anubis Staff",
	"Anubon",
	"Apple",
	"Aquarage",
	"Armageddon",
	"Artorias",
	"Atom Splitter",
	"Atomic Dislocator",
	"AttackDoge",
	"Aurora",
	"Autumn",
	"Avarice",
	"Azure Periastron",
	"Azurewrath Sword",
	"BLADEOFTHEPATRIOTS",
	"BLUEBLADE",
	"BabbitsSword",
	"Ballerina",
	"Ban Hammer",
	"BananaPeel",
	"Bannana",
	"Bat Sword",
	"Beast Armor",
	"Beast Helm",
	"Beginner's Illumination",
	"Beginner's Knife",
	"Berserker",
	"Berserker Potion",
	"BestStaff",
	"Black Hole Sword",
	"BlackEdge",
	"Blackfyre",
	"Blade of Erasure",
	"Blade of the Horseman",
	"Blessed Blade",
	"Blinding Light",
	"Blood",
	"Blood Key",
	"Bloods Wraith",
	"Bloodsteel Katana",
	"Bloody Conception",
	"Bloody Night",
	"Bloody Perception",
	"Blossom",
	"Blue Fang",
	"Blue Steel Savior",
	"Boat",
	"Bone Lord's Son's Sword",
	"Bone Sword",
	"BoomBox",
	"Borealis",
	"BornOfAStar",
	"BrokenHeroSword",
	"Bronze Sword",
	"Buff Bacon Arm",
	"Buff Noob Arm",
	"Buff Zombie Arm",
	"Bunny Annihilator",
	"Bunny Blade",
	"Bunny Demolisher",
	"Bunny Destroyer",
	"Bunny Ender",
	"Bunny Obliterator",
	"Bunny Slasher",
	"Bunny Slicer",
	"Bunny Vanquisher",
	"Bunny's Pride",
	"Butter Sword",
	"Cactus",
	"Calamity",
	"Calaster Axe",
	"Cardboard Sword",
	"Ceaseless Scimitar",
	"Cerberus Costume",
	"Cerberus Mask",
	"Challenge Access",
	"ChiefjustusHammer",
	"Chocolate Coated Blade",
	"Chroma",
	"Cinder",
	"Citadel Access",
	"Class1c $w0rd",
	"Classic Trowel",
	"Cloud",
	"Clover Sword",
	"Clovete",
	"Collapsing Star",
	"Collector's Scythe",
	"Color Blade",
	"Conqueror",
	"Cool Shades",
	"Corpse Scythe",
	"Corrosion",
	"Corrupted Sanctuary",
	"Corvus",
	"Cosmic Age",
	"Cosmic Light",
	"Crackling Crimson",
	"Creation",
	"Creation Access",
	"Crescendo",
	"Crescent Moon",
	"Crimson Catseye Crescendo",
	"Crimson Lance",
	"Crimson Periastron",
	"Crimson Slayer",
	"Crimson Terror",
	"CrimsonWrath",
	"CrimsonwrathSword",
	"Cription",
	"Crocodilo",
	"Cryogenic Abolisher",
	"Cryogenic Disaster",
	"Cybernetic Annihilator",
	"Cybernetic Infiltrator",
	"DKrojeon",
	"Daestrophe",
	"Dafish",
	"Damage Egg I",
	"Damage Egg II",
	"Damage Egg III",
	"Damage Potion I",
	"Damage Potion II",
	"Damage Potion III",
	"Damage Potion IV",
	"Damage Potion IX",
	"Damage Potion V",
	"Damage Potion VI",
	"Damage Potion VII",
	"Damage Potion VIII",
	"Damage Potion X",
	"Damage Ruby",
	"Dark Blade",
	"Dark Claws",
	"Dark Heart",
	"Dark Helmet",
	"Dark Knight",
	"Dark Scaled Blade",
	"Dark Shield",
	"Dark Skull",
	"Dark Staff",
	"Dark Steampunk Dominus",
	"DarkBot",
	"DarkCrossbow",
	"DarkDagger",
	"DarkGold",
	"DarkScythe",
	"DarkSpirit",
	"Darkness Access",
	"Darkness Emblem",
	"Darkness Key",
	"Dash",
	"Dawn of Posiedon",
	"DeadlyPillow",
	"Death Staff",
	"Deathdancer",
	"DeathlordArmor",
	"DeathlordHelmet",
	"Deathseeker",
	"Deep Space Blade",
	"Demolisher",
	"Demonis Core",
	"Demonis Main",
	"Derixios",
	"Desert's Tribulation",
	"DesertEdge",
	"DesertScythe",
	"Destiny's Adversary",
	"Destroyer Orb",
	"DestroyerArmor",
	"DestroyerHood",
	"Destructias Staff",
	"Deviant Headgear",
	"Deviant Suit",
	"Devils Rage",
	"Devourer",
	"Diaboli",
	"Diamonx",
	"Diamonx's Helmet",
	"DiamonxWarAxe",
	"DiamonxWarAxe1",
	"Dissonance",
	"Divine Armor",
	"Divine Valk",
	"Divinity",
	"Dominus",
	"Dominus Empyreus",
	"Double Minigun",
	"Draconite",
	"Dragon Slayer",
	"Dragon Sword",
	"DragonScale",
	"Dragonlord Spear",
	"DragonlordArmor",
	"DragonlordHelmet",
	"Dream Edge",
	"Dreamer's Ascension",
	"Dual Draconic Saber",
	"Dual Scaled Blade",
	"EAGLEOFTHESKIES",
	"ETERNAL LIFE",
	"EaglesCry",
	"Earth Sword",
	"EastersRevenge",
	"Eden's Key",
	"Edge Of Termination",
	"Egg Finder V1",
	"Egg Finder V2",
	"Egg Finder V3",
	"EggBeater",
	"Electrus",
	"Elemental Sword",
	"ElixirOfDreams",
	"Emerald Bone Club",
	"Empty Bottle",
	"Enchanter",
	"End's Sword",
	"Enigma",
	"Enmity",
	"Entropic Slayer",
	"Equinox",
	"Equinox Blade",
	"Esoteric Destruction",
	"Eternal",
	"Eternal Haven",
	"Eternal Inferno",
	"Eternal Piercer",
	"Eternity",
	"EverDark",
	"EverFrost",
	"EverLight",
	"Everlasting",
	"EverythinginONE",
	"Evil Staff",
	"Excalibur",
	"Exodus",
	"Fade Axe",
	"Fallen Bodyarmor",
	"Fallen Crown",
	"Fallen Eclipse",
	"Fallen Greatsword",
	"Fallen Waraxe",
	"Federation",
	"Ferocious Neurotoxin",
	"Filled Bottle",
	"Fire Axe",
	"Fire Brand",
	"Fire Sword",
	"Firecracker",
	"Flagbladeofamerica",
	"Flamaa",
	"FlashBang",
	"Flood Sword",
	"Flower Sword",
	"Fluorescent Blade",
	"Forbidden Key",
	"Forcefield",
	"Forsaken Eye",
	"Fortuna",
	"Fortunate Cutter",
	"Fortune",
	"Fourleaf Clover",
	"Fractured Staff",
	"Fracturing Vulcan",
	"Frigidus",
	"Frost",
	"Frost Blade",
	"FrostEdge",
	"FrostSword",
	"Frostbite's Touch",
	"Frozover",
	"GODSLAYER",
	"GaelGreatsword",
	"Galactic Broadsword",
	"GalaxyStarBlade",
	"Garood",
	"Gear Cloner",
	"Ghosdeeri's Sword",
	"GhostWalker",
	"Ghostizer Gun",
	"Ghoul Blade",
	"Giant Golden Sword",
	"Gilded",
	"Gilded Helmet",
	"Gilded Staff",
	"Glacial Collapse",
	"Glacial Smasher",
	"Glorious Feather Dagger",
	"Glorious Victory",
	"Glory",
	"Gnomed",
	"Godnite",
	"Gold Edge",
	"GoldEagleSword",
	"Golden Vengeance",
	"Golden Waraxe",
	"GoldsWish",
	"Goliath",
	"GoliathHammer",
	"Gorgoth",
	"Gracious Hope",
	"Grand Terrestrium",
	"Granite",
	"GrappleHook",
	"Gravity Egg I",
	"Gravity Egg II",
	"Gravity Egg III",
	"Gravity Potion I",
	"Gravity Potion II",
	"Gravity Potion III",
	"Gravity Potion IV",
	"Gravity Potion IX",
	"Gravity Potion V",
	"Gravity Potion VI",
	"Gravity Potion VII",
	"Gravity Potion VIII",
	"Gravity Potion X",
	"Great Chocolate Hammer",
	"Great Chocolate Staff",
	"Great Shark",
	"GreatMasterStaff",
	"GreatSword",
	"HOTDOGSTICK",
	"Hammer of Stars",
	"Healing Jade",
	"Health Egg I",
	"Health Egg II",
	"Health Egg III",
	"Health Potion I",
	"Health Potion II",
	"Health Potion III",
	"Health Potion IV",
	"Health Potion IX",
	"Health Potion V",
	"Health Potion VI",
	"Health Potion VII",
	"Health Potion VIII",
	"Health Potion X",
	"Heart Breaker",
	"Heart Shaker",
	"Heart Striker",
	"Heart Surge",
	"Heart of the World",
	"Heartcake",
	"Heartchete",
	"Heaven's Feather",
	"Heaven's Gift",
	"Heavenly Key",
	"Helios Body",
	"Helios Flame Piercer",
	"Helios Head",
	"Helios Lance",
	"Hellsender",
	"Holo Sword",
	"Holy Sword",
	"Hopeless Edge",
	"Hydrahok",
	"Hypothermic Zero",
	"Ice Blade",
	"Ice Breaker",
	"Ice Crown",
	"Ice Dragon Sword",
	"Icedagger",
	"Ichor",
	"Icspikle",
	"Immortal",
	"Immortal Bulwark",
	"Immortal Claymore",
	"Immortal Patriot",
	"Immortality",
	"Impossible Lucky Sword",
	"Inferno Greatsword",
	"InfernoEdge",
	"Infinite Lucky Sword",
	"Infinity",
	"Interstellar Bone Sword",
	"Inverted Sword",
	"Invigoration",
	"Invisible Sword",
	"Iron Sword",
	"Ironclad Longsword",
	"Jane",
	"John",
	"Judgement Sword",
	"KANESAMERICANSWORD",
	"KNIFE",
	"Killer's Knife",
	"Kings Sword",
	"Knight Of Fire",
	"Korblox Armor",
	"Korblox Death Blade",
	"Korblox Helm",
	"Krojeon",
	"Krypton",
	"Kursiona",
	"LANCEOFSTARS",
	"LIBERTYPRIMESHOPE",
	"Last Hope",
	"Last Retribution",
	"LastChance",
	"LastResort",
	"LeafyStarBlade",
	"Leaves Revenge",
	"Letter.",
	"Leviathan",
	"Lifeforce",
	"Light Scaled Blade",
	"Lighten Crosole",
	"Lightning Slasher",
	"Lightspeed",
	"LinkedAmericanSword",
	"Liquidizer",
	"Longrass Katana",
	"Love Edge",
	"Love Legend",
	"Lovegeddon",
	"Loveless Edge",
	"Lovely Chocolates",
	"Lovestruck Umbrella",
	"Luck",
	"Luck Sword",
	"Luckium Slicer",
	"Lucky Legend",
	"Lucky Periastron",
	"Lucky Sword",
	"Machete",
	"Mango Masher",
	"Master Hood",
	"Master Robes",
	"Master Staff",
	"Mega Damage Potion",
	"Mega Lucky Sword",
	"Merchant's Caravan",
	"Messor",
	"MidStarStaff",
	"Mighty Ban Hammer",
	"Mini Ban Hammer",
	"Minigun",
	"Misfortune",
	"Mist",
	"Mithril Sword",
	"Molten Cutter",
	"Moneybag",
	"Monster",
	"MonsterMashPotion",
	"Moonlight greatsword",
	"MoonsMans",
	"Mortalium",
	"Mystical Clover",
	"NUKEONASTICK",
	"Nadege",
	"Natura",
	"Nature",
	"Nature Staff",
	"Neois",
	"Neptune",
	"Nightfall",
	"No_Life",
	"Noir Periastron",
	"Noxious",
	"Noxious Edge",
	"OVERSEER ARMOR",
	"Obliteration",
	"Ocean Slayer",
	"Oceanic",
	"Octuple Minigun",
	"Old Rusty",
	"Onyx Butcher",
	"Orb of Light",
	"Origin",
	"Otherworldly Knife",
	"Overseer",
	"Overseer BLADE",
	"OverseerHelmet",
	"PSHHHHHHHHHHHHH",
	"Pain Bane",
	"Pancake Sword",
	"Paradigm",
	"Paragon Armor",
	"Paragon Helmet",
	"Parlus Orb",
	"Parlus Scythe",
	"ParlusArmor",
	"ParlusHelm",
	"Patriotic Grimaxe",
	"PatrioticDarkTrollSword",
	"PatrioticDucky",
	"PatrioticWraith",
	"PatriotsDreams",
	"Penguin",
	"Penguin Penguin",
	"Penguin Penguin Penguin",
	"Periastron of Darkness",
	"Perm Damage Potion",
	"Phantom",
	"Phantom Blade",
	"Phantom Helmet",
	"Phantom2",
	"PhantomEdge",
	"PhantomI",
	"PhantomII",
	"Phase Blade",
	"Phoenix Sword",
	"Pink Diamond",
	"PirateRapier",
	"Poison Dagger of Braen",
	"Poltergast",
	"Portal",
	"Poseidon's Trident",
	"Prasanite",
	"Prasax",
	"Primordial Bow",
	"Primordial Waraxe",
	"Primordialis",
	"Progenitor Body",
	"Progenitor Head",
	"Pumpkin Scythe",
	"Pumpkin Sword",
	"PumpkinHammer",
	"Pumpkins Tears",
	"Pumpkins Terror",
	"Pumpkins Vengeance",
	"Pumpkins Wraith",
	"Pure Ascension",
	"Pure Dark",
	"Pure Gold",
	"Quadruple Minigun",
	"Ragnarok",
	"Rainbane",
	"Rainbow Periastron",
	"Rainbow Slayer",
	"Rainbow Sword",
	"Rapacious Treasure",
	"Reality Splitter",
	"Red Diamond",
	"Red DragonScale",
	"Reflection",
	"Regenerative Clover",
	"Repentence",
	"Replica Cription",
	"Resentful Clockwork",
	"Ridable Raptor",
	"RoyalG",
	"Ruler",
	"Ruptured Armor",
	"Ruptured Helmet",
	"Ryat",
	"STARSABORN",
	"STARSTEARS",
	"STICK",
	"Sacred Judgement",
	"Sacrifice",
	"Salt Sword",
	"Santa Helm",
	"SantaArmor",
	"SantaursCrusher",
	"Scarecrow",
	"Scythe",
	"Scythe of Judgement",
	"Scythe of Souls",
	"SeaThemedCrossbow",
	"Secret Access",
	"Secret Key #1",
	"Secret Key #2",
	"Secret Key #3",
	"Sectronic",
	"Seedling",
	"Seraph",
	"SerpentsTears",
	"Servitude",
	"Shamrock Dagger",
	"Shark",
	"Shattered Water",
	"Shimmering Veil",
	"Sidero",
	"Sight",
	"SkeleBlade",
	"Skeleton Head",
	"Skull Crusher",
	"Slime Slasher",
	"Snake Apple",
	"Solice",
	"Soulbound",
	"Soulless Dagger",
	"Spear of skeletons",
	"Speed Egg I",
	"Speed Egg II",
	"Speed Egg III",
	"Speed Potion I",
	"Speed Potion II",
	"Speed Potion III",
	"Speed Potion IV",
	"Speed Potion IX",
	"Speed Potion V",
	"Speed Potion VI",
	"Speed Potion VII",
	"Speed Potion VIII",
	"Speed Potion X",
	"Speedy Diamond",
	"Spire Access",
	"Staff of Stars",
	"Staff of Terror",
	"StaffOfAmerica",
	"StaffOfNightmares",
	"Starbane",
	"Starbreaker",
	"Starlight",
	"StarryBlade",
	"StarryDay",
	"StarryNight",
	"StarrySky",
	"Stasis Body",
	"Stasis GreatSword",
	"Stasis Head",
	"Steampunk Dark Armor",
	"Steel Sword",
	"SteinAxe",
	"Stellar Impact",
	"Stellaria",
	"Stoppable Force",
	"Stratis",
	"Subspace Gun",
	"SunSword",
	"Sunburn",
	"Suniros Staff",
	"Sunshine Protection",
	"Sunshine Shade",
	"Sunspot",
	"Super Damage Potion",
	"Super Lucky Sword",
	"Super Sonic Slasher",
	"Supreme Damage Potion",
	"Supreme Knife",
	"Supreme Lucky Sword",
	"Swamp Edge",
	"Swamp Scythe",
	"Swamp Tree",
	"Sword",
	"Sword Of Light",
	"Sword Of Swords",
	"Sword of Agony",
	"Sword of Darkness",
	"Sword of Fate",
	"Sword of Fluff",
	"Sword of Ordinance",
	"Sword of Patriots",
	"Sword of Self",
	"Sword of Stars",
	"Sword of Wrath",
	"Sword of the Unknown",
	"Tasty_Memes",
	"Terminator",
	"Terminator Helmet",
	"Terminator Suit",
	"Terrestrial Armor",
	"Terrestrial Blade",
	"Terrestrial Headgear",
	"TestingKnife",
	"The Accelerant Sword",
	"The Almighty Chocolate Saber",
	"The Blade Of Creation",
	"The Bone Sword",
	"The Corrupted Bone Sword",
	"The Crucible",
	"The Destroyer",
	"The First Sword",
	"The Fractured Dimensions Sword",
	"The Lustrous Blade",
	"The Mini Rock",
	"The Promised Blade",
	"The Promised Elixir",
	"The Queen's Crown",
	"The Queen's Demolisher",
	"The Reality Collapse Sword",
	"The Rock",
	"The True Knife",
	"Timeless Demise",
	"Tower Access",
	"Toxic Clover",
	"Tralala",
	"Tree",
	"Tree Access",
	"Tree Sword",
	"Trident of Hell",
	"Trimmed Helmet",
	"Trimmed Phantom",
	"Troll Sword",
	"True Bone Sword",
	"True Lucky Sword",
	"Tung Tung",
	"Turkey",
	"Turkeys Revenge",
	"Tyson",
	"Tysonite",
	"UDeath",
	"USAKNIFE",
	"USAVAMPBLADE",
	"Ultia Body",
	"Ultia Hood",
	"Ultimate Damage Potion",
	"Ultimate Lucky Sword",
	"Ultimatia",
	"Ultimation",
	"Ultra Damage Potion",
	"Ultra Dash",
	"Ultra Lucky Sword",
	"Undying",
	"Undying Guard",
	"Universe Ender",
	"Universe Splitter",
	"Unstoppable Force",
	"Usurper",
	"Valentine",
	"Valkyrie",
	"Vanquisher",
	"Vash Armor",
	"Vash Bow",
	"Vash Head",
	"VenomShank",
	"Verdant Fang",
	"Viridescent Edge",
	"Viridian Dagger",
	"Virtuous Blade",
	"Void Fang",
	"Volcanic Rock",
	"Volcanic Terror",
	"Volcanis",
	"VortexBlade",
	"Vortrex",
	"Water Sword",
	"Wateraged Artifact",
	"Waterstone Defense",
	"Waterstone Rampart",
	"Weightless Amethyst",
	"WerewolfEdge",
	"Whispering Skulls",
	"White",
	"White Death",
	"White Flames",
	"Wind Dancer",
	"WingCutter",
	"Woo!",
	"Wood Sword",
	"Wooden Sword",
	"World Splitter",
	"Yin & Yang",
	"Yolksed",
	"Zano",
	"ZantaClawz",
	"knife.",
	"lavithin",
}

-- Deduplicate item list
local uniqueItems = {}
for _, name in ipairs(itemNames) do
	uniqueItems[name] = true
end
local itemList = {}
for name in pairs(uniqueItems) do
	table.insert(itemList, name)
end
table.sort(itemList)

-- ============================================================
-- ARMOR DATA (HELMETS & BODY ARMOR)
-- ============================================================
local helmetNames = {
	"AbominusHelmet",
	"Ancestral Transformation",
	"Beast Helm",
	"Bloody Perception",
	"Cerberus Mask",
	"Dark Helmet",
	"Dark Steampunk Dominus",
	"DeathlordHelmet",
	"Demonis Main",
	"DestroyerHood",
	"Deviant Headgear",
	"Diamonx's Helmet",
	"Divine Valk",
	"Dominus Empyreus",
	"DragonlordHelmet",
	"Fallen Crown",
	"Frigidus",
	"Gilded Helmet",
	"Helios Head",
	"Korblox Helm",
	"Master Hood",
	"OverseerHelmet",
	"Paragon Helmet",
	"ParlusHelm",
	"Phantom Helmet",
	"Progenitor Head",
	"Ruptured Helmet",
	"Santa Helm",
	"Stasis Head",
	"Sunshine Shade",
	"Terminator Helmet",
	"Terrestrial Headgear",
	"The Queen's Crown",
	"Trimmed Helmet",
	"Ultia Hood",
	"Undying Guard",
	"Vash Head",
	"Waterstone Rampart",
}

local bodyArmorNames = {
	"White",
	"Waterstone Defense",
	"Vash Armor",
	"Ultia Body",
	"Tysonite",
	"Terrestrial Armor",
	"Terminator Suit",
	"Sunshine Protection",
	"Steampunk Dark Armor",
	"Stasis Body",
	"SantaArmor",
	"Progenitor Body",
	"Ruptured Armor",
	"Prasanite",
	"PhantomII",
	"PhantomI",
	"ParlusArmor",
	"Paragon Armor",
	"OVERSEER ARMOR",
	"Master Robes",
	"Korblox Armor",
	"Immortal Bulwark",
	"Helios Body",
	"Granite",
	"Gilded",
	"Godnite",
	"Frost",
	"Federation",
	"Fallen Bodyarmor",
	"DragonlordArmor",
	"DragonScale",
	"Draconite",
	"Divine Armor",
	"Diamonx",
	"Deviant Suit",
	"DestroyerArmor",
	"Demonis Core",
	"DeathlordArmor",
	"Dark Knight",
	"Cerberus Costume",
	"Bloody Conception",
	"Berserker",
	"Beast Armor",
	"Base",
	"Ancestral Metamorphosis",
}

-- Combine armor lists
local armorList = {}
for _, name in ipairs(helmetNames) do
	table.insert(armorList, name)
end
for _, name in ipairs(bodyArmorNames) do
	table.insert(armorList, name)
end

-- Some armor pieces ship as Tools in ReplicatedStorage.Weapons instead of the
-- Armor.Helmets/BodyArmor folders (e.g. "Trimmed Phantom", "Red DragonScale",
-- "DarkSpirit"). Armor carries the stat signature "Health: X | Speed: Y" in its
-- ToolTip (real weapons show Damage), so fold any such tool we don't already
-- know about into the armor lists — that makes them show in the Armor tab AND
-- auto-equip. This is a live scan, so future armor-as-weapon is caught too.
do
	local existing = {}
	for _, n in ipairs(armorList) do existing[n] = true end
	local weaponsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Weapons")
	if weaponsFolder then
		for _, tool in ipairs(weaponsFolder:GetChildren()) do
			if tool:IsA("Tool") then
				local tip = tostring(tool.ToolTip)
				if tip:match("^Health:%s*[%w%.]+%s*|%s*Speed:") and not existing[tool.Name] then
					existing[tool.Name] = true
					table.insert(bodyArmorNames, tool.Name)
					table.insert(armorList, tool.Name)
				end
			end
		end
	end
end
table.sort(armorList)

-- Remove armor/helmet names from the Item tab so they only appear under Armor.
do
	local armorLookup = {}
	for _, name in ipairs(armorList) do
		armorLookup[name] = true
	end
	local filteredItems = {}
	for _, name in ipairs(itemList) do
		if not armorLookup[name] then
			table.insert(filteredItems, name)
		end
	end
	itemList = filteredItems
end

-- SELF-UPDATING WEAPON/ITEM SCAN.
-- ReplicatedStorage.Weapons holds every equippable Tool the game ships (858+
-- at time of writing). Rather than trust only the hardcoded itemNames list, fold
-- in ANY Tool we don't already know about so a game update that adds new weapons
-- shows them in the Item tab automatically on next execution -- no manual list
-- edit required. Armor tools (ToolTip "Health: X | Speed: Y") are skipped here;
-- they are handled by the armor scan above and by armorLookup.
do
	local known = {}
	for _, name in ipairs(itemList) do known[name] = true end
	local armorLookup = {}
	for _, name in ipairs(armorList) do armorLookup[name] = true end
	local weaponsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Weapons")
	if weaponsFolder then
		local added = false
		for _, tool in ipairs(weaponsFolder:GetChildren()) do
			if tool:IsA("Tool") and not known[tool.Name] and not armorLookup[tool.Name] then
				local tip = tostring(tool.ToolTip)
				-- Armor carries the Health|Speed signature; everything else
				-- (damage weapons and blank-tip items) is a valid Item entry.
				if not tip:match("^Health:%s*[%w%.]+%s*|%s*Speed:") then
					known[tool.Name] = true
					table.insert(itemList, tool.Name)
					added = true
				end
			end
		end
		if added then table.sort(itemList) end
	end
end

-- SHOP DATA
local shopData = {
    "Advanced Potion Shop", "Armor Shop", "Citadel Shop", "Blood Altar",
    "Creation Salesman", "Dark Sword Shop", "Desert Sword Shop",
    "Divine Sword Shop", "Gamepass Shop", "Potion Shop", "Sell Person",
    "Sky, The Challenge Master", "Snowy Sword Shop", "Supreme Sword Shop",
    "Swamp Sword Shop", "Sword Shop", "Tower of Darkness Salesman",
    "Ultimate Sword Shop", "Volcano Sword Shop", "~Server Master~"
}

local antiAFKEnabled = saveData.antiAFK
local antiAFKConnection = nil
local afkSession = 0 -- token to stop the proactive heartbeat loop on toggle-off
local healthCache = {}

local function getToggleKeyEnum()
    if saveData.toggleKey then
        local enumKey = Enum.KeyCode[saveData.toggleKey]
        if enumKey then
            return enumKey
        end
    end
    return Enum.KeyCode.RightShift
end

local toggleKey = getToggleKeyEnum()

local function getKeyNameFromEnum(keyEnum)
    local name = tostring(keyEnum):gsub("Enum.KeyCode.", "")
    return name
end

local function updateToggleKey(newKeyEnum)
    toggleKey = newKeyEnum
    saveData.toggleKey = getKeyNameFromEnum(newKeyEnum)
    saveDataToFile()
    if keybindLabel then
        keybindLabel.Text = "🔑 Toggle Key: " .. saveData.toggleKey
    end
end

local function getMaxHealthByName(name)
    if healthCache[name] ~= nil then return healthCache[name] end
    local maxHealth = 0
    local mobsFolder = Workspace:FindFirstChild("Mobs")
    if mobsFolder then
        local mob = mobsFolder:FindFirstChild(name)
        if mob then
            local humanoid = mob:FindFirstChild("Humanoid")
            if humanoid then
                maxHealth = humanoid.MaxHealth or humanoid.Health or 0
                if maxHealth > 0 then healthCache[name] = maxHealth return maxHealth end
            end
            local enemy = mob:FindFirstChild("Enemy")
            if enemy then
                local health = enemy:FindFirstChild("Health")
                if health and (health:IsA("NumberValue") or health:IsA("IntValue")) then
                    maxHealth = health.Value
                    if maxHealth > 0 then healthCache[name] = maxHealth return maxHealth end
                end
            end
        end
    end
    local bossEvents = ReplicatedStorage:FindFirstChild("Boss Events")
    if bossEvents then
        local bosses = bossEvents:FindFirstChild("Bosses")
        if bosses then
            for _, rarityFolder in pairs(bosses:GetChildren()) do
                if rarityFolder:IsA("Folder") then
                    local boss = rarityFolder:FindFirstChild(name)
                    if boss then
                        local humanoid = boss:FindFirstChild("Humanoid")
                        if humanoid then
                            maxHealth = humanoid.MaxHealth or humanoid.Health or 0
                            if maxHealth > 0 then healthCache[name] = maxHealth return maxHealth end
                        end
                        local enemy = boss:FindFirstChild("Enemy")
                        if enemy then
                            local health = enemy:FindFirstChild("Health")
                            if health and (health:IsA("NumberValue") or health:IsA("IntValue")) then
                                maxHealth = health.Value
                                if maxHealth > 0 then healthCache[name] = maxHealth return maxHealth end
                            end
                        end
                    end
                end
            end
        end
    end
    healthCache[name] = 0
    return 0
end

local function scanMobs()
    local list = {}
    local folder = Workspace:FindFirstChild("Mobs")
    if folder then
        for _, child in pairs(folder:GetChildren()) do
            if child:IsA("Model") then table.insert(list, child.Name) end
        end
    end
    return list
end

local function scanBosses()
    local data = {Common = {}, Rare = {}, Epic = {}, Legendary = {}, Secret = {}}
    local bossEvents = ReplicatedStorage:FindFirstChild("Boss Events")
    if bossEvents then
        local bosses = bossEvents:FindFirstChild("Bosses")
        if bosses then
            for _, rarityFolder in pairs(bosses:GetChildren()) do
                if rarityFolder:IsA("Folder") then
                    local list = {}
                    for _, child in pairs(rarityFolder:GetChildren()) do
                        if child:IsA("Model") then
                            table.insert(list, child.Name)
                        end
                    end
                    local name = rarityFolder.Name
                    if data[name] then
                        data[name] = list
                    end
                end
            end
        end
    end
    return data
end

local function getMobFromMobsFolder(name)
    local folder = Workspace:FindFirstChild("Mobs")
    if not folder then return nil end
    local mob = folder:FindFirstChild(name)
    if not mob then
        for _, child in pairs(folder:GetChildren()) do
            if child:IsA("Model") and child.Name:lower() == name:lower() then
                return child
            end
        end
    end
    return mob
end

-- Live current/max HP of a mob by name, read off the real instance in
-- Workspace.Mobs. This game writes the REAL health into the model NAME as a
-- "Health: current/max" suffix and updates it live as the mob takes damage (the
-- Humanoid is frequently just a static 100 cap, so it can't be trusted). Mob
-- models carry decorated names, so match on the stripped name. Returns current,
-- max (max may be nil) or nil when no live instance is present.
local function getCurrentHealthByName(name)
    local mob = getMobFromMobsFolder(name)
    if not mob then
        local folder = Workspace:FindFirstChild("Mobs")
        local target = name and name:lower()
        if folder and target then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    local bare = child.Name
                        :gsub("%s*Health:.*$", "")
                        :gsub("%s*❤.*$", "")
                        :gsub("%s*%(level%s*%d+%)%s*$", "")
                        :gsub("%s+$", "")
                        :lower()
                    if bare == target then mob = child break end
                end
            end
        end
    end
    if not mob then return nil end
    -- 1. The live "Health: cur/max" suffix in the model name (plain ints like
    --    10000000000 and scientific like 5e+28).
    local cur, max = tostring(mob.Name):match("Health:%s*([%d%.eE%+%-]+)%s*/%s*([%d%.eE%+%-]+)")
    local curN, maxN = tonumber(cur), tonumber(max)
    if curN and maxN and maxN > 0 then return curN, maxN end
    -- 2. An Enemy.Health value used by some rigs.
    local enemy = mob:FindFirstChild("Enemy")
    if enemy then
        local health = enemy:FindFirstChild("Health")
        if health and (health:IsA("NumberValue") or health:IsA("IntValue")) then
            return health.Value, nil
        end
    end
    -- 3. Humanoid, last resort.
    local humanoid = mob:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.MaxHealth and humanoid.MaxHealth > 0 then
        return humanoid.Health, humanoid.MaxHealth
    end
    return nil
end

-- Resolve a mob/boss model's EXACT current location instead of its model
-- pivot. GetPivot() returns the pivot origin, which is frequently offset from
-- the body, stale, or sitting at (0,0,0) when the PrimaryPart isn't set. We
-- instead read the real rendered parts, preferring the canonical body part and
-- falling back to the geometric centre of every BasePart in the model.
local function getTargetPosition(model)
    if not model then return nil end

    -- 1. If it's a BasePart itself, that's the exact spot.
    if model:IsA("BasePart") then
        return model.Position
    end

    -- 2. Canonical body parts, in order of preference.
    local priority = {
        "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head", "Root", "RootPart",
    }
    for _, partName in ipairs(priority) do
        local part = model:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            return part.Position
        end
    end

    -- 3. Whatever the humanoid is rooted to, if anything.
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.RootPart then
        return humanoid.RootPart.Position
    end

    -- 4. An explicitly set PrimaryPart.
    if model.PrimaryPart then
        return model.PrimaryPart.Position
    end

    -- 5. True geometric centre of all parts (accurate even for odd rigs).
    local ok, cf = pcall(function() return (model:GetBoundingBox()) end)
    if ok and cf and cf.Position.Magnitude > 0 then
        return cf.Position
    end

    -- 6. Last resort: first BasePart, then the model pivot.
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            return part.Position
        end
    end
    local pivot = model:GetPivot()
    return pivot and pivot.Position or nil
end

-- Backwards-compatible wrapper: existing callers expect a CFrame and read
-- .Position off it, so wrap the exact position in a CFrame.
local function getWorldPivot(model)
    local pos = getTargetPosition(model)
    return pos and CFrame.new(pos) or nil
end

local function findModelInWorkspace(name)
    for _, child in pairs(Workspace:GetDescendants()) do
        if child:IsA("Model") and child.Name == name then
            return child
        end
        if child:IsA("Model") and child.Name:lower() == name:lower() then
            return child
        end
    end
    return nil
end

local function getBossFromStorage(name)
    local bossEvents = ReplicatedStorage:FindFirstChild("Boss Events")
    if not bossEvents then return nil end
    local bosses = bossEvents:FindFirstChild("Bosses")
    if not bosses then return nil end
    for _, rarityFolder in pairs(bosses:GetChildren()) do
        if rarityFolder:IsA("Folder") then
            local boss = rarityFolder:FindFirstChild(name)
            if boss then return boss end
        end
    end
    return nil
end

local function toggleAntiAFK(state)
    antiAFKEnabled = state
    saveData.antiAFK = state
    saveDataToFile()
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
    -- bump the session token; any previously running heartbeat loop will exit
    afkSession = afkSession + 1
    local mySession = afkSession

    if state then
        local function poke()
            pcall(function()
                VirtualUser:CaptureController()
                local cam = workspace.CurrentCamera
                local cf = cam and cam.CFrame or CFrame.new()
                VirtualUser:Button2Down(Vector2.new(0, 0), cf)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), cf)
            end)
        end

        -- Layer 1 (reactive): respond the instant Roblox fires Idled.
        antiAFKConnection = localPlayer.Idled:Connect(poke)

        -- Layer 2 (proactive): the actual fix. Don't wait ~20 min for Idled --
        -- simulate input every 60s so the idle timer is continuously reset and
        -- never reaches the kick threshold, even if one Idled event is missed.
        task.spawn(function()
            while antiAFKEnabled and mySession == afkSession do
                poke()
                for _ = 1, 60 do
                    if not antiAFKEnabled or mySession ~= afkSession then break end
                    task.wait(1)
                end
            end
        end)
    end
end

local mobList = scanMobs()
if #mobList == 0 then
    mobList = {"Goblin", "Skeleton", "Robber", "Knight", "Dragon", "Werewolf"}
end

local isUIVisible = true

-- ============================================================
-- PERMANENT OWNERSHIP FIX - CRITICAL FOR PERSISTENCE
-- ============================================================
local function ensureItemOwned(itemName)
    local repStorage = game:GetService("ReplicatedStorage")
    local armorFolder = repStorage:FindFirstChild("Armor")
    if not armorFolder then return false end
    
    -- Check owned folders
    local ownedFolder = armorFolder:FindFirstChild("Owned")
    if not ownedFolder then
        ownedFolder = Instance.new("Folder")
        ownedFolder.Name = "Owned"
        ownedFolder.Parent = armorFolder
    end
    
    -- Check if already marked owned
    local ownedBool = ownedFolder:FindFirstChild(itemName)
    if ownedBool and ownedBool:IsA("BoolValue") and ownedBool.Value == true then
        return true -- Already owned
    end
    
    -- Create ownership marker
    if ownedBool then
        ownedBool.Value = true
    else
        local newOwned = Instance.new("BoolValue")
        newOwned.Name = itemName
        newOwned.Value = true
        newOwned.Parent = ownedFolder
    end
    
    -- Also check if there's an unlock remote
    local events = repStorage:FindFirstChild("Events")
    if events then
        local unlockRemote = events:FindFirstChild("UnlockItem") or events:FindFirstChild("PurchaseItem") or events:FindFirstChild("GiveItem")
        if unlockRemote and unlockRemote:IsA("RemoteEvent") then
            pcall(function()
                unlockRemote:FireServer(itemName)
            end)
        end
    end
    
    return true
end

-- ============================================================
-- INVENTORY & EQUIP FUNCTIONS
-- ============================================================
local function getPlayerInventory()
	local inv = {}
	local player = localPlayer
	if not player then return inv end
	
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") or child:IsA("HopperBin") then
				table.insert(inv, child.Name)
			end
		end
	end
	
	local char = player.Character
	if char then
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Tool") or child:IsA("HopperBin") then
				table.insert(inv, child.Name)
			end
		end
	end
	
	local starterGear = player:FindFirstChild("StarterGear")
	if starterGear then
		for _, child in ipairs(starterGear:GetChildren()) do
			if child:IsA("Tool") or child:IsA("HopperBin") then
				table.insert(inv, child.Name)
			end
		end
	end
	
	local repStorage = game:GetService("ReplicatedStorage")
	if repStorage then
		local ownedFolder = repStorage:FindFirstChild("OwnedItems") or repStorage:FindFirstChild("ItemsOwned") or repStorage:FindFirstChild("OwnedWeapons") or repStorage:FindFirstChild("WeaponsOwned")
		if ownedFolder then
			for _, child in ipairs(ownedFolder:GetChildren()) do
				if child:IsA("BoolValue") and child.Value == true then
					table.insert(inv, child.Name)
				elseif child:IsA("StringValue") or child:IsA("ObjectValue") then
					table.insert(inv, child.Name)
				end
			end
		end
		
		local armorFolder = repStorage:FindFirstChild("Armor")
		if armorFolder then
			local ownedArmor = armorFolder:FindFirstChild("Owned") or armorFolder:FindFirstChild("OwnedArmor")
			if ownedArmor then
				for _, child in ipairs(ownedArmor:GetChildren()) do
					if child:IsA("BoolValue") and child.Value == true then
						table.insert(inv, child.Name)
					elseif child:IsA("StringValue") or child:IsA("ObjectValue") then
						table.insert(inv, child.Name)
					end
				end
			end
		end
	end
	
	local invSet = {}
	for _, name in ipairs(inv) do
		invSet[name] = true
	end
	local result = {}
	for name in pairs(invSet) do
		table.insert(result, name)
	end
	return result
end

local function getItemsWithOwnership()
	local ownedItems = {}
	local inventory = getPlayerInventory()
	local invSet = {}
	for _, name in ipairs(inventory) do
		invSet[name] = true
	end

	-- Also check persistent ownership markers in ReplicatedStorage
	local repStorage = game:GetService("ReplicatedStorage")

	-- Check Weapons/Owned or similar marker folders
	local markers = {"OwnedWeapons", "WeaponsOwned", "OwnedItems", "ItemsOwned", "Owned"}
	for _, folderName in ipairs(markers) do
		local markerFolder = repStorage:FindFirstChild(folderName)
		if markerFolder then
			for _, child in ipairs(markerFolder:GetChildren()) do
				if child:IsA("BoolValue") and child.Value == true then
					invSet[child.Name] = true
				elseif child:IsA("StringValue") or child:IsA("ObjectValue") then
					invSet[child.Name] = true
				end
			end
		end
	end

	for _, itemName in ipairs(itemList) do
		ownedItems[itemName] = invSet[itemName] or false
	end
	return ownedItems
end

-- ============================================================
-- GET ARMOR OWNERSHIP - SCANS PLAYER'S INVENTORY AND PERSISTENT STORAGE
-- ============================================================
local function getArmorOwnership()
	local ownedArmor = {}
	local inventory = getPlayerInventory()
	local invSet = {}
	for _, name in ipairs(inventory) do
		invSet[name] = true
	end
	
	-- Check persistent ownership marker
	local repStorage = game:GetService("ReplicatedStorage")
	local armorFolder = repStorage:FindFirstChild("Armor")
	local ownedFolder = armorFolder and armorFolder:FindFirstChild("Owned")
	local persistentSet = {}
	if ownedFolder then
		for _, child in ipairs(ownedFolder:GetChildren()) do
			if child:IsA("BoolValue") and child.Value == true then
				persistentSet[child.Name] = true
			end
		end
	end
	
	-- Combine: owned if in inventory OR persistent marker exists
	for _, armorName in ipairs(armorList) do
		ownedArmor[armorName] = invSet[armorName] or persistentSet[armorName] or false
	end
	
	return ownedArmor
end

-- ============================================================
-- GET TOOLINFO REMOTE EVENT - USING THE CORRECT SYSTEM
-- ============================================================
local function getToolInfoRemote()
	local repStorage = game:GetService("ReplicatedStorage")
	local events = repStorage:WaitForChild("Events", 5)
	if events then
		local toolInfo = events:WaitForChild("ToolInfo", 5)
		if toolInfo then
			return toolInfo
		end
	end
	return nil
end

-- ============================================================
-- GET ITEM FUNCTIONALITY - REQUIRED FOR PROPER EQUIPPING
-- ============================================================
local function getItemFunctionality()
	local repFirst = game:GetService("ReplicatedFirst")
	local itemFunc = repFirst:FindFirstChild("ItemFunctionality")
	if itemFunc then
		return itemFunc
	end
	return nil
end

-- ============================================================
-- EQUIP ITEM - NO CLONE FOR WEAPONS, CLONE ONLY FOR ARMOR/HELMETS
-- ============================================================
local function equipItem(itemName)
    local player = localPlayer
    if not player then
        return false, "Player not found"
    end

    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    if not humanoid then
        return false, "Humanoid not found"
    end

    -- Check if already equipped in character
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") or child:IsA("HopperBin") then
            if child.Name == itemName then
                return true, "Already equipped"
            end
        end
    end

    -- If the tool is already in the player's Backpack, just equip it directly.
    -- This covers weapons that aren't registered under ReplicatedStorage.Weapons
    -- (e.g. Knife/Compass/Staff), and cleanly SWITCHES from whatever is held.
    do
        local backpack = player:FindFirstChild("Backpack")
        local existing = backpack and backpack:FindFirstChild(itemName)
        if existing and (existing:IsA("Tool") or existing:IsA("HopperBin")) then
            pcall(function() humanoid:UnequipTools() end)
            local ok = pcall(function() humanoid:EquipTool(existing) end)
            if ok then return true, "Equipped from backpack" end
        end
    end

    local repStorage = game:GetService("ReplicatedStorage")

    -- Check if it's a weapon (in ReplicatedStorage.Weapons)
    local weaponsFolder = repStorage:FindFirstChild("Weapons")
    local isWeapon = false
    if weaponsFolder and weaponsFolder:FindFirstChild(itemName) then
        isWeapon = true
    end

    -- Check if it's armor/helmet (in ReplicatedStorage.Armor)
    local armorFolder = repStorage:FindFirstChild("Armor")
    local isArmor = false
    if armorFolder then
        local helmets = armorFolder:FindFirstChild("Helmets")
        local bodyArmor = armorFolder:FindFirstChild("BodyArmor")
        if (helmets and helmets:FindFirstChild(itemName)) or (bodyArmor and bodyArmor:FindFirstChild(itemName)) then
            isArmor = true
        end
    end

    if isWeapon then
        -- For weapons: check if already in Backpack, if not we can't equip without cloning
        -- Try to find it in Backpack first
        local backpack = player:FindFirstChild("Backpack")
        local tool = backpack and backpack:FindFirstChild(itemName)

        if tool and (tool:IsA("Tool") or tool:IsA("HopperBin")) then
            local success, err = pcall(function()
                humanoid:EquipTool(tool)
            end)
            if success then
                return true, "Equipped via EquipTool"
            end
            print("EquipTool error:", err)
        else
            -- Weapon not in Backpack - can't equip without cloning
            return false, "Weapon not in Backpack"
        end

    elseif isArmor then
        -- For armor/helmets: clone to Backpack then equip
        local template = nil
        if armorFolder then
            local helmets = armorFolder:FindFirstChild("Helmets")
            if helmets then template = helmets:FindFirstChild(itemName) end
            if not template then
                local bodyArmor = armorFolder:FindFirstChild("BodyArmor")
                if bodyArmor then template = bodyArmor:FindFirstChild(itemName) end
            end
        end

        if not template then
            return false, "Armor template not found"
        end

        local backpack = player:FindFirstChild("Backpack")
        local tool = template:Clone()
        pcall(function()
            tool.Parent = backpack
        end)

        if tool.Parent ~= backpack then
            pcall(function()
                tool.Parent = player
            end)
        end

        local success, err = pcall(function()
            humanoid:EquipTool(tool)
        end)

        if success then
            return true, "Equipped via EquipTool"
        end
        print("EquipTool error:", err)
        return false, "Equip failed"

    else
        return false, "Item not found in Weapons or Armor"
    end
end

-- ============================================================
-- EQUIP ALL ARMOR - WITH RECLONE PREVENTION AND NO GOTO
-- ============================================================
local function equipAllArmor()
    -- HOW ARMOR IS WORN IN THIS GAME (verified against ReplicatedStorage.Library.weararmor):
    -- there is no "equip into StarterGear" step. A piece is WORN by EQUIPPING (holding) its
    -- Tool -- the server sees the held armor tool, calls WearHelmet/WearBodyArmor, applies the
    -- WearArmor* stat bonus + visual, and CONSUMES the tool out of the backpack. StarterGear
    -- only matters as the respawn loadout that refills the backpack. Setting_ArmorPersist is
    -- off in this game, so armor is cleared on every death -- which is why this runs on the
    -- toggle's 2s loop: it re-wears whatever the respawn put back into the backpack.
    --
    -- The previous implementation treated "name present in StarterGear" as "already equipped"
    -- and skipped it, and cloned from Armor.Helmets/BodyArmor (which hold VISUAL meshes, not
    -- Tools) -- so with a full StarterGear it equipped literally nothing. This version just
    -- equips every armor Tool actually sitting in the backpack. Worn pieces are already gone
    -- from the backpack, so they self-skip; only unworn (freshly respawned) pieces get worn.
    local player = localPlayer
    if not player then return false, "Player not found" end

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not humanoid or humanoid.Health <= 0 then
        return false, "Character not ready"
    end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return false, "No backpack" end

    -- Authoritative "is this armor?" test: the exact ArmorDataStorage the server's
    -- WearHelmet/WearBodyArmor validate against. Non-nil => it's a wearable armor piece.
    local okData, ArmorData = pcall(require, game:GetService("ReplicatedStorage").Library.ArmorDataStorage)
    local function isArmor(name)
        if okData and ArmorData and ArmorData.GetArmorData then
            return ArmorData.GetArmorData(name) ~= nil
        end
        -- Fallback to the script's own armor name list if the module is unavailable.
        for _, n in ipairs(armorList) do if n == name then return true end end
        return false
    end

    -- Remember the weapon the player is holding: wearing armor briefly holds each piece and
    -- the server then unequips it, which would otherwise leave the player empty-handed.
    local heldBefore
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") or c:IsA("HopperBin") then heldBefore = c break end
    end

    -- GetChildren() is a snapshot, so equipping tools out of the backpack mid-loop is safe.
    local equippedCount = 0
    for _, tool in ipairs(backpack:GetChildren()) do
        if (tool:IsA("Tool") or tool:IsA("HopperBin")) and isArmor(tool.Name) then
            pcall(function() humanoid:EquipTool(tool) end)
            equippedCount = equippedCount + 1
            task.wait(0.12)  -- let the server absorb the equip before the next piece
            if statusLabel then
                statusLabel.Text = "Equipping armor: " .. equippedCount .. "..."
            end
        end
    end

    -- Put the player's weapon back if wearing armor knocked it out of their hands.
    if equippedCount > 0 and heldBefore and heldBefore.Parent == backpack then
        pcall(function() humanoid:EquipTool(heldBefore) end)
    end

    if equippedCount > 0 then
        local msg = "Equipped " .. equippedCount .. " armor piece(s)"
        if statusLabel then statusLabel.Text = "\226\156\147 " .. msg end
        return true, msg
    end
    if statusLabel then statusLabel.Text = "All owned armor already worn" end
    return true, "All owned armor already worn"
end

-- ============================================================
-- HELPER FUNCTION: Apply high ZIndex to all GUI objects recursively
-- ============================================================
local function applyHighZIndex(obj, baseZ)
    baseZ = baseZ or 9999
    if obj:IsA("GuiObject") then
        obj.ZIndex = math.max(obj.ZIndex or 0, baseZ)
        for _, child in ipairs(obj:GetChildren()) do
            applyHighZIndex(child, baseZ + 1)
        end
    end
end

-- ============================================================
-- HELPER: Create UICorner with radius
-- ============================================================
local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

-- ============================================================
-- HELPER: Create UIStroke
-- ============================================================
local function addStroke(parent, color, thickness, radius)
    local s = Instance.new("UIStroke")
    s.Color = color or colors.accent
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    if radius then
        s.LineJoinMode = Enum.LineJoinMode.Round
    end
    s.Parent = parent
    return s
end

-- ============================================================
-- HELPER: Create padding
-- ============================================================
local function addPadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 4)
    p.PaddingBottom = UDim.new(0, bottom or 4)
    p.PaddingLeft = UDim.new(0, left or 4)
    p.PaddingRight = UDim.new(0, right or 4)
    p.Parent = parent
    return p
end

-- ============================================================
-- THEME SYSTEM
-- ============================================================
local isDarkTheme = true

local themeColors = {
    dark = {
        background = Color3.fromRGB(10, 10, 18),
        backgroundDark = Color3.fromRGB(6, 6, 12),
        surface = Color3.fromRGB(18, 18, 30),
        surfaceHover = Color3.fromRGB(25, 25, 42),
        accent = Color3.fromRGB(120, 80, 255),
        accentDim = Color3.fromRGB(80, 55, 180),
        text = Color3.fromRGB(255, 255, 255),
        textDim = Color3.fromRGB(180, 180, 200),
        textMuted = Color3.fromRGB(120, 120, 150),
        border = Color3.fromRGB(60, 60, 80),
        borderLight = Color3.fromRGB(40, 40, 60),
        danger = Color3.fromRGB(255, 50, 80),
        success = Color3.fromRGB(0, 255, 150),
        warning = Color3.fromRGB(255, 200, 0),
        shadow = Color3.fromRGB(0, 0, 0),
        dropdown = Color3.fromRGB(14, 14, 24),
        dropdownHover = Color3.fromRGB(30, 30, 50),
        inputBg = Color3.fromRGB(12, 12, 22),
        statusBar = Color3.fromRGB(8, 8, 16),
    },
    light = {
        background = Color3.fromRGB(240, 240, 248),
        backgroundDark = Color3.fromRGB(225, 225, 235),
        surface = Color3.fromRGB(250, 250, 255),
        surfaceHover = Color3.fromRGB(235, 235, 245),
        accent = Color3.fromRGB(120, 80, 255),
        accentDim = Color3.fromRGB(140, 110, 255),
        text = Color3.fromRGB(20, 20, 30),
        textDim = Color3.fromRGB(80, 80, 100),
        textMuted = Color3.fromRGB(140, 140, 160),
        border = Color3.fromRGB(200, 200, 215),
        borderLight = Color3.fromRGB(210, 210, 225),
        danger = Color3.fromRGB(220, 40, 70),
        success = Color3.fromRGB(0, 180, 110),
        warning = Color3.fromRGB(200, 160, 0),
        shadow = Color3.fromRGB(180, 180, 195),
        dropdown = Color3.fromRGB(245, 245, 252),
        dropdownHover = Color3.fromRGB(230, 230, 242),
        inputBg = Color3.fromRGB(248, 248, 255),
        statusBar = Color3.fromRGB(220, 220, 232),
    }
}

local function getTheme()
    return isDarkTheme and themeColors.dark or themeColors.light
end

-- ============================================================
-- BUILD MODERN GUI
-- ============================================================
local existingGui = playerGui:FindFirstChild("SAUCE")
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SAUCE"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent = playerGui

-- Main frame with rounded corners and purple border
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, saveData.windowSize[1], 0, saveData.windowSize[2])
mainFrame.Position = UDim2.new(saveData.windowPos[1], saveData.windowPos[2], saveData.windowPos[3], saveData.windowPos[4])
mainFrame.BackgroundColor3 = getTheme().background
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true  -- sink mouse input so dragging over the window can't rotate the camera
mainFrame.ZIndex = 9999
mainFrame.Parent = screenGui
addCorner(mainFrame, 12)
addStroke(mainFrame, colors.accent, 2, true)

-- Shadow effect behind main frame
local shadowFrame = Instance.new("ImageLabel")
shadowFrame.Size = UDim2.new(1, 20, 1, 20)
shadowFrame.Position = UDim2.new(0, -10, 0, -10)
shadowFrame.BackgroundTransparency = 1
shadowFrame.Image = "rbxassetid://6015897843"
shadowFrame.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadowFrame.ImageTransparency = 0.6
shadowFrame.ScaleType = Enum.ScaleType.Slice
shadowFrame.SliceCenter = Rect.new(49, 49, 450, 450)
shadowFrame.ZIndex = 9998
shadowFrame.Parent = mainFrame

-- ============================================================
-- TITLE BAR - Clean, minimal
-- ============================================================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = getTheme().backgroundDark
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 10000
titleBar.Parent = mainFrame
addCorner(titleBar, 12)

-- Title text - clean Gotham font
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 200, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SAUCE"
titleLabel.TextColor3 = colors.accent
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextYAlignment = Enum.TextYAlignment.Center
titleLabel.TextScaled = false
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.ZIndex = 10001
titleLabel.Parent = titleBar

-- Subtitle
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(0, 200, 1, 0)
subtitleLabel.Position = UDim2.new(0, 90, 0, 0)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Fight The Monsters: Restored"
subtitleLabel.TextColor3 = getTheme().textMuted
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.TextYAlignment = Enum.TextYAlignment.Center
subtitleLabel.TextScaled = false
subtitleLabel.TextSize = 11
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.ZIndex = 10001
subtitleLabel.Parent = titleBar

-- Title bar buttons - clean flat style
local function makeTitleBtn(text, color, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(1, x, 0, 8)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = colors.text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 14
    b.ZIndex = 10002
    b.Parent = titleBar
    addCorner(b, 6)
    return b
end

local miniModeBtn = makeTitleBtn("◈", Color3.fromRGB(60, 60, 100), -128)
local themeBtn = makeTitleBtn("◐", Color3.fromRGB(60, 60, 100), -96)
local minimizeBtn = makeTitleBtn("\u{2013}", Color3.fromRGB(200, 170, 50), -64)  -- en dash "–"
local closeBtn = makeTitleBtn("\u{00D7}", colors.danger, -32)                    -- multiplication sign "×"

-- ============================================================
-- GLOBAL SEARCH BAR - Top of content area
-- ============================================================
local globalSearchContainer = Instance.new("Frame")
-- Position leaves a 34px slot on the LEFT for the sidebar collapse toggle (built later).
globalSearchContainer.Size = UDim2.new(1, -58, 0, 36)
globalSearchContainer.Position = UDim2.new(0, 48, 0, 50)
globalSearchContainer.BackgroundColor3 = getTheme().inputBg
globalSearchContainer.BorderSizePixel = 0
globalSearchContainer.ZIndex = 10000
globalSearchContainer.Parent = mainFrame
addCorner(globalSearchContainer, 8)
addStroke(globalSearchContainer, getTheme().borderLight, 1, true)

local searchIcon = Instance.new("TextLabel")
searchIcon.Size = UDim2.new(0, 30, 1, 0)
searchIcon.Position = UDim2.new(0, 4, 0, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Text = "🔍"
searchIcon.TextColor3 = getTheme().textMuted
searchIcon.TextSize = 16
searchIcon.Font = Enum.Font.GothamMedium
searchIcon.ZIndex = 10001
searchIcon.Parent = globalSearchContainer

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -40, 1, 0)
searchBox.Position = UDim2.new(0, 30, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.Text = ""
searchBox.PlaceholderText = "Search across all tabs..."
searchBox.PlaceholderColor3 = getTheme().textMuted
searchBox.TextColor3 = getTheme().text
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 13
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 10001
searchBox.Parent = globalSearchContainer

-- ============================================================
-- CONTENT CONTAINER - Below search bar
-- ============================================================
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -90)
contentContainer.Position = UDim2.new(0, 0, 0, 90)
contentContainer.BackgroundTransparency = 1
contentContainer.ZIndex = 9999
contentContainer.Parent = mainFrame

-- ============================================================
-- SIDEBAR - Collapsible groups, no emojis
-- ============================================================
local sideContainer = Instance.new("Frame")
sideContainer.Size = UDim2.new(0, saveData.sidebarWidth, 1, -44)
sideContainer.Position = UDim2.new(0, 0, 0, 0)
sideContainer.BackgroundColor3 = getTheme().backgroundDark
sideContainer.BorderSizePixel = 0
sideContainer.ZIndex = 10000
sideContainer.Parent = contentContainer
addCorner(sideContainer, 0)

-- Sidebar scroll for overflow
local sideScroll = Instance.new("ScrollingFrame")
sideScroll.Size = UDim2.new(1, 0, 1, 0)
sideScroll.BackgroundTransparency = 1
sideScroll.ScrollBarThickness = 3
sideScroll.ScrollBarImageColor3 = colors.accent
sideScroll.BorderSizePixel = 0
sideScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
sideScroll.ZIndex = 10001
sideScroll.Parent = sideContainer

local sideLayout = Instance.new("UIListLayout")
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0, 6)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center  -- even gap on both sides
sideLayout.Parent = sideScroll

-- {internalId, displayLabel?} - label defaults to the id when omitted.
-- Item/Armor keep their internal id (used in logic checks) but show a pluralised label.
local sideTabs = {
    {"Farm"},
    {"Bosses"},
    {"Quest", "Quests"},
    {"NPC", "NPCs"},
    {"Item", "Items"},
    {"Armor", "Armors"},
    {"Shops"},
    {"Bone", "Bone World"},
    {"Config"}
}

-- Maps a tab's internal id to its display label (for status-bar text, etc.)
local tabLabels = {}
for _, t in ipairs(sideTabs) do tabLabels[t[1]] = t[2] or t[1] end

local sideButtons = {}
local currentTab = saveData.currentTab or "Farm"
-- The Mobs tab was removed; a session saved on it falls back to Farm.
if currentTab == "Mobs" then currentTab = "Farm" end
local currentBossTab = saveData.currentBossTab or "Common"
local currentType = "Mob"

for i, tab in ipairs(sideTabs) do
    local label = tab[2] or tab[1]
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 36)
    btn.BackgroundColor3 = getTheme().surface
    -- Inactive tabs are fully flat (transparent) so the rail reads as a clean list
    -- instead of a stack of gray boxes; setSideTabActive fills the active one.
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = getTheme().textDim
    btn.TextScaled = false
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Center
    btn.TextYAlignment = Enum.TextYAlignment.Center
    btn.ZIndex = 10001
    btn.LayoutOrder = i
    btn.Name = tab[1]
    btn.Parent = sideScroll
    addCorner(btn, 8)
    addPadding(btn, 0, 0, 6, 6)

    -- Subtle hover feedback on inactive tabs only (the active one keeps its fill).
    btn.MouseEnter:Connect(function()
        if currentTab ~= btn.Name then btn.BackgroundTransparency = 0.88 end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= btn.Name then btn.BackgroundTransparency = 1 end
    end)

    table.insert(sideButtons, {btn = btn, name = tab[1], label = label})
end

-- Evenly size the tabs to fill the sidebar's height. If there are too many to
-- fit at a comfortable minimum height, they lock to that height and the sidebar
-- scrolls instead (so more tabs can be added later without breaking the layout).
local SIDE_TAB_MIN_H = 40
local function layoutSideTabs()
    local n = #sideButtons
    if n == 0 then return end
    local gap = sideLayout.Padding.Offset
    -- Sidebar height = mainFrame height minus title area (90) and status bar (44).
    local avail = mainFrame.Size.Y.Offset - 90 - 44
    if avail < SIDE_TAB_MIN_H then avail = SIDE_TAB_MIN_H end
    local idealH = (avail - gap * (n - 1)) / n
    local tabH, canvasH
    if idealH >= SIDE_TAB_MIN_H then
        tabH = math.floor(idealH)   -- fits: stretch to fill, no scrollbar
        canvasH = avail
    else
        tabH = SIDE_TAB_MIN_H       -- overflow: fixed height, enable scrolling
        canvasH = n * SIDE_TAB_MIN_H + gap * (n - 1)
    end
    for _, t in ipairs(sideButtons) do
        t.btn.Size = UDim2.new(1, -8, 0, tabH)
    end
    sideScroll.CanvasSize = UDim2.new(0, 0, 0, canvasH)
end
layoutSideTabs()

-- Sidebar resize handle (purple accent bar)
local sideHandle = Instance.new("Frame")
sideHandle.Size = UDim2.new(0, 4, 1, -20)
sideHandle.Position = UDim2.new(1, -4, 0, 10)
sideHandle.BackgroundColor3 = colors.accent
sideHandle.BackgroundTransparency = 0.4
sideHandle.BorderSizePixel = 0
sideHandle.Active = true  -- sink input so sidebar-resize drag doesn't twist the camera
sideHandle.ZIndex = 10010
sideHandle.Parent = sideContainer
addCorner(sideHandle, 2)

-- ============================================================
-- CONTENT AREA - Right side
-- ============================================================
-- Universal per-tab scroll: contentArea is a ScrollingFrame whose canvas auto-
-- grows to hug the furthest-down visible child. Any tab that gains a new control
-- (or opens a dropdown taller than the window) becomes scrollable instead of
-- clipping. Its viewport is sized in updateLayout so a tab that already fits
-- shows no scrollbar.
local contentArea = Instance.new("ScrollingFrame")
contentArea.Size = UDim2.new(1, -(saveData.sidebarWidth + 15), 1, 0)
contentArea.Position = UDim2.new(0, saveData.sidebarWidth + 5, 0, 0)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
contentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentArea.ScrollingDirection = Enum.ScrollingDirection.Y
contentArea.ScrollBarThickness = 5
contentArea.ScrollBarImageColor3 = colors.accent
contentArea.ScrollBarImageTransparency = 0.2
contentArea.ClipsDescendants = true
contentArea.ZIndex = 9999
contentArea.Parent = contentContainer

-- ============================================================
-- FARM TAB SCROLL - stacks the status panel, auto-farm toggle, and auto-equip
-- weapon control in a single scrollable column so every control stays reachable
-- even on a short window. Only shown on the Farm tab.
-- ============================================================
local farmScroll = Instance.new("ScrollingFrame")
farmScroll.Name = "FarmScroll"
farmScroll.BackgroundTransparency = 1
farmScroll.BorderSizePixel = 0
farmScroll.ScrollBarThickness = 5
farmScroll.ScrollBarImageColor3 = colors.accent
farmScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
farmScroll.ScrollingDirection = Enum.ScrollingDirection.Y
farmScroll.Visible = false
farmScroll.ZIndex = 9999
farmScroll.Parent = contentArea

do
    local farmScrollLayout = Instance.new("UIListLayout")
    farmScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    farmScrollLayout.Padding = UDim.new(0, 8)
    farmScrollLayout.Parent = farmScroll
    farmScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        farmScroll.CanvasSize = UDim2.new(0, 0, 0, farmScrollLayout.AbsoluteContentSize.Y + 80)
    end)
end

-- ============================================================
-- BOSS RARITY TABS - Clean pill buttons
-- ============================================================
local bossTabContainer = Instance.new("Frame")
bossTabContainer.Size = UDim2.new(1, -10, 0, 34)
bossTabContainer.Position = UDim2.new(0, 5, 0, 0)
bossTabContainer.BackgroundColor3 = getTheme().surface
bossTabContainer.BorderSizePixel = 0
bossTabContainer.Visible = false
bossTabContainer.ZIndex = 10000
bossTabContainer.Parent = contentArea
addCorner(bossTabContainer, 8)

local bossRarities = {"Common", "Rare", "Epic", "Legendary", "Secret"}
local bossTabBtns = {}

local bossTabLayout = Instance.new("UIListLayout")
bossTabLayout.FillDirection = Enum.FillDirection.Horizontal
bossTabLayout.SortOrder = Enum.SortOrder.LayoutOrder
bossTabLayout.Padding = UDim.new(0, 6)
bossTabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
bossTabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
-- Fill = every tab grows to an equal width and the row spans the whole bar
pcall(function() bossTabLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill end)
bossTabLayout.Parent = bossTabContainer

addPadding(bossTabContainer, 3, 3, 4, 4)

for i, rarity in ipairs(bossRarities) do
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = getTheme().surface
    btn.BorderSizePixel = 0
    btn.Text = rarity
    btn.TextColor3 = getTheme().textDim
    btn.TextScaled = false
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.ZIndex = 10001
    btn.LayoutOrder = i
    btn.Parent = bossTabContainer
    addCorner(btn, 6)
    -- equal-width tabs: zero base width + HorizontalFlex.Fill spreads them evenly.
    -- Scale fallback keeps them evenly sized on clients without UIFlex support.
    btn.Size = UDim2.new(1 / #bossRarities, -8, 1, -6)
    btn.TextXAlignment = Enum.TextXAlignment.Center

    table.insert(bossTabBtns, {btn = btn, name = rarity})
end

-- ============================================================
-- DROPDOWN SELECTOR - Modern dropdown instead of scrolling list
-- ============================================================
local dropdownContainer = Instance.new("Frame")
dropdownContainer.Size = UDim2.new(1, -10, 0, 36)
dropdownContainer.Position = UDim2.new(0, 5, 0, 40)
dropdownContainer.BackgroundColor3 = getTheme().inputBg
dropdownContainer.BorderSizePixel = 0
dropdownContainer.ZIndex = 10000
dropdownContainer.Parent = contentArea
addCorner(dropdownContainer, 8)
addStroke(dropdownContainer, getTheme().borderLight, 1, true)

local dropdownLabel = Instance.new("TextLabel")
dropdownLabel.Size = UDim2.new(1, -30, 1, 0)
dropdownLabel.Position = UDim2.new(0, 12, 0, 0)
dropdownLabel.BackgroundTransparency = 1
dropdownLabel.Text = "Select an item..."
dropdownLabel.TextColor3 = getTheme().textDim
dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
dropdownLabel.TextSize = 13
dropdownLabel.Font = Enum.Font.Gotham
dropdownLabel.ZIndex = 10001
dropdownLabel.Parent = dropdownContainer

local dropdownArrow = Instance.new("TextLabel")
dropdownArrow.Size = UDim2.new(0, 24, 1, 0)
dropdownArrow.Position = UDim2.new(1, -28, 0, 0)
dropdownArrow.BackgroundTransparency = 1
dropdownArrow.Text = "▾"
dropdownArrow.TextColor3 = getTheme().textMuted
dropdownArrow.TextSize = 14
dropdownArrow.Font = Enum.Font.GothamMedium
dropdownArrow.ZIndex = 10001
dropdownArrow.Parent = dropdownContainer

local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(1, 0, 1, 0)
dropdownBtn.BackgroundTransparency = 1
dropdownBtn.Text = ""
dropdownBtn.ZIndex = 10002
dropdownBtn.Parent = dropdownContainer

-- Dropdown popup list (appears below the dropdown selector)
local dropdown = Instance.new("ScrollingFrame")
dropdown.Size = UDim2.new(0, 0, 0, 0)
dropdown.Position = UDim2.new(0, 5, 0, 77)
dropdown.BackgroundColor3 = getTheme().dropdown
dropdown.BorderSizePixel = 0
dropdown.ScrollBarThickness = 4
dropdown.ScrollBarImageColor3 = colors.accent
dropdown.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdown.ClipsDescendants = true
dropdown.ZIndex = 10005  -- above InfoPanel (10000/10001) so the open popup fully covers it
dropdown.Visible = false
dropdown.Parent = contentArea
addCorner(dropdown, 8)
addStroke(dropdown, getTheme().border, 1, true)

-- Dropdown search bar. Lives INSIDE the popup list as its first layout item so
-- it scrolls away with the list instead of staying pinned to the top.
local dropdownSearchContainer = Instance.new("Frame")
dropdownSearchContainer.Size = UDim2.new(1, -8, 0, 30)
dropdownSearchContainer.BackgroundColor3 = getTheme().inputBg
dropdownSearchContainer.BorderSizePixel = 0
dropdownSearchContainer.ZIndex = 10008
dropdownSearchContainer.LayoutOrder = -100  -- sorts above every mob row (rowY >= 0)
dropdownSearchContainer.Visible = false
dropdownSearchContainer.Parent = dropdown
addCorner(dropdownSearchContainer, 6)
addStroke(dropdownSearchContainer, getTheme().borderLight, 1, true)

-- Keep the search bar shown/hidden in lockstep with the popup, and re-run the
-- pinning layout each time it opens (its position depends on the popup width).
dropdown:GetPropertyChangedSignal("Visible"):Connect(function()
    layoutDropdownSearch()
end)

local dropdownSearchIcon = Instance.new("TextLabel")
dropdownSearchIcon.Size = UDim2.new(0, 24, 1, 0)
dropdownSearchIcon.Position = UDim2.new(0, 4, 0, 0)
dropdownSearchIcon.BackgroundTransparency = 1
dropdownSearchIcon.Text = "🔍"
dropdownSearchIcon.TextColor3 = getTheme().textMuted
dropdownSearchIcon.TextSize = 12
dropdownSearchIcon.Font = Enum.Font.GothamMedium
dropdownSearchIcon.ZIndex = 10009
dropdownSearchIcon.Parent = dropdownSearchContainer

local dropdownSearchBox = Instance.new("TextBox")
dropdownSearchBox.Size = UDim2.new(1, -30, 1, 0)
dropdownSearchBox.Position = UDim2.new(0, 26, 0, 0)
dropdownSearchBox.BackgroundTransparency = 1
dropdownSearchBox.Text = ""
dropdownSearchBox.PlaceholderText = "Filter items..."
dropdownSearchBox.PlaceholderColor3 = getTheme().textMuted
dropdownSearchBox.TextColor3 = getTheme().text
dropdownSearchBox.Font = Enum.Font.Gotham
dropdownSearchBox.TextSize = 12
dropdownSearchBox.TextXAlignment = Enum.TextXAlignment.Left
dropdownSearchBox.ClearTextOnFocus = false
dropdownSearchBox.ZIndex = 10009
dropdownSearchBox.Parent = dropdownSearchContainer

local dropdownListLayout = Instance.new("UIListLayout")
dropdownListLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropdownListLayout.Padding = UDim.new(0, 1)
dropdownListLayout.Parent = dropdown

local dropdownPad = addPadding(dropdown, 4, 4, 4, 4)

-- Transparent scroll spacer. The overlay popup floats at a fixed canvas Y, so on
-- its own it only extends the outer contentArea canvas to its own bottom. This
-- invisible child sits ~60px BELOW the open popup, forcing the universal scroll
-- to always leave room to scroll the whole tab down past the dropdown. It
-- collapses to zero height while the popup is closed (no resting scrollbar).
-- Built in a do-block + found via signals so it costs no main-chunk register.
do
    local sp = Instance.new("Frame")
    sp.Name = "DropdownScrollSpacer"
    sp.BackgroundTransparency = 1
    sp.BorderSizePixel = 0
    sp.Size = UDim2.new(0, 1, 0, 0)
    sp.Position = UDim2.new(0, 0, 0, 0)
    sp.ZIndex = 1
    sp.Parent = contentArea
    local function syncSpacer()
        -- Only meaningful while the popup floats over contentArea. On the Armor tab
        -- the popup rides inline inside ArmorShopScroll, so the spacer would only
        -- add a stray canvas to contentArea -- collapse it there.
        if dropdown.Visible and dropdown.Parent == contentArea then
            local b = dropdown.Position.Y.Offset + dropdown.Size.Y.Offset + 60
            sp.Position = UDim2.new(0, 0, 0, math.max(0, b - 1))
            sp.Size = UDim2.new(0, 1, 0, 1)
        else
            sp.Position = UDim2.new(0, 0, 0, 0)
            sp.Size = UDim2.new(0, 1, 0, 0)
        end
    end
    dropdown:GetPropertyChangedSignal("Visible"):Connect(syncSpacer)
    dropdown:GetPropertyChangedSignal("Size"):Connect(syncSpacer)
    dropdown:GetPropertyChangedSignal("Position"):Connect(syncSpacer)
end

-- ============================================================
-- DROPDOWN FILTER-BAR PINNING
-- On the Farm tab the mob-select filter bar is pinned to the top of the popup
-- (parented outside the ScrollingFrame) so it stays put while the mob list
-- scrolls underneath it. On every other tab it keeps the original behavior of
-- scrolling away with the list as its first item.
-- ============================================================
function layoutDropdownSearch()
    if currentTab == "Farm" then
        local sw = sideContainer.Size.X.Offset
        local mw = mainFrame.Size.X.Offset
        local cw = mw - sw - 15
        -- Popup sits at X=5, Y=76 with 4px inner padding, so the pinned bar
        -- lands at (9, 80) and spans the popup width minus the padding.
        dropdownSearchContainer.Size = UDim2.new(0, (cw - 10) - 8, 0, 30)
        dropdownSearchContainer.Position = UDim2.new(0, 9, 0, 80)
        dropdownSearchContainer.Parent = contentArea
        -- Push the scrolling rows down so the first one clears the pinned bar.
        dropdownPad.PaddingTop = UDim.new(0, 38)
    else
        dropdownSearchContainer.Size = UDim2.new(1, -8, 0, 30)
        dropdownSearchContainer.LayoutOrder = -100
        dropdownSearchContainer.Parent = dropdown
        dropdownPad.PaddingTop = UDim.new(0, 4)
    end
    dropdownSearchContainer.Visible = dropdown.Visible
end

-- ============================================================
-- CONFIG CONTAINER - Clean card layout
-- ============================================================
local configContainer = Instance.new("Frame")
configContainer.Size = UDim2.new(0, 0, 0, 0)
configContainer.Position = UDim2.new(0, 5, 0, 40)
configContainer.BackgroundColor3 = getTheme().surface
configContainer.BorderSizePixel = 0
configContainer.Visible = false
configContainer.ZIndex = 10000
configContainer.Parent = contentArea
addCorner(configContainer, 8)
addStroke(configContainer, getTheme().borderLight, 1, true)

-- ============================================================
-- QUEST TAB - Auto quest panel (Daily / Weekly / Monthly)
-- Built inside an immediately-invoked closure so all of its many Instance
-- locals live in THIS function's own register budget, not the main chunk's
-- 200-local ceiling. Everything is reached later by name (contentArea ->
-- "QuestContainer" -> children), exactly like configContainer's own controls.
-- The coordinator loop near the end of the file reads the game's quest state
-- and writes the status labels + drives auto-accept / auto-farm.
-- ============================================================
;(function()
    local qc = Instance.new("Frame")
    qc.Name = "QuestContainer"
    qc.Size = UDim2.new(0, 0, 0, 0)
    qc.Position = UDim2.new(0, 5, 0, 4)
    qc.BackgroundColor3 = getTheme().surface
    qc.BorderSizePixel = 0
    qc.Visible = false
    qc.ZIndex = 10000
    qc.Parent = contentArea
    addCorner(qc, 8)
    addStroke(qc, getTheme().borderLight, 1, true)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -28, 0, 26)
    title.Position = UDim2.new(0, 16, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "AUTO QUEST"
    title.TextColor3 = colors.accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 10001
    title.Parent = qc

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -28, 0, 30)
    sub.Position = UDim2.new(0, 16, 0, 38)
    sub.BackgroundTransparency = 1
    sub.Text = "Accepts, turns in and farms Daily / Weekly / Monthly bounties automatically."
    sub.TextColor3 = getTheme().textDim
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.TextWrapped = true
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextYAlignment = Enum.TextYAlignment.Top
    sub.ZIndex = 10001
    sub.Parent = qc

    -- Sliding on/off switch bound to a saveData flag. Reused for all three rows.
    local function makeToggleRow(y, labelText, descText, flagKey)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -80, 0, 20)
        lbl.Position = UDim2.new(0, 16, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = getTheme().text
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 10001
        lbl.Parent = qc

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -80, 0, 16)
        desc.Position = UDim2.new(0, 16, 0, y + 19)
        desc.BackgroundTransparency = 1
        desc.Text = descText
        desc.TextColor3 = getTheme().textDim
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.ZIndex = 10001
        desc.Parent = qc

        local on = saveData[flagKey] == true
        local track = Instance.new("TextButton")
        track.Size = UDim2.new(0, 46, 0, 24)
        track.Position = UDim2.new(1, -20, 0, y + 12)
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.BackgroundColor3 = on and colors.success or colors.danger
        track.BorderSizePixel = 0
        track.Text = ""
        track.AutoButtonColor = false
        track.ZIndex = 10002
        track.Parent = qc
        addCorner(track, 12)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.Position = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        knob.BackgroundColor3 = colors.text
        knob.BorderSizePixel = 0
        knob.ZIndex = 10003
        knob.Parent = track
        addCorner(knob, 9)

        track.MouseButton1Click:Connect(function()
            local nv = not (saveData[flagKey] == true)
            saveData[flagKey] = nv
            saveDataToFile()
            track.BackgroundColor3 = nv and colors.success or colors.danger
            local target = nv and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            local ok = pcall(function()
                knob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            end)
            if not ok then knob.Position = target end
        end)
    end

    makeToggleRow(78,  "Auto Accept",  "Grab every available bounty from the Quest Master.", "questAutoAccept")
    makeToggleRow(122, "Auto Turn In", "Flush finished quests and re-pull the next when it unlocks.", "questAutoTurnin")
    makeToggleRow(166, "Auto Farm",    "Point the farm engine at the current quest's kill target.", "questAutoFarm")

    -- Manual "refresh the board" button: fires the Quest Master so the server
    -- (re)generates the Daily/Weekly/Monthly offers into QuestData_Bounties.
    local refresh = Instance.new("TextButton")
    refresh.Name = "QuestRefreshBtn"
    refresh.Size = UDim2.new(1, -32, 0, 32)
    refresh.Position = UDim2.new(0, 16, 0, 212)
    refresh.BackgroundColor3 = colors.accent
    refresh.BorderSizePixel = 0
    refresh.Text = "Refresh Bounty Board"
    refresh.TextColor3 = colors.text
    refresh.Font = Enum.Font.GothamMedium
    refresh.TextSize = 13
    refresh.ZIndex = 10002
    refresh.Parent = qc
    addCorner(refresh, 6)

    local statusHeader = Instance.new("TextLabel")
    statusHeader.Size = UDim2.new(1, -28, 0, 20)
    statusHeader.Position = UDim2.new(0, 16, 0, 252)
    statusHeader.BackgroundTransparency = 1
    statusHeader.Text = "QUEST PROGRESS"
    statusHeader.TextColor3 = colors.accent
    statusHeader.Font = Enum.Font.GothamBold
    statusHeader.TextSize = 12
    statusHeader.TextXAlignment = Enum.TextXAlignment.Left
    statusHeader.ZIndex = 10001
    statusHeader.Parent = qc

    -- Live "what auto-farm is doing right now" line, e.g. "Auto Quest - killing 15 kills".
    local action = Instance.new("TextLabel")
    action.Name = "QuestAction"
    action.Size = UDim2.new(1, -32, 0, 34)
    action.Position = UDim2.new(0, 16, 0, 274)
    action.BackgroundColor3 = getTheme().inputBg
    action.BorderSizePixel = 0
    action.Text = "Auto Farm: idle"
    action.TextColor3 = getTheme().text
    action.Font = Enum.Font.GothamMedium
    action.TextSize = 13
    action.TextXAlignment = Enum.TextXAlignment.Left
    action.TextWrapped = true
    action.ZIndex = 10001
    action.Parent = qc
    addCorner(action, 6)
    addPadding(action, 0, 0, 10, 10)

    -- Per-tier progress readout. Scrolls if the three tiers' task lists overflow.
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "QuestStatusScroll"
    scroll.Position = UDim2.new(0, 16, 0, 316)
    scroll.Size = UDim2.new(1, -32, 1, -328)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = colors.accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.ZIndex = 10001
    scroll.Parent = qc

    local status = Instance.new("TextLabel")
    status.Name = "QuestStatus"
    status.Size = UDim2.new(1, -6, 0, 0)
    status.AutomaticSize = Enum.AutomaticSize.Y
    status.Position = UDim2.new(0, 0, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = "No active quests. Turn on Auto Accept (or hit Refresh Bounty Board) to begin."
    status.TextColor3 = getTheme().textDim
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.RichText = true
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.ZIndex = 10001
    status.Parent = scroll

    refresh.MouseButton1Click:Connect(function()
        local qg = Workspace:FindFirstChild("QuestGivers")
        local npc = qg and qg:FindFirstChild("~Quest Master~")
        local torso = npc and (npc:FindFirstChild("Torso") or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head"))
        local prompt = torso and torso:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            pcall(function() fireproximityprompt(prompt) end)
            action.Text = "Refreshed bounty board from the Quest Master."
        else
            action.Text = "Could not find the Quest Master NPC to refresh."
        end
    end)
end)()

-- Walk Speed - clean row
local walkLabel = Instance.new("TextLabel")
walkLabel.Size = UDim2.new(0, 150, 0, 32)
walkLabel.Position = UDim2.new(0, 18, 0, 30)
walkLabel.AnchorPoint = Vector2.new(0, 0.5)
walkLabel.BackgroundTransparency = 1
walkLabel.Text = "Walk Speed"
walkLabel.TextColor3 = getTheme().text
walkLabel.TextScaled = false
walkLabel.TextSize = 13
walkLabel.Font = Enum.Font.GothamMedium
walkLabel.TextXAlignment = Enum.TextXAlignment.Left
walkLabel.TextYAlignment = Enum.TextYAlignment.Center
walkLabel.ZIndex = 10001
walkLabel.Parent = configContainer

local walkInput = Instance.new("TextBox")
walkInput.Size = UDim2.new(0, 92, 0, 32)
walkInput.Position = UDim2.new(1, -96, 0, 30)
walkInput.AnchorPoint = Vector2.new(1, 0.5)
walkInput.BackgroundColor3 = getTheme().inputBg
walkInput.BorderSizePixel = 0
walkInput.Text = tostring(saveData.walkSpeed)
walkInput.TextColor3 = getTheme().text
walkInput.Font = Enum.Font.Gotham
walkInput.TextSize = 13
walkInput.ZIndex = 10001
walkInput.Parent = configContainer
addCorner(walkInput, 6)
addStroke(walkInput, colors.accent, 1, true)

-- Walk Speed override switch (iOS pill) in place of the old SET button.
-- ON applies the entered value (and re-applies on respawn); OFF reverts to
-- the Roblox default. Wrapped in a do-block below with the Jump switch so
-- their locals stay out of the main chunk's 200-local budget.

-- Jump Power - clean row
local jumpLabel = Instance.new("TextLabel")
jumpLabel.Size = UDim2.new(0, 150, 0, 32)
jumpLabel.Position = UDim2.new(0, 18, 0, 74)
jumpLabel.AnchorPoint = Vector2.new(0, 0.5)
jumpLabel.BackgroundTransparency = 1
jumpLabel.Text = "Jump Power"
jumpLabel.TextColor3 = getTheme().text
jumpLabel.TextScaled = false
jumpLabel.TextSize = 13
jumpLabel.Font = Enum.Font.GothamMedium
jumpLabel.TextXAlignment = Enum.TextXAlignment.Left
jumpLabel.TextYAlignment = Enum.TextYAlignment.Center
jumpLabel.ZIndex = 10001
jumpLabel.Parent = configContainer

local jumpInput = Instance.new("TextBox")
jumpInput.Size = UDim2.new(0, 92, 0, 32)
jumpInput.Position = UDim2.new(1, -96, 0, 74)
jumpInput.AnchorPoint = Vector2.new(1, 0.5)
jumpInput.BackgroundColor3 = getTheme().inputBg
jumpInput.BorderSizePixel = 0
jumpInput.Text = tostring(saveData.jumpPower)
jumpInput.TextColor3 = getTheme().text
jumpInput.Font = Enum.Font.Gotham
jumpInput.TextSize = 13
jumpInput.ZIndex = 10001
jumpInput.Parent = configContainer
addCorner(jumpInput, 6)
addStroke(jumpInput, colors.accent, 1, true)

-- Jump Power override switch (iOS pill) -- see the do-block just below for both.

-- ============================================================
-- WALK SPEED / JUMP POWER override switches
-- Replaces the old "SET" buttons with iOS sliders (same style as the Anti-AFK
-- switch). ON applies the value from the adjacent TextBox and re-applies it on
-- every respawn; OFF restores the Roblox humanoid default. All locals live in
-- this do-block so they never touch the main chunk's 200-local ceiling.
-- ============================================================
do
    local DEFAULT_WALK, DEFAULT_JUMP = 16, 50

    local function makeSwitch(yOff, initOn)
        local track = Instance.new("TextButton")
        track.Size = UDim2.new(0, 46, 0, 24)
        track.Position = UDim2.new(1, -27, 0, yOff)
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.BackgroundColor3 = initOn and colors.success or colors.danger
        track.BorderSizePixel = 0
        track.Text = ""
        track.AutoButtonColor = false
        track.ZIndex = 10002
        track.Parent = configContainer
        addCorner(track, 12)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.Position = initOn and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        knob.BackgroundColor3 = colors.text
        knob.BorderSizePixel = 0
        knob.ZIndex = 10003
        knob.Parent = track
        addCorner(knob, 9)
        local function setVisual(on)
            local target = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            track.BackgroundColor3 = on and colors.success or colors.danger
            local ok = pcall(function()
                knob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            end)
            if not ok then knob.Position = target end
        end
        return track, setVisual
    end

    local walkSwitch, setWalkVisual = makeSwitch(30, saveData.walkEnabled)
    local jumpSwitch, setJumpVisual = makeSwitch(74, saveData.jumpEnabled)

    local function getHumanoid()
        local char = localPlayer.Character
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    -- Push the saved walk/jump values onto the humanoid when their switch is ON.
    local function applyWalk()
        local h = getHumanoid()
        if h then h.WalkSpeed = saveData.walkEnabled and saveData.walkSpeed or DEFAULT_WALK end
    end
    local function applyJump()
        local h = getHumanoid()
        if h then h.JumpPower = saveData.jumpEnabled and saveData.jumpPower or DEFAULT_JUMP end
    end

    walkSwitch.MouseButton1Click:Connect(function()
        saveData.walkEnabled = not saveData.walkEnabled
        if saveData.walkEnabled then
            local v = tonumber(walkInput.Text)
            if v then saveData.walkSpeed = v end
            walkInput.Text = tostring(saveData.walkSpeed)
        end
        setWalkVisual(saveData.walkEnabled)
        applyWalk()
        saveDataToFile()
    end)

    jumpSwitch.MouseButton1Click:Connect(function()
        saveData.jumpEnabled = not saveData.jumpEnabled
        if saveData.jumpEnabled then
            local v = tonumber(jumpInput.Text)
            if v then saveData.jumpPower = v end
            jumpInput.Text = tostring(saveData.jumpPower)
        end
        setJumpVisual(saveData.jumpEnabled)
        applyJump()
        saveDataToFile()
    end)

    -- Live-edit the value while the switch is ON: re-apply on commit.
    walkInput.FocusLost:Connect(function()
        local v = tonumber(walkInput.Text)
        if v then
            saveData.walkSpeed = v
            if saveData.walkEnabled then applyWalk() end
            saveDataToFile()
        else
            walkInput.Text = tostring(saveData.walkSpeed)
        end
    end)
    jumpInput.FocusLost:Connect(function()
        local v = tonumber(jumpInput.Text)
        if v then
            saveData.jumpPower = v
            if saveData.jumpEnabled then applyJump() end
            saveDataToFile()
        else
            jumpInput.Text = tostring(saveData.jumpPower)
        end
    end)

    -- Re-apply after every respawn so the override "sticks" through death.
    localPlayer.CharacterAdded:Connect(function(char)
        if not (saveData.walkEnabled or saveData.jumpEnabled) then return end
        task.spawn(function()
            char:WaitForChild("Humanoid", 10)
            task.wait(0.5)
            applyWalk()
            applyJump()
        end)
    end)

    -- Apply once now for a session that loaded with either switch already ON.
    if saveData.walkEnabled then applyWalk() end
    if saveData.jumpEnabled then applyJump() end
end

-- Anti-AFK - clean row
local afkLabel = Instance.new("TextLabel")
afkLabel.Size = UDim2.new(0, 150, 0, 32)
afkLabel.Position = UDim2.new(0, 18, 0, 206)
afkLabel.AnchorPoint = Vector2.new(0, 0.5)
afkLabel.BackgroundTransparency = 1
afkLabel.Text = "Anti-AFK"
afkLabel.TextColor3 = getTheme().text
afkLabel.TextScaled = false
afkLabel.TextSize = 13
afkLabel.Font = Enum.Font.GothamMedium
afkLabel.TextXAlignment = Enum.TextXAlignment.Left
afkLabel.TextYAlignment = Enum.TextYAlignment.Center
afkLabel.ZIndex = 10001
afkLabel.Parent = configContainer

local afkStatus = Instance.new("TextLabel")
afkStatus.Size = UDim2.new(0, 92, 0, 32)
afkStatus.Position = UDim2.new(1, -96, 0, 206)
afkStatus.AnchorPoint = Vector2.new(1, 0.5)
afkStatus.BackgroundColor3 = getTheme().inputBg
afkStatus.BorderSizePixel = 0
afkStatus.Text = antiAFKEnabled and "ON" or "OFF"
afkStatus.TextColor3 = antiAFKEnabled and colors.success or colors.danger
afkStatus.TextScaled = false
afkStatus.TextSize = 12
afkStatus.Font = Enum.Font.GothamMedium
afkStatus.ZIndex = 10001
afkStatus.Parent = configContainer
addCorner(afkStatus, 6)

-- Toggle switch (sliding pill) instead of an ON/OFF button.
local afkToggleBtn = Instance.new("TextButton")
afkToggleBtn.Name = "afkSwitchTrack"
afkToggleBtn.Size = UDim2.new(0, 46, 0, 24)
afkToggleBtn.Position = UDim2.new(1, -27, 0, 206)
afkToggleBtn.AnchorPoint = Vector2.new(1, 0.5)
afkToggleBtn.BackgroundColor3 = antiAFKEnabled and colors.success or colors.danger
afkToggleBtn.BorderSizePixel = 0
afkToggleBtn.Text = ""
afkToggleBtn.AutoButtonColor = false
afkToggleBtn.ZIndex = 10002
afkToggleBtn.Parent = configContainer
addCorner(afkToggleBtn, 12)  -- full pill

local afkKnob = Instance.new("Frame")
afkKnob.Name = "afkSwitchKnob"
afkKnob.Size = UDim2.new(0, 18, 0, 18)
afkKnob.AnchorPoint = Vector2.new(0, 0.5)
afkKnob.Position = antiAFKEnabled and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
afkKnob.BackgroundColor3 = colors.text
afkKnob.BorderSizePixel = 0
afkKnob.ZIndex = 10003
afkKnob.Parent = afkToggleBtn
addCorner(afkKnob, 9)  -- circle

-- Slides the knob and recolors the track to match the given state.
local function setAfkSwitchVisual(on)
    local target = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    afkToggleBtn.BackgroundColor3 = on and colors.success or colors.danger
    -- Snap if the knob isn't rendered yet (tween throws off-screen); see farm toggle.
    local ok = pcall(function()
        afkKnob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
    end)
    if not ok then afkKnob.Position = target end
end

-- Keybind row
local keybindLabel = Instance.new("TextLabel")
keybindLabel.Size = UDim2.new(0, 220, 0, 32)
keybindLabel.Position = UDim2.new(0, 18, 0, 162)
keybindLabel.AnchorPoint = Vector2.new(0, 0.5)
keybindLabel.BackgroundTransparency = 1
keybindLabel.Text = "Toggle Key: " .. saveData.toggleKey
keybindLabel.TextColor3 = getTheme().text
keybindLabel.TextScaled = false
keybindLabel.TextSize = 13
keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
keybindLabel.TextYAlignment = Enum.TextYAlignment.Center
keybindLabel.Font = Enum.Font.GothamMedium
keybindLabel.ZIndex = 10001
keybindLabel.Parent = configContainer

local keybindPickerBtn = Instance.new("TextButton")
keybindPickerBtn.Size = UDim2.new(0, 72, 0, 32)
keybindPickerBtn.Position = UDim2.new(1, -14, 0, 162)
keybindPickerBtn.AnchorPoint = Vector2.new(1, 0.5)
keybindPickerBtn.BackgroundColor3 = colors.accent
keybindPickerBtn.BorderSizePixel = 0
keybindPickerBtn.Text = "Change"
keybindPickerBtn.TextColor3 = colors.text
keybindPickerBtn.Font = Enum.Font.GothamMedium
keybindPickerBtn.TextSize = 12
keybindPickerBtn.ZIndex = 10002
keybindPickerBtn.Parent = configContainer
addCorner(keybindPickerBtn, 6)

-- NOTE: The ESP Mobs / Mob ESP Radius config rows are created inside the ESP
-- do-block further down (keeps their locals out of the main chunk's 200-local
-- budget). They still parent into configContainer and appear here in the tab.

local pickingKey = false

-- ============================================================
-- ACTION BUTTONS - Teleport, Refresh, Equip All
-- ============================================================
local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(0, 0, 0, 36)
teleportBtn.Position = UDim2.new(0, 5, 0, 0)
teleportBtn.BackgroundColor3 = colors.accent
teleportBtn.BorderSizePixel = 0
teleportBtn.Text = "TELEPORT"
teleportBtn.TextColor3 = colors.text
teleportBtn.Font = Enum.Font.GothamMedium
teleportBtn.TextSize = 14
teleportBtn.ZIndex = 10000
teleportBtn.Parent = contentArea
addCorner(teleportBtn, 8)

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 0, 0, 36)
refreshBtn.Position = UDim2.new(0, 5, 0, 0)
refreshBtn.BackgroundColor3 = colors.accent
refreshBtn.BorderSizePixel = 0
refreshBtn.Text = "REFRESH"
refreshBtn.TextColor3 = colors.text
refreshBtn.Font = Enum.Font.GothamMedium
refreshBtn.TextSize = 14
refreshBtn.ZIndex = 10000
refreshBtn.Parent = contentArea
addCorner(refreshBtn, 8)

-- ============================================================
-- SHOPS TAB PANEL - buy any weapon / potion / merchant item from
-- ANYWHERE. The game buys via ReplicatedStorage.Events.PurchaseEvent
-- (weapons + potions) and MerchantPurchaseEvent (merchant), both by
-- item-name string; verified there's no server proximity check, so no
-- teleport is needed. Three inline dropdowns, each with a status
-- readout and its own Buy button. Merchant stock is server-pushed only
-- near the (rotating) merchant, so we cache it live via OpenMerchantShop
-- and persist it. Wrapped in a do-block so the ~heavy builder locals
-- free before the main chunk's 200-register ceiling; only layoutShops
-- escapes as a top-level upvalue.
-- ============================================================
local layoutShops
do
    local Events = game:GetService("ReplicatedStorage"):WaitForChild("Events")
    local PurchaseEvent = Events:WaitForChild("PurchaseEvent")
    local MerchantPurchaseEvent = Events:FindFirstChild("MerchantPurchaseEvent")
    local OpenMerchantShop = Events:FindFirstChild("OpenMerchantShop")

    -- WEAPON SHOP DATA (harvested live from every weapon shop). value = the
    -- exact string the game's own buy button fires; cost is display-only.
    local weaponData = {
        {shop="Sword Shop", name="Water Sword", cost="250", value="Water Sword"},
        {shop="Sword Shop", name="Earth Sword", cost="750", value="Earth Sword"},
        {shop="Sword Shop", name="Fire Sword", cost="1250", value="Fire Sword"},
        {shop="Sword Shop", name="Elemental Sword", cost="2500", value="Elemental Sword"},
        {shop="Desert Shop", name="Pumpkin Sword", cost="6K", value="Pumpkin Sword"},
        {shop="Desert Shop", name="Scythe", cost="20K", value="Scythe"},
        {shop="Desert Shop", name="FrostEdge", cost="65K", value="FrostEdge"},
        {shop="Desert Shop", name="Turkeys Revenge", cost="150K", value="Turkeys Revenge"},
        {shop="Swamp Shop", name="Tyson", cost="500K", value="Tyson"},
        {shop="Swamp Shop", name="Goliath", cost="1M", value="Goliath"},
        {shop="Swamp Shop", name="EverFrost", cost="2.5M", value="EverFrost"},
        {shop="Swamp Shop", name="BlackEdge", cost="5M", value="BlackEdge"},
        {shop="Volcano Shop", name="Apple", cost="10M", value="Apple"},
        {shop="Volcano Shop", name="Fade Axe", cost="20M", value="Fade Axe"},
        {shop="Volcano Shop", name="CrimsonWrath", cost="50M", value="CrimsonWrath"},
        {shop="Volcano Shop", name="EggBeater", cost="100M", value="EggBeater"},
        {shop="Snowy Shop", name="AngelsBlessing", cost="5B", value="AngelsBlessing"},
        {shop="Snowy Shop", name="Pumpkin Scythe", cost="10B", value="Pumpkin Scythe"},
        {shop="Snowy Shop", name="Leaves Revenge", cost="25B", value="Leaves Revenge"},
        {shop="Snowy Shop", name="Blackfyre", cost="250B", value="Blackfyre"},
        {shop="Dark Shop", name="BabbitsSword", cost="666B", value="BabbitsSword"},
        {shop="Dark Shop", name="Bat Sword", cost="2.5T", value="Bat Sword"},
        {shop="Dark Shop", name="StarryBlade", cost="7.5T", value="StarryBlade"},
        {shop="Dark Shop", name="Pumpkins Wraith", cost="100T", value="Pumpkins Wraith"},
        {shop="Divine Shop", name="Bone Sword", cost="250T", value="Bone Sword"},
        {shop="Divine Shop", name="Kings Sword", cost="1Qa", value="Kings Sword"},
        {shop="Divine Shop", name="Valkyrie", cost="10Qa", value="Valkyrie"},
        {shop="Divine Shop", name="Immortal Patriot", cost="50Qa", value="Immortal Patriot"},
        {shop="Divine Shop", name="Crimson Terror", cost="2.5Qi", value="Crimson Terror"},
        {shop="Ultimate Shop", name="EastersRevenge", cost="10Qi", value="EastersRevenge"},
        {shop="Ultimate Shop", name="StarryDay", cost="25Qi", value="StarryDay"},
        {shop="Ultimate Shop", name="StarryNight", cost="100Qi", value="StarryNight"},
        {shop="Ultimate Shop", name="Gracious Hope", cost="300Qi", value="Gracious Hope"},
        {shop="Ultimate Shop", name="Serpents Tears", cost="1Sx", value="SerpentsTears"},
        {shop="Ultimate Shop", name="Patriotic Grimaxe", cost="5Sx", value="Patriotic Grimaxe"},
        {shop="Ultimate Shop", name="BLUEBLADE", cost="20Sx", value="BLUEBLADE"},
        {shop="Ultimate Shop", name="Shark", cost="99Sx", value="Shark"},
        {shop="Ultimate Shop", name="USAKNIFE", cost="333Sx", value="USAKNIFE"},
        {shop="Ultimate Shop", name="Pumpkins Tears", cost="1Sp", value="Pumpkins Tears"},
        {shop="Ultimate Shop", name="PatrioticWraith", cost="3Sp", value="PatrioticWraith"},
        {shop="Ultimate Shop", name="EaglesCry", cost="38Sp", value="EaglesCry"},
        {shop="Ultimate Shop", name="Pumpkins Terror", cost="100Sp", value="Pumpkins Terror"},
        {shop="Ultimate Shop", name="LastResort", cost="500Sp", value="LastResort"},
        {shop="Ultimate Shop", name="Whispering Skulls", cost="10Sp", value="Whispering Skulls"},
        {shop="Ultimate Shop", name="BornOfAStar", cost="1Oc", value="BornOfAStar"},
        {shop="Ultimate Shop", name="White Flames", cost="5Oc", value="White Flames"},
        {shop="Ultimate Shop", name="Forsaken Eye", cost="10Oc", value="Forsaken Eye"},
        {shop="Supreme Shop", name="HOTDOGSTICK", cost="100Oc", value="HOTDOGSTICK"},
        {shop="Supreme Shop", name="Starry Sky", cost="1No", value="StarrySky"},
        {shop="Supreme Shop", name="Sword of Stars", cost="4.5No", value="Sword of Stars"},
        {shop="Supreme Shop", name="LIBERTYPRIMESHOPE", cost="10No", value="LIBERTYPRIMESHOPE"},
        {shop="Supreme Shop", name="EverythinginONE", cost="80No", value="EverythinginONE"},
        {shop="Supreme Shop", name="Flagbladeofamerica", cost="250No", value="Flagbladeofamerica"},
        {shop="Supreme Shop", name="LeafyStarBlade", cost="1De", value="LeafyStarBlade"},
        {shop="Supreme Shop", name="LastChance", cost="3.33De", value="LastChance"},
        {shop="Supreme Shop", name="Pumpkins Vengeance", cost="9De", value="Pumpkins Vengeance"},
        {shop="Supreme Shop", name="GalaxyStarBlade", cost="100De", value="GalaxyStarBlade"},
        {shop="Supreme Shop", name="StaffOfNightmares", cost="1Ud", value="StaffOfNightmares"},
        {shop="Supreme Shop", name="EAGLEOFTHESKIES", cost="5Ud", value="EAGLEOFTHESKIES"},
        {shop="Supreme Shop", name="PatriotsDreams", cost="20Ud", value="PatriotsDreams"},
        {shop="Supreme Shop", name="Eternal Piercer", cost="100Ud", value="Eternal Piercer"},
        {shop="Supreme Shop", name="MidStarStaff", cost="700Ud", value="MidStarStaff"},
        {shop="Supreme Shop", name="USAVAMPBLADE", cost="1.5DD", value="USAVAMPBLADE"},
        {shop="Supreme Shop", name="Overseer BLADE", cost="9.5DD", value="Overseer BLADE"},
        {shop="Supreme Shop", name="Beast Scythe", cost="34DD", value="Beast Scythe"},
        {shop="Supreme Shop", name="Staff of Stars", cost="100DD", value="Staff of Stars"},
        {shop="Supreme Shop", name="Infinity", cost="1TD", value="Infinity"},
        -- NOTE: WinterShop's "Frost Scrimitar" (value "Frost Scrimi") is intentionally
        -- omitted: it's a seasonal event shop, so the server rejects the purchase when
        -- the winter event is inactive (gold never moves, same as the in-game button).
    }

    -- POTION DATA (both potion shops). value = exact PurchaseEvent string.
    local potionData = {}
    do
        local tiers1 = {"I","II","III","IV","V"}
        local tiers2 = {"VI","VII","VIII","IX","X"}
        -- cost tables keyed by kind then tier index (1..10)
        local COST = {
            Health  = {"1K + 1%","10K + 2%","100K + 3%","1M + 4%","10M + 5%","1B + 5%","10B + 5%","100B + 5%","1T + 5%","10T + 5%"},
            Speed   = {"25K + 2%","250K + 4%","2.5M + 6%","25M + 8%","250M + 10%","2.5B + 10%","25B + 10%","250B + 10%","2.5T + 10%","25T + 10%"},
            Damage  = {"10M + 4%","100M + 8%","1B + 12%","10B + 16%","100B + 20%","1T + 20%","10T + 20%","100T + 20%","1Qa + 20%","10Qa + 20%"},
            Gravity = {"1M + 3%","10M + 6%","100M + 9%","1B + 12%","10B + 15%","100B + 15%","1T + 15%","10T + 15%","100T + 15%","1Qa + 15%"},
        }
        local ROMAN = {"I","II","III","IV","V","VI","VII","VIII","IX","X"}
        for _, kind in ipairs({"Health","Damage","Speed","Gravity"}) do
            for idx = 1, 10 do
                local tier = ROMAN[idx]
                local shop = idx <= 5 and "Potion Shop" or "Advanced Potion Shop"
                potionData[#potionData+1] = {
                    shop = shop, kind = kind, tier = tier,
                    cost = COST[kind][idx], value = kind .. " Potion " .. tier,
                }
            end
        end
    end

    -- Compact number -> short-suffix formatter (mirrors the game's merchant UI)
    -- so cached merchant costs read like "12.5Qa" instead of a raw integer.
    local SUFFIX = {"","K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","De","Ud","DD","TdD","QdD","QnD","SxD","SpD","OcD","NvD","Vgn"}
    local function fmtNum(x)
        x = tonumber(x)
        if not x then return "?" end
        if x < 1000 then return tostring(x) end
        local d = math.floor(math.log10(x) / 3)
        local s = string.format("%.2f", x / 10 ^ (d * 3)):gsub("%.?0+$", "")
        return s .. (SUFFIX[d + 1] or ("e" .. (d * 3)))
    end

    -- SELF-UPDATING SHOP-WEAPON SCAN.
    -- weaponData above is the curated, shop-grouped list. To catch weapons a game
    -- update adds to any shop without a manual edit, walk every Tool in
    -- ReplicatedStorage.Weapons and ask shopdata.GetShopData(name) for its price:
    -- a non-nil price means the server will sell it, so it belongs in the Shops
    -- tab. Anything not already curated is appended under a clearly-labeled
    -- auto-detected section (buy still fires PurchaseEvent, same as the rest).
    -- Armor (Health|Speed tooltip -> Armor tab) and potions (own section below)
    -- are skipped so they are not duplicated here.
    do
        local ok, ShopMod = pcall(require, game:GetService("ReplicatedStorage").Library.shopdata)
        local weaponsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Weapons")
        if ok and type(ShopMod) == "table" and type(ShopMod.GetShopData) == "function" and weaponsFolder then
            local known = {}
            for _, e in ipairs(weaponData) do known[e.value or e.name] = true; known[e.name] = true end
            for _, e in ipairs(potionData) do known[e.value] = true end
            local extras = {}
            for _, tool in ipairs(weaponsFolder:GetChildren()) do
                if tool:IsA("Tool") and not known[tool.Name] and not tool.Name:match("[Pp]otion") then
                    local tip = tostring(tool.ToolTip)
                    if not tip:match("^Health:%s*[%w%.]+%s*|%s*Speed:") then
                        local okD, d = pcall(ShopMod.GetShopData, tool.Name)
                        if okD and type(d) == "table" and d.Cost then
                            known[tool.Name] = true
                            extras[#extras + 1] = {
                                shop = "More (auto-detected)",
                                name = tool.Name,
                                cost = fmtNum(d.Cost),
                                value = tool.Name,
                            }
                        end
                    end
                end
            end
            table.sort(extras, function(a, b) return a.name < b.name end)
            for _, e in ipairs(extras) do weaponData[#weaponData + 1] = e end
        end
    end

    -- Merchant cache (persisted). Rebuilt live whenever the server pushes stock.
    local merchantData = {}
    if type(saveData.merchantStock) == "table" then
        for _, e in ipairs(saveData.merchantStock) do
            if type(e) == "table" and e.name then
                merchantData[#merchantData + 1] = {name = e.name, cost = e.cost or "?", value = e.name}
            end
        end
    end
    local rebuildMerchant  -- set once the merchant section exists

    if OpenMerchantShop then
        OpenMerchantShop.OnClientEvent:Connect(function(list)
            if type(list) ~= "table" then return end
            local fresh, persist = {}, {}
            for _, v in ipairs(list) do
                if type(v) == "table" and v.Name then
                    local c = fmtNum(v.Cost)
                    fresh[#fresh + 1] = {name = v.Name, cost = c, value = v.Name}
                    persist[#persist + 1] = {name = v.Name, cost = c}
                end
            end
            if #fresh > 0 then
                merchantData = fresh
                saveData.merchantStock = persist
                pcall(saveDataToFile)
                if rebuildMerchant then rebuildMerchant() end
            end
        end)
    end

    -- Scrolling container that holds the three shop sections.
    local panel = Instance.new("ScrollingFrame")
    panel.Name = "ShopsPanel"
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 5
    panel.ScrollBarImageColor3 = colors.accent
    panel.CanvasSize = UDim2.new(0, 0, 0, 0)
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.Visible = false
    panel.ZIndex = 10000
    panel.Parent = contentArea
    do
        local pl = Instance.new("UIListLayout")
        pl.Padding = UDim.new(0, 10)
        pl.SortOrder = Enum.SortOrder.LayoutOrder
        pl.Parent = panel
    end

    -- Build one collapsible shop section (title, selector, inline filtered list,
    -- multi-line status, Buy button). statusFn/textFn/buyFn customise each shop.
    local function makeSection(order, title, buyText, statusFn, textFn, buyFn, hasFilter)
        local sec = Instance.new("Frame")
        sec.LayoutOrder = order
        sec.BackgroundColor3 = getTheme().surface
        sec.BorderSizePixel = 0
        sec.Size = UDim2.new(1, -8, 0, 0)
        sec.AutomaticSize = Enum.AutomaticSize.Y
        sec.ZIndex = 10001
        sec.Parent = panel
        addCorner(sec, 8)
        addStroke(sec, getTheme().borderLight, 1, true)
        do
            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
            pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
            pad.Parent = sec
            local v = Instance.new("UIListLayout")
            v.Padding = UDim.new(0, 6); v.SortOrder = Enum.SortOrder.LayoutOrder
            v.Parent = sec
        end

        local titleLbl = Instance.new("TextLabel")
        titleLbl.LayoutOrder = 1; titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, 0, 0, 20); titleLbl.Text = title
        titleLbl.TextColor3 = colors.accent; titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 14; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 10002; titleLbl.Parent = sec

        local selector = Instance.new("TextButton")
        selector.LayoutOrder = 2; selector.Size = UDim2.new(1, 0, 0, 32)
        selector.BackgroundColor3 = getTheme().inputBg; selector.BorderSizePixel = 0
        selector.Text = "  Select..."; selector.TextColor3 = getTheme().textDim
        selector.TextXAlignment = Enum.TextXAlignment.Left; selector.Font = Enum.Font.Gotham
        selector.TextSize = 13; selector.ZIndex = 10002; selector.Parent = sec
        addCorner(selector, 6); addStroke(selector, getTheme().borderLight, 1, true)

        local listWrap = Instance.new("Frame")
        listWrap.LayoutOrder = 3; listWrap.BackgroundTransparency = 1
        listWrap.Size = UDim2.new(1, 0, 0, 0); listWrap.AutomaticSize = Enum.AutomaticSize.Y
        listWrap.Visible = false; listWrap.ZIndex = 10002; listWrap.Parent = sec
        do
            local wl = Instance.new("UIListLayout")
            wl.Padding = UDim.new(0, 4); wl.SortOrder = Enum.SortOrder.LayoutOrder
            wl.Parent = listWrap
        end

        local filterBox
        if hasFilter then
            filterBox = Instance.new("TextBox")
            filterBox.LayoutOrder = 1; filterBox.Size = UDim2.new(1, 0, 0, 26)
            filterBox.BackgroundColor3 = getTheme().inputBg; filterBox.BorderSizePixel = 0
            filterBox.PlaceholderText = "Filter..."; filterBox.Text = ""
            filterBox.TextColor3 = getTheme().text; filterBox.Font = Enum.Font.Gotham
            filterBox.TextSize = 12; filterBox.ClearTextOnFocus = false
            filterBox.TextXAlignment = Enum.TextXAlignment.Left; filterBox.ZIndex = 10003
            filterBox.Parent = listWrap
            addCorner(filterBox, 4)
            local fp = Instance.new("UIPadding"); fp.PaddingLeft = UDim.new(0, 6); fp.Parent = filterBox
        end

        local listScroll = Instance.new("ScrollingFrame")
        listScroll.LayoutOrder = 2; listScroll.Size = UDim2.new(1, 0, 0, 150)
        listScroll.BackgroundColor3 = getTheme().dropdown; listScroll.BorderSizePixel = 0
        listScroll.ScrollBarThickness = 4; listScroll.ScrollBarImageColor3 = colors.accent
        listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listScroll.ZIndex = 10003; listScroll.Parent = listWrap
        addCorner(listScroll, 6)
        do
            local sl = Instance.new("UIListLayout")
            sl.Padding = UDim.new(0, 2); sl.SortOrder = Enum.SortOrder.LayoutOrder
            sl.Parent = listScroll
        end

        local statusLbl = Instance.new("TextLabel")
        statusLbl.LayoutOrder = 4; statusLbl.BackgroundTransparency = 1
        statusLbl.Size = UDim2.new(1, 0, 0, 0); statusLbl.AutomaticSize = Enum.AutomaticSize.Y
        statusLbl.TextColor3 = getTheme().textDim; statusLbl.Font = Enum.Font.Gotham
        statusLbl.TextSize = 12; statusLbl.TextXAlignment = Enum.TextXAlignment.Left
        statusLbl.TextYAlignment = Enum.TextYAlignment.Top; statusLbl.TextWrapped = true
        statusLbl.ZIndex = 10002; statusLbl.Parent = sec

        local buyBtn = Instance.new("TextButton")
        buyBtn.LayoutOrder = 5; buyBtn.Size = UDim2.new(1, 0, 0, 34)
        buyBtn.BackgroundColor3 = colors.accent; buyBtn.BorderSizePixel = 0
        buyBtn.Text = buyText; buyBtn.TextColor3 = colors.text
        buyBtn.Font = Enum.Font.GothamMedium; buyBtn.TextSize = 14
        buyBtn.ZIndex = 10002; buyBtn.Parent = sec
        addCorner(buyBtn, 6)

        local handle = {selected = nil, expanded = false, defaultStatus = "No selection", frame = sec, statusLabel = statusLbl}
        local optionBtns = {}
        local dataRef = {}

        local function refreshStatus()
            if handle.selected then
                statusLbl.Text = statusFn(handle.selected)
                statusLbl.TextColor3 = getTheme().text
            else
                statusLbl.Text = handle.defaultStatus
                statusLbl.TextColor3 = getTheme().textDim
            end
        end
        refreshStatus()

        local function rebuildOptions()
            for _, b in ipairs(optionBtns) do b:Destroy() end
            table.clear(optionBtns)
            local f = filterBox and filterBox.Text:lower() or ""
            local shown = 0
            for _, entry in ipairs(dataRef) do
                local label = textFn(entry)
                if f == "" or label:lower():find(f, 1, true) then
                    shown = shown + 1
                    local ob = Instance.new("TextButton")
                    ob.LayoutOrder = shown; ob.Size = UDim2.new(1, -4, 0, 26)
                    ob.BackgroundColor3 = getTheme().surface; ob.BorderSizePixel = 0
                    ob.Text = "  " .. label; ob.TextColor3 = getTheme().text
                    ob.TextXAlignment = Enum.TextXAlignment.Left; ob.Font = Enum.Font.Gotham
                    ob.TextSize = 12; ob.ZIndex = 10004; ob.Parent = listScroll
                    addCorner(ob, 4)
                    ob.MouseButton1Click:Connect(function()
                        handle.selected = entry
                        selector.Text = "  " .. label
                        selector.TextColor3 = getTheme().text
                        refreshStatus()
                        handle.expanded = false; listWrap.Visible = false
                    end)
                    optionBtns[#optionBtns + 1] = ob
                end
            end
            if shown == 0 then
                local ob = Instance.new("TextLabel")
                ob.Size = UDim2.new(1, -4, 0, 24); ob.BackgroundTransparency = 1
                ob.Text = (#dataRef == 0) and "  (no items)" or "  (no match)"
                ob.TextColor3 = getTheme().textDim; ob.Font = Enum.Font.Gotham
                ob.TextSize = 12; ob.TextXAlignment = Enum.TextXAlignment.Left
                ob.ZIndex = 10004; ob.Parent = listScroll
                optionBtns[#optionBtns + 1] = ob
            end
        end

        if filterBox then
            filterBox:GetPropertyChangedSignal("Text"):Connect(function()
                if handle.expanded then rebuildOptions() end
            end)
        end

        selector.MouseButton1Click:Connect(function()
            handle.expanded = not handle.expanded
            listWrap.Visible = handle.expanded
            if handle.expanded then rebuildOptions() end
        end)

        buyBtn.MouseButton1Click:Connect(function()
            if not handle.selected then
                statusLbl.Text = "Select an item first."
                statusLbl.TextColor3 = Color3.fromRGB(230, 180, 80)
                return
            end
            buyFn(handle.selected)
            statusLbl.Text = "Purchased:  " .. textFn(handle.selected) .. "\n(check your inventory)"
            statusLbl.TextColor3 = Color3.fromRGB(120, 220, 140)
        end)

        function handle.setData(list)
            dataRef = list
            if handle.expanded then rebuildOptions() end
        end
        function handle.setDefaultStatus(t)
            handle.defaultStatus = t
            if not handle.selected then refreshStatus() end
        end
        return handle
    end

    local wSec = makeSection(1, "WEAPONS", "BUY WEAPON",
        function(e) return ("Shop:  %s\nItem:  %s\nCost:  %s Gold"):format(e.shop, e.name, e.cost) end,
        function(e) return e.name .. "   (" .. e.cost .. ")" end,
        function(e) PurchaseEvent:FireServer(e.value) end, true)
    wSec.setData(weaponData)

    local pSec = makeSection(2, "POTIONS", "BUY POTION",
        function(e) return ("Shop:  %s\nType:  %s\nTier:  %s\nCost:  %s Gold"):format(e.shop, e.kind, e.tier, e.cost) end,
        function(e) return e.kind .. " " .. e.tier .. "   (" .. e.cost .. ")" end,
        function(e) PurchaseEvent:FireServer(e.value) end, true)
    pSec.setData(potionData)

    local mSec = makeSection(3, "MERCHANT", "BUY MERCHANT ITEM",
        function(e) return ("Merchant Salesman\nItem:  %s\nCost:  %s Gold"):format(e.name, e.cost) end,
        function(e) return e.name .. "   (" .. e.cost .. " Gold)" end,
        function(e) if MerchantPurchaseEvent then MerchantPurchaseEvent:FireServer(e.value) end end, false)
    mSec.setDefaultStatus("Walk up to the Merchant Salesman in-game ONCE to load its daily stock. It auto-saves, then you can buy from anywhere.")
    mSec.setData(merchantData)
    rebuildMerchant = function() mSec.setData(merchantData) end

    -- MERCHANT TELEPORT - jump straight to the roaming merchant wherever it
    -- spawned so the user doesn't have to comb the map. The Workspace.Merchant
    -- model is present only while the merchant is active, and its pivot persists
    -- even when streamed out (far away), so its presence + a non-origin pivot is a
    -- reliable "spawned" signal. Sits directly under the Buy button.
    do
        local tp = Instance.new("TextButton")
        tp.LayoutOrder = 6
        tp.Size = UDim2.new(1, 0, 0, 34)
        tp.BackgroundColor3 = getTheme().surfaceHover
        tp.BorderSizePixel = 0
        tp.Text = "TELEPORT TO MERCHANT"
        tp.TextColor3 = colors.text
        tp.Font = Enum.Font.GothamMedium
        tp.TextSize = 14
        tp.ZIndex = 10002
        tp.Parent = mSec.frame
        addCorner(tp, 6)
        addStroke(tp, colors.accent, 1, true)

        local mStatus = mSec.statusLabel
        tp.MouseButton1Click:Connect(function()
            local m = workspace:FindFirstChild("Merchant")
            local pos = m and m:GetPivot().Position
            if not m or not pos or pos.Magnitude < 1 then
                mStatus.Text = "Merchant isn't spawned right now. Try again when it appears on the map."
                mStatus.TextColor3 = Color3.fromRGB(230, 180, 80)
                return
            end
            local char = localPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 6))
                mStatus.Text = "Teleported to the merchant."
                mStatus.TextColor3 = Color3.fromRGB(120, 220, 140)
            end
        end)
    end

    -- SELL ITEMS - dump any items from your live inventory via the game's
    -- SellItemsEvent("SellSelected", {...}) without visiting the Sell Person.
    -- Verified: the server sells by Name alone (ItemId optional). Inventory is
    -- aggregated by name with a live count; multi-select several names and one
    -- Sell Selected dumps every copy you hold of each. Own do-block so its
    -- builder locals free (nothing here escapes the shop panel).
    do
        local SellItemsEvent = Events:FindFirstChild("SellItemsEvent")

        local sec = Instance.new("Frame")
        sec.LayoutOrder = 4
        sec.BackgroundColor3 = getTheme().surface
        sec.BorderSizePixel = 0
        sec.Size = UDim2.new(1, -8, 0, 0)
        sec.AutomaticSize = Enum.AutomaticSize.Y
        sec.ZIndex = 10001
        sec.Parent = panel
        addCorner(sec, 8)
        addStroke(sec, getTheme().borderLight, 1, true)
        do
            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
            pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8); pad.Parent = sec
            local v = Instance.new("UIListLayout")
            v.Padding = UDim.new(0, 6); v.SortOrder = Enum.SortOrder.LayoutOrder; v.Parent = sec
        end

        local titleLbl = Instance.new("TextLabel")
        titleLbl.LayoutOrder = 1; titleLbl.BackgroundTransparency = 1
        titleLbl.Size = UDim2.new(1, 0, 0, 20); titleLbl.Text = "SELL ITEMS"
        titleLbl.TextColor3 = colors.accent; titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 14; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 10002; titleLbl.Parent = sec

        local selector = Instance.new("TextButton")
        selector.LayoutOrder = 2; selector.Size = UDim2.new(1, 0, 0, 32)
        selector.BackgroundColor3 = getTheme().inputBg; selector.BorderSizePixel = 0
        selector.Text = "  Select items to sell..."; selector.TextColor3 = getTheme().textDim
        selector.TextXAlignment = Enum.TextXAlignment.Left; selector.Font = Enum.Font.Gotham
        selector.TextSize = 13; selector.ZIndex = 10002; selector.Parent = sec
        addCorner(selector, 6); addStroke(selector, getTheme().borderLight, 1, true)

        local listWrap = Instance.new("Frame")
        listWrap.LayoutOrder = 3; listWrap.BackgroundTransparency = 1
        listWrap.Size = UDim2.new(1, 0, 0, 0); listWrap.AutomaticSize = Enum.AutomaticSize.Y
        listWrap.Visible = false; listWrap.ZIndex = 10002; listWrap.Parent = sec
        do
            local wl = Instance.new("UIListLayout")
            wl.Padding = UDim.new(0, 4); wl.SortOrder = Enum.SortOrder.LayoutOrder; wl.Parent = listWrap
        end

        local filterBox = Instance.new("TextBox")
        filterBox.LayoutOrder = 1; filterBox.Size = UDim2.new(1, 0, 0, 26)
        filterBox.BackgroundColor3 = getTheme().inputBg; filterBox.BorderSizePixel = 0
        filterBox.PlaceholderText = "Filter inventory..."; filterBox.Text = ""
        filterBox.TextColor3 = getTheme().text; filterBox.Font = Enum.Font.Gotham
        filterBox.TextSize = 12; filterBox.ClearTextOnFocus = false
        filterBox.TextXAlignment = Enum.TextXAlignment.Left; filterBox.ZIndex = 10003
        filterBox.Parent = listWrap; addCorner(filterBox, 4)
        do local fp = Instance.new("UIPadding"); fp.PaddingLeft = UDim.new(0, 6); fp.Parent = filterBox end

        local listScroll = Instance.new("ScrollingFrame")
        listScroll.LayoutOrder = 2; listScroll.Size = UDim2.new(1, 0, 0, 150)
        listScroll.BackgroundColor3 = getTheme().dropdown; listScroll.BorderSizePixel = 0
        listScroll.ScrollBarThickness = 4; listScroll.ScrollBarImageColor3 = colors.accent
        listScroll.CanvasSize = UDim2.new(0, 0, 0, 0); listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listScroll.ZIndex = 10003; listScroll.Parent = listWrap; addCorner(listScroll, 6)
        do
            local sl = Instance.new("UIListLayout")
            sl.Padding = UDim.new(0, 2); sl.SortOrder = Enum.SortOrder.LayoutOrder; sl.Parent = listScroll
        end

        local statusLbl = Instance.new("TextLabel")
        statusLbl.LayoutOrder = 4; statusLbl.BackgroundTransparency = 1
        statusLbl.Size = UDim2.new(1, 0, 0, 0); statusLbl.AutomaticSize = Enum.AutomaticSize.Y
        statusLbl.Text = "Nothing selected."; statusLbl.TextColor3 = getTheme().textDim
        statusLbl.Font = Enum.Font.Gotham; statusLbl.TextSize = 12
        statusLbl.TextXAlignment = Enum.TextXAlignment.Left; statusLbl.TextYAlignment = Enum.TextYAlignment.Top
        statusLbl.TextWrapped = true; statusLbl.ZIndex = 10002; statusLbl.Parent = sec

        local sellBtn = Instance.new("TextButton")
        sellBtn.LayoutOrder = 5; sellBtn.Size = UDim2.new(1, 0, 0, 34)
        sellBtn.BackgroundColor3 = colors.accent; sellBtn.BorderSizePixel = 0
        sellBtn.Text = "SELL SELECTED"; sellBtn.TextColor3 = colors.text
        sellBtn.Font = Enum.Font.GothamMedium; sellBtn.TextSize = 14
        sellBtn.ZIndex = 10002; sellBtn.Parent = sec; addCorner(sellBtn, 6)

        local sellQty = {}   -- [toolName] = how many copies to sell (1..count)
        local expanded = false
        local rowBtns = {}
        local lastCounts = {}   -- name -> live count, from the last rebuild

        local WARN = Color3.fromRGB(230, 180, 80)
        local RED = Color3.fromRGB(200, 60, 60)
        local GREEN = Color3.fromRGB(120, 220, 140)

        -- Aggregate the player's live tools (Backpack + equipped) by name -> count.
        local function invCounts()
            local counts, order = {}, {}
            local function scan(c)
                if not c then return end
                for _, t in ipairs(c:GetChildren()) do
                    if t:IsA("Tool") then
                        if not counts[t.Name] then counts[t.Name] = 0; order[#order + 1] = t.Name end
                        counts[t.Name] = counts[t.Name] + 1
                    end
                end
            end
            scan(localPlayer:FindFirstChild("Backpack"))
            scan(localPlayer.Character)
            table.sort(order)
            return counts, order
        end

        -- number of item TYPES queued and total COPIES queued
        local function queued()
            local types, copies = 0, 0
            for _, q in pairs(sellQty) do types = types + 1; copies = copies + q end
            return types, copies
        end

        local function updateSelectorText()
            local types, copies = queued()
            if types == 0 then
                selector.Text = "  Select items to sell..."; selector.TextColor3 = getTheme().textDim
            else
                selector.Text = "  " .. copies .. " item" .. (copies == 1 and "" or "s")
                    .. " (" .. types .. " type" .. (types == 1 and "" or "s") .. ") queued"
                selector.TextColor3 = getTheme().text
            end
        end

        -- The Sell button is a two-click confirm ("double click to sell"): the
        -- first click arms it and the second within 3s actually sells. Any change
        -- to the selection disarms it so you always confirm the exact set.
        local armed = false
        local armToken = 0
        local function disarm()
            if not armed then return end
            armed = false
            sellBtn.Text = "SELL SELECTED"
            sellBtn.BackgroundColor3 = colors.accent
        end

        local function rebuild()
            for _, b in ipairs(rowBtns) do b:Destroy() end
            table.clear(rowBtns)
            local counts, order = invCounts()
            lastCounts = counts
            -- drop any queued items the player no longer has, and clamp to stock
            for name, q in pairs(sellQty) do
                if not counts[name] then sellQty[name] = nil
                elseif q > counts[name] then sellQty[name] = counts[name] end
            end
            local f = filterBox.Text:lower()
            local shown = 0
            for _, name in ipairs(order) do
                if f == "" or name:lower():find(f, 1, true) then
                    shown = shown + 1
                    local total = counts[name]

                    -- One toggle per item name. The game's sell remote removes EVERY
                    -- copy of a name in a single action (identical items share no
                    -- unique id), so selecting a name always queues all N copies -
                    -- selling a subset of identical items isn't supported server-side.
                    local row = Instance.new("TextButton")
                    row.LayoutOrder = shown; row.Size = UDim2.new(1, -4, 0, 26); row.BorderSizePixel = 0
                    row.Text = "  " .. name .. "   x" .. total
                    row.TextXAlignment = Enum.TextXAlignment.Left; row.Font = Enum.Font.Gotham
                    row.TextSize = 12; row.ZIndex = 10004; row.Parent = listScroll; addCorner(row, 4)

                    local function paint()
                        if sellQty[name] then
                            row.BackgroundColor3 = RED; row.TextColor3 = colors.text
                        else
                            row.BackgroundColor3 = getTheme().surface; row.TextColor3 = getTheme().text
                        end
                    end
                    paint()
                    row.MouseButton1Click:Connect(function()
                        -- toggle: queue every copy of this name, or none
                        sellQty[name] = (not sellQty[name]) and total or nil
                        disarm()
                        paint(); updateSelectorText()
                        local types, copies = queued()
                        statusLbl.Text = types == 0 and "Nothing selected."
                            or ("Queued " .. copies .. " item" .. (copies == 1 and "" or "s")
                                .. " across " .. types .. " type" .. (types == 1 and "" or "s") .. ".")
                        statusLbl.TextColor3 = getTheme().textDim
                    end)
                    rowBtns[#rowBtns + 1] = row
                end
            end
            if shown == 0 then
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -4, 0, 24); lbl.BackgroundTransparency = 1
                lbl.Text = (#order == 0) and "  (inventory empty)" or "  (no match)"
                lbl.TextColor3 = getTheme().textDim; lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 10004; lbl.Parent = listScroll; rowBtns[#rowBtns + 1] = lbl
            end
        end

        filterBox:GetPropertyChangedSignal("Text"):Connect(function()
            if expanded then rebuild() end
        end)

        selector.MouseButton1Click:Connect(function()
            expanded = not expanded
            listWrap.Visible = expanded
            if expanded then rebuild() end   -- re-scan the live inventory each open
        end)

        sellBtn.MouseButton1Click:Connect(function()
            if not SellItemsEvent then
                statusLbl.Text = "Sell remote not found."; statusLbl.TextColor3 = WARN; return
            end
            local types, copies = queued()
            if copies == 0 then
                disarm()
                statusLbl.Text = "Select at least one item to sell."; statusLbl.TextColor3 = WARN; return
            end
            if not armed then
                -- first click: arm, wait for a confirming second click ("double click")
                armed = true
                armToken = armToken + 1
                local myToken = armToken
                sellBtn.Text = "CONFIRM: SELL " .. copies .. " ITEM" .. (copies == 1 and "" or "S") .. "? (click again)"
                sellBtn.BackgroundColor3 = RED
                statusLbl.Text = "Click Sell again within 3s to confirm."; statusLbl.TextColor3 = WARN
                task.delay(3, function()
                    if armed and armToken == myToken then
                        disarm()
                        statusLbl.Text = "Sell cancelled (timed out)."; statusLbl.TextColor3 = getTheme().textDim
                    end
                end)
                return
            end

            -- second click: confirmed. Build one descriptor per copy of every queued
            -- name and fire a single SellSelected (the server sells all copies of each
            -- listed name in that one call).
            disarm()
            local descs = {}
            local function scan(c)
                if not c then return end
                for _, t in ipairs(c:GetChildren()) do
                    if t:IsA("Tool") and sellQty[t.Name] then
                        descs[#descs + 1] = {Name = t.Name, ItemId = t:GetAttribute("ItemId"), UpgradeLevel = t:GetAttribute("UpgradeLevel") or 0}
                    end
                end
            end
            scan(localPlayer:FindFirstChild("Backpack"))
            scan(localPlayer.Character)
            if #descs == 0 then
                statusLbl.Text = "Those items are no longer in your inventory."; statusLbl.TextColor3 = WARN
                table.clear(sellQty); updateSelectorText()
                if expanded then rebuild() end
                return
            end
            SellItemsEvent:FireServer("SellSelected", descs)
            statusLbl.Text = "Sold " .. #descs .. " item" .. (#descs == 1 and "" or "s") .. "."
            statusLbl.TextColor3 = GREEN
            table.clear(sellQty)
            updateSelectorText()
            if expanded then task.wait(0.2); rebuild() end
        end)
    end

    -- Positions/sizes the panel; visibility driven by the Shops tab.
    layoutShops = function(cw, lh, visible)
        panel.Visible = visible
        if not visible then return end
        panel.Position = UDim2.new(0, 5, 0, 4)
        panel.Size = UDim2.new(0, cw - 10, 0, math.max(200, lh))
    end
end

-- ============================================================
-- NPC TAB - a Shops-style dropdown of the game's quest/mission givers
-- (Workspace.QuestGivers: Tutorial Master, Swamp Master, Volcano Master, etc.).
-- Pick a giver to see its live NPC status (spawned/available, area, distance,
-- interaction) and its per-NPC progression quest (live progress from the game's
-- Quest HUD, or a preview of what it offers). TELEPORT lands you in front of it,
-- DO QUEST / TURN IN accept + advance its quest chain, and AUTO DO QUEST loops
-- accept-and-farm on the selected giver. The list is ordered by game progression.
-- Wrapped in a do-block so only layoutNpc escapes to the main chunk.
-- npcAuto bridges the early panel to the farm engine (defined far below): the
-- toggle sets on/giver, and the panel installs the accept/target helpers a small
-- coordinator near startFarm() calls.
-- ============================================================
local npcAuto = { on = false, giver = nil }
local layoutNpc
do
    -- Game progression order (region unlock order). Givers not listed fall to
    -- the end, ordered alphabetically. Keyed by the cleaned display name.
    -- Quest Master is intentionally absent -- it runs the global Daily/Weekly/
    -- Monthly bounties, not the region progression, so it's excluded below.
    local ORDER = {
        ["Tutorial Master"] = 1, ["Desert Master"] = 2, ["Swamp Master"] = 3,
        ["Volcano Master"] = 4, ["Dock Master"] = 5, ["Snowy Master"] = 6,
        ["Abyssal Master"] = 7, ["Heaven Master"] = 8, ["Portal Master"] = 9,
        ["Forsaken Master"] = 10, ["Eden Master"] = 11,
        ["Sky, The Challenge Master"] = 12, ["Event Master"] = 13,
        ["Secretphobe"] = 14, ["Blood Cultist"] = 15,
        ["Psychopath"] = 16, ["Leprechaun"] = 17,
    }

    -- Givers to hide from the NPC list (not part of region progression).
    local EXCLUDE = { ["Quest Master"] = true }

    -- "~Swamp Master~" -> "Swamp Master"; leaves plain names untouched.
    local function cleanName(n)
        return (n:gsub("~", ""):gsub("^%s+", ""):gsub("%s+$", ""))
    end

    -- First ProximityPrompt anywhere under the NPC model, if any.
    local function getPrompt(model)
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("ProximityPrompt") then return d end
        end
        return nil
    end

    -- Per-NPC progression quests: definitions from QuestDictionary + live
    -- progress read off the game's own Quest HUD.
    local QDICT = {}
    do
        local ok, mod = pcall(function()
            return require(game:GetService("ReplicatedStorage").Library.QuestDictionary)
        end)
        if ok and type(mod) == "table" and type(mod.Quests) == "table" then
            QDICT = mod.Quests
        end
    end

    -- giver raw name -> its first (lowest-id) offered quest id. Used for givers
    -- that have no quest active right now, so the status still previews what
    -- they hand out. Built once from the dictionary.
    local FIRST_QUEST = {}
    do
        local byGiver = {}
        for id, q in pairs(QDICT) do
            if q.Giver then
                byGiver[q.Giver] = byGiver[q.Giver] or {}
                table.insert(byGiver[q.Giver], id)
            end
        end
        for g, ids in pairs(byGiver) do
            table.sort(ids)
            FIRST_QUEST[g] = ids[1]
        end
    end

    -- Objective one-liner for a dictionary task (no live counts).
    local function fmtDictTask(t)
        local a = tonumber(t.Amount) or 1
        local ty = t.Type
        if ty == "KillSpecific" then return "- Kill " .. a .. " " .. tostring(t.Target)
        elseif ty == "OwnsTool" then return "- Obtain " .. tostring(t.Target)
        elseif ty == "KillBosses" then return "- Kill " .. a .. " bosses"
        elseif ty == "KillAny" then return "- Kill " .. a .. " enemies"
        elseif ty == "KillWeapon" then return "- Kill " .. a .. " using " .. tostring(t.Weapon or t.Target)
        elseif ty == "KillDistance" then return "- Kill " .. a .. " from range"
        elseif ty == "PlayTime" then return "- Play " .. a .. "s"
        else return "- " .. tostring(ty) .. " x" .. a end
    end

    -- Live active quest for a giver, read from the game's Quest HUD (real
    -- progress counts, with the HUD's green tags on finished tasks intact).
    local function activeQuestFor(rawName)
        local pg = localPlayer:FindFirstChild("PlayerGui")
        local hud = pg and pg:FindFirstChild("QuestHUDGui")
        local listF = hud and hud:FindFirstChild("QuestList", true)
        if not listF then return nil end
        for _, node in ipairs(listF:GetChildren()) do
            local id = node.Name:match("^Active_(.+)")
            if id and QDICT[id] and QDICT[id].Giver == rawName then
                local qn = node:FindFirstChild("QuestName", true)
                local tt = node:FindFirstChild("TasksText", true)
                local pt = node:FindFirstChild("ProgressText", true)
                return {
                    id = id,
                    name = (qn and qn.Text) or QDICT[id].Name or id,
                    progress = (pt and pt.Text) or "",
                    tasks = (tt and tt.Text) or "",
                }
            end
        end
        return nil
    end

    -- ---- quest actions (accept + farm targeting) --------------------------
    -- Progression-quest completion is server-only (QuestData_Completed stays []
    -- for it), so we can't compute "the next quest" on the client. Instead we ask
    -- the server the same way the game does: fire the giver's Talk prompt, which
    -- makes the server push OpenDialogueUI carrying the exact quest it would offer
    -- ("New" = a fresh quest to accept), then AcceptQuest that id.
    local QuestEvents = game:GetService("ReplicatedStorage"):FindFirstChild("QuestEvents")
    local AcceptQuest = QuestEvents and QuestEvents:FindFirstChild("AcceptQuest")
    local OpenDialogueUI = QuestEvents and QuestEvents:FindFirstChild("OpenDialogueUI")
    local Events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
    local PurchaseEvent = Events and Events:FindFirstChild("PurchaseEvent")

    local lastOffer = { npc = nil, id = nil, state = nil }
    if OpenDialogueUI then
        OpenDialogueUI.OnClientEvent:Connect(function(npcName, _lines, questId, _qdata, state)
            lastOffer = { npc = npcName, id = questId, state = state }
        end)
    end

    -- Dismiss the dialogue window we popped open to read the offer.
    local function closeDialogue()
        local pg = localPlayer:FindFirstChild("PlayerGui")
        local dg = pg and pg:FindFirstChild("QuestDialogueGui")
        local mf = dg and dg:FindFirstChild("MainFrame")
        if mf then mf.Visible = false end
    end

    -- Drop the player just in front of an NPC model (the server range-checks Talk
    -- prompts, so we must actually be next to the giver for it to respond).
    local function teleportToModel(model)
        local okCF, cf = pcall(function() return model:GetPivot() end)
        if not okCF or not cf then return end
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local look = cf.LookVector
        if look.Magnitude < 0.1 then look = Vector3.new(0, 0, 1) end
        local front = cf.Position + look * 5 + Vector3.new(0, 3, 0)
        pcall(function()
            root.CFrame = CFrame.new(front, Vector3.new(cf.Position.X, front.Y, cf.Position.Z))
        end)
        task.wait(0.3)
    end

    -- Ask the server what `rawName` offers, and accept it if it's a fresh quest.
    -- Returns the accepted quest id, or nil (already active / nothing new).
    local function acceptNext(rawName)
        local qg = Workspace:FindFirstChild("QuestGivers")
        local model = qg and qg:FindFirstChild(rawName)
        local prompt = model and getPrompt(model)
        if not prompt or not AcceptQuest then return nil end
        -- Must be next to the giver or the server ignores the prompt (a quest whose
        -- tasks kept us far, or an idle non-kill quest, otherwise left us out of
        -- range and the giver offered nothing -- "not doing quest").
        teleportToModel(model)
        lastOffer = { npc = nil, id = nil, state = nil }
        pcall(function() fireproximityprompt(prompt) end)
        local deadline = os.clock() + 1.5
        while os.clock() < deadline do
            if lastOffer.npc == rawName and lastOffer.id then break end
            task.wait(0.1)
        end
        local id = nil
        if lastOffer.npc == rawName and lastOffer.id and lastOffer.state == "New" then
            id = lastOffer.id
            pcall(function() AcceptQuest:FireServer(id) end)
        end
        closeDialogue()
        return id
    end

    -- The active quest's still-incomplete tasks (raw dictionary entries), decided
    -- from live HUD progress: a line the HUD marks green (#00FF00) or shows at full
    -- count (n/n) is done. Returns {} when there's no active quest.
    local function incompleteTasks(rawName)
        local aq = activeQuestFor(rawName)
        if not aq then return {} end
        local hudLines = {}
        for line in (aq.tasks .. "\n"):gmatch("(.-)\n") do hudLines[#hudLines + 1] = line end
        local out = {}
        local tasks = (QDICT[aq.id] and QDICT[aq.id].Tasks) or {}
        for i, t in ipairs(tasks) do
            local line = hudLines[i] or ""
            local doneByColor = line:find("#00FF00") ~= nil
            local cur, mx = line:match("%(([%d%.]+%a?)%s*/%s*([%d%.]+%a?)%)")
            local doneByCount = cur and mx and (cur == mx)
            if not doneByColor and not doneByCount then out[#out + 1] = t end
        end
        return out
    end

    -- Incomplete kill-targets (mob names) the farm should chase.
    local function activeTargets(rawName)
        local out = {}
        for _, t in ipairs(incompleteTasks(rawName)) do
            if (t.Type == "KillSpecific" or t.Type == "KillTimeLimit") and t.Target then
                out[#out + 1] = t.Target
            end
        end
        return out
    end

    -- Auto-buy items an active quest still needs (OwnsTool tasks) from the shops,
    -- e.g. Desert_02's "Obtain Scythe". Some quests advance by purchase, not kills,
    -- so without this the farm just idles and the chain stalls. The server ignores
    -- buys you can't afford / that aren't shop items, exactly like the shop button.
    -- Returns true if it fired at least one purchase.
    local function buyNeeded(rawName)
        if not PurchaseEvent then return false end
        local fired = false
        for _, t in ipairs(incompleteTasks(rawName)) do
            if t.Type == "OwnsTool" and t.Target then
                pcall(function() PurchaseEvent:FireServer(t.Target) end)
                fired = true
            end
        end
        return fired
    end

    -- Complete a quest's "Talk to <NPC>" handoff tasks (the final step of most
    -- giver chains, e.g. Desert_08 -> "Talk to Swamp Master") by teleporting to
    -- that NPC and firing its prompt. Without this the chain stalls on the handoff.
    local function talkNeeded(rawName)
        local qg = Workspace:FindFirstChild("QuestGivers")
        if not qg then return false end
        for _, t in ipairs(incompleteTasks(rawName)) do
            if t.Type == "TalkToNPC" and t.Target then
                local target = qg:FindFirstChild(t.Target)
                if not target then
                    for _, m in ipairs(qg:GetChildren()) do
                        if cleanName(m.Name) == cleanName(t.Target) then target = m break end
                    end
                end
                local prompt = target and getPrompt(target)
                if prompt then
                    teleportToModel(target)
                    pcall(function() fireproximityprompt(prompt) end)
                    task.wait(0.4)
                    closeDialogue()
                    return true
                end
            end
        end
        return false
    end

    -- Bridges for the far-below farm coordinator.
    npcAuto.buyNeeded = buyNeeded
    npcAuto.talkNeeded = talkNeeded
    npcAuto.hasActive = function(rawName) return activeQuestFor(rawName) ~= nil end
    npcAuto.activeTargets = activeTargets
    npcAuto.acceptNext = acceptNext

    -- NPC status for one giver: whether it's spawned/available, where it is,
    -- how far away, its interaction prompt, and its quest -- the live active
    -- quest (with progress) if any, otherwise a preview of what it offers.
    local function npcStatusFor(model, pos, dist, rawName)
        local lines = {}
        local prompt = getPrompt(model)
        local spawned = model.Parent ~= nil
        local available = spawned and prompt ~= nil and prompt.Enabled
        lines[#lines + 1] = "Status:  " .. (available and "Available"
            or (spawned and "Present (no prompt)" or "Not spawned"))
        lines[#lines + 1] = string.format("Area:  (%d, %d, %d)  ·  %s studs away",
            math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z), tostring(dist))
        if prompt then
            local inRange = (type(dist) == "number") and (dist <= prompt.MaxActivationDistance)
            local action = (prompt.ActionText ~= "" and prompt.ActionText) or "Interact"
            lines[#lines + 1] = "Interaction:  " .. action
                .. "  (" .. (inRange and "in range" or "out of range") .. ")"
        else
            lines[#lines + 1] = "Interaction:  none"
        end

        local aq = activeQuestFor(rawName)
        if aq then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Quest:  " .. aq.name
                .. (aq.progress ~= "" and ("  (" .. aq.progress .. ")") or "")
            if aq.tasks ~= "" then lines[#lines + 1] = aq.tasks end
        else
            local fid = FIRST_QUEST[rawName]
            local q = fid and QDICT[fid]
            if q then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "Offers:  " .. tostring(q.Name)
                for _, t in ipairs(q.Tasks or {}) do
                    lines[#lines + 1] = fmtDictTask(t)
                end
            end
        end
        return table.concat(lines, "\n")
    end

    -- ---- panel + single "QUEST GIVERS" section (mirrors a Shops section) ----
    local panel = Instance.new("ScrollingFrame")
    panel.Name = "NpcPanel"
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 5
    panel.ScrollBarImageColor3 = colors.accent
    panel.CanvasSize = UDim2.new(0, 0, 0, 0)
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.Visible = false
    panel.ZIndex = 10000
    panel.Parent = contentArea
    do
        local pl = Instance.new("UIListLayout")
        pl.Padding = UDim.new(0, 10)
        pl.SortOrder = Enum.SortOrder.LayoutOrder
        pl.Parent = panel
    end

    local sec = Instance.new("Frame")
    sec.LayoutOrder = 1
    sec.BackgroundColor3 = getTheme().surface
    sec.BorderSizePixel = 0
    sec.Size = UDim2.new(1, -8, 0, 0)
    sec.AutomaticSize = Enum.AutomaticSize.Y
    sec.ZIndex = 10001
    sec.Parent = panel
    addCorner(sec, 8)
    addStroke(sec, getTheme().borderLight, 1, true)
    do
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = sec
        local v = Instance.new("UIListLayout")
        v.Padding = UDim.new(0, 6); v.SortOrder = Enum.SortOrder.LayoutOrder
        v.Parent = sec
    end

    local titleLbl = Instance.new("TextLabel")
    titleLbl.LayoutOrder = 1; titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1, 0, 0, 20); titleLbl.Text = "QUEST GIVERS"
    titleLbl.TextColor3 = colors.accent; titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 14; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 10002; titleLbl.Parent = sec

    local selector = Instance.new("TextButton")
    selector.LayoutOrder = 2; selector.Size = UDim2.new(1, 0, 0, 32)
    selector.BackgroundColor3 = getTheme().inputBg; selector.BorderSizePixel = 0
    selector.Text = "  Select a giver..."; selector.TextColor3 = getTheme().textDim
    selector.TextXAlignment = Enum.TextXAlignment.Left; selector.Font = Enum.Font.Gotham
    selector.TextSize = 13; selector.ZIndex = 10002; selector.Parent = sec
    addCorner(selector, 6); addStroke(selector, getTheme().borderLight, 1, true)

    local listWrap = Instance.new("Frame")
    listWrap.LayoutOrder = 3; listWrap.BackgroundTransparency = 1
    listWrap.Size = UDim2.new(1, 0, 0, 0); listWrap.AutomaticSize = Enum.AutomaticSize.Y
    listWrap.Visible = false; listWrap.ZIndex = 10002; listWrap.Parent = sec
    do
        local wl = Instance.new("UIListLayout")
        wl.Padding = UDim.new(0, 4); wl.SortOrder = Enum.SortOrder.LayoutOrder
        wl.Parent = listWrap
    end

    local filterBox = Instance.new("TextBox")
    filterBox.LayoutOrder = 1; filterBox.Size = UDim2.new(1, 0, 0, 26)
    filterBox.BackgroundColor3 = getTheme().inputBg; filterBox.BorderSizePixel = 0
    filterBox.PlaceholderText = "Filter..."; filterBox.Text = ""
    filterBox.TextColor3 = getTheme().text; filterBox.Font = Enum.Font.Gotham
    filterBox.TextSize = 12; filterBox.ClearTextOnFocus = false
    filterBox.TextXAlignment = Enum.TextXAlignment.Left; filterBox.ZIndex = 10003
    filterBox.Parent = listWrap
    addCorner(filterBox, 4)
    do local fp = Instance.new("UIPadding"); fp.PaddingLeft = UDim.new(0, 6); fp.Parent = filterBox end

    local listScroll = Instance.new("ScrollingFrame")
    listScroll.LayoutOrder = 2; listScroll.Size = UDim2.new(1, 0, 0, 170)
    listScroll.BackgroundColor3 = getTheme().dropdown; listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 4; listScroll.ScrollBarImageColor3 = colors.accent
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listScroll.ZIndex = 10003; listScroll.Parent = listWrap
    addCorner(listScroll, 6)
    do
        local sl = Instance.new("UIListLayout")
        sl.Padding = UDim.new(0, 2); sl.SortOrder = Enum.SortOrder.LayoutOrder
        sl.Parent = listScroll
    end

    local statusLbl = Instance.new("TextLabel")
    statusLbl.LayoutOrder = 4; statusLbl.BackgroundTransparency = 1
    statusLbl.Size = UDim2.new(1, 0, 0, 0); statusLbl.AutomaticSize = Enum.AutomaticSize.Y
    statusLbl.TextColor3 = getTheme().textDim; statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 12; statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.TextYAlignment = Enum.TextYAlignment.Top; statusLbl.TextWrapped = true
    statusLbl.RichText = true  -- render the Quest HUD's green done-task <font> tags
    statusLbl.ZIndex = 10002; statusLbl.Parent = sec

    local tpBtn = Instance.new("TextButton")
    tpBtn.LayoutOrder = 5; tpBtn.Size = UDim2.new(1, 0, 0, 34)
    tpBtn.BackgroundColor3 = colors.accent; tpBtn.BorderSizePixel = 0
    tpBtn.Text = "TELEPORT"; tpBtn.TextColor3 = colors.text
    tpBtn.Font = Enum.Font.GothamMedium; tpBtn.TextSize = 14
    tpBtn.ZIndex = 10002; tpBtn.Parent = sec
    addCorner(tpBtn, 6)

    local selected  -- { model, label, raw }
    local entries = {}
    local optionBtns = {}
    local expanded = false
    local lastActionAt = 0  -- keeps transient action messages up before live refresh reclaims the label

    -- Idle status (no giver picked): how many givers are present right now.
    local function setIdleStatus()
        local qg = Workspace:FindFirstChild("QuestGivers")
        local n = 0
        if qg then for _, m in ipairs(qg:GetChildren()) do
            if m:IsA("Model") and not EXCLUDE[cleanName(m.Name)] then n = n + 1 end
        end end
        statusLbl.Text = "Pick a giver to view its status and teleport.\n\n"
            .. "Givers present:  " .. n
        statusLbl.TextColor3 = getTheme().textDim
    end

    local function refreshStatus()
        if selected then
            local m = selected.model
            local okP, pivot = pcall(function() return m:GetPivot().Position end)
            local pos = okP and pivot or Vector3.new()
            local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
            local dist = root and math.floor((root.Position - pos).Magnitude) or "?"
            statusLbl.Text = selected.label .. "\n" .. npcStatusFor(m, pos, dist, selected.raw)
            statusLbl.TextColor3 = getTheme().text
        else
            setIdleStatus()
        end
    end

    -- Read Workspace.QuestGivers into `entries`, ordered by game progression.
    local function refreshEntries()
        table.clear(entries)
        local qg = Workspace:FindFirstChild("QuestGivers")
        if not qg then return end
        for _, m in ipairs(qg:GetChildren()) do
            if m:IsA("Model") and not EXCLUDE[cleanName(m.Name)] then
                entries[#entries + 1] = { model = m, label = cleanName(m.Name), raw = m.Name }
            end
        end
        table.sort(entries, function(a, b)
            local ra, rb = ORDER[a.label] or math.huge, ORDER[b.label] or math.huge
            if ra ~= rb then return ra < rb end
            return a.label < b.label
        end)
    end

    local function rebuildOptions()
        for _, b in ipairs(optionBtns) do b:Destroy() end
        table.clear(optionBtns)
        local f = filterBox.Text:lower()
        local shown = 0
        for _, entry in ipairs(entries) do
            if f == "" or entry.label:lower():find(f, 1, true) then
                shown = shown + 1
                local ob = Instance.new("TextButton")
                ob.LayoutOrder = shown; ob.Size = UDim2.new(1, -4, 0, 26)
                ob.BackgroundColor3 = getTheme().surface; ob.BorderSizePixel = 0
                ob.Text = "  " .. entry.label; ob.TextColor3 = getTheme().text
                ob.TextXAlignment = Enum.TextXAlignment.Left; ob.Font = Enum.Font.Gotham
                ob.TextSize = 12; ob.ZIndex = 10004; ob.Parent = listScroll
                addCorner(ob, 4)
                ob.MouseButton1Click:Connect(function()
                    selected = entry
                    selector.Text = "  " .. entry.label
                    selector.TextColor3 = getTheme().text
                    expanded = false; listWrap.Visible = false
                    if npcAuto.setGiver then npcAuto.setGiver(entry.raw) end
                    refreshStatus()
                end)
                optionBtns[#optionBtns + 1] = ob
            end
        end
        if shown == 0 then
            local ob = Instance.new("TextLabel")
            ob.Size = UDim2.new(1, -4, 0, 24); ob.BackgroundTransparency = 1
            ob.Text = (#entries == 0) and "  (no givers found)" or "  (no match)"
            ob.TextColor3 = getTheme().textDim; ob.Font = Enum.Font.Gotham
            ob.TextSize = 12; ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.ZIndex = 10004; ob.Parent = listScroll
            optionBtns[#optionBtns + 1] = ob
        end
    end

    filterBox:GetPropertyChangedSignal("Text"):Connect(function()
        if expanded then rebuildOptions() end
    end)

    selector.MouseButton1Click:Connect(function()
        expanded = not expanded
        listWrap.Visible = expanded
        if expanded then refreshEntries(); rebuildOptions() end
    end)

    tpBtn.MouseButton1Click:Connect(function()
        if not selected then
            statusLbl.Text = "Pick a giver first."
            statusLbl.TextColor3 = Color3.fromRGB(230, 180, 80)
            return
        end
        local okP, pivot = pcall(function() return selected.model:GetPivot() end)
        if not okP or not pivot then
            statusLbl.Text = "Could not locate " .. selected.label .. "."
            statusLbl.TextColor3 = Color3.fromRGB(230, 180, 80)
            return
        end
        local char = localPlayer.Character
        if not char then
            localPlayer.CharacterAdded:Wait()
            char = localPlayer.Character
        end
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            -- Land a few studs IN FRONT of the NPC (along its facing vector) and
            -- turn to face it. A fixed +Z offset dropped us behind givers that
            -- face -Z (e.g. the Volcano Master), out of the "Talk" prompt's arc;
            -- their prompts have a small range (~10) so side matters.
            local npcPos = pivot.Position
            local look = pivot.LookVector
            -- Fall back to a fixed direction if the model has no real facing.
            if look.Magnitude < 0.1 then look = Vector3.new(0, 0, 1) end
            local front = npcPos + look * 5 + Vector3.new(0, 3, 0)
            root.CFrame = CFrame.new(front, Vector3.new(npcPos.X, front.Y, npcPos.Z))
            refreshStatus()
        else
            statusLbl.Text = "No character to teleport."
            statusLbl.TextColor3 = Color3.fromRGB(230, 180, 80)
        end
    end)

    setIdleStatus()

    -- ---- quest action controls (DO QUEST / TURN IN / AUTO DO QUEST) -------
    -- Row with the two manual buttons.
    local actionRow = Instance.new("Frame")
    actionRow.LayoutOrder = 6; actionRow.BackgroundTransparency = 1
    actionRow.Size = UDim2.new(1, 0, 0, 34); actionRow.ZIndex = 10002
    actionRow.Parent = sec
    do
        local rl = Instance.new("UIListLayout")
        rl.FillDirection = Enum.FillDirection.Horizontal
        rl.Padding = UDim.new(0, 6); rl.SortOrder = Enum.SortOrder.LayoutOrder
        rl.Parent = actionRow
    end

    local function makeActionBtn(order, text)
        local b = Instance.new("TextButton")
        b.LayoutOrder = order; b.Size = UDim2.new(0.5, -3, 1, 0)
        b.BackgroundColor3 = getTheme().surfaceHover; b.BorderSizePixel = 0
        b.Text = text; b.TextColor3 = colors.text
        b.Font = Enum.Font.GothamMedium; b.TextSize = 13
        b.ZIndex = 10003; b.Parent = actionRow
        addCorner(b, 6); addStroke(b, colors.accent, 1, true)
        return b
    end
    local doBtn = makeActionBtn(1, "DO QUEST")
    local turnBtn = makeActionBtn(2, "TURN IN")

    -- DO QUEST: accept this giver's next available quest.
    doBtn.MouseButton1Click:Connect(function()
        lastActionAt = os.clock()
        if not selected then
            statusLbl.Text = "Pick a giver first."
            statusLbl.TextColor3 = Color3.fromRGB(230, 180, 80)
            return
        end
        local active = activeQuestFor(selected.raw)
        if active then
            statusLbl.Text = "Already on \"" .. active.name .. "\" ("
                .. active.progress .. ") for " .. selected.label .. "."
            statusLbl.TextColor3 = Color3.fromRGB(230, 180, 80)
            return
        end
        local id = acceptNext(selected.raw)
        if id then
            statusLbl.Text = "Accepted \"" .. (QDICT[id].Name or id) .. "\" from " .. selected.label .. "."
            statusLbl.TextColor3 = Color3.fromRGB(120, 220, 140)
            task.delay(0.6, function() if selected then refreshStatus() end end)
        else
            statusLbl.Text = "No new quest available from " .. selected.label
                .. " (finish the current one or its prerequisites first)."
            statusLbl.TextColor3 = Color3.fromRGB(230, 180, 80)
        end
    end)

    -- TURN IN: progression quests complete automatically once their tasks are
    -- met (there's no claim step). This advances the chain -- it pulls the next
    -- quest the moment the current one has cleared.
    turnBtn.MouseButton1Click:Connect(function()
        lastActionAt = os.clock()
        if not selected then
            statusLbl.Text = "Pick a giver first."
            statusLbl.TextColor3 = Color3.fromRGB(230, 180, 80)
            return
        end
        local active = activeQuestFor(selected.raw)
        if active then
            statusLbl.Text = "\"" .. active.name .. "\" is " .. active.progress
                .. " done. It turns in automatically once every task is complete."
            statusLbl.TextColor3 = Color3.fromRGB(230, 180, 80)
            return
        end
        local id = acceptNext(selected.raw)
        if id then
            statusLbl.Text = "Pulled next quest \"" .. (QDICT[id].Name or id) .. "\" from " .. selected.label .. "."
            statusLbl.TextColor3 = Color3.fromRGB(120, 220, 140)
            task.delay(0.6, function() if selected then refreshStatus() end end)
        else
            statusLbl.Text = "Nothing to turn in or pull for " .. selected.label .. " right now."
            statusLbl.TextColor3 = getTheme().textDim
        end
    end)

    -- AUTO DO QUEST toggle (iOS pill): loops accept -> farm on the selected
    -- giver. The actual accept/farm loop lives in the coordinator by startFarm().
    local autoRow = Instance.new("Frame")
    autoRow.LayoutOrder = 7; autoRow.BackgroundColor3 = getTheme().surface
    autoRow.BorderSizePixel = 0; autoRow.Size = UDim2.new(1, 0, 0, 40)
    autoRow.ZIndex = 10002; autoRow.Parent = sec
    addCorner(autoRow, 8); addStroke(autoRow, getTheme().borderLight, 1, true)

    local autoLbl = Instance.new("TextLabel")
    autoLbl.Size = UDim2.new(1, -70, 1, 0); autoLbl.Position = UDim2.new(0, 12, 0, 0)
    autoLbl.BackgroundTransparency = 1; autoLbl.Text = "Auto Do Quest"
    autoLbl.TextColor3 = getTheme().text; autoLbl.TextXAlignment = Enum.TextXAlignment.Left
    autoLbl.Font = Enum.Font.GothamMedium; autoLbl.TextSize = 13
    autoLbl.ZIndex = 10003; autoLbl.Parent = autoRow

    local autoTrack = Instance.new("TextButton")
    autoTrack.Size = UDim2.new(0, 46, 0, 24); autoTrack.Position = UDim2.new(1, -14, 0.5, 0)
    autoTrack.AnchorPoint = Vector2.new(1, 0.5)
    autoTrack.BackgroundColor3 = colors.danger; autoTrack.BorderSizePixel = 0
    autoTrack.Text = ""; autoTrack.AutoButtonColor = false
    autoTrack.ZIndex = 10003; autoTrack.Parent = autoRow
    addCorner(autoTrack, 12)
    local autoKnob = Instance.new("Frame")
    autoKnob.Size = UDim2.new(0, 18, 0, 18); autoKnob.AnchorPoint = Vector2.new(0, 0.5)
    autoKnob.Position = UDim2.new(0, 3, 0.5, 0); autoKnob.BackgroundColor3 = colors.text
    autoKnob.BorderSizePixel = 0; autoKnob.ZIndex = 10004; autoKnob.Parent = autoTrack
    addCorner(autoKnob, 9)
    local function setAutoVisual(on)
        local target = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        autoTrack.BackgroundColor3 = on and colors.success or colors.danger
        local ok = pcall(function()
            autoKnob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end)
        if not ok then autoKnob.Position = target end
    end

    autoTrack.MouseButton1Click:Connect(function()
        lastActionAt = os.clock()
        if not npcAuto.on and not selected then
            statusLbl.Text = "Pick a giver first, then turn on Auto Do Quest."
            statusLbl.TextColor3 = Color3.fromRGB(230, 180, 80)
            return
        end
        npcAuto.on = not npcAuto.on
        npcAuto.giver = npcAuto.on and selected and selected.raw or nil
        setAutoVisual(npcAuto.on)
        if not npcAuto.on then
            -- Switching OFF: stop the farm right away and leave the player wherever
            -- the farm ended -- no teleport back to a saved position.
            saveData._questFarmTargets = nil
            if npcAuto.isFarming and npcAuto.isFarming() and npcAuto.stopFarm then npcAuto.stopFarm() end
        end
        statusLbl.Text = npcAuto.on
            and ("Auto Do Quest ON for " .. (selected and selected.label or "?")
                .. " - accepting and farming its quest chain.")
            or "Auto Do Quest OFF."
        statusLbl.TextColor3 = npcAuto.on and Color3.fromRGB(120, 220, 140) or getTheme().textDim
    end)

    -- Keep the toggle's giver pointed at the current selection while it's on.
    npcAuto.setGiver = function(raw) if npcAuto.on then npcAuto.giver = raw end end

    -- Live status: while the tab is open with a giver selected, re-render the
    -- status once a second so quest progress, distance and in-range tick live.
    -- Held off for ~3s after a button/toggle press so its message stays readable.
    task.spawn(function()
        while panel and panel.Parent do
            if panel.Visible and selected and (os.clock() - lastActionAt) > 3 then
                pcall(refreshStatus)
            end
            task.wait(1)
        end
    end)

    -- Positions/sizes the panel; visibility driven by the NPC tab. Each open
    -- refreshes the giver list (event/seasonal masters) and the live status.
    layoutNpc = function(cw, lh, visible)
        panel.Visible = visible
        if not visible then return end
        panel.Position = UDim2.new(0, 5, 0, 4)
        panel.Size = UDim2.new(0, cw - 10, 0, math.max(200, lh))
        refreshEntries()
        if selected then
            -- Drop a stale selection if that giver despawned.
            local stillHere = false
            for _, e in ipairs(entries) do if e.raw == selected.raw then selected = e; stillHere = true; break end end
            if not stillHere then
                selected = nil
                selector.Text = "  Select a giver..."
                selector.TextColor3 = getTheme().textDim
            end
        end
        refreshStatus()
        if expanded then rebuildOptions() end
    end
end

-- ============================================================
-- BONE WORLD TAB - "Legend of The Bone Sword" is a self-contained progression
-- world (Workspace["Legend of The Bone Sword"]) reached by the lobby's
-- "To Bone World" portal. Unlike the main map, its enemies use a real
-- Humanoid (Health lives on the Humanoid, no decoy) and each boss DROPS the
-- sword that the NEXT area's portal requires -- so progress is a chain:
-- kill enemy -> get its sword -> equip it -> touch the portal that needs it ->
-- new area with the next enemy. This tab surfaces that whole chain plus:
--   GO TO BONE WORLD  - teleport onto the lobby entry portal.
--   TELEPORT TO AREA  - jump onto any of the 45 bone-world portals.
--   Auto Farm         - camp the nearest bone enemy where you stand.
--   Auto Progress     - farm the exact enemy that drops your next missing
--                       sword, then auto-equip it and touch the next portal.
-- Everything the coordinator (far below, by startFarm) needs is hung on the
-- in-memory holder saveData._bone so no new main-chunk local is added (the
-- file sits right at Luau's 200-local ceiling). Underscore keys are never
-- serialized (saveConfig uses an explicit whitelist), so the holder -- and the
-- _boneMode / _boneTargetName scan flags -- stay purely runtime state.
-- Wrapped in an immediately-invoked function (not a bare do-block) so ALL its
-- locals live in a fresh function scope and add NOTHING to the main chunk's
-- 200-local register budget, which the file already sits right against.
-- ============================================================
;(function()
    -- Ordered progression: {sword this step yields, enemy that drops it}. The
    -- portal to touch after obtaining the sword is resolved live from the pad
    -- whose name reads "(<sword> Required)". Ends at Diaboli -- past that the
    -- bosses have absurd health (billions+) and the "trial" routing forks, so
    -- Auto Progress stops there and the portal list covers the rest manually.
    local CHAIN = {
        {"Bronze Sword", "Goblin Leader"},
        {"Iron Sword", "Ice Guardian"},
        {"Steel Sword", "Frostbite Ice Knight"},
        {"Mithril Sword", "Skeleton King"},
        {"Dragon Sword", "Orc Leader"},
        {"Bone Lord's Son's Sword", "The Bone Lord's Son"},
        {"Mini Ban Hammer", "HadenTheCreeper, the Creator"},
        {"Nightfall", "Korblox Deathspeaker"},
        {"Diaboli", "Flame Master"},
    }

    local function boneRootF() return Workspace:FindFirstChild("Legend of The Bone Sword") end

    -- Set of tool names the player currently owns (Backpack + equipped).
    local function ownedSet()
        local set = {}
        local bp = localPlayer:FindFirstChild("Backpack")
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then set[t.Name] = true end end end
        local char = localPlayer.Character
        if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then set[t.Name] = true end end end
        return set
    end

    -- First chain step whose sword the player does not yet own -> (step, index).
    local function frontier(owned)
        owned = owned or ownedSet()
        for i, st in ipairs(CHAIN) do
            if not owned[st[1]] then return st, i end
        end
        return nil, nil
    end

    -- The teleport pad model whose requirement is this sword ("To Desert
    -- (Bronze Sword Required)" for "Bronze Sword").
    local function padForSword(sword)
        local root = boneRootF()
        local tps = root and root:FindFirstChild("Bone Teleports")
        if not tps then return nil end
        local needle = "(" .. sword .. " Required)"
        for _, m in ipairs(tps:GetChildren()) do
            if m:IsA("Model") and m.Name:find(needle, 1, true) then return m end
        end
        return nil
    end

    -- Step the character onto a pad's touch part (fires its server .Touched, the
    -- same client-owned-position mechanism the farm pin already relies on).
    local function padTouch(pad)
        if not pad then return false end
        local p = pad:FindFirstChild("teleporter1d") or pad:FindFirstChild("teleporter1c")
        if not p then for _, d in ipairs(pad:GetChildren()) do if d:IsA("BasePart") then p = d break end end end
        if not p then return false end
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        root.CFrame = CFrame.new(p.Position + Vector3.new(0, 4, 0))
        return true
    end

    local function goToBone()
        local entry = Workspace:FindFirstChild("To Bone World (Credits to Chrythm!)")
        if not entry then return false end
        return padTouch(entry)
    end

    -- Equip an owned tool by exact name (portals check the held/owned sword).
    local function equipByName(name)
        local char = localPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        local bp = localPlayer:FindFirstChild("Backpack")
        local t = (bp and bp:FindFirstChild(name)) or (char and char:FindFirstChild(name))
        if t then pcall(function() hum:EquipTool(t) end) return true end
        return false
    end

    -- ---- panel + section (mirrors the NPC / Shops sections) ----
    local panel = Instance.new("ScrollingFrame")
    panel.Name = "BonePanel"
    panel.BackgroundTransparency = 1; panel.BorderSizePixel = 0
    panel.ScrollBarThickness = 5; panel.ScrollBarImageColor3 = colors.accent
    panel.CanvasSize = UDim2.new(0, 0, 0, 0)
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.Visible = false; panel.ZIndex = 10000; panel.Parent = contentArea
    do
        local pl = Instance.new("UIListLayout")
        pl.Padding = UDim.new(0, 10); pl.SortOrder = Enum.SortOrder.LayoutOrder; pl.Parent = panel
    end

    local sec = Instance.new("Frame")
    sec.LayoutOrder = 1; sec.BackgroundColor3 = getTheme().surface; sec.BorderSizePixel = 0
    sec.Size = UDim2.new(1, -8, 0, 0); sec.AutomaticSize = Enum.AutomaticSize.Y
    sec.ZIndex = 10001; sec.Parent = panel
    addCorner(sec, 8); addStroke(sec, getTheme().borderLight, 1, true)
    do
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8); pad.Parent = sec
        local v = Instance.new("UIListLayout")
        v.Padding = UDim.new(0, 6); v.SortOrder = Enum.SortOrder.LayoutOrder; v.Parent = sec
    end

    local titleLbl = Instance.new("TextLabel")
    titleLbl.LayoutOrder = 1; titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1, 0, 0, 20); titleLbl.Text = "BONE WORLD"
    titleLbl.TextColor3 = colors.accent; titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 14; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 10002; titleLbl.Parent = sec

    local statusLbl = Instance.new("TextLabel")
    statusLbl.LayoutOrder = 2; statusLbl.BackgroundTransparency = 1
    statusLbl.Size = UDim2.new(1, 0, 0, 0); statusLbl.AutomaticSize = Enum.AutomaticSize.Y
    statusLbl.TextColor3 = getTheme().text; statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 12; statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.TextYAlignment = Enum.TextYAlignment.Top; statusLbl.TextWrapped = true
    statusLbl.RichText = true; statusLbl.ZIndex = 10002; statusLbl.Parent = sec

    local function setStatus(t, c)
        statusLbl.Text = t
        statusLbl.TextColor3 = c or getTheme().text
    end

    -- Live progression summary (owned count + next sword/enemy/portal).
    local function buildProgress()
        local owned = ownedSet()
        local haveN = 0
        for _, st in ipairs(CHAIN) do if owned[st[1]] then haveN = haveN + 1 end end
        local lines = { "Bone swords obtained:  " .. haveN .. " / " .. #CHAIN }
        local step = frontier(owned)
        if step then
            local pad = padForSword(step[1])
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Next weapon:  " .. step[1]
            lines[#lines + 1] = "Kill:  " .. step[2]
            lines[#lines + 1] = "Then portal:  " .. (pad and pad.Name or "(portal not found)")
        else
            lines[#lines + 1] = ""
            lines[#lines + 1] = "All mapped swords obtained. Use the portal list below to explore the rest."
        end
        return table.concat(lines, "\n")
    end

    local function refreshProgress() setStatus(buildProgress()) end

    -- GO TO BONE WORLD
    local goBtn = Instance.new("TextButton")
    goBtn.LayoutOrder = 3; goBtn.Size = UDim2.new(1, 0, 0, 34)
    goBtn.BackgroundColor3 = colors.accent; goBtn.BorderSizePixel = 0
    goBtn.Text = "GO TO BONE WORLD"; goBtn.TextColor3 = colors.text
    goBtn.Font = Enum.Font.GothamMedium; goBtn.TextSize = 14
    goBtn.ZIndex = 10002; goBtn.Parent = sec
    addCorner(goBtn, 6)
    goBtn.MouseButton1Click:Connect(function()
        local went = goToBone()
        setStatus(went and "Teleported to the Bone World entry portal."
            or "Could not find the Bone World entry portal.",
            went and Color3.fromRGB(120, 220, 140) or Color3.fromRGB(230, 180, 80))
    end)

    -- ---- portal picker (dropdown of all bone-world teleports) ----
    local selector = Instance.new("TextButton")
    selector.LayoutOrder = 4; selector.Size = UDim2.new(1, 0, 0, 32)
    selector.BackgroundColor3 = getTheme().inputBg; selector.BorderSizePixel = 0
    selector.Text = "  Select an area/portal..."; selector.TextColor3 = getTheme().textDim
    selector.TextXAlignment = Enum.TextXAlignment.Left; selector.Font = Enum.Font.Gotham
    selector.TextSize = 13; selector.ZIndex = 10002; selector.Parent = sec
    addCorner(selector, 6); addStroke(selector, getTheme().borderLight, 1, true)

    local listWrap = Instance.new("Frame")
    listWrap.LayoutOrder = 5; listWrap.BackgroundTransparency = 1
    listWrap.Size = UDim2.new(1, 0, 0, 0); listWrap.AutomaticSize = Enum.AutomaticSize.Y
    listWrap.Visible = false; listWrap.ZIndex = 10002; listWrap.Parent = sec
    do
        local wl = Instance.new("UIListLayout")
        wl.Padding = UDim.new(0, 4); wl.SortOrder = Enum.SortOrder.LayoutOrder; wl.Parent = listWrap
    end
    local filterBox = Instance.new("TextBox")
    filterBox.LayoutOrder = 1; filterBox.Size = UDim2.new(1, 0, 0, 26)
    filterBox.BackgroundColor3 = getTheme().inputBg; filterBox.BorderSizePixel = 0
    filterBox.PlaceholderText = "Filter..."; filterBox.Text = ""
    filterBox.TextColor3 = getTheme().text; filterBox.Font = Enum.Font.Gotham
    filterBox.TextSize = 12; filterBox.ClearTextOnFocus = false
    filterBox.TextXAlignment = Enum.TextXAlignment.Left; filterBox.ZIndex = 10003
    filterBox.Parent = listWrap
    addCorner(filterBox, 4)
    do local fp = Instance.new("UIPadding"); fp.PaddingLeft = UDim.new(0, 6); fp.Parent = filterBox end
    local listScroll = Instance.new("ScrollingFrame")
    listScroll.LayoutOrder = 2; listScroll.Size = UDim2.new(1, 0, 0, 170)
    listScroll.BackgroundColor3 = getTheme().dropdown; listScroll.BorderSizePixel = 0
    listScroll.ScrollBarThickness = 4; listScroll.ScrollBarImageColor3 = colors.accent
    listScroll.CanvasSize = UDim2.new(0, 0, 0, 0); listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listScroll.ZIndex = 10003; listScroll.Parent = listWrap
    addCorner(listScroll, 6)
    do
        local sl = Instance.new("UIListLayout")
        sl.Padding = UDim.new(0, 2); sl.SortOrder = Enum.SortOrder.LayoutOrder; sl.Parent = listScroll
    end

    local selectedPad
    local padEntries = {}
    local padOptionBtns = {}
    local expanded = false

    -- Portal ordering by WEAPON TIER (Bronze first -> last tier). Bone swords
    -- aren't in WeaponDataStorage, so we read each required sword's MAX damage off
    -- its Tool ToolTip ("Damage: LO-HI") and rank by magnitude. Suffixes are
    -- standard short-scale (K=1e3, M=1e6, ... De=1e33, DD the top tier seen here);
    -- this reproduces the verified chain (Bronze<Iron<Steel<...<Diaboli) and then
    -- extends cleanly through the whole endgame tree. Cached on first dropdown open
    -- (sword damage never changes); pads with no "(X Required)" tag or an unknown
    -- sword rank as +inf and fall to the end, alphabetically.
    local TIEREXP = { [""] = 0, K = 3, M = 6, B = 9, T = 12, Qa = 15, Qi = 18,
                      Sx = 21, Sp = 24, Oc = 27, No = 30, De = 33, DD = 39 }
    local tierCache
    local function swordTier(sword)
        if not sword then return math.huge end
        if not tierCache then
            tierCache = {}
            local index = {}
            local function idx(inst)
                if not inst then return end
                for _, d in ipairs(inst:GetDescendants()) do
                    if d:IsA("Tool") and index[d.Name] == nil then index[d.Name] = d end
                end
            end
            idx(boneRootF())
            idx(game:GetService("ReplicatedStorage"):FindFirstChild("Weapons"))
            for name, tool in pairs(index) do
                local m, suf = tostring(tool.ToolTip):match("Damage:%s*[%d%.]+%a*%s*%-%s*([%d%.]+)(%a*)")
                local e = m and TIEREXP[suf or ""]
                tierCache[name] = (m and e) and (tonumber(m) * 10 ^ e) or math.huge
            end
        end
        return tierCache[sword] or math.huge
    end

    local function refreshPads()
        table.clear(padEntries)
        local root = boneRootF()
        local tps = root and root:FindFirstChild("Bone Teleports")
        if not tps then return end
        for _, m in ipairs(tps:GetChildren()) do
            if m:IsA("Model") and m.Name:sub(1, 3) == "To " then
                padEntries[#padEntries + 1] = { model = m, label = m.Name,
                    tier = swordTier(m.Name:match("%((.-) Required%)")) }
            end
        end
        table.sort(padEntries, function(a, b)
            if a.tier ~= b.tier then return a.tier < b.tier end
            return a.label < b.label
        end)
    end

    local function rebuildPadOptions()
        for _, b in ipairs(padOptionBtns) do b:Destroy() end
        table.clear(padOptionBtns)
        local f = filterBox.Text:lower()
        local shown = 0
        for _, entry in ipairs(padEntries) do
            if f == "" or entry.label:lower():find(f, 1, true) then
                shown = shown + 1
                local ob = Instance.new("TextButton")
                ob.LayoutOrder = shown; ob.Size = UDim2.new(1, -4, 0, 26)
                ob.BackgroundColor3 = getTheme().surface; ob.BorderSizePixel = 0
                ob.Text = "  " .. entry.label; ob.TextColor3 = getTheme().text
                ob.TextXAlignment = Enum.TextXAlignment.Left; ob.Font = Enum.Font.Gotham
                ob.TextSize = 12; ob.ZIndex = 10004; ob.Parent = listScroll
                addCorner(ob, 4)
                ob.MouseButton1Click:Connect(function()
                    selectedPad = entry
                    selector.Text = "  " .. entry.label
                    selector.TextColor3 = getTheme().text
                    expanded = false; listWrap.Visible = false
                end)
                padOptionBtns[#padOptionBtns + 1] = ob
            end
        end
        if shown == 0 then
            local ob = Instance.new("TextLabel")
            ob.Size = UDim2.new(1, -4, 0, 24); ob.BackgroundTransparency = 1
            ob.Text = (#padEntries == 0) and "  (go to Bone World first)" or "  (no match)"
            ob.TextColor3 = getTheme().textDim; ob.Font = Enum.Font.Gotham
            ob.TextSize = 12; ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.ZIndex = 10004; ob.Parent = listScroll
            padOptionBtns[#padOptionBtns + 1] = ob
        end
    end

    filterBox:GetPropertyChangedSignal("Text"):Connect(function()
        if expanded then rebuildPadOptions() end
    end)
    selector.MouseButton1Click:Connect(function()
        expanded = not expanded
        listWrap.Visible = expanded
        if expanded then refreshPads(); rebuildPadOptions() end
    end)

    local tpBtn = Instance.new("TextButton")
    tpBtn.LayoutOrder = 6; tpBtn.Size = UDim2.new(1, 0, 0, 34)
    tpBtn.BackgroundColor3 = getTheme().surfaceHover; tpBtn.BorderSizePixel = 0
    tpBtn.Text = "TELEPORT TO AREA"; tpBtn.TextColor3 = colors.text
    tpBtn.Font = Enum.Font.GothamMedium; tpBtn.TextSize = 13
    tpBtn.ZIndex = 10002; tpBtn.Parent = sec
    addCorner(tpBtn, 6); addStroke(tpBtn, colors.accent, 1, true)
    tpBtn.MouseButton1Click:Connect(function()
        if not selectedPad or not selectedPad.model.Parent then
            setStatus("Pick an area/portal first.", Color3.fromRGB(230, 180, 80))
            return
        end
        if padTouch(selectedPad.model) then
            setStatus("Teleported to portal:  " .. selectedPad.label
                .. "\n(You still need the required sword for it to accept you.)",
                Color3.fromRGB(120, 220, 140))
        else
            setStatus("Could not locate that portal's pad.", Color3.fromRGB(230, 180, 80))
        end
    end)

    -- ---- toggles ----
    local setFarmVisual, setProgVisual
    local function makePill(order, labelText, onClick)
        local row = Instance.new("Frame")
        row.LayoutOrder = order; row.BackgroundColor3 = getTheme().surface; row.BorderSizePixel = 0
        row.Size = UDim2.new(1, 0, 0, 40); row.ZIndex = 10002; row.Parent = sec
        addCorner(row, 8); addStroke(row, getTheme().borderLight, 1, true)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0); lbl.Position = UDim2.new(0, 12, 0, 0); lbl.BackgroundTransparency = 1
        lbl.Text = labelText; lbl.TextColor3 = getTheme().text; lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 13; lbl.ZIndex = 10003; lbl.Parent = row
        local track = Instance.new("TextButton")
        track.Size = UDim2.new(0, 46, 0, 24); track.Position = UDim2.new(1, -14, 0.5, 0); track.AnchorPoint = Vector2.new(1, 0.5)
        track.BackgroundColor3 = colors.danger; track.BorderSizePixel = 0; track.Text = ""; track.AutoButtonColor = false
        track.ZIndex = 10003; track.Parent = row; addCorner(track, 12)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18); knob.AnchorPoint = Vector2.new(0, 0.5); knob.Position = UDim2.new(0, 3, 0.5, 0)
        knob.BackgroundColor3 = colors.text; knob.BorderSizePixel = 0; knob.ZIndex = 10004; knob.Parent = track; addCorner(knob, 9)
        local function setv(on)
            local target = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            track.BackgroundColor3 = on and colors.success or colors.danger
            local ok = pcall(function()
                knob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            end)
            if not ok then knob.Position = target end
        end
        track.MouseButton1Click:Connect(function() onClick(setv) end)
        return setv
    end

    setFarmVisual = makePill(7, "Auto Farm (nearest enemy)", function(setv)
        local B = saveData._bone
        B.farmOn = not B.farmOn
        if B.farmOn and B.progressOn then B.progressOn = false; if setProgVisual then setProgVisual(false) end end
        setv(B.farmOn)
        if B.farmOn then
            setStatus("Auto Farm ON - camping the nearest Bone World enemy.\n"
                .. "Turn on GO TO BONE WORLD first if you are not there yet.",
                Color3.fromRGB(120, 220, 140))
        else
            setStatus("Auto Farm OFF.", getTheme().textDim)
        end
    end)

    setProgVisual = makePill(8, "Auto Progress (weapon -> portal)", function(setv)
        local B = saveData._bone
        B.progressOn = not B.progressOn
        if B.progressOn and B.farmOn then B.farmOn = false; if setFarmVisual then setFarmVisual(false) end end
        setv(B.progressOn)
        if B.progressOn then
            setStatus("Auto Progress ON - farming your next missing sword, then\n"
                .. "auto-equipping it and stepping through its portal, and repeat.",
                Color3.fromRGB(120, 220, 140))
        else
            setStatus("Auto Progress OFF.", getTheme().textDim)
        end
    end)

    -- Live refresh of the progression summary while the tab is open and idle.
    local lastNote = 0
    task.spawn(function()
        while panel and panel.Parent do
            if panel.Visible and not saveData._bone.farmOn and not saveData._bone.progressOn
               and (os.clock() - lastNote) > 3 then
                pcall(refreshProgress)
            end
            task.wait(1.5)
        end
    end)

    -- Publish helpers + state for the coordinator (added far below by startFarm).
    saveData._bone = saveData._bone or {}
    local B = saveData._bone
    B.farmOn = false; B.progressOn = false
    B.chain = CHAIN
    B.ownedSet = ownedSet
    B.frontier = frontier
    B.padForSword = padForSword
    B.padTouch = padTouch
    B.equip = equipByName
    B.goToBone = goToBone
    -- Is a given bone enemy (by clean name) currently alive anywhere in the world?
    -- Bone trash mobs drop the SAME chain swords as the bosses, so Auto Progress
    -- gates its portal step on the STEP'S BOSS being dead (not merely on owning the
    -- sword): while the boss still stands we keep farming it, so an incidental trash
    -- kill that hands us the sword can't skip the boss. Scans every area folder and
    -- strips the "[BOSS]/[Lv...]" tag the same way the farm scan does.
    B.enemyAlive = function(name)
        local root = boneRootF()
        if not root then return false end
        for _, folder in ipairs(root:GetChildren()) do
            if folder:IsA("Folder") then
                for _, c in ipairs(folder:GetChildren()) do
                    local h = c:IsA("Model") and c:FindFirstChildOfClass("Humanoid")
                    if h and h.MaxHealth > 0 and c.Name:sub(1, 3) ~= "To "
                       and h.Health > 0 and (c.Name:gsub("%s*%[.*$", "")) == name then
                        return true
                    end
                end
            end
        end
        return false
    end
    -- Highest-tier bone sword the player owns (last in chain order). Bone enemies
    -- only take damage from bone-world swords, so this is what farming must hold.
    local function bestBoneSword()
        local owned = ownedSet()
        for i = #CHAIN, 1, -1 do if owned[CHAIN[i][1]] then return CHAIN[i][1] end end
        return nil
    end
    B.bestBoneName = bestBoneSword
    B.equipBestBone = function()
        local s = bestBoneSword()
        if s then return equipByName(s) end
        return false  -- owns no bone sword yet; keep the starter for the first boss
    end
    B.setStatus = function(t, c) lastNote = os.clock(); pcall(function() setStatus(t, c) end) end
    B.layout = function(cw, lh, visible)
        panel.Visible = visible
        if not visible then return end
        panel.Position = UDim2.new(0, 5, 0, 4)
        panel.Size = UDim2.new(0, cw - 10, 0, math.max(200, lh))
        if not (B.farmOn or B.progressOn) then refreshProgress() end
        if expanded then refreshPads(); rebuildPadOptions() end
    end
end)()

-- AUTO FARM toggle row (Farm tab only) - an iOS-style slider that starts/stops
-- the auto-farm loop. Replaces the old big START/STOP FARM button.
local farmActive = false
-- Live state published by the farm loop for the Farm-tab status panel.
local farmRuntime = { weapon = "", current = "", nextName = "", model = nil }

-- Only farmToggleRow (positioned by updateLayout) and setFarmSwitchVisual
-- (called from the farm loop) need to escape; the rest are wrapped in a
-- do-block so their locals free before the main chunk's 200-local ceiling.
local farmToggleRow
local setFarmSwitchVisual
do
    farmToggleRow = Instance.new("Frame")
    farmToggleRow.Size = UDim2.new(1, 0, 0, 40)
    farmToggleRow.BackgroundColor3 = getTheme().surface
    farmToggleRow.BorderSizePixel = 0
    farmToggleRow.ZIndex = 9999
    farmToggleRow.LayoutOrder = 2
    farmToggleRow.Visible = true
    farmToggleRow.Parent = farmScroll
    addCorner(farmToggleRow, 8)
    addStroke(farmToggleRow, getTheme().borderLight, 1, true)

    local farmToggleLabel = Instance.new("TextLabel")
    farmToggleLabel.Size = UDim2.new(0.55, 0, 1, 0)
    farmToggleLabel.Position = UDim2.new(0, 12, 0, 0)
    farmToggleLabel.BackgroundTransparency = 1
    farmToggleLabel.Text = "Auto Farm Mobs"
    farmToggleLabel.TextColor3 = getTheme().text
    farmToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    farmToggleLabel.TextYAlignment = Enum.TextYAlignment.Center
    farmToggleLabel.Font = Enum.Font.GothamMedium
    farmToggleLabel.TextSize = 13
    farmToggleLabel.ZIndex = 10001
    farmToggleLabel.Parent = farmToggleRow

    local farmToggleStatus = Instance.new("TextLabel")
    farmToggleStatus.Name = "farmSwitchStatus"
    farmToggleStatus.Size = UDim2.new(0, 34, 1, 0)
    farmToggleStatus.Position = UDim2.new(1, -64, 0, 0)
    farmToggleStatus.AnchorPoint = Vector2.new(0, 0)
    farmToggleStatus.BackgroundTransparency = 1
    farmToggleStatus.Text = "OFF"
    farmToggleStatus.TextColor3 = colors.danger
    farmToggleStatus.TextXAlignment = Enum.TextXAlignment.Right
    farmToggleStatus.TextYAlignment = Enum.TextYAlignment.Center
    farmToggleStatus.Font = Enum.Font.GothamMedium
    farmToggleStatus.TextSize = 12
    farmToggleStatus.ZIndex = 10001
    farmToggleStatus.Parent = farmToggleRow

    -- iOS-style slider (track + knob), mirroring the Anti-AFK / ESP switches.
    local farmToggleTrack = Instance.new("TextButton")
    farmToggleTrack.Name = "farmSwitchTrack"
    farmToggleTrack.Size = UDim2.new(0, 46, 0, 24)
    farmToggleTrack.Position = UDim2.new(1, -10, 0.5, 0)
    farmToggleTrack.AnchorPoint = Vector2.new(1, 0.5)
    farmToggleTrack.BackgroundColor3 = colors.danger
    farmToggleTrack.BorderSizePixel = 0
    farmToggleTrack.Text = ""
    farmToggleTrack.AutoButtonColor = false
    farmToggleTrack.ZIndex = 10002
    farmToggleTrack.Parent = farmToggleRow
    addCorner(farmToggleTrack, 12)

    local farmToggleKnob = Instance.new("Frame")
    farmToggleKnob.Name = "farmSwitchKnob"
    farmToggleKnob.Size = UDim2.new(0, 24, 0, 24)
    farmToggleKnob.AnchorPoint = Vector2.new(0, 0.5)
    farmToggleKnob.Position = UDim2.new(0, 0, 0.5, 0)
    farmToggleKnob.BackgroundColor3 = colors.text
    farmToggleKnob.BorderSizePixel = 0
    farmToggleKnob.ZIndex = 10003
    farmToggleKnob.Parent = farmToggleTrack
    addCorner(farmToggleKnob, 12)

    -- Slides the knob and recolors track/status text to match the given state.
    setFarmSwitchVisual = function(on)
        local target = on and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 0, 0.5, 0)
        farmToggleTrack.BackgroundColor3 = on and colors.success or colors.danger
        farmToggleStatus.Text = on and "ON" or "OFF"
        farmToggleStatus.TextColor3 = on and colors.success or colors.danger
        -- TweenPosition throws ("Can only tween objects in the workspace") when the
        -- knob isn't being rendered yet -- e.g. updateLayout runs this on the load-
        -- time layout pass while the Farm tab is hidden. Snap instantly in that case
        -- so the state stays correct without spamming the console.
        local ok = pcall(function()
            farmToggleKnob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end)
        if not ok then farmToggleKnob.Position = target end
    end
end

-- ============================================================
-- FARM DODGE OFFSET SLIDERS (Farm tab) - drag 0-25 studs on X/Y to
-- nudge the character off the mob's center while auto-farming so its
-- swings whiff. Each row mirrors the Auto Farm Mobs toggle (full width,
-- 40px, same surface/corner/stroke) so they stack cleanly beneath it.
-- Wrapped in a do-block so the builder locals free before the ceiling.
-- ============================================================
do
    local MIN_OFF, MAX_OFF = 0, 25

    local function makeOffsetSlider(order, labelText, key)
        local row = Instance.new("Frame")
        row.Name = "FarmOffset_" .. key
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = getTheme().surface
        row.BorderSizePixel = 0
        row.ZIndex = 9999
        row.LayoutOrder = order
        row.Parent = farmScroll
        addCorner(row, 8)
        addStroke(row, getTheme().borderLight, 1, true)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 110, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = getTheme().text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 13
        label.ZIndex = 10001
        label.Parent = row

        -- Live value readout on the far right, echoing the toggle's status label.
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 26, 1, 0)
        valueLabel.Position = UDim2.new(1, -12, 0.5, 0)
        valueLabel.AnchorPoint = Vector2.new(1, 0.5)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = "1"
        valueLabel.TextColor3 = colors.accent
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.TextYAlignment = Enum.TextYAlignment.Center
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 13
        valueLabel.ZIndex = 10001
        valueLabel.Parent = row

        local track = Instance.new("TextButton")
        track.Name = "track"
        track.Size = UDim2.new(1, -176, 0, 6)
        track.Position = UDim2.new(0, 126, 0.5, 0)
        track.AnchorPoint = Vector2.new(0, 0.5)
        track.BackgroundColor3 = getTheme().inputBg
        track.BorderSizePixel = 0
        track.Text = ""
        track.AutoButtonColor = false
        track.ZIndex = 10001
        track.Parent = row
        addCorner(track, 3)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = colors.accent
        fill.BorderSizePixel = 0
        fill.ZIndex = 10002
        fill.Parent = track
        addCorner(fill, 3)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.new(0, 0, 0.5, 0)
        knob.BackgroundColor3 = colors.text
        knob.BorderSizePixel = 0
        knob.ZIndex = 10003
        knob.Parent = track
        addCorner(knob, 7)

        local function applyVisual(v)
            local frac = (v - MIN_OFF) / (MAX_OFF - MIN_OFF)
            fill.Size = UDim2.new(frac, 0, 1, 0)
            knob.Position = UDim2.new(frac, 0, 0.5, 0)
            valueLabel.Text = tostring(v)
        end

        applyVisual(math.clamp(saveData[key] or MIN_OFF, MIN_OFF, MAX_OFF))

        -- Map an absolute mouse/touch X onto the 0-25 range (snapped to whole studs).
        local dragging = false
        local function setFromX(px)
            local aw = track.AbsoluteSize.X
            if aw <= 0 then return end
            local frac = math.clamp((px - track.AbsolutePosition.X) / aw, 0, 1)
            local v = math.floor(MIN_OFF + frac * (MAX_OFF - MIN_OFF) + 0.5)
            saveData[key] = v
            applyVisual(v)
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch) then
                dragging = false
                saveDataToFile()  -- persist only when the drag settles
            end
        end)
    end

    makeOffsetSlider(4, "Strafe Offset X", "farmOffsetX")
    makeOffsetSlider(5, "Height Offset Y", "farmOffsetY")
end

-- ============================================================
-- EQUIP ALL CONTAINER
-- ============================================================
local equipAllContainer = Instance.new("Frame")
equipAllContainer.Size = UDim2.new(0, 0, 0, 0)
equipAllContainer.Position = UDim2.new(0, 5, 0, 0)
equipAllContainer.BackgroundColor3 = getTheme().surface
equipAllContainer.BorderSizePixel = 0
equipAllContainer.Visible = false
equipAllContainer.ZIndex = 10000
equipAllContainer.Parent = contentArea
addCorner(equipAllContainer, 8)
addStroke(equipAllContainer, getTheme().borderLight, 1, true)

-- "Auto Equip All Armor" — an iOS-style toggle (mirrors the Farm-tab Auto Equip
-- Weapon/Strongest switches, but for armor + helmets). While ON, a background loop
-- keeps every owned armor piece equipped and re-equips them after death/respawn.
-- Built entirely inside this do-block so its widget refs, session token, setter and
-- loop stay BLOCK-local -- they never touch the main chunk's 200-local ceiling
-- (one extra top-level local overflows it and the whole script fails to load).
do
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.62, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Auto Equip All Armor"
    label.TextColor3 = getTheme().text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.ZIndex = 10001
    label.Parent = equipAllContainer

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 34, 1, 0)
    status.Position = UDim2.new(1, -64, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = "OFF"
    status.TextColor3 = colors.danger
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.TextYAlignment = Enum.TextYAlignment.Center
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 12
    status.ZIndex = 10001
    status.Parent = equipAllContainer

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, 46, 0, 24)
    track.Position = UDim2.new(1, -10, 0.5, 0)
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.BackgroundColor3 = colors.danger
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.ZIndex = 10002
    track.Parent = equipAllContainer
    addCorner(track, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 24, 0, 24)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = colors.text
    knob.BorderSizePixel = 0
    knob.ZIndex = 10003
    knob.Parent = track
    addCorner(knob, 12)

    local armorSession = 0

    local function setVisual(on)
        status.Text = on and "ON" or "OFF"
        status.TextColor3 = on and colors.success or colors.danger
        track.BackgroundColor3 = on and colors.success or colors.danger
        local target = on and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 0, 0.5, 0)
        -- TweenPosition throws if the knob isn't rendered yet (Armor tab hidden at
        -- load); snap instantly in that case so state stays correct without spam.
        local ok = pcall(function()
            knob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end)
        if not ok then knob.Position = target end
    end

    -- Flip the toggle. ON launches a loop that keeps all owned armor equipped and
    -- re-equips after respawn; OFF cancels it via the session token.
    local function setEnabled(on)
        on = on and true or false
        saveData.autoEquipArmor = on
        armorSession = armorSession + 1
        saveDataToFile()
        setVisual(on)
        if on then
            local mine = armorSession
            task.spawn(function()
                while saveData.autoEquipArmor and mine == armorSession
                    and screenGui and screenGui.Parent do
                    -- pcall the WHOLE pass: equipAllArmor clones/yields and can throw
                    -- during the death/respawn gap (nil Character, WaitForChild). An
                    -- unguarded error would kill this thread for good -- the exact
                    -- "stops equipping after death" failure. Never let that happen.
                    pcall(function()
                        local char = localPlayer.Character
                        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                        if char and humanoid and humanoid.Health > 0 then
                            equipAllArmor()
                        end
                    end)
                    task.wait(2)  -- re-equip after pickups / after respawn
                end
            end)
        end
    end

    track.MouseButton1Click:Connect(function()
        setEnabled(not saveData.autoEquipArmor)
    end)

    -- Restore saved state (deferred so screenGui is parented and the character is
    -- ready before the loop's first equip).
    if saveData.autoEquipArmor then
        task.defer(function() setEnabled(true) end)
    else
        setVisual(false)
    end
end

-- ============================================================
-- STATUS BAR - Bottom of main frame
-- ============================================================
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, 0, 0, 28)
statusBar.Position = UDim2.new(0, 0, 1, -28)
statusBar.BackgroundColor3 = getTheme().statusBar
statusBar.BorderSizePixel = 0
statusBar.ZIndex = 10000
statusBar.Parent = mainFrame
addCorner(statusBar, 0)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.6, 0, 1, 0)
statusLabel.Position = UDim2.new(0, 12, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Select a target"
statusLabel.TextColor3 = getTheme().textDim
statusLabel.TextScaled = false
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 10001
statusLabel.Parent = statusBar

local statusTabLabel = Instance.new("TextLabel")
statusTabLabel.Size = UDim2.new(1, 0, 1, 0)
statusTabLabel.Position = UDim2.new(0, 0, 0, 0)
statusTabLabel.BackgroundTransparency = 1
statusTabLabel.Text = "Tab: " .. (tabLabels[currentTab] or currentTab)
statusTabLabel.TextColor3 = getTheme().textMuted
statusTabLabel.TextScaled = false
statusTabLabel.TextSize = 10
statusTabLabel.Font = Enum.Font.Gotham
statusTabLabel.TextXAlignment = Enum.TextXAlignment.Center
statusTabLabel.ZIndex = 10001
statusTabLabel.Parent = statusBar

local statusSelectedLabel = Instance.new("TextLabel")
statusSelectedLabel.Size = UDim2.new(0.2, -12, 1, 0)
statusSelectedLabel.Position = UDim2.new(0.8, 0, 0, 0)
statusSelectedLabel.BackgroundTransparency = 1
statusSelectedLabel.Text = "None"
statusSelectedLabel.TextColor3 = getTheme().textMuted
statusSelectedLabel.TextScaled = false
statusSelectedLabel.TextSize = 10
statusSelectedLabel.Font = Enum.Font.Gotham
statusSelectedLabel.TextXAlignment = Enum.TextXAlignment.Right
statusSelectedLabel.ZIndex = 10001
statusSelectedLabel.Parent = statusBar

-- Debug button (invisible, on status bar)
local debugBtn = Instance.new("TextButton")
debugBtn.Size = UDim2.new(1, 0, 1, 0)
debugBtn.BackgroundTransparency = 1
debugBtn.Text = ""
debugBtn.ZIndex = 10001
debugBtn.Parent = statusBar

-- ============================================================
-- RESIZE HANDLES - Every purple edge & corner is draggable
-- ============================================================
-- Helper: builds one accent-colored resize strip/handle.
local function makeResizeHandle(name, size, pos, transparency)
    local h = Instance.new("Frame")
    h.Name = name
    h.Size = size
    h.Position = pos
    h.BackgroundColor3 = colors.accent
    h.BackgroundTransparency = transparency or 0
    h.BorderSizePixel = 0
    h.Active = true  -- sink input so edge-drag resizing doesn't twist the camera
    h.ZIndex = 10010
    h.Parent = mainFrame
    addCorner(h, 2)
    return h
end

-- Edges (thin strips, inset 8px on each end so corners stay clean)
local resizeTop    = makeResizeHandle("resizeTop",    UDim2.new(1, -16, 0, 4), UDim2.new(0, 8, 0, 0),  0.7)
local resizeBottom = makeResizeHandle("resizeBottom", UDim2.new(1, -16, 0, 4), UDim2.new(0, 8, 1, -4), 0.7)
local resizeLeft   = makeResizeHandle("resizeLeft",   UDim2.new(0, 4, 1, -16), UDim2.new(0, 0, 0, 8),  0.7)
local resizeRight  = makeResizeHandle("resizeRight",  UDim2.new(0, 4, 1, -16), UDim2.new(1, -4, 0, 8), 0.7)

-- Corner handles (diagonal resize) are created + wired lower down, inside a
-- do-block next to the edge-resize connections, so they add no top-level locals
-- (this chunk is at Luau's 200-register ceiling).


-- ============================================================
-- FLOATING MINI-MODE
-- ============================================================
local floatingBtn = Instance.new("TextButton")
floatingBtn.Size = UDim2.new(0, 44, 0, 44)
floatingBtn.Position = UDim2.new(0, 20, 0.5, -22)
floatingBtn.BackgroundColor3 = colors.accent
floatingBtn.BorderSizePixel = 0
floatingBtn.Text = "S"
floatingBtn.TextColor3 = colors.text
floatingBtn.Font = Enum.Font.GothamBlack
floatingBtn.TextSize = 18
floatingBtn.ZIndex = 9999
floatingBtn.Visible = false
floatingBtn.Parent = screenGui
addCorner(floatingBtn, 22)
addStroke(floatingBtn, Color3.fromRGB(255, 255, 255), 1, true)

-- ============================================================
-- MINIMIZE / CLOSE / MINI-MODE HANDLERS
-- ============================================================
local minimized = false
local storedPos = mainFrame.Position
local storedH = mainFrame.Size.Y.Offset
local storedW = mainFrame.Size.X.Offset
local isMiniMode = false

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        storedPos = mainFrame.Position
        storedH = mainFrame.Size.Y.Offset
        storedW = mainFrame.Size.X.Offset
        contentContainer.Visible = false
        globalSearchContainer.Visible = false
        statusBar.Visible = false
        mainFrame.Size = UDim2.new(0, storedW, 0, 44)
        minimizeBtn.Text = "\u{25A1}"  -- white square "□" = restore
        mainFrame.Position = storedPos
    else
        contentContainer.Visible = true
        globalSearchContainer.Visible = true
        statusBar.Visible = true
        mainFrame.Size = UDim2.new(0, storedW, 0, storedH)
        minimizeBtn.Text = "\u{2013}"  -- en dash "–" = minimize
        mainFrame.Position = storedPos
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
    screenGui:Destroy()
end)

miniModeBtn.MouseButton1Click:Connect(function()
    isMiniMode = not isMiniMode
    if isMiniMode then
        storedPos = mainFrame.Position
        storedH = mainFrame.Size.Y.Offset
        storedW = mainFrame.Size.X.Offset
        mainFrame.Visible = false
        floatingBtn.Visible = true
    else
        mainFrame.Visible = true
        floatingBtn.Visible = false
        mainFrame.Position = storedPos
        mainFrame.Size = UDim2.new(0, storedW, 0, storedH)
    end
end)

floatingBtn.MouseButton1Click:Connect(function()
    isMiniMode = false
    mainFrame.Visible = true
    floatingBtn.Visible = false
    mainFrame.Position = storedPos
    mainFrame.Size = UDim2.new(0, storedW, 0, storedH)
end)

-- ============================================================
-- RESOLUTION AUTO-FIT HANDLER
-- ============================================================
-- Scale the whole window relative to a 1080p reference so the GUI stays a
-- sensible size on tiny laptops and giant 4K/ultrawide screens alike. A UIScale
-- parented to mainFrame scales it and every descendant uniformly.
--
-- Everything here is wrapped in a `do ... end` block so its locals free their
-- registers afterward (the whole script is one chunk and Luau caps it at 200
-- local registers). The button click handler keeps the values it needs alive as
-- upvalues, so scoping them here costs nothing at runtime.
do
    local guiScale = Instance.new("UIScale")
    guiScale.Scale = 1
    guiScale.Parent = mainFrame

    local autoFitBtn = makeTitleBtn("\u{26F6}", Color3.fromRGB(60, 60, 100), -160)  -- ⛶ fit-to-screen

    local REF_W, REF_H = 1920, 1080
    local autoFitEnabled = saveData.autoFitGui
    local autoFitConn = nil

    local function computeFitScale()
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize
        if not vp or vp.X <= 0 or vp.Y <= 0 then return 1 end
        local s = math.min(vp.X / REF_W, vp.Y / REF_H)
        return math.clamp(s, 0.55, 1.6)
    end

    local function applyAutoFit()
        guiScale.Scale = autoFitEnabled and computeFitScale() or 1
        autoFitBtn.BackgroundColor3 = autoFitEnabled and colors.accent or Color3.fromRGB(60, 60, 100)
    end

    local function setAutoFit(on)
        autoFitEnabled = on
        saveData.autoFitGui = on
        saveDataToFile()
        if on then
            -- keep tracking live resolution changes (window resize, fullscreen toggle)
            if not autoFitConn then
                local cam = workspace.CurrentCamera
                if cam then
                    autoFitConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyAutoFit)
                end
            end
        elseif autoFitConn then
            autoFitConn:Disconnect()
            autoFitConn = nil
        end
        applyAutoFit()
    end

    autoFitBtn.MouseButton1Click:Connect(function()
        setAutoFit(not autoFitEnabled)
        if statusLabel then
            statusLabel.Text = autoFitEnabled
                and ("Auto-fit ON (" .. string.format("%.0f", guiScale.Scale * 100) .. "%)")
                or "Auto-fit OFF (100%)"
        end
    end)

    -- Apply the saved preference on load.
    setAutoFit(autoFitEnabled)
end

-- Floating button drag
local floatingDragging = false
local floatingDragStart, floatingStartPos

floatingBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        floatingDragging = true
        floatingDragStart = i.Position
        floatingStartPos = floatingBtn.Position
    end
end)

-- ============================================================
-- THEME TOGGLE HANDLER
-- ============================================================
local function applyTheme()
    local t = getTheme()
    mainFrame.BackgroundColor3 = t.background
    titleBar.BackgroundColor3 = t.backgroundDark
    subtitleLabel.TextColor3 = t.textMuted
    globalSearchContainer.BackgroundColor3 = t.inputBg
    searchIcon.TextColor3 = t.textMuted
    searchBox.PlaceholderColor3 = t.textMuted
    searchBox.TextColor3 = t.text
    sideContainer.BackgroundColor3 = t.backgroundDark
    bossTabContainer.BackgroundColor3 = t.surface
    dropdownContainer.BackgroundColor3 = t.inputBg
    dropdownLabel.TextColor3 = t.textDim
    dropdownArrow.TextColor3 = t.textMuted
    dropdown.BackgroundColor3 = t.dropdown
    configContainer.BackgroundColor3 = t.surface
    walkLabel.TextColor3 = t.text
    walkInput.BackgroundColor3 = t.inputBg
    walkInput.TextColor3 = t.text
    jumpLabel.TextColor3 = t.text
    jumpInput.BackgroundColor3 = t.inputBg
    jumpInput.TextColor3 = t.text
    afkLabel.TextColor3 = t.text
    afkStatus.BackgroundColor3 = t.inputBg
    keybindLabel.TextColor3 = t.text
    refreshBtn.BackgroundColor3 = colors.accent
    refreshBtn.TextColor3 = colors.text
    equipAllContainer.BackgroundColor3 = t.surface
    statusBar.BackgroundColor3 = t.statusBar
    statusLabel.TextColor3 = t.textDim
    statusTabLabel.TextColor3 = t.textMuted
    statusSelectedLabel.TextColor3 = t.textMuted

    for _, tab in ipairs(sideButtons) do
        local on = tab.name == currentTab
        tab.btn.BackgroundColor3 = on and colors.accent or t.surface
        tab.btn.BackgroundTransparency = on and 0 or 1
        tab.btn.TextColor3 = on and colors.text or t.textDim
        tab.btn.Font = on and Enum.Font.GothamBold or Enum.Font.GothamMedium
    end
    for _, tab in ipairs(bossTabBtns) do
        if tab.name ~= currentBossTab then
            tab.btn.BackgroundColor3 = t.surface
            tab.btn.TextColor3 = t.textDim
        end
    end
end

themeBtn.MouseButton1Click:Connect(function()
    isDarkTheme = not isDarkTheme
    applyTheme()
    statusLabel.Text = isDarkTheme and "Dark theme" or "Light theme"
end)

-- ============================================================
-- CONFIG BUTTON HANDLERS
-- ============================================================
-- (Walk Speed / Jump Power now use iOS switches wired up in the do-block near
-- their TextBoxes -- the old "SET" button handlers were removed.)

afkToggleBtn.MouseButton1Click:Connect(function()
    toggleAntiAFK(not antiAFKEnabled)
    setAfkSwitchVisual(antiAFKEnabled)
    afkStatus.Text = antiAFKEnabled and "ON" or "OFF"
    afkStatus.TextColor3 = antiAFKEnabled and colors.success or colors.danger
    statusLabel.Text = antiAFKEnabled and "Anti-AFK ON" or "Anti-AFK OFF"
end)

-- ============================================================
-- MOB ESP - billboard over each mob within the radius, showing its
--   name and current/max health. Health is parsed from the mob's model
--   name ("<name> Health: <cur>/<max>") since the Humanoid caps at 100.
-- Wrapped in a do-block so all these locals free at `end` and don't count
-- toward Luau's 200-local-per-chunk limit later in the script.
-- ============================================================
do
-- ESP Mobs config rows (created here so their locals stay inside this do-block)
local espLabel = Instance.new("TextLabel")
espLabel.Size = UDim2.new(0, 150, 0, 32)
espLabel.Position = UDim2.new(0, 18, 0, 118)
espLabel.AnchorPoint = Vector2.new(0, 0.5)
espLabel.BackgroundTransparency = 1
espLabel.Text = "ESP Mobs"
espLabel.TextColor3 = getTheme().text
espLabel.TextScaled = false
espLabel.TextSize = 13
espLabel.Font = Enum.Font.GothamMedium
espLabel.TextXAlignment = Enum.TextXAlignment.Left
espLabel.TextYAlignment = Enum.TextYAlignment.Center
espLabel.ZIndex = 10001
espLabel.Parent = configContainer

local espToggleBtn = Instance.new("TextButton")
espToggleBtn.Name = "espSwitchTrack"
espToggleBtn.Size = UDim2.new(0, 46, 0, 24)
espToggleBtn.Position = UDim2.new(1, -27, 0, 118)
espToggleBtn.AnchorPoint = Vector2.new(1, 0.5)
espToggleBtn.BackgroundColor3 = saveData.espMobs and colors.success or colors.danger
espToggleBtn.BorderSizePixel = 0
espToggleBtn.Text = ""
espToggleBtn.AutoButtonColor = false
espToggleBtn.ZIndex = 10002
espToggleBtn.Parent = configContainer
addCorner(espToggleBtn, 12)  -- full pill

local espKnob = Instance.new("Frame")
espKnob.Name = "espSwitchKnob"
espKnob.Size = UDim2.new(0, 18, 0, 18)
espKnob.AnchorPoint = Vector2.new(0, 0.5)
espKnob.Position = saveData.espMobs and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
espKnob.BackgroundColor3 = colors.text
espKnob.BorderSizePixel = 0
espKnob.ZIndex = 10003
espKnob.Parent = espToggleBtn
addCorner(espKnob, 9)  -- circle

local function setEspSwitchVisual(on)
    local target = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    espToggleBtn.BackgroundColor3 = on and colors.success or colors.danger
    -- Snap if the knob isn't rendered yet (tween throws off-screen); see farm toggle.
    local ok = pcall(function()
        espKnob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
    end)
    if not ok then espKnob.Position = target end
end

-- Radius number box now lives INSIDE the ESP Mobs row (Y=118), just left of the
-- slider -- "ESP Mobs  [500]  (slider)". Commits on focus-lost (no SET button).
local espRadiusInput = Instance.new("TextBox")
espRadiusInput.Size = UDim2.new(0, 92, 0, 32)
espRadiusInput.Position = UDim2.new(1, -96, 0, 118)
espRadiusInput.AnchorPoint = Vector2.new(1, 0.5)
espRadiusInput.BackgroundColor3 = getTheme().inputBg
espRadiusInput.BorderSizePixel = 0
espRadiusInput.Text = tostring(math.clamp(saveData.espRadius or 50, 1, 1000))
espRadiusInput.PlaceholderText = "1-1000"
espRadiusInput.TextColor3 = getTheme().text
espRadiusInput.ClearTextOnFocus = false
espRadiusInput.Font = Enum.Font.Gotham
espRadiusInput.TextSize = 13
espRadiusInput.ZIndex = 10001
espRadiusInput.Parent = configContainer
addCorner(espRadiusInput, 6)
addStroke(espRadiusInput, colors.accent, 1, true)

-- Infinite Yield (FE admin commands) loader button -- full-width row below Mob ESP Radius
local iyBtn = Instance.new("TextButton")
iyBtn.Size = UDim2.new(1, -32, 0, 32)
iyBtn.Position = UDim2.new(0.5, 0, 0, 250)
iyBtn.AnchorPoint = Vector2.new(0.5, 0.5)
iyBtn.BackgroundColor3 = colors.accent
iyBtn.BorderSizePixel = 0
iyBtn.Text = "Load Infinite Yield"
iyBtn.TextColor3 = colors.text
iyBtn.Font = Enum.Font.GothamMedium
iyBtn.TextSize = 13
iyBtn.ZIndex = 10002
iyBtn.Parent = configContainer
addCorner(iyBtn, 6)

local iyLoaded = false
iyBtn.MouseButton1Click:Connect(function()
    if iyLoaded then
        statusLabel.Text = "Infinite Yield already loaded"
        return
    end
    statusLabel.Text = "Loading Infinite Yield..."
    local ok, err = pcall(function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end)
    if ok then
        iyLoaded = true
        iyBtn.Text = "Infinite Yield Loaded"
        statusLabel.Text = "Infinite Yield loaded (cmdbar prefix: ;)"
    else
        statusLabel.Text = "IY load failed: " .. tostring(err)
    end
end)

local espEnabled = saveData.espMobs or false
local espRadius = math.clamp(saveData.espRadius or 50, 1, 1000)
local espTags = {}        -- mob -> {gui, nameLbl, hpLbl, part}
local espSession = 0

-- Split "<name> Health: <cur>/<max>" into name, cur, max (strings).
local function parseMobName(full)
    local base, cur, max = full:match("^(.*) Health: ([^/]+)/(.+)$")
    if base then return base, cur, max end
    return full, nil, nil
end

-- The part to pin the billboard to (Torso via the Humanoid, or any BasePart).
local function mobAnchorPart(mob)
    local hum = mob:FindFirstChild("Monster") or mob:FindFirstChildOfClass("Humanoid")
    if hum and hum.RootPart then return hum.RootPart end
    return mob:FindFirstChildWhichIsA("BasePart", true)
end

local function makeEspTag(mob)
    local part = mobAnchorPart(mob)
    if not part then return nil end

    -- Glowing outline = the actual visible ESP (the game already shows a name
    -- plate, so an outline is what makes a mob stand out through terrain/crowd).
    local hl = Instance.new("Highlight")
    hl.Name = "SAUCE_ESP"
    hl.Adornee = mob
    hl.FillColor = colors.accent
    hl.FillTransparency = 0.6
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = mob

    local bb = Instance.new("BillboardGui")
    bb.Name = "SAUCE_ESP"
    bb.Adornee = part
    bb.Size = UDim2.new(0, 200, 0, 42)
    bb.StudsOffset = Vector3.new(0, 6, 0)  -- sit above the game's native nameplate
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.Parent = part

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextColor3 = colors.accent
    nameLbl.TextStrokeTransparency = 0.3
    nameLbl.Text = ""
    nameLbl.Parent = bb

    local hpLbl = Instance.new("TextLabel")
    hpLbl.Position = UDim2.new(0, 0, 0.55, 0)
    hpLbl.Size = UDim2.new(1, 0, 0.45, 0)
    hpLbl.BackgroundTransparency = 1
    hpLbl.Font = Enum.Font.GothamMedium
    hpLbl.TextSize = 12
    hpLbl.TextColor3 = colors.success
    hpLbl.TextStrokeTransparency = 0.3
    hpLbl.Text = ""
    hpLbl.Parent = bb

    return {gui = bb, highlight = hl, nameLbl = nameLbl, hpLbl = hpLbl, part = part}
end

local function destroyTag(tag)
    if tag.gui then tag.gui:Destroy() end
    if tag.highlight then tag.highlight:Destroy() end
end

local function clearEsp()
    for _, tag in pairs(espTags) do
        destroyTag(tag)
    end
    espTags = {}
end

local function stopEsp()
    espEnabled = false
    espSession = espSession + 1  -- kills the running scan loop
    clearEsp()
end

local function startEsp()
    espEnabled = true
    espSession = espSession + 1
    local mySession = espSession
    task.spawn(function()
        while espEnabled and espSession == mySession and screenGui.Parent do
            local mobsFolder = Workspace:FindFirstChild("Mobs")
            local char = localPlayer.Character
            local pr = char and char:FindFirstChild("HumanoidRootPart")
            if mobsFolder and pr then
                local ppos = pr.Position
                local inRange = {}
                for _, mob in ipairs(mobsFolder:GetChildren()) do
                    local piv = getTargetPosition(mob)
                    if piv then
                        local dist = (ppos - piv).Magnitude
                        if dist <= espRadius then
                            inRange[mob] = true
                            local tag = espTags[mob]
                            -- (re)build the tag if missing or its part streamed out
                            if not tag or not tag.gui or not tag.gui.Parent
                               or not tag.part or not tag.part.Parent then
                                if tag then destroyTag(tag) end
                                tag = makeEspTag(mob)
                                espTags[mob] = tag
                            end
                            if tag then
                                local base, cur, max = parseMobName(mob.Name)
                                tag.nameLbl.Text = base
                                if cur then
                                    tag.hpLbl.Text = cur .. " / " .. max .. " HP"
                                    local c, mx = tonumber(cur), tonumber(max)
                                    if c and mx and mx > 0 then
                                        local r = math.clamp(c / mx, 0, 1)
                                        local hpColor = Color3.fromRGB(
                                            math.floor(255 * (1 - r)), math.floor(255 * r), 70)
                                        tag.hpLbl.TextColor3 = hpColor
                                        if tag.highlight then tag.highlight.FillColor = hpColor end
                                    end
                                else
                                    tag.hpLbl.Text = "? HP"
                                end
                            end
                        end
                    end
                end
                -- drop tags for mobs now out of range / gone
                for mob, tag in pairs(espTags) do
                    if not inRange[mob] or not mob.Parent then
                        destroyTag(tag)
                        espTags[mob] = nil
                    end
                end
            else
                clearEsp()
            end
            task.wait(0.2)
        end
        clearEsp()  -- final cleanup when the loop stops (toggle off or GUI closed)
    end)
end

espToggleBtn.MouseButton1Click:Connect(function()
    if espEnabled then
        stopEsp()
        setEspSwitchVisual(false)
        saveData.espMobs = false
        saveDataToFile()
        statusLabel.Text = "Mob ESP OFF"
    else
        startEsp()
        setEspSwitchVisual(true)
        saveData.espMobs = true
        saveDataToFile()
        statusLabel.Text = "Mob ESP ON (radius " .. espRadius .. ")"
    end
end)

espRadiusInput.FocusLost:Connect(function()
    local r = tonumber(espRadiusInput.Text)
    if r then
        r = math.clamp(math.floor(r), 1, 1000)
        espRadius = r
        espRadiusInput.Text = tostring(r)
        saveData.espRadius = r
        saveDataToFile()
        statusLabel.Text = "ESP radius set to " .. r .. " studs"
    else
        espRadiusInput.Text = tostring(espRadius)
        statusLabel.Text = "Invalid radius (1-1000)"
    end
end)

-- Start ESP automatically if it was left ON.
if espEnabled then
    startEsp()
end
end  -- end of ESP do-block

-- Activate anti-AFK on startup if it was saved as ON. Previously toggleAntiAFK
-- was only ever called from the button click, so a restored "ON" state showed
-- "ON" in the UI but never connected anything -- and you'd still get kicked.
if antiAFKEnabled then
    toggleAntiAFK(true)
end

keybindPickerBtn.MouseButton1Click:Connect(function()
    pickingKey = true
    keybindLabel.Text = "Press any key..."
    statusLabel.Text = "Press a key to bind..."
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if pickingKey and not gameProcessed then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            updateToggleKey(input.KeyCode)
            pickingKey = false
            keybindLabel.Text = "Toggle Key: " .. saveData.toggleKey
            statusLabel.Text = "Keybind set to " .. saveData.toggleKey
        end
        return
    end
    
    if not gameProcessed and input.KeyCode == toggleKey then
        isUIVisible = not isUIVisible
        mainFrame.Visible = isUIVisible
        if isMiniMode and isUIVisible then
            floatingBtn.Visible = false
            isMiniMode = false
        elseif not isUIVisible and not isMiniMode then
            -- Hidden via keybind, show floating
            floatingBtn.Visible = true
            isMiniMode = true
        end
    end
end)

-- (The old EQUIP ALL button is gone -- replaced by the "Auto Equip All Armor"
-- toggle built into equipAllContainer above.)

-- Forward declarations for the stat info panel (created in a do-block further
-- down so its helper locals stay out of the main chunk's 200-local budget).
local infoPanel
local updateInfoPanel
-- Returns (health, damage) for a name on a given tab, from the game's stat
-- modules. Used to sort dropdown lists weakest -> strongest. Assigned in the
-- info-panel do-block (which already holds the required modules).
local statHealthDmg
-- Farm-tab live status panel. Created/assigned in the info-panel do-block
-- (which holds MobData/cleanName/abbr); driven by the farm loop's runtime state.
local farmStatusPanel
local updateFarmStatus
-- Farm-tab "Auto Equip Weapon" control: a dropdown row (in farmScroll) plus an
-- overlay popup that searches the weapons you own in your inventory. Keeps the
-- chosen weapon equipped even after death. Created in its own do-block.
local autoEquipRow
local autoEquipPopup
local updateAutoEquipPanel
-- NOTE: positionAutoEquipPopup is intentionally a GLOBAL (assigned without `local`
-- further down), not a new main-chunk local. The main chunk is at Luau's 200-local
-- ceiling, so adding one more local here fails to COMPILE (silent - the executor
-- console doesn't surface compile errors), and the whole GUI silently never loads.
-- Because it's a global, its value LEAKS across executor re-runs. On reload the
-- fresh chunk's first updateLayout (during the load-time applyResize below) would
-- otherwise call the PREVIOUS run's closure, which reparents a now-destroyed label
-- into the old AutoEquipToggleHost and throws ("Parent property is locked"),
-- killing the rest of this chunk before the Farm panels build. Clear it so the
-- guard `if positionAutoEquipPopup then` skips it until its fresh assignment below.
positionAutoEquipPopup = nil

-- Declared here (before updateLayout) so updateLayout can keep the popup's
-- Visible in sync with the open/closed state instead of forcing it open.
local dropdownOpen = false

-- ============================================================
-- FARM COLUMN LAYOUT - keeps the farm controls visible and simply pushes them
-- down below the mob-select popup while it's open (instead of hiding them or
-- letting the popup overlay them), for a cleaner look.
-- ============================================================
function layoutFarmColumn()
    if not farmScroll or currentTab ~= "Farm" then return end
    local sw = sideContainer.Size.X.Offset
    local mw = mainFrame.Size.X.Offset
    local mh = mainFrame.Size.Y.Offset
    local cw = mw - sw - 15
    local lh = mh - 90 - 28 - 44
    -- Default: farm column starts right under the mob selector (Y=82). While the
    -- popup is open it starts just below the popup's bottom edge (popup Y=76).
    local top = 82
    if dropdown.Visible then
        top = 76 + dropdown.Size.Y.Offset + 8
    end
    farmScroll.Position = UDim2.new(0, 5, 0, top)
    -- Bottom edge stays fixed just above the Refresh button (lh-12).
    farmScroll.Size = UDim2.new(0, cw - 10, 0, math.max(60, (lh - 4) - top - 8))
end

-- ============================================================
-- ARMOR COLUMN LAYOUT - the Armor tab is one roomy scroll (stats, auto-equip,
-- shop selector, list, buy). Sizing it to the full body left a big empty gap
-- below BUY ARMOR when the shop list is closed. Instead, size the scroll to its
-- own content (capped so an open list scrolls internally rather than shoving the
-- Refresh button off-screen) and dock Refresh directly beneath it -- no gap.
-- Re-run whenever the scroll's content height changes (list open/close, resize).
-- ============================================================
function layoutArmorColumn()
    if currentTab ~= "Armor" then return end
    local aShopScroll = contentArea:FindFirstChild("ArmorShopScroll")
    if not aShopScroll then return end
    local sw = sideContainer.Size.X.Offset
    local mw = mainFrame.Size.X.Offset
    local mh = mainFrame.Size.Y.Offset
    local cw = mw - sw - 15
    local lh = mh - 90 - 28 - 44
    local layout = aShopScroll:FindFirstChildOfClass("UIListLayout")
    local contentH = layout and layout.AbsoluteContentSize.Y or 0
    -- Cap so the scroll bottom + an 8px gap + the 36px Refresh button all land
    -- within the body; a taller (open) list then scrolls inside the frame.
    local maxH = (lh - 4) - 36 - 8
    local scrollH = math.max(60, math.min(contentH + 4, maxH))
    aShopScroll.Position = UDim2.new(0, 5, 0, 4)
    aShopScroll.Size = UDim2.new(0, cw - 10, 0, scrollH)
    -- Dock Refresh right under the content-sized scroll.
    refreshBtn.Size = UDim2.new(0, cw - 10, 0, 36)
    refreshBtn.Position = UDim2.new(0, 5, 0, 4 + scrollH + 8)
end

-- ============================================================
-- UPDATE LAYOUT - Modern responsive layout
-- ============================================================
local function updateLayout()
    local sw = sideContainer.Size.X.Offset
    local mw = mainFrame.Size.X.Offset
    local mh = mainFrame.Size.Y.Offset
    local cw = mw - sw - 15
    local lh = mh - 90 - 28 - 44 -- subtract titlebar, statusbar, searchbar
    
    -- Viewport is -40 (not -44): the bottom action row (Refresh) is pinned at
    -- lh-4 with height 36, so its bottom lands 4px past a -44 viewport and would
    -- leave a permanent 4px scrollbar on every tab that otherwise fits. -40 makes
    -- the resting canvas exactly meet the viewport; real overflow still scrolls.
    contentArea.Size = UDim2.new(0, cw, 1, -40)
    contentArea.Position = UDim2.new(0, sw + 5, 0, 0)

    layoutSideTabs()  -- re-fill the sidebar tabs to the new window height

    local isArmorTab = (currentTab == "Armor")
    local isConfigTab = (currentTab == "Config")
    local isShopsTab = (currentTab == "Shops")
    local isQuestTab = (currentTab == "Quest")
    local isNpcTab = (currentTab == "NPC")
    local isBoneTab = (currentTab == "Bone")

    -- Dropdown container hidden on Config (uses config panel), Shops (custom
    -- 3-dropdown panel), Quest (its own auto-quest panel), NPC (giver list) and
    -- Bone (its own progression panel).
    dropdownContainer.Visible = not isConfigTab and not isShopsTab and not isQuestTab
        and not isNpcTab and not isBoneTab

    -- Quest tab: dedicated panel owns the area, like Config. Hide every generic
    -- control and size the quest panel to fill the body, then return early.
    local questPanel = contentArea:FindFirstChild("QuestContainer")
    if questPanel then questPanel.Visible = isQuestTab end
    if isQuestTab then
        dropdown.Visible = false
        configContainer.Visible = false
        teleportBtn.Visible = false
        farmScroll.Visible = false
        equipAllContainer.Visible = false
        refreshBtn.Visible = false
        searchBox.Visible = true
        bossTabContainer.Visible = false
        if infoPanel then infoPanel.Visible = false end
        if farmStatusPanel then farmStatusPanel.Visible = false end
        if autoEquipPopup then autoEquipPopup.Visible = false end
        if layoutShops then layoutShops(cw, lh, false) end
        if layoutNpc then layoutNpc(cw, lh, false) end
        if saveData._bone and saveData._bone.layout then saveData._bone.layout(cw, lh, false) end
        -- Hide the Armor tab's roomy scroll (and all its children). This branch
        -- returns before updateLayoutPositions' `aShopScroll.Visible = isArmorTab`,
        -- so without this it stays visible and overlaps the quest panel.
        do
            local aShopScroll = contentArea:FindFirstChild("ArmorShopScroll")
            if aShopScroll then aShopScroll.Visible = false end
        end
        if questPanel then
            questPanel.Size = UDim2.new(0, cw - 10, 0, math.max(324, lh - 20))
            questPanel.Position = UDim2.new(0, 5, 0, 4)
        end
        statusTabLabel.Text = "Tab: " .. (tabLabels[currentTab] or currentTab)
        return
    end

    -- NPC tab: dedicated giver-list panel owns the area, like Quest. Hide every
    -- generic control, fill the body with the panel, then return early.
    if isNpcTab then
        dropdown.Visible = false
        configContainer.Visible = false
        teleportBtn.Visible = false
        farmScroll.Visible = false
        equipAllContainer.Visible = false
        refreshBtn.Visible = false
        searchBox.Visible = true
        bossTabContainer.Visible = false
        if infoPanel then infoPanel.Visible = false end
        if farmStatusPanel then farmStatusPanel.Visible = false end
        if autoEquipPopup then autoEquipPopup.Visible = false end
        if layoutShops then layoutShops(cw, lh, false) end
        if questPanel then questPanel.Visible = false end
        -- Hide the Armor tab's roomy scroll (and all its children). This branch
        -- returns before updateLayoutPositions' `aShopScroll.Visible = isArmorTab`,
        -- so without this it stays visible and overlaps the NPC giver panel.
        do
            local aShopScroll = contentArea:FindFirstChild("ArmorShopScroll")
            if aShopScroll then aShopScroll.Visible = false end
        end
        layoutNpc(cw, lh, true)
        if saveData._bone and saveData._bone.layout then saveData._bone.layout(cw, lh, false) end
        statusTabLabel.Text = "Tab: " .. (tabLabels[currentTab] or currentTab)
        return
    end

    -- Bone World tab: dedicated progression panel owns the area, like NPC/Quest.
    if isBoneTab then
        dropdown.Visible = false
        configContainer.Visible = false
        teleportBtn.Visible = false
        farmScroll.Visible = false
        equipAllContainer.Visible = false
        refreshBtn.Visible = false
        searchBox.Visible = true
        bossTabContainer.Visible = false
        if infoPanel then infoPanel.Visible = false end
        if farmStatusPanel then farmStatusPanel.Visible = false end
        if autoEquipPopup then autoEquipPopup.Visible = false end
        if layoutShops then layoutShops(cw, lh, false) end
        if layoutNpc then layoutNpc(cw, lh, false) end
        if questPanel then questPanel.Visible = false end
        do
            local aShopScroll = contentArea:FindFirstChild("ArmorShopScroll")
            if aShopScroll then aShopScroll.Visible = false end
        end
        if saveData._bone and saveData._bone.layout then saveData._bone.layout(cw, lh, true) end
        statusTabLabel.Text = "Tab: " .. (tabLabels[currentTab] or currentTab)
        return
    end

    if isConfigTab then
        dropdown.Visible = false
        configContainer.Visible = true
        configContainer.Size = UDim2.new(0, cw - 10, 0, math.max(324, lh - 20))
        configContainer.Position = UDim2.new(0, 5, 0, 4)
        teleportBtn.Visible = false
        farmScroll.Visible = false
        equipAllContainer.Visible = false
        refreshBtn.Visible = false
        if infoPanel then infoPanel.Visible = false end
        if farmStatusPanel then farmStatusPanel.Visible = false end
        if autoEquipPopup then autoEquipPopup.Visible = false end
        -- Hide the custom Shops panel too: this branch returns before the normal
        -- layoutShops call below, so without this it stays visible and overlaps the
        -- config panel when switching Shops -> Config.
        if layoutShops then layoutShops(cw, lh, false) end
        if layoutNpc then layoutNpc(cw, lh, false) end
        if saveData._bone and saveData._bone.layout then saveData._bone.layout(cw, lh, false) end
        updateLayoutPositions(cw, lh, isArmorTab, isConfigTab)
        return
    elseif isShopsTab then
        -- Shops tab: hide every generic control; the custom shop panel owns the area.
        dropdown.Visible = false
        configContainer.Visible = false
        teleportBtn.Visible = false
        refreshBtn.Visible = false
        farmScroll.Visible = false
        equipAllContainer.Visible = false
        searchBox.Visible = true
        if infoPanel then infoPanel.Visible = false end
        if farmStatusPanel then farmStatusPanel.Visible = false end
        if autoEquipPopup then autoEquipPopup.Visible = false end
    else
        dropdown.Visible = dropdownOpen
        configContainer.Visible = false
        -- Teleport is meaningless on Item/Armor tabs (they use EQUIP) and on the
        -- Farm tab (which uses START/STOP FARM instead), so hide it there.
        teleportBtn.Visible = (currentTab ~= "Item" and currentTab ~= "Armor" and currentTab ~= "Farm")
        -- Stay visible on the Farm tab even while the mob-select popup is up; the
        -- column is pushed down below the popup by layoutFarmColumn() instead.
        farmScroll.Visible = (currentTab == "Farm")
        if currentTab == "Farm" then
            farmToggleRow.Visible = true
            setFarmSwitchVisual(farmActive)
        end
        searchBox.Visible = true
        refreshBtn.Visible = true
    end
    
    -- Boss tabs
    bossTabContainer.Visible = (currentTab == "Bosses")
    bossTabContainer.Size = UDim2.new(1, -10, 0, 34)
    
    local dropdownY = 4
    if currentTab == "Bosses" then
        dropdownY = 40
    end
    
    -- Dropdown popup sizing. The filter search bar now scrolls inside the list
    -- (as its first item), so the scroll frame starts where the search used to be
    -- pinned (Y=76) and is 34px taller to keep the same bottom edge.
    local ddH = math.min(200, math.max(100, lh - 120))
    dropdown.Size = UDim2.new(0, cw - 10, 0, ddH + 34)
    dropdown.Position = UDim2.new(0, 5, 0, 76)
    
    -- The Auto Equip All Armor toggle now lives inside ArmorShopScroll (so it's
    -- reachable by scrolling with the shop list open). Keep it Visible; the
    -- scroll's own visibility (set in updateLayoutPositions) gates the tab.
    equipAllContainer.Visible = true
    
    updateLayoutPositions(cw, lh, isArmorTab, isConfigTab)

    -- Drive the custom Shops panel (shows only on the Shops tab).
    if layoutShops then layoutShops(cw, lh, isShopsTab) end
    -- NPC tab returns early above, so here it's always hidden.
    if layoutNpc then layoutNpc(cw, lh, false) end
    -- Bone tab returns early above too, so here it's always hidden.
    if saveData._bone and saveData._bone.layout then saveData._bone.layout(cw, lh, false) end
end

function updateLayoutPositions(cw, lh, isArmorTab, isConfigTab)
    -- Armor-tab ARMOR SHOP scroll (selector + inline list + status + buy + the
    -- Auto Equip All Armor toggle). Found by name so it needs no main-chunk local;
    -- shown only on the Armor tab (this runs before the Config early-return so it
    -- hides there too). Its children are managed by a UIListLayout, so positioning
    -- is just placing/sizing this one scroll frame below the stat panel.
    local aShopScroll = contentArea:FindFirstChild("ArmorShopScroll")
    if aShopScroll then aShopScroll.Visible = isArmorTab end

    if isConfigTab then return end

    local bottomY = lh - 4
    
    -- Teleport button (moved up one row so Refresh fits directly beneath it)
    teleportBtn.Size = UDim2.new(0, cw - 10, 0, 36)
    teleportBtn.Position = UDim2.new(0, 5, 0, lh - 46)

    -- Refresh button - same size & color as Teleport, docked right below it
    refreshBtn.Size = UDim2.new(0, cw - 10, 0, 36)
    refreshBtn.Position = UDim2.new(0, 5, 0, lh - 4)

    -- Status bar info
    statusTabLabel.Text = "Tab: " .. (tabLabels[currentTab] or currentTab)
    statusSelectedLabel.Text = selectedItem or "None"

    -- Stat info panel sits below the dropdown selector, above the action buttons.
    -- On the Armor tab it takes a compact top slice and the ARMOR SHOP scroll
    -- fills the rest (so the shop + its open list + buttons all scroll below it).
    -- Stat panel. On the Armor tab it rides INSIDE the armor scroll as the top row
    -- (LayoutOrder -1) so the whole tab is one roomy scroll like the Shops tab.
    -- Everywhere else it's an absolutely-placed panel below the dropdown selector.
    if infoPanel then
        if isArmorTab and aShopScroll then
            if infoPanel.Parent ~= aShopScroll then infoPanel.Parent = aShopScroll end
            infoPanel.LayoutOrder = -1
            infoPanel.Position = UDim2.new(0, 0, 0, 0)
            infoPanel.Size = UDim2.new(1, -4, 0, 72)
        else
            if infoPanel.Parent ~= contentArea then infoPanel.Parent = contentArea end
            infoPanel.LayoutOrder = 0
            infoPanel.Position = UDim2.new(0, 5, 0, 82)
            infoPanel.Size = UDim2.new(0, cw - 10, 0, math.max(70, (lh - 46) - 82 - 8))
        end
    end

    -- Armor scroll fills the tab body: from just below the pinned dropdown selector
    -- (its bottom is ~76) down to just above the action buttons. One roomy scroll
    -- like ShopsPanel, so opening the shop list still leaves plenty of room to
    -- scroll past it.
    -- The equip selector now rides INSIDE this scroll (below), so nothing is pinned
    -- above it anymore -- pull the scroll to the top of the body to reclaim the band
    -- the old floating selector used to occupy.
    if isArmorTab and aShopScroll then
        -- Size the scroll to its content and dock Refresh beneath it (no bottom gap).
        layoutArmorColumn()
    end

    -- Generic equip selector ("Select an item...") + its owned-armor list. On the
    -- Armor tab these ride INLINE as the top two rows INSIDE the roomy armor scroll,
    -- so opening the owned-armor list pushes the stat panel / auto-equip / shop
    -- rows DOWN and you scroll this one panel past it -- instead of the list
    -- floating over (and overlapping) the shop selector and BUY button. On every
    -- other tab they stay a floating overlay in contentArea (restored here). The
    -- popup's Position is ignored once it's a UIListLayout child, so only its Size
    -- (its pushed-down height) and Parent matter here.
    if isArmorTab and aShopScroll then
        if dropdownContainer.Parent ~= aShopScroll then dropdownContainer.Parent = aShopScroll end
        dropdownContainer.LayoutOrder = -3
        dropdownContainer.Size = UDim2.new(1, -4, 0, 36)
        if dropdown.Parent ~= aShopScroll then dropdown.Parent = aShopScroll end
        dropdown.LayoutOrder = -2
        dropdown.Size = UDim2.new(1, -4, 0, math.min(190, math.max(120, (lh - 46) - 140)))
    else
        if dropdownContainer.Parent ~= contentArea then
            dropdownContainer.Parent = contentArea
            dropdownContainer.Position = UDim2.new(0, 5, 0, 40)
        end
        dropdownContainer.LayoutOrder = 0
        dropdownContainer.Size = UDim2.new(1, -10, 0, 36)
        if dropdown.Parent ~= contentArea then dropdown.Parent = contentArea end
        dropdown.LayoutOrder = 0
    end
    -- Farm tab scroll column: status panel + auto-farm toggle + auto-equip row.
    -- Spans from just under the mob selector down to just above the Refresh button.
    if farmScroll then
        layoutFarmColumn()
    end
    -- Keep the (Farm-tab) pinned filter bar sized/placed to the current width.
    layoutDropdownSearch()
    -- The auto-equip popup attaches directly under the "select weapon" selector
    -- bar and flows downward. Handled by positionAutoEquipPopup(), which also runs
    -- every frame while the popup is open so it stays glued to the selector as the
    -- farm column scrolls/reflows (a one-shot placement here drifted out of sync).
    if positionAutoEquipPopup then positionAutoEquipPopup() end
    if updateInfoPanel then updateInfoPanel() end
    if updateFarmStatus then updateFarmStatus() end
    if updateAutoEquipPanel then updateAutoEquipPanel() end
end

-- ============================================================
-- RESIZE LOGIC - Drag purple border edges to resize
-- ============================================================
local function applyResize(w, h)
    w = math.max(400, w)
    h = math.max(350, h)
    local pos = mainFrame.Position
    storedW = w
    storedH = h
    saveData.windowSize = {w, h}
    saveData.windowPos = {pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset}
    saveDataToFile()
    mainFrame.Size = UDim2.new(0, w, 0, h)
    mainFrame.Position = pos
    updateLayout()
end

-- Unified edge/corner resize. Each handle flags which sides it drags;
-- left/top drags also shift the frame position so the opposite edge stays put.
local resizing = false
local dragStart, startW, startH, startOffX, startOffY, startScaleX, startScaleY
local eLeft, eTop, eRight, eBottom = false, false, false, false

local function beginResize(input, l, t, r, b)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    resizing = true
    dragStart = input.Position
    startW = mainFrame.Size.X.Offset
    startH = mainFrame.Size.Y.Offset
    startOffX = mainFrame.Position.X.Offset
    startOffY = mainFrame.Position.Y.Offset
    startScaleX = mainFrame.Position.X.Scale
    startScaleY = mainFrame.Position.Y.Scale
    eLeft, eTop, eRight, eBottom = l, t, r, b
end

local function doResize(input)
    local dx = input.Position.X - dragStart.X
    local dy = input.Position.Y - dragStart.Y
    local newW, newH = startW, startH
    if eRight  then newW = startW + dx end
    if eLeft   then newW = startW - dx end
    if eBottom then newH = startH + dy end
    if eTop    then newH = startH - dy end
    newW = math.max(400, newW)
    newH = math.max(350, newH)
    -- keep the anchored (opposite) edge fixed when growing from left/top
    local newOffX = eLeft and (startOffX + (startW - newW)) or startOffX
    local newOffY = eTop  and (startOffY + (startH - newH)) or startOffY
    storedW = newW
    storedH = newH
    saveData.windowSize = {newW, newH}
    saveData.windowPos = {startScaleX, newOffX, startScaleY, newOffY}
    saveDataToFile()
    mainFrame.Size = UDim2.new(0, newW, 0, newH)
    mainFrame.Position = UDim2.new(startScaleX, newOffX, startScaleY, newOffY)
    updateLayout()
end

resizeLeft.InputBegan:Connect(function(i)   beginResize(i, true,  false, false, false) end)
resizeRight.InputBegan:Connect(function(i)  beginResize(i, false, false, true,  false) end)
resizeTop.InputBegan:Connect(function(i)    beginResize(i, false, true,  false, false) end)
resizeBottom.InputBegan:Connect(function(i) beginResize(i, false, false, false, true)  end)

-- Corner handles: small squares over each corner that drag two edges at once =
-- diagonal resize. Built + wired here in a do-block (locals free after) so they
-- cost no top-level registers. ZIndex sits one above the edges so the corner
-- wins input in the overlap region.
do
    local corners = {
        {"resizeTL", UDim2.new(0, 0,   0, 0),   true,  true,  false, false},
        {"resizeTR", UDim2.new(1, -12, 0, 0),   false, true,  true,  false},
        {"resizeBL", UDim2.new(0, 0,   1, -12), true,  false, false, true},
        {"resizeBR", UDim2.new(1, -12, 1, -12), false, false, true,  true},
    }
    for _, c in ipairs(corners) do
        -- transparency 1 = invisible grab zone; still captures drag input.
        local h = makeResizeHandle(c[1], UDim2.new(0, 12, 0, 12), c[2], 1)
        h.ZIndex = 10011
        local l, t, r, b = c[3], c[4], c[5], c[6]
        h.InputBegan:Connect(function(i) beginResize(i, l, t, r, b) end)
    end
end

-- Sidebar resize
local sidebarResizing = false
local sideStart, sideStartPos

sideHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sidebarResizing = true
        sideStart = input.Position
        sideStartPos = sideContainer.Size.X.Offset
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        -- Edge/corner resize (any purple edge)
        if resizing then
            doResize(input)
        end

        -- Sidebar resize
        if sidebarResizing then
            local delta = input.Position.X - sideStart.X
            local newWidth = math.max(70, math.min(220, sideStartPos + delta))
            sideContainer.Size = UDim2.new(0, newWidth, 1, -44)
            saveData.sidebarWidth = newWidth
            saveDataToFile()
            updateLayout()
        end
        
        -- Floating button drag
        if floatingDragging then
            local d = input.Position - floatingDragStart
            floatingBtn.Position = UDim2.new(
                floatingStartPos.X.Scale, floatingStartPos.X.Offset + d.X,
                floatingStartPos.Y.Scale, floatingStartPos.Y.Offset + d.Y
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = false
        sidebarResizing = false
        floatingDragging = false
    end
end)

-- ============================================================
-- SIDEBAR COLLAPSE TOGGLE - lives in the slot to the right of the global search
-- bar. Collapsing zeroes the sidebar's width so contentArea (which derives its
-- own width/position from sideContainer.Size.X) reflows full-width automatically,
-- no other layout code needs to know about the collapsed state.
-- ============================================================
do
    local sidebarToggleBtn = Instance.new("TextButton")
    sidebarToggleBtn.Size = UDim2.new(0, 34, 0, 36)
    sidebarToggleBtn.Position = UDim2.new(0, 10, 0, 50)
    sidebarToggleBtn.BackgroundColor3 = getTheme().inputBg
    sidebarToggleBtn.BorderSizePixel = 0
    sidebarToggleBtn.AutoButtonColor = true
    sidebarToggleBtn.Text = "\u{00AB}"  -- « (collapse). Flips to » when collapsed.
    sidebarToggleBtn.TextColor3 = colors.accent
    sidebarToggleBtn.Font = Enum.Font.GothamBold
    sidebarToggleBtn.TextSize = 18
    sidebarToggleBtn.ZIndex = 10001
    sidebarToggleBtn.Parent = mainFrame
    addCorner(sidebarToggleBtn, 8)
    addStroke(sidebarToggleBtn, getTheme().borderLight, 1, true)

    sidebarToggleBtn.MouseButton1Click:Connect(function()
        saveData.sidebarCollapsed = not saveData.sidebarCollapsed
        saveDataToFile()
        if saveData.sidebarCollapsed then
            sideContainer.Visible = false
            sideContainer.Size = UDim2.new(0, 0, 1, -44)
            sidebarToggleBtn.Text = "\u{00BB}"  -- »
        else
            sideContainer.Size = UDim2.new(0, saveData.sidebarWidth, 1, -44)
            sideContainer.Visible = true
            sidebarToggleBtn.Text = "\u{00AB}"  -- «
        end
        updateLayout()
    end)

    -- Honor a collapsed state restored from disk on load.
    if saveData.sidebarCollapsed then
        sideContainer.Visible = false
        sideContainer.Size = UDim2.new(0, 0, 1, -44)
        sidebarToggleBtn.Text = "\u{00BB}"  -- »
        updateLayout()
    end
end

-- Floor the window height so the Farm tab's scroll region is tall enough to show
-- ~6 weapon rows in the auto-equip popup (like the mob dropdown). Users can still
-- resize taller; this only lifts a too-short saved height up to the minimum.
applyResize(saveData.windowSize[1], math.max(saveData.windowSize[2], 600))

-- ============================================================
-- DROPDOWN POPULATION - Modern dropdown list items
-- ============================================================
local itemBtns = {}
local selectedItem = saveData.selectedItem or nil
local selectedBtn = nil

-- Farm tab multi-select: set of mob names (name -> true), seeded from save.
-- farmSelection: quick membership set (name -> true) for highlight checks.
-- saveData.farmMobs is the SAME picks in selection order, so the farm loop can
-- target the first-picked mob, then the second, and so on. Deduped on load.
local farmSelection = {}
do
    -- Build a lookup of the real, selectable mob names (case-insensitive). The
    -- Farm dropdown only ever lists these, so a saved pick that isn't among them
    -- can never be highlighted or un-picked -- it just inflates the "N mobs
    -- selected" count forever (the phantom-count bug). An older build also saved
    -- the *display label* ("<name> Health: x/y") instead of the clean name, which
    -- is exactly this kind of dead entry. Drop anything that isn't a live mob.
    -- A mob's identity is its base name WITHOUT the volatile " Health: x/y" tail the
    -- game bakes into the live model name -- that number changes every time the mob
    -- is hit, so keying a pick on the raw string makes it "drift" out of match the
    -- instant the mob takes damage: the highlight vanishes and the pick can't be
    -- un-selected (you'd be clicking a button whose name no longer matches the saved
    -- key). parseMobName strips that tail. The farm loop already targets on this same
    -- stripped base (baseMobName/findNearestMobOfName), so storing the base here keeps
    -- the UI highlight and the loop's targeting in lockstep.
    -- Strip inline (not via parseMobName): that helper is a main-chunk local only
    -- ever referenced from a closure, and calling it directly here -- next to the
    -- 200-local ceiling -- reads nil. `gsub` is a string method, so it needs none.
    local valid = {}
    for _, m in ipairs(mobList) do valid[(tostring(m):gsub("%s*Health:.*$", "")):lower()] = true end

    local seen, cleaned = {}, {}
    for _, n in ipairs(saveData.farmMobs or {}) do
        local key = (tostring(n):gsub("%s*Health:.*$", "")):gsub("^%s+", ""):gsub("%s+$", "")
        if key ~= "" and valid[key:lower()] and not seen[key] then
            seen[key] = true
            cleaned[#cleaned + 1] = key
        end
    end

    -- Persist the scrubbed+migrated list so old full-health picks are rewritten to
    -- their stable base form for good, not just hidden.
    local changed = (#cleaned ~= #(saveData.farmMobs or {}))
    if not changed then
        for i = 1, #cleaned do
            if cleaned[i] ~= saveData.farmMobs[i] then changed = true break end
        end
    end
    saveData.farmMobs = cleaned
    if changed then saveDataToFile() end
    for _, n in ipairs(cleaned) do farmSelection[n] = true end
end
local function farmSelectionCount()
    return #saveData.farmMobs
end
-- Callers pass the raw list/label string; we strip it to the stable base key here so
-- every entry point (highlight, toggle, save) agrees on the same identity.
local function toggleFarmMob(name)
    local key = (tostring(name):gsub("%s*Health:.*$", ""))
    if farmSelection[key] then
        farmSelection[key] = nil
        for i, n in ipairs(saveData.farmMobs) do
            if n == key then table.remove(saveData.farmMobs, i) break end
        end
    else
        farmSelection[key] = true
        saveData.farmMobs[#saveData.farmMobs + 1] = key
    end
    saveDataToFile()
    return farmSelection[key] == true
end
-- dropdownOpen is declared earlier (before updateLayout); reset it here.
dropdownOpen = false

-- ============================================================
-- STAT INFO PANEL - shows stats for the selected item/name.
-- Wrapped in a do-block so its helper locals free before the main chunk's
-- 200-local ceiling. Only `infoPanel`/`updateInfoPanel` (forward-declared
-- above) escape as upvalues.
-- ============================================================
do
    -- Live game data modules (server-authoritative stat tables).
    local RS = game:GetService("ReplicatedStorage")
    local function tryRequire(path)
        local ok, mod = pcall(function() return require(path) end)
        return ok and mod or nil
    end
    local lib = RS:FindFirstChild("Library")
    local WeaponData = lib and tryRequire(lib:FindFirstChild("WeaponDataStorage"))
    local ArmorData2 = lib and tryRequire(lib:FindFirstChild("ArmorDataStorage"))
    local MobData    = lib and tryRequire(lib:FindFirstChild("MobDataStorage"))

    -- Abbreviate huge numbers (1250 -> 1.25K, 5e28 -> 50Oc, beyond table -> sci).
    local SUF = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
                 "Ud", "Dd", "Td", "Qd", "Qn", "Sd", "St"}
    local function abbr(n)
        if type(n) ~= "number" then return tostring(n) end
        if n ~= n then return "?" end
        local i, x = 1, n
        while math.abs(x) >= 1000 and i < #SUF do x = x / 1000; i = i + 1 end
        if math.abs(x) >= 1000 then return string.format("%.2e", n) end
        if i == 1 then return string.format("%d", x) end
        return (string.format("%.2f", x):gsub("%.?0+$", "")) .. SUF[i]
    end

    -- Strip " Health: x/y", " ❤ x", and " (level N)" so names match the data tables.
    local function cleanName(s)
        if not s then return "" end
        s = s:gsub("%s*Health:.*$", "")
        s = s:gsub("%s*❤.*$", "")
        s = s:gsub("%s*%(level%s*%d+%)%s*$", "")
        s = s:gsub("%s+$", "")
        return s
    end

    -- A boss counts as "spawned" if a model with its (cleaned) name is live in Workspace.Mobs.
    local function bossSpawned(name)
        local folder = Workspace:FindFirstChild("Mobs")
        if not folder then return false end
        for _, mob in ipairs(folder:GetChildren()) do
            if cleanName(mob.Name) == name then return true end
        end
        return false
    end

    -- Build the panel UI.
    infoPanel = Instance.new("Frame")
    infoPanel.Name = "InfoPanel"
    infoPanel.Size = UDim2.new(0, 200, 0, 120)
    infoPanel.Position = UDim2.new(0, 5, 0, 82)
    infoPanel.BackgroundColor3 = getTheme().surface
    infoPanel.BorderSizePixel = 0
    infoPanel.Visible = false
    infoPanel.ZIndex = 10000
    infoPanel.Parent = contentArea
    addCorner(infoPanel, 8)
    addStroke(infoPanel, getTheme().borderLight, 1, true)

    local infoTitle = Instance.new("TextLabel")
    infoTitle.Size = UDim2.new(1, -20, 0, 24)
    infoTitle.Position = UDim2.new(0, 10, 0, 6)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "Info"
    infoTitle.TextColor3 = colors.accent
    infoTitle.TextXAlignment = Enum.TextXAlignment.Left
    infoTitle.TextYAlignment = Enum.TextYAlignment.Center
    infoTitle.TextTruncate = Enum.TextTruncate.AtEnd
    infoTitle.Font = Enum.Font.GothamBold
    infoTitle.TextSize = 14
    infoTitle.ZIndex = 10001
    infoTitle.Parent = infoPanel

    local infoBody = Instance.new("TextLabel")
    infoBody.Size = UDim2.new(1, -20, 1, -36)
    infoBody.Position = UDim2.new(0, 10, 0, 30)
    infoBody.BackgroundTransparency = 1
    infoBody.Text = ""
    infoBody.TextColor3 = getTheme().textDim
    infoBody.TextXAlignment = Enum.TextXAlignment.Left
    infoBody.TextYAlignment = Enum.TextYAlignment.Top
    infoBody.TextWrapped = true
    infoBody.Font = Enum.Font.Gotham
    infoBody.TextSize = 13
    infoBody.ZIndex = 10001
    infoBody.Parent = infoPanel

    -- ---- Armor-tab "ARMOR SHOP" dropdown ----------------------------------
    -- A self-contained shop modelled on the Shops-tab sections: a selector that
    -- drops down the armour salesman's stock (the DMScape shop -- level-gated,
    -- NOT gold; boss / event / gamepass-only armour is deliberately excluded),
    -- a status readout, and a BUY button. Armour buys server-side from ANY
    -- location via DMscapePurchaseEvent (verified) and the server replies through
    -- ShopFeedbackEvent(success:boolean, message:string).
    --
    -- CRITICAL: the whole builder runs inside an anonymous IIFE so its many
    -- locals live in a SEPARATE function frame. The main GUI chunk sits at Luau's
    -- 200-register ceiling, so nothing here may become a persistent main-chunk
    -- local. The four controls parent to contentArea by name; the list's own
    -- Visible flag is the single source of truth for open/closed, so
    -- updateLayoutPositions (which finds them via FindFirstChild) can place them
    -- and force-close the list when the Armor tab is left.
    ;(function()
        local ShopFeedbackEvent = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("ShopFeedbackEvent")
        local DMscapePurchaseEvent = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("DMscapePurchaseEvent")
        -- Armour salesman stock, ascending by level requirement: {name, levelReq}.
        local armorShop = {
            {"Gilded Helmet","10"}, {"Dark Helmet","25"}, {"Phantom Helmet","50"},
            {"Diamonx's Helmet","100"}, {"Trimmed Phantom","200"}, {"Frost","500"},
            {"Draconite","1K"}, {"DragonScale","2K"}, {"Granite","4K"}, {"White","8K"},
            {"Godnite","20K"}, {"Tysonite","50K"}, {"Red DragonScale","100K"},
            {"PhantomI","200K"}, {"Gilded","400K"}, {"Dark Knight","1M"},
            {"Diamonx","2.5M"}, {"PhantomII","5M"}, {"Prasanite","10M"},
            {"OverseerHelmet","13M"}, {"OVERSEER ARMOR","14M"}, {"DragonlordHelmet","15M"},
            {"DragonlordArmor","16M"}, {"DestroyerHood","19M"}, {"DestroyerArmor","20M"},
            {"Korblox Armor","22M"}, {"Korblox Helm","23M"}, {"Stasis Body","25M"},
            {"Stasis Head","26M"}, {"Ultia Body","29M"}, {"Ultia Hood","30M"},
            {"Deviant Headgear","32.5M"}, {"Deviant Suit","33.5M"}, {"Immortal Bulwark","35M"},
            {"Undying Guard","36M"}, {"Demonis Main","37M"}, {"Demonis Core","38M"},
        }
        local reqOf = {}
        for _, e in ipairs(armorShop) do reqOf[e[1]] = e[2] end

        local WARN = Color3.fromRGB(230, 180, 80)
        local OKC  = Color3.fromRGB(120, 220, 130)
        local ERRC = Color3.fromRGB(230, 120, 120)

        -- Scroll container: holds the selector, the (inline, expanding) list, the
        -- status readout, the BUY button AND the Auto Equip All Armor toggle,
        -- stacked by a UIListLayout. Opening the list pushes the rows below it down
        -- and grows the canvas, so the user can scroll down to the buy / auto-equip
        -- buttons with the dropdown still open (instead of the list overlaying them).
        -- updateLayoutPositions finds it by name to place/show it on the Armor tab.
        -- Armor tab scroll -- modelled on the Shops tab's ShopsPanel: one roomy,
        -- full-height ScrollingFrame that owns the whole tab body. Everything (stats,
        -- auto-equip toggle, shop selector, inline list, buy) stacks inside via a
        -- UIListLayout, so opening the shop list pushes the rows down and you scroll
        -- THIS panel past the open list -- the "extra scroll", exactly like Shops.
        local shopScroll = Instance.new("ScrollingFrame")
        shopScroll.Name = "ArmorShopScroll"
        shopScroll.BackgroundTransparency = 1
        shopScroll.BorderSizePixel = 0
        shopScroll.ScrollBarThickness = 5
        shopScroll.ScrollBarImageColor3 = colors.accent
        shopScroll.ScrollingDirection = Enum.ScrollingDirection.Y
        shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        shopScroll.Visible = false
        shopScroll.ZIndex = 10000
        shopScroll.Parent = contentArea
        do
            local l = Instance.new("UIListLayout")
            l.Padding = UDim.new(0, 8); l.SortOrder = Enum.SortOrder.LayoutOrder
            l.Parent = shopScroll
            -- Reflow the scroll height + Refresh dock whenever content grows/shrinks
            -- (shop list open/close, owned-armor list open/close), so the bottom gap
            -- stays collapsed. layoutArmorColumn no-ops off the Armor tab.
            l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if layoutArmorColumn then layoutArmorColumn() end
            end)
        end

        -- Selector (the drop trigger).
        local selector = Instance.new("TextButton")
        selector.Name = "ArmorShopSelector"
        selector.LayoutOrder = 1
        selector.Size = UDim2.new(1, -4, 0, 32)
        selector.BackgroundColor3 = getTheme().inputBg
        selector.BorderSizePixel = 0
        selector.Text = "  Armor Shop:  Select armor..."
        selector.TextColor3 = getTheme().textDim
        selector.TextXAlignment = Enum.TextXAlignment.Left
        selector.Font = Enum.Font.Gotham
        selector.TextSize = 13
        selector.ZIndex = 10001
        selector.Parent = shopScroll
        addCorner(selector, 6)
        addStroke(selector, getTheme().borderLight, 1, true)

        -- Drop list -- same format as the Shops-tab sections: a collapsible wrap
        -- holding a "Filter..." box and a fixed-height (150px) inner scroll. Opening
        -- it pushes the rows below down and grows the outer canvas, so the buy/toggle
        -- rows stay reachable by scrolling with the list open.
        local listWrap = Instance.new("Frame")
        listWrap.Name = "ArmorShopList"
        listWrap.LayoutOrder = 2
        listWrap.Size = UDim2.new(1, -4, 0, 0)
        listWrap.AutomaticSize = Enum.AutomaticSize.Y
        listWrap.BackgroundTransparency = 1
        listWrap.Visible = false
        listWrap.ZIndex = 10001
        listWrap.Parent = shopScroll
        do
            local wl = Instance.new("UIListLayout")
            wl.Padding = UDim.new(0, 4); wl.SortOrder = Enum.SortOrder.LayoutOrder
            wl.Parent = listWrap
        end

        local filterBox = Instance.new("TextBox")
        filterBox.LayoutOrder = 1
        filterBox.Size = UDim2.new(1, 0, 0, 26)
        filterBox.BackgroundColor3 = getTheme().inputBg
        filterBox.BorderSizePixel = 0
        filterBox.PlaceholderText = "Filter..."
        filterBox.Text = ""
        filterBox.TextColor3 = getTheme().text
        filterBox.Font = Enum.Font.Gotham
        filterBox.TextSize = 12
        filterBox.ClearTextOnFocus = false
        filterBox.TextXAlignment = Enum.TextXAlignment.Left
        filterBox.ZIndex = 10003
        filterBox.Parent = listWrap
        addCorner(filterBox, 4)
        do
            local fp = Instance.new("UIPadding"); fp.PaddingLeft = UDim.new(0, 6); fp.Parent = filterBox
        end

        -- Drop list: fixed-height inner scroll, exactly like the Shops-tab sections.
        -- It stays compact (150px) so opening it doesn't bury the buy button; you
        -- scroll PAST it using the roomy outer armor scroll (hover off the list),
        -- which is how the Shops tab's "extra scroll" works.
        local listScroll = Instance.new("ScrollingFrame")
        listScroll.LayoutOrder = 2
        listScroll.Size = UDim2.new(1, 0, 0, 150)
        listScroll.BackgroundColor3 = getTheme().dropdown
        listScroll.BorderSizePixel = 0
        listScroll.ScrollBarThickness = 4
        listScroll.ScrollBarImageColor3 = colors.accent
        listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listScroll.ZIndex = 10003
        listScroll.Parent = listWrap
        addCorner(listScroll, 6)
        do
            local sl = Instance.new("UIListLayout")
            sl.Padding = UDim.new(0, 2); sl.SortOrder = Enum.SortOrder.LayoutOrder
            sl.Parent = listScroll
        end

        -- Status readout.
        local status = Instance.new("TextLabel")
        status.Name = "ArmorBuyStatus"
        status.LayoutOrder = 3
        status.Size = UDim2.new(1, -4, 0, 36)
        status.BackgroundColor3 = getTheme().surface
        status.BorderSizePixel = 0
        status.Text = ""
        status.Visible = false  -- collapsed until an armor is picked or a buy runs
        status.TextColor3 = getTheme().textDim
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.TextYAlignment = Enum.TextYAlignment.Center
        status.TextWrapped = true
        status.Font = Enum.Font.Gotham
        status.TextSize = 13
        status.ZIndex = 10001
        status.Parent = shopScroll
        addCorner(status, 8)
        addStroke(status, getTheme().borderLight, 1, true)
        do
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
            pad.Parent = status
        end

        -- Buy button.
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "ArmorBuyBtn"
        buyBtn.LayoutOrder = 4
        buyBtn.Size = UDim2.new(1, -4, 0, 34)
        buyBtn.BackgroundColor3 = colors.accent
        buyBtn.BorderSizePixel = 0
        buyBtn.Text = "BUY ARMOR"
        buyBtn.TextColor3 = colors.text
        buyBtn.Font = Enum.Font.GothamMedium
        buyBtn.TextSize = 14
        buyBtn.ZIndex = 10001
        buyBtn.Parent = shopScroll
        addCorner(buyBtn, 6)

        -- Move the existing "Auto Equip All Armor" toggle into the scroll as the
        -- top row (LayoutOrder 0): directly below the stat panel ("armor status")
        -- and above the Armor Shop dropdown selector (1).
        equipAllContainer.Parent = shopScroll
        equipAllContainer.LayoutOrder = 0
        equipAllContainer.Size = UDim2.new(1, -4, 0, 42)
        equipAllContainer.Visible = true

        local sel = nil        -- chosen armor name (nil = none)
        local buyBusy = false

        local function setStatusDefault()
            if sel then
                status.Visible = true
                status.Text = sel .. "   |   Requires Level " .. (reqOf[sel] or "?")
                status.TextColor3 = getTheme().text
            else
                status.Visible = false
                status.Text = ""
            end
        end

        -- (Re)build the option rows into the inner scroll, honouring the filter box.
        -- Mirrors the Shops-tab rebuildOptions so both dropdowns behave identically.
        local optionBtns = {}
        local function rebuildOptions()
            for _, b in ipairs(optionBtns) do b:Destroy() end
            table.clear(optionBtns)
            local f = filterBox.Text:lower()
            local shown = 0
            for _, e in ipairs(armorShop) do
                local nm, req = e[1], e[2]
                local label = nm .. "   (Lvl " .. req .. ")"
                if f == "" or label:lower():find(f, 1, true) then
                    shown = shown + 1
                    local ob = Instance.new("TextButton")
                    ob.LayoutOrder = shown
                    ob.Size = UDim2.new(1, -4, 0, 26)
                    ob.BackgroundColor3 = getTheme().surface
                    ob.BorderSizePixel = 0
                    ob.Text = "  " .. label
                    ob.TextColor3 = getTheme().text
                    ob.TextXAlignment = Enum.TextXAlignment.Left
                    ob.Font = Enum.Font.Gotham
                    ob.TextSize = 12
                    ob.ZIndex = 10004
                    ob.Parent = listScroll
                    addCorner(ob, 4)
                    ob.MouseButton1Click:Connect(function()
                        sel = nm
                        selector.Text = "  Armor Shop:  " .. nm
                        selector.TextColor3 = getTheme().text
                        listWrap.Visible = false
                        setStatusDefault()
                    end)
                    optionBtns[#optionBtns + 1] = ob
                end
            end
            if shown == 0 then
                local ob = Instance.new("TextLabel")
                ob.Size = UDim2.new(1, -4, 0, 24); ob.BackgroundTransparency = 1
                ob.Text = "  (no match)"; ob.TextColor3 = getTheme().textDim
                ob.Font = Enum.Font.Gotham; ob.TextSize = 12
                ob.TextXAlignment = Enum.TextXAlignment.Left
                ob.ZIndex = 10004; ob.Parent = listScroll
                optionBtns[#optionBtns + 1] = ob
            end
        end

        filterBox:GetPropertyChangedSignal("Text"):Connect(function()
            if listWrap.Visible then rebuildOptions() end
        end)

        selector.MouseButton1Click:Connect(function()
            listWrap.Visible = not listWrap.Visible
            if listWrap.Visible then rebuildOptions() end
        end)

        buyBtn.MouseButton1Click:Connect(function()
            if buyBusy then return end
            status.Visible = true  -- any buy path shows a message, so reveal the readout
            if not sel then
                status.Text = "Pick an armor from the shop first."; status.TextColor3 = WARN; return
            end
            if not DMscapePurchaseEvent then
                status.Text = "Armor purchase event is missing."; status.TextColor3 = ERRC; return
            end
            buyBusy = true
            local nm = sel
            status.Text = "Buying " .. nm .. " ..."
            status.TextColor3 = getTheme().textDim
            local done, conn = false, nil
            if ShopFeedbackEvent then
                conn = ShopFeedbackEvent.OnClientEvent:Connect(function(ok, msg)
                    if done then return end
                    done = true
                    if conn then conn:Disconnect() end
                    buyBusy = false
                    if ok then
                        status.Text = "Bought " .. nm .. "!  Equip it from the list above."
                        status.TextColor3 = OKC
                    else
                        status.Text = tostring(msg or "Purchase failed.")
                        status.TextColor3 = ERRC
                    end
                end)
            end
            DMscapePurchaseEvent:FireServer(nm)
            -- Fallback if the server never replies (or ShopFeedbackEvent is gone).
            task.delay(4, function()
                if done then return end
                done = true
                if conn then conn:Disconnect() end
                buyBusy = false
                status.Text = ShopFeedbackEvent and "No response from the server. Try again."
                    or ("Fired purchase for " .. nm .. ".")
                status.TextColor3 = WARN
            end)
        end)
    end)()

    -- ---- Farm-tab live status panel (shares infoPanel's region) ----------
    farmStatusPanel = Instance.new("Frame")
    farmStatusPanel.Name = "FarmStatusPanel"
    farmStatusPanel.Size = UDim2.new(1, 0, 0, 190)
    farmStatusPanel.BackgroundColor3 = getTheme().surface
    farmStatusPanel.BorderSizePixel = 0
    farmStatusPanel.Visible = false
    farmStatusPanel.ZIndex = 9999
    farmStatusPanel.LayoutOrder = 1
    farmStatusPanel.Parent = farmScroll
    addCorner(farmStatusPanel, 8)
    addStroke(farmStatusPanel, getTheme().borderLight, 1, true)

    local farmStatusTitle = Instance.new("TextLabel")
    farmStatusTitle.Size = UDim2.new(1, -20, 0, 22)
    farmStatusTitle.Position = UDim2.new(0, 10, 0, 6)
    farmStatusTitle.BackgroundTransparency = 1
    farmStatusTitle.Text = "Farm Status"
    farmStatusTitle.TextColor3 = colors.accent
    farmStatusTitle.TextXAlignment = Enum.TextXAlignment.Left
    farmStatusTitle.Font = Enum.Font.GothamBold
    farmStatusTitle.TextSize = 14
    farmStatusTitle.ZIndex = 10001
    farmStatusTitle.Parent = farmStatusPanel

    -- Line 1: the running/idle pill (coloured), the rest goes in the body.
    local farmStatusState = Instance.new("TextLabel")
    farmStatusState.Size = UDim2.new(1, -20, 0, 20)
    farmStatusState.Position = UDim2.new(0, 10, 0, 28)
    farmStatusState.BackgroundTransparency = 1
    farmStatusState.Text = "Auto Farm:  OFF"
    farmStatusState.TextColor3 = colors.danger
    farmStatusState.TextXAlignment = Enum.TextXAlignment.Left
    farmStatusState.Font = Enum.Font.GothamMedium
    farmStatusState.TextSize = 13
    farmStatusState.ZIndex = 10001
    farmStatusState.Parent = farmStatusPanel

    local farmStatusBody = Instance.new("TextLabel")
    farmStatusBody.Size = UDim2.new(1, -20, 1, -54)
    farmStatusBody.Position = UDim2.new(0, 10, 0, 50)
    farmStatusBody.BackgroundTransparency = 1
    farmStatusBody.Text = ""
    farmStatusBody.TextColor3 = getTheme().textDim
    farmStatusBody.TextXAlignment = Enum.TextXAlignment.Left
    farmStatusBody.TextYAlignment = Enum.TextYAlignment.Top
    farmStatusBody.TextWrapped = true
    farmStatusBody.Font = Enum.Font.Gotham
    farmStatusBody.TextSize = 13
    farmStatusBody.ZIndex = 10001
    farmStatusBody.Parent = farmStatusPanel

    -- Fields 5-10: stats for a given mob name (reads MobData/cleanName/abbr).
    local function getMobStatsBlock(rawName)
        local name = rawName and cleanName(rawName) or nil
        if not name or name == "" then
            return "Mob:  —"
        end
        local d = MobData and MobData.GetMobData(name)
        if not d then
            return "Mob:  " .. name .. "\n(no stat data)"
        end
        local dropsStr = "none"
        if type(d.DROPS) == "table" and #d.DROPS > 0 then
            local ds = {}
            for _, dr in ipairs(d.DROPS) do
                local pct = type(dr.Chance) == "number"
                    and (string.format("%g", dr.Chance * 100) .. "%") or "?"
                ds[#ds + 1] = tostring(dr.Tool) .. " (" .. pct .. ")"
            end
            dropsStr = table.concat(ds, ", ")
        end
        -- HP shows the live target's current/max while it's spawned (updates as it
        -- takes damage mid-farm); falls back to max/max when no instance is live.
        -- Prefer the EXACT model the farm loop is hitting (its Humanoid ticks down);
        -- mob models carry decorated names ("... Health: x/y (level n)") so a plain
        -- by-name lookup would miss it, and same-named copies are indistinguishable.
        local curHP, liveMax
        local liveMob = farmActive and farmRuntime.model or nil
        if liveMob and liveMob.Parent then
            -- Parse the exact farmed model's live "Health: cur/max" name suffix.
            local c, m = tostring(liveMob.Name):match("Health:%s*([%d%.eE%+%-]+)%s*/%s*([%d%.eE%+%-]+)")
            curHP, liveMax = tonumber(c), tonumber(m)
        end
        if not curHP then
            curHP, liveMax = getCurrentHealthByName(name)
        end
        local hpLine
        if curHP then
            local maxHP = liveMax or d.HEALTH
            hpLine = "HP:  " .. abbr(math.max(0, math.floor(curHP + 0.5))) .. "/" .. abbr(maxHP)
        else
            hpLine = "HP:  " .. abbr(d.HEALTH) .. "/" .. abbr(d.HEALTH)
        end
        return table.concat({
            "Mob:  " .. name,
            hpLine,
            "DMG:  " .. abbr(d.MOBDAMAGE),
            "Speed:  " .. abbr(d.WALKSPEED),
            "Respawn:  " .. tostring(d.RESPAWNTIME) .. "s",
            "Drops:  " .. dropsStr,
        }, "\n")
    end

    -- Assign the forward-declared farm-status updater.
    updateFarmStatus = function()
        if not farmStatusPanel then return end
        -- Only visible on the Farm tab. It stays visible while the mob-select
        -- popup is open (the farm column is pushed down below the popup).
        if currentTab ~= "Farm" then
            farmStatusPanel.Visible = false
            return
        end
        farmStatusPanel.Visible = true
        farmStatusPanel.BackgroundColor3 = getTheme().surface

        farmStatusState.Text = "Auto Farm:  " .. (farmActive and "RUNNING" or "OFF")
        farmStatusState.TextColor3 = farmActive and colors.success or colors.danger

        -- Weapon: live equipped tool while farming, else whatever's held now.
        local weapon = farmRuntime.weapon
        if weapon == "" then
            local char = localPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            weapon = tool and tool.Name or "none"
        end

        -- The mob whose detailed stats we show: the live target when farming,
        -- otherwise the first picked farm mob (falling back to selectedItem).
        local focusName = farmActive and farmRuntime.current or ""
        if focusName == "" then
            focusName = saveData.farmMobs[1] or selectedItem or ""
        end

        local lines = {
            "Weapon:  " .. weapon,
            "Farming:  " .. (farmActive and (farmRuntime.current ~= "" and farmRuntime.current or "searching...") or "—"),
            "Next:  " .. (farmActive and (farmRuntime.nextName ~= "" and farmRuntime.nextName or "—") or "—"),
            "",
            getMobStatsBlock(focusName),
        }
        farmStatusBody.Text = table.concat(lines, "\n")
    end

    -- Assign the forward-declared updater.
    updateInfoPanel = function()
        if not infoPanel then return end
        local tab = currentTab
        local relevant = (tab == "Item" or tab == "Armor" or tab == "Bosses")
        if not relevant then
            infoPanel.Visible = false
            return
        end
        infoPanel.Visible = true
        infoBody.TextColor3 = getTheme().textDim
        infoPanel.BackgroundColor3 = getTheme().surface

        local sel = selectedItem
        if not sel then
            infoTitle.Text = "Info"
            infoBody.Text = "Select a name above to view its stats."
            return
        end

        local name = cleanName(sel)
        local lines = {}

        if tab == "Item" then
            local d = WeaponData and WeaponData.GetWeaponData(name)
            if d then
                local dmg = (d.MINDAMAGE == d.MAXDAMAGE) and abbr(d.MINDAMAGE)
                    or (abbr(d.MINDAMAGE) .. "  -  " .. abbr(d.MAXDAMAGE))
                lines = {
                    "Damage:  " .. dmg,
                    "Cooldown:  " .. tostring(d.COOLDOWN) .. "s",
                    "Type:  " .. (tostring(d.WEAPONTYPE):upper() == "MAGE" and "Mage" or "Melee"),
                }
            end
        elseif tab == "Armor" then
            local d = ArmorData2 and ArmorData2.GetArmorData(name)
            if d then
                lines = {
                    "Health:  " .. abbr(d.HEALTH),
                    "Speed:  " .. abbr(d.SPEED),
                    "Type:  " .. (tostring(d.TYPE):upper() == "HELMET" and "Helmet" or "Body Armor"),
                }
            end
        elseif tab == "Bosses" then
            local d = MobData and MobData.GetMobData(name)
            if d then
                lines = {
                    "Health:  " .. abbr(d.HEALTH),
                    "Damage:  " .. abbr(d.MOBDAMAGE),
                    "Speed:  " .. abbr(d.WALKSPEED),
                    "Spawned:  " .. (bossSpawned(name) and "Yes" or "No"),
                }
            end
        end

        infoTitle.Text = name
        if #lines == 0 then
            infoBody.Text = "No stat data found for this name."
        else
            infoBody.Text = table.concat(lines, "\n")
        end
    end

    -- Sort key provider: (health, damage) for a name on a given tab. Unknown
    -- names return math.huge so they sink to the bottom of the list. Results are
    -- memoized because populateDropdown re-sorts on every keystroke/tab switch.
    local statCache = {}
    statHealthDmg = function(tab, rawName)
        local n = cleanName(rawName)
        local key = tab .. "|" .. n
        local cached = statCache[key]
        if cached then return cached[1], cached[2] end
        local h, dmg = math.huge, math.huge
        if tab == "Item" then
            local d = WeaponData and WeaponData.GetWeaponData(n)
            if d then h, dmg = 0, (d.MAXDAMAGE or d.MINDAMAGE or 0) end
        elseif tab == "Armor" then
            local d = ArmorData2 and ArmorData2.GetArmorData(n)
            if d then h, dmg = (d.HEALTH or 0), 0 end
        elseif tab == "Mobs" or tab == "Bosses" then
            local d = MobData and MobData.GetMobData(n)
            if d then h, dmg = (d.HEALTH or 0), (d.MOBDAMAGE or 0) end
        end
        statCache[key] = {h, dmg}
        return h, dmg
    end

    -- The dropdown popup opens over the same region as this panel, so hide the
    -- panel while the popup is open (otherwise the opaque panel covers the list).
    dropdown:GetPropertyChangedSignal("Visible"):Connect(function()
        if dropdown.Visible then
            infoPanel.Visible = false
            -- Close the inline auto-equip weapon list if it's open.
            if autoEquipRow then
                local lw = autoEquipRow:FindFirstChild("AutoEquipList")
                if lw then lw.Visible = false end
            end
        else
            updateInfoPanel()
            updateFarmStatus()
            if updateAutoEquipPanel then updateAutoEquipPanel() end
        end
        -- On the Farm tab keep the controls visible; layoutFarmColumn() pushes the
        -- column down below the popup while it's open and restores it when closed.
        if farmScroll then
            farmScroll.Visible = (currentTab == "Farm")
            layoutFarmColumn()
        end
    end)
end

-- ============================================================
-- FARM-TAB "AUTO EQUIP WEAPON" - a dropdown selector (in the farm scroll column,
-- directly under the Auto Farm toggle) that opens an overlay popup. The popup
-- lets you search the weapons you actually own in your inventory and pick one to
-- keep equipped even through death/respawn. Its own do-block + a single state
-- table keep it well under the main chunk's 200-local ceiling.
-- ============================================================
do
    local W = { buttons = {}, session = 0 }

    -- Stats for the weapon currently held in the character (nil -> "none"). Kept
    -- fully self-contained (WeaponData/abbr live inside the closure) so it costs
    -- the main chunk just one local against Luau's 200-register ceiling.
    local function heldWeaponStats()
        local char = localPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        local held = tool and tool.Name
        if not held or held == "" then
            return "Held weapon:  none"
        end
        local lib = game:GetService("ReplicatedStorage"):FindFirstChild("Library")
        local ok, d = pcall(function()
            return require(lib:FindFirstChild("WeaponDataStorage")).GetWeaponData(held)
        end)
        if not ok or not d then
            return "Held:  " .. held .. "\n(no stat data)"
        end
        local function ab(n)
            if type(n) ~= "number" then return tostring(n) end
            local suf = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc"}
            local i, x = 1, n
            while math.abs(x) >= 1000 and i < #suf do x = x / 1000; i = i + 1 end
            if i == 1 then return string.format("%d", x) end
            return (string.format("%.2f", x):gsub("%.?0+$", "")) .. suf[i]
        end
        local dmg = (d.MINDAMAGE == d.MAXDAMAGE) and ab(d.MINDAMAGE)
            or (ab(d.MINDAMAGE) .. "  -  " .. ab(d.MAXDAMAGE))
        local wtype = (tostring(d.WEAPONTYPE):upper() == "MAGE") and "Staff" or "Melee"
        return table.concat({
            "Held:  " .. held,
            "Damage:  " .. dmg,
            "Speed:  " .. tostring(d.COOLDOWN) .. "s cd",
            "Type:  " .. wtype,
        }, "\n")
    end

    -- The weapons you own right now: every Tool in your inventory that isn't a
    -- piece of armor. Rebuilt each time the popup opens so it stays current.
    local armorLookup = {}
    for _, n in ipairs(armorList) do armorLookup[n] = true end
    local function getOwnedWeapons()
        local seen, out = {}, {}
        for _, name in ipairs(getPlayerInventory()) do
            if not armorLookup[name] and not seen[name] then
                seen[name] = true
                out[#out + 1] = name
            end
        end
        table.sort(out)
        return out
    end

    -- Equip the saved weapon, retrying while the backpack repopulates after a
    -- respawn. Does nothing unless the toggle is ON and a weapon is chosen.
    local function equipNow()
        if not saveData.autoEquipEnabled then return end
        local name = saveData.autoEquipWeapon
        if not name or name == "" then return end
        W.session = W.session + 1
        local mine = W.session
        task.spawn(function()
            for _ = 1, 20 do
                if mine ~= W.session or not saveData.autoEquipEnabled
                    or saveData.autoEquipWeapon ~= name then return end
                if equipItem(name) then return end
                task.wait(0.5)
            end
        end)
    end

    -- Slides the toggle knob + recolours track/status to match the given state.
    local function setSwitchVisual(on)
        if not W.track then return end
        W.track.BackgroundColor3 = on and colors.success or colors.danger
        local target = on and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 0, 0.5, 0)
        -- Snap if the knob isn't rendered yet (tween throws off-screen); see farm toggle.
        local ok = pcall(function()
            W.knob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end)
        if not ok then W.knob.Position = target end
    end

    -- Refresh the row's selector label + toggle, and hide the popup off-tab.
    updateAutoEquipPanel = function()
        -- Bail if a reload has superseded this build. The old run's GUI is destroyed,
        -- but its CharacterAdded/ChildAdded handlers stay connected and keep calling
        -- this (and W.dock below), reparenting now-destroyed labels -- which spams
        -- "The Parent property of TextLabel is locked" on every tool swap / respawn.
        -- A dead screenGui means we're a zombie from a previous load: do nothing.
        if not (screenGui and screenGui.Parent) then return end
        if not autoEquipRow then return end
        local cur = saveData.autoEquipWeapon
        if W.value then
            if cur and cur ~= "" then
                W.value.Text = cur
                W.value.TextColor3 = colors.success
            else
                W.value.Text = "None - tap to pick"
                W.value.TextColor3 = getTheme().textDim
            end
        end
        if W.stats then
            W.stats.Text = heldWeaponStats()
        end
        setSwitchVisual(saveData.autoEquipEnabled == true)
        if W.setStrongestVisual then W.setStrongestVisual(saveData.autoEquipStrongest == true) end
        if currentTab ~= "Farm" and W.listWrap then
            W.listWrap.Visible = false
        end
    end

    -- Flip the on/off toggle: ON re-equips the chosen weapon, OFF stops.
    local function setEnabled(on)
        -- Manual pick and "strongest" fight over the equipped tool, so turning
        -- the manual toggle ON forces the strongest toggle OFF.
        if on and saveData.autoEquipStrongest then
            saveData.autoEquipStrongest = false
            W.strongestSession = (W.strongestSession or 0) + 1
            if W.setStrongestVisual then W.setStrongestVisual(false) end
        end
        saveData.autoEquipEnabled = on and true or false
        saveDataToFile()
        if on then equipNow() else W.session = W.session + 1 end
        updateAutoEquipPanel()
    end

    -- Rebuild the popup's owned-weapon buttons (called every time it opens).
    local pick  -- forward decl (buttons call it)
    local function rebuildOwned()
        for _, b in pairs(W.buttons) do b:Destroy() end
        W.buttons = {}
        local cur = saveData.autoEquipWeapon
        local owned = getOwnedWeapons()

        -- "None" row at the very top to turn auto-equip off.
        local noneBtn = Instance.new("TextButton")
        noneBtn.Size = UDim2.new(1, 0, 0, 30)
        noneBtn.BackgroundColor3 = (not cur or cur == "") and colors.accent or getTheme().inputBg
        noneBtn.BorderSizePixel = 0
        noneBtn.Text = "None (off)"
        noneBtn.TextColor3 = (not cur or cur == "") and colors.text or getTheme().textDim
        noneBtn.Font = Enum.Font.GothamMedium
        noneBtn.TextSize = 12
        noneBtn.TextXAlignment = Enum.TextXAlignment.Left
        noneBtn.LayoutOrder = 0
        noneBtn.ZIndex = 10052
        noneBtn.Parent = W.scroll
        addCorner(noneBtn, 5)
        addPadding(noneBtn, 0, 0, 8, 8)
        noneBtn.MouseButton1Click:Connect(function() pick(nil) end)
        W.buttons["\0none"] = noneBtn

        if #owned == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 38)
            empty.BackgroundTransparency = 1
            empty.Text = "No weapons in your inventory"
            empty.TextColor3 = getTheme().textDim
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.TextXAlignment = Enum.TextXAlignment.Left
            empty.LayoutOrder = 1
            empty.ZIndex = 10052
            empty.Parent = W.scroll
            addPadding(empty, 0, 0, 8, 8)
            W.buttons["\0empty"] = empty
            return
        end

        for i, name in ipairs(owned) do
            local on = (name == cur)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.BackgroundColor3 = on and colors.accent or getTheme().inputBg
            btn.BorderSizePixel = 0
            btn.Text = name
            btn.TextColor3 = on and colors.text or getTheme().textDim
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextTruncate = Enum.TextTruncate.AtEnd
            btn.LayoutOrder = i
            btn.ZIndex = 10052
            btn.Parent = W.scroll
            addCorner(btn, 5)
            addPadding(btn, 0, 0, 8, 8)
            btn.MouseButton1Click:Connect(function() pick(name) end)
            W.buttons[name] = btn
        end
    end

    -- Open/close the INLINE dropdown. No overlay, no lift/glue: the list is a child
    -- of the card in the farm column, so it just expands the card and the roomy
    -- farmScroll handles scrolling past it (exactly like the Shops/Armor dropdowns).
    local function openPopup()
        if not W.listWrap then return end
        -- Never open on top of the mob-select popup.
        dropdown.Visible = false
        dropdownOpen = false
        if W.search then W.search.Text = "" end
        rebuildOwned()
        W.listWrap.Visible = true
    end
    local function closePopup()
        if W.listWrap then W.listWrap.Visible = false end
    end

    -- Clicking a weapon selects it (nil turns auto-equip off). Assigned to the
    -- forward-declared upvalue so the button handlers above can reach it.
    pick = function(name)
        if name == "" then name = nil end
        saveData.autoEquipWeapon = name
        -- Picking a real weapon turns the toggle ON; picking "None" turns it OFF.
        saveData.autoEquipEnabled = (name ~= nil)
        -- A manual pick also overrides the "strongest" toggle (they'd conflict).
        if name and saveData.autoEquipStrongest then
            saveData.autoEquipStrongest = false
            W.strongestSession = (W.strongestSession or 0) + 1
            if W.setStrongestVisual then W.setStrongestVisual(false) end
        end
        saveDataToFile()
        if name then equipNow() else W.session = W.session + 1 end
        closePopup()
        updateAutoEquipPanel()
    end

    -- Build the selector card (lives in the farm scroll column). Stacked by a
    -- UIListLayout so the dropdown is INLINE (like the Shops/Armor shop): opening it
    -- pushes the rows below down and grows the card, and the roomy farm column
    -- (farmScroll) scrolls past it -- no floating overlay, no glue needed.
    do
        local row = Instance.new("Frame")
        row.Name = "AutoEquipRow"
        row.Size = UDim2.new(1, 0, 0, 0)
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.BackgroundColor3 = getTheme().surface
        row.BorderSizePixel = 0
        row.ZIndex = 9999
        row.LayoutOrder = 6  -- below Dodge Boss AoE (3) + Dodge Offset X/Y (4,5)
        row.Parent = farmScroll
        addCorner(row, 8)
        addStroke(row, getTheme().borderLight, 1, true)
        autoEquipRow = row
        do
            local pad = Instance.new("UIPadding")
            pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8)
            pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12)
            pad.Parent = row
            local v = Instance.new("UIListLayout")
            v.Padding = UDim.new(0, 8); v.SortOrder = Enum.SortOrder.LayoutOrder
            v.Parent = row
        end

        -- Each sub-section is wrapped in its own do-block so its locals free right
        -- away -- the whole auto-equip block counts against the main chunk's 200-
        -- register ceiling, and keeping every widget in a live local overflows it.
        do  -- title
            local title = Instance.new("TextLabel")
            title.LayoutOrder = 1
            title.Size = UDim2.new(1, 0, 0, 20)
            title.BackgroundTransparency = 1
            title.Text = "Auto Equip Weapon"
            title.TextColor3 = colors.accent
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Font = Enum.Font.GothamBold
            title.TextSize = 14
            title.ZIndex = 10000
            title.Parent = row
        end

        do  -- selector bar (opens the inline list)
            local selector = Instance.new("TextButton")
            selector.LayoutOrder = 2
            selector.Size = UDim2.new(1, 0, 0, 28)
            selector.BackgroundColor3 = getTheme().inputBg
            selector.BorderSizePixel = 0
            selector.Text = ""
            selector.AutoButtonColor = false
            selector.ZIndex = 10000
            selector.Parent = row
            addCorner(selector, 6)
            addStroke(selector, getTheme().borderLight, 1, true)

            local value = Instance.new("TextLabel")
            value.Size = UDim2.new(1, -34, 1, 0)
            value.Position = UDim2.new(0, 10, 0, 0)
            value.BackgroundTransparency = 1
            value.Text = "None - tap to pick"
            value.TextColor3 = getTheme().textDim
            value.TextXAlignment = Enum.TextXAlignment.Left
            value.TextTruncate = Enum.TextTruncate.AtEnd
            value.Font = Enum.Font.Gotham
            value.TextSize = 12
            value.ZIndex = 10001
            value.Parent = selector
            W.value = value

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 24, 1, 0)
            arrow.Position = UDim2.new(1, -26, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▾"
            arrow.TextColor3 = getTheme().textMuted
            arrow.TextSize = 14
            arrow.Font = Enum.Font.GothamMedium
            arrow.ZIndex = 10001
            arrow.Parent = selector

            selector.MouseButton1Click:Connect(function()
                if W.listWrap and W.listWrap.Visible then closePopup() else openPopup() end
            end)
        end

        do  -- inline dropdown: filter box + fixed-height owned-weapon scroll
            local listWrap = Instance.new("Frame")
            listWrap.Name = "AutoEquipList"
            listWrap.LayoutOrder = 3
            listWrap.Size = UDim2.new(1, 0, 0, 0)
            listWrap.AutomaticSize = Enum.AutomaticSize.Y
            listWrap.BackgroundTransparency = 1
            listWrap.Visible = false
            listWrap.ZIndex = 10000
            listWrap.Parent = row
            do
                local wl = Instance.new("UIListLayout")
                wl.Padding = UDim.new(0, 4); wl.SortOrder = Enum.SortOrder.LayoutOrder
                wl.Parent = listWrap
            end
            W.listWrap = listWrap

            local search = Instance.new("TextBox")
            search.LayoutOrder = 1
            search.Size = UDim2.new(1, 0, 0, 26)
            search.BackgroundColor3 = getTheme().inputBg
            search.BorderSizePixel = 0
            search.Text = ""
            search.PlaceholderText = "Search your weapons..."
            search.PlaceholderColor3 = getTheme().textMuted
            search.TextColor3 = getTheme().text
            search.Font = Enum.Font.Gotham
            search.TextSize = 12
            search.TextXAlignment = Enum.TextXAlignment.Left
            search.ClearTextOnFocus = false
            search.ZIndex = 10003
            search.Parent = listWrap
            addCorner(search, 6)
            do local sp = Instance.new("UIPadding"); sp.PaddingLeft = UDim.new(0, 8); sp.PaddingRight = UDim.new(0, 8); sp.Parent = search end
            W.search = search

            local scroll = Instance.new("ScrollingFrame")
            scroll.LayoutOrder = 2
            scroll.Size = UDim2.new(1, 0, 0, 150)
            scroll.BackgroundColor3 = getTheme().dropdown
            scroll.BorderSizePixel = 0
            scroll.ScrollBarThickness = 4
            scroll.ScrollBarImageColor3 = colors.accent
            scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            scroll.ZIndex = 10003
            scroll.Parent = listWrap
            addCorner(scroll, 6)
            do
                local sl = Instance.new("UIListLayout")
                sl.Padding = UDim.new(0, 2); sl.SortOrder = Enum.SortOrder.LayoutOrder
                sl.Parent = scroll
                local sp = Instance.new("UIPadding")
                sp.PaddingTop = UDim.new(0, 3); sp.PaddingBottom = UDim.new(0, 3)
                sp.PaddingLeft = UDim.new(0, 3); sp.PaddingRight = UDim.new(0, 3)
                sp.Parent = scroll
            end
            W.scroll = scroll

            -- Live filter over the owned-weapon buttons.
            search:GetPropertyChangedSignal("Text"):Connect(function()
                local q = search.Text:lower()
                for key, btn in pairs(W.buttons) do
                    if key == "\0none" or key == "\0empty" then
                        btn.Visible = true
                    else
                        btn.Visible = (q == "" or key:lower():find(q, 1, true) ~= nil)
                    end
                end
            end)
        end

        do  -- live held-weapon stats
            local stats = Instance.new("TextLabel")
            stats.LayoutOrder = 4
            stats.Size = UDim2.new(1, 0, 0, 64)
            stats.BackgroundTransparency = 1
            stats.Text = "Held weapon:  none"
            stats.TextColor3 = getTheme().textDim
            stats.TextXAlignment = Enum.TextXAlignment.Left
            stats.TextYAlignment = Enum.TextYAlignment.Top
            stats.Font = Enum.Font.Gotham
            stats.TextSize = 12
            stats.ZIndex = 10000
            stats.Parent = row
            W.stats = stats
        end

        do  -- iOS on/off toggle (label left, switch right)
            local toggleContainer = Instance.new("Frame")
            toggleContainer.LayoutOrder = 5
            toggleContainer.Size = UDim2.new(1, 0, 0, 28)
            toggleContainer.BackgroundTransparency = 1
            toggleContainer.ZIndex = 10000
            toggleContainer.Parent = row

            local toggleLabel = Instance.new("TextLabel")
            toggleLabel.Size = UDim2.new(0.5, 0, 1, 0)
            toggleLabel.Position = UDim2.new(0, 0, 0, 0)
            toggleLabel.BackgroundTransparency = 1
            toggleLabel.Text = "Auto Equip"
            toggleLabel.TextColor3 = getTheme().text
            toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            toggleLabel.TextYAlignment = Enum.TextYAlignment.Center
            toggleLabel.Font = Enum.Font.GothamMedium
            toggleLabel.TextSize = 13
            toggleLabel.ZIndex = 10000
            toggleLabel.Parent = toggleContainer
            W.toggleLabel = toggleLabel

            local track = Instance.new("TextButton")
            track.Size = UDim2.new(0, 46, 0, 24)
            track.Position = UDim2.new(1, 0, 0.5, 0)
            track.AnchorPoint = Vector2.new(1, 0.5)
            track.BackgroundColor3 = colors.danger
            track.BorderSizePixel = 0
            track.Text = ""
            track.AutoButtonColor = false
            track.ZIndex = 10001
            track.Parent = toggleContainer
            addCorner(track, 12)
            W.track = track

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 24, 0, 24)
            knob.AnchorPoint = Vector2.new(0, 0.5)
            knob.Position = UDim2.new(0, 0, 0.5, 0)
            knob.BackgroundColor3 = colors.text
            knob.BorderSizePixel = 0
            knob.ZIndex = 10002
            knob.Parent = track
            addCorner(knob, 12)
            W.knob = knob

            track.MouseButton1Click:Connect(function()
                setEnabled(not saveData.autoEquipEnabled)
            end)
        end
    end

    -- ============================================================
    -- AUTO EQUIP STRONGEST WEAPON - a standalone iOS toggle row sized like
    -- the Auto Farm Mobs switch, sitting directly below the Auto Equip card.
    -- ON keeps the highest-damage weapon you own equipped (re-checked so it
    -- also grabs a stronger weapon picked up mid-run); mutually exclusive with
    -- the manual Auto Equip toggle. All state hangs off W (no new main-chunk
    -- locals) to respect Luau's 200-register ceiling.
    -- ============================================================
    W.strongestSession = 0

    -- Highest-damage owned weapon via WeaponDataStorage (MAXDAMAGE, then
    -- MINDAMAGE, then faster cooldown as tiebreaks). nil if none/no stat data.
    W.getStrongest = function()
        local lib = game:GetService("ReplicatedStorage"):FindFirstChild("Library")
        local store = lib and lib:FindFirstChild("WeaponDataStorage")
        if not store then return nil end
        local best, bMax, bMin, bCd
        for _, name in ipairs(getOwnedWeapons()) do
            local ok, d = pcall(function() return require(store).GetWeaponData(name) end)
            if ok and d then
                local mx = tonumber(d.MAXDAMAGE) or 0
                local mn = tonumber(d.MINDAMAGE) or 0
                local cd = tonumber(d.COOLDOWN) or 1
                local better
                if not best then better = true
                elseif mx ~= bMax then better = mx > bMax
                elseif mn ~= bMin then better = mn > bMin
                else better = cd < bCd end
                if better then best, bMax, bMin, bCd = name, mx, mn, cd end
            end
        end
        return best
    end

    -- Slide the knob + recolour track/status to match state (mirrors the
    -- Auto Farm Mobs switch). Safe to call before the row exists.
    W.setStrongestVisual = function(on)
        if not W.strongestTrack then return end
        W.strongestTrack.BackgroundColor3 = on and colors.success or colors.danger
        if W.strongestStatus then
            W.strongestStatus.Text = on and "ON" or "OFF"
            W.strongestStatus.TextColor3 = on and colors.success or colors.danger
        end
        local target = on and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 0, 0.5, 0)
        -- TweenPosition throws ("Can only tween objects in the workspace") when the
        -- knob isn't being rendered yet (e.g. during the load-time layout pass while
        -- the Farm tab is hidden). Snap instantly in that case so state stays correct
        -- without spamming the console.
        local ok = pcall(function()
            W.strongestKnob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end)
        if not ok then W.strongestKnob.Position = target end
    end

    -- Flip the strongest-equip toggle. ON switches the manual Auto Equip OFF
    -- (single driver) and launches a loop that keeps the strongest owned weapon
    -- equipped; OFF cancels the loop via the session token.
    W.setStrongestEnabled = function(on)
        on = on and true or false
        saveData.autoEquipStrongest = on
        W.strongestSession = (W.strongestSession or 0) + 1
        if on and saveData.autoEquipEnabled then
            saveData.autoEquipEnabled = false
            W.session = W.session + 1
            setSwitchVisual(false)
        end
        saveDataToFile()
        W.setStrongestVisual(on)
        if on then
            local mine = W.strongestSession
            task.spawn(function()
                while saveData.autoEquipStrongest and mine == W.strongestSession
                    and screenGui and screenGui.Parent do
                    -- pcall the WHOLE body: getStrongest/equipItem can throw or yield
                    -- during the death/respawn gap (nil Character, WaitForChild), and an
                    -- unguarded error here would kill this thread for good -- which is
                    -- exactly the "stops equipping after death" bug. Never let that happen.
                    pcall(function()
                        local best = W.getStrongest()
                        if best then equipItem(best) end
                    end)
                    task.wait(2)  -- re-check for a stronger pickup / re-equip after respawn
                end
            end)
        end
        updateAutoEquipPanel()
    end

    -- The standalone toggle row (full-width, 40px, iOS switch).
    do
        local row = Instance.new("Frame")
        row.Name = "AutoEquipStrongestRow"
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = getTheme().surface
        row.BorderSizePixel = 0
        row.ZIndex = 9999
        row.LayoutOrder = 7  -- directly below the Auto Equip Weapon card (6)
        row.Parent = farmScroll
        addCorner(row, 8)
        addStroke(row, getTheme().borderLight, 1, true)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = "Auto Equip Strongest"
        label.TextColor3 = getTheme().text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 13
        label.ZIndex = 10001
        label.Parent = row

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(0, 34, 1, 0)
        status.Position = UDim2.new(1, -64, 0, 0)
        status.BackgroundTransparency = 1
        status.Text = "OFF"
        status.TextColor3 = colors.danger
        status.TextXAlignment = Enum.TextXAlignment.Right
        status.TextYAlignment = Enum.TextYAlignment.Center
        status.Font = Enum.Font.GothamMedium
        status.TextSize = 12
        status.ZIndex = 10001
        status.Parent = row
        W.strongestStatus = status

        local track = Instance.new("TextButton")
        track.Size = UDim2.new(0, 46, 0, 24)
        track.Position = UDim2.new(1, -10, 0.5, 0)
        track.AnchorPoint = Vector2.new(1, 0.5)
        track.BackgroundColor3 = colors.danger
        track.BorderSizePixel = 0
        track.Text = ""
        track.AutoButtonColor = false
        track.ZIndex = 10002
        track.Parent = row
        addCorner(track, 12)
        W.strongestTrack = track

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 24, 0, 24)
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.Position = UDim2.new(0, 0, 0.5, 0)
        knob.BackgroundColor3 = colors.text
        knob.BorderSizePixel = 0
        knob.ZIndex = 10003
        knob.Parent = track
        addCorner(knob, 12)
        W.strongestKnob = knob

        track.MouseButton1Click:Connect(function()
            W.setStrongestEnabled(not saveData.autoEquipStrongest)
        end)
    end

    -- Restore the toggle's saved state (deferred so screenGui is parented and
    -- the character is ready before the loop's first equip).
    if saveData.autoEquipStrongest then
        task.defer(function() W.setStrongestEnabled(true) end)
    else
        W.setStrongestVisual(false)
    end

    -- (The floating overlay popup + its glue -- dismiss layer, toggle host/dock,
    -- positionAutoEquipPopup, and the scroll/position re-glue signals -- are gone:
    -- the weapon list is now an inline dropdown inside the card, so none of that
    -- machinery is needed. positionAutoEquipPopup stays nil; its callers are guarded.)

    updateAutoEquipPanel()

    -- Re-equip after every respawn so the weapon "sticks" through death.
    localPlayer.CharacterAdded:Connect(function(char)
        if not saveData.autoEquipWeapon or saveData.autoEquipWeapon == "" then return end
        task.spawn(function()
            char:WaitForChild("Humanoid", 10)
            task.wait(1)  -- let the backpack repopulate before equipping
            equipNow()
        end)
    end)

    -- Same safety net for "Auto Equip Strongest": don't rely solely on the 2s
    -- poll loop to recover after death (it can stall if a body error/yield ever
    -- slips through). Fire an immediate re-equip on every respawn so the
    -- strongest weapon comes straight back the moment the backpack repopulates.
    localPlayer.CharacterAdded:Connect(function(char)
        if not saveData.autoEquipStrongest then return end
        task.spawn(function()
            char:WaitForChild("Humanoid", 10)
            task.wait(1)  -- let the backpack repopulate before equipping
            if not saveData.autoEquipStrongest then return end
            pcall(function()
                local best = W.getStrongest and W.getStrongest()
                if best then equipItem(best) end
            end)
        end)
    end)

    -- Keep the held-weapon stats live: refresh whenever a tool is equipped or
    -- unequipped (tools parent to / leave the character model).
    local function hookCharTools(char)
        if not char then return end
        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then updateAutoEquipPanel() end
        end)
        char.ChildRemoved:Connect(function(c)
            if c:IsA("Tool") then task.defer(updateAutoEquipPanel) end
        end)
    end
    hookCharTools(localPlayer.Character)
    localPlayer.CharacterAdded:Connect(hookCharTools)

    -- Resume a weapon chosen in a previous session.
    if saveData.autoEquipWeapon and saveData.autoEquipWeapon ~= "" then
        task.spawn(function() task.wait(1) equipNow() end)
    end
end

-- ============================================================
-- DODGE BOSS AOE toggle (Farm tab) - an iOS switch that tells the auto-farm loop
-- to auto-dash the character out of boss ability AoE hitboxes (the anchored 30-stud
-- "Hitbox" parts a boss drops to deal ranged/area damage) and slide back onto the
-- target once they fade. This only flips a saved flag; the farm loop reads
-- saveData.farmDodgeAoE and runs the dodge on its live target. (Client-side freeze
-- was scrapped: mob physics + damage are server-authoritative, so freezing only
-- changed local rendering while the real mob kept hitting -- dodging position is the
-- one thing the server actually honors.) Own do-block so the widget locals free
-- before the 200-local ceiling.
-- ============================================================
do
    local row = Instance.new("Frame")
    row.Name = "FarmDodgeRow"
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = getTheme().surface
    row.BorderSizePixel = 0
    row.ZIndex = 9999
    row.LayoutOrder = 3  -- directly below Auto Farm Mobs (2); offsets/equip shift down
    row.Parent = farmScroll
    addCorner(row, 8)
    addStroke(row, getTheme().borderLight, 1, true)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Dodge Boss AoE"
    label.TextColor3 = getTheme().text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.ZIndex = 10001
    label.Parent = row

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 34, 1, 0)
    status.Position = UDim2.new(1, -64, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = "OFF"
    status.TextColor3 = colors.danger
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.TextYAlignment = Enum.TextYAlignment.Center
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 12
    status.ZIndex = 10001
    status.Parent = row

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, 46, 0, 24)
    track.Position = UDim2.new(1, -10, 0.5, 0)
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.BackgroundColor3 = colors.danger
    track.BorderSizePixel = 0
    track.Text = ""
    track.AutoButtonColor = false
    track.ZIndex = 10002
    track.Parent = row
    addCorner(track, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 24, 0, 24)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = colors.text
    knob.BorderSizePixel = 0
    knob.ZIndex = 10003
    knob.Parent = track
    addCorner(knob, 12)

    local function setVisual(on)
        status.Text = on and "ON" or "OFF"
        status.TextColor3 = on and colors.success or colors.danger
        track.BackgroundColor3 = on and colors.success or colors.danger
        local target = on and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 0, 0.5, 0)
        -- Snap if the knob isn't rendered yet (tween throws off-screen); see farm toggle.
        local ok = pcall(function()
            knob:TweenPosition(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        end)
        if not ok then knob.Position = target end
    end

    track.MouseButton1Click:Connect(function()
        saveData.farmDodgeAoE = not saveData.farmDodgeAoE
        saveDataToFile()
        setVisual(saveData.farmDodgeAoE)
        statusLabel.Text = saveData.farmDodgeAoE
            and "Dodge boss AoE ON" or "Dodge boss AoE OFF"
    end)

    setVisual(saveData.farmDodgeAoE == true)
end

local ITEM_BATCH_SIZE = 20
local populateTaskActive = false

local function cancelPopulateTask()
    populateTaskActive = false
end

local function restoreSelection()
    if selectedBtn and selectedBtn.Parent then
        local rowFrame = selectedBtn.Parent
        local isRowFrame = (rowFrame ~= dropdown)
        if isRowFrame then
            rowFrame.BackgroundColor3 = getTheme().surface
        else
            selectedBtn.BackgroundColor3 = getTheme().surface
        end
        selectedBtn.TextColor3 = selectedBtn.Text:find("✅") and colors.success or getTheme().textDim
    end
end

local function createItemRow(itemName, rowY, displayText, owned)
    local rowFrame = Instance.new("Frame")
    rowFrame.Size = UDim2.new(1, -8, 0, 32)
    rowFrame.BackgroundColor3 = getTheme().surface
    rowFrame.BorderSizePixel = 0
    rowFrame.ZIndex = 10005  -- popup band, above InfoPanel (see dropdown.ZIndex)
    rowFrame.LayoutOrder = rowY
    rowFrame.Parent = dropdown
    addCorner(rowFrame, 4)

    local nameLabel = Instance.new("TextButton")
    nameLabel.Size = UDim2.new(0.7, -10, 1, 0)
    nameLabel.Position = UDim2.new(0, 8, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = displayText
    nameLabel.TextColor3 = owned and colors.success or getTheme().textDim
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.ZIndex = 10006
    nameLabel.Parent = rowFrame

    if selectedItem == itemName then
        selectedBtn = nameLabel
        rowFrame.BackgroundColor3 = colors.accent
        nameLabel.TextColor3 = colors.text
    end

    local equipBtn = Instance.new("TextButton")
    equipBtn.Size = UDim2.new(0.3, -10, 1, -6)
    equipBtn.Position = UDim2.new(0.7, 5, 0, 3)
    equipBtn.BackgroundColor3 = owned and colors.success or colors.danger
    equipBtn.BorderSizePixel = 0
    equipBtn.Text = owned and "EQUIP" or "LOCKED"
    equipBtn.TextColor3 = colors.text
    equipBtn.TextSize = 10
    equipBtn.Font = Enum.Font.GothamMedium
    equipBtn.ZIndex = 10007
    equipBtn.Parent = rowFrame
    addCorner(equipBtn, 4)

    nameLabel.MouseButton1Click:Connect(function()
        restoreSelection()
        selectedBtn = nameLabel
        selectedItem = itemName
        saveData.selectedItem = itemName
        saveDataToFile()
        rowFrame.BackgroundColor3 = colors.accent
        nameLabel.TextColor3 = colors.text
        dropdownLabel.Text = itemName
        statusLabel.Text = "Selected: " .. itemName .. (owned and " (owned)" or " (not owned)")
        statusSelectedLabel.Text = itemName
        if updateInfoPanel then updateInfoPanel() end
        -- Close dropdown after selection
        dropdown.Visible = false
        dropdownOpen = false
    end)

    equipBtn.MouseButton1Click:Connect(function()
        if owned then
            local success, msg = equipItem(itemName)
            statusLabel.Text = success and "Equipped: " .. itemName or "Failed: " .. msg
            if success then
                populateDropdown(searchBox.Text)
                statusLabel.Text = "✓ " .. itemName .. " equipped!"
                task.wait(1.5)
                statusLabel.Text = "Select a target"
            end
        else
            statusLabel.Text = "You do not own " .. itemName
        end
    end)

    -- Hover effect
    nameLabel.MouseEnter:Connect(function()
        if selectedBtn ~= nameLabel then
            rowFrame.BackgroundColor3 = getTheme().surfaceHover
        end
    end)
    nameLabel.MouseLeave:Connect(function()
        if selectedBtn ~= nameLabel then
            rowFrame.BackgroundColor3 = getTheme().surface
        end
    end)

    return rowFrame
end

-- Toggle dropdown open/close
dropdownBtn.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    dropdown.Visible = dropdownOpen
    if dropdownOpen then
        -- Start from an unfiltered list each time the popup opens.
        -- Clearing the text fires the filter handler below, which repopulates.
        -- (populateDropdown isn't in scope yet at this point, so we go via .Text.)
        dropdownSearchBox.Text = ""
        -- (No BringToFront: it isn't a member of ScrollingFrame in this Roblox
        -- build and only errored. The popup's ZIndex 10000 already layers it.)
    end
end)

local function populateDropdownAsync(filter, sortedItems, isArmor)
    cancelPopulateTask()
    for _, b in pairs(itemBtns) do b:Destroy() end
    itemBtns = {}

    local f = filter and filter:lower() or ""
    local filteredItems = {}
    for _, item in ipairs(sortedItems) do
        if f == "" or item.name:lower():find(f) then
            table.insert(filteredItems, item)
        end
    end

    local totalItems = #filteredItems
    local y = 0
    dropdown.CanvasSize = UDim2.new(0, 0, 0, math.max(140, totalItems * 32) + 34)

    populateTaskActive = true
    task.spawn(function()
        for index, item in ipairs(filteredItems) do
            if not populateTaskActive then return end

            local displayText = item.name
            if isArmor then
                if item.owned then
                    displayText = item.persistent and item.name .. " ✅ (P)" or item.name .. " ✅"
                else
                    displayText = item.name .. " ❌"
                end
            else
                displayText = item.name .. (item.owned and " ✅" or " ❌")
            end

            local rowFrame = createItemRow(item.name, y, displayText, item.owned)
            table.insert(itemBtns, rowFrame)
            y = y + 32

            if index % ITEM_BATCH_SIZE == 0 then
                dropdown.CanvasSize = UDim2.new(0, 0, 0, y + (totalItems - index) * 32 + 34)
                task.wait()
            end
        end

        if not populateTaskActive then return end
        dropdown.CanvasSize = UDim2.new(0, 0, 0, y + 34)
        if #itemBtns == 0 then
            statusLabel.Text = isArmor and "No armor pieces match filter" or "No items match filter"
        end
        updateLayout()
        populateTaskActive = false
    end)
end

local function getList(tab)
    if tab == "Mobs" or tab == "Farm" then
        return mobList, "Mob"
    elseif tab == "Bosses" then
        local rarity = currentBossTab or "Common"
        return bossData[rarity] or {}, "Boss"
    elseif tab == "Item" then
        return itemList, "Item"
    elseif tab == "Armor" then
        return armorList, "Armor"
    elseif tab == "Shops" then
        return shopData, "Shop"
    elseif tab == "Config" then
        return {}, "Config"
    end
    return {}, "Mob"
end

local function populateDropdown(filter)
    cancelPopulateTask()
    for _, b in pairs(itemBtns) do b:Destroy() end
    itemBtns = {}

    local y = 0
    local f = filter and filter:lower() or ""
    local list, typ = getList(currentTab)
    currentType = typ

    if currentTab == "Config" then
        dropdown.Visible = false
        dropdownContainer.Visible = false
        configContainer.Visible = true
        teleportBtn.Visible = false
        farmScroll.Visible = false
        equipAllContainer.Visible = false
        refreshBtn.Visible = false
        updateLayout()
        return
    else
        dropdownContainer.Visible = true
        configContainer.Visible = false
        teleportBtn.Visible = true
        refreshBtn.Visible = true
    end

    if currentTab == "Armor" then
        local ownedData = getArmorOwnership()
        local repStorage = game:GetService("ReplicatedStorage")
        local armorFolder = repStorage:FindFirstChild("Armor")
        local ownedFolder = armorFolder and armorFolder:FindFirstChild("Owned")

        local sortedItems = {}
        for _, name in ipairs(armorList) do
            local persistentOwned = false
            if ownedFolder then
                local marker = ownedFolder:FindFirstChild(name)
                if marker and marker:IsA("BoolValue") and marker.Value == true then
                    persistentOwned = true
                end
            end
            local owned = ownedData[name] or persistentOwned
            local h, dmg = statHealthDmg("Armor", name)
            table.insert(sortedItems, {name = name, owned = owned, persistent = persistentOwned, sortH = h, sortD = dmg})
        end
        -- Owned first, then weakest -> strongest (lowest health/damage first).
        table.sort(sortedItems, function(a, b)
            local ao, bo = a.owned and true or false, b.owned and true or false
            if ao ~= bo then return ao end
            if a.sortH ~= b.sortH then return a.sortH < b.sortH end
            if a.sortD ~= b.sortD then return a.sortD < b.sortD end
            return a.name < b.name
        end)

        equipAllContainer.Visible = true

        if #sortedItems > 30 then
            populateDropdownAsync(filter, sortedItems, true)
            return
        end

        for _, item in ipairs(sortedItems) do
            if f == "" or item.name:lower():find(f) then
                local displayText = item.name
                if item.owned then
                    displayText = item.persistent and item.name .. " ✅ (P)" or item.name .. " ✅"
                else
                    displayText = item.name .. " ❌"
                end
                local rowFrame = createItemRow(item.name, y, displayText, item.owned)
                table.insert(itemBtns, rowFrame)
                y = y + 32
            end
        end

        dropdown.CanvasSize = UDim2.new(0, 0, 0, y + 34)
        if #itemBtns == 0 then
            statusLabel.Text = "No armor pieces match filter"
        end
        updateLayout()
        return
    end

    if currentTab == "Item" then
        local ownedData = getItemsWithOwnership()
        local sortedItems = {}
        for _, name in ipairs(itemList) do
            local h, dmg = statHealthDmg("Item", name)
            table.insert(sortedItems, {name = name, owned = ownedData[name], sortH = h, sortD = dmg})
        end
        -- Owned first, then weakest -> strongest (lowest damage first).
        table.sort(sortedItems, function(a, b)
            local ao, bo = a.owned and true or false, b.owned and true or false
            if ao ~= bo then return ao end
            if a.sortH ~= b.sortH then return a.sortH < b.sortH end
            if a.sortD ~= b.sortD then return a.sortD < b.sortD end
            return a.name < b.name
        end)

        if #sortedItems > 80 then
            populateDropdownAsync(filter, sortedItems, false)
            return
        end

        for _, item in ipairs(sortedItems) do
            if f == "" or item.name:lower():find(f) then
                local rowFrame = createItemRow(item.name, y, item.name .. (item.owned and " ✅" or " ❌"), item.owned)
                table.insert(itemBtns, rowFrame)
                y = y + 32
            end
        end

        dropdown.CanvasSize = UDim2.new(0, 0, 0, y + 34)
        if #itemBtns == 0 then
            statusLabel.Text = "No items match filter"
        end
        updateLayout()
        return
    end

    if currentTab == "Mobs" or currentTab == "Bosses" or currentTab == "Farm" then
        local statTab = (currentTab == "Bosses") and "Bosses" or "Mobs"
        local itemsWithHealth = {}
        for _, name in ipairs(list) do
            local health = getMaxHealthByName(name)   -- live value shown as ❤
            local sh, sd = statHealthDmg(statTab, name)  -- canonical values for sorting
            table.insert(itemsWithHealth, {name = name, health = health, sortH = sh, sortD = sd})
        end

        -- Sort weakest -> strongest (lowest health, then lowest damage).
        table.sort(itemsWithHealth, function(a, b)
            if a.sortH ~= b.sortH then return a.sortH < b.sortH end
            if a.sortD ~= b.sortD then return a.sortD < b.sortD end
            return a.name < b.name
        end)

        for _, item in ipairs(itemsWithHealth) do
            local name = item.name
            local health = item.health
            if f == "" or name:lower():find(f) then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -8, 0, 32)
                btn.BackgroundColor3 = getTheme().surface
                btn.BorderSizePixel = 0
                btn.Text = name
                btn.TextColor3 = getTheme().textDim
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.TextSize = 12
                btn.Font = Enum.Font.Gotham
                btn.ZIndex = 10005
                btn.LayoutOrder = y
                btn.Parent = dropdown
                addCorner(btn, 4)
                addPadding(btn, 0, 0, 8, 8)

                if health and health > 0 then
                    btn.Text = name .. "  ❤ " .. string.format("%.0f", health)
                end

                -- The Farm tab supports selecting many mobs at once; every
                -- other tab keeps the original single-selection behaviour.
                local isFarmTab = (currentTab == "Farm")
                -- Farm selection is keyed on the base name (health stripped) so the
                -- highlight survives the mob's live-health drift; see toggleFarmMob.
                local farmKey = isFarmTab and (tostring(name):gsub("%s*Health:.*$", "")) or nil
                local function btnSelected()
                    if isFarmTab then return farmSelection[farmKey] == true end
                    return selectedBtn == btn
                end

                if (isFarmTab and farmSelection[farmKey]) or (not isFarmTab and selectedItem == name) then
                    if not isFarmTab then selectedBtn = btn end
                    btn.BackgroundColor3 = colors.accent
                    btn.TextColor3 = colors.text
                end

                btn.MouseButton1Click:Connect(function()
                    if isFarmTab then
                        -- Toggle this mob in/out of the farm set; leave the
                        -- dropdown open so several can be picked in a row.
                        local nowOn = toggleFarmMob(name)
                        btn.BackgroundColor3 = nowOn and colors.accent or getTheme().surface
                        btn.TextColor3 = nowOn and colors.text or getTheme().textDim
                        local count = farmSelectionCount()
                        dropdownLabel.Text = count == 0 and "Select mobs..."
                            or (count .. " mob" .. (count == 1 and "" or "s") .. " selected")
                        statusLabel.Text = (nowOn and "Added: " or "Removed: ") .. name
                        statusSelectedLabel.Text = dropdownLabel.Text
                        return
                    end
                    restoreSelection()
                    selectedBtn = btn
                    selectedItem = name
                    saveData.selectedItem = name
                    saveDataToFile()
                    btn.BackgroundColor3 = colors.accent
                    btn.TextColor3 = colors.text
                    dropdownLabel.Text = name
                    statusLabel.Text = "Selected: " .. name
                    statusSelectedLabel.Text = name
                    if updateInfoPanel then updateInfoPanel() end
                    dropdown.Visible = false
                    dropdownOpen = false
                end)

                -- Hover effect
                btn.MouseEnter:Connect(function()
                    if not btnSelected() then
                        btn.BackgroundColor3 = getTheme().surfaceHover
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if not btnSelected() then
                        btn.BackgroundColor3 = getTheme().surface
                    end
                end)

                table.insert(itemBtns, btn)
                y = y + 32
            end
        end
    else
        table.sort(list)
        for _, name in ipairs(list) do
            if f == "" or name:lower():find(f) then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -8, 0, 32)
                btn.BackgroundColor3 = getTheme().surface
                btn.BorderSizePixel = 0
                btn.Text = name
                btn.TextColor3 = getTheme().textDim
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.TextSize = 12
                btn.Font = Enum.Font.Gotham
                btn.ZIndex = 10005
                btn.LayoutOrder = y
                btn.Parent = dropdown
                addCorner(btn, 4)
                addPadding(btn, 0, 0, 8, 8)

                if selectedItem == name then
                    selectedBtn = btn
                    btn.BackgroundColor3 = colors.accent
                    btn.TextColor3 = colors.text
                end

                btn.MouseButton1Click:Connect(function()
                    restoreSelection()
                    selectedBtn = btn
                    selectedItem = name
                    saveData.selectedItem = name
                    saveDataToFile()
                    btn.BackgroundColor3 = colors.accent
                    btn.TextColor3 = colors.text
                    dropdownLabel.Text = name
                    statusLabel.Text = "Selected: " .. name
                    statusSelectedLabel.Text = name
                    if updateInfoPanel then updateInfoPanel() end
                    dropdown.Visible = false
                    dropdownOpen = false
                end)

                btn.MouseEnter:Connect(function()
                    if selectedBtn ~= btn then
                        btn.BackgroundColor3 = getTheme().surfaceHover
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if selectedBtn ~= btn then
                        btn.BackgroundColor3 = getTheme().surface
                    end
                end)

                table.insert(itemBtns, btn)
                y = y + 32
            end
        end
    end

    dropdown.CanvasSize = UDim2.new(0, 0, 0, y + 34)
    if #itemBtns == 0 then
        statusLabel.Text = "No items match filter"
    end
    updateLayout()
end

-- SIDE TAB SWITCHING - Clean highlight
for _, tab in ipairs(sideButtons) do
    tab.btn.MouseButton1Click:Connect(function()
        currentTab = tab.name
        saveData.currentTab = tab.name
        saveDataToFile()
        for _, t in ipairs(sideButtons) do
            local on = t == tab
            t.btn.BackgroundColor3 = on and colors.accent or getTheme().surface
            t.btn.BackgroundTransparency = on and 0 or 1
            t.btn.TextColor3 = on and colors.text or getTheme().textDim
            t.btn.Font = on and Enum.Font.GothamBold or Enum.Font.GothamMedium
        end

        -- Reset dropdown label (Farm tab shows how many mobs are picked)
        if tab.name == "Farm" then
            local count = farmSelectionCount()
            dropdownLabel.Text = count == 0 and "Select mobs..."
                or (count .. " mob" .. (count == 1 and "" or "s") .. " selected")
        else
            dropdownLabel.Text = "Select an item..."
        end
        dropdown.Visible = false
        dropdownOpen = false

        bossTabContainer.Visible = (tab.name == "Bosses")
        populateDropdown(searchBox.Text)
        updateLayout()
        statusLabel.Text = "Tab: " .. tab.label
        statusTabLabel.Text = "Tab: " .. tab.label
    end)
end

-- BOSS TAB SWITCHING - Clean pill highlight
for _, tab in ipairs(bossTabBtns) do
    tab.btn.MouseButton1Click:Connect(function()
        currentBossTab = tab.name
        saveData.currentBossTab = tab.name
        saveDataToFile()
        for _, t in ipairs(bossTabBtns) do
            t.btn.BackgroundColor3 = getTheme().surface
            t.btn.TextColor3 = getTheme().textDim
        end
        tab.btn.BackgroundColor3 = colors.accent
        tab.btn.TextColor3 = colors.text
        
        if currentTab == "Bosses" then
            dropdownLabel.Text = "Select an item..."
            dropdown.Visible = false
            dropdownOpen = false
            populateDropdown(searchBox.Text)
            updateLayout()
            statusLabel.Text = "Bosses: " .. tab.name
        end
    end)
end

-- Set defaults
for _, tab in ipairs(sideButtons) do
    tab.btn.BackgroundColor3 = (tab.name == currentTab) and colors.accent or getTheme().surface
    tab.btn.BackgroundTransparency = (tab.name == currentTab) and 0 or 1
    tab.btn.TextColor3 = (tab.name == currentTab) and colors.text or getTheme().textDim
    tab.btn.Font = (tab.name == currentTab) and Enum.Font.GothamBold or Enum.Font.GothamMedium
end
for _, tab in ipairs(bossTabBtns) do
    if tab.name == currentBossTab then
        tab.btn.BackgroundColor3 = colors.accent
        tab.btn.TextColor3 = colors.text
    end
end

-- Helper function to get the type for a tab
local function getListType(tab)
    if tab == "Mobs" or tab == "Farm" then return "Mob"
    elseif tab == "Bosses" then return "Boss"
    elseif tab == "Item" then return "Item"
    elseif tab == "Armor" then return "Armor"
    elseif tab == "Shops" then return "Shop"
    elseif tab == "Config" then return "Config"
    end
    return "Mob"
end

-- Global search function to search across all data
local function performGlobalSearch(searchText)
    local searchLower = searchText:lower()
    
    -- Search in Mobs (routed to the Farm tab, which lists mobs now that the
    -- standalone Mobs tab has been removed).
    for _, mob in ipairs(mobList) do
        if mob:lower():find(searchLower) then
            return "Farm", mob, nil
        end
    end
    
    -- Search in Bosses
    for rarity, bosses in pairs(bossData) do
        for _, boss in ipairs(bosses) do
            if boss:lower():find(searchLower) then
                return "Bosses", boss, rarity
            end
        end
    end
    
    -- Search in Items
    for _, item in ipairs(itemList) do
        if item:lower():find(searchLower) then
            return "Item", item, nil
        end
    end
    
    -- Search in Armor
    for _, armor in ipairs(armorList) do
        if armor:lower():find(searchLower) then
            return "Armor", armor, nil
        end
    end
    
    -- Search in Shops
    for _, shopName in ipairs(shopData) do
        if type(shopName) == "string" and shopName:lower():find(searchLower) then
            return "Shops", shopName, nil
        end
    end
    
    -- Search in Config: the settings that live on the Config tab aren't list items,
    -- so match them by name + common aliases. Typing "walk", "jump", "afk", "esp",
    -- "keybind", "yield", etc. jumps straight to the Config tab.
    local configTerms = {
        {"Walk Speed",     {"walk", "walkspeed", "speed", "run"}},
        {"Jump Power",     {"jump", "jumppower", "power", "height"}},
        {"ESP Mobs",       {"esp", "espmobs", "radius", "highlight", "wallhack"}},
        {"Anti-AFK",       {"anti", "afk", "antiafk", "idle", "kick"}},
        {"Toggle Key",     {"toggle", "key", "keybind", "hotkey", "bind"}},
        {"Infinite Yield", {"infinite", "yield", "iy", "cmd", "command", "cmdbar"}},
        {"Config",         {"config", "setting", "settings", "option", "options"}},
    }
    for _, entry in ipairs(configTerms) do
        if entry[1]:lower():find(searchLower, 1, true) then
            return "Config", entry[1], nil
        end
        for _, term in ipairs(entry[2]) do
            if term:find(searchLower, 1, true) then
                return "Config", entry[1], nil
            end
        end
    end

    -- Search in Quest: the auto-quest controls aren't list items either, so route
    -- quest/bounty/daily/weekly/monthly and the auto-* toggles to the Quest tab.
    local questTerms = { "quest", "quests", "bounty", "bounties", "daily", "weekly",
        "monthly", "accept", "turn in", "turnin", "auto quest", "questmaster" }
    for _, term in ipairs(questTerms) do
        if term:find(searchLower, 1, true) then
            return "Quest", "Auto Quest", nil
        end
    end

    -- No match found
    return nil, nil, nil
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = searchBox.Text
    if searchText ~= "" then
        -- Perform global search across all tabs
        local foundTab, foundItem, foundSubTab = performGlobalSearch(searchText)
        if foundTab and foundItem then
            -- Switch to the found tab
            currentTab = foundTab
            saveData.currentTab = foundTab
            
            if foundSubTab then
                currentBossTab = foundSubTab
                saveData.currentBossTab = foundSubTab
                
                -- Update boss tab buttons visually
                if bossTabBtns then
                    for _, tab in ipairs(bossTabBtns) do
                        tab.btn.BackgroundColor3 = getTheme().surface
                        tab.btn.TextColor3 = getTheme().textDim
                    end
                    for _, tab in ipairs(bossTabBtns) do
                        if tab.name == currentBossTab then
                            tab.btn.BackgroundColor3 = colors.accent
                            tab.btn.TextColor3 = colors.text
                            break
                        end
                    end
                end
            end
            
            saveDataToFile()
            
            -- Update sidebar buttons
            for _, tab in ipairs(sideButtons) do
                local on = tab.name == foundTab
                tab.btn.BackgroundColor3 = on and colors.accent or getTheme().surface
                tab.btn.BackgroundTransparency = on and 0 or 1
                tab.btn.TextColor3 = on and colors.text or getTheme().textDim
                tab.btn.Font = on and Enum.Font.GothamBold or Enum.Font.GothamMedium
            end
            
            -- Update boss tab visibility if needed
            bossTabContainer.Visible = (foundTab == "Bosses")
            
            -- Update currentType
            currentType = getListType(foundTab)
            
            -- Populate dropdown with the search term
            populateDropdown(searchText)
            
            -- Update status
            statusLabel.Text = "Found: " .. foundItem .. " in " .. foundTab
            statusTabLabel.Text = "Tab: " .. foundTab
            
            -- Update layout
            updateLayout()
            return
        end
    end
    
    -- Default behavior for empty search or no match
    populateDropdown(searchText)
end)

-- Dropdown's built-in "Filter items..." box: live-filter the currently open
-- list as the user types. Previously this TextBox had no handler, so it
-- accepted typing but never filtered.
dropdownSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    populateDropdown(dropdownSearchBox.Text)
end)

-- REFRESH
local function refreshAll()
    healthCache = {}
    
    if currentTab == "Item" then
        populateDropdown(searchBox.Text)
        updateLayout()
        local inv = getPlayerInventory()
        statusLabel.Text = "Items refreshed - " .. #inv .. " owned"
        task.wait(1.5)
        statusLabel.Text = "Select a target"
        return
    end
    
    if currentTab == "Armor" then
        -- Re-scan the game's armor folders for pieces added since load. The helmet/
        -- body lists are hardcoded at startup, so new gear the game ships wouldn't
        -- appear until now. Read the live ReplicatedStorage.Armor.Helmets/BodyArmor
        -- folder names and merge in anything we don't already know about.
        local newFound = 0
        do
            local existing = {}
            for _, n in ipairs(armorList) do existing[n] = true end
            local armorFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Armor")
            local function scanSub(subName, targetList)
                local f = armorFolder and armorFolder:FindFirstChild(subName)
                if not f then return end
                for _, child in ipairs(f:GetChildren()) do
                    local nm = child.Name
                    if nm ~= "" and not existing[nm] then
                        existing[nm] = true
                        table.insert(targetList, nm)
                        table.insert(armorList, nm)
                        newFound = newFound + 1
                    end
                end
            end
            if armorFolder then
                scanSub("Helmets", helmetNames)
                scanSub("BodyArmor", bodyArmorNames)
            end
            -- Also fold in armor-signature tools that live in the Weapons folder
            -- (armor stored as a Tool with a "Health: X | Speed: Y" tooltip).
            local weaponsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Weapons")
            if weaponsFolder then
                for _, tool in ipairs(weaponsFolder:GetChildren()) do
                    if tool:IsA("Tool") then
                        local tip = tostring(tool.ToolTip)
                        if tip:match("^Health:%s*[%w%.]+%s*|%s*Speed:") and not existing[tool.Name] then
                            existing[tool.Name] = true
                            table.insert(bodyArmorNames, tool.Name)
                            table.insert(armorList, tool.Name)
                            newFound = newFound + 1
                        end
                    end
                end
            end
            if newFound > 0 then table.sort(armorList) end
        end
        populateDropdown(searchBox.Text)
        updateLayout()
        local ownedData = getArmorOwnership()
        local count = 0
        for _, owned in pairs(ownedData) do
            if owned then count = count + 1 end
        end
        statusLabel.Text = newFound > 0
            and ("Armor refreshed - " .. newFound .. " new found, " .. count .. " owned")
            or ("Armor refreshed - " .. count .. " owned")
        task.wait(1.5)
        statusLabel.Text = "Select a target"
        return
    end
    
    local newMobs = scanMobs()
    if #newMobs > 0 then mobList = newMobs end
    
    local newBosses = scanBosses()
    local hasData = false
    for _, list in pairs(newBosses) do
        if #list > 0 then hasData = true break end
    end
    if hasData then
        for rarity, list in pairs(newBosses) do
            bossData[rarity] = list
        end
    end
    
    populateDropdown(searchBox.Text)
    updateLayout()
    local total = #mobList
    local totalB = 0
    for _, list in pairs(bossData) do totalB = totalB + #list end
    statusLabel.Text = "Refreshed - " .. total .. " mobs, " .. totalB .. " bosses"
    task.wait(1.5)
    statusLabel.Text = "Select a target"
end

refreshBtn.MouseButton1Click:Connect(refreshAll)

debugBtn.MouseButton1Click:Connect(function()
    print("=== SAUCE DEBUG ===")
    print("Tab:", currentTab)
    print("Boss Tab:", currentBossTab)
    print("Type:", currentType)
    print("Selected:", selectedItem or "None")
    print("Mobs:", #mobList)
    print("Items:", #itemList)
    print("Armor:", #armorList)
    print("Anti-AFK:", antiAFKEnabled and "ON" or "OFF")
    print("Toggle Key:", saveData.toggleKey)
    statusLabel.Text = "Debug printed"
end)

-- TELEPORT
teleportBtn.MouseButton1Click:Connect(function()
    if currentTab == "Item" then
        statusLabel.Text = "Teleport disabled for Item tab - use EQUIP button"
        return
    end
    
    if currentTab == "Armor" then
        statusLabel.Text = "Teleport disabled for Armor tab - use EQUIP ALL button"
        return
    end
    
    if currentTab == "Config" then
        return
    end
    
    if not selectedItem then
        statusLabel.Text = "No item selected"
        return
    end
    
    -- Shops teleport removed: the Shops tab now buys directly via its own panel
    -- (weapons/potions/merchant), so the generic Teleport button never runs here.

    if currentType == "Mob" then
        local mob = getMobFromMobsFolder(selectedItem)
        if not mob then mob = findModelInWorkspace(selectedItem) end
        if not mob then
            statusLabel.Text = "Mob not found"
            return
        end
        
        local targetCFrame = getWorldPivot(mob)
        if not targetCFrame then
            statusLabel.Text = "No CFrame"
            return
        end
        
        local char = localPlayer.Character
        if not char then
            localPlayer.CharacterAdded:Wait()
            char = localPlayer.Character
        end
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(targetCFrame.Position + Vector3.new(0, 3, 2))
            statusLabel.Text = "Teleported to " .. selectedItem
        end
        return
    end
    
    if currentType == "Boss" then
        local boss = findModelInWorkspace(selectedItem)
        local targetCFrame = boss and getWorldPivot(boss)
        if not targetCFrame then
            local storageBoss = getBossFromStorage(selectedItem)
            if storageBoss then
                targetCFrame = getWorldPivot(storageBoss)
            end
        end
        if not targetCFrame then
            statusLabel.Text = "No WorldPivot"
            return
        end
        
        local char = localPlayer.Character
        if not char then
            localPlayer.CharacterAdded:Wait()
            char = localPlayer.Character
        end
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(targetCFrame.Position + Vector3.new(0, 3, 2))
            statusLabel.Text = "Teleported to " .. selectedItem
        end
        return
    end
    
    statusLabel.Text = "Unknown target type"
end)

-- ============================================================
-- AUTO FARM - teleport onto the selected mob and swing the equipped
-- tool until it dies, then move on to the next live copy of that mob.
-- Wrapped in a do-block so its helpers don't consume main-chunk local
-- slots; only farmActive and the toggle-row widgets (declared earlier) escape.
-- ============================================================
do
local farmSession = 0

local function getEquippedTool()
    local char = localPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

-- Return an equipped tool, equipping the first one in the backpack if needed.
local function ensureToolEquipped()
    local tool = getEquippedTool()
    if tool then return tool end
    local char = localPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local backpack = localPlayer:FindFirstChild("Backpack")
    if humanoid and backpack then
        for _, c in ipairs(backpack:GetChildren()) do
            if c:IsA("Tool") then
                pcall(function() humanoid:EquipTool(c) end)
                return c
            end
        end
    end
    return nil
end

local function isMobAlive(mob)
    if not mob or not mob.Parent then return false end
    local humanoid = mob:FindFirstChildOfClass("Humanoid")
    if humanoid then return humanoid.Health > 0 end
    local enemy = mob:FindFirstChild("Enemy")
    if enemy then
        local health = enemy:FindFirstChild("Health")
        if health and (health:IsA("NumberValue") or health:IsA("IntValue")) then
            return health.Value > 0
        end
    end
    return true
end

-- Forward-declared as main-chunk locals, then assigned inside the do-block below
-- so the shared baseMobName helper can live as a BLOCK local -- keeping it off
-- the main chunk's 200-local-per-function ceiling (adding one more top-level
-- local overflows it and the whole script fails to load).
local findNearestMobOfName, getFarmOrder, pickFarmTarget
do
    -- Mob model names carry VOLATILE suffixes -- live health ("Skeleton Health:
    -- 40/100"), a level tag ("(level 15)"), or a heart badge ("❤ 100"). None of
    -- that is identity: a skeleton's name changes every time it takes a hit.
    -- Strip it so a saved pick keeps matching its mob across health/level drift
    -- and, crucially, across the seconds you're dead -- otherwise the target
    -- "expires" on death and the farm never re-acquires it.
    local function baseMobName(s)
        if not s then return "" end
        s = tostring(s)
        s = s:gsub("%s*Health:.*$", "")
        s = s:gsub("%s*❤.*$", "")
        s = s:gsub("%s*%(level%s*%d+%)%s*$", "")
        s = s:gsub("^%s+", ""):gsub("%s+$", "")
        return s
    end

    -- Nearest live copy of one specific mob name (case-insensitive).
    function findNearestMobOfName(name)
        local folder = Workspace:FindFirstChild("Mobs")
        if not folder then return nil end
        -- Match on the stripped base name, not the exact string, so a pick keeps
        -- resolving as the mob's live health/level (and thus model name) changes.
        local lowered = baseMobName(name):lower()
        local char = localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local origin = root and root.Position or Vector3.new()
        local best, bestDist
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") and baseMobName(child.Name):lower() == lowered and isMobAlive(child) then
                local pivot = getWorldPivot(child)
                if pivot then
                    local d = (pivot.Position - origin).Magnitude
                    if not bestDist or d < bestDist then
                        best, bestDist = child, d
                    end
                end
            end
        end
        return best
    end

    -- The mob picks in selection order, falling back to the single selectedItem
    -- so a lone pick still farms without ever touching the Farm multi-select.
    function getFarmOrder()
        -- Quest auto-farm hijacks the farm engine non-destructively: when the quest
        -- coordinator has a live kill target it parks the name list here (in-memory
        -- only, never written to disk) and the farm loop -- which re-reads this every
        -- pass -- targets it instead of the user's manual picks. Cleared back to nil
        -- when quest auto-farm stops, so the manual Farm selection is untouched.
        local q = saveData._questFarmTargets
        if type(q) == "table" and #q > 0 then return q end
        if #saveData.farmMobs > 0 then return saveData.farmMobs end
        if selectedItem then return {selectedItem} end
        return {}
    end

    -- Pick the target by SELECTION ORDER: farm the first-picked mob type that has
    -- a live copy, then the second, and so on. Returns (mob, currentName, nextName).
    -- `nextName` is the next picked type (after the current, cyclically) with a
    -- live copy -- what the loop will move to once the current type is cleared.
    -- KILL AURA: nearest live mob of ANY name (ignores the selection list).
    -- Skips mobs parked in the in-memory stuck set -- targets that outlived a full
    -- swing cap without dying (e.g. an over-leveled boss), so the aura rotates on
    -- to the next-closest killable mob instead of camping an unkillable one.
    local function findNearestMobAny()
        -- Bone-world mob name -> clean identity: "Goblin Leader [BOSS] [100]" ->
        -- "Goblin Leader". Strips bracket tags and any HP/Health suffix so an Auto
        -- Progress target keeps matching as the enemy's live health string drifts.
        -- Declared here (not as a main-chunk-do-block local) to keep off the file's
        -- 200-local ceiling.
        local function boneClean(s)
            s = tostring(s or "")
            s = s:gsub("%s*%[.*$", ""):gsub("%s*HP:.*$", ""):gsub("%s*Health:.*$", "")
            return (s:gsub("^%s+", ""):gsub("%s+$", ""))
        end
        local char = localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local origin = root and root.Position or Vector3.new()
        local stuck = saveData._auraStuck
        local now = os.clock()
        local best, bestDist
        -- BONE WORLD mode: scan the "Legend of The Bone Sword" area folders (each
        -- holds enemy Models with a real Humanoid) instead of Workspace.Mobs.
        -- Optionally restrict to one enemy type (Auto Progress targets the exact
        -- mob that drops the frontier sword); nil = nearest enemy of any kind.
        if saveData._boneMode then
            local boneRoot = Workspace:FindFirstChild("Legend of The Bone Sword")
            if not boneRoot then return nil end
            local want = saveData._boneTargetName
            for _, folder in ipairs(boneRoot:GetChildren()) do
                if folder:IsA("Folder") then
                    for _, child in ipairs(folder:GetChildren()) do
                        -- Teleport pads and other props are ALSO Models with a
                        -- Humanoid, but their Humanoid has MaxHealth 0 and their
                        -- name starts with "To " -- exclude both so the aura only
                        -- ever camps real enemies (which have MaxHealth > 0).
                        local hum = child:IsA("Model") and child:FindFirstChildOfClass("Humanoid")
                        if hum and hum.MaxHealth > 0 and child.Name:sub(1, 3) ~= "To "
                           and isMobAlive(child)
                           and not (stuck and stuck[child] and now < stuck[child])
                           and (not want or boneClean(child.Name) == want) then
                            local pivot = getWorldPivot(child)
                            if pivot then
                                local d = (pivot.Position - origin).Magnitude
                                if not bestDist or d < bestDist then best, bestDist = child, d end
                            end
                        end
                    end
                end
            end
            return best
        end
        local folder = Workspace:FindFirstChild("Mobs")
        if not folder then return nil end
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") and isMobAlive(child)
               and not (stuck and stuck[child] and now < stuck[child]) then
                local pivot = getWorldPivot(child)
                if pivot then
                    local d = (pivot.Position - origin).Magnitude
                    if not bestDist or d < bestDist then best, bestDist = child, d end
                end
            end
        end
        return best
    end

    function pickFarmTarget()
        -- Aura mode short-circuits selection-order targeting: just take whatever
        -- live mob is physically closest and hit it until it dies, then re-pick.
        if saveData._auraMode then
            local m = findNearestMobAny()
            if not m then return nil end
            return m, baseMobName(m.Name), nil
        end
        local order = getFarmOrder()
        local mob, idx
        for i, name in ipairs(order) do
            local m = findNearestMobOfName(name)
            if m then mob, idx = m, i break end
        end
        if not mob then return nil end
        local nextName
        for step = 1, #order - 1 do
            local j = ((idx - 1 + step) % #order) + 1
            if findNearestMobOfName(order[j]) then nextName = order[j] break end
        end
        -- Show the clean base name in the status panel, not the raw model name
        -- with its live health string baked in.
        return mob, baseMobName(order[idx]), nextName and baseMobName(nextName) or nil
    end
end

local function stopFarm()
    farmActive = false
    farmSession = farmSession + 1
    -- Leaving any farm also exits Kill Aura mode, so a later normal (selection)
    -- farm start isn't silently hijacked into nearest-any targeting.
    saveData._auraMode = nil
    -- Also exit Bone World scan mode so a later main-map farm isn't redirected
    -- to the bone folders (and clear any Auto Progress single-target lock).
    saveData._boneMode = nil
    saveData._boneTargetName = nil
    -- Safety net: never leave the character anchored/floating after a stop.
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then pcall(function() root.Anchored = false end) end
    setFarmSwitchVisual(false)
    farmRuntime.current, farmRuntime.nextName, farmRuntime.weapon, farmRuntime.model = "", "", "", nil
    if updateFarmStatus then updateFarmStatus() end
end

local function startFarm()
    local initialCount = #getFarmOrder()
    -- Kill Aura needs no selection -- it targets the nearest live mob of any type.
    if initialCount == 0 and not saveData._auraMode then
        statusLabel.Text = "Select at least one mob to farm first"
        setFarmSwitchVisual(false)
        return
    end
    farmActive = true
    farmSession = farmSession + 1
    local mySession = farmSession
    setFarmSwitchVisual(true)
    statusLabel.Text = saveData._boneMode and (saveData._boneTargetName
            and ("Bone World: farming " .. saveData._boneTargetName .. "...")
            or "Bone World: hunting nearest enemy...")
        or (saveData._auraMode and "Kill Aura: hunting nearest mob..."
        or ("Farming: " .. initialCount .. " mob type" .. (initialCount == 1 and "" or "s")))
    if updateFarmStatus then updateFarmStatus() end

    task.spawn(function()
        -- One live Heartbeat pin at a time, held here so cleanup can always reach
        -- it even if a pass throws (otherwise a leaked connection keeps writing
        -- CFrame to a dead root after we die).
        local pin
        local function killPin()
            if pin then pin:Disconnect() pin = nil end
        end
        -- DODGE BOSS AOE: bosses cast ability attacks as an anchored 30x30x30 part
        -- named "Hitbox" (CanQuery=false, so raycasts/region queries can't see it),
        -- parented UNDER the casting mob, sitting at a target spot and damaging any
        -- character it touches for ~1s via a server-side .Touched. That server damage
        -- can't be blocked from here -- but the character's POSITION is client-owned
        -- and the server honors it, so when a hitbox lands on us we dash clear of its
        -- footprint until it fades, then the normal pin slides us back onto the target.
        -- Live hitboxes are tracked by one DescendantAdded listener on the Mobs folder
        -- (name == "Hitbox") so we never scan the whole workspace each frame.
        local activeAoE = {}   -- [BasePart] = true for currently-live ability hitboxes
        local aoeConn
        local function watchAoE()
            if aoeConn then return end
            local mobsFolder = Workspace:FindFirstChild("Mobs")
            if not mobsFolder then return end
            aoeConn = mobsFolder.DescendantAdded:Connect(function(inst)
                if inst:IsA("BasePart") and inst.Name == "Hitbox" then
                    activeAoE[inst] = true
                    -- Drop it from the set the instant the server Debris-removes it.
                    inst.AncestryChanged:Connect(function(_, parent)
                        if not parent then activeAoE[inst] = nil end
                    end)
                end
            end)
        end
        local function stopWatchAoE()
            if aoeConn then aoeConn:Disconnect() aoeConn = nil end
            table.clear(activeAoE)
        end
        -- If the character (at pos) is inside any live AoE footprint, return a CFrame
        -- just outside the worst offender's edge (+ margin) to dash to; else nil. Only
        -- the horizontal (XZ) footprint matters -- the cube is tall enough that height
        -- never saves us. Picks the deepest overlap so stacked casts still clear.
        local function aoeEscape(pos)
            local worst, worstPen
            for part in pairs(activeAoE) do
                if part.Parent then
                    local half = math.max(part.Size.X, part.Size.Z) * 0.5
                    local flat = pos - part.Position
                    flat = Vector3.new(flat.X, 0, flat.Z)
                    local pen = (half + 6) - flat.Magnitude   -- >0 means inside (+ 6-stud margin)
                    if pen > 0 and (not worstPen or pen > worstPen) then
                        worst, worstPen = part, pen
                    end
                else
                    activeAoE[part] = nil
                end
            end
            if not worst then return nil end
            local flat = pos - worst.Position
            flat = Vector3.new(flat.X, 0, flat.Z)
            local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(1, 0, 0)
            local half = math.max(worst.Size.X, worst.Size.Z) * 0.5
            return CFrame.new(worst.Position + dir * (half + 10) + Vector3.new(0, 3, 0))
        end
        watchAoE()
        while farmActive and mySession == farmSession and screenGui and screenGui.Parent do
            -- Crash-proof each pass. A single transient throw during the death/
            -- respawn churn used to kill this whole thread while farmActive stayed
            -- true -- the farm looked ON but did nothing until toggled off/on.
            -- pcall lets the loop self-heal and resume the instant we respawn.
            local passOk = pcall(function()
            local char = localPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if not root or not humanoid or humanoid.Health <= 0 then
                task.wait(0.5)
            else
                -- Re-picked each pass (by selection order) so mobs toggled
                -- mid-farm and respawns take effect immediately.
                local mob, curName, nextName = pickFarmTarget()
                if not mob then
                    statusLabel.Text = "Farming: no live targets - waiting..."
                    farmRuntime.current, farmRuntime.nextName, farmRuntime.model = "", "", nil
                    if updateFarmStatus then updateFarmStatus() end
                    task.wait(1)
                else
                    farmRuntime.current = curName
                    farmRuntime.nextName = nextName or ""
                    farmRuntime.model = mob  -- exact live target so its HP can tick down in the status panel
                    local tool = ensureToolEquipped()
                    farmRuntime.weapon = tool and tool.Name or ""
                    if updateFarmStatus then updateFarmStatus() end
                    -- Stay on the mob and swing until it dies (cap swings so a
                    -- stuck/invincible target can't hang the loop forever).
                    local swings = 0
                    local RunService = game:GetService("RunService")
                    -- IMPORTANT: do NOT anchor. Mobs in this game HIBERNATE (take zero
                    -- damage) until a physically-simulating player is next to them --
                    -- an anchored character never wakes them, so every swing whiffed.
                    -- Instead we stay unanchored (so the mob wakes and takes hits) and
                    -- PIN ourselves every frame: lerp the root to the target CFrame and
                    -- zero its velocity so gravity can't pull us down between writes.
                    -- That kills the old fall/re-snap camera shake without anchoring.
                    local holdCF = nil
                    pin = RunService.Heartbeat:Connect(function()
                        if not (root and root.Parent) then return end
                        -- Dodge takes priority over hugging the mob: if a boss AoE
                        -- hitbox is on us, snap clear of it this frame (hard set, not a
                        -- lerp -- the AoE only lives ~1s, so we can't ease out of it).
                        local safe = saveData.farmDodgeAoE and aoeEscape(root.Position) or nil
                        if safe then
                            root.CFrame = safe
                        elseif holdCF then
                            root.CFrame = root.CFrame:Lerp(holdCF, 0.5)
                        end
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                    end)
                    -- Farm from directly ABOVE the mob instead of face-to-face: perched
                    -- overhead the character can't be shoved around by the boss's body and
                    -- stays clear of most ground-level contact, while hits still land
                    -- straight DOWN into it (verified: GreatSword from 3-6 studs above
                    -- one-shot lvl 25-700 mobs). vlift is how high above the torso we hover
                    -- -- tracks the weapon: melee sits close, a STAFF sits higher so its orb
                    -- (spawns ~5 studs along our aim) drops down THROUGH the whole body.
                    local vlift = 4
                    local classifiedTool = nil
                    -- Bails the instant this mob is deselected mid-fight, instead of
                    -- waiting on the swing cap below to notice. Inlined as an IIFE
                    -- (not a named local) -- this file sits right at Luau's 200-local
                    -- ceiling per function, and a new named local here previously
                    -- overflowed it and silently killed the whole script's compile.
                    -- Swing cap: 60 in nearest-any aura so a too-tanky mob gets parked
                    -- and we rotate on. But a deliberate SINGLE bone target
                    -- (_boneTargetName, set by Auto Progress) has nowhere to rotate TO --
                    -- exiting at 60 just stuck-lists it and idles the farm ~8s ("stops for
                    -- a couple seconds then continues"). Bone bosses have tens of thousands
                    -- of HP, so lift the cap for that case and swing continuously until it
                    -- actually dies. (Inline expr -- no new local; file is at the 200 ceiling.)
                    while farmActive and mySession == farmSession and isMobAlive(mob)
                          and humanoid and humanoid.Health > 0
                          and swings < (saveData._boneTargetName and 100000 or 60)
                          and screenGui and screenGui.Parent   -- stop instantly if the GUI (this execution) is torn down / re-run, so an orphaned thread can't keep swinging a bumped tool
                          -- Aura mode hits the picked mob until it dies (or the cap),
                          -- so skip the "is curName still selected" bail -- there is no
                          -- selection list in aura mode.
                          and (saveData._auraMode or (function()
                              for _, n in ipairs(getFarmOrder()) do
                                  local stripped = tostring(n):gsub("%s*Health:.*$", "")
                                      :gsub("%s*%(level%s*%d+%)%s*$", "")
                                      :gsub("^%s+", ""):gsub("%s+$", "")
                                  if stripped == curName then return true end
                              end
                              return false
                          end)()) do
                        if tool and tool.Name ~= classifiedTool then
                            classifiedTool = tool.Name
                            local isStaff = false
                            pcall(function()
                                local data = require(ReplicatedStorage.Library.WeaponDataStorage).GetWeaponData(tool.Name)
                                isStaff = data ~= nil and tostring(data.WEAPONTYPE):upper() == "STAFF"
                            end)
                            vlift = isStaff and 6 or 4
                        end
                        local pivot = getWorldPivot(mob)
                        if pivot and root and root.Parent then
                            -- Hover above the mob's torso and aim straight DOWN into center
                            -- mass. The sliders nudge (default 0): X strafes sideways, Y raises
                            -- us higher above it -- applied in bone world too so the offset is
                            -- adjustable there (NOTE: bone enemies take TOUCH damage, so a large
                            -- Y can lift the sword off them and swings whiff -- keep Y modest).
                            -- Use an explicit up hint (world +Z) so a near-vertical look can't
                            -- collapse into a NaN CFrame the way CFrame.new(pos, target) does
                            -- when pos is right over target.
                            local desired = pivot.Position + Vector3.new(saveData.farmOffsetX or 0, vlift + (saveData.farmOffsetY or 0), 0)
                            -- The Heartbeat pin above follows this every frame, so we glide
                            -- to (and re-aim down at) the mob smoothly wherever it moves.
                            holdCF = CFrame.lookAt(desired, pivot.Position, Vector3.new(0, 0, 1))
                        end
                        -- Swing whatever is actually EQUIPPED right now. We FOLLOW the
                        -- live equipped tool instead of clinging to the one captured at
                        -- loop start: the quest coordinator keeps the STRONGEST weapon
                        -- equipped (and KillWeapon tasks force a specific one), so re-
                        -- equipping our stale capture would fight it -- each side bumping
                        -- the other's tool back to the Backpack every frame, and every
                        -- swing whiffing ("Tool:Activate() called when tool is not
                        -- equipped"). If nothing is held (respawn / a bump landed us
                        -- empty-handed) we re-equip: our captured tool, else any tool.
                        local held = getEquippedTool()
                        if held then
                            tool = held
                        else
                            if tool and tool.Parent ~= char then
                                pcall(function() humanoid:EquipTool(tool) end)
                            end
                            if not (tool and tool.Parent == char) then
                                tool = ensureToolEquipped()
                            end
                        end
                        farmRuntime.weapon = tool and tool.Name or ""
                        if tool then
                            pcall(function() tool:Activate() end)
                        end
                        swings = swings + 1
                        -- Refresh the Farm Status panel each swing so its HP line
                        -- ticks down live as the target loses health. pcall-guarded so
                        -- a status hiccup can never bubble up to the pass pcall, which
                        -- would kill the pin and UNFREEZE the target mid-fight.
                        if updateFarmStatus then pcall(updateFarmStatus) end
                        task.wait(0.15)
                    end
                    -- Aura mode: if the mob outlived a full swing cap without dying,
                    -- it's too tanky for our current weapon -- park it in the stuck
                    -- set (~8s) so findNearestMobAny rotates on to the next-closest
                    -- killable mob instead of camping it forever.
                    -- Never park a deliberate single bone target (Auto Progress) -- there
                    -- is nothing else to rotate to, so parking it just idles the farm.
                    if saveData._auraMode and swings >= 60 and isMobAlive(mob)
                       and not saveData._boneTargetName then
                        saveData._auraStuck = saveData._auraStuck or {}
                        saveData._auraStuck[mob] = os.clock() + 8
                    end
                    -- Stop pinning before we idle / switch targets.
                    killPin()
                    holdCF = nil
                    if root and root.Parent then
                        pcall(function() root.AssemblyLinearVelocity = Vector3.zero end)
                    end
                    task.wait(0.05)
                end
            end
            end)
            if not passOk then
                -- Transient error (usually a mid-teardown instance during death).
                -- Drop the pin, kill residual velocity, and keep farming -- never
                -- let one bad frame end the run.
                killPin()
                local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then pcall(function() root.AssemblyLinearVelocity = Vector3.zero end) end
                task.wait(0.3)
            end
        end
        killPin()
        stopWatchAoE()  -- farm stopped: drop the AoE listener so it doesn't leak
        farmRuntime.current, farmRuntime.nextName, farmRuntime.weapon, farmRuntime.model = "", "", "", nil
        if mySession == farmSession then
            setFarmSwitchVisual(false)
        end
        if updateFarmStatus then updateFarmStatus() end
    end)
end

farmToggleRow:FindFirstChild("farmSwitchTrack").MouseButton1Click:Connect(function()
    if farmActive then
        stopFarm()
        statusLabel.Text = "Farm stopped"
    else
        startFarm()
    end
end)

-- AUTO KILL AURA hotkey (default: K). Toggles a farm that ignores the mob-type
-- selection and instead camps the NEAREST live mob of any type, retargeting the
-- instant one dies. Reuses the whole farm engine below (strongest-weapon equip,
-- AoE dodge, overhead pin) so it stays at the server's hit-rate ceiling with zero
-- travel/idle time -- the fastest progression the (server-authoritative) game
-- allows. It does NOT and cannot bypass the per-hit cooldown or fake damage.
do
    -- Inlined (no `local`) to stay under the main chunk's 200-local register
    -- ceiling -- the Bone World tab's additions pushed this block to the edge.
    game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.K then
            if farmActive and saveData._auraMode then
                stopFarm()                       -- stopFarm clears _auraMode
                statusLabel.Text = "Kill Aura stopped"
            else
                if farmActive then stopFarm() end -- swap a running normal farm over
                saveData._auraStuck = {}          -- fresh stuck set each activation
                saveData._auraMode = true
                startFarm()
            end
        end
    end)
end

-- Bridge the farm engine to the (early-declared) NPC auto-do coordinator. The
-- NPC-tab "Auto Do Quest" loop lives at the very end of the file where these
-- local functions are out of reach, so hand it live references here.
npcAuto.startFarm = startFarm
npcAuto.stopFarm = stopFarm
npcAuto.isFarming = function() return farmActive end

-- ============================================================
-- BONE WORLD COORDINATOR
-- Drives the Bone-World tab's two toggles (saveData._bone.farmOn / .progressOn)
-- through the SAME farm engine, redirected to the bone-enemy folders via the
-- _boneMode scan flag set below:
--   farmOn     -> _boneTargetName = nil : camp the nearest bone enemy (the pin
--                 teleports the character onto it, wherever the player stands).
--   progressOn -> _boneTargetName = <boss> : camp the exact BOSS that drops the
--                 next missing sword. The portal step is gated on that BOSS dying
--                 (B.enemyAlive), NOT merely on owning the sword: bone trash mobs
--                 drop the same chain swords (Mummy->Bronze, Sandman->Iron, ...),
--                 so an incidental swing that clips a nearby trash mob must not be
--                 allowed to skip the boss / step the wrong portal. Progress walks
--                 the chain one boss (one portal) at a time via B.stepIdx.
-- WEAPON: bone enemies only take damage from BONE-WORLD swords (Bronze Sword etc.),
-- NOT the strongest main-map weapon. So this keeps the highest-tier bone sword the
-- player owns equipped (B.equipBestBone) and SUSPENDS the main auto-equip loops
-- while active (restoring them on stop) so they can't swap a useless main weapon in.
-- The loop dies when the GUI is torn down (screenGui) so a reload can't stack copies.
-- ============================================================
task.spawn(function()
    while screenGui and screenGui.Parent do
        task.wait(1)
        local ok = pcall(function()
            local B = saveData._bone
            local anyOn = B and (B.farmOn or B.progressOn)

            -- Suspend the main auto-equip (strongest/keep-equipped) loops while bone
            -- mode runs, else they fight us for the tool slot with a main weapon that
            -- deals zero damage to bone enemies. Snapshot once; restore when we stop.
            if anyOn and not B._suppressed then
                B._suppressed = { e = saveData.autoEquipEnabled, s = saveData.autoEquipStrongest }
                saveData.autoEquipEnabled = false
                saveData.autoEquipStrongest = false
            elseif not anyOn and B and B._suppressed then
                saveData.autoEquipEnabled = B._suppressed.e
                saveData.autoEquipStrongest = B._suppressed.s
                B._suppressed = nil
            end

            if not anyOn then
                B.stepIdx = nil
                -- Only stop a farm WE started (bone scan mode); never a main-map
                -- aura/quest farm.
                if farmActive and saveData._boneMode then stopFarm() end
                return
            end

            if B.farmOn then
                -- Nearest-any bone enemy, swung with our best owned bone sword.
                B.stepIdx = nil
                saveData._boneTargetName = nil
                saveData._boneMode = true
                saveData._auraMode = true
                saveData._auraStuck = saveData._auraStuck or {}
                pcall(B.equipBestBone)
                if not farmActive then startFarm() end
                return
            end

            -- Auto Progress -- boss-kill driven, ONE portal per boss, walked in
            -- order. B.stepIdx is a persistent pointer into the chain that only
            -- advances after a step's designated BOSS is dead. Init it to the first
            -- step we don't already own (so prior progress isn't re-farmed).
            if not B.stepIdx then
                local _, i = B.frontier(B.ownedSet())
                B.stepIdx = i or (#B.chain + 1)
            end
            if B.stepIdx > #B.chain then
                B.progressOn = false
                if farmActive and saveData._boneMode then stopFarm() end
                B.setStatus("Auto Progress complete - all mapped bone swords obtained.")
                return
            end

            local step = B.chain[B.stepIdx]
            local owned = B.ownedSet()
            -- Only advance once we hold this step's sword AND its boss is no longer
            -- alive (killed / despawned). While the boss still stands we keep
            -- farming it, even if a trash kill already handed us the sword -- the
            -- portal step must follow the BOSS, never an incidental trash drop.
            local bossAlive = B.enemyAlive and B.enemyAlive(step[2])
            if owned[step[1]] and not bossAlive then
                if farmActive and saveData._boneMode then stopFarm() end
                B.equip(step[1])
                task.wait(0.35)
                local pad = B.padForSword(step[1])
                if pad then B.padTouch(pad) end
                B.setStatus("Killed " .. step[2] .. ", got " .. step[1]
                    .. " - stepping through its portal...")
                B.stepIdx = B.stepIdx + 1
                task.wait(1.3)
                return
            end

            -- Still need to kill this step's boss: camp ONLY it, swung with the
            -- best bone sword we own (bone enemies ignore main-map weapons).
            saveData._boneTargetName = step[2]
            saveData._boneMode = true
            saveData._auraMode = true
            saveData._auraStuck = saveData._auraStuck or {}
            pcall(B.equipBestBone)
            if not farmActive then startFarm() end
            B.setStatus("Auto Progress: farming " .. step[2] .. " for " .. step[1]
                .. " (weapon: " .. (B.bestBoneName() or "starter") .. ")...")
        end)
        if not ok then task.wait(1) end
    end
end)

-- ============================================================
-- AUTO QUEST COORDINATOR
-- Reads the game's replicated quest state (player attributes, JSON) and drives
-- auto-accept / auto-turn-in / auto-farm from the saveData.quest* flags that the
-- Quest-tab toggles set. Auto-farm reuses the real farm engine: it parks the
-- current quest's kill target in saveData._questFarmTargets (picked up by the
-- getFarmOrder override) and calls startFarm()/stopFarm(), so quest kills use the
-- same proven pin/dodge/swing combat and never clobber the manual Farm selection.
-- Runs in a task.spawn closure -> its locals are in their own register budget and
-- add nothing to the main chunk's 200-local ceiling. Placed inside the farm block
-- so startFarm/stopFarm/isMobAlive are in scope as upvalues.
-- ============================================================
task.spawn(function()
    local HttpService = game:GetService("HttpService")
    local QuestEvents = ReplicatedStorage:FindFirstChild("QuestEvents")
    local TIERS = { "Daily", "Weekly", "Monthly" }
    local questStartedFarm = false   -- did WE start the farm (so we know to stop it)
    local lastPoke = 0               -- throttle Quest Master board refreshes
    local farmAssertT = 0            -- last time our farm was confirmed engaged (staleness watchdog)
    local skipUntil = {}             -- taskKey -> os.clock expiry; a task making no progress is parked here
    local curKey, curProg, curProgT = nil, 0, 0  -- track the chosen task's kill progress over time

    local function decode(attr)
        local out = {}
        pcall(function() out = HttpService:JSONDecode(localPlayer:GetAttribute(attr) or "{}") end)
        if type(out) ~= "table" then out = {} end
        return out
    end

    -- Strip a mob model's volatile name suffix down to its stable base (baseMobName
    -- itself is a block-local elsewhere, so re-inline the same rules here).
    local function strip(nm)
        nm = tostring(nm)
        nm = nm:gsub("%s*Health:.*$", ""):gsub("%s*\u{2764}.*$", ""):gsub("%s*%(level%s*%d+%)%s*$", "")
        return (nm:gsub("^%s+", ""):gsub("%s+$", ""))
    end

    -- Distinct base names of live mobs in Workspace.Mobs, NEAREST FIRST, so the farm
    -- engages the closest reachable target. For "kill bosses" we keep only names the
    -- server treats as a boss (name contains "boss"). For "kill any" we prefer normal
    -- mobs and push the mega-tier ones (bosses / gods / champions / (??)-secrets) to
    -- the back, since a near-unkillable neighbour would otherwise stall the farm on a
    -- target it can't clear. Feeds the farm override for kill-any / kill-boss tasks.
    local function liveMobNames(bossesOnly)
        local folder = Workspace:FindFirstChild("Mobs")
        if not folder then return {} end
        local char = localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local origin = root and root.Position or Vector3.new()
        local cands = {}
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") and isMobAlive(child) then
                local nm = child.Name
                local low = nm:lower()
                local isBoss = low:find("boss") ~= nil
                -- The model name carries live stats, e.g. "Flying Eyeball (level
                -- 1500000) Health: 100000000000/100000000000". Parse them: a mob with
                -- an absurd level or max-HP is a decorative super-boss (100 BILLION HP,
                -- level 1.5M) that a normal weapon can NEVER dent. Name-based tough
                -- detection misses these (the name is just "Flying Eyeball"), so the
                -- farm used to fly thousands of studs to hover over one and swing
                -- forever for zero kills. Gate on the numbers, not the name.
                local lvl = tonumber(nm:match("%(level%s*(%d+)%)")) or 0
                local maxHp = tonumber(nm:match("Health:%s*[%d%.]+%s*/%s*(%d+)")) or 0
                local absurd = lvl > 100000 or maxHp > 5000000   -- unkillable super-mob
                if (not bossesOnly) or isBoss then
                    local pivotOk, pos = pcall(function() return child:GetPivot().Position end)
                    local d = pivotOk and (pos - origin).Magnitude or 1e9
                    -- Mega-tier markers: keep them, but sort them after normal mobs
                    -- for kill-any so we chew through weak mobs first.
                    local tough = isBoss or low:find("god") or low:find("champion")
                        or low:find("%(%?%?%)") or low:find("titan") or low:find("lord")
                    -- For kill-any, DROP the absurd super-mobs entirely (never farmable).
                    -- For kill-boss they can stay but sink to the very back.
                    if not (absurd and not bossesOnly) then
                        cands[#cands + 1] = {
                            base = strip(nm), dist = d,
                            tough = (tough or absurd) and 1 or 0,
                        }
                    end
                end
            end
        end
        table.sort(cands, function(a, b)
            if bossesOnly then return a.dist < b.dist end
            if a.tough ~= b.tough then return a.tough < b.tough end
            return a.dist < b.dist
        end)
        local seen, out = {}, {}
        for _, c in ipairs(cands) do
            if c.base ~= "" and not seen[c.base] then
                seen[c.base] = true
                out[#out + 1] = c.base
                if #out >= 40 then break end
            end
        end
        return out
    end

    -- Is `name` an actual WEAPON (per the game's WeaponDataStorage)? Bounty
    -- "KillWeapon" tasks sometimes name a MASK/HELMET as their "weapon" (e.g.
    -- "Cerberus Mask"); equipping that as if it were a weapon leaves the farm
    -- swinging a hat for zero damage. This gate stops that.
    local weaponDataMod = nil
    local function isWeapon(name)
        if not name or name == "" then return false end
        if weaponDataMod == nil then
            weaponDataMod = false
            pcall(function()
                weaponDataMod = require(ReplicatedStorage.Library.WeaponDataStorage)
            end)
        end
        if not weaponDataMod then return true end   -- can't verify -> don't block
        local ok, data = pcall(function() return weaponDataMod.GetWeaponData(name) end)
        return ok and data ~= nil
    end

    -- Wearables (helmets/masks/etc.) can carry a WeaponData entry too, so isWeapon
    -- alone lets a hat pass and the farm ends up swinging armor for no damage. Exclude
    -- anything that reads as a wearable by name.
    local function looksLikeArmor(name)
        name = tostring(name):lower()
        return name:find("helmet") or name:find("helm") or name:find("mask")
            or name:find("armor") or name:find("crown") or name:find("hat")
            or name:find("cap") or name:find("hood") or name:find("shield") ~= nil
    end
    local function isRealWeapon(name)
        return isWeapon(name) and not looksLikeArmor(name)
    end

    -- Highest-damage OWNED real weapon (a Tool in the Backpack or already held),
    -- scored via WeaponDataStorage: MAXDAMAGE, then MINDAMAGE, then faster COOLDOWN.
    -- Armour/masks are excluded (isRealWeapon). Returns the Tool instance, or nil.
    -- This is the quest-farm's own copy of the Farm tab's "keep strongest equipped"
    -- pick, kept self-contained here (the Farm tab's W.getStrongest lives in a
    -- do-block that's out of scope for this coordinator closure).
    local function strongestRealWeapon()
        local char = localPlayer.Character
        local bp = localPlayer:FindFirstChild("Backpack")
        local best, bMax, bMin, bCd
        local function consider(tool)
            if not (tool and tool:IsA("Tool")) then return end
            if not isRealWeapon(tool.Name) then return end
            if not weaponDataMod then isWeapon(tool.Name) end   -- lazy-load the module once
            local mx, mn, cd = 0, 0, 1
            if weaponDataMod then
                local ok, d = pcall(function() return weaponDataMod.GetWeaponData(tool.Name) end)
                if ok and d then
                    mx = tonumber(d.MAXDAMAGE) or 0
                    mn = tonumber(d.MINDAMAGE) or 0
                    cd = tonumber(d.COOLDOWN) or 1
                end
            end
            local better
            if not best then better = true
            elseif mx ~= bMax then better = mx > bMax
            elseif mn ~= bMin then better = mn > bMin
            else better = cd < bCd end
            if better then best, bMax, bMin, bCd = tool, mx, mn, cd end
        end
        if bp then for _, c in ipairs(bp:GetChildren()) do consider(c) end end
        if char then for _, c in ipairs(char:GetChildren()) do consider(c) end end
        return best
    end

    -- Guarantee a REAL weapon is held before/while quest-farming. A KillWeapon task's
    -- own weapon wins (killing with anything else earns no credit for it); otherwise we
    -- keep the STRONGEST owned weapon equipped -- re-checked each pass so a stronger
    -- pickup is swapped in automatically. Idempotent: if the right weapon is already
    -- held it does nothing, so it never thrashes the equip slot. Crucially it REPLACES a
    -- non-weapon (armor/mask) a KillWeapon task may have left on, which was the cause of
    -- "auto-farm runs but never kills".
    local function ensureRealWeapon(prefer)
        local char = localPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not humanoid then return end
        local equipped = char:FindFirstChildOfClass("Tool")
        if prefer and isRealWeapon(prefer) then
            if equipped and equipped.Name == prefer then return end
            local bp = localPlayer:FindFirstChild("Backpack")
            local t = (bp and bp:FindFirstChild(prefer)) or char:FindFirstChild(prefer)
            if t and t:IsA("Tool") then pcall(function() humanoid:EquipTool(t) end) return end
        end
        local best = strongestRealWeapon()
        if best then
            if equipped and equipped == best then return end   -- strongest already held
            pcall(function() humanoid:EquipTool(best) end)
            return
        end
        -- No stat data at all: fall back to keeping any real weapon rather than armor.
        if equipped and isRealWeapon(equipped.Name) then return end
        local bp = localPlayer:FindFirstChild("Backpack")
        if bp then
            for _, c in ipairs(bp:GetChildren()) do
                if c:IsA("Tool") and isRealWeapon(c.Name) then
                    pcall(function() humanoid:EquipTool(c) end)
                    return
                end
            end
        end
    end

    -- Share the strongest-weapon equipper with the NPC-tab "Auto Do Quest"
    -- coordinator (end of file) so it farms giver quests with a real weapon too.
    npcAuto.ensureWeapon = ensureRealWeapon

    -- One human-readable task line, e.g. "Kill (?) Rob 3/5".
    local function taskLine(t, cur)
        local amt = t.Amount or 1
        cur = cur or 0
        local ty = t.Type
        local verb
        if ty == "KillSpecific" or ty == "KillTimeLimit" then verb = "Kill " .. tostring(t.Target)
        elseif ty == "KillAny" then verb = "Kill enemies"
        elseif ty == "KillBosses" then verb = "Kill bosses"
        elseif ty == "KillWeapon" then verb = "Kill w/ " .. tostring(t.Weapon or t.Target or "weapon")
        elseif ty == "KillDistance" then verb = "Snipe enemies"
        elseif ty == "PlayTime" then verb = "Play time (sec)"
        elseif ty == "OwnsTool" then verb = "Obtain " .. tostring(t.Target)
        elseif ty == "Currency" then verb = "Reach " .. tostring(t.Target or t.CurrencyType)
        elseif ty == "TalkToNPC" then verb = "Talk to " .. tostring(t.Target)
        else verb = tostring(ty or "Progress") end
        return verb .. " " .. cur .. "/" .. amt
    end

    -- Target name list for a task if it's an incomplete, attack-farmable kill task;
    -- nil for complete tasks and non-combat types (PlayTime / OwnsTool / Currency).
    local function farmTargetsFor(t, cur)
        if (cur or 0) >= (t.Amount or 1) then return nil end
        local ty = t.Type
        if ty == "KillSpecific" or ty == "KillTimeLimit" then
            -- Only lock onto a named mob/boss if a live copy exists RIGHT NOW; else
            -- return nil so the coordinator falls through to a task we can actually
            -- farm (kill-any / kill-weapon) instead of idling on an unspawned boss.
            return findNearestMobOfName(tostring(t.Target)) and { tostring(t.Target) } or nil
        elseif ty == "KillAny" or ty == "KillDistance" then
            local l = liveMobNames(false)
            return #l > 0 and l or nil
        elseif ty == "KillWeapon" then
            -- Side-effect-free: weapon equipping happens once for the CHOSEN task in
            -- the AUTO FARM block, not here (this runs for every task during scanning).
            local l = liveMobNames(false)
            return #l > 0 and l or nil
        elseif ty == "KillBosses" then
            local l = liveMobNames(true)
            return #l > 0 and l or nil
        end
        return nil
    end

    local function pokeQuestMaster()
        local qg = Workspace:FindFirstChild("QuestGivers")
        local npc = qg and qg:FindFirstChild("~Quest Master~")
        local torso = npc and (npc:FindFirstChild("Torso") or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head"))
        local prompt = torso and torso:FindFirstChildOfClass("ProximityPrompt")
        if prompt then pcall(function() fireproximityprompt(prompt) end) end
    end

    -- Self-healing loop. Binding liveness to a captured screenGui.Parent used to kill
    -- the whole coordinator PERMANENTLY the instant the GUI was briefly detached (a
    -- respawn quirk, an anti-cheat pass, or any transient re-parent) -- after which
    -- auto-quest silently stopped forever. Now a detach is TOLERATED: we only give up
    -- if the GUI stays gone for a sustained window (a real teardown / script re-run,
    -- which Destroy()s the old GUI). Any shorter blip self-heals.
    local goneSince = nil
    while true do
        if not (screenGui and screenGui.Parent) then
            goneSince = goneSince or os.clock()
            if os.clock() - goneSince > 8 then break end
            task.wait(1)
        else
        goneSince = nil
        local passOk = pcall(function()
            local active    = decode("QuestData_Active")
            local bounties  = decode("QuestData_Bounties")
            local cooldowns = decode("QuestData_Cooldowns")

            -- AUTO ACCEPT: grab every offered tier that isn't already active or on
            -- cooldown. If nothing is offered yet, poke the Quest Master (throttled)
            -- so the server generates the board into QuestData_Bounties.
            if saveData.questAutoAccept and QuestEvents then
                local anyOffered = false
                for _, tier in ipairs(TIERS) do
                    if bounties[tier] then
                        anyOffered = true
                        local onCd = cooldowns[tier] and os.time() < cooldowns[tier]
                        if not active[tier] and not onCd then
                            pcall(function() QuestEvents.AcceptQuest:FireServer(tier) end)
                            task.wait(0.25)
                        end
                    end
                end
                if not anyOffered and os.time() - lastPoke > 8 then
                    lastPoke = os.time()
                    pokeQuestMaster()
                end
            end

            -- AUTO TURN IN: completion is granted server-side the moment a tier's
            -- tasks are all met (it leaves QuestData_Active and goes on cooldown) --
            -- there is no client turn-in to fire. So all we do is a throttled board
            -- refresh, which re-offers a tier the instant it comes off cooldown for
            -- Auto Accept to grab. NOTE: we must NEVER synchronously Invoke the
            -- ForceFlushQuests BindableFunction here -- it has no bound OnInvoke
            -- handler on the client, so Invoke() BLOCKS THE THREAD FOREVER. Doing so
            -- froze this entire coordinator on its first pass (auto-farm, auto-accept
            -- and the status readout all dead), which read as "auto farm quest broken
            -- on every execution". Keep this path yield-free.
            if saveData.questAutoTurnin then
                if os.time() - lastPoke > 8 then
                    lastPoke = os.time()
                    pokeQuestMaster()
                end
            end

            -- Build the progress readout AND collect every currently-farmable task
            -- (Daily -> Weekly -> Monthly order) so the rotation watchdog below can
            -- skip any that stall and move on instead of grinding forever.
            local lines = {}
            local farmable = {}   -- { {key, desc, targets, cur}, ... } in priority order
            for _, tier in ipairs(TIERS) do
                local a = active[tier]
                if a and a.DynamicInfo then
                    local info = a.DynamicInfo
                    local prog = a.Progress or {}
                    lines[#lines + 1] = "<b>" .. tier .. "</b>  <font color=\"#B0B0C0\">" .. tostring(info.Name or "Bounty") .. "</font>"
                    for i, t in ipairs(info.Tasks or {}) do
                        local cur = prog[i] or 0
                        local done = cur >= (t.Amount or 1)
                        local s = taskLine(t, cur)
                        if done then
                            s = "<font color=\"#00FF88\">  " .. s .. "  \u{2713}</font>"
                        else
                            s = "  " .. s
                        end
                        lines[#lines + 1] = s
                        local tg = farmTargetsFor(t, cur)
                        if tg then
                            farmable[#farmable + 1] = {
                                key = tier .. "#" .. i .. "#" .. tostring(t.Type) .. "#" .. tostring(t.Target or t.Weapon or ""),
                                desc = tier .. " - " .. taskLine(t, cur),
                                targets = tg,
                                cur = cur,
                                weapon = (t.Type == "KillWeapon") and (t.Weapon or t.Target) or nil,
                            }
                        end
                    end
                else
                    local onCd = cooldowns[tier] and os.time() < cooldowns[tier]
                    local st = onCd and ("on cooldown (" .. math.max(0, math.floor((cooldowns[tier] - os.time()) / 60)) .. "m)")
                        or (bounties[tier] and "available - accept it" or "no offer yet")
                    lines[#lines + 1] = "<b>" .. tier .. "</b>  <font color=\"#8080A0\">" .. st .. "</font>"
                end
            end

            -- ROTATION WATCHDOG: pick the first farmable task that isn't currently
            -- parked, and track its kill progress. If the chosen task makes NO progress
            -- for 15s (e.g. a required boss that's present but the player can't actually
            -- kill), park it for 60s and rotate to the next task -- so auto-farm keeps
            -- making progress somewhere instead of looking frozen on an unkillable one.
            local nowc = os.clock()
            local chosen
            for _, f in ipairs(farmable) do
                if not (skipUntil[f.key] and nowc < skipUntil[f.key]) then chosen = f break end
            end
            if not chosen then chosen = farmable[1] end   -- all parked: fall back to the first
            local farmTargets, farmDesc = nil, nil
            if chosen then
                farmTargets, farmDesc = chosen.targets, chosen.desc
                if chosen.key == curKey then
                    if chosen.cur > curProg then
                        curProg, curProgT = chosen.cur, nowc
                    elseif nowc - curProgT > 15 then
                        skipUntil[chosen.key] = nowc + 60
                        curKey = nil   -- re-pick a different task next tick
                    end
                else
                    curKey, curProg, curProgT = chosen.key, chosen.cur, nowc
                end
            end

            -- AUTO FARM: hand the target to the farm engine, or release it. This is
            -- written to be idempotent + self-correcting every tick so it can never
            -- wedge: the farm thread can be killed out from under us (e.g. a transient
            -- GUI detach makes its own screenGui check fail) while farmActive stays
            -- stuck TRUE -- the old code's `if not farmActive` guard then refused to
            -- ever restart, so auto-farm "broke" and never recovered. Now we watch
            -- whether our farm is actually ENGAGED (farmRuntime has a live target) and
            -- force a clean restart if it's been idle-but-active too long.
            local action
            if saveData.questAutoFarm and farmTargets then
                saveData._questFarmTargets = farmTargets
                -- Make sure we're actually holding a real weapon (prefer the chosen
                -- KillWeapon task's weapon when it's genuine). Fixes "farms but never
                -- kills" caused by a mask/helmet being equipped.
                ensureRealWeapon(chosen and chosen.weapon)
                local now = os.clock()
                if not farmActive then
                    -- Not running -> start it (also the normal first-enable path).
                    questStartedFarm = true
                    startFarm()
                    farmAssertT = now
                elseif questStartedFarm then
                    -- Running and ours: confirm it's engaged. If the thread is alive and
                    -- on a target, keep resetting the watchdog. If farmActive is true but
                    -- nothing is engaged for >6s, the thread is dead/stuck -> restart.
                    if farmRuntime.model ~= nil or farmRuntime.current ~= "" then
                        farmAssertT = now
                    elseif now - farmAssertT > 6 then
                        pcall(stopFarm)
                        task.wait(0.1)
                        questStartedFarm = true
                        startFarm()
                        farmAssertT = now
                    end
                end
                action = "Auto Quest - " .. (farmDesc or "farming") .. "   (target: " .. tostring(farmTargets[1]) .. ")"
            else
                -- Toggle off, OR no farmable kill task right now: release our override
                -- and stop the farm ONLY if we own it (never kill a manual farm run).
                -- Guard: the NPC-tab "Auto Do Quest" coordinator drives the SAME
                -- _questFarmTargets channel. Don't wipe its target while it's on, or
                -- the farm flips back to the manual Farm picks (e.g. Robbers) for a
                -- pass every few seconds -- the "targets right mob for 1s then farms
                -- robbers" bug.
                if saveData._questFarmTargets ~= nil and not npcAuto.on then
                    saveData._questFarmTargets = nil
                end
                if questStartedFarm then
                    questStartedFarm = false
                    if farmActive then pcall(stopFarm) end
                end
                if not saveData.questAutoFarm then
                    action = "Auto Farm: off"
                else
                    local hasActive = active.Daily or active.Weekly or active.Monthly
                    action = hasActive and "Auto Quest - no kill task to farm (playtime/obtain tasks are passive)"
                        or "Auto Quest - no active quest; enable Auto Accept"
                end
            end

            -- Push to the Quest-tab labels (found by name; safe if the tab isn't built).
            local qcp = contentArea:FindFirstChild("QuestContainer")
            if qcp then
                local statusLbl = qcp:FindFirstChild("QuestStatus", true)
                local actionLbl = qcp:FindFirstChild("QuestAction", true)
                if statusLbl then
                    statusLbl.Text = (#lines > 0) and table.concat(lines, "\n")
                        or "No active quests. Turn on Auto Accept (or hit Refresh Bounty Board) to begin."
                end
                if actionLbl then actionLbl.Text = action end
            end
        end)
        task.wait(passOk and 1.0 or 1.5)
        end
    end
end)
end

-- DRAG - Title bar drag
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        saveData.windowPos = {mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset}
        saveDataToFile()
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- AUTO-UPDATE
local function autoUpdate()
    while screenGui and screenGui.Parent do
        task.wait(60)
        healthCache = {}
        local newMobs = scanMobs()
        local newBosses = scanBosses()
        local changed = false
        
        if #newMobs ~= #mobList then
            changed = true
        else
            for i, n in ipairs(newMobs) do
                if mobList[i] ~= n then changed = true break end
            end
        end
        
        if not changed then
            for r, list in pairs(newBosses) do
                local old = bossData[r] or {}
                if #list ~= #old then
                    changed = true
                    break
                end
                for i, n in ipairs(list) do
                    if old[i] ~= n then changed = true break end
                end
                if changed then break end
            end
        end
        
        if changed then
            if #newMobs > 0 then mobList = newMobs end
            local has = false
            for _, list in pairs(newBosses) do
                if #list > 0 then has = true break end
            end
            if has then
                for r, list in pairs(newBosses) do
                    bossData[r] = list
                end
            end
            if currentTab == "Mobs" or currentTab == "Bosses" or currentTab == "Farm" then
                populateDropdown(searchBox.Text)
                updateLayout()
            end
            statusLabel.Text = "Auto-updated!"
            task.wait(1)
            statusLabel.Text = "Select a target"
        end
    end
end

-- ============================================================
-- NPC AUTO DO QUEST coordinator - drives the farm engine through the selected
-- giver's progression-quest chain when the NPC-tab "Auto Do Quest" switch is on.
-- Bridged from the (early) NPC panel via the npcAuto table: it farms the giver's
-- CURRENT active quest kill-targets, and when no quest is active it accepts the
-- giver's next available one (throttled). Owns the farm only while running, and
-- hands it back (clears _questFarmTargets, stops the loop) when switched off.
-- ============================================================
task.spawn(function()
    local managing = false
    local lastAccept = 0
    local lastBuy = 0
    local lastTalk = 0
    local function releaseFarm()
        saveData._questFarmTargets = nil
        if npcAuto.isFarming and npcAuto.isFarming() and npcAuto.stopFarm then npcAuto.stopFarm() end
    end
    while true do
        local ok = pcall(function()
            if npcAuto.on and npcAuto.giver and npcAuto.hasActive then
                managing = true
                if npcAuto.hasActive(npcAuto.giver) then
                    -- Buy anything the quest needs but you don't own yet (OwnsTool
                    -- tasks, e.g. a shop weapon), throttled. Some quests advance by
                    -- purchase, not kills -- without this the chain stalls there.
                    if npcAuto.buyNeeded and (os.clock() - lastBuy) > 5 then
                        if npcAuto.buyNeeded(npcAuto.giver) then lastBuy = os.clock() end
                    end
                    -- A quest is active: farm its still-incomplete kill targets.
                    local targets = npcAuto.activeTargets(npcAuto.giver)
                    if #targets > 0 then
                        saveData._questFarmTargets = targets
                        -- Keep the strongest owned weapon equipped so kills actually
                        -- register (no weapon / a mask means farming but never killing).
                        if npcAuto.ensureWeapon then pcall(npcAuto.ensureWeapon) end
                        if not (npcAuto.isFarming and npcAuto.isFarming()) and npcAuto.startFarm then
                            npcAuto.startFarm()
                        end
                    else
                        -- Active but nothing to kill right now: idle the farm, and
                        -- if the remaining task is a "Talk to <NPC>" handoff, go do
                        -- it (throttled) so the chain doesn't stall on it.
                        releaseFarm()
                        if npcAuto.talkNeeded and (os.clock() - lastTalk) > 5 then
                            if npcAuto.talkNeeded(npcAuto.giver) then lastTalk = os.clock() end
                        end
                    end
                else
                    -- No active quest for this giver: pull the next one from the
                    -- server (throttled so we don't spam the dialogue).
                    releaseFarm()
                    if npcAuto.acceptNext and (os.clock() - lastAccept) > 6 then
                        lastAccept = os.clock()
                        npcAuto.acceptNext(npcAuto.giver)
                    end
                end
            elseif managing then
                managing = false
                releaseFarm()
            end
        end)
        task.wait(ok and 3 or 5)
    end
end)

-- ============================================================
-- FINAL: Apply high ZIndex to all GUI elements and start
-- ============================================================
applyHighZIndex(screenGui, 9999)

refreshAll()
coroutine.wrap(autoUpdate)()