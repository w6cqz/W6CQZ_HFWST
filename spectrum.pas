// (c) 2013 CQZ Electronics
unit spectrum;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CTypes, cmaps, fftw_jl, graphics, Math;

Const
  JT_DLL = 'JT65v32.dll';

Type
    PNGPixel = Packed Record
             r : Word;
             g : Word;
             b : Word;
             a : Word;
    end;

    PNGArray = Array[0..749] of PNGPixel;

procedure computeSpectrum(Const dBuffer : Array of CTypes.cint16);
function computeAudio(Const Buffer : Array of CTypes.cint16): Integer;
procedure flat(ss,n,nsum : Pointer); cdecl;

Var
   specPNG         : Packed Array[0..179] Of PNGArray;
   specPNGTemp     : Packed Array[0..179] Of PNGArray;
   specFirstRun    : Boolean;
   specColorMap    : Integer;
   specSpeed2      : Integer;
   specGain        : Integer;
   specVGain       : Integer;
   specContrast    : Integer;
   specfftCount    : Integer;
   specSmooth      : Boolean;
   specWindow      : Boolean;
   specagc         : CTypes.cuint64;
   specuseagc      : Boolean;
   audiocomputing  : Boolean;
   spectrumComputing65 : Boolean;
   specNewSpec65   : Boolean;

implementation

procedure flat(ss,n,nsum : Pointer); cdecl; external JT_DLL name 'flat2_';

//function colorMap(Const integerArray : Array of LongInt; Var rgbArray : RGBArray ): Boolean;
//Var
//   floatvar : Single;
//   i        : Integer;
//   intvar   : LongInt;
//Begin
//     // This routine maps integerArray[0..749] to rgbArray[0..749] in RGB pixel format.
//     If specColorMap = 0 Then
//     Begin
//          for i := 0 to 749 do
//          Begin
//               floatvar := cmaps.bluecmap1[integerArray[i]];
//               floatvar := floatvar * 256; // Red
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].r := intvar;
//
//               floatvar := cmaps.bluecmap2[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].g := intvar;
//
//               floatvar := cmaps.bluecmap3[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].b := intvar;
//          End;
//     End;
//     If specColorMap = 1 Then
//     Begin
//          for i := 0 to 749 do
//          Begin
//               floatvar := cmaps.linradcmap1[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].r := intvar;
//
//               floatvar := cmaps.linradcmap2[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].g := intvar;
//
//               floatvar := cmaps.linradcmap3[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].b := intvar;
//          End;
//     End;
//     If specColorMap = 2 Then
//     Begin
//          for i := 0 to 749 do
//          Begin
//               floatvar := cmaps.gray0cmap1[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].r := intvar;
//
//               floatvar := cmaps.gray0cmap2[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].g := intvar;
//
//               floatvar := cmaps.gray0cmap3[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].b := intvar;
//          End;
//     End;
//     If specColorMap = 3 Then
//     Begin
//          for i := 0 to 749 do
//          Begin
//               floatvar := cmaps.gray1cmap1[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].r := intvar;
//
//               floatvar := cmaps.gray1cmap2[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].g := intvar;
//
//               floatvar := cmaps.gray1cmap3[integerArray[i]];
//               floatvar := floatvar * 256;
//               intvar := trunc(floatvar);
//               intVar := min(255,max(0,intVar));
//               rgbArray[i].b := intvar;
//          End;
//     End;
//     Result := True;
//End;

