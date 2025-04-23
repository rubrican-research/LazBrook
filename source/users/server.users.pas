unit server.users;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fgl, fpjson, sugar.contactInfo;

type
    NLazBrookUserStatus = (
        lzbrUserUnknown,     // The status is unknown. Necessary to identify incorrect initialization.
        lzbrUserOnBoarding,  // The user is being on boarding. There are many workflows for onboarding.s
        lzbrUserActive,           // The user account is active

        lzbrUserPaused = 150,     // The user is temporarily not allowed to login
        lzbrUserSuspended,        // Incorrect password

        {These values are fixed so you can add more status levels before these.
         Older versions of TLazBrookUserAuth will continue to function correctly when checked for status < lbUserBlocked}
        lzbrUserFlagged = 253, // This user account is flagged - you can implement logic to handle different flag
        lzbrUserBlocked = 254, // The user is not allowed to login
        lzbrUserDeleted = 255  // The user has been deleted
    );


	{ TLazBrookAuth }

    TLazBrookAuth = class(TJSONObject)
	private
		function getLoginID: string;
		procedure setLoginID(const _value: string);
    published
        property LoginID : string read getLoginID write setLoginID;
    public
        constructor Create; virtual;
	end;

	{ TLazBrookUserAuth }

    TLazBrookUserAuth = class(TLazBrookAuth)
	private
		function getAuthStatus: NLazBrookUserStatus;
		function getFlags: string;
		function getPwdHash: string;
		procedure setAuthStatus(const _value: NLazBrookUserStatus);
		procedure setFlags(const _value: string);
		procedure setPwdHash(const _value: string);
    published
        property PwdHash    :  string read getPwdHash write setPwdHash;
        property AuthStatus : NLazBrookUserStatus read getAuthStatus write setAuthStatus;
        property Flags      : string read getFlags write setFlags; // because string implementation is flexible and future ready.
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
		function getLastReqAt: TDateTime;
		function getLoginTime: TDateTime;
		function getSessionID: string;
		procedure setLastReqAt(const _value: TDateTime);
		procedure setLoginTime(const _value: TDateTime);
		procedure setSessionID(const _value: string);
    published
           property loginID;
           property loginTime: TDateTime     read getLoginTime write setLoginTime  ;
           property lastReqAt: TDateTime     read getLastReqAt write setLastReqAt  ;
           property sessionID: string        read getSessionID write setSessionID  ;
    public
        constructor Create; override;
        function sessionActive: boolean;
        procedure clear;
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

        property loginID: string read getloginID write setLoginID; // Proxy for TLazBrookUserAuth
        property auth   : TLazBrookUserAuth read getAuth write setAuth;
        property session: TLazBrookUserSession read getsession write setSession;
    public
        constructor Create; override;
	end;

	{ TMapLazBrookUsers }

    TMapLazBrookUsers = class(specialize TFPGMapObject<string, TLazBrookUser>)
        constructor Create(AFreeObjects: Boolean);
    end;

    {Implement the kinds of criteria you want to load users on}
    TLazBrookLoadUserCriteria = class(TJSONObject)
    public

    end;

    TLazBrookPWDHashGen = class
        function genHash(_pwd: string): string; virtual;
	end;

    TLazBrookPWD


    TLazBrookUsers = class
    private
        myFreeObjects: boolean;
        myUserTimeOut: DWord;
        myMaxConcurrentUsers: DWord;
		function getmaxConcurrentUsers: Word;
		function getuserTimeOut: DWord;
		procedure setmaxConcurrentUsers(const _value: Word);
		procedure setuserTimeOut(const _value: DWord);
    public
        listCriteria  : TLazBrookLoadUserCriteria;
        usersByLoginId: TMapLazBrookUsers;
        usersBySession: TMapLazBrookUsers;

        usersLoggedIn : TMapLazBrookUsers;
        usersLoggedOut: TMapLazBrookUsers;

        constructor Create(AFreeObjects: boolean);
        destructor Destroy; override;

        {Authentication functions}
        function isLoggedIn(_loginID: string) : boolean;
        function canLogin(_loginID: string): boolean;
        function verifyCredentials(const _loginID: string; const _pwd: string) : boolean;
        function doLogin(const _loginID: string; const _pwd: string): boolean;
        function user(const _loginID: string): TLazBrookUser;
        function whichUser(const _sessionID: string): TLazBrookUser;


        {config values }
    published
        property userTimeOut : DWord read getuserTimeOut write setuserTimeOut;
        property maxConcurrentUsers : Word read getmaxConcurrentUsers write setmaxConcurrentUsers;

    end;

    function loadLazBrookUsers(constref _criteria: TLazBrookLoadUserCriteria): TLazBrookUsers;


