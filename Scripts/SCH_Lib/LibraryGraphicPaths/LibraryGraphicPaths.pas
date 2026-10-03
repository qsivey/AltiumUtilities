{ LibraryGraphicPaths v1.0.2
  Store component Graphic paths as ..\Images\<filename>; embedding is optional. }

Var
   BackupFolder       : String;
   CurrentLibrary     : String;
   CurrentComponent   : String;
   CurrentStep        : String;
   SavedLibraries     : Integer;
   UnchangedLibraries : Integer;
   FailedLibraries    : Integer;
   UpdatedImages      : Integer;

Procedure LogFailure(MessageText : String);
Begin
     LogMemo.Lines.Add('  ERROR: ' + CurrentLibrary + ' / ' +
                      CurrentComponent + ': ' + MessageText);
End;

Function NormalizeImagePath(PathText : String) : String;
Var
   I : Integer;
Begin
     Result := PathText;
     For I := 1 To Length(Result) Do
          If Result[I] = '/' Then Result[I] := '\';
End;

Function ResolveCurrentImageSource(LibraryPath, OldPath : String) : String;
Begin
     { Embedding uses the image Altium loaded from its current link. Do not
       substitute another file or reload pixels while changing metadata. }
     If ExtractFileDrive(OldPath) <> '' Then
          Result := OldPath
     Else
          Result := ExpandFileName(ExtractFilePath(LibraryPath) + OldPath);
     If Not FileExists(Result) Then Result := '';
End;

Function ProcessGraphic(Graphic : ISch_Image; LibraryPath : String;
                        ApplyChanges : Boolean;
                        Var ImageCount, ChangeCount : Integer) : Boolean;
Var
   OldPath       : String;
   FileNameOnly  : String;
   RelativePath  : String;
   SourcePath    : String;
   WasEmbedded   : Boolean;
   WantEmbedded  : Boolean;
Begin
     Result := False;
     CurrentStep := 'reading Graphic file name';
     OldPath := NormalizeImagePath(Graphic.FileName);
     FileNameOnly := ExtractFileName(OldPath);
     If Not ApplyChanges Then Inc(ImageCount);
     If (FileNameOnly = '') Or (FileNameOnly = '.') Or (FileNameOnly = '..') Then
     Begin
          LogFailure('Graphic has no usable file name. Library skipped.');
          Exit;
     End;
     RelativePath := '..\Images\' + FileNameOnly;
     CurrentStep := 'reading Embedded for Graphic ' + OldPath;
     WasEmbedded := Graphic.EmbedImage;
     WantEmbedded := cbEmbedded.Checked;
     SourcePath := '';
     If Not WantEmbedded Then
     Begin
          { Linked images must exist at the destination, not just the old path. }
          SourcePath := ExpandFileName(ExtractFilePath(LibraryPath) + RelativePath);
          If Not FileExists(SourcePath) Then
          Begin
               LogFailure('Cannot use Graphic without Embedded: target not found: ' + SourcePath);
               Exit;
          End;
     End;
     If (WasEmbedded = WantEmbedded) And (Graphic.FileName = RelativePath) Then
     Begin
          Result := True;
          Exit;
     End;
     If WantEmbedded And (Not WasEmbedded) Then
     Begin
          SourcePath := ResolveCurrentImageSource(LibraryPath, OldPath);
          If SourcePath = '' Then
          Begin
               LogFailure('Cannot embed Graphic: current source not found: ' + OldPath +
                          '. Run with Embedded unchecked first, then reopen the library before embedding.');
               Exit;
          End;
     End;
     If Not ApplyChanges Then
     Begin
          Inc(ChangeCount);
          Result := True;
          Exit;
     End;
     { SetState_FileName does not load external pixels when EmbedImage is true.
       Keep the existing image and frame; change only FileName and EmbedImage.
       Altium loads external pixels when the linked library is reopened. }
     CurrentStep := 'temporarily enabling Embedded for Graphic ' + OldPath;
     Graphic.EmbedImage := True;
     { Altium compares names without case; clear the name while embedded
       so paths such as ..\images\ also acquire the requested spelling. }
     CurrentStep := 'clearing embedded Graphic path ' + OldPath;
     Graphic.FileName := '';
     CurrentStep := 'setting Graphic path to ' + RelativePath;
     Graphic.FileName := RelativePath;
     CurrentStep := 'setting chosen Embedded mode for Graphic ' + RelativePath;
     Graphic.EmbedImage := WantEmbedded;
     CurrentStep := 'checking Graphic settings for ' + RelativePath;
     If (Graphic.EmbedImage <> WantEmbedded) Or (Graphic.FileName <> RelativePath) Then
     Begin
          LogFailure('Altium did not retain the requested Graphic settings.');
          Exit;
     End;
     Result := True;
End;

Function ProcessContainer(Container : ISch_BasicContainer; LibraryPath : String;
                          ApplyChanges : Boolean;
                          Var ImageCount, ChangeCount : Integer) : Boolean;
Var
   Iterator  : ISch_Iterator;
   Primitive : ISch_GraphicalObject;
