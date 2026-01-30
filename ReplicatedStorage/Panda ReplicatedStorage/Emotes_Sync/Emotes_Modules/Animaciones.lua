local Animaciones = {}

Animaciones.Ids = {
	{ID = 138316142522795, Nombre = 'Menea I'},
	{ID = 93650537970037, Nombre = 'Menea II'},
	{ID = 124982597491660, Nombre = 'California Girls'},
	{ID = 133551169796944, Nombre = 'Salsa Sensual'},
	{ID = 80443100846814, Nombre = 'Sexy Dance'},
	{ID = 140264972855688, Nombre = 'Rock n Roll'},
	{ID = 99786006678146, Nombre = 'Soul II'},
	{ID = 82928714109101, Nombre = 'Soul III'}, 
	{ID = 122584436407402, Nombre = 'Bombastic'},

	{ID = 106725869492202, Nombre = 'Samba I'},
	{ID = 89111424480965, Nombre = 'Samba II'},
	{ID = 135274414278380, Nombre = 'Samba III'},
	{ID = 88477349752052, Nombre = 'Samba IV'},
	{ID = 16270690701, Nombre = 'Samba V'},

	{ID = 128838190174445, Nombre = 'Arm Sway'},
	{ID = 98813116714164, Nombre = 'Belly I'},
	{ID = 101421039901803, Nombre = 'Belly II'},
	{ID = 111030032759956, Nombre = 'Belly III'},
	{ID = 110328541025392, Nombre = 'Belly IV'},
	{ID = 125053765985375, Nombre = 'Rumba I'},
	{ID = 134059337517351, Nombre = 'Rumba II'},
	{ID = 139695580295254, Nombre = 'Dreaming'},
	{ID = 87256667587302, Nombre = 'Salsa I'},
	{ID = 79730790380560, Nombre = 'Salsa II'},
	{ID = 105174102127690, Nombre = 'Salsa III'},
	{ID = 81075111598672, Nombre = 'Salsa IV'},
	{ID = 95627144044934, Nombre = 'Salsa V'},
	{ID = 93582366449826, Nombre = 'HipHop VII'},
	{ID = 104904326781868, Nombre = 'Fresh'},
	{ID = 111951087688291, Nombre = 'Gandy'},
	{ID = 87366880880445, Nombre = 'Fancy'},
	{ID = 105978455508635, Nombre = 'Dynamite'},
	{ID = 87911767600339, Nombre = 'DnB Step'},
	{ID = 121070617692386, Nombre = 'Daydream'},
	{ID = 133510433394834, Nombre = 'CrissCross'},
	{ID = 90051254810946, Nombre = 'Chill'},
	{ID = 72420765697390, Nombre = 'CanCan'},
	{ID = 76314116414269, Nombre = 'Billie'},
	{ID = 84492113139839, Nombre = 'Conceited'},
	{ID = 107878753518729, Nombre = 'Cannonbal'},
	{ID = 132611906841113, Nombre = 'Pushing Buttons'},
	{ID = 72433216272255, Nombre = 'Pop'},
	{ID = 99079687606639, Nombre = 'Baby Bunny'},
	{ID = 116800653493137, Nombre = 'Bboy'},
	{ID = 111525609019853, Nombre = 'Afox'},
	{ID = 98627473756565, Nombre = 'Freak'},
	{ID = 139794680145941, Nombre = 'Freak II'},      
	{ID = 78603995113426, Nombre = 'Line Dancing'},
	{ID = 115583440429313, Nombre = 'The Mind'},
	{ID = 116157825323323, Nombre = 'Cheerleader'},
	{ID = 115945187669605, Nombre = 'Zoom'},
	{ID = 119774995987419, Nombre = 'BoomBoom'},
	{ID = 111604765506563, Nombre = 'Chasin'},
	{ID = 108571779943901, Nombre = 'Collide'},
	{ID = 109592914853200, Nombre = 'Damn Time'},
	{ID = 123539369286057, Nombre = 'Feel Spectacular'},
	{ID = 133320214944635, Nombre = 'Fiesta'},
	{ID = 89288947751010, Nombre = 'Galleta'},
	{ID = 121472315872091, Nombre = 'Gee'},
	{ID = 125802053398277, Nombre = 'Glass Bead'},
	{ID = 132334408930899, Nombre = 'Going Loco'},
	{ID = 116788416886018, Nombre = 'Green Grass'},
	{ID = 110237007424845, Nombre = 'Smooth Ice'},
	{ID = 129776939385438, Nombre = 'Seeing Tinny'},
	{ID = 115874865062092, Nombre = 'Still Yapping'},
	{ID = 89675190698975, Nombre = '1000 Nights'},
	{ID = 101009932520056, Nombre = 'Anaconda'},
	{ID = 120043392669833, Nombre = 'World Ruler'},
	{ID = 102925318918158, Nombre = 'Lively'},
}

