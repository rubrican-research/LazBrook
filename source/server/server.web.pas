unit server.web;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, Forms, BrookLibraryLoader, BrookMediaTypes,
	BrookURLEntryPoints, BrookURLRouter, BrookHTTPServer, BrookUtility,
	BrookHTTPResponse, BrookHTTPRequest, BrookHTTPCookies,
	route.base, route.filesrv, server.defines;

type

    { TWebserver }

    TWebserver = class(TDataModule)
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
            ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
            AResponse: TBrookHTTPResponse);
        procedure URLEntryPointsNotFound(ASender: TObject;
            const AEntryPoint, APath: string; ARequest: TBrookHTTPRequest;
            AResponse: TBrookHTTPResponse);
    private
		myerrorPageHtml: string;
        myhomePageHtml: string;
		myinfoPageHtml: string;

		function getErrorPageHtml: string;
		function getHomePageHtml: string;
        function getHost: string;
		function getInfoPageHtml: string;
        function getPort: uint16;
        function getServerRunning: boolean;
        function getServerUrl: string;


		procedure seterrorPageHtml(const _value: string);
        procedure sethomePageHtml(const _value: string);
        procedure setHost(const _value: string);
		procedure setinfoPageHtml(const _value: string);
        procedure setPort(const _value: uint16);
        procedure setServerRunning(const _value: boolean);

    protected
        function initEntryPoint(_entryPoint: string): TBrookURLEntryPoint;
        procedure asychTerminate(_data: PtrInt);
    public
        procedure startServer;
        procedure stopServer;
        procedure EntryPointsActive(_val: boolean);

        {Returns the endpoints server}
        function endPoints: TStringArray;

        function addRoute(_entryPoint: string; constref _routeClass: TBrookURLRouteClass): TBrookURLRoute; overload;
        function addRoute(_entryPoint: string; constref _routeClassArray: array of TBrookURLRouteClass): TWebServer; overload;

        function addRoute(_entryPoint: string; constref _routeFactory: TBrookURLRouteFactory): TBrookURLRoute; overload;
        function addRoute(_entryPoint: string; constref _routeFactoryArray: array of TBrookURLRouteFactory): TWebServer; overload;

        function addRoute(_entryPoint: string; constref _routeFactoryMethod: TBrookURLRouteFactoryMethod): TBrookURLRoute; overload;
        function addRoute(_entryPoint: string; constref _routeFactoryMethodArray: array of TBrookURLRouteFactoryMethod): TWebServer; overload;

        function addRoutes(_appRoutes: TLazBrookRoutes): TWebserver; overload;

        {Sets the default route for an entry point.
        If a default route is already assigned, it will be replaced by the new rout}
        function setDefaultRoute(_entryPoint: string; constref _route: TBrookURLRoute): boolean;

    public
        property Running: boolean read getServerRunning write setServerRunning;
        property host: string read getHost write setHost;
        property port: uint16 read getPort write setPort;
        property serverUrl: string read getServerUrl;

        // Default Pages. Stored as the complete HTML
        property homePageHtml: string read getHomePageHtml write sethomePageHtml;    // HTML for default home page.
        property errorPageHtml: string read getErrorPageHtml write seterrorPageHtml; // HTML Display an error message. Suggest using templates to customize messages
        property infoPageHtml: string read getInfoPageHtml write setinfoPageHtml;    // HTML Display information. Suggest using templates to customize messages.

    end;

    TProcCreateServerHook = function(_server: TWebserver): TWebserver; // Return _server
    TProcDestroyServerHook = function(_server: TWebserver): TWebserver;

function BrookLibPath: string;

function serverInitialized: boolean;
function createServer: TWebserver;
procedure destroyServer(var _webServer: TWebServer);

function startServer(const _host: string = ''; _port: word = DEFAULT_PORT): boolean;
function serverRunning: boolean;
function serverURL: string;
function serverEndPoints: string;
procedure stopServer;

function webServer: TWebServer;
function appPath: string; // Returns the folder of the executable

var
    {Use these to initialize routes when instantiating server}
    OnCreateServer: TProcCreateServerHook = nil;
    OnDestroyServer: TProcDestroyServerHook = nil;

    {Identification information about this server}
    ServerName: string  = 'LazBrook Webserver';
    ServerID: string    = '1.0';
    serverAbout: string = 'An easy-to-use template for creating webserver applications in Lazarus/FPC using Brookframework';

implementation

{$R *.lfm}

uses
    LCLIntf, sugar.utils, sugar.logger, libsagui;

var
    mylibsagui : string = '';
    myWebServer: TWebServer = nil;

function BrookLibPath: string;
begin
    if mylibsagui = '' then begin
        mylibsagui := ExpandFileName(SG_LIB_NAME);
	end;
    result := mylibsagui;
end;

function webServer: TWebServer;
begin
    if not assigned(myWebServer) then
        myWebServer := createServer;
    Result := myWebServer;
end;

var
    myAppPath: string;
function appPath: string;
begin
    if myAppPath.isEmpty then
        myAppPath := ExtractFileDir(Application.ExeName);
    Result := myAppPath;
