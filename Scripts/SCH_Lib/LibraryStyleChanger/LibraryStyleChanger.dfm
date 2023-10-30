object LibraryStyleChangerForm: TLibraryStyleChangerForm
  Left = 0
  Top = 0
  Caption = 'LibraryStyleChanger'
  ClientHeight = 273
  ClientWidth = 320
  Color = clAppWorkSpace
  Constraints.MaxHeight = 312
  Constraints.MaxWidth = 336
  Constraints.MinHeight = 312
  Constraints.MinWidth = 336
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 12
  object Label1: TLabel
    Left = 14
    Top = 3
    Width = 81
    Height = 12
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Libraries directory'
  end
  object LProcessingState: TLabel
    Left = 13
    Top = 230
    Width = 3
    Height = 12
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
  end
  object bRun: TButton
    Left = 39
    Top = 246
    Width = 60
    Height = 20
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Run'
    TabOrder = 0
    OnClick = bRunClick
  end
  object bCancel: TButton
    Left = 212
    Top = 246
    Width = 60
    Height = 20
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = bCancelClick
  end
  object XPFolderEdit: TXPDirectoryEdit
    Left = 11
    Top = 18
    Width = 290
    Height = 20
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    AutoSize = False
    ReadOnly = True
    StretchButtonImage = False
    TabOrder = 2
    Text = ''
    OnChange = XPFolderChange
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 42
    Width = 184
    Height = 188
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Libraries to convert'
    TabOrder = 3
    object CheckListBoxSchLibraries: TCheckListBox
      Left = 6
      Top = 16
      Width = 172
      Height = 146
      ItemHeight = 13
      TabOrder = 0
    end
    object bClearAll: TButton
      Left = 103
      Top = 166
      Width = 75
      Height = 18
      Caption = 'Clear All'
      TabOrder = 1
      OnClick = bClearAllClick
    end
    object bEnableAll: TButton
      Left = 7
      Top = 166
      Width = 75
      Height = 18
      Caption = 'Enable All'
      TabOrder = 2
      OnClick = bEnableAllClick
    end
  end
end
