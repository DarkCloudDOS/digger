Program Level_Editor;

Uses GamePro,Crt;

Const
  StartY                       = 16;
  Back                         = 25;
  TextColor     : Byte         = 1;
  BackColor                    = 7;
  BoxColor                     = 1;
  Shadow                       = 20;
  Normal                       = 23;
  Light                        = 27;
  CursorColor                  = 10;
  SizeSquare                   = 16;
  Dx                           = 10;
  Dy                           = 10;
  MnuNum                       = 6;
  Mnu           :
  Array[0..MnuNum-1] Of String = ('SAVE FILE','LOAD FILE','LOAD PICS','NEW FILE','ABOUT','RETURN');

  FntName                      = 'DEFAULT.FNT';
  PicName       : String       = 'DEFAULT.PIC';
  LvlName       : String       = 'DEFAULT.LVL';
  CurX          : Byte         = 0;
  CurY          : Byte         = 0;
  OldX          : Byte         = 0;
  OldY          : Byte         = 0;
  Active        : Byte         = 0;
  PicNumber                    = 54;


  Ver                          = 'LEVEL EDITOR VER 1.45, 1996(c)';

Type
  Plevel = ^TLevel;
  TLevel = Array [0..19,0..13]    Of Byte;
  PBox   = ^Tbox;
  TBox   = Array [0..15,0..15]    Of Byte;
  PPic   = ^Tpic;
  TPic   = Array [0..PicNumber-1] Of tbox;
  PFont  = ^TFont;
  TFont  = Array [#40..#90, 0..7] Of Byte;

Var
  Level         : PLevel ;
  Pic           : PPic   ;
  Font          : PFont  ;
  CurPal,PPAl,
  ExtraPal      : PalType;
  KeyPressed    : Char   ;

{-----Cursor----}
Procedure DrawCursor;
Begin
                                  Pixel(OldX*SizeSquare              ,StartY+OldY*SizeSquare            ,BoxColor);
  If (OldY<13)               Then Pixel(OldX*SizeSquare              ,StartY+OldY*SizeSquare+SizeSquare ,BoxColor);
  If (OldX<19)               Then Pixel(OldX*SizeSquare+SizeSquare   ,StartY+OldY*SizeSquare            ,BoxColor);
  If (OldX<19) And (OldY<13) Then Pixel(OldX*SizeSquare+SizeSquare   ,StartY+OldY*SizeSquare+SizeSquare ,BoxColor);

                                   Pixel(CurX*SizeSquare              ,StartY+CurY*SizeSquare            ,CursorColor);
  If (CurY<13)               Then  Pixel(CurX*SizeSquare              ,StartY+CurY*SizeSquare+SizeSquare ,CursorColor);
  If (CurX<19)               Then  Pixel(CurX*SizeSquare+SizeSquare   ,StartY+CurY*SizeSquare            ,CursorColor);
  If (CurY<13) And (CurX<19) Then  Pixel(CurX*SizeSquare+SizeSquare   ,StartY+CurY*SizeSquare+SizeSquare ,CursorColor);
End;

Procedure FixBounds;
Begin
  If CurX=20  Then CurX:=0 ;
  If CurX=255 Then CurX:=19;

  If CurY=14  Then CurY:=0;
  If CurY=255 Then CurY:=13;

  If Active=PicNumber Then Active:=0;
  If Active=255 Then Active:=PicNumber-1;
End;

{---- Bit Setting ----}
Procedure SetBit( Var Number : Byte; BitNum : Byte; Destination : Boolean);
Begin
  If Destination Then Number := Number Or (1 Shl BitNum) Else
                      Number := Number And Not (1 Shl BitNum);
End;

Function GetBit( Number, BitNum : Byte) : Boolean;
Begin
  GetBit := Number And (1 Shl BitNum)<>0;
End;

{---Graphics---}
Procedure Box( X1,Y1, X2,Y2 : Word; C : Byte );
Var
  Xc,Yc : Word;
Begin
  For Xc:=X1 To X2 Do
    For Yc:=Y1 To Y2 Do
      Pixel (Xc,Yc,C);
End;

Procedure Frame(X1,Y1,X2,Y2 : Word; On : Boolean);
Var
  C : Word;
Begin
  If On
  Then
    Begin
      For C := X1 To X2 Do
        Begin
          Pixel (C,Y1,Light);
          Pixel (C,Y2,Shadow);
        End;
      For C := Y1 To Y2 Do
        Begin
          Pixel (X1,C,Light);
          Pixel (X2,C,Shadow);
        End;
    End
  Else
    Begin
      For C := X1 To X2 Do
        Begin
          Pixel (C,Y1,Shadow);
          Pixel (C,Y2,Light);
        End;
      For C := Y1 To Y2 Do
        Begin
          Pixel (X1,C,Shadow);
          Pixel (X2,C,Light);
        End;
    End;
End;

{-----Disk-----}

Function Exist(Name : String) : Boolean;
Var
  F  : File;
Begin
  Assign(F,name);
  {$I-}
  Reset(F);
  Close(F);
  {$I+}
  Exist:= IOResult=0;
End;

{Font}

Procedure LoadFont;
Var
  Xc    : Char;
  Yc    : Byte;
  F     : File Of Byte;
  xx,yy : Word;
Begin
  Assign (F,FntName);
  Reset(F);
  For Xc:=#40 To #90 Do
    For Yc := 0 To 7 Do
      Read(F,Font^[Xc,Yc]);
  Close(F);
End;

Procedure InitFnt;
Begin
  New(Font);
  LoadFont;
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

Procedure GetKey( Var Ch : Char);
Begin
  Ch:=ReadKey;
  If Ch In [#97..#122] Then Ch:=Chr(Ord(Ch)-32) Else
End;

Procedure ReadStr(X,Y : Word; Var Str : String);
Var
  Xc,Yc : Word  ;
  Key   : Char  ;
  StrC  : String;
Begin
  StrC[0]:=Chr(0);
  Repeat
    For Yc:=0 To 7 Do Pixel(Ord(StrC[0])*8+X,Y+Yc,TextColor);
    GetKey(Key);
    If Key=#32 Then Key:=#64;
    Case Key Of
      #40..#90 : Begin
                   StrC:=StrC+Key;
                   DrawChar(X+(Ord(StrC[0])-1)*8,Y,True,Key);
                 End;
      #8       : If StrC[0]>#0 Then Begin
                   For Yc:=0 To 7 Do Pixel(Ord(StrC[0])*8+X,Y+Yc,BackColor);
                   DrawChar(X+(Ord(StrC[0])-1)*8,Y,True,#64);
                   StrC[0]:=Chr(Ord(StrC[0])-1);
                 End;
      #0       : Key:=ReadKey;
    End;
  Until Key In [#13,#27];
  If Key=#13 Then Str:=StrC;
End;

Procedure DoneFnt;
Begin
  Dispose (Font);
End;

{-----Level-----}
Procedure InitLvl;
Begin
  New(Level);
  FillChar(Level^,SizeOf(Level^),0);
End;

Procedure LoadLevel;
Var
  F : File;
Begin
  Assign(F,LvlName);
  Reset(F,SizeOf(Tlevel));
  BlockRead(F,Level^,1);
  Close(F);
End;

Procedure DoneLvl;
Begin
  Dispose (Level);
End;

{-----General-----}
Procedure SaveLvl ( B : boolean);
Var
  Xc : Byte;
  Fl : File;
Begin
  Assign(Fl,LvlName);
  If B Then Begin
    Rewrite(Fl,1);
    BlockWrite(Fl,Level^,SizeOf(TLevel));
  End Else If Exist(LvlName) Then Begin
    Reset(Fl,SizeOf(TLevel));
    BlockRead(Fl,Level^,1);
  End Else Begin
    WriteStr(100,10,True,'FILE NOT FOUND.');
    WriteStr(100,20,True,'PRESS ANY KEY TO CONTINUE');
    If ReadKey=#0 Then ReadKey;
    Box(100,10,320,28,Back);
  End;
End;

Procedure CurrName;
Begin
  Box(50,200,300,208,Back);
  WriteStr(50,200,True,'CURRENT FILE :'+LvlName);
End;

Procedure SetLvlName;
Begin
  Box(50+8*14,200,300,208,Back);
  ReadStr(50+14*8,200,LvlName);
  CurrName;
End;

Procedure HandleMnu;
Var
  Op,
  Yc,
  Xc,
  Oc    : Byte;
  K     : Char;
  Mexit : Boolean;
Begin
  For Xc:=80 To 2*80 Do Begin
    SetShowFrom(240*Xc);
    Delay(5);
  End;
  WritePage(2);
  Yc:=MnuNum-1;
  MExit:=False;
  Oc := TextColor;
  TextColor := 10;
  WriteStr(Dx+4,Dy+5+Yc*10,False,Mnu[Yc]);
  Op := MnuNum-1;
  Repeat
    K  := ReadKey;
    Case K Of
      #0  : Begin
              K:=ReadKey;
              Case K Of
                #72 : Yc:=Yc-1;
                #80 : Yc:=Yc+1;
              End;
            End;
      #13 : Case Yc Of
              0 : SaveLvl(True);
              1 : SaveLvl(False);
              2 : SetLvlName;
              MnuNum-1 : MExit := true;
            End;
      #27 : begin Yc := MnuNum-1; Delay(5); Mexit := True; End;
    End;
    If Yc=255 Then Yc:=MnuNum-1;
    If Yc=MnuNum Then Yc:=0;
    TextColor := Oc;
    WriteStr(Dx+4,Dy+5+Op*10,False,Mnu[Op]);
    Op := Yc;
    TextColor:=10;
    WriteStr(Dx+4,Dy+5+Yc*10,False,Mnu[Yc]);
  Until MExit;
  TextColor := Oc;
  For Xc:=2*80 DownTo 80 Do Begin
    SetShowFrom(240*Xc);
    Delay(5);
  End;
  WritePage(1);
End;

Function  PictureNumber : Byte;
Begin
  PictureNumber:=Active-44+$80;
End;

Procedure DrawActive(NotOut , ON : Boolean);
Var
  Xc,Yc : Byte;
Begin
    If On Then Begin
      For Yc:=0 To 15 Do
        For Xc:=0 To 15 Do If NotOut Then Pixel(Xc+208,Yc,Pic^[Active,Xc,Yc]) Else
                                          Pixel(Xc+SizeSquare*CurX,StartY+Yc+SizeSquare*CurY,Pic^[Active,Xc,Yc]);
      Level^[CurX,CurY]:=PictureNumber;
    End Else Begin
      Box(CurX*SizeSquare,CurY*SizeSquare+StartY,(CurX+1)*SizeSquare-1,(CurY+1)*SizeSquare+StartY-1,Back);
      Level^[CurX,CurY]:=$80;
    End;
    DrawCursor;
End;

Function B2S (B : Byte) : String;
Var
  Num : String;
Begin
  Str (B,Num);
  B2S := Num;
End;

Procedure PicNum;
Var
  Num :String;
Begin
  Num:=B2S(Active);
  DrawChar(150,2,True,'(');
  WriteStr(150+8,2,True,Num);
  DrawChar(150+8+8*Ord(Num[0]),2,True,')');
  If Active<10  Then WriteStr(150+8*2+8*Ord(Num[0]),2,True,' ');
  WriteStr(280,2,True,B2S(PictureNumber));
End;

Procedure WhereXY;
Var
  NumX,
  NumY  :String;
Begin
  NumX:=B2S(CurX);
  NumY:=B2S(CurY);
  DrawChar(10                     ,2,True,'(');
  WriteStr(10+8                   ,2,True,NumX);
  DrawChar(10+8+8*Ord(NumX[0])    ,2,True,',');
  WriteStr(10+8+8*(Ord(NumX[0])+1),2,True,NumY);
  WriteStr(10+8+8*(Ord(NumX[0])+Ord(NumY[0])+1),2,True,') ');
End;

Procedure InitHelp;
Begin
  WritePage(0);
  WriteStr(30,15,True,  '<>     : PIC NUM               ');
  WriteStr(30,24,True,  'SPACE  : DELETE                ');
  WriteStr(30,33,True,  'F1     : HELP                  ');
  WriteStr(30,42,True,  'F2     : SAVE                  ');
  WriteStr(30,51,True,  'F3     : LOAD                  ');
  WriteStr(30,60,True,  'F4     : NEW NAME              ');
  WriteStr(30,69,True,  'F5     : NUMBER                ');
  WriteStr(30,78,True,  'F6     : NEW                   ');
  WriteStr(30,87,True,  'F7     : SAVE CURRENT COLOR    ');
  WriteStr(30,96,True,  'F8     : CHOSSE PICTURE        ');
  WriteStr(30,105,True, 'F10    : MENU                  ');
  WriteStr(30,114,True, 'ESC    : EXIT                  ');
  WriteStr(30,123,True, '0..9   : GET SAVED COLOR       ');
  WriteStr(30,132,True, '(C)    : COPY PICTURE          ');
  WriteStr(30,141,True, '(P)    : PASTE                 ');
  WriteStr(30,150,True, 'HOME   : TURN PICTURE LEFT     ');
  WriteStr(30,159,True, 'PGUP   : TURN PICTURE RIGHT    ');
  WriteStr(30,168,True, 'END    : GET LAST PICTURE      ');
  WriteStr(30,177,True, 'PGDOWN : GET FIRST PICTURE     ');
  WriteStr(30,186,True, '(ENTER): DRAW A POINT          ');
  WriteStr(30,195,True, '(TAB)  : GET COLOR             ');
  WriteStr(13,210,False,'PRESS ANY KEY TO RETURN TO THE EDITOR');
  WritePage(1);
End;

Procedure Help;
Var
  Xc : Byte;
Begin
  For Xc:=80 DownTo 0 Do
    Begin
      SetShowFrom(Xc*240);
      Delay(5);
    End;
  If ReadKey=#0 Then ReadKey;
  For Xc:=0 To 80 Do
    Begin
      SetShowFrom(Xc*240);
      Delay(5);
    End;
End;

Procedure HandleFuncs;
Begin
  OldX:=CurX;
  OldY:=CurY;
  KeyPressed:=ReadKey;
  Case KeyPressed Of
    { F.. }
    #59 : Help;
    #60 : HandleMnu;
    {Arrows}
    #80 : CurY:=CurY+1;
    #72 : CurY:=CurY-1;
    #77 : CurX:=CurX+1;
    #75 : CurX:=CurX-1;
  End;
  FixBounds ;
  WhereXY;
  DrawCursor;
End;

Procedure HandleAll;
Begin
  Case KeyPressed Of
    #0            : HandleFuncs;
    ',','<'       : Begin Active:=Active-1; FixBounds; PicNum; DrawActive(True,True); End;
    '.','>'       : Begin Active:=Active+1; FixBounds; PicNum; DrawActive(True,True); End;
    #13           : DrawActive(False,True);
    #32           : DrawActive(True,False);
    #9            : Begin Active:=(Level^[CurX,CurY] And $000F); PicNum; DrawActive(True,True); End;
  End;
End;

{-----Screen---}
Procedure FadeOut1;
Begin
  GetAllPal(CurPal);
  FillPalType(ExtraPal,0,0,0);
  Fade2Pal(ExtraPal,0,255,10);
  ClrScr;

  SetXMode;

  GetAllPal(PPal);
  SetAllPal(ExtraPal);
End;

Procedure FadeOut2;
Begin
  Fade2Pal(ExtraPal,0,255,10);
  SetTextMode;
  WriteLn;
  WriteLn('Bye...');
  WriteLn;
  SetAllPal(ExtraPal);
  Fade2Pal(CurPal,0,255,10);
End;

Procedure FadeIn;
Begin
  Fade2Pal(PPal,0,255,10);
End;

Procedure InitBox;
Var
  Xc,Yc : Word;
Begin
  For Xc:= 0 To 19 Do
    For Yc:= 0 To 13 Do
      Pixel (Xc*SizeSquare,StartY+Yc*SizeSquare,BoxColor);
End;

Procedure InitScreen;
Var
  Yc : Byte;
Begin
  FadeOut1;
  FillChar(Mem[$A000:000],80*240*3,Back);
  WritePage(2);
  Frame(Dx,Dy,Dx+10*8,Dy+200,True);
  Box  (Dx+1,Dy+1,Dx+10*8-1,Dy+200-1,Normal);
  For Yc := 0 to MnuNum-1 do
    WriteStr(Dx+4,Dy+5+Yc*10,False,Mnu[Yc]);
  CurrName;
  WritePage(1);
  ShowPage(1);
  Box(0,0,319,15,10);
  WriteStr(80,2,False,'PIC NUM:');
  PicNum;
  DrawActive(True,True);
  DrawCursor;
  WhereXY;
  InitBox;
  InitHelp;
  FadeIn;
End;

Procedure DoneScreen;
Begin
  FadeOut2;
End;

{-----Pic-----}
Procedure LoadPic;
Var
  F : File;
Begin
  Assign(F,PicName);
  Reset(F,SizeOf(TPic));
  BlockRead(F,Pic^,1);
  Close(F);
End;

Procedure InitPic;
Begin
  New(Pic);
  LoadPic;
End;

Procedure DonePic;
Begin
  Dispose (Pic);
End;

Procedure InitAll;
Begin
  InitFnt;
  InitPic;
  InitLvl;
  InitScreen;
End;

Procedure DoneAll;
Begin
  DoneFnt;
  DonePic;
  DoneLvl;
  DoneScreen;
End;

BEGIN
  If Exist(FntName) Then Begin
    InitAll;
    Repeat
      KeyPressed:=ReadKey;
      HandleAll;
    Until Port[$60]=1;
    DoneAll;
  End Else
    WriteLn(#10,#13,'''',FntName,'''',' Is not found.',#7,#10,#13);
END.