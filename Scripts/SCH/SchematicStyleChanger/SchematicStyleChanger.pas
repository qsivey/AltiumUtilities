{ SchematicStyleChanger v1.8.5 - Other fills remaining Defaults color fields. }

Const
   StyleColorCount = 12;
   JunctionModeUnchanged = 0;
   JunctionModeManual = 1;
   JunctionModeGlobal = 2;
   ImageModeUnchanged = 0;
   ImageModeRecolor = 1;
   ImageModeOriginal = 2;

Var
   ImageSourceFolder : String;
   ImageOutputFolder : String;
   StyleWarnings     : TStringList;
   PreparedImageNames: TStringList;
   PreparedImagePaths: TStringList;
   ImagesFound       : Integer;
   ImagesUpdated     : Integer;
   ManualJunctionsCreated : Integer;
   CurrentDocumentName : String;
   UpdatingDefaults : Boolean;
   DefaultsImperialFile : String;
   DefaultsMetricFile : String;
   DefaultsStep : String;
   AppliedThemeName : String;

Function FindImagesFolder : String;
Begin
     Result := IncludeTrailingPathDelimiter(OriginalImagesFolder.Text);
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
         If LowerCase(Workspace.DM_Projects(I).DM_ProjectFileName) = 'schematicstylechanger.prjscr' Then
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
   ImageModeName : String;
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
          ShowWarning('Keep RecolorImages.ps1 next to SchematicStyleChanger.pas: ' + HelperName);
          Exit;
     End;
     If Not ForceDirectories(ImageOutputFolder) Then
     Begin
          ShowWarning('Cannot create image output folder: ' + ImageOutputFolder);
          Exit;
     End;
     ImageModeName := 'Recolor';
     If cbImageMode.ItemIndex = ImageModeOriginal Then ImageModeName := 'Original';
     ResultName := ImageOutputFolder + '.lsc-result-' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.txt';
     CommandLine := 'powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden' +
                    ' -ExecutionPolicy Bypass -File "' + HelperName + '"' +
                    ' -SourceDirectory "' + ExcludeTrailingPathDelimiter(ImageSourceFolder) + '"' +
                    ' -OutputDirectory "' + ExcludeTrailingPathDelimiter(ImageOutputFolder) + '"' +
                    ' -Mode ' + ImageModeName +
                    ' -ColorBgr ' + IntToStr(ShapeImages.Brush.Color And $FFFFFF) +
                    ' -ResultFile "' + ResultName + '"';
     LProcessingState.Caption := 'Preparing PNG images: ' + ImageModeName + '...';
     LProcessingState.Refresh;
     RunCode := RunApplication(CommandLine);
     If RunCode <> 0 Then
     Begin
          ShowWarning('Cannot start PNG preparation: ' + GetErrorMessage(RunCode));
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
          ShowWarning('PNG preparation did not finish within 40 seconds. Schematics were not changed.' +
                      #13#10 + 'Expected result: ' + ResultName);
          Exit;
     End;
     ResultData := TStringList.Create;
     Try
          ResultData.LoadFromFile(ResultName);
          DeleteFile(ResultName);
          If ResultData.Count = 0 Then
          Begin
               ShowWarning('PNG preparation returned an empty result.');
               Exit;
          End;
          If ResultData.Strings[0] <> 'OK' Then
          Begin
               ShowWarning('PNG preparation failed:' + #13#10 + ResultData.Text);
               Exit;
          End;
          If ((ResultData.Count - 1) Mod 2) <> 0 Then
          Begin
               ShowWarning('PNG preparation returned an incomplete file list.');
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

Procedure UpdateSchematicImage(Primitive : ISch_Image);
Var
   OriginalName : String;
   SourceName   : String;
   ColoredName  : String;
   WasEmbedded  : Boolean;
   ImageListIndex : Integer;
Begin
     OriginalName := Primitive.FileName;
     If LowerCase(ExtractFileExt(OriginalName)) <> '.png' Then Exit;
     If Not UpdatingDefaults Then Inc(ImagesFound);
     SourceName := OriginalPngName(OriginalName);
     ImageListIndex := PreparedImageNames.IndexOf(SourceName);
     If ImageListIndex < 0 Then
     Begin
          AddStyleWarning(CurrentDocumentName + ': original PNG not found: ' + SourceName);
          Exit;
     End;
     ColoredName := PreparedImagePaths.Strings[ImageListIndex];
     If Not FileExists(ColoredName) Then
     Begin
          AddStyleWarning(CurrentDocumentName + ': prepared PNG not found: ' + ColoredName);
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
          If Not UpdatingDefaults Then
          Begin
               Primitive.GraphicallyInvalidate;
               Inc(ImagesUpdated);
          End;
     Except
          Primitive.EmbedImage := False;
          Primitive.FileName := OriginalName;
          Primitive.EmbedImage := WasEmbedded;
          AddStyleWarning('Could not reload PNG: ' + OriginalName);
     End;
End;

{ Nonvisual records have no color. Their children are visited by the iterator. }
Function HasStyleColor(Primitive : ISch_BasicContainer) : Boolean;
Begin
     Result := (Primitive.ObjectId <> eSchComponent) And
               (Primitive.ObjectId <> eSheet) And
               (Primitive.ObjectId <> eSchLib) And
               (Primitive.ObjectId <> eTemplate) And
               (Primitive.ObjectId <> eMapDefiner) And
               (Primitive.ObjectId <> eImplementationMap) And
               (Primitive.ObjectId <> eImplementation) And
               (Primitive.ObjectId <> eImplementationsList) And
               (Primitive.ObjectId <> eParameterList);
     If (Primitive.ObjectId = eJunction) And
        (cbJunctionMode.ItemIndex = JunctionModeUnchanged) Then Result := False;
     If (Primitive.ObjectId = eImage) And
        (cbImageMode.ItemIndex = ImageModeUnchanged) Then Result := False;
End;

Function IsComponentRectangle(Primitive : ISch_BasicContainer) : Boolean;
Var
   ParentObject : ISch_BasicContainer;
Begin
     Result := False;
     If Primitive.ObjectId <> eRectangle Then Exit;
     ParentObject := Primitive.Container;
     If ParentObject = Nil Then Exit;
     Result := ParentObject.ObjectId = eSchComponent;
End;

Procedure ApplyPrimitiveStyle(Primitive : ISch_GraphicalObject);
Begin
     { Explicit blocks avoid nested Case/Else parsing in DelphiScript. }
     If Primitive.ObjectId = ePin Then
     Begin
          Primitive.Color := ShapePinText.Brush.Color;
          Primitive.Designator_CustomColor := ShapePinText.Brush.Color;
          Primitive.Name_CustomColor := ShapePinText.Brush.Color;
          Exit;
     End;
     If Primitive.ObjectId = eRectangle Then
     Begin
          Primitive.Color := ShapeBodyOutline.Brush.Color;
          If IsComponentRectangle(Primitive) Then
          Begin
               Primitive.AreaColor := ShapeBodyFill.Brush.Color;
               Primitive.IsSolid := cbEnableBodyFill.Checked;
               { Transparency is opt-in. Never use it to repair primitive order. }
               Primitive.Transparent := cbTransparentBodyFill.Checked;
          End;
          Exit;
     End;
     If (Primitive.ObjectId = eRoundRectangle) Or
        (Primitive.ObjectId = eEllipse) Or
		(Primitive.ObjectId = ePolygon) Or
		(Primitive.ObjectId = ePie) Then
     Begin
          Primitive.Color := ShapeBodyOutline.Brush.Color;
          Primitive.AreaColor := ShapeBodyFill.Brush.Color;
          { Body fill / Enable only applies to component Rectangle objects. }
          Exit;
     End;

     If (Primitive.ObjectId = ePolyline) Or
        (Primitive.ObjectId = eLine) Or
        (Primitive.ObjectId = eBezier) Or
        (Primitive.ObjectId = eEllipticalArc) Or
        (Primitive.ObjectId = eSymbol) Then
     Begin
          Primitive.Color := ShapeGraphics.Brush.Color;
          Exit;
     End;
     If Primitive.ObjectId = eArc Then
     Begin
          If Primitive.Radius = MilsToCoord(20) Then
          Begin
               Primitive.Color := ShapePinText.Brush.Color;
          End
          Else
          Begin
               Primitive.Color := ShapeGraphics.Brush.Color;
          End;
          Exit;
     End;
     If (Primitive.ObjectId = eDesignator) Or
        (Primitive.ObjectId = eParameter) Then
     Begin
          Primitive.Color := ShapeParameters.Brush.Color;
          Exit;
     End;
     If Primitive.ObjectId = eLabel Then
     Begin
          Primitive.Color := ShapePinText.Brush.Color;
          Exit;
     End;
     If Primitive.ObjectId = eImage Then
     Begin
          If cbImageMode.ItemIndex <> ImageModeUnchanged Then
          Begin
               UpdateSchematicImage(Primitive);
          End;
          Exit;
     End;
     If Primitive.ObjectId = eWire Then
     Begin
          Primitive.Color := ShapeWires.Brush.Color;
          Exit;
     End;
     If Primitive.ObjectId = eJunction Then
     Begin
          If cbJunctionMode.ItemIndex <> JunctionModeUnchanged Then
               Primitive.Color := ShapeWires.Brush.Color;
          Exit;
     End;
     If Primitive.ObjectId = ePort Then
     Begin
          Primitive.Color := ShapePortBorder.Brush.Color;
          Primitive.AreaColor := ShapePortFill.Brush.Color;
          Primitive.TextColor := ShapePortFont.Brush.Color;
          Exit;
     End;

     { Buses, net labels, power ports, sheet symbols/entries,
       harnesses, directives and remaining schematic graphics use Other. }
     Primitive.Color := ShapeOther.Brush.Color;
     Primitive.AreaColor := ShapeOther.Brush.Color;
     If (Primitive.ObjectId = eTextFrame) Or
        (Primitive.ObjectId = eNote) Or
        (Primitive.ObjectId = eSheetEntry) Or
        (Primitive.ObjectId = eHarnessEntry) Then
     Begin
          Primitive.TextColor := ShapeOther.Brush.Color;
     End;
End;

Function HasPotentialPinOcclusion(Component : ISch_Component) : Boolean;
Var
   ChildIterator : ISch_Iterator;
   Primitive     : ISch_GraphicalObject;
   SeenVisiblePin: Boolean;
Begin
     Result := False;
     SeenVisiblePin := False;
     ChildIterator := Component.SchIterator_Create;
     If ChildIterator = Nil Then Raise('Cannot inspect component primitive order.');
     Try
          ChildIterator.SetState_IterationDepth(eIterateFirstLevel);
          ChildIterator.AddFilter_CurrentPartPrimitives;
          ChildIterator.AddFilter_ObjectSet(MkSet(ePin, eRectangle));
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
               { Order-only check: no bounding records or pin list are needed.
                 A later opaque fill can cover an earlier pin label. }
               If SeenVisiblePin And IsComponentRectangle(Primitive) Then
                    If Primitive.IsSolid And (Not Primitive.Transparent) Then
                    Begin
                         Result := True;
                         Exit;
                    End;
               Primitive := ChildIterator.NextSchObject;
          End;
     Finally
          Component.SchIterator_Destroy(ChildIterator);
     End;
End;

Procedure WarnBodyPrimitiveOrder(SchDoc : ISch_Document);
Var
   ComponentIterator : ISch_Iterator;
   Component         : ISch_Component;
Begin
     If Not cbEnableBodyFill.Checked Then Exit;
     If cbTransparentBodyFill.Checked Then Exit;
     ComponentIterator := SchDoc.SchIterator_Create;
     If ComponentIterator = Nil Then
     Begin
          AddStyleWarning('Could not check component primitive order.');
          Exit;
     End;
     Try
          Try
               ComponentIterator.SetState_IterationDepth(eIterateAllLevels);
               ComponentIterator.AddFilter_ObjectSet(MkSet(eSchComponent));
               Component := ComponentIterator.FirstSchObject;
               While Component <> Nil Do
               Begin
                    If HasPotentialPinOcclusion(Component) Then
                    Begin
                         { AddStyleWarning deduplicates this message across all documents. }
                         AddStyleWarning('Some pin labels may be covered by rectangle fills. ' +
                              'Check primitive order in the components. Order left unchanged.');
                         Exit;
                    End;
                    Component := ComponentIterator.NextSchObject;
               End;
          Except
               AddStyleWarning('Could not check component primitive order.');
          End;
     Finally
          SchDoc.SchIterator_Destroy(ComponentIterator);
     End;
End;

Function ApplyGlobalJunctionColor : Boolean;
Begin
     Result := False;
     Try
          { This preference affects automatic wire junctions in ALL schematics. }
          SchServer.Preferences.WireAutoJunctionsColor := ShapeWires.Brush.Color;
          Result := SchServer.Preferences.WireAutoJunctionsColor = ShapeWires.Brush.Color;
          If Not Result Then
               AddStyleWarning('Global wire junction color was not accepted by Altium.');
     Except
          AddStyleWarning('Could not set global Wire Auto-Junctions Color in this Altium version.');
     End;
End;

{ Read the compiled wire connections before changing the sheet. Never infer
  junctions from arbitrary line crossings or retain live IConnection objects
  while registering new primitives: Altium can rebuild the connection array. }
Function CollectManualJunctionLocations(FilePath : String; JunctionLocations : TStringList) : Boolean;
Var
   Workspace       : IWorkspace;
   SourceDocument  : IDocument;
   Sheet           : ISch_Sheet;
   Connections     : IConnectionsArray;
   WireConnection  : IConnection;
   JunctionIterator: ISch_Iterator;
   ExistingJunction: ISch_Junction;
   OccupiedPoints  : TStringList;
   JunctionPoint   : TLocation;
   PointKey        : String;
   ConnectionNumber: Integer;
Begin
     Result := False;
     JunctionLocations.Clear;
     OccupiedPoints := TStringList.Create;
     Try
          OccupiedPoints.Sorted := True;
          Try
               Workspace := GetWorkspace;
               If Workspace = Nil Then
               Begin
                    AddStyleWarning(CurrentDocumentName + ': manual junctions skipped; workspace unavailable.');
                    Exit;
               End;
               SourceDocument := Workspace.DM_GetDocumentFromPath(FilePath);
               If SourceDocument = Nil Then
               Begin
                    AddStyleWarning(CurrentDocumentName + ': manual junctions skipped; open the sheet in Altium and retry.');
                    Exit;
               End;
               If Not SourceDocument.DM_Compile Then
               Begin
                    AddStyleWarning(CurrentDocumentName + ': manual junctions skipped; document compilation failed.');
                    Exit;
               End;
               Sheet := SchServer.GetSchDocumentByPath(FilePath);
               If Sheet = Nil Then Exit;
               Connections := Sheet.WireConnections;
               If Connections = Nil Then
               Begin
                    AddStyleWarning(CurrentDocumentName + ': manual junctions skipped; wire connection data unavailable.');
                    Exit;
               End;
               JunctionIterator := Sheet.SchIterator_Create;
               If JunctionIterator = Nil Then
               Begin
                    AddStyleWarning(CurrentDocumentName + ': manual junctions skipped; cannot check existing points.');
                    Exit;
               End;
               Try
                    JunctionIterator.AddFilter_ObjectSet(MkSet(eJunction));
                    ExistingJunction := JunctionIterator.FirstSchObject;
                    While ExistingJunction <> Nil Do
                    Begin
                         JunctionPoint := ExistingJunction.Location;
                         PointKey := IntToStr(JunctionPoint.X) + ',' + IntToStr(JunctionPoint.Y);
                         If OccupiedPoints.IndexOf(PointKey) < 0 Then OccupiedPoints.Add(PointKey);
                         ExistingJunction := JunctionIterator.NextSchObject;
                    End;
               Finally
                    Sheet.SchIterator_Destroy(JunctionIterator);
               End;
               For ConnectionNumber := 0 To Connections.ConnectionsCount - 1 Do
               Begin
                    WireConnection := Connections.Connection(ConnectionNumber);
                    If WireConnection = Nil Then Continue;
                    If WireConnection.IsManualJunction Then Continue;
                    { Match the renderer: fewer than three connections is not an auto-junction. }
                    If WireConnection.ObjectsCount < 3 Then Continue;
                    JunctionPoint := WireConnection.Location;
                    PointKey := IntToStr(JunctionPoint.X) + ',' + IntToStr(JunctionPoint.Y);
                    If OccupiedPoints.IndexOf(PointKey) >= 0 Then Continue;
                    JunctionLocations.Add(PointKey);
                    OccupiedPoints.Add(PointKey);
               End;
               Result := True;
          Except
               JunctionLocations.Clear;
               AddStyleWarning(CurrentDocumentName + ': manual junctions skipped; could not read compiled wire connections.');
          End;
     Finally
          OccupiedPoints.Free;
     End;
End;

Procedure CreateManualWireJunctions(SchDoc : ISch_Document; JunctionLocations : TStringList);
Var
   Junction        : ISch_Junction;
   JunctionNumber  : Integer;
   SeparatorPos    : Integer;
   PointKey        : String;
   PointX          : Integer;
   PointY          : Integer;
   Registered      : Boolean;
Begin
     For JunctionNumber := 0 To JunctionLocations.Count - 1 Do
     Begin
          PointKey := JunctionLocations.Strings[JunctionNumber];
          SeparatorPos := Pos(',', PointKey);
          PointX := StrToInt(Copy(PointKey, 1, SeparatorPos - 1));
          PointY := StrToInt(Copy(PointKey, SeparatorPos + 1, Length(PointKey)));
          Junction := SchServer.SchObjectFactory(eJunction, eCreate_Default);
          If Junction = Nil Then
          Begin
               AddStyleWarning(CurrentDocumentName + ': could not create manual junction at ' + PointKey);
               Continue;
          End;
          Registered := False;
          Try
               Junction.Location := Point(PointX, PointY);
               Junction.Color := ShapeWires.Brush.Color;
               Junction.Size := SchServer.Preferences.WireAutoJunctionsSize;
               { Locked junctions remain explicit objects when Altium cleans up
                 automatic junction records. Do not change existing junction locks. }
               Junction.Locked := True;
               SchDoc.RegisterSchObjectInContainer(Junction);
               Registered := True;
               Inc(ManualJunctionsCreated);
               SchServer.RobotManager.SendMessage(SchDoc.I_ObjectAddress,
                    c_BroadCast, SCHM_PrimitiveRegistration, Junction.I_ObjectAddress);
          Finally
               If Not Registered Then SchServer.DestroySchObject(Junction);
          End;
     End;
End;

Procedure UpdateThemeLabel(SchDoc : ISch_Document);
Var
   LabelIterator : ISch_Iterator;
   ExistingLabel : ISch_Label;
   ThemeLabel    : ISch_Label;
   LabelPosition : TLocation;
   ThemeFont     : TFontID;
   IsNew         : Boolean;
   Registered    : Boolean;
Begin
     Try
          ThemeLabel := Nil;
          LabelIterator := SchDoc.SchIterator_Create;
          If LabelIterator = Nil Then
          Begin
               AddStyleWarning(CurrentDocumentName + ': cannot inspect the theme label.');
               Exit;
          End;
          Try
               { Only sheet text at the dedicated anchor belongs to this feature. }
               LabelIterator.SetState_IterationDepth(eIterateFirstLevel);
               LabelIterator.AddFilter_ObjectSet(MkSet(eLabel));
               ExistingLabel := LabelIterator.FirstSchObject;
               While ExistingLabel <> Nil Do
               Begin
                    If Copy(ExistingLabel.Text, 1, 7) = 'Theme: ' Then
                    Begin
                         LabelPosition := ExistingLabel.Location;
                         If (LabelPosition.X = MilsToCoord(250)) And
                            (LabelPosition.Y = MilsToCoord(250)) Then
                         Begin
                              ThemeLabel := ExistingLabel;
                              Break;
                         End;
                    End;
                    ExistingLabel := LabelIterator.NextSchObject;
               End;
          Finally
               SchDoc.SchIterator_Destroy(LabelIterator);
          End;
          ThemeFont := SchServer.FontManager.GetFontID(14, 0, False, False,
                                                       False, False, 'Times New Roman');
          IsNew := ThemeLabel = Nil;
          If IsNew Then ThemeLabel := SchServer.SchObjectFactory(eLabel, eCreate_Default);
          If ThemeLabel = Nil Then
          Begin
               AddStyleWarning(CurrentDocumentName + ': cannot create the theme label.');
               Exit;
          End;
          Registered := Not IsNew;
          Try
               If Not IsNew Then
                    SchServer.RobotManager.SendMessage(ThemeLabel.I_ObjectAddress,
                         c_BroadCast, SCHM_BeginModify, c_NoEventData);
               Try
                    ThemeLabel.Location := Point(MilsToCoord(250), MilsToCoord(250));
                    ThemeLabel.Text := 'Theme: ' + AppliedThemeName;
                    ThemeLabel.FontID := ThemeFont;
                    ThemeLabel.Justification := eJustify_BottomLeft;
                    ThemeLabel.Orientation := eRotate0;
                    ThemeLabel.IsMirrored := False;
                    ThemeLabel.Color := ShapePinText.Brush.Color;
               Finally
                    If Not IsNew Then
                         SchServer.RobotManager.SendMessage(ThemeLabel.I_ObjectAddress,
                              c_BroadCast, SCHM_EndModify, c_NoEventData);
               End;
               If IsNew Then
               Begin
                    SchDoc.RegisterSchObjectInContainer(ThemeLabel);
                    Registered := True;
                    SchServer.RobotManager.SendMessage(SchDoc.I_ObjectAddress,
                         c_BroadCast, SCHM_PrimitiveRegistration, ThemeLabel.I_ObjectAddress);
               End;
          Finally
               If Not Registered Then SchServer.DestroySchObject(ThemeLabel);
          End;
     Except
          AddStyleWarning(CurrentDocumentName + ': could not create or update the theme label.');
     End;
End;

Procedure StyleSchematic(SchDoc : ISch_Document; JunctionLocations : TStringList);
Var
   PrimitiveIterator : ISch_Iterator;
   Primitive         : ISch_GraphicalObject;
Begin
     SchServer.ProcessControl.PreProcess(SchDoc, '');
     Try
          { Sheet Color is the document's inherited area color. }
          SchServer.RobotManager.SendMessage(SchDoc.I_ObjectAddress,
               c_BroadCast, SCHM_BeginModify, c_NoEventData);
          Try
               Try
                    SchDoc.AreaColor := ShapeSheetColor.Brush.Color;
                    SchDoc.UpdateDocumentProperties;
               Except
                    AddStyleWarning(CurrentDocumentName + ': could not set Sheet Color.');
               End;
          Finally
               SchServer.RobotManager.SendMessage(SchDoc.I_ObjectAddress,
                    c_BroadCast, SCHM_EndModify, c_NoEventData);
          End;
          PrimitiveIterator := SchDoc.SchIterator_Create;
          If PrimitiveIterator <> Nil Then
          Begin
               Try
                    { Includes graphics inside placed symbols, sheet entries and parameters. }
                    PrimitiveIterator.SetState_IterationDepth(eIterateAllLevels);
                    Primitive := PrimitiveIterator.FirstSchObject;
                    While Primitive <> Nil Do
                    Begin
                         If HasStyleColor(Primitive) Then
                         Begin
                              SchServer.RobotManager.SendMessage(Primitive.I_ObjectAddress,
                                   c_BroadCast, SCHM_BeginModify, c_NoEventData);
                              Try
                                   Try
                                        ApplyPrimitiveStyle(Primitive);
                                   Except
                                        AddStyleWarning(CurrentDocumentName +
                                             ': could not style object type ' + IntToStr(Primitive.ObjectId));
                                   End;
                              Finally
                                   SchServer.RobotManager.SendMessage(Primitive.I_ObjectAddress,
                                        c_BroadCast, SCHM_EndModify, c_NoEventData);
                              End;
                         End;
                         Primitive := PrimitiveIterator.NextSchObject;
                    End;
               Finally
                    SchDoc.SchIterator_Destroy(PrimitiveIterator);
               End;
          End;
          { The primitive iterator is destroyed before adding any new objects. }
          If cbJunctionMode.ItemIndex = JunctionModeManual Then
               CreateManualWireJunctions(SchDoc, JunctionLocations);
          UpdateThemeLabel(SchDoc);
     Finally
          SchServer.ProcessControl.PostProcess(SchDoc, '');
     End;
     SchDoc.GraphicallyInvalidate;
     WarnBodyPrimitiveOrder(SchDoc);
End;

Function ProcessSchematic(FilePath : String) : Boolean;
Var
   Document  : IServerDocument;
   SchDoc    : ISch_Document;
   WasOpen   : Boolean;
   JunctionLocations : TStringList;
Begin
     Result := False;
     CurrentDocumentName := ExtractFileName(FilePath);
     Document := Client.GetDocumentByPath(FilePath);
     WasOpen := Document <> Nil;
     If WasOpen Then
        If Document.Modified Then
        Begin
             AddStyleWarning(CurrentDocumentName + ': skipped; save existing unsaved edits first.');
             Exit;
        End;
     If Document = Nil Then Document := Client.OpenDocument('SCH', FilePath);
     If Document = Nil Then
     Begin
          AddStyleWarning(CurrentDocumentName + ': could not open schematic.');
          Exit;
     End;
     JunctionLocations := TStringList.Create;
     Try
          If cbJunctionMode.ItemIndex = JunctionModeManual Then
               If Not CollectManualJunctionLocations(FilePath, JunctionLocations) Then
                    JunctionLocations.Clear;
          SchDoc := SchServer.GetSchDocumentByPath(FilePath);
          If SchDoc = Nil Then
          Begin
               AddStyleWarning(CurrentDocumentName + ': schematic document unavailable.');
               Exit;
          End;
          If SchDoc.ObjectId <> eSheet Then
          Begin
               AddStyleWarning(CurrentDocumentName + ': not a schematic sheet.');
               Exit;
          End;
          StyleSchematic(SchDoc, JunctionLocations);
          Document.Modified := True;
          Result := Document.DoFileSave('Advanced Schematic binary');
          If Not Result Then
             AddStyleWarning(CurrentDocumentName + ': save failed; document left open.');
     Finally
          JunctionLocations.Free;
          { Keep pre-existing tabs and any unsaved results open. }
          If Not WasOpen Then
             If Not Document.Modified Then Client.CloseDocument(Document);
     End;
End;

procedure TSchematicStyleChangerForm.XPFolderChange(Sender: TObject);
Var
    I                : Integer;
    SchDocFiles      : TWideStringList;
    Path             : WideString;
    Check            : WideString;
Begin
     Check := XPFolderEdit.Text;
     If Check = '' Then
     Begin
          CheckListBoxSchematics.Items.Clear;
          Exit;
     End;
     If Not(Check[Length(Check)] = '\') Then
        XPFolderEdit.Text := XPFolderEdit.Text + '\';
     Path := XPFolderEdit.Text;
     If CheckListBoxSchematics.Items.Count > 0 Then
             For I := 0 to CheckListBoxSchematics.Items.Count - 1 Do
                 CheckListBoxSchematics.Items.Delete(CheckListBoxSchematics.Items.Count - 1);
     Try
         SchDocFiles := TStringList.Create;
         FindFiles(Path,'*.SchDoc',faAnyFile,False, SchDocFiles);

         If SchDocFiles.Count > 0 Then
             For I := 0 to SchDocFiles.Count - 1 Do
                 CheckListBoxSchematics.Items.Add(ExtractFileName(SchDocFiles.Strings[I]))
         Else
              Exit;
     Finally
         SchDocFiles.Free;
     End;
     For I := 0 to CheckListBoxSchematics.Items.Count - 1 Do
        CheckListBoxSchematics.Checked[I] := True;
End;

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
               ShapeWires.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 6]);
               ShapePortBorder.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 7]);
               ShapePortFill.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 8]);
               ShapePortFont.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 9]);
               ShapeOther.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 10]);
               ShapeSheetColor.Brush.Color := StrToInt(PresetColors.Strings[ColorOffset + 11]);
               AppliedThemeName := cbPresets.Text;
               LProcessingState.Caption := 'Preset applied: ' + cbPresets.Text;
          End;
          Result := True;
     Finally
          PresetColors.Free;
          PresetNames.Free;
     End;