end;

function serverInitialized: boolean;
begin
    Result := assigned(myWebserver);
end;

function createServer: TWebserver;
begin
    Result := TWebServer.Create(nil);
    Result.homePageHtml := 'LazBrook server is running at ' + Result.serverUrl;
    {You can initialize the server routes etc by attaching an OnCreateServer function}
    if assigned(OnCreateServer) then
        OnCreateServer(Result);
end;

procedure destroyServer(var _webServer: TWebServer);
begin
    if assigned(_webServer) then
    begin
        if assigned(OnDestroyServer) then
            OnDestroyServer(_webServer);

        if _webServer.Running then
            _webServer.stopServer;

        FreeAndNil(_webServer);
    end;
end;

function startServer(const _host: string; _port: word): boolean;
begin
    Result := False;
    if not serverInitialized then
        myWebServer := createServer;

    if serverRunning then
    begin
        raise Exception.Create(Format('Server is already running (%s)',
            [Webserver.serverUrl]));
    end;

    WebServer.port := _port;
    WebServer.host := _host;
    Webserver.Running := True;
    Result := True;
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
    BrookLibraryLoader.LibraryName := BrookLibPath;
    BrookLibraryLoader.Active      := true;
    Log('TWebserver.DataModuleCreate');
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

function TWebserver.getInfoPageHtml: string;
begin

end;


function TWebserver.getErrorPageHtml: string;
begin
    if myerrorPageHtml.isEmpty then
        Result := 'Lazbrook Webserver encountered an error.'
    else
        Result := myerrorPageHtml;
end;

function TWebserver.getHomePageHtml: string;
begin
    if myhomePageHtml.isEmpty then
        Result := 'Lazbrook Webserver is running at ' + serverUrl
    else
        Result := myhomePageHtml;

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
	c: TBrookHTTPCookie;

begin
    log('REQUEST: ' + ARequest.Path);
    URLEntryPoints.Enter(ASender, ARequest, AResponse);
    c := AResponse.Cookies.Find('lazbrookafter');
    if not assigned(c) then begin
        c :=  AResponse.Cookies.Add;
        c.Name := 'lazbrookafter';
	end;
    c.Value := GetTickCount64.ToString;
end;

procedure TWebserver.onHomePage(ASender: TObject; ARoute: TBrookURLRoute;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    SendHtml(AResponse, homePageHtml);
end;

procedure TWebserver.HTTPServerError(ASender: TObject; AException: Exception);
begin
    Log('Lazbrook HTTPServerError:: %s', [AException.Message]);
end;

function TWebserver.getServerRunning: boolean;
begin
    Result := HTTPServer.Active;
end;

function TWebserver.getServerUrl: string;
begin
    if port = 0 then
        Result := Format('http://%s', [host])
    else
        Result := Format('http://%s:%d', [host, Port]);
end;



procedure TWebserver.seterrorPageHtml(const _value: string);
begin
	if myerrorPageHtml=_value then Exit;
	myerrorPageHtml:=_value;
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

procedure TWebserver.setinfoPageHtml(const _value: string);
begin
	if myinfoPageHtml=_value then Exit;
	myinfoPageHtml:=_value;
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


function TWebserver.initEntryPoint(_entryPoint: string): TBrookURLEntryPoint;
var
    _EP: TBrookURLEntryPoint;
    _i: integer;
begin
    {FIND THE ENTRY POINT}
    _i := URLEntryPoints.List.IndexOf(_entryPoint);
    if _i > -1 then
    begin
        _EP := URLEntryPoints.List.Items[_i];
    end
    else
    begin
        _EP         := URLEntryPoints.Add;
        _EP.Name    := _entryPoint;
        _EP.Router  := TBrookURLRouter.Create(HTTPServer);
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
            Result[_i] := Format('%s%s%s', [serverUrl, e.Name, r.Pattern]);
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

            if assigned(_r) then begin
                _r.pattern := _endpoint.regex;
                _r.METHODS := _endpoint.methods;
                if _endpoint.default then
                    setDefaultRoute(_entryPoint.entryPoint, _r)
                else
                    _r.Default:=false;
			end;
		end;
    end;
end;

function TWebserver.setDefaultRoute(_entryPoint: string; constref _route: TBrookURLRoute
	): boolean;
var
    _EP: TBrookURLEntryPoint;
    _router: TBrookURLRouter;
	_defaultRoute: TBrookURLRoute;
begin
    Result := false;
    if Running then
    begin
        raise Exception.Create(
            'Webserver is running. You can only set a route to default when the server is not running');
    end;

    if _entryPoint.isEmpty then exit;
    if not assigned(_route) then exit;

    _EP := initEntryPoint(_entryPoint);
    _router := _EP.Router;
    _defaultRoute := _router.Routes.FindDefault;
    if _defaultRoute <> _route then begin
        if assigned(_defaultRoute) then
            _defaultRoute.Default:=False;
        _route.Default := true;
        Result := true;
	end;
end;

initialization
    //myWebServer := createServer;

finalization
    if serverInitialized then
    begin
        destroyServer(myWebServer);
    end;
end.
