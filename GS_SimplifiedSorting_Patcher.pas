{
	GS Simplified Sorting Patcher
		by GS
		
	xEdit Script which automatically tags any items for use with Simplified Sorting. 
}

unit UserScript;
uses 'lib\mxpf';

const
	blDebug     	  		= true;
	blIgnoreBethesda  		= false;
	blDefaultPluginState	= true;
	blDeleteTags            = true;
	excludeEsps       		= 'Fallout4.esm'#13'DLCCoast.esm'#13'DLCNukaWorld.esm'#13'DLCRobot.esm'#13'DLCworkshop01.esm'#13'DLCworkshop02.esm'#13'DLCworkshop03.esm';	
	sDnKeywordsSS           = 'dn_A1EYE dn_A1HAT dn_A1RNG dn_A2BPK dn_A2CLT dn_A2UAR dn_A3FAR dn_A3HZM dn_A3MSK dn_A4AHM dn_A4ARL dn_A4ARR dn_A4CHS dn_A4LLG dn_A4RLG dn_A62MU dn_A7DOG';
	sAuthor                 = 'GS_SS_Patcher';
	
	// Local Form Ids for Simplified Sorting Dynamic Naming Keywords
	dnEyewearId				= $000800;
	dnHatId				    = $000801;
	dnRingId				= $000802;
	dnBackpackId			= $000803;
	dnClothesId				= $000804;
	dnUnderarmourId			= $000805;
	dnFullArmourId			= $000806;
	dnHazmatSuitId			= $000807;
	dnMaskId				= $000808;
	dnHelmetId			    = $000809;
	dnArmourLeftArmId	    = $00080A;
	dnArmourRightArmId	    = $00080B;
	dnArmourTorsoId			= $00080C;
	dnArmourLeftLegId		= $00080D;
	dnArmourRightLegId		= $00080E;
	dnSupermutantId		    = $00080F;
	dnDogId				    = $000810;
	
	// Form IDs for various vanilla records of use. 
	kPowerArmourId          = 1;
	
var 
	tlFiles, validPlugins, tlWeaponTrapStrings, tlVanillaBlacklist, tlAlchemyMeatStrings, tlAlchemyCleanWaterKeywords, tlAlchemyAidSounds, tlAlchemyDeviceStrings, tlCraftingIngredients, tlSigsToLoad, tlAlchemyRadiationAidEffects, tlArmourBackpackStrings, tlWeaponSignalGrenadeStrings, fltrAlchemyKeywords, fltrAlchemyStrings, tlWeaponAnimMelee, fltrAlchemyStringsAllow, fltrAllowArmourRaces, fltrWeaponStrings: TStringList;
	i: integer;
	sHeader, sTag: string;
	fSimplifiedSorting: IInterface;
	//kEyewear: IInterface;
	kEyewear, kHat, kRing, kBackpack, kClothes, kUnderarmour, kFullArmour, kHazmatSuit, kMask, kHelmet, kArmourLeftArm, kArmourRightArm, kArmourTorso, kArmourLeftLeg, kArmourRightLeg, kSuperMutant, kDog: string;
	

{===================================================================================================================}
{                                                  Main Function                                                    }
{===================================================================================================================}

function Initialize: Integer;
var
	j: integer;
	rec, f, g: IInterface;
	aRecord: IInterface;
	sFiles, s: string;
begin
	DefaultOptionsMXPF;
	InitializeMXPF;
	PatchFileByAuthor(sAuthor);
	mxLoadMasterRecords := true;
	mxSkipPatchedRecords := true;
	mxLoadWinningOverrides := true;
	
	{ Creates various lists which are used by the script. }
	CreateLists;
	
	{ Filters only plugins with relevant records (defined by tlSigsToLoad). }
	AddMessage('[GS] - Checking Plugins for relevant records');
	validPlugins := TStringList.Create;
	FilterValidPlugins;
	
	{ TODO: Find best place for this? Best to do check for SS ASAP! }
	SetUpInnr;
	
	{ Show form to select which plugins to patch. }
	ShowPluginSelect;
	sFiles := tlFiles.CommaText;
	
	
	
	{ Load all records. }
	AddMessage('[GS] - Loading all relevant records');
	SetInclusions(sFiles);
	LoadAllRecords;
	
	AddMastersToPatch;
	AddMasterIfMissing(mxPatchFile, 'Simplified Sorting.esp');
	
	{ Abort Script if No Records found. }
	if (MaxRecordIndex = -1) then begin
		ShowMessage('No Relevant Records Found');
		exit;
	end;
	
	// Checks all COBJ for crafting ingredients
	{
	tlCraftingIngredients := TStringList.Create;
	tlCraftingIngredients := GetCraftingIngredients();
	
	for j := 0 to tlCraftingIngredients.Count - 1 do begin
		AddMessage(tlCraftingIngredients[j]);
	end;
	}	
	
	{ Process and Patch the records. }
	ProcessRecords;
	
	{ Finish scripts and tidy records }
	AddMessage('[GS] - Script is finishing, Patching was successful');
	PrintMXPFReport;
	FinalizeMXPF;
	AddMessage('[GS] - Script has finished, Please remember to save patch');
