unit test.gui;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fpcunit, testutils, testregistry;

type

    TLazBrookTest= class(TTestCase)
    protected
        procedure SetUp; override;
        procedure TearDown; override;
    published
        procedure TestHookUp;
    end;

implementation

procedure TLazBrookTest.TestHookUp;
begin
    Fail('Write your own test');
end;

procedure TLazBrookTest.SetUp;
begin

end;

procedure TLazBrookTest.TearDown;
begin

end;

initialization

    RegisterTest(TLazBrookTest);
end.

