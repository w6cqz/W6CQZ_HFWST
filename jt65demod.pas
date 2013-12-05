unit jt65demod;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, math, CTypes, fftw_jl, DateUtils;

Const
  JT_DLL = 'JT65v32.dll';
  SYNC65 : array[0..125] of CTypes.cint =
        (1,-1,-1,1,1,-1,-1,-1,1,1,1,1,1,1,-1,1,-1,1,-1,-1,-1,1,-1,1,1,-1,-1,1,-1,-1,-1,1,1,1,-1,-1,1,1,1,1,-1,1,1,-1,1,1,1,1,-1,-1,-1,1,1,-1,
         1,-1,1,-1,1,1,-1,-1,1,1,-1,1,-1,1,-1,1,-1,-1,1,-1,-1,-1,-1,-1,-1,1,1,-1,-1,-1,-1,-1,-1,-1,1,1,-1,1,-1,-1,1,-1,1,1,-1,1,-1,1,-1,1,-1,
         -1,1,1,-1,-1,1,-1,-1,1,-1,-1,-1,-1,1,1,1,1,1,1,1,1);

Var
   glCCF   : Array[0..545] of CTypes.cfloat;
   glPSavg : Array[0..1023] of CTypes.cfloat;

procedure jt_flat1(psavg,s2,nh,nsteps,nhmax,nsmax : Pointer); cdecl;
procedure jt_xcor(s2,ipk,nsteps,nsym,lag1,lag2,ccf,ccf0,lagpk,flip,fdot : Pointer); cdecl;
procedure jt_peakup(ym,y0,yp,dx : Pointer); cdecl;
procedure jt_pctile(x,tmp,nmax,npct,xpct : Pointer); cdecl;

procedure jl_xcor(const a : Array of CTypes.cfloat; const nsteps,nsym,lag1,lag2 : CTypes.cint; var ccf : Array of CTypes.cfloat; Var ccf0,lagpk0,flip : CTypes.cfloat);
procedure jl_slope(var y : Array of CTypes.cfloat; const n : CTypes.cint; const xpk : CTypes.cfloat);
procedure jl_peakup(const ym,y0,yp : CTypes.cfloat; var dx : CTypes.cfloat);
procedure jl_ps(const a : Array of CTypes.cfloat; const n : CTypes.cint; var s : Array of CTypes.cfloat);
procedure jl_sync65(const dat : Array of CTypes.cfloat; const jz : CTypes.cint; const cf : CTypes.cfloat; const bw : CTypes.cfloat; var dtx,dfx,snrx,snrsync,flip : CTypes.cfloat);
procedure jl_flat2(var a : Array of CTypes.cfloat; const n,x : CTypes.cint);
function  jdb(x : CTypes.cfloat) : CTypes.cfloat;

implementation

procedure jt_flat1(psavg,s2,nh,nsteps,nhmax,nsmax : Pointer); cdecl; external JT_DLL name 'flat1_';
procedure jt_xcor(s2,ipk,nsteps,nsym,lag1,lag2,ccf,ccf0,lagpk,flip,fdot : Pointer); cdecl; external JT_DLL name 'xcor_';
procedure jt_peakup(ym,y0,yp,dx : Pointer); cdecl; external JT_DLL name 'peakup_';
procedure jt_pctile(x,tmp,nmax,npct,xpct : Pointer); cdecl; external JT_DLL name 'pctile_';

procedure jl_flat2(var a : Array of CTypes.cfloat; const n,x : CTypes.cint);
Var
   ref,tmp : Array[0..2047] Of CTypes.cfloat;
   nsmo,ia,ib,i,j,k : CTypes.cint;
   base,base2 : CTypes.cfloat;
