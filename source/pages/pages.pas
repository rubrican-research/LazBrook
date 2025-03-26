unit pages;
{
    Collection of pages served by thi app.
    You can implement the logic where you can have a basic page template
    which is then modified to generate the required page
}

{$mode ObjFPC}{$H+}

interface

uses
     Classes, SysUtils;

    function homePage: string;
    function message(_msg: string): string;
    function blank: string;
    function error(_msg: string): string;
    function info(_msg: string): string;

implementation

function homePage: string;
begin
    Result:= 'Home Page';
end;

function message(_msg: string): string;
begin
    Result:= 'Message: ' + _msg;
end;

function blank: string;
begin
    Result:='';
end;

function error(_msg: string): string;
begin
    Result:= 'Error: ' + _msg;
end;

function info(_msg: string): string;
begin
    Result:= 'Info: ' + _msg;
end;

end.

