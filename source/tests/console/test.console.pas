unit test.console;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fpcunit, testutils, testregistry;

type

    TLazBrookConsoleTest= class(TTestCase)
    protected
        procedure SetUp; override;
        procedure TearDown; override;
    published
        procedure TestHookUp;
    end;

implementation

procedure TLazBrookConsoleTest.TestHookUp;
begin
    Fail('Write your own test');
end;

procedure TLazBrookConsoleTest.SetUp;
begin

end;

procedure TLazBrookConsoleTest.TearDown;
begin

end;

initialization

    RegisterTest(TLazBrookConsoleTest);
end.

