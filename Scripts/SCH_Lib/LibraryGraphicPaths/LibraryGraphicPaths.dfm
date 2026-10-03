object LibraryGraphicPathsForm: TLibraryGraphicPathsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'LibraryGraphicPaths v1.0.2'
  ClientHeight = 440
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
  object LFolder: TLabel
    Left = 14
    Top = 12
    Width = 686
    Height = 16
    AutoSize = False
    Caption = 'Libraries directory (all SchLib files in this folder)'
  end
  object LibraryFolder: TXPDirectoryEdit
    Left = 14
    Top = 34
    Width = 686
    Height = 25
    AutoSize = False
    ReadOnly = True
    StretchButtonImage = False
    TabOrder = 0
    Text = ''
  end
  object LTarget: TLabel
    Left = 14
    Top = 72
    Width = 480
    Height = 16
    AutoSize = False
    Caption = 'Graphic: ..\Images\<filename>'
  end
  object cbEmbedded: TCheckBox
    Left = 510
    Top = 70
    Width = 190
    Height = 20
    Hint = 'Checked: embed images. Unchecked: link to existing files in ..\Images\.'
    Caption = 'Embedded'
    Checked = True
    ParentShowHint = False
    ShowHint = True
    State = cbChecked
    TabOrder = 1
  end
  object LBackup: TLabel
    Left = 14
    Top = 96
    Width = 686
    Height = 16
    AutoSize = False
    Caption = 'Backups: selected folder\_GraphicPathsBackup\<timestamp>'
  end
  object LogMemo: TMemo
    Left = 14
    Top = 124
    Width = 686
    Height = 244
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
  end
  object LStatus: TLabel
    Left = 14
    Top = 378
    Width = 686
    Height = 16
    AutoSize = False
    Caption = 'Choose a folder, then click Run.'
  end
  object bRun: TButton
    Left = 534
    Top = 404
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 3
    OnClick = bRunClick
  end
  object bClose: TButton
    Left = 625
    Top = 404
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Close'
    TabOrder = 4
    OnClick = bCloseClick
  end
end
