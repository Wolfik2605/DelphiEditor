object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 578
  ClientWidth = 999
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  Position = poDesigned
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  TextHeight = 15
  object StatusBar1: TStatusBar
    Left = 0
    Top = 559
    Width = 999
    Height = 19
    Panels = <>
    ExplicitTop = 551
    ExplicitWidth = 997
  end
  object SynEdit1: TSynEdit
    Left = 0
    Top = 0
    Width = 999
    Height = 559
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Consolas'
    Font.Style = []
    Font.Quality = fqClearTypeNatural
    TabOrder = 2
    UseCodeFolding = False
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -13
    Gutter.Font.Name = 'Consolas'
    Gutter.Font.Style = []
    Gutter.Bands = <
      item
        Kind = gbkMarks
        Width = 13
      end
      item
        Kind = gbkLineNumbers
      end
      item
        Kind = gbkFold
      end
      item
        Kind = gbkTrackChanges
      end
      item
        Kind = gbkMargin
        Width = 3
      end>
    Highlighter = SynPasSyn1
    Lines.Strings = (
      '')
    SelectedColor.Alpha = 1.000000000000000000
    OnSpecialLineColors = SynEdit1SpecialLineColors
    ExplicitWidth = 997
    ExplicitHeight = 551
  end
  object CheckSyntaxBtn: TButton
    Left = 840
    Top = 523
    Width = 136
    Height = 30
    Caption = #1055#1088#1086#1074#1077#1088#1080#1090#1100' '#1089#1080#1085#1090#1072#1082#1089#1080#1089
    TabOrder = 1
    OnClick = CheckSyntaxBtnClick
  end
  object OpenDialog1: TOpenDialog
    Left = 672
    Top = 24
  end
  object SaveDialog1: TSaveDialog
    Left = 704
    Top = 24
  end
  object MainMenu1: TMainMenu
    Left = 736
    Top = 240
    object F1: TMenuItem
      Caption = #1060#1072#1081#1083
      object New: TMenuItem
        Caption = #1053#1086#1074#1099#1081
        ShortCut = 16462
        OnClick = NewClick
      end
      object Open: TMenuItem
        Caption = #1054#1090#1082#1088#1099#1090#1100
        ShortCut = 16463
        OnClick = OpenClick
      end
      object Save: TMenuItem
        Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100
        ShortCut = 16467
        OnClick = SaveClick
      end
      object SaveAs: TMenuItem
        Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100' '#1082#1072#1082
        ShortCut = 24659
        OnClick = SaveAsClick
      end
      object Exit1: TMenuItem
        Caption = #1042#1099#1093#1086#1076
        ShortCut = 32883
        OnClick = Exit1Click
      end
    end
    object Edit: TMenuItem
      Caption = #1055#1088#1072#1074#1082#1072
      object Cut: TMenuItem
        Caption = #1042#1099#1088#1077#1079#1072#1090#1100
        ShortCut = 16472
        OnClick = CutClick
      end
      object Copy: TMenuItem
        Caption = #1050#1086#1087#1080#1088#1086#1074#1072#1090#1100
        ShortCut = 16451
        OnClick = CopyClick
      end
      object Paste: TMenuItem
        Caption = #1042#1089#1090#1072#1074#1080#1090#1100
        ShortCut = 16470
        OnClick = PasteClick
      end
      object Delete: TMenuItem
        Caption = #1059#1076#1072#1083#1080#1090#1100
        OnClick = DeleteClick
      end
    end
    object Format: TMenuItem
      Caption = #1060#1086#1088#1084#1072#1090
      object FontSize: TMenuItem
        Caption = #1056#1072#1079#1084#1077#1088' '#1096#1088#1080#1092#1090#1072
        OnClick = FontSizeClick
      end
      object FontColor: TMenuItem
        Caption = #1062#1074#1077#1090' '#1096#1088#1080#1092#1090#1072
        OnClick = FontColorClick
      end
    end
  end
  object FontDialog1: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Segoe UI'
    Font.Style = []
    Left = 736
    Top = 24
  end
  object ColorDialog1: TColorDialog
    Left = 768
    Top = 24
  end
  object SynPasSyn1: TSynPasSyn
    Left = 600
    Top = 240
  end
  object StatusBarPopupMenu: TPopupMenu
    Left = 800
    Top = 240
    object CopyStatusText1: TMenuItem
      Caption = 'Copy Error Text'
      OnClick = CopyStatusText1Click
    end
  end
end