end;

{===================================================================================================================}
{                                              Pre-Process Functions                                                }
{===================================================================================================================}

{ Checks each plugin to see if it has any valid records. Validity defined by tlSigsToLoad. }
procedure FilterValidPlugins();
var
	f, g: IInterface;
	j, n: integer;
begin
	for j := 0  to FileCount - 2 do begin
		f := FileByLoadOrder(j);
		if (Pos(GetFileName(f), excludeEsps) > 0) and blIgnoreBethesda then begin
			continue;
		end else if (GetAuthor(f) = sAuthor) then begin
			continue;
		end;
		for n := 0 to tlSigsToLoad.Count - 1 do begin
			g := GroupBySignature(f, tlSigsToLoad[n]);
			if (ElementCount(g) > 0) then begin
				validPlugins.Add(GetFileName(f));
				break;
			end;		
		end;
	end;	
end;

{ Sets up variables ready for INNR patching } 
procedure SetUpInnr(); 
begin
	{ TODO: This should probably be at start of Init function? }
	fSimplifiedSorting := FileByName('Simplified Sorting.esp');
	if not (Assigned(fSimplifiedSorting)) then
		raise Exception.Create('Simplified Sorting.esp not found! It is required for keywords.');
	
	{ TODO: Can i tidy this? Dictionary? }
	//kEyewear := IntToHex(MasterCount(fSimplifiedSorting) * $01000000 + dnEyewearId, 8);
	kEyewear := GetHexFormID(dnEyewearId);
	kHat := GetHexFormID(dnHatId);
	kEyewear := GetHexFormID(dnEyewearId);
	kEyewear := GetHexFormID(dnEyewearId);
	kEyewear := GetHexFormID(dnEyewearId);
	kEyewear := GetHexFormID(dnEyewearId);
	kEyewear := GetHexFormID(dnEyewearId);
	kEyewear := GetHexFormID(dnEyewearId);
	kEyewear := GetHexFormID(dnEyewearId);
	
end;

{ Creates various lists used by the script }
{ TODO: Might be better to just use comma-separated strings with Pos()? }
procedure CreateLists();
begin
	tlSigsToLoad := TStringList.Create;
		//tlSigsToLoad.Add('WEAP');
		tlSigsToLoad.Add('ARMO');
		//tlSigsToLoad.Add('AMMO');
		//tlSigsToLoad.Add('ALCH');
		//tlSigsToLoad.Add('BOOK');
		//tlSigsToLoad.Add('NOTE');
		//tlSigsToLoad.Add('KEYM');
		//tlSigsToLoad.Add('MISC');
		
	{ Contains which Races should be allowed for armour }
	fltrAllowArmourRaces := TStringList.Create;
		fltrAllowArmourRaces.add('DogmeatRace');
		fltrAllowArmourRaces.add('SuperMutantRace');
		//fltrAllowArmourRaces.add('HumanChildRace "Human"');
		fltrAllowArmourRaces.add('HumanRace "Human"');
		
	{ Contains Substrs to filter irrelevant Alchemy EDIDs }	
	fltrAlchemyStrings := TStringList.Create;
		fltrAlchemyStrings.Add('HC_');
		fltrAlchemyStrings.Add('DLC04GZVaultTec_Experiment');
	
	{ Used in conjuction with above, this will list exceptions to above filter } 
	fltrAlchemyStringsAllow := TStringList.Create;
		fltrAlchemyStringsAllow.Add('HC_Herbal');
		fltrAlchemyStringsAllow.Add('HC_Antibiotics');
		
	{ Contains Substrs to Identify Utility Grenades }
	tlWeaponSignalGrenadeStrings := TStringList.Create;
		tlWeaponSignalGrenadeStrings.Add('Signal');
		tlWeaponSignalGrenadeStrings.Add('Beacon');
		tlWeaponSignalGrenadeStrings.Add('Smoke');
		tlWeaponSignalGrenadeStrings.Add('Relay');
	
	{ Contains Substrs to Identify Traps }
	tlWeaponTrapStrings := TStringList.Create;
		tlWeaponTrapStrings.Add(' Trap');
		tlWeaponTrapStrings.Add('Trap ');
		tlWeaponTrapStrings.Add('Caltrop');
	
	{ Contains Substrs to Identify Backpacks }
	tlArmourBackpackStrings := TStringList.Create;
		tlArmourBackpackStrings.Add('Bandolier');
		tlArmourBackpackStrings.Add('Backpack');
		tlArmourBackpackStrings.Add(' Bag');
		
	{ Contains Effect IDs to identify Radiation Aid }
	tlAlchemyRadiationAidEffects := TStringList.Create;
		tlAlchemyRadiationAidEffects.Add('FortifyResistRadsRadX');
		tlAlchemyRadiationAidEffects.Add('RestoreRadsChem');
		
	{ Contains Substrs used to identify Devices }
	tlAlchemyDeviceStrings := TStringList.Create;
		tlAlchemyDeviceStrings.Add('Settings');
		tlAlchemyDeviceStrings.Add('Uninstall');
		tlAlchemyDeviceStrings.Add(' List');
		tlAlchemyDeviceStrings.Add('Repair');
		tlAlchemyDeviceStrings.Add('Set Up');
		tlAlchemyDeviceStrings.Add('StealthBoy');

	{ Contains Substrs used to identify Meat }
	tlAlchemyMeatStrings := TStringList.Create;
		tlAlchemyMeatStrings.Add('Meat');
		tlAlchemyMeatStrings.Add(' Leg');
		tlAlchemyMeatStrings.Add('Squirrel Bits');
		tlAlchemyMeatStrings.Add(' Gland');
	
	{ Will check records for Substrs listed here and Remove them, can be partial. }
	tlVanillaBlacklist := TStringList.Create;
		tlVanillaBlacklist.Add('DLC02WorkshopDetectLifeTest');
		tlVanillaBlacklist.Add('DogWhistle');
		tlVanillaBlacklist.Add('HC_Antibiotics_SILENT_SCRIPT_ONLY');
		tlVanillaBlacklist.Add('AmmoMirelurkSpawn');
		tlVanillaBlacklist.Add('Ammo10mmCOPY0000');
		tlVanillaBlacklist.Add('DLC05WorkshopFireworkWeapon');
		tlVanillaBlacklist.Add('MS02Nuke');
		tlVanillaBlacklist.Add('DLC05PaintballGun');
		tlVanillaBlacklist.Add('FatManBomb');
		tlVanillaBlacklist.Add('WorkshopArtilleryWeapon');
		tlVanillaBlacklist.Add('NonPlayable');
		tlVanillaBlacklist.Add('DLC03_Clothes_Waders');
		
