unit route.filesrv;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, BrookUtility, BrookMediaTypes, BrookURLRouter,
    BrookHTTPResponse, BrookHTTPRequest, BrookHTTPUploads,
    server.defines, route.base;

type
    TLazBrookFileSrvRouter = class;

function LazBrookFileSrvRouterFactory(ACollection: TCollection): TBrookURLRoute;

const
    {named group "file". alphanumeric, starts with / and contains -, _ @ and .}
    assetKey = 'assets'; // Default key for assets in the url route
    uploadKey = 'upload'; // Default key for for upload in the url route

    pcreFileSrvRoute = '(?P<file>[/\w\-\._@\s]+)';
    // this has been assigned to the route

  { SPECIFICATION FOR REGEX
    a)  The route is built from the regex, with a configured %s parameter
        (for Format()) which indicates the route name.

    b)  Following the route name we have:
            1)  either a named group called <key> which matches a secure,
                sanitized folder path separated by / with the final term
                matching a guid

            2) OR a named group called "upload" which is followed by:
                -   a "/" which indicates the root position
                -   OR a valid, secure, sanitized folder path separated
                    by / with no trailing / at the end.
  }

    pcreFileSrvRouteDYN =
        '^%s(?:/(?:upload/(?:(?P<upload>(?!.*(?:^|/)\.{1,2}(?:/|$))[\p{L}\p{N}\p{M}\p{Pc}\p{Pd} @%.,]+(?:/[\p{L}\p{N}\p{M}\p{Pc}\p{Pd} @%.,]+)*)|)|(?P<key>(?!.*(?:^|/)\.{1,2}(?:/|$))(?:[\p{L}\p{N}\p{M}\p{Pc}\p{Pd} @%.,]+/)*(?P<guid>[A-Fa-f0-9]{8}(?:-[A-Fa-f0-9]{4}){3}-[A-Fa-f0-9]{12}))))?$';
    //pcreFileSrvRoute    = '^(?:/(?:upload/(?:(?P<upload>(?!.*(?:^|/)\.{1,2}(?:/|$))[\p{L}\p{N}\p{M}\p{Pc}\p{Pd} @%.,]+(?:/[\p{L}\p{N}\p{M}\p{Pc}\p{Pd} @%.,]+)*)|)|(?P<' + uploadKey +' >(?!.*(?:^|/)\.{1,2}(?:/|$))(?:[\p{L}\p{N}\p{M}\p{Pc}\p{Pd} @%.,]+/)*(?P<guid>[A-Fa-f0-9]{8}(?:-[A-Fa-f0-9]{4}){3}-[A-Fa-f0-9]{12}))))?$';


    {File server entry point}
    FileSrvEntryPoint: TEntryPoint = (
        entryPoint: '/' + assetKey;
        comment: '';
        authReq: False;
        endpoints: (
        (regex: '/' + pcreFileSrvRoute;   // The pattern of the endpoint
        Name: 'File';
        // Use this field to store a readable caption for this endpoint
        comment: '';
        default: True;
        methods: [rmGET, rmPOST, rmPUT, rmDELETE, rmPATCH, rmOPTIONS, rmHEAD];
        routeClass: nil;
        routeFactory: @LazBrookFileSrvRouterFactory;
        routeFactoryMethod: nil;
        )
        );
        );

type
    RFileCacheTags = record
        filepath: string;
        size: int64;
        fileAge: TDateTime;
        last_modified: string;
        mimeType: string;
        etag: string;
    end;

    // How to resolve storage names
    NFileKeyMode = (fkmPassthrough,   // URL maps (sanitized) directly under BaseDir
        fkmGuidOriginal); // Stored as <GUID>=<original>; GUID is the URL key

    RFileSrvConfig = record
        baseDir: string;
        // absolute path to your storage root; If empty then this will be ExpandFileName(routePrefix);
        routePrefix: string;      // e.g. 'assets' (no slashes.They will be added)
        uploadPrefix: string;     // e.g.  upload  (no slashes.They will be added)
        mode: NFileKeyMode;       // fkmGuidOriginal recommended
        enableCORS: boolean;      // add permissive CORS headers
        immutableIDs: boolean;    // strong caching on GET if true (GUIDs)
        maxUploadBytes: int64;    // 0 = unlimited
    end;

const
    // This is the default configuration.
    DefaultFileSrvConfig: RFileSrvConfig = (
        baseDir: '';
        // absolute path to your storage root. If empty then this will be ExpandFileName(routePrefix);
        routePrefix: assetKey;   // e.g. 'assets' (no slashes.They will be added)
        uploadPrefix: 'upload';   // e.g.  upload  (no slashes.They will be added)
        mode: fkmGuidOriginal;    // fkmGuidOriginal recommended
        enableCORS: False;        // add permissive CORS headers
        immutableIDs: True;       // strong caching on GET if true (GUIDs)
        maxUploadBytes: 0;         // 0 = unlimited
        );

