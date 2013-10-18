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
  // 11th Order Chebyshew 255 Tap LP @ 11025 SR - Cut = 2756.25 FIR
  FCoef : array[0..254] of CTypes.cfloat =
  (
  0.00000196757215275783,
  0.00000015909830563925,
  -0.00000636107038511026,
  -0.00000002764514766958,
  0.00001140937180536214,
  -0.00000046404458333580,
  -0.00001716632208737237,
  0.00000139541719905245,
  0.00002368714715710445,
  -0.00000285667994955854,
  -0.00003102808522890891,
  0.00000494987769911287,
  0.00003924594313568119,
  -0.00000779004990492034,
  -0.00004839756849111534,
  0.00001150647079774932,
  0.00005853922860370182,
  -0.00001624397499079908,
  -0.00006972588641686627,
  0.00002216436974737849,
  0.00008201036282146327,
  -0.00002944793379778784,
  -0.00009544237375100093,
  0.00003829500080373196,
  0.00011006742910354640,
  -0.00004892762325852024,
  -0.00012592557890745657,
  0.00006159130965326839,
  0.00014304998998547374,
  -0.00007655682408584918,
  -0.00016146533361976413,
  0.00009412203272366248,
  0.00018118596115898353,
  -0.00011461377562838413,
  -0.00020221383984711882,
  0.00013838973477501573,
  0.00022453621467021225,
  -0.00016584025908366934,
  -0.00024812295305169592,
  0.00019739009473279982,
  0.00027292351579717635,
  -0.00023349995332465012,
  -0.00029886347761529580,
  0.00027466783232152385,
  0.00032584049113504809,
  -0.00032142998395757441,
  -0.00035371954566634046,
  0.00037436141413300071,
  0.00038232731443063606,
  -0.00043407578827598151,
  -0.00041144531266807993,
  0.00050122463573486523,
  0.00044080150791335953,
  -0.00057649578362871335,
  -0.00047005994592866601,
  0.00066061101903909460,
  0.00049880790014098300,
  -0.00075432306949648441,
  -0.00052654004085697930,
  0.00085841207524993835,
  0.00055263918145123105,
  -0.00097368174322317951,
  -0.00057635329111915086,
  0.00110095521324815790,
  0.00059676858451880143,
  -0.00124107019777413060,
  -0.00061277838967002608,
  0.00139487215120215270,
  0.00062304677859081285,
  -0.00156320331187844970,
  -0.00062596425554381941,
  0.00174688499976825620,
  0.00061959011360968985,
  -0.00194669123030158160,
  -0.00060157276804716111,
  0.00216331373907683230,
  0.00056903548320860124,
  -0.00239732212173931820,
  -0.00051840914477902997,
  0.00264913122840051450,
  0.00044518648742603723,
  -0.00291900831405756370,
  -0.00034357212663010082,
  0.00320719011157018920,
  0.00020603209380282240,
  -0.00351422363013585920,
  -0.00002283809632525611,
  0.00384163340051001810,
  -0.00021815107971262561,
  -0.00419283241425586100,
  0.00053122709884257258,
  0.00457394688639651670,
  -0.00093212285647972445,
  -0.00499426484979621340,
  0.00143714253492770170,
  0.00546637649680928320,
  -0.00206225526593976270,
  -0.00600638220005058830,
  0.00282179176856083360,
  0.00663562754433745340,
  -0.00372107308332907940,
  -0.00737614143641260410,
  0.00474304433737914210,
  0.00822234813392190220,
  -0.00585646116052898450,
  -0.00909759638351029070,
  0.00708268876014754660,
  0.00987066140591091700,
  -0.00853979734680612720,
  -0.01033963681091273000,
  0.01065157846427118400,
  0.01055418400609691100,
  -0.01405668084741708100,
  -0.01130097747832729500,
  0.01862381273566918900,
  0.01343425204952298000,
  -0.02224058600905436100,
  -0.01299469858232347100,
  0.03023337934523219100,
  0.01417243795062225900,
  -0.04098925350311821000,
  -0.01471259421852221500,
  0.06017388327738771400,
  0.01521605440792269500,
  -0.10356498058600246000,
  -0.01553515494233502300,
  0.31584202575474801000,
  0.51279803508335442000,
  0.31584202575474801000,
  -0.01553515494233502300,
  -0.10356498058600246000,
  0.01521605440792269500,
  0.06017388327738771400,
  -0.01471259421852221500,
  -0.04098925350311821000,
  0.01417243795062225900,
  0.03023337934523219100,
  -0.01299469858232347100,
  -0.02224058600905436100,
  0.01343425204952298000,
  0.01862381273566918900,
  -0.01130097747832729500,
  -0.01405668084741708100,
  0.01055418400609691100,
  0.01065157846427118400,
  -0.01033963681091273000,
  -0.00853979734680612720,
  0.00987066140591091700,
  0.00708268876014754660,
  -0.00909759638351029070,
  -0.00585646116052898450,
  0.00822234813392190220,
  0.00474304433737914210,
  -0.00737614143641260410,
  -0.00372107308332907940,
  0.00663562754433745340,
  0.00282179176856083360,
  -0.00600638220005058830,
  -0.00206225526593976270,
  0.00546637649680928320,
  0.00143714253492770170,
  -0.00499426484979621340,
  -0.00093212285647972445,
  0.00457394688639651670,
  0.00053122709884257258,
  -0.00419283241425586100,
  -0.00021815107971262561,
  0.00384163340051001810,
  -0.00002283809632525611,
  -0.00351422363013585920,
  0.00020603209380282240,
  0.00320719011157018920,
  -0.00034357212663010082,
  -0.00291900831405756370,
  0.00044518648742603723,
  0.00264913122840051450,
  -0.00051840914477902997,
  -0.00239732212173931820,
  0.00056903548320860124,
  0.00216331373907683230,
  -0.00060157276804716111,
  -0.00194669123030158160,
  0.00061959011360968985,
  0.00174688499976825620,
  -0.00062596425554381941,
  -0.00156320331187844970,
  0.00062304677859081285,
  0.00139487215120215270,
  -0.00061277838967002608,
  -0.00124107019777413060,
  0.00059676858451880143,
  0.00110095521324815790,
  -0.00057635329111915086,
  -0.00097368174322317951,
  0.00055263918145123105,
  0.00085841207524993835,
  -0.00052654004085697930,
  -0.00075432306949648441,
  0.00049880790014098300,
  0.00066061101903909460,
  -0.00047005994592866601,
  -0.00057649578362871335,
  0.00044080150791335953,
  0.00050122463573486523,
  -0.00041144531266807993,
  -0.00043407578827598151,
  0.00038232731443063606,
  0.00037436141413300071,
  -0.00035371954566634046,
  -0.00032142998395757441,
  0.00032584049113504809,
  0.00027466783232152385,
  -0.00029886347761529580,
  -0.00023349995332465012,
  0.00027292351579717635,
  0.00019739009473279982,
  -0.00024812295305169592,
  -0.00016584025908366934,
  0.00022453621467021225,
  0.00013838973477501573,
  -0.00020221383984711882,
  -0.00011461377562838413,
  0.00018118596115898353,
  0.00009412203272366248,
  -0.00016146533361976413,
  -0.00007655682408584918,
  0.00014304998998547374,
  0.00006159130965326839,
  -0.00012592557890745657,
  -0.00004892762325852024,
  0.00011006742910354640,
  0.00003829500080373196,
  -0.00009544237375100093,
  -0.00002944793379778784,
  0.00008201036282146327,
  0.00002216436974737849,
  -0.00006972588641686627,
  -0.00001624397499079908,
  0.00005853922860370182,
  0.00001150647079774932,
  -0.00004839756849111534,
  -0.00000779004990492034,
  0.00003924594313568119,
  0.00000494987769911287,
  -0.00003102808522890891,
  -0.00000285667994955854,
  0.00002368714715710445,
  0.00000139541719905245,
  -0.00001716632208737237,
  -0.00000046404458333580,
  0.00001140937180536214,
  -0.00000002764514766958,
  -0.00000636107038511026,
  0.00000015909830563925,
  0.00000196757215275783
  );

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
Var
   d65rxFBuffer    : Packed Array[0..661503] of CTypes.cfloat;   // Frame sample buffer
   adclast2k1      : Packed Array[0..2047] of CTypes.cint16;     // For computing audio levels
   adclast2k2      : Packed Array[0..2047] of CTypes.cint16;
   adclast4k1      : Packed Array[0..4095] of CTypes.cint16;     // For computing spectrum
   adclast4k2      : Packed Array[0..4095] of CTypes.cint16;
   adclast4k1F     : Packed Array[0..4095] of CTypes.cfloat;     // Hopefully these will soon obsolete ^^^
   adclast4k2F     : Packed Array[0..4095] of CTypes.cfloat;
   l1x,l1y         : Array[0..19] of CTypes.cfloat;              // IIR accumulators
   fx              : Array[0..254] of CTypes.cfloat;             // FIR accumulator
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