Animaciones.Recomendado = {
	{ID = 109863843469159, Nombre = 'Zapateo I'},
	{ID = 79209803496762, Nombre = 'Zapateo II'},
	{ID = 129013038044362, Nombre = 'Zapateo III'},

	{ID = 78487446167065, Nombre = 'Sapito Ghost'},
	{ID = 114047726239264, Nombre = 'Andy V Ghost'},

	{ID = 117717879866825, Nombre = 'Nene Malo I Ghost'},
	{ID = 104764044091264, Nombre = 'Nene Malo II Ghost'},

	{ID = 95598009785895, Nombre = 'Wachiturros I Ghost'},
	{ID = 127092810179206, Nombre = 'Wachiturros II Ghost'},

	{ID = 129615131982878, Nombre = 'Maquina I Jose Jeri'},
	{ID = 98406276692762, Nombre = 'Maquina II Jose Jeri'},
	{ID = 123606278208422, Nombre = 'Maquina III Jose Jeri'},

	{ID = 101758039233408, Nombre = 'Diva I'},
	{ID = 79464831560180, Nombre = 'Diva II'},
	{ID = 136073073685621, Nombre = 'Diva III'},
	{ID = 111664314706389, Nombre = 'Diva V'},
	{ID = 118896295981144, Nombre = 'Diva VI'},

	{ID = 108873777157620, Nombre = 'Lady I'},
	{ID = 111799322743206, Nombre = 'Lady II'},
	{ID = 93358488237387, Nombre = 'Lady III'},
	{ID = 92689671662713, Nombre = 'Lady IV'},
	{ID = 114912639422575, Nombre = 'Lady V'},

	{ID = 129991743366120, Nombre = 'Locura I'},
	{ID = 102571052202995, Nombre = 'Locura II'},
	{ID = 107098873662122, Nombre = 'Locura III'},
	{ID = 113814533436918, Nombre = 'Locura IV'},
	{ID = 95690194214852, Nombre = 'Locura V'},


	{ID = 122599479076921, Nombre = 'Electro  I'},
	{ID = 138785676658772, Nombre = 'Electro II'},
	{ID = 100618969608942, Nombre = 'Electro III'},
	{ID = 118468821959324, Nombre = 'Electro IV'},
	{ID = 117991470645633, Nombre = 'Electro V'},

	{ID = 77109707167884, Nombre = 'Kawaii I'},
	{ID = 73932117454031, Nombre = 'Kawaii II'},

	{ID = 86295087151051, Nombre = 'Menea IV'},
	{ID = 140418182009287, Nombre = 'Menea V'},
	{ID = 122719596509695, Nombre = 'Menea VI'},
	{ID = 139110277540140, Nombre = 'Menea VII'},
	{ID = 112176404394603, Nombre = 'Menea VIII'},


	{ID = 75043657148780, Nombre = 'Sad I'},
	{ID = 136392114296143, Nombre = 'Sad II'},
	{ID = 129267654758612, Nombre = 'Sad III'},
	{ID = 94144854386419, Nombre = 'Sad IV'},

	{ID = 117803396402998, Nombre = 'Fly Superhero'},

	{ID = 73352560404489, Nombre = 'Sit I'},
	{ID = 131244541901818, Nombre = 'Sit II'},
	{ID = 74942907606000, Nombre = 'Sit III'},
	{ID = 119788722787041, Nombre = 'Sit IV'},

	{ID = 85062238386196, Nombre = 'Twist I'},
	{ID = 75369987383599, Nombre = 'Twist II'},
	{ID = 90166098423888, Nombre = 'Twist III'},

	{ID = 106791897561327, Nombre = 'Bella I'},
	{ID = 85047784800271, Nombre = 'Bella II'},
	{ID = 72932062656739, Nombre = 'Bella III'},
	{ID = 79689692681563, Nombre = 'Bella IV'},



	{ID = 133394554631338, Nombre = 'Billy Bounce'},

	{ID = 83650099589962, Nombre = 'Koto Nai'},

	{ID = 139957672285986, Nombre = 'MJ Moon Walk'},
	{ID = 130179674791973, Nombre = 'MJ Billie Jean'},

	{ID = 87026730190141, Nombre = 'Macarena'},

	{ID = 72248021897603, Nombre = 'Bob Esponja'},

	{ID = 108759656834820, Nombre = 'Saka Saka'},

	{ID = 84658481455741, Nombre = 'Garrys Dance'},
}

