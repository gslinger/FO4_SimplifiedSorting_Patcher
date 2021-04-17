{
	1N_CheatBoxes
		by 1NGR
	
	This is a patcher which adds modded items into boxes which can be constructed from Workshop Menu.
	Created mainly for coding practice and testing .esl items in game, maybe someone else will find use in it. 
	
	Requirements: mxpf
	
	Credits: matortheeternal, ruddy88 
}

unit UserScript;
uses 'lib\mxpf';

const
	blPluginsAutoChecked 	= true;
	blDebug         	 	= false;
	blAllowBethesda         = false;
	espName         		= '1N_CraftableCheatBoxes.esp';
	author          		= '1N_CheatBoxes_Patcher';
	excludeEsps             = 'Fallout4.esm'#13'DLCCoast.esm'#13'DLCNukaWorld.esm'#13'DLCRobot.esm'#13'DLCworkshop01.esm'#13'DLCworkshop02.esm'#13'DLCworkshop03.esm'#13'1N_CraftableCheatBoxes.esp';
	
	// Form IDs for FormLists
	idWeapon    			= $000805;
	idArmour    			= $000806;
	idHolotapes 			= $000809;
	idConsumables 			= $00080C;
	idMisc 					= $00080F;
	idMods 					= $000812;
	idAmmo 					= $000815;
	// Form ID for variable which adds modded containers to workshop
	idBoolModdedContainers  = $0008AC;
var
	j, i, buttonSelected: Integer;
	baseFile, rec, weapons, armour, holotapes, consumables, misc, mods, ammo: IInterface;
	blReset: boolean;
	tlExtraRaces, tlMiscMods: TStringList;
	
//  ~~~~~~~~~ Main Function ~~~~~~~~~
function Initialize: Integer;
var
	sFiles, header: String;
