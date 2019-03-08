
(* ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออป   *)
(* บ                                                        บÛ  *)
(* บ     Borland Pascal Programs                            บÛ  *)
(* บ     SB Interface Unit                                  บÛ  *)
(* บ                                                        บÛ  *)
(* วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถÛ  *)
(* บ                                                        บÛ  *)
(* บ     Copyright (C) 1996 Diego Iastrubni                 บÛ  *)
(* บ                                                        บÛ  *)
(* ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออผÛ  *)
(*  ฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿  *)

Unit SB;

Interface

Const
  bp210h = 1;
  bp220h = 2;

  feNoError      =  0;
  feNotARiff     =  1;
  feNotAWave     =  2;
  feNotAnFMT     =  3;
  feErrorInData  =  4;


Type
  RIFF_FILE = Record
    rID             : array [0..3] of char;  { Always    "RIFF"          }
    rLen            : LongInt;               { Size of data              }
    wID             : array [0..3] of char;  { Always    "WAVE"          }
    fID             : array [0..3] of char;  { Always    "fmt "          }
    fLen            : LongInt;               { Size of data in format    }
    wFormatTag      : Word;                  { *                         }
    nChannels       : Word;                  { Number of channels        }
    nSamplesPerSec  : Word;                  { Playback frequency        }
    nAvgBytesPerSec : Word;                  { **                        }
    nBlockAlign     : Word;                  { ***                       }
    FormatSpecific  : Word;                  { Format specific data area }
    Dummy           : LongInt;
    dID             : array [0..3] of char;  { Always    "data"          }
    dLen            : LongInt;               { Size of data              }
    dData           : Pointer;               { Actual waveform data      }
  End;

  WAVE_RECORD = Record
    Frequency      : Word;                  { Playback frequency        }
    DataSize       : Word;                  { Size of the waveform data }
    Data           : Pointer;               { Actual waveform data      }
  End;

  (* DSP Procedures *)
