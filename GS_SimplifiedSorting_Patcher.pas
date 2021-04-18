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
	blDeleteTags            = false;
	excludeEsps       		= 'Fallout4.esm'#13'DLCCoast.esm'#13'DLCNukaWorld.esm'#13'DLCRobot.esm'#13'DLCworkshop01.esm'#13'DLCworkshop02.esm'#13'DLCworkshop03.esm';	
	sAuthor                 = 'GS_SS_Patcher';
		
	{ Tag Variables - Will probably add to file }
	tUtilGrenade            = '[W9SIG]';  // Has Grenade Anim Type + A Substr from tlWeaponSignalGrenadeStrings
	tTraps                  = '[W9TRP]';  // Has Grenade Anim Type + A Substr from tlWeaponTrapStrings
	tGrenade                = '[W9GND]';  // Has Grenade Anim Type  (leftovers from above)
	tMine             		= '[W9MNE]';          
var 
	tlFiles, validPlugins, tlSigsToLoad, tlWeaponTrapStrings, tlWeaponSignalGrenadeStrings, fltrAlchemyKeywords, fltrAlchemyStrings, tlWeaponAnimMelee, fltrAlchemyStringsAllow, fltrAllowArmourRaces, fltrWeaponStrings: TStringList;
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
		tlSigsToLoad.Add('WEAP');
		//tlSigsToLoad.Add('ARMO');
		//tlSigsToLoad.Add('AMMO');
		//tlSigsToLoad.Add('ALCH');
		//tlSigsToLoad.Add('BOOK');
		//tlSigsToLoad.Add('NOTE');
		//tlSigsToLoad.Add('KEYM');
		tlSigsToLoad.Add('MISC');
		
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
		end;
		AddMessage(RemoveTags(geev(rec, 'FULL - Name')));
		//AddTag(rec, 'FULL - Name');
	end;	
	
	
end;

{===================================================================================================================}
{                                                Filter Functions                                                   }
{===================================================================================================================}

procedure FilterWeapon(e: IInterface);
begin
	{ Checks if weapon has Non-Playable flag. }
	if (GetElementEditValues(e, 'DNAM - Data\Flags\Not Playable') = '1') then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for having Non Playable tag', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
	{ Checks if weapon has a model. }
	if not (HasModel(e)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for having no model', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
	{ Checks weapon EDID for predefined strings. }
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
	{ Checks if Armour has Non-Playable flag. }
	if (sRace = 'HumanRace "Human"') and (IsNonPlayable(e)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for being Human + Non Playable', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	{ Checks if Armour is usable by a race in the predefined list: fltrAllowArmourRaces. }
	end else if (fltrAllowArmourRaces.IndexOf(sRace) = -1) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for not being allowed race', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
end;

procedure FilterAmmo(e: IInterface);
begin
	{ Checks if ammo has Non-Playable flag }
	if (IsNonPlayable(e)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for having Non Playable tag', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
end;

procedure FilterAlchemy(e: IInterface);
begin
	{ Checks if Ingestible has a model. } 
	{ NOTE: Might be a problem for script chems e.g. uninstallers? }
	if not (HasModel(e)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for having no model', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
	{ Checks if Ingestible has a keyword from a predefined list: fltrAlchemyKeywords. }
	if (HasKeywordFromList(e, fltrAlchemyKeywords)) then begin
		if blDebug then AddMessage(Format('[GS] - [%s] Filtered %s for HC Keyword', [sHeader, Name(e)]));
		RemoveRecord(i);
		exit;
	end;
	{ Checks Ingestible EDID for certain substrings, inclusions: fltrAlchemyStringsAllow, exclusions: fltrAlchemyStrings. }
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
	{ Checks animation types for various values. }
	sAnimType := GetElementEditValues(e, 'DNAM - Data\Animation Type');
	if (sAnimType = 'Grenade') then begin
		if (ElementContainsStrFromList(e, 'FULL - Name', tlWeaponSignalGrenadeStrings)) then begin
			sTag := tUtilGrenade;
		end else if (ElementContainsStrFromList(e, 'FULL - Name', tlWeaponTrapStrings)) then begin
			sTag := tTraps;
		end else begin
			sTag := tGrenade;
		end;
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
		sCur := DeleteTags(sCur);
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
	Result := (Pos(sStr, geev(e, sPath)) > 0);
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
	
	
///////////////////////////////////////////  END ////////////////////////////////////////////////////

end.
