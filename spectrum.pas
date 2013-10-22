// (c) 2013 CQZ Electronics
unit spectrum;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CTypes, cmaps, fftw_jl, graphics, Math;

Const
  JT_DLL = 'JT65v5.dll';
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

Type
    RGBPixel = Packed Record
             r : Byte;
             g : Byte;
             b : Byte;
    End;

    BMP_Header = Packed Record
               bfType1 : Char ; (* "B" *)
               bfType2 : Char ; (* "M" *)
               bfSize : LongInt ; (* Size of File *)
               bfReserved1 : Word ; (* Zero *)
               bfReserved2 : Word ; (* Zero *)
               bfOffBits : LongInt ; (* Offset to beginning of BitMap *)
               biSize : LongInt ; (* Number of Bytes in Structure *)
               biWidth : LongInt ; (* Width of BitMap in Pixels *)
               biHeight : LongInt ; (* Height of BitMap in Pixels *)
               biPlanes : Word ; (* Planes in target device = 1 *)
               biBitCount : Word ; (* Bits per Pixel 1, 4, 8, or 24 *)
               biCompression : LongInt ; (* BI_RGB = 0, BI_RLE8, BI_RLE4 *)
               biSizeImage : LongInt ; (* Size of Image Part (often ignored) *)
               biXPelsPerMeter : LongInt ; (* Always Zero *)
               biYPelsPerMeter : LongInt ; (* Always Zero *)
               biClrUsed : LongInt ; (* # of Colors used in Palette *)
               biClrImportant : LongInt ; (* # of Colors that are Important *)
    End;

    RGBArray = Array[0..749] of RGBPixel;

//procedure computeSpectrum(Const dBuffer : Array of CTypes.cint16);
procedure computeSpectrum(Const dBuffer : Array of CTypes.cfloat);

function colorMap(Const integerArray : Array of LongInt; Var rgbArray : RGBArray): Boolean;

function computeAudio(Const Buffer : Array of CTypes.cint16): Integer;

procedure flat(ss,n,nsum : Pointer); cdecl;

function chebyLP(const f : CTypes.cfloat) : CTypes.cfloat;

Var
   specDisplayData : Packed Array[0..179]    Of RGBArray;
   specTempSpec1   : Packed Array[0..179]    Of RGBArray;
   bmpD            : Packed Array[0..405359] Of Byte;
   chebyBuff       : Array[0..254] Of CTypes.cfloat;
   specFirstRun    : Boolean;
   specColorMap    : Integer;
   specSpeed2      : Integer;
   specGain        : Integer;
   specVGain       : Integer;
   specContrast    : Integer;
   specfftCount    : Integer;
   specSmooth      : Boolean;
   specagc         : CTypes.cuint64;
   specuseagc      : Boolean;
   audiocomputing  : Boolean;
   spectrumComputing65 : Boolean;
   specNewSpec65   : Boolean;
   specMs65        : TMemoryStream;
implementation

function chebyLP(const f : CTypes.cfloat) : CTypes.cfloat;
Var
   n : Integer;
   y : CTypes.cfloat;
Begin
     //static float x[Ntap]; //input samples
     //float y=0;            //output sample
     //int n;

     //shift the old samples
     //for(n=Ntap-1; n>0; n--)
     //   x[n] = x[n-1];
     for n := 254 downto 1 do chebyBuff[n] := chebyBuff[n-1];

     //Calculate the new output
     //x[0] = NewSample;
     chebyBuff[0] := f;
     //for(n=0; n<Ntap; n++)
     //    y += FIRCoef[n] * x[n];
     for n := 0 to 254 do
     begin
          y := FCoef[n] * chebyBuff[n];
     end;
     //return y;
     result := y;
end;


procedure flat(ss,n,nsum : Pointer); cdecl; external JT_DLL name 'flat2_';

function colorMap(Const integerArray : Array of LongInt; Var rgbArray : RGBArray ): Boolean;
Var
   floatvar : Single;
   i        : Integer;
   intvar   : LongInt;
Begin
     // This routine maps integerArray[0..749] to rgbArray[0..749] in RGB pixel format.
     If specColorMap = 0 Then
     Begin
          for i := 0 to 749 do
          Begin
               floatvar := cmaps.bluecmap1[integerArray[i]];
               floatvar := floatvar * 256; // Red
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].r := intvar;

               floatvar := cmaps.bluecmap2[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].g := intvar;

               floatvar := cmaps.bluecmap3[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].b := intvar;
          End;
     End;
     If specColorMap = 1 Then
     Begin
          for i := 0 to 749 do
          Begin
               floatvar := cmaps.linradcmap1[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].r := intvar;

               floatvar := cmaps.linradcmap2[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].g := intvar;

               floatvar := cmaps.linradcmap3[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].b := intvar;
          End;
     End;
     If specColorMap = 2 Then
     Begin
          for i := 0 to 749 do
          Begin
               floatvar := cmaps.gray0cmap1[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].r := intvar;

               floatvar := cmaps.gray0cmap2[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].g := intvar;

               floatvar := cmaps.gray0cmap3[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].b := intvar;
          End;
     End;
     If specColorMap = 3 Then
     Begin
          for i := 0 to 749 do
          Begin
               floatvar := cmaps.gray1cmap1[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].r := intvar;

               floatvar := cmaps.gray1cmap2[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].g := intvar;

               floatvar := cmaps.gray1cmap3[integerArray[i]];
               floatvar := floatvar * 256;
               intvar := trunc(floatvar);
               if intvar > 255 then intvar := 255;
               rgbArray[i].b := intvar;
          End;
     End;
     Result := True;
End;

function computeAudio(Const Buffer : Array of CTypes.cint16) : Integer;
Var
   lrealArray                 : Array[0..2047] Of CTypes.cfloat;
   fac, rms1, decibel, flevel : CTypes.cfloat;
   dgain, sum, ave, sq, d     : CTypes.cfloat;
   i                          : Integer;
   specLrms                   : CTypes.cfloat;
Begin
     audioComputing := True;
     Try
        Result := 0;
        for i := 0 to 2047 do lrealArray[i] := 0.0;
        fac := 0.0;
        rms1 := 0.0;
        decibel := 0.0;
        flevel := 0.0;
        dgain := 2.0;
        sum := 0.0;
        ave := 0.0;
        sq := 0.0;
        d := 0.0;
        fac := 2.0/10000.0;  // No Idea why... comes from WSJT code and must be so to yield equal result to WSJT audio level computations.
        // Compute S-Meter Level.  Scale = 0-100, steps = .4db
        // Expects 2048 samples in dBuffer[bStart]..dBuffer[bEnd]
        for i := 0 to 2047 do lrealArray[i] := 0.5 * dgain * buffer[i];
        sum := 0;
        for i := 0 to 2047 do
        Begin
             sum := sum + lrealArray[i];
        End;
        ave := sum/2048;
        sq := 0;
        for i := 0 to 2047 do
        Begin
             d := lrealArray[i]-ave;
             sq := sq + d * d;
             lrealArray[i] := fac*d;
        End;
        rms1 := sqrt(sq/2048);
        specLrms := 0;
        if specLrms = 0 Then specLrms := rms1;
        specLrms := 0.25 * rms1 + 0.75 * specLrms;
        if specLrms > 0 Then
        Begin
             decibel := 20 * log10(specLrms/800);
             flevel := 50 + 2.5 * decibel;
             flevel := min(100.0,max(0.0,flevel));
        End;
        Result := trunc(flevel);
     Except
        //dlog.fileDebug('Exception raised in audio level computation');
        Result := 0;
     End;
     audioComputing := False;
End;

procedure computeSpectrum(Const dBuffer : Array of CTypes.cfloat);
Var
   i,x,y,z,intVar,nh,iadj  : CTypes.cint;
   gamma,offset,fi,fvar,pw1,pw2 : CTypes.cfloat;
   rgbSpectra                      : RGBArray;
   doSpec                          : Boolean;
   bmpH                            : BMP_Header;
   Bytes_Per_Raster                : LongInt;
   Raster_Pad, j          : Integer;
   //auBuff65                        : Packed Array[0..4095] Of smallint;
   fftOut65                        : Array[0..2047] of fftw_jl.complex_single;
   //fftIn65,srealArray165           : Array[0..4095] of Single;
   fftIn65                         : Array[0..4095] of Single;
   //lxa,lya,hxa,hya                 : Array[0..19] of Single;
   pfftIn65                        : PSingle;
   pfftOut65                       : fftw_jl.Pcomplex_single;
   p                               : fftw_plan_single;
   ss65,ss65b                      : Array[0..2047] of CTypes.cfloat;
   floatSpectra                    : Array[0..749] of CTypes.cfloat;
   integerSpectra                  : Array[0..749] of CTypes.cint32;
   fsum,fave                       : CTypes.cfloat;

Begin
     // Compute spectrum display.  Expects 4096 samples in dBuffer
     spectrumComputing65 := True;
     nh := 2048;
     If specFirstRun Then
     Begin
          specagc := 0;
          // clear ss65
          for i := 0 to 2047 do
          Begin
               ss65[i] := 0;
          End;
          // clear rgbSpectra
          for i := 0 to 749 do
          Begin
               rgbSpectra[i].r := 0;
               rgbSpectra[i].g := 0;
               rgbSpectra[i].b := 0;
          End;
          // clear lpf accumulators
          //for i := 0 to 19 do
          //begin
               //lxa[i] := 0.0;
               //lya[i] := 0.0;
               //hxa[i] := 0.0;
               //hya[i] := 0.0;
          //end;
          cmaps.buildCMaps();
     End;
     Try
        if specspeed2 > -1 then
        begin
             //specspeed2 < 0 = spectrum display off.
             doSpec := False;
             specNewSpec65 := False;
             // Adjust to float and copy data to FFT calculation buffer

             // Apply lpf
             //function chebyLP(const f : CTypes.cfloat) : CTypes.cfloat;
             //for i := 0 to length(dBuffer)-1 do fftIn65[i] := chebyLP(dBuffer[i]);

             for i := 0 to length(dBuffer)-1 do fftIn65[i] := dBuffer[i];

             fsum := 0.0;
             fave := 0;
             for i := 0 to length(fftIn65)-1 do fsum := fsum + fftIn65[i];
             fave := fsum/length(fftIn65);
             for i := 0 to length(fftIn65)-1 do fftIn65[i] := fftIn65[i]-fave;
             fsum := 0.0;
             fave := 0.0;
             for i := 0 to length(fftIn65)-1 do
             Begin
                  fftIn65[i] := 0.1 * fftIn65[i];
                  fsum := fsum + fftIn65[i];
             End;
             fave := fsum/length(fftIn65);
             for i := 0 to length(fftIn65)-1 do fftIn65[i] := fftIn65[i]-fave;

             // Clear FFT output array
             for i := 0 to 2047 do
             begin
                  fftOut65[i].re := 0.0;
                  fftOut65[i].im := 0.0;
             end;
             // Compute 4096 point FFT
             pfftIn65  := @fftIn65;
             pfftOut65 := @fftOut65;
             p := fftw_plan_dft_1d(4096,pfftIn65,pfftOut65,[fftw_estimate]);
             fftw_execute(p);

             // I want to start thinking about scaling this such that the over strong
             // don't swamp the weak.

             // Accumulate power spectrum
             for i := 0 to 2047 do ss65[i] := ss65[i] + (power(fftOut65[i].re,2) + power(fftOut65[i].im,2));
             fftw_destroy_plan(p);
             // FFT Completed.
             // ss[0..2047] now contains an fft of the power spectrum of the last 4096 samples.
             //
             // Compute spectral display line.
             // ss[0..2047] contains the power density in ~2.7 hz steps.
             inc(specfftCount);
             iadj := 97; // Adjust bins to match graphic display - this is for a 2K range centered on 1270.5 Hz
             if specfftCount >= (10-specSpeed2) Then
             Begin
                  // Removed smoothing being optional.
                  inc(specfftCount);
                  try
                     for i := 0 to length(ss65)-1 do ss65b[i] := ss65[i];
                     flat(@ss65[0],@nh,@specfftCount);
                     if specuseagc then
                     begin
                          gamma := 1.3 + 0.01*specContrast;
                          offset := (specGain+64.0)/2;
                          fi := 0.0;
                          i := iadj;
                          j := 0;
                          While i < length(ss65)-1 do
                          begin
                               fi := ss65[i];
                               i := i + iadj;
                               inc(j);
                          end;
                          fi := fi / j;
                          intvar := 0;
                          intVar := 0;
                          fvar := fi;
                          if fvar <> 0 Then
                          Begin
                               pw1 := 0.01*fvar;
                               pw2 := gamma;
                               fvar := 0.0;
                               fvar := power(pw1,pw2);
                               fvar := fvar+offset;
                          End
                          Else
                          Begin
                               fvar := 0.0;
                          End;
                          if fvar <> 0 then intVar := trunc(fvar) else intVar := 0;
                          intVar := min(252,max(0,intVar));
                          if intVar < 5 then
                          begin
                               // Undo the smooth if the avg value looks too low...
                               for i := 0 to length(ss65)-1 do ss65[i] := ss65b[i];
                               inc(specagc);
                          end;
                     end;
                  except
                        for i := 0 to length(ss65)-1 do ss65[i] := ss65b[i];
                  end;
                  // Create spectra line
                  For i := 0 to 749 do floatSpectra[i] := (specVGain*ss65[i+iadj])/specfftCount;
                  //Clear ss[]
                  for i := 0 to 2047 do ss65[i] := 0;
                  specfftCount := 0;
                  gamma := 1.3 + 0.01*specContrast;
                  offset := (specGain+64.0)/2;
                  // Map float specta pixels to integer
                  For i := 0 to 749 do
                  Begin
                       intVar := 0;
                       fvar := floatSpectra[i];
                       if fvar <> 0 Then
                       Begin
                            pw1 := 0.01*fvar;
                            pw2 := gamma;
                            fvar := 0.0;
                            fvar := power(pw1,pw2);
                            fvar := fvar+offset;
                       End
                       Else
                       Begin
                            fvar := 0.0;
                       End;
                       if fvar <> 0 then intVar := min(252,max(0,trunc(fvar))) else intVar := 0;
                       intVar := min(252,max(0,intVar));
                       integerSpectra[i] := intVar;
                  End;
                  doSpec := True;
                  for i := 0 to 749 do floatSpectra[i] := 0.0;
             End
             Else
             Begin
                  doSpec := False;
             End;
             // integerSpectra[0..749] now contains the values ready to convert to rgbSpectra via colorMap()
             If doSpec Then
             Begin
                  // Spectrum types 0..3 need conversion via colorMap()
                  If specColorMap < 4 Then colorMap(integerSpectra, rgbSpectra);
                  // Spectrum types 4 is simple single color mapping.
                  If specColorMap = 4 Then
                  Begin
                       // GREEN
                       for i := 0 to 749 do
                       Begin
                            rgbSpectra[i].g := integerSpectra[i];
                            rgbSpectra[i].r := 0;
                            rgbSpectra[i].b := 0;
                       End;
                  End;
                  // Now prepend the new spectra to the spectrum rolling off the former
                  // oldest element.  This is held in specDisplayData :
                  // Array[0..109][0..749] Of CTypes.cint32  Will use tempSpec1 as
                  // a copy buffer.
                  //
                  // Shift specDisplayData 1 line into tempSpec1 remembering that a
                  // full spectrum display has 180 lines.  See that I'm copying the
                  // newest 179 lines (0 to 178) to temp as lines 1 to 179 then
                  // adding the new line as element 0 yielding again 180 lines.
                  for i := 0 to 178 do specTempSpec1[i+1] := specDisplayData[i];
                  // Prepend new spectra to copy buffer
                  specTempSpec1[0] := rgbSpectra;
                  // Move copy buffer to real buffer
                  for i := 0 to 179 do specDisplayData[i] := specTempSpec1[i];
                  // Setup BMP Header
                  bmpH.bfType1         := 'B';
                  bmpH.bfType2         := 'M';
                  bmpH.bfSize          := 0;
                  bmpH.bfReserved1     := 0;
                  bmpH.bfReserved2     := 0;
                  bmpH.bfOffBits       := 0;
                  bmpH.biSize          := 40;
                  bmpH.biWidth         := 750;
                  bmpH.biHeight        := 180;
                  bmpH.biPlanes        := 1;
                  bmpH.biBitCount      := 24;
                  bmpH.biCompression   := 0;
                  bmpH.biSizeImage     := 0;
                  bmpH.biXPelsPerMeter := 0;
                  bmpH.biYPelsPerMeter := 0;
                  bmpH.biClrUsed       := 0;
                  bmpH.biClrImportant  := 0;
                  Bytes_Per_Raster := bmpH.biWidth * 3;
                  If Bytes_Per_Raster Mod 4 = 0 Then Raster_Pad := 0 Else Raster_Pad := 4 - (Bytes_Per_Raster Mod 4);
                  Bytes_Per_Raster := Bytes_Per_Raster + Raster_Pad;
                  bmpH.biSizeImage := Bytes_Per_Raster * bmpH.biHeight;
                  bmpH.bfSize := SizeOf(bmpH) + bmpH.biSizeImage;
                  bmpH.bfOffbits := SizeOf(bmpH);
                  // Clear BMP data
                  for i := 0 to 405359 do bmpD[i] := 0;
                  // Build BMP data
                  z := 0;
                  for y := 180 downto 1 do
                  Begin
                       for x := 0 to 749 do
                       begin
                            // BLUE
                            if (y=180) Or (x=0) Or (x=749) Then
                            Begin
                                 bmpD[z] := 0;
                                 inc(z);
                                 // GREEN
                                 bmpD[z] := 0;
                                 inc(z);
                                 // RED
                                 bmpD[z] := 0;
                                 inc(z);
                            End
                            Else
                            Begin
                                 bmpD[z] := specDisplayData[y-1][x].b;
                                 inc(z);
                                 // GREEN
                                 bmpD[z] := specDisplayData[y-1][x].g;
                                 inc(z);
                                 // RED
                                 bmpD[z] := specDisplayData[y-1][x].r;
                                 inc(z);
                            End;
                       end;
                       inc(z); // This is correct (re double inc of z)
                       inc(z);
                  end;
                  // Write BMP to memory stream
                  specMs65.Position := 0;
                  z := SizeOf(bmpH);
                  specMs65.Write(bmpH,SizeOf(bmpH));
                  z := SizeOf(bmpD);
                  specMs65.Write(bmpD,SizeOf(bmpd));
                  specNewSpec65 := True;
             End
             Else
             Begin
                  specNewSpec65 := False;
             End;
        end;
     Except
        //dlog.fileDebug('Exception raised in spectrum computation');
        specNewSpec65 := False;
     End;
     spectrumComputing65 := False;
     specFirstRun := False;
End;

end.
