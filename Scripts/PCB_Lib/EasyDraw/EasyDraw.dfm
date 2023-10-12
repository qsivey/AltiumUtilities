object EasyDrawForm: TEasyDrawForm
  Left = 0
  Top = 0
  Cursor = crCross
  Caption = 'Easy Draw'
  ClientHeight = 203
  ClientWidth = 312
  Color = clAppWorkSpace
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
    Left = 33
    Top = 170
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 2
    OnClick = bOkClick
  end
  object bCancel: TButton
    Left = 201
    Top = 170
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 0
    OnClick = bCancelClick
  end
  object GroupBox2: TGroupBox
    Left = 16
    Top = 8
    Width = 280
    Height = 152
    Caption = 'Properties'
    TabOrder = 1
    object GroupBox3: TGroupBox
      Left = 16
      Top = 88
      Width = 80
      Height = 56
      Caption = 'Height'
      TabOrder = 2
      object eHeight: TEdit
        Left = 8
        Top = 24
        Width = 64
        Height = 24
        TabOrder = 0
        Text = '5'
        OnExit = eHeightExit
      end
    end
    object GroupBox4: TGroupBox
      Left = 16
      Top = 24
      Width = 80
      Height = 57
      Caption = 'Width'
      TabOrder = 1
      object eWidth: TEdit
        Left = 8
        Top = 24
        Width = 64
        Height = 24
        TabOrder = 0
        Text = '10'
        OnExit = eWidthExit
      end
    end
    object GroupBox5: TGroupBox
      Left = 104
      Top = 88
      Width = 80
      Height = 57
      Caption = 'Lines Width'
      TabOrder = 4
      object eLinesWidth: TEdit
        Left = 8
        Top = 25
        Width = 64
        Height = 24
        TabOrder = 0
        Text = '0,25'
        OnExit = eLinesWidthExit
      end
    end
    object GroupBox6: TGroupBox
      Left = 104
      Top = 24
      Width = 80
      Height = 56
      Caption = 'Lines Pitch'
      TabOrder = 3
      object eLinesPitch: TEdit
        Left = 8
        Top = 24
        Width = 64
        Height = 24
        TabOrder = 0
        Text = '1,25'
        OnExit = eLinesPitchExit
      end
    end
    object rgUnit: TRadioGroup
      Left = 192
      Top = 20
      Width = 80
      Height = 100
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = ' Unit '
      ItemIndex = 0
      Items.Strings = (
        'MMs'
        'Mils')
      TabOrder = 0
      OnClick = rgUnitClick
    end
    object cbDeleteOld: TCheckBox
      Left = 192
      Top = 127
      Width = 80
      Height = 17
      TabStop = False
      Caption = 'Delete Old'
      TabOrder = 5
    end
  end
end
