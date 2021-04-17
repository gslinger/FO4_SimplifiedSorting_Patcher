{
	Hotkey: Ctrl+E
}

unit UserScript;
uses 'lib\mxpf';

// ==================================== Declare Constants Here ========================================== //
const
	blDebug     	  		= true;
	blIgnoreBethesda  		= false;
	blDefaultPluginState	= true;
	// 
	excludeEsps       		= 'Fallout4.esm'#13'DLCCoast.esm'#13'DLCNukaWorld.esm'#13'DLCRobot.esm'#13'DLCworkshop01.esm'#13'DLCworkshop02.esm'#13'DLCworkshop03.esm';	
	
// =================================Declare Global Variables Here ========================================== //
var 
	tlFiles, validPlugins, tlSigsToLoad, fltrAlchemyKeywords, fltrAllowArmourRaces: TStringList;
	i: integer;

// ======================================== Main Function =============================================== //

function Initialize: Integer;
var
	j: integer;
	rec, f, g: IInterface;
	sFiles: string;
begin
	DefaultOptionsMXPF;
	InitializeMXPF;
	PatchFileByAuthor('1N_SS_Patcher');
	mxLoadMasterRecords := true;
	mxSkipPatchedRecords := true;
	mxLoadWinningOverrides := true;
	
	// Creates various lists which are used by the script
	CreateLists;
	
	// Filters only plugins with relevant records (defined by tlSigsToLoad) 
	validPlugins := TStringList.Create;
	FilterValidPlugins;
	
	// Show form to select which plugins to patch
	ShowPluginSelect;
	sFiles := tlFiles.CommaText;
	
	// Load all records
	SetInclusions(sFiles);
	LoadAllRecords;
	
	ProcessRecords;
	
	ClearPatch;
	CopyRecordsToPatch;
	
	PrintMXPFReport;
	FinalizeMXPF;
	//ShowMessage('Patching Complete');
end;

// ==================================== Pre-Processing Functions =========================================
procedure FilterValidPlugins();
var
	f, g: IInterface;
	j, n:    integer;
begin
	for j := 0  to FileCount - 2 do begin
		f := FileByLoadOrder(j);
		if (Pos(GetFileName(f), excludeEsps) > 0) and blIgnoreBethesda then
			continue;
		for n := 0 to tlSigsToLoad.Count - 1 do begin
			g := GroupBySignature(f, tlSigsToLoad[n]);
			//if blDebug then
			//	AddMessage(Format('[1N] %s : %s : %s', [GetFileName(f), tlSigsToLoad[n],IntToStr(ElementCount(g))]));
			if ElementCount(g) > 0 then begin
				validPlugins.Add(GetFileName(f));
				break;
			end;		
		end;
	end;	
end;

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
		
	fltrAlchemyKeywords := TStringList.Create;
		fltrAlchemyKeywords.Add('HC_EffectType_Sleep');
		fltrAlchemyKeywords.Add('HC_Eff3ype_Sleep');
	
	fltrAllowArmourRaces := TStringList.Create;
		fltrAllowArmourRaces.add('DogmeatRace');
		fltrAllowArmourRaces.add('SuperMutantRace');
		//fltrAllowArmourRaces.add('HumanChildRace "Human"');
		fltrAllowArmourRaces.add('HumanRace "Human"');
end;

procedure LoadAllRecords();
var
	j: integer;
begin
	for j := 0 to tlSigsToLoad.Count - 1 do begin
		LoadRecords(tlSigsToLoad[j]);
	end;
end;


procedure ClearPatch();
var 
	j: integer;
begin
	for j := 0 to tlSigsToLoad.Count - 1 do begin
		RemoveNode(GroupBySignature(mxPatchFile, tlSigsToLoad[j]));
	end;
end;
// ===================================== Processing Functions ============================================ //

procedure ProcessRecords();
var
	j: integer;
	rec: IInterface;
	sHeader: string;