end;	


{ Loads all records with a signature defined in tlSigsToLoad. }
procedure LoadAllRecords();
var
	j: integer;
begin
	for j := 0 to tlSigsToLoad.Count - 1 do begin
		LoadRecords(tlSigsToLoad[j]);
	end;
end;

{ Removes all records from Patch file }
procedure ClearPatch();
var 
	j: integer;
begin
	for j := 0 to tlSigsToLoad.Count - 1 do begin
		RemoveNode(GroupBySignature(mxPatchFile, tlSigsToLoad[j]));
	end;
end;

{ Checks every COBJ for its components and creates a non-duplicate list }
{ TODO: More efficient to use ReferencedByIndex? Does it require loading references when opening FO4Edit? Can 'BuildRef' be used if so? }
function GetCraftingIngredients(): TStringList;
var
	j, k, l: integer;
	f, gCobj, eComponentGroup, eRecord, eComponentRow, eComponent: IInterface;
begin
	Result := TStringList.Create;
	Result.Duplicates := dupIgnore;
	Result.Sorted := true;
	for j := 0 to FileCount - 2 do begin
		f := FileByIndex(j);
		gCobj := GroupBySignature(f, 'COBJ');
		for k := 0 to ElementCount(gCobj) do begin
			eRecord := WinningOverride(ElementByIndex(gCobj, k));
			eComponentGroup := ElementBySignature(eRecord, 'FVPA');
			for l := 0 to ElementCount(eComponentGroup) - 1 do begin
				eComponentRow := ElementByIndex(eComponentGroup, l);
				//eComponent := WinningOverride(LinksTo(ElementByName(eComponentRow, 'Component')));
				eComponent := LinksTo(ElementByName(eComponentRow, 'Component'));
				Result.Add(geev(eComponent, 'EDID'));
			end;
		end;
	end;	
end;

{===================================================================================================================}
{                                             Main Process Function                                                 }
{===================================================================================================================}

{ This handles all processing and patching } 
procedure ProcessRecords();
var
	j: integer;
	rec: IInterface;
	sName: string;
