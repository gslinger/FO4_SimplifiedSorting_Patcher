{       
	gsUtilities - Element Functions
	
	An extension of my utilities which will include lots of Data Retrieval functions. 
}

unit gsUtil;

{ Record Header }

{ Gets value of the Data Size of a specified Record }
function GetDataSize(rec: IInterface): integer;
begin
	Result := GetElementEditValues(rec, 'Record Header\Data Size');
end;

{ Gets value of the Signature of a specified Record }
function GetSignature(rec: IInterface): string;
begin
	Result := GetElementEditValues(rec, 'Record Header\Signature');
end;

{ Gathers the element for the Record Header of a specified record }
function GetRecordFlags(rec: IInterface): IInterface;
begin
	Result := ElementByPath(rec, 'Record Header\Record Flags');
end;

{ Gathers all Record flags into a string list for a specified record }
function GetRecordFlagsAsList(rec: IInterface): TStringList;
var
	j: integer;
	eRecordFlags, eRecordFlag: IInterface;
begin
	Result := TStringList.Create;
	eRecordFlags := GetRecordFlags(rec);
	for j := 0 to ElementCount(eRecordFlags) - 1 do begin
		eRecordFlag := ElementByIndex(eRecordFlags, j);
		Result.Add(Name(eRecordFlag));
	end;
end;

{  Checks whether specified record has a specified flag }
function HasRecordFlag(rec: IInterface; sFlag: string): boolean;
var
	tlRecordFlags: TStringList;
begin
	tlRecordFlags := GetRecordFlagsAsList(rec);
	Result := (tlRecordFlags.IndexOf(sFlag) >= 0)
end;

{ EDID - Editor ID }

{ Gets value of the Editor ID of specified record }
function GetEditorID(rec: IInterface): string;
begin
	Result := GetElementEditValues(rec, 'EDID - Editor ID');
end;

{ Sets value of the Editor ID of specified record }
procedure SetEditorID(rec: IInterface; s: string);
begin
	SetElementEditValues(rec, 'EDID - Editor ID', s);
end;

{ OBND - Object Bounds }

