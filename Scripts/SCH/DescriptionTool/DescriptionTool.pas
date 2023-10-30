{..............................................................................}
{       Description Tool v.1.2                                                 }
{    Adds checked parameters to component's description.                       }
{                                                                              }
{                                                                              }
{..............................................................................}

{..............................................................................}
Var
    SchDoc            : ISch_Document;
    TemplateComponent : ISch_Component;
    ParamNames        : TWideStringList;
    ParamFixes        : TWideStringList;

{..............................................................................}
                             {Registry}
{..............................................................................}

Function RegistryLoadString(Const sKey, sItem, sDefVal: String ): String;
Var
  reg: TRegIniFile;
Begin
  reg := TRegIniFile.Create(sKey);
  Try
    result := reg.ReadString('', sItem, sDefVal);
  Finally
    reg.Free;
  End;
End;

Procedure RegistrySaveString(Const sKey, sItem, sVal: String);
Var
  reg: TRegIniFile;
Begin
  reg := TRegIniFile.Create(sKey);
  Try
    reg.WriteString('', sItem, sVal + #0);
  Finally
    reg.Free;
  End;
End;

{..............................................................................}
                         {Functions}
{..............................................................................}

Function GetParameterValue(Component : ISch_Component, ParamName : ISch_WideString) : WideString;
Var
   Parameter     : ISch_Parameter;
   ParamIterator : ISch_Iterator;
Begin
     Try
          ParamIterator := Component.SchIterator_Create;
          ParamIterator.AddFilter_ObjectSet(MkSet(eParameter));
          Parameter := ParamIterator.FirstSchObject;
          While Parameter <> Nil Do
          Begin
               If Parameter.Name = ParamName Then
               Begin
                    Result := Parameter.Text;
                    Break;
               End;
               Parameter := ParamIterator.NextSchObject;
          End;
     Finally
          TemplateComponent.SchIterator_Destroy(ParamIterator);
     End;
End;

Function GetDescription(Component : ISch_Component) : WideString;
Var
   I : Integer;
Begin
     For I := 0 To CheckListBoxProperties.Items.Count - 1 Do
          If CheckListBoxProperties.Checked[I] Then
               If ParamFixes[I] = '{Value}' Then
                   Result := Result + GetParameterValue(Component, ParamNames[I]) + ' '
               Else
                   Result := Result + StringReplace(ParamFixes[I], '{Value}', GetParameterValue(Component, ParamNames[I]), 3) + ' ';
     If cbForceUppercase.Checked = True Then
        Result := UpperCase(Result);
End;

{..............................................................................}
                         {Procedures}
{..............................................................................}

Procedure SetParametersList(Dummy : Integer = 0);
Var
   Parameter     : ISch_Parameter;
   Iterator      : ISch_Iterator;
   ParamIterator : ISch_Iterator;
   I             : Integer;
   LibRef        : WideString;
Begin
     LibRef := CBComponents.Text;
     If CheckListBoxProperties.Items.Count > 0 Then
        For I := 0 to CheckListBoxProperties.Items.Count - 1 Do
            CheckListBoxProperties.Items.Delete(CheckListBoxProperties.Items.Count - 1);
     Try
          Iterator := SchDoc.SchIterator_Create;
          Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));
          TemplateComponent := Iterator.FirstSchObject;
          While TemplateComponent <> Nil Do
          Begin
               If LibRef = TemplateComponent.GetState_LibReference Then
                  Break;
               TemplateComponent := Iterator.NextSchObject;
          End;
     Finally
            SchDoc.SchIterator_Destroy(Iterator);
     End;
     Try
        ParamNames := TStringList.Create;
        ParamFixes := TStringList.Create;
        ParamIterator := TemplateComponent.SchIterator_Create;
        ParamIterator.AddFilter_ObjectSet(MkSet(eParameter));
        Parameter := ParamIterator.FirstSchObject;
        While Parameter <> Nil Do
        Begin
             CheckListBoxProperties.Items.Add(Parameter.Name);
             ParamNames.Append(Parameter.Name);
             ParamFixes.Append('{Value}');
             Parameter := ParamIterator.NextSchObject;
        End;
        If CheckListBoxProperties.Items.Count > 0 Then
        Begin
             CheckListBoxProperties.ItemIndex := 0;
             eFix.Text := ParamFixes[CheckListBoxProperties.ItemIndex];
        End;
        pExample.Caption := GetDescription(TemplateComponent);
     Finally
               TemplateComponent.SchIterator_Destroy(ParamIterator);
     End;
End;

{..............................................................................}
                         {Checks}
{..............................................................................}

