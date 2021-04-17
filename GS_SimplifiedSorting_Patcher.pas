

unit UserScript;
uses 'lib\mxpf';

// ==================================== Declare Constants Here ========================================== //
const
	blDebug     	  		= true;
	blIgnoreBethesda  		= false;
	blDefaultPluginState	= true;
	// 
	excludeEsps       		= 'Fallout4.esm'#13'DLCCoast.esm'#13'DLCNukaWorld.esm'#13'DLCRobot.esm'#13'DLCworkshop01.esm'#13'DLCworkshop02.esm'#13'DLCworkshop03.esm';	
	
// ==================================== Declare Variables Here ========================================== //
var 
	validPlugins, tlSigsToLoad, kywdFilterAlch: TStringList;

// ======================================== Main Function =============================================== //

function Initialize: Integer;
var
	i, j: integer;
	rec, f, g: IInterface;
begin
	DefaultOptionsMXPF;
	InitializeMXPF;
	PatchFileByAuthor('1N_SS_Patcher');
	mxLoadMasterRecords := true;
	mxSkipPatchedRecords := true;
	mxLoadWinningOverrides := true;
	// 
	CreateLists;
	// Filters only plugins with relevant records (defined by tlSigsToLoad) 
	validPlugins := TStringList.Create;
	FilterValidPlugins;
	

	for i := 0 to validPlugins.Count - 1 do begin
		AddMessage(validPlugins[i]);
	end;

	
		{for i := MaxRecordIndex downto 0 do begin
			rec := GetRecord(i);
			if not HasName(rec) then
				//AddMessage(Name(rec));
				continue;
		end;}
	ShowPluginSelect;
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
			if blDebug then
				AddMessage(Format('[1N] %s : %s : %s', [GetFileName(f), tlSigsToLoad[n],IntToStr(ElementCount(g))]));
			if ElementCount(g) > 0 then begin
				validPlugins.Add(GetFileName(f));
				break;
			end;		
		end;
	end;	
end;

procedure CreateLists();
begin
	kywdFilterAlch := TStringList.Create;
		kywdFilterAlch.Add('HC_EffectType_Sleep');
		kywdFilterAlch.Add('HC_Eff3ype_Sleep');
		
	tlSigsToLoad := TStringList.Create;
		tlSigsToLoad.Add('WEAP');
		tlSigsToLoad.Add('ARMO');
		tlSigsToLoad.Add('AMMO');
		tlSigsToLoad.Add('ALCH');
		tlSigsToLoad.Add('BOOK');
		tlSigsToLoad.Add('NOTE');
		tlSigsToLoad.Add('KEYM');
		tlSigsToLoad.Add('MISC');
end;

procedure LoadAllRecords();
var
	j: integer;
begin
	for j := 0 to tlSigsToLoad.Count - 1 do begin
		LoadRecords(tlSigsToLoad[j]);
	end;
end;

// ======================================= Helper Functions ============================================== //

function HasName(e: IInterface): boolean;
begin
	Result := (ElementExists(e, 'FULL - Name')) or not (geev(e, 'FULL - Name') = '')
end;

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
 

// ======================================= GUI  ============================================== //

procedure ShowPluginSelect;
const
	spacing = 24;
var
	frm: TForm;
	pnl: TPanel;
	lastTop, contentHeight: Integer;
	cbArray: Array[0..255] of TCheckBox;
	lbl: TLabel;
	sb: TScrollBox;
	i: Integer;
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
		lbl.Caption := 'ppppppppppppp';
		lbl.Left := 8;
		lbl.Top := 8;
		lbl.Width := 280;
		lbl.WordWrap := true;
		lastTop := lbl.Top + lbl.Height + 8 - spacing;

		for i := 0 to validPlugins.Count - 1 do begin
			f := FileByName(validPlugins[i]);
			cbArray[i] := TCheckBox.Create(sb);
			cbArray[i].Parent := sb;
			cbArray[i].Caption := Format(' [%s] %s', [IntToHex(i, 2), validPlugins[i]]);
			cbArray[i].Top := lastTop + spacing;
			cbArray[i].Width := 260;
			lastTop := lastTop + spacing;
			cbArray[i].Left := 12;
			//cbArray[i].Checked := sl.IndexOf(GetFileName(f)) > -1;
		end;
		contentHeight := spacing*(i + 2) + 100;
		if frm.Height > contentHeight then
			frm.Height := contentHeight;

		frm.ShowModal;
	Finally
		frm.Free;
	end;		
end;		
	
	
///////////////////////////////////////////  END ////////////////////////////////////////////////////

end.
