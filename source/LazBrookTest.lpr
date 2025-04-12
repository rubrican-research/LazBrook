program LazBrookTest;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, testFileSrv, sugar.logger;

{$R *.res}

begin
  startLog();
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