begin
	{ This section removes records which should not be patched }
	AddMessage('[GS] - The script will now filter and remove irrelevant or bad records');
	for i := MaxRecordIndex downto 0 do begin
		rec := GetRecord(i);
		if not HasName(rec) then begin
			//AddMessage(Format('[GS] - Filtered %s for having null name.', [Name(rec)]));
			RemoveRecord(i);
			continue;
		end;
		sHeader := GetElementEditValues(rec, 'Record Header\Signature');
		if (sHeader = 'WEAP') then begin
			FilterWeapon(rec);
		end else if (sHeader = 'ARMO') then begin
			FilterArmour(rec);
		end else if (sHeader = 'AMMO') then begin
			FilterAmmo(rec);
		end else if (sHeader = 'ALCH') then begin
			FilterAlchemy(rec);
		end;
	end;
	
	{ Copy the records to Patch File }
	AddMessage('[GS] - Copying relevant records to patch file');
	ClearPatch;
	CopyRecordsToPatch;
	
	{ This section edits the records by adding tags and various other tweaks }
	AddMessage('[GS] - Patching records, may take a little while depending on selected load order size');
	for i := MaxRecordIndex downto 0 do begin
		sTag := '';
		rec := GetPatchRecord(i);
		sName := geev(rec, 'FULL - Name');
		seev(rec, 'FULL - Name', RemoveTags(sName));
		sHeader := GetElementEditValues(rec, 'Record Header\Signature');
		if (sHeader = 'WEAP') then begin
			PatchWeapon(rec);
		end else if (sHeader = 'ARMO') then begin
			PatchArmour(rec);
		end else if (sHeader = 'AMMO') then begin
			PatchAmmo(rec);
		end else if (sHeader = 'ALCH') then begin
			PatchAlchemy(rec);
		end;
		AddTag(rec, 'FULL - Name');
	end;	
end;

{===================================================================================================================}
{                                                Filter Functions                                                   }
{===================================================================================================================}

procedure FilterWeapon(e: IInterface);
begin
	if (GetElementEditValues(e, 'DNAM - Data\Flags\Not Playable') = '1') then begin
		RemoveRecord(i);
		exit;
	end;
	if (GetElementEditValues(e, 'DNAM - Data\Flags\Not Used In Normal Combat') = '1') then begin
		RemoveRecord(i);
		exit;
	end;
	if not (HasModel(e)) then begin
		RemoveRecord(i);
		exit;
	end;	
end;

procedure FilterArmour(e: IInterface);
var
	sRace: string;
begin
	sRace := GetElementEditValueTrimmed(e, 'RNAM - Race');
	{ Does the record have Human Race and Non Playable flag? }
	if (sRace = 'HumanRace "Human"') and (IsNonPlayable(e)) then begin
		RemoveRecord(i);
		exit;
	{ Does the record have a race defined in fltrAllowArmourRaces? }
	end else if (fltrAllowArmourRaces.IndexOf(sRace) = -1) then begin
		RemoveRecord(i);
		exit;
	end;
end;

procedure FilterAmmo(e: IInterface);
begin
	{ Does the record have Non-Playable flag? }
	if (IsNonPlayable(e)) then begin
		RemoveRecord(i);
		exit;
	end;
end;

procedure FilterAlchemy(e: IInterface);
begin
	{ NOTE: Might be a problem for script chems e.g. uninstallers? }
	if not (HasModel(e)) then begin
		RemoveRecord(i);
		exit;
	end;
	if (ElementContainsStrFromList(e, 'EDID - Editor ID', fltrAlchemyStrings)) and not (ElementContainsStrFromList(e, 'EDID - Editor ID', fltrAlchemyStringsAllow)) then begin
		RemoveRecord(i);
		exit;
	end;
end;


{===================================================================================================================}
{                                                 Patch Functions                                                   }
{===================================================================================================================}

procedure PatchWeapon(rec: IInterface);
var
	sAnimType: string;
begin
	sAnimType := GetElementEditValues(rec, 'DNAM - Data\Animation Type');
	{ GRENADES }
	if (sAnimType = 'Grenade') then begin
		if (ElementContainsStrFromList(rec, 'FULL - Name', tlWeaponSignalGrenadeStrings)) then begin
			sTag := '[UTIL GRENADE]';
		end else begin
			sTag := '[GRENADE]';
		end;
	{ MINES }
	end else if (sAnimType = 'Mine') then begin
		if (ElementContainsStrFromList(rec, 'FULL - Name', tlWeaponTrapStrings)) then begin
			sTag := '[TRAP]';
		end else begin
			sTag := '[MINE]';
		end;
	end;
	{ Simplified Sorting uses INNR for most weapon tags. }
	{ TODO: INNR Patching }
end;

procedure PatchArmour(rec: IInterface);
var
	sRace: string;
	j: integer;
	eBodyFlags: IInterface;
