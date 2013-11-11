// (c) 2013 CQZ Electronics
program project1;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, tachartlazaruspkg, lazcontrols, Unit1, portaudio, adc,
  spectrum, cmaps, fftw_jl, spot, demodulate, waterfall1, valobject,
  rebel, d65;

{$R *.res}

begin
  Application.Title:='HFWST';
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

