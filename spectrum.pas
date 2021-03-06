// Copyright (c) 2008,2009,2010,2011,2012,2013,2014 J C Large - W6CQZ
unit spectrum;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CTypes, cmaps, fftw_jl, graphics, Math, jt65demod;

Type
    PNGPixel = Packed Record
             r : Word;
             g : Word;
             b : Word;
             a : Word;
    end;

    PNGArray = Array[0..929] of PNGPixel;

procedure computeSpectrum(Const dBuffer : Array of CTypes.cint16);
function computeAudio(Const Buffer : Array of CTypes.cint16): Integer;

Var
   specPNG         : Packed Array[0..179] Of PNGArray;
   specPNGTemp     : Packed Array[0..179] Of PNGArray;
   specFirstRun    : Boolean;
   specColorMap    : Integer;
   specSpeed2      : Integer;
   specVGain       : Integer;
   specContrast    : Integer;
   specfftCount    : Integer;
   specSmooth      : Boolean;
   specWindow      : Boolean;
   audiocomputing  : Boolean;
   spectrumComputing65 : Boolean;
   specNewSpec65   : Boolean;

implementation

function pColorMap(Const integerArray : Array of LongInt; Var rgbArray : PNGArray ): Boolean;
Var
   floatvar : Single;
   i        : Integer;
   intvar   : LongInt;
   scale    : Single;
Begin
     scale := 65535.0;
     // This routine maps integerArray[0..929] to rgbArray[0..929] in RGB pixel format.
     If specColorMap = 0 Then
     Begin
          for i := 0 to 929 do
          Begin
               rgbarray[i].a := 65535;
               floatvar := cmaps.bluecmap1[integerArray[i]];
               floatvar := floatvar * scale; // Red
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].r := intvar;

               floatvar := cmaps.bluecmap2[integerArray[i]];
               floatvar := floatvar * scale; // Green
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].g := intvar;

               floatvar := cmaps.bluecmap3[integerArray[i]];
               floatvar := floatvar * scale; // Blue
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].b := intvar;
          End;
     End
     Else If specColorMap = 1 Then
     Begin
          for i := 0 to 929 do
          Begin
               rgbarray[i].a := 65535;
               floatvar := cmaps.linradcmap1[integerArray[i]];
               floatvar := floatvar * scale; // Red
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].r := intvar;

               floatvar := cmaps.linradcmap2[integerArray[i]];
               floatvar := floatvar * scale; // Green
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].g := intvar;

               floatvar := cmaps.linradcmap3[integerArray[i]];
               floatvar := floatvar * scale; // Blue
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].b := intvar;
          End;
     End
     Else If specColorMap = 2 Then
     Begin
          for i := 0 to 929 do
          Begin
               rgbarray[i].a := 65535;
               floatvar := cmaps.gray0cmap1[integerArray[i]];
               floatvar := floatvar * scale; // Red
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].r := intvar;

               floatvar := cmaps.gray0cmap2[integerArray[i]];
               floatvar := floatvar * scale; // Green
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].g := intvar;

               floatvar := cmaps.gray0cmap3[integerArray[i]];
               floatvar := floatvar * scale; // Blue
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].b := intvar;
          End;
     End
     Else If specColorMap = 3 Then
     Begin
          for i := 0 to 929 do
          Begin
               rgbarray[i].a := 65535;
               floatvar := cmaps.gray1cmap1[integerArray[i]];
               floatvar := floatvar * scale; // Red
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].r := intvar;

               floatvar := cmaps.gray1cmap2[integerArray[i]];
               floatvar := floatvar * scale; // Green
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].g := intvar;

               floatvar := cmaps.gray1cmap3[integerArray[i]];
               floatvar := floatvar * scale; // Blue
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].b := intvar;
          End;
     End
     Else If specColorMap = 4 Then
     Begin
          // Spectrum types 4 is simple single color mapping.
          for i := 0 to 929 do
          Begin
               rgbarray[i].a := 65535;
               rgbarray[i].g := min(65535,max(0,integerArray[i]*255));
               rgbarray[i].r := 0;
               rgbarray[i].b := 0;
          end;
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
        Result := 0;
     End;
     audioComputing := False;
End;

