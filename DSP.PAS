Unit DSP;

Interface


Type

  TWav = Record
           Freq,
           Index,
           File_Size : Word;
           Buffer    : Pointer;
           FileName  : String;
  End;

{ ResetDSP returns true if reset was successful
  base should be 1 for base address 210h, 2 for 220h etc... }
function ResetDSP(base : word) : boolean;

{ Write DAC sets the speaker output level }
procedure WriteDAC(level : byte);

{ ReadDAC reads the microphone input level }
function ReadDAC : byte;

{ SpeakerOn connects the DAC to the speaker }
function SpeakerOn: byte;

{ SpeakerOff disconnects the DAC from the speaker,
  but does not affect the DAC operation }
function SpeakerOff: byte;

{ Functions to pause DMA playback }
procedure DMAStop;
procedure DMAContinue;

{ Files }
Procedure loadWav(var Wav : TWAV);
procedure unloadWav(Var Wav : TWAV);

{ Playback plays a sample of a given size back at a given frequency using
  DMA channel 1. The sample must not cross a page boundry }
procedure Playback(Wav : TWav);

Implementation

Uses Crt;

var      DSP_RESET : word;
     DSP_READ_DATA : word;
    DSP_WRITE_DATA : word;
  DSP_WRITE_STATUS : word;
    DSP_DATA_AVAIL : word;

function ResetDSP(base : word) : boolean;
begin

  base := base * $10;

  { Calculate the port addresses }
  DSP_RESET := base + $206;
  DSP_READ_DATA := base + $20A;
  DSP_WRITE_DATA := base + $20C;
  DSP_WRITE_STATUS := base + $20C;
  DSP_DATA_AVAIL := base + $20E;

  { Reset the DSP, and give some nice long delays just to be safe }
  Port[DSP_RESET] := 1;
  Delay(10);
  Port[DSP_RESET] := 0;
  Delay(10);
  if (Port[DSP_DATA_AVAIL] And $80 = $80) And
     (Port[DSP_READ_DATA] = $AA) then
    ResetDSP := true
  else
    ResetDSP := false;
end;

procedure WriteDSP(value : byte);
begin
  while Port[DSP_WRITE_STATUS] And $80 <> 0 do;
  Port[DSP_WRITE_DATA] := value;
end;

function ReadDSP : byte;
begin
  while Port[DSP_DATA_AVAIL] and $80 = 0 do;
  ReadDSP := Port[DSP_READ_DATA];
end;

procedure WriteDAC(level : byte);
begin
  WriteDSP($10);
  WriteDSP(level);
end;

function ReadDAC : byte;
begin
  WriteDSP($20);
  ReadDAC := ReadDSP;
end;

function SpeakerOn: byte;
begin
  WriteDSP($D1);
end;

function SpeakerOff: byte;
begin
  WriteDSP($D3);
end;

procedure DMAContinue;
begin
  WriteDSP($D4);
end;

procedure DMAStop;
begin
  WriteDSP($D0);
end;

procedure Playback(Wav : TWav);
var time_constant : word;
     page, offset : word;
begin

  Wav.Index:=Wav.File_Size-1;

  { Set up the DMA chip }
  offset := Seg(Wav.Buffer^) Shl 4 + Ofs(Wav.Buffer^);
  page := (Seg(Wav.Buffer^) + Ofs(Wav.Buffer^) shr 4) shr 12;
  Port[$0A] := 5;
  Port[$0C] := 0;
  Port[$0B] := $49;
  Port[$02] := Lo(offset);
  Port[$02] := Hi(offset);
  Port[$83] := page;
  Port[$03] := Lo(Wav.Index);
  Port[$03] := Hi(Wav.Index);
  Port[$0A] := 1;

  { Set the playback frequency }
  time_constant := 256 - 1000000 div Wav.Freq;
  WriteDSP($40);
  WriteDSP(time_constant);

  { Set the playback type (8-bit) }
  WriteDSP($14);
  WriteDSP(Lo(Wav.Index));
  WriteDSP(Hi(Wav.Index));
end;

{ Files }

Procedure loadWav(var Wav : TWAV );
var
  errcode:integer;
  file_size: longint;
  F : file;
begin
  Assign(F, WAV.filename);
  {$I-} Reset(F,1); {$I+}
  if IOResult = 0 then begin
    file_size := FileSize(F);
    getmem(WAV.buffer, file_size);
    BlockRead(F,WAV.buffer^,file_size,errcode);
  end;
  WAV.File_Size:=file_size;
  Close(F);
  Wav.Freq:=22000;
end;

procedure UnloadWav(Var Wav : TWav);
begin
  Freemem(Wav.Buffer,Wav.File_Size);
end;

end.
