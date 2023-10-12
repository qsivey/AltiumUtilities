{..............................................................................}
{       Easy Draw v.1.5                                                        }
{   Automaticly draws draw layer for PCBLib Components.                                   }
{                                                                              }
{                                                                              }
{..............................................................................}

{..............................................................................}

Var
    CurrentLib     : IPCB_Library;
    CurrentLibComp : IPCB_LibComponent;
    TempLibComp    : IPCB_LibComponent;

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
    If PcbLibComp = Nil Then
    Begin
        ShowWarning('Error. Footprint not recognized.');
        Exit;
    End;

    X1 := MMsToCoord(0);
    Y1 := MMsToCoord(0);

    If rgUnit.ItemIndex = 0 Then
    Begin
         X2 := MMsToCoord(EasyDrawForm.eWidth.Text);
         Y2 := MMsToCoord(EasyDrawForm.eHeight.Text);
         lWidth := MMsToCoord(EasyDrawForm.eLinesWidth.Text);
         lPitch := MMsToCoord(EasyDrawForm.eLinesPitch.Text);
    End
    Else
    Begin
         X2 := MilsToCoord(EasyDrawForm.eWidth.Text);
         Y2 := MilsToCoord(EasyDrawForm.eHeight.Text);
         lWidth := MilsToCoord(EasyDrawForm.eLinesWidth.Text);
         lPitch := MilsToCoord(EasyDrawForm.eLinesPitch.Text);
    End;

    XMarker1 := X1 + lPitch;
    YMarker1 := Y1;
    XMarker2 := X1;
    YMarker2 := Y1 + lPitch;

    NewTrack := PcbServer.PCBObjectFactory(eTrackObject,eNoDimension,eCreate_Default);
    NewTrack.X1 := X1;
    NewTrack.Y1 := Y1;
    NewTrack.X2 := X2;
    NewTrack.Y2 := Y1;
    NewTrack.Layer := eMechanical2;
    NewTrack.Width := lWidth;
    PCBLibComp.AddPCBObject(NewTrack);

    NewTrack := PcbServer.PCBObjectFactory(eTrackObject,eNoDimension,eCreate_Default);
    NewTrack.X1 := X2;
    NewTrack.Y1 := Y1;
    NewTrack.X2 := X2;
    NewTrack.Y2 := Y2;
    NewTrack.Layer := eMechanical2;
    NewTrack.Width := lWidth;
    PCBLibComp.AddPCBObject(NewTrack);

    NewTrack := PcbServer.PCBObjectFactory(eTrackObject,eNoDimension,eCreate_Default);
    NewTrack.X1 := X2;
    NewTrack.Y1 := Y2;
    NewTrack.X2 := X1;
    NewTrack.Y2 := Y2;
    NewTrack.Layer := eMechanical2;
    NewTrack.Width := lWidth;
    PCBLibComp.AddPCBObject(NewTrack);

    NewTrack := PcbServer.PCBObjectFactory(eTrackObject,eNoDimension,eCreate_Default);
    NewTrack.X1 := X1;
    NewTrack.Y1 := Y2;
    NewTrack.X2 := X1;
    NewTrack.Y2 := Y1;
    NewTrack.Layer := eMechanical2;
    NewTrack.Width := lWidth;
    PCBLibComp.AddPCBObject(NewTrack);

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
               Begin
                   If XMarker1 < X2 Then
                   Begin
                        YMarker1 := lPitch - (X2 - XMarker1);
                        XMarker1 := X2;
                   End
                   Else
                       YMarker1 := YMarker1 + lPitch;
                   End;
                   If (YMarker2 <= (Y2 - lPitch)) Then
                      YMarker2 := YMarker2 + lPitch
                   Else
                   Begin
                        if YMarker2 < Y2 Then
                        Begin
                             XMarker2 := lPitch - (Y2 - YMarker2);
                             YMarker2 := Y2;
                        End
                        Else
                            XMarker2 := XMarker2 + lPitch;
                        End;
               End;
End;

Procedure RemoveAllDrawPrimitives(PCBLibComp : IPCB_LibComponent);
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
               PCBLibComp.RemovePCBObject(Primitive);
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