begin
	// Filter Records
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
			continue;
		end else if (sHeader = 'ARMO') then begin
			FilterArmour(rec);
		end;
	end;
end;

procedure FilterWeapon(e: IInterface);
begin
	// Checks for Non Playable Tag
	if (GetElementEditValues(e, 'DNAM - Data\Flags\Not Playable') = '1') then begin
		if blDebug then AddMessage(Format('[GS] - Filtered %s for having Not Playable tag', [Name(e)]));
		RemoveRecord(i);
		exit;
	end;
	// Checks if weapon has model 
	if not (HasModel(e)) then begin
		if blDebug then AddMessage(Format('[GS] - Filtered %s for having no model.', [Name(e)]));
		RemoveRecord(i);
		exit;
	end;		
end;

procedure ProcessWeapon(e: IInterface);
var
	f: IInterface;
begin
	//AddTag(f, '[WEAPON]', 'FULL - Full Name');	
	AddMessage(Name(e));
end;

procedure FilterArmour(e: IInterface);
var
	sRace: string;
begin
	sRace := GetElementEditValueTrimmed(e, 'RNAM - Race');
	// Removes non-playable human armour
	if (sRace = 'HumanRace "Human"') and (GetElementEditValues(e, 'Record Header\Record Flags\Non-Playable') = '1') then begin
		if blDebug then AddMessage(Format('[GS] - Filtered %s for being Human Non-Playable.', [Name(e)]));
		RemoveRecord(i);
		exit;
	end else if (fltrAllowArmourRaces.IndexOf(sRace) = -1) then begin
		if blDebug then AddMessage(Format('[GS] - Filtered %s for not being human/dogmeat/supermutant', [Name(e)]));
		RemoveRecord(i)
	end;
	
end;


// ======================================= Helper Functions ============================================== //
procedure AddTag(e: IInterface; sTag, sPath: string);
var
	sCur: string;
begin
	sCur := GetElementEditValues(e, sPath);
	//DeleteTags;
	SetElementEditValues(e, sPath, (sTag + ' ' + sCur));
end;

procedure DeleteTags(s: string);
begin
	exit;
end;
// Check if a record has a model (MODL - Model Filename).
function HasModel(e: IInterface): boolean;
begin
	Result := Assigned(geev(e, 'Model\MODL - Model FileName'))
end;

// Check if a record has a name (either null or blank).
function HasName(e: IInterface): boolean;
begin
	Result := (ElementExists(e, 'FULL - Name')) or not (geev(e, 'FULL - Name') = '')
end;

// Checks if a record has any keywords from a list.
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

// Same as above but checks effects. 
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

// Checks if a record has a certain effect 
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

function GetElementEditValueTrimmed(e: IInterface; sPath: string): string;
var
	sVal: string;
begin 
	sVal := GetElementEditValues(e, sPath);
	Result := Copy(sVal, 1, (Pos('[', sVal) - 2));
end; 

// ======================================= GUI  ============================================== //

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
	//
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

		// create scrollbox
		sb := TScrollBox.Create(frm);
		sb.Parent := frm;
		sb.Align := alTop;
		sb.Height := 500;

		// create label
		lbl := TLabel.Create(sb);
		lbl.Parent := sb;
		lbl.Caption := 'Select Plugins you would like to Patch';
		lbl.Left := 8;
		lbl.Top := 8;
		lbl.Width := 280;
		lbl.WordWrap := true;
		lastTop := lbl.Top + lbl.Height + 8 - spacing;
		
		// Create checkboxes for each plugin
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
		
		// Resizes form depending on how many plugins loaded
		contentHeight := spacing * (j + 2) + 100;
		if frm.Height > contentHeight then
			frm.Height := contentHeight;
		
		// Create OK, Cancel buttons. (mtefunctions)
		cModal(frm, frm, frm.Height - 70);
	
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
