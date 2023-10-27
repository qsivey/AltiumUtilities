object DescriptionToolForm: TDescriptionToolForm
  Left = 0
  Top = 0
  Caption = 'Description Tool'
  ClientHeight = 293
  ClientWidth = 342
  Color = clAppWorkSpace
  Constraints.MaxHeight = 340
  Constraints.MaxWidth = 360
  Constraints.MinHeight = 340
  Constraints.MinWidth = 360
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  PixelsPerInch = 120
  TextHeight = 16
  object bOk: TButton
    Left = 60
    Top = 260
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 2
    OnClick = bOkClick
  end
  object bCancel: TButton
    Left = 210
    Top = 260
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 0
    OnClick = bCancelClick
  end
  object gbSettings: TGroupBox
    Left = 8
    Top = 8
    Width = 326
    Height = 200
    Caption = 'Settings'
    TabOrder = 1
    object CheckListBoxProperties: TCheckListBox
      Left = 8
      Top = 48
      Width = 136
      Height = 144
      TabStop = False
      OnClickCheck = CheckListBoxPropertiesClickCheck
      ParentShowHint = False
      ShowHint = False
      TabOrder = 6
      OnClick = CheckListBoxPropertiesClick
    end
    object CBComponents: TComboBox
      Left = 8
      Top = 18
      Width = 160
      Height = 24
      TabOrder = 0
      OnDrawItem = CheckListBoxPropertiesClickCheck
      OnSelect = CBComponentsSelect
    end
    object bUp: TButton
      Left = 146
      Top = 52
      Width = 24
      Height = 41
      Caption = #8593
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = bUpClick
    end
    object bDown: TButton
      Left = 146
      Top = 96
      Width = 24
      Height = 41
      Caption = #8595
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = bDownClick
    end
    object cbForceUppercase: TCheckBox
      Left = 151
      Top = 171
      Width = 121
      Height = 17
      TabStop = False
      Caption = 'Force Uppercase'
      TabOrder = 5
      OnClick = cbForceUppercaseClick
    end
    object cbOnlySelected: TCheckBox
      Left = 151
      Top = 146
      Width = 169
      Height = 17
      TabStop = False
      Caption = 'Only Selected'
      TabOrder = 4
    end
    object gbFix: TGroupBox
      Left = 176
      Top = 48
      Width = 142
      Height = 48
      Caption = 'Fix'
      TabOrder = 1
      TabStop = True
      object eFix: TEdit
        Left = 7
        Top = 16
        Width = 128
        Height = 24
        TabOrder = 0
        OnChange = eFixChange
      end
    end
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 208
    Width = 326
    Height = 48
    Caption = 'Description Example'
    TabOrder = 3
    object pExample: TPanel
      Left = 12
      Top = 17
      Width = 302
      Height = 22
      Margins.Left = 10
      Margins.Right = 10
      Alignment = taLeftJustify
      BevelOuter = bvNone
      BorderWidth = 3
      Color = clActiveCaption
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentBackground = False
      ParentCtl3D = False
      ParentFont = False
      TabOrder = 0
    end
  end
end
