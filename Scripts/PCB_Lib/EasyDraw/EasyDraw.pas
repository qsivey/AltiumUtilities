{..............................................................................}
{       Easy Draw v.1.9.6                                                      }
{   Automaticly draws draw layer for PCBLib Components.                        }
{                                                                              }
{..............................................................................}

{..............................................................................}
Const
     Sin45 = Sin(PI/4);
Var
    CurrentLib     : IPCB_Library;
    CurrentLibComp : IPCB_LibComponent;
    TempLibComp    : IPCB_LibComponent;
    X0, Y0, R      : TCoord;
    Width, Height  : TCoord;
    LinesWidth     : TCoord;
    LinesPitch     : TCoord;

{..............................................................................}
                             {Registry}
{..............................................................................}

Function RegistryLoadString(Const sKey, sItem, sDefVal: String ): String;
Var
  Reg : TRegIniFile;
Begin
  Reg := TRegIniFile.Create(sKey);
  Try
    Result := Reg.ReadString('', sItem, sDefVal);
  Finally
    Reg.Free;
  End;
End;

Procedure RegistrySaveString(Const sKey, sItem, sVal: String);
Var
  Reg: TRegIniFile;
Begin
  Reg := TRegIniFile.Create(sKey);
  Try
    Reg.WriteString('', sItem, sVal + #0);
  Finally
    Reg.Free;
  End;
End;

{..............................................................................}
                             {Draw}
{..............................................................................}

Procedure DrawCircleDraw(PCBLibComp : IPCB_LibComponent);
Var
   NewTrack           : IPCB_Track;
   XMarker1, YMarker1 : TCoord;
   XMarker2, YMarker2 : TCoord;
   TrackCount         : Integer;
   HalfTrack          : TCoord;
   Distance           : TCoord;
Begin
     If ((R * 2) Mod LinesPitch) > (LinesPitch * 0.85) Then
         TrackCount := (R * 2) Div LinesPitch - 1
     Else
         TrackCount := (R * 2) Div LinesPitch - 2;
     Distance := (TrackCount / 2) * LinesPitch;
     HalfTrack := Sqrt(Sqr(R - (LinesPitch * 0.75)) - Sqr(Distance));
     While Distance >= 0 Do
     Begin
          XMarker1 := X0 - (Distance * Sin45) - (HalfTrack * Sin45);
          YMarker1 := Y0 - (Distance * Sin45) + (HalfTrack * Sin45);
          XMarker2 := X0 - (Distance * Sin45) + (HalfTrack * Sin45);
          YMarker2 := Y0 - (Distance * Sin45) - (HalfTrack * Sin45);
          NewTrack := PcbServer.PCBObjectFactory(eTrackObject,eNoDimension,eCreate_Default);
          NewTrack.X1 := XMarker1;
          NewTrack.Y1 := YMarker1;
          NewTrack.X2 := XMarker2;
          NewTrack.Y2 := YMarker2;
          NewTrack.Layer := eMechanical2;
          NewTrack.Width := LinesWidth;
          PCBLibComp.AddPCBObject(NewTrack);

          Distance := Distance - LinesPitch;
          HalfTrack := Sqrt(Sqr(R - (LinesPitch * 0.75)) - Sqr(Distance));
     End;
     Distance := (TrackCount / 2) * LinesPitch;
     HalfTrack := Sqrt(Sqr(R - (LinesPitch * 0.75)) - Sqr(Distance));
     While Distance > 0 Do
     Begin
          XMarker1 := X0 + (Distance * Sin45) + (HalfTrack * Sin45);
          YMarker1 := Y0 + (Distance * Sin45) - (HalfTrack * Sin45);
          XMarker2 := X0 + (Distance * Sin45) - (HalfTrack * Sin45);
          YMarker2 := Y0 + (Distance * Sin45) + (HalfTrack * Sin45);

          NewTrack := PcbServer.PCBObjectFactory(eTrackObject,eNoDimension,eCreate_Default);
          NewTrack.X1 := XMarker1;
          NewTrack.Y1 := YMarker1;
          NewTrack.X2 := XMarker2;
          NewTrack.Y2 := YMarker2;
          NewTrack.Layer := eMechanical2;
          NewTrack.Width := LinesWidth;
          PCBLibComp.AddPCBObject(NewTrack);

          Distance := Distance - LinesPitch;
          HalfTrack := Sqrt(Sqr(R - (LinesPitch * 0.75)) - Sqr(Distance));
     End;
End;

Procedure DrawRectDraw(PCBLibComp : IPCB_LibComponent);
Var
   NewTrack           : IPCB_Track;
   X1, Y1             : TCoord;
   XMarker1, YMarker1 : TCoord;
   XMarker2, YMarker2 : TCoord;
   CornerPitch        : TCoord;
Begin
    X1 := X0 + Width;
    Y1 := Y0 + Height;
    CornerPitch := ((Width + Height) Mod LinesPitch) / 2;
    YMarker1 := Y0;
    XMarker2 := X0;
    If CornerPitch > LinesWidth * 3 Then
    Begin
         XMarker1 := X0 + CornerPitch;
         YMarker2 := Y0 + CornerPitch;
    End
    Else
    Begin
        XMarker1 := X0 + CornerPitch + LinesPitch;
        YMarker2 := Y0 + CornerPitch + LinesPitch;
        If XMarker1 > X1 Then
        Begin
             YMarker1 := YMarker1 + XMarker1 - X1;
             XMarker1 := X1;
        End;
        If YMarker2 > Y1 Then
        Begin
             XMarker2 := XMarker2 + YMarker2 - Y1;
             YMarker2 := Y1;
        End;
    End;
    While (YMarker1 < Y1) and (XMarker2 < X1) Do
    Begin
         NewTrack := PcbServer.PCBObjectFactory(eTrackObject,eNoDimension,eCreate_Default);
         NewTrack.X1 := XMarker1;
         NewTrack.Y1 := YMarker1;
         NewTrack.X2 := XMarker2;
         NewTrack.Y2 := YMarker2;
         NewTrack.Layer := eMechanical2;
         NewTrack.Width := LinesWidth;
         PCBLibComp.AddPCBObject(NewTrack);
         If XMarker1 <= (X1 - LinesPitch) Then
            XMarker1 := XMarker1 + LinesPitch
         Else
             If XMarker1 < X1 Then
             Begin
                  YMarker1 := YMarker1 + LinesPitch - (X1 - XMarker1);
                  XMarker1 := X1;
             End
             Else
                  If YMarker1 < Y1 - LinesPitch - LinesWidth * 3 Then
                     YMarker1 := YMarker1 + LinesPitch
                  Else
                      YMarker1 := Y1;
         If YMarker2 <= (Y1 - LinesPitch) Then
            YMarker2 := YMarker2 + LinesPitch
         Else
              If YMarker2 < Y1 Then
              Begin
                   XMarker2 := XMarker2 + LinesPitch - (Y1 - YMarker2);
                   YMarker2 := Y1;
              End
              Else
                   If XMarker2 < X1 - LinesPitch - LinesWidth * 3 Then
                     XMarker2 := XMarker2 + LinesPitch
                   Else
                      XMarker1 := X1;
    End;
End;

Procedure DeleteDrawTracks(PCBLibComp : IPCB_LibComponent);
Var
   TrackIterator : IPCB_GroupIterator;
   Track         : IPCB_Track;
Begin
     Try
          TrackIterator := PCBLibComp.GroupIterator_Create;
          TrackIterator.AddFilter_LayerSet(MkSet(eMechanical2));
          TrackIterator.AddFilter_ObjectSet(MkSet(eTrackObject));
          While Track  <> Nil Do
          Begin
               TrackIterator.FirstPCBObject;
               Track := TrackIterator.NextPCBObject;
               PCBLibComp.RemovePCBObject(Track);
          End;
          Track := TrackIterator.FirstPCBObject;
          PCBLibComp.RemovePCBObject(Track);
     Finally
          PCBLibComp.GroupIterator_Destroy(TrackIterator);
     End;
End;
{..............................................................................}
                          {Edits}
{..............................................................................}

Function ReturnDoubleEdit(S : String, eName : String) : String;
Var
   I             : Integer;
   IsSingleComma : Boolean;
Begin
     IsSingleComma := False;
     If (S[1] = '0') and Not((S[2] = ',') or (S[2] = '.')) Then
        Insert(',',S,2);
     For I := 1 to Length(S) Do
         Case S[I] of
         '0':
             If Length(Result) = 0 Then
             Begin
                  Result := Result + S[I] +',';
                  IsSingleComma := True;
             End
             Else
                 Result := Result + S[I];
         '1', '2', '3', '4', '5', '6', '7', '8', '9':
              Result := Result + S[I];
         ',', '.':
              If Not(IsSingleComma) and Not(Length(Result) = 0) Then
                  Begin
                     Result := Result + ',';
                     IsSingleComma := True;
                  End;
         End;
     If (Result[Length(Result)] = ',') Then
        Delete(Result, Length(Result), 1);
     If (Result = '') or (StrToFloat(Result) = 0) Then
          Result := RegistryLoadString( 'EasyDraw', eName, '10' );
End;

Procedure DoEditUpdate(Dummy : Integer = 0);
Begin
     eLinesPitch.Text := ReturnDoubleEdit(eLinesPitch.Text, eLinesPitch.Name);
     If rgUnit.ItemIndex = 0 Then
         LinesPitch := MMsToCoord(eLinesPitch.Text)
    Else
         LinesPitch := MilsToCoord(eLinesPitch.Text);
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eLinesPitch.Name, eLinesPitch.Text );
     CurrentLib.CurrentComponent := CurrentLibComp;
     DeleteDrawTracks(TempLibComp);
     If gbRadius.Visible Then
         DrawCircleDraw(TempLibComp)
     Else
         DrawRectDraw(TempLibComp);
     CurrentLib.CurrentComponent := TempLibComp;