begin

	{ NON HUMAN ARMOUR } 
	sRace := GetElementEditValueTrimmed(rec, 'RNAM - Race');
	if (sRace = 'SuperMutantRace') then begin
		sTag := '[SUPERMUTANT]';
		exit;
	end else if (sRace = 'DogmeatRace') or (HasKeyword(rec, 'ClothingDogmeat')) then begin
		sTag := '[DOG]';
		exit;
	end;
	
	eBodyFlags := ElementByPath(rec, 'BOD2 - Biped Body Template\First Person Flags');
	if (ElementCount(eBodyFlags) = 1) then begin
		{ SINGLE FLAG ARMOR PIECES }
		if (HasBipedFlag(rec, '42 - [A] L Arm')) then begin
			if HasKeyword(rec, 'ArmorTypePower') then
				sTag := '[POWER ARMOR L ARM]'
			else
				sTag := '[ARMOR L ARM]';
		end else if (HasBipedFlag(rec, '43 - [A] R Arm')) then begin
			if HasKeyword(rec, 'ArmorTypePower') then
				sTag := '[POWER ARMOR R ARM]'
			else
				sTag := '[ARMOR R ARM]';
		end else if (HasBipedFlag(rec, '44 - [A] L Leg')) then begin
			if HasKeyword(rec, 'ArmorTypePower') then
				sTag := '[POWER ARMOR L LEG]'
			else
				sTag := '[ARMOR L LEG]';
		end else if (HasBipedFlag(rec, '45 - [A] R Leg')) then begin
			if HasKeyword(rec, 'ArmorTypePower') then
				sTag := '[POWER ARMOR R LEG]'
			else
				sTag := '[ARMOR R LEG]';
		end else if (HasBipedFlag(rec, '41 - [A] Torso')) then begin
			if HasKeyword(rec, 'ArmorTypePower') then begin
				sTag := '[POWER ARMOR TORSO]';
			end else if (ElementContainsStrFromList(rec, 'FULL - Name', tlArmourBackpackStrings)) then begin
				sTag := '[BACKPACK]';
			end else begin
				sTag := '[ARMOR TORSO]';
			end;
		{ SINGLE FLAG CLOTHING PIECES }
		end else if (HasBipedFlag(rec, '47 - Eyes')) then begin
			if (ElementContainsStr(rec, 'FULL - Name', 'Mask')) then
				sTag := '[MASK]'
			else
				sTag := '[EYEWEAR]';
		end else if (HasBipedFlag(rec, '51 - Ring')) then begin
			sTag := '[RING]';
		end else if (HasBipedFlag(rec, '30 - Hair Top')) or (HasBipedFlag(rec, '46 - Headband')) then begin
			sTag := '[HAT]';
		end else if (HasBipedFlag(rec, '54 - Unnamed')) then begin
			sTag := '[BACKPACK]';
		end else if (HasBipedFlag(rec, '50 - Neck')) then begin
			sTag := '[NECK]';
		end;
		{ MULTIPLE FLAG PIECES }
	end else begin
		if (HasKeyword(rec, 'ArmorTypePower')) and (HasBipedFlag(rec, '52 - Scalp')) then begin
			sTag := '[POWER ARMOR HELMET]';
		end else if (HasBipedFlag(rec, '30 - Hair Top')) and not (HasBipedFlag(rec, '33 - BODY')) then begin
			if (GetElementEditValues(rec, 'FNAM - FNAM\Armor Rating') > 0) then begin
				sTag := '[HELMET]';
			end else begin
 				sTag := '[HAT]';
			end;
		end else if (HasBipedFlag(rec, '33 - BODY')) then begin
			if (IsAllBody(rec, 'U')) and not (IsAnyBody(rec, 'A')) then
				sTag := '[UNDERARMOR]'
			else if (GetElementEditValues(rec, 'FNAM - FNAM\Armor Rating') > 0) then
				sTag := '[ARMOR]'
			else
				sTag := '[CLOTHING]';
		end else if (IsAllBody(rec, 'A')) then begin
			sTag := '[ARMOR TORSO]';
		end else if (IsMask(rec)) then begin
			sTag := '[MASK]';
		end;
	end;
	PatchArmourInnr(rec, kEyewear);
end;

procedure PatchArmourInnr(rec: IInterface; keyword: string);
var
	sInrd: string;
	fArmorKeywords, kwdaEyewear: IInterface;
	
begin
	sInrd := geev(rec, 'INRD');
	AddInnrKey(rec, keyword);
end;

procedure AddInnrKey(rec: IInterface; keyword: string);
var
	eKeywords: IInterface;
begin
	{ TODO: Might want to check for discrepencies between existing tags and my filtered suggestions }
	if not (HasKywd(rec, sDnKeywordsSS)) then begin
		eKeywords := ElementByPath(rec, 'KWDA - Keywords');
		SetEditValue(ElementAssign(eKeywords, HighInteger, nil, false), keyword);
	end;
end;


procedure PatchAmmo(rec: IInterface);
begin

	if (HasKeyword(rec, 'isPowerArmorBattery')) then begin
		sTag := '[FUSIONCORE]';
	end else begin
		sTag := '[AMMO]';
	end;
	{ TODO: Ballistic has 3D Count keyword? - could use to split ballistic/energy, etc. }
end;


