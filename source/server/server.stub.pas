unit server.stub;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils;
// This function announces that the library is indeed a LazBrook Server Library
// AFter loading the library check if this method exists. If it does, check
// the returned string to correctly identify the library.
function libIdentity: pChar; stdcall;

function startServer (_host: pChar; _port: dword): boolean; stdcall;
function serverRunning: boolean; stdcall;
function serverName: pChar; stdcall;
function serverID: pChar; stdcall;
function serverAbout: pChar; stdcall;
function serverURL: pChar; stdcall;
function serverEndPoints: pChar; stdcall;
function stopServer: boolean; stdcall;

const
    LAZBROOKID = 'LazBrook Server Library V1';

implementation

uses
    server.web, sugar.utils, route.base, route.filesrv, route.home ;

function libIdentity: pChar; stdcall;
begin
    Result := getPChar(LAZBROOKID);
end;

function startServer(_host: pChar; _port: dword): boolean; stdcall;
begin
    Result := false;
    try
        Result    := server.web.startServer(_host, _port);
	except
        on E: Exception do begin
            raise;
        end;
	end;
end;

function serverRunning: boolean; stdcall;
begin
    Result := server.web.serverRunning;
end;

function serverName: pChar; stdcall;
begin
    Result := getPChar(server.web.ServerName);
end;

function serverID: pChar; stdcall;
begin
    Result := getPChar(server.web.ServerID);
end;

function serverAbout: pChar; stdcall;
begin
    Result := getPChar(server.web.serverAbout);
end;

function serverURL: pChar; stdcall;
begin
    Result := getPChar(server.web.serverURL);
end;

function serverEndPoints: pChar; stdcall;
begin
    Result := getPChar(server.web.serverEndPoints);
end;

function stopServer: boolean; stdcall;
begin
    result := serverRunning;
    if Result then begin
        server.web.stopServer;
	end;
end;

end.

