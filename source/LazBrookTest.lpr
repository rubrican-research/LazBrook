program LazBrookTest;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, testFileSrv, sugar.logger, testGender,
  testContactInfo;

{$R *.res}

begin
  startLog();
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

