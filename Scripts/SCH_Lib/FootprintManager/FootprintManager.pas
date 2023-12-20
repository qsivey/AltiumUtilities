{..............................................................................}
{      SchLibCompFPsManager v0.5                                         WIP   }
{   Manager for schematic lib components' footprints.                          }
{                                                                              }
{                                                                              }
{..............................................................................}

Const
    DataFileName = 'FootprintList.dat';
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
    ScriptVersion = 'v0.5';
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
    SchLibCompFPsManager.Icon := iContainer.Picture;
    iContainer.Free;
    SchLibCompFPsManager.Caption := SchLibCompFPsManager.Caption + ScriptVersion;
    UIDarkMode := Client.OptionsManager.GetOptionsReader('Client', '').ReadString('Client Preferences', 'UIThemeName', '') = 'Altium Dark Gray';
    If UIDarkMode Then
    Begin
        SchLibCompFPsManager.Color := $4E4E4E;
        SchLibCompFPsManager.Font.Color := $FFFFFF;
        lbComponentFPs.Color := $3B3B3B;
        For I := 0 to SchLibCompFPsManager.ComponentCount - 1 Do
            Case SchLibCompFPsManager.Components[I].ClassName of
                'TXPExtPanel':
                Begin
                    Case SchLibCompFPsManager.Components[I].Tag of
                            0:
                            Begin
                                 SchLibCompFPsManager.Components[I].Color := cldPanelLabel;
                                 SchLibCompFPsManager.Components[I].BorderColor := cldBorderActive;
                            End;
                            1:
                            Begin
                                 SchLibCompFPsManager.Components[I].Color := cldPanelMain;
                                 SchLibCompFPsManager.Components[I].BorderColor := cldBorderUnactive;
                            End;
                            2:
                            Begin
                                 SchLibCompFPsManager.Components[I].Color := cldListBox;
                                 SchLibCompFPsManager.Components[I].BorderColor := cldBorderActive;
                            End;
                            3:
                            Begin
                                 SchLibCompFPsManager.Components[I].Color := cldPanelButton;
                                 SchLibCompFPsManager.Components[I].BorderColor := cldBorderActive;
                            End;
                    End;
                End;
                'TShape':
                Begin
                          SchLibCompFPsManager.Components[I].Brush.Color := cldPanelBtnUnactive;
                          SchLibCompFPsManager.Components[I].Pen.Color := cldBorderActive;
                End;
                'TListBox':
                          SchLibCompFPsManager.Components[I].Color := cldListBox;
                'TXPLabel':
                          SchLibCompFPsManager.Components[I].Font.Color := $FFFFFF;
                'TComboBox':
                          SchLibCompFPsManager.Components[I].Color := cldPanelButton;
                End;
    End;
End;

{..............................................................................}
                          {Procedures}
{..............................................................................}

Procedure SetLibraryFPsList(const NameFilter : WideString, const LibFilter : WideString);
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
        Exit;
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
        lbLibraryFPs.Clear;
        lbLibraryFPs.Items.Text := FiltList.Text;
        lbLibraryFPsCount.Caption := IntToStr(lbLibraryFPs.Items.Count);
    Finally
        FPsList.Free;
        FiltList.Free;
    End;
End;

Procedure AddFootprint(Const FootprintName : WideString);
Var
   SchImp   : ISch_Implementation;
   DataList : TWideStringList;
   Ptr      : Integer;
Begin
    SchImp := SchServer.SchObjectFactory(eImplementation,eCreate_Default);
    SchImp.ModelType := 'PCBLIB';
    SchImp.ModelName := FootprintName;
    DataList := TStringList.Create;
    Try
        DataList.LoadFromFile(Dir + DataFileName);
        Ptr := StrToInt(Copy(DataList.Strings[1], 1, Pos(#31, DataList.Strings[1]) - 1)) + StrToInt(Copy(DataList.Strings[1], Pos(#31, DataList.Strings[1]) + 1, Length(DataList.Strings[1]) - 1)) + 3;
        For Ptr := Ptr to Ptr + StrToInt(Copy(DataList.Strings[Ptr - 1], Pos(#31, DataList.Strings[Ptr - 1]) + 1, Length(DataList.Strings[Ptr - 1]) - 1)) - 1 Do
            If Copy(DataList.Strings[Ptr], 1, Pos(#31, DataList.Strings[Ptr]) - 1) = FootprintName Then
                SchImp.Description := Copy(DataList.Strings[Ptr], Pos(#31, DataList.Strings[Ptr]) + 1, Length(DataList.Strings[Ptr]) - 1);
    Finally
        DataList.Free;
    End;
    SchImp.AddDataFileLink(FootprintName, '', 'PCBLib');
    SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
    SchLib.CurrentSchComponent.AddImplementationToComponent(SchImp);
    SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_EndModify, c_NoEventData);
End;

Procedure DeleteFootprint(Const FootprintName : WideString);
Var
    ImpIterator   : ISch_Iterator;
    SchImp        : ISch_Implementation;
Begin
    ImpIterator := SchLib.CurrentSchComponent.SchIterator_Create;
    ImpIterator.AddFilter_ObjectSet(MkSet(eImplementation));
    Try
        SchImp := ImpIterator.FirstSchObject;
        While SchImp <> Nil Do
        Begin
            If (SchImp.ModelType = 'PCBLIB') and (SchImp.ModelName = FootprintName) Then
            Begin
                SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_BeginModify, c_NoEventData);
                SchLib.CurrentSchComponent.RemoveSchImplementation(SchImp);
                SchServer.RobotManager.SendMessage(SchLib.CurrentSchComponent.I_ObjectAddress, c_BroadCast, SCHM_EndModify, c_NoEventData);
            End;
            SchImp := ImpIterator.NextSchObject;
        End;
    Finally
        SchLib.CurrentSchComponent.SchIterator_Destroy(ImpIterator);
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
    SetLibraryFPsList(xpeSearch.Text, cbLibraries.Text);
End;

Procedure TSchLibCompFPsManager.bUpdateClick(Sender: TObject);
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
    SchLibCompFPsManager.FormStyle := fsNormal;
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
                        FPsList.Append(Footprint.Name);
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
     SetLibraryFPsList(xpeSearch.Text, cbLibraries.Text);
     bUpdate.Cursor := crDefault;
     SchLibCompFPsManager.FormStyle := fsStayOnTop;
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

Procedure ApplyList(Dummy : Integer = 0);
Var
    InitialFPsList : TWidestringList;
    I              : Integer;
    J              : Integer;
Begin
    SchServer.ProcessControl.PreProcess(SchLib, '');
    InitialFPsList := TStringList.Create;
    Try
        InitialFPsList.Text := GetCurrentCompFPsList;
        If InitialFPsList.Count = 0 Then
            InitialFPsList.Append('Null');
        If lbComponentFPs.Count <> 0 Then
        Begin
            For I := 0 to lbComponentFPs.Count - 1 Do
                For J := 0 to InitialFPsList.Count - 1 Do
                Begin
                    If InitialFPsList.Strings[J] = lbComponentFPs.Items[I] Then
                        Break;
                    If J = InitialFPsList.Count - 1 Then
                        AddFootprint(lbComponentFPs.Items[I]);
                End;
            For I := 0 to InitialFPsList.Count - 1 Do
                For J := 0 to lbComponentFPs.Count - 1 Do
                Begin
                    If InitialFPsList.Strings[I] = lbComponentFPs.Items[J] Then
                        Break;
                    If J = lbComponentFPs.Count - 1 Then
                        DeleteFootprint(InitialFPsList.Strings[I]);
                End;
        End
        Else
            For I := 0 to InitialFPsList.Count - 1 Do
                DeleteFootprint(InitialFPsList.Strings[I]);
    Finally
        InitialFPsList.Free;
    End;
    SchServer.ProcessControl.PostProcess(SchLib, '');
    lbComponentFPs.Clear;
    lbComponentFPs.Items.Text := GetCurrentCompFPsList;
    lbComponentFPsCount.Caption := IntToStr(lbComponentFPs.Items.Count);
End;

Procedure TSchLibCompFPsManager.eSearchChange(Sender: TObject);
Begin
    SetLibraryFPsList(xpeSearch.Text, cbLibraries.Text);
End;

{..............................................................................}
                          {ComboBox}
{..............................................................................}

Procedure TSchLibCompFPsManager.cbComponentsSelect(Sender: TObject);
Begin
    If SchLib.GetState_SchComponentByLibRef(cbComponents.Text) <> Nil Then
        SchLib.CurrentSchComponent := SchLib.GetState_SchComponentByLibRef(cbComponents.Text)
    Else
        cbComponents.Text := cbComponents.Items.LibReference;
    lbComponentFPs.Items.Text := GetCurrentCompFPsList;
End;

Procedure TSchLibCompFPsManager.cbLibrariesSelect(Sender: TObject);
Begin
    SetLibraryFPsList(xpeSearch.Text, cbLibraries.Text);
End;

Procedure SetComponentsComboBox(Dummy : Integer = 0);
Var
    Path     : WideString;
    I        : Integer;
Begin
    Path := SchLib.DocumentName;
    For I : = 0 to IntMan.GetComponentCount(Path) - 1 Do
    Begin
        If cbComponents.Items[cbComponents.Items.Add(IntMan.GetComponentName(Path, I))] = SchLib.CurrentSchComponent.LibReference Then
            cbComponents.ItemIndex := I;
    End;
    lbComponentFPs.Items.Text := GetCurrentCompFPsList;
End;

{..............................................................................}
                          {ListBoxes}
{..............................................................................}

Procedure TSchLibCompFPsManager.lbComponentFPsDblClick(Sender: TObject);
Begin
    lbComponentFPs.Items.Delete(lbComponentFPs.ItemIndex);
    lbComponentFPsCount.Caption := IntToStr(lbComponentFPs.Items.Count);
End;

Procedure TSchLibCompFPsManager.lbLibraryFPsDblClick(Sender: TObject);
Var
    Index : Integer;
Begin
    Index := FindInListBox(lbComponentFPs, lbLibraryFPs.Items[lbLibraryFPs.ItemIndex]);
    If Index = -1 Then
        lbComponentFPs.Items.Append(lbLibraryFPs.Items[lbLibraryFPs.ItemIndex])
    Else
        lbComponentFPs.Items.Delete(Index);
    lbComponentFPsCount.Caption := IntToStr(lbComponentFPs.Items.Count);
End;

{..............................................................................}
                          {Buttons}
{..............................................................................}

Procedure TSchLibCompFPsManager.bAddToLeftClick(Sender: TObject);
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
    lbComponentFPsCount.Caption := IntToStr(lbComponentFPs.Items.Count);
End;

Procedure TSchLibCompFPsManager.bRemoveClick(Sender: TObject);
Var
    I : Integer;
Begin
    For I := lbComponentFPs.Items.Count - 1 downto 0 Do
    Begin
        If lbComponentFPs.Selected[I] Then
            lbComponentFPs.Items.Delete(I);
    End;
    lbComponentFPsCount.Caption := IntToStr(lbComponentFPs.Items.Count);
End;

Procedure TSchLibCompFPsManager.bApplyClick(Sender: TObject);
Begin
    ApplyList;
End;

Procedure TSchLibCompFPsManager.bOkClick(Sender: TObject);
Begin
    ApplyList;
    SchLibCompFPsManager.Close;
End;

Procedure TSchLibCompFPsManager.bCloseClick(Sender: TObject);
Begin
    SchLibCompFPsManager.Close;
End;

{..............................................................................}
                             {Main}
{..............................................................................}

Procedure RunFootprintManager;
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
        If (WorkSpace.DM_Projects(I) <> Nil) and (WorkSpace.DM_Projects(I).DM_ProjectFileName = 'FootprintManager.PrjScr') Then
        Begin
            Dir := ExtractFileDirFromPath(WorkSpace.DM_Projects(I).DM_ProjectFullPath);
            Break;
        End;
    SetComponentsComboBox;
    SetLibrariesComboBox;
    lbComponentFPsCount.Caption := IntToStr(lbComponentFPs.Items.Count);
    SetGUI;
    SchLibCompFPsManager.Show;
End;

End.
