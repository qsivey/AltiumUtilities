{..............................................................................}
{       Easy Draw v.1.8                                              WIP       }
{   Automaticly draws draw layer for PCBLib Components.                        }
{  You need to place a proper rectangle for it!                                }
{                                                                              }
{..............................................................................}

{..............................................................................}

Var
    CurrentLib     : IPCB_Library;
    CurrentLibComp : IPCB_LibComponent;
    TempLibComp    : IPCB_LibComponent;
    X0, Y0         : Integer;
    Width, Height  : Integer;
    LinesWidth     : Integer;

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

Procedure DrawDraw(PCBLibComp : IPCB_LibComponent);
Var
   NewTrack      : IPCB_Track;
   X1, Y1, X2, Y2 : TCoord;
   lPitch, lWidth : TCoord;
   XMarker1, YMarker1, XMarker2, YMarker2 : TCoord;
Begin
    X1 := X0;
    Y1 := Y0;
    X2 := X1 + Width;
    Y2 := Y1 + Height;
    lWidth := LinesWidth;
    If rgUnit.ItemIndex = 0 Then
         lPitch := MMsToCoord(EasyDrawForm.eLinesPitch.Text)
    Else
         lPitch := MilsToCoord(EasyDrawForm.eLinesPitch.Text);

    XMarker1 := X1 + lPitch;
    YMarker1 := Y1;
    XMarker2 := X1;
    YMarker2 := Y1 + lPitch;

    While (YMarker1 < (Y2)) and (XMarker2 < (X2)) Do
    Begin
         NewTrack := PcbServer.PCBObjectFactory(eTrackObject,eNoDimension,eCreate_Default);
         NewTrack.X1 := XMarker1;
         NewTrack.Y1 := YMarker1;
         NewTrack.X2 := XMarker2;
         NewTrack.Y2 := YMarker2;
         NewTrack.Layer := eMechanical2;
         NewTrack.Width := lWidth;
         PCBLibComp.AddPCBObject(NewTrack);
         If (XMarker1 <= (X2 - lPitch)) Then
            XMarker1 := XMarker1 + lPitch
         Else
             If XMarker1 < X2 Then
             Begin
                  YMarker1 := YMarker1 + lPitch - (X2 - XMarker1);
                  XMarker1 := X2;
             End
             Else
                 YMarker1 := YMarker1 + lPitch;
         If (YMarker2 <= (Y2 - lPitch)) Then
            YMarker2 := YMarker2 + lPitch
         Else
              If YMarker2 < Y2 Then
              Begin
                   XMarker2 := XMarker2 + lPitch - (Y2 - YMarker2);
                   YMarker2 := Y2;
              End
              Else
                   XMarker2 := XMarker2 + lPitch;
    End;
End;

Procedure RemoveDrawPrimitives(PCBLibComp : IPCB_LibComponent);
Var
   PrimitiveIterator     : IPCB_GroupIterator;
   Primitive             : IPCB_Primitive;
Begin
     Try
          PrimitiveIterator := PCBLibComp.GroupIterator_Create;
          PrimitiveIterator.AddFilter_LayerSet(MkSet(eMechanical2));
          While Primitive  <> Nil Do
          Begin
               PrimitiveIterator.FirstPCBObject;
               Primitive := PrimitiveIterator.NextPCBObject;
               PCBLibComp.
               RemovePCBObject(Primitive);
          End;
          Primitive := PrimitiveIterator.FirstPCBObject;
          PCBLibComp.RemovePCBObject(Primitive);
     Finally
          PCBLibComp.GroupIterator_Destroy(PrimitiveIterator);
     End;
End;
{..............................................................................}
                          {Edits}
{..............................................................................}

Function ReturnDoubleEdit(S : String, eName : String) : String;
Var
   I             : Integer;
   IsSingleComma : Booline;
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

Procedure TEasyDrawForm.eLinesPitchExit(Sender: TObject);
Begin
     EasyDrawForm.eLinesPitch.Text := ReturnDoubleEdit(EasyDrawForm.eLinesPitch.Text, EasyDrawForm.eLinesPitch.Name);
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eLinesPitch.Name, EasyDrawForm.eLinesPitch.Text );
     CurrentLib.CurrentComponent := CurrentLibComp;
     RemoveDrawPrimitives(TempLibComp);
     DrawDraw(TempLibComp);
     CurrentLib.CurrentComponent := TempLibComp;
End;

{..............................................................................}
                              {Unit Convert}
{..............................................................................}

