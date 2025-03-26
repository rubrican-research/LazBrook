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
        libPath        : string;
        host           : string;
        port           : DWord;
        lazBrookID     : ProcServerText;
		startServer    : ProcStartServer; // Call start() to store host and port in one call;
		serverRunning  : ProcServerFlag;
		serverName     : ProcServerText;
		serverID       : ProcServerText;
		serverAbout    : ProcServerText;
		serverURL      : ProcServerText;
		serverEndPoints: ProcServerText;
		stopServer     : ProcServerFlag;
        log            : TStringList;
        function isLoaded: boolean;
        procedure init;
        constructor Create;
        destructor Destroy; override;

        // Call start() to start the server
        // This will save the host and port
        function start(_host: string; _port: DWord): boolean;
    end;

    function isLazBrookLib(const _libPath: string): boolean;
    function WebAppLib(const _libPath: string): TWebAppIntf;
    procedure close(constref _intf: TWebAppIntf);


implementation
uses
    fgl;
type
    TWebAppIntfList = class(specialize TFPGMapObject<string, TWebAppIntf>);

var
    webAppIntfs : TWebAppIntfList;


function loadWebAppLib(const _libPath: string): TWebAppIntf;
const
    LAZBROOK_IDV1 = '{B3F543DF-F070-4D0E-8FA2-9849A2B02B73}';
var
	_plibID: pChar;
    _strLibID: shortString;
    _message : string;
begin
    Result := TWebAppIntf.Create;
    Result.libPath := _libPath;

    if FileExists(_libPath) then begin
        Result.Handle  := loadLibrary(_libPath);
        if Result.Handle <> 0 then begin
            Pointer(Result.lazBrookID    )  := GetProcAddress(Result.Handle, 'lazBrookID');
            if not assigned(Result.lazBrookID) then begin
                Result.init;
                Raise Exception.Create(Format('%s is not a LazBrook server library', [_libPath]));
            end
            else begin
                _plibID    := Result.lazBrookID();
                _strLibID := _plibID;
                 //StrDispose(_plibID);
                case _strLibID of
                    LAZBROOK_IDV1: ;
                    else begin
                        Result.init;
                        _message := Format('%d (%s): This version of LazBrook server library is not supported.', [_libPath, _plibID]);
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
            Result := Assigned(GetProcAddress(_handle, 'lazBrookID'));
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
    lazBrookID     := nil;
	startServer    := nil;
	serverRunning  := nil;
	serverName     := nil;
	serverID       := nil;
	serverAbout    := nil;
	serverURL      := nil;
	serverEndPoints:= nil;
	stopServer     := nil;
    log.Clear;
end;

constructor TWebAppIntf.Create;
begin
    inherited;
    log := TStringList.Create;
    init;
end;

destructor TWebAppIntf.Destroy;
begin
    close(self);
    log.Free;
	inherited Destroy;
end;

function TWebAppIntf.start(_host: string; _port: DWord): boolean;
begin
    host := _host;
    port := _port;
    Result := startServer(pChar(host), port);
end;


initialization
    webAppIntfs := TWebAppIntfList.Create(True);

finalization
    webAppIntfs.Free;

end.