begin
	
	InitializeMXPF;
	DefaultOptionsMXPF;
	mxLoadWinningOverrides  := false;
	mxSaveDebug 			:= false;
	
	baseFile := FileByName(espName);

	// Shows Plugin Select Dialog and Sets up Patch File. 
	if not MultiFileSelectString('Select PLugins you would like to include in Patch', sFiles) then
		exit;
	SetInclusions(sFiles);
	PatchFileByAuthor(author);
	
	AddMessage('[1N] Loading all Relevant Records and Creating Patch');
	
	// Load all relevant Records 
	LoadRecords('WEAP'); LoadRecords('ARMO'); LoadRecords('AMMO'); 
	LoadRecords('ALCH'); LoadRecords('BOOK'); LoadRecords('NOTE'); 
	LoadRecords('KEYM'); LoadRecords('MISC');
	
	
	// If no records found close the script
	AddMessage(Format('[1N] %s Records Found', [IntToStr(MaxRecordIndex)]));
	if MaxRecordIndex = -1 then
	begin
		AddMessage('[1N] No Records Found - Aborting');
		FinalizeMXPF;
		exit;
	end;
	
	CreateLists();
	
	// Adds relevant masters for Patch File
	AddMastersToPatch;
	AddMasterIfMissing(mxPatchFile, espName);
	
	// Creates Patch File Records
	weapons 	:= CreateRec(idWeapon);
	armour 		:= CreateRec(idArmour);
	holotapes 	:= CreateRec(idHolotapes);
	consumables := CreateRec(idConsumables);
	misc 		:= CreateRec(idMisc);
	mods 		:= CreateRec(idMods);
	ammo 		:= CreateRec(idAmmo);	
	// Sets variable to allow modded containers to appear in workshop menu
	SetModdedGlobal();
	
	AddMessage('[1N] Patching Process Begun. Could take a while depending on amount of mods loaded');
	
	// Main Patching and Filtering Process
	for i := 0 to MaxRecordIndex do begin
		rec := GetRecord(i);
		if not (ElementExists(rec, 'FULL - Name')) or (geev(rec, 'FULL - Name') = '') then	
			continue;
		header := geev(rec, 'Record Header\Signature');
			if header = 'WEAP' then begin
				if not (geev(rec, 'DNAM - Data\Flags\Not Playable') = '1') then
					SetEditValue(ElementAssign(weapons, HighInteger, nil, False), Name(rec))
				else
					if (blDebug) then
						AddMessage(Format('[1N Debug] - WEAP Record Removed: %s', [Name(rec)]));
				continue;
			end else if header = 'ARMO' then begin
				if (tev(rec, 'RNAM - Race') = 'HumanRace "Human"') and not (geev(rec, 'Record Header\Record Flags\Non-Playable') = '1')
				or (tlExtraRaces.indexOf(tev(rec, 'RNAM - Race')) >= 0) then
					SetEditValue(ElementAssign(armour, HighInteger, nil, False), Name(rec))
				else
					if (blDebug) then
						AddMessage(Format('[1N Debug] - ARMO Record Removed: %s', [Name(rec)]));
				continue;
			end else if header = 'AMMO' then begin
				if not (geev(rec, 'Record Header\Record Flags\Non-Playable') = '1') then
					SetEditValue(ElementAssign(ammo, HighInteger, nil, False), Name(rec))
				else
					if (blDebug) then
						AddMessage(Format('[1N Debug] - AMMO Record Removed: %s', [Name(rec)]));
				continue;
			end else if header = 'ALCH' then begin
				SetEditValue(ElementAssign(consumables, HighInteger, nil, False), Name(rec));
				continue;
			end else if (header = 'BOOK') or (header = 'NOTE') then begin
				SetEditValue(ElementAssign(holotapes, HighInteger, nil, False), Name(rec));
				continue;
			end else if header = 'MISC' then begin
				if HasKeyword(rec, 'ObjectTypeLooseMod') or (tlMiscMods.indexOf(tev(rec, 'PTRN - Preview Transform')) >= 0) then
					SetEditValue(ElementAssign(mods, HighInteger, nil, False), Name(rec))
				else 
					SetEditValue(ElementAssign(misc, HighInteger, nil, False), Name(rec));
			end else
				SetEditValue(ElementAssign(misc, HighInteger, nil, False), Name(rec));
	end;
	

	// Final Tidying and Reports
	AddMessage('[1N] Patching Process Finished. Tidying Records and Closing Scripts'); 
	RemoveNullRecords();
	CleanMasters(mxPatchFile);
	FinalizeMXPF;
	AddMessage('[1N] Patch Finished.');
	AddMessage('[1N] Make sure to save your new ESP and enable it in your load order');
	AddMessage('[1N] The Patch File should be fine to be made ESL');
end;


// Creates and cleans a patch record for formlist, it returns the 'Formids' Element for easy editing. 
function CreateRec(id: Integer): IInterface;
var
	e: IInterface;
