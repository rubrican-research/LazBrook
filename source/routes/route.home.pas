unit route.home;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
    route.base, BrookURLRouter, BrookHTTPResponse, BrookHTTPRequest;

type

    { THomeRouter }

    THomeRouter = class(TDataModule)
        router: TBrookURLRouter;
        api1router: TBrookURLRouter;
		procedure api1routerRoute(ASender: TObject; const ARoute: string;
			ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure onOne(ASender: TObject; ARoute: TBrookURLRoute;
            ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure onTwo(ASender: TObject; ARoute: TBrookURLRoute;
            ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure onAbout(ASender: TObject; ARoute: TBrookURLRoute;
            ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure onDefault(ASender: TObject; ARoute: TBrookURLRoute;
            ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
    private

    public

    end;

var
    HomeRouter: THomeRouter;

implementation

{$R *.lfm}

uses
    server.stub, sugar.logger;

    { THomeRouter }

procedure THomeRouter.onDefault(ASender: TObject; ARoute: TBrookURLRoute;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
    _endPoints: PChar;
    _html: string;
begin
    _endPoints := server.stub.serverEndPoints;
    _html := 'Welcome Home! <br><br>' + ARoute.Path + '<br><br>' + _endPoints;
    StrDispose(_endPoints);
    sendHTML(AResponse, _html);
end;

procedure THomeRouter.onAbout(ASender: TObject; ARoute: TBrookURLRoute;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    sendHTML(AResponse, aboutRouter(router));
end;

procedure THomeRouter.onOne(ASender: TObject;
    ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    SendHtml(AResponse, 'One >> <br><br>' + ARequest.Path);
end;

procedure THomeRouter.api1routerRoute(ASender: TObject; const ARoute: string;
	ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    AResponse.SetCookie('Trial','And Error');
    Log('THomeRouter.api1routerRoute:: route: %s',[ARoute]);
end;

procedure THomeRouter.onTwo(ASender: TObject;
    ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    SendHtml(AResponse, 'Two <br><br>' + ARoute.Path);
    Log('THomeRouter.api1routerRoutes2Request: %s', [ARoute.Path]);
end;

end.
