{$A+,B-,D+,E+,F-,G+,I+,L+,N-,O-,P-,Q-,R-,S+,T-,V+,X+}
{$M 16384,0,655360}

Program Game;

Uses GamePro,Music,Crt,SB;

Const

  Ver = 'DigMan In the Rock , Version 1.01';

  {Global}
  AbsoluteSpeed    = 1;
  CurrLevel : Byte = 0;
  MaxLevel         = 10;
  MemUsed          = 100000;

  DrUp        = 1;
  drDown      = 2;
  drLeft      = 3;
  drRight     = 4;

  { Messeges }
  NTFND       = ' Not Found.';
  FilesFnd    = ' All Files Found.';
  MemAlloc    = #10+#13+'Mem Allocated.'+#10+#13;
  ExitMsg     = #10+#13+' Bye...';
  ErrExitMsg  = #10+#13+'CAN NOT INITALIZE '+Ver+#10+#13;
  FileNotFound: String ='All Files Found';

  { File Names }
  PicFileName = 'DEFAULT.PIC';
  CFGFileName = 'DIGGER.CFG';
  FntFileName = 'DIGGER.FNT';
  MscFileName = 'SMJOOP.HSC';
  LvlName     : Array [1..MaxLevel] Of String =
                  ('LEVEL.001','LEVEL.002','LEVEL.003','LEVEL.004','LEVEL.005'
                  ,'LEVEL.006','LEVEL.007','LEVEL.008','LEVEL.009','LEVEL.010');

  { Screen Mask }
  DownDirt     = $80;
  Clum         = 0;
  Player1      = 1;
  Player2      = 2;
  Monster1     = 3;
  Monster2     = 4;
  Sack         = 5;
  Shot         = 6;     { Scores }
  Cherry       = 7;     CherryPoints   = 500 ;
  DFrame1      = 8;     DiamondPoints  = 25  ;
  Dirt         = 9;     DirtPoints     = 1   ;
  FallingSack  = 10;
  ExplodedSack = 11;    ExSackPoints   = 100 ;
  MonHole      = 12;    Mon1Points     = 100 ;
  DFrame2      = 13;    Mon2points     = 150 ;
  DFrame3      = 14;    BlowSackPoints = 30  ;
  Dframe4      = 15;
  Wall         = 16;
                        LevelPoints    = 10000;

  { Special Places }
  DiggerOkPlaces   = [Clum,Cherry,Dirt,DFrame1,Dframe2..Dframe4,shot,ExplodedSack,PLayer1,PLayer2,MOnster1,Monster2];
  Monster1OKPlaces = [Clum,Player1,Player2,Monster1,Monster2{,Cherry},MonHole,ExplodedSack];
  Monster2OkPlaces = [Clum,Player1,Player2,Monster1,Monster2,Cherry,Sack,Dirt,Dirt,DFrame1,Dframe2..Dframe4,MonHole];
  ShotOKPlaces     = [Clum,Player1,player2,monster1,monster2];
  SackOKPlaces     = [Clum,DownDirt,Monster1,Monster2];
  DiggerSlowDown   = [Sack];
  Monster1SlowDown = [Sack];
  Monster2SlowDown = [Sack];



  {Effects}
  StartSpeed     = 10;
  SackSpeed      = StartSpeed*3;
  SackFallSpeed  = StartSpeed*1-2;
  DirtSlow       = StartSpeed*2;
  DiamondSlow    = StartSpeed*2;
  ShotSpeed      = StartSpeed Div 2; {<-----}
  Monster1Speed  = StartSpeed+2;
  Monster2Speed  = StartSpeed+4;
  BlowUpHight    = 3;
  ScreenPalSpeed = 3;

  {Colors}
  TextColor   = 10;
  BackColor   = 0;
  DirtCol     = 25;

  { Palletes }
  cR           = 1;
  cG           = 2;
  cB           = 3;

  Type
    TPal = Array[cR..cB] Of Byte;

  Const

  RekaPal       : TPal = (10,10,33);

  TRGBlownSack  : TPal = (63,63,63);
  TRGDiamond    : Tpal = (60,30,40);
  TRGCanShot    : Tpal = (63,00,00);

  {Sound}
  MaxSounds        = 8;
  ExplodeSackSound = 1;
  FallenSack       = 2;
  FireSound        = 3;
  CheersSound      = 4;
  MonsterOutSound  = 5;
  GoldEatSound     = 6;
  MonsterDeadSound = 7;
  DiamondEaten     = 8;
  SoundFiles       : Array [1..MaxSounds] of String[13] =
      ( 'Record.WAV','Record1.WAV','Record2.WAV','Record3.Wav','Record4.Wav','Record5.Wav','Record6.Wav','Record7.Wav');

  {Player Stuff}
  MaxPlr        = 2;
  Startlives    = 3;
  PixelEvery    = 100;
  PathFindEvery = 100;
  RipTime       = 2000;

  {Monster1 Stuff}
  MaxMons       = 10;

  {Sack Stuff}
  MaxSack       = 10;
  RockingTimes  = 4;
  Dx            = 1;
  FlashEvery    = 1000;
  FlashChance   = 10;
  SackAnim      = 60;

  {Hole Stuff}
  HoleAnimSpeed = 150;
  MonsterSpeed  : Word = 10000;

  {ShotStuff}
  ShotEvery     = 20000;
  ShotPalEvery  = 300;

  {DiamondStuff}
  DiamondAnim   = 50;
  DmndEvery     = 100;
  DiamondChance = 800;

Type

