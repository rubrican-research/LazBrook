unit form.main;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
    server.web;

type

    { TWebServerGui }

    TWebServerGui = class(TForm)
        Button1: TButton;
        Label1: TLabel;
        lblBackground: TLabel;
        lblUrl: TLabel;
        TrayIcon1: TTrayIcon;
        procedure Button1Click(Sender: TObject);
        procedure FormCreate(Sender: TObject);
        procedure lblUrlClick(Sender: TObject);
    public
        function isServerRunning: boolean;
        procedure startServer;
        procedure stopServer;
    end;

var
    WebServerGui: TWebServerGui;

implementation

uses
    LCLIntf, sugar.uiHelper;
    {$R *.lfm}

    { TWebServerGui }

procedure TWebServerGui.Button1Click(Sender: TObject);
begin
    case isServerRunning of
        True:  StopServer;
        False: StartServer;
    end;
end;

procedure TWebServerGui.FormCreate(Sender: TObject);
begin
    setHover(lblUrl);
    lblUrl.Visible := False;
end;

procedure TWebServerGui.lblUrlClick(Sender: TObject);
begin
    OpenDocument(lblUrl.Caption);
end;

function TWebServerGui.isServerRunning: boolean;
begin
    Result := server.web.serverRunning;
end;

procedure TWebServerGui.startServer;
begin
    server.web.startServer;
    case server.web.serverRunning of
    	True: begin
            label1.Visible := server.web.serverRunning;
	        lblUrl.Visible := server.web.serverRunning;
            lblUrl.Caption := serverURL;
            Button1.Caption := 'Stop';
        end;
        False: ShowMessage('The server could not be started. Check logfile for details.');
    end;
end;

procedure TWebServerGui.stopServer;
begin
    server.web.StopServer;
    Button1.Caption := 'Start';
    label1.Visible := False;
    lblUrl.Visible := False;
end;

end.
