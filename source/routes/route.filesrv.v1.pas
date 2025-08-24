unit route.filesrv.v1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, StrUtils,
  BrookHTTPServer, BrookHTTPRequest, BrookHTTPResponse, BrookURLRouter,
  BrookMediaTypes;

type
  // How to resolve storage names
  TFileKeyMode = (fkmPassthrough,   // URL maps (sanitized) directly under BaseDir
                  fkmGuidOriginal); // Stored as <GUID>=<original>; GUID is the URL key

  TFileServConfig = record
    BaseDir: string;          // absolute path to your storage root
    RoutePrefix: string;      // e.g. '/assets' (no trailing slash)
    Mode: TFileKeyMode;       // fkmGuidOriginal recommended
    EnableCORS: Boolean;      // add permissive CORS headers
    ImmutableIDs: Boolean;    // strong caching on GET if true (GUIDs)
    MaxUploadBytes: Int64;    // 0 = unlimited
  end;

  { TLazBrookFileServRoute }

  TLazBrookFileServRoute = class(TBrookURLRoute)
  public
    class function RoutePattern: string;
    procedure Get(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
    procedure Head(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
    procedure Options(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
    procedure Post(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);  // /uploa
    procedure Delete(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
  end;

procedure LazbrookBindFileServer(const Routes: TBrookURLRoutes; const Cfg: TFileServConfig);

implementation
uses
  Math;
var
  GCfg: TFileServConfig;

{————— Small helpers —————}

function HttpTime(const DT: TDateTime): string;
var fs: TFormatSettings;
begin
  fs := DefaultFormatSettings;
  fs.DateSeparator := '-'; fs.TimeSeparator := ':';
  Result := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss "GMT"', LocalTimeToUniversal(DT), fs);
end;

function FileLastWriteUTC(const Path: string): TDateTime;
var age: LongInt;
begin
  age := FileAge(Path);
  if age <= 0 then exit(Now);
  Result := FileDateToDateTime(age);
end;

function MakeETag(const Path: string; Size: Int64; MTime: TDateTime): string;
begin
  Result := Format('"%d-%x"', [Size, DateTimeToFileDate(MTime)]);
end;

procedure MaybeAddCORS(const Resp: TBrookHTTPResponse);
begin
  if not GCfg.EnableCORS then exit;
  Resp.Headers.Values['Access-Control-Allow-Origin'] := '*';
  Resp.Headers.Values['Access-Control-Allow-Methods'] := 'GET,HEAD,POST,DELETE,OPTIONS';
  Resp.Headers.Values['Access-Control-Allow-Headers'] := 'Content-Type,Range,X-CSRF,Authorization';
  Resp.Headers.Values['Access-Control-Expose-Headers'] := 'ETag,Content-Range,Content-Length,Last-Modified';
  Resp.Headers.Values['Access-Control-Max-Age'] := '86400';
end;

function SanitizeRel(const S: string): string;
var i: Integer; ch: Char;
begin
  if (S = '') or (S[1] = '/') or (Pos('..', S) > 0) then exit('');
  Result := '';
  for i := 1 to Length(S) do begin
    ch := S[i];
    if ch in ['A'..'Z','a'..'z','0'..'9','-','_','.','@'] then
      Result += ch
    else if ch in ['\','/'] then exit('')
    else if ch = ' ' then Result += '_'
    else if Ord(ch) < 32 then exit('');
  end;
end;

function JoinUnderBase(const BaseDir, Rel: string; out Full: string): Boolean;
var base: string;
begin
  base := ExpandFileName(IncludeTrailingPathDelimiter(BaseDir));
  Full := ExpandFileName(base + Rel);
  Result := AnsiStartsText(base, Full);
end;

function GuessMime(const Path: string): string;
var ext: string;
begin
  // Brook MIME tables if available; else fallback
  //if BrookMIME.Active then begin
  //  ext := ExtractFileExt(Path);
  //  Result := BrookMIME.Types.Find(ext);
  //  if Result <> '' then exit;
  //end;
  Result := 'application/octet-stream';
end;

function ParseRange(const S: string; Size: Int64; out A, B: Int64): Boolean;
var p: SizeInt; s1,s2: string;
begin
  Result := False; A := 0; B := 0;
  if (S = '') or (LeftStr(S,6) <> 'bytes=') then exit;
  s1 := Copy(S,7,MaxInt);
  p := Pos('-', s1); if p = 0 then exit;
  s2 := Copy(s1, p+1, MaxInt);
  s1 := Copy(s1, 1, p-1);
  if s1 = '' then begin
    // suffix bytes
    A := Max(Size - StrToInt64Def(s2,0), 0);
    B := Size - 1;
  end else begin
    A := StrToInt64Def(s1,0);
    if s2 = '' then B := Size - 1 else B := StrToInt64Def(s2,0);
  end;
  if (A < 0) or (B < A) or (B >= Size) then exit;
  Result := True;
end;

procedure SetDisposition(const Resp: TBrookHTTPResponse; const OrigName: string; Inline: Boolean);
var disp, enc: string;
begin
  if Inline then disp := 'inline' else disp := 'attachment';
  enc := OrigName;
  enc := StringReplace(enc, ' ', '%20', [rfReplaceAll]);
  Resp.Headers.Values['Content-Disposition'] :=
    Format('%s; filename="%s"; filename*=UTF-8''''%s', [disp, OrigName, enc]);
end;

procedure EnsureMimeReady;
begin
  //if not BrookMIME.Active then begin
  //  BrookMIME.Active := True;
  //  BrookMIME.Types.Prepare;
  //end;
end;

{————— Storage resolution —————}

function ResolveGuidToDisk(const Id: string; out FilePath, MetaPath, OrigName: string): Boolean;
var sub, folder: string; sr: TSearchRec;
begin
  Result := False; FilePath := ''; MetaPath := ''; OrigName := '';
  if Length(Id) < 8 then exit;

  sub := LowerCase(StringReplace(Id, '{','', [rfReplaceAll]));
  sub := LowerCase(StringReplace(sub, '}','', [rfReplaceAll]));



  if Length(sub) < 4 then exit;
  folder := IncludeTrailingPathDelimiter(GCfg.BaseDir) +
            Copy(sub,1,2) + PathDelim + Copy(sub,3,2);
  if FindFirst(folder + PathDelim + Id + '=*', faAnyFile and not faDirectory, sr) = 0 then
  begin
    FilePath := folder + PathDelim + sr.Name;
    MetaPath := ChangeFileExt(FilePath, '.json');
    OrigName := sr.Name;
    if Pos('=', OrigName) > 0 then
      OrigName := Copy(OrigName, Pos('=',OrigName)+1, MaxInt);
    Result := True;
  end;
  FindClose(sr);
end;

function ResolvePassthroughToDisk(const RelKey: string; out FilePath: string): Boolean;
begin
  Result := JoinUnderBase(GCfg.BaseDir, RelKey, FilePath) and FileExists(FilePath);
end;

{————— Streaming —————}

procedure StreamFile(const Path, OrigName: string; Req: TBrookHTTPRequest; Resp: TBrookHTTPResponse);
var fs: TFileStream; size,len: Int64; mtime: TDateTime; etag,lm: string; a,b: Int64;
    mime, inm: string;
begin
  EnsureMimeReady;
  mime := GuessMime(Path);
  fs := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
  try
    size  := fs.Size;
    mtime := FileLastWriteUTC(Path);
    etag  := MakeETag(Path, size, mtime);
    lm    := HttpTime(mtime);

    // Conditional
    if (Req.Headers.Values['If-None-Match'] = etag) or
       (Req.Headers.Values['If-Modified-Since'] = lm) then
    begin
      Resp.Status := 304;
      Resp.Headers.Values['ETag'] := etag;
      Resp.Headers.Values['Last-Modified'] := lm;
      MaybeAddCORS(Resp);
      exit;
    end;

    // Common headers
    Resp.Headers.Values['ETag'] := etag;
    Resp.Headers.Values['Last-Modified'] := lm;
    Resp.Headers.Values['Accept-Ranges'] := 'bytes';
    if GCfg.ImmutableIDs then
      Resp.Headers.Values['Cache-Control'] := 'public, max-age=31536000, immutable'
    else
      Resp.Headers.Values['Cache-Control'] := 'public, max-age=3600';

    // Disposition: inline for common types
    inm := LowerCase(mime);
    SetDisposition(Resp, OrigName, (Pos('image/',inm)=1) or (inm='application/pdf') or (Pos('audio/',inm)=1) or (Pos('video/',inm)=1));

    // Range
    if ParseRange(Req.Headers.Values['Range'], size, a, b) then
    begin
      fs.Position := a;
      len := b - a + 1;
      Resp.Status := 206;
      Resp.Headers.Values['Content-Type'] := mime;
      Resp.Headers.Values['Content-Range'] := Format('bytes %d-%d/%d',[a,b,size]);
      Resp.Headers.Values['Content-Length'] := IntToStr(len);
      MaybeAddCORS(Resp);
      Resp.Stream(fs, len); // Brook: send exactly len bytes
      exit;
    end;

    // Full
    Resp.Status := 200;
    Resp.Headers.Values['Content-Type'] := mime;
    Resp.Headers.Values['Content-Length'] := IntToStr(size);
    MaybeAddCORS(Resp);
    Resp.Stream(fs); // Brook: send all
  finally
    fs.Free;
  end;
end;

function SaveUploadAtomic(const Guid, SafeName: string; Src: TStream; out FinalPath: string; out Bytes: Int64): Boolean;
var sub, dir, part, final: string; fs: TFileStream;
begin
  sub  := LowerCase(Copy(Guid, 1, 4));
  dir  := IncludeTrailingPathDelimiter(GCfg.BaseDir) + Copy(sub,1,2) + PathDelim + Copy(sub,3,2);
  ForceDirectories(dir);
  final := dir + PathDelim + Guid + '=' + SafeName;
  part  := final + '.part';
  fs := TFileStream.Create(part, fmCreate or fmShareExclusive);
  try
    Bytes := fs.CopyFrom(Src, 0);
    fs.Flush;
  finally
    fs.Free;
  end;
  Result := RenameFile(part, final);
  if Result then FinalPath := final else DeleteFile(part);
end;

{————— Route —————}

class function TLazBrookFileServRoute.RoutePattern: string;
begin
  // Supports:
  //  GET/HEAD/DELETE  {prefix}/:key
  //  POST             {prefix}/upload
  Result := Format('^%s(?:/(?:upload|(?P<key>[\w\-\._@%]+)))?$', [GCfg.RoutePrefix]);
end;

procedure TLazBrookFileServRoute.Get(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var key, path, meta, orig: string;
begin
  if ARequest.Variables.IndexOfName('key') < 0 then begin
    AResponse.Send('Not Found', 'text/plain', 404); exit;
  end;

  key := ARequest.Variables.Values['key'];

  case GCfg.Mode of
    fkmGuidOriginal:
      begin
        if not ResolveGuidToDisk(key, path, meta, orig) then
          begin AResponse.Send('Not Found', 'text/plain', 404); exit; end;
        StreamFile(path, orig, ARequest, AResponse);
      end;
    fkmPassthrough:
      begin
        key := SanitizeRel(key);
        if (key = '') or not ResolvePassthroughToDisk(key, path) then
          begin AResponse.Send('Not Found', 'text/plain', 404); exit; end;
        orig := ExtractFileName(path);
        StreamFile(path, orig, ARequest, AResponse);
      end;
  end;
end;

procedure TLazBrookFileServRoute.Head(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
  // Mirror GET headers without body
  Get(ASender, ARequest, AResponse);
  if AResponse.Status = 200 then
    AResponse.Send('', 'text/plain', 200); // ensure no body
end;

procedure TLazBrookFileServRoute.Options(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
begin
  MaybeAddCORS(AResponse);
  AResponse.Send('', 'text/plain', 204);
end;

procedure TLazBrookFileServRoute.Post(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
  guid, safeName, orig: string;
  upStream: TStream;
  finalPath: string;
  n: Int64;
begin
  // Expect /upload
  if (ARequest.Variables.IndexOfName('key') >= 0) or
     not EndsText('/upload', ARequest.Path) then
  begin
    AResponse.Send('Bad Request', 'text/plain', 400); exit;
  end;

  // Access the uploaded file stream from your existing lazbrook helpers:
  // Replace the following three lines with your actual multipart accessors.
  if not ARequest.Fields.HasFile('file') then begin
    AResponse.Send('No file', 'text/plain', 400); exit;
  end;
  upStream := ARequest.Fields.FileStream('file');     // your accessor
  orig     := ARequest.Fields.FileOriginalName('file'); // your accessor

  if (GCfg.MaxUploadBytes > 0) and (upStream.Size > GCfg.MaxUploadBytes) then
    begin AResponse.Send('Payload Too Large', 'text/plain', 413); exit; end;

  // Create GUID and sanitize name
  guid := Copy(StringReplace(GUIDToString(CreateGUID), ['{','}'], ['', ''], [rfReplaceAll]),1,36);
  safeName := SanitizeRel(orig); if safeName = '' then safeName := 'file.bin';

  if not SaveUploadAtomic(guid, safeName, upStream, finalPath, n) then
    begin AResponse.Send('Write failed', 'text/plain', 500); exit; end;

  MaybeAddCORS(AResponse);
  AResponse.Status := 201;
  AResponse.Headers.Values['Content-Type'] := 'application/json';
  AResponse.Send(Format('{"id":"%s","name":"%s","bytes":%d}', [guid, orig, n]), 'application/json', 201);
end;

procedure TLazBrookFileServRoute.Delete(ASender: TObject; ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var key, path, meta, orig: string;
begin
  if ARequest.Variables.IndexOfName('key') < 0 then begin
    AResponse.Send('Not Found', 'text/plain', 404); exit;
  end;
  key := ARequest.Variables.Values['key'];

  case GCfg.Mode of
    fkmGuidOriginal:
      if ResolveGuidToDisk(key, path, meta, orig) then begin
        if FileExists(path) then DeleteFile(path);
        if FileExists(meta) then DeleteFile(meta);
        MaybeAddCORS(AResponse);
        AResponse.Send('', 'text/plain', 204);
      end else AResponse.Send('Not Found', 'text/plain', 404);
    fkmPassthrough:
      begin
        key := SanitizeRel(key);
        if (key = '') or not ResolvePassthroughToDisk(key, path) then
          AResponse.Send('Not Found', 'text/plain', 404)
        else begin
          if FileExists(path) then DeleteFile(path);
          MaybeAddCORS(AResponse);
          AResponse.Send('', 'text/plain', 204);
        end;
      end;
  end;
end;

{————— Public bind —————}

procedure LazbrookBindFileServer(const Routes: TBrookURLRoutes; const Cfg: TFileServConfig);
var R: TBrookURLRoute;
begin
  GCfg := Cfg;

  // Ensure Brook MIME once
  EnsureMimeReady;

  // Mount one route at Cfg.RoutePrefix
  R := Routes.Add(TLazBrookFileServRoute);
  // no per-instance state needed; GCfg is used by handlers
end;

end.

