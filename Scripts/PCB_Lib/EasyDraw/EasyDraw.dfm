object EasyDrawForm: TEasyDrawForm
  Left = 0
  Top = 0
  Cursor = crCross
  Caption = 'Easy Draw'
  ClientHeight = 173
  ClientWidth = 312
  Color = clAppWorkSpace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesigned
  OnClose = EasyDrawFormClose
  FormKind = fkNormal
  PixelsPerInch = 120
  TextHeight = 16
  object bOk: TButton
    Left = 33
    Top = 142
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 2
    OnClick = bOkClick
  end
  object bCancel: TButton
    Left = 201
    Top = 142
    Width = 75
    Height = 25
    Caption = 'Cancel'
    TabOrder = 0
    OnClick = bCancelClick
  end
  object gbProperties: TGroupBox
    Left = 16
    Top = 8
    Width = 280
    Height = 128
    Caption = 'Properties'
    TabOrder = 1
    object gbLinesPitch: TGroupBox
      Left = 104
      Top = 72
      Width = 80
      Height = 48
      Caption = 'Lines Pitch'
      TabOrder = 1
      object eLinesPitch: TEdit
        Left = 8
        Top = 16
        Width = 64
        Height = 24
        TabOrder = 0
        Text = '1,25'
        OnExit = eLinesPitchExit
        OnKeyPress = eLinesPitchKeyPress
      end
    end
    object rgUnit: TRadioGroup
      Left = 192
      Top = 14
      Width = 80
      Height = 106
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
    object gbWidth: TGroupBox
      Left = 8
      Top = 24
      Width = 88
      Height = 48
      Caption = 'Width'
      TabOrder = 2
      object pWidth: TPanel
        Left = 8
        Top = 20
        Width = 72
        Height = 20
        Color = clInactiveBorder
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
    object gbHeight: TGroupBox
      Left = 8
      Top = 72
      Width = 88
      Height = 48
      Caption = 'Height'
      TabOrder = 3
      object pHeight: TPanel
        Left = 8
        Top = 20
        Width = 72
        Height = 20
        Color = clInactiveBorder
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
    object gbLinesWidth: TGroupBox
      Left = 104
      Top = 24
      Width = 80
      Height = 48
      Caption = 'Lines Width'
      TabOrder = 4
      object pLinesWidth: TPanel
        Left = 8
        Top = 20
        Width = 64
        Height = 20
        Color = clInactiveBorder
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
    object gbRadius: TGroupBox
      Left = 8
      Top = 24
      Width = 88
      Height = 48
      Caption = 'Radius'
      TabOrder = 5
      Visible = False
      object pRadius: TPanel
        Left = 8
        Top = 20
        Width = 72
        Height = 20
        Color = clInactiveBorder
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
end