Function  ResetDSP( Base: Word) : boolean;
Procedure WriteDAC( Level: Byte);
Function  ReadDAC: Byte;
Function  SpeakerOn: Byte;
Function  SpeakerOff: Byte;
Procedure DMAStop;
Procedure DMAContinue;
Procedure PlayBack( Sound: Pointer; Size: Word; Frequency: Word);

  (* Waves and RIFF's *)
Function  LoadRiff( Name: String; Var Riff: RIFF_FILE ): Byte;
Function  LoadWave( Name: String; Var Wave: WAVE_RECORD ): Byte;
Procedure UnLoadWave( Var Wave: WAVE_Record );
Procedure PlayWave( Var Wave: WAVE_RECORD );

   (* Alternative delay procedure *)
Procedure MyDelay( n: Word );

Implementation


 (* Signatures of RIFF file *)

Const
  RiffSignature =  'RIFF';
  WaveSignature =  'WAVE';
  FmtSignature  =  'fmt ';
  DataSignature =  'data';


  (* Internal variables  *)

Var
   DSP_Reset        : Word;
   DSP_Read_Data    : Word;
   DSP_Write_Data   : Word;
   DSP_Write_Status : Word;
   DSP_Data_Avail   : Word;


  (* DSP Procedures *)

Function ResetDSP(Base: Word) : Boolean;
Begin
  Base             := Base * $010;
  DSP_Reset        := Base + $206;
  DSP_Read_Data    := Base + $20A;
  DSP_Write_Data   := Base + $20C;
  DSP_Write_Status := Base + $20C;
  DSP_Data_Avail   := Base + $20E;

  Port[DSP_Reset]:= 1;
  MyDelay( 1 );
  Port[DSP_Reset]:= 0;
  MyDelay( 1 );

  If (Port[DSP_Data_Avail] and $80 = $80) and
     (Port[DSP_Read_Data] = $AA)
    Then ResetDSP:= True
    Else ResetDSP:= False;
End;

Procedure WriteDSP( Value: Byte );
Begin
  While Port[DSP_Write_Status] and $80 <> 0 Do;
  Port[DSP_Write_Data]:= Value;
End;

Function ReadDSP: byte;
Begin
  While Port[DSP_Data_Avail] and $80 = 0 Do;
  ReadDSP := Port[DSP_Read_Data];
End;

Procedure WriteDAC( Level: Byte );
Begin
  WriteDSP($10);
  WriteDSP(Level);
End;

Function ReadDAC: Byte;
Begin
  WriteDSP($20);
  ReadDAC:= ReadDSP;
End;

Function SpeakerOn: Byte;
Begin
  WriteDSP($D1);
End;

Function SpeakerOff: Byte;
Begin
  WriteDSP($D3);
End;

Procedure DMAContinue;
Begin
  WriteDSP($D4);
End;

Procedure DMAStop;
Begin
  WriteDSP($D0);
End;

Procedure Playback( Sound: Pointer; Size: Word; Frequency: Word);
Var
  Time_Constant: Word;
  Page, Offset: Word;
Begin
  If ReadDAC<>0 Then DMAStop;
  SpeakerOn;
  Size := Size - 1;
  Offset:= Seg(Sound^) Shl 4 + Ofs(Sound^);
  Page:= (Seg(Sound^) + Ofs(Sound^) shr 4) shr 12;
  Port[$0A]:= 5;
  Port[$0C]:= 0;
  Port[$0B]:= $49;
  Port[$02]:= Lo(Offset);
  Port[$02]:= Hi(Offset);
  Port[$83]:= Page;
  Port[$03]:= Lo(Size);
  Port[$03]:= Hi(Size);
  Port[$0A]:= 1;

  Time_Constant := 256 - 1000000 div Frequency;
  WriteDSP($40);
  WriteDSP(Time_Constant);

  WriteDSP($14);
  WriteDSP(Lo(Size));
  WriteDSP(Hi(Size));
End;

  (* Waves and RIFF's *)
Function LoadRiff( Name: String; Var Riff: RIFF_FILE ): Byte;
Var
  RiffFile: File;
Begin
  FillChar( Riff, SizeOf(Riff), 0 );
  LoadRiff:= feNoError;

  Assign( RiffFile, Name );
  Reset( RiffFile, 1 );
  BlockRead( RiffFile, Riff, 44 );

  If Riff.rID <> RiffSignature
    Then Begin
           LoadRiff:= feNotARiff;
           Exit;
         End;

  If Riff.wID <> WaveSignature
    Then Begin
           LoadRiff:= feNotAWave;
           Exit;
         End;

  If Riff.fID <> FmtSignature
    Then Begin
           LoadRiff:= feNotAnFMT;
           Exit;
         End;

  If Riff.dID <> DataSignature
    Then Begin
           LoadRiff:= feErrorInData;
           Exit;
         End;

  If Riff.dLen > FileSize(RiffFile)
    Then Begin
           GetMem( Riff.dData, FileSize(RiffFile) );
           BlockRead( RiffFile, Riff.dData^, FileSize(RiffFile) )
         End
    Else Begin
           GetMem( Riff.dData, Riff.dLen );
           BlockRead( RiffFile, Riff.dData^, Riff.dLen )
         End;

  Close( RiffFile );
End;

Function LoadWave( Name: String; Var Wave: WAVE_RECORD ): Byte;
Var
  Riff: RIFF_FILE;
  Tmp : Byte;
Begin
  Tmp:= LoadRiff( Name, Riff );

  If Tmp = feNoError
    Then Begin
           Wave.Frequency  := Riff.nSamplesPerSec;
           Wave.DataSize   := Riff.dLen mod $FFFF;
           Wave.Data       := Riff.dData;
         End;

  LoadWave:= Tmp;
End;

Procedure UnLoadWave( Var Wave: WAVE_Record );
Begin
  If (Wave.DataSize <> 0)
    Then With Wave do
           Begin
             FreeMem( Data, DataSize );
             DataSize := 0;
             Frequency:= 0;
           End;
End;

Procedure PlayWave( Var Wave: WAVE_RECORD );
Begin
  Playback( Wave.Data, Wave.DataSize, Wave.Frequency );
End;

  (* Delay procedure *)
Procedure MyDelay( n: Word ); Assembler;
Var
  LastTick: Word absolute $40:$6C;
Asm
        MOV     ES,     SEG0040
        MOV     DX,     ES:LastTick

@AGAIN: MOV     AX,     ES:LastTick
        SUB     AX,     DX
        CMP     AX,     n
        JB      @AGAIN
End;

End.
