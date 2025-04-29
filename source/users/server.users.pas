unit server.users;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fgl, fpjson, sugar.contactInfo;
const
    LZBK = 'LZBK';
    LZBKVER = '01';
    LZBK_ID = LZBK + LZBKVER;
type
    NLazBrookUserStatus = (
        lzbrUserUnknown,
        // The status is unknown. Necessary to identify incorrect initialization.
        lzbrUserOnBoarding,
        // The user is being on boarding. There are many workflows for onboarding.s
        lzbrUserActive,           // The user account is active

        lzbrUserPaused = 150,     // The user is temporarily not allowed to login
        lzbrUserSuspended,        // Incorrect password

        {These values are fixed so you can add more status levels before these.
         Older versions of TLazBrookUserAuth will continue to function correctly when checked for status < lbUserBlocked}
        lzbrUserFlagged = 253,
        // This user account is flagged - you can implement logic to handle different flag
        lzbrUserBlocked = 254, // The user is not allowed to login
        lzbrUserDeleted = 255  // The user has been deleted
        );


    { TLazBrookAuth }

    TLazBrookAuth = class(TJSONObject)
    private
        function getLoginID: string;
        procedure setLoginID(const _value: string);
    published
        property LoginID: string read getLoginID write setLoginID;
    public
        constructor Create; virtual;
    end;

    { TLazBrookUserAuth }

    TLazBrookUserAuth = class(TLazBrookAuth)
    private
        function getAuthStatus: NLazBrookUserStatus;
        function getFlags: string;
		function getIsActive: boolean;
		function getIsOnBoarding: boolean;
        function getPwdHash: string;
        function getSalt: string;
        procedure setAuthStatus(const _value: NLazBrookUserStatus);
        procedure setFlags(const _value: string);
        procedure setPwdHash(const _value: string);
        procedure setSalt(const _value: string);

    published
        property PwdHash: string read getPwdHash write setPwdHash;
        property Salt: string read getSalt write setSalt;
        property AuthStatus: NLazBrookUserStatus read getAuthStatus write setAuthStatus;
        property Flags: string read getFlags write setFlags;
        // For Convenience
        property isOnboarding: boolean read getIsOnBoarding;
        property isActive: boolean read getIsActive; // If false, then we can interrogate AuthStatus to understand why.

        // because string implementation is flexible and future ready.

    public
        constructor Create; override;
    end;

    NLazBrookUserSessionStatus = (
        lzbrUserLoggedOut,
        lzbrUserLoggedIn
        );

    { TLazBrookUserSession }

    TLazBrookUserSession = class(TLazBrookAuth)
    private
        function getExpires: TDateTime;
        function getLastReqAt: TDateTime;
        function getLoginTime: TDateTime;
        function getSessionID: string;
        procedure setExpires(const _value: TDateTime);
        procedure setLastReqAt(const _value: TDateTime);
        procedure setLoginTime(const _value: TDateTime);
        procedure setSessionID(const _value: string);
    published
        property loginID;
        property loginTime: TDateTime read getLoginTime write setLoginTime;
        property lastReqAt: TDateTime read getLastReqAt write setLastReqAt;
        property sessionID: string read getSessionID write setSessionID;
        property expires: TDateTime read getExpires write setExpires;
    public
        constructor Create; override;
        function isActive: boolean;
        procedure reset;
    end;

    TLazBrookUser = class(TContactPersonBasic)
    private
        function getAuth: TLazBrookUserAuth;
        function getloginID: string;
        function getsession: TLazBrookUserSession;
        procedure setAuth(const _value: TLazBrookUserAuth);
        procedure setLoginID(const _value: string);
        procedure setSession(const _value: TLazBrookUserSession);

    published
        property Name;
        property Emails;
        property Phones;

        property LoginID: string read getloginID write setLoginID;
        // Proxy for TLazBrookUserAuth
        property Auth: TLazBrookUserAuth read getAuth write setAuth;
        property Session: TLazBrookUserSession read getsession write setSession;

    public
        constructor Create; override;
        constructor Create(_loginID: string; _name: string = '');
    end;

    { TMapLazBrookUsers }

    TMapLazBrookUsers = class(specialize TFPGMapObject<string, TLazBrookUser>)
        constructor Create(AFreeObjects: boolean);
    end;

    {Implement the kinds of criteria you want to load users on}
    TLazBrookLoadUserCriteria = class(TJSONObject)
    public

    end;

    { TLazBrookPWDHashGen }

    TLazBrookPWDHashGen = class
        function genSalt(_minSize: byte = 128; _maxSize: byte = 255): unicodestring;
        // Generates a salt with length between _minSize and _maxSize;
        function genHash(_pwd: string; _salt: string): unicodestring;
    end;

    { TLazBrookSessionGen }

    TLazBrookSessionGen = class
        function newSession(_usr: TLazBrookUser): TLazBrookUserSession;
    end;

    NLazBrookLogoutState = (
        logout_state_Start,
        logout_state_CheckUserExists,
        logout_state_CheckSessionIDValid,
        logout_state_CheckUserSessionIndex,
        logout_state_CheckUserLoggedIn,
        logout_state_PerformLogout,
        logout_state_Done,
        logout_state_Error
        );

    NLazBrookLogoutResult = (
        logout_result_UserNotExists,
        logout_result_SessionIDEmpty,
        logout_result_SessionIDNotFound,
        logout_result_UserSessionNotAssigned,
        logout_result_UserNotLoggedIn,
        logout_result_LogoutFailed,
        logout_result_OK
        );

    NLazBrookUserOnBoardResult = (
        user_onboarding_Unknown
    );


    TLazBrookUserOnBoarder = class
    protected

    end;

    ELazBrookError = Class(Exception);
    ELazBrookUserExists         = Class(ELazBrookError);
    ELazBrookUserDoesNotExist   = Class(ELazBrookError);
    ELazBrookInvalidLoginID     = Class(ELazBrookError);
    ELazBrookWrongLoginCreds    = Class(ELazBrookError);
    ELazBrookLoginAttemptsExceeded = Class(ELazBrookError);
    ELazBrookInvalidUserSession = Class(ELazBrookError);

    { TLazBrookLoginManager }

    TLazBrookLoginManager = class
    private
        myUserTimeOut: DWord;
        myMaxConcurrentUsers: DWord;
        mylistCriteria   : TLazBrookLoadUserCriteria;
        myUsersByLoginId : TMapLazBrookUsers;
        {These are indices. Only references}
        myUsersBySession : TMapLazBrookUsers;
        myUsersOnBoarding: TMapLazBrookUsers;
        myUsersLoggedIn  : TMapLazBrookUsers;
        myUsersLoggedOut : TMapLazBrookUsers;

        function getmaxConcurrentUsers: word;
        function getuserTimeOut: DWord;
        procedure setmaxConcurrentUsers(const _value: word);
        procedure setuserTimeOut(const _value: DWord);

    public
        function listCriteria: TLazBrookLoadUserCriteria;
        function usersByLoginId: TMapLazBrookUsers;
        function usersBySession: TMapLazBrookUsers;
        function usersOnBoarding: TMapLazBrookUsers;
        function usersLoggedIn  : TMapLazBrookUsers;
        function usersLoggedOut : TMapLazBrookUsers;

        constructor Create(constref _listCriteria: TLazBrookLoadUserCriteria);
        destructor Destroy; override;

        function userExists (const _loginID: string) : boolean;

        function newUser(const _loginID: string): TLazBrookUser;  // Creates a new user and updates indices. Returns false if user already present;
        function addUser(constref _user: TLazBrookUser): boolean; // Adds the user and updates indices. Returns false if user already present;
        function rmUser(constref _user: TLazBrookUser): boolean;  // Removes the user and updates indices. Returns false if user is not already present;

        function user(const _loginID: string): TLazBrookUser;

        {Authentication functions}
        function genPWDHash(_pwd: string; _salt: string): string;
        function isLoggedIn(_loginID: string): boolean;
        function canLogin(_loginID: string): boolean;
        function verifyCredentialsGetUser(const _loginID: string;
            const _pwd: string): TLazBrookUser;
        function doLogin(const _loginID: string; const _pwd: string): boolean;
        function whichUser(const _sessionID: string): TLazBrookUser;
        function doLogout(_loginID: string): NLazBrookLogoutResult;

        {Onboarding functions}
        function onBoard(_user: TLazBrookUser): boolean;
        function isOnboarding(_loginID: string): boolean;
        function getVerificationCode(_loginID: TLazBrookUser): string;
        function verifyCode(_loginID: string; _verificationCode: string): boolean;
        function onBoard(_loginID: string;
            _verificationCode: string): NLazBrookUserOnBoardResult;

        function asJSONObj: TJSONObject;
        function asJSON: string;

        {config values }
    published
        property userTimeOut: DWord read getuserTimeOut write setuserTimeOut;
        property maxConcurrentUsers: word read getmaxConcurrentUsers
            write setmaxConcurrentUsers;
    end;

	{ TLazBrookUserManagerJSON }

    TLazBrookUserManagerJSON = class(TJSONObject)
    protected
        myLzBkUM : TLazBrookLoginManager;
    public
        constructor Create(_lzbrUM: TLazBrookLoginManager);
        function parse(_jsonstr: string): boolean;
	end;



    { TLazBrookStore }
    TLazBrookStoreResult = (
        lzbr_save_Unknown,
        lzbr_save_fail,
        lzbr_save_target_not_found,
        lzbr_save_target_not_ready,
        lzbr_save_target_error,
        lzbr_save_success
        );

    NLazBrookStoreMode = (
        lzbr_store_create,
        lzbr_store_read,
        lzbr_store_write
        );
    SLazBrookStoreModes = set of NLazBrookStoreMode;

    generic TLazBrookStore<LazBrook: TObject> = class
    private
        mymodes: SLazBrookStoreModes;
        mystoreName: string;
        function getModeCreate: boolean;
        function getModeRead: boolean;
        function getModeWrite: boolean;
        procedure setmode(const _value: SLazBrookStoreModes);
        procedure setstoreName(const _value: string);

    protected
        myLazBrookObj: LazBrook; // Only stores the reference

    public
        property storeName: string read mystoreName write setstoreName;
        property modes: SLazBrookStoreModes read mymodes write setmode;
        property modeCreate: boolean read getModeCreate;
        property modeRead: boolean read getModeRead;
        property modeWrite: boolean read getModeWrite;

        constructor Create(constref _LZ: LazBrook; const _storeName: string;
            _modes: SLazBrookStoreModes); virtual;
        function save: TLazBrookStoreResult; virtual;
        function read: LazBrook; virtual;
    end;

    { TLazBrookFileStore }

    generic TLazBrookFileStore<LazBrook: TObject> =
        class(specialize TLazBrookStore<LazBrook>)
    protected
        myFileStream: TFileStream;
    public
        constructor Create(constref _LZ: LazBrook; const _storeName: string;
            _modes: SLazBrookStoreModes); override;
        destructor Destroy; override;
    end;

	{ TStoreLazBrookLoginManager }

    TStoreLazBrookLoginManager = class(specialize TLazBrookFileStore<TLazBrookLoginManager>)
        function save: TLazBrookStoreResult; override;
        function read: TLazBrookLoginManager; override;

    end;


