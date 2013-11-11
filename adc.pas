// (c) 2013 CQZ Electronics
{
   Added BPF filtering here
   Removed integer buffers for samples - all FP now other than audio level/spectrum
   Cleaned up buffering - now using one FP buffer and only running BPF for stream
   actually being used.  Still computing audio level for both channels (unless it's
   running mono) and saving spectrum samples for both.  This is *necessary* for
   spectrum - otherwise it doesn't gracefully switch audio channels on the fly.
}

{ TODO : Try Chebyshev LP FIR filter }

{ OK - while doing the filtering here and avoiding the LPF1 issues seen using
  stock K1JT methods fixes some things it breaks others.  I need to find a happy
  medium between the two.  I can have speed, fewer artifact decodes (false hits)
  and less than stellar decode reliability or the opposite.  There has to be a
  mid point - but, for now, I'm going back toward the way it's always been done.
}

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
   d65rxFBuffer    : Packed Array[0..661503] of CTypes.cfloat;   // Frame sample buffer (V5 float)
   d65rxIBuffer    : Packed Array[0..661503] of CTypes.cint16;   // Frame sample buffer (V3 integer)
   adclast2k1      : Packed Array[0..2047] of CTypes.cint16;     // For computing audio levels
   adclast2k2      : Packed Array[0..2047] of CTypes.cint16;
   adclast4k1      : Packed Array[0..4095] of CTypes.cint16;     // For computing spectrum
   adclast4k2      : Packed Array[0..4095] of CTypes.cint16;
   adclast4k1F     : Packed Array[0..4095] of CTypes.cfloat;     // Hopefully these will soon obsolete ^^^
   adclast4k2F     : Packed Array[0..4095] of CTypes.cfloat;
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
   tempInt2    : smallint;
   localIdx    : Integer;
   tAr1,tAr2   : Array[0..2047] of CTypes.cfloat; // Setting these to 2K even though I'm only (now) using 64
   tAr1i,tAr2i : Array[0..2047] of CTypes.cint16; // This is more ecnomical than dynamically allocating/deallocating.
Begin
     Try
        if adcRunning Then
        Begin
             inc(adcECount);  // Looking for any recursive calls to this - i.e. overruns.
        end;
        // Get count of samples to process now so I can reference it
        z := framecount;
        if adcFirst Then
        Begin
             for i := 0 to z-1 do
             begin
                  tAr1[i] := 0.0;
                  tAr2[i] := 0.0;
                  tAr1i[i] := 0;
                  tAr2i[i] := 0;
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
        tempInt1 := 0;
        tempInt2 := 0;
        for i := 0 to z-1 do
        begin
             // Reading in the interger samples to a temporary processing/conversion buffer(s)
             // Still preserving (for now) a copy of integer value for AU and spectrum routines.
             // inptr is a pointer ^ indicates read value at pointer address NOT the pointer's value. :)
             if adcMono Then
             Begin
                  tempInt1 := inptr^;
                  inc(inptr);
                  tAr1[i] := tempInt1;
                  tAr1i[i] := tempInt1;
             end
             else
             begin
                  tempInt1 := inptr^;  // Left channel data
                  inc(inptr);
                  tempInt2 := inptr^;  // Right channel data
                  inc(inptr);
                  tempint1 := min(32766,max(-32766,tempInt1));
                  tempint2 := min(32766,max(-32766,tempInt2));
                  tAr1[i] := tempInt1;
                  tAr2[i] := tempInt2;
                  tAr1i[i] := tempInt1;
                  tAr2i[i] := tempInt1;
             end;
        end;
        // Signal conditioning processing samples here on 64 sample blocks led
        // to a lot of odd stuff... likely discontinuities between the blocks.
        // Moving that back to working on the full blocks of 2K, 4K or full
        // frame in proper places.

        // Copy out the processed callback buffer to the full period buffers
        // and trigger audio/spectrum generation as needed.  No longer keeping
        // a left and right buffer.  Main program feeds from d65rxFBuffer and
        // regardless of mono, stereo left or stereo right it gets the next
        // sample in line.
        For i := 0 to z-1 do
        Begin
             if localIdx > 661503 Then localIdx       := 0;
             if localIdx > 661503 Then d65rxBufferIdx := 0;
             if auIDX >      2047 Then auIDX          := 0;
             if specIDX >    4095 Then specIDX        := 0;
             // Save samples to mono buffer (1) or left if not running in mono samples mode
             d65rxFBuffer[localIdx] := tAr1[i]; // Left or mono
             d65rxIBuffer[localIdx] := tAr1i[i]; // Left or mono
             if adcMono Then
             Begin
                  // Update both streams audio level and spectrum buffers - solves an oddity
                  // when switching for those 2 functions.
                  if not haveAU Then
                  Begin
                       adclast2k1[auIDX] := tAr1i[i];
                       adclast2k2[auIDX] := tAr1i[i]; // This is correct for a mono stream
                  end;
                  if not haveSpec Then
                  Begin
                       adclast4k1[specIDX] := tAr1i[i];
                       adclast4k2[specIDX] := tAr1i[i]; // This is correct for a mono stream
                       adclast4k1F[specIDX] := tAr1[i];
                       adclast4k2F[specIDX] := tAr1[i]; // This is correct for a mono stream
                  end;
             end
             else
             begin
                  // Process for the right channel (buffer2)
                  if adcChan = 2 Then
                  begin
                       d65rxFBuffer[localIdx] := tAr2[i]; // Right (If it's left then that was handled above)
                       d65rxIBuffer[localIdx] := tAr2i[i]; // Left or mono
                  end;
                  // Update both streams audio level and spectrum buffers - solves an oddity
                  // when switching for those 2 functions.
                  if not haveAU Then
                  Begin
                       adclast2k1[auIDX] := tAr1i[i];
                       adclast2k2[auIDX] := tAr2i[i];
                  end;
                  if not haveSpec Then
                  Begin
                       adclast4k1[specIDX] := tAr1i[i];
                       adclast4k2[specIDX] := tAr2i[i];
                       adclast4k1F[specIDX] := tAr1[i];
                       adclast4k2F[specIDX] := tAr2[i];
                  end;
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