implementation

function loadLazBrookUsers(constref _criteria: TLazBrookLoadUserCriteria
	): TLazBrookUsers;
begin
    Result := TLazBrookUsers.Create(True);
    Result.listCriteria   := _criteria;
    {Implement the criteria selection here and assign the resulting
    users lists to the member fields}
    Result.usersByLoginId := TMapLazBrookUsers.Create(True);
    Result.usersBySession := TMapLazBrookUsers.Create(false); // Reference to the users maintained in usersByLoginId;
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

function TLazBrookUserAuth.getPwdHash: string;
begin
    Result := strings['PwdHash'];
end;

procedure TLazBrookUserAuth.setAuthStatus(const _value: NLazBrookUserStatus);
begin
    integers['AuthStatus'] := ord(_value);
end;

procedure TLazBrookUserAuth.setFlags(const _value: string);
begin
    strings['Flags']  := _value;
end;

procedure TLazBrookUserAuth.setPwdHash(const _value: string);
begin
    strings['PwdHash']   := _value;
end;

constructor TLazBrookUserAuth.Create;
begin
	inherited Create;
    strings['PwdHash']      := '';
    integers['AuthStatus']   := ord(lzbrUserUnknown);
    strings['Flags']        := '';
end;

{ TLazBrookUser }

function TLazBrookUser.getAuth: TLazBrookUserAuth;
begin
    Result := TLazBrookUserAuth(objects['auth']);
end;

function TLazBrookUser.getloginID: string;
begin
    Result := auth.LoginID;
end;

function TLazBrookUser.getsession: TLazBrookUserSession;
begin
    Result := TLazBrookUserSession(objects['session']);
end;

procedure TLazBrookUser.setAuth(const _value: TLazBrookUserAuth);
begin
    objects['auth'] := _value;
end;

procedure TLazBrookUser.setLoginID(const _value: string);
begin
    auth.LoginID   := _value;
    session.LoginID:= _value;
end;

procedure TLazBrookUser.setSession(const _value: TLazBrookUserSession);
begin
    objects['session'] := _value;
end;

constructor TLazBrookUser.Create;
begin
	inherited Create;
    objects['auth']     := TLazBrookUserAuth.Create;
    objects['session']  := TLazBrookUserSession.Create;
end;

{ TMapLazBrookUsers }

constructor TMapLazBrookUsers.Create(AFreeObjects: Boolean);
begin
    inherited Create(AFreeObjects);
    sorted := true;
end;

{ TLazBrookUsers }

function TLazBrookUsers.getmaxConcurrentUsers: Word;
begin

end;

function TLazBrookUsers.getuserTimeOut: DWord;
begin

end;

procedure TLazBrookUsers.setmaxConcurrentUsers(const _value: Word);
begin

end;

procedure TLazBrookUsers.setuserTimeOut(const _value: DWord);
begin

end;

constructor TLazBrookUsers.Create(AFreeObjects: boolean);
begin
    inherited Create;
    myFreeObjects := AFreeObjects;
end;

destructor TLazBrookUsers.Destroy;
begin
    if myFreeObjects then begin
        listCriteria.Free;
        usersByLoginId.Free;
        usersBySession.Free;
    end;
	inherited Destroy;
end;

function TLazBrookUsers.isLoggedIn(_loginID: string): boolean;
begin

end;

function TLazBrookUsers.canLogin(_loginID: string): boolean;
begin

end;

function TLazBrookUsers.verifyCredentials(const _loginID: string;
	const _pwd: string): boolean;
begin

end;

function TLazBrookUsers.doLogin(const _loginID: string; const _pwd: string
	): boolean;
begin

end;

function TLazBrookUsers.user(const _loginID: string): TLazBrookUser;
begin

end;

function TLazBrookUsers.whichUser(const _sessionID: string): TLazBrookUser;
begin

end;


{ TLazBrookUserSession }

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

function TLazBrookUserSession.sessionActive: boolean;
begin
    Result := not sessionID.IsEmpty;
end;

constructor TLazBrookUserSession.Create;
begin
	inherited Create;
    clear;
end;

procedure TLazBrookUserSession.clear;
begin
    Floats['loginTime'] := 0;
    Floats['lastReqAt'] := 0;
    Strings['sessionID']:= '';
end;

end.