function loadLazBrookUsers(constref _criteria: TLazBrookLoadUserCriteria):
    TLazBrookLoginManager;


implementation

uses
    sugar.utils, Math;

function loadLazBrookUsers(constref _criteria: TLazBrookLoadUserCriteria): TLazBrookLoginManager;
begin
    Result := TLazBrookLoginManager.Create(_criteria);
end;

function validatePWD(_pwd: unicodestring): boolean;
begin

    //Log('TUser.validatePWD:: _pwd: %s', [_pwd]);
    //Log('TUser.validatePWD:: passwordHash: %s', [passWordHash]);
    //Log('TUser.validatePWD:: generatePWDHash: %s', [generatePWDHash(_pwd)]);
    //Log('TUser.validatePWD:: compareResult: %d', [UnicodeCompareStr(generatePWDHash(_pwd), passwordHash)]);

    //Result:= UnicodeCompareStr(generatePWDHash(_pwd), passwordHash) = 0;

end;

{ TLazBrookAuth }

function TLazBrookAuth.getLoginID: string;
begin
    Result := strings['LoginID'];
end;

procedure TLazBrookAuth.setLoginID(const _value: string);
begin
    strings['LoginID'] := _value;
end;

constructor TLazBrookAuth.Create;
begin
    inherited Create;
    strings['LoginID'] := '';