type
    { TLazBrookFileSrvRouter }
    TLazBrookFileSrvRouter = class(TBrookURLRoute)
    private
        myconfig: RFileSrvConfig;
        mydownloadPath: string;
        myuploadPath: string;
        function getBasePath: string;
        function getDownloadPath: string;
        function getUploadPath: string;
        procedure setBasePath(const _value: string);
        procedure setconfig(const _value: RFileSrvConfig);

    protected
        BrookMIME: TBrookMIME;
    public
        constructor Create(ACollection: TCollection); override;
        destructor Destroy; override;
    public
        procedure DoMatch(ARoute: TBrookURLRoute); override;

        procedure DoRequestMethod(ASender: TObject; ARoute: TBrookURLRoute;
            ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse;
            var AAllowed: boolean); override;

        procedure DoRequest(ASender: TObject; ARoute: TBrookURLRoute;
            ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse); override;

        procedure deleteFile(const _route: string; ARequest: TBrookHTTPRequest;
            AResponse: TBrookHTTPResponse);
        procedure getFile(const _route: string; ARequest: TBrookHTTPRequest;
            AResponse: TBrookHTTPResponse);
        procedure patchFile(const _route: string; ARequest: TBrookHTTPRequest;
            AResponse: TBrookHTTPResponse);
        procedure postFile(const _route: string; ARequest: TBrookHTTPRequest;
            AResponse: TBrookHTTPResponse);
        procedure putFile(const _route: string; ARequest: TBrookHTTPRequest;
            AResponse: TBrookHTTPResponse);

        function getMIMEType(_filePath: string): string;

        property config: RFileSrvConfig read myconfig write setconfig;
        // Server configuration.
        property basePath: string read getBasePath write setBasePath;
        property downloadPath: string read getDownloadPath;
        property uploadPath: string read getUploadPath;

    end;
    // Use this if you have different routes for GET/POST/...
    TLazBrookGetFileRouter = class(TLazBrookFileSrvRouter); // GET
    TLazBrookPutFileRouter = class(TLazBrookFileSrvRouter); // PUT


const
    DefaultDownloadFolderName = 'assets';
    DefaultUploadFolderName = 'uploads';

procedure setDownloadFolder(_download: string);
procedure setUploadFolder(_upload: string);

// Set the path where the files to be served are found
function FileSrvDownloadPath: string;  // Path from where files will be served
function FileSrvUploadPath: string;     // Path where the files will be uploaded
//function genETag(const _file: string; _lastmodified: string): string;
function genETag(const _f: RFileCacheTags): string;

implementation

uses
    LazFileUtils, FileUtil, md5, fpJSON, DateUtils, sugar.httphelper,
    sugar.utils, sugar.logger, server.web, httpprotocol, sugar.jsonlib;

var
    myDownloadFolder: string = '';
    myUploadFolder: string = '';

{
function genUploadedFileName(_f: TBrookHTTPUpload): string;
    generates a filename of the format
    uuid=name.ext
    This can be parsed to get the uuid and original name of the file
    in one step, making it easy to recover the original filename
    after it has been uploaded. One could also scan folder for duplicates
    based on the name.
}
function genUploadedFileName(_f: TBrookHTTPUpload): string;
begin
    Result := genUUID() + '=' + ExtractFileName(_f.Name);
end;

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
    if Result.isEmpty then
    begin
        Result := ExpandFileName(DefaultDownloadFolderName);
        ForceDirectories(Result);
    end;
end;

function FileSrvUploadPath: string;
begin
    Result := myUploadFolder;
    if Result.isEmpty then
    begin
        Result := ExpandFileName(DefaultUploadFolderName);
        ForceDirectories(Result);
    end;
end;

//function genETag(const _file: string; _lastmodified: string): string;
//begin
//    // MD5 Hash of filename and modification time
//    Result := 'W/"' + MD5Print(MD5String(_file + _lastmodified )) + '"';
//end;

function genETag(const _f: RFileCacheTags): string;
begin
    Result := 'W/"' + MD5Print(MD5String(_f.size.ToString() + _f.last_modified)) + '"';
end;



function getHttpTime(const _fileage: TDateTime): string;
var
    i: integer = 0;
begin
    // <day-name>, <day> <month> <year> <hour>:<minute>:<second> GMT
    Result := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss ' + 'GMT',
        LocalTimeToUniversal(_fileage), DefaultFormatSettings);
end;

function defaultExpiresOn: string;
begin
    Result := getHttpTime(IncWeek(Now));
end;

function sendFile(const _filepath: string; AResponse: TBrookHTTPResponse;
    _offerDownload: boolean): boolean;