begin
	AddMessage(IntToStr(MasterCount(baseFile) * 01000000 + id));
	e := RecordByFormID(baseFile, MasterCount(baseFile) * $01000000 + id, false);
	e := wbCopyElementToFile(e, mxPatchFile, false, true);
	Remove(ElementByPath(e, 'FormIDs\'));
	Add(e, 'FormIDs', false);
	Result := ElementByPath(e, 'FormIDs');
end;

procedure SetModdedGlobal();
var
	e: IInterface;
begin
	e := RecordByFormID(baseFile, MasterCount(baseFile) * $01000000 + idBoolModdedContainers, false);
	e := wbCopyElementToFile(e, mxPatchFile, false, true);
	seev(e, 'FLTV', 1);
end;
// Deletes NULL references from 1st entry of formlist. 
procedure RemoveNullRecords();
begin
	RemoveByIndex(weapons, 0, true);
	RemoveByIndex(armour, 0, true);
	RemoveByIndex(holotapes, 0, true);
	RemoveByIndex(consumables, 0, true);
	RemoveByIndex(misc, 0, true);
	RemoveByIndex(mods, 0, true);
	RemoveByIndex(ammo, 0, true);
end;

// Creates lists useful for filtering
procedure CreateLists();
begin
	tlExtraRaces := TStringList.create;
	//tlExtraRaces.add('HumanRace "Human"');
	tlExtraRaces.add('DogmeatRace');
	tlExtraRaces.add('SuperMutantRace');
		
	tlMiscMods := TStringList.create;
	tlMiscMods.add('MiscMod01');
	tlMiscMods.add('MiscMod02');
end;

// It is same as geev but removes the form ID, mainly for load order compatability 
function tev(rec: IInterface; sPath: String): String;
var
	sVal: String;
begin
	sVal := geev(rec, sPath);
	Result := Copy(sVal,1,(Pos('[',sVal)-2));
end;

// Checks a records keywords for any matches inside a string lists
function CheckForKeywords(e: IInterface; tlKeywords: TStringList): Boolean;
var
	k: String;
	keywords: IInterface;
	x: Integer;	
begin
	Result := false;
	keywords := ElementByPath(e, 'KWDA');
	for x := 0 to ElementCount(keywords) - 1 do begin
		k := geev(WinningOverride(LinksTo(ElementByIndex(keywords, x))), 'EDID');
		if tlKeywords.indexOf(k) >= 0 then begin
			Result := true;
			exit;
		end;
	end;
end;

{
	This section has been lifted from mtefunctions and tweaked by me. 
	I also used ruddy88 simple sorter as a reference 
	Credits to ruddy and mator.
}
function MultipleFileSelectString(sPrompt: String; var sFiles: String): Boolean;
var
  sl: TStringList;
begin
	sl := TStringList.Create;
	try
	Result := MultiFileSelect(sl, (sPrompt));
	sFiles := sl.CommaText;
	finally
	sl.Free;
	end;
end;

function MultiFileSelect(var sl: TStringList; prompt: string): Boolean;
const
  spacing = 24;
var
  frm: TForm;
  pnl: TPanel;
  lastTop, contentHeight: Integer;
  cbArray: Array[0..1000] of TCheckBox;
  lbl: TLabel;
  sb: TScrollBox;
  i: Integer;
  f: IInterface;
  fName: String;
begin
  Result := false;
  frm := TForm.Create(nil);
  try
    frm.Position := poScreenCenter;
    frm.Width := 300;
    frm.Height := 600;
    frm.BorderStyle := bsDialog;
    frm.Caption := '- Select Plugins -';
    
    // create scrollbox
    sb := TScrollBox.Create(frm);
    sb.Parent := frm;
    sb.Align := alTop;
    sb.Height := 500;
    
    // create label
    lbl := TLabel.Create(sb);
    lbl.Parent := sb;
    lbl.Caption := prompt;
    lbl.Left := 8;
    lbl.Top := 8;
    lbl.Width := 280;
    lbl.WordWrap := true;
    lastTop := lbl.Top + lbl.Height + 8 - spacing;
    
    // create checkboxes
	for i := 0 to FileCount - 2 do begin
		f := FileByLoadOrder(i);
		fName := GetFileName(f);
		cbArray[i] := TCheckBox.Create(sb);
		cbArray[i].Parent := sb;
		cbArray[i].Caption := Format(' [%s] %s', [IntToHex(i, 2), fName]);
		cbArray[i].Top := lastTop + spacing;
		cbArray[i].Width := 260;
		lastTop := lastTop + spacing;
		cbArray[i].Left := 12;
		
		// Filter base, patch and bethesda plugins 
		if (Pos(fName, excludeEsps) > 0) or (GetAuthor(f) = author) then 
			cbArray[i].Enabled := blAllowBethesda
		else 
			cbArray[i].Checked := blPluginsAutoChecked;
	end;
    
    contentHeight := spacing*(i + 2) + 100;
    if frm.Height > contentHeight then
      frm.Height := contentHeight;
    
    // create modal buttons
    cModal(frm, frm, frm.Height - 70);
    sl.Clear;
    
    if frm.ShowModal = mrOk then begin
      Result := true;
      for i := 0 to FileCount - 2 do begin
        f := FileByLoadOrder(i);
        if (cbArray[i].Checked) and (sl.IndexOf(GetFileName(f)) = -1) then
          sl.Add(GetFileName(f));
      end;
    end;
  finally
    frm.Free;
  end;
end;

end.
