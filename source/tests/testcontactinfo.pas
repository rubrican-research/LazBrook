unit testContactInfo;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fpcunit, testutils, testregistry;

type

    { TTestContactInfo }

    TTestContactInfo = class(TTestCase)
    published
        procedure TestInitContactInfo;
        procedure TestInitContactPhone;
        procedure TestPerson;
    end;

implementation

uses
    sugar.utils, sugar.contactInfo, sugar.logger, fpJson;

procedure TTestContactInfo.TestInitContactInfo;
var
	_c: TContactInfo;
begin
    _c := TContactInfo.Create;
    try
        log('TTestContactInfo.TestInitContactInfo');
        log(_c.FormatJSON());
	finally
        _c.Free;
	end;
end;

procedure TTestContactInfo.TestInitContactPhone;
var
	_c: TContactPhone;
begin
    _c := TContactPhone.Create;
    try
        log('TTestContactInfo.TestInitContactPhone');
        log(_c.FormatJSON());
        _c.countryCode:=91;
        _c.areaCode:=4262;
        _c.number:=261073;
        assert(_c.intPhoneNo = 914262261073, Format('intPhone failed because it is %d',[_c.intPhoneNo]));
        assert(_c.sPhoneNo = '+91 4262 261073');
        log(_c.FormatJSON());
	finally
        _c.Free;
	end;
end;

procedure TTestContactInfo.TestPerson;
var
	_p: TContactPerson;
	s: String;
begin
    _p := TContactPerson.Create;
    try
        {Checking that we can use this properly }
	    _p.Name := 'Stanley Stephen';
	    _p.DOB  := readHtmlDateTime('1972-12-12-');
	    _p.Gender:= 'Man';

	    _p.Emails.named['Home'].Email   := 'stanley.stephen@gmail.com';
	    _p.Emails.named['Office'].Email := 'stanley@rubrican.in';
	    _p.Emails.named['Secret'].Email := 'stanley@jelleo.co';

	    _p.Phones.named['Home'].number      := 919662499436;
	    _p.Phones.named['Office'].number    := 92883928832;

	    _p.Addresses.named['Home'].Line1    := '10/536 Kusumagiri Road';
	    _p.Addresses.named['Home'].Line2    := 'Opp. S. M. Complex';
	    _p.Addresses.named['Home'].City     := 'Gudalur';
	    _p.Addresses.named['Home'].Region   := 'The Nilgiris';
	    _p.Addresses.named['Home'].State    := 'Tamil Nadu';
	    _p.Addresses.named['Home'].Country  := 'India';
	    _p.Addresses.named['Home'].PostCode := '643212';

	    _p.Addresses.named['Office'].Line1    := 'Umbrella Villa';
	    _p.Addresses.named['Office'].Line2    := '';
	    _p.Addresses.named['Office'].City     := 'Tonktonk';
	    _p.Addresses.named['Office'].Region   := 'Burlesque';
	    _p.Addresses.named['Office'].State    := 'Contifesta';
	    _p.Addresses.named['Office'].Country  := 'Gilkonia';
	    _p.Addresses.named['Office'].PostCode := '1224552';

	    log(_p.FormatJSON());
        for s in _p.emails.keys do begin
            case s of
                'Home': ;
                'Office': ;
                'Secret': ;
                else begin
                    Fail('Email Keys: not found "%s"', [s]);
				end;
			end;
		end;

        for s in _p.phones.keys do begin
            case s of
                'Home': ;
                'Office': ;
                else begin
                    Fail('Phone Keys: not found "%s"', [s]);
				end;
			end;
		end;

        for s in _p.addresses.keys do begin
            case s of
                'Home': ;
                'Office': ;
                else begin
                    Fail('Address Keys: not found "%s"', [s]);
				end;
			end;
		end;

	finally
        _p.Free;
	end;

end;



initialization

    RegisterTest(TTestContactInfo);
end.