begin
    Result := False;
    try
        if FileExists(_filepath) then
        begin
            AResponse.Compressed := True;
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
            AResponse.Send(e.Message, mimePlainText, httpInternalServerError.code);
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

procedure TLazBrookFileSrvRouter.setconfig(const _value: RFileSrvConfig);
begin
    myconfig := _value;
end;

function TLazBrookFileSrvRouter.getDownloadPath: string;
begin
    Result := basePath;
end;

function TLazBrookFileSrvRouter.getBasePath: string;
begin
    if myconfig.baseDir = '' then
        myconfig.baseDir := ExpandFileName(myconfig.routePrefix);

    Result := myconfig.baseDir;
end;

function TLazBrookFileSrvRouter.getUploadPath: string;
begin
    Result := appendPath([myconfig.baseDir, myconfig.uploadPrefix]);
end;

procedure TLazBrookFileSrvRouter.setBasePath(const _value: string);
begin
    if config.baseDir = _value then exit;
    myconfig.baseDir := _value;
end;


constructor TLazBrookFileSrvRouter.Create(ACollection: TCollection);
begin
    inherited Create(ACollection);
    myconfig := DefaultFileSrvConfig;
    BrookMIME := TBrookMIME.Create(nil);
    log('TLazBrookFileSrvRouter.Create()');
end;

destructor TLazBrookFileSrvRouter.Destroy;
begin
    log('TLazBrookFileSrvRouter.Destory');
    BrookMIME.Free;
    inherited Destroy;
end;

procedure TLazBrookFileSrvRouter.DoMatch(ARoute: TBrookURLRoute);
begin
    log('TLazBrookFileSrvRouter.DoMatch()');
    inherited DoMatch(ARoute);
end;

procedure TLazBrookFileSrvRouter.DoRequestMethod(ASender: TObject;
    ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse;
    var AAllowed: boolean);
begin
    inherited DoRequestMethod(ASender, ARoute, ARequest, AResponse, AAllowed);
end;