procedure PatchAlchemy(rec: IInterface);
begin
	
	{ FOODS }
	if (HasKeyword(rec, 'ObjectTypeFood')) then begin 
		if (ElementContainsStr(rec, 'FULL - Name', 'preserved')) then begin
			sTag := '[PRE WAR FOOD]';
		end else if (ElementContainsStrFromList(rec, 'FULL', tlAlchemyMeatStrings)) then begin
			sTag := '[MEAT]';
		end else if (HasKeyword(rec, 'HC_IgnoreAsFood')) then begin
			sTag := '[WILD PLANTS]';
		end else if (HasKeyword(rec, 'FruitOrVegetable')) then begin
			if (ElementContainsStr(rec, 'FULL', 'Wild ')) then begin
				sTag := '[WILD PLANTS]';
			end else begin
				sTag := '[CROPS]';
			end;
		end else if (Length(geev(rec, 'DESC')) >= 1) then begin
			sTag := '[BUFF FOOD]';
		end else if (HasEffect(rec, 'DamageRadiationChem')) then begin
			sTag := '[RAD FOOD]';
		end else if (HasEffect(rec, 'RestoreHealthFood')) then begin
 			sTag := '[SURVIVAL FOOD]';
		end;
		
	{ DRINKS }
	end else if (HasKeyword(rec, 'ObjectTypeNukaCola')) then begin
		sTag := '[NUKA COLA]';
	end else if (HasKeyword(rec, 'ObjectTypeAlcohol')) then begin
		sTag := '[ALCOHOL]';
	end else if (GetElementEditValueTrimmed(rec, 'ENIT\Sound - Consume') = 'DLC03NPCHumanDrinkSludgePack') then begin
		sTag := '[SLUDGE COCKTAIL]';
	end else if (HasKeyword(rec, 'ObjectTypeWater')) then begin
		if not (HasEffect(rec, 'DamageRadiationWater')) then begin
			sTag := '[CLEAN WATER]';
		end else begin
			sTag := '[DRINK]';
		end;
	end else if (GetElementEditValueTrimmed(rec, 'ENIT\Sound - Consume') = 'NPCHumanDrinkGeneric') then begin
		sTag := '[DRINK]';
		
	{ AID AND CHEMS }
	end else if (GetElementEditValues(rec, 'ENIT\Addiction Chance') > 0) then begin
		sTag := '[CHEM]';
	end else if (HasKeyword(rec, 'ObjectTypeStimpak')) then begin
		sTag := '[STIMPACK]';
	end else if (HasEffectFromList(rec, tlAlchemyRadiationAidEffects)) then begin
		sTag := '[RADIATION AID]';
	end else if GetElementEditValueTrimmed(rec, 'PTRN - Preview Transform') = 'MiscIV' then begin
		sTag := '[BLOODPACK]';
	end else if (GetElementEditValueTrimmed(rec, 'ENIT\Sound - Consume') = 'NPCHumanEatSoupSlurp') then begin
		sTag := '[HERBAL SOUP]';
	end else if (GetElementEditValues(rec, 'ENIT - Effect Data\Flags\Medicine') = 1) then begin
		sTag := '[AID]';
	end else if (GetElementEditValueTrimmed(rec, 'ENIT\Sound - Consume') = 'NPCHumanChemsAddictol') then begin
		sTag := '[AID]';
	end;
	
	{ These will overwrite the above tags where relevant. }
	{ QUEST ITEMS, DEVICES, SYRINGER AMMO, ETC }
	if (HasKeyword(rec, 'FeaturedItem')) then begin
		sTag := '[QUEST ITEM]';
	end else if (geev(rec, 'Model\MODL - Model FileName') = 'Props\StealthBoy01.nif') then begin
		sTag := '[DEVICE]';
	end else if (ElementContainsStrFromList(rec, 'FULL - Name', tlAlchemyDeviceStrings)) then begin
		sTag := '[DEVICE]';
	end else if (HasKeyword(rec, 'ObjectTypeSyringerAmmo')) then begin
		sTag := '[SYRINGER AMMO]';
	//end else if (tlCraftingIngredients.IndexOf(geev(rec, 'EDID')) > 0) then begin
	//	sTag := '[CRAFTING]';
	end;
	
	{ Individual Overrides - Vanilla Patching only }
	{
	MoldyFood01 = RADFOOD
	BrainGround04 ?? 
	}
end;


{===================================================================================================================}
{                                                Helper Functions                                                   }
{===================================================================================================================}


{ Gets load order hex form id as string, input is local form ID }
function GetHexFormID(id: variant): string;
begin
	Result := IntToHex(MasterCount(fSimplifiedSorting) * $01000000 + id, 8);
end;

{ See if clothing item covers multiple face parts }
{ TODO: Do mods use AnimHelmetCoversMouth ? could use as 2nd check }
function IsMask(rec: IInterface): boolean;
var
	n: integer;
