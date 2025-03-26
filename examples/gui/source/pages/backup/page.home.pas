unit page.home;

{$mode ObjFPC}{$H+}

interface

uses
	 Classes, SysUtils, page.template;
type

	{ THomePage }

    THomePage = class(TLazBrookPageTemplate)
        procedure buildPageBody;
        constructor Create; override;
    end;


	function html: string;

implementation
uses
     server.web;

function html: string;
var
	p: THomePage;
begin
     p := THomePage.Create;
     try
        Result := p.page;
	 finally
         p.Free;
	 end;
end;

{ THomePage }

procedure THomePage.buildPageBody;
var
	e: String;
begin
    with document.Body do begin
        h1('LazBrook Demo Page');
        with div_.p do begin
            span_('You are seeing a page that has been rendered on the server with the ');
            a('sugar.html library', 'https://github.com/rubrican-research/sugar');
		end;
        with div_ do begin
            p('The server has the following endpoints');
            for e in webserver.endPoints do begin

			end;
		end;
	end;
end;

constructor THomePage.Create;
begin
	inherited Create;
    buildPageBody;
end;

end.