end;

{ TLazBrookUserAuth }

function TLazBrookUserAuth.getAuthStatus: NLazBrookUserStatus;
begin
    Result := NLazBrookUserStatus(integers['AuthStatus']);
end;

function TLazBrookUserAuth.getFlags: string;
begin
    Result := strings['Flags'];
end;

function TLazBrookUserAuth.getIsActive: boolean;
begin
    Result := (authStatus >= lzbrUserActive) and (authStatus < lzbrUserPaused)
end;

function TLazBrookUserAuth.getIsOnBoarding: boolean;
begin
    Result := authStatus = lzbrUserOnBoarding;
end;

function TLazBrookUserAuth.getPwdHash: string;
begin
    Result :=  strings['PwdHash'];
end;

function TLazBrookUserAuth.getSalt: string;
begin
    Result := strings['Salt'];
end;

procedure TLazBrookUserAuth.setAuthStatus(const _value: NLazBrookUserStatus);
begin
    integers['AuthStatus'] := Ord(_value);
end;

procedure TLazBrookUserAuth.setFlags(const _value: string);
begin
    strings['Flags'] := _value;
end;

procedure TLazBrookUserAuth.setPwdHash(const _value: string);
begin
    strings['PwdHash'] := _value;
end;

procedure TLazBrookUserAuth.setSalt(const _value: string);
begin
    strings['Salt'] := _value;