Animaciones.Vip = {


	{ID = 112455083563294, Nombre = 'Perreo I'},
	{ID = 89794141549021, Nombre = 'Perreo II'},
	{ID = 84263289883225, Nombre = 'Perreo III'},
	{ID = 72453237141167, Nombre = 'Perreo IV'},

	{ID = 81377469599060, Nombre = 'LATIN I'},
	{ID = 121540036206716, Nombre = 'LATIN II'},
	{ID = 74407321445762, Nombre = 'LATIN III'},
	{ID = 124209914932987, Nombre = 'LATIN IV'},

	{ID = 117743822724223, Nombre = 'Rebote I'},
	{ID = 107109795056101, Nombre = 'Rebote II'},
	{ID = 72067682558080, Nombre = 'Rebote III'},
	{ID = 75256518776176, Nombre = 'Rebote IV'},

	{ID = 104685509336391, Nombre = 'Jump I'},
	{ID = 131751661872100, Nombre = 'Jump II'},
	{ID = 75835894773315, Nombre = 'Jump III'},
	{ID = 125178785524122, Nombre = 'Jump IV'},

	{ID = 80962650363654, Nombre = 'SMOOTH I'},
	{ID = 113057522886646, Nombre = 'SMOOTH II'},
	{ID = 106876962974091, Nombre = 'SMOOTH III'},

	{ID = 96072539308174, Nombre = 'FLOW I'},
	{ID = 103571429590163, Nombre = 'FLOW II'},
	{ID = 115310253361374, Nombre = 'FLOW III'},
	{ID = 121418461728575, Nombre = 'FLOW IV'},
	{ID = 84450135363865, Nombre = 'FLOW V'},



	{ID = 96649139759245, Nombre = 'STURDY I'},
	{ID = 115988057886214, Nombre = 'STURDY II'},
	{ID = 112773902133223, Nombre = 'STURDY III'},
	{ID = 132555082396072, Nombre = 'STURDY IV'},

	{ID = 92001399624797, Nombre = 'Perreo Sexy'},
	{ID = 131584988251817, Nombre = 'Perreo Sexy VI'},
	{ID = 110560761506205, Nombre = 'Perreo Sexy VII'},
	{ID = 77780134372141, Nombre = 'Perreo Sexy VIII'},

	{ID = 100672487163010, Nombre = 'Golpe I'},
	{ID = 97079458057304, Nombre = 'Golpe II'},
	{ID = 126490613005651, Nombre = 'Golpe III'},
	{ID = 102779295838500, Nombre = 'Golpe IV'},
	{ID = 126780665379004, Nombre = 'Golpe V'},

	{ID = 84112287597268, Nombre = 'Huaska I'},
	{ID = 84623954062978, Nombre = 'Huaska II'},
	{ID = 94847143626311, Nombre = 'Huaska III'},

	{ID = 71589647866255, Nombre = 'Sexy I'},
	{ID = 125855137691891, Nombre = 'Sexy II'},
	{ID = 82290588229832, Nombre = 'Sexy III'},

	{ID = 120500147347751, Nombre = 'Rock I'},
	{ID = 112116164691956, Nombre = 'Rock II'},
	{ID = 105085166718175, Nombre = 'Rock III'},
	{ID = 128545921603470, Nombre = 'Rock IV'},

	{ID = 140219184038687, Nombre = 'Funk I'},
	{ID = 138353516964579, Nombre = 'Funk II'},
	{ID = 100360981689145, Nombre = 'Funk III'},
	{ID = 103360497719320, Nombre = 'Funk IV'},

	{ID = 137588536535005, Nombre = 'IshowSpeed'},
	{ID = 134594513356628, Nombre = 'Deadpool'},
	{ID = 116409384225743, Nombre = 'Orange Justice'},

	{ID = 74498799892136, Nombre = 'MJ Thriller I'},
	{ID = 87993818624535, Nombre = 'MJ Thriller II'},
	{ID = 119059160928904, Nombre = 'MJ Thriller III'},
	{ID = 73665396963024, Nombre = 'MJ Thriller IV'},

	{ID = 129014371180875, Nombre = 'Merlina'},
	{ID = 71043409187026, Nombre = 'Metro Man'},

	{ID = 82445927449072, Nombre = 'Bachata I'},
	{ID = 129492556391446, Nombre = 'Bachata II'},
	{ID = 136760422939999, Nombre = 'Bachata III'},

	{ID = 119075562351736, Nombre = 'Gangnam Style'},
	{ID = 119473524290403, Nombre = 'Russian Dance'},

	{ID = 91219524625419, Nombre = 'RADIANT I'},
	{ID = 98837556665887, Nombre = 'RADIANT II'},

	{ID = 101780256353339, Nombre = 'Ghost Siqui'},

}

return Animaciones
