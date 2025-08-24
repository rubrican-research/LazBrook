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
        procedure TestAddUsers;
        procedure TestClearLoginManager;
        procedure TestCannotLoginOnboardingUsers;
        procedure TestCanLoginActiveUsers;
        procedure TestInvalidLoginCredentials;
        procedure TestUserSessionTimeOut;
        procedure TestJSONLib2;
    end;

implementation

uses
    sugar.utils, sugar.contactInfo, sugar.logger, sugar.securesalt,
    sugar.maps, fpJson, server.users,
    Math, sugar.jsonlib;

function genPWDHash(_pwd: unicodestring; _salt: unicodestring): unicodestring;
begin
    Result := genHashUTF8(_pwd, _salt, 30);
end;


function newPerson: TLazBrookUser;
begin
    Result := TLazBrookUser.Create;
    with Result do
    begin
        Result.Auth.AuthStatus := lzbrUserActive;
        createdOn := Now;
        loginID := genRandomKey(8);
        Name := genRandomKey(12) + ' ' + genRandomKey(5);
        Emails.named['office'].Email :=
            genRandomKey(4) + '@' + genRandomKey(7) + '.' + genRandomKey(3);
    end;
end;

function loadLoginManager: TLazBrookLoginManager;
var
	_user: TLazBrookUser;
begin
    {Password is same as Name}
    Result := TLazBrookLoginManager.Create(nil);
    with Result.newUser('rose') do begin
        Name := 'Rose Carter';
        auth.AuthStatus := lzbrUserActive;
        auth.salt := genSecureSalt();
        auth.PwdHash := genPWDHash(Name, auth.salt);
	end;

	with Result.newUser('jasmine') do begin
        Name := 'Jasmine Jha';
        auth.AuthStatus := lzbrUserActive;
        auth.salt := genSecureSalt();
        auth.PwdHash := genPWDHash(Name, auth.salt);
	end;

    with Result.newUser('lily') do begin
        Name := 'Lily Potter';
        auth.AuthStatus := lzbrUserActive;
        auth.salt := genSecureSalt();
        auth.PwdHash := genPWDHash(Name, auth.salt);
	end;

    with Result.newUser('marigold') do begin
        Name := 'Marigold Guduru';
        auth.AuthStatus := lzbrUserActive;
        auth.salt := genSecureSalt();
        auth.PwdHash := genPWDHash(Name, auth.salt);
	end;

    with Result.newUser('dhalia') do begin
        Name := 'Salvador Dali';
        auth.AuthStatus := lzbrUserActive;
        auth.salt := genSecureSalt();
        auth.PwdHash := genPWDHash(Name, auth.salt);
	end;

    with Result.newUser('sunflower') do begin
        Name := 'Solar Plexus';
        auth.AuthStatus := lzbrUserActive;
        auth.salt := genSecureSalt();
        auth.PwdHash := genPWDHash(Name, auth.salt);
	end;

    with Result.newUser('honeysuckle') do begin
        Name := 'Huckleberry Finn';
        auth.AuthStatus := lzbrUserActive;
        auth.salt := genSecureSalt();
        auth.PwdHash := genPWDHash(Name, auth.salt);
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
        _c.countryCode := 91;
        _c.areaCode := 4262;
        _c.number := 261073;
        assert(_c.intPhoneNo = 914262261073,
            Format('intPhone failed because it is %d', [_c.intPhoneNo]));
        assert(_c.sPhoneNo = '+91 4262 261073');
        log(_c.FormatJSON());
    finally
        _c.Free;
    end;
end;

procedure TTestContactInfo.TestAddPerson;
var
    _p: TContactPerson;
    s: string;
begin
    _p := TContactPerson.Create;
    try
        {Checking that we can use this properly }
        _p.Name := 'Stanley Stephen';
        _p.DOB := readHtmlDateTime('1972-12-12-');
        _p.Gender := 'Man';

        _p.Emails.named['Home'].Email := 'stanley.stephen@gmail.com';
        _p.Emails.named['Office'].Email := 'stanley@rubrican.in';
        _p.Emails.named['Secret'].Email := 'stanley@jelleo.co';

        _p.Phones.named['Home'].number := 919662499436;
        _p.Phones.named['Office'].number := 92883928832;

        _p.Addresses.named['Home'].Line1 := '10/536 Kusumagiri Road';
        _p.Addresses.named['Home'].Line2 := 'Opp. S. M. Complex';
        _p.Addresses.named['Home'].City := 'Gudalur';
        _p.Addresses.named['Home'].Region := 'The Nilgiris';
        _p.Addresses.named['Home'].State := 'Tamil Nadu';
        _p.Addresses.named['Home'].Country := 'India';
        _p.Addresses.named['Home'].PostCode := '643212';

        _p.Addresses.named['Office'].Line1 := 'Umbrella Villa';
        _p.Addresses.named['Office'].Line2 := '';
        _p.Addresses.named['Office'].City := 'Tonktonk';
        _p.Addresses.named['Office'].Region := 'Burlesque';
        _p.Addresses.named['Office'].State := 'Contifesta';
        _p.Addresses.named['Office'].Country := 'Gilkonia';
        _p.Addresses.named['Office'].PostCode := '1224552';

        log(_p.FormatJSON());
        for s in _p.emails.keys do
        begin
            case s of
                'Home': ;
                'Office': ;
                'Secret': ;
                else
                begin
                    Fail('Email Keys: not found "%s"', [s]);
                end;
            end;
        end;

        for s in _p.phones.keys do
        begin
            case s of
                'Home': ;
                'Office': ;
                else
                begin
                    Fail('Phone Keys: not found "%s"', [s]);
                end;
            end;
        end;

        for s in _p.addresses.keys do
        begin
            case s of
                'Home': ;
                'Office': ;
                else
                begin
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
    pwds: TStringMap;
    i: integer;
    pwd: string;
    tmpHash: unicodestring;
