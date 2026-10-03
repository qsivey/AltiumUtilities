{..............................................................................}
{      LibraryStyleChanger v.1.4.6                                             }
{   Changes selected SchLibs using six user-selected role colors.              }
{                                                                              }
{                                                                              }
{..............................................................................}

{..............................................................................}
                          {Procedures}
{..............................................................................}

Const
   { The shared TXT has twelve roles; libraries use the first six. }
   StyleColorCount = 12;

Var
   ImageSourceFolder : String;
   ImageOutputFolder : String;
   StyleWarnings     : TStringList;
   PreparedImageNames: TStringList;
   PreparedImagePaths: TStringList;
   ImagesFound       : Integer;
   ImagesUpdated     : Integer;

Function FindImagesFolder : String;
Var
   LibraryFolder : String;
Begin
     LibraryFolder := ExcludeTrailingPathDelimiter(XPFolderEdit.Text);
     { Originals are always in the sibling Images folder, never in the output. }
     Result := IncludeTrailingPathDelimiter(ExtractFilePath(LibraryFolder)) + 'Images\';
End;

Procedure AddStyleWarning(MessageText : String);
Begin
     If StyleWarnings.IndexOf(MessageText) < 0 Then
        StyleWarnings.Add(MessageText);
End;

Function FindStyleFile(FileName : String) : String;
Var
   Workspace : IWorkspace;
   I         : Integer;
Begin
     Result := ExtractFilePath(GetRunningScriptProjectName) + FileName;
     If FileExists(Result) Then Exit;
     Workspace := GetWorkspace;
     For I := 0 To Workspace.DM_ProjectCount - 1 Do
         If LowerCase(Workspace.DM_Projects(I).DM_ProjectFileName) = 'librarystylechanger.prjscr' Then
         Begin
              Result := ExtractFilePath(Workspace.DM_Projects(I).DM_ProjectFullPath) + FileName;
              Exit;
         End;
End;

Function PrepareImages : Boolean;
Var
   HelperName  : String;
   ResultName  : String;
   CommandLine : String;
   RunCode     : Integer;
   I           : Integer;
   ResultData  : TStringList;
