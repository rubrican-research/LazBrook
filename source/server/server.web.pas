unit server.web;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, ExtCtrls, Forms, BrookLibraryLoader, BrookMediaTypes,
    BrookURLEntryPoints, BrookURLRouter, BrookHTTPServer, BrookLogger,
    BrookUtility, BrookHTTPResponse, BrookHTTPRequest, route.base, route.home,
    route.filesrv;

const
    BROOKLIB = 'libsagui-3.dll';
    DEFAULT_PORT = 999;

type

    { TWebserver }

    TWebserver = class(TDataModule)
        BrookHTTPServer: TBrookHTTPServer;
        BrookLibraryLoader: TBrookLibraryLoader;
        BrookLogger: TBrookLogger;
        BrookURLEntryPoints: TBrookURLEntryPoints;
		shutdownRouter: TBrookURLRouter;
        procedure BrookHTTPServerRequest(ASender: TObject; ARequest: TBrookHTTPRequest;
            AResponse: TBrookHTTPResponse);
        procedure BrookHTTPServerRequestError(ASender: TObject;
            ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse;
            AException: Exception);
        procedure DataModuleCreate(Sender: TObject);
		procedure shutdownRouterRoutes0Request(ASender: TObject;
			ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
			AResponse: TBrookHTTPResponse);
    private
        function getHost: string;
        function getPort: uint16;
        function getServerRunning: boolean;
        function getServerUrl: string;
        procedure setHost(const _value: string);
        procedure setPort(const _value: uint16);
        procedure setServerRunning(const _value: boolean);
    public
        procedure startServer;
        procedure stopServer;
        procedure EntryPointsActive(_val: boolean);
        function endPoints: TStringArray;
    public
        property Running: boolean read getServerRunning write setServerRunning;
        property host: string read getHost write setHost;
        property port: uint16 read getPort write setPort;
        property serverUrl: string read getServerUrl;
    end;

function serverInitialized: boolean;
function createServer: TWebserver;
procedure destroyServer;

function startServer(const _host: string = ''; _port: word = DEFAULT_PORT): boolean;
function serverRunning: boolean;
function serverURL: string;
function serverEndPoints: string;
procedure stopServer;

var
    Webserver: TWebserver = nil;

    {Identification information about this server}
    ServerName: string;
    ServerID: string;
    serverAbout: string;

implementation

{$R *.lfm}

uses
    LCLIntf, sugar.utils;

var
    BrookLibPath: string = BROOKLIB;

function serverInitialized: boolean;
begin
    Result := assigned(Webserver);
end;

function createServer: TWebserver;
begin
    if not assigned(Webserver) then
    begin
        FilesrvRouter := TFilesrvRouter.Create(Application);
        HomeRouter := THomeRouter.Create(Application);
        WebServer := TWebServer.Create(Application);
    end;
    Result := WebServer;
end;

procedure destroyServer;
begin
    FreeAndNil(FilesrvRouter);
    FreeAndNil(HomeRouter);
    FreeAndNil(WebServer);
end;

function startServer(const _host: string; _port: word): boolean;
begin
    Result := False;
    if not serverInitialized then createServer;

    if Webserver.Running then
    begin
        raise Exception.Create(Format('Server is already running (%s)',
            [Webserver.serverUrl]));
    end;

    WebServer.port := _port;
    WebServer.host := _host;
    Webserver.Running := True;
    OpenURL(Webserver.serverUrl);

end;

function serverRunning: boolean;
begin
    if serverInitialized then
        Result := Webserver.Running
    else
        Result := False;
end;

function serverURL: string;
begin
    if assigned(Webserver) then
        Result := Webserver.serverUrl
    else
        Result := '';
end;

function serverEndPoints: string;
begin
    if assigned(WebServer) then
    begin
        Result := getDelimitedString(WebServer.endPoints, '<br>');
    end
    else
        Result := '';
end;

procedure stopServer;
begin
    if assigned(Webserver) then
        WebServer.Running := False;
end;

{ TWebserver }

procedure TWebserver.BrookHTTPServerRequestError(ASender: TObject;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse; AException: Exception);
begin
    AResponse.Send(
        'ERROR - replace this',
        'text/html',
        404
        );
end;

procedure TWebserver.DataModuleCreate(Sender: TObject);
begin
    setPort(DEFAULT_PORT);
end;

procedure TWebserver.shutdownRouterRoutes0Request(ASender: TObject;
	ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
	AResponse: TBrookHTTPResponse);
begin
    SendHtml(AResponse, '');
    Application.Terminate;
end;

function TWebserver.getHost: string;
begin
    Result := BrookHTTPServer.HostName;
    if Result.isEmpty then Result := 'localhost';
end;

function TWebserver.getPort: uint16;
begin
    Result := BrookHTTPServer.Port;
end;

procedure TWebserver.BrookHTTPServerRequest(ASender: TObject;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    BrookURLEntryPoints.Enter(ASender, ARequest, AResponse);
end;

function TWebserver.getServerRunning: boolean;
begin
    Result := BrookHTTPServer.Active;
end;

function TWebserver.getServerUrl: string;
begin
    Result := Format('http://%s:%d', [host, Port]);
end;

procedure TWebserver.setHost(const _value: string);
begin
    BrookHTTPServer.HostName := _value;
end;

procedure TWebserver.setPort(const _value: uint16);
begin
    BrookHTTPServer.Port := _value;
end;

procedure TWebserver.setServerRunning(const _value: boolean);
begin
    if BrookHTTPServer.Active = _value then exit;
    case _value of
        True: startServer;
        False: stopServer;
    end;
end;

procedure TWebserver.startServer;
begin
    if BrookHTTPServer.Active then exit;

    if BrookLibraryLoader.LibraryName <> BrookLibPath then
    begin
        BrookLibraryLoader.Active := False;
        BrookLibraryLoader.LibraryName := BrookLibPath;
    end;
    BrookLibraryLoader.Active := True;
    BrookHTTPServer.Active := True;
    EntryPointsActive(True);
end;

procedure TWebserver.stopServer;
begin
    BrookHTTPServer.Active := False;
    EntryPointsActive(False);
    //BrookLibraryLoader.Active := False;
end;

procedure TWebserver.EntryPointsActive(_val: boolean);
var
    i: integer;
    _ep: TBrookURLEntryPoint;
begin
    BrookURLEntryPoints.Active := _val;
    for i := 0 to pred(BrookURLEntryPoints.List.Count) do
    begin
        _ep := BrookURLEntryPoints.Items[i];
        if assigned(_ep.Router) then _ep.Router.Active := _val;
    end;
end;

function TWebserver.endPoints: TStringArray;
var
    _asize: integer = 0;
    _i: integer = 0;
    e: TBrookURLEntryPoint;
    r: TBrookURLRoute;
begin
    Result := [];
    for e in BrookURLEntryPoints do
    begin
        _asize := _asize + e.Router.Routes.Count;
        SetLength(Result, _aSize);
        for r in e.Router.Routes do
        begin
            Result[_i] := Format('%s%s%s', [serverUrl, e.Name, r.Pattern]);
            Inc(_i);
        end;
    end;
end;

end.