Procedure TEasyDrawForm.rgUnitClick(Sender: TObject);
Begin
    If rgUnit.ItemIndex = 0 Then
    Begin
         EasyDrawForm.eLinesPitch.Text := round(EasyDrawForm.eLinesPitch.Text / 0.03937)/1000;
         pWidth.Caption := CoordToMMs(Width);
         pHeight.Caption := CoordToMMs(Height);
         pLinesWidth.Caption := CoordToMMs(LinesWidth);
    End
    Else
    Begin
         EasyDrawForm.eLinesPitch.Text := round(EasyDrawForm.eLinesPitch.Text * 39370) /1000;
         pWidth.Caption := CoordToMils(Width);
         pHeight.Caption := CoordToMils(Height);
         pLinesWidth.Caption := CoordToMils(LinesWidth);
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
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eLinesPitch.Name, EasyDrawForm.eLinesPitch.Text );

     RemoveDrawPrimitives(CurrentLibComp);
     DrawDraw(CurrentLibComp);
     CurrentLib.CurrentComponent := CurrentLibComp;
     CurrentLib.DeRegisterComponent(TempLibComp);
     PCBServer.DestroyPCBLibComp(TempLibComp);
     Close;
End;

Procedure TEasyDrawForm.bCancelClick(Sender: TObject);
Begin
     RegistrySaveString( 'EasyDraw', 'FormLeftMargin', IntToStr(EasyDrawForm.Left) );
     RegistrySaveString( 'EasyDraw', 'FormTopMargin', IntToStr(EasyDrawForm.Top) );
     RegistrySaveString( 'EasyDraw', rgUnit.Name, IntToStr(rgUnit.ItemIndex) );
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eLinesPitch.Name, EasyDrawForm.eLinesPitch.Text );
     CurrentLib.CurrentComponent := CurrentLibComp;
     CurrentLib.DeRegisterComponent(TempLibComp);
     PCBServer.DestroyPCBLibComp(TempLibComp);
     Close;
End;

{..............................................................................}
						{Main}
{..............................................................................}

Procedure RunEasyDraw;
Var
   TrackIterator         : IPCB_GroupIterator;
   Track                 : IPCB_Track;
Begin
     If PCBServer = Nil Then  Begin
        ShowWarning('PCB Server is not active!');
        Close;
    End;
    CurrentLib := PcbServer.GetCurrentPCBLibrary;
    If CurrentLib = Nil Then
    Begin
        ShowWarning('This document is not a PCB Library!');
        Close;
    End;
    CurrentLibComp := CurrentLib.CurrentComponent;
    TempLibComp := PCBServer.CreatePCBLibComp;
    TempLibComp.Name := 'TEMP_EASY_DRAW';
    CurrentLib.RegisterComponent(TempLibComp);
    CurrentLib.CurrentComponent := TempLibComp;
    RemoveDrawPrimitives(CurrentLibComp);
    CurrentLib.CurrentComponent := CurrentLibComp;
    Try
          TrackIterator := CurrentLibComp.GroupIterator_Create;
          TrackIterator.AddFilter_ObjectSet(MkSet(eTrackObject));
          TrackIterator.AddFilter_LayerSet(MkSet(eMechanical2));
          Track := TrackIterator.FirstPCBObject;
          If Track = Nil Then
          Begin
               ShowWarning('No a draw rectangle.');
               CurrentLib.CurrentComponent := CurrentLibComp;
               CurrentLib.DeRegisterComponent(TempLibComp);
               PCBServer.DestroyPCBLibComp(TempLibComp);
               Close;
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
          X0 := X0 - MilsToCoord(50000);
          Y0 := Y0 - MilsToCoord(50000);
     Finally
          CurrentLibComp.GroupIterator_Destroy(TrackIterator);
     End;
     If rgUnit.ItemIndex = 0 Then
     Begin
         pWidth.Caption := CoordToMMs(Width);
         pHeight.Caption := CoordToMMs(Height);
         pLinesWidth.Caption := CoordToMMs(LinesWidth);
     End
     Else
     Begin
         pWidth.Caption := CoordToMils(Width);
         pHeight.Caption := CoordToMils(Height);
         pLinesWidth.Caption := CoordToMils(LinesWidth);
     End;
     EasyDrawForm.Left := StrToInt(RegistryLoadString( 'EasyDraw', 'FormLeftMargin', '0' ));
     EasyDrawForm.Top := StrToInt(RegistryLoadString( 'EasyDraw', 'FormTopMargin', '0' ));
     rgUnit.ItemIndex := StrToInt(RegistryLoadString( 'EasyDraw', rgUnit.Name, '0' ));
     EasyDrawForm.eLinesPitch.Text := RegistryLoadString( 'EasyDraw', EasyDrawForm.eLinesPitch.Name, '1,25' );
     DrawDraw(TempLibComp);
     CurrentLib.CurrentComponent := TempLibComp;
End;

End.