Begin
     Result := False;
     ImageSourceFolder := FindImagesFolder;
     ImageOutputFolder := IncludeTrailingPathDelimiter(XPFolderEdit.Text) + 'Images\';
     If Not DirectoryExists(ImageSourceFolder) Then
     Begin
          ShowWarning('Original PNG folder not found: ' + ImageSourceFolder);
          Exit;
     End;
     HelperName := FindStyleFile('RecolorImages.ps1');
     If Not FileExists(HelperName) Then
     Begin
          ShowWarning('Keep RecolorImages.ps1 next to LibraryStyleChanger.pas: ' + HelperName);
          Exit;
     End;
     If Not ForceDirectories(ImageOutputFolder) Then
     Begin
          ShowWarning('Cannot create image output folder: ' + ImageOutputFolder);
          Exit;
     End;
     ResultName := ImageOutputFolder + '.lsc-result-' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.txt';
     CommandLine := 'powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden' +
                    ' -ExecutionPolicy Bypass -File "' + HelperName + '"' +
                    ' -SourceDirectory "' + ExcludeTrailingPathDelimiter(ImageSourceFolder) + '"' +
                    ' -OutputDirectory "' + ExcludeTrailingPathDelimiter(ImageOutputFolder) + '"' +
                    ' -ColorBgr ' + IntToStr(ShapeImages.Brush.Color And $FFFFFF) +
                    ' -ResultFile "' + ResultName + '"';
     LProcessingState.Caption := 'Preparing PNG images...';
     LProcessingState.Refresh;
     RunCode := RunApplication(CommandLine);
     If RunCode <> 0 Then
     Begin
          ShowWarning('Cannot start PNG conversion: ' + GetErrorMessage(RunCode));
          Exit;
     End;
     { The helper publishes the result atomically, after all PNG files are ready. }
     For I := 0 To 399 Do
     Begin
          If FileExists(ResultName) Then Break;
          Sleep(100);
     End;
     If Not FileExists(ResultName) Then
     Begin
          ShowWarning('PNG conversion did not finish within 40 seconds. Libraries were not changed.' +
                      #13#10 + 'Expected result: ' + ResultName);
          Exit;
     End;
     ResultData := TStringList.Create;
     Try
          ResultData.LoadFromFile(ResultName);
          DeleteFile(ResultName);
          If ResultData.Count = 0 Then
          Begin
               ShowWarning('PNG conversion returned an empty result.');
               Exit;
          End;
          If ResultData.Strings[0] <> 'OK' Then
          Begin
               ShowWarning('PNG conversion failed:' + #13#10 + ResultData.Text);
               Exit;
          End;
          If ((ResultData.Count - 1) Mod 2) <> 0 Then
          Begin
               ShowWarning('PNG conversion returned an incomplete file list.');
               Exit;
          End;
          I := 1;
          While I < ResultData.Count Do
          Begin
               PreparedImageNames.Add(ResultData.Strings[I]);
               PreparedImagePaths.Add(ResultData.Strings[I + 1]);
               I := I + 2;
          End;
          Result := True;
     Finally
          ResultData.Free;
     End;
End;

Function OriginalPngName(ImagePath : String) : String;
Var
   Stem   : String;
   Marker : Integer;
   I      : Integer;
Begin
     Result := ExtractFileName(ImagePath);
     { An exact original filename takes priority, even if it contains _HEX. }
     If PreparedImageNames.IndexOf(Result) >= 0 Then Exit;
     Marker := Pos('.__lsc_v2_', LowerCase(Result));
     If Marker = 0 Then Marker := Pos('.__lsc_original_v1_', LowerCase(Result));
     If Marker > 0 Then
     Begin
          Result := Copy(Result, 1, Marker - 1) + '.png';
          Exit;
     End;
     Stem := ChangeFileExt(Result, '');
     If Length(Stem) <= 10 Then Exit;
     Marker := Length(Stem) - 9;
     If UpperCase(Copy(Stem, Marker, 4)) <> '_HEX' Then Exit;
     For I := Marker + 4 To Length(Stem) Do
          If Pos(UpperCase(Stem[I]), '0123456789ABCDEF') = 0 Then Exit;
     Result := Copy(Stem, 1, Marker - 1) + '.png';
End;

Procedure RecolorLibraryImage(Primitive : ISch_Image);
Var
   OriginalName : String;
   SourceName   : String;
   ColoredName  : String;
   WasEmbedded  : Boolean;
   ImageListIndex : Integer;
Begin
     OriginalName := Primitive.FileName;
     If LowerCase(ExtractFileExt(OriginalName)) <> '.png' Then Exit;
     Inc(ImagesFound);
     SourceName := OriginalPngName(OriginalName);
     ImageListIndex := PreparedImageNames.IndexOf(SourceName);
     If ImageListIndex < 0 Then
     Begin
          AddStyleWarning('Original PNG not found: ' + SourceName);
          Exit;
     End;
     ColoredName := PreparedImagePaths.Strings[ImageListIndex];
     If Not FileExists(ColoredName) Then
     Begin
          AddStyleWarning('Converted PNG not found: ' + ColoredName);
          Exit;
     End;
     WasEmbedded := Primitive.EmbedImage;
     Try
          { FileName loads pixels only for non-embedded images. Clear the old
            name as well, to reload even when reapplying the same cached color. }
          Primitive.EmbedImage := False;
          Primitive.FileName := '';
          Primitive.FileName := ColoredName;
          { Pixels are loaded using the absolute path above. Change only the
            stored link while embedded, then restore the original mode. }
          Primitive.EmbedImage := True;
          Primitive.FileName := 'Images\' + ExtractFileName(ColoredName);
          Primitive.EmbedImage := WasEmbedded;
          Primitive.GraphicallyInvalidate;
          Inc(ImagesUpdated);
     Except
          Primitive.EmbedImage := False;
          Primitive.FileName := OriginalName;
          Primitive.EmbedImage := WasEmbedded;
          AddStyleWarning('Could not reload PNG: ' + OriginalName);
     End;
End;

Function HasPotentialPinOcclusion(PrimitiveContainer : ISch_BasicContainer;
                                  Component : ISch_Component;
                                  PartNumber, DisplayModeNumber : Integer) : Boolean;
Var
   ChildIterator : ISch_Iterator;
   Primitive     : ISch_GraphicalObject;
   SeenVisiblePin: Boolean;
Begin
     Result := False;
     SeenVisiblePin := False;
     ChildIterator := PrimitiveContainer.SchIterator_Create;
     If ChildIterator = Nil Then Raise('Cannot inspect component primitive order.');
     Try
          ChildIterator.SetState_IterationDepth(eIterateFirstLevel);
          ChildIterator.AddFilter_PartPrimitives(PartNumber, DisplayModeNumber);
          ChildIterator.AddFilter_ObjectSet(MkSet(ePin, eRectangle, ePolygon));
          Primitive := ChildIterator.FirstSchObject;
          While Primitive <> Nil Do
          Begin
               If Primitive.ObjectId = ePin Then
               Begin
                    If (Not Primitive.IsHidden) Or Component.ShowHiddenPins Then
                         If (Primitive.ShowName And (Primitive.Name <> '')) Or
                            (Primitive.ShowDesignator And (Primitive.Designator <> '')) Then
                              SeenVisiblePin := True;
               End;
               { Order-only check: no bounds calculations or pin list. }
               If SeenVisiblePin And ((Primitive.ObjectId = eRectangle) Or
                                      (Primitive.ObjectId = ePolygon)) Then
                    If Primitive.IsSolid And (Not Primitive.Transparent) Then
                    Begin
                         Result := True;
                         Exit;
                    End;
               Primitive := ChildIterator.NextSchObject;
          End;
     Finally
          PrimitiveContainer.SchIterator_Destroy(ChildIterator);
     End;
End;

Procedure WarnBodyPrimitiveOrder(Component : ISch_Component;
                                 PrimitiveContainer : ISch_BasicContainer;
                                 LibraryName : String);
Var
   PartNumber        : Integer;
   DisplayModeNumber : Integer;
Begin
     If Not cbEnableBodyFill.Checked Then Exit;
     If cbTransparentBodyFill.Checked Then Exit;
     Try
          { Check every library part and display mode without changing the
            component's current part, current mode or primitive order. }
          For PartNumber := 1 To Component.PartCount Do
               For DisplayModeNumber := 0 To Component.DisplayModeCount - 1 Do
                    If HasPotentialPinOcclusion(PrimitiveContainer, Component, PartNumber, DisplayModeNumber) Then
                    Begin
                         AddStyleWarning(LibraryName + ': Some pin labels may be covered by rectangle or polygon fills. ' +
                              'Check primitive order in the components. Order left unchanged.');
                         Exit;
                    End;
     Except
          AddStyleWarning(LibraryName + ': Could not check component primitive order.');
     End;
End;

Procedure IterateCompPrimitives(PrimitiveContainer : ISch_BasicContainer;
                                BodyOutlineColor, BodyFillColor,
                                GraphicsColor, ParameterColor,
                                PinTextColor : TColor;
                                RecolorImages : Boolean);
Var
   PrimitiveIterator : ISch_Iterator;
   Primitive         : ISch_GraphicalObject;
Begin
     PrimitiveIterator := PrimitiveContainer.SchIterator_Create;
     If PrimitiveIterator = Nil Then Raise('Cannot inspect component primitives.');
     Try
          PrimitiveIterator.SetState_IterationDepth(eIterateFirstLevel);
          Primitive := PrimitiveIterator.FirstSchObject;
          While Primitive <> Nil Do
          Begin
               Case Primitive.ObjectId of
                    ePin:
                    Begin
                         Primitive.SetState_Color := PinTextColor;
                         Primitive.Designator_CustomColor := PinTextColor;
                         Primitive.Name_CustomColor := PinTextColor;
                    End;
                    eRectangle, ePolygon:
                    Begin
                         Primitive.SetState_Color := BodyOutlineColor;
                         { Both callers supply component primitives at first level:
                           stored components, or the active symbol in the library
                           editor. The latter is owned by SchLib, not Component. }
                         Primitive.SetState_AreaColor := BodyFillColor;
                         Primitive.IsSolid := cbEnableBodyFill.Checked;
                         Primitive.Transparent := cbTransparentBodyFill.Checked;
                    End;
                    eEllipse, eRoundRectangle:
                    Begin
                         Primitive.SetState_Color := BodyOutlineColor;
                         { Body Fill controls apply to component Rectangle and Polygon objects. }
                    End;
                    eDesignator:
                         Primitive.SetState_Color := ParameterColor;
                    eParameter:
                         Primitive.SetState_Color := ParameterColor;
                    ePolyline:
                         Primitive.SetState_Color := GraphicsColor;
                    eArc:
                         If Primitive.Radius <> MilsToCoord(20) Then
                             Primitive.SetState_Color := GraphicsColor
                         Else
                             Primitive.SetState_Color := PinTextColor;
                    22:   {Text}
                         Primitive.SetState_Color := PinTextColor;
                    eImage:
                         If RecolorImages Then
                            RecolorLibraryImage(Primitive);
               End;
               Primitive := PrimitiveIterator.NextSchObject;
          End;
     Finally
            PrimitiveContainer.SchIterator_Destroy(PrimitiveIterator);
     End;
End;

Procedure IterateLibComps(I : Integer);
Var
   SchLib       : ISch_Lib;
   CompIterator : ISch_Iterator;
   Component    : ISch_Component;
   LibraryName  : String;
Begin
     LibraryName := CheckListBoxSchLibraries.Items.Strings[I];
     SchLib := SchServer.GetSchDocumentByPath(XPFolderEdit.Text + CheckListBoxSchLibraries.Items.Strings[I]);
     If SchLib = Nil Then
     Begin
          ShowWarning( CheckListBoxSchLibraries.Items.Strings[I] + ' is not Sch Library.');
          Exit;
     End;
     Try
          CompIterator := SchLib.SchLibIterator_Create;
          CompIterator.AddFilter_ObjectSet(MkSet(26));   {Component}
          Component := CompIterator.FirstSchObject;
          While Component <> Nil Do
          Begin
               IterateCompPrimitives(Component,
                                     ShapeBodyOutline.Brush.Color,
                                     ShapeBodyFill.Brush.Color,
                                     ShapeGraphics.Brush.Color,
                                     ShapeParameters.Brush.Color,
                                     ShapePinText.Brush.Color,
                                     cbRecolorImages.Checked);
               WarnBodyPrimitiveOrder(Component, Component, LibraryName);
               Component := CompIterator.NextSchObject;
          End;
     Finally
            SchLib.SchIterator_Destroy(CompIterator);
     End;
     { Altium moves the active part's visible primitives out of its component
       into the library editor. A component-only pass misses these objects. }
     Component := SchLib.CurrentSchComponent;
     If Component <> Nil Then
     Begin
          IterateCompPrimitives(SchLib,
                                ShapeBodyOutline.Brush.Color,
                                ShapeBodyFill.Brush.Color,
                                ShapeGraphics.Brush.Color,
                                ShapeParameters.Brush.Color,
                                ShapePinText.Brush.Color,
                                cbRecolorImages.Checked);
          WarnBodyPrimitiveOrder(Component, SchLib, LibraryName);
     End;
     SchLib.GraphicallyInvalidate;
End;

{..............................................................................}
                          {Edit}
{..............................................................................}

procedure TLibraryStyleChangerForm.XPFolderChange(Sender: TObject);
Var
    I                : Integer;
    SchLIBFiles      : TWideStringList;
    Path             : WideString;
    Check            : WideString;
Begin
     Check := XPFolderEdit.Text;
     If Check = '' Then
     Begin
          CheckListBoxSchLibraries.Items.Clear;
          Exit;
     End;
     If Not(Check[Length(Check)] = '\') Then
        XPFolderEdit.Text := XPFolderEdit.Text + '\';
     Path := XPFolderEdit.Text;
     If CheckListBoxSchLibraries.Items.Count > 0 Then
             For I := 0 to CheckListBoxSchLibraries.Items.Count - 1 Do
                 CheckListBoxSchLibraries.Items.Delete(CheckListBoxSchLibraries.Items.Count - 1);
     Try
         SchLIBFiles := TStringList.Create;
         FindFiles(Path,'*.SchLib',faAnyFile,False, SchLibFiles);

         If SchLIBFiles.Count > 0 Then
             For I := 0 to SchLIBFiles.Count - 1 Do
                 CheckListBoxSchLibraries.Items.Add(ExtractFileName(SchLIBFiles.Strings[I]))
         Else
              Exit;
     Finally
         SchLIBFiles.Free;
     End;
     For I := 0 to CheckListBoxSchLibraries.Items.Count - 1 Do
        CheckListBoxSchLibraries.Checked[I] := True;
End;

{..............................................................................}
                          {Buttons}
{..............................................................................}

{ TXT uses ordinary RGB, while Altium TColor stores bytes in BGR order. }
Function HexRGBToColor(HexText : String) : Integer;
Var
   CharNumber : Integer;
   DigitValue : Integer;
   RGBValue   : Integer;
Begin
     Result := -1;
     HexText := UpperCase(Trim(HexText));
     If Length(HexText) > 0 Then
        If HexText[1] = '#' Then Delete(HexText, 1, 1);
     If Length(HexText) <> 6 Then Exit;
     RGBValue := 0;
     For CharNumber := 1 To 6 Do
     Begin
          DigitValue := Pos(HexText[CharNumber], '0123456789ABCDEF') - 1;
          If DigitValue < 0 Then Exit;
          RGBValue := RGBValue * 16 + DigitValue;
     End;
     Result := (RGBValue Div 65536) + ((RGBValue Div 256) Mod 256) * 256 +
               (RGBValue Mod 256) * 65536;
End;

Function ReadStylePresets(PresetNames, PresetColors : TStringList) : Boolean;
Var
   TextLines     : TStringList;
   RoleKeys      : TStringList;
   PresetPath    : String;
   LineText      : String;
   PresetTitle   : String;
   KeyText       : String;
   ErrorText     : String;
   LineNumber    : Integer;
   SeparatorPos  : Integer;
   RoleNumber    : Integer;
   PresetNumber  : Integer;
   ColorSlot     : Integer;
   ColorValue    : Integer;
Begin
     Result := False;
     PresetPath := FindStyleFile('..\..\..\Libraries\StylePresets.txt');
     If Not FileExists(PresetPath) Then
     Begin
          ShowWarning('Preset file not found: ' + PresetPath);
          Exit;
     End;
     TextLines := TStringList.Create;
     RoleKeys := TStringList.Create;
     Try
          Try
               TextLines.LoadFromFile(PresetPath);
          Except
               ShowWarning('Cannot read preset file: ' + PresetPath);
               Exit;
          End;
          RoleKeys.Text := 'bodyoutline' + #13#10 + 'bodyfill' + #13#10 +
               'graphics' + #13#10 + 'parameters' + #13#10 + 'pintext' + #13#10 +
               'images' + #13#10 + 'wires' + #13#10 + 'portborder' + #13#10 +
               'portfill' + #13#10 + 'portfont' + #13#10 + 'other' + #13#10 +
               'sheetcolor';
          PresetNames.Clear;
          PresetColors.Clear;
          PresetNumber := -1;
          ErrorText := '';
          For LineNumber := 0 To TextLines.Count - 1 Do
          Begin
               LineText := Trim(TextLines.Strings[LineNumber]);
               If LineText = '' Then Continue;
               If LineText[1] = ';' Then Continue;
               If LineText[1] = '[' Then
               Begin
                    If LineText[Length(LineText)] <> ']' Then
                    Begin
                         ErrorText := 'Expected [Preset name].';
                         Break;
                    End;
                    PresetTitle := Trim(Copy(LineText, 2, Length(LineText) - 2));
                    If (PresetTitle = '') Or (PresetNames.IndexOf(PresetTitle) >= 0) Then
                    Begin
                         ErrorText := 'Empty or duplicate preset name: ' + PresetTitle;
                         Break;
                    End;
                    PresetNames.Add(PresetTitle);
                    PresetNumber := PresetNames.Count - 1;
                    For RoleNumber := 0 To StyleColorCount - 1 Do PresetColors.Add('');
               End
               Else
               Begin
                    SeparatorPos := Pos('=', LineText);
                    If (PresetNumber < 0) Or (SeparatorPos < 2) Then
                    Begin
                         ErrorText := 'Expected a [Preset name] followed by Role=#RRGGBB lines.';
                         Break;
                    End;
                    KeyText := LowerCase(Trim(Copy(LineText, 1, SeparatorPos - 1)));
                    RoleNumber := RoleKeys.IndexOf(KeyText);
                    If RoleNumber < 0 Then
                    Begin
                         ErrorText := 'Unknown color role: ' + KeyText;
                         Break;
                    End;
                    ColorSlot := PresetNumber * StyleColorCount + RoleNumber;
                    If PresetColors.Strings[ColorSlot] <> '' Then
                    Begin
                         ErrorText := 'Duplicate color role: ' + KeyText;
                         Break;
                    End;
                    ColorValue := HexRGBToColor(Copy(LineText, SeparatorPos + 1, Length(LineText)));
                    If ColorValue < 0 Then
                    Begin
                         ErrorText := 'Invalid color for ' + KeyText + ': use #RRGGBB.';
                         Break;
                    End;
                    PresetColors.Strings[ColorSlot] := IntToStr(ColorValue);
               End;
          End;
          If ErrorText <> '' Then
          Begin
               ShowWarning(PresetPath + #13#10 + 'Line ' + IntToStr(LineNumber + 1) + ': ' + ErrorText);
               Exit;
          End;
          If PresetNames.Count = 0 Then
          Begin
               ShowWarning('No presets found in ' + PresetPath);
               Exit;
          End;
          For ColorSlot := 0 To PresetColors.Count - 1 Do
          Begin
               If PresetColors.Strings[ColorSlot] = '' Then
               Begin
                    ShowWarning(PresetPath + #13#10 + '[' +
                         PresetNames.Strings[ColorSlot Div StyleColorCount] + '] is missing ' +
                         RoleKeys.Strings[ColorSlot Mod StyleColorCount] + '.');
                    Exit;
               End;
          End;
          Result := True;
     Finally
          RoleKeys.Free;
          TextLines.Free;
     End;
End;

Function ReloadStylePresets(ApplySelection : Boolean) : Boolean;
Var
   PresetNames    : TStringList;
   PresetColors   : TStringList;
   SelectedPreset : String;
   PresetNumber   : Integer;
   ColorOffset    : Integer;
Begin
     Result := False;
     SelectedPreset := cbPresets.Text;
     PresetNames := TStringList.Create;
     PresetColors := TStringList.Create;
     Try
          If Not ReadStylePresets(PresetNames, PresetColors) Then Exit;
          PresetNumber := PresetNames.IndexOf(SelectedPreset);
          If PresetNumber < 0 Then
          Begin
               If ApplySelection And (SelectedPreset <> '') Then
               Begin
                    cbPresets.Items.Assign(PresetNames);
                    cbPresets.ItemIndex := -1;
                    ShowWarning('Preset was removed or renamed. Choose a preset from the list.');
                    Exit;
               End;
               PresetNumber := 0;
          End;
          cbPresets.Items.Assign(PresetNames);
          cbPresets.ItemIndex := PresetNumber;
          If ApplySelection Then
          Begin
               { Validate the entire file before changing any visible color. }
               ColorOffset := PresetNumber * StyleColorCount;
               ShapeBodyOutline.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset]);
               ShapeBodyFill.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 1]);
               ShapeGraphics.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 2]);
               ShapeParameters.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 3]);
               ShapePinText.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 4]);
               ShapeImages.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 5]);
               LProcessingState.Caption := 'Preset applied: ' + cbPresets.Text;
          End;
          Result := True;
     Finally
          PresetColors.Free;
          PresetNames.Free;
     End;
