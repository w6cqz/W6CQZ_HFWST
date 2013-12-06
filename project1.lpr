// (c) 2013 CQZ Electronics
program project1;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, lazcontrols, tachartlazaruspkg, Unit1, portaudio, adc,
  spectrum, cmaps, fftw_jl, spot, waterfall1, valobject, rebel, d65, jt65demod;

{$R *.res}

begin
  Application.Title:='HFWST';
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

