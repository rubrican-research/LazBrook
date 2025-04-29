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
        procedure TestAddPerson;
        procedure TestSaltAndPWDHash;
        procedure TestUserLoginSession;
        procedure TestUserSessionValid;
        procedure TestUserSessionInvalid;
        procedure TestUserSessionTimeOut;
        procedure TestJSONLib2;
    end;

implementation

uses
    sugar.utils, sugar.contactInfo, sugar.logger, sugar.securesalt, sugar.maps, fpJson, server.users,
    Math, sugar.jsonlib ;

function genPWDHash(_pwd: unicodestring; _salt: unicodestring): unicodestring;
begin
    Result := genHashUTF8(_pwd, _salt, 30);
end;


function newPerson: TLazBrookUser;
begin
    Result := TLazBrookUser.Create;
    with Result do begin
        createdOn:= Now;
        loginID  := genRandomKey(8);
        Name     := genRandomKey(12) + ' ' + genRandomKey(5);
        Emails.named['office'].Email:= genRandomKey(4) + '@' + genRandomKey(7) + '.' + genRandomKey(3);
	end;
end;

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

procedure TTestContactInfo.TestAddPerson;
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

procedure TTestContactInfo.TestSaltAndPWDHash;
var
    users: TMapLazBrookUsers;
	u: TLazBrookUser;
    pwds : TStringMap;
	i: Integer;
	pwd: String;
	tmpHash: unicodestring;

begin
    {Tests the check of login credentials using pwdHash}

    users := TMapLazBrookUsers.Create(true);
    pwds  := TStringMap.Create;
    try
        // STEP 1
        // Create Users, List of user=>passwords and generate password hash from salt.
        for i := 0 to 10 do begin
	        u := newPerson;
	        // password
	        pwds.KeyData[u.loginID] := genRandomKey(16);
	        u.auth.salt   := genSecureSalt();
	        u.auth.PwdHash:= genPWDHash(pwds.KeyData[u.loginID], u.auth.salt);
	        users.Add(u.loginID, u);
            log('%d. added user: %s', [i,u.loginID]);
		end;
        // STEP 2:
        // Check passwords against pwdHash and salt stored with the user
        for i := 0 to pred(users.Count) do begin
            u := users.Data[i];
            pwd := pwds.KeyData[u.loginID];
            tmpHash := genPWDHash(pwds.KeyData[u.loginID], u.auth.salt);
            Assert(UnicodeCompareStr(tmpHash, u.auth.PwdHash) = 0);
            log('password match for user: %s', [u.loginID]);
		end;

	finally
        pwds.Free;
        users.Free;
	end;
end;

procedure TTestContactInfo.TestUserLoginSession;
var
    users : TLazBrookLoginManager;
begin
    users := TLazBrookLoginManager.Create(nil);
    try
        users.addUser(newPerson);
        users.addUser(newPerson);
        users.addUser(newPerson);
        users.addUser(newPerson);
        users.addUser(newPerson);
        users.addUser(newPerson);
        log(users.asJSON());

	finally
        users.Free;
	end;
end;

procedure TTestContactInfo.TestUserSessionValid;
begin

end;

procedure TTestContactInfo.TestUserSessionInvalid;
begin

end;

procedure TTestContactInfo.TestUserSessionTimeOut;
begin

end;

procedure TTestContactInfo.TestJSONLib2;
var
    o1, o2: TJSONObject;
	i: Integer;
begin
    for i := 0 to 49 do begin
	    o1 := newJSONRandomObj();
        log('ITERATION %d', [i]);
	    log(o1.formatJSON);
	    log('');
	    log('');
	    o2 := TJSONObject.Create;
	    try
		    AssertFalse('The two objects are not different', o1.formatJson = o2.FormatJson);
		    AssertTrue('JSONObject copy did not succeed', copyJSONObject(o1, o2));
		    AssertTrue('The two objects are different after copying', o1.formatJson = o2.FormatJson);
		finally
	    	o1.Free;
	        o2.Free;
		end;
	end;
end;

initialization
    Randomize;
    RegisterTest(TTestContactInfo);
end.
