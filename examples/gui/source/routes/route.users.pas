unit route.users;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, BrookHTTPResponse, BrookHTTPRequest,  BrookURLRouter,
    brookUtility, route.base;

const
    pcreUser = '(?P<user>[\w\-\._@\s]+)'; // creates a named group called "user"

type

	{ TRouteGetUserList }

    TRouteGetUserList = class (TLazBrookURLRoute)
        {@pattern /users/list}
        class function routePattern: string; override;
        procedure doRequest (ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
                 AResponse: TBrookHTTPResponse); override;
        constructor Create(ACollection: TCollection); override;
	end;

	{ TRouteGetUserDetails }

    TRouteGetUserDetails = class (TLazBrookURLRoute)
        {@pattern /users/<pcreUser>/details }
        class function routePattern: string; override;
        procedure doRequest (ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
                 AResponse: TBrookHTTPResponse); override;
        constructor Create(ACollection: TCollection); override;
	end;

	{ TRoutePostDoLogin }

    TRoutePostDoLogin = class (TLazBrookURLRoute)
        {@pattern /users/<pcreUser>/login }
        class function routePattern: string; override;
        procedure doRequest (ASender: TObject; ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
                 AResponse: TBrookHTTPResponse); override;
        constructor Create(ACollection: TCollection); override;
	end;

implementation

uses
    sugar.logger;

{ TRouteGetUserList }

class function TRouteGetUserList.routePattern: string;
begin
	Result:= '/list';
end;

procedure TRouteGetUserList.doRequest(ASender: TObject; ARoute: TBrookURLRoute;
	ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    sendHTML(AResponse, ARoute.Path + 'invoked' );
end;

constructor TRouteGetUserList.Create(ACollection: TCollection);
begin
	inherited Create(ACollection);
    log('TRouteGetUserList.Create');
end;

{ TRouteGetUserDetails }

class function TRouteGetUserDetails.routePattern: string;
begin
    Result := format('/%s/details', [pcreUser]);
end;

procedure TRouteGetUserDetails.doRequest(ASender: TObject;
	ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
	AResponse: TBrookHTTPResponse);
begin
    sendHTML(AResponse, ARoute.Path + 'invoked' );
end;

constructor TRouteGetUserDetails.Create(ACollection: TCollection);
begin
	inherited Create(ACollection);
    log('TRouteGetUserDetails.Create');
end;

{ TRoutePostDoLogin }

class function TRoutePostDoLogin.routePattern: string;
begin
    Result := format('/%s/login', [pcreUser]);
end;

procedure TRoutePostDoLogin.doRequest(ASender: TObject; ARoute: TBrookURLRoute;
	ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    sendHTML(AResponse, ARoute.Path + 'invoked' );
end;

constructor TRoutePostDoLogin.Create(ACollection: TCollection);
begin
	inherited Create(ACollection);
    log('TRoutePostDoLogin.Create');
end;

end.