End;

Procedure TLibraryStyleChangerForm.cbPresetsDropDown(Sender : TObject);
Begin
     If Not ReloadStylePresets(False) Then Exit;
End;

Procedure TLibraryStyleChangerForm.bApplyPresetClick(Sender : TObject);
Begin
     If Not ReloadStylePresets(True) Then Exit;
End;

Function ChooseStyleColor(CurrentColor : TColor) : TColor;
Begin
     Result := CurrentColor;
     StyleColorDialog.Color := CurrentColor;
     If StyleColorDialog.Execute Then
        Result := StyleColorDialog.Color;
End;

Procedure TLibraryStyleChangerForm.bBodyOutlineColorClick(Sender: TObject);
Begin
     ShapeBodyOutline.Brush.Color := ChooseStyleColor(ShapeBodyOutline.Brush.Color);
End;

Procedure TLibraryStyleChangerForm.bBodyFillColorClick(Sender: TObject);
Begin
     ShapeBodyFill.Brush.Color := ChooseStyleColor(ShapeBodyFill.Brush.Color);
End;

Procedure TLibraryStyleChangerForm.bGraphicsColorClick(Sender: TObject);
Begin
     ShapeGraphics.Brush.Color := ChooseStyleColor(ShapeGraphics.Brush.Color);
