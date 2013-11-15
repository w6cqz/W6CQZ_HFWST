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
   d65rxIBuffer    : Packed Array[0..661503] of CTypes.cint16;   // Frame sample buffer (V3 integer)
   adclast2k1      : Packed Array[0..2047] of CTypes.cint16;     // For computing audio levels
   adclast4k1      : Packed Array[0..4095] of CTypes.cint16;     // For computing spectrum
   d65rxBufferIdx  : Integer;
   adcChan         : Integer;  // 1 = Left, 2 = Right
   adcFirst        : Boolean;  // Flag so I can init some things on first call to this
   adcRunning      : Boolean;
   adcLDgain       : Integer;
   adcRDgain       : Integer;
   adcECount       : Integer;
   adcTick         : CTypes.cuint;
   adcMono         : Boolean;
   auIDX           : Integer;
   specIDX         : Integer;
   haveAU          : Boolean; // Flag indicating 2048 samples ready for audio level computation
   haveSpec        : Boolean; // Flag indicating 4096 samples ready for spectrum computation

implementation

function adcCallback(input: Pointer; output: Pointer; frameCount: Longword;
                       timeInfo: PPaStreamCallbackTimeInfo;
                       statusFlags: TPaStreamCallbackFlags;
                       inputDevice: Pointer): Integer; cdecl;
Var
   i,z,lpidx   : Integer;
   inptr       : ^smallint;
   tempInt1    : smallint;
   localIdx    : Integer;
Begin
     Try
        if adcRunning Then
        Begin
             inc(adcECount);  // Looking for any recursive calls to this - i.e. overruns.
        end;
        if adcFirst Then
        Begin
             for i := 0 to 661503 do
             begin
                  d65rxIBuffer[i] := 0;
             end;
             adcFirst := False;
        end;
        adcRunning := True;
        // Move paAudio Buffer to d65rxBuffer (d65rxBufferIdx ranges 0..661503)
        inptr := input;
        localIdx := d65rxBufferIdx;
        // Now I need to copy the frames to real rx buffer
        // Don't get confused remembering OLD OLD things - framecount is now 64 samples per callback NOT 2048 :)
        // By the way.... at 64 samples per frame (11025 S/S) this routine is called every ~5.805 mS best not
        // get too greedy here doing things.
        lpidx := 0;
        // Get count of samples to process now so I can reference it
        z := framecount;
        For i := 0 to z-1 do
        Begin
             if localIdx > 661503 Then localIdx       := 0;
             if localIdx > 661503 Then d65rxBufferIdx := 0;
             if auIDX >      2047 Then auIDX          := 0;
             if specIDX >    4095 Then specIDX        := 0;
             // Save samples to mono buffer (1) or left if not running in mono samples mode
             if adcMono Then
             Begin
                  tempint1 := inptr^;
                  inc(inptr);
                  d65rxIBuffer[localIdx] := min(32766,max(-32766,tempint1)); // Left or mono
                  // Update both streams audio level and spectrum buffers - solves an oddity
                  // when switching for those 2 functions.
                  if not haveAU Then adclast2k1[auIDX] := d65rxIBuffer[localIdx];
                  if not haveSpec Then adclast4k1[specIDX] := d65rxIBuffer[localIdx];
             end
             else
             begin
                  tempint1 := inptr^;
                  inc(inptr);
                  d65rxIBuffer[localIdx] := min(32766,max(-32766,tempint1)); // Left or mono
                  // Must read the next if in stereo regardless of selected channel
                  tempint1 := inptr^;
                  inc(inptr);
                  // Process for the right channel (buffer2)
                  if adcChan = 2 Then
                  begin
                       d65rxIBuffer[localIdx] := min(32766,max(-32766,tempint1)); // Left or mono
                  end;
                  // Update both streams audio level and spectrum buffers - solves an oddity
                  // when switching for those 2 functions.
                  if not haveAU Then adclast2k1[auIDX] := d65rxIBuffer[localIdx];
                  if not haveSpec Then adclast4k1[specIDX] := d65rxIBuffer[localIdx];
             end;
             // Update index values
             inc(d65rxBufferIdx);
             inc(localIdx);
             inc(auIDX);
             inc(specIDX);
             inc(lpidx);
             // Flags for spectrum/audio level computations
             if auIDX = 2048 then haveAU := True;
             if specIDX = 4096 then haveSpec := True;
        End;
        result := paContinue;
        z := 0;
        inc(adcTick);
        adcRunning := False;
     except
        inc(adcECount);
     end;
     adcFirst := False;
End;
end.
