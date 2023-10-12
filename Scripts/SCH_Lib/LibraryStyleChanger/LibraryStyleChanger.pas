{..............................................................................}
{      LibraryStyleChanger v.0.7.3                                               }
{                                                                              }
{                                                                              }
{                                                                              }
{..............................................................................}

{..............................................................................}

Procedure IterateLibPrimitives(I : Integer);
Var
   SchLib          : ISch_Lib;
   LibIterator     : ISch_Iterator;
   Primitive       : ISch_GraphicalObject;
Begin
     SchLib := SchServer.GetSchDocumentByPath(XPFolderEdit.Text + CheckListBoxSchLibraries.Items.Strings[I]);
     If SchLib = Nil Then
     Begin
          ShowWarning( CheckListBoxSchLibraries.Items.Strings[I] + ' is not Sch Library.');
          Exit;
     End;

     LibIterator := SchLib.SchLibIterator_Create;                               {Rectangle}
     LibIterator.AddFilter_ObjectSet(MkSet(eRectangle));
     Primitive := LibIterator.FirstSchObject;
     While Primitive <> Nil Do
     Begin
          Primitive.SetState_Color := $000080;
          Primitive.SetState_IsSolid := True;
          Primitive.SetState_Transparent := True;
          Primitive.SetState_AreaColor := $B0FFFF;
          Primitive := LibIterator.NextSchObject;
     End;
     SchLib.SchIterator_Destroy(LibIterator);

     LibIterator := SchLib.SchLibIterator_Create;                               {Pin}
     LibIterator.AddFilter_ObjectSet(MkSet(ePin));
     Primitive := LibIterator.FirstSchObject;
     While Primitive <> Nil Do
     Begin
          Primitive.SetState_Color := $000000;
          Primitive.Designator_CustomColor := $000000;
          Primitive.Name_CustomColor := $000000;
          Primitive := LibIterator.NextSchObject;
     End;
     SchLib.SchIterator_Destroy(LibIterator);

     LibIterator := SchLib.SchLibIterator_Create;                               {Designator}
     LibIterator.AddFilter_ObjectSet(MkSet(eDesignator));
     Primitive := LibIterator.FirstSchObject;
     While Primitive <> Nil Do
     Begin
          Primitive.SetState_Color := $800000;
          Primitive := LibIterator.NextSchObject;
     End;
     SchLib.SchIterator_Destroy(LibIterator);

     LibIterator := SchLib.SchLibIterator_Create;                               {Parameter}
     LibIterator.AddFilter_ObjectSet(MkSet(eParameter));
     Primitive := LibIterator.FirstSchObject;
     While Primitive <> Nil Do
     Begin
          Primitive.SetState_Color := $800000;
          Primitive := LibIterator.NextSchObject;
     End;
     SchLib.SchIterator_Destroy(LibIterator);

     LibIterator := SchLib.SchLibIterator_Create;                               {Line}
     LibIterator.AddFilter_ObjectSet(MkSet(ePolyline));
     Primitive := LibIterator.FirstSchObject;
     While Primitive <> Nil Do
     Begin
          Primitive.SetState_Color := $FF0000;
          Primitive := LibIterator.NextSchObject;
     End;
     SchLib.SchIterator_Destroy(LibIterator);

     LibIterator := SchLib.SchLibIterator_Create;                               {Arc}
     LibIterator.AddFilter_ObjectSet(MkSet(eArc));
     Primitive := LibIterator.FirstSchObject;
     While Primitive <> Nil Do
     Begin
          Primitive.SetState_Color := $FF0000;
          Primitive := LibIterator.NextSchObject;
     End;
     SchLib.SchIterator_Destroy(LibIterator);

     LibIterator := SchLib.SchLibIterator_Create;                               {Polygon}
     LibIterator.AddFilter_ObjectSet(MkSet(ePolygon));
     Primitive := LibIterator.FirstSchObject;
     While Primitive <> Nil Do
     Begin
          Primitive.SetState_Color := $FF0000;
          Primitive.SetState_AreaColor := $FF0000;
          Primitive := LibIterator.NextSchObject;
     End;
     SchLib.SchIterator_Destroy(LibIterator);

     LibIterator := SchLib.SchLibIterator_Create;                               {Text}
     LibIterator.AddFilter_ObjectSet(MkSet(22));
     Primitive := LibIterator.FirstSchObject;
     While Primitive <> Nil Do
     Begin
          Primitive.SetState_Color := $000000;
          Primitive := LibIterator.NextSchObject;
     End;
     SchLib.SchIterator_Destroy(LibIterator);
End;

{..............................................................................}

{..............................................................................}

procedure TLibraryStyleChangerForm.XPFolderChange(Sender: TObject);             {Edit Change}
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

procedure TLibraryStyleChangerForm.bEnableAllClick(Sender: TObject);
var
    I : Integer;
begin
    For I := 0 to CheckListBoxSchLibraries.Items.Count - 1 Do
        CheckListBoxSchLibraries.Checked[I] := True;
end;

procedure TLibraryStyleChangerForm.bClearAllClick(Sender: TObject);
var
    I : Integer;
begin
    For I := 0 to CheckListBoxSchLibraries.Items.Count - 1 Do
        CheckListBoxSchLibraries.Checked[I] := False;
end;

{..............................................................................}

{..............................................................................}

Procedure TLibraryStyleChangerForm.bRunClick(Sender: TObject);                  {Run Button Click}
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
                   IterateLibPrimitives(I);
                   Document.DoFileSave('Advanced Schematic binary library');
              End;
              Client.CloseDocument(Document);
         End;
     Showmessage('Done');
     Close;
End;

Procedure TLibraryStyleChangerForm.bCancelClick(Sender: TObject);
Begin
     Close;
End;

{..............................................................................}

{..............................................................................}

Procedure RunLibraryStyleChanger;                                               {Main}
Var
   LastLibDocument     : IServerDocument;
Begin
     If SchServer = Nil Then
     Begin
          ShowWarning('Sch Server is not active!');
          Exit;
     End;
     LastLibDocument := Client.LastActiveDocumentOfType('SCHLIB');
     If LastLibDocument = Nil Then
     Begin
        LastLibDocument := Client.LastActiveDocumentOfType('PCBLIB');
        If LastLibDocument <> Nil Then
        Begin
             XPFolderEdit.InitialDir := ExtractFilePath(LastLibDocument.FileName);
             XPFolderEdit.Text := XPFolderEdit.InitialDir;
        End;
     End
     Else
     Begin
         XPFolderEdit.InitialDir := ExtractFilePath(LastLibDocument.FileName);
         XPFolderEdit.Text := XPFolderEdit.InitialDir;
     End;
     LibraryStyleChangerForm.ShowModal;
End;




End.


