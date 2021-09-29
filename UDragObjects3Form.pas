unit UDragObjects3Form;

// DragObjects3 by Andreas Toth (andreas.toth@xtra.co.nz)
// Based on DragObjects2 from http://www.blong.com/conferences/borcon2001/draganddrop/4114.htm

// KNOWN ISSUES
//   1) Low-level mouse hook procedure does not always initialize (especially if mouse is moving at the time)!
//   2) Low-level mouse handler always sets AMessage.Result to 0 which causes issues for some messages (size form to see what happens)!

// WARNING: Breakpointing in the low-level routines can cause Windows to temporarily/permanently disable the low-level hook!

interface

uses
  Forms,
  Windows,
  Messages,
  Classes,
  Controls,
  StdCtrls,
  ExtCtrls;

type
  TControlDragObject = class(TDragControlObjectEx)
  private
    FControl: TControl;
    FText: string;
  protected
    function GetDragCursor(Accepted: Boolean; X: Integer; Y: Integer): TCursor; override;
  public
    constructor Create(const AControl: TControl; const AText: string); reintroduce;

    property Control: TControl read FControl;
    property Text: string read FText;
  end;

  TDragStateEx =
  (
    dsInactive,
    dsPending,
    dsActive
  );

  TDragObjectsForm = class(TForm)
    btnButton: TButton;
    lblLabel: TLabel;
    edtComboBox: TComboBox;
    edtEdit: TEdit;
    edtMemo: TMemo;
    edtListBox: TListBox;
    grpPanel: TPanel;
    lblDragMode: TLabel;
    edtAutomaticDragMode: TRadioButton;
    edtManualDragMode: TRadioButton;
    lblLog: TLabel;
    edtLiveInfo: TLabel;
    edtLog: TMemo;
    procedure grpPanelDragOver(Sender: TObject; Source: TObject; X: Integer; Y: Integer; State: TDragState; var Accept: Boolean);
    procedure grpPanelDragDrop(Sender: TObject; Source: TObject; X: Integer; Y: Integer);
    procedure edtAutomaticDragModeClick(Sender: TObject);
    procedure edtManualDragModeClick(Sender: TObject);
  private
    FDragSourceArray: array of TControl;

    procedure ControlStartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure ListBoxStartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure ControlEndDrag(Sender: TObject; Target: TObject; X: Integer; Y: Integer);
  private
    FLowLevelMouseHandler: HWND;

    FDragMode: TDragMode;
    FDragState: TDragStateEx;
    FDragStart: TPoint;
    FDragSource: TControl;
    FDragObject: TControlDragObject;

    procedure LowLevelMouseHandler(var AMessage: TMessage);

    function CreateDragObject(const AControl: TControl; const AText: string): TDragObject;
    procedure DestroyDragObject(const ADrop: Boolean = False);

    procedure SetDragModeEx(const ADragMode: TDragMode);
  private
    procedure Log(const AText: string);
    procedure LogLiveInfo(const AMouseScreenPosition: TPoint);
    procedure RefreshLiveInfo;

    function ObjectAsString(const AObject: TObject): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  Types,
  SysUtils;

type
  TControlAccess = class(TControl);

  TMouseLowLevelHookStruct = record // TODO: Replace with VCL equivalent type
    pt: TPoint;
    mouseData: Cardinal;
    flags: Cardinal;
    time: Cardinal;
    dwExtraInfo: Cardinal;
  end;

  PMouseLowLevelHookStruct = ^TMouseLowLevelHookStruct;

const
  GLowLevelMouseHookDataIndexMin = 0;
  GLowLevelMouseHookDataIndexMax = 7;
  GLowLevelMouseHookDataIndexMod = GLowLevelMouseHookDataIndexMax + 1;

var
  GLowLevelMouseHandler: HWND;
  GLowLevelMouseHookProc: Cardinal;
  GLowLevelMouseHookDataIndex: Integer = GLowLevelMouseHookDataIndexMin;
  GLowLevelMouseHookDataArray: array[GLowLevelMouseHookDataIndexMin..GLowLevelMouseHookDataIndexMax] of TMouseLowLevelHookStruct; // Using a circular buffer instead of a mutex