procedure TLazBrookFileSrvRouter.DoRequest(ASender: TObject;
    ARoute: TBrookURLRoute; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    log('FileSrv:: %s %s', [ARequest.Method, ARoute.Path]);
    case upperCase(ARequest.Method) of

        // DELETE
        // The DELETE method deletes the specified resource.
        'DELETE': deleteFile(ARoute.Path, ARequest, AResponse);

        // GET
        // The GET method requests a representation of the specified resource. Requests using GET should only retrieve data.
        'GET': getFile(ARoute.Path, ARequest, AResponse);

        // PATCH
        // The PATCH method applies partial modifications to a resource.
        'PATCH': patchFile(ARoute.Path, ARequest, AResponse);

        // POST
        // The POST method submits an entity to the specified resource, often causing a change in state or side effects on the ServerFile.
        'POST': PutFile(ARoute.Path, ARequest, AResponse);

        // PUT
        // The PUT method replaces all current representations of the target resource with the request payload.
        'PUT': putFile(ARoute.Path, ARequest, AResponse);
    end;
end;

procedure TLazBrookFileSrvRouter.deleteFile(const _route: string;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    log('Delete file not implemented');
    AResponse.Send(
        'Delete file not implemented',
        mimeHTML,
        httpOK.code
        );

end;

procedure TLazBrookFileSrvRouter.getFile(const _route: string;
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
        _etag := _fileCacheTags.etag;
        _len := _fileCacheTags.etag.Length;

        log(HeaderName(hhIfNoneMatch));
        log(ARequest.Headers.Get(HeaderName(hhIfNoneMatch)));

        {Extract the If-None-Match header}
        _noneMatch := Copy(ARequest.Headers.Get(HeaderName(hhIfNoneMatch)), 1, _len);
        r := CompareStr(_noneMatch, _etag);

        log(_fileCacheTags.filepath);
        log('%s %s %s', [_noneMatch, ' vs ', _etag]);
        log('compare string gave %d', [r]);

        if (r = 0) or (CompareStr(ARequest.Headers.Get(
            HeaderName(hhIfModifiedSince)), _fileCacheTags.last_modified) = 0) then
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
    _filePath := appendPath([downloadPath, _route]);


    if not FileExists(_filePath) then
    begin
        AResponse.Send('File does not exist', mimePlainText,
            THTTPResponses.httpNotFound.code);
        log('File does not exist: %s', [_filePath]);
        Exit;
    end;

    if not FileAge(_filePath, _fileAge) then
    begin
        AResponse.Send('File age did not compute', mimePlainText,
            THTTPResponses.httpNotFound.code);
        log('File age did not compute: %s', [_filePath]);
        Exit;
    end;

    with _fileTags do
    try
        filepath := _filePath;
        mimeType := getMIMEType(_filepath);
        last_modified := getHttpTime(_fileAge);
        size := fileSize(_filePath);
        etag := genETag(_fileTags);
        // MD5 Hash of filename and modification time
    except
        on E: Exception do
        begin
            AResponse.Send(e.Message, mimePlainText, THTTPResponses.httpOK.code);
            Exit;
        end;
    end;

    AResponse.Headers.AddOrSet(HeaderName(hhContentType), _fileTags.mimeType);
    AResponse.Headers.AddOrSet(HeaderName(hhCacheControl), 'public');
    {$IFDEF Debug}
    AResponse.Headers.AddOrSet('Access-Control-Allow-Origin', '*');
    {$ENDIF}
    AResponse.Headers.AddOrSet(HeaderName(hhETag), _fileTags.etag);
    AResponse.Headers.AddOrSet(HeaderName(hhExpires), defaultExpiresOn);

    _offerDownload := not (_fileTags.mimeType.StartsWith('video') or
        _fileTags.mimeType.StartsWith('image') or
        _fileTags.mimeType.StartsWith('audio') or
        _fileTags.mimeType.StartsWith('text'));

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
            AResponse.Send(e.Message, mimePlainText, THTTPResponses.httpNotFound.code);
    end;
end;


procedure TLazBrookFileSrvRouter.patchFile(const _route: string;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    log('Patch file not implemented');
    AResponse.Send(
        'Patch file not implemented',
        mimeHTML,
        httpOK.code
        );

end;

procedure TLazBrookFileSrvRouter.postFile(const _route: string;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
    _file: TBrookHTTPUpload;

    _fileName, _url: string;
    _urlsJsonArray: TJSONArray;
    _response: TJSONObject;

    function saveTo(_f: TBrookHTTPUpload; _dest: string): string;
    begin
        log('TLazBrookFileSrvRouter.UploadFile:: saving to "%s"', [_dest]);
        _f.SaveAs(_dest);
        Result := _dest;
    end;

begin
    log('TLazBrookFileSrvRouter.UploadFile:: Entered');
    _response := TJSONObject.Create();
    _urlsJsonArray := TJSONArray.Create;
    _response.strings['message'] := '';
    _response.arrays['urls'] := _urlsJsonArray;
    try

        for _file in ARequest.Files do
        begin
            _fileName := genUploadedFileName(_file);
            _url := appendURL([serverURL, FileSrvEntryPoint.entryPoint, _fileName]);
            _urlsJSONArray.Add(
                TJSONObject.Create(['name',
                _fileName, 'url', _url])
                );

            saveTo(_file, appendPath([downloadPath, _fileName]));
        end;

        _response.strings['message'] := Format('Ok', [_urlsJsonArray.Count, _url]);
        log('TLazBrookFileSrvRouter.UploadFile:: response: %s',
            [_response.FormatJSON()]);
        AResponse.Send(
            _response.FormatJSON(),
            mimeJSON,
            httpOK.code
            );

    finally
        _response.Free;
        log('TLazBrookFileSrvRouter.UploadFile:: Done.');
    end;
end;

procedure TLazBrookFileSrvRouter.putFile(const _route: string;
    ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
    log('Replace file not implemented');
    AResponse.Send(
        'Replace file not implemented',
        mimeHTML,
        httpOK.code
        );
end;



function TLazBrookFileSrvRouter.getMIMEType(_filePath: string): string;
var
    _ext: string;

    function addCharset(const AMime: string): string;
    var
        m: string;
        needsCharset: boolean;
    begin
        m := Trim(LowerCase(AMime));
        // strip any existing parameters
        if Pos(';', m) > 0 then
            m := Copy(m, 1, Pos(';', m) - 1);

        // Decide policy
        needsCharset :=
            // All text/* benefit from explicit charset (incl. text/event-stream)
            (Copy(m, 1, 5) = 'text/') or
            // XML family (often parsed as text)
            (m = 'application/xml') or (m = 'application/xhtml+xml') or
            (m = 'application/rss+xml') or (m = 'image/svg+xml');

        // Exceptions that should NOT carry charset
        if (m = 'application/json') or (m = 'application/pdf') or
            (m = 'application/wasm') then
            needsCharset := False;

        if needsCharset then
            Result := m + '; charset=UTF-8'
        else
            Result := m;
    end;

begin
    if not BrookMIME.Active then
    begin
        BrookMime.FileName := appendPath([appPath, 'mime.types']);
        BrookMime.DefaultType := mimeMarkdown;
        BrookMime.Active := True;
        BrookMime.Types.Prepare;
    end;
    _ext := ExtractFileExt(_filePath);
    Result := BrookMIME.Types.Find(_ext);

    Result := addCharSet(Result);
end;



end.
