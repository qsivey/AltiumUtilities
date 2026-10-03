object LibraryStyleChangerForm: TLibraryStyleChangerForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'LibraryStyleChanger v1.4.6'
  ClientHeight = 547
  ClientWidth = 714
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
  object Label1: TLabel
    Left = 18
    Top = 4
    Width = 103
    Height = 16
    Caption = 'Libraries directory'
  end
  object LProcessingState: TLabel
    Left = 16
    Top = 488
    Width = 4
    Height = 16
  end
  object bRun: TButton
    Left = 534
    Top = 512
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 3
    OnClick = bRunClick
  end
  object bCancel: TButton
    Left = 625
    Top = 512
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 4
    OnClick = bCancelClick
  end
  object XPFolderEdit: TXPDirectoryEdit
    Left = 14
    Top = 23
    Width = 686
    Height = 25
    AutoSize = False
    ReadOnly = True
    StretchButtonImage = False
    TabOrder = 0
    Text = ''
    OnChange = XPFolderChange
  end
  object GroupBox1: TGroupBox
    Left = 10
    Top = 53
    Width = 230
    Height = 427
    Caption = 'Libraries to convert'
    TabOrder = 1
    object CheckListBoxSchLibraries: TCheckListBox
      Left = 8
      Top = 20
      Width = 215
      Height = 375
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 0
    end
    object bClearAll: TButton
      Left = 129
      Top = 400
      Width = 94
      Height = 22
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'Clear All'
      TabOrder = 1
      OnClick = bClearAllClick
    end
    object bEnableAll: TButton
      Left = 9
      Top = 400
      Width = 94
      Height = 22
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'Enable All'
      TabOrder = 2
      OnClick = bEnableAllClick
    end
  end
  object GroupBoxColors: TGroupBox
    Left = 252
    Top = 53
    Width = 448
    Height = 427
    Caption = 'Colors by primitive role'
    TabOrder = 2
    object LabelBodyOutline: TLabel
      Left = 12
      Top = 30
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Body outline'
    end
    object ShapeBodyOutline: TShape
      Left = 284
      Top = 26
      Width = 36
      Height = 25
      Hint = 'Rectangle, Polygon, rounded rectangle and ellipse outlines'
      Brush.Color = 128
      ParentShowHint = False
      ShowHint = True
    end
    object bBodyOutlineColor: TButton
      Left = 332
      Top = 25
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 0
      OnClick = bBodyOutlineColorClick
    end
    object LabelBodyFill: TLabel
      Left = 12
      Top = 78
      Width = 68
      Height = 16
      AutoSize = False
      Caption = 'Body fill'
    end
    object cbEnableBodyFill: TCheckBox
      Left = 88
      Top = 76
      Width = 76
      Height = 20
      Hint = 'Fill component Rectangle and Polygon objects. Uncheck for outlines only.'
      Caption = 'Enable'
      Checked = True
      ParentShowHint = False
      ShowHint = True
      State = cbChecked
      TabOrder = 1
    end
    object cbTransparentBodyFill: TCheckBox
      Left = 170
      Top = 76
      Width = 104
      Height = 20
      Hint = 'Optional transparency for component Rectangle and Polygon fills. Off by default; opaque fills are checked for primitive order conflicts.'
      Caption = 'Transparent'
      Checked = False
      ParentShowHint = False
      ShowHint = True
      State = cbUnchecked
      TabOrder = 2
    end
    object ShapeBodyFill: TShape
      Left = 284
      Top = 74
      Width = 36
      Height = 25
      Hint = 'Component Rectangle and Polygon fills; Enable controls fill, Transparent controls transparency'
      Brush.Color = 11599871
      ParentShowHint = False
      ShowHint = True
    end
    object bBodyFillColor: TButton
      Left = 332
      Top = 73
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 3
      OnClick = bBodyFillColorClick
    end
    object LabelGraphics: TLabel
      Left = 12
      Top = 126
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Lines / arcs'
    end
    object ShapeGraphics: TShape
      Left = 284
      Top = 122
      Width = 36
      Height = 25
      Hint = 'Polylines and arcs except radius 20 mil'
      Brush.Color = 16711680
      ParentShowHint = False
      ShowHint = True
    end
    object bGraphicsColor: TButton
      Left = 332
      Top = 121
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 4
      OnClick = bGraphicsColorClick
    end
    object LabelParameters: TLabel
      Left = 12
      Top = 174
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Parameters / designator'
    end
    object ShapeParameters: TShape
      Left = 284
      Top = 170
      Width = 36
      Height = 25
      Hint = 'Component parameters and designator'
      Brush.Color = 8388608
      ParentShowHint = False
      ShowHint = True
    end
    object bParametersColor: TButton
      Left = 332
      Top = 169
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 5
      OnClick = bParametersColorClick
    end
    object LabelPinText: TLabel
      Left = 12
      Top = 222
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'Pins / text / 20 mil arcs'
    end
    object ShapePinText: TShape
      Left = 284
      Top = 218
      Width = 36
      Height = 25
      Hint = 'Pins, pin names and designators, text, arcs of radius 20 mil'
      Brush.Color = clBlack
      ParentShowHint = False
      ShowHint = True
    end
    object bPinTextColor: TButton
      Left = 332
      Top = 217
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 6
      OnClick = bPinTextColorClick
    end
    object LabelImages: TLabel
      Left = 12
      Top = 270
      Width = 260
      Height = 16
      AutoSize = False
      Caption = 'PNG images'
    end
    object ShapeImages: TShape
      Left = 284
      Top = 266
      Width = 36
      Height = 25
      Hint = 'PNG pixels; transparency and original source files are preserved'
      Brush.Color = clBlack
      ParentShowHint = False
      ShowHint = True
    end
    object bImagesColor: TButton
      Left = 332
      Top = 265
      Width = 104
      Height = 27
      Caption = 'Choose...'
      TabOrder = 7
      OnClick = bImagesColorClick
    end
    object cbRecolorImages: TCheckBox
      Left = 12
      Top = 308
      Width = 424
      Height = 20
      Hint = 'Originals: sibling Images folder. Colored copies: selected library folder\Images.'
      Caption = 'Recolor PNG pixels (otherwise keep original)'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 8
    end
    object bAllColors: TButton
      Left = 12
      Top = 343
      Width = 424
      Height = 27
      Caption = 'One color for all six accents...'
      TabOrder = 9
      OnClick = bAllColorsClick
    end
    object cbPresets: TComboBox
      Left = 12
      Top = 385
      Width = 308
      Height = 24
      Style = csDropDownList
      DropDownCount = 10
      Hint = 'Choose a preset from Libraries\StylePresets.txt, then click Apply preset'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 10
      OnDropDown = cbPresetsDropDown
    end
    object bApplyPreset: TButton
      Left = 332
      Top = 384
      Width = 104
      Height = 27
      Caption = 'Apply preset'
      TabOrder = 11
      OnClick = bApplyPresetClick
    end
  end
  object StyleColorDialog: TColorDialog
    Ctl3D = True
    Options = [cdFullOpen]
    Left = 256
    Top = 504
  end
end