Procedure TDescriptionToolForm.CheckListBoxPropertiesClickCheck(Sender: TObject);
Begin
     pExample.Caption := GetDescription(TemplateComponent);
End;

Procedure TDescriptionToolForm.cbForceUppercaseClick(Sender: TObject);
Begin
     pExample.Caption := GetDescription(TemplateComponent);
End;

{..............................................................................}
                         {Edit}
{..............................................................................}

Procedure TDescriptionToolForm.eFixChange(Sender: TObject);
Begin
     If ContainsText(eFix.Text, '{Value}') Then
         ParamFixes[CheckListBoxProperties.ItemIndex] := eFix.Text
     Else
         eFix.Text := ParamFixes[CheckListBoxProperties.ItemIndex];
     If UpperCase(ParamFixes[CheckListBoxProperties.ItemIndex]) = '{VALUE}' Then
         CheckListBoxProperties.Items.Strings[CheckListBoxProperties.ItemIndex] := ParamNames[CheckListBoxProperties.ItemIndex]
     Else
         CheckListBoxProperties.Items.Strings[CheckListBoxProperties.ItemIndex] := ParamNames[CheckListBoxProperties.ItemIndex] + '*';
     pExample.Caption := GetDescription(TemplateComponent);
End;

{..............................................................................}
                         {Buttons}
{..............................................................................}

Procedure TDescriptionToolForm.bCancelClick(Sender: TObject);
Begin
     ParamNames.Free;
     ParamFixes.Free;
     RegistrySaveString( 'DescriptionTool', 'FormLeftMargin', IntToStr(DescriptionToolForm.Left) );
     RegistrySaveString( 'DescriptionTool', 'FormTopMargin', IntToStr(DescriptionToolForm.Top) );
     RegistrySaveString( 'DescriptionTool', 'LibRef', CBComponents.Text );
     RegistrySaveString( 'DescriptionTool', 'OnlySelected', BoolToStr(cbOnlySelected.Checked) );
     RegistrySaveString( 'DescriptionTool', 'ForceUppercase', BoolToStr(cbForceUppercase.Checked) );
     Close;
End;

Procedure TDescriptionToolForm.bUpClick(Sender: TObject);
Var
   I : Integer;
Begin
     I := CheckListBoxProperties.ItemIndex;
     If (I >= 0) and (CheckListBoxProperties.Items.Count > 1) Then
     Begin
          CheckListBoxProperties.Items.Move (I, I - 1);
          ParamNames.Move (I, I - 1);
          ParamFixes.Move (I, I - 1);
          CheckListBoxProperties.Selected[I - 1] := True;
          eFix.Text := ParamFixes[CheckListBoxProperties.ItemIndex];
     End
     Else
         Exit;
     pExample.Caption := GetDescription(TemplateComponent);
End;

Procedure TDescriptionToolForm.bDownClick(Sender: TObject);
Var
   I : Integer;
Begin
     I := CheckListBoxProperties.ItemIndex;
     If (I >= 0) and (I < CheckListBoxProperties.Items.Count - 1) and (CheckListBoxProperties.Items.Count > 1) Then
     Begin
          CheckListBoxProperties.Items.Move (I, I + 1);
          ParamNames.Move (I, I + 1);
          ParamFixes.Move (I, I + 1);
          CheckListBoxProperties.Selected[I + 1] := True;
          eFix.Text := ParamFixes[CheckListBoxProperties.ItemIndex];
     End;
     pExample.Caption := GetDescription(TemplateComponent);
End;

{..............................................................................}
                         {Combo Box and Check List Box}
{..............................................................................}

Procedure TDescriptionToolForm.CBComponentsSelect(Sender: TObject);
Begin
     ParamNames.Free;
     ParamFixes.Free;
     SetParametersList;
End;

Procedure TDescriptionToolForm.CheckListBoxPropertiesClick(Sender: TObject);
Begin
     eFix.Text := ParamFixes[CheckListBoxProperties.ItemIndex];
     If ParamFixes[CheckListBoxProperties.ItemIndex] = '{Value}' Then
         CheckListBoxProperties.Items.Strings[CheckListBoxProperties.ItemIndex] := ParamNames[CheckListBoxProperties.ItemIndex]
     Else
         CheckListBoxProperties.Items.Strings[CheckListBoxProperties.ItemIndex] := ParamNames[CheckListBoxProperties.ItemIndex] + '*';
     pExample.Caption := GetDescription(TemplateComponent);
End;

{..............................................................................}
                            {Main}
{..............................................................................}

Procedure TDescriptionToolForm.bOkClick(Sender: TObject);
Var
   Iterator   : ISch_Iterator;
   Component  : ISch_Component;
   LibRef     : WideString;
   I          : Integer;
   CorrectRef : Boolean;