End;

Procedure TLibraryStyleChangerForm.bParametersColorClick(Sender: TObject);
Begin
     ShapeParameters.Brush.Color := ChooseStyleColor(ShapeParameters.Brush.Color);
End;

Procedure TLibraryStyleChangerForm.bPinTextColorClick(Sender: TObject);
Begin
     ShapePinText.Brush.Color := ChooseStyleColor(ShapePinText.Brush.Color);
End;

Procedure TLibraryStyleChangerForm.bImagesColorClick(Sender: TObject);
Begin
     ShapeImages.Brush.Color := ChooseStyleColor(ShapeImages.Brush.Color);
End;

Procedure TLibraryStyleChangerForm.bAllColorsClick(Sender: TObject);
Begin
     StyleColorDialog.Color := ShapeBodyOutline.Brush.Color;
     If Not StyleColorDialog.Execute Then Exit;
     ShapeBodyOutline.Brush.Color := StyleColorDialog.Color;
     ShapeBodyFill.Brush.Color := StyleColorDialog.Color;
     ShapeGraphics.Brush.Color := StyleColorDialog.Color;
     ShapeParameters.Brush.Color := StyleColorDialog.Color;
     ShapePinText.Brush.Color := StyleColorDialog.Color;
     ShapeImages.Brush.Color := StyleColorDialog.Color;
