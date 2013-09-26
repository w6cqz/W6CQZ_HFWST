// (c) 2013 CQZ Electronics
unit adc;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, CTypes, PortAudio;

  function adcCallback(input: Pointer; output: Pointer; frameCount: Longword;
                       timeInfo: PPaStreamCallbackTimeInfo;
                       statusFlags: TPaStreamCallbackFlags;
                       inputDevice: Pointer): Integer; cdecl;

Var
   d65rxBuffer1    : Packed Array[0..661503] of CTypes.cint16;   // This is slightly more than 60*11025 to make it evenly divided by 2048
   d65rxBuffer2    : Packed Array[0..661503] of CTypes.cint16;   // This is slightly more than 60*11025 to make it evenly divided by 2048
   adclast2k1      : Packed Array[0..2047] of CTypes.cint16;     // ^^^ 1 holds left ADC channel samples - 2 holds right.
   adclast2k2      : Packed Array[0..2047] of CTypes.cint16;
   adclast4k1      : Packed Array[0..4095] of CTypes.cint16;
   adclast4k2      : Packed Array[0..4095] of CTypes.cint16;
   d65rxBufferIdx  : Integer;
   adcChan         : Integer;  // 1 = Left, 2 = Right
   adcFirst        : Integer;  // Flag so I can init some things on first call to this
   adcRunning      : Boolean;
   adcLDgain       : Integer;
   adcRDgain       : Integer;
   adcECount       : Integer;
   adcTick         : CTypes.cuint;
   adcMono         : Boolean;
   auIDX           : Integer;
   specIDX         : Integer;
   haveAU          : Boolean;
   haveSpec        : Boolean;

implementation

function adcCallback(input: Pointer; output: Pointer; frameCount: Longword;
                       timeInfo: PPaStreamCallbackTimeInfo;
                       statusFlags: TPaStreamCallbackFlags;
                       inputDevice: Pointer): Integer; cdecl;
Var
   i,z,lpidx,jz,nave : Integer;
   inptr             : ^smallint;
   tempInt1          : smallint;
   tempInt2          : smallint;
   localIdx,n        : Integer;
   fsum,ave,sq       : CTypes.cfloat;
Begin
     Try
        if adcRunning Then
        Begin
             inc(adcECount);  // Looking for any recursive calls to this - i.e. overruns.
        end;
        adcRunning := True;
        // Move paAudio Buffer to d65rxBuffer (d65rxBufferIdx ranges 0..661503)
        inptr := input;
        localIdx := d65rxBufferIdx;
        // Now I need to copy the frames to real rx buffer
        z := framecount;
        // Don't get confused remembering OLD OLD things - framecount is now 64 samples per callback NOT 2048 :)
        // By the way.... at 64 samples per frame (11025 S/S) this routine is called every ~5.805 mS best not
        // get too greedy here doing things.
        lpidx := 0;
        For i := 1 to z do
        Begin
             // inptr is a pointer ^ indicates read value at pointer address NOT the pointer's value. :)
             if adcMono Then
             Begin
               // Read in sample
               tempInt1 := inptr^;
               inc(inptr);
               if localIdx > 661503 Then localIdx       := 0;
               if localIdx > 661503 Then d65rxBufferIdx := 0;
               if auIDX >      2047 Then auIDX          := 0;
               if specIDX >    4095 Then specIDX        := 0;
               // Save samples to mono buffer (1)
               d65rxBuffer1[localIdx] := min(32766,max(-32766,tempInt1));
               if not haveAU Then adclast2k1[auIDX] := min(32766,max(-32766,tempInt1));
               if not haveSpec Then adclast4k1[specIDX] := min(32766,max(-32766,tempInt1));
               // Update index values
               inc(d65rxBufferIdx);
               inc(localIdx);
               inc(auIDX);
               inc(specIDX);
               inc(lpidx);
               // Flags for spectrum/audio level computations
               if auIDX = 2048 then haveAU := True;
               if specIDX = 4096 then haveSpec := True;
             end
             else
             begin
                  // Read in left then right sample
                  tempInt1 := inptr^;  // Left channel data
                  inc(inptr);
                  tempInt2 := inptr^;  // Right channel data
                  inc(inptr);
                  if localIdx > 661503 Then localIdx       := 0;
                  if localIdx > 661503 Then d65rxBufferIdx := 0;
                  if auIDX >      2047 Then auIDX          := 0;
                  if specIDX >    4095 Then specIDX        := 0;
                  // Save samples to left (1) and right(2) buffers
                  // Left
                  d65rxBuffer1[localIdx] := min(32766,max(-32766,tempInt1));
                  if not haveAU Then adclast2k1[auIDX] := min(32766,max(-32766,tempInt1));
                  if not haveSpec Then adclast4k1[specIDX] := min(32766,max(-32766,tempInt1));
                  // Right
                  d65rxBuffer2[localIdx] := min(32766,max(-32766,tempInt2));
                  if not haveAU Then adclast2k2[auIDX] := min(32766,max(-32766,tempInt2));
                  if not haveSpec Then adclast4k2[specIDX] := min(32766,max(-32766,tempInt2));
                  // Update index values
                  inc(d65rxBufferIdx);
                  inc(localIdx);
                  inc(auIDX);
                  inc(specIDX);
                  inc(lpidx);
                  // Flags for spectrum/audio level computations
                  if auIDX = 2048 then haveAU := True;
                  if specIDX = 4096 then haveSpec := True;
             end;
        End;
        result := paContinue;
        z := 0;
        inc(adcTick);
        adcRunning := False;
     except
        inc(adcECount);
     end;
End;
end.

