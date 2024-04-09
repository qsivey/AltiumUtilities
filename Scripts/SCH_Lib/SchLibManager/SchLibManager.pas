{..............................................................................}
{      SchLibManager v0.7.1                                       WIP          }
{                                                                              }
{   Manager for schematic lib component's footprints and parameters.           }
{                                                                              }
{..............................................................................}

Const
    DataFileName = 'FootprintList.dat';
    ParamSet = 'Name|Value|{other}|Case|Part Number|Link|Note';
Var
    UIDarkMode  : Boolean;
    WorkSpace   : IWorkspace;
    IntMan      : IIntegratedLibraryManager;
    SchLib      : ISch_Lib;
    CurrentComp : ISch_Component;
    Dir         : WideString;

{..............................................................................}
                          {GUI}
{..............................................................................}


Procedure SetGUI(Dummy : Integer = 0);
Const
    ScriptVersion = 'v0.7.1';
    cldBorderActive = $222222
    cldBorderUnactive = $353535;
    cldBorderHighlighted = $A2D2FD;
    cldPanelMain = $404040;
    cldPanelLabel = $4E4E4E;
    cldPanelButton = $5C5C5C;
    cldPanelButtonHighlighted = $545454;
    cldPanelBtnUnactive = $484848;
    cldListBox = $3B3B3B;
Var
    I : Integer;
Begin
    SchLibManager.Icon := iContainer.Picture;
    iContainer.Free;
    SchLibManager.Caption := SchLibManager.Caption + ScriptVersion;
    UIDarkMode := Client.OptionsManager.GetOptionsReader('Client', '').ReadString('Client Preferences', 'UIThemeName', '') = 'Altium Dark Gray';
    If UIDarkMode Then
    Begin
        SchLibManager.Color := $4E4E4E;
        SchLibManager.Font.Color := $FFFFFF;
        lbComponentFPs.Color := $3B3B3B;
        For I := 0 to SchLibManager.ComponentCount - 1 Do
            Case SchLibManager.Components[I].ClassName of
                'TXPExtPanel':
                Begin
                    Case SchLibManager.Components[I].Tag of
                            0:
                            Begin
                                 SchLibManager.Components[I].Color := cldPanelLabel;
                                 SchLibManager.Components[I].BorderColor := cldBorderActive;
                            End;
                            1:
                            Begin
                                 SchLibManager.Components[I].Color := cldPanelMain;
                                 SchLibManager.Components[I].BorderColor := cldBorderUnactive;
                            End;
                            2:
                            Begin
                                 SchLibManager.Components[I].Color := cldListBox;
                                 SchLibManager.Components[I].BorderColor := cldBorderActive;
                            End;
                            3:
                            Begin
                                 SchLibManager.Components[I].Color := cldPanelButton;
                                 SchLibManager.Components[I].BorderColor := cldBorderActive;
                            End;
                    End;
                End;
                'TShape':
                Begin
                          SchLibManager.Components[I].Brush.Color := cldPanelBtnUnactive;
                          SchLibManager.Components[I].Pen.Color := cldBorderActive;
                End;
                'TListBox', 'TCheckListBox':
                          SchLibManager.Components[I].Color := cldListBox;
                'TXPLabel':
                          SchLibManager.Components[I].Font.Color := $FFFFFF;
                'TComboBox':
                          SchLibManager.Components[I].Color := cldPanelButton;
                End;
    End;
End;

{..............................................................................}
                          {Functions}
{..............................................................................}

Function GetLibraryFPsList(const NameFilter : WideString, const LibFilter : WideString) : TWideString;
Var
    FPsList    : TWideStringList;
    FiltList   : TWideStringList;
    LibCounter : Integer;
    FPsCounter : Integer;
    FPsCount   : Integer;
    Ptr        : Integer;
    SepPos     : Integer;
Begin
    If Not(FileExists(Dir + DataFileName)) Then
    Begin
        Result := '';
        SchLibManager.Show;
        ShowInfo('Datalist update is required. Press the button under the libraries combobox', '');
        Exit;
    End;

    Ptr := 2;
    FPsList := TStringList.Create;
    FiltList := TStringList.Create;
    Try
        FPsList.LoadFromFile(Dir + DataFileName);
        For LibCounter := 1 to StrToInt(Copy(FPsList.Strings[1], 1, Pos(#31, FPsList.Strings[1]) - 1)) Do
        Begin
            SepPos := Pos(#31, FPsList.Strings[Ptr]);
            FPsCount := StrToInt(Copy(FPsList.Strings[Ptr], SepPos + 1, Length(FPsList.Strings[Ptr]) - 1));
            If (LibFilter = 'All') or (Copy(FPsList.Strings[Ptr], 1, SepPos - 1) = LibFilter) Then
            Begin
                For FPsCounter := 1 to FPsCount Do
                    If (NameFilter = '') or (AnsiPos(UpperCase(NameFilter), UpperCase(FPsList.Strings[Ptr + FPsCounter])) <> 0) Then
                        FiltList.Append(FPsList.Strings[Ptr + FPsCounter]);
                If LibFilter <> 'All' Then
                    Break;
            End;
            Ptr := Ptr + FPsCount + 1;
        End;
        Result := FiltList.Text;
    Finally
        FPsList.Free;
        FiltList.Free;
    End;
End;

Function GetCurrentCompFPsList(Dummy : Integer = 0) : WideString;
Var
    FootprintList : TWidestringList;
    ImpIterator   : ISch_Iterator;
    SchImp        : ISch_Implementation;
Begin
    ImpIterator := SchLib.CurrentSchComponent.SchIterator_Create;
    ImpIterator.AddFilter_ObjectSet(MkSet(eImplementation));
    FootprintList := TStringList.Create;
    Try
        SchImp := ImpIterator.FirstSchObject;
        While SchImp <> Nil Do
        Begin
            If SchImp.ModelType = 'PCBLIB' Then
                FootprintList.Append(SchImp.ModelName);
            SchImp := ImpIterator.NextSchObject;
        End;
        FootprintList.Sort;
        Result := FootprintList.Text;
    Finally
        SchLib.CurrentSchComponent.SchIterator_Destroy(ImpIterator);
        FootprintList.Free;
    End;
End;

Procedure SetLibrariesComboBox(Dummy : Integer = 0);
Var
    DataList : TWideStringList;
    Ptr      : Integer;
    I        : Integer;
Begin
    cbLibraries.Items.Append('All');
    If FileExists(Dir + DataFileName) Then
    Begin
        Ptr := 2;
        DataList := TStringList.Create;
        Try
            DataList.LoadFromFile(Dir + DataFileName);
            For I := 1 to StrToInt(Copy(DataList.Strings[1], 1, Pos(#31, DataList.Strings[1]) - 1)) Do
            Begin
                cbLibraries.Items.Append(Copy(DataList.Strings[Ptr], 1, Pos(#31, DataList.Strings[Ptr]) - 1));
                Ptr := Ptr + StrToInt(Copy(DataList.Strings[Ptr], Pos(#31, DataList.Strings[Ptr]) + 1, Length(DataList.Strings[Ptr]) - 1)) + 1;
            End;
        Finally
            DataList.Free;
        End;
    End;
    cbLibraries.ItemIndex := 0;

    lbLibraryFPs.Items.Text := GetLibraryFPsList(xpeSearch.Text, cbLibraries.Text);
    lbLibraryFPsCount.Caption := IntToStr(lbLibraryFPs.Items.Count);
End;

Function FindInListBox(ListBox : TListBox, Item : WideString) : Integer;
Var
    I : Integer;
Begin
    For I := 0 to ListBox.Count - 1 Do
        If ListBox.Items.Strings[I] = Item Then
        Begin
            Result := I;
            Exit;
        End;
    Result := -1;
End;

{..............................................................................}
                          {Procedures}
{..............................................................................}

Procedure SetParametersCheckListBox(Dummy : Integer = 0);
Var
    OtherParamList : TWidestringList;
    ParamIterator  : ISch_Iterator;
    Parameter      : ISch_Parameter;
    I              : Integer;
Begin
    ParamIterator := SchLib.CurrentSchComponent.SchIterator_Create;
    ParamIterator.AddFilter_ObjectSet(MkSet(eParameter));
    OtherParamList := TStringList.Create;
    Try
        cblParameters.Items.Delimiter := '|';
        cblParameters.Items.StrictDelimiter := True;
        cblParameters.Items.DelimitedText := ParamSet;

        Parameter := ParamIterator.FirstSchObject;
        While Parameter <> Nil Do
        Begin
            If (cblParameters.Items.IndexOf(Parameter.Name) = -1) and (Parameter.Name <> 'Comment') Then
                OtherParamList.Append(Parameter.Name);
            Parameter := ParamIterator.NextSchObject;
        End;

        If OtherParamList.Count > 0 Then
        Begin
            OtherParamList.Delimiter := '|';
            OtherParamList.StrictDelimiter := True;
            cblParameters.Items.DelimitedText := StringReplace(cblParameters.Items.DelimitedText, '{other}', OtherParamList.DelimitedText, 0);
        End
        Else
            cblParameters.Items.DelimitedText := StringReplace(cblParameters.Items.DelimitedText, '|{other}|', '|', 0);

        Parameter := ParamIterator.FirstSchObject;
        While Parameter <> Nil Do
        Begin
            I := cblParameters.Items.IndexOf(Parameter.Name);
            If I <> -1 Then
                cblParameters.Checked[I] := True;
            Parameter := ParamIterator.NextSchObject;
        End;
    Finally
        SchLib.CurrentSchComponent.SchIterator_Destroy(ParamIterator);
        OtherParamList.Free;
    End;
End;

{Function GetFootprintPinCount(const Footprint : IPCB_LibComponent) : Integer;
Var
    PadIterator     : IPCB_GroupIterator;
    PadDesignators  : TWideStringList;
    Pad             : IPCB_Pad;
Begin
    PadIterator := Footprint.GroupIterator_Create;
    PadDesignators := TStringList.Create;
    PadIterator.AddFilter_ObjectSet(MkSet(ePadObject));
    Try
        Pad := PadIterator.FirstPCBObject;
        Result := 0;
        While Pad <> Nil Do
        Begin
            If PadDesignators.IndexOf(Pad.Name) = -1 Then
                Result := PadDesignators.Add(Pad.Name) + 1;
            Pad := PadIterator.NextPCBObject;
        End;
    Finally
        Footprint.GroupIterator_Destroy(PadIterator);
        PadDesignators.Free;
    End;
End;}

Procedure TSchLibManager.eSearchChange(Sender: TObject);
Begin
    lbLibraryFPs.Items.Text := GetLibraryFPsList(xpeSearch.Text, cbLibraries.Text);
    lbLibraryFPsCount.Caption := IntToStr(lbLibraryFPs.Items.Count);
End;

Procedure CompareFPsLists(Dummy : Integer = 0);
Var
    CompFPs     : TWideStringList;
    AddCount    : Integer;
    RemoveCount : Integer;
    I, J        : Integer;
Begin
    lbComponentFPsCount.Caption := IntToStr(lbComponentFPs.Items.Count);

    lbAddCount.Visible := True;
    lbRemoveCount.Visible := True;

    CompFPs := TStringList.Create;
    Try
        CompFPs.Text := GetCurrentCompFPsList;
        If (CompFPs.Count = 0) or (lbComponentFPs.Count = 0) Then
        Begin
            If lbComponentFPs.Count = 0 Then
                lbAddCount.Visible := False
            Else
                lbAddCount.Caption := '+ ' + IntToStr(lbComponentFPs.Count);
            If CompFPs.Count = 0 Then
                lbRemoveCount.Visible := False
            Else
                lbRemoveCount.Caption := '- ' + IntToStr(CompFPs.Count);
            Exit;
        End;

        AddCount := 0;
        RemoveCount := 0;

        For I := 0 to lbComponentFPs.Count - 1 Do
                For J := 0 to CompFPs.Count - 1 Do
                Begin
                    If lbComponentFPs.Items[I] = CompFPs.Strings[J] Then
                        Break;
                    If J = CompFPs.Count - 1 Then
                        Inc(AddCount);
                End;
        If AddCount = 0 Then
            lbAddCount.Visible := False
        Else
            lbAddCount.Caption := '+ ' + IntToStr(AddCount);

        For I := 0 to CompFPs.Count - 1 Do
            For J := 0 to lbComponentFPs.Count - 1 Do
            Begin
                If CompFPs.Strings[I] = lbComponentFPs.Items[J] Then
                    Break;
                If J = lbComponentFPs.Count - 1 Then
                    Inc(RemoveCount);
            End;
        If RemoveCount = 0 Then
            lbRemoveCount.Visible := False
        Else
            lbRemoveCount.Caption := '- ' + IntToStr(RemoveCount);
    Finally
        CompFPs.Free;
    End;
End;

Procedure SetComponentFPsList(Dummy : Integer = 0);
Begin
    lbComponentFPs.Items.Text := GetCurrentCompFPsList;
    CompareFPsLists;
End;

Procedure ApplyFPsList(Dummy : Integer = 0);
Var
    ImpIterator   : ISch_Iterator;
    SchImp        : ISch_Implementation;
    CurModelName  : WideString;
    DataList      : TWideStringList;
    Ptr           : Integer;
    I, J          : Integer;
Begin
    bApply.Cursor := crHourGlass;

    SchServer.ProcessControl.PreProcess(SchLib, '');

    ImpIterator := SchLib.CurrentSchComponent.SchIterator_Create;
    ImpIterator.AddFilter_ObjectSet(MkSet(eImplementation));
    Try
        SchImp := ImpIterator.FirstSchObject;
        While SchImp <> Nil Do
        Begin
            If (SchImp.ModelType = 'PCBLIB')Then
            Begin
                If SchImp.IsCurrent Then
                    CurModelName := SchImp.ModelName;
                SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                SchLib.CurrentSchComponent.RemoveSchImplementation(SchImp);
                SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_EndModify, c_NoEventData);
            End;
            SchImp := ImpIterator.NextSchObject;
        End;
    Finally
        SchLib.CurrentSchComponent.SchIterator_Destroy(ImpIterator);
    End;

    SchServer.ProcessControl.PreProcess(SchLib, '');
    SchLib.LockViewUpdate;
    DataList := TStringList.Create;
    Try
        DataList.LoadFromFile(Dir + DataFileName);
        Ptr := StrToInt(Copy(DataList.Strings[1], 1, Pos(#31, DataList.Strings[1]) - 1)) + StrToInt(Copy(DataList.Strings[1], Pos(#31, DataList.Strings[1]) + 1, Length(DataList.Strings[1]) - 1)) + 3;

        For I := 0 to lbComponentFPs.Count - 1 Do
        Begin
            SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);

            SchImp := SchLib.CurrentSchComponent.AddSchImplementation;
            SchImp.ModelType := 'PCBLIB';
            SchImp.ModelName := lbComponentFPs.Items[I];
            If SchImp.ModelName = CurModelName Then
                SchImp.IsCurrent := True;

            For J := Ptr to Ptr + StrToInt(Copy(DataList.Strings[Ptr - 1], Pos(#31, DataList.Strings[Ptr - 1]) + 1, Length(DataList.Strings[Ptr - 1]) - 1)) - 1 Do
                If Copy(DataList.Strings[J], 1, Pos(#31, DataList.Strings[J]) - 1) = lbComponentFPs.Items[I] Then
                   SchImp.Description := Copy(DataList.Strings[J], Pos(#31, DataList.Strings[J]) + 1, Length(DataList.Strings[J]) - 1);

            SchImp.AddDataFileLink(lbComponentFPs.Items[I], '', 'PCBLib');

            SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_EndModify, c_NoEventData);
        End;

        SchServer.ProcessControl.PostProcess(SchLib, '');
        SchLib.UnLockViewUpdate;
    Finally
        DataList.Free;
    End;

    lbComponentFPs.Clear;
    lbComponentFPs.Items.Text := GetCurrentCompFPsList;
    lbComponentFPsCount.Caption := IntToStr(lbComponentFPs.Items.Count);
    CompareFPsLists;

    bApply.Cursor := crDefault;
End;

Procedure ApplyParamList(Dummy : Integer = 0);
Var
    ParamIterator : ISch_Iterator;
    Parameter     : ISch_Parameter;
    OldParamList  : TWideStringList;
    I, J          : Integer;
Begin
    ParamIterator := SchLib.CurrentSchComponent.SchIterator_Create;
    ParamIterator.AddFilter_ObjectSet(MkSet(eParameter));
    OldParamList := TStringList.Create;
    Try
        SchServer.ProcessControl.PreProcess(SchLib, '');
        SchLib.LockViewUpdate;

        Parameter := ParamIterator.FirstSchObject;
        While Parameter <> Nil Do
        Begin
            If Parameter.Name <> 'Comment' Then
            Begin
                OldParamList.Append(Parameter.Name + '|' + Parameter.Text);
                SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                SchLib.CurrentSchComponent.Remove_Parameter(Parameter);
                SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_EndModify, c_NoEventData);
            End;
            Parameter := ParamIterator.NextSchObject;
        End;

        For I := 0 to cblParameters.Count - 1 Do
            If cblParameters.Checked[I] Then
            Begin
                SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                Parameter := SchLib.CurrentSchComponent.AddSchParameter;
                SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_EndModify, c_NoEventData);

                Parameter.Name := cblParameters.Items.Strings[I];
                Parameter.Text := '';
                Parameter.Color := SchLib.CurrentSchComponent.Designator.Color;

                For J := 0 to OldParamList.Count - 1 Do
                    If ContainsStr(OldParamList.Strings[J], Parameter.Name + '|') Then
                        Parameter.Text := Copy(OldParamList.Strings[J], Pos('|', OldParamList.Strings[J]) + 1, Length(OldParamList.Strings[J]) - 1);
            End;

        SchServer.ProcessControl.PostProcess(SchLib, '');
        SchLib.UnLockViewUpdate;
    Finally
        SchLib.CurrentSchComponent.SchIterator_Destroy(ParamIterator);
        OldParamList.Free;
    End;
End;

{..............................................................................}
                          {ComboBox}
{..............................................................................}

Procedure TSchLibManager.cbComponentsSelect(Sender: TObject);
Begin
    If SchLib.GetState_SchComponentByLibRef(cbComponents.Text) <> Nil Then
    Begin
        SchLib.CurrentSchComponent := SchLib.GetState_SchComponentByLibRef(cbComponents.Text);
        SetComponentFPsList;
        SetParametersCheckListBox;
        SchLib.UnLockViewUpdate;
    End
    Else
        cbComponents.Text := cbComponents.Items.LibReference;
End;

Procedure TSchLibManager.cbLibrariesSelect(Sender: TObject);
Begin
    lbLibraryFPs.Items.Text := GetLibraryFPsList(xpeSearch.Text, cbLibraries.Text);
    lbLibraryFPsCount.Caption := IntToStr(lbLibraryFPs.Items.Count);
End;

Procedure SetComponentsComboBox(Dummy : Integer = 0);
Var
    Path : WideString;
    I    : Integer;
Begin
    Path := SchLib.DocumentName;
    For I : = 0 to IntMan.GetComponentCount(Path) - 1 Do
        cbComponents.Items.Add(IntMan.GetComponentName(Path, I));
    cbComponents.ItemIndex := cbComponents.Items.IndexOf(SchLib.CurrentSchComponent.LibReference);
    lbComponentFPs.Items.Text := GetCurrentCompFPsList;
End;

{..............................................................................}
                          {ListBoxes}
{..............................................................................}

Procedure TSchLibManager.lbComponentFPsDblClick(Sender: TObject);
Begin
    lbComponentFPs.Items.Delete(lbComponentFPs.ItemIndex);
    CompareFPsLists;
End;

Procedure TSchLibManager.lbLibraryFPsDblClick(Sender: TObject);
Var
    Index : Integer;
Begin
    Index := FindInListBox(lbComponentFPs, lbLibraryFPs.Items[lbLibraryFPs.ItemIndex]);
    If Index = -1 Then
        lbComponentFPs.Items.Append(lbLibraryFPs.Items[lbLibraryFPs.ItemIndex])
    Else
        lbComponentFPs.Items.Delete(Index);
    CompareFPsLists;
End;

{..............................................................................}
                          {Buttons}
{..............................................................................}

Procedure TSchLibManager.bAddToLeftClick(Sender: TObject);
Var
    I : Integer;
    J : Integer;
Begin
    For I := 0 to lbLibraryFPs.Items.Count - 1 Do
        If lbLibraryFPs.Selected[I] Then
        Begin
            J := FindInListBox(lbComponentFPs, lbLibraryFPs.Items[I]);
            If J = -1 Then
                lbComponentFPs.Items.Append(lbLibraryFPs.Items[I]);
        End;
    CompareFPsLists;
End;

Procedure TSchLibManager.bRemoveClick(Sender: TObject);
Var
    I : Integer;
Begin
    For I := lbComponentFPs.Items.Count - 1 downto 0 Do
    Begin
        If lbComponentFPs.Selected[I] Then
            lbComponentFPs.Items.Delete(I);
    End;
    lbComponentFPsCount.Caption := IntToStr(lbComponentFPs.Items.Count);
    CompareFPsLists;
End;

Procedure TSchLibManager.bValidateClick(Sender: TObject);
Var
    AllFPs  : TWideStringList;
    I       : Integer;
Begin
    AllFPs := TStringList.Create;
    Try
        AllFPs.Text := GetLibraryFPsList('', 'All');
        For I := lbComponentFPs.Items.Count - 1 downto 0 Do
            If AllFPs.IndexOf(lbComponentFPs.Items[I]) = -1 Then
                lbComponentFPs.Items.Delete(I);
    Finally
        AllFPs.Free;
    End;
    CompareFPsLists;
End;

Procedure TSchLibManager.bResetClick(Sender: TObject);
Begin
    SetComponentFPsList;
    CompareFPsLists;
End;

Procedure TSchLibManager.bApplyClick(Sender: TObject);
Begin
    ApplyFPsList;
End;

Procedure TSchLibManager.bApplyParamClick(Sender: TObject);
Begin
    ApplyParamList;
End;

Procedure TSchLibManager.bOkClick(Sender: TObject);
Begin
    ApplyFPsList;
    ApplyParamList;
    SchLibManager.Close;
End;

Procedure TSchLibManager.bCloseClick(Sender: TObject);
Begin
    SchLibManager.Close;
End;

Procedure TSchLibManager.bTempClick(Sender: TObject);
Var
    CompIterator  : ISch_Iterator;
    Component     : ISch_Component;
    ParamIterator : ISch_Iterator;
    Parameter     : ISch_Parameter;
    FixCount      : Integer;
Begin
    FixCount := 0;
    SchLib.LockViewUpdate;

    CompIterator := SchLib.SchLibIterator_Create;
    Try
        CompIterator.AddFilter_ObjectSet(MkSet(26));   {Component}
        Component := CompIterator.FirstSchObject;
        While Component <> Nil Do
        Begin
            ParamIterator := Component.SchIterator_Create;
            Try
                ParamIterator.AddFilter_ObjectSet(MkSet(eParameter));
                Parameter := ParamIterator.FirstSchObject;
                While Parameter <> Nil Do
                Begin
                    If Parameter.Color <> Component.Designator.Color Then
                    Begin
                        Parameter.Color := Component.Designator.Color;
                        Inc(FixCount);
                    End;

                    Parameter := ParamIterator.NextSchObject;
                End;
            Finally
                Component.SchIterator_Destroy(ParamIterator);
            End;

            Component := CompIterator.NextSchObject;
        End;
    Finally
        SchLib.SchIterator_Destroy(CompIterator);
    End;

    SchLib.UnLockViewUpdate;
    ShowInfo(IntToStr(FixCount) + ' parameters have been fixed.', '');
End;

Procedure TSchLibManager.bUpdateClick(Sender: TObject);
Var
    Document    : IServerDocument;
    PCBLib      : IPCB_Library;
    FPsIterator : IPCB_LibraryIterator;
    Footprint   : IPCB_LibComponent;
    FPsList     : TWideStringList;
    DscrptList  : TWideStringList;
    LibPath     : WideString;
    LibCount    : Integer;
    I           : Integer;
Begin
    SchLibManager.FormStyle := fsNormal;
    FPsList := TStringList.Create;
    DscrptList := TStringList.Create;
    Try
        FPsList.Append(GetDateAndTimeStamp);
        FPsList.Append('');
        ProgressBar.Position := 0;
        ProgressBar.Max := 0;
        For I : = 0 to IntMan.InstalledLibraryCount - 1 Do
                If ExtractFileExtFromPath(IntMan.InstalledLibraryPath(I)) = '.PcbLib' Then
                    ProgressBar.Max := ProgressBar.Max + 1;
        ProgressBar.Visible := True;
        For I : = 0 to IntMan.InstalledLibraryCount - 1 Do
        Begin
            LibPath := IntMan.InstalledLibraryPath(I);
            If ExtractFileExtFromPath(LibPath) = '.PcbLib' Then
            Begin
                Document := Client.OpenDocument('PCBLIB', LibPath);
                If Document = Nil Then
                    Continue;
                PCBLib := PCBServer.GetPCBLibraryByPath(LibPath);
                If PCBLib = Nil Then
                Begin
                    Client.CloseDocument(Document);
                    Continue;
                End;
                Inc(LibCount);
                FPsList.Append(ExtractWholeFileNameFromPath(LibPath) + #31 + IntToStr(PCBLib.ComponentCount));
                FPsIterator := PCBLib.LibraryIterator_Create;
                FPsIterator.SetState_FilterAll;
                Try
                    Footprint := FPsIterator.FirstPCBObject;
                    While Footprint <> Nil Do
                    Begin
                        If Footprint.Description <> '' Then
                            DscrptList.Append(Footprint.Name + #31 + Footprint.Description);
                        FPsList.Append(Footprint.Name{ + GetFootprintPinCount(Footprint)});
                        Footprint := FPsIterator.NextPCBObject;
                    End;
                    ProgressBar.Position := ProgressBar.Position + 1;
                Finally
                    PCBLib.LibraryIterator_Destroy(FPsIterator);
                    Client.CloseDocument(Document);
                End;
             End;
        End;
        FPsList.Strings[1] := IntToStr(LibCount) + #31 + IntToStr(FPsList.Count - LibCount - 2);
        FPsList.Append('~Descriptions' + #31 + IntToStr(DscrptList.Count));
        FPsList.Text := FPsList.Text + DscrptList.Text;
        FPsList.SaveToFile(Dir + DataFileName);
     Finally
        FPsList.Free;
        DscrptList.Free;
     End;
     cbLibraries.Clear;
     SetLibrariesComboBox;
     ProgressBar.Visible := False;
     lbLibraryFPs.Items.Text := GetLibraryFPsList(xpeSearch.Text, cbLibraries.Text);
     SchLibManager.FormStyle := fsStayOnTop;
End;

{..............................................................................}
                             {Main}
{..............................................................................}

Procedure RunSchLibManager;
Var
   I : Integer;
Begin
    If Client = Nil Then
    Begin
        ShowWarning('Client is not active!');
        Exit;
    End;
    If PCBServer = Nil Then
    Begin
        ShowWarning('PCB Server is not active!');
        Exit;
    End;
    If SchServer = Nil Then
    Begin
        ShowWarning('Sch Server is not active!');
        Exit;
    End;
    IntMan := IntegratedLibraryManager;
    If IntMan = Nil Then
    Begin
        ShowWarning('Integrated Library Manager is not active!');
        Close;
    End;
    SchLib := SchServer.GetCurrentSchDocument;
    If SchLib = Nil Then
    Begin
        ShowWarning('Current document is not Sch Lib!');
        Exit;
    End;
    WorkSpace := GetWorkspace;
    For I := 0 to WorkSpace.DM_ProjectCount Do
        If (WorkSpace.DM_Projects(I) <> Nil) and (WorkSpace.DM_Projects(I).DM_ProjectFileName = 'SchLibManager.PrjScr') Then
        Begin
            Dir := ExtractFileDirFromPath(WorkSpace.DM_Projects(I).DM_ProjectFullPath);
            Break;
        End;
    SetGUI;
    SetComponentsComboBox;
    lbComponentFPsCount.Caption := IntToStr(lbComponentFPs.Items.Count);
    SetParametersCheckListBox;
    SchLibManager.Show;
    SetLibrariesComboBox;
    SchLibManager.FormStyle := fsStayOnTop;
End;

End.
