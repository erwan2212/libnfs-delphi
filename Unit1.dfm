object Form1: TForm1
  Left = 292
  Top = 179
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'NFS Browser 0.1 by erwan2212@gmail.com'
  ClientHeight = 517
  ClientWidth = 747
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 16
  object Button2: TButton
    Left = 512
    Top = 20
    Width = 70
    Height = 30
    Caption = 'Open'
    TabOrder = 0
    OnClick = Button2Click
  end
  object ListView1: TListView
    Left = 20
    Top = 59
    Width = 720
    Height = 415
    Columns = <
      item
        Caption = 'Filename'
        Width = 246
      end
      item
        Caption = 'Size'
        Width = 123
      end
      item
        Caption = 'Type'
        Width = 62
      end>
    ReadOnly = True
    RowSelect = True
    PopupMenu = PopupMenu1
    TabOrder = 1
    ViewStyle = vsReport
    OnColumnClick = ListView1ColumnClick
    OnDblClick = ListView1DblClick
  end
  object txtpath: TEdit
    Left = 20
    Top = 482
    Width = 720
    Height = 24
    Color = clSilver
    ReadOnly = True
    TabOrder = 2
  end
  object Button1: TButton
    Left = 591
    Top = 20
    Width = 70
    Height = 30
    Caption = 'Close'
    TabOrder = 3
    OnClick = Button1Click
  end
  object Button3: TButton
    Left = 670
    Top = 20
    Width = 70
    Height = 30
    Caption = 'Discover'
    TabOrder = 4
    OnClick = Button3Click
  end
  object txtnfs: TComboBox
    Left = 20
    Top = 20
    Width = 483
    Height = 24
    Hint = 'nfs://servername/export_path/'
    ItemHeight = 16
    ParentShowHint = False
    ShowHint = True
    TabOrder = 5
  end
  object Button4: TButton
    Left = 256
    Top = 522
    Width = 119
    Height = 31
    Caption = 'Button4'
    TabOrder = 6
    Visible = False
    OnClick = Button4Click
  end
  object PopupMenu1: TPopupMenu
    Left = 248
    Top = 216
    object ReadFile1: TMenuItem
      Caption = 'View file as TEXT'
      OnClick = ReadFile1Click
    end
    object DownloadFile1: TMenuItem
      Caption = 'Download File'
      OnClick = DownloadFile1Click
    end
    object UploadFile1: TMenuItem
      Caption = 'Upload File'
      OnClick = UploadFile1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Refresh1: TMenuItem
      Caption = 'Refresh'
      OnClick = Refresh1Click
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 88
    Top = 416
  end
end
