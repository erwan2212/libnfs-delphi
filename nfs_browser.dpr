program nfs_browser;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  libnfs in 'libnfs.pas',
  Unit2 in 'Unit2.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  //Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