end;

constructor TLazBrookUserAuth.Create;
begin
    inherited Create;
    Strings['PwdHash'] := '';
    Strings['Salt'] := '';
    integers['AuthStatus'] := Ord(lzbrUserUnknown);
    strings['Flags'] := '';
end;

{ TLazBrookUser }

function TLazBrookUser.getAuth: TLazBrookUserAuth;
begin
    Result := TLazBrookUserAuth(objects['Auth']);
end;

function TLazBrookUser.getloginID: string;
begin
    Result := strings['LoginID'];
end;

function TLazBrookUser.getsession: TLazBrookUserSession;
begin
    Result := TLazBrookUserSession(objects['Session']);
end;

procedure TLazBrookUser.setAuth(const _value: TLazBrookUserAuth);
begin
    objects['Auth'] := _value;
end;

procedure TLazBrookUser.setLoginID(const _value: string);
begin
    if _value.isEmpty then
        raise ELazBrookInvalidLoginID.Create('Login id cannot be empty');
    strings['LoginID']  := _value;
    auth.LoginID        := _value;
    session.LoginID     := _value;
end;

procedure TLazBrookUser.setSession(const _value: TLazBrookUserSession);
begin
    objects['Session'] := _value;
end;

constructor TLazBrookUser.Create;
begin
    inherited Create;
    strings['LoginID']  := '';
    objects['Auth']     := TLazBrookUserAuth.Create;
    objects['Session']  := TLazBrookUserSession.Create;
end;

constructor TLazBrookUser.Create(_loginID: string; _name: string);
begin
    Create;
	loginID := _loginID;
    Name    := _name;
end;

{ TMapLazBrookUsers }

constructor TMapLazBrookUsers.Create(AFreeObjects: boolean);
begin
    inherited Create(AFreeObjects);
    sorted := True;
end;

{ TLazBrookPWDHashGen }

function TLazBrookPWDHashGen.genSalt(_minSize: byte; _maxSize: byte): unicodestring;
begin

end;

function TLazBrookPWDHashGen.genHash(_pwd: string; _salt: string): unicodestring;
begin
    Result := UTF8ToString(genHashUTF8(_pwd, _salt, 10000));
end;

{ TLazBrookSessionGen }

function TLazBrookSessionGen.newSession(_usr: TLazBrookUser): TLazBrookUserSession;
begin

end;

{ TLazBrookLoginManager }

function TLazBrookLoginManager.getmaxConcurrentUsers: word;
begin
    Result := myMaxConcurrentUsers;
end;

function TLazBrookLoginManager.getuserTimeOut: DWord;
begin
    Result := myUserTimeOut;
end;

procedure TLazBrookLoginManager.setmaxConcurrentUsers(const _value: word);
begin
    if myMaxConcurrentUsers = _value then exit;
    myMaxConcurrentUsers := _value;