Begin
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
     for i := 0 to 2047 do
     begin
          ref[i] := 0.0;
          tmp[i] := 0.0;
     end;

     nsmo := 20;
     base := 50.0 * power(x,1.5);
     ia := nsmo+1;
     ib := n-nsmo-1;

     j := 2*nsmo+1;
     k := 50;
     for i := ia to ib do
     begin
          jt_pctile(@a[i-nsmo],@tmp,@j,@k,@ref[i])
     end;
     j := ib-ia+1;
     k := 68;
     base2 := 0.0;
     jt_pctile(@ref[ia],@tmp,@j,@k,@base2);

     if base2 > 0.05*base Then
     Begin
          for i := ia to ib do
          begin
               a[i] := base*a[i]/ref[i];
          end;
     end
     else
     begin
          for i := 0 to n-1 do a[i] := a[i]*0.9;
          //for i := 0 to n-1 do a[i] := 0.0;
          for i := 0 to 2047 do
          begin
               ref[i] := 0.0;
               tmp[i] := 0.0;
          end;

          nsmo := 20;
          base := 50.0 * power(x,1.5);
          ia := nsmo+1;
          ib := n-nsmo-1;

          j := 2*nsmo+1;
          k := 50;
          for i := ia to ib do
          begin
               jt_pctile(@a[i-nsmo],@tmp,@j,@k,@ref[i])
          end;
          j := ib-ia+1;
          k := 68;
          base2 := 0.0;
          jt_pctile(@ref[ia],@tmp,@j,@k,@base2);

          if base2 > 0.05*base Then
          Begin
               for i := ia to ib do
               begin
                    a[i] := base*a[i]/ref[i];
               end;
          end
          else
          begin
               for i := 0 to n-1 do a[i] := a[i]*0.9;
               for i := 0 to 2047 do
               begin
                    ref[i] := 0.0;
                    tmp[i] := 0.0;
               end;

               nsmo := 20;
               base := 50.0 * power(x,1.5);
               ia := nsmo+1;
               ib := n-nsmo-1;

               j := 2*nsmo+1;
               k := 50;
               for i := ia to ib do
               begin
                    jt_pctile(@a[i-nsmo],@tmp,@j,@k,@ref[i])
               end;
               j := ib-ia+1;
               k := 68;
               base2 := 0.0;
               jt_pctile(@ref[ia],@tmp,@j,@k,@base2);

               if base2 > 0.05*base Then
               Begin
                    for i := ia to ib do
                    begin
                         a[i] := base*a[i]/ref[i];
                    end;
               end
               else
               begin
                    for i := 0 to n-1 do a[i] := a[i]*0.9;
               end;
          end;
     end;
end;

function  jdb(x : CTypes.cfloat) : CTypes.cfloat;
Begin
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
     Result := -99.0;
     if x > 1.259e-10 Then Result := 10.0 * log10(x);
end;

procedure jl_slope(var y : Array of CTypes.cfloat; const n : CTypes.cint; const xpk : CTypes.cfloat);
Var
   x : Array[0..99] of CTypes.cfloat;
   i : CTypes.cint;
   sumw,sumx,sumy,sumx2,sumxy,sumy2,delta,a,b : CTypes.cfloat;
Begin
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
     if n < 101 Then
     Begin
          for i := 0 to 99 do x[i] := i+1.0; // Initialize x[]
          // Init other vars
          sumw  := 0.0;
          sumx  := 0.0;
          sumy  := 0.0;
          sumx2 := 0.0;
          sumxy := 0.0;
          sumy2 := 0.0;
          delta := 0.0;
          a     := 0.0;
          b     := 0.0;
          // Here we go - pay attention to the adjuster when dealing with i
          for i := 0 to n-1 do
          begin
               if abs(i-xpk) > 2.0 Then
               Begin
                    // This excludes the peak +/- 2 of xpk from being perturbed
                    sumw := sumw + 1.0;
                    sumx := sumx + x[i];
                    sumy := sumy + y[i];
                    sumx2 := sumx2 + power(x[i],2);
                    sumxy := sumxy + x[i] * y[i];
                    sumy2 := sumy2 + power(y[i],2);
               end;
          end;

          delta := sumw * sumx2 - power(sumx,2);
          a := (sumx2*sumy - sumx*sumxy) / delta;
          b := (sumw*sumxy - sumx*sumy) / delta;

          for i := 0 to n-1 do
          begin
               y[i] := y[i]-(a + b*x[i]);
          end;
     end
     else
     begin
          // Need to throw an exception here
          i := n;
     end;

