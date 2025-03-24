unit route.base;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, BrookURLRouter, BrookHTTPResponse, BrookHTTPRequest,
    BrookURLEntryPoints;

type
    { TRouterBase }
    TRouterBase = class(TDataModule)


    end;

    function routes(constref router: TBrookURLRouter): TStringArray;
    function aboutRouter(constref router: TBrookURLRouter): string;
    procedure sendHTML(constref AResponse: TBrookHTTPResponse; const _html: string);


implementation

function routes(constref router: TBrookURLRouter): TStringArray;
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
    AResponse.Send(_html, 'text/html', 200);
end;

{$R *.lfm}







end.