Function ReturnDoubleEdit(S : String, eName : String) : string;
Var
   I             : Integer;
   IsSingleComma : Booline;
   CommaPosition : Integer;
Begin
     IsSingleComma := False;
     CommaPosition : = 0;
     If (S[1] = '0') and Not((S[2] = ',') or (S[2] = '.')) Then
        Insert(',',S,2);
     For I := 1 to Length(S) Do
           If Not((S[I] = '0') or (S[I] = '1') or (S[I] = '2') or (S[I] = '3') or (S[I] = '4') or (S[I] = '5')
           or (S[I] = '6') or (S[I] = '7') or (S[I] = '8') or (S[I] = '9') or (S[I] = ',') or (S[I] = '.') or (S[I] = '')) Then
           Begin
              Delete(S, I, 1);
              Dec(I);
           End
           Else
               If (S[I] = ',') or (S[I] = '.') Then
                  If Not(IsSingleComma)and (I > 1) and (I < Length(S))  Then
                  Begin
                     S[I] := ',';
                     IsSingleComma := True;
                     CommaPosition := I;
                  End
                  Else
                  Begin
                     Delete(S, I, 1);
                     Dec(I);
                  End;
     If (S[1] = '0') and Not(S[2] = ',') Then
     Begin
          If IsSingleComma Then
             Delete(S, CommaPosition, 1);
          Insert(',',S,2);
     End;
     If (S = '') or (StrToFloat(S) = 0) Then
     Begin
          Result := RegistryLoadString( 'EasyDraw', eName, '10' );
          Exit;
     End;
     Result := S;
End;

Procedure TEasyDrawForm.eWidthExit(Sender: TObject);
Begin
     EasyDrawForm.eWidth.Text := ReturnDoubleEdit(EasyDrawForm.eWidth.Text, EasyDrawForm.eWidth.Name);
     CurrentLib.CurrentComponent := CurrentLibComp;
     RemoveAllDrawPrimitives(TempLibComp);
     DrawDraw(TempLibComp);
     CurrentLib.CurrentComponent := TempLibComp;
End;

Procedure TEasyDrawForm.eHeightExit(Sender: TObject);
Begin
     EasyDrawForm.eHeight.Text := ReturnDoubleEdit(EasyDrawForm.eHeight.Text, EasyDrawForm.eHeight.Name);
     CurrentLib.CurrentComponent := CurrentLibComp;
     RemoveAllDrawPrimitives(TempLibComp);
     DrawDraw(TempLibComp);
     CurrentLib.CurrentComponent := TempLibComp;
End;

Procedure TEasyDrawForm.eLinesWidthExit(Sender: TObject);
Begin
     EasyDrawForm.eLinesWidth.Text := ReturnDoubleEdit(EasyDrawForm.eLinesWidth.Text, EasyDrawForm.eLinesWidth.Name);
     CurrentLib.CurrentComponent := CurrentLibComp;
     RemoveAllDrawPrimitives(TempLibComp);
     DrawDraw(TempLibComp);
     CurrentLib.CurrentComponent := TempLibComp;
End;

Procedure TEasyDrawForm.eLinesPitchExit(Sender: TObject);
Begin
     EasyDrawForm.eLinesPitch.Text := ReturnDoubleEdit(EasyDrawForm.eLinesPitch.Text, EasyDrawForm.eLinesPitch.Name);
     CurrentLib.CurrentComponent := CurrentLibComp;
     RemoveAllDrawPrimitives(TempLibComp);
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
         EasyDrawForm.eWidth.Text := round(EasyDrawForm.eWidth.Text / 0.03937)/1000;
         EasyDrawForm.eHeight.Text := round(EasyDrawForm.eHeight.Text / 0.03937)/1000;
         EasyDrawForm.eLinesWidth.Text := round(EasyDrawForm.eLinesWidth.Text / 0.03937)/1000;
         EasyDrawForm.eLinesPitch.Text := round(EasyDrawForm.eLinesPitch.Text / 0.03937)/1000;
    End
    Else
    Begin
         EasyDrawForm.eWidth.Text := round(EasyDrawForm.eWidth.Text * 39370) /1000;
         EasyDrawForm.eHeight.Text := round(EasyDrawForm.eHeight.Text * 39370) /1000;
         EasyDrawForm.eLinesWidth.Text := round(EasyDrawForm.eLinesWidth.Text * 39370) /1000;
         EasyDrawForm.eLinesPitch.Text := round(EasyDrawForm.eLinesPitch.Text * 39370) /1000;
    End;
