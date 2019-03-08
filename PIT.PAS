Unit PIT;

Interface

Type
  TProc = Procedure;

Var
  InstalledPit : Boolean;

Procedure InstallPit( CurrProc : TProc ; F : Word );
Procedure DonePit;

Implementation

Uses Dos;

{$F+} { Force far mode, a good idea when mucking around with interrupts }

Const
      TIMERINTR     =     8;
      PIT_FREQ      =     $1234DD;
      CurrClockTiks =     $10000;

Var
    BIOSTimerHandler,
    NewProc              : Procedure;
    clock_ticks, counter : longint;

procedure SetTimer(TimerHandler : pointer; frequency : word);
begin

  { Do some initialization }
  clock_ticks := 0;
  counter := $1234DD div frequency;

  { Store the current BIOS handler and set up our own }
  GetIntVec(TIMERINTR, @BIOSTimerHandler);
  SetIntVec(TIMERINTR, TimerHandler);

  { Set the PIT channel 0 frequency }
  Port[$43] := $34;
  Port[$40] := counter mod 256;
  Port[$40] := counter div 256;
end;

procedure CleanUpTimer;
begin
  { Restore the normal clock frequency }
  Port[$43] := $34;
  Port[$40] := 0;
  Port[$40] := 0;

  { Restore the normal ticker handler }
  SetIntVec(TIMERINTR, @BIOSTimerHandler);
end;

procedure Handler; Interrupt;
begin

  { DO WHATEVER WE WANT TO DO IN HERE }
  NEWPROC;

  { Adjust the count of clock ticks }
  clock_ticks := clock_ticks + counter;

  { Is it time for the BIOS handler to do it's thang? }
  if clock_ticks >= CurrClockTiks then
    begin

      asm pushf end;
      BIOSTimerHandler;
      Clock_Ticks:=Clock_Ticks-CurrClockTiks;
    end

  { If not then just acknowledge the interrupt }
  else
    Port[$20] := $20;
end;

Procedure InstallPit( CurrProc : TProc ; F : Word );
Begin
  InstalledPit:=True;
  NewProc:=CurrProc;
  SetTimer(Addr(Handler), F);
End;

Procedure DonePit;
Begin
  InstalledPit:=False;
  CleanUpTimer;
End;

Begin
  InstalledPit := False;
End.