end;

procedure jl_peakup(const ym,y0,yp : CTypes.cfloat; var dx : CTypes.cfloat);
var
   b,c : CTypes.cfloat;
Begin
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
     b := (yp-ym)/2.0;
     c := (yp+ym-2.0*y0)/2.0;
     dx := b/(2.0*c);
end;

procedure jl_ps(const a : Array of CTypes.cfloat; const n : CTypes.cint; var s : Array of CTypes.cfloat);

Var
   pfI  : PSingle;
   pfO  : fftw_jl.Pcomplex_single;
   p    : fftw_plan_single;
   c    : Array of fftw_jl.complex_single;
   x    : Array of CTypes.cfloat;
   fac  : CTypes.cfloat;
   i,nh : Integer;
   nn   : Integer;
   wis  : PChar;
   foo  : String = '';
   t1,t2                  : TDateTime;
   span                   : Double;
Begin
     // For a 2048 point run it's about 160 ms for first pass then 1 ms for following
     // Assuming one saved wisdom all would be 1ms give or take a bit.
     t1 := now;
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
     // Runs an N point FFT on array a[] returning computed power spectrum in s[]
     // Copies input data to temporary array x[]
     // Complex array c[] is allocated to half size of FFT point count N
     // if input array a[] is smaller than N*2 it is 0 padded
     // Compute 4096 point FFT
     nn := n;

     nh := n div 2;

     // Allocate arrays
     setLength(x,n);
     setLength(c,nh);

     pfI := @x[0];
     pfO := @c[0];

     // Copy and scale input data
     for i := 0 to nn-1 do
     begin
          Try
             x[i] := a[i]/128.0; // No idea why the divide by 128.0 but it's how it's done in WSJT
          except
             x[i] := 0.0;
          end;
     end;

     // Clear complex FFT result array
     for i := 0 to nh-1 do
     begin
          c[i].re := 0.0;
          c[i].im := 0.0;
     end;

     // Build FFT Plan
     p := fftw_plan_dft_1d(n,pfI,pfO,[fftw_estimate]);
     //p := fftw_jl.fftw_plan_dft_1d(n,pfI,pfO,[fftw_jl.fftw_measure]);
     //p := fftw_plan_dft_1d(n,pfI,pfO,[fftw_exhaustive]);
     //p := fftw_plan_dft_1d(n,pfI,pfO,[fftw_patient]);
     //p := fftw_plan_dft_1d(n,pfI,pfO,[fftw_unaligned])
     //p := fftw_plan_dft_1d(n,pfI,pfO,[fftw_conserve_memory]);

     // Execute plan
     fftw_jl.fftw_execute(p);

     // Accumulate power spectrum
     fac := 1.0/nh;
     for i := 0 to nh-1 do s[i] := fac * (power(c[i].re,2) + power(c[i].im,2));

     // Accumulate wisdom
     if length(foo) < 4 Then
     Begin
          wis := fftw_jl.fftwf_export_wisdom_to_string;
          foo := strpas(wis);
     end;

     // Clean up plan
     fftw_jl.fftw_destroy_plan(p);

     // Deallocate arrays
     setLength(x,0);
     setLength(c,0);

     t2 := now;
     span := MilliSecondSpan(t1,t2);
     span := span;
end;

procedure jl_xcor(const a : Array of CTypes.cfloat; const nsteps,nsym,lag1,lag2 : CTypes.cint; var ccf : Array of CTypes.cfloat; Var ccf0,lagpk0,flip : CTypes.cfloat);
Var
   ccfmax,ccfmin,x : CTypes.cfloat;
   i,j,lag         : CTypes.cint;
   lagmin          : CTypes.cint;