procedure computeSpectrum(Const dBuffer : Array of CTypes.cint16);
Var
   i,nh,iadj         : CTypes.cint;
   gamma,offset,fave : CTypes.cfloat;
   pngSpectra        : PNGArray;
   doSpec            : Boolean;
   fftOut65          : Array[0..2047] of fftw_jl.complex_single;
   fftIn65           : Array[0..4095] of Single;
   pfftIn65          : PSingle;
   pfftOut65         : fftw_jl.Pcomplex_single;
   p                 : fftw_plan_single;
   ss65              : Array[0..2047] of CTypes.cfloat;
   integerSpectra    : Array[0..929] of CTypes.cint32;
Begin
     // Compute spectrum display.  Expects 4096 samples in dBuffer
     spectrumComputing65 := True;
     nh := 2048;
     If specFirstRun Then
     Begin
          // clear ss65
          for i := 0 to 2047 do
          Begin
               ss65[i] := 0;
          End;
          // clear rgbSpectra
          for i := 0 to 929 do
          Begin
               pngSpectra[i].r := 0;
               pngSpectra[i].g := 0;
               pngSpectra[i].b := 0;
               pngSpectra[i].a := 65535;
          End;
          cmaps.buildCMaps();
     End;
     Try
        if specspeed2 > -1 then
        begin
             //specspeed2 < 0 = spectrum display off.
             doSpec := False;
             specNewSpec65 := False;
             // Adjust to float and copy data to FFT calculation buffer - removing any DC to boot
             fave := 0.0;
             for i := 0 to length(dBuffer)-1 do fave := fave + dBuffer[i];
             fave := fave/length(dBuffer);
             // Convert to float and scale.
             for i := 0 to length(dbuffer)-1 do fftIn65[i] := 0.001*(dbuffer[i]-fave);
             // Gaussian 3/5 window function (If enabled)
             fave := -2*3.5*3.5;
             if specWindow Then for i := 0 to 4095 do fftIn65[i] := fftIn65[i] * exp(fave*(0.25 + ((i/4096)*(i/4096)) - (i/4096)));
             // Compute 4096 point FFT
             pfftIn65  := @fftIn65;
             pfftOut65 := @fftOut65;
             p := fftw_plan_dft_1d(4096,pfftIn65,pfftOut65,[fftw_estimate]);
             fftw_execute(p);
             // Accumulate power spectrum
             for i := 0 to 2047 do ss65[i] := ss65[i] + (power(fftOut65[i].re,2) + power(fftOut65[i].im,2));
             // FFT done, destroy plan.
             fftw_destroy_plan(p);
             // Keep track of accumulations
             inc(specfftCount);
             // iadj sets the lower bin to F = iadj * (11025/4096) = iadj * 2.691650390625
             iadj := 97; // 97 * (11025/4096) = 261.090087890625
             // Maps PS to pixels - these can vary based on user choices for contrast and gain.
             gamma := 1.3 + 0.01*specContrast;
             //offset := (specGain+64.0)/2;
             offset := 32.0;
             if specfftCount >= (8-specSpeed2) Then
             Begin
                  // Compute spectral display line.
                  jt65demod.jl_flat2(ss65,nh,specfftCount);
                  // Map float specta pixels to integer
                  For i := 0 to 929 do
                  begin
                       integerSpectra[i] := min(255,max(0,Round(offset + (power((0.01*((specVGain*ss65[i+iadj])/specfftCount)),gamma)))));
                  end;
                  // Clear ss65 (This is important!) :)
                  for i := 0 to length(ss65)-1 do ss65[i] := 0.0;
                  // Need to generate new spectrum display frame
                  doSpec := True;
                  // Reset spectrum PS accumulator counter
                  specfftCount := 0;
             End
             Else
             Begin
                  // Haven't accumulated enough samples yet.
                  doSpec := False;
             End;
             // integerSpectra[0..929] now contains the values ready to convert to rgbSpectra via colorMap()
             If doSpec Then
             Begin
                  // Map spectra values to png RGB pixel values
                  pColorMap(integerSpectra, pngSpectra);
                  // Shift the lines and add new one then Build the PNG
          	  for i := 0 to 178 do specPNGTemp[i+1] := specPNG[i];
          	  // Prepend new spectra to copy buffer
          	  specPNGTemp[0] := pngSpectra;
          	  // Move copy buffer to real buffer
          	  for i := 0 to 179 do specPNG[i] := specPNGTemp[i];
                  specNewSpec65 := True;
             End
             Else
             Begin
                  specNewSpec65 := False;
             End;
        end;
     Except
        specNewSpec65 := False;
     End;
     spectrumComputing65 := False;
     specFirstRun := False;
End;

end.