End;

Procedure TEasyDrawForm.eLinesPitchKeyPress(Sender: TObject; Var Key: Char);
Begin
     If Key = #13 then    //Return Key
  Begin
    Key := #0;
    DoEditUpdate;
  End;
End;

Procedure TEasyDrawForm.eLinesPitchExit(Sender: TObject);
Begin
     DoEditUpdate;
End;

{..............................................................................}
                              {Unit Convert}
{..............................................................................}

Procedure TEasyDrawForm.rgUnitClick(Sender: TObject);
Begin
    If rgUnit.ItemIndex = 0 Then
    Begin
         eLinesPitch.Text := CoordToMMs(LinesPitch);
         pWidth.Caption := CoordToMMs(Width);
         pHeight.Caption := CoordToMMs(Height);
         pLinesWidth.Caption := CoordToMMs(LinesWidth);
         pRadius.Caption := CoordToMMs(R);
    End
    Else
    Begin
         eLinesPitch.Text := CoordToMils(LinesPitch);
         pWidth.Caption := CoordToMils(Width);
         pHeight.Caption := CoordToMils(Height);
         pLinesWidth.Caption := CoordToMils(LinesWidth);
         pRadius.Caption := CoordToMils(R);
    End;
End;

{..............................................................................}
                      {Buttons}
{..............................................................................}

