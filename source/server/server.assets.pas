unit server.assets;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fgl;
type
    TServerAsset = class

    end;

//type
 //   TServerAsset = class
 //       myRelPath: string;     // relative under asset folder. this is the path that the server uses to identify this asset
 //       myDescription: string; // For documentation. In-code.
 //       myMimeType: string;    //
 //   published
 //       property url: string read getUrl write setUrl;
 //       property description read myDescription write setDescription;
 //       property mimeType: string getMimeType;
 //       property eTag: string read getETag;
 //   public
 //       constructor Create(_relPath: string);
	//end;

    function assetEntryPoint: string;
    function assetRoot: string;

    {Getters}
    function assetExists(_url: string) : boolean;
    function assetFullPath(_url: string): string;
    function assetObj(_url: string): TServerAsset;

    {Setters: Copies files to the asset folder}
    function putAsset(_path: string; _targetLocation: string; _description: string = ''): TServerAsset;
    procedure putAssets(_paths: TStringArray; _targetLocation: string);

    {Housekeeping}
    function refreshAssets: integer; // Loads assets and returns the number of assets loaded.
    function deleteAsset(_url: string): boolean;
    function moveAsset(_oldUrl: string; _newUrl: string): boolean;

var
    assetsFolder : string = '';

implementation
uses
    sugar.utils, server.web;

type
    TAssetList = class(specialize TFPGMapObject<string, TServerAsset>);
    TAssetIndex = class(specialize TFPGMapObject<string, TAssetList>);

var
    mimeIndex: TAssetIndex;

function assetExists(_url: string): boolean;
begin
    Result := assigned(assetObj(_url));
end;

function assetEntryPoint: string;
begin

end;

function assetRoot: string;
begin

end;


function assetFullPath(_url: string): string;
begin
    Result := appendPath([_url]);
end;

function assetObj(_url: string): TServerAsset;
begin

end;

function putAsset(_path: string; _targetLocation: string; _description: string
	): TServerAsset;
begin

end;

procedure putAssets(_paths: TStringArray; _targetLocation: string);
begin

end;

function refreshAssets: integer;
begin

end;

function deleteAsset(_url: string): boolean;
begin

end;

function moveAsset(_oldUrl: string; _newUrl: string): boolean;
begin

end;



initialization
    assetsFolder := ExpandFileName('');

end.