Begin
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);

     if (lag1<0) or (lag2>545) Then
     Begin
          i:=0;
          //Big fat error
     end;

     // Setup to correlate to sync vector
     ccfmax := 0.0;
     ccfmin := 0.0;

     // In JT's original correlator the lag1 to lag2 was -5 ... 59
     // I'm using 0 ... 64 so does this screw up the loop where I calculate x?
     //
     // In JT's the value of j would run j = 2*1-1+-5 to 2*126-1+59 for -4,-2,0,2,4,6,8,10 ... to 310 stepping +2 each loop
     // In JL's the value of j would run j = 2*0-1+0 to 2*125-1+64 for -1,1,3,5,7,9,11,13  ... to 313
     // so if I adjust mine to 2*i-4+lag I would get... -4,-2,0,2,4,6,8,10.... to 310
     // It ignores j < 1 or j > 254
     //
     // Now the output data is also no longer "centered" as in JT's code. (ccfblue[])
     // It used to run -5 ... max
     // now it runs 0 ... max
     // Sure enough in JT's orginal code it would run from -5 -> 59 in ccfblue
     // while in my code it's running 0 -> 64 so I need to account for this in
     // other areas looking at ccfblue as I'm now offset from what *might* be
     // expected.

     x := 0.0;

     for lag := lag1 to lag2 do
     begin
          // This runs 65 (0 ... 64) passes looking for correlation peak
          for i := 0 to nsym-1 do
          begin
               // This runs 126 ( 0 ... 125) passes looking for correlation peak at this lag
               j := 2*i-4+lag; // j runs from -1 to 249 incrementing 2 each pass
               if (j>=1) And (j<=nsteps) Then x := x+a[j]*SYNC65[i];
          end;

          // Sets ccf[lag] (lag = 0 ... 64) to 2*x with x calculated above.
          ccf[lag] := 2*x;

          // Looking for the maximal value of x (as stored in ccf[lag])
          if ccf[lag] > ccfmax Then
          Begin
               ccfmax := ccf[lag];  // Maximal value of x
               lagpk0 := lag;       // Index to this in ccf array
          end;

          // Looking for the minimal value of x (as stored in ccf[lag])
          if ccf[lag] < ccfmin Then
          Begin
               ccfmin := ccf[lag];  // Minimal value of x
               lagmin := lag;       // Index to this in ccf array
          end;
     end;

     // Leaving above I have the peak and mimimum in ccfmax and ccfmin with the index to max in lagpk0 and min lin lagmin.
     // lagmin only matters if sync is inverted in which case it becomes the max.

     ccf0 := ccfmax;  // Peak value of sync correlation
     flip := 1.0;     // Sync is not inverted

     // Check for inverted sync
     if -ccfmin > ccfmax then
     Begin
          for lag := lag1 to lag2 do ccf[lag] := -ccf[lag];
          lagpk0 := lagmin;
          ccf0  := -ccfmin;
          flip := -1.0;
     end;
end;

// Utility methods in place above - now to the demod routines in specific starting with sync detect (single then multi)

procedure jl_sync65(const dat : Array of CTypes.cfloat; const jz : CTypes.cint; const cf : CTypes.cfloat; const bw : CTypes.cfloat; var dtx,dfx,snrx,snrsync,flip : CTypes.cfloat);
Var
   t1,t2                  : TDateTime;
   span                   : Double;
   s2                     : Array[0..1023,0..319] of CTypes.cfloat;
   s2t                    : Array[0..319] Of CTypes.cfloat;
   pstmpI                 : Array[0..2047] Of CTypes.cfloat;
   pstmpO                 : Array[0..1023] Of CTypes.cfloat;
   i,j,k,nsym,nfft,nsteps : CTypes.cint;
   nh,ia,ib,lag1,lag2  : CTypes.cint;
   ipk,lag  : CTypes.cint;
   df,famin,fbmax,fa,fb   : CTypes.cfloat;
   syncbest,syncbest2  : CTypes.cfloat;
   ccf0,lagpk0,sync,lagpk : CTypes.cfloat;
   ppmax,sq,ccfmax : CTypes.cfloat;
   xlag,dx2,nsq,istart : CTypes.cfloat;
   rms,tf2   : CTypes.cfloat;
   dt        : CTypes.cfloat;
