unit testAddresses;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fpcunit, testutils, testregistry, fpJSON;

type

    TTestContactInfo= class(TTestCase)
    private
        persons : TJSONArray;
    protected
        procedure SetUp; override;
        procedure TearDown; override;
    published

    end;

implementation

procedure TTestContactInfo.TestHookUp;
begin
    Fail('Write your own test');
end;

procedure TTestContactInfo.SetUp;
begin

end;

procedure TTestContactInfo.TearDown;
begin

end;

initialization

    RegisterTest(TTestContactInfo);
end.

