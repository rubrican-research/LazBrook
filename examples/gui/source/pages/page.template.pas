unit page.template;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, sugar.htmlpage;
type

	{ TLazBrookPageTemplate }

    TLazBrookPageTemplate = class (RbWebPage)
        constructor Create; override;
	end;

implementation

{ TLazBrookPageTemplate }

constructor TLazBrookPageTemplate.Create;
begin
	inherited Create;
    with document.Head do begin
        // FomaticUI
        script.src:='https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js';
        stylesheet('https://cdn.jsdelivr.net/npm/fomantic-ui@2.9.4/dist/semantic.min.css');
        script.src:='https://cdn.jsdelivr.net/npm/fomantic-ui@2.9.4/dist/semantic.min.js';
	end;
    document.Body.addClass('ui container');
end;

end.

