unit testAddresses;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fpcunit, testutils, testregistry, fpJSON;

type

	{ TTestContactInfo }

    TTestContactInfo= class(TTestCase)
    private
        persons : TJSONArray;
    protected
        procedure SetUp; override;
        procedure TearDown; override;
    public
        constructor Create; override;

    published
        procedure TestContactInfo;
        procedure Test

    end;

implementation

constructor TTestContactInfo.Create;
begin
    Fail('Write your own test');
end;

procedure TTestContactInfo.SetUp;
begin

end;

procedure TTestContactInfo.TearDown;
begin

end;

constructor TTestContactInfo.Create;
begin
	inherited Create;
end;

initialization

    RegisterTest(TTestContactInfo);
end.

