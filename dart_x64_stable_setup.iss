#define MyAppName "Dart"
#define MyAppVersion "stable 64-bit"
#define MyAppPublisher "Gekorm"
#define MyAppURL "https://www.dartlang.org/"
#define MyAppExeName "dart.exe"
#include <idp.iss>

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{E30EFA88-E6EE-4149-860C-049E4F1A1CFC}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
ArchitecturesInstallIn64BitMode=x64
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=D:\Downloads\Chrome\d skd\LICENSE.txt
InfoBeforeFile=D:\Downloads\Chrome\d skd\INFO.txt
InfoAfterFile=D:\Downloads\Chrome\d skd\AFTER.txt
OutputDir=D:\Downloads\Chrome\d skd
OutputBaseFilename=Dart_x64 stable setup
SetupIconFile=D:\Downloads\Chrome\d skd\Twitter-02.ico
Compression=lzma
SolidCompression=yes
; Tell Windows Explorer to reload the environment
ChangesEnvironment=yes
; Size of files to download:
ExtraDiskSpaceRequired = 210006813

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "D:\Downloads\Chrome\7za920\7za.exe"; DestDir: {tmp}; Flags: dontcopy
Source: "{tmp}\dart-sdk\*"; DestDir: "{app}\dart-sdk"; Flags: ignoreversion recursesubdirs createallsubdirs external
Source: "{code:GetDartiumName}\*"; DestDir: "{app}\dartium"; Flags: ignoreversion recursesubdirs createallsubdirs external
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

[Registry]
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}\dart-sdk\bin"; Check: NeedsAddPath('{app}\dart-sdk\bin')
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "DART_SDK"; ValueData: "{app}\dart-sdk";

[Code]
// SO: http://stackoverflow.com/questions/3304463/
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
  ParamExpanded: string;
begin
  // Expand the setup constants like {app} from Param
  ParamExpanded := ExpandConstant(Param);
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  // Look for the path with leading and trailing semicolon and with or without \ ending
  // Pos() returns 0 if not found
  Result := Pos(';' + UpperCase(ParamExpanded) + ';', ';' + UpperCase(OrigPath) + ';') = 0;  
  if Result = True then
     Result := Pos(';' + UpperCase(ParamExpanded) + '\;', ';' + UpperCase(OrigPath) + ';') = 0; 
end;

procedure InitializeWizard;
begin
  // Extract 7za to temp folder
  ExtractTemporaryFile('7za.exe');
  // Only tell the plugin when we want to start downloading
  // Add the files to the list; at this time, the {app} directory is known
  idpAddFile('https://storage.googleapis.com/dart-archive/channels/stable/release/latest/dartium/dartium-windows-ia32-release.zip', ExpandConstant('{tmp}\dartium.zip'));
  idpAddFile('https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-windows-x64-release.zip', ExpandConstant('{tmp}\dart-sdk.zip'));
  idpDownloadAfter(wpReady);
end;

procedure DoUnzip(source: String; targetdir: String);
var 
  unzipTool: String;
  ReturnCode: Integer;
begin
  // Source contains tmp constant, so resolve it to path name
  source := ExpandConstant(source);

  unzipTool := ExpandConstant('{tmp}\7za.exe');

  if not FileExists(unzipTool)
  then MsgBox('UnzipTool not found: ' + unzipTool, mbError, MB_OK)
  else if not FileExists(source)
  then MsgBox('File was not found while trying to unzip: ' + source, mbError, MB_OK)
  else begin
       if Exec(unzipTool, ' x "' + source + '" -o"' + targetdir + '" -y',
               '', SW_HIDE, ewWaitUntilTerminated, ReturnCode) = false
       then begin
           MsgBox('Unzip failed:' + source, mbError, MB_OK);
       end;
  end;
end;

function TryGetFirstSubfolder(const Path: string; out Folder: string): Boolean;
var
  S: string;
  FindRec: TFindRec;
begin
  Result := False;
  if FindFirst(ExpandConstant(AddBackslash(Path) + '*'), FindRec) then
  try
    repeat
      if (FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0) and
        (FindRec.Name <> '.') and (FindRec.Name <> '..') then
      begin
        Result := True;
        Folder := AddBackslash(Path) + FindRec.Name;
        Exit;
      end;
    until
      not FindNext(FindRec);
  finally
    FindClose(FindRec);
  end;
end;

function GetDartiumName(Param: String): String;
var
  S: string;
begin;
  if (TryGetFirstSubfolder(ExpandConstant('{tmp}\' + 'dartium'), S)) then
    Result := S;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  S: string;
begin
  // If the user just reached the ready page, then...
  if CurPageID = wpInstalling then
  begin
    // Extract the zip to the temp folder (when included in the installer)
    // Skip this, when the file is downloaded with IDP to the temp folder
    // ExtractTemporaryFile('app.zip);

    // Unzip the Dart SDK zip in the tempfolder to your temp target path
    DoUnzip(ExpandConstant('{tmp}\') + 'dart-sdk.zip', ExpandConstant('{tmp}'));

    // Unzip the Dartium zip in the tempfolder to your temp target path
    DoUnzip(ExpandConstant('{tmp}\') + 'dartium.zip', ExpandConstant('{tmp}\dartium'));     
  end;
end;