Procedure TEasyDrawForm.bOkClick(Sender: TObject);
Begin
     RegistrySaveString( 'EasyDraw', 'FormLeftMargin', IntToStr(EasyDrawForm.Left) );
     RegistrySaveString( 'EasyDraw', 'FormTopMargin', IntToStr(EasyDrawForm.Top) );
     RegistrySaveString( 'EasyDraw', rgUnit.Name, IntToStr(rgUnit.ItemIndex) );
     RegistrySaveString( 'EasyDraw', eLinesPitch.Name, eLinesPitch.Text );
     Try
        {PCBServer.PreProcess;
        PCBServer.SendMessageToRobots(CurrentLib.I_ObjectAddress, c_Broadcast, PCBM_BeginModify, CurrentLibComp.I_ObjectAddress);}
        If gbRadius.Visible Then
           DrawCircleDraw(CurrentLibComp)
        Else
            DrawRectDraw(CurrentLibComp);
        {PCBServer.SendMessageToRobots(CurrentLib.I_ObjectAddress, c_Broadcast, PCBM_EndModify, CurrentLibComp.I_ObjectAddress);
        PCBServer.PostProcess;}
     Finally
           EasyDrawForm.Close;
     End;
End;

Procedure TEasyDrawForm.bCancelClick(Sender: TObject);
Begin
     RegistrySaveString( 'EasyDraw', 'FormLeftMargin', IntToStr(EasyDrawForm.Left) );
     RegistrySaveString( 'EasyDraw', 'FormTopMargin', IntToStr(EasyDrawForm.Top) );
     RegistrySaveString( 'EasyDraw', rgUnit.Name, IntToStr(rgUnit.ItemIndex) );
     RegistrySaveString( 'EasyDraw', eLinesPitch.Name, eLinesPitch.Text );
     EasyDrawForm.Close;