begin
	n := 0;
	if (HasBipedFlag(rec, '46 - Headband')) then
		Inc(n);
	if (HasBipedFlag(rec, '47 - Eyes')) then
		Inc(n);
	if (HasBipedFlag(rec, '48 - Beard')) then
		Inc(n);
	if (HasBipedFlag(rec, '49 - Mouth')) then
		Inc(n);
	if (n > 1) then 
		Result := true
	else 
		Result := false;
	
end;

{ Checks if a piece of clothing covers all body parts, can check for 'A' (Armour) or 'U' (Underarmour) }
function IsAllBody(rec: IInterface; s: string): boolean;
var
	n: integer;
begin
	if (s = 'A') then
		n := 41
	else if (s = 'U') then
		n := 36
	else
		exit;

	if (HasBipedFlag(rec, Format( '%s - [%s] Torso', [IntToStr(n), s]))) 
	and (HasBipedFlag(rec, Format( '%s - [%s] L Arm', [IntToStr(n+1),s])))
	and (HasBipedFlag(rec, Format( '%s - [%s] R Arm', [IntToStr(n+2),s])))
	and (HasBipedFlag(rec, Format( '%s - [%s] L Leg', [IntToStr(n+3),s])))
	and (HasBipedFlag(rec, Format( '%s - [%s] R Leg', [IntToStr(n+4),s]))) then
		Result := true;		
end;

{ Checks if a piece of clothing covers any body part, can check for 'A' (Armour) or 'U' (Underarmour) }
function IsAnyBody(rec: IInterface; s: string): boolean;
var
	n: integer;
begin
	if (s = 'A') then
		n := 41
	else if (s = 'U') then
		n := 36
	else
		exit;

	if (HasBipedFlag(rec, Format( '%s - [%s] Torso', [IntToStr(n), s]))) 
	or (HasBipedFlag(rec, Format( '%s - [%s] L Arm', [IntToStr(n+1),s])))
	or (HasBipedFlag(rec, Format( '%s - [%s] R Arm', [IntToStr(n+2),s])))
	or (HasBipedFlag(rec, Format( '%s - [%s] L Leg', [IntToStr(n+3),s])))
	or (HasBipedFlag(rec, Format( '%s - [%s] R Leg', [IntToStr(n+4),s]))) then
		Result := true;		
end;

