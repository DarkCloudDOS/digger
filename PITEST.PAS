Uses Pit,DrcSB;

Var
  Wav   : TWav;
  F,E   : Word;

Procedure PlayWav; Far;
Begin
  Inc(Wav.Index);
  write_dsp(mem[seg(Wav.buffer^):ofs(Wav.buffer^)+WaV.index]);
  If Wav.Index=Wav.File_Size Then DonePit
End;

Begin
  Wav.FileName:=ParamStr(1);
  VAL(ParamStr(2),F,E);
  If Reset_Dsp And (Load_File(WAV)=0) And (F>0) Then Begin
    SPK_On;
    InstallPit(PlayWav,F);
    ReadLn;
    SPK_OFF;
    {DonePit;}
    Unload_Snd(Wav.Buffer,Wav.File_Size);
  End Else WriteLn(#10,#13,'Error Loading WAV.',#10,#13);
End.