{ Gets value of an individual Object Bounds value, enter x1, x2, y1, y2, z1, z2 as S value. }
function GetObjectBound(rec: IInterface; s: string): integer;
begin
	Result := GetElementEditValues(rec, 'OBND - Object Bounds\' + Uppercase(s));
end;

{ Gets the object bound values as stringlist }
function GetObjectBounds(rec: IInterface): TStringList;
begin
	Result := TStringList.Create;
	Result := ElementByPathAsList(rec, 'OBND - Object Bounds', '', true);
end;

{ Set an individual Object Bound }
procedure SetObjectBound(rec: IInterface; sBound: string; iValue: integer);
begin
	SetElementEditValues(rec, 'OBND - Object Bounds\' + Uppercase(sBound), iValue);
end;

{ Set all object bounds }
procedure SetObjectBounds(rec: IInterface; x1, y1, z1, x2, y2, z2: integer);
begin
	SetObjectBound(rec, 'x1', x1);
	SetObjectBound(rec, 'y1', y1);
	SetObjectBound(rec, 'z1', z1);
	SetObjectBound(rec, 'x2', x2);
	SetObjectBound(rec, 'y2', y2);
	SetObjectBound(rec, 'z2', z2);
end;

{ PTRN - Preview Transform }

{ Gets value of the Preview Transform of specified record }
function GetPreviewTransform(rec: IInterface): string;
begin
	Result := GetElementEditValues(rec, 'PTRN - Preview Transform');
end;

{ Sets value of the Preview Transform of specified record }
procedure SetPreviewTransform(rec: IInterface, s: string);
begin
	SetElementEditValues(rec, 'PTRN - Preview Transform');
end;

function GetPreviewTransformAsRecord(rec: IInterface): IInterface;
begin
	exit;
	{TODO}
end;

{ String Manipulation and Name Editing }

{ File Header } 

{ Checks whether a specified plugin is an ESL }
function IsESL(f: IInterface): boolean;
var
	eHeader: IInterface;
begin
	Result := false;
	eHeader := ElementByPath(ElementByIndex(f, 0), 'Record Header\Record Flags\ESL');
	
	if not (Assigned(eHeader)) then
		exit;
		
	if (GetEditValue(eHeader) = 1) or (SameText(ExtractFileExt(GetFileName(f)), '.esl')) then
		Result := true;
end;

{ Checks whether a specified plugin is an ESM }
function IsESM(f: IInterface): boolean;
var
	eHeader: IInterface;
begin
	Result := false;
	eHeader := ElementByPath(ElementByIndex(f, 0), 'Record Header\Record Flags\ESM');
	
	if not (Assigned(eHeader)) then
		exit;
		
	if (GetEditValue(eHeader) = 1) or (SameText(ExtractFileExt(GetFileName(f)), '.esm')) then
		Result := true;
end;

{ Returns total number of records of a file }
function GetRecordCount(f: IInterface): integer;
begin
	Result := GetElementEditValues(ElementByIndex(f, 0), 'HEDR - Header\Number of Records');
end;

{ Returns string list of plugin names which contain records with the specified signature }
function ListFilesWhichContainSig(sSignature: string): TStringList;
var
	j: integer;
begin
	Result := TStringList.Create;
	for j := 0 to Pred(FileCount) do begin
		if (GetRecordCountOfSig(FileByIndex(j), sSignature) > 0) then
			Result.Add(GetFileName(FileByIndex(j)));
	end;	
end;

{ Returns number of records with the specified signature in a specified file }
function GetRecordCountOfSig(f: IInterface; sSignature: string): integer;
begin
	Result := ElementCount(GroupBySignature(f, sSignature));
end;

{ Gets load order hex form id as string, input is local form ID. }
function GetHexFormID(f: IInterface, id: variant): string;
begin
	Result := IntToHex(MasterCount(f) * $01000000 + id, 8);
end;

{ File Management }

{ Gets the File reference for a specified name } 
function FileByName(sName: string): IInterface;
var 
	j: integer;
	f: IInterface;
begin
	Result := nil;
	for j := 0 to Pred(FileCount) do begin
		if GetFileName(FileByIndex(j)) = sName then begin
			Result := FileByIndex(i);
			break;
		end;
	end;			
end;

{ Armour related functions }

{ Checks if a clothing piece has a specified Biped flag }
function HasBipedFlag(rec: IInterface; s: string): boolean;
begin
	Result := (GetElementEditValues(rec, 'BOD2 - Biped Body Template\First Person Flags\' + s) = '1')
end;

{ Gets all biped flags as a list }
function GetBipedFlags(rec: IInterface): TStringList;
var
	eBipedFlags: IInterface;
	j: integer;
begin
	Result := TStringList.Create;
	Result := ElementByPathAsList(rec, 'BOD2 - Biped Body Template\First Person Flags', 'Name', false);
end;

{ Keywords }

{ TODO: Can't work out how to pass an array which works with xEdit } 

function HasKeyword(rec: IInterface; sKeyword: string): boolean;
var
	tlKeywords: TStringList;
begin
	tlKeywords := TStringList.Create;
	tlKeywords := ElementByPathAsList(rec, 'KWDA - Keywords', 'EDID', false);
	Result := (tlKeywords.IndexOf(sKeyword) >= 0);
end;

function HasKeywordFromString(e: IInterface; sKeywords: string): boolean;
var
	eKeywords: IInterface;
	j: integer;
begin
	Result := false;
	eKeywords := ElementByPath(e, 'KWDA');
	for j := 0 to Pred(ElementCount(eKeywords)) do begin
		if (Pos(GetElementEditValues(LinksTo(ElementByIndex(eKeywords, j)), 'EDID'), sKeywords) > 0) then begin
			Result := true;
			break;
		end;
	end;
end;

function HasKeywordFromList(rec: IInterface; tlKeywords: TStringList): boolean;
var
	j: integer;
begin
	Result := false;
	for j := 0 to tlKeywords.Count - 1 do begin
		if (HasKeyword(rec, tlKeywords[j])) then begin
			Result := true;
			break;
		end;
	end;
end;

function GetKeywords(rec: IInterface): TStringList;
begin
	Result := TStringList.Create;
	Result := ElementByPathAsList(rec, 'KWDA - Keywords', 'EDID', true);
end;

{ Internal functions ...  } 

{ Gets an Element as a list of strings, meant for internal use }
{ xEdit does not support optional/default params.. }
function ElementByPathAsList(rec: IInterface; sPath: string; sValue: string = ''; blAllowDups: boolean): TStringList;
var
	e: IInterface;
	j: integer;
begin
	Result := TStringList.Create;
	if not blAllowDups then begin
		Result.Duplicates := dupIgnore;
		Result.Sorted := true;
	end;
	e := ElementByPath(rec, sPath);
	for j := 0 to Pred(ElementCount(e)) do begin
		if (sValue = 'Name') then 
			Result.Add(Name(ElementByIndex(e, j)))
		else if (sValue = 'EDID') then
			Result.Add(GetElementEditValues(LinksTo(ElementByIndex(e, j)), 'EDID - Editor ID'))
		else 
			Result.Add(GetEditValue(ElementByIndex(e, j)));
	end;
end;


end.