Begin
     LibRef := CBComponents.Text;
     CorrectRef := False;
     For I := 0 To CBComponents.Items.Count - 1 Do
         If LibRef = CBComponents.Items.Strings[I] Then
         Begin
              CorrectRef := True;
              Break;
         End;
     If Not(CorrectRef) Then
     Begin
          ParamNames.Free;
          ParamFixes.Free;
          Exit;
     End;
     Try
         Iterator := SchDoc.SchIterator_Create;
         Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));
         Component := Iterator.FirstSchObject;
         SchServer.ProcessControl.PreProcess(SchDoc, '');
         If cbOnlySelected.Checked = True Then
            While Component <> Nil Do
            Begin
                 If (LibRef = Component.GetState_LibReference) and Component.GetState_Selection Then
                 Begin
                      SchServer.RobotManager.SendMessage(Component.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                      Component.SetState_ComponentDescription := GetDescription(Component);
                      SchServer.RobotManager.SendMessage(Component.I_ObjectAddress, c_BroadCast, SCHM_EndModify, c_NoEventData);
                 End;
                 Component := Iterator.NextSchObject;
            End
         Else
             While Component <> Nil Do
             Begin
                  If (LibRef = Component.GetState_LibReference) Then
                  Begin
                       SchServer.RobotManager.SendMessage(Component.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                       Component.SetState_ComponentDescription := GetDescription(Component);
                       SchServer.RobotManager.SendMessage(Component.I_ObjectAddress, c_BroadCast, SCHM_EndModify, c_NoEventData);
                  End;
                  Component := Iterator.NextSchObject;
             End;
     Finally
          SchDoc.SchIterator_Destroy(Iterator);
          ParamNames.Free;
          ParamFixes.Free;
          SchServer.ProcessControl.PostProcess(SchDoc, '');
     End;
     RegistrySaveString( 'DescriptionTool', 'FormLeftMargin', IntToStr(DescriptionToolForm.Left) );
     RegistrySaveString( 'DescriptionTool', 'FormTopMargin', IntToStr(DescriptionToolForm.Top) );
     RegistrySaveString( 'DescriptionTool', 'LibRef', LibRef );
     RegistrySaveString( 'DescriptionTool', 'OnlySelected', BoolToStr(cbOnlySelected.Checked) );
     RegistrySaveString( 'DescriptionTool', 'ForceUppercase', BoolToStr(cbForceUppercase.Checked) );
     Showmessage('Done');
     Close;
End;

Procedure RunDescriptionTool;
Var
   Iterator      : ISch_Iterator;
   Component     : ISch_Component;
   I             : Integer;
   LibRefCatched : Boolean;
Begin
     If SchServer = Nil Then
     Begin
          ShowWarning('SCH Server is not active!');
          Exit;
     End;
     SchDoc := SchServer.GetCurrentSchDocument;
     If SchDoc = Nil Then
     Begin
          ShowWarning('Current Document is not Schematic!');
          Exit;
     End;
     Iterator := SchDoc.SchIterator_Create;
     Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));
     Component := Iterator.FirstSchObject;
     LibRefCatched := False;
     While Component <> Nil Do
     Begin
          For I := 0 To CBComponents.Items.Count - 1 Do
              If CBComponents.Items.Strings[I] = Component.GetState_LibReference Then
                 LibRefCatched := True;
          If LibRefCatched = False Then
             CBComponents.Items.Add(Component.GetState_LibReference);
          LibRefCatched := False;
          Component := Iterator.NextSchObject;
     End;
     SchDoc.SchIterator_Destroy(Iterator);
     DescriptionToolForm.Left := StrToInt(RegistryLoadString( 'DescriptionTool', 'FormLeftMargin', '0' ));
     DescriptionToolForm.Top := StrToInt(RegistryLoadString( 'DescriptionTool', 'FormTopMargin', '0' ));
     If ContainsText(CBComponents.Items.Text, RegistryLoadString( 'DescriptionTool', 'LibRef', '' )) Then
     Begin
        CBComponents.Text := RegistryLoadString( 'DescriptionTool', 'LibRef', '' );
        SetParametersList;
     End
     Else
     Begin
          ParamNames := TStringList.Create;
          ParamFixes := TStringList.Create;
     End;
     cbOnlySelected.Checked := StrToBool(RegistryLoadString( 'DescriptionTool', 'OnlySelected', 'False' ));
     cbForceUppercase.Checked := StrToBool(RegistryLoadString( 'DescriptionTool', 'ForceUppercase', 'False' ));
     DescriptionToolForm.ShowModal;
End;

End.
