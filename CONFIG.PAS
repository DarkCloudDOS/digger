Program Config;

Var
  x,temp  : Byte;
  F     : File Of Byte;

Function ScanKey : Byte; Assembler;
Asm
  Mov Ah,0
  Int 16h
  Xchg Ah,Al
  Xor Ah,Ah
End;

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

Begin
  Assign(F,'Digger.Cfg');
  If Exist('Digger.Cfg') Then
    Reset(F) Else ReWrite(F);

  For X:=1 To  2 Do Begin
  WriteLn('Enter Key For Up ');
  Temp:=ScanKey;
  Write(F,Temp);

  WriteLn('Enter Key For Down ');
  Temp:=ScanKey;
  Write(F,Temp);

  WriteLn('Enter Key For Left ');
  Temp:=ScanKey;
  Write(F,Temp);

  WriteLn('Enter Key For Right ');
  Temp:=ScanKey;
  Write(F,Temp);

  WriteLn('Enter Key To Fire ');
  Temp:=ScanKey;
  Write(F,Temp);

  Temp:=5*5*5*x;
  Write(F,temp);

End;
  Close(F);
End.