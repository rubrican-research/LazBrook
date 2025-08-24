unit server.apploop;

{A general purpose console application main loop}
{for windows and unix}

{$mode ObjFPC}{$H+}

interface

uses
    SysUtils, Classes;

type
    TAppStartProc = procedure of object;
    TAppStopProc = procedure of object;

    procedure terminateApp;
    procedure restartApp;
    procedure AppLoop(const _startProc: TAppStartProc;
        const _stopProc: TAppStopProc);

implementation

{$IFDEF MSWINDOWS}
uses Windows, SyncObjs;

var
    myStopEvent: THandle = 0;
    appTerminated : boolean = false;

function consoleEventWatcher(_ctrlType: DWORD): BOOL; stdcall;
begin
    case _ctrlType of
        CTRL_C_EVENT, CTRL_BREAK_EVENT, CTRL_CLOSE_EVENT, CTRL_SHUTDOWN_EVENT:
        begin
            if myStopEvent <> 0 then
                SetEvent(myStopEvent);
            appTerminated := true;
            Result := True;  // handled
        end;
        else
            Result := False;
    end;
end;

procedure terminateApp;
begin
    appTerminated := true;
    if myStopEvent <> 0 then
        SetEvent(myStopEvent);
end;

procedure restartApp;
begin
    appTerminated := false;
    if myStopEvent <> 0 then
        SetEvent(myStopEvent);
end;

procedure AppLoop(const _startProc: TAppStartProc;
    const _stopProc: TAppStopProc);
var
    rc: DWORD;
begin

    while not appTerminated do begin
	    // create manual-reset event, initially non-signaled
	    myStopEvent := CreateEvent(nil, True, False, nil);
	    if myStopEvent = 0 then
	        raise Exception.Create('CreateEvent failed');

	    SetConsoleCtrlHandler(@consoleEventWatcher, True);
	    try
	        if Assigned(_startProc) then _startProc;

	        // main wait loop: block, but periodically pump queued synchronizations
	        repeat
	            rc := WaitForSingleObject(myStopEvent, 100); // 100ms pulse
	            CheckSynchronize(0);
	        until rc = WAIT_OBJECT_0;

	        if Assigned(_stopProc) then _stopProc;
	    finally
	        SetConsoleCtrlHandler(@consoleEventWatcher, False);
	        if myStopEvent <> 0 then
	            CloseHandle(myStopEvent);
	        myStopEvent := 0;
	    end;
	end;
end;

{$ELSE}

uses
    BaseUnix, Unix, SyncObjs, Classes;

var
    myStopEvent: PRTLEvent = nil;
    myExitCode : integer;

procedure terminateApp;
begin
    FpKill(FpGetpid, SIGTERM);
end;

procedure restartApp;
begin
    FpKill(FpGetpid, SIGUSR1);
end;

procedure SignalHandler(Sig: longint); cdecl;
begin
    myExitCode:= 0;
    case sig of
        SIGTERM: Log('Shutdown Request -->');
        SIGINT:  Log('Signal: Ctrl+C');
        SIGQUIT: Log('Signal: Quit');
        SIGKILL: Log('Signal: KILL');
        SIGABRT: Log('Signal: Abort');
        SIGUSR1:
        begin
          Log('Signal to Restart');
          myExitCode := 11;
          ExitCode   := 11;
		end;
	end;
    terminated := (myExitCode = 0);
    if Assigned(myStopEvent) then
        RTLEventSetEvent(myStopEvent);
end;

procedure RunUntilStopped(const _startProc: TAppStartProc;
    const _stopProc: TAppStopProc);
begin
    while not terminated do begin
	    myStopEvent := RTLEventCreate;
	    try
	        _sigerr := fpSignal(SIGINT, SignalHandler(@DoSig)) = signalhandler(SIG_ERR);
	        if _sigerr then
	            WriteLn('Could not init signal handler for SIGINT');

	        _sigerr := fpSignal(SIGTERM, SignalHandler(@DoSig)) = signalhandler(SIG_ERR);
	        if _sigerr then
	            WriteLn('Could not init signal handler for SIGTERM');

	        _sigerr := fpSignal(SIGQUIT, SignalHandler(@DoSig)) = signalhandler(SIG_ERR);
	        if _sigerr then
	            WriteLn('Could not init signal handler for SIGQUIT');

	        _sigerr := fpSignal(SIGKILL, SignalHandler(@DoSig)) = signalhandler(SIG_ERR);
	        if _sigerr then
	            WriteLn('Could not init signal handler for SIGKILL');

	        _sigerr := fpSignal(SIGABRT, SignalHandler(@DoSig)) = signalhandler(SIG_ERR);
	        if _sigerr then
	            WriteLn('Could not init signal handler for SIGABRT');

	        _sigerr := fpSignal(SIGUSR1, SignalHandler(@DoSig)) = signalhandler(SIG_ERR);
	        if _sigerr then
	            WriteLn('Could not init signal handler for SIGUSR1');

	        if Assigned(_startProc) then _startProc;

	        // Wait, but wake periodically to process queued synchronizations
	        while RTLEventWaitFor(myStopEvent, 100) = wrTimeout do
	            CheckSynchronize(0);

	        if Assigned(_stopProc) then _stopProc;
	    finally
	        RTLEventDestroy(myStopEvent);
	        myStopEvent := nil;
	    end;
    end;
end;
{$ENDIF}

end.
