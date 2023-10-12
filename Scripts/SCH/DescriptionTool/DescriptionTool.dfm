object DescriptionToolForm: TDescriptionToolForm
  Left = 0
  Top = 0
  Caption = 'Description Tool'
  ClientHeight = 293
  ClientWidth = 297
  Color = clAppWorkSpace
  Constraints.MaxHeight = 340
  Constraints.MaxWidth = 315
  Constraints.MinHeight = 340
  Constraints.MinWidth = 315
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
    Left = 40
    Top = 260
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 1
    OnClick = bOkClick
  end
  object bCancel: TButton
    Left = 190
    Top = 260
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 0
    OnClick = bCancelClick
  end
  object Select: TGroupBox
    Left = 8
    Top = 8
    Width = 280
    Height = 200
    Caption = 'Select'
    TabOrder = 2
    object CheckListBoxProperties: TCheckListBox
      Left = 8
      Top = 48
      Width = 136
      Height = 144
      OnClickCheck = CheckListBoxPropertiesClickCheck
      TabOrder = 0
    end
    object CBComponents: TComboBox
      Left = 8
      Top = 16
      Width = 160
      Height = 24
      TabOrder = 1
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
      TabOrder = 4
      OnClick = cbForceUppercaseClick
    end
    object cbOnlySelected: TCheckBox
      Left = 151
      Top = 146
      Width = 121
      Height = 17
      TabStop = False
      Caption = 'Only Selected'
      TabOrder = 5
    end
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 208
    Width = 280
    Height = 48
    Caption = 'Description Example'
    TabOrder = 3
    object pExample: TPanel
      Left = 9
      Top = 17
      Width = 263
      Height = 24
      Alignment = taLeftJustify
      BevelOuter = bvNone
      Color = clActiveCaption
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentBackground = False
      ParentFont = False
      TabOrder = 0
    end
  end
end
