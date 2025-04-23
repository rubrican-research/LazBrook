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
        procedure GetRequestTest;
        procedure PostRequestTest;
    public
        constructor Create;
    end;

implementation

uses
    LCLIntf, sugar.contactInfo;

procedure TTestLazBrookFileSrv.StartServerTest;
begin
    startServer();
    AssertTrue(serverRunning);
    OpenUrl(serverURL);
end;

procedure TTestLazBrookFileSrv.GetRequestTest;
begin

end;

procedure TTestLazBrookFileSrv.PostRequestTest;
begin

end;

constructor TTestLazBrookFileSrv.Create;
begin
    inherited;
    webserver.addRoutes([FileSrvEntryPoint]);
end;

procedure TTestLazBrookFileSrv.SetUp;
begin

end;

procedure TTestLazBrookFileSrv.TearDown;
begin

end;

initialization
    RegisterTest(TTestLazBrookFileSrv);

end.
