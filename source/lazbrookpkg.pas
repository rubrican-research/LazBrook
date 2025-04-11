{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit Lazbrookpkg;

{$warn 5023 off : no warning about unused units}
interface

uses
    server.intf, server.stub, server.web, route.filesrv, server.defines, 
    route.base, server.init, server.assets, route.parser, server.users, 
    LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('Lazbrookpkg', @Register);
end.