end;

procedure TLazBrookLoginManager.setuserTimeOut(const _value: DWord);
begin
    if myUserTimeOut = _value then exit;
    myUserTimeOut := _value;
end;

function TLazBrookLoginManager.listCriteria: TLazBrookLoadUserCriteria;
begin
    Result := mylistCriteria;
end;

function TLazBrookLoginManager.usersByLoginId: TMapLazBrookUsers;
begin
    Result := myUsersByLoginId;
end;

function TLazBrookLoginManager.usersBySession: TMapLazBrookUsers;
begin
    Result := myUsersBySession;
end;

function TLazBrookLoginManager.usersOnBoarding: TMapLazBrookUsers;
begin
    Result := myUsersOnBoarding;
end;

function TLazBrookLoginManager.usersLoggedIn: TMapLazBrookUsers;
begin
    Result := myUsersLoggedIn;
end;

function TLazBrookLoginManager.usersLoggedOut: TMapLazBrookUsers;
begin
    Result := myUsersLoggedOut;
end;

constructor TLazBrookLoginManager.Create(constref
	_listCriteria: TLazBrookLoadUserCriteria);
begin
    inherited Create;
    mylistCriteria   := _listCriteria;

    myUsersByLoginId := TMapLazBrookUsers.Create(True);
    {These are indices. Only references}
    myUsersBySession := TMapLazBrookUsers.Create(False);
    myUsersOnBoarding:= TMapLazBrookUsers.Create(False);
    myUsersLoggedIn  := TMapLazBrookUsers.Create(False);
    myUsersLoggedOut := TMapLazBrookUsers.Create(False);
end;

destructor TLazBrookLoginManager.Destroy;
begin
    listCriteria.Free;

    usersByLoginId.Free;
    usersBySession.Free;

    usersOnBoarding.Free;
    usersLoggedIn.Free;
    usersLoggedOut.Free;

    inherited Destroy;
end;

function TLazBrookLoginManager.userExists(const _loginID: string): boolean;
begin
    Result := usersByLoginId.IndexOf(_loginID) > -1;
end;

function TLazBrookLoginManager.newUser(const _loginID: string): TLazBrookUser;
begin
    Result := TLazBrookUser.Create;
    Result.loginID:=_loginID;
    Result.Auth.AuthStatus:= lzbrUserOnBoarding;
    try
        addUser(Result);
	except
        on E:Exception do begin
            FreeAndNil(Result);
            raise;
		end;
	end;
end;

function TLazBrookLoginManager.addUser(constref _user: TLazBrookUser): boolean;
var
	_loginID: String;
	_i: Integer;
begin
    _loginID := _user.loginID;
    if userExists(_loginID) then
        raise ELazBrookUserExists.Create(format('TLazBrookLoginManager.NewUser:: user id "%s" already exists',[_loginID]));

    usersByLoginId.KeyData[_loginID] := _user;

    if _user.auth.isOnboarding then
        usersOnBoarding.KeyData[_loginID] := _user;

    if _user.session.isActive then begin
        usersLoggedIn.KeyData[_loginId] := _user;
        usersLoggedOut.remove(_loginID);
	end else begin {Session not active}
        usersLoggedOut.KeyData[_loginId] := _user;
	    usersLoggedIn.Remove(_loginID);
    end;

end;

function TLazBrookLoginManager.rmUser(constref _user: TLazBrookUser): boolean;
var
	_loginID: String;
begin
    _loginID := _user.loginID;

    if not userExists(_loginID) then
        raise ELazBrookUserDoesNotExist.Create(Format('TLazBrookLoginManager.rmUser userID "%s" does not exist', [_user.loginID]));

    if isLoggedIn(_loginID) then doLogout(_loginID);

    usersOnBoarding.remove(_loginID);
    usersLoggedOut.remove(_loginID);
    usersLoggedOut.Remove(_loginID);
    usersByLoginId.Remove(_loginID); // Delete the user from the list

end;

function TLazBrookLoginManager.isLoggedIn(_loginID: string): boolean;
begin
    Result := usersLoggedIn.IndexOf(_loginID) > -1;
end;

type
    {$SCOPEDENUMS ON}
    NStageCheckLogin = (
        undefined,
        userExists,
        isOnboarding,
        isActive,
        done
    );
    {$SCOPEDENUMS OFF}

