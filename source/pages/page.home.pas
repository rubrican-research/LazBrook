unit page.home;

{$mode ObjFPC}{$H+}

interface

uses
	 Classes, SysUtils;

	function html: string;

implementation

function html: string;
begin
     Result:= 'Welcome Home';
end;

end.