{$R *.dfm}

function LowLevelMouseHookProc(nCode: Integer; wParam: Integer; lParam: Integer): Integer; stdcall;
var
  LPLnfo: PMouseLowLevelHookStruct absolute lParam;
  LIndex: Integer;
begin
  Result := CallNextHookEx(GLowLevelMouseHookProc, nCode, wParam, lParam);

  if GLowLevelMouseHandler <> 0 then
  begin
    LIndex := GLowLevelMouseHookDataIndex;
    GLowLevelMouseHookDataArray[LIndex] := LPLnfo^;
    GLowLevelMouseHookDataIndex := (LIndex + 1) mod GLowLevelMouseHookDataIndexMod;

    PostMessage(GLowLevelMouseHandler, wParam, wParam, Integer(@GLowLevelMouseHookDataArray[LIndex]));
  end;
end;

{ TControlDragObject }

constructor TControlDragObject.Create(const AControl: TControl; const AText: string);
begin
  inherited Create(AControl);

  FControl := AControl;
  FText := AText;
end;

function TControlDragObject.GetDragCursor(Accepted: Boolean; X: Integer; Y: Integer): TCursor;
begin
  if Accepted then
  begin
    Result := TControlAccess(FControl).DragCursor;
  end else
  begin
    Result := inherited GetDragCursor(False, X, Y);
  end;
end;

{ TDragObjectsForm }

constructor TDragObjectsForm.Create(AOwner: TComponent);

  procedure __InitializeDragHandlers;
  var
    LIndex: Integer;
    LControl: TControl;
    LControlAccess: TControlAccess;
  begin
    for LIndex := Low(FDragSourceArray) to High(FDragSourceArray) do
    begin
      LControl := FDragSourceArray[LIndex];
      LControlAccess := TControlAccess(LControl);

      if not (LControl is TListBox) then
      begin
        LControlAccess.OnStartDrag := ControlStartDrag;
      end else
      begin
        LControlAccess.OnStartDrag := ListBoxStartDrag;
      end;

      LControlAccess.OnEndDrag := ControlEndDrag;
    end;
  end;

begin
  inherited;

  SetLength(FDragSourceArray, 6);
  FDragSourceArray[0] := btnButton;
  FDragSourceArray[1] := lblLabel;
  FDragSourceArray[2] := edtComboBox;
  FDragSourceArray[3] := edtEdit;
  FDragSourceArray[4] := edtMemo;
  FDragSourceArray[5] := edtListBox;

  __InitializeDragHandlers;
  edtAutomaticDragMode.Checked := True; // Triggers change event which in turn sets up individual drag modes

  FLowLevelMouseHandler := AllocateHWnd(LowLevelMouseHandler);
  GLowLevelMouseHandler := FLowLevelMouseHandler;
end;

destructor TDragObjectsForm.Destroy;
begin
  GLowLevelMouseHandler := 0;
  DeallocateHWnd(FLowLevelMouseHandler);

  SetLength(FDragSourceArray, 0);

  inherited;
end;

procedure TDragObjectsForm.Log(const AText: string);
begin
  edtLog.Lines.Append(AText);
  RefreshLiveInfo;
end;

procedure TDragObjectsForm.LogLiveInfo(const AMouseScreenPosition: TPoint);
const
  CDragState: array[TDragStateEx] of string =
  (
     'Inactive',
     'Pending',
     'Active'
  );

var
  LState: string;
begin
  if FDragMode = dmAutomatic then
  begin
    LState := 'Automatic'
  end else
  begin
    LState := 'Manual (' + CDragState[FDragState] + ')';
  end;

  edtLiveInfo.Caption := LState + ' at ' + IntToStr(AMouseScreenPosition.X) + ', ' + IntToStr(AMouseScreenPosition.Y);
end;

procedure TDragObjectsForm.RefreshLiveInfo;
begin
  LogLiveInfo(ClientToScreen(Mouse.CursorPos));
end;

