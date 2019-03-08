Program The_LE;
Uses CRT,Xtndmode;
Const
  setimg=0; getimg=1;
  PicName       : String       = 'c:\ter4\download\DEFAULT.PIC';
  AutoLoad                     = NOT True;
  LvlName       : String       = 'LEVEL.001';
  CurPic        : Byte         = 1;
  CurX          : Byte         = 0;
  CurY          : Byte         = 0;
  OldX          : Byte         = 0;
  OldY          : Byte         = 0;
  Active        : Byte         = 0;
  {Colors}
  BackColor                    = 023;
  Color1                       = 021;  {Darker  then Back}
  Color2                       = 027;  {Lighter then Normal}
  Shadow                       = 019;  { Frame  }
  Normal                       = 025;  {   -    }
  Light                        = 030;  { Consts }
  PntC  : Array [1..9] of Byte = (240,216,191,120,2,48,10,72,96);
  {Sizes}
  SizeX                        = 20;
  SizeY                        = 14;
  PSizeX                       = 16;
  PSizeY                       = 16;
  PicNumber                    = 68;
  { Screen Mask }
  DownDirt     = $80;
  Clum         = 0;
  Player1      = 1;
  Player2      = 2;
  Monster1     = 3;
  Monster2     = 4;
  Sack         = 5;
  Shot         = 6;
  Cherry       = 7;
  DFrame1      = 8; {Diamond}
  Dirt         = 9;
  FallingSack  = 10;
  ExplodedSack = 11;
  MonHole      = 12;

  {Places}
  Sx   = 30;  Sy   = 30;
  infX = 420; infY = 100;
  CrX  = infX+124; CrY  = infY+207;
  DrMx = infX+014; DrMy = InfY+210;
  DwnX = 450; DwnY = 80;

  StartPlaceX : byte = 255;
  StartPlaceY : byte = 255;

  Ver                          = 'THE LEVEL EDITOR VER 1.00, 1996(c)';
