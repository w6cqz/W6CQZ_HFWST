unit waterfall2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Spectrum;

function genPNG : Boolean;

implementation
function genPNG : Boolean;
Var
   i,j : Integer;
Begin
  if spectrum.specNewSpec65 Then
  Begin
       Result := True;
  end;
end;

end.

