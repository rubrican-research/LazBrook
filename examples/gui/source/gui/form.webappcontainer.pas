unit form.WebAppContainer;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
    server.intf;

type

	{ TForm1 }

    TForm1 = class(TForm)
		Check: TButton;
		Load: TButton;
		ServerAbout: TButton;
		ServerID: TButton;
		ServerName: TButton;
		Info: TButton;
		Memo1: TMemo;
		StopServer: TButton;
		StartServer: TButton;
		Edit1: TEdit;
		procedure CheckClick(Sender: TObject);
  procedure InfoClick(Sender: TObject);
		procedure LoadClick(Sender: TObject);
		procedure ServerAboutClick(Sender: TObject);
		procedure ServerIDClick(Sender: TObject);
		procedure ServerNameClick(Sender: TObject);
		procedure StartServerClick(Sender: TObject);
		procedure StopServerClick(Sender: TObject);
    private
        webAppIntf: TWebAppIntf;
    public

    end;

var
    Form1: TForm1;

implementation

{$R *.lfm}



{ TForm1 }

procedure TForm1.InfoClick(Sender: TObject);
var
    s: pChar;
begin
    s := webAppIntf.serverURL();
    Memo1.Lines.Add(s);
    StrDispose(s);

    s := webAppIntf.serverEndPoints();
    Memo1.Lines.Add(s);
    StrDispose(s);

end;

procedure TForm1.CheckClick(Sender: TObject);
begin
    load.Enabled := isLazBrookLib(edit1.Text);

end;

procedure TForm1.LoadClick(Sender: TObject);
begin
    webAppIntf  := WebAppLib(edit1.Text);
    StartServer.Enabled := webAppIntf.isLoaded;
	ServerAbout.Enabled := webAppIntf.isLoaded;
	ServerID.Enabled    := webAppIntf.isLoaded;
	ServerName.Enabled  := webAppIntf.isLoaded;
	Info.Enabled        := webAppIntf.isLoaded;
	StopServer.Enabled  := webAppIntf.isLoaded;
end;

procedure TForm1.ServerAboutClick(Sender: TObject);
var
    s: pChar;
begin
    s := webAppIntf.serverAbout();
    Memo1.Lines.Add(s);
    StrDispose(s);
end;

procedure TForm1.ServerIDClick(Sender: TObject);
var
    s: pChar;
begin
    s := webAppIntf.serverID();
    Memo1.Lines.Add(s);
    StrDispose(s);
end;

procedure TForm1.ServerNameClick(Sender: TObject);
var
	s: pChar;
begin
    s := webAppIntf.serverName();
    Memo1.Lines.Add(s);
    StrDispose(s);
end;

procedure TForm1.StartServerClick(Sender: TObject);
begin
    webAppIntf.startServer(pChar(''), 100);
end;

procedure TForm1.StopServerClick(Sender: TObject);
begin
    webAppIntf.stopServer;
end;

end.

