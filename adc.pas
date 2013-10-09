// (c) 2013 CQZ Electronics
{
   Added BPF filtering here
   Removed integer buffers for samples - all FP now other than audio level/spectrum
   Cleaned up buffering - now using one FP buffer and only running BPF for stream
   actually being used.  Still computing audio level for both channels (unless it's
   running mono) and saving spectrum samples for both.  This is *necessary* for
   spectrum - otherwise it doesn't gracefully switch audio channels on the fly.
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

Const
  //// 19 pole butterworth LPF - good for < ~2.5KHz (this is an IIR type)
  //LACoef : array[0..19] of CTypes.cfloat =
  //      (
  //      0.00001939180997620892,
  //      0.00036844438954796945,
  //      0.00331599950593172540,
  //      0.01879066386694644400,
  //      0.07516265546778577700,
  //      0.22548796640335733000,
  //      0.52613858827450044000,
  //      0.97711452108121499000,
  //      1.46567178162182250000,
  //      1.79137662198222760000,
  //      1.79137662198222760000,
  //      1.46567178162182250000,
  //      0.97711452108121499000,
  //      0.52613858827450044000,
  //      0.22548796640335733000,
  //      0.07516265546778577700,
  //      0.01879066386694644400,
  //      0.00331599950593172540,
  //      0.00036844438954796945,
  //      0.00001939180997620892
  //      );
  //
  //LBCoef : array[0..19] of CTypes.cfloat =
  //      (
  //      1.00000000000000000000,
  //      0.30124524681121684000,
  //      2.62368718667596430000,
  //      0.68183386600980578000,
  //      2.71043558836035330000,
  //      0.59957920836218892000,
  //      1.42524899306136610000,
  //      0.26375059355045877000,
  //      0.41246083660156979000,
  //      0.06237667312611505600,
  //      0.06644496002297710400,
  //      0.00794483191686967340,
  //      0.00575615778774987010,
  //      0.00051759803100776295,
  //      0.00024561616410988675,
  //      0.00001526235709911922,
  //      0.00000429882913347158,
  //      0.00000015515020059209,
  //      0.00000001973933115243,
  //      0.00000000023001431849
  //      );

  // 19 pole butterworth LPF - good for CO = 1/4 SR = 2756 [Optimal design] (this is an IIR type)
  LACoef : array[0..19] of CTypes.cfloat =
        (
        0.00001504924358515241,
        0.00028593562811789571,
        0.00257342065306106170,
        0.01458271703401268200,
        0.05833086813605072700,
        0.17499260440815217000,
        0.40831607695235511000,
        0.75830128576865941000,
        1.13745192865298920000,
        1.39021902390920890000,
        1.39021902390920890000,
        1.13745192865298920000,
        0.75830128576865941000,
        0.40831607695235511000,
        0.17499260440815217000,
        0.05833086813605072700,
        0.01458271703401268200,
        0.00257342065306106170,
        0.00028593562811789571,
        0.00001504924358515241
        );

  LBCoef : array[0..19] of CTypes.cfloat =
        (
        1.00000000000000000000,
        -0.00172140060578456350,
        2.58205258076210150000,
        -0.00387612261833999690,
        2.62901750972755680000,
        -0.00339245230819233820,
        1.36436790682869200000,
        -0.00148588057502895760,
        0.39015462773882825000,
        -0.00035002233370319774,
        0.06217321075439868900,
        -0.00004442085147844632,
        0.00533318808198796150,
        -0.00000288440090482224,
        0.00022553102456804476,
        -0.00000008479405243348,
        0.00000391505248428130,
        -0.00000000085957849110,
        0.00000001784290450798,
        -0.00000000000127108861
        );


  // 3 pole butterworth HPF - good for > ~400Hz (This is an IIR type)
  HACoef : array[0..3] of CTypes.cfloat =
      (
      0.79309546371795214000,
      -2.37928639115385640000,
      2.37928639115385640000,
      -0.79309546371795214000
      );
  HBCoef : array[0..3] of CTypes.cfloat =
      (
      1.00000000000000000000,
      -2.54502682052873870000,
      2.18780625843708300000,
      -0.63322898404546324000
      );

Var
   d65rxFBuffer    : Packed Array[0..661503] of CTypes.cfloat;   // Frame sample buffer
   adclast2k1      : Packed Array[0..2047] of CTypes.cint16;     // For computing audio levels
   adclast2k2      : Packed Array[0..2047] of CTypes.cint16;
   adclast4k1      : Packed Array[0..4095] of CTypes.cint16;     // For computing spectrum
   adclast4k2      : Packed Array[0..4095] of CTypes.cint16;
   l1x,l1y,h1x,h1y : Array[0..19] of CTypes.cfloat;              // IIR accumulators
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

function bpf(input : CTypes.cint16) : CTypes.Cfloat;
Var
   hf          : CTypes.cfloat;
   k : Integer;
Begin
     // Dropping HPF seems to have helped bring decoder back closer to old wsjt
     // standards.  Watching closely.  It seems to help but still not as solid
     // as the old implementation.
     // HPF 3rd order also converts int16 to float
     // Shift old samples in x[] and y[]
     //for k := 3 downto 1 do
     //begin
     //     h1x[k] := h1x[k-1];
     //     h1y[k] := h1y[k-1];
     //end;
     // Calculate new sample
     //h1x[0] := input;
     //h1y[0] := HACoef[0] * h1x[0];

     //for k := 0 to 3 do
     //begin
     //     h1y[0] := h1y[0] + ((HACoef[k] * h1x[k]) - (HBCoef[k] * h1y[k]));
     //end;
     //hf := h1y[0];
     hf := input;

     // LPF 19th order
     // Shift old samples in x[] and y[]
     for k := 19 downto 1 do
     begin
          l1x[k] := l1x[k-1];
          l1y[k] := l1y[k-1];
     end;
     // Calculate new sample
     l1x[0] := hf;
     l1y[0] := LACoef[0] * l1x[0];
     for k := 0 to 19 do
     begin
          l1y[0] := l1y[0] + ((LACoef[k] * l1x[k]) - (LBCoef[k] * l1y[k]));
     end;
     Result := l1y[0];
end;

function adcCallback(input: Pointer; output: Pointer; frameCount: Longword;
                       timeInfo: PPaStreamCallbackTimeInfo;
                       statusFlags: TPaStreamCallbackFlags;
                       inputDevice: Pointer): Integer; cdecl;
Var
   i,z,lpidx : Integer;
   inptr     : ^smallint;
   tempInt1  : smallint;
   tempInt2  : smallint;
   localIdx  : Integer;
Begin
     Try
        if adcRunning Then
        Begin
             inc(adcECount);  // Looking for any recursive calls to this - i.e. overruns.
        end;
        if adcFirst Then
        Begin
             for i := 0 to 19 do
             begin
                  l1x[i] := 0.0;
                  h1x[i] := 0.0;
                  l1y[i] := 0.0;
                  h1y[i] := 0.0;
             end;
             adcFirst := False;
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
        tempInt1 := 0;
        tempInt2 := 0;
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
               tempInt1 := min(32766,max(-32766,tempInt1));
               d65rxFBuffer[localIdx] := bpf(tempInt1);
               if not haveAU Then
               Begin
                    adclast2k1[auIDX] := tempInt1;
                    adclast2k2[auIDX] := tempInt1;
               end;
               if not haveSpec Then
               Begin
                    adclast4k1[specIDX] := tempInt1;
                    adclast4k2[specIDX] := tempInt1;
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
             end
             else
             begin
                  // Read in left then right sample
                  tempInt1 := inptr^;  // Left channel data
                  inc(inptr);
                  tempInt2 := inptr^;  // Right channel data
                  inc(inptr);
                  tempint1 := min(32766,max(-32766,tempInt1));
                  tempint2 := min(32766,max(-32766,tempInt2));
                  if localIdx > 661503 Then localIdx       := 0;
                  if localIdx > 661503 Then d65rxBufferIdx := 0;
                  if auIDX >      2047 Then auIDX          := 0;
                  if specIDX >    4095 Then specIDX        := 0;
                  // Save samples from selected active channel 1L or 2R
                  if adcChan = 1 Then d65rxFBuffer[localIdx] := bpf(tempInt1); // Left
                  if adcChan = 2 Then d65rxFBuffer[localIdx] := bpf(tempInt2); // Right
                  // Update both streams audio level and spectrum buffers - solves an oddity
                  // when switching for those 2 functions.
                  if not haveAU Then
                  Begin
                       adclast2k1[auIDX] := tempInt1;
                       adclast2k2[auIDX] := tempInt2;
                  end;
                  if not haveSpec Then
                  Begin
                       adclast4k1[specIDX] := tempInt1;
                       adclast4k2[specIDX] := tempInt2;
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
             end;
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