End;

Procedure TLibraryStyleChangerForm.bRunClick(Sender: TObject);
Var
   Document       : IServerDocument;
   I              : Integer;
   CheckedCount   : Integer;
   CheckedCounter : Integer;
   SummaryText    : String;
Begin
     CheckedCount := 0;
     CheckedCounter := 0;
     For I := 0 to CheckListBoxSchLibraries.Items.Count - 1 Do
         If CheckListBoxSchLibraries.Checked[I] Then
            Inc(CheckedCount);
     If CheckedCount = 0 Then
     Begin
          Showmessage('There is no checked files');
          Exit;
     End;
     StyleWarnings := TStringList.Create;
     PreparedImageNames := TStringList.Create;
     PreparedImagePaths := TStringList.Create;
     ImagesFound := 0;
     ImagesUpdated := 0;
     bRun.Cursor := crHourGlass;
     Try
          If cbRecolorImages.Checked Then
             If Not PrepareImages Then Exit;
          For I := 0 to CheckListBoxSchLibraries.Items.Count - 1 Do
              If CheckListBoxSchLibraries.Checked[I] Then
              Begin
                   Document := Client.OpenDocument('SCHLIB',XPFolderEdit.Text + CheckListBoxSchLibraries.Items.Strings[I]);
                   If Document <> Nil Then
                   Begin
                        Inc(CheckedCounter);
                        LProcessingState.Caption := 'Processing... ' + IntToStr(CheckedCounter) + ' of ' + IntToStr(CheckedCount);
                        LProcessingState.Refresh;
                        IterateLibComps(I);
                        Document.Modified := True;
                        Document.DoFileSave('Advanced Schematic binary library');
                        Client.CloseDocument(Document);
                   End;
              End;
          SummaryText := 'Done. Libraries processed: ' + IntToStr(CheckedCounter) + '.';
          If cbRecolorImages.Checked Then
          Begin
               SummaryText := SummaryText + #13#10 + 'PNG images found: ' + IntToStr(ImagesFound) +
                              '; updated: ' + IntToStr(ImagesUpdated) + '.' + #13#10 +
                              'PNG copies: ' + ImageOutputFolder;
               If ImagesFound = 0 Then
                  AddStyleWarning('No PNG image primitives were found in the selected libraries.');
          End;
          If StyleWarnings.Count = 0 Then
             ShowMessage(SummaryText)
          Else
             ShowWarning(SummaryText + #13#10 + 'Warnings:' +
                         #13#10 + StyleWarnings.Text);
     Finally
          bRun.Cursor := crDefault;
          PreparedImagePaths.Free;
          PreparedImageNames.Free;
          StyleWarnings.Free;
     End;
     Close;
End;

Procedure TLibraryStyleChangerForm.bEnableAllClick(Sender: TObject);
Var
    I : Integer;
Begin
    For I := 0 to CheckListBoxSchLibraries.Items.Count - 1 Do
        CheckListBoxSchLibraries.Checked[I] := True;
End;

Procedure TLibraryStyleChangerForm.bClearAllClick(Sender: TObject);
Var
    I : Integer;
Begin
    For I := 0 to CheckListBoxSchLibraries.Items.Count - 1 Do
        CheckListBoxSchLibraries.Checked[I] := False;
End;

Procedure TLibraryStyleChangerForm.bCancelClick(Sender: TObject);
Begin
     Close;
End;

{..............................................................................}
                             {Main}
{..............................................................................}

Procedure RunLibraryStyleChanger;
Var
   Workspace : IWorkspace;
   WSPrefs   : IWorkspacePreferences;
Begin
     If SchServer = Nil Then
     Begin
          ShowWarning('Sch Server is not active!');
          Exit;
     End;
     Workspace := GetWorkSpace;
     If Workspace = Nil Then
        Exit;
     WSPrefs := Workspace.DM_Preferences;
     XPFolderEdit.InitialDir := WSPrefs.GetDefaultLibraryPath + '\CustomStyleSymbols';
     XPFolderEdit.Text := XPFolderEdit.InitialDir;
     If Not ReloadStylePresets(False) Then
        LProcessingState.Caption := 'Presets could not be loaded; manual colors are available.';
     LibraryStyleChangerForm.ShowModal;
End;

End.