Begin
     t1 := now;
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);

     nsym   := 126;
     nfft   := 2048;
     nh     := nfft div 2;
     nsteps := 2 * jz div nfft - 1; // comes out to 254

     for i := 0 to 319 do
     begin
          for j := 0 to 1023 do s2[j,i] := 0.0;
     end;

     nfft := 2048;
     df   := 5512.5/nfft; // Downsampled 2X so SR is now 5512.5 giving df as 2.691650390625

     for i := 0 to length(glPSAvg)-1 do glPSAvg[i] := 0;

     // An interesting implication to this is I could be doing this in real time.
     for j := 0 to nsteps - 1 do
     begin
          // Ok I see now.  It just walks the samples in 2K blocks grabbing a power spectrum for each into s2[a,b]
          k := j*nh;  // so j=0 k=0, j=1 k=1024, j=2 k=2048, j=254 k=260096 and this makes sense since it's stepping half symbol length (4096)
                      // but since 2X downsample this would be 2048 div 2 = 1024.
          // Not calling limit as it seems it does all of nothing in this context.
          for i := 0 to 2047 do pstmpI[i] := dat[k+i];
          for i := 0 to 1023 do pstmpO[i] := 0.0;
          jl_ps(pstmpI,nfft,pstmpO);
          for i := 0 to 1023 do s2[i,j] := pstmpO[i];
          // Add last PS calc to psavg accumulator
          for i := 0 to length(glPSAvg)-1 do glPSAvg[i] := glPSAvg[i]+pstmpO[i];
     end;

     famin := 3.0;
     fbmax := 2700.0;

     fa := 0.0;
     fb := 0.0;

     fa := 1270.46+cf-bw;
     fb := 1270.46+cf+bw;

     if fa < famin then fa := famin;
     if fb > fbmax then fb := fbmax;

     nfft := 2048;
     df   := 5512.5/nfft; // Downsampled 2X so SR is now 5512.5 giving df as 2.691650390625

     ia := round(fa/df);
     ib := round(fb/df);

     //i0 := round(1270.46/df);

     lag1 := 0;
     lag2 := 64;

     sync      := -1.e30;
     syncbest  := -1.e30;
     syncbest2 := -1.e30;

     ccf0    := 0.0;
     lagpk0  := 0.0;
     flip    := 0.0;
     dtx     := 0.0;
     dfx     := 0.0;
     snrx    := 0.0;
     snrsync := 0.0;

     for i := 0 to 545 do glCCF[i] := 0.0;

     for i := ia to ib do
     begin
          // ia to ib defines the bins to evaluate based upon the bandwidth and center frequency
          // Need to copy a slice of s2 to a temporary processing holder.
          // But it's a slice of s2[i,0 .. i,254]
          // Now we're looking at s2 which is the series of PS points taken for the entire frame
          // in chunks calling the correlator where i defines a bin (frequency point) and j defines
          // a slice of time.
          // Now it's interesting here... I'm looking at 254 slices (time axis) of the 320 allocated
          // 320 comes from looking at symbol times at 1/2 symbol (1/11025 * 4096) steps over 60 seconds
          // This give (1/11025)*4096 = 371.5 ms giving 161.5 symbol periods per minute * 2 = 323
          // The ia to ib range defines the bin range to look at (Frequency points)
          // Starting to understand this I see I want to start looking at data before second = 0 maybe
          // from about 58 to 48 of new minute.  This would certainly improve my implementation's lack
          // of robustness in handling negative time offsets.
          //
          // Now... more understanding needed but I'd like to start calculating the correlation in real
          // time vs batching it at end.  This may mean for strong signals I might have a correlation
          // with sufficient confidence well before frame is complete (and a decode) while the weakest
          // will need an entire sample set to zero in on.
          //
          // Bad news is with the interleaved sync and data it will be difficult to completely remove
          // need to look at an entire frame.  I'm starting to think sending the sync alone first followed
          // by data might have some merit in that I could find sync quickly.  And increase sending rate
          // of sync by 2 to 4x its current rate....
          // Right now sync takes 63 * 371.5ms = 23.4045 seconds. At 4x 5.851125 seconds or 11.70225 for X2
          // giving a frame time of 23.4045 (data) + 11.70225 (sync) for 35.10675 or 29.255625 seconds
          // If I cut the symbol time to 2048 samples/symbol I'd be at 11.70225  x 2 for 23.4045
          // I think this is something I want to start experimenting with.
          //
          // Looking just at data... it's 72 bits data + 306 bits FEC per frame.  At 45 bits/second I'd be
          // sending that in 8.4 seconds using BFSK.  JT65 uses 64 symbol tones to convey 6 bits per tone.
          // Giving it a baud rate (baud rate is symbol change time NOT bit rate) of about 2.7 baud but the
          // bit rate is 6x or 16.15 bits/second for 23.41 seconds data time (Sync takes up an equal amount)
          // giving the 46.81 second frame time.
          // For experimenting with MSK I could go to a symbol time of 1/12000 (yes moving to 12K s/s rate)
          // at 1024 samples per symbol time. For 11.71875 baud BFSK needing 32.256 seconds (data time) or
          // 512 samples per symbol time for 23.4375 baud BFSK needing 16.128 or 45.45 baud BFSK for 8.317
          // seconds.  I have a source for a 45.45 baud MSK modem.  :)  Symbol spacing for MSK is 1/2 baud
          // rate or  22.725 Hz
          // Next question is....
          // Can I do away with all this time sync to UTC and transmission of a sync vector and simply do
          // this as.... MSK RTTY on steroids?
          //
          // What a correlator should do is give a figure of merit for the match between an unknown
          // set of samples and a known one
          // s2                     : Array[0..1023,0..319] of CTypes.cfloat;

          for j := 0 to nsteps-1 do s2t[j] := s2[i,j];
          // Call correlator
          jl_xcor(s2t,nsteps,nsym,lag1,lag2,glCCF,ccf0,lagpk0,flip);

          tf2 := lagpk0+1.0; // Why +1?

          // Testing for k1 or k2 being out of array bounds
          if (tf2<0) or (tf2>545) Then
          Begin
               tf2 := tf2; // This would be an error
          end;
          // In JT's code slope is called starting at ccfblue[-5],59-5+1
          // lag1 = -5
          // lag2 = 59
          // lagpk0 = var
          //call slope(ccfblue(lag1),lag2-lag1+1,lagpk0-lag1+1.0)
          // so this goes;
          // call slope(ccfblue(-5),59-5+1,lagpk0--5+1.0)
          //k1 := (lag2-5)-5+1; // 55,55,55 so this sets the lag2 point to its fixed place -4
          //k1 := 55;
          //k2 := round(lagpk0-(lag1-5)+1); // 70 with lagpk0=64,13 with lagpk0=7,12 with lagpk0=6
          // adds 6 to lagpk0 - I suspect the +1 is what I need as it seems the +5 just gets it
          // out of - land in the -5 based array.
          // and I'm calling it with ccfblue[0],64,var where var is like 59,59,49,58  vs JT's     64,64,54,63
          // I'm thinking tf2 below is correct but not sure about lag2 being nailed to 64
          // Actually looking at slope... it doesn't care.  It does some magic about the tf2 points
          // but other than that seems to have no deps on the specific data format of ccfblue
          // Looking at slope source code I see;
          // Remove best-fit slope from data in y(i).  When fitting the straight
          // line, ignore the peak around xpk +/- 2.
          // And slope processes from start of array to 2nd parameter as index
          // while third parameter defines the xpk point mentioned above.
          // Soooooooooooo.... :)  Doesn't seem to matter about the change in array index basis
          // And I'm setting 2nd parameter at 55 fixed in mine as well since JT's redefines the
          // array in slope running from x[i=1] to x[i=55]
          jl_slope(glCCF,55,tf2);

          sync := abs(glCCF[round(lagpk0)]);

          ppmax := glPSAvg[i]-1.0;
          if sync > syncbest2 Then
          Begin
               //ipk2 := i;
               //lagpk2 := lagpk0;
               syncbest2 := sync;
          end;
          if ppmax > 0.2938 Then
          Begin
               if sync > syncbest Then
               Begin
                    ipk := i;
                    lagpk := lagpk0;
                    syncbest := sync;
               end;
          end;
     end;
     // Now have found the best (strongest) sync point within the resolution of BW at CF
     // Interesting question.  Is CF referenced at -1000 ... 0 ... +1000 as in JT65 DF axis
     // or real frequency as in 1270.5?  Seems to be JT65 DF Axis looking at d65.doDecode

     if syncbest > -10.0001 Then
     Begin
          //base := 0.25*(psavg[ipk-3]+psavg[ipk-2]+psavg[ipk+2]+psavg[ipk+3]);
          // Note i0 is a constant i0 := 1270.46/(5512.5/2048) = 1270.46/2.691650390625 = 472.00037732426303854875283446712
          dfx  := (ipk-472.0)*df; // Now have dfx for the return this is JT65 DF of sync detected. (And this is spot on with normal code now \0/)


          // Copy correct slice of s2[ipk,0 .. ipk,254]
          for j := 0 to nsteps-1 do s2t[j] := s2[ipk,j];
          ccfmax := 0.0;
          lag1 := 0;
          lag2 := 64;
          // Call correlator
          jl_xcor(s2t,nsteps,nsym,lag1,lag2,glCCF,ccfmax,lagpk,flip);
          xlag := lagpk;
          if (lagpk > lag1+5) and (lagpk < lag2+5) Then
          Begin
               dx2 := 0.0;
               //procedure peakup(var ym,y0,yp,dx : CTypes.cfloat);
               jl_peakup(glCCF[Round(lagpk-1)],ccfmax,glCCF[Round(lagpk+1)],dx2);
               xlag := lagpk+dx2;
          end;

          tf2 := xlag-lag1+1.0;
          jl_slope(glCCF,55,tf2);

          sq  := 0.0;
          nsq := 0.0;
          for lag := lag1 to lag2 do
          begin
               if abs(lag-xlag) > 2.0 Then
               begin
                    sq := sq + power(glCCF[lag],2);
                    nsq := nsq+1;
               end;
          end;
          rms := sqrt(sq/nsq);
          snrsync := abs(glCCF[Round(lagpk)-1])/rms - 1.1; // Now have snrsync and flip for return

          dt := 2.0/11025.0;
          istart := xlag*nh;
          dtx := istart*dt; // Now have dtx for return
          dtx := dtx;

          snrx := -99.0;

          ppmax := glPSAvg[ipk]-1.0;
          if ppmax > 0.0001 then snrx := jdb(ppmax*df/2500.0);
          if snrx < -33.0 then snrx := -33.0;  // Now have snrx for return
          //
          //// Do I really care about width of sync tone?  Not really for now, so we're done here.

     end
     else
     Begin
          // Didn't find sync at > -30 dB so take the best found
          // Note:  I'm thinking I don't want to do the rest if
          // nothing > -30 found... but will for now.
          snrx := -9999.9;
          snrsync := -9999.9;
          dtx := -9999.9;
          dfx := -9999.9;
     end;

     t2 := now;
     span := MilliSecondSpan(t1,t2);
     span := span;
end;

end.

