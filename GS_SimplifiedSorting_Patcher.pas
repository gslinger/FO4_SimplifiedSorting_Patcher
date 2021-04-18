{
	GS Simplified Sorting Patcher
		by GS
		
	xEdit Script which automatically tags any items for use with Simplified Sorting. Can change tags for similar mods. 
}

unit UserScript;
uses 'lib\mxpf';

const
	blDebug     	  		= true;
	blIgnoreBethesda  		= false;
	blDefaultPluginState	= true;
	blDeleteTags            = true;
	excludeEsps       		= 'Fallout4.esm'#13'DLCCoast.esm'#13'DLCNukaWorld.esm'#13'DLCRobot.esm'#13'DLCworkshop01.esm'#13'DLCworkshop02.esm'#13'DLCworkshop03.esm';	
	sAuthor                 = 'GS_SS_Patcher';
		
	{ Tag Variables - Will probably add to file }
	tGrenade                = '[W9GND]';  // Has Grenade Anim Type 
	tUtilGrenade            = '[W9SIG]';  // Has Grenade Anim Type + A Substr from tlWeaponSignalGrenadeStrings
	tMine             		= '[W9MNE]';  // Has Mine Anim Type 
	tTraps                  = '[W9TRP]';  // Has Mine Anim Type + A Substr from tlWeaponTrapStrings
	tSuperMutantArmour      = '[A6SMU]';  // Has SuperMutant Race 
	tDogArmour              = '[A7DOG]';  // Has Dogmeat Race
	tAmmo                   = '[W1AMM]';  // Has Signature 'AMMO' 
	tFusionCore             = '[W1FSC]';  // Has Signature 'AMMO' + Keyword isPowerArmorBattery
	tStimpack               = '[STIMPACK]';
	tAid                    = '[AID]';
	tRadiationAid           = '[RADIATIONAID]';
	tCleanWater             = '[CLEANWATER]';
	tBloodpack              = '[BLOODPACK]';
	tDevice                 = '[DEVICES]'; // Has Model (Stealthboy01.nif) 
	tChem                   = '[CHEM]';
	tDrink                  = '[DRINK]';
	tNukaCola               = '[NUKACOLA]';
	tAlcohol                = '[ALCOHOL]';
	tSurvivalFood           = '[SURVIVAL FOOD]';
	tBuffFood               = '[BUFFFOOD]';
	tRadFood                = '[RADFOOD]';
	tMeat                   = '[MEAT]';
	tCrops                  = '[CROPS]';
	tWildPlants             = '[WILD PLANTS]';
	
var 
	tlFiles, validPlugins, tlAlchemyCleanWaterKeywords, tlAlchemyAidSounds, tlAlchemyDeviceStrings, tlCraftingIngredients, tlSigsToLoad, tlAlchemyRadiationAidEffects, tlWeaponTrapStrings, tlWeaponSignalGrenadeStrings, fltrAlchemyKeywords, fltrAlchemyStrings, tlWeaponAnimMelee, fltrAlchemyStringsAllow, fltrAllowArmourRaces, fltrWeaponStrings: TStringList;
	i: integer;
	sHeader, sTag: string;

{===================================================================================================================}
{                                                  Main Function                                                    }
{===================================================================================================================}

function Initialize: Integer;
var
	j: integer;
	rec, f, g: IInterface;
	aRecord: IInterface;
	sFiles: string;
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
	
	{ Show form to select which plugins to patch. }
	ShowPluginSelect;
	sFiles := tlFiles.CommaText;
	
	{ Load all records. }
	AddMessage('[GS] - Loading all relevant records');
	SetInclusions(sFiles);
	LoadAllRecords;
	
	{ Abort Script if No Records found. }
	if (MaxRecordIndex = -1) then begin
		ShowMessage('No Relevant Records Found');
		exit;
	end;
	
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

