object SchematicStyleChangerForm: TSchematicStyleChangerForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'SchematicStyleChanger v1.8.5'
  ClientHeight = 801
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsNormal
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 120
  TextHeight = 16
  object LabelFolder: TLabel
    Left = 14
    Top = 8
    Width = 119
    Height = 16
    Caption = 'Schematics directory'
  end
  object LabelOriginalImages: TLabel
    Left = 14
    Top = 60
    Width = 289
    Height = 16
    Caption = 'Original PNG directory (recolor / restore)'
  end
  object LProcessingState: TLabel
    Left = 14
    Top = 769
    Width = 516
    Height = 18
    AutoSize = False
    Caption = 'Run saves changes to the selected SchDoc files.'
  end
  object XPFolderEdit: TXPDirectoryEdit
    Left = 14
    Top = 28
    Width = 732
    Height = 25
    AutoSize = False
    ReadOnly = True
    StretchButtonImage = False
    TabOrder = 0
    Text = ''
    OnChange = XPFolderChange
  end
  object OriginalImagesFolder: TXPDirectoryEdit
    Left = 14
    Top = 80
    Width = 732
    Height = 25
    AutoSize = False
    ReadOnly = True
    StretchButtonImage = False
    TabOrder = 1
    Text = ''
  end
  object GroupBoxDocuments: TGroupBox
    Left = 14
    Top = 115
    Width = 272
    Height = 641
    Caption = 'SchDoc files to convert'
    TabOrder = 2
    object CheckListBoxSchematics: TCheckListBox
      Left = 8
      Top = 24
      Width = 256
      Height = 568
      TabOrder = 0
    end
    object bEnableAll: TButton
      Left = 8
      Top = 604
      Width = 120
      Height = 27
      Caption = 'Enable All'
      TabOrder = 1
      OnClick = bEnableAllClick
    end
    object bClearAll: TButton
      Left = 144
      Top = 604
      Width = 120
      Height = 27
      Caption = 'Clear All'
      TabOrder = 2
      OnClick = bClearAllClick
    end
  end
  object GroupBoxColors: TGroupBox
    Left = 298
    Top = 115
    Width = 448
    Height = 641
    Caption = 'Colors by primitive role'
    TabOrder = 3
    object LabelBodyOutline: TLabel
      Left = 12
      Top = 29
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Body outline'
    end
    object ShapeBodyOutline: TShape
      Left = 284
      Top = 25
      Width = 36
      Height = 25
      Hint = 'Rectangle and ellipse outlines'
      Brush.Color = clMaroon
      ParentShowHint = False
      ShowHint = True
    end
    object LabelBodyFill: TLabel
      Left = 12
      Top = 65
      Width = 68
      Height = 16
      AutoSize = False
      Caption = 'Body fill'
    end
    object cbEnableBodyFill: TCheckBox
      Left = 88
      Top = 63
      Width = 76
      Height = 20
      Hint = 'Fill component Rectangle objects only. Uncheck for outlines only.'
      Caption = 'Enable'
      Checked = True
      ParentShowHint = False
      ShowHint = True
      State = cbChecked
      TabOrder = 1
    end
    object cbTransparentBodyFill: TCheckBox
      Left = 170
      Top = 63
      Width = 104
      Height = 20
      Hint = 'Optional transparency for component Rectangle fills. Off by default; opaque fills are checked for primitive order conflicts.'
      Caption = 'Transparent'
      Checked = False
      ParentShowHint = False
      ShowHint = True
      State = cbUnchecked
      TabOrder = 2
    end
    object ShapeBodyFill: TShape
      Left = 284
      Top = 61
      Width = 36
      Height = 25
      Hint = 'Component Rectangle fills only; Enable controls fill, Transparent controls transparency'
      Brush.Color = 11599871
      ParentShowHint = False
      ShowHint = True
    end
    object LabelGraphics: TLabel
      Left = 12
      Top = 101
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Lines / polygons / arcs'
    end
    object ShapeGraphics: TShape
      Left = 284
      Top = 97
      Width = 36
      Height = 25
      Hint = 'Graphic lines, polygons, curves and arcs except radius 20 mil'
      Brush.Color = clBlue
      ParentShowHint = False
      ShowHint = True
    end
    object LabelParameters: TLabel
      Left = 12
      Top = 137
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Parameters / designator'
    end
    object ShapeParameters: TShape
      Left = 284
      Top = 133
      Width = 36
      Height = 25
      Hint = 'Parameters and component designators'
      Brush.Color = clNavy
      ParentShowHint = False
      ShowHint = True
    end
    object LabelPinText: TLabel
      Left = 12
      Top = 173
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Pins / text / 20 mil arcs'
    end
    object ShapePinText: TShape
      Left = 284
      Top = 169
      Width = 36
      Height = 25
      Hint = 'Pins, pin names and designators, text and 20 mil arcs'
      Brush.Color = clBlack
      ParentShowHint = False
      ShowHint = True
    end
    object LabelImages: TLabel
      Left = 12
      Top = 209
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'PNG images'
    end
    object ShapeImages: TShape
      Left = 284
      Top = 205
      Width = 36
      Height = 25
      Hint = 'PNG pixels; original files and transparency are preserved'
      Brush.Color = clBlack
      ParentShowHint = False
      ShowHint = True
    end
    object LabelWires: TLabel
      Left = 12
      Top = 245
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Wires'
    end
    object ShapeWires: TShape
      Left = 284
      Top = 241
      Width = 36
      Height = 25
      Hint = 'Electrical wires; junctions follow the selected mode. Buses use Other.'
      Brush.Color = clNavy
      ParentShowHint = False
      ShowHint = True
    end
    object LabelPortBorder: TLabel
      Left = 12
      Top = 281
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Port Border'
    end
    object ShapePortBorder: TShape
      Left = 284
      Top = 277
      Width = 36
      Height = 25
      Hint = 'Port outline color'
      Brush.Color = clMaroon
      ParentShowHint = False
      ShowHint = True
    end
    object LabelPortFill: TLabel
      Left = 12
      Top = 317
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Port Fill'
    end
    object ShapePortFill: TShape
      Left = 284
      Top = 313
      Width = 36
      Height = 25
      Hint = 'Port interior fill color'
      Brush.Color = 8454143
      ParentShowHint = False
      ShowHint = True
    end
    object bPortFillColor: TButton
      Left = 332
      Top = 312
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 10
      OnClick = bPortFillColorClick
    end
    object LabelPortFont: TLabel
      Left = 12
      Top = 353
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Port Font'
    end
    object ShapePortFont: TShape
      Left = 284
      Top = 349
      Width = 36
      Height = 25
      Hint = 'Port name text color; font family and size are preserved'
      Brush.Color = clMaroon
      ParentShowHint = False
      ShowHint = True
    end
    object LabelOther: TLabel
      Left = 12
      Top = 389
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Other'
    end
    object ShapeOther: TShape
      Left = 284
      Top = 385
      Width = 36
      Height = 25
      Hint = 
        'Buses, labels, power ports, sheet symbols, harnesses ' +
        'and directives'
      Brush.Color = clNavy
      ParentShowHint = False
      ShowHint = True
    end
    object bBodyOutlineColor: TButton
      Left = 332
      Top = 24
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 0
      OnClick = bBodyOutlineColorClick
    end
    object bBodyFillColor: TButton
      Left = 332
      Top = 60
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 3
      OnClick = bBodyFillColorClick
    end
    object bGraphicsColor: TButton
      Left = 332
      Top = 96
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 4
      OnClick = bGraphicsColorClick
    end
    object bParametersColor: TButton
      Left = 332
      Top = 132
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 5
      OnClick = bParametersColorClick
    end
    object bPinTextColor: TButton
      Left = 332
      Top = 168
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 6
      OnClick = bPinTextColorClick
    end
    object bImagesColor: TButton
      Left = 332
      Top = 204
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 7
      OnClick = bImagesColorClick
    end
    object bWiresColor: TButton
      Left = 332
      Top = 240
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 8
      OnClick = bWiresColorClick
    end
    object bPortBorderColor: TButton
      Left = 332
      Top = 276
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 9
      OnClick = bPortBorderColorClick
    end
    object bPortFontColor: TButton
      Left = 332
      Top = 348
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 11
      OnClick = bPortFontColorClick
    end
    object bOtherColor: TButton
      Left = 332
      Top = 384
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 12
      OnClick = bOtherColorClick
    end
    object LabelSheetColor: TLabel
      Left = 12
      Top = 425
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Sheet Color'
    end
    object ShapeSheetColor: TShape
      Left = 284
      Top = 421
      Width = 36
      Height = 25
      Hint = 'Schematic sheet background; separate from the common accent'
      Brush.Color = clWhite
      ParentShowHint = False
      ShowHint = True
    end
    object bSheetColor: TButton
      Left = 332
      Top = 420
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 13
      OnClick = bSheetColorClick
    end
    object LabelImageMode: TLabel
      Left = 12
      Top = 466
      Width = 84
      Height = 16
      AutoSize = False
      Caption = 'PNG images'
    end
    object cbImageMode: TComboBox
      Left = 104
      Top = 462
      Width = 332
      Height = 24
      Style = csDropDownList
      Hint = 'Recolor and Return to original image use the original PNG directory; copies go to Images beside the schematics.'
      ItemIndex = 0
      ParentShowHint = False
      ShowHint = True
      TabOrder = 14
      Text = 'Leave unchanged'
      Items.Strings = (
        'Leave unchanged'
        'Recolor'
        'Return to original image')
    end
    object LabelJunctionMode: TLabel
      Left = 12
      Top = 496
      Width = 84
      Height = 16
      AutoSize = False
      Caption = 'Junctions'
    end
    object cbJunctionMode: TComboBox
      Left = 104
      Top = 492
      Width = 332
      Height = 24
      Style = csDropDownList
      Hint =
        'Manual creates locked points on selected sheets. Global changes ' +
        'automatic junction color in ALL schematics. Both use Wires color.'
      ItemIndex = 0
      ParentShowHint = False
      ShowHint = True
      TabOrder = 15
      Text = 'Leave unchanged'
      Items.Strings = (
        'Leave unchanged'
        'Manual junctions'
        'Global color (all schematics)')
    end
    object bAllColors: TButton
      Left = 12
      Top = 528
      Width = 424
      Height = 27
      Caption = 'One color for all accents (except sheet)...'
      TabOrder = 16
      OnClick = bAllColorsClick
    end
    object cbPresets: TComboBox
      Left = 12
      Top = 569
      Width = 308
      Height = 24
      Style = csDropDownList
      DropDownCount = 10
      Hint = 'Choose a preset from Libraries\StylePresets.txt, then click Apply preset'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 17
      OnDropDown = cbPresetsDropDown
    end
    object bApplyPreset: TButton
      Left = 332
      Top = 568
      Width = 104
      Height = 27
      Caption = 'Apply preset'
      TabOrder = 18
      OnClick = bApplyPresetClick
    end
    object cbCreateDefaults: TCheckBox
      Left = 12
      Top = 607
      Width = 424
      Height = 20
      Hint = 'Run creates a DFT / MMsdft pair from current Altium defaults with the selected colors, beside the schematics.'
      Caption = 'Create defaults'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 19
    end
  end
  object bRun: TButton
    Left = 542
    Top = 767
    Width = 96
    Height = 27
    Caption = 'Run'
    TabOrder = 4
    OnClick = bRunClick
  end
  object bCancel: TButton
    Left = 650
    Top = 767
    Width = 96
    Height = 27
    Cancel = True
    Caption = 'Close'
    TabOrder = 5
    OnClick = bCancelClick
  end
  object StyleColorDialog: TColorDialog
    Options = [cdFullOpen]
    Left = 300
    Top = 764
  end
end
