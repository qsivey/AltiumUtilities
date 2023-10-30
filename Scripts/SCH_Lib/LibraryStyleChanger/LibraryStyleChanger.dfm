object LibraryStyleChangerForm: TLibraryStyleChangerForm
  Left = 0
  Top = 0
  Caption = 'LibraryStyleChanger'
  ClientHeight = 343
  ClientWidth = 402
  Color = clAppWorkSpace
  Constraints.MaxHeight = 390
  Constraints.MaxWidth = 420
  Constraints.MinHeight = 390
  Constraints.MinWidth = 420
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
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
    Top = 288
    Width = 4
    Height = 16
  end
  object bRun: TButton
    Left = 49
    Top = 308
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 0
    OnClick = bRunClick
  end
  object bCancel: TButton
    Left = 265
    Top = 308
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = bCancelClick
  end
  object XPFolderEdit: TXPDirectoryEdit
    Left = 14
    Top = 22
    Width = 362
    Height = 24
    AutoSize = False
    ReadOnly = True
    StretchButtonImage = False
    TabOrder = 2
    Text = ''
    OnChange = XPFolderChange
  end
  object GroupBox1: TGroupBox
    Left = 10
    Top = 52
    Width = 230
    Height = 236
    Caption = 'Libraries to convert'
    TabOrder = 3
    object CheckListBoxSchLibraries: TCheckListBox
      Left = 8
      Top = 20
      Width = 214
      Height = 182
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 0
    end
    object bClearAll: TButton
      Left = 129
      Top = 208
      Width = 93
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
      Top = 208
      Width = 93
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
end
