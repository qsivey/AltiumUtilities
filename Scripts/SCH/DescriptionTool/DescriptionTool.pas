{..............................................................................}
{       Description Tool v.1.0                                                 }
{    Adds checked parameters to component's description.                       }
{                                                                              }
{                                                                              }
{..............................................................................}

{..............................................................................}
Var
    SchDoc            : ISch_Document;
    TemplateComponent : ISch_Component;

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
     TemplateComponent.SchIterator_Destroy(ParamIterator);
End;

Function GetDescription(Component : ISch_Component) : WideString;
Var
   S : WideString;
   I : Integer;
Begin
     S := '';
     For I := 0 To CheckListBoxProperties.Items.Count - 1 Do
     Begin
          If CheckListBoxProperties.Checked[I] Then
          Begin
               S := S + GetParameterValue(Component, CheckListBoxProperties.Items.Strings[I]) + ' ';
               If (CBComponents.Text = 'Res') and (CheckListBoxProperties.Items.Strings[I] = 'Value') Then
                  S := S + 'OHM ';
          End;

     End;
     If cbForceUppercase.Checked = True Then
        Result := UpperCase(S)
     Else
         Result := S;
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
     Iterator := SchDoc.SchIterator_Create;
     Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));
     TemplateComponent := Iterator.FirstSchObject;
     While TemplateComponent <> Nil Do
     Begin
          If LibRef = TemplateComponent.GetState_LibReference Then
             Break;
          TemplateComponent := Iterator.NextSchObject;
     End;
     SchDoc.SchIterator_Destroy(Iterator);
     If TemplateComponent = Nil Then
        Exit;
     Try
        ParamIterator := TemplateComponent.SchIterator_Create;
        ParamIterator.AddFilter_ObjectSet(MkSet(eParameter));
        Parameter := ParamIterator.FirstSchObject;
        While Parameter <> Nil Do
        Begin
             CheckListBoxProperties.Items.Add(Parameter.Name);
             Parameter := ParamIterator.NextSchObject;
        End;
     Finally
               TemplateComponent.SchIterator_Destroy(ParamIterator);
     End;
     pExample.Caption := ' ' + GetDescription(TemplateComponent);
End;

{..............................................................................}
                         {Checks}
{..............................................................................}

Procedure TDescriptionToolForm.CheckListBoxPropertiesClickCheck(Sender: TObject);
Begin
     pExample.Caption := ' ' + GetDescription(TemplateComponent);
End;

Procedure TDescriptionToolForm.cbForceUppercaseClick(Sender: TObject);
Begin
     pExample.Caption := ' ' + GetDescription(TemplateComponent);
End;

{..............................................................................}
                         {Buttons}
{..............................................................................}

Procedure TDescriptionToolForm.bCancelClick(Sender: TObject);
Begin
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
          CheckListBoxProperties.Selected[I - 1] := true;
     End
     Else
         Exit;
     pExample.Caption := ' ' + GetDescription(TemplateComponent);
End;

Procedure TDescriptionToolForm.bDownClick(Sender: TObject);
Var
   I : Integer;
Begin
     I := CheckListBoxProperties.ItemIndex;
     If (I >= 0) and (I < CheckListBoxProperties.Items.Count - 1) and (CheckListBoxProperties.Items.Count > 1) Then
     Begin
          CheckListBoxProperties.Items.Move (I, I + 1);
          CheckListBoxProperties.Selected[I + 1] := True;
     End;
     pExample.Caption := ' ' + GetDescription(TemplateComponent);
End;

{..............................................................................}
                         {Combo Box}
{..............................................................................}

Procedure TDescriptionToolForm.CBComponentsSelect(Sender: TObject);
Begin
     SetParametersList;
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
   CorrectRef : Booline;
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
        Exit;
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
     SchDoc.SchIterator_Destroy(Iterator);
     SchServer.ProcessControl.PostProcess(SchDoc, '');
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
   LibRefCatched : Booline;
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
     CBComponents.Text := RegistryLoadString( 'DescriptionTool', 'LibRef', '' );
     SetParametersList;
     cbOnlySelected.Checked := StrToBool(RegistryLoadString( 'DescriptionTool', 'OnlySelected', 'False' ));
     cbForceUppercase.Checked := StrToBool(RegistryLoadString( 'DescriptionTool', 'ForceUppercase', 'False' ));
     DescriptionToolForm.ShowModal;
End;

End.
