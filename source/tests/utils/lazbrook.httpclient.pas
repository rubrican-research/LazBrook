unit lazbrook.httpclient;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, fphttpclient, fpWeb, BrookUtility, httpprotocol;

 {HTTP CLIENT FACTORIES}
    function newHTTPClient  : TFPHTTPClient;

implementation

function newHTTPClient: TFPHTTPClient;
begin
    Result := TFPHTTPClient.Create(nil);
    With Result do begin
        AddHeader(HeaderAccept, ACCEPTED_CONTENT_TYPES);
        AddHeader(HeaderUserAgent, defaultUserAgent);
	end;
end;

end.