begin
    {Tests the check of login credentials using pwdHash}

    users := TMapLazBrookUsers.Create(True);
    pwds := TStringMap.Create;
    try
        // STEP 1
        // Create Users, List of user=>passwords and generate password hash from salt.
        for i := 0 to 10 do
        begin
            u := newPerson;
            // password
            pwds.KeyData[u.loginID] := genRandomKey(16);
            u.auth.salt := genSecureSalt();
            u.auth.PwdHash := genPWDHash(pwds.KeyData[u.loginID], u.auth.salt);
            users.Add(u.loginID, u);
            log('%d. added user: %s', [i, u.loginID]);
        end;
        // STEP 2:
        // Check passwords against pwdHash and salt stored with the user
        for i := 0 to pred(users.Count) do
        begin
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

procedure TTestContactInfo.TestAddUsers;
var
    users: TLazBrookLoginManager;
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

procedure TTestContactInfo.TestClearLoginManager;
var
	um: TLazBrookLoginManager;
    s1, s2 : string;
begin
    um := loadLoginManager;
    try
	    s1 := um.asJSON;
	    log ('TTestContactInfo.TestClearLoginManager');
        log('S1');
        log(s1);
        log('');
	    um.reset;
	    s2 := um.asJSON;
        log('S2');
        log(s2);
        log('');
	    Assert(s1 <> s2, 'Reset did not work as expected. The resulting json should be different');
	finally
        um.Free;
	end;
end;

procedure TTestContactInfo.TestCannotLoginOnboardingUsers;
var
    users: TLazBrookLoginManager;
	i: Integer;
	_user: TLazBrookUser;
	_reason: NLazBrookCanLoginResult;
begin
    users := TLazBrookLoginManager.Create(nil);
    try
        users.newUser('rose').Name:= 'Rose Carter';
        users.newUser('jasmine').Name := 'Jasmine Jha';
        users.newUser('lily').Name := 'Lily Potter';
        users.newUser('marigold').Name := 'Marigold Guduru';
        users.newUser('dhalia').Name := 'Salvador Dali';
        users.newUser('sunflower').Name := 'Solar Plexus';
        users.newUser('honeysuckle').Name := 'Huckleberry Finn';
        log(users.asJSON());

        for i := 0 to pred(users.count) do begin
            _user := users.Items[i];
            AssertFalse(Format('User %s cannot login',[_user.LoginID]), users.canLogin(_user.LoginID, _reason));
		end;
    finally
        users.Free;
    end;
end;

procedure TTestContactInfo.TestCanLoginActiveUsers;
var
	um: TLazBrookLoginManager;
	i, _countUsers, _countSessions, _countLoggedIn, _countLoggedOut: Integer;
	_usr: TLazBrookUser;
	_reason: NLazBrookCanLoginResult;
	_loginResult: NLazBrookUserLoginStatus;
