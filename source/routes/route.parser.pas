unit route.parser;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, BrookHTTPRequest, BrookURLEntryPoints, BrookURLRouter;

    function findEntryPoint(constref _req: TBrookHTTPRequest; out _ep: TBrookURLEntryPoint): boolean;

implementation

uses
    LazStringUtils, sugar.logger;

function findEntryPoint(constref _req: TBrookHTTPRequest; out
	_ep: TBrookURLEntryPoint): boolean;
const
  __delim = '/';
var
    _temp: string;
    _entryPoint: string;
    _path: string;
    _pos: integer;
    _pTemp: pChar;
begin
    log('findEntryPoint-->');
    _temp := _req.Path;
    if _temp.length > 1 then begin
        _pTemp  := @_temp[2];
        _pos    := Pos(__delim, _pTemp);
        if _pos > 0 then begin
            _entryPoint := Copy(_pTemp, 1, _pos);
            log('Entrypoint found: %s', [_entryPoint]);
		end;
	end;
    log('done findEntryPoint');
end;

end.