procedure TDragObjectsForm.LowLevelMouseHandler(var AMessage: TMessage);

  procedure __ProcessMouseDown(const AData: TMouseLowLevelHookStruct; const AButton: TMouseButton);

    function __IsSourceControl(const AControl: TControl): Boolean;
    var
      LIndex: Integer;
      LControl: TControl;
    begin
      for LIndex := Low(FDragSourceArray) to High(FDragSourceArray) do
      begin
        LControl := FDragSourceArray[LIndex];

        if LControl = AControl then
        begin
          Result := True;
          Exit; // ==>
        end;
      end;

      Result := False;
    end;

  const
    CMouseButton: array[TMouseButton] of string =
    (
      'Left',
      'Right',
      'Middle'
    );
  var
    LPoint: TPoint;
    LControl: TControl;
  begin
    LPoint := AData.pt;
    LControl := ControlAtPos(ScreenToClient(LPoint), False, True, True);

    if (not Assigned(LControl)) or (not __IsSourceControl(LControl)) then
    begin
      Exit; // ==>
    end;

    Log('__ProcessMouseDown(Control = ' + ObjectAsString(LControl) + ', Button = ' + CMouseButton[AButton] + ')');

    if TControlAccess(LControl).DragMode = dmAutomatic then
    begin
      Exit; // ==>
    end;

    DestroyDragObject;

    if AButton = mbLeft then
    begin
      // NOTE: TControlAccess(LControl).BeginDrag(False) doesn't defer as it should so we have to implement our own!!!
      FDragStart := LPoint;
      FDragSource := LControl;
      FDragState := dsPending;

      RefreshLiveInfo;
    end;
  end;

  procedure __ProcessMouseMove(const AData: TMouseLowLevelHookStruct);
  var
    LPoint: TPoint;
  begin
    if (FDragState <> dsPending) or (not Assigned(FDragSource)) or (TControlAccess(FDragSource).DragMode <> dmManual) then
    begin
      Exit; // ==>
    end;

    LPoint := AData.pt;

    if not TPoint.PointInCircle(LPoint, FDragStart, Mouse.DragThreshold) then
    begin
      FDragState := dsActive;
      FDragSource.BeginDrag(True);
    end;
  end;

var
  LInfo: TMouseLowLevelHookStruct;
  LButton: TMouseButton;
  LPoint: TPoint;
begin
  AMessage.Result := 0; // WRONG! Must not be done for some messages - size form to see why!!!

  case AMessage.Msg of
    WM_LBUTTONDOWN:
    begin
      LButton := mbLeft;
    end;
    WM_MBUTTONDOWN:
    begin
      LButton := mbMiddle;
    end;
    WM_RBUTTONDOWN:
    begin
      LButton := mbRight;
    end;
    WM_MOUSEMOVE:
    begin
      LButton := Low(LButton); // Keep compiler happy
    end;
  else
    Exit; // ==>
  end;

  LInfo := PMouseLowLevelHookStruct(AMessage.LParam)^;

  LPoint := LInfo.pt;
  LogLiveInfo(LPoint);

  case AMessage.Msg of
    WM_LBUTTONDOWN,
    WM_MBUTTONDOWN,
    WM_RBUTTONDOWN:
    begin
      __ProcessMouseDown(LInfo, LButton);
    end;
    WM_MOUSEMOVE:
    begin
      __ProcessMouseMove(LInfo);
    end;
  end;
end;

function TDragObjectsForm.ObjectAsString(const AObject: TObject): string;
begin
  if not Assigned(AObject) then
  begin
    Result := 'nil';
    Exit; // ==>
  end;

  Result := AObject.ClassName;

  if AObject is TControl then
  begin
    Result := Result + ' "' + TControl(AObject).Name + '"';
  end;
end;

function TDragObjectsForm.CreateDragObject(const AControl: TControl; const AText: string): TDragObject;
var
  LText: string;
begin
  LText := Trim(AText);
  Log('CreateDragObject(' + ObjectAsString(AControl) + ', ' + LText + ')');

  Assert(not Assigned(FDragObject));
  FDragObject := TControlDragObject.Create(AControl, LText);
  Result := FDragObject;
end;

