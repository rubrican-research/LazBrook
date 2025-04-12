unit testFileSrv;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fpcunit, testutils, testregistry,
    server.web, route.base, route.filesrv;

type

    { TTestLazBrookFileSrv }

    TTestLazBrookFileSrv = class(TTestCase)
    protected
        procedure SetUp; override;
        procedure TearDown; override;
    published
        procedure StartServerTest;
    end;

implementation

uses
    LCLIntf;

procedure TTestLazBrookFileSrv.StartServerTest;
begin
    startServer();
    AssertTrue(serverRunning);
    OpenUrl(serverURL);
end;

function initWebServer(_server: TWebserver): TWebServer;
begin
    Result := _server;
    {Init the routes here}
    _server.addRoutes([FileSrvEntryPoint]);
end;

procedure TTestLazBrookFileSrv.SetUp;
begin
    OnCreateServer := @InitWebserver;
end;

procedure TTestLazBrookFileSrv.TearDown;
begin
    //stopServer;
end;

initialization
    RegisterTest(TTestLazBrookFileSrv);

end.
