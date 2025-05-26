unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, windows,
  Buttons, ExtCtrls, finfo;

type

  progInfo = record
     ShortCut: string;
     Props   : TLinkProperties;
     Button  : TBitBtn;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    procedure FormClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonsClick(Sender: TObject);
  private
    procedure CreateIcons(Sender: TObject);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}
uses inifiles, LazFileUtils;

var
  ini:TIniFile;
  iniPath:string;
  ButtonArray: array of progInfo;
  yOffset:integer = 20;


procedure DoTask(index:integer);
var
  pFile:PChar;
  pArgs:PChar;
  pWorkingDir:PChar;
  desc:string;
begin
  if Length(ButtonArray[index].Props.FullPath) < 1 then
     begin
     desc := ButtonArray[index].Props.Description;
     if (desc = 'Desktop anzeigen') or (desc = 'Shows Desktop') then
        ShowDesktop
     else
        begin
        ShowMessage('Button' +IntToStr(index) + ':' + #13#10 +
                    'Could not find the executable path for ' + ButtonArray[index].ShortCut);
        exit;
       end;
     end;
  try
     // http://stackoverflow.com/questions/9115574/how-can-you-open-a-file-with-the-program-associated-with-its-file-extension
     pFile := PChar(ButtonArray[index].Props.FullPath);

     if ButtonArray[index].Props.Arguments <> '' then
        pArgs := PChar(ButtonArray[index].Props.Arguments)
     else
        pArgs := NIL;

     if ButtonArray[index].Props.WorkingDirectory <> '' then
        pWorkingDir := PChar(ButtonArray[index].Props.WorkingDirectory)
     else
        pWorkingDir := NIL;

     Shellexecute(0, nil, pFile, pArgs, pWorkingDir, SW_SHOW);
  except
  end;
end;


procedure TForm1.ButtonsClick(Sender: TObject);
var
  aBitBtn: TBitBtn;
begin
  aBitBtn := Sender as TBitBtn;
  DoTask(aBitBtn.Tag);
end;


procedure TForm1.CreateIcons(Sender: TObject);
var
  i:integer;
  btn:TBitBtn;
  bmp:graphics.TBitmap;
  ico:TIcon;
begin
  for i:=0 to Length(ButtonArray)-1 do
     begin
     ButtonArray[i].Props.ShortCut:='';
     GetLinkProperties(ButtonArray[i].ShortCut, ButtonArray[i].Props);

     btn := TBitBtn.Create(Self);
     ButtonArray[i].Button := btn;

     btn.Parent        := Form1;
     btn.Align         := alNone;
     btn.AutoSize      := False;
     btn.Caption       := ExtractFileNameOnly(ButtonArray[i].ShortCut);
     if ButtonArray[i].Props.Arguments <> '' then
        btn.Hint          := 'Run "' + ButtonArray[i].Props.FullPath + ' ' + ButtonArray[i].Props.Arguments + '"'
     else
        btn.Hint          := 'Run "' + ButtonArray[i].Props.FullPath + '"';
     btn.ShowHint      := true;
     btn.Name          := 'Button' + IntToStr(1+i);
     btn.TabOrder      := i;
     btn.Left          := 10;
     btn.Width         := 200;
     btn.Top           := yOffset; inc(yOffset, btn.Height);
     btn.Margin        := 2;
     btn.Tag           := i;
     btn.OnClick       := @ButtonsClick;
     btn.Color         := Form1.Color;

     if Length(ButtonArray[i].Props.FullPath) < 1 then
        ico := GetIcon('*.lnk', false)
     else
        ico := GetIcon(ButtonArray[i].Props.FullPath, false);
     bmp:=graphics.TBitmap.Create;
     bmp.height := ico.height;
     bmp.width := ico.width;
     bmp.BitmapHandle:=ico.BitmapHandle;
     btn.Glyph := bmp;
     ico.Free;

     {

     ParentFont    := False;
     Font          := LabelFont;
     Width    := LabelWidth;
     Height   := LabelHeight;
     Left     := xpos;
     Top      := ypos;
     }
     Application.ProcessMessages;
     end;

  Form1.Height := yOffset + 30;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  localDir:string;
  username:array[0..63] of char;
  sr:TSearchRec;
  n:LongWord;
begin
  iniPath := GetAppConfigDir(false) + 'settings.ini';
  n := 64;
  GetUserName(@username, n);
  localDir := 'c:\users\' + string(username) + '\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch';

  n:=0;
  if FileExists(iniPath) then
     begin
     ini := TIniFile.Create(iniPath);
     localDir:=ini.ReadString('Global', 'LocalDir', localDir);
     Form1.Top :=ini.ReadInteger('Form1', 'Top', 100);
     Form1.Left:=ini.ReadInteger('Form1', 'Left', 100);
     try
        Form1.Width:=ini.ReadInteger('Form1', 'Width', 220);
     except
     end;
     ini.Free;
     end
  else
     begin
     CreateDir(GetAppConfigDir(false));
     ini := TIniFile.Create(iniPath);
     ini.WriteString('Global', 'LocalDir', localDir);
     ini.Free;
     end;

  if DirectoryExists(localDir) then
     begin
     If sysutils.FindFirst(localDir + '\*', faAnyFile, sr) = 0 then
        begin
        Repeat
        if (sr.Attr and faDirectory) = faDirectory then
           continue;
        if (sr.Name = '.') or (sr.Name = '..') or (sr.Name = 'desktop.ini') then
           continue;
        SetLength(ButtonArray, Length(ButtonArray) + 1);
        ButtonArray[n].ShortCut:=localDir + '\' + sr.Name;
        inc(n);
        Application.ProcessMessages;
        until sysutils.FindNext(sr) <> 0;
        sysutils.FindClose(sr);
        end;
     end;
  if Length(ButtonArray) > 0 then
     CreateIcons(Sender);
end;

procedure TForm1.FormClose(Sender: TObject);
begin
  SetLength(ButtonArray,0);
  ini := TIniFile.Create(iniPath);
  ini.WriteInteger('Form1', 'Top',  Form1.Top);
  ini.WriteInteger('Form1', 'Left', Form1.Left);
  if Form1.Width <> 220 then
     ini.WriteInteger('Form1', 'Width', Form1.Width);
  ini.Free;
end;


































end.

