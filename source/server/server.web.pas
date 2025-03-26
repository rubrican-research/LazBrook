unit server.web;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, Forms, BrookLibraryLoader, BrookMediaTypes,
    BrookURLEntryPoints, BrookURLRouter, BrookHTTPServer,
    BrookUtility, BrookHTTPResponse, BrookHTTPRequest,
    route.base, route.filesrv,
    server.defines;



type

    { TWebserver }

    TWebserver = class(TDataModule)
        BrookURLRouter1: TBrookURLRouter;
        HTTPServer: TBrookHTTPServer;
        BrookLibraryLoader: TBrookLibraryLoader;
        homeRouter: TBrookURLRouter;
        URLEntryPoints: TBrookURLEntryPoints;
        shutdownRouter: TBrookURLRouter;
        procedure HTTPServerError(ASender: TObject; AException: Exception);
        procedure onHomePage(ASender: TObject; ARoute: TBrookURLRoute;
            ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure HTTPServerRequest(ASender: TObject; ARequest: TBrookHTTPRequest;
            AResponse: TBrookHTTPResponse);
        procedure HTTPServerRequestError(ASender: TObject;
            ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse;
            AException: Exception);
        procedure DataModuleCreate(Sender: TObject);
        procedure DataModuleDestroy(Sender: TObject);
        procedure shutdownRouterRoutes0Request(ASender: TObject;
            ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure URLEntryPointsNotFound(ASender: TObject; const AEntryPoint, APath: string;
            ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
    private
        myhomePageHtml: string;
        function getDownloadPath: string;
        function getHost: string;
        function getPort: uint16;
        function getServerRunning: boolean;
        function getServerUrl: string;
        function getuploadPath: string;
        procedure setDownloadPath(const _value: string);
        procedure sethomePageHtml(const _value: string);
        procedure setHost(const _value: string);
        procedure setPort(const _value: uint16);
        procedure setServerRunning(const _value: boolean);
        procedure setuploadPath(const _value: string);
    protected
        function initEntryPoint(_entryPoint: string): TBrookURLEntryPoint;
        procedure asychTerminate(_data: PtrInt);
    public
        procedure startServer;
        procedure stopServer;
        procedure EntryPointsActive(_val: boolean);
        function endPoints: TStringArray;

        function addRoute(_entryPoint: string;
            constref _routeClass: TBrookURLRouteClass): TBrookURLRoute; overload;
        function addRoute(_entryPoint: string;
            constref _routeClassArray: array of TBrookURLRouteClass): TWebServer; overload;

        function addRoute(_entryPoint: string;
            constref _routeFactory: TBrookURLRouteFactory): TBrookURLRoute; overload;
        function addRoute(_entryPoint: string;
            constref _routeFactoryArray: array of TBrookURLRouteFactory): TWebServer; overload;

        function addRoute(_entryPoint: string;
            constref _routeFactoryMethod: TBrookURLRouteFactoryMethod): TBrookURLRoute; overload;
        function addRoute(_entryPoint: string;
            constref _routeFactoryMethodArray: array of TBrookURLRouteFactoryMethod): TWebServer;
            overload;

        function addRoutes(_appRoutes: TLazBrookRoutes): TWebserver; overload;
    public
        property Running: boolean read getServerRunning write setServerRunning;
        property host: string read getHost write setHost;
        property port: uint16 read getPort write setPort;
        property serverUrl: string read getServerUrl;
        property homePageHtml: string read myhomePageHtml write sethomePageHtml;
        property downloadPath: string read getDownloadPath write setDownloadPath;
        property uploadPath: string read getuploadPath write setuploadPath;
    end;

    TProcCreateServerHook  = function(_server: TWebserver): TWebserver; // Return _server
    TProcDestroyServerHook = function(_server: TWebserver): TWebserver;

function webServer: TWebServer;
function serverInitialized: boolean;
function createServer: TWebserver;
procedure destroyServer;

function startServer(const _host: string = ''; _port: word = DEFAULT_PORT): boolean;
function serverRunning: boolean;
function serverURL: string;
function serverEndPoints: string;
procedure stopServer;

var
    {Use these to initialize routes when instantiating server}
    OnCreateServer: TProcCreateServerHook = nil;
    OnDestroyServer: TProcDestroyServerHook = nil;

    {Identification information about this server}
    ServerName: string   = 'LazBrook Webserver';
    ServerID: string     = '1.0';
    serverAbout: string  = 'An easy-to-use template for creating webserver applications in Lazarus/FPC using Brookframework';

implementation

{$R *.lfm}

uses
    LCLIntf, sugar.utils, sugar.logger;

var
    BrookLibPath: string = BROOKLIB;
    myWebServer: TWebServer = nil;

function webServer: TWebServer;
begin
    if not assigned(myWebServer) then
        Application.CreateForm(TWebServer, myWebServer);
    Result := myWebServer;
end;

function serverInitialized: boolean;
begin
    Result := assigned(myWebserver);
end;

function createServer: TWebserver;
begin
    if not assigned(myWebserver) then
    begin
        myWebServer := TWebServer.Create(nil);
        FilesrvRouter(); // force init

        myWebServer.homePageHtml := 'LazBrook server is running at ' + serverURL;

        if assigned(OnCreateServer) then
            OnCreateServer(myWebServer);

    end;
    Result := myWebServer;
end;

procedure destroyServer;
begin
    if assigned(myWebServer) then
    begin
        if assigned(OnDestroyServer) then
            OnDestroyServer(myWebserver);

        if serverRunning then
            stopServer;

    end;
    FreeAndNil(myWebServer);
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
    Result := true;
    //OpenURL(Webserver.serverUrl);
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
    if serverInitialized then
        WebServer.Running := False;
end;


{ TWebserver }

procedure TWebserver.HTTPServerRequestError(ASender: TObject;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse; AException: Exception);
begin
    AResponse.Send(
        'REQUEST ERROR: ' + ARequest.Path,
        'text/html',
        404
        );
end;

procedure TWebserver.DataModuleCreate(Sender: TObject);
begin
    setPort(DEFAULT_PORT);
    Log('TWebserver.Create');
end;

procedure TWebserver.DataModuleDestroy(Sender: TObject);
begin
    Log('TWebserver.DataModuleDestroy');
end;

procedure TWebserver.shutdownRouterRoutes0Request(ASender: TObject;
    ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    SendHtml(AResponse, '');
    Application.QueueAsyncCall(@asychTerminate, 0);
end;

procedure TWebserver.URLEntryPointsNotFound(ASender: TObject;
    const AEntryPoint, APath: string; ARequest: TBrookHTTPRequest;
    AResponse: TBrookHTTPResponse);
begin
    SendHtml(AResponse, Format('%s/%s was not found', [AEntryPoint, APath]));
end;

function TWebserver.getHost: string;
begin
    Result := HTTPServer.HostName;
    if Result.isEmpty then Result := 'localhost';
end;

function TWebserver.getDownloadPath: string;
begin
    Result := FilesrvRouter.downloadPath;
end;

function TWebserver.getPort: uint16;
begin
    Result := HTTPServer.Port;
end;

procedure TWebserver.HTTPServerRequest(ASender: TObject;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
    ep: TBrookURLEntryPoint;
    r: TBrookURLRoute;
begin
    log('REQUEST: ' + ARequest.Path);
    URLEntryPoints.Enter(ASender, ARequest, AResponse);

    if AResponse.IsEmpty then
        log('   Empty Request: ' + ARequest.Path);

    log('   Looking at routes for /users:');
    ep := URLEntryPoints.List.FindInList('/users');
    if assigned(ep) then
        for r in ep.Router.Routes do
            log('       %s <br>', [r.Pattern]);
end;

procedure TWebserver.onHomePage(ASender: TObject; ARoute: TBrookURLRoute;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    SendHtml(AResponse, homePageHtml);
end;

procedure TWebserver.HTTPServerError(ASender: TObject; AException: Exception);
begin
    Log('HTTPServerError:: %s', [AException.Message]);
end;

function TWebserver.getServerRunning: boolean;
begin
    Result := HTTPServer.Active;
end;

function TWebserver.getServerUrl: string;
begin
    Result := Format('http://%s:%d', [host, Port]);
end;

function TWebserver.getuploadPath: string;
begin
    Result := FilesrvRouter.uploadPath;
end;

procedure TWebserver.setDownloadPath(const _value: string);
begin
    FilesrvRouter.DownloadPath := _value;
end;


procedure TWebserver.sethomePageHtml(const _value: string);
begin
    if myhomePageHtml = _value then Exit;
    myhomePageHtml := _value;
end;

procedure TWebserver.setHost(const _value: string);
begin
    HTTPServer.HostName := _value;
end;

procedure TWebserver.setPort(const _value: uint16);
begin
    HTTPServer.Port := _value;
end;

procedure TWebserver.setServerRunning(const _value: boolean);
begin
    if HTTPServer.Active = _value then exit;
    case _value of
        True: Self.startServer;
        False: Self.stopServer;
    end;
end;

procedure TWebserver.setuploadPath(const _value: string);
begin
    FilesrvRouter.uploadPath := _value;
end;

function TWebserver.initEntryPoint(_entryPoint: string): TBrookURLEntryPoint;
var
    _EP: TBrookURLEntryPoint;
    _router: TBrookURLRouter;
    _i: integer;
begin
    {FIND THE ENTRY POINT}
    _i := URLEntryPoints.List.IndexOf(_entryPoint);
    if _i > -1 then
    begin
        _EP := URLEntryPoints.List.Items[_i];
        _router := _EP.Router;
    end
    else
    begin
        _EP := URLEntryPoints.Add;
        _EP.Name := _entryPoint;
        _router := TBrookURLRouter.Create(HTTPServer);
        _EP.Router := _router;
    end;
    Result := _EP;

end;

procedure TWebserver.asychTerminate(_data: PtrInt);
begin
    Application.ProcessMessages;
    Application.Terminate;
end;

procedure TWebserver.startServer;
begin
    if HTTPServer.Active then exit;

    if BrookLibraryLoader.LibraryName <> BrookLibPath then
    begin
        BrookLibraryLoader.Active := False;
        BrookLibraryLoader.LibraryName := BrookLibPath;
    end;
    BrookLibraryLoader.Active := True;
    HTTPServer.Active := True;
    EntryPointsActive(True);
end;

procedure TWebserver.stopServer;
begin
    HTTPServer.Active := False;
    EntryPointsActive(False);
    //BrookLibraryLoader.Active := False;
end;

procedure TWebserver.EntryPointsActive(_val: boolean);
var
    i: integer;
    _ep: TBrookURLEntryPoint;
begin
    URLEntryPoints.Active := _val;
    for i := 0 to pred(URLEntryPoints.List.Count) do
    begin
        _ep := URLEntryPoints.Items[i];
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
    for e in URLEntryPoints do
    begin
        _asize := _asize + e.Router.Routes.Count;
        SetLength(Result, _aSize);
        for r in e.Router.Routes do
        begin
            Result[_i] := Format('%s%s%s - %s', [serverUrl, e.Name,
                r.Pattern, BoolToStr(e.Router.Active, 'Running', 'off')]);
            Inc(_i);
        end;
    end;
end;

function TWebserver.addRoute(_entryPoint: string;
    constref _routeClass: TBrookURLRouteClass): TBrookURLRoute;
var
    _EP: TBrookURLEntryPoint;
    _router: TBrookURLRouter;
    _i: integer;
    _routePattern: string;
begin
    Result := nil;
    if Running then
    begin
        raise Exception.Create(
            'Webserver is running. You can only add a new route when the server is not running');
    end;
    if _entryPoint.isEmpty then exit;
    if not assigned(_routeClass) then exit;

    _EP := initEntryPoint(_entryPoint);
    _router := _EP.Router;

    {Prep the router}
    if _routeClass.ClassName = TLazBrookURLRoute.ClassName then
    begin
        // Remove if already exists
        _routePattern := TLazBrookURLRoute(_routeClass).routePattern;
        _i := _router.Routes.IndexOf(_routePattern);
        if _i > -1 then
        begin
            try
                _router.Active := False;
                _router.Remove(_routePattern);
            finally
                _router.Active := True;
            end;
        end;
    end;

    Result := _routeClass.Create(_router.Routes); // Adds the new route to the collection

end;

function TWebserver.addRoute(_entryPoint: string;
    constref _routeClassArray: array of TBrookURLRouteClass): TWebServer;
var
    _r: TBrookURLRouteClass;
begin
    Result := self;
    for _r in _routeClassArray do
    begin
        addRoute(_entryPoint, _r);
    end;
end;

function TWebserver.addRoute(_entryPoint: string;
    constref _routeFactory: TBrookURLRouteFactory): TBrookURLRoute;
var
    _EP: TBrookURLEntryPoint;
    _router: TBrookURLRouter;
begin
    Result := nil;
    if Running then
    begin
        raise Exception.Create(
            'Webserver is running. You can only add a new route when the server is not running');
    end;

    if _entryPoint.isEmpty then exit;
    if not assigned(_routeFactory) then exit;

    _EP := initEntryPoint(_entryPoint);
    _router := _EP.Router;

    Result := _routeFactory(_router.Routes);
end;

function TWebserver.addRoute(_entryPoint: string;
    constref _routeFactoryArray: array of TBrookURLRouteFactory): TWebServer;
var
    _r: TBrookURLRouteFactory;
begin
    Result := self;
    for _r in _routeFactoryArray do
    begin
        addRoute(_entryPoint, _r);
    end;
end;

function TWebserver.addRoute(_entryPoint: string;
    constref _routeFactoryMethod: TBrookURLRouteFactoryMethod): TBrookURLRoute;
var
    _EP: TBrookURLEntryPoint;
    _router: TBrookURLRouter;
begin
    Result := nil;
    if Running then
    begin
        raise Exception.Create(
            'Webserver is running. You can only add a new route when the server is not running');
    end;

    if _entryPoint.isEmpty then exit;
    if not assigned(_routeFactoryMethod) then exit;

    _EP := initEntryPoint(_entryPoint);
    _router := _EP.Router;

    Result := _routeFactoryMethod(_router.Routes);
end;

function TWebserver.addRoute(_entryPoint: string;
    constref _routeFactoryMethodArray: array of TBrookURLRouteFactoryMethod): TWebServer;
var
    _r: TBrookURLRouteFactoryMethod;
begin
    Result := self;
    for _r in _routeFactoryMethodArray do
    begin
        addRoute(_entryPoint, _r);
    end;
end;

function TWebserver.addRoutes(_appRoutes: TLazBrookRoutes): TWebserver;
var
    _entryPoint: TEntryPoint;
    _endPoint: TEndpointDef;
    _r: TBrookURLRoute;
begin
    Result := Self;
    for _entryPoint in _appRoutes do
    begin
        for _endPoint in _entrypoint.endpoints do
        begin
            if assigned(_endPoint.routeClass) then
                _r := addRoute(_entryPoint.entryPoint, _endPoint.routeClass)
            else if assigned(_endPoint.routeFactory) then
                _r := addRoute(_entryPoint.entryPoint, _endPoint.routeFactory)
            else if assigned(_endPoint.routeFactoryMethod) then
                _r := addRoute(_entryPoint.entryPoint, _endPoint.routeFactoryMethod)
            else
                continue;
            if assigned(_r) then with _r do
                begin
                    pattern := _endpoint.regex;
                    Default := _endpoint.default;
                    METHODS := _endpoint.methods;
                end;
        end;
    end;
end;


initialization
    createServer;

finalization
    if serverInitialized then
    begin
        destroyServer;
    end;
end.
