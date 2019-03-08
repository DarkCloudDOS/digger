Program PATHFINDER;

Uses Crt;

Var
  Screen : Array [ 0..19, 0..13 ] Of Byte;

Procedure DrawScreen;
Var
  Xc,Yc : Byte;
Begin
  For Yc:=0 To 13 Do Begin
    For Xc:=0 To 19 Do
      Write(Screen[Xc,Yc]:4);
    WriteLn;
  End;
End;

Procedure Init;
Var
  Xc,Yc : Byte;
Begin
  For Xc:=0 To 19 Do
    For Yc:=0 To 13 Do
      If (Yc=9) And (Xc>0) And (Xc<15) Then Screen[Xc,Yc]:=255 Else Screen[Xc,Yc]:=0;
End;

Procedure PathFind(X , Y : Byte);
Var
  Xc,Yc,
  Index     : Byte;
  Finished  : Boolean;
Begin
  Index:=1;
  Screen[X,Y]:=Index;
  Repeat
    Finished:=True;
    For Xc:=0 To 19 Do
      For Yc:=0 To 13 Do
        If Screen[Xc,Yc]=Index Then Begin
          If (Xc<19) And (Screen[Xc+1,Yc]=0) Then Screen[Xc+1,Yc]:=Index+1;
          If (Xc>00) And (Screen[Xc-1,Yc]=0) Then Screen[Xc-1,Yc]:=Index+1;
          If (Yc<13) And (Screen[Xc,Yc+1]=0) Then Screen[Xc,Yc+1]:=Index+1;
          If (Yc>00) And (Screen[Xc,Yc-1]=0) Then Screen[Xc,Yc-1]:=Index+1;
          Finished:=False;
        End;
    Inc(Index);
    DrawScreen;
    ReadKey;
  Until Finished;
End;



Begin
  Init;
  PathFind(5,5);
  DrawScreen;
  ReadLn;
End.