End;

Procedure TSchematicStyleChangerForm.cbPresetsDropDown(Sender : TObject);
Begin
     If Not ReloadStylePresets(False) Then Exit;
End;

Procedure TSchematicStyleChangerForm.bApplyPresetClick(Sender : TObject);
Begin
     If Not ReloadStylePresets(True) Then Exit;
End;

Function ChooseStyleColor(CurrentColor : TColor) : TColor;
Begin
     Result := CurrentColor;
     StyleColorDialog.Color := CurrentColor;
     If StyleColorDialog.Execute Then
     Begin
          Result := StyleColorDialog.Color;
          If Result <> CurrentColor Then AppliedThemeName := 'Custom';
     End;
End;

Procedure TSchematicStyleChangerForm.bBodyOutlineColorClick(Sender : TObject);
Begin
     ShapeBodyOutline.Brush.Color := ChooseStyleColor(ShapeBodyOutline.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bBodyFillColorClick(Sender : TObject);
Begin
     ShapeBodyFill.Brush.Color := ChooseStyleColor(ShapeBodyFill.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bGraphicsColorClick(Sender : TObject);
Begin
     ShapeGraphics.Brush.Color := ChooseStyleColor(ShapeGraphics.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bParametersColorClick(Sender : TObject);
Begin
     ShapeParameters.Brush.Color := ChooseStyleColor(ShapeParameters.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bPinTextColorClick(Sender : TObject);
Begin
     ShapePinText.Brush.Color := ChooseStyleColor(ShapePinText.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bImagesColorClick(Sender : TObject);
Begin
     ShapeImages.Brush.Color := ChooseStyleColor(ShapeImages.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bWiresColorClick(Sender : TObject);
Begin
     ShapeWires.Brush.Color := ChooseStyleColor(ShapeWires.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bPortBorderColorClick(Sender : TObject);
Begin
     ShapePortBorder.Brush.Color := ChooseStyleColor(ShapePortBorder.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bPortFillColorClick(Sender : TObject);
Begin
     ShapePortFill.Brush.Color := ChooseStyleColor(ShapePortFill.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bPortFontColorClick(Sender : TObject);
Begin
     ShapePortFont.Brush.Color := ChooseStyleColor(ShapePortFont.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bOtherColorClick(Sender : TObject);
Begin
     ShapeOther.Brush.Color := ChooseStyleColor(ShapeOther.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bSheetColorClick(Sender : TObject);
Begin
     ShapeSheetColor.Brush.Color := ChooseStyleColor(ShapeSheetColor.Brush.Color);
End;

Procedure TSchematicStyleChangerForm.bAllColorsClick(Sender : TObject);
Begin
     StyleColorDialog.Color := ShapeBodyOutline.Brush.Color;
     If Not StyleColorDialog.Execute Then Exit;
     AppliedThemeName := 'Custom';
     ShapeBodyOutline.Brush.Color := StyleColorDialog.Color;
     ShapeBodyFill.Brush.Color := StyleColorDialog.Color;
     ShapeGraphics.Brush.Color := StyleColorDialog.Color;
     ShapeParameters.Brush.Color := StyleColorDialog.Color;
     ShapePinText.Brush.Color := StyleColorDialog.Color;
     ShapeImages.Brush.Color := StyleColorDialog.Color;
     ShapeWires.Brush.Color := StyleColorDialog.Color;
     ShapePortBorder.Brush.Color := StyleColorDialog.Color;
     ShapePortFill.Brush.Color := StyleColorDialog.Color;
     ShapePortFont.Brush.Color := StyleColorDialog.Color;
     ShapeOther.Brush.Color := StyleColorDialog.Color;
     { Keep the sheet background independent of the common accent color. }
End;

{ The parametric object IDs below extend the installed Defaults exporter's list
  with Parameter Set (Rt_Schematic.TObjectId, NOT ASCII RECORD numbers). Nil copies
  are skipped just as Altium's own Defaults exporter skips unsupported objects.
  SchObjectFactoryBySettings copies current in-memory settings for a given unit;
  no saved AppData file or repository preset is used as the source. }
Procedure AddLiveDefaults(Snapshot : ISch_Document; UnitSystem : Integer);
Var
   DefaultKinds : TStringList;
   KindNumber   : Integer;
   ObjectKind   : Integer;
   DefaultCopy  : ISch_BasicContainer;
   AddedToSheet : Boolean;
   HaveWire     : Boolean;
   HaveParameterSet : Boolean;
Begin
     DefaultKinds := TStringList.Create;
     Try
          DefaultKinds.CommaText :=
               '8,21,20,7,15,9,36,11,16,22,5,24,35,26,12,37,17,18,38,48,39,' +
               '4,10,40,41,34,42,13,2,49,3,19,27,28,53,54,56,58,59,61,23,14,' +
               '82,81,83,84,85,86,87,88,89,92,93,94,98,100,106,109,110,111,112,113';
          HaveWire := False;
          HaveParameterSet := False;
          For KindNumber := 0 To DefaultKinds.Count - 1 Do
          Begin
               ObjectKind := StrToInt(DefaultKinds.Strings[KindNumber]);
               DefaultsStep := 'copying object type ' + IntToStr(ObjectKind);
               DefaultCopy := SchServer.SchObjectFactoryBySettings(ObjectKind, UnitSystem);
               If DefaultCopy = Nil Then Continue;
               AddedToSheet := False;
               Try
                    Snapshot.AddSchObject(DefaultCopy);
                    AddedToSheet := True;
                    If ObjectKind = eWire Then HaveWire := True;
                    If ObjectKind = eParameterSet Then HaveParameterSet := True;
               Finally
                    If Not AddedToSheet Then SchServer.DestroySchObject(DefaultCopy);
               End;
          End;
          If Not HaveWire Then
               Raise('Current Wire defaults could not be copied.');
          If Not HaveParameterSet Then
               Raise('Current Parameter Set defaults could not be copied.');
     Finally
          DefaultKinds.Free;
     End;
End;

{ Defaults use ASCII RECORD ids here, not the API ObjectId enum above. }
Function DefaultsFieldValue(LineText, FieldName : String) : String;
Var
   ValueStart : Integer;
   ValueEnd   : Integer;
Begin
     Result := '';
     ValueStart := Pos('|' + UpperCase(FieldName) + '=', UpperCase(LineText));
     If ValueStart = 0 Then Exit;
     ValueStart := ValueStart + Length(FieldName) + 2;
     ValueEnd := ValueStart;
     While ValueEnd <= Length(LineText) Do
     Begin
          If LineText[ValueEnd] = '|' Then Break;
          Inc(ValueEnd);
     End;
     Result := Copy(LineText, ValueStart, ValueEnd - ValueStart);
End;

Function IsDefaultsColorValue(FieldName, ValueText : String) : Boolean;
Var
   NameEnd    : Integer;
   FirstDigit : Integer;
   I          : Integer;
Begin
     Result := False;
     { Include COLOR, AREACOLOR, TEXTCOLOR, BORDERCOLOR, *_CUSTOMCOLOR,
       SECONDARYCOLOR etc.; never rewrite COLORNAME, USECOLOR or font flags. }
     If FieldName = 'USECOLOR' Then Exit;
     NameEnd := Length(FieldName);
     While NameEnd > 0 Do
     Begin
          If Pos(FieldName[NameEnd], '0123456789') = 0 Then Break;
          Dec(NameEnd);
     End;
     If NameEnd < 5 Then Exit;
     If Copy(FieldName, NameEnd - 4, 5) <> 'COLOR' Then Exit;
     If ValueText = '' Then Exit;
     FirstDigit := 1;
     If ValueText[1] = '-' Then FirstDigit := 2;
     If FirstDigit > Length(ValueText) Then Exit;
     For I := FirstDigit To Length(ValueText) Do
          If Pos(ValueText[I], '0123456789') = 0 Then Exit;
     Result := True;
End;

Function HasDedicatedDefaultsColor(RecordKind : Integer; FieldName : String;
                                   ComponentRectangle : Boolean) : Boolean;
Begin
     Result := False;
     If FieldName = 'COLOR' Then
     Begin
          { Pins, graphics, body outlines, labels, ports, wire and parameters
            were already styled through the native API. }
          Result := Pos(',' + IntToStr(RecordKind) + ',',
               ',2,3,4,5,6,7,8,9,10,11,12,13,14,18,27,29,34,41,') > 0;
          { Junction keeps the selected mode, including Leave unchanged. }
          Exit;
     End;
     If FieldName = 'AREACOLOR' Then
     Begin
          { Polygon, ellipse, pie, port and sheet fills. Round Rectangle's
            Defaults fill uses Other; its border keeps Body outline. }
          Result := Pos(',' + IntToStr(RecordKind) + ',', ',7,8,9,18,31,') > 0;
          If (RecordKind = 14) And ComponentRectangle Then Result := True;
          Exit;
     End;
     If (RecordKind = 18) And (FieldName = 'TEXTCOLOR') Then Result := True;
     If RecordKind = 2 Then
          If (FieldName = 'NAME_CUSTOMCOLOR') Or
             (FieldName = 'DESIGNATOR_CUSTOMCOLOR') Then Result := True;
End;

Procedure CompleteDefaultsColors(FileData : TStringList);
Var
   RecordKinds        : TStringList;
   LineText           : String;
   UpdatedLine        : String;
   RecordText         : String;
   OwnerText          : String;
   FieldText          : String;
   FieldName          : String;
   ValueText          : String;
   OtherColorText     : String;
   LineNumber         : Integer;
   RecordKind         : Integer;
   OwnerIndex         : Integer;
   FieldStart         : Integer;
   FieldEnd           : Integer;
   Separator          : Integer;
   ComponentRectangle : Boolean;
Begin
     OtherColorText := IntToStr(ShapeOther.Brush.Color);
     RecordKinds := TStringList.Create;
     Try
          For LineNumber := 0 To FileData.Count - 1 Do
          Begin
               LineText := FileData.Strings[LineNumber];
               If Pos('|RECORD=', UpperCase(LineText)) <> 1 Then Continue;
               RecordText := DefaultsFieldValue(LineText, 'RECORD');
               RecordKind := StrToInt(RecordText);
               ComponentRectangle := False;
               If RecordKind = 14 Then
               Begin
                    OwnerText := DefaultsFieldValue(LineText, 'OWNERINDEX');
                    If OwnerText <> '' Then
                    Begin
                         OwnerIndex := StrToInt(OwnerText);
                         If (OwnerIndex >= 0) And (OwnerIndex < RecordKinds.Count) Then
                              ComponentRectangle := RecordKinds.Strings[OwnerIndex] = '1';
                    End;
               End;
               { The sheet (RECORD=31) is record index zero; the HEADER is not. }
               RecordKinds.Add(RecordText);
               UpdatedLine := '';
               FieldStart := 1;
               While FieldStart <= Length(LineText) Do
               Begin
                    If LineText[FieldStart] = '|' Then
                    Begin
                         UpdatedLine := UpdatedLine + '|';
                         Inc(FieldStart);
                    End;
                    FieldEnd := FieldStart;
                    While FieldEnd <= Length(LineText) Do
                    Begin
                         If LineText[FieldEnd] = '|' Then Break;
                         Inc(FieldEnd);
                    End;
                    FieldText := Copy(LineText, FieldStart, FieldEnd - FieldStart);
                    Separator := Pos('=', FieldText);
                    If Separator > 0 Then
                    Begin
                         FieldName := UpperCase(Copy(FieldText, 1, Separator - 1));
                         ValueText := Copy(FieldText, Separator + 1, Length(FieldText));
                         If IsDefaultsColorValue(FieldName, ValueText) Then
                              If Not HasDedicatedDefaultsColor(RecordKind, FieldName, ComponentRectangle) Then
                                   FieldText := Copy(FieldText, 1, Separator) + OtherColorText;
                    End;
                    UpdatedLine := UpdatedLine + FieldText;
                    FieldStart := FieldEnd;
               End;
               { Some zero-valued colors are omitted by the serializer.
                 These containers or skipped objects have no dedicated role. }
               If (RecordKind = 1) Or (RecordKind = 30) Or (RecordKind = 43) Then
                    If DefaultsFieldValue(UpdatedLine, 'COLOR') = '' Then
                         UpdatedLine := UpdatedLine + '|COLOR=' + OtherColorText;
               If (RecordKind = 1) Or (RecordKind = 10) Or (RecordKind = 30) Or
                  ((RecordKind = 14) And (Not ComponentRectangle)) Then
                    If DefaultsFieldValue(UpdatedLine, 'AREACOLOR') = '' Then
                         UpdatedLine := UpdatedLine + '|AREACOLOR=' + OtherColorText;
               FileData.Strings[LineNumber] := UpdatedLine;
          End;
     Finally
          RecordKinds.Free;
     End;
End;

Procedure SaveLiveDefaults(FilePath : String; UnitSystem : Integer);
Var
   Snapshot          : ISch_Document;
   PrimitiveIterator : ISch_Iterator;
   Primitive         : ISch_GraphicalObject;
   FileData          : TStringList;
   LineNumber        : Integer;
   WireRecords       : Integer;
Begin
     DefaultsStep := 'creating the snapshot sheet';
     Snapshot := SchServer.SchObjectFactory(eSheet, eCreate_Default);
     If Snapshot = Nil Then Raise('Cannot create a temporary Defaults sheet.');
     Try
          AddLiveDefaults(Snapshot, UnitSystem);
          Snapshot.AreaColor := ShapeSheetColor.Brush.Color;
          PrimitiveIterator := Snapshot.SchIterator_Create;
          If PrimitiveIterator = Nil Then Raise('Cannot inspect the Defaults snapshot.');
          Try
               PrimitiveIterator.SetState_IterationDepth(eIterateAllLevels);
               Primitive := PrimitiveIterator.FirstSchObject;
               While Primitive <> Nil Do
               Begin
                    DefaultsStep := 'styling object type ' + IntToStr(Primitive.ObjectId);
                    If HasStyleColor(Primitive) Then ApplyPrimitiveStyle(Primitive);
                    Primitive := PrimitiveIterator.NextSchObject;
               End;
          Finally
               Snapshot.SchIterator_Destroy(PrimitiveIterator);
          End;
          WarnBodyPrimitiveOrder(Snapshot);
          { Detached copies need no edit notifications, compile or manual junctions.
            Altium serializes the complete objects, children and font table. }
          DefaultsStep := 'saving the ASCII file';
          SchServer.SaveSchDocument(Snapshot, FilePath, 'Advanced Schematic ascii');
          If Not FileExists(FilePath) Then Raise('Altium did not write the Defaults snapshot.');
          FileData := TStringList.Create;
          Try
               DefaultsStep := 'validating the saved ASCII file';
               FileData.LoadFromFile(FilePath);
               If FileData.Count < 2 Then Raise('The Defaults snapshot is empty.');
               If Pos('SCHEMATIC CAPTURE ASCII FILE', UpperCase(FileData.Strings[0])) = 0 Then
                    Raise('Altium did not save an ASCII Defaults file.');
               WireRecords := 0;
               For LineNumber := 1 To FileData.Count - 1 Do
                    If Pos('|RECORD=27|', UpperCase(FileData.Strings[LineNumber]) + '|') = 1 Then
                         Inc(WireRecords);
               If WireRecords <> 1 Then Raise('The Defaults snapshot must contain one Wire default.');
               { Cover serialized colors which the older script interfaces do
                 not expose, while retaining every explicitly assigned role. }
               DefaultsStep := 'applying Other to remaining Defaults colors';
               CompleteDefaultsColors(FileData);
               FileData.SaveToFile(FilePath);
          Finally
               FileData.Free;
          End;
     Finally
          SchServer.DestroySchObject(Snapshot);
     End;
End;

Function CreateDefaultsPair : Boolean;
Var
   BasePath      : String;
   UniqueSuffix  : String;
   AttemptNumber : Integer;
   TemporaryMil  : String;
   TemporaryMM   : String;
   PublishedMil  : Boolean;
   PublishedMM   : Boolean;
Begin
     Result := False;
     PublishedMil := False;
     PublishedMM := False;
     BasePath := IncludeTrailingPathDelimiter(XPFolderEdit.Text) + 'SchematicStyleDefaults-' +
          FormatDateTime('yyyymmdd-hhnnsszzz', Now);
     AttemptNumber := 0;
     UniqueSuffix := '';
     Repeat
          DefaultsImperialFile := BasePath + UniqueSuffix + '.dft';
          DefaultsMetricFile := BasePath + UniqueSuffix + '.MMsdft';
          TemporaryMil := BasePath + UniqueSuffix + '.pending.dft';
          TemporaryMM := BasePath + UniqueSuffix + '.pending.MMsdft';
          If Not FileExists(DefaultsImperialFile) And Not FileExists(DefaultsMetricFile) And
             Not FileExists(TemporaryMil) And Not FileExists(TemporaryMM) Then Break;
          Inc(AttemptNumber);
          UniqueSuffix := '-' + IntToStr(AttemptNumber);
     Until False;
     UpdatingDefaults := True;
     Try
          Try
               CurrentDocumentName := 'Defaults (mil)';
               LProcessingState.Caption := 'Copying current Defaults (mil)...';
               LProcessingState.Refresh;
               SaveLiveDefaults(TemporaryMil, eImperial);
               CurrentDocumentName := 'Defaults (mm)';
               LProcessingState.Caption := 'Copying current Defaults (mm)...';
               LProcessingState.Refresh;
               SaveLiveDefaults(TemporaryMM, eMetric);
               { Publish only after both unit snapshots have been generated. }
               DefaultsStep := 'publishing the two output files';
               If Not RenameFile(TemporaryMil, DefaultsImperialFile) Then
                    Raise('Cannot publish the imperial Defaults file.');
               PublishedMil := True;
               If Not RenameFile(TemporaryMM, DefaultsMetricFile) Then
                    Raise('Cannot publish the metric Defaults file.');
               PublishedMM := True;
               Result := True;
          Except
               AddStyleWarning(CurrentDocumentName + ': cannot export current Defaults while ' +
                    DefaultsStep + '. ' +
                    'SchObjectFactoryBySettings and SaveSchDocument must be available. ' +
                    'No saved-file fallback was used.');
          End;
     Finally
          UpdatingDefaults := False;
          If FileExists(TemporaryMil) Then DeleteFile(TemporaryMil);
          If FileExists(TemporaryMM) Then DeleteFile(TemporaryMM);
          If Not Result Then
          Begin
               If PublishedMil Then DeleteFile(DefaultsImperialFile);
               If PublishedMM Then DeleteFile(DefaultsMetricFile);
               DefaultsImperialFile := '';
               DefaultsMetricFile := '';
          End;
     End;
End;

Procedure TSchematicStyleChangerForm.bRunClick(Sender : TObject);
Var
   FileNumber     : Integer;
   CheckedCount   : Integer;
   AttemptedCount : Integer;
   SavedCount     : Integer;
   SummaryText    : String;
   GlobalJunctionColorApplied : Boolean;
Begin
     CheckedCount := 0;
     AttemptedCount := 0;
     SavedCount := 0;
     For FileNumber := 0 To CheckListBoxSchematics.Items.Count - 1 Do
         If CheckListBoxSchematics.Checked[FileNumber] Then Inc(CheckedCount);
     If CheckedCount = 0 Then
     Begin
          ShowMessage('Select at least one SchDoc file.');
          Exit;
     End;
     StyleWarnings := TStringList.Create;
     PreparedImageNames := TStringList.Create;
     PreparedImagePaths := TStringList.Create;
     ImagesFound := 0;
     ImagesUpdated := 0;
     ManualJunctionsCreated := 0;
     UpdatingDefaults := False;
     DefaultsImperialFile := '';
     DefaultsMetricFile := '';
     GlobalJunctionColorApplied := False;
     bRun.Enabled := False;
     bRun.Cursor := crHourGlass;
     Try
          If cbImageMode.ItemIndex <> ImageModeUnchanged Then
             If Not PrepareImages Then Exit;
          If cbCreateDefaults.Checked Then
               If Not CreateDefaultsPair Then
               Begin
                    ShowWarning('Defaults were not created; schematics were not changed.' +
                         #13#10 + StyleWarnings.Text);
                    Exit;
               End;
          If cbJunctionMode.ItemIndex = JunctionModeGlobal Then
               GlobalJunctionColorApplied := ApplyGlobalJunctionColor;
          For FileNumber := 0 To CheckListBoxSchematics.Items.Count - 1 Do
              If CheckListBoxSchematics.Checked[FileNumber] Then
              Begin
                   Inc(AttemptedCount);
                   CurrentDocumentName := CheckListBoxSchematics.Items.Strings[FileNumber];
                   LProcessingState.Caption := 'Processing ' + IntToStr(AttemptedCount) +
                        ' of ' + IntToStr(CheckedCount) + ': ' + CurrentDocumentName;
                   LProcessingState.Refresh;
                   Try
                        If ProcessSchematic(IncludeTrailingPathDelimiter(XPFolderEdit.Text) +
                             CurrentDocumentName) Then Inc(SavedCount);
                   Except
                        AddStyleWarning(CurrentDocumentName + ': processing failed; inspect the open document.');
                   End;
              End;
          SummaryText := 'Schematics saved: ' + IntToStr(SavedCount) +
                         ' of ' + IntToStr(CheckedCount) + '.';
          If cbImageMode.ItemIndex <> ImageModeUnchanged Then
             SummaryText := SummaryText + #13#10 + 'PNG images found: ' + IntToStr(ImagesFound) +
                            '; updated: ' + IntToStr(ImagesUpdated) + '.' + #13#10 +
                            'PNG copies: ' + ImageOutputFolder;
          If cbImageMode.ItemIndex = ImageModeOriginal Then
               SummaryText := SummaryText + #13#10 + 'PNG originals restored from: ' + ImageSourceFolder;
          If cbCreateDefaults.Checked Then
               SummaryText := SummaryText + #13#10 + 'Defaults created from current Altium settings:' +
                    #13#10 + DefaultsImperialFile + #13#10 + DefaultsMetricFile +
                    #13#10 + 'Load the DFT in Preferences > Schematic > Defaults; keep both files together.';
          If cbJunctionMode.ItemIndex = JunctionModeManual Then
             SummaryText := SummaryText + #13#10 + 'Manual wire junctions created: ' +
                            IntToStr(ManualJunctionsCreated) + '.';
          If cbJunctionMode.ItemIndex = JunctionModeGlobal Then
          Begin
               If GlobalJunctionColorApplied Then
                    SummaryText := SummaryText + #13#10 + 'Global wire junction color updated (all schematics).'
               Else
                    SummaryText := SummaryText + #13#10 + 'Global wire junction color NOT updated.';
          End;
          If cbJunctionMode.ItemIndex = JunctionModeUnchanged Then
               SummaryText := SummaryText + #13#10 + 'Junctions left unchanged.';
          LProcessingState.Caption := SummaryText;
          If StyleWarnings.Count = 0 Then
             ShowMessage('Done. ' + SummaryText)
          Else
             ShowWarning(SummaryText + #13#10 + 'Warnings:' + #13#10 + StyleWarnings.Text);
     Finally
          bRun.Cursor := crDefault;
          bRun.Enabled := True;
          PreparedImagePaths.Free;
          PreparedImageNames.Free;
          StyleWarnings.Free;
     End;
End;

Procedure TSchematicStyleChangerForm.bEnableAllClick(Sender : TObject);
Var
   FileNumber : Integer;
Begin
     For FileNumber := 0 To CheckListBoxSchematics.Items.Count - 1 Do
         CheckListBoxSchematics.Checked[FileNumber] := True;
End;

Procedure TSchematicStyleChangerForm.bClearAllClick(Sender : TObject);
Var
   FileNumber : Integer;
Begin
     For FileNumber := 0 To CheckListBoxSchematics.Items.Count - 1 Do
         CheckListBoxSchematics.Checked[FileNumber] := False;
End;

Procedure TSchematicStyleChangerForm.bCancelClick(Sender : TObject);
Begin
     Close;
End;

Procedure RunSchematicStyleChanger;
Var
   Workspace       : IWorkspace;
   WSPrefs         : IWorkspacePreferences;
   CurrentSheet    : ISch_Document;
   FocusedProject  : IProject;
   InitialFolder   : String;
Begin
     If SchServer = Nil Then
     Begin
          ShowWarning('Sch Server is not active.');
          Exit;
     End;
     Workspace := GetWorkspace;
     If Workspace = Nil Then Exit;
     WSPrefs := Workspace.DM_Preferences;
     OriginalImagesFolder.Text := IncludeTrailingPathDelimiter(WSPrefs.GetDefaultLibraryPath) + 'Images';
     OriginalImagesFolder.InitialDir := OriginalImagesFolder.Text;
     InitialFolder := ExtractFilePath(GetRunningScriptProjectName);
     FocusedProject := Workspace.DM_FocusedProject;
     If FocusedProject <> Nil Then
        InitialFolder := ExtractFilePath(FocusedProject.DM_ProjectFullPath);
     CurrentSheet := SchServer.GetCurrentSchDocument;
     If CurrentSheet <> Nil Then
        If CurrentSheet.ObjectId = eSheet Then
           InitialFolder := ExtractFilePath(CurrentSheet.DocumentName);
     XPFolderEdit.InitialDir := InitialFolder;
     XPFolderEdit.Text := InitialFolder;
     AppliedThemeName := 'Custom';
     If Not ReloadStylePresets(False) Then
        LProcessingState.Caption := 'Presets could not be loaded; manual colors are available.';
     SchematicStyleChangerForm.ShowModal;
End;

End.