{ Creates various lists used by the script }
{ TODO: Might be better to just use comma-separated strings with Pos()? }
procedure CreateLists();
begin
	tlSigsToLoad := TStringList.Create;
		//tlSigsToLoad.Add('WEAP');
		//tlSigsToLoad.Add('ARMO');
		//tlSigsToLoad.Add('AMMO');
		tlSigsToLoad.Add('ALCH');
		//tlSigsToLoad.Add('BOOK');
		//tlSigsToLoad.Add('NOTE');
		//tlSigsToLoad.Add('KEYM');
		//tlSigsToLoad.Add('MISC');
		
	fltrAlchemyKeywords := TStringList.Create;
		fltrAlchemyKeywords.Add('HC_IconColor_Red');
		fltrAlchemyKeywords.Add('HC_Eff3ype_Sleep');
	
	fltrAllowArmourRaces := TStringList.Create;
		fltrAllowArmourRaces.add('DogmeatRace');
		fltrAllowArmourRaces.add('SuperMutantRace');
		//fltrAllowArmourRaces.add('HumanChildRace "Human"');
		fltrAllowArmourRaces.add('HumanRace "Human"');
		
	fltrAlchemyStrings := TStringList.Create;
		fltrAlchemyStrings.Add('HC_');
		fltrAlchemyStrings.Add('DLC04GZVaultTec_Experiment');
	
	fltrAlchemyStringsAllow := TStringList.Create;
		fltrAlchemyStringsAllow.Add('HC_Herbal');
		fltrAlchemyStringsAllow.Add('HC_Antibiotics');
		
	fltrWeaponStrings := TStringList.Create;
		fltrWeaponStrings.Add('DLC05WorkshopFireworkWeapon');
		fltrWeaponStrings.Add('MS02Nuke');
		fltrWeaponStrings.Add('DLC05PaintballGun');
		fltrWeaponStrings.Add('FatManBomb');
		fltrWeaponStrings.Add('WorkshopArtilleryWeapon');
		
	tlWeaponAnimMelee := TStringList.Create;
		tlWeaponAnimMelee.Add('HandToHandMelee');
		tlWeaponAnimMelee.Add('OneHandAxe');
		tlWeaponAnimMelee.Add('OneHandDagger');
		tlWeaponAnimMelee.Add('OneHandMace');
		tlWeaponAnimMelee.Add('OneHandSword');
		tlWeaponAnimMelee.Add('TwoHandAxe');
		tlWeaponAnimMelee.Add('TwoHandSword');

	tlWeaponSignalGrenadeStrings := TStringList.Create;
		tlWeaponSignalGrenadeStrings.Add('Signal');
		tlWeaponSignalGrenadeStrings.Add('Beacon');
		tlWeaponSignalGrenadeStrings.Add('Smoke');
		tlWeaponSignalGrenadeStrings.Add('Relay');
		
	tlWeaponTrapStrings := TStringList.Create;
		tlWeaponTrapStrings.Add('Trap');
		tlWeaponTrapStrings.Add('Caltrop');
		
	tlAlchemyRadiationAidEffects := TStringList.Create;
		tlAlchemyRadiationAidEffects.Add('FortifyResistRadsRadX');
		tlAlchemyRadiationAidEffects.Add('RestoreRadsChem');
		
	tlAlchemyDeviceStrings := TStringList.Create;
		tlAlchemyDeviceStrings.Add('Settings');
		tlAlchemyDeviceStrings.Add('Uninstall');
		tlAlchemyDeviceStrings.Add(' List');
		tlAlchemyDeviceStrings.Add('Repair');
	
	tlAlchemyAidSounds := TStringList.Create;
		tlAlchemyAidSounds.Add('NPCHumanEatSoupSlurp');
		tlAlchemyAidSounds.Add('NPCHumanChemsAddictol');
		
	tlAlchemyCleanWaterKeywords := TStringList.Create;
		tlAlchemyCleanWaterKeywords.Add('AnimFurnWater');
		tlAlchemyCleanWaterKeywords.Add('ObjectTypeWater');
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
				eComponent := WinningOverride(LinksTo(ElementByName(eComponentRow, 'Component')));
				Result.Add(Name(eComponent));
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
	{ Does the record have Non-Playable flag? }
	if (GetElementEditValues(e, 'DNAM - Data\Flags\Not Playable') = '1') then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for having Non Playable tag', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
	{ Does the record have a model? } 
	if not (HasModel(e)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for having no model', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
	{ Does the record contain any substr from fltrWeaponStrings? }
	if (ElementContainsStrFromList(e, 'EDID - Editor ID', fltrWeaponStrings)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s based on excl/incl lists', [sHeader, Name(e)]));
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
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for being Human + Non Playable', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	{ Does the record have a race defined in fltrAllowArmourRaces? }
	end else if (fltrAllowArmourRaces.IndexOf(sRace) = -1) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for not being allowed race', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
end;

procedure FilterAmmo(e: IInterface);
begin
	{ Does the record have Non-Playable flag? }
	if (IsNonPlayable(e)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for having Non Playable tag', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
end;

procedure FilterAlchemy(e: IInterface);
begin
	{ Does the record have a model? } 
	{ NOTE: Might be a problem for script chems e.g. uninstallers? }
	if not (HasModel(e)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for having no model', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
	{ Does the record have a keyword from the list fltrAlchemyKeywords }
	if (HasKeywordFromList(e, fltrAlchemyKeywords)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for HC Keyword', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
	{ Does the record EDID contain any substr from fltrAlchemyKeywords? }
	if (ElementContainsStrFromList(e, 'EDID - Editor ID', fltrAlchemyStrings)) and not (ElementContainsStrFromList(e, 'EDID - Editor ID', fltrAlchemyStringsAllow)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s based on excl/incl lists', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
end;


{===================================================================================================================}
{                                                 Patch Functions                                                   }
{===================================================================================================================}

procedure PatchWeapon(e: IInterface);
var
	sAnimType: string;
begin
	sAnimType := GetElementEditValues(e, 'DNAM - Data\Animation Type');
	{ Does the record have Grenade Animation Type? }
	if (sAnimType = 'Grenade') then begin
		{ Does the record have a substr from tlWeaponSignalGrenadeStrings? }
		if (ElementContainsStrFromList(e, 'FULL - Name', tlWeaponSignalGrenadeStrings)) then begin
			sTag := tUtilGrenade;
			if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Anim Type (Grenade) and Strings (tlWeaponSignalGrenadeStrings)', [sHeader, sTag, Name(e)]));
		end else begin
			sTag := tGrenade;
			if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Anim Type (Grenade)', [sHeader, sTag, Name(e)]));
		end;
	{ Does the record have Mine Animation Type? }
	end else if (sAnimType = 'Mine') then begin
		{ Does the record have a substr from tlWeaponTrapStrings? }
		if (ElementContainsStrFromList(e, 'FULL - Name', tlWeaponTrapStrings)) then begin
			sTag := tTraps;
			if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Anim Type (Mine) and Strings (tlWeaponTrapStrings)', [sHeader, sTag, Name(e)]));
		end else begin
			sTag := tMine;
			if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Anim Type (Mine)', [sHeader, sTag, Name(e)]));
		end;
	end;
	{ Simplified Sorting uses INNR for most weapon tags. }
	{ TODO: INNR Patching }
end;

procedure PatchArmour(e: IInterface);
var
	sRace: string;
begin
	{ Does the Record have Supermutant race? }
	sRace := GetElementEditValueTrimmed(e, 'RNAM - Race');
	if (sRace = 'SuperMutantRace') then begin
		sTag := tSuperMutantArmour;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Race (SuperMutant)', [sHeader, sTag, Name(e)]));
		exit;
	{ Does the Record have Dogmeat race? }
	end else if (sRace = 'DogmeatRace') then begin
		sTag := tDogArmour;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Race (Dogmeat)', [sHeader, sTag, Name(e)]));
		exit;
	end;
end;

procedure PatchAmmo(e: IInterface);
begin
	{ Does the record have PowerArmorBattery Keyword? }
	if (HasKeyword(e, 'isPowerArmorBattery')) then begin
		sTag := tFusionCore; 
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Keyword (isPowerArmorBattery)', [sHeader, sTag, Name(e)]));	
	end else begin
		sTag := tAmmo; 
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Signature (AMMO)', [sHeader, sTag, Name(e)]));
	end;
	{ TODO: Ballistic has 3D Count keyword? - could use to split ballistic/energy, etc. }
end;

procedure PatchAlchemy(rec: IInterface);
begin
	{ Individual Records which defy the script filters - only needed for vanilla patching }
	if (geev(rec, 'EDID - Editor ID') = 'HC_Antibiotics') then begin
		sTag := tAid;
		exit;
	end;
	{ Does the record have ObjectTypeStimpack Keyword? }
	if (HasKeyword(rec, 'ObjectTypeStimpak')) then begin
		sTag := tStimpack;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Keyword (ObjectTypeStimpack)', [sHeader, sTag, Name(rec)]));
	{ Does the record have an effect from tlAlchemyRadiationAidEffects? }
	end else if (HasEffectFromList(rec, tlAlchemyRadiationAidEffects)) then begin
		sTag := tRadiationAid; 
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Effect (tlAlchemyRadiationAidEffects)', [sHeader, sTag, Name(rec)]));	
	{ Does the record have a Keyword from tlAlchemyCleanWaterKeywords + No radiation effect + Water in name? }
	end else if (HasKeywordFromList(rec, tlAlchemyCleanWaterKeywords)) and not (HasEffect(rec, 'DamageRadiationWater')) and (ElementContainsStr(rec, 'FULL - Name', 'Water')) then begin
		sTag := tCleanWater;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Keyword from tlAlchemyCleanWaterKeywords + NOT Effect (DamageRadiationWater) + Name contains Water', [sHeader, sTag, Name(rec)]));
	{ Does the record have IV Bag preview transform? }	
	end else if GetElementEditValueTrimmed(rec, 'PTRN - Preview Transform') = 'MiscIV' then begin
		sTag := tBloodpack;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Preview Transform (MiscIV)', [sHeader, sTag, Name(rec)]));
	{ Does the record use the stealthboy model? }
	end else if (geev(rec, 'Model\MODL - Model FileName') = 'Props\StealthBoy01.nif') then begin
		sTag := tDevice;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Model (Stealthboy01.nif)', [sHeader, sTag, Name(rec)]));	
	{ Does the record name contain any substrs from tlAlchemyDeviceStrings? }
	end else if (ElementContainsStrFromList(rec, 'FULL - Name', tlAlchemyDeviceStrings)) then begin
		sTag := tDevice;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Name contains substr from tlAlchemyDeviceStrings)', [sHeader, sTag, Name(rec)]));	
	{ Does the record have any consume found from tlAlchemyAidSounds? }
	end else if (tlAlchemyAidSounds.IndexOf(GetElementEditValueTrimmed(rec, 'ENIT\Sound - Consume')) >= 0) then begin
		sTag := tAid;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Has Consume Sound from tlAlchemyAidSounds)', [sHeader, sTag, Name(rec)]));
	{ Does the record have ObjectTypeAlcohol Keyword? }
	end else if (HasKeyword(rec, 'ObjectTypeAlcohol')) then begin
		sTag := tAlcohol;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Keyword (ObjectTypeAlcohol)', [sHeader, sTag, Name(rec)]));
	{ Does the record have sludge drink consume sound? }
	end else if (GetElementEditValueTrimmed(rec, 'ENIT\Sound - Consume') = 'DLC03NPCHumanDrinkSludgePack') then begin
		sTag := tAlcohol; 
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Consume Sound (DLC03NPCHumanDrinkSludgePack)', [sHeader, sTag, Name(rec)]));
	{ Does the record have ObjectTypeChem Keyword? }
	end else if (HasKeyword(rec, 'ObjectTypeChem')) then begin
		sTag := tChem;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Keyword (ObjectTypeChem)', [sHeader, sTag, Name(rec)]));
	{ Does the record have ObjectTypeNukaCola Keyword? }
	end else if (HasKeyword(rec, 'ObjectTypeNukaCola')) then begin
		sTag := tNukaCola;
		if blDebug then AddMessage(Format('[GS] - [%s] Added %s tag to %s - Keyword (ObjectTypeNukaCola)', [sHeader, sTag, Name(rec)]));
	end;
end;
{===================================================================================================================}
{                                                Helper Functions                                                   }
{===================================================================================================================}

{ Adds a prefix tag to element from path, sTag is defined by Patch* functions. }
procedure AddTag(e: IInterface; sPath: string);
var
	sCur: string;
begin
	sCur := GetElementEditValues(e, sPath);
	if blDeleteTags then 
		sCur := RemoveTags(sCur);
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
	Result := false;
	if (GetElementEditValues(e, 'Record Header\Record Flags\Non-Playable') = '1') then Result := true;
end;

{ Checks if a record has a model. }
function HasModel(e: IInterface): boolean;
begin
	Result := Assigned(geev(e, 'Model\MODL - Model FileName'))
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