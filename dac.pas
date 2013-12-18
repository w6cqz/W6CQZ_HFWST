// (c) 2013 CQZ Electronics
unit dac;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CTypes, PortAudio;

function dacCallback(input: Pointer; output: Pointer; frameCount: Longword;
                       timeInfo: PPaStreamCallbackTimeInfo;
                       statusFlags: TPaStreamCallbackFlags;
                       inputDevice: Pointer): Integer; cdecl;

Var
   d65txBuffer           : Packed Array[0..661503] of CTypes.cint16;
   d65txBufferIdx,dacEOD : Integer;
   dacRunning,dacFirst   : Boolean;
   dacECount,dacSOD      : Integer;
   dacTick               : CTypes.cuint;
   dacMono,dacTXOn       : Boolean;

implementation

function dacCallback(input: Pointer; output: Pointer; frameCount: Longword;
                     timeInfo: PPaStreamCallbackTimeInfo;
                     statusFlags: TPaStreamCallbackFlags;
                     inputDevice: Pointer): Integer; cdecl;
Var
   i    : Integer;
   optr : ^smallint;
Begin
     if dacFirst Then
     Begin
          dacTick := 0;
          dacECount := 0;
          if dacSOD = 0 then d65txBufferIdx := 0 else d65txBufferIdx := dacSOD;
          dacSOD := 0;
          dacFirst := False;
     end;
     inc(dacTick);
     if dacRunning Then inc(dacECount);
     dacRunning := True;
     optr := output;
     if dacTXOn Then
     Begin
          // Send real samples
          for i := 0 to frameCount-1 do
          Begin
               optr^ := d65txBuffer[d65txBufferIdx+i];
               inc(optr);
               optr^ := d65txBuffer[d65txBufferIdx+i];
               inc(optr);
          End;
          d65txBufferIdx := d65txBufferIdx+Integer(frameCount);
          if d65txBufferIdx >= dacEOD Then dacTXon := False;
     end
     else
     begin
          // Send silence
          for i := 0 to frameCount-1 do
          Begin
               optr^ := 0;
               inc(optr);
               optr^ := 0;
               inc(optr);
          End;
     end;
     //result := paContinue;
     if dacTXOn Then result := paContinue else result := paComplete;
     dacRunning := False;
End;
end.

