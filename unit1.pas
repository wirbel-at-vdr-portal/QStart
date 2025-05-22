unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, windows,
  Buttons, ExtCtrls;

type

  progInfo = record
     LinkName: string;
     ProgName: string;
     Button  : TBitBtn;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
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
uses inifiles, finfo, LazFileUtils;

var
  ini:TIniFile;
  ButtonArray: array of progInfo;
  yOffset:integer = 20;


procedure DoTask(index:integer);
var fName:string;
begin
  fName:= ButtonArray[index].ProgName;
  if fileExists(fname) then
     try
     // http://stackoverflow.com/questions/9115574/how-can-you-open-a-file-with-the-program-associated-with-its-file-extension
     Shellexecute(0, nil, PChar(fname),nil,nil,SW_SHOW);
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
  s:string;
begin
  for i:=0 to Length(ButtonArray)-1 do
     begin
     btn := TBitBtn.Create(Self);
     ButtonArray[i].Button := btn;
     s := GetShortcutTarget(ButtonArray[i].LinkName);
     ButtonArray[i].ProgName:=s;

     btn.Parent        := Self;
     btn.Align         := alNone;
     btn.AutoSize      := False;
     btn.Caption       := ExtractFileNameOnly(ButtonArray[i].LinkName);
     btn.Name          := 'Button' + IntToStr(1+i);
     btn.TabOrder      := i;
     btn.Left          := 10;
     btn.Width         := 200;
     btn.Top           := yOffset; inc(yOffset, btn.Height);
     btn.Margin        := 2;
     btn.Tag           := i;
     btn.OnClick       := @ButtonsClick;

     ico := GetIcon(s, false);
     bmp:=graphics.TBitmap.Create;
     bmp.height := ico.height;
     bmp.width := ico.width;
     bmp.BitmapHandle:=ico.BitmapHandle;
     btn.Glyph := bmp;
     ico.Free;


     {
     Color         := clGreen;
     ParentFont    := False;
     Font          := LabelFont;
     Width    := LabelWidth;
     Height   := LabelHeight;
     Left     := xpos;
     Top      := ypos;
     }
     end;

  Form1.Height := yOffset + 30;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  iniPath:string;
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
        ButtonArray[n].LinkName:=localDir + '\' + sr.Name;
        inc(n);
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
end;


































end.

