unit asset.icons;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, Controls;

type

	{ TAssetIcons }
    EAssetIcon = (
        iconLogo

    );
    TAssetIcons = class(TDataModule)
		iconList: TImageList;
    private

    public
        function base64(_icon: EAssetIcon): string;

    end;

var
    AssetIcons: TAssetIcons;


implementation

{$R *.lfm}
uses
    base64, graphics, GraphType, sugar.utils;

{ TAssetIcons }

function TAssetIcons.base64(_icon: EAssetIcon): string;
var
    imgFileStream : TFileStream;
    imgStream     : TMemoryStream;
    stringStream  : TStringStream;
    encoder       : TBase64EncodingStream;

    bmp: TRawImage;

	_oFile: RawByteString;
begin
    _oFile        := ExpandFileName('img.png');
    touch(_oFile);

    bmp           := TRawImage.Create;
    imgStream     := TMemoryStream.Create;
    imgFileStream := TFileStream.Create(_oFile, fmOpenWrite);
    stringStream  := TStringStream.Create('');

    try
        iconList.Resolution[64].GetRawImage(ord(_icon), bmp);
        bmp.SaveToStream(imgStream);
        bmp.SaveToStream(imgFileStream);

        encoder := TBase64EncodingStream.Create(stringStream);
        encoder.Write(imgStream, imgStream.Size);
        result := stringStream.DataString;
	finally
        encoder.Free;
        stringStream.Free;
        imgFileStream.Free;
        imgStream.Free;
        bmp.Free;

        Result := FileToBase64(_oFile);
    end;
end;

end.

