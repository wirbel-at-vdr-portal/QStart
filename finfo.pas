unit finfo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, windows;


type
 TLinkProperties = record
   ShortCut:string;
   Arguments: string;
   Description: string;
  {Hotkey:DWord;}
  {IconFile:string;}
  {IconIndex:integer;}
  {pPIDL:pointer;}
   FullPath:string;
  //--   FIND_DATA
   FileAttributes : DWORD;
   CreationTime : FILETIME;
   LastAccessTime : FILETIME;
   LastWriteTime : FILETIME;
   FileSizeHigh : DWORD;
   FileSizeLow : DWORD;
   FileName : string;
   AlternateFileName: string;
  //--
  {ShowCmd:integer}
   WorkingDirectory: string;
 end;


function GetIcon(aFile:string; large:boolean):TIcon;
function GetLinkProperties(const ShortCut:string; var Props:TLinkProperties):boolean;

implementation

uses unit1, ShellAPI, ActiveX, ShlObj;

var FileInfo : TSHFILEINFO;



function GetLinkProperties(const ShortCut:string; var Props:TLinkProperties):boolean;
const
  IID_IPersistFile: TGUID =
    (D1:$0000010B; D2:$0000; D3:$0000; D4:($C0,$00,$00,$00,$00,$00,$00,$46));
var
  pShellLink  : IShellLink;
  pPersistFile: IPersistFile;
  WideName: array[0..MAX_PATH]   of WideChar;
  fFlags:DWord;
  AnsiName : array[0..MAX_PATH] of AnsiChar;
  FindData: TWin32FindData;
  r:DWord;
begin
  Props.ShortCut:=ShortCut;

  CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, IID_IShellLinkA, pShellLink);
  pShellLink.QueryInterface(IID_IPersistFile, pPersistFile);
  MultiByteToWideChar(CP_ACP, 0, pAnsiChar(ShortCut), -1, WideName, Max_Path);
  pPersistFile.Load(WideName, STGM_READ);

  { https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-ishelllinka }

  fFlags := (100 shl 16) or { high word of fFlags = timeout in ms, if SLR_NO_UI is set. 3secs otherwise.}
            SLR_NO_UI    or { dont display a dialog if link cannot be resolved && use timeout }
          { SLR_ANY_MATCH     ignored flag -> dont use }
          { SLR_UPDATE        if the link object has changed, update its path and list of identifiers. }
            SLR_NOUPDATE or { dont update the link }
          { SLR_NOSEARCH or dont execute the search heuristics. }
            SLR_NOTRACK  or { dont use distributed link tracking }
            SLR_NOLINKINFO; { disable distributed link tracking. }
          { SLR_INVOKE_MSI    call the Windows Installer }
          { SLR_NO_UI_WITH_MSG_PUMP   winXP & later }
          { SLR_OFFER_DELETE_WITHOUT_FILE Offer the option to delete the shortcut when this method is
                                          unable to resolve it, even if the shortcut is not a shortcut
                                          to a file }
          { SLR_KNOWNFOLDER  Report as dirty if the target is a known folder and the known folder was redirected }
          { SLR_MACHINE_IN_LOCAL_TARGET  Resolve the computer name in UNC targets that point to a local computer. }
          { SLR_UPDATE_MACHINE_AND_SID   Update the computer GUID and user SID if necessary. }

  r := 0;
  r += pShellLink.Resolve(Form1.Handle, fFlags);


  r += pShellLink.GetArguments(@AnsiName, MAX_PATH);
  Props.Arguments := StrPas(AnsiName);

  r += pShellLink.GetDescription(@AnsiName, MAX_PATH);
  Props.Description := StrPas(AnsiName);

  FindData.dwReserved0:=0; {silentium}
  r += pShellLink.GetPath(@AnsiName, MAX_PATH, FindData, fFlags);
  Props.FullPath := StrPas(AnsiName);
  Props.FileAttributes    := FindData.dwFileAttributes;
  Props.CreationTime      := FindData.ftCreationTime;
  Props.LastAccessTime    := FindData.ftLastAccessTime;
  Props.LastWriteTime     := FindData.ftLastWriteTime;
  Props.FileSizeHigh      := FindData.nFileSizeHigh;
  Props.FileSizeLow       := FindData.nFileSizeLow;
  Props.FileName          := StrPas(FindData.cFileName);
  Props.AlternateFileName := StrPas(FindData.cAlternateFileName);

  r += pShellLink.GetWorkingDirectory(@AnsiName, MAX_PATH);
  Props.WorkingDirectory := StrPas(AnsiName);

  result := r = 0;