function TLazBrookLoginManager.canLogin(_loginID: string): boolean;
var
    _user: TLazBrookUser;
    _stage : NStageCheckLogin;
    _error : byte = 0;
begin
    // CHECK 1: Is loginID valid

    _stage := NStageCheckLogin.undefined;

    while _stage < NStageCheckLogin.done do begin
        case _stage of
        	NStageCheckLogin.undefined: begin
                _stage := NStageCheckLogin.userExists;
            end;

            NStageCheckLogin.userExists: begin
                _user := user(_loginID);
                if assigned(_user) then
                    _stage := NStageCheckLogin.isOnboarding
                else begin
                    inc(_error);
                    _stage := NStageCheckLogin.done;
			    end;
            end;

            NStageCheckLogin.isOnboarding: begin

                if _user.Auth.isOnboarding then begin
                    inc(_error);
                    _stage := NStageCheckLogin.done;
                end
                else
                    _stage := NStageCheckLogin.isActive;
            end;

            NStageCheckLogin.isActive: begin
                if not _user.isActive then begin
                    inc(_error);
                    _stage := NStageCheckLogin.done;
                    continue;
                end;

                if not _user.Auth.isActive then
                    inc(_error);
                _stage := NStageCheckLogin.done;
            end;

            NStageCheckLogin.done: begin
                break; // Control won't actually come here because of the while condition.
            end;
        end;
    end;
    Result := _error = 0;

end;

function TLazBrookLoginManager.verifyCredentialsGetUser(const _loginID: string;
    const _pwd: string): TLazBrookUser;
var
    _pwdHash: unicodestring;
begin
{ 1. Extract the user object from loginID into _user/
  2. generate password hash with _pwd and _user.salt and store in _pwdHash
  3. compare _user.pwdHash with _pwdHash. Verified if both are same
  4. Return the retrieved valid user
}

    Result := user(_loginID);
    if not assigned(Result) then exit;

    _pwdHash := genPWDHash(_pwd, Result.auth.Salt);

    if UnicodeCompareStr(_pwdHash, Result.auth.PwdHash) <> 0 then
        Result := nil;

end;

function TLazBrookLoginManager.doLogin(const _loginID: string;
    const _pwd: string): boolean;
var
    _user: TLazBrookUser;
begin
    if isLoggedIn(_loginID) then
        doLogout(_loginID);

    _user := verifyCredentialsGetUser(_loginID, _pwd);
    Result := assigned(_user);
    if Result then
    begin
        {change status of user}
    end;
end;

function TLazBrookLoginManager.user(const _loginID: string): TLazBrookUser;
var
    _i: integer;
begin
    _i := usersByLoginId.IndexOf(_loginID);
    if _i > -1 then
        Result := usersByLoginId.Data[_i]
    else
        Result := nil;
end;

function TLazBrookLoginManager.whichUser(const _sessionID: string): TLazBrookUser;
begin
    Result := usersBySession.KeyData[_sessionID];
end;

//function TLazBrookLoginManager.doLogout(_loginID: string): NLazBrookLogoutState;
//var
//    _user: TLazBrookUser;
//    _sessionID: String;
//    _indexUserBySession, _indexLoggedInUser: Integer;
//begin
//    _user := user(_loginID);
//    Result := Assigned(_user);

//    if Result then begin
//        _sessionID := _user.session.sessionID;
//        Result := Length(_sessionID) > 0
//    end;

//    if Result then begin
//        _indexUserBySession := usersBySession.IndexOf(_sessionID);
//        Result := _indexUserBySession > -1;
//    end;

//    if Result then begin
//        _indexLoggedInUser := usersLoggedIn.IndexOf(_loginID);
//        Result := _indexLoggedInUser > -1;
//    end;

//    if Result then begin
//        _user.session.clear;
//        usersbySession.Delete(_indexUserBySession);
//        usersLoggedIn.Delete(_indexLoggedInUser);
//        usersLoggedOut.Add(_loginId, _user);
//        // make a log entry that the user has logged out.
//    end;
//end;

function TLazBrookLoginManager.genPWDHash(_pwd: string; _salt: string): string;
begin
    Result := genHashUTF8(_pwd, _salt, 30);