Begin
     Result := False;
     CurrentStep := 'iterating Graphics';
     Iterator := Container.SchIterator_Create;
     If Iterator = Nil Then
     Begin
          LogFailure('Cannot create image iterator.');
          Exit;
     End;
     Try
          Iterator.SetState_IterationDepth(eIterateFirstLevel);
          Iterator.AddFilter_ObjectSet(MkSet(eImage));
          Primitive := Iterator.FirstSchObject;
          While Primitive <> Nil Do
          Begin
               If Not ProcessGraphic(Primitive, LibraryPath, ApplyChanges,
                                     ImageCount, ChangeCount) Then Exit;
               Primitive := Iterator.NextSchObject;
          End;
          Result := True;
     Finally
          Container.SchIterator_Destroy(Iterator);
     End;
End;

Function ProcessComponents(SchLib : ISch_Lib; LibraryPath : String;
                           ApplyChanges : Boolean;
                           Var ImageCount, ChangeCount : Integer) : Boolean;
Var
   Iterator  : ISch_Iterator;
   Component : ISch_Component;
Begin
     Result := False;
     CurrentStep := 'iterating components';
     Iterator := SchLib.SchLibIterator_Create;
     If Iterator = Nil Then
     Begin
          LogFailure('Cannot create component iterator.');
          Exit;
     End;
     Try
          Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));
          Component := Iterator.FirstSchObject;
          While Component <> Nil Do
          Begin
               CurrentComponent := Component.LibReference;
               If Not ProcessContainer(Component, LibraryPath, ApplyChanges,
                                       ImageCount, ChangeCount) Then Exit;
               Component := Iterator.NextSchObject;
          End;
     Finally
          SchLib.SchIterator_Destroy(Iterator);
     End;
     { Active-part primitives live at editor level, not inside the component.
       First-level iteration avoids processing the other components twice. }
     Component := SchLib.CurrentSchComponent;
     If Component <> Nil Then
     Begin
          CurrentComponent := Component.LibReference;
          If Not ProcessContainer(SchLib, LibraryPath, ApplyChanges,
                                  ImageCount, ChangeCount) Then Exit;
     End;
     Result := True;
End;

Function ProcessLibrary(LibraryPath : String) : Boolean;
Var
   Document    : IServerDocument;
   SchLib      : ISch_Lib;
   WasOpen     : Boolean;
   ImageCount  : Integer;
   ChangeCount : Integer;
   BackupPath  : String;
Begin
     Result := False;
     CurrentLibrary := ExtractFileName(LibraryPath);
     CurrentComponent := '(library)';
     CurrentStep := 'opening library';
     Document := Client.GetDocumentByPath(LibraryPath);
     WasOpen := Document <> Nil;
     If WasOpen Then
          If Document.Modified Then
          Begin
               LogFailure('Unsaved edits: save or close this library before running.');
               Exit;
          End;
     If Document = Nil Then Document := Client.OpenDocument('SCHLIB', LibraryPath);
     If Document = Nil Then
     Begin
          LogFailure('Cannot open library.');
          Exit;
     End;
     Try
          Try
               SchLib := SchServer.GetSchDocumentByPath(LibraryPath);
               If SchLib = Nil Then
               Begin
                    LogFailure('Schematic library is unavailable.');
                    Exit;
               End;
               ImageCount := 0;
               ChangeCount := 0;
               { Complete a read-only pass before backing up or changing anything. }
               If Not ProcessComponents(SchLib, LibraryPath, False,
                                        ImageCount, ChangeCount) Then Exit;
               CurrentComponent := '(library)';
               If ChangeCount = 0 Then
               Begin
                    Inc(UnchangedLibraries);
                    LogMemo.Lines.Add(CurrentLibrary + ': unchanged; Graphics found: ' +
                                     IntToStr(ImageCount) + '.');
                    Result := True;
                    Exit;
               End;
               CurrentStep := 'creating backup';
               If Not ForceDirectories(BackupFolder) Then
               Begin
                    LogFailure('Cannot create backup folder: ' + BackupFolder);
                    Exit;
               End;
               BackupPath := IncludeTrailingPathDelimiter(BackupFolder) + CurrentLibrary;
               If Not CopyFile(LibraryPath, BackupPath, True) Then
               Begin
                    LogFailure('Cannot create backup: ' + BackupPath);
                    Exit;
               End;
               { Mark dirty before mutation so failure cannot silently close the tab. }
               Document.Modified := True;
               If Not ProcessComponents(SchLib, LibraryPath, True,
                                        ImageCount, ChangeCount) Then
               Begin
                    LogMemo.Lines.Add('  NOT SAVED. Reload this library from disk before retrying.');
                    Exit;
               End;
               SchLib.GraphicallyInvalidate;
               CurrentComponent := '(library)';
               CurrentStep := 'saving library';
               If Not Document.DoFileSave('Advanced Schematic binary library') Then
               Begin
                    Document.Modified := True;
                    LogFailure('Save failed; library left open. Backup: ' + BackupPath);
                    Exit;
               End;
               Inc(SavedLibraries);
               UpdatedImages := UpdatedImages + ChangeCount;
               LogMemo.Lines.Add(CurrentLibrary + ': saved; Graphics updated: ' +
                                IntToStr(ChangeCount) + ' of ' + IntToStr(ImageCount) + '.');
               Result := True;
          Except
               LogFailure('Altium error while ' + CurrentStep + '.');
               If Document.Modified Then
                    LogMemo.Lines.Add('  NOT SAVED. Reload this library from disk before retrying.');
          End;
     Finally
          If Not WasOpen Then
               If Not Document.Modified Then Client.CloseDocument(Document);
     End;