procedure TDragObjectsForm.DestroyDragObject(const ADrop: Boolean);
const
  CBoolean: array[Boolean] of string =
  (
    'False',
    'True'
  );
begin
  Log('DestroyDragObject(Drop = ' + CBoolean[ADrop] + ')');

  if (FDragState = dsActive) and Assigned(FDragSource) and (TControlAccess(FDragSource).DragMode = dmManual) then
  begin
    FDragSource.EndDrag(ADrop);
  end;

  FDragSource := nil;

  if FDragObject is TDragControlObjectEx then
  begin
    FDragObject := nil; // TDragControlObjectEx is automatically destroyed
  end else
  begin
    FreeAndNil(FDragObject);
  end;

  FDragState := dsInactive;
end;

procedure TDragObjectsForm.SetDragModeEx(const ADragMode: TDragMode);
const
  CDragMode: array[TDragMode] of string =
  (
     'Manual',
     'Automatic'
  );

var
  LIndex: Integer;
  LControl: TControlAccess;
begin
  Log('SetDragModeEx(' + CDragMode[ADragMode] + ')');
  FDragMode := ADragMode;

  for LIndex := Low(FDragSourceArray) to High(FDragSourceArray) do
  begin
    LControl := TControlAccess(FDragSourceArray[LIndex]);
    LControl.DragMode := ADragMode;
  end;
end;

procedure TDragObjectsForm.ControlStartDrag(Sender: TObject; var DragObject: TDragObject);
begin
  Log('ControlStartDrag(Sender = ' + ObjectAsString(Sender) + ')');
  DragObject := CreateDragObject(Sender as TControl, TControlAccess(Sender).Caption);
end;

procedure TDragObjectsForm.ControlEndDrag(Sender: TObject; Target: TObject; X: Integer; Y: Integer);
begin
  Log('ControlEndDrag(Sender = ' + ObjectAsString(Sender) + ', Target = ' + ObjectAsString(Target) + ')');
  DestroyDragObject;
end;

procedure TDragObjectsForm.ListBoxStartDrag(Sender: TObject; var DragObject: TDragObject);
var
  LListBox: TListBox;
  LText: string;
begin
  Log('ListBoxStartDrag(Sender = ' + ObjectAsString(Sender) + ')');
  LListBox := Sender as TListBox;

  if (LListBox.Items.Count = 0) or (LListBox.ItemIndex = -1) then
  begin
    LText := '<' + ObjectAsString(LListBox) + '>';
  end else
  begin
    LText := LListBox.Items[LListBox.ItemIndex];
  end;

  DragObject := CreateDragObject(LListBox, LText);
end;

procedure TDragObjectsForm.grpPanelDragOver(Sender: TObject; Source: TObject; X: Integer; Y: Integer; State: TDragState; var Accept: Boolean);
begin
  // It is tempting to write this...
  // Accept := Source is TControlDragObject
  // ... We are, however, advised to instead write this...
  Accept := IsDragObject(Source);
  RefreshLiveInfo;
end;

procedure TDragObjectsForm.grpPanelDragDrop(Sender: TObject; Source: TObject; X: Integer; Y: Integer);
begin
  Log('grpPanelDragDrop(Sender = ' + ObjectAsString(Sender) + ', Source = ' + ObjectAsString(Source) + ')');

  // The OnDragOver event handler verified we are dealing with a drag object so there is no chance of getting a normal control
  (Sender as TPanel).Caption := (Source as TControlDragObject).Text;
  DestroyDragObject(True);
end;

procedure TDragObjectsForm.edtAutomaticDragModeClick(Sender: TObject);
begin
  SetDragModeEx(dmAutomatic);
  RefreshLiveInfo;
end;

procedure TDragObjectsForm.edtManualDragModeClick(Sender: TObject);
begin
  SetDragModeEx(dmManual);
  RefreshLiveInfo;
end;

initialization
  GLowLevelMouseHookProc := SetWindowsHookEx(WH_MOUSE_LL, @LowLevelMouseHookProc, hInstance, 0);

finalization
  UnhookWindowsHookEx(GLowLevelMouseHookProc);

end.