end;

function TLazBrookLoginManager.doLogout(_loginID: string): NLazBrookLogoutResult;
var
    state: NLazBrookLogoutState;
    _user: TLazBrookUser;
    _sessionID: string;
    _indexUserBySession, _indexLoggedInUser: integer;
begin
    state := logout_state_Start;
    Result := logout_result_OK;
    while True do
    begin
        case state of

            logout_state_Start: begin
                _user := user(_loginID);
                if Assigned(_user) then
                    state := logout_state_CheckSessionIDValid
                else
                begin
                    state := logout_state_Error;
                    Result := logout_result_UserNotExists;
                end;
            end;

            logout_state_CheckSessionIDValid: begin
                _sessionID := _user.session.sessionID;
                if Length(_sessionID) > 0 then
                    state := logout_state_CheckUserSessionIndex
                else
                begin
                    state := logout_state_Error;
                    Result := logout_result_SessionIDEmpty;
                end;
            end;

            logout_state_CheckUserSessionIndex: begin
                _indexUserBySession := usersBySession.IndexOf(_sessionID);
                if _indexUserBySession > -1 then
                    state := logout_state_CheckUserLoggedIn
                else
                begin
                    state := logout_state_Error;
                    Result := logout_result_SessionIDNotFound;
                end;
            end;

            logout_state_CheckUserLoggedIn: begin
                _indexLoggedInUser := usersLoggedIn.IndexOf(_loginID);
                if _indexLoggedInUser > -1 then
                    state := logout_state_PerformLogout
                else
                begin
                    state := logout_state_Error;
                    Result := logout_result_UserNotLoggedIn;
                end;
            end;

            logout_state_PerformLogout: begin
                _user.session.reset;
                usersBySession.Delete(_indexUserBySession);
                usersLoggedIn.Delete(_indexLoggedInUser);
                usersLoggedOut.Add(_loginID, _user);
                // make a log entry here if needed
                state := logout_state_Done;
            end;

            logout_state_Done: begin
                Break;
            end;

            logout_state_Error: begin
                Break;
            end;

        end;
    end;
end;

function TLazBrookLoginManager.onBoard(_user: TLazBrookUser): boolean;
begin

end;

function TLazBrookLoginManager.isOnboarding(_loginID: string): boolean;
begin

end;

function TLazBrookLoginManager.getVerificationCode(_loginID: TLazBrookUser): string;
begin

end;

function TLazBrookLoginManager.verifyCode(_loginID: string;
    _verificationCode: string): boolean;
begin

end;

function TLazBrookLoginManager.onBoard(_loginID: string;
    _verificationCode: string): NLazBrookUserOnBoardResult;
begin

end;

function TLazBrookLoginManager.asJSONObj: TJSONObject;
begin
    Result := TLazBrookUserManagerJSON.Create(self);
end;

function TLazBrookLoginManager.asJSON: string;
begin
    with asJSONObj do begin
        Result := FormatJSON;
        Free;
	end;
end;

{ TLazBrookUserManagerJSON }

constructor TLazBrookUserManagerJSON.Create(_lzbrUM: TLazBrookLoginManager);
var
	i: Integer;
begin
    inherited Create;
    myLzBkUM := _lzbrUM;
    if not assigned(myLzBkUM) then raise Exception.Create('TLazBrookUserManagerJSON.Create:: LazBrookUserManager is not assigned');
    Strings[LZBK] := LZBK_ID;
    Strings['class'] := ClassName;
    arrays['users'] := TJSONArray.Create;
    for i := 0 to pred(myLzBkUM.usersByLoginId.Count) do
        arrays['users'].Add(myLzBkUM.usersByLoginId.Data[i].Clone);
end;

function TLazBrookUserManagerJSON.parse(_jsonstr: string
	): boolean;
var
    _j: TJSONData;
    _jObj: TJSONObject;
	_className: TJSONStringType;

begin
    Result := False;
 //   _j := parseJSON(_jsonStr);
 //
 //   if _j.JSONType = jtObject then begin
 //       _jObj := TJSONObject(_j);
 //       _className := _jObj.get('class', '');
 //       Result := _className = myLzBkUM.ClassName;
	//end;
 //
 //   if not Result then exit;
 //
 //   // All is good now
 //   Result := copyJSONObject(_jObj, myLzBkUM)
 //
