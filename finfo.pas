unit finfo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, windows;

{
type
TFileInfoCollector = Class(TComponent)
   Function IndexOfExtension (AExtension : String; CachedOnly : Boolean = False) : Integer;
   Function FindDescription  (AExtension : String; CachedOnly : Boolean = False) : String;
   Function FindExtensionInfo(AExtension : String; CachedOnly : Boolean = False) : TExtensionInfo;
   Property Extensions[AIndex : Integer] : String;
   Property Descriptions[AIndex : Integer] : String;
   Property MimeTypes[AIndex : Integer] : String;
   Property IconHandles[AIndex : Integer] : Thandle;
   Property ImageIndex[AIndex : Integer] : Integer;
   Property InfoCount : Integer;
Published
   Property ImageList : TImageList;
   Property SmallIcons : Boolean;
   Property FreeIconHandles : Boolean;
end;
}


function GetIcon(aFile:string; large:boolean):TIcon;
function GetShortcutTarget(const ShortcutFilename: string): string;

implementation

uses ShellAPI, ActiveX, ShlObj;

var FileInfo : TSHFILEINFO;


function GetShortcutTarget(const ShortcutFilename: string): string;
var
  Psl: IShellLink;
  Ppf: IPersistFile;
  WideName: array[0..MAX_PATH] of WideChar;
  pResult: array[0..MAX_PATH-1] of ansiChar;
  Data: TWin32FindData;
const
  IID_IPersistFile: TGUID = (D1:$0000010B; D2:$0000; D3:$0000; D4:($C0,$00,$00,$00,$00,$00,$00,$46));
begin
  CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, IID_IShellLinkA, psl);
  psl.QueryInterface(IID_IPersistFile, ppf);
  MultiByteToWideChar(CP_ACP, 0, pAnsiChar(ShortcutFilename), -1, WideName, Max_Path);
  ppf.Load(WideName, STGM_READ);

  // https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-ishelllinka

  psl.Resolve(0, SLR_ANY_MATCH);
  psl.GetPath(@pResult, MAX_PATH, Data, SLGP_UNCPRIORITY);
  Result := StrPas(pResult);
end;



function GetIcon(aFile:string; large:boolean):TIcon;
var
  Attr : DWord;
  icon : TIcon;
begin
  //result := 0;
  icon := TIcon.Create;

  Attr := SHGFI_ICON or SHGFI_TYPENAME or SHGFI_USEFILEATTRIBUTES;

  if large then
     Attr := Attr or SHGFI_LARGEICON
  else
     Attr := Attr or SHGFI_SMALLICON;

  if SHGetFileInfo(PChar(aFile), FILE_ATTRIBUTE_NORMAL, FileInfo, SizeOf(FileInfo), Attr) <> 0 then
     begin
     try
        icon.Handle := FileInfo.hIcon;
        result := icon;
     finally
     end;
     end
  else
     begin
     result := GetIcon('*.exe', large);
     end;
end;





{
function TFileInfoCollector.FetchExtensionInfo(AExtension: String): TExtensionInfo;
const
  IconOptions : Array[Boolean] of DWORD = (SHGFI_LARGEICON,SHGFI_SMALLICON);
var
  FileInfo : SHFILEINFO;
  Attr : DWORD;
  Info : TextensionInfo;
  AnIcon : TIcon;
begin
  Result:=Nil;
  Attr := SHGFI_ICON or SHGFI_TYPENAME or SHGFI_USEFILEATTRIBUTES or IconOptions[SmallIcons];
  if SHGetFileInfo(PChar(’ * ’+AExtension), FILE_ATTRIBUTE_NORMAL, FileInfo,SizeOf(FileInfo),Attr) <> 0 then
    begin
    Info := FExtensions.Add as TExtensionInfo;
    Info.Extension:=AExtension;
    Info.Description:=FileInfo.szTypeName;
    Info.hIcon:=FileInfo.hIcon;
    Result:=Info;
    if Assigned(ImageList) then
       begin
       AnIcon:=TIcon.Create;
       try
          AnIcon.Handle:=Info.hIcon;
          Info.ImageIndex:=ImageList.AddIcon(anIcon);
       finally
          if FreeIconHandles then
             Info.hIcon:=0
          else
             AnIcon.Handle:=0;
          AnIcon.Free;
       end;
       end
    else
       begin
       Info.ImageIndex:=-1;
       if FreeIconHandles then
          begin
          DestroyIcon(Info.hIcon);
          Info.hIcon:=0;
          end;
       end;
    if FRegistry.OpenKeyReadOnly(AExtension) then
       Info.MimeType:=Fregistry.ReadString(’Content Type’);
    end;
end;
}

end.