End;

{..............................................................................}
                      {Buttons}
{..............................................................................}

Procedure TEasyDrawForm.bOkClick(Sender: TObject);
Begin
     RegistrySaveString( 'EasyDraw', 'FormLeftMargin', IntToStr(EasyDrawForm.Left) );
     RegistrySaveString( 'EasyDraw', 'FormTopMargin', IntToStr(EasyDrawForm.Top) );
     RegistrySaveString( 'EasyDraw', 'DeleteOld', BoolToStr(cbDeleteOld.Checked));
     RegistrySaveString( 'EasyDraw', rgUnit.Name, IntToStr(rgUnit.ItemIndex) );
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eWidth.Name, EasyDrawForm.eWidth.Text );
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eHeight.Name, EasyDrawForm.eHeight.Text );
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eLinesWidth.Name, EasyDrawForm.eLinesWidth.Text );
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eLinesPitch.Name, EasyDrawForm.eLinesPitch.Text );

     If cbDeleteOld.Checked = True Then
       RemoveAllDrawPrimitives(CurrentLibComp);
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
     RegistrySaveString( 'EasyDraw', 'DeleteOld', BoolToStr(cbDeleteOld.Checked));
     RegistrySaveString( 'EasyDraw', rgUnit.Name, IntToStr(rgUnit.ItemIndex) );
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eWidth.Name, EasyDrawForm.eWidth.Text );
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eHeight.Name, EasyDrawForm.eHeight.Text );
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eLinesWidth.Name, EasyDrawForm.eLinesWidth.Text );
     RegistrySaveString( 'EasyDraw', EasyDrawForm.eLinesPitch.Name, EasyDrawForm.eLinesPitch.Text );
     CurrentLib.CurrentComponent := CurrentLibComp;
     CurrentLib.DeRegisterComponent(TempLibComp);
     PCBServer.DestroyPCBLibComp(TempLibComp);
     Close;
End;

{..............................................................................}

{..............................................................................}

Procedure RunEasyDraw;
Begin
     EasyDrawForm.Left := StrToInt(RegistryLoadString( 'EasyDraw', 'FormLeftMargin', '0' ));
     EasyDrawForm.Top := StrToInt(RegistryLoadString( 'EasyDraw', 'FormTopMargin', '0' ));
     cbDeleteOld.Checked := StrToBool(RegistryLoadString( 'EasyDraw', 'DeleteOld', 'False' ));
     rgUnit.ItemIndex := StrToInt(RegistryLoadString( 'EasyDraw', rgUnit.Name, '0' ));
     EasyDrawForm.eWidth.Text := RegistryLoadString( 'EasyDraw', EasyDrawForm.eWidth.Name, '10' );
     EasyDrawForm.eHeight.Text := RegistryLoadString( 'EasyDraw', EasyDrawForm.eHeight.Name, '5' );
     EasyDrawForm.eLinesPitch.Text := RegistryLoadString( 'EasyDraw', EasyDrawForm.eLinesPitch.Name, '1,25' );
     EasyDrawForm.eLinesWidth.Text := RegistryLoadString( 'EasyDraw', EasyDrawForm.eLinesWidth.Name, '0,2' );
     If PCBServer = Nil Then  Begin
        ShowWarning('PCB Server is not active!');
        Exit;
    End;
    CurrentLib := PcbServer.GetCurrentPCBLibrary;
    If CurrentLib = Nil Then
    Begin
        ShowWarning('This document is not a PCB Library!');
        Exit;
    End;
    CurrentLibComp := CurrentLib.CurrentComponent;
    TempLibComp := PCBServer.CreatePCBLibComp;
    TempLibComp.Name := 'TEMP_EASY_DRAW';
    CurrentLib.RegisterComponent(TempLibComp);
    DrawDraw(TempLibComp);
    CurrentLib.CurrentComponent := TempLibComp;
    EasyDrawForm.ShowModal;
End;

End.

