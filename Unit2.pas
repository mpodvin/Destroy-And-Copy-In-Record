unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm2 = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Form2: TForm2;

implementation

uses DestroyRec;

{$R *.dfm}

procedure Test(var X:TDestroyRec);
var
  rec:TDestroyRec;
begin
  rec := TDestroyRec.Create(31415);
  X := rec;
end;

procedure TForm2.Button1Click(Sender: TObject);
var
  rec, recnull, rec3, recnull2 :TDestroyRec;
begin
  rec := TDestroyRec.Create(666);
  rec3 := TDestroyRec.Create(999999);
  recnull := rec;
  recnull := rec3;
  Test(recnull2);
  Test(recnull);
end;

end.
