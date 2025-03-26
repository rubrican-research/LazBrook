unit form.WebAppContainer;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
	ExtCtrls, server.intf;

type

	{ TForm1 }

    TForm1 = class(TForm)
		Check: TButton;
		Edit1: TEdit;
		Info: TButton;
		ListView1: TListView;
		Load: TButton;
		Memo1: TMemo;
		Panel1: TPanel;
		Panel2: TPanel;
		Panel3: TPanel;
		Panel4: TPanel;
		SelectDirectoryDialog1: TSelectDirectoryDialog;
		ServerAbout: TButton;
		ServerID: TButton;
		ServerName: TButton;
		Splitter1: TSplitter;
		StartServer: TButton;
		StopServer: TButton;
		procedure FormCreate(Sender: TObject);
        procedure InfoClick(Sender: TObject);
		procedure ListView1SelectItem(Sender: TObject; Item: TListItem;
			Selected: Boolean);
		procedure LoadClick(Sender: TObject);
		procedure ServerAboutClick(Sender: TObject);
		procedure ServerIDClick(Sender: TObject);
		procedure ServerNameClick(Sender: TObject);
		procedure StartServerClick(Sender: TObject);
		procedure StopServerClick(Sender: TObject);
    private
        mySelectedLibPath: string;
        webAppIntf: TWebAppIntf;
		function getLibLoaded: boolean;
        function getSelectedLib: TWebAppIntf;
		procedure setLibLoaded(const _value: boolean);
    public
        property selectedLib: TWebAppIntf read getSelectedLib;
        property libLoaded: boolean read getLibLoaded write setLibLoaded;
    end;

var
    Form1: TForm1;

implementation

{$R *.lfm}
uses
    sugar.utils;
{ TForm1 }

procedure TForm1.InfoClick(Sender: TObject);
var
    s: pChar;
begin
    s := webAppIntf.serverURL();
    Memo1.Lines.Add(s);
    //StrDispose(s);

    s := webAppIntf.serverEndPoints();
    Memo1.Lines.Add(s);
    //StrDispose(s);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
    SelectDirectoryDialog1.InitialDir := ExtractFileDir(ExpandFileName(''));
    edit1.Text := SelectDirectoryDialog1.InitialDir;
end;

procedure TForm1.ListView1SelectItem(
    Sender: TObject;
    Item: TListItem;
	Selected: Boolean);
begin
    if Selected then begin
        mySelectedLibPath   := Item.Caption;
        load.Enabled := isLazBrookLib(mySelectedLibPath);
        if load.Enabled then begin
	        webAppIntf  := WebAppLib(mySelectedLibPath);
	        StartServer.Enabled := webAppIntf.isLoaded;
		    ServerAbout.Enabled := webAppIntf.isLoaded;
		    ServerID.Enabled    := webAppIntf.isLoaded;
		    ServerName.Enabled  := webAppIntf.isLoaded;
		    Info.Enabled        := webAppIntf.isLoaded;
		    StopServer.Enabled  := webAppIntf.isLoaded;

	        if webAppIntf.isLoaded then begin
	            StartServer.Enabled := not webAppIntf.serverRunning();
	            StopServer.Enabled  := not StartServer.Enabled;
	        end;
		end
        else begin
            StartServer.Enabled := false;
		    ServerAbout.Enabled := false;
		    ServerID.Enabled    := false;
		    ServerName.Enabled  := false;
		    Info.Enabled        := false;
		    StopServer.Enabled  := false;
		end;
	end;
end;

procedure TForm1.LoadClick(Sender: TObject);
var
    _files: TStrings;
	_file: String;
begin
    SelectDirectoryDialog1.InitialDir := edit1.Text;
    if SelectDirectoryDialog1.Execute then begin
        edit1.Text := SelectDirectoryDialog1.FileName;
        _files := getFiles(edit1.Text, '*.dll');
        try
            ListView1.Clear;
            Memo1.Clear;
            for _file in _files do begin
                Memo1.Lines.Add(_file);
                if isLazBrookLib(_file) then begin
                    ListView1.AddItem(_file, nil);
				end;
			end;
		finally
            _files.Free;
		end;

	end;
end;

procedure TForm1.ServerAboutClick(Sender: TObject);
var
    s: pChar;
begin
    s := webAppIntf.serverAbout();
    Memo1.Lines.Add(s);
    //StrDispose(s);
end;

procedure TForm1.ServerIDClick(Sender: TObject);
var
    s: pChar;
begin
    s := webAppIntf.serverID();
    Memo1.Lines.Add(s);
    //StrDispose(s);
end;

procedure TForm1.ServerNameClick(Sender: TObject);
var
	s: pChar;
begin
    s := webAppIntf.serverName();
    Memo1.Lines.Add(s);
    //StrDispose(s);
end;

procedure TForm1.StartServerClick(Sender: TObject);
begin
    if webAppIntf.start('', 100) then begin
        StartServer.Enabled := False;
        StopServer.Enabled  := True;
	end;
end;

procedure TForm1.StopServerClick(Sender: TObject);
begin
    if webAppIntf.stopServer() then begin
        StartServer.Enabled := True;
        StopServer.Enabled  := False;
	end;
end;

function TForm1.getSelectedLib: TWebAppIntf;
begin
    Result := webAppIntf;
end;

function TForm1.getLibLoaded: boolean;
begin

end;

procedure TForm1.setLibLoaded(const _value: boolean);
begin

end;

end.