function lpf(x : CTypes.cfloat) : CTypes.cfloat;
var
   i : Integer;
   y : CTypes.cfloat;
Begin
     for i := 254 downto 1 do fx[i] := fx[i-1];
     fx[0] := x;
     for i := 0 to 254 do y := y + FCoef[i] * fx[i];
     result := y;
end;

function bpf(input : CTypes.cfloat) : CTypes.Cfloat;
Var
   k : Integer;
Begin
     // LPF 19th order
     // Shift old samples in x[] and y[]
     for k := 19 downto 1 do
     begin
          l1x[k] := l1x[k-1];
          l1y[k] := l1y[k-1];
     end;
     // Calculate new sample
     l1x[0] := input;
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
   i,z,lpidx   : Integer;
   inptr       : ^smallint;
   tempInt1    : smallint;
   tempInt2    : smallint;
   localIdx    : Integer;
   tAr1,tAr2   : Array[0..2047] of CTypes.cfloat; // Setting these to 2K even though I'm only (now) using 64
   tAr1i,tAr2i : Array[0..2047] of CTypes.cint16; // This is more ecnomical than dynamically allocating/deallocating.
   sum,ave     : CTypes.cfloat;
Begin
     Try
        if adcRunning Then
        Begin
             inc(adcECount);  // Looking for any recursive calls to this - i.e. overruns.
        end;
        // Get count of samples to process (doing this early so I can set the array lengths on first pass
        z := framecount;
        if adcFirst Then
        Begin
             for i := 0 to 19 do
             begin
                  l1x[i] := 0.0;
                  l1y[i] := 0.0;
             end;
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
        // Convert tAr1 and (if needed) tAr2 to floating point values like
        // was done in older JT65-HF versions.  Chasing something here....
        // Somewhat better on the decoder now ;)
        // Experiment with running LPF before this.
        // This all seems to be good stuffs... watching it closely though.
        { TODO : Monitor changes in ADC to sample conversion methods }
        // Normalize the samples and remove any DC component
        sum := 0.0;
        ave := 0;
        for i := 0 to z-1 do sum := sum + tAr1[i];
        ave := sum/z;
        for i := 0 to z-1 do tAr1[i] := tAr1[i]-ave;
        sum := 0.0;
        ave := 0.0;
        for i := 0 to z-1 do
        Begin
             tAr1[i] := 0.1 * tAr1[i];
             sum := sum + tAr1[i];
        End;
        ave := sum/z;
        for i := 0 to z-1 do tAr1[i] := tAr1[i]-ave;
        //for i := 0 to z-1 do tAr1[i] := bpf(tAr1[i]);
        //for i := 0 to z-1 do tAr1[i] := lpf(tAr1[i]);
        if not adcMono Then
        Begin
             sum := 0.0;
             ave := 0;
             for i := 0 to z-1 do sum := sum + tAr2[i];
             ave := sum/z;
             for i := 0 to z-1 do tAr2[i] := tAr2[i]-ave;
             sum := 0.0;
             ave := 0.0;
             for i := 0 to z-1 do
             Begin
                  tAr2[i] := 0.1 * tAr2[i];
                  sum := sum + tAr2[i];
             End;
             ave := sum/z;
             for i := 0 to z-1 do tAr2[i] := tAr2[i]-ave;
             //for i := 0 to z-1 do tAr2[i] := bpf(tAr2[i]);
             //for i := 0 to z-1 do tAr2[i] := lpf(tAr2[i]);
        end;
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
                  if adcChan = 2 Then d65rxFBuffer[localIdx] := tAr2[i]; // Right (If it's left then that was handled above)
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
