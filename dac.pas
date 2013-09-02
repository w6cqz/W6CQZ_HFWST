// (c) 2013 CQZ Electronics
unit dac;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CTypes, PortAudio, globalData;

function dacCallback(input: Pointer; output: Pointer; frameCount: Longword;
                       timeInfo: PPaStreamCallbackTimeInfo;
                       statusFlags: TPaStreamCallbackFlags;
                       inputDevice: Pointer): Integer; cdecl;

Var
   d65txBuffer    : Packed Array[0..661503] of CTypes.cint16;
   d65txBufferIdx : Integer;
   dacRunning     : Boolean;
   dacECount      : Integer;
   dacTick        : CTypes.cuint;
   dacMono        : Boolean;

implementation

function dacCallback(input: Pointer; output: Pointer; frameCount: Longword;
                     timeInfo: PPaStreamCallbackTimeInfo;
                     statusFlags: TPaStreamCallbackFlags;
                     inputDevice: Pointer): Integer; cdecl;
Var
   i    : Integer;
   optr : ^smallint;
Begin
     inc(dacTick);
     if dacRunning Then inc(dacECount);
     dacRunning := True;
     optr := output;
     if globalData.txInProgress Then
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
          if d65txBufferIdx > 661503 then d65txBufferIdx := 0;
     End
     Else
     Begin
          // Send silence samples
          for i := 0 to frameCount-1 do
          Begin
               optr^ := 0;
               inc(optr);
               optr^ := 0;
               inc(optr);
          End;
     End;
     if globalData.txInProgress Then result := paContinue else result := paComplete;
     dacRunning := False;
End;
end.

