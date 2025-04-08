unit route.base;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, BrookURLRouter, BrookHTTPResponse, BrookHTTPRequest,
    BrookURLEntryPoints, BrookUtility, fpjson;

type

    //These factory method pointers allow you to instantiate complex route handlers and then add them to the Entrypoint
    // The way to add the route to the router is to call
    // TRouteClass.Create(_router.Routes); // Adds the new route to the collection. This is how it has been implemented in Brook Framework

    TBrookURLRouteFactory       = function(ACollection: TCollection): TBrookURLRoute;
    TBrookURLRouteFactoryMethod = function(ACollection: TCollection): TBrookURLRoute of object;

    TEndpointDef = record
        regex: string;   // The pattern of the endpoint
        name: string;    // Use this field to store a readable caption for this endpoint
        comment: string; // Docoument the endpoint while defining. You can also use this to generate a list of endpoints implemented by the server
        default: boolean;// Is this the default pattern for the entry point. When multiple Endpoints are marked as default during definition, the last one added is taken. All previous endpoints' default value is set to false.
        methods: TBrookHTTPRequestMethods;
        routeClass: TBrookURLRouteClass;
        routeFactory: TBrookURLRouteFactory;
        routeFactoryMethod: TBrookURLRouteFactoryMethod;
	end;

    TEndpointDefArray =  array of TEndPointDef;

    TEntryPoint = record
        entryPoint: string;
        comment: string;
        endpoints: TEndPointDefArray;
	end;

    TLazBrookRoutes = array of TEntryPoint;

	{ TLazBrookURLRoute }
    TLazBrookURLRoute = class(TBrookURLRoute)
    private
        class var myCount: integer;
    public
        class function routePattern: string virtual; // override this in child classes to indentify the pattern
        constructor Create(ACollection: TCollection); override;
	end;

    { TRouterBase }
    TRouterBase = class(TDataModule)

    end;

	{ TLazBrookCommand }

    TLazBrookCommand = class(TJSONObject)
	private
		mypath: string;
        myEndPoint: string;
		function getEndPoint: string;
		function getRequestMethod: TBrookHTTPRequestMethod;
		function getServerURL: string;
		procedure setEndPoint(const _value: string);
		procedure setpath(const _value: string);
		procedure setRequestMethod(const _value: TBrookHTTPRequestMethod);
    protected
        function getIsWellDefined: boolean; virtual;

    public {CONSTRUCTORS}
        constructor Create; reintroduce;
        constructor Create(const _elements: array of const); reintroduce;
        constructor Build(const _serverURL: string);

    public
        function urlFull: string;
        function urlRel: string;
        function urlStub: string;
        property isWellDefined: boolean read getIsWellDefined;
        property method: TBrookHTTPRequestMethod read getRequestMethod write setRequestMethod;

    published
        property serverURL: string read getServerURL;
        property endPoint: string read getEndPoint write setEndPoint;
        property path: string read mypath write setpath;
        {In child classes, Add specific properties here}

    end;


    function listRoutes(constref router: TBrookURLRouter): TStringArray;
    function aboutRouter(constref router: TBrookURLRouter): string;
    procedure sendHTML(constref AResponse: TBrookHTTPResponse; const _html: string);


implementation
uses
    server.defines;

function listRoutes(constref router: TBrookURLRouter): TStringArray;
var
    r: TBrookURLRoute;
    i: integer = 0;
begin
    Result := [];
    SetLength(Result, router.Routes.Count);
    for r in Router.Routes do
    begin
        Result[i] := r.Pattern;
        Inc(i);
    end;
end;

function aboutRouter(constref router: TBrookURLRouter): string;
var
    r: TBrookURLRoute;
begin
    Result := '';
    for r in Router.Routes do
    begin
        Result := Result + Format('(%s) %s <br>', [r.Path, r.Pattern]);
    end;
end;

procedure sendHTML(constref AResponse: TBrookHTTPResponse; const _html: string);
begin
    AResponse.Send(_html, mimeHTML, 200);
end;

{$R *.lfm}

{ TLazBrookURLRoute }

class function TLazBrookURLRoute.routePattern: string;
begin
    // To avoid any accidental duplicate patterns
    Result := Format('/%s%d', [ClassName, myCount]);
end;

constructor TLazBrookURLRoute.Create(ACollection: TCollection);
begin
	inherited Create(ACollection);

    {This handles the case where pattern already exists in routes.
    Apply a default value that is unique}
    inc(myCount);
    try
        pattern := routePattern{which can be overriden in child classes}
    except
        pattern := Format('/%s%d', [ClassName, myCount])
    end;
end;

{ TLazBrookCommand }

function TLazBrookCommand.getEndPoint: string;
begin
    Result := myEndPoint;
end;

function TLazBrookCommand.getIsWellDefined: boolean;
begin
    Result := false;
end;

const
  CMD_CREATE_ERROR =
            'TLazBrookCommand is not designed to be used as a regular JSONObject. ' + sLineBreak +
		    'You need to define parameters of your command and ensure that isWellFormed returns true before generating command urls.'+ sLineBreak +
		    ''+ sLineBreak +
		    'Call Build() constructor to start';

constructor TLazBrookCommand.Create;
begin
    raise Exception.Create(CMD_CREATE_ERROR);
end;

constructor TLazBrookCommand.Create(const _elements: array of const);
begin
    raise Exception.Create(CMD_CREATE_ERROR);

end;

constructor TLazBrookCommand.Build(const _serverURL: string);
begin
    inherited Create(['serverURL', _serverURL]);
end;

function TLazBrookCommand.getRequestMethod: TBrookHTTPRequestMethod;
begin

end;

function TLazBrookCommand.getServerURL: string;
begin
    Result := strings['serverURL'];
end;

procedure TLazBrookCommand.setEndPoint(const _value: string);
begin
    if myEndPoint = _value then exit;
    myEndPoint := _value;
end;

procedure TLazBrookCommand.setpath(const _value: string);
begin
	if mypath=_value then Exit;
	mypath:=_value;
end;

procedure TLazBrookCommand.setRequestMethod(
	const _value: TBrookHTTPRequestMethod);
begin

end;


function TLazBrookCommand.urlFull: string;
begin

end;

function TLazBrookCommand.urlRel: string;
begin

end;

function TLazBrookCommand.urlStub: string;
begin

end;







end.
