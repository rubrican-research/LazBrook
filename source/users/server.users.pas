unit server.users;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fgl, fpjson;

type
    TLazBrookUserStatus = (
        lzbrUserUnkown,     // The status is unknown. Necessary to identify incorrect initialization.
        lzbrUserInvited,
        lzbrUserWaitingVerification,
        lzbrUserActive,           // The user account is active

        lzbrUserPaused = 150,     // The user is temporarily not allowed to login
        lzbrUserSuspended,        // Incorrect password

        {These values are fixed so you can add more status levels before these.
         Older versions of TLazBrookUser will continue to function correctly when checked for status < lbUserBlocked}
        lzbrUserFlagged = 253, // This user account is flagged - you can implement logic to handle different flag
        lzbrUserBlocked = 254, // The user is not allowed to login
        lzbrUserDeleted = 255  // The user has been deleted
    );

 //   TLazBrookUser = class(TJSONObject)
 //       property LoginID : string read getLoginID write setLoginID;
 //       property PwdHash : string read getPwdHash write setPwdHash;
 //       property Status  : read getStatus write setStatus;
 //       property Flags   : string read getFlags write setFlags; // because string implementation is flexible and future ready.
	//end;
 //
 //   TLazBrookUserSessionStatus = (
 //       lzbrUserLoggedOut,
 //       lzbrUserLoggedIn,
 //   );
 //
 //   TLazBrookUserSession = class(TJSONObject)
 //          property LoginID : string read getLoginID write setLoginID;
 //          property loginTime: TDateTime     read getLoginTime write setLoginTime  ;
 //          property lastReqAt: TDateTime     read getLastReqAt write setLastReqAt  ;
 //          property sessionID: string        read getSessionID write setSessionID  ;
 //
 //          function sessionActive: boolean;
 //  	end;
 //
 //   TLazBrookUserInfo = class(TJSONObject)
 //       property LoginID : string read getLoginID write setLoginID;
 //       property Title : string read getTitle write setTitle;
 //       property FirstName : string read getFirstName write setFirstName;
 //       property LastName : string read getLastName write setLastName;
 //       property Phone :
 //       property Email : string read getEmail write setEmail;
 //
	//end;
 //
 //
 //
 //   TLazBrookUserList= class(specialize TFPGMapObject<string, TLazBrookUser>)
 //   end;
 //
 //   TLazBrookUserSessionList= class(specialize TFPGMapObject<string, TLazBrookUserSession>)
 //   end;

implementation

end.

