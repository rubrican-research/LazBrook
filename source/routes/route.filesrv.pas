unit route.filesrv;

{$mode ObjFPC}{$H+}

interface

uses
     Classes, SysUtils, Forms, Controls, Graphics, Dialogs, BrookMediaTypes,
	 route.base, BrookURLRouter, BrookHTTPResponse, BrookHTTPRequest;

const
    {named group "file". alphanumeric, starts with / and contains -, _ @ and .}
    pcreFileName  = '/(?P<file>[\w\-\._@\s]+)'; // this has been assigned to the route

type
     RFileCacheTags = record
       filepath: string;
       mimeType: string;
       etag: string;
       last_modified: string;
     end;

	 { TFilesrvRouter }
     TFilesrvRouter = class(TDataModule)
          router: TBrookURLRouter;
		  BrookMIME: TBrookMIME;
		  procedure DataModuleCreate(Sender: TObject);
		  procedure routerNotFound(ASender: TObject; const ARoute: string;
			   ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
		  procedure routerRoutes0Request(ASender: TObject;
			   ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
			   AResponse: TBrookHTTPResponse);
     private
        myRootPath: string;
        myDownloadPath: string;
        myUploadPath: string;
		function getDownloadPath: string;
		function getUploadPath: string;
		procedure setDownloadPath(const _value: string);
		procedure setUploadPath(const _value: string);
     public
        procedure initRootPath(const _rootPath: string);
        function rootPath(): string; // Returns the root path;

        procedure DeleteFile(const _route: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure PatchFile(const _route: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure ReplaceFile(const _route: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure ServeFile(const _route: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure UploadFile(const _route: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);


        function getMIMEType(_filePath: string): string;

     public
        property downloadPath: string read getDownloadPath write setDownloadPath;
        property uploadPath: string read getUploadPath write setUploadPath;

     end;

     function getETag(const _file: string; _lastmodified: string): string;
     function sendMedia(const _filepath: string; AResponse: TBrookHTTPResponse): boolean;
     function sendAsset(const _filepath: string; AResponse: TBrookHTTPResponse): boolean;
     function sendFile(const _filepath: string; AResponse: TBrookHTTPResponse;_offerDownload: boolean = True): boolean;

var
     FilesrvRouter: TFilesrvRouter;

implementation
{$R *.lfm}

uses
     LazFileUtils, FileUtil, md5, DateUtils, pages, sugar.httphelper, sugar.utils, sugar.logger ;

function getETag(const _file: string; _lastmodified: string): string;
begin
    Result := 'W/"' + MD5Print(MD5String(_file + _lastmodified )) + '"';
end;

function getHttpTime(const _fileage: TDateTime): string;
var
    i: integer = 0;
begin
    // <day-name>, <day> <month> <year> <hour>:<minute>:<second> GMT
    Result := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss ' + 'GMT',
        LocalTimeToUniversal(_fileage),
        DefaultFormatSettings);
end;

function defaultExpiresOn: string;
begin
    Result:= getHttpTime(IncWeek(Now));
end;

function sendMedia(const _filepath: string; AResponse: TBrookHTTPResponse): boolean;
begin
    Result := sendFile(_filePath, AResponse, False {don't download});
end;

function sendAsset(const _filepath: string; AResponse: TBrookHTTPResponse): boolean;
begin
    Result := sendFile(_filePath, AResponse, True {download});
end;

function sendFile(const _filepath: string; AResponse: TBrookHTTPResponse;
    _offerDownload: boolean): boolean;
begin
    Result := False;
    try
        if FileExists(_filepath) then
        begin
            // AResponse.SendFile(0, 0, 0, _filepath, False{download}, httpOK.code);
            if _offerDownload then
               AResponse.Download(_filepath)
            else
               AResponse.SendFile(0, 0, 0, _filepath, False{no download}, httpOK.code);

            Result := True;
        end
        else
        begin
            Log(_filepath + ' not found. RbWebServer.serveFile()');
            AResponse.Send('Resource not found.', mimePlainText, httpNotFound.code);
        end;

    except
        on e: Exception do
            AResponse.Send(e.Message, mimePlainText, httpRequestRangeNotSatisfiable.code);
    end;
end;

{ TFilesrvRouter }

procedure TFilesrvRouter.DataModuleCreate(Sender: TObject);
begin
     router.Items[0].Pattern:= pcreFileName;
end;

procedure TFilesrvRouter.routerNotFound(ASender: TObject; const ARoute: string;
	 ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
     AResponse.SendEmpty;
end;

procedure TFilesrvRouter.routerRoutes0Request(ASender: TObject;
	 ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
	 AResponse: TBrookHTTPResponse);
begin
     {==== /assets  FILE ServerFile }
     case upperCase(ARequest.Method) of

        // DELETE
        // The DELETE method deletes the specified resource.
        'DELETE' : DeleteFile(ARoute.Path, ARequest, AResponse);

        // GET
        // The GET method requests a representation of the specified resource. Requests using GET should only retrieve data.
        'GET'    : serveFile(ARoute.Path, ARequest, AResponse);

        // PATCH
        // The PATCH method applies partial modifications to a resource.
        'PATCH'  : patchFile(ARoute.Path, ARequest, AResponse);

        // POST
        // The POST method submits an entity to the specified resource, often causing a change in state or side effects on the ServerFile.
        'POST'   : uploadFile(ARoute.Path, ARequest, AResponse);

        // PUT
        // The PUT method replaces all current representations of the target resource with the request payload.
        'PUT'    : replaceFile(ARoute.Path, ARequest, AResponse);
	 end;
{

HEAD
The HEAD method asks for a response identical to a GET request, but without the response body.

CONNECT
The CONNECT method establishes a tunnel to the ServerFile identified by the target resource.

OPTIONS
The OPTIONS method describes the communication options for the target resource.

TRACE
The TRACE method performs a message loop-back test along the path to the target resource.

}


end;

function TFilesrvRouter.getDownloadPath: string;
begin
    if myDownloadPath.isEmpty then
        Result:= rootPath()
    else
       Result:= myDownloadPath;
end;

function TFilesrvRouter.getUploadPath: string;
begin
    if myUploadPath.isEmpty then
        Result:= rootPath()
    else
       Result:= myUploadPath;
end;

procedure TFilesrvRouter.setDownloadPath(const _value: string);
begin
    if myDownloadPath = _value then exit;
    myDownloadPath := _value;
end;

procedure TFilesrvRouter.setUploadPath(const _value: string);
begin
    if myUploadPath = _value then exit;
    myUploadPath := _value;
end;

procedure TFilesrvRouter.initRootPath(const _rootPath: string);
begin
    myRootPath:= _rootPath;
end;

function TFilesrvRouter.rootPath: string;
begin
     if myRootPath.IsEmpty then
         Result:= ExpandFileName('')
     else
        Result:= myRootPath;
end;

procedure TFilesrvRouter.DeleteFile(const _route: string;
	 ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
     AResponse.Send(
        pages.info('Delete file not implemented'),
        mimeHTML,
        httpOK.code
     );
end;

procedure TFilesrvRouter.PatchFile(const _route: string;
	 ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    AResponse.Send(
       pages.info('Patch file not implemented'),
       mimeHTML,
       httpOK.code
    );

end;

procedure TFilesrvRouter.ReplaceFile(const _route: string;
	 ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
     AResponse.Send(
        pages.info('Replace file not implemented'),
        mimeHTML,
        httpOK.code
     );
end;

procedure TFilesrvRouter.ServeFile(const _route: string;
	 ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);

	 function shouldSendFile(_fileCacheTags: RFileCacheTags): boolean;
	 var
	   r: integer;
	   _noneMatch: string;
	   _etag: string;
	   _len: integer;
	 begin
	     Result := True;
	     {ETag being sent by libsagui appends  "-gzip". Have to remove from eTag
	     before comparing.... ugh!}
	     _len := _fileCacheTags.etag.Length-1;
	     _noneMatch := Copy(ARequest.Headers.Get('If-None-Match'),1, _len );
	     _etag:= Copy(_fileCacheTags.etag,1, _len);
	     r := CompareStr(_noneMatch, _etag);

	     //log(_fileCacheTags.filepath);
	     //log(_noneMatch, ' vs ',  _etag);
	     //log('compare string gave ', r);
	     if (r = 0)
	          OR
	        (CompareStr(ARequest.Headers.Get('If-Modified-Since'),_fileCacheTags.last_modified) = 0) then
	     begin
	        //Log('If-None-Match is identical so use cache');
	        Result := False; {Don't send the file}
	     end;
	 end;
var
    _filePath: string;
    _fileAge: TDateTime;
    _fileETag: RFileCacheTags;
    _offerDownload: boolean;
begin
    ThreadSwitch;
    {This is where the files are served}
    {Assume that the urlparamPath in ARoute points to the file needed}
    _filePath := appendPath([downloadPath, _route]);
    if not FileExists (_filePath) then
    begin
        log('fileserver:: No file %s', [_filePath]);
        AResponse.SendEmpty;
        Exit;
   	end;

    if not FileAge(_filePath, _fileAge) then
    begin
        log('fileserver:: FileAge returned error %s', [_filePath]);
        AResponse.SendEmpty;
        Exit;
   	end;

    with _fileETag do
    begin
        filepath := _filePath;
        mimeType := getMIMEType(_filepath);
        last_modified := getHttpTime(_fileAge);
    	etag := getETag(_filepath, last_modified); // MD5 Hash of filename and modification time
    end;

	AResponse.Headers.AddOrSet('Content-Type', _fileETag.mimeType);
  	AResponse.Headers.AddOrSet('Cache-Control', 'public');
  	{$IFDEF RBDebug}
  	AResponse.Headers.AddOrSet('Access-Control-Allow-Origin', '*');
  	{$ENDIF}
  	AResponse.Headers.AddOrSet('ETag', _fileETag.etag);
  	AResponse.Headers.AddOrSet('Expires', defaultExpiresOn);

  	_offerDownload := not (_fileETag.mimeType.StartsWith('video')
					   	  or _fileETag.mimeType.StartsWith('image')
					   	  or _fileETag.mimeType.StartsWith('audio')
					   	  or _fileETag.mimeType.StartsWith('text') );

  	//resp.Headers.AddOrSet('Last-Modified', _fileETag.last_modified);

  	{ServerFile files from here}
  	try
       if shouldSendFile(_fileETag) then
       begin
       		sendFile(_filePath, AResponse, _offerDownload);
          	log('fileserver:: sending file');
   	   end
   	   else
       begin
          	{tell the browser to send use its cached version}
          	AResponse.Send('', _fileETag.mimeType, httpNotModified.code);
          	log('fileserver:: responded - not modified');
   	   end;
   	except
    	  on e: Exception do
          	 AResponse.Send(e.Message, mimePlainText, THTTPResponses.httpOK.code);
    end;
end;

procedure TFilesrvRouter.UploadFile(const _route: string;
	 ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
     AResponse.Send(
        pages.info('Upload file not implemented'),
        mimeHTML,
        httpOK.code
     );
end;

function TFilesrvRouter.getMIMEType(_filePath: string): string;
var
    _ext: string;
begin
    if not BrookMIME.Active then begin
        BrookMime.FileName:= ExpandFileName('mime.types');
        BrookMime.Active := True;
        BrookMime.Types.Prepare;
    end;
    _ext := ExtractFileExt(_filePath);
    Result := BrookMIME.Types.Find(_ext);
end;

end.