end;

{ TLazBrookStore }

procedure TLazBrookStore.setmode(const _value: SLazBrookStoreModes);
begin
    if mymodes = _value then Exit;
    mymodes := _value;
end;

function TLazBrookStore.getModeCreate: boolean;
begin
    Result := lzbr_store_create in mymodes;
end;

function TLazBrookStore.getModeRead: boolean;
begin
    Result := lzbr_store_read in mymodes;
end;

function TLazBrookStore.getModeWrite: boolean;
begin
    Result := lzbr_store_write in mymodes;
end;

procedure TLazBrookStore.setstoreName(const _value: string);
begin
    if mystoreName = _value then Exit;
    mystoreName := _value;
end;

constructor TLazBrookStore.Create(constref _LZ: LazBrook; const _storeName: string;
    _modes: SLazBrookStoreModes);
begin
    inherited Create;
    myLazBrookObj := _LZ; // Only referene
    storeName := _storeName;
    modes := _modes;
end;

function TLazBrookStore.save: TLazBrookStoreResult;
begin
    // Implement how the object will be saved
    Result := TLazBrookStoreResult.lzbr_save_Unknown;
end;

function TLazBrookStore.read: LazBrook;
begin
    Result := myLazBrookObj;
end;

{ TLazBrookStore }

constructor TLazBrookFileStore.Create(constref _LZ: LazBrook;
	const _storeName: string; _modes: SLazBrookStoreModes);
var
    _fstreamMode:  Word = 0;

begin
    inherited Create(_LZ, _storeName, _modes);

    if modeCreate then
        _fstreamMode := _fstreamMode or fmCreate;

    if modeRead and modeWrite then
        _fstreamMode := _fstreamMode or fmOpenReadWrite
    else if modeWrite then
        _fstreamMode := _fstreamMode or fmOpenWrite
    else
        _fstreamMode := _fstreamMode or fmOpenRead;

    myFileStream := TFileStream.Create(_storeName, _fstreamMode);

end;

destructor TLazBrookFileStore.Destroy;
begin
    myFileStream.Free;
    inherited Destroy;
end;


{ TStoreLazBrookLoginManager }

function TStoreLazBrookLoginManager.save: TLazBrookStoreResult;
begin
    Result := TLazBrookStoreResult.lzbr_save_Unknown;
    if not FileExists(storeName) and not modeCreate then
        raise Exception.Create(Format('"%s".Save():: "%s" does not exist and modeCreate is false.', [ClassName, storeName]));

    myFileStream.WriteAnsiString(myLazBrookObj.asJSON);

end;

function TStoreLazBrookLoginManager.read: TLazBrookLoginManager;
begin
    myFileStream.ReadAnsiString;
end;


{ TLazBrookUserSession }

function TLazBrookUserSession.getExpires: TDateTime;
begin

end;

function TLazBrookUserSession.getLastReqAt: TDateTime;
begin
    Result := TDateTime(Floats['LastReqAt']);
end;

function TLazBrookUserSession.getLoginTime: TDateTime;
begin
    Result := TDateTime(Floats['LoginTime']);
end;

function TLazBrookUserSession.getSessionID: string;
begin
    Result := strings['SessionID'];
end;

procedure TLazBrookUserSession.setExpires(const _value: TDateTime);
begin

end;

procedure TLazBrookUserSession.setLastReqAt(const _value: TDateTime);
begin
    Floats['LastReqAt'] := _value;
end;

procedure TLazBrookUserSession.setLoginTime(const _value: TDateTime);
begin
    Floats['LoginTime'] := _value;
end;

procedure TLazBrookUserSession.setSessionID(const _value: string);
begin
    Strings['SessionID'] := _value;
end;

function TLazBrookUserSession.isActive: boolean;
begin
    Result := not sessionID.IsEmpty;
end;

constructor TLazBrookUserSession.Create;
begin
    inherited Create;
    reset;
end;

procedure TLazBrookUserSession.reset;
begin
    Floats['LoginTime'] := 0;
    Floats['LastReqAt'] := 0;
    Floats['Expires'] := 0;
    Strings['SessionID'] := '';
end;

end.