{********************************* Objects **********************************}

  TCharacter = Object
    Speed,
    AnimSpeed,
    Frame,
    VirX,
    VirY    : Byte;
    LocX,
    LocY    : Word;
    Active  : Boolean;
    Function    MovementDone : Boolean;
    Procedure   HandleLocMovement;
  End;

  Tplayer    = Object (Tcharacter)
    Up,Down,Right,Left,FireKey,
    Ox,Oy,
    KeysSpeed,
    RotateSpeed,
    DrFrame,
    Lives,
    PlrNum    : Byte;
    Score     : Word;
    Constructor Init( Num : Byte );
    Function    Middle       : Boolean;
    Function    CanMoveUp    : Boolean;
    Function    CanMoveDown  : Boolean;
    Function    CanMoveLeft  : Boolean;
    Function    CanMoveRight : Boolean;
    Function    PlrSlowDown  : Boolean;
    Procedure   ExecuteDie;
    Procedure   RIP;
    Procedure   HandleKeys;
    Procedure   HandleVirMovement;
    Procedure   WhereStep;
    Procedure   HandlePic;
    Procedure   HandlePlayer;
  End;

  TMonster1  = Object (Tcharacter)
    Ox,Oy,
    Direction,
    MetNum,
    DeltaAnim,
    PlrNumChasing   : Byte;
    Chasing         : Boolean;
    Constructor Init( X, Y : Byte);
    Function    Middle       : Boolean;
    Function    CanMoveUp    : Boolean;
    Function    CanMoveDown  : Boolean;
    Function    CanMoveLeft  : Boolean;
    Function    CanMoveRight : Boolean;
    Function    MnstrSlowDown: Boolean;
    Procedure   ExecuteBlowUp;
    Procedure   HandleVirMovement;
    Procedure   HandlePic;
    Procedure   Handle;
  End;

  TMonster2  = Object (Tcharacter)
    Ox,Oy,
    Direction,
    MetNum,
    DeltaAnim,
    PlrNumChasing   : Byte;
    Time            : Word;
    Chasing         : Boolean;
    Constructor Init( X, Y : Byte);
    Function    Middle       : Boolean;
    Function    CanMoveUp    : Boolean;
    Function    CanMoveDown  : Boolean;
    Function    CanMoveLeft  : Boolean;
    Function    CanMoveRight : Boolean;
    Function    MnstrSlowDown: Boolean;
    Procedure   ExecuteBlowUp;
    Procedure   HandleVirMovement;
    Procedure   HandlePic;
    Procedure   Handle;
  End;

  TSack      = Object (Tcharacter)
    Hight,
    CurrRockingtimes      : Byte;
    Left,
    Falling,
    StopRocking           : Boolean;
    Function CanFall      : Boolean;
    Function PushedLeft   : Boolean;
    Function PushedRight  : Boolean;
    Constructor Init(X,Y  :Byte);
    Procedure BlowUP;
    Procedure Handleframe;
    Procedure HandleVirMovement;
    Procedure Handle;
  End;

  TFire      = Object (Tcharacter)
    Direction   : Byte;
    BlownAway,
    CanShot     : Boolean;
    FireTime    : Word;
    Constructor Init;
    Procedure HandleVirMovement;
    Procedure HandleLocMovement;
    Function  BlowUp  : Boolean ;
    Procedure HandleFrame;
    Procedure Handle;
    Procedure ExecuteBlowUp;
{    Destructor DeInit;}
  End;

  TMonsterHole = Object (TCharacter)
    MonsterOut  : Boolean;
    CurrMon     : Byte;
    Constructor Init(X,Y : Byte);
    Procedure   HandleFrame;
    Procedure   Handle;
    Procedure   BlowUp;
{    Destructor Done;}
  End;

  TScreenPal = Object
    Active,
    UP,
    Done      : Boolean;
    TRGPal,
    CurrPal   : TPal;
    Procedure SetTarget(Pal : TPal);
    Constructor Init(Pal : TPal);
    Procedure SFade;
    Procedure Handle;
   {Destructor DeInit;}
  End;

  TShowScore = Object
    Constructor Init( Score : Word );
   {Destructor Done}
  End;
{****************************************************************************}

  TBox   = Array [0..15,0..15] Of Byte;
  TLevel = Array [0..19,0..13] Of Byte;

  TFont = Array [#40..#90, 0..7] Of Byte;
  PFont = ^TFont;

VAR

  TrackScreen,
  Level           : Tlevel;
  DiggerFrames    : Array [1..4,1..4] Of Tbox;
  Monster1Frames,
  Monster2Frames  : Array [1..4,1..3] Of Tbox;
  DiamondFrames   : Array [1..4] Of TBox;
  SackFrames,
  MHoleFrames,
  ShotFrames      : Array [1..7] Of TBox;
  CherryPic,
  DirtPic,
  RIPIC,
  WallPic         : TBox;
  ItsTime         : Word;
  Font            : PFont;

  Fire	          : Array [1..2] of TFire;
  Player          : Array [1..MaxPlr] of TPlayer;
  Monster         : Array [1..MaxMons] Of Tmonster1;
  VarSack         : Array [1..MaxSack] Of TSack;
  MHole           : TMonsterHole;

  MMusic          : HSC_SONG;

  Wav             : Array [1..MaxSounds] of Wave_Record;

  DiamondNum,
  CurrNumMons,
  ActiveMons,
  CurrNumSack     : Byte;

  ScreenPal       : TScreenPal;
  showScore       : tShowScore;

{----------------------------------------------------------------------------}

{ All Font Stuff }
Procedure LoadFont;
Var
  Xc    : Char;
  Yc    : Byte;
  F     : File Of Byte;
Begin
  Assign (F,FntFileName);
  Reset(F);
  For Xc:=#40 To #90 Do
    For Yc := 0 To 7 Do
      Read(F,Font^[Xc,Yc]);
  Close(F);
End;

Function GetBit( Number, BitNum : Byte) : Boolean;
Begin
  GetBit := Number And (1 Shl BitNum)<>0;
End;

Procedure DrawChar(X,Y : Word; WithBack : Boolean; Chr : Char);
Var
  Xc,Yc : Word;
Begin
  For Xc:=0 To 7 Do
    For Yc:=0 To 7 Do
      If (GetBit(Font^[Chr,Yc],Xc)) And (Chr<>#32) Then Pixel(X+Xc,Y+Yc,TextColor) Else
                                       If WithBack Then Pixel(X+Xc,Y+Yc,BackColor);
End;

Procedure WriteStr(X,Y : Word; WithBack : Boolean; Str:String);
Var
  Xc : Byte;
Begin
  For Xc:=1 To Ord(Str[0]) Do
    DrawChar(X+(Xc-1)*8,Y,WithBack, Str[Xc])
End;

{ Functions }
Function Exist(Name : String) : Boolean;
Var
  F  : File;
Begin
  Assign(F,name);
  {$I-}
  Reset(F);
  Close(F);
  {$I+}
  Exist:= IOResult = 0;
End;

Function NoDirt( Num : Byte ) : Byte;
Begin
  NoDirt:= (Num And (Not DownDirt));
End;

Function IfDirt( X , Y : Byte ) : Boolean;
Begin
  IfDirt:= Level[X,Y]>$7F;
End;

Function CheckFiles : Boolean;
Var
  Count : Byte;
Begin
  If Not Exist(CFGFileName) Then Begin
   				   WriteLn;
  				   FileNotFound:=CFGFileName;
    			   	   WriteLn;
			           WriteLn(FileNotFound,NTFND);
                                 End;
  If Not Exist(PICFileName) Then begin
                                   FileNotFound:=PICFileName;
			           WriteLn(FileNotFound,NTFND);
                                 End;
  If Not Exist(FntFileName) Then begin
                                   FileNotFound:=FntFileName;
			           WriteLn(FileNotFound,NTFND);
                                 End;
  For Count:=1 To MaxLevel Do
    If Not Exist(LvlName[Count]) Then Begin
    				        FileNotFound:=LvlName[Count];
			                WriteLn(FileNotFound,NTFND);
                                      End;
  CheckFiles:=FileNotFound=FilesFnd;
  If FileNotFound=FilesFnd Then Begin
    WriteLn;
    WriteLn(FileNotFound);
    WriteLn;
  End;
End;

Function CheckMem : Boolean;
Begin
  FileNotFound:=MemAlloc;
  If MaxAvail<MemUsed Then Begin
    WriteLn;
    WriteLn('Mem Needed  : ',MemUsed );
    WriteLn('Mem Aviable : ',MaxAvail);
    WriteLn;
    FileNotFound:='No Mem';
  End Else WriteLn(FileNotFound);
  CheckMem:=FileNotFound=MemAlloc;
End;

Function Check : Boolean;
Var
  Temp : Boolean;
Begin
  Temp:=CheckMem;
  Check:=CheckFiles And Temp;
End;

Function LvlDone  : Boolean;
Begin
  LvlDone:=(CurrLevel*LevelPoints< Player[1].Score) or (DiamondNum=0) or ((ActiveMons=0) And (MHole.CurrMon=CurrNumMons));
End;

{Procs}


{Screen}

{Procedure DrawLeftLives(PlrNum : Byte);
Procedure DrawPoints  }
Procedure ShakeTheRoom;
Var
  Xc : Byte;
Begin
  For Xc:=1 to 3 Do Begin
    SetShowFrom(240*2);
    Delay(10);
    SetShowFrom(0);
    Delay(10);
  End;
End;

{Global}

{Sounds}
Procedure Load1Wav ( num : byte);
Begin
  LoadWave(SoundFiles[Num],Wav[Num]);
End;

Procedure LoadAllWav;
Var Xc : Byte;
Begin
  For Xc := 1 to MaxSounds do
    Load1Wav (xc);
End;

Procedure InitSound( Num : Byte);
Begin
  PlayWave(Wav[Num]);
End;

Procedure UnLoadAllWav;
Var Xc : Byte;
Begin
  For Xc:= 1 to MaxSounds do
    UnloadWave(Wav[Xc]);
End;

Procedure PutPic (X,Y : Word; Pic : TBox);
Var
  XC,YC : Byte;
Begin
  For Xc := 0 to 15 Do
    For Yc := 0 To 15 Do If Pic[Xc,Yc]>0 Then
      Pixel (X+Xc,Y+Yc,Pic[Xc,Yc]);
End;

Procedure LoadLevel;
Var
  F : File Of Tlevel;
Begin
  Assign (F,LvlName[CurrLevel]);
  Reset  (F);
  Read   (F,Level);
  Close  (F);
End;

Procedure LoadAllPics;
Var
  F  : File;
Begin
  Assign(F,PicFileName);
  Reset(F,1);
  BlockRead(F,DiggerFrames,SizeOf(DiggerFrames));
  BlockRead(F,Monster1Frames,SizeOf(Monster1Frames));
  BlockRead(F,Monster2Frames,SizeOf(Monster2Frames));
  BlockRead(F,SackFrames,SizeOf(SackFrames));
  BlockRead(F,ShotFrames,SizeOf(ShotFrames));
  BlockRead(F,CherryPic,SizeOf(CherryPic));
  BlockRead(F,DirtPic,SizeOf(DirtPic));
  BlockRead(F,MHoleFrames,SizeOf(MHoleFrames));
  BlockRead(F,RIPIC,SizeOf(RIPIC));
  BlockRead(F,DiamondFrames,SizeOF(DiaMondFrames));
  BlockRead(F,WallPic,SizeOF(WallPic));
  Close(F);
End;

Procedure LevelOnScreen;
Var
  Xc,Yc : Byte;
  X , Y : Word;
Begin
  For Xc:=0 To 19 Do
    For Yc:=0 To 13 Do Begin
      PutPic(Xc Shl 4,Yc Shl 4, DirtPic);
      Case NoDirt(Level[Xc,Yc]) Of
        Cherry  : PutPic(Xc Shl 4,Yc Shl 4, CherryPic);
        DFrame1,Dframe2..Dframe4 : Begin PutPic(Xc Shl 4,Yc Shl 4, DiamondFrames[1]); Inc(DiamondNum); End;
  	Sack    : PutPic(Xc Shl 4,Yc Shl 4, SackFrames[1]);
        Wall    : PutPic(Xc Shl 4,Yc Shl 4, WallPic);
      End;
    End;
  For Xc:=0 To 19 Do
    For Yc:=0 To 12 Do
      If (Level[Xc,Yc]=Clum) And (Nodirt(Level[Xc,Yc+1])=Clum) Then
        For Y:=Yc Shl 4 To Yc + 1 Shl 4 -1 Do
          PutPic(Xc Shl 4,Y,ShotFrames[7]) Else
        If NoDirt(Level[Xc,Yc  ])=Clum Then PutPic(X Shl 4,Y Shl 4,ShotFrames[7]) Else
        If NoDirt(Level[Xc,Yc+1])=Clum Then PutPic(X Shl 4,(Y+1) Shl 4,ShotFrames[7]);
  For Yc:=0 To 13 Do
    For Xc:=0 To 18 Do
      If (NoDirt(Level[Xc,Yc])=Clum) And (NoDirt(Level[Xc+1,Yc])=Clum) Then
        For X:=Xc Shl 4 To Xc + 1 Shl 4 -1 Do
          PutPic(X,Yc Shl 4,ShotFrames[7]) Else
        If NoDirt(Level[Xc,Yc  ])=Clum Then PutPic(X Shl 4,Y Shl 4,ShotFrames[7]) Else
        If NoDirt(Level[Xc+1,Yc])=Clum Then PutPic((X+1) Shl 4,Y Shl 4,ShotFrames[7]);
End;


{Type Definations}

{ TCharacter }
Function TCharacter.MovementDone : Boolean;
Begin
  MovementDone := (VirX Shl 4 =LocX) And (VirY Shl 4 = LocY);
End;

Procedure TCharacter.HandleLocMovement;
Begin
  if VirX shl 4 < locX Then dec(LocX);
  if VirX shl 4 > locX Then inc(LocX);
  if VirY shl 4 > LocY Then inc(LocY);
  If VirY Shl 4 < LocY Then Dec(LocY);
End;



{ Tplayer }
Function Tplayer.Middle    : Boolean;
Begin
  Middle:=(LocX mod 16 =8) or (LocY mod 16 =8)
End;

Function Tplayer.CanMoveUp : Boolean;
Begin
  CanMoveUP := (VirY>0) And (NoDirt(Level[VirX,VirY-1])<>Sack)
  And (NoDirt(Level[VirX,VirY-1]) in DiggerOkPlaces);
End;

Function Tplayer.CanMoveDown : Boolean;
Begin
  CanMoveDown := (VirY<13) And (NoDirt(Level[VirX,VirY+1])<>Sack)
  And (NoDirt(Level[VirX,VirY+1]) in DiggerOkPlaces);
End;

Function Tplayer.CanMoveLeft : Boolean;
Begin
  CanMoveLeft := (VirX>0) And(( (NoDirt(Level[VirX-1,VirY])=Sack) And(NoDirt(Level[VirX-2,VirY])=Clum)
  Or(NoDirt(Level[VirX-1,VirY]) in DiggerOkPlaces)));
End;

Function Tplayer.CanMoveRight : Boolean;
Begin
  CanMoveRight := (VirX<19) And (( (NoDirt(Level[VirX+1,VirY])=Sack) And (NoDirt(Level[VirX+2,VirY])=Clum)
  Or (NoDirt(Level[VirX+1,VirY]) in DiggerOkPlaces)));
End;

Function Tplayer.PlrSlowDown : Boolean;
Begin
  PlrSlowDown := (NoDirt(Level[VirX,VirY]) in DiggerSlowDown);
End;

Procedure Tplayer.Rip;
Var
  Xc,Yc,Zc : Byte;
Begin
  For Zc:=0 To 15-2 Do Begin
    Delay(100);
    For Yc:=0 To Zc Do
      For Xc:=0 To 15 Do
       If (RIPic[Xc,Yc]<>0) Then Pixel(LocX+Xc,LocY+Yc-Zc+13,RIPic[Xc,Yc]);
  End;
End;

Procedure Tplayer.ExecuteDie;
Begin
  PutPic(LocX,LocY,ShotFrames[7]);
  Dec(Lives);
  RIP;
  If Ifdirt(VirX,VirY) Then Level[VirX,VirY]:=DownDirt Else Level[VirX,VirY]:=Clum;
  Delay(RIPTime);
  PutPic(LocX,LocY,ShotFrames[7]);
  VirX:=Random(19);
  VirY:=Random(13);
  LocX:=VirX Shl 4;
  LocY:=VirY Shl 4;
End;

Procedure PathFind(X , Y : Byte);
Var
  Xc,Yc,
  Index     : Byte;
  Finished  : Boolean;
Begin
  For Xc:=0 To 19 Do
    For Yc:=0 To 13 Do
      If Not (NoDirt(Level[Xc,Yc]) In Monster1OKPlaces) Then TrackScreen[Xc,Yc]:=255 Else
        If IfDirt(Xc,Yc) Then TrackScreen[Xc,Yc]:=DownDirt Else
                              TrackScreen[Xc,Yc]:=Clum;
  Index:=1;
  Inc(TrackScreen[X,Y],Index);
  Repeat
    Finished:=True;
    For Xc:=0 To 19 Do
      For Yc:=0 To 13 Do
        If NoDirt(TrackScreen[Xc,Yc])=Index Then Begin
          If (Xc<19) And (NoDirt(TrackScreen[Xc+1,Yc])=Clum) Then Inc(TrackScreen[Xc+1,Yc],Index+1);
          If (Xc>00) And (NoDirt(TrackScreen[Xc-1,Yc])=Clum) Then Inc(TrackScreen[Xc-1,Yc],Index+1);
          If (Yc<13) And (Not IfDirt(Xc,Yc)) And (NoDirt(TrackScreen[Xc,Yc+1])=Clum)
            Then Inc(TrackScreen[Xc,Yc+1],Index+1);
          If (Yc>00) And (TrackScreen[Xc,Yc-1]=Clum) Then Inc(TrackScreen[Xc,Yc-1],Index+1);
          Finished:=False;
        End;
    Inc(Index);
  Until Finished;
End;

Constructor Tplayer.Init( Num : Byte );
Var
  F : File of Byte;
Begin
  PlrNum:=Num;
  Assign (F,CfgFileName);
  Reset  (F);
  Seek   (F,(Num-1)*6);
  Read   (F,Up);
  Read   (F,Down);
  Read   (F,Left);
  Read   (F,Right);
  Read   (F,FireKey);
  Read   (F,AnimSpeed);
  Close  (F);

  Speed:=StartSpeed*2;
  drFrame:=1;
  Frame:=1;
  KeysSpeed:=1;
  RotateSpeed:=1;
  Active:=True;

  VirX:=Random(19);
  VirY:=Random(13);
  LocX:=VirX Shl 4;
  LocY:=VirY Shl 4;

  lives:=startlives;
End;

Procedure Tplayer.HandleKeys ;
Begin
    If Keys[FireKey] And Fire[PlrNum].CanShot And Not Fire[PlrNum].Active Then Begin
      InitSound(FireSound);
      Fire[PlrNum].CanShot:=False;
      Fire[PlrNum].Active:=True;
      Fire[PlrNum].BlownAway:=False;
      Fire[PlrNum].LocX:=LocX;
      Fire[PlrNum].LocY:=LocY;
      Fire[PlrNum].VirX:=VirX;
      Fire[PlrNum].VirY:=VirY;
      If (Level[VirX,VirY-1]=Sack) And (VirY>0) and (DrFrame=drUp) And (keys[Up]) Then
        Fire[PlrNum].Direction:=DrDown Else Fire[PlrNum].Direction:=DrFrame;

      Fire[PlrNum].Frame:=1;
    End Else
    If Keys[Up] And (ItsTime Mod KeysSpeed = 0) Then Begin
      If DrFrame<>DrUp Then
      Begin
        If ItsTime Mod RotateSpeed = 0 Then DrFrame:=DrUp
      End Else
      If CanMoveUp Then Dec(VirY);
    End Else
    If Keys[Down] And (ItsTime Mod KeysSpeed = 0) Then Begin
      If DrFrame<>DrDown Then
      Begin
        If ItsTime Mod RotateSpeed = 0 Then DrFrame:=DrDown
      End Else
      If CanMoveDown Then Inc(VirY);
    End Else
    If Keys[Left] And (ItsTime Mod KeysSpeed = 0) Then Begin
      If DrFrame<>DrLeft Then
      Begin
        If ItsTime Mod RotateSpeed = 0 Then DrFrame:=DrLeft
      End Else
      If CanMoveLeft Then Dec(VirX);
    End Else
    If Keys[Right] And (ItsTime Mod KeysSpeed = 0) Then Begin
      If DrFrame<>DrRight Then
      Begin
        If ItsTime Mod RotateSpeed = 0 Then DrFrame:=DrRight
      End Else
      If CanMoveRight Then Inc(VirX);
    End
End;

Procedure TPlayer.HandleVirMovement;
Begin
  If Level[VirX,VirY]=FallingSack Then Begin If (NoDirt(Level[VirX,VirY+1])=Clum) And (VirY<13) Then Begin
    Inc(VirY);
    Speed:=SackFallSpeed;
    End; End
  Else Begin
    HandleKeys;
    If PlrSlowDown Then Speed:=SackSpeed Else Speed := StartSpeed;
  End;
End;

Procedure Tplayer.HandlePic ;
Begin
  Inc(Frame);
  If Frame=5 then Frame:=1;
End;

Procedure TPlayer.WhereStep;
Begin
  Case NoDirt(Level[VirX,VirY]) Of
    ExplodedSack : Begin InitSound(GoldEatSound);
                         ScreenPal.Init(TRGBlownSack); Inc(Score,ExSackPoints); ShowScore.Init(Player[1].Score);
                         If IfDirt(VirX,VirY) then Level[Virx,VirY]:= DownDirt
                         else Level[VirX,VirY]:=Clum;ShowScore.Init(Player[1].Score);End;
    DFrame1,
    Dframe2..Dframe4 : Begin InitSound(DiamondEaten); Dec(DiamondNum); Inc(Score,DiamondPoints);
                         If IfDirt(VirX,VirY) then Level[Virx,VirY]:= DownDirt
                         else Level[VirX,VirY]:=Clum;ShowScore.Init(Player[1].Score);End;
    Monster1,
    Monster2     : ExecuteDie;
    Sack         : If MovementDone Then ExecuteDie;
  End;
End;

Procedure Tplayer.HandlePlayer;
Begin
  IF Active then begin
    If ItsTime Mod PathFindEvery = 0 Then PathFind(VirX,VirY);
    If ItsTime mod speed = 0 then begin
      If MovementDone then Begin
        Ox:=VirX;Oy:=VirY;
        WhereStep;
        HandleVirMovement;
        WhereStep;
    If (Ox<>VirX) Or (Oy<>VirY) then Begin
          Case DrFrame Of
            DrUp   : Begin If IfDirt(Ox,Oy) Then Level[Ox,Oy]:=DownDirt Else Level[Ox,Oy]:=Clum;
                           Level[VirX,VirY]:=PlrNum; End;
            DrDown : Begin Level[Ox,Oy]:=Clum;
                           If IfDirt(VirX,VirY) Then Level[VirX,VirY]:=PlrNum+DownDirt Else Level[VirX,virY]:=PlrNum; End;
            Else     Begin If IfDirt(Ox,Oy) Then Level[Ox,Oy]:=DownDirt Else Level[Ox,Oy]:=Clum;
                           If IfDirt(VirX,VirY) Then Level[VirX,VirY]:=DownDirt+PlrNum Else Level[VirX,VirY]:=PlrNum;
                     End;
          End;
        End;
      End;
      PutPic(LocX,LocY,DiggerFrames[DrFrame,Frame]);
      handleLocMovement;
    End;
    If ItsTime mod animspeed =0 then Begin
      handlePic;
      PutPic (LocX,LocY,DiggerFrames[DrFrame,Frame]);
    End;
  End;
End;

{------Tfire----}

Constructor Tfire.Init;
Begin
  Frame:=1;
  AnimSpeed := 27;
  Blownaway:=false;
End;

Procedure Tfire.HandleVirMovement;
Begin
  Case Direction Of
    DrUp    : Dec(VirY);
    DrDown  : Inc(VirY);
    DrLeft  : Dec(VirX);
    DrRight : Inc(VirX);
  End;
End;

Procedure TFire.HandleLocMovement;
Begin
  If VirX Shl 4 > LocX then Inc(LocX);
  If VirX Shl 4 < LocX then Dec(LocX);
  If VirY Shl 4 > LocY then Inc(LocY);
  If VirY Shl 4 < LocY then Dec(LocY);
End;

Function Tfire.BlowUp : boolean;
Begin
  Case Direction Of
    DrUp    : BlowUp := (VirY=0) or IfDirt(VirX,Viry-1) or Not (Level[virX,VirY-1] In ShotOkPlaces);
    DrDown  : BlowUp := (VirY=13) or IfDirt(VirX,Viry) or Not (NoDirt(Level[virX,VirY+1]) In ShotOkPlaces);
    DrLeft  : BlowUp := (VirX=0) or Not (NoDirt(Level[virX-1,VirY]) In ShotOkPlaces);
    DrRight : BlowUp := (VirX=19) or Not (NoDirt(Level[virX+1,VirY]) In ShotOkPlaces);
  End;
End;

Procedure Tfire.HandleFrame;
Begin
  If BlownAway And MovementDone Then Inc(Frame);
  If Not BlownAway Then Inc(Frame);
  If (Frame=5) And Not BlownAway Then Frame:=1;
  PutPic(LocX,LocY,ShotFrames[Frame]);
End;

Procedure Tfire.ExecuteBlowUp;
Begin
  Active := False;
  If IfDirt(VirX,VirY) Then Level[VirX,VirY]:=downDirt else level[virX,virY]:=clum;
End;

Procedure Tfire.Handle;
Begin
  If FireTIme Mod ShotEvery = 0 Then Begin
    CanShot := True;
    FireTime:=1;
  End;
  Inc(FireTime);
  If CanShot And (ItsTime Mod ShotPalEvery = 0 ) Then ScreenPal.Init(TRGCanShot);
  If Active Then Begin
    If ItsTime Mod AnimSpeed = 0 Then HandleFrame;
    If ItsTime Mod ShotSpeed = 0 then Begin
      If MovementDone Then Begin
        If Not BlownAway Then BlownAway:=BlowUp;
        If not (NoDirt(Level[VirX,VirY]) in [Player1,Player2]) then Begin
          If ifdirt(virX,Viry) then level[virX,virY]:=downDirt else level[virX,virY]:=clum;
        End;
        If Not BlownAway Then HandleVirMovement;
        If not (NoDirt(Level[VirX,VirY]) in [Player1,Player2]) then Begin
          If Ifdirt(virX,Viry) then level[virX,virY]:=downDirt+shot else level[virX,virY]:=shot;
        End;
        If Frame=7 Then ExecuteBlowUp;
      End;
      HandleLocMovement;
      PutPic(LocX,LocY,ShotFrames[Frame]);
    End;
  End;
End;

{---------TMonster1-----}

Constructor Tmonster1.Init( X, Y : Byte);
Begin
  Active:=true;
  VirX:=X;
  VirY:=Y;
  Level[X,Y]:=Monster1+DownDirt;
  LocX:=VirX Shl 4;
  LocY:=VirY Shl 4;
  AnimSpeed:=100;
  Speed    :=StartSpeed+6;
  DeltaAnim:=Random(100);
  Chasing:=Random(360)<180;
  If Chasing Then PlrNumChasing:=Random(MaxPlr)+1;
  Direction:=1;
  Frame:=Random(3)+1;
End;

Function Tmonster1.Middle    : Boolean;
Begin
  Middle:=(LocX mod 16 =8) or (LocY mod 16 =8)
End;

Function TMonster1.CanMoveUP : Boolean;
Begin
  CanMoveUP := (VirY>0) And (NoDirt(Level[VirX,VirY-1])<>Sack)
  And (Level[VirX,VirY-1] in Monster1OkPlaces);
End;

Function TMonster1.CanMoveDown  : Boolean;
Begin
  CanMoveDown := (VirY<13) And (NoDirt(Level[VirX,VirY+1])<>Sack)
  And (NoDirt(Level[VirX,VirY+1]) in Monster1OkPlaces) and (Not ifdirt(virx,viry));
End;

Function TMonster1.CanMoveLeft  : Boolean;
Begin
  CanMoveLeft := (VirX>0) And (( (NoDirt(Level[VirX-1,VirY])=Sack) And (NoDirt(Level[VirX-2,VirY])=Clum)
  Or (NoDirt(Level[VirX-1,VirY]) in Monster1OkPlaces)));
End;

Function TMonster1.CanMoveRight : Boolean;
Begin
  CanMoveRight := (VirX<19) And (( (NoDirt(Level[VirX+1,VirY])=Sack) And (NoDirt(Level[VirX+2,VirY])=Clum)
  Or (NoDirt(Level[VirX+1,VirY]) in Monster1OkPlaces)));
End;

Function TMonster1.MnstrSlowDown : Boolean;
Begin
  MnstrSlowDown := NoDirt(Level[VirX,VirY]) in Monster1SlowDown;
End;

Procedure Tmonster1.HandleVirMovement;
Var
  Where : Byte;
Begin
  Where:=NoDirt(TrackScreen[VirX,VirY]);
  Begin
    If (Nodirt(TrackScreen[VirX,Viry-1])<Where) And CanMoveUp    Then Begin Dec(VirY); Direction:= DrUp;   End Else
    If (Nodirt(TrackScreen[VirX,Viry+1])<Where) And CanMoveDown  Then Begin Inc(VirY); Direction:= DrDown; End Else
    If (Nodirt(TrackScreen[VirX-1,Viry])<Where) And CanMoveLeft  Then Begin Dec(VirX); Direction:= DrLeft; End Else
    If (Nodirt(TrackScreen[VirX+1,Viry])<Where) And CanMoveRight Then Begin Inc(VirX); Direction:= DrRight End;
    If Mnstrslowdown then speed:= Sackspeed else speed:= monster1speed;
  End;
End;

Procedure Tmonster1.HandlePic;
Begin
  Inc(Frame);
  If Frame=4 then Frame:=1;
End;

Procedure Tmonster1.ExecuteBlowUp;
Begin
   InitSound(MonsterDeadSound);
   Dec(ActiveMons);
   if Level[virX,VirY]= Sack then Putpic(VirX shl 4,VirY Shl 4,SackFrames[1])
     else putpic(locX,locY,shotframes[7]);
   active:= false;
   Fire[1].BlownAway:=True;
   If Not NoDirt(Level[VirX,VirY]) In [FallingSack,Sack] Then Begin
     If Ifdirt(OX,OY) Then Level[OX,OY]:= DownDirt End else Level[OX,OY]:= Clum;
end;

Procedure Tmonster1.Handle;
Begin
  IF Active then begin
    If (ItsTime+DeltaAnim) mod animspeed =0 then Begin
      handlePic;
      PutPic (LocX,LocY,monster1Frames[Direction,Frame]);
    End;
    If ItsTime mod speed = 0 then begin
      If Not MovementDone Then PutPic (LocX,LocY,monster1Frames[Direction,Frame]);
      handleLocMovement;
      If NoDirt(level[VirX,VirY])=shot then ExecuteBlowUp;
      If (NoDirt(Level[VirX,VirY])=Sack) And (NoDirt(Level[VirX,VirY])<>Clum) Then ExecuteBlowUp;
      If Level[VirX,VirY]=FallingSack Then Begin If (NoDirt(Level[VirX,VirY+1])=Clum) And (VirY<13) Then Begin
          Inc(VirY);
          Speed:=SackFallSpeed;
      End End Else if movementDone then HandleVirMovement;
      If Middle And (Level[VirX,VirY]<>FallingSack) Then Begin
        If Level[Ox,Oy]<>FallingSack Then Begin If Ifdirt(OX,OY) Then Level[OX,OY]:= DownDirt else Level[OX,OY]:= Clum; End;
        If Ifdirt(VirX,VirY) Then Level[VirX,VirY]:=DownDirt+Monster1 Else Level[VirX,VirY]:=Monster1;
        Ox:=VirX;Oy:=VirY;
      End;
    end;
  End;
End;

{---------TMonster2-----}

Constructor Tmonster2.Init( X, Y : Byte);
Begin
  Active:=true;
  VirX:=X;
  VirY:=Y;
  Level[X,Y]:=Monster2+DownDirt;
  LocX:=VirX Shl 4;
  LocY:=VirY Shl 4;
  AnimSpeed:=100;
  Speed    :=StartSpeed+6;
  DeltaAnim:=Random(100);
  Chasing:=Random(360)<180;
  If Chasing Then PlrNumChasing:=Random(MaxPlr)+1;
  Direction:=1;
  Frame:=Random(3)+1;
End;

Function Tmonster2.Middle    : Boolean;
Begin
  Middle:=(LocX mod 16 =8) or (LocY mod 16 =8)
End;

Function TMonster2.CanMoveUP : Boolean;
Begin
  CanMoveUP := (VirY>0) {And (NoDirt(Level[VirX,VirY-1])<>Sack)}
  And (NoDirt(Level[VirX,VirY-1]) in Monster2OkPlaces);
End;

Function TMonster2.CanMoveDown  : Boolean;
Begin
  CanMoveDown := (VirY<13) {And (NoDirt(Level[VirX,VirY+1])<>Sack)}
  And (NoDirt(Level[VirX,VirY+1]) in Monster2OkPlaces);{ and (Not ifdirt(virx,viry));}
End;

Function TMonster2.CanMoveLeft  : Boolean;
Begin
  CanMoveLeft := (VirX>0){ And (( (NoDirt(Level[VirX-1,VirY])=Sack) And (NoDirt(Level[VirX-2,VirY])=Clum)}
  And (NoDirt(Level[VirX-1,VirY]) in Monster2OkPlaces);
End;

Function TMonster2.CanMoveRight : Boolean;
Begin
  CanMoveRight := (VirX<19){ And (( (NoDirt(Level[VirX+1,VirY])=Sack) And (NoDirt(Level[VirX+2,VirY])=Clum)}
  And (NoDirt(Level[VirX+1,VirY]) in Monster2OkPlaces);
End;

Function TMonster2.MnstrSlowDown : Boolean;
Begin
  MnstrSlowDown := NoDirt(Level[VirX,VirY]) in Monster2SlowDown;
End;

Procedure Tmonster2.HandleVirMovement;
Begin
  If (VirY>Player[Player1].VirY) And CanMoveUp    Then Begin Dec(VirY); Direction:=DrUp    End Else
  If (Viry<Player[Player1].VirY) And CanMoveDown  Then Begin Inc(VirY); Direction:=DrDown  End Else
  If (VirX>Player[Player1].VirX) And CanMoveLeft  Then Begin Dec(VirX); Direction:=DrLeft  End Else
  If (VirX<Player[Player1].VirX) And CanMoveRight Then Begin Inc(VirX); Direction:=DrRight End;
  If Mnstrslowdown then speed:= Sackspeed else speed:= Monster2speed;
End;

Procedure Tmonster2.HandlePic;
Begin
  Inc(Frame);
  If Frame=4 then Frame:=1;
End;

Procedure Tmonster2.ExecuteBlowUp;
Begin
   Dec(ActiveMons);
   if Level[virX,VirY]= Sack then Putpic(VirX shl 4,VirY Shl 4,SackFrames[1])
     else putpic(locX,locY,shotframes[7]);
   active:= false;
   Fire[1].BlownAway:=True;
   If Not NoDirt(Level[VirX,VirY]) In [FallingSack,Sack] Then Begin
     If Ifdirt(OX,OY) Then Level[OX,OY]:= DownDirt End else Level[OX,OY]:= Clum;
end;

Procedure Tmonster2.Handle;
Begin
  IF Active then begin
    If (ItsTime+DeltaAnim) mod animspeed =0 then Begin
      handlePic;
      PutPic (LocX,LocY,monster2Frames[Direction,Frame]);
    End;
    If ItsTime mod speed = 0 then begin
      If Not MovementDone Then PutPic (LocX,LocY,monster2Frames[Direction,Frame]);
      handleLocMovement;
      If NoDirt(level[VirX,VirY])=shot then ExecuteBlowUp;
      If Level[VirX,VirY]=FallingSack Then Begin If (NoDirt(Level[VirX,VirY+1])=Clum) And (VirY<13) Then Begin
          Inc(VirY);
          Speed:=SackFallSpeed;
      End End Else if movementDone then HandleVirMovement;
      If Middle And (Level[VirX,VirY]<>FallingSack) Then Begin
        If Level[Ox,Oy]<>FallingSack Then Begin If Ifdirt(OX,OY) Then Level[OX,OY]:= DownDirt else Level[OX,OY]:= Clum; End;
        If Ifdirt(VirX,VirY) Then Level[VirX,VirY]:=DownDirt+Monster2 Else Level[VirX,VirY]:=Monster2;
        Ox:=VirX;Oy:=VirY;
      End;
    end;
  End;
End;

{----- TSack -----}

Function TSack.CanFall     : Boolean;
Begin
  CanFall :=(((NoDirt(Level[VirX,VirY+1])=Player1) And not (keys[player[1].up] And Not Falling)) or
             ((NoDirt(Level[VirX,VirY+1])=Player2) And not (keys[player[2].up] And Not Falling)) or
             (NoDirt(Level[VirX,VirY+1]) in SackOKPlaces)) And (VirY<13)
End;

Function Tsack.PushedLeft  : Boolean;
begin
  PushedLeft:= ((NoDirt(Level[virX,virY])=Player1) And
               (Not Player[1].MovementDone) And
               (Player[1].DrFrame=DrLeft) And
               (VirX>0)) Or
               ((NoDirt(Level[virX,virY])=Player2) And
               (Not Player[2].MovementDone) And
               (Player[2].DrFrame=DrLeft) And
               (VirX>0));
End;

Function Tsack.PushedRight : Boolean;
Begin
  PushedRight:= ((NoDirt(Level[virX,virY])=Player1) And
                (Not Player[1].MovementDone) And
                (Player[1].DrFrame=DrRight) And
                (VirX<19)) Or
                ((NoDirt(Level[virX,virY])=Player2) And
                (Not Player[2].MovementDone) And
                (Player[2].DrFrame=DrRight) And
                (VirX<19));
End;

Procedure Tsack.BlowUP;
begin
  frame:=5;
  InitSound(ExplodeSackSound);
  PutPic(LocX,LocY,SackFrames[Frame]);
  Inc(Player[Player1].Score,BlowSackPoints);
  ShowScore.Init(Player[Player1].Score);
  ShakeTheRoom;
end;

Procedure Tsack.Handleframe;
begin
  If Frame=4 Then Frame:=0;
  if (frame>=3) and (frame<8) then inc(frame);
end;

Constructor Tsack.Init(X,Y : Byte);
Begin
  Active:=True;
  Frame:=1;
  AnimSpeed:=SackAnim;
  CurrRockingTimes:=RockingTimes;
  VirX:=X;
  VirY:=Y;
  Level[X,Y]:=Sack+DownDirt;
  LocX:=VirX Shl 4;
  LocY:=VirY Shl 4;
  Left:=True;
End;

Procedure TSack.HandleVirMovement;
Begin
  If CanFall And Not Falling And (CurrRockingTimes=RockingTImes) And Not StopRocking Then Begin
    CurrRockingTimes:=0;
  End Else
  If CanFall And StopRocking then begin
    Falling:=True;
    Inc(hight);
    Inc(VirY);
  End Else Begin
    Falling:=False;
    Hight:=0;
    If PushedLeft  Then Begin Dec(VirX); StopRocking:=True; End Else
    If PushedRight Then Begin Inc(VirX); StopRocking:=True; End;
  End;
  If Not CanFall Then StopRocking:=False;
  If Falling Then Frame:=2 Else If Frame=2 Then Begin
    Frame:=1;
    PutPic(LocX,LocY,SackFrames[1]);
  End;
End;

Procedure Tsack.Handle;
Var
  Ox,Oy : Byte;
Begin
  IF Active then Begin
    If (ItsTime Mod FlashEvery = 0) And (Random(FlashChance)=1) Then Frame:=3;
    If Falling Then Speed:=SackFallSpeed Else Speed:=SackSpeed;
    If ItsTime Mod AnimSpeed = 0 Then Begin
      If Frame=0 Then Begin
        Frame:=1;
        PutPic(LocX,LocY,SackFrames[Frame]);
      End;
      If Frame>2 then PutPic(LocX,LocY,SackFrames[Frame]);
      HandleFrame;
      If (CurrRockingTimes<RockingTimes) Then Begin
        If (VirX>0 ) And (VirX<19) Then If Left Then LocX:=LocX-DX Else LocX:=LocX+2*DX;
        If (VirX=0 ) Then If Left Then LocX:=LocX+2*DX;
        If (VirX=19) Then If Left Then LocX:=LocX-2*DX;
        Left:=Not Left;
        PutPic(LocX,LocY,SackFrames[Frame]);
        Inc(CurrRockingTimes);
        If CurrRockingTimes=RockingTImes Then StopRocking:=True;
      End;
    End;
    If ItsTime Mod Speed = 0 Then Begin
      Ox:=VirX;
      Oy:=VirY;
      If MovementDone Then Begin
        If not CanFall And (Hight>=BlowUpHight) And (Frame In [2,3,4]) Then BlowUP Else
          If Not CanFall and (Hight>0) and (Hight<BlowUphight) then initSound(Fallensack);
        HandleVirMovement;
      End;
      Level[Ox,Oy]:=Clum;
      If Falling Then Level[VirX,VirY]:=FallingSack Else Level[VirX,Viry]:=Sack;
      If Not MovementDone Then PutPic(LocX,LocY,SackFrames[Frame]);
      HandleLocMovement;
      If Frame=8 Then Begin Active:=False; Level[VirX,VirY]:=ExplodedSack; End;
    End;
  End;
End;

{ Diamond }

Procedure HandleDiamonds;
Var xc,Yc : Byte;
Begin
  For Xc:= 0 to 19 do
    For Yc:= 0 to 13 do
      Case NoDirt(Level[Xc,Yc]) of
        dFrame1 : If (Random(DiamondChance)=1)And (ItsTime mod DmndEvery=0) then
                    Begin If IfDirt(Xc,Yc) then Level[Xc,Yc]:=DownDirt+DFrame2
                    else Level[Xc,Yc]:=DFrame2;
                    PutPic (XC shl 4,Yc shl 4,DirtPic);
                    PutPic (XC shl 4,Yc shl 4,DiamondFrames[2]);
                  End;
        dFrame2..DFrame3 : If ItsTime mod DiamondAnim =0 then Begin
                             Inc(level[Xc,Yc]);
                             PutPic (XC shl 4,Yc shl 4,DirtPic);
                             PutPic (XC shl 4,Yc shl 4,DiamondFrames[NoDirt(Level[Xc,yc])-DFrame2+2]);
                           End;
        dFrame4 : If ItsTime mod DiamondAnim =0 then Begin If IfDirt(Xc,Yc) then Level[Xc,Yc]:=DownDirt+DFrame1
                                               else Level[Xc,Yc]:=DFrame1;
                          PutPic (XC shl 4,Yc shl 4,DirtPic);
                          PutPic (XC shl 4,Yc shl 4,DiamondFrames[1]);
                        End;
    End;
End;

{ MonsterHole }

Constructor TMonsterHole.Init(X,Y : Byte);
Begin
  VirX:=X;
  VirY:=Y;
  LocX:=VirX SHL 4;
  LocY:=VirY SHL 4;
  AnimSpeed:=HoleAnimSpeed;
  Active:=True;
  Frame:=1;
  ActiveMons:=0;
  CurrMon:=0;
  Level[VirX,VirY]:=MonHole;
End;

Procedure TMonsterHole.HandleFrame;
Begin
  PutPic(LocX,LocY,MHoleFrames[Frame]);
  If Frame=2 Then Frame:=0;
  Inc(Frame);
  If (Frame=5) And (CurrMon<CurrNumMons) Then Begin
    MonsterOut:=True;
    Frame:=1;
  End;
  If Frame=8 Then BlowUp;
End;

Procedure TMonsterHole.BlowUp;
Begin
  Active:=False;
  If IfDirt(VirX,VirY) Then Level[Virx,VirY]:=DownDirt Else Level[VirX,VirY]:=Clum;
  PutPic(LocX,LocY,ShotFrames[7]);
  ShakeTheRoom;
End;

Procedure TMonsterHole.Handle;
Begin
  If Active Then Begin
    If (ItsTime Mod MonsterSpeed = 0) And Not MonsterOut And (CurrMon<CurrNumMons+1) Then Frame:=3;
    If MonsterOut Then Begin
      Inc(ActiveMons);
      Inc(CurrMon);
      Monster[CurrMon].Init(VirX,VirY);
      InitSound(MonsterOutSound);
    End;
    MonsterOut:=False;
    If ItsTime Mod AnimSpeed     = 0  Then    Begin
      Level[VirX,VirY]:=MonHole;
      HandleFrame;
    End;
  End;
End;

{ ScreenPal }

Procedure TScreenPal.SetTarget(Pal : TPal);
Begin
  TRGPal[cR] :=Pal[cR];
  TRGPal[cG] :=Pal[cG];
  TRGPal[cB] :=Pal[cB];
End;

Constructor TScreenPal.Init(Pal : Tpal);
Begin
  Up:=True;
  Done:=False;
  Active:=True;
  CurrPal[cR]:=RekaPal[cR];
  CurrPal[cG]:=RekaPal[cG];
  CurrPal[cB]:=RekaPal[cB];
  SetTarget(Pal);
End;

Procedure TScreenPal.Sfade;
Var
  Xc : Byte;
Begin
  For Xc:=cR To cB Do Begin
    Done:=True;
    If CurrPal[Xc]<TRGPal[Xc] Then Begin Inc(CurrPal[Xc]);Done:=False; End;
    If CurrPal[Xc]>TRGPal[Xc] then Begin Dec(CurrPal[Xc]);Done:=False; End;
  End;
  Pal(0,CurrPal[cR],CurrPal[cG],CurrPal[cB]);
End;

Procedure TScreenPal.Handle;
Begin
  If Active And (ItsTime mod ScreenPalSpeed=0) then Begin
    SFade;
    If Done And Up Then begin SetTarget(RekaPal); Up:=False; Done:=False; End;
    If Done And not UP then active:=False;
  End;
End;

{}
Constructor TShowScore.Init (Score : word);
Var
  temp : string;
Begin
  Str (Score,Temp);
  WriteStr (10,240-12,True,Temp)
End;

{General}

Procedure RandomLevel;
Var
  X,Y :Byte;
Begin
  Player[Player1].init(Player1);
  CurrNumMons:=Random (MaxMons)+1;
  MonsterSpeed:=Random(5000)+5000;
  MHole.Init(Random(19),Random(13));
  CurrNumSack:=Random (MaxSack)+1;
  For X:=1 To CurrNumSack Do
    VarSack[X].Init(Random(19),Random(13));
  For X:=0 To 19 Do
    For Y:=0 To 13 Do
      If level[x,y]=Clum Then
        Case RanDom(10) Of
          0..4  : Level[X,Y]:=Dframe1+DownDirt;
          5..8  : Level[X,Y]:=Dirt+DownDirt;
          9..10 : Level[X,Y]:=Wall+DownDirt;
        End;
End;

Procedure DeInitAllMons;
Var
  Xc : Byte;
Begin
  For Xc:=1 To CurrNumMons Do
    Monster[Xc].Active:=False;
End;

Procedure RunLevel;
Var
  Xc,Yc : byte;
Begin
  InitSound(CheersSound);
  For xc:= 0 to 19 do
    For yc:= 0 to 13 do
      Level[Xc,Yc]:=Clum;
  Inc(CurrLevel);
  Fire[Player1].FireTime:=1;
  DiamondNum:=0;
  RandomLevel;
  DeInitAllMons;
  Fire[Player1].Active:=False;
  LevelOnScreen;
End;

Procedure HandleAllMonsters;
Var
  C : byte;
Begin
  For C:=1 to CurrNumMons do
    Monster[C].Handle;
End;

Procedure CheckForDoneLvl;
Begin
  If LvlDone then RunLevel;
End;

Procedure HandleAllSacks;
Var
  C : byte;
Begin
  For C:=1 to CurrNumSack do
    VaRSack[C].Handle;
End;


Procedure Init;
Var
  X,Y : Byte;
Begin
  Randomize;
  Repeat Until ResetDSP(2);
  SpeakerOn;
  DiamondNum:=0;
  New(Font);
  LoadFont;
  LoadALlPics;
  LoadAllWav;

  Player[Player1].Init(Player1);
  Fire[Player1].Init;
  Player[Player2].Init(Player2);
  Fire[Player2].Init;

  ItsTime := 1;
  KeyInit;
  MMusic.FileName:=MSCFileName;
  LoadSong(MMusic);
  SetXMode;
  Pal(17,  0, 0, 0);
  ScreenPal.Init(RekaPal);
  RunLevel;
  WriteStr(115,229,False,'DIGGER VER 1');
  If MMusic.SongOK Then Begin
    StartMusic(MMusic.Song,False,True);
  End;
End;

Procedure DeInit;
Var
  P: PalType;
Begin
  FillPalType( P, 0, 0, 0 );
  If MMusic.SongOK Then Begin
    FadeMusic;
    WaitRetrace;
    Fade2Pal( P, 0, 255, 1 );
    ClearSong(MMusic);
  End else Fade2Pal( P, 0, 255, 0 );
  UnLoadAllWav;
  SpeakerOff;

  Dispose(Font);
  WaitRetrace;
  SetTextMode;
  KeyDone;
  WriteLn(ExitMsg);
End;

Procedure DrawScreen;
Var
  Xc,Yc : Byte;
Begin
  For Yc:=0 To 13 Do
    For Xc:=0 To 19 Do
      Write(TrackScreen[Xc,Yc]:4);
End;

{}

Begin
{  If Check Then Begin}
    Init;
    Repeat
      HandleDiamonds;
      Fire[Player1].Handle;
      HandleAllMonsters;
      HandleAllSacks;
      Player[Player1].HandlePlayer;
      MHole.Handle;
      ScreenPal.Handle;
      CheckForDoneLVL;
      Inc(ItsTime);
      Delay(AbsoluteSpeed);
      Mem[$40:$1a]:=Mem[$40:$1c];
    Until (Port[$60]=1) Or (PLayer[Player1].Lives=0);
    DeInit;
    ClrScr;
{  DrawScreen;}
{  End Else WriteLn(ErrExitMsg);}
End.