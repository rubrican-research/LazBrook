library lazBrookLib;

{$mode objfpc}{$H+}

uses
    Interfaces, Classes, Forms, server.web, server.stub
    { you can add units after this };

{$R *.res}

exports
    server.stub.lazBrookID,
    server.stub.startServer,
    server.stub.serverRunning,
    server.stub.serverName,
    server.stub.serverID,
    server.stub.serverAbout,
    server.stub.serverURL,
    server.stub.serverEndPoints,
    server.stub.stopServer;

initialization
    server.web.ServerName := 'My First WebServer Dll' ;
    server.web.ServerID   := 'V0.0.1' ;
    server.web.serverAbout:= 'If this works, we are in for a treat!!';
end.

