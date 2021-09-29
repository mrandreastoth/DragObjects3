program DragObjects3;

uses
  Forms,
  UDragObjects3Form in 'UDragObjects3Form.pas' {DragObjectsForm};

{$R *.res}

var
  DragObjectsForm: TDragObjectsForm;

begin
  Application.Initialize;
  Application.CreateForm(TDragObjectsForm, DragObjectsForm);
  Application.Run;
end.