End;

Procedure TLibraryGraphicPathsForm.bRunClick(Sender : TObject);
Var
   LibraryFiles : TStringList;
   FolderPath   : String;
   BackupBase   : String;
   I            : Integer;
   Suffix       : Integer;
Begin
     FolderPath := IncludeTrailingPathDelimiter(Trim(LibraryFolder.Text));
     If Not DirectoryExists(FolderPath) Then
     Begin
          ShowWarning('Library folder not found: ' + FolderPath);
          Exit;
     End;
     LibraryFiles := TStringList.Create;
     Try
          FindFiles(FolderPath, '*.SchLib', faAnyFile, False, LibraryFiles);
          If LibraryFiles.Count = 0 Then
          Begin
               ShowWarning('No SchLib files in ' + FolderPath);
               Exit;
          End;
          LibraryFiles.Sort;
          LogMemo.Clear;
          LogMemo.Lines.Add('Folder: ' + FolderPath);
          If cbEmbedded.Checked Then
               LogMemo.Lines.Add('Target: ..\Images\<filename>; Embedded = True')
          Else
               LogMemo.Lines.Add('Target: ..\Images\<filename>; Embedded = False');
          SavedLibraries := 0;
          UnchangedLibraries := 0;
          FailedLibraries := 0;
          UpdatedImages := 0;
          BackupBase := FolderPath + '_GraphicPathsBackup\' +
                        FormatDateTime('yyyymmdd-hhnnsszzz', Now);
          BackupFolder := BackupBase;
          Suffix := 0;
          While DirectoryExists(BackupFolder) Do
          Begin
               Inc(Suffix);
               BackupFolder := BackupBase + '-' + IntToStr(Suffix);
          End;
          bRun.Enabled := False;
          bClose.Enabled := False;
          LibraryFolder.Enabled := False;
          cbEmbedded.Enabled := False;
          LibraryGraphicPathsForm.Cursor := crHourGlass;
          Try
               For I := 0 To LibraryFiles.Count - 1 Do
               Begin
                    LStatus.Caption := 'Processing ' + IntToStr(I + 1) + ' of ' +
                                       IntToStr(LibraryFiles.Count) + '...';
                    LStatus.Refresh;
                    Try
                         If Not ProcessLibrary(FolderPath +
                              ExtractFileName(LibraryFiles.Strings[I])) Then Inc(FailedLibraries);
                    Except
                         Inc(FailedLibraries);
                         LogFailure('Altium error while ' + CurrentStep + '.');
                    End;
                    LogMemo.Refresh;
               End;
               LStatus.Caption := 'Finished. Saved: ' + IntToStr(SavedLibraries) +
                    '; unchanged: ' + IntToStr(UnchangedLibraries) +
                    '; failed/skipped: ' + IntToStr(FailedLibraries) + '.';
               LogMemo.Lines.Add('');
               LogMemo.Lines.Add(LStatus.Caption);
               LogMemo.Lines.Add('Graphics updated in saved libraries: ' + IntToStr(UpdatedImages));
               If DirectoryExists(BackupFolder) Then
               Begin
                    LogMemo.Lines.Add('Backups: ' + BackupFolder);
                    Try
                         LogMemo.Lines.SaveToFile(IncludeTrailingPathDelimiter(BackupFolder) + 'Report.txt');
                    Except
                         LogMemo.Lines.Add('Could not save Report.txt; copy the log from this window.');
                    End;
               End;
          Finally
               LibraryGraphicPathsForm.Cursor := crDefault;
               LibraryFolder.Enabled := True;
               cbEmbedded.Enabled := True;
               bClose.Enabled := True;
               bRun.Enabled := True;
          End;
     Finally
          LibraryFiles.Free;
     End;
End;

Procedure TLibraryGraphicPathsForm.bCloseClick(Sender : TObject);
Begin
     Close;
End;

Procedure RunLibraryGraphicPaths;
Var
   Workspace : IWorkspace;
   WSPrefs   : IWorkspacePreferences;
Begin
     If SchServer = Nil Then
     Begin
          ShowWarning('Sch Server is not active.');
          Exit;
     End;
     Workspace := GetWorkspace;
     If Workspace = Nil Then Exit;
     WSPrefs := Workspace.DM_Preferences;
     LibraryFolder.InitialDir := IncludeTrailingPathDelimiter(WSPrefs.GetDefaultLibraryPath) +
                                 'CustomStyleSymbols';
     LibraryFolder.Text := LibraryFolder.InitialDir;
     LibraryGraphicPathsForm.ShowModal;
End;

End.
