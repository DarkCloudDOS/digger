Program Font_Editor;

Uses GamePro,Crt;

Const
  TextColor   : Byte   = 1;
  BackColor   : Byte   = 7;
  Back                 = 25;
  Boxcolor             = 25;
  CursorColor          = 10;
  CurrX       : Byte   = 0;
  CurrY       : Byte   = 0;
  Active      : Char   = #65;
  FntName     : String = 'DEFAULT.FNT';

Type
  PFont = ^Tfont                        ;
  TFont = Array [#40..#90, 0..7] Of Byte;

Var
  Font          : PFont;
  KeyPressed    : Char ;

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

{---- OutPut -------}
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

Procedure ReadStr(X,Y : Word; WithBack : Boolean; Var Str : String);
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

{---Screen-----}
Procedure InitScreen;
Var
  Xc,Yc : Word;
Begin
  WaitRetrace;
  SetXmode;
  New( Font );
  For Xc:=0 To 319 Do
    For Yc:=0 To 239 Do
      Pixel(Xc,Yc,Back);
  For Xc:=200 To 316 Do
    For Yc:=50 To 236 Do
      Pixel(Xc,Yc,23);
End;

Procedure Current;
Var
  Oc : Byte;
Begin
  Oc :=BackColor;
  BackColor:=Back;
  WriteStr(10,150,True,'NAME :');
  WriteStr(10+8+8*6,150,True,Fntname);
  BackColor:=Oc;
  WriteStr(210,62 ,True,'DEL: DELETE ');
  WriteStr(210,72 ,True,'INS: REVERSE');
  WriteStr(210,82 ,True,'F2 : SAVE   ');
  WriteStr(210,92 ,True,'F3 : LOAD   ');
  WriteStr(210,102 ,True,'F4 : NEW    ');
  WriteStr(210,112,True,'ESC: EXIT   ');
End;

Procedure DrawScreen;
Var
  Xc,Yc : Word;
Begin
  For Xc:=0 To 24 Do
    For Yc:=0 to 1 Do
      DrawChar(Xc*12+5,5+Yc*15,True,Chr(40+Yc*25+Xc));
  DrawChar((Xc+1)*12+5,5+Yc*15,True,Chr(40+Yc*25+Xc+1));
  Current;
End;

Procedure DrawBox;
Var
  Xc,Yc : Byte;
Begin
  For Xc:=0 To 8 Do
    For Yc:=0 To 8 Do
      Pixel(210+Xc*12,130+Yc*12,BoxColor);
  Pixel(CurrX*12+210,CurrY*12+130,CursorColor);
  Pixel(CurrX*12+210+12,CurrY*12+130,CursorColor);
  Pixel(CurrX*12+210,CurrY*12+130+12,CursorColor);
  Pixel(CurrX*12+210+12,CurrY*12+130+12,CursorColor);

End;

{---General---}
Procedure ChkBounds;
Begin
  If CurrX=8   Then CurrX:=0;
  If CurrX=255 Then CurrX:=7;
  If CurrY=8   Then CurrY:=0;
  If CurrY=255 Then CurrY:=7;
End;

Procedure DrawInBox(X,Y : Byte; On : Boolean);
Var
  Xc,Yc, Color : Byte;
Begin
  If On Then Color:=TextColor Else
             Color:=BackColor;
  For Xc:=1 To 11 Do
    For Yc:=1 To 11 Do
      Pixel(Xc+210+X*12,Yc+130+Y*12,Color);
End;

Procedure DrawIT(On : Boolean);
Begin
  SetBit(Font^[Active,CurrY],CurrX,On);
  DrawInBox(CurrX,CurrY,On);
  DrawScreen;
End;

Procedure SetActive;
Var
  Xc,Yc : Byte;
Begin
  For Xc:=0 To 7 Do
    For Yc:=0 To 7 Do
      If GetBit(Font^[Active,Yc],Xc) Then DrawInBox(Xc,Yc,True) Else
                                               DrawInBox(Xc,Yc,False);
End;

{---Disk-------}
Function Exist : Boolean;
Var
  F  : File;
Begin
  Assign(F,Fntname);
  {$I-}
  Reset(F);
  Close(F);
  {$I+}
  Exist:= IOResult=0;
End;

Procedure SetName;
Var
  Xc,Yc : Word;
Begin
  WriteStr(10,140,True,'NEW  :');
  ReadStr (10+8+8*6,140,False,FntName);
  For Xc:=10 To 195 Do
    For Yc:=140 To 148 Do
      Pixel(Xc,Yc,Back);
  For Xc:=10+8+8*6 To 195 Do
    For Yc:=150 To 158 Do
      Pixel(Xc,Yc,Back);
  Current;
End;

Procedure LoadFnt(On : Boolean);
Var
  Xc    : Char;
  Yc    : Byte;
  F     : File;
  xx,yy : Word;
Begin
  If Exist Or (Not On) Then Begin
    Assign (F,FntName);
    If On Then Reset(F,SizeOf(Font^)) Else ReWrite(F,SizeOf(Font^));
    If On Then BlockRead(F,Font^,1) Else
               BlockWrite(F,Font^,1);
    Close(F);
    If On Then Begin
      DrawScreen;
      SetActive;
    End;
  End Else Begin
    WriteStr(10,190,TRUE,'FILE NOT FOUND.');
    WriteStr(10,200,TRUE,'PRESS ANY KEY.');
    If ReadKey=#0 Then ReadKey;
    For XX:=10 To 10+8*15 Do
      For YY:=190 To 208 Do
        Pixel(XX,YY,Back);
  End;
End;

Procedure ReverseActive;
Var
  Xc : Byte;
Begin
  For Xc:=0 To 7 Do
    Font^[Active,Xc]:=Not Font^[Active,Xc];
  SetActive;
  DrawScreen;
End;

Procedure DelActive;
Begin
  FillChar(Font^[Active],8,0);
  SetActive;
  DrawScreen;
End;

Procedure HandleSpecial;
Begin
  KeyPressed:=ReadKey;
  Case KeyPressed Of
    {Arrows}
    #80 : CurrY:=CurrY+1;
    #72 : CurrY:=CurrY-1;
    #77 : CurrX:=CurrX+1;
    #75 : CurrX:=CurrX-1;

    {F ...}
   {#59 : Help;}
    #60 : LoadFnt(False);
    #61 : LoadFnt(True);
    #62 : SetName;

    {Ins}
    #82 : ReverseActive;
    #83 : DelActive; {Del}

  End;
  ChkBounds;
  DrawBox;
End;

Procedure HandleFuncs;
Begin
  Case KeyPressed Of
    #0       : HandleSpecial;
    #13      : DrawIt(True);
    #32      : DrawIt(False);
    #40..#90 : Begin
                 Active:=KeyPressed;
                 SetActive;
               End;
  End;
End;

Procedure WhereXY;
Begin
  DrawChar(10    ,120,True,'(');
  DrawChar(10+8  ,120,True,Chr(48+CurrX));
  DrawChar(10+8*2,120,True,',');
  DrawChar(10+8*3,120,True,Chr(48+CurrY));
  DrawChar(10+8*4,120,True,')');
End;

Begin
   If Exist Then Begin
     InitScreen;
     LoadFnt(True);
     WriteStr(10,70,False,'FONT EDITOR');
     WriteStr(10,80,False,'BY AK');
     WriteStr(10,90,False,'VER-1.56');
     DrawBox;
     WhereXY;
     Repeat
       GetKey(KeyPressed);
       HandleFuncs;
       WhereXY;
     Until KeyPressed=#27;
     Dispose(Font);
     SetTextMode;
     WriteLn(#10,#13,'bye...',#13,#10);
   End Else
   WriteLn(#10,#13,'Could not initalize font. (',FntName,') Not Found.',#13,#10);
End.