function pColorMap(Const integerArray : Array of LongInt; Var rgbArray : PNGArray ): Boolean;
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
               rgbarray[i].a := 65535;
               floatvar := cmaps.bluecmap1[integerArray[i]];
               floatvar := floatvar * 65536; // Red
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].r := intvar;

               floatvar := cmaps.bluecmap2[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].g := intvar;

               floatvar := cmaps.bluecmap3[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].b := intvar;
          End;
     End;
     If specColorMap = 1 Then
     Begin
          for i := 0 to 749 do
          Begin
               rgbarray[i].a := 65535;
               floatvar := cmaps.linradcmap1[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].r := intvar;

               floatvar := cmaps.linradcmap2[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].g := intvar;

               floatvar := cmaps.linradcmap3[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].b := intvar;
          End;
     End;
     If specColorMap = 2 Then
     Begin
          for i := 0 to 749 do
          Begin
               rgbarray[i].a := 65535;
               floatvar := cmaps.gray0cmap1[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].r := intvar;

               floatvar := cmaps.gray0cmap2[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].g := intvar;

               floatvar := cmaps.gray0cmap3[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].b := intvar;
          End;
     End;
     If specColorMap = 3 Then
     Begin
          for i := 0 to 749 do
          Begin
               rgbarray[i].a := 65535;
               floatvar := cmaps.gray1cmap1[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].r := intvar;

               floatvar := cmaps.gray1cmap2[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
               rgbArray[i].g := intvar;

               floatvar := cmaps.gray1cmap3[integerArray[i]];
               floatvar := floatvar * 65536;
               intvar := trunc(floatvar);
               intVar := min(65535,max(0,intVar));
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

procedure computeSpectrum(Const dBuffer : Array of CTypes.cint16);
Var
   i,intVar,nh,iadj,j           : CTypes.cint;
   gamma,offset,fi,fvar,pw1,pw2 : CTypes.cfloat;
   fave                         : CTypes.cfloat;
   pngSpectra                   : PNGArray;
   doSpec                       : Boolean;
   fftOut65                     : Array[0..2047] of fftw_jl.complex_single;
   fftIn65                      : Array[0..4095] of Single;
   pfftIn65                     : PSingle;
   pfftOut65                    : fftw_jl.Pcomplex_single;
   p                            : fftw_plan_single;
   ss65,ss65b                   : Array[0..2047] of CTypes.cfloat;
   floatSpectra                 : Array[0..749] of CTypes.cfloat;
   integerSpectra               : Array[0..749] of CTypes.cint32;
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
             // Adjust to float and copy data to FFT calculation buffer
             fave := 0.0;
             for i := 0 to length(dBuffer)-1 do fave := fave + dBuffer[i];
             fave := fave/(length(dBuffer));
             for i := 0 to length(dbuffer)-1 do fftIn65[i] := 0.001*(dbuffer[i]-fave);
             if specWindow Then
             Begin
                  // Gaussian 3/5
                  // This might not be so bad with the change above scaling by .001 :)
                  fave := -2*3.5*3.5;
                  for i := 0 to 4095 do fftIn65[i] := fftIn65[i] * exp(fave*(0.25 + ((i/4096)*(i/4096)) - (i/4096)));
             end;
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
             iadj := 97; // Adjust bins to match graphic display - this is for a 2K range centered on 1270.5 Hz
             if specfftCount >= (10-specSpeed2) Then
             Begin
                  inc(specfftCount);
                  try
                     for i := 0 to length(ss65)-1 do ss65b[i] := ss65[i];
                     flat(@ss65[0],@nh,@specfftCount);
                     //if specuseagc then
                     //begin
                          gamma := 1.3 + 0.01*specContrast;
                          offset := (specGain+64.0)/2;
                          fi := 0.0;
                          i := iadj;
                          j := 0;
                          // WUT
                          { TODO : Sort this out - it seems to do a whole lot of looping FOR NOTHING }
                          //While i < length(ss65)-1 do
                          //begin
                               //fi := ss65[i];
                               //i := i + iadj;
                               //inc(j);
                          //end;
                          // Now... I just "corrected" the above with the line below BUT
                          // if AGC stops working the deal is....
                          // Uncorrect it and figure out why the hell it works that cockeyed way.
                          // It's likely my rescaling of the data from data[x]*.1 to data[x]*.001 may have cured this and made all this moot.
                          for i := 0 to 2047 do fi := fi+ss65[i];
                          //While i < length(ss65)-1 do
                          //begin
                               //fi := fi + ss65[i];
                               //i := i + iadj;
                               //inc(j);
                          //end;
                          fi := fi / 2048.0;
                          intvar := 0;
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
                     //end;
                  except
                        for i := 0 to length(ss65)-1 do ss65[i] := ss65b[i];
                  end;
                  // Create spectra line
                  // Somewhere in range of 490...570 there's a "stuck" pixel - lets find that someday :)
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
                  If specColorMap < 4 then pColorMap(integerSpectra, pngSpectra);
                  // Spectrum types 4 is simple single color mapping.
                  If specColorMap = 4 Then
                  Begin
                       for i := 0 to 749 do
                       Begin
                            pngSpectra[i].a := 65535;
                            pngSpectra[i].g := integerSpectra[i]*256;
                            pngSpectra[i].r := 0;
                            pngSpectra[i].b := 0;
                       end;
                  End;

                  // Shift the lines and add new one then Build the PNG
                  // Now prepend the new spectra to the spectrum rolling off the former
          	  // oldest element.  This is held in specDisplayData :
                  // Array[0..109][0..749] Of CTypes.cint32  Will use tempSpec1 as
          	  // a copy buffer.
          	  //
          	  // Shift specDisplayData 1 line into tempSpec1 remembering that a
          	  // full spectrum display has 180 lines.  See that I'm copying the
          	  // newest 179 lines (0 to 178) to temp as lines 1 to 179 then
          	  // adding the new line as element 0 yielding again 180 lines.

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
        //dlog.fileDebug('Exception raised in spectrum computation');
        specNewSpec65 := False;
     End;
     spectrumComputing65 := False;
     specFirstRun := False;
End;

end.
