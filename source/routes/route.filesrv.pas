unit route.filesrv;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, BrookUtility, BrookMediaTypes, BrookURLRouter,
    BrookHTTPResponse, BrookHTTPRequest,
    server.defines, route.base;

type
    TLazBrookFileSrvRouter = class;
    function LazBrookFileSrvRouterFactory (ACollection: TCollection): TBrookURLRoute;

const
  {named group "file". alphanumeric, starts with / and contains -, _ @ and .}
  pcreFileName    = '(?P<file>[/\w\-\._@\s]+)'; // this has been assigned to the route
  assetFolderName = 'assets'; // Default foldername for assets
  {File server entry point}

  FileSrvEntryPoint :  TEntryPoint = (
      entryPoint: '/assets';
      comment: '';
      authReq: false;
      endpoints: (
             (
              regex: '/' + pcreFileName;   // The pattern of the endpoint
              name: 'File';                // Use this field to store a readable caption for this endpoint
              comment: '';
              default: True;
              methods: [rmGET, rmPOST, rmDELETE, rmPATCH, rmHEAD];
              routeClass: nil;
              routeFactory: @LazBrookFileSrvRouterFactory;
              routeFactoryMethod: nil;
             )
      );
  );

type

    RFileCacheTags = record
      filepath: string;
      last_modified: string;
      mimeType: string;
      etag: string;
    end;


	{ TLazBrookFileSrvRouter }
    TLazBrookFileSrvRouter = class(TBrookURLRoute)
    protected
        BrookMIME: TBrookMIME;
    public
        constructor Create(ACollection: TCollection); override;
        destructor Destroy; override;

    public
        procedure DoMatch(ARoute: TBrookURLRoute); override;

        procedure DoRequestMethod(ASender: TObject; ARoute: TBrookURLRoute;
          ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse;
          var AAllowed: Boolean); override;

        procedure DoRequest(ASender: TObject; ARoute: TBrookURLRoute;
          ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse); override;

        procedure DeleteFile(const _route: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure PatchFile(const _route: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure ReplaceFile(const _route: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);

        procedure ServeFile(const _route: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
        procedure UploadFile(const _route: string; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);

        function getMIMEType(_filePath: string): string;

	end;

const
    DefaultDownloadFolderName = 'assets';
    DefaultUploadFolderName   = 'uploads';

    procedure setDownloadFolder(_download: string);
    procedure setUploadFolder(_upload: string);

    // Set the path where the files to be served are found
    function FileSrvDownloadPath : string;  // Path from where files will be served
    function FileSrvUploadPath: string;     // Path where the files will be uploaded
    function genETag(const _file: string; _lastmodified: string): string;

implementation

uses
  LazFileUtils, FileUtil, md5, DateUtils, sugar.httphelper,
  sugar.utils, sugar.logger, server.web;

var
    myDownloadFolder: string = '';
    myUploadFolder: string = '';

function LazBrookFileSrvRouterFactory(ACollection: TCollection): TBrookURLRoute;
begin
    Result := TLazBrookFileSrvRouter.Create(ACollection);
end;

procedure setDownloadFolder(_download: string);
begin
    myDownloadFolder := _download;
end;

procedure setUploadFolder(_upload: string);
begin
    myUploadFolder := _upload;
end;

function FileSrvDownloadPath: string;
begin
    Result := myDownloadFolder;
    if Result.isEmpty then begin
        Result := ExpandFileName(DefaultDownloadFolderName);
        ForceDirectories(Result);
	end;
end;

function FileSrvUploadPath: string;
begin
    Result := myUploadFolder;
    if Result.isEmpty then begin
        Result := ExpandFileName(DefaultUploadFolderName);
        ForceDirectories(Result);
	end;
end;

function genETag(const _file: string; _lastmodified: string): string;
begin
    // MD5 Hash of filename and modification time
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

function sendMedia(const _filepath: string; AResponse: TBrookHTTPResponse): boolean;
begin
    Result := sendFile(_filePath, AResponse, False {don't download});
end;

function sendAsset(const _filepath: string; AResponse: TBrookHTTPResponse): boolean;
begin
    Result := sendFile(_filePath, AResponse, True {download});
end;


{ TLazBrookFileSrvRouter }

constructor TLazBrookFileSrvRouter.Create(ACollection: TCollection);
begin
	inherited Create(ACollection);
    BrookMIME := TBrookMIME.Create(nil);
end;

destructor TLazBrookFileSrvRouter.Destroy;
begin
	BrookMIME.Free;
    inherited Destroy;
end;

procedure TLazBrookFileSrvRouter.DoMatch(ARoute: TBrookURLRoute);
begin
	inherited DoMatch(ARoute);
end;

procedure TLazBrookFileSrvRouter.DoRequestMethod(ASender: TObject;
	ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
	AResponse: TBrookHTTPResponse; var AAllowed: Boolean);
begin
	inherited DoRequestMethod(ASender, ARoute, ARequest, AResponse, AAllowed);
end;

procedure TLazBrookFileSrvRouter.DoRequest(ASender: TObject;
	ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest;
	AResponse: TBrookHTTPResponse);
begin
    log('FileSrv:: %s %s',[ARequest.Method, ARoute.Path]);
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
end;

procedure TLazBrookFileSrvRouter.DeleteFile(const _route: string;
	ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    log('Delete file not implemented');
     AResponse.Send(
        'Delete file not implemented',
        mimeHTML,
        httpOK.code
     );

end;

procedure TLazBrookFileSrvRouter.PatchFile(const _route: string;
	ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    log('Patch file not implemented');
    AResponse.Send(
       'Patch file not implemented',
       mimeHTML,
       httpOK.code
    );

end;

procedure TLazBrookFileSrvRouter.ReplaceFile(const _route: string;
	ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    log('Replace file not implemented');
     AResponse.Send(
        'Replace file not implemented',
        mimeHTML,
        httpOK.code
     );
end;

procedure TLazBrookFileSrvRouter.ServeFile(const _route: string;
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
        _etag:= _fileCacheTags.etag;
	    _len := _fileCacheTags.etag.Length;

        log('If-None-Match');
        log(ARequest.Headers.Get('If-None-Match'));

       {Extract the If-None-Match header}
	    _noneMatch := Copy(ARequest.Headers.Get('If-None-Match'),1, _len );
	    r := CompareStr(_noneMatch, _etag);

	    log(_fileCacheTags.filepath);
	    log('%s %s %s',[_noneMatch, ' vs ',  _etag]);
	    log('compare string gave %d',[r]);

	    if (r = 0)
	         OR
	       (CompareStr(ARequest.Headers.Get('If-Modified-Since'),_fileCacheTags.last_modified) = 0) then
	    begin
	       Log('If-None-Match is identical so use cache');
	       Result := False; {Don't send the file}
	    end;
	end;

var
    _filePath: string;
    _fileAge: TDateTime;
    _fileTags: RFileCacheTags;
    _offerDownload: boolean;
begin
    {This is where the files are served}
    {Assume that the urlparamPath in ARoute points to the file needed}
    _filePath := appendPath([FileSrvDownloadPath, _route]);


    if not FileExists (_filePath) then
    begin
        AResponse.SendEmpty;
        Exit;
   	end;

    if not FileAge(_filePath, _fileAge) then
    begin
        AResponse.SendEmpty;
        Exit;
   	end;

    with _fileTags do
    begin
        try
	        filepath      := _filePath;
	        mimeType      := getMIMEType(_filepath);
	        last_modified := getHttpTime(_fileAge);
	    	etag          := genETag(_filepath, last_modified); // MD5 Hash of filename and modification time
        except
            on E:Exception do begin
                AResponse.Send(e.Message, mimePlainText, THTTPResponses.httpOK.code);
                Exit;
			end;
		end;
	end;

	AResponse.Headers.AddOrSet('Content-Type', _fileTags.mimeType);
  	AResponse.Headers.AddOrSet('Cache-Control', 'public');
  	{$IFDEF Debug}
  	AResponse.Headers.AddOrSet('Access-Control-Allow-Origin', '*');
  	{$ENDIF}
  	AResponse.Headers.AddOrSet('ETag', _fileTags.etag);
  	AResponse.Headers.AddOrSet('Expires', defaultExpiresOn);

  	_offerDownload := not (_fileTags.mimeType.StartsWith('video')
					   	  or _fileTags.mimeType.StartsWith('image')
					   	  or _fileTags.mimeType.StartsWith('audio')
					   	  or _fileTags.mimeType.StartsWith('text') );

  	{ServerFile files from here}
  	try
       if shouldSendFile(_fileTags) then
       begin
       		sendFile(_filePath, AResponse, _offerDownload);
          	log('fileserver:: sending file');
   	   end
   	   else
       begin
          	{tell the browser to send use its cached version}
          	AResponse.Send('', _fileTags.mimeType, httpNotModified.code);
          	log('fileserver:: responded - not modified');
   	   end;
   	except
    	  on e: Exception do
          	 AResponse.Send(e.Message, mimePlainText, THTTPResponses.httpOK.code);
    end;
end;

procedure TLazBrookFileSrvRouter.UploadFile(const _route: string;
	ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    AResponse.Send(
       'Upload file not implemented',
       mimeHTML,
       httpOK.code
    );

end;

function TLazBrookFileSrvRouter.getMIMEType(_filePath: string): string;
var
    _ext: string;
begin
    if not BrookMIME.Active then begin
        BrookMime.FileName:= appendPath([appPath, 'mime.types']);
        BrookMime.Active  := True;
        BrookMime.Types.Prepare;
    end;
    _ext := ExtractFileExt(_filePath);
    Result := BrookMIME.Types.Find(_ext);
end;

end.

