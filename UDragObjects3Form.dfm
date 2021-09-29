object DragObjectsForm: TDragObjectsForm
  Left = 192
  Top = 126
  Caption = 'Drag Objects'
  ClientHeight = 510
  ClientWidth = 264
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  DesignSize = (
    264
    510)
  PixelsPerInch = 96
  TextHeight = 13
  object lblLabel: TLabel
    Left = 135
    Top = 14
    Width = 26
    Height = 13
    Caption = 'Label'
    DragMode = dmAutomatic
  end
  object lblLog: TLabel
    Left = 8
    Top = 286
    Width = 18
    Height = 13
    Caption = 'Log'
  end
  object edtLiveInfo: TLabel
    Left = 206
    Top = 286
    Width = 50
    Height = 13
    Alignment = taRightJustify
    Anchors = [akLeft, akTop, akRight]
    Caption = '<LiveInfo>'
  end
  object btnButton: TButton
    Left = 8
    Top = 8
    Width = 121
    Height = 25
    Caption = 'Button'
    DragMode = dmAutomatic
    TabOrder = 0
  end
  object edtComboBox: TComboBox
    Left = 8
    Top = 39
    Width = 121
    Height = 21
    DragMode = dmAutomatic
    TabOrder = 1
    Text = 'One'
    Items.Strings = (
      'One'
      'Two'
      'Three'
      'Four'
      'Five'
      'Six'
      'Seven'
      'Eight'
      'Nine'
      'Ten')
  end
  object edtEdit: TEdit
    Left = 135
    Top = 40
    Width = 121
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    DragMode = dmAutomatic
    TabOrder = 2
    Text = 'Edit'
  end
  object edtMemo: TMemo
    Left = 8
    Top = 66
    Width = 121
    Height = 95
    DragMode = dmAutomatic
    Lines.Strings = (
      'Memo')
    TabOrder = 3
  end
  object edtListBox: TListBox
    Left = 135
    Top = 67
    Width = 121
    Height = 95
    Anchors = [akLeft, akTop, akRight]
    DragMode = dmAutomatic
    IntegralHeight = True
    ItemHeight = 13
    Items.Strings = (
      'One'
      'Two'
      'Three'
      'Four'
      'Five'
      'Six'
      'Seven'
      'Eight'
      'Nine'
      'Ten')
    TabOrder = 4
  end
  object grpPanel: TPanel
    Left = 8
    Top = 167
    Width = 248
    Height = 113
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Drag-and-drop an object from above to here'
    TabOrder = 5
    OnDragDrop = grpPanelDragDrop
    OnDragOver = grpPanelDragOver
    object lblDragMode: TLabel
      Left = 8
      Top = 8
      Width = 52
      Height = 13
      Caption = 'Drag mode'
    end
    object edtAutomaticDragMode: TRadioButton
      Left = 66
      Top = 7
      Width = 71
      Height = 17
      Caption = 'Automatic'
      TabOrder = 0
      OnClick = edtAutomaticDragModeClick
    end
    object edtManualDragMode: TRadioButton
      Left = 135
      Top = 7
      Width = 71
      Height = 17
      Caption = 'Manual'
      TabOrder = 1
      OnClick = edtManualDragModeClick
    end
  end
  object edtLog: TMemo
    Left = 8
    Top = 305
    Width = 248
    Height = 197
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 6
  end
end