begin
    um := loadLoginManager;

    try
        // Checking if users can login
        for i := 0 to pred(um.count) do begin
            _usr := um.Items[i];
            Assert(um.canLogin(_usr.LoginID, _reason), Format('user "%s" cannot login because reason is %d', [_usr.LoginID, ord(_reason)]) );
		end;

        // Check if the number of users in lists are correct
        _countUsers := um.usersByLoginId.count;
        _countSessions  := um.usersBySession.count;
        _countLoggedIn  := um.usersLoggedIn.Count;
        _countLoggedOut := um.usersLoggedOut.Count;

        Assert(_countUsers = _countLoggedOut, 'COUNT CHECK1 1');
        Assert(_countLoggedIn = 0, 'COUNT CHECK1 2');
        Assert(_countSEssions = 0, 'COUNT CHECK1 3');

        // Checking Login Logic
        for i := 0 to pred(um.count) do begin
            _usr := um.Items[i];
            Assert(um.doLogin(_usr.loginID, _usr.Name) = ulsLoggedIn, Format('%s could not login',[_usr.loginID]));
        end;

        _countSessions  := um.usersBySession.count;
        _countLoggedIn  := um.usersLoggedIn.Count;
        _countLoggedOut := um.usersLoggedOut.Count;

        Assert(_countUsers = _countLoggedIn, 'COUNT CHECK2 1');
        Assert(_countLoggedOut = 0, 'COUNT CHECK2 2');
        Assert(_countSessions = _countLoggedIn, 'COUNT CHECK2 3');


        {Check login Expiree logic}
        for i := 0 to pred(um.count) do begin
            _usr := um.Items[i];
            _usr.Session.expires :=_usr.Session.loginTime;
            sleep(100);
            _loginResult := um.doLogin(_usr.loginID, _usr.Name);
            Assert(_loginResult = ulsTimedOut, Format('%s is not timedout',[_usr.loginID]));
		end;

        _countSessions  := um.usersBySession.count;
        _countLoggedIn  := um.usersLoggedIn.Count;
        _countLoggedOut := um.usersLoggedOut.Count;

        Assert(_countUsers = _countLoggedOut, 'COUNT CHECK3 1');
        Assert(_countLoggedIn = 0, 'COUNT CHECK3 2');
        Assert(_countSessions = 0, 'COUNT CHECK3 3');

        // Checking if users are logged in after time out
        for i := 0 to pred(um.count) do begin
            _usr := um.Items[i];
            Assert(um.getLoginStatus(_usr.loginID) = ulsLoggedOut,   Format('%s is not logged out after timeout',[_usr.loginID]));
		end;

        // checking if users can logout. They should not be because they timed out and were automatically logged out
        for i := 0 to pred(um.count) do begin
            _usr := um.Items[i];
            Assert(um.doLogout(_usr.loginID) = logout_result_UserNotLoggedIn,    Format('%s is could not logout because %d',[_usr.loginID, ord(_usr.Session.loginStatus)]));
		end;

        _countSessions  := um.usersBySession.count;
        _countLoggedIn  := um.usersLoggedIn.Count;
        _countLoggedOut := um.usersLoggedOut.Count;

        Assert(_countUsers = _countLoggedOut, 'COUNT CHECK4 1');
        Assert(_countLoggedIn = 0, 'COUNT CHECK4 2');
        Assert(_countSessions = 0, 'COUNT CHECK4 3');

        // Checking invalid credentials
        assert(um.doLogin('rose', 'Do not log in') = ulsWrongCredentials,  'WRONG CREDENTIALS 1');
        assert(um.doLogin('rose', 'Do not log in') = ulsWrongCredentials,  'WRONG CREDENTIALS 2');
        assert(um.doLogin('rose', 'Do not log in') <> ulsWrongCredentials, 'WRONG CREDENTIALS 3');
        assert(um.doLogin('rose', 'Do not log in') = ulsExceededRetries,   'WRONG CREDENTIALS 4');

        assert(um.doLogin('jasmine', 'Do not log in') = ulsWrongCredentials,  'WRONG CREDENTIALS 5');
        assert(um.user('jasmine').Auth.AttemptsRemaining = 2,  'WRONG CREDENTIALS 5.1');
        assert(um.doLogin('jasmine', 'Do not log in') = ulsWrongCredentials,  'WRONG CREDENTIALS 6');
        assert(um.user('jasmine').Auth.AttemptsRemaining = 1,  'WRONG CREDENTIALS 5.1');
        assert(um.doLogin('jasmine', 'Do not log in') = ulsExceededRetries,  'WRONG CREDENTIALS 7');
        assert(um.user('jasmine').Auth.AttemptsRemaining = 0,  'WRONG CREDENTIALS 7.1');


	finally
        um.Free;
	end;
end;


procedure TTestContactInfo.TestInvalidLoginCredentials;
begin

end;

procedure TTestContactInfo.TestUserSessionTimeOut;
begin

end;

procedure TTestContactInfo.TestJSONLib2;
var
    o1, o2: TJSONObject;
    i: integer;
begin
    for i := 0 to 49 do
    begin
        o1 := newJSONRandomObj();
        log('ITERATION %d', [i]);
        log(o1.formatJSON);
        log('');
        log('');
        o2 := TJSONObject.Create;
        try
            if o1.Count = 0 then continue;
            AssertFalse('The two objects are not different', o1.formatJson = o2.FormatJson);
            AssertTrue('JSONObject copy did not succeed', copyJSONObject(o1, o2));
            AssertTrue('The two objects are different after copying',
                o1.formatJson = o2.FormatJson);
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