end;

function GetIcon(aFile:string; large:boolean):TIcon;
var
  uFlags : DWord;
  icon : TIcon;
begin
  icon := TIcon.Create;

  if large then
     uFlags := SHGFI_LARGEICON { Modify SHGFI_ICON, causing the function to retrieve the file's large icon.  }
  else
     uFlags := SHGFI_SMALLICON;{ Modify SHGFI_ICON, causing the function to retrieve the file's small icon. }


  uFlags := uFlags or
    { SHGFI_ADDOVERLAYS     Apply the appropriate overlays to the file's icon. The SHGFI_ICON flag must also be set.}
    { SHGFI_ATTR_SPECIFIED  indicate that the dwAttributes member of the SHFILEINFO structure at psfi contains the specific attributes that are desired }
    { SHGFI_ATTRIBUTES      Retrieve the item attributes. The attributes are copied to the dwAttributes
                            member of the structure specified in the psfi parameter.
                            These are the same attributes that are obtained from IShellFolder::GetAttributesOf. }
    { SHGFI_DISPLAYNAME or  Retrieve the display name for the file, which is the name as it appears in Windows Explorer.
                            The name is copied to the szDisplayName member of the structure specified in psfi. }
      SHGFI_EXETYPE or    { Retrieve the type of the executable file if pszPath identifies an executable file.
                            The information is packed into the return value. }
      SHGFI_ICON or       { Retrieve the handle to the icon that represents the file and the index of the icon
                            within the system image list. The handle is copied to the hIcon member of the structure
                            specified by psfi, and the index is copied to the iIcon member }
    { SHGFI_ICONLOCATION    Retrieve the name of the file that contains the icon representing the file specified by pszPath,
                            as returned by the IExtractIcon::GetIconLocation method of the file's icon handler.
                            Also retrieve the icon index within that file. The name of the file containing the icon
                            is copied to the szDisplayName member of the structure specified by psfi.
                            The icon's index is copied to that structure's iIcon member. }
    { SHGFI_LINKOVERLAY     Modify SHGFI_ICON, causing the function to add the link overlay to the file's icon. }
    { SHGFI_OPENICON        Modify SHGFI_ICON, causing the function to retrieve the file's open icon. }
    { SHGFI_OVERLAYINDEX    Return the index of the overlay icon. The value of the overlay index is returned in
                            the upper eight bits of the iIcon member of the structure specified by psfi. }
    { SHGFI_PIDL            Indicate that pszPath is the address of an ITEMIDLIST structure rather than a path name. }
    { SHGFI_SELECTED        Modify SHGFI_ICON, causing the function to blend the file's icon with the system highlight color. }
    { SHGFI_SHELLICONSIZE   Modify SHGFI_ICON, causing the function to retrieve a Shell-sized icon. }
    { SHGFI_SYSICONINDEX    Retrieve the index of a system image list icon. If successful, the index is copied to the
                            iIcon member of psfi. The return value is a handle to the system image list.
                            Only those images whose indices are successfully copied to iIcon are valid. Attempting to
                            access other images in the system image list will result in undefined behavior. }
      SHGFI_TYPENAME or   { Retrieve the string that describes the file's type. The string is copied to the szTypeName
                            member of the structure specified in psfi. }
      SHGFI_USEFILEATTRIBUTES;  { Indicates that the function should not attempt to access the file specified by pszPath.
                                  Rather, it should act as if the file specified by pszPath exists with the file attributes
                                  passed in dwFileAttributes.
                                  This flag cannot be combined with the SHGFI_ATTRIBUTES, SHGFI_EXETYPE, or SHGFI_PIDL flags. }


  if SHGetFileInfo(PChar(aFile), FILE_ATTRIBUTE_NORMAL, FileInfo, SizeOf(FileInfo), uFlags) <> 0 then
     try
        icon.Handle := FileInfo.hIcon;
        result := icon;
     except
        result := GetIcon('*.txt', large);
     end;
end;


end.

