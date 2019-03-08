Unit DRCSB;

InterFace

Const
  RiffSignature =  'RIFF';
  WaveSignature =  'WAVE';
  FmtSignature  =  'fmt ';

  feNoError   =  0;
  feNotARiff  =  1;
  feNotAWave  =  2;
  feNotAnFMT  =  3;


TYPE
  BYTE_ARRAY    = array [0..$FFFF-1] of Byte;
  POINTER_ARRAY = ^BYTE_ARRAY;

  FORMAT_RECORD = Record
    fID             : array [0..3] of Char;
    fLen            : LongInt;
    wFormatTag      : Word;
    nChannels       : Word;
    nSamplesPerSec  : Word;
    nAvgBytesPerSec : Word;
    nBlockAlign     : Word;
    FormatSpecific  : Word;
  End;

  WAVE_DATA = Record
    wID        :  Array [0..3] of char;
    Format     :  FORMAT_RECORD;
    Wave_Audio :  Pointer;
  End;

  RIFF_FILE = Record
    rID   :  Array [0..3] of char;
    rLen  :  LongInt;
    rData :  WAVE_DATA;
  End;

  TWav = Record
           Index : Word;
           File_Size : Integer;
           Buffer : Pointer;
           FileName : String;
  End;

function reset_dsp: boolean;
procedure spk_on;
procedure spk_off;
procedure write_dsp(data:byte);
function read_dsp: byte;
procedure write_midi(data:byte);
function read_midi: byte;
Procedure load_file(var Wav : TWAV);
procedure unload_snd(buffer : pointer; FSize:Word);

Implementation

Uses Crt;

function reset_dsp: boolean;
begin
  reset_dsp:=False;
  port[$226]:=1;                  { write 1 to port 226h }
  delay(1);                       { then wait 3 microseconds, sorry cant get}
                                  { 3 micro second out of delay only milli }
  port[$226]:=0;                  { write 0 to port 226h }
  delay(1);
  repeat until port[$22E] > $80;  { check data available port }
  if port[$22A]=$AA then          { if data available then read the data }
  begin                           { if the data is AAh (ready byte)}
    reset_dsp:=True;              { return true }
    exit;
  end;
end;

procedure spk_on;
begin
  repeat until port[$22C] < $80;  { wait until the write reg bit 7 is off }
  port[$22C]:=$D1;                { then write message }
end;

procedure spk_off;
begin
  repeat until port[$22C] < $80;  { wait until the write reg bit 7 is off }
  port[$22C]:=$D3;                { then write message }
end;

procedure write_dsp(data:byte);
begin
  repeat until port[$22C] < $80;  { wait until the write reg bit 7 is off }
  port[$22C]:=$10;                { then write message }
  repeat until port[$22C] < $80;  { ditto}
  port[$22C]:=data;
end;

function read_dsp: byte;
begin
  repeat until port[$22C] < $80;  { wait until the write reg bit 7 is off }
  port[$22C]:=$20;                { then write message }
  repeat until port[$22E] > $80;  { wait until the status reg bit 7 is on }
  read_dsp:=port[$22A];           { then read the awaiting data }
end;

procedure write_midi(data:byte);
begin
  repeat until port[$22C] < $80;  { wait until the write reg bit 7 is off }
  port[$22C]:=$38;                { then write message }
  repeat until port[$22C] < $80;  { ditto}
  port[$22C]:=data;
end;

function read_midi: byte;
begin
  repeat until port[$22C] < $80;  { wait until the write reg bit 7 is off }
  port[$22C]:=$30;                { then write message }
  repeat until port[$22E] > $80;  { wait until the status reg bit 7 is on }
  read_midi:=port[$22A];          { then read the awaiting data }
end;

Procedure load_file(var Wav : TWAV );
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
end;

procedure unload_snd(buffer : pointer; FSize:Word);
begin
  freemem(buffer,FSize);
end;

Function LoadRiff( Name: String; Var Rif: RIFF_FILE ): Byte;
Var
  RiffFile: File;
Begin
  FillChar( Rif, SizeOf(Rif), 0 );
  LoadRiff:= feNoError;

  Assign( RiffFile, Name );
  Reset( RiffFile, 1 );

  BlockRead( RiffFile, Rif.rID, 4 );
  If Rif.rID <> RiffSignature Then
    Begin
      LoadRiff:= feNotARiff;
      Exit;
    End;

  BlockRead( RiffFile, Rif.rLen, 4 );
  BlockRead( RiffFile, Rif.rData.wID, 4 );
  If Rif.rData.wID <> WaveSignature Then
    Begin
      LoadRiff:= feNotAWave;
      Exit;
    End;

  BlockRead( RiffFile, Rif.rData.Format, 20 );
  If Rif.rData.Format.fID <> FmtSignature Then
    Begin
      LoadRiff:= feNotAnFMT;
      Exit;
    End;

  GetMem( Rif.rData.Wave_Audio, Rif.rData.Format.FLen );
  BlockRead( RiffFile, Rif.rData.Wave_Audio^, Rif.rData.Format.FLen );

  Close( RiffFile );
End;

End.