End;

{..............................................................................}
                        {Main}
{..............................................................................}

Procedure TEasyDrawForm.EasyDrawFormClose(Sender: TObject; Var Action: TCloseAction);
Begin
     CurrentLib.CurrentComponent := CurrentLibComp;
     If CurrentLib.GetComponentByName('TEMP_EASY_DRAW') <> Nil Then
     Begin
          CurrentLib.DeRegisterComponent(TempLibComp);
          PCBServer.DestroyPCBLibComp(TempLibComp);
     End;
End;

Procedure RunEasyDraw;
Var
   TrackIterator : IPCB_GroupIterator;
   Track         : IPCB_Track;
   Arc           : IPCB_Arc;
   CompX, CompY  : TCoord;
Begin
     EasyDrawForm.Left := StrToInt(RegistryLoadString( 'EasyDraw', 'FormLeftMargin', '0' ));
     EasyDrawForm.Top := StrToInt(RegistryLoadString( 'EasyDraw', 'FormTopMargin', '0' ));
     If PCBServer = Nil Then  Begin
        EasyDrawForm.Hide;
        ShowWarning('PCB Server is not active!');
        EasyDrawForm.Free;
    End;
    CurrentLib := PcbServer.GetCurrentPCBLibrary;
    If CurrentLib = Nil Then
    Begin
         EasyDrawForm.Hide;
         ShowWarning('This document is not a PCB Library!');
         EasyDrawForm.Free;
    End;
    CurrentLibComp := CurrentLib.CurrentComponent;
    If CurrentLibComp.Name = 'TEMP_EASY_DRAW' Then
    Begin
         EasyDrawForm.Hide;
         ShowWarning('The TEMP Component is selected! It will be deleted.');
         CurrentLib.Navigate_FirstComponent;
         CurrentLib.DeRegisterComponent(CurrentLibComp);
         PCBServer.DestroyPCBLibComp(CurrentLibComp);
         EasyDrawForm.Free;
    End;
    Try
          TrackIterator := CurrentLibComp.GroupIterator_Create;
          TrackIterator.AddFilter_LayerSet(MkSet(eMechanical2));
          TrackIterator.AddFilter_ObjectSet(MkSet(eArcObject));
          Arc := TrackIterator.FirstPCBObject;
          If Arc <> Nil Then
          Begin
               R := Arc.Radius;
               X0 := Arc.XCenter - CurrentLibComp.X;
               Y0 := Arc.YCenter - CurrentLibComp.Y;
               LinesWidth := Arc.LineWidth;
               gbWidth.Visible := False;
               gbHeight.Visible := False;
               gbRadius.Visible := True;
          End
          Else
          Begin
               TrackIterator.AddFilter_LayerSet(MkSet(eMechanical2));
               TrackIterator.AddFilter_ObjectSet(MkSet(eTrackObject));
               Track := TrackIterator.FirstPCBObject;
               If Track = Nil Then
               Begin
                    EasyDrawForm.Hide;
                    ShowWarning('There is no draw primitives.');
                    CurrentLib.CurrentComponent := CurrentLibComp;
                    CurrentLib.DeRegisterComponent(TempLibComp);
                    PCBServer.DestroyPCBLibComp(TempLibComp);
                    EasyDrawForm.Free;
               End;
               LinesWidth : = Track.Width;
               X0 := Track.X1;
               Y0 := Track.Y1;
               Width : = Abs(Track.X1 - Track.X2);
               Height : = Abs(Track.Y1 - Track.Y2);
               While Track  <> Nil Do
               Begin
                    If Track.X1 <= X0  Then
                       X0 := Track.X1;
                    If Track.X2 <= X0  Then
                       X0 := Track.X2;
                    If Track.Y1 <= Y0  Then
                       Y0 := Track.Y1;
                    If Track.Y2 <= Y0  Then
                       Y0 := Track.Y2;
                    If Abs(Track.X1 - Track.X2) > Width  Then
                       Width := Abs(Track.X1 - Track.X2);
                    If Abs(Track.Y1 - Track.Y2) > Height  Then
                       Height := Abs(Track.Y1 - Track.Y2);
                    Track := TrackIterator.NextPCBObject;
               End;
               X0 := X0 - CurrentLibComp.X;
               Y0 := Y0 - CurrentLibComp.Y;
          End;
     Finally
          CurrentLibComp.GroupIterator_Destroy(TrackIterator);
     End;
     If StrToBool(RegistryLoadString( 'EasyDraw', rgUnit.Name, '0' )) = 0 Then
         LinesPitch := MMsToCoord(StrToFloat(RegistryLoadString( 'EasyDraw', eLinesPitch.Name, '1,25' )))
     Else
         LinesPitch := MilsToCoord(StrToFloat(RegistryLoadString( 'EasyDraw', eLinesPitch.Name, '1,25' )));
     rgUnit.ItemIndex := StrToBool(RegistryLoadString( 'EasyDraw', rgUnit.Name, '0' ));
     If rgUnit.ItemIndex = 0 Then
     Begin
         pRadius.Caption := CoordToMMs(R);
         pWidth.Caption := CoordToMMs(Width);
         pHeight.Caption := CoordToMMs(Height);
         pLinesWidth.Caption := CoordToMMs(LinesWidth);
         eLinesPitch.Text := CoordToMMs(LinesPitch);
     End
     Else
     Begin
         pRadius.Caption := CoordToMils(R);
         pWidth.Caption := CoordToMils(Width);
         pHeight.Caption := CoordToMils(Height);
         pLinesWidth.Caption := CoordToMils(LinesWidth);
         eLinesPitch.Text := CoordToMils(LinesPitch);
     End;
     TempLibComp := CurrentLib.GetComponentByName('TEMP_EASY_DRAW');
     If TempLibComp <> Nil Then
     Begin
          CurrentLib.DeRegisterComponent(TempLibComp);
          PCBServer.DestroyPCBLibComp(TempLibComp);
     End;
     TempLibComp := PCBServer.CreatePCBLibComp;
     TempLibComp.Name := 'TEMP_EASY_DRAW';
     CurrentLib.RegisterComponent(TempLibComp);
     CompX := CurrentLibComp.X;
     CompY := CurrentLibComp.Y;
     CurrentLibComp.X := 0;
     CurrentLibComp.Y := 0;
     CurrentLibComp.CopyTo(TempLibComp, eFullCopy);
     CurrentLibComp.X := CompX;
     CurrentLibComp.Y := CompY;
     If gbRadius.Visible Then
         DrawCircleDraw(TempLibComp)
     Else
         DrawRectDraw(TempLibComp);
     CurrentLib.CurrentComponent := TempLibComp;
End;

End.