{ Checks if a clothing piece has a specified Biped flag }
function HasBipedFlag(rec: IInterface; s: string): boolean;
begin
	Result := (GetElementEditValues(rec, 'BOD2 - Biped Body Template\First Person Flags\' + s) = '1')
end;

{ Adds a prefix tag to element from path, sTag is defined by Patch* functions. }
procedure AddTag(e: IInterface; sPath: string);
var
	sCur: string;
begin
	sCur := GetElementEditValues(e, sPath);
	if (sTag <> '') then
		SetElementEditValues(e, sPath, (sTag + ' ' + sCur));
end;

{ Removes existing tags, recursive to remove multiple. }
function RemoveTags(s: string): string;
var
	sChars, sNew: string;
	j, n, x: integer; 
begin
	sChars := '[{(|]})|';
	x := Length(sChars) Div 2;
	n := 0;
		
	for j := 1 to x do begin
		if (s[1] = sChars[j]) then begin
			n := Pos(sChars[j+x], Copy(s, 2, Length(s))) + 1;
			break;
		end;
	end;
	
	if (n = 0) then begin
		Result := s;
		exit;
	end;
	
	sNew := Trim(Copy(s, n + 1, Length(s)));
	
	if (sNew = RemoveTags(sNew)) then
		Result := sNew
	else
		Result := RemoveTags(sNew);
end;

{ Removes component tags - RemoveTags should be run beforehand. }
function RemoveCompTags(s: string): string;
var
	n: integer;
begin
	Result := s;
	n := Pos('{', Copy(s, 2, Length(s)));
	if (n >= 1) then
		Result := Trim(Copy(s, 1, n));
end;

{ Checks if a record has a Non-Playable flag. }
function IsNonPlayable(e: IInterface): boolean;
begin
	Result := (GetElementEditValues(e, 'Record Header\Record Flags\Non-Playable') = '1');
end;

{ Checks if a record has a model. }
function HasModel(e: IInterface): boolean;
begin
	Result := (Assigned(geev(e, 'Model\MODL - Model FileName')))
end;

{ Checks if a record has a name. }
function HasName(e: IInterface): boolean;
begin
	Result := (ElementExists(e, 'FULL - Name')) or not (geev(e, 'FULL - Name') = '')
end;

{ Checks if a record has a keyword from a list. }
function HasKeywordFromList(e: IInterface; keywords: TStringList): boolean;
var 
	j: integer;
begin
	Result := false;
	for j := 0 to keywords.Count - 1 do begin
		if HasKeyword(e, keywords[j]) then begin
			Result := true;
			exit;
		end;
	end;
end;

{ Checks if a record has an Effect from a list. }
function HasEffectFromList(e: IInterface; effects: TStringList): boolean;
var
	j: integer;
begin
	Result := false;
	for j := 0 to effects.Count - 1 do begin
		if HasEffect(e, effects[j]) then begin
			Result := true;
			exit;
		end;
	end;
end;

{ Checks if a record has a certain Effect. }
function HasEffect(e: IInterface; edid: String): boolean;
var
	effects, effect: IInterface;
	j: Integer;
begin
	Result := false;
	effects := ElementByName(e, 'Effects');
	for j := 0 to ElementCount(effects) - 1 do begin
		effect := WinningOverride(LinksTo(ElementBySignature(ElementByIndex(effects, j), 'EFID')));   
		if(GetElementEditValues(effect, 'EDID') = edid) then begin
			Result := true;
			exit; 
		end;
	end;
end;

{ GetElementEditValue but without the form ID. }
function GetElementEditValueTrimmed(e: IInterface; sPath: string): string;
var
	sVal: string;
begin 
	sVal := GetElementEditValues(e, sPath);
	Result := Copy(sVal, 1, (Pos('[', sVal) - 2));
end; 

{ Checks whether an element contains a SubStr. }
function ElementContainsStr(e: IInterface; sPath, sStr: string): boolean;
begin
	Result := (Pos(Lowercase(sStr), Lowercase(geev(e, sPath))) > 0);
end;

{ Checks whether an element contains a SubStr from a list. }
function ElementContainsStrFromList(e: IInterface; sPath: string; tlStrs: TStringList): boolean;
var
	j: integer;
begin
	Result := false;	
	for j := 0 to tlStrs.Count -1 do begin
		if (ElementContainsStr(e, sPath, tlStrs[j])) then begin
			Result := true;
			exit;
		end;
	end;
end;

{ Checks if a record has a keyword in a string } 
function HasKywd(e: IInterface; sKeywords: string): boolean;
var
	eKwda: IInterface;
	j: integer;
begin
	Result := false;
	eKwda := ElementByPath(e, 'KWDA');
	for j := 0 to ElementCount(eKwda) - 1 do begin
		if (Pos(geev(LinksTo(ElementByIndex(eKwda, j)), 'EDID'), sKeywords) > 0) then
			Result := true;
	end;
end;

{===================================================================================================================}
{                                                      GUI                                                          }
{===================================================================================================================}

procedure ShowPluginSelect;
const
	spacing = 24;
var
	frm: TForm;
	lastTop, contentHeight: Integer;
	cbArray: Array[0..1000] of TCheckBox;
	lbl: TLabel;
	sb: TScrollBox;
	btnOK: TButton;
	j: Integer;
	f: IInterface;
begin
	frm := TForm.Create(nil);
	try
		frm.Position := poScreenCenter;
		frm.Width := 300;
		frm.Height := 600;
		frm.BorderStyle := bsDialog;
		frm.Caption := 'Multiple file selection';

		sb := TScrollBox.Create(frm);
		sb.Parent := frm;
		sb.Align := alTop;
		sb.Height := 500;

		lbl := TLabel.Create(sb);
		lbl.Parent := sb;
		lbl.Caption := 'Select Plugins you would like to Patch';
		lbl.Left := 8;
		lbl.Top := 8;
		lbl.Width := 280;
		lbl.WordWrap := true;
		lastTop := lbl.Top + lbl.Height + 8 - spacing;
		
		{ Create a checkbox for each plugin. }
		for j := 0 to validPlugins.Count - 1 do begin
			f := FileByName(validPlugins[j]);
			cbArray[j] := TCheckBox.Create(sb);
			cbArray[j].Parent := sb;
			cbArray[j].Caption := Format(' [%s] %s', [IntToHex(j, 2), validPlugins[j]]);
			cbArray[j].Top := lastTop + spacing;
			cbArray[j].Width := 260;
			lastTop := lastTop + spacing;
			cbArray[j].Left := 12;
			cbArray[j].Checked := blDefaultPluginState;
		end;
		
		{ Resize form based on number of plugins loaded. }
		contentHeight := spacing * (j + 2) + 100;
		if frm.Height > contentHeight then
			frm.Height := contentHeight;
		
		{ Create Cancel, OK buttons - mtefunctions.pas }
		cModal(frm, frm, frm.Height - 70);
	
		{ Populate tlFiles based on status of checkboxes. }
		tlFiles := TStringList.Create;
		if frm.ShowModal = mrOk then begin
			for j := 0 to validPlugins.Count - 1 do begin
				f := FileByName(validPlugins[j]);
				if (cbArray[j].Checked) and (tlFiles.IndexOf(GetFileName(f)) = -1) then
					tlFiles.Add(GetFileName(f));
			end;
		end;
	Finally
		frm.Free;
	end;		
end;		
	
end.