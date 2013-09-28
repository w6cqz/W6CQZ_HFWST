// (c) 2013 CQZ Electronics
unit spectrum;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CTypes, cmaps, fftw_jl, globalData, graphics, Math;

Const
  JT_DLL = 'JT65v5.dll';
  // 19 pole butterworth LPF - good for < ~2.5KHz (This is an IIR type)
  LACoef : array[0..19] of CTypes.cfloat =
      (
      0.00001939180997620892,
      0.00036844438954796945,
      0.00331599950593172540,
      0.01879066386694644400,
      0.07516265546778577700,
      0.22548796640335733000,
      0.52613858827450044000,
      0.97711452108121499000,
      1.46567178162182250000,
      1.79137662198222760000,
      1.79137662198222760000,
      1.46567178162182250000,
      0.97711452108121499000,
      0.52613858827450044000,
      0.22548796640335733000,
      0.07516265546778577700,
      0.01879066386694644400,
      0.00331599950593172540,
      0.00036844438954796945,
      0.00001939180997620892
      );
  LBCoef : array[0..19] of CTypes.cfloat =
      (
      1.00000000000000000000,
      0.30124524681121684000,
      2.62368718667596430000,
      0.68183386600980578000,
      2.71043558836035330000,
      0.59957920836218892000,
      1.42524899306136610000,
      0.26375059355045877000,
      0.41246083660156979000,
      0.06237667312611505600,
      0.06644496002297710400,
      0.00794483191686967340,
      0.00575615778774987010,
      0.00051759803100776295,
      0.00024561616410988675,
      0.00001526235709911922,
      0.00000429882913347158,
      0.00000015515020059209,
      0.00000001973933115243,
      0.00000000023001431849
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

procedure computeSpectrum(Const dBuffer : Array of CTypes.cint16);

function colorMap(Const integerArray : Array of LongInt; Var rgbArray : RGBArray): Boolean;

function computeAudio(Const Buffer : Array of CTypes.cint16): Integer;

procedure flat(ss,n,nsum : Pointer); cdecl;

Var
   specDisplayData : Packed Array[0..179]    Of RGBArray;
   specTempSpec1   : Packed Array[0..179]    Of RGBArray;
   bmpD            : Packed Array[0..405359] Of Byte;
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

implementation

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
     globalData.audioComputing := True;
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
     globalData.audioComputing := False;
End;

procedure computeSpectrum(Const dBuffer : Array of CTypes.cint16);
Var
   i,x,y,z,intVar,nh,nfmid,iadj,k  : CTypes.cint;
   gamma,offset,fi,df,fvar,pw1,pw2 : CTypes.cfloat;
   rgbSpectra                      : RGBArray;
   doSpec                          : Boolean;
   bmpH                            : BMP_Header;
   Bytes_Per_Raster                : LongInt;
   Raster_Pad, nfrange, j          : Integer;
   auBuff65                        : Packed Array[0..4095] Of smallint;
   fftOut65                        : Array[0..2047] of fftw_jl.complex_single;
   fftIn65,srealArray165           : Array[0..4095] of Single;
   lxa,lya,hxa,hya                 : Array[0..19] of Single;
   pfftIn65                        : PSingle;
   pfftOut65                       : fftw_jl.Pcomplex_single;
   p                               : fftw_plan_single;
   ss65,ss65b                      : Array[0..2047] of CTypes.cfloat;
   floatSpectra                    : Array[0..749] of CTypes.cfloat;
   integerSpectra                  : Array[0..749] of CTypes.cint32;
Begin
     // Compute spectrum display.  Expects 4096 samples in dBuffer
     globalData.spectrumComputing65 := True;
     nh := 2048;
     nfmid := 1270;
     df := 11025.0/4096;
     nfrange := 2000;
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
          for i := 0 to 19 do
          begin
               lxa[i] := 0.0;
               lya[i] := 0.0;
               hxa[i] := 0.0;
               hya[i] := 0.0;
          end;
          cmaps.buildCMaps();
     End;
     Try
        if specspeed2 > -1 then
        begin
             //specspeed2 < 0 = spectrum display off.
             doSpec := False;
             globalData.specNewSpec65 := False;
             // Copy input
             for i := 0 to 4095 do auBuff65[i] := min(32766,max(-32766,dBuffer[i]));
             // HPF 3rd order (also converts int16 to float)
             for i := 0 to 4095 do
             begin
                  // Shift old samples in x[] and y[]
                  for k := 3 downto 1 do
                  begin
                       hxa[k] := hxa[k-1];
                       hya[k] := hya[k-1];
                  end;
                  // Calculate new sample
                  hxa[0] := auBuff65[i];
                  hya[0] := HACoef[0] * hxa[0];
                  for k := 0 to 3 do
                  begin
                       hya[0] := hya[0] + ((HACoef[k] * hxa[k]) - (HBCoef[k] * hya[k]));
                  end;
                  srealArray165[i] := hya[0];
             end;
             // LPF 19th order
             for i := 0 to 4095 do
             begin
                  // Shift old samples in x[] and y[]
                  for k := 19 downto 1 do
                  begin
                       lxa[k] := lxa[k-1];
                       lya[k] := lya[k-1];
                  end;
                  // Calculate new sample
                  lxa[0] := srealArray165[i];
                  lya[0] := LACoef[0] * lxa[0];
                  for k := 0 to 19 do
                  begin
                       lya[0] := lya[0] + ((LACoef[k] * lxa[k]) - (LBCoef[k] * lya[k]));
                  end;
                  srealArray165[i] := lya[0];
             end;
             // Clear FFT Input array
             for i := 0 to length(fftIn65)-1 do fftIn65[i] := 0.0;
             for i := 0 to 4095 do fftIn65[i] := srealArray165[i];
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
             // Accumulate power spectrum
             for i := 0 to 2047 do ss65[i] := ss65[i] + (power(fftOut65[i].re,2) + power(fftOut65[i].im,2));
             fftw_destroy_plan(p);
             // FFT Completed.
             // ss[0..2047] now contains an fft of the power spectrum of the last 4096 samples.
             //
             // Compute spectral display line.
             // ss[0..2047] contains the power density in ~2.7 hz steps.
             inc(specfftCount);
             if specfftCount >= (10-specSpeed2) Then
             Begin
                  inc(specfftCount);
                  if specSmooth Then
                  Begin
                       try
                          for i := 0 to length(ss65)-1 do ss65b[i] := ss65[i];
                          flat(@ss65[0],@nh,@specfftCount);
                          if specuseagc then
                          begin
                               if nfrange = 2000 Then iadj := (182 + round((nfmid-1500)/df))-1;
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
                  end;

                  // Create spectra line
                  if nfrange = 2000 Then iadj := 182 + round((nfmid-1500)/df);
                  if nfrange = 4000 Then iadj := round(nfmid/df - 752.0);
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
                       if fvar <> 0 then intVar := trunc(fvar) else intVar := 0;
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
                  globalData.specMs65.Position := 0;
                  z := SizeOf(bmpH);
                  globalData.specMs65.Write(bmpH,SizeOf(bmpH));
                  z := SizeOf(bmpD);
                  globalData.specMs65.Write(bmpD,SizeOf(bmpd));
                  globalData.specNewSpec65 := True;
             End
             Else
             Begin
                  globalData.specNewSpec65 := False;
             End;
        end;
     Except
        //dlog.fileDebug('Exception raised in spectrum computation');
        globalData.specNewSpec65 := False;
     End;
     globalData.spectrumComputing65 := False;
     specFirstRun := False;
End;
end.