Type
  Plevel = ^TLevel;
  TLevel = Array [0..SizeX-1,0..SizeY-1]    Of Byte;
  PBox   = ^Tbox;
  TBox   = Array [0..PsizeX-1,0..PsizeY-1]  Of Byte;
  TPic   = Array [0..PicNumber-1] Of tbox;
  PFont  = ^TFont;
  Tletter= Array [0..15] of Byte;
  TFont  = Array [#0..#255] Of Tletter;

Var
  Level         : PLevel ;
  Pic           : TPic   ;
  Font          : PFont  ;
  PicC,
  CrsrCol       : Byte;
  DrawMode,
  Cdown         : Boolean;
  Time          : LongInt;

Procedure Putpic (x,y,num : Word);
Var Xc,Yc : Byte;
Begin
  For xc:= 0 to PsizeX-1 do
    For Yc:= 0 to PSIzeY-1 do
      Pixel (X+xc,y+yc,Pic[num,xc,yc]);
End;

{ 컴 Bit Setting 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴� }
{Procedure SetBit( Var B; N: Byte; TurnOn: Boolean ); Assembler;
Asm
   LES  DI,     B
   MOV  AX,     1
   MOV  CL,     N
   SHL  AX,     CL
   CMP  TurnOn, TRUE
   JE   @SetOn
   JMP  @SetOff

@SetOn:
   OR   ES:[DI],AX
   JMP  @End
@SetOff:
   NOT  AX
   AND  ES:[DI],AX
   JMP  @End
@End:
End;}
Procedure XorBit( B: Word; N:byte );
Begin  B:=B xor (1 shl N); End;

Function  GetBit( B: Word; N: Byte ): Boolean; assembler;
Asm
   MOV  AX,     B
   MOV  BX,     1
   MOV  CL,     N
   SHL  BX,     CL
   AND  AX,     BX
   JZ   @END
   MOV  AX,     TRUE
@END:
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
  If On Then
    Begin
      For C := X1 To X2 Do Begin Pixel (C,Y1,Light); Pixel (C,Y2,Shadow); End;
      For C := Y1 To Y2 Do Begin Pixel (X1,C,Light); Pixel (X2,C,Shadow); End;
    End Else
    Begin
      For C := X1 To X2 Do Begin Pixel (C,Y1,Shadow); Pixel (C,Y2,Light); End;
      For C := Y1 To Y2 Do Begin Pixel (X1,C,Shadow); Pixel (X2,C,Light); End;
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
{Pic}
Procedure LoadPics;
Var
  F : File;
Begin
  Assign(F,PicName);
  Reset(F,1);
  BlockRead(F,Pic,SizeOf(TPic));
  Close(F);
End;

{Font}
Procedure getsetimage(chr:char; var data; getset:byte; size:word); assembler;
asm
  push ds
  mov al,32
  mul [chr]
  cmp getset,getimg
  je @goget
  mov di,ax
  mov ax,0a000h
  mov es,ax
  mov cx,size
  shl cx,1
  lds si,data
  jmp @start
 @goget:
  mov si,ax
  mov ax,0a000h
  mov ds,ax
  mov cx,size
  shl cx,1
  les di,data
 @start:
  cli
  mov dx,03c4h; mov ax,0402h; out dx,ax; mov ax,0704h; out dx,ax
  mov dx,03ceh; mov ax,0204h; out dx,ax; mov ax,0005h; out dx,ax; mov ax,0006h; out dx,ax
  rep movsw
  mov dx,03c4h; mov ax,0302h; out dx,ax; mov ax,0304h; out dx,ax
  mov dx,03ceh; mov ax,0004h; out dx,ax; mov ax,1005h; out dx,ax; mov ax,0e06h; out dx,ax
  sti
  pop ds
end;

Procedure LoadFont;
Var
  c: Byte;
Begin
  New(Font);
  for c:= 0 to 255 do
    GetSetimage(chr(c),Font^[chr(c)],GetImg,16);
End;
Procedure InitFnt;
Begin
  New(Font);
  LoadFont;
End;

Procedure WriteChr (x,y,c :Word; lt : tletter);
var xc,yc : byte;
begin
  For yc:= 0 to 15 do
    For xc:= 0 to 7 do
      if GetBit(lt[yc],7-xc) then Pixel(x+xc,y+yc,c and not $FF00)
                             else Pixel(x+xc,y+yc,c shr 8);
End;

Procedure WriteStr(X,Y : Word; Col: Word; Str:String);
Var
  Xc : Byte;
Begin
  For Xc:=1 To Ord(Str[0]) Do
    WriteChr(X+(Xc-1)*9,Y,Col, Font^[Str[Xc]])
End;

Procedure GetKey( Var Ch : Char);
Begin
  Ch:=ReadKey;
  If Ch In [#97..#122] Then Ch:=Chr(Ord(Ch)-32) Else
End;

{Procedure ReadStr(X,Y : Word; Var Str : String);
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
End;    }

Procedure DoneFnt;
Begin
  Dispose (Font);
End;
{Pics}
Const
  Px = 80; Py=320;
  PicSt : Array [1..9] of string[15] =
     ( ' Starting Place','     Sack      ','    Diamond    ',
       '     Mons      ','  Mons'' Hole  ','    Cherry     ',
       '    DownDirt   ','     Stone     ','     Clum      ' );
  PicCode : Array[1..9] of byte =
    ( Player1,Sack,Dframe1+DownDirt,MOnster1,MonHole,Cherry,DownDirt,Dirt+DownDirt,Clum );
  numPic : array[0..12] of byte =
    ( 9,1,1,4,4,2,0,6,3,8,0,0,5 );
  CherryPic = 54;
  DirtPic   = 55;
  Pics : Array [1..5,1..4] of byte = ( ( 12,13,14,15 ),   {Digger Start Place}
                                       ( 40,40,42,43 ),   {Sack}
                                       ( 64,65,66,67 ),   {Diamond}
                                       ( 16,17,18,19 ),   {Mons}
                                       ( 56,56,57,57 ) ); {MonsHole}
Var DiamoPic  : Tbox;

Function Code2Pic(cd : byte) : byte;
var c:byte;
Begin For C:=1 to 9 do if PicCode[C]=cd then Code2Pic:=cd; End;
Function pic2Num(pc: byte) :byte;
var c:Byte;
begin For c:= clum to monhole do if numpic[c]=pc then pic2num:=c; end;
Procedure RefreshPics;
Begin
  Inc(PicC);
  PicC:= ((PicC-1) and 3)+1;
  If CurPic <6 then
  PutPic(Px+PsizeX*CurPic+(10*CurPic)-8,Py+PsizeY div 2,Pics[CurPic,PicC]);
End;

Procedure PicNum(col:Word);
Begin
  WriteChr(Px+PsizeX*CurPic+10*CurPic-3,Py+3*PsizeY div 2 +4,col,Font^[chr(curPic+48)]);
End;
{-----Cursor----}
Procedure DrawCursor;
Var
  Xc,Yc,x,y:Byte;
  T1,T2:String[3];
Begin
  For Xc := 1 to 4 do Pixel(Sx+(OldX+1)*(PsizeX+1)+xc,Sy+(OldY+1)*(PsizeY+1)   ,{Normal}Color1);
  For Yc := 1 to 4 do Pixel(Sx+(OldX+1)*(PsizeX+1)   ,Sy+(OldY+1)*(PsizeY+1)+yc,{Normal}Color1);
  For Xc := 1 to 4 do Pixel(Sx+(OldX+1)*(PsizeX+1)+xc,Sy+(OldY+2)*(PsizeY+1)   ,{Normal}Color1);
  For Yc := 1 to 4 do Pixel(Sx+(OldX+1)*(PsizeX+1)   ,Sy+(OldY+2)*(PsizeY+1)-yc,{Normal}Color1);
  For Xc := 1 to 4 do Pixel(Sx+(OldX+2)*(PsizeX+1)-xc,Sy+(OldY+1)*(PsizeY+1)   ,{Normal}Color1);
  For Yc := 1 to 4 do Pixel(Sx+(OldX+2)*(PsizeX+1)   ,Sy+(OldY+1)*(PsizeY+1)+yc,{Normal}Color1);
  For Xc := 1 to 4 do Pixel(Sx+(OldX+2)*(PsizeX+1)-xc,Sy+(OldY+2)*(PsizeY+1)   ,{Normal}Color1);
  For Yc := 1 to 4 do Pixel(Sx+(OldX+2)*(PsizeX+1)   ,Sy+(OldY+2)*(PsizeY+1)-yc,{Normal}Color1);

  For Xc := 1 to 4 do Pixel(Sx+(CurX+1)*(PsizeX+1)+xc,Sy+(CurY+1)*(PsizeY+1)   ,PntC[CrsrCol]);
  For Yc := 1 to 4 do Pixel(Sx+(CurX+1)*(PsizeX+1)   ,Sy+(CurY+1)*(PsizeY+1)+yc,PntC[CrsrCol]);
  For Xc := 1 to 4 do Pixel(Sx+(CurX+1)*(PsizeX+1)+xc,Sy+(CurY+2)*(PsizeY+1)   ,PntC[CrsrCol]);
  For Yc := 1 to 4 do Pixel(Sx+(CurX+1)*(PsizeX+1)   ,Sy+(CurY+2)*(PsizeY+1)-yc,PntC[CrsrCol]);
  For Xc := 1 to 4 do Pixel(Sx+(CurX+2)*(PsizeX+1)-xc,Sy+(CurY+1)*(PsizeY+1)   ,PntC[CrsrCol]);
  For Yc := 1 to 4 do Pixel(Sx+(CurX+2)*(PsizeX+1)   ,Sy+(CurY+1)*(PsizeY+1)+yc,PntC[CrsrCol]);
  For Xc := 1 to 4 do Pixel(Sx+(CurX+2)*(PsizeX+1)-xc,Sy+(CurY+2)*(PsizeY+1)   ,PntC[CrsrCol]);
  For Yc := 1 to 4 do Pixel(Sx+(CurX+2)*(PsizeX+1)   ,Sy+(CurY+2)*(PsizeY+1)-yc,PntC[CrsrCol]);

  For Xc:= 0 to 1 do For Yc:= 0 to 1 do
    Pixel(Sx+(OldX+Xc+1)*(PSizeX+1),Sy+(OldY+Yc+1)*(PSizeY+1),PntC[1]);
  For Xc:= 0 to 1 do For Yc:= 0 to 1 do
    Pixel(Sx+(CurX+Xc+1)*(PSizeX+1),Sy+(CurY+Yc+1)*(PSizeY+1),PntC[9]);
  Str(CurX,t1); Str(CurY,t2);
  Box(CrX+11,CrY+4,CrX+11+16,CrY+4+16,BackColor);
  Box(CrX+4+5 shl 3,CrY+4,CrX+12+6 shl 3,CrY+4+16,BackColor);
  WriteStr(CrX+11,CrY+4,BackColor shl 8+14,t1);
  WriteStr(CrX+4+5 shl 3,CrY+4,BackColor shl 8+14,t2);
End;
Procedure RefreshCursor;
Var
  Xc,Yc:Byte;
Begin
  If Cdown then Dec(CrsrCol) else Inc(CrsrCol); IF CrsrCol=9 then CDown:=True; If CrsrCol=1 then Cdown:=false;
  For Xc := 1 to 4 do Pixel(Sx+(CurX+1)*(PsizeX+1)+xc,Sy+(CurY+1)*(PsizeY+1)   ,PntC[CrsrCol]);
  For Yc := 1 to 4 do Pixel(Sx+(CurX+1)*(PsizeX+1)   ,Sy+(CurY+1)*(PsizeY+1)+yc,PntC[CrsrCol]);
  For Xc := 1 to 4 do Pixel(Sx+(CurX+1)*(PsizeX+1)+xc,Sy+(CurY+2)*(PsizeY+1)   ,PntC[CrsrCol]);
  For Yc := 1 to 4 do Pixel(Sx+(CurX+1)*(PsizeX+1)   ,Sy+(CurY+2)*(PsizeY+1)-yc,PntC[CrsrCol]);
  For Xc := 1 to 4 do Pixel(Sx+(CurX+2)*(PsizeX+1)-xc,Sy+(CurY+1)*(PsizeY+1)   ,PntC[CrsrCol]);
  For Yc := 1 to 4 do Pixel(Sx+(CurX+2)*(PsizeX+1)   ,Sy+(CurY+1)*(PsizeY+1)+yc,PntC[CrsrCol]);
  For Xc := 1 to 4 do Pixel(Sx+(CurX+2)*(PsizeX+1)-xc,Sy+(CurY+2)*(PsizeY+1)   ,PntC[CrsrCol]);
  For Yc := 1 to 4 do Pixel(Sx+(CurX+2)*(PsizeX+1)   ,Sy+(CurY+2)*(PsizeY+1)-yc,PntC[CrsrCol]);
End;

Procedure FixBounds;
Begin
  If CurX=SizeX  Then CurX:=0 ;
  If CurX=255 Then CurX:=SizeX-1;
  If CurY=SizeY  Then CurY:=0;
  If CurY=255 Then CurY:=SizeY-1;
End;
Procedure DrawInLevel(x,y,p:byte);
Var Xc,Yc: Byte;
Begin
  Case P of
    Clum     : Begin
                 Box(Sx+(X+1)*(PSizeX+1)+1,Sy+(Y+1)*(PSizeY+1)+1,Sx+(X+1)*(PSizeX+1)+PsizeX,
                 Sy+(Y+1)*(PSizeY+1)+PsizeY,0);
                 Level^[X,Y]:=Clum;
               End;
    DownDirt : Begin
                 For Xc:=1 to 16 do
                   For yc:= 1 to 14 do
                     Pixel(Sx+xc+(X+1)*(PsizeX+1),Sy+yc+(Y+1)*(PsizeY+1),0);
                 For Xc:=1 to 16 do
                   For yc:= 15 to 16 do
                     Pixel(Sx+xc+(X+1)*(PsizeX+1),Sy+yc+(Y+1)*(PsizeY+1),Pic[DirtPic,xc-1,yc-1]);
                 Level^[X,Y]:=DownDirt;
               End;
    Player1,
    Player2  : Begin
                 if (startPlaceX<255) and not (Level^[X,Y] in [Player1,player2]) then
                   DrawInLevel(StartPlaceX,StartPlaceY,Level^[X,Y]);
                 startPlaceX:=X; StartPlaceY:=Y;
                 PutPic(Sx+(X+1)*(PSizeX+1)+1,Sy+(Y+1)*(PSizeY+1)+1,Pics[1,1]);
                 Level^[X,Y]:=Player1;
               End;
    Monster1 : Begin
                 PutPic(Sx+(X+1)*(PSizeX+1)+1,Sy+(Y+1)*(PSizeY+1)+1,Pics[4,1]);
                 Level^[X,Y]:=Monster1;
               End;
    Monster2 : Begin
                 PutPic(Sx+(X+1)*(PSizeX+1)+1,Sy+(Y+1)*(PSizeY+1)+1,Pics[4,2]);
                 Level^[X,Y]:=Monster2;
               End;
    Sack     : Begin
                 PutPic(Sx+(X+1)*(PSizeX+1)+1,Sy+(Y+1)*(PSizeY+1)+1,Pics[2,1]);
                 Level^[X,Y]:=Sack;
               End;
    Cherry,Cherry+downDirt   : Begin
                 PutPic(Sx+(X+1)*(PSizeX+1)+1,Sy+(Y+1)*(PSizeY+1)+1,CherryPic);
                 Level^[X,Y]:=Cherry+Downdirt;
               End;
    DFrame1,Dframe1+DownDirt {Diamond}
             : Begin
                 For xc:= 0 to PsizeX-1 do
                   For yc:= 0 to PsizeY-1 do
                     Pixel(Sx+(X+1)*(PSizeX+1)+1+xc,Sy+(Y+1)*(PSizeY+1)+1+yc,DiamoPic[xc,yc]);
                 Level^[X,Y]:=Dframe1+DownDirt;
               End;
    Dirt,Dirt+DownDirt
             : Begin
                 PutPic(Sx+(X+1)*(PSizeX+1)+1,Sy+(Y+1)*(PSizeY+1)+1,DirtPic);
                 Level^[X,Y]:=Dirt+DownDirt;
               End;
    MonHole  : Begin
                 PutPic(Sx+(X+1)*(PSizeX+1)+1,Sy+(Y+1)*(PSizeY+1)+1,Pics[5,1]);
                 Level^[X,Y]:=MonHole;
               End;
    Else Begin
         Level^[X,Y]:=Pics[P,1];
         PutPic(Sx+(X+1)*(PSizeX+1)+1,Sy+(Y+1)*(PSizeY+1)+1,Pics[P,1]);
       End;
  End;
End;

{-----Level-----}
Procedure InitLvl;
Begin
  New(Level);
  FillChar(Level^,SizeOf(TLevel),0);
End;

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
    Reset(Fl,1);
    BlockRead(Fl,Level^,sizeOf(Tlevel));
  End Else Begin
    WriteStr(100,10,LightBlue,'FILE NOT FOUND.');
    WriteStr(100,20,Blue,'PRESS ANY KEY TO CONTINUE');
    If ReadKey=#0 Then ReadKey;
    Box(100,10,320,28,BackColor);
  End;
  Close(Fl);
End;


Procedure DoneLvl;
Begin
  Dispose (Level);
End;

{-----General-----}

Procedure HandleFuncs;
Var xc,yc : byte;K  : Char;
Begin
  K:=ReadKey;
  Case K Of
    { F.. }
{    #59 : Help;}
     #60 : SaveLvl(True);
     #61 : Begin SaveLvl(False);
                 For Xc:= 0 to SizeX-1 do
                   For Yc:= 0 to SizeY-1 do
                     DrawInLevel(xc,yc,code2Pic(level^[Xc,yc]));
           End;
    {Arrows}
    #72..#80 : Begin
                 OldX:=CurX;
                 OldY:=CurY;
                 Case K of
                   #80 : Inc(CurY);
                   #72 : Dec(CurY);
                   #77 : Inc(CurX);
                   #75 : Dec(CurX);
                 End;
                 FixBounds;
                 If DrawMode then drawInLevel(curX,CurY,PicCode[curPIc]);
                 DrawCursor;
               End;
    #83  : If not (CurPic in [1,2,4,5]) then
           For xc:= 0 to SizeX-1 do
             For yc:= 0 to SizeY-1 do
               DrawInLevel(xc,yc,PicCode[CurPic]);
  End;
End;

Procedure HandleAll;
Var Ch : Char;
Begin
  Ch:=Readkey;
  Case upcase(Ch) Of
    #0            : HandleFuncs;
    ',','<'       : Begin if CurPic<6 then PutPic(Px+PsizeX*CurPic+(10*CurPic)-8,Py+PsizeY div 2,Pics[CurPic,1]);
                          PicNum(Normal shl 8+1);
                          Dec(CurPic); If CurPic=0 then CurPic:=9;
                          PicNum(Normal shl 8+14);
                          WriteStr(Px+70,Py+PsizeY*3+4,BackColor shl 8+10,PicSt[CurPic]);
                    End;
    '.','>'       : Begin if CurPic<6 then PutPic(Px+PsizeX*CurPic+(10*CurPic)-8,Py+PsizeY div 2,Pics[CurPic,1]);
                          PicNum(Normal shl 8+1);
                          Inc(CurPic); If CurPic=10 then CurPic:=1;
                          PicNum(Normal shl 8+14);
                          WriteStr(Px+70,Py+PsizeY*3+4,BackColor shl 8+10,PicSt[CurPic]);
                    End;
    #9            : Begin if CurPic<6 then PutPic(Px+PsizeX*CurPic+(10*CurPic)-8,Py+PsizeY div 2,Pics[CurPic,1]);
                          PicNum(Normal shl 8+1);
                          CurPic:=pic2num(code2Pic(Level^[CurX,CurY]));
                          PicNum(Normal shl 8+14);
                          WriteStr(Px+70,Py+PsizeY*3+4,BackColor shl 8+10,PicSt[CurPic]);
                    End;
    #13           : DrawInLevel(CurX,CurY,PicCode[CurPic]);
    'D'           : Begin DrawMode:=Not DrawMode;
                      If DrawMode then WriteChr (DrmX+94,DrmY+2,Color2 shl 8+11,Font^['Y'])
                                  else WriteChr (DrmX+94,Drmy+2,Color2 shl 8 +3,Font^['N'])
                    End;
    '1'..'9'      : Begin if CurPic<6 then PutPic(Px+PsizeX*CurPic+(10*CurPic)-8,Py+PsizeY div 2,Pics[CurPic,1]);
                          PicNum(Normal shl 8+1);
                          CurPic:=Ord(ch)-48;
                          PicNum(Normal shl 8+14);
                          WriteStr(Px+70,Py+PsizeY*3+4,BackColor shl 8+10,PicSt[CurPic]);
                    End;
  End;
End;


Procedure ShowLvl;
Var Xc,Yc,x,y :byte;
Begin
  Frame(Sx,Sy,Sx+(PsizeX+1)*(SizeX+2),sy+(PsizeY+1)*(SizeY+2),False);
  Frame(Sx+1,Sy+1,Sx+(PsizeX+1)*(SizeX+2)-1,sy+(PsizeY+1)*(SizeY+2)-1,False);
  Box(Sx+2,Sy+2,Sx+(PsizeX+1)*(SizeX+2)-2,sy+(PsizeY+1)*(SizeY+2)-2,{Normal}Color1);
  If AutoLoad then Begin
    SaveLvl(False);
    For Xc:= 0 to SizeX-1 do
      For Yc:= 0 to SizeY-1 do
        DrawInLevel(xc,yc,code2Pic(level^[Xc,yc]));
    End else  For Xc:= 0 to SizeX-1 do
                For Yc:= 0 to SizeY-1 do
                  DrawInLevel(xc,yc,Dirt);
  For Xc:= 1 to SizeX+1 do
    For Yc:= 1 to SizeY+1 do
      Pixel (Sx+xc*(PSizeX+1),Sy+yc*(PSizeY+1),pntC[1]);
End;
Procedure ShowPal(x,y,sz : word);
Var xc,Yc  : byte;
Begin
  Frame(x,y,x+2+255,y+1+sz,False);
  For Xc:= 0 to 255 do
    For Yc:= 1 to sz do
      Pixel (x+xc+1,y+yc,xc);
End;
Procedure ShowInfo;
Var Xc,Yc : Byte;
Begin
  Frame(InfX,InfY,InfX+205,infY+240,True);
  Box  (InfX+1,InfY+1,InfX+204,infY+239,Normal);
  WriteChr(InfX+16,InfY+16,Normal shl 8+40,Font^['F']);
  WriteStr(InfX+24,InfY+16,Normal shl 8+12,'ile Name:');
  WriteStr(600-9*length(lvlName),InfY+32,Normal shl 8+42,LvlName);
  ShowPal(infX-50,infY+250,8)
End;

Procedure ShowPics;
Var xc,yc :byte;
Begin
  For xc:= 0 to PsizeX-1 do
    For yc:= 0 to PsizeY-1 do
      If (Pic[Pics[3,1],Xc,Yc] in [0,17]) then DiamoPic[xc,yc]:=Pic[DirtPic,xc,yc]
                                          else DiamoPic[xc,yc]:=Pic[Pics[3,1],xc,yc];
  Frame(Px,Py,Px+11*PSizeX+83,Py+PsizeY*3,True);
  Box(Px+1,Py+1,Px+PSizeX*11+82,Py+PsizeY*3-1,Normal);
  For xC:= 1 to 9 do begin
    Frame (Px+PsizeX*xC+(10*xC)-9,Py+PsizeY div 2-1,Px+(PsizeX)*(xC+1)+(10*xC)-8,Py+(PsizeY*3) div 2,False);
    WriteChr(Px+PsizeX*xC+10*xC-3,Py+3*PsizeY div 2 +4,Normal shl 8 + 1,Font^[chr(xc+48)]);
  End;
  For xc:= 1 to 6 do
    PutPic(Px+PsizeX*xC+(10*xC)-8,Py+PsizeY div 2,Pics[xC,1]);
  Box(Px+PsizeX*9+(10*9)-8,Py+PsizeY div 2,Px+PsizeX*10+(10*9)-9,Py+PsizeY div 2+PsizeY-1,0);
  For Xc:=1 to 16 do
    For yc:= 1 to 14 do
      Pixel(Px+xc+7*PsizeX+61,Py+yc+PsizeY div 2-1,0);
  For Xc:=1 to 16 do
    For yc:= 15 to 16 do
      Pixel(Px+xc+7*PsizeX+61,Py+yc+PsizeY div 2-1,Pic[DirtPic,xc-1,yc-1]);
  PutPic(Px+6*PsizeX+52,Py+PsizeY div 2,CherryPic);
  PutPic(Px+8*PsizeX+72,Py+PsizeY div 2,DirtPic);
End;

Procedure InitScreen;
Begin
  InitXtended(BackColor);
  ShowLvl; ShowInfo;
  Frame(crX,crY,crX+6+8 shl 3,cry+6+16,False);
  box(crX+1,crY+1,crX+5+8 shl 3,cry+5+16,BackColor);
  WriteChr(crx+4 shl 3,cry+4,BackColor shl 8+14,Font^[',']);
  DrawCursor;
  ShowPics;
  Frame(DrmX,DrmY,Drmx+104,DrmY+18,True);
  Box(Drmx+1,DrmY+1,Drmx+103,DrmY+17,Color2);
  Writechr(DrMX+3,DrmY+2,Color2 shl 8 +32,Font^['D']);
  WriteStr(DrMX+3+8,DrmY+2,Color2 shl 8 +1,'raw Mode:');
  DrawMode:=False; WriteChr(DrmX+94,Drmy+2,Color2 shl 8 +3,Font^['N']);
  PicNum(Normal shl 8+14);
  WriteStr(Px+70,Py+PsizeY*3+4,BackColor shl 8+10,PicSt[CurPic]);
End;
Procedure InitAll;
Begin
  InitFnt;
  LoadPics;
  InitLvl;
  InitScreen;
End;

Procedure DoneAll;
Begin
  DoneFnt;
  DoneLvl;
  TextMode(Co80);
  WriteLn ('Bye...');
End;

Begin
  InitAll;
  Repeat
    Repeat
      Inc(Time);
      If Time mod 3500=0 then RefreshCursor;
      If Time mod 10000=0 then RefreshPics;
    Until KeyPressed;

    HandleAll;
  Until Port[$60]=1;
  DoneAll;
End.