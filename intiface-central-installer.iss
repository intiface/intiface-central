#define Configuration GetEnv('CONFIGURATION')
#if Configuration == ""
#define Configuration "Release"
#endif

#define Version GetEnv('BUILD_VERSION')
#if Version == ""
#define Version "x.x.x.x"
#endif

[Setup]
AppName=Intiface Central
AppVersion={#Version}
AppPublisher=Nonpolynomial Labs, LLC
AppPublisherURL=www.intiface.com
AppId={{702b7792-a984-48e4-a7e2-734828b0e9f1}
SetupIconFile=windows\runner\resources\app_icon.ico
WizardImageFile=assets\icons\intiface_central_icon.bmp
WizardSmallImageFile=assets\icons\intiface_central_icon.bmp
DefaultDirName={code:GetDefaultDirName}
UninstallDisplayIcon=windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
OutputBaseFilename=intiface-central-installer
OutputDir=.\installer
// Force local install
PrivilegesRequired=lowest
// Uncomment to allow users to install globally. 
// PrivilegesRequiredOverridesAllowed=dialog
// Uncomment to show License during install.
// LicenseFile=LICENSE


[Dirs]
Name: "{localappdata}\IntifaceCentral"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\{#Configuration}\*.exe"; DestDir: "{app}"
Source: "build\windows\x64\runner\{#Configuration}\*.dll"; DestDir: "{app}"
Source: "build\windows\x64\runner\{#Configuration}\data\*.*"; DestDir: "{app}\data"; Flags: recursesubdirs
Source: "Readme.md"; DestDir: "{app}"; DestName: "Readme.txt"
// Source: "LICENSE"; DestDir: "{app}"; DestName: "License.txt"

[Icons]
Name: "{code:GetDefaultMenuName}\Intiface Central"; Filename: "{app}\intiface_central.exe"; IconFilename: "{app}\intiface_central.exe" 
Name: "{code:GetDefaultDesktopName}\Intiface Central"; Filename: "{app}\intiface_central.exe"; Tasks: desktopicon; IconFilename: "{app}\intiface_central.exe"

// [Run]
// Filename: "{app}\Readme.txt"; Description: "View the README file"; Flags: postinstall shellexec unchecked

[Code]

// Uninstall on install code taken from https://stackoverflow.com/a/2099805/4040754
////////////////////////////////////////////////////////////////////
function GetUninstallString(): String;
var
  sUnInstPath: String;
  sUnInstallString: String;
begin
  sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\{#emit SetupSetting("AppId")}_is1');
  sUnInstallString := '';
  if not RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString) then
    RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sUnInstallString);
  Result := sUnInstallString;
end;


/////////////////////////////////////////////////////////////////////
function IsUpgrade(): Boolean;
begin
  Result := (GetUninstallString() <> '');
end;


/////////////////////////////////////////////////////////////////////
function UnInstallOldVersion(): Integer;
var
  sUnInstallString: String;
  iResultCode: Integer;
begin
// Return Values:
// 1 - uninstall string is empty
// 2 - error executing the UnInstallString
// 3 - successfully executed the UnInstallString

  // default return value
  Result := 0;

  // get the uninstall string of the old app
  sUnInstallString := GetUninstallString();
  if sUnInstallString <> '' then begin
    sUnInstallString := RemoveQuotes(sUnInstallString);
    if Exec(sUnInstallString, '/SILENT /NORESTART /SUPPRESSMSGBOXES','', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
      Result := 3
    else
      Result := 2;
  end else
    Result := 1;
end;

/////////////////////////////////////////////////////////////////////
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep=ssInstall) then
  begin
    if (IsUpgrade()) then
    begin
      UnInstallOldVersion();
    end;
  end;
end;


/////////////////////////////////////////////////////////////////////
function GetDefaultDirName(Param: string): string;
begin
  if IsAdmin then
  begin
    Result := ExpandConstant('{pf}\IntifaceCentral');
  end
    else
  begin
    Result := ExpandConstant('{userappdata}\IntifaceCentral');
  end;
end;


/////////////////////////////////////////////////////////////////////
function GetDefaultDesktopName(Param: string): string;
begin
  if IsAdmin then
  begin
    Result := ExpandConstant('{commondesktop}');
  end
    else
  begin
    Result := ExpandConstant('{userdesktop}');
  end;
end;

/////////////////////////////////////////////////////////////////////
function GetDefaultMenuName(Param: string): string;
begin
  if IsAdmin then
  begin
    Result := ExpandConstant('{commonprograms}');
  end
    else
  begin
    Result := ExpandConstant('{userprograms}');
  end;
end;