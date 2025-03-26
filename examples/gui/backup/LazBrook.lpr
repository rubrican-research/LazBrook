program LazBrook;

{$mode objfpc}{$H+}

uses
	 {$IFDEF UNIX}
	 cthreads,
	 {$ENDIF}
	 {$IFDEF HASAMIGA}
	 athreads,
	 {$ENDIF}
	 Interfaces, // this includes the LCL widgetset
     LCLIntf,
	 Forms, sugar.logger, server.web, page.home, pages, form.main, config.routes,
	 route.users, page.template;

{$R *.res}

procedure initWebServer;
begin
    server.web.serverName  := 'QATree User Module';
    server.web.serverID    := 'V1.0';
    server.web.serverAbout := 'This microserver handles user authentication, user management';
    {Init routes for this server}
    webServer.addRoutes(UserRoutes);

    {Set the home page}
    webServer.homePageHtml := page.home.html();
end;


{$IFDEF CONSOLEAPP}
var
    cmd: string;

function processCmd(_cmd: shortstring; out _terminate: boolean): string;
begin
    Result := _cmd;
    _terminate := (LowerCase(_cmd) = 'quit')
                  or (LowerCase(_cmd) = 'exit')
                  or (LowerCase(_cmd) = 'bye');
    if _terminate then
        Application.Terminate
    else begin

    end;
end;

procedure RunConsoleApp;
begin
    server.web.startServer();
    writeln(server.web.serverName + ' started.' );
    writeln(server.web.serverID );
    writeln(server.web.serverAbout );
    writeln('');
    writeln('Serving ' + server.web.serverURL);
    OpenURL(server.web.serverURL);
    while (not Application.Terminated) do begin
        //readln(cmd);
        //processCmd(cmd, terminated);
        Application.Run;
    end;
end;
{$ENDIF}

begin
	RequireDerivedFormResource:=True;
	Application.Scaled:=True;
	Application.Initialize;

    startLog();
    initWebServer();

    {$IFNDEF CONSOLEAPP}
	Application.CreateForm(TWebServerGui, WebServerGui);
    {$ENDIF}


    {$IFDEF CONSOLEAPP}
    RunConsoleApp;
    {$ELSE}
    Application.Run;
    {$ENDIF}
end.

