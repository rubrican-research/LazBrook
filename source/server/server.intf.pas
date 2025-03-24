unit server.intf;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils;
type
	ProcStartServer     =  function (_host: pChar; _port: dword): boolean; stdcall;
	ProcServerText      =  function : pChar; stdcall;
	ProcServerFlag      =  function : boolean;stdcall;

	{ TWebAppIntf }

    TWebAppIntf = class
        handle         : TLibHandle;
        libIdentity    : ProcServerText;
		startServer    : ProcStartServer;
		serverRunning  : ProcServerFlag;
		serverName     : ProcServerText;
		serverID       : ProcServerText;
		serverAbout    : ProcServerText;
		serverURL      : ProcServerText;
		serverEndPoints: ProcServerText;
		stopServer     : ProcServerFlag;
        function isLoaded: boolean;
        procedure init;
        constructor Create;
        destructor Destroy; override;
    end;
    function isLazBrookLib(const _libPath: string): boolean;
    function WebAppLib(const _libPath: string): TWebAppIntf;
    procedure close(constref _intf: TWebAppIntf);

const
    LAZBROOKIDV1 = 'LazBrook Server Library V1';


implementation
uses
    fgl;
type
    TWebAppIntfList = class(specialize TFPGMapObject<string, TWebAppIntf>);

var
    webAppIntfs : TWebAppIntfList;


function loadWebAppLib(const _libPath: string): TWebAppIntf;
var
	_libID: pChar;
    _strLibID: shortString;
    _message : string;
begin
    Result := TWebAppIntf.Create;

    if FileExists(_libPath) then begin
        Result.Handle  := loadLibrary(_libPath);
        if Result.Handle <> 0 then begin
            Pointer(Result.libIdentity    )  := GetProcAddress(Result.Handle, 'libIdentity');
            if not assigned(Result.libIdentity) then begin
                Result.init;
                Raise Exception.Create(Format('%s is not a LazBrook server library', [_libPath]));
            end
            else begin
                _libID    := Result.libIdentity();
                _strLibID := _libID;
                 StrDispose(_libID);
                case _strLibID of
                    LAZBROOKIDV1: ;
                    else begin
                        Result.init;
                        _message := Format('%d: LazBrook server library version not supported (%s)', [_libPath, _libID]);
                        Raise Exception.Create(_message);
					end;
				end;
			end;
            Pointer(Result.startServer    )  := GetProcAddress(Result.Handle, 'startServer');
            Pointer(Result.serverRunning  )  := GetProcAddress(Result.Handle, 'serverRunning');
            Pointer(Result.serverName     )  := GetProcAddress(Result.Handle, 'serverName');
            Pointer(Result.serverID       )  := GetProcAddress(Result.Handle, 'serverID');
            Pointer(Result.serverAbout    )  := GetProcAddress(Result.Handle, 'serverAbout');
            Pointer(Result.serverURL      )  := GetProcAddress(Result.Handle, 'serverURL');
            Pointer(Result.serverEndPoints)  := GetProcAddress(Result.Handle, 'serverEndPoints');
            Pointer(Result.stopServer     )  := GetProcAddress(Result.Handle, 'stopServer');
		end;
	end;
end;

function isLazBrookLib(const _libPath: string): boolean;
var
	_handle: TLibHandle;
begin
    Result := false;
    if FileExists(_libPath) then begin
        _handle  := loadLibrary(_libPath);
        if _handle <> 0 then begin
            Result := Assigned(GetProcAddress(_handle, 'libIdentity'));
            FreeLibrary(_handle);
		end;
	end;
end;

function WebAppLib(const _libPath: string): TWebAppIntf;
var
	i: Integer;
begin
    i := webAppIntfs.IndexOf(_libPath);
    if i = -1 then begin
        Result := loadWebAppLib(_libPath);
        webAppIntfs.Add(_libPath, Result);
	end
    else
        Result := webAppIntfs.Data[i];
end;

procedure close(constref _intf: TWebAppIntf);
begin
    if _intf.handle <> 0 then begin
        if _intf.serverRunning() then _intf.stopServer();
        FreeLibrary(_intf.handle);
        _intf.init;
	end;
end;

{ TWebAppIntf }

function TWebAppIntf.isLoaded: boolean;
begin
    Result := handle <> 0;
end;

procedure TWebAppIntf.init;
begin
    handle := 0;
    libIdentity    := nil;
	startServer    := nil;
	serverRunning  := nil;
	serverName     := nil;
	serverID       := nil;
	serverAbout    := nil;
	serverURL      := nil;
	serverEndPoints:= nil;
	stopServer     := nil;
end;

constructor TWebAppIntf.Create;
begin
    inherited;
    init;
end;

destructor TWebAppIntf.Destroy;
begin
    close(self);
	inherited Destroy;
end;


initialization
    webAppIntfs := TWebAppIntfList.Create(True);

finalization
    webAppIntfs.Free;

end.

