Unit Music;

InterFace

TYPE HSC_Song = RECORD
                  Song     : POINTER;
                  SongSize : WORD;
                  FileName : STRING;
                  SongOK   : BOOLEAN;
                END;

PROCEDURE _HscPlayer;
PROCEDURE StartMusic (Song : POINTER; Polling, OldIRQ : BOOLEAN);
PROCEDURE PollMusic;
PROCEDURE StopMusic;
PROCEDURE FadeMusic;
FUNCTION  DetectAdlib (SuggestedPort : WORD) : WORD;
PROCEDURE ToggleRasterBar;
PROCEDURE SetUserIRQ (Link : BOOLEAN; Routine : POINTER);
PROCEDURE GetPlayerState (VAR Destination);
PROCEDURE LoadSong (VAR Dest : HSC_Song);
PROCEDURE ClearSong (VAR Dest : HSC_Song);

IMPLEMENTATION

{$L HSCOBJ.OBJ}
PROCEDURE _HscPlayer; EXTERNAL;

PROCEDURE StartMusic (Song : POINTER; Polling, OldIRQ : BOOLEAN); ASSEMBLER;
  ASM
    MOV  AH,0
    MOV  BL,Polling
    MOV  BH,OldIRQ
    CMP  BH,1
    JE   @Invert
    MOV  BH,1
    JMP  @GoOn
  @Invert:
    XOR  BH,BH
  @GoOn:
    LES  SI,DWORD PTR Song
    CALL _HscPlayer
  END;

PROCEDURE PollMusic; ASSEMBLER;
  ASM
    MOV  AH,1
    CALL _HscPlayer
  END;

PROCEDURE StopMusic; ASSEMBLER;
  ASM
    MOV  AH,2
    CALL _HscPlayer
  END;

PROCEDURE FadeMusic; ASSEMBLER;
  ASM
    MOV  AH,3
    CALL _HscPlayer
  END;

FUNCTION  DetectAdlib (SuggestedPort : WORD) : WORD; ASSEMBLER;
  ASM
    MOV  AH,4
    MOV  BX,SuggestedPort
    CALL _HscPlayer
    JNC  @GoOn
    MOV  AX,0FFh
  @GoOn:
  END;

PROCEDURE ToggleRasterBar; ASSEMBLER;
  ASM
    MOV  AH,5
    CALL _HscPlayer
  END;

PROCEDURE SetUserIRQ (Link : BOOLEAN; Routine : POINTER); ASSEMBLER;
  ASM
    PUSH DS
    MOV  AH,6
    MOV  BL,Link
    LDS  DX,DWORD PTR Routine
    CALL _HscPlayer
    POP  DS
  END;

PROCEDURE GetPlayerState (VAR Destination); ASSEMBLER;
  ASM
    MOV  AH,7
    LES  SI,DWORD PTR Destination
    CALL _HscPlayer
  END;

PROCEDURE LoadSong (VAR Dest : HSC_Song);
  VAR F : FILE;
  BEGIN
    ASSIGN (F,Dest.Filename);
    {$I-} RESET (F,1); {$I+}
    IF IORESULT <> 0
      THEN Dest.SongOK := FALSE
      ELSE
        BEGIN
          Dest.SongSize := FILESIZE (F);
          GETMEM (Dest.Song,Dest.SongSize);
          BLOCKREAD (F,Dest.Song^,Dest.SongSize);
          Dest.SongOK := TRUE;
          CLOSE (F)
        END
  END;

PROCEDURE ClearSong (VAR Dest : HSC_Song);
  BEGIN
    Dest.SongOK := FALSE;
    FREEMEM (Dest.Song,Dest.SongSize);
    Dest.SongSize := 0
  END;

End.