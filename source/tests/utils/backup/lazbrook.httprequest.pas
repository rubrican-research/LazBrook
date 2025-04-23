unit lazbrook.httpRequest;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, fphttpclient, fpWeb, BrookUtility, httpprotocol;

{USER AGENT DEFINITIONS}
const
    WINDOWS_CHROME_USER_AGENT   = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0';
    LINUX_CHROME_USER_AGENT     = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0';
    MACOS_SAFARI_USER_AGENT     = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15';

var
    defaultUserAgent: string    = {$IFDEF WINDOWS}
	                                    WINDOWS_CHROME_USER_AGENT;
	                              {$ELSEIF LINUX}
							            LINUX_CHROME_USER_AGENT;
							      {$ELSEIF DARWIN}
							            MACOS_SAFARI_USER_AGENT;
							      {$ELSE}
							            'LazBrook/1.0';
							      {$ENDIF}

{CONTENT TYPE DEFINITIONS}
const
  ACCEPTED_CONTENT_TYPES  = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7';
  ACCEPTED_ENCODINGS      = 'gzip, deflate, br, zsdch, zstd';

  {Text Data}
    CONTENT_TEXT_PLAIN  = 'text/plain; charset=utf-8'; // - Plain text
    CONTENT_TEXT_HTML   = 'text/html; charset=utf-8'; // - HTML content
    CONTENT_TEXT_CSS    = 'text/css; charset=utf-8'; // - CSS stylesheets
    CONTENT_TEXT_CSV    = 'text/csv; charset=utf-8'; // - CSV (Comma-Separated Values)
    CONTENT_TEXT_XML    = 'text/xml; charset=utf-8'; // - XML data

  {Application Data}
    CONTENT_APPLICATION_JSON    = 'application/json'; // - JSON data
    CONTENT_APPLICATION_XHTML   = 'application/xhtml+xml'; //
    CONTENT_APPLICATION_XML     = 'application/xml'; // - XML data (alternative to text/xml)
    CONTENT_APPLICATION_PDF     = 'application/pdf'; // - PDF documents
    CONTENT_APPLICATION_ZIP     = 'application/zip'; // - ZIP archives

    CONTENT_APPLICATION_FORM_URLENCODED = 'application/x-www-form-urlencoded'; // - Form data (default for HTML forms)
    CONTENT_APPLICATION_JAVASCRIPT      = 'application/javascript'; // or text/javascript - JavaScript code
    CONTENT_APPLICATION_OCTET_STREAM    = 'application/octet-stream'; //  - Binary data/files
  {Multipart Data}

    CONTENT_MULTIPART_FORM_DATA = 'multipart/form-data'; // - Used for form submissions with file uploads
    CONTENT_MULTIPART_MIXED     = 'multipart/mixed';     // - Multiple content parts with different types

 {Image Types}
    CONTENT_IMAGE_JPEG      = 'image/jpeg'; // - JPEG images
    CONTENT_IMAGE_PNG       = 'image/png'; // - PNG images
    CONTENT_IMAGE_GIF       = 'image/gif'; // - GIF images
    CONTENT_IMAGE_SVG_XML   = 'image/svg+xml'; // - SVG images

 {Audio/Video Types}
    CONTENT_AUDIO_MPEG = 'audio/mpeg'; // - MP3 or other MPEG audio
    CONTENT_AUDIO_WAV  = 'audio/wav'; // - WAV audio
    CONTENT_VIDEO_MP4  = 'video/mp4'; // - MP4 video
    CONTENT_VIDEO_MPEG = 'video/mpeg'; // - MPEG video

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

