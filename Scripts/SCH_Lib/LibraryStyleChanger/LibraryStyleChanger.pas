{..............................................................................}
{      LibraryStyleChanger v.0.9                                               }
{   Changes a color style of selected SchLibs to Classic.                      }
{                                                                              }
{                                                                              }
{..............................................................................}

{..............................................................................}
                          {Procedures}
{..............................................................................}

Procedure IterateCompPrimitives(Component : ISch_Componen);
Var
   PrimitiveIterator : ISch_Iterator;
   Primitive         : ISch_GraphicalObject;
Begin
     Try
          PrimitiveIterator := Component.SchIterator_Create;
          Primitive := PrimitiveIterator.FirstSchObject;
          While Primitive <> Nil Do
          Begin
               Case Primitive.ObjectId of
                    ePin:
                    Begin
                         Primitive.SetState_Color := $000000;
                         Primitive.Designator_CustomColor := $000000;
                         Primitive.Name_CustomColor := $000000;
                    End;
                    eRectangle:
                    Begin
                         Primitive.SetState_Color := $000080;
                         Primitive.SetState_AreaColor := $B0FFFF;
                         Primitive.SetState_IsSolid := True;
                         Primitive.SetState_Transparent := True;
                    End;
                    ePolygon:
                    Begin
                         Primitive.SetState_Color := $FF0000;
                         Primitive.SetState_AreaColor := $FF0000;
                    End;
                    eDesignator:
                         Primitive.SetState_Color := $800000;
                    eParameter:
                         Primitive.SetState_Color := $800000;
                    ePolyline:
                         Primitive.SetState_Color := $FF0000;
                    eArc:
                         Primitive.SetState_Color := $FF0000;
                    22:   {Text}
                         Primitive.SetState_Color := $000000;
                    eImage:
                         Component.RemoveSchObject(Primitive);
               End;
               Primitive := PrimitiveIterator.NextSchObject;
          End;
     Finally
            Component.SchIterator_Destroy(PrimitiveIterator);
     End;
End;

Procedure IterateLibComps(I : Integer);
Var
   SchLib       : ISch_Lib;
   CompIterator : ISch_Iterator;
   Component    : ISch_Component;
Begin
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
               IterateCompPrimitives(Component);
               Component := CompIterator.NextSchObject;
          End;
     Finally
            SchLib.SchIterator_Destroy(CompIterator);
     End;
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

Procedure TLibraryStyleChangerForm.bRunClick(Sender: TObject);
Var
   Document       : IServerDocument;
   I              : Integer;
   CheckedCount   : Integer;
   CheckedCounter : Integer;
Begin
     bRun.Cursor := crHourGlass;
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
                   Document.DoFileSave('Advanced Schematic binary library');
              End;
              Client.CloseDocument(Document);
         End;
     Showmessage('Done');
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
     XPFolderEdit.InitialDir := WSPrefs.GetDefaultLibraryPath;
     XPFolderEdit.Text := XPFolderEdit.InitialDir;
     LibraryStyleChangerForm.ShowModal;
End;

End.


