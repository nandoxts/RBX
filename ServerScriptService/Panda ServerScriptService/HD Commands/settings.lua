	--[[
▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

██╗     ██╗ ██████╗███████╗███╗   ██╗███████╗███████╗
██║     ██║██╔════╝██╔════╝████╗  ██║██╔════╝██╔════╝
██║     ██║██║     █████╗  ██╔██╗ ██║███████╗█████╗  
██║     ██║██║     ██╔══╝  ██║╚██╗██║╚════██║██╔══╝  
███████╗██║╚██████╗███████╗██║ ╚████║███████║███████╗
╚══════╝╚═╝ ╚═════╝╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝

▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

/* Copyright (C) 2025 Panda - All rights reserved
 * You only have the right to modify the file.
 *
 * It is strictly forbidden to resell the code,
 * copy the code, distribute the code and above
 * all to make an image of the code.
 * If you want to do this, contact Panda15Fps
 *
 * Remember that any violation will result in a report
 * for unauthorized use of copyright and the ban for
 * this is permanent as well as the closure of the game.
 *
 * https://discord.gg/jmQCcC28Fd
 */

▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
]]

local Configuration = require(game.ServerScriptService["Panda ServerScriptService"].Configuration)

--------------| SETUP RANKS |--------------																															 ]] 
return{

	Ranks = {
		{5,	  "Owner",					{"Panda15Fps",3405128485},{"PandaaUGC",7370452980},{"Pandaa15Fps",5472718136},{"VALLEIDS",522683358},{"bvwdhfv",4074563891}};
		{4.4, "Help Creator",			{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},	};
		{4.3, "Lead Admin",				{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},	};
		{4.2, "Head Admin",				{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},	};
		{4.1, "Administrador",			{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},{"",0},	};
		{4,   "Moderador",				{"",0},	};
		{3,   "DJ",						{"",0},	};
		{2.1, "Influencer",				{"",0},	};
		{2,   "Socio",					{"",0},	};
		{1.1, "COMMANDS",				{"",0},	};
		{1,	  "VIP",					{"",0},	};
		{0,	  "NonAdmin",		};
	};

	-- GAMEPASSES
	Gamepasses = {
		[Configuration.VIP] = "VIP"; -- VIP
		[Configuration.COMMANDS] = "COMMANDS"; -- COMMANDS
	};

	-- ASSETS
	Assets = {
		[0] = "VIP";
	};

	-- GROUPS
	Groups = {
		[Configuration.GroupID] = {
			[255] = "Owner"; -- [ Propietario ]
			[254] = "Owner"; -- [ Co-Owner ]
			[253] = "Help Creator"; -- [ Help Creator ]
			[252] = "Lead Admin"; -- [ Lead Admin ]
			[251] = "Head Admin"; -- [ Head Admin ]
			[250] = "Administrador"; -- [ Administrador ]
			[249] = "Moderador"; -- [ Moderador ]
			[248] = "DJ"; -- [ DJ ]
			[247] = "Influencer"; -- [ Influencer ]
			[246] = "Socio" -- [ Socio ]
		};
	};

	-- FRIENDS
	Friends = "NonAdmin";

	-- VIP SERVER OWNER
	VipServerOwner = "NonAdmin";

	-- FREE ADMIN
	FreeAdmin = "NonAdmin";

	--------------| BANLAND |--------------
	Banned = {"",0};

	--------------| SYSTEM SETTINGS |--------------
	Prefix				= ";";			
	SplitKey 			= " ";			
	BatchKey 			= "";			
	QualifierBatchKey 	= ",";			

	AppTheme			= "Red";	
	AppThemes = {
		{"Blurple", Color3.fromRGB(135, 98, 255),	};
		{"Red", 	Color3.fromRGB(199, 80, 82),	};
		{"Orange", 	Color3.fromRGB(152, 114, 69),	};
		{"Green", 	Color3.fromRGB(73, 148, 104),	};
		{"Blue", 	Color3.fromRGB(91, 122, 189),	};
		{"Pink",	Color3.fromRGB(172, 121, 167),	};
		{"Black", 	Color3.fromRGB(35, 39, 47),		};
	};

	ShowOnlyUsableAndBuyableCommands	= false; 	
	DisableBoosterBundles				= false;	
	RankRequiredToViewCommandsIcon		= 0; 		
	RankRequiredToViewDashboardIcon		= 1; 		

	NoticeSoundId		= 2865227271;	
	NoticeVolume		= 0.1;			
	NoticePitch			= 1;			
	ErrorSoundId		= 2865228021;	
	ErrorVolume			= 0.1;			
	ErrorPitch			= 1;			
	AlertSoundId		= 9161622880;	
	AlertVolume			= 0.5;			
	AlertPitch			= 1;			

	WelcomeBadgeId		= 0;			

	CommandDebounce		= true;			
	SaveRank			= true;			
	LoopCommands		= 4.1;			

	Colors = {							
		{"r", 		"Red",		 		Color3.fromRGB(255, 0, 0)		};
		{"o", 		"Orange",	 		Color3.fromRGB(250, 100, 0)		};
		{"y", 		"Yellow",			Color3.fromRGB(255, 255, 0)		};
		{"g", 		"Green"	,			Color3.fromRGB(0, 255, 0)		};
		{"dg", 		"DarkGreen"	, 		Color3.fromRGB(0, 125, 0)		};
		{"b", 		"Blue",		 		Color3.fromRGB(0, 255, 255)		};
		{"db", 		"DarkBlue",			Color3.fromRGB(0, 50, 255)		};
		{"p", 		"Purple",	 		Color3.fromRGB(135, 98, 255)	};
		{"pk",		"Pink",		 		Color3.fromRGB(255, 85, 185)	};
		{"bk",		"Black",		 	Color3.fromRGB(0, 0, 0)			};
		{"w",		"White",	 		Color3.fromRGB(255, 255, 255)	};
	};

	Cmdbar						= 1;
	Cmdbar2						= 3;
	ViewBanland					= 4;
	RankRequiredToViewPage		= {	
		["Commands"]		= 0;
		["Moderation"]		= 4;
		["Revenue"]			= 4;
		["Settings"]		= 1;
	};

	WelcomeRankNotice			= false;			
	WarnIncorrectPrefix			= false;			
	DisableAllNotices			= true;		
	HideWarningsIfBelowRank		= 1; 			

	ScaleLimit					= 2;			
	IgnoreScaleLimit			= 5;			
	CommandLimits				= {				
		["fly"]	= {
			Limit 				= 10000;
			IgnoreLimit 		= 4;
		};
		["fly2"]	= {
			Limit 				= 10000;
			IgnoreLimit 		= 4;
		};
		["noclip"]	= {
			Limit 				= 10000;
			IgnoreLimit 		= 4;
		};
		["noclip2"]	= {
			Limit 				= 10000;
			IgnoreLimit 		= 4;
		};
		["speed"]	= {
			Limit 				= 10000;
			IgnoreLimit 		= 4;
		};
		["jumpPower"]	= {
			Limit 				= 10000;
			IgnoreLimit 		= 4;
		};
	};

	VIPServerCommandBlacklist	= {""};	
	GearBlacklist				= {67798397};	
	IgnoreGearBlacklist			= 4;			

	PlayerDataStoreVersion		= "V1.0";		
	SystemDataStoreVersion		= "V1.0";		

	CoreNotices					= {	
		--NoticeName = NoticeDetails;
	};

	SetCommandRankByName = {


		-- Owner 
		["morph"] = "Owner";
		["bundle"] = "Owner";
		["forceField"] = "Owner";
		["paint"] = "Owner";
		["ping"] = "Owner";
		["face"] = "Owner";
		["head"] = "Owner";
		["insert"] = "Owner";
		["change"] = "Owner";
		["subtract"] = "Owner";
		["resetStats"] = "Owner";
		["punish"] = "Owner";
		["fogColor"] = "Owner";
		["add"] = "Owner";
		["reflectance"] = "Owner";
		["laserEyes"] = "Owner";
		["bodyTypeScale"] = "Owner";
		["depth"] = "Owner";
		["height"] = "Owner";
		["hipHeight"] = "Owner";
		["apparate"] = "Owner";
		["refresh"] = "Lead Admin";
		["lockPlayer"] = "Owner";
		["chatHijacker"] = "Owner";
		["saveMap"] = "Owner";
		["loadMap"] = "Owner";
		["follow"] = "Owner";
		["chatTagColor"] = "Owner";
		["chatNameColor"] = "Owner";
		["chatName"] = "Owner";
		["notice"] = "Owner";
		-- Help Creator
		["permBan"] = "Owner";
		["globalAlert"] = "Help Creator";
		["serverLock"] = "Help Creator";
		["forcePlace"] = "Help Creator";
		["permRank"] = "Help Creator";
		["shutdown"] = "Help Creator";
		["chat"] = "Help Creator";
		["createTeam"] = "Help Creator";
		--["globalAnnouncement"] = "Help Creator";
		["removeTeam"] = "Help Creator";
		["place"] = "Help Creator";
		["fast"] = "Help Creator";
		["superJump"] = "Help Creator";
		["slow"] = "Help Creator";
		["time"] = "Help Creator";
		["jump"] = "Help Creator";
		["blur"] = "Help Creator";
		["team"] = "Help Creator";
		["explode"] = "Help Creator";
		["name"] = "Help Creator";
		["heavyJump"] = "Help Creator";
		["health"] = "Help Creator";
		["heal"] = "Help Creator";
		["damage"] = "Help Creator";
		["bring"] = "Help Creator";
		["handTo"] = "Help Creator";
		["fling"] = "Help Creator";
		["crash"] = "Help Creator";
		["fog"] = "Help Creator";
		["lockMap"] = "Help Creator";
		["globalAnnouncement"] = "Help Creator";
		["jumpHeight"] = "Help Creator";
		["sellGamepass"] = "Help Creator";
		["sellAsset"] = "Help Creator";
		["banland"] = "Help Creator";
		["tempRank"] = "Help Creator";
		["globalVote"] = "Help Creator";
		["rank"] = "Help Creator";
		["unRank"] = "Help Creator";
		["mute"] = "Help Creator";
		["r15"] = "Help Creator";
		["sc"] = "Help Creator";
		["kill"] = "Help Creator";
		["message"] = "Help Creator";
		["serverMessage"] = "Help Creator";
		["systemMessage"] = "Help Creator";
		-- Lead Admin
		["view"] = "Moderador";
		["control"] = "Help Creator";
		["ban"] = "Owner";
		["unban"] = "Owner";
		["aura2"] = "Owner";
		["freeze"] = "Help Creator";
		-- Head Admin
		["countdown"] = "Head Admin";
		["serverHint"] = "Head Admin";
		["vote"] = "Head Admin";
		["directBan"] = "Owner";
		-- Administrador
		["sword"] = "Owner";
		["timeBan"] = "Owner";
		["alert"] = "Owner";
		["nightVision"] = "Administrador";
		-- Moderador
		["respawn"] = "Help Creator";
		["cmds"] = "Moderador";
		["give"] = "Help Creator";
		["size"] = "Socio";
		["privateMessage"] = "Moderador";
		["chatLogs"] = "Moderador";
		["logs"] = "Moderador";
		--["ranks"] = "Moderador";
		["Owner"] = "Moderador";
		--["teleport"] = "Moderador";
		["m"] = "Lead Admin";
		["kick"] = "Owner";
		-- DJ
		["disco"] = "DJ";
		["music"] = "DJ";
		["volume"] = "DJ";
		["countdown2"] = "DJ";
		["pitch"] = "DJ";
		["buildingTools"] = "Owner";
		["ranks"] = "DJ";
		["warp"] = "Owner";
		-- Influencer
		["title"] = "Influencer";
		-- Socios
		["jail"] = "Owner";
		["gear"] = "Owner";
		["material"] = "Socio";
		["transparency"] = "Socio";
		["ice"] = "Help Creator";
		["glass"] = "Socio";
		["neon"] = "Socio";
		["spin"] = "Help Creator";
		["smoke"] = "Socio";
		["fire"] = "Socio";
		["clone"] = "Owner";
		["clear"] = "Socio";
		["clearHats"] = "Socio";
		["teleport"] = "Socio";
		["r6"] = "Socio";
		["cmdbar2"] = "Socio";
		["cmdbar"] = "Socio";
		["god"] = "Socio";
		["fat"] = "Socio";
		["thin"] = "Socio";
		["squash"] = "Socio";
		["width"] = "Socio";
		["headSize"] = "Socio";
		["h"] = "Socio";
		-- COMMANDS
		["hideName"] = "COMMANDS";
		["sparkles"] = "COMMANDS";
		["shine"] = "COMMANDS";
		["ghost"] = "COMMANDS";
		["dwarf"] = "COMMANDS";
		["giantDwarf"] = "COMMANDS";
		["hat"] = "COMMANDS";
		["char"] = "COMMANDS";
		["fly"] = "COMMANDS";
		["speed"] = "COMMANDS";
		["fly2"] = "COMMANDS";
		["noclip2"] = "COMMANDS";
		["noclip"] = "COMMANDS";
		["to"] = "COMMANDS";
		["fiesta"] = "Owner";
		["pulse"] = "Owner";
		["quake"] = "Owner";
		["invisible"] = "Help Creator";
		-- FREE
		["hideGuis"] = "NonAdmin";
		["showGuis"] = "NonAdmin";


		-- Influencer
		-- ["COMANDO"]
		-- "ROL"
		-- ["COMANDO"] = "ROL";


	};	


};
