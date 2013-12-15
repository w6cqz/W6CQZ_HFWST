unit d65;
//
// Copyright (c) 2008,2009,2010,2011,2012,2013 J C Large - W6CQZ
//
//
// JT65-HF is the legal property of its developer.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; see the file COPYING. If not, write to
// the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
// Boston, MA 02110-1301, USA.
//

{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils, CTypes, math, Process, Types, StrUtils, FileUtil, DateUtils;

Const
  JT_DLL = 'JT65v392.dll';
  WordDelimiter = [' '];
  CsvDelim = [','];

Type
   decodeRec = Record
      numSync   : Integer;
      dsigLevel : Integer;
      deltaTime : Single;
      deltaFreq : Single;
      sigW      : Integer;
      cSync     : String;
      bDecoded  : String;
      kDecoded  : String;
      sDecoded  : String;
      timeStamp : String;
   end;

   d65Result = Record
      dtTimeStamp : String;
      dtNumSync   : String;
      dtSigLevel  : String;
      dtDeltaTime : String;
      dtDeltaFreq : String;
      dtSigW      : String;
      dtCharSync  : String;
      dtDecoded   : String;
      dtProcessed : Boolean;
      dtType      : String;
   end;

   decTrace = Record
      trDTX       : CTypes.cfloat;
      trDFX       : CTypes.cfloat;
      trSNR       : CTypes.cfloat;
      trBIN       : CTypes.cint;
      trDEC       : String;
      trRES       : Boolean;
      trDIS       : Boolean;
      trTIM       : Double;
   end;

   msyncresult = Record
      df          : CTypes.cfloat;
      dt          : CTypes.cfloat;
      snr         : CTypes.cfloat;
      syn         : CTypes.cfloat;
      flip        : CTypes.cfloat;
      bin         : CTypes.cint;
   end;



Var
   gldecOut, glsort1             : TStringList;
   glmyline, glwisfile, glkvs    : PChar;
   glmcall, glmline, glkvfname   : PChar;
   gld65timestamp                : String;
   dmtmpdir                      : String;
   dmwispath                     : String;
   dmTimeStamp                   : String;
   gldecoderPass                 : CTypes.cint;
   glMouseDF,glNblank            : CTypes.cint;
   glNshift, glDFTolerance       : CTypes.cint;
   glNzap, glmode65              : CTypes.cint;
   glstepBW, glsteps, glbinspace : CTypes.cint;
   glsbinspace                   : CTypes.cint;
   glfftFWisdom                  : CTypes.cint;
   dmPlotCount                   : CTypes.cint;
   dmrcount,dmkvhangs            : CTypes.cint;
   dmSynPoints, dmMerged         : CTypes.cint;
   glSampOffset                  : CTypes.cint;
   glDecCount                    : CTypes.cuint32;
   glDemodCount                  : CTypes.cuint32;
   glRunCount                    : CTypes.cuint32;
   glinBuffer                    : Array[0..661503] of CTypes.cint16;
   glf1Buffer,glf2Buffer,gllpfM  : Array[0..661503] of CTypes.cfloat;
   gld65decodes                  : Array[0..49] of d65Result;
   glDecTrace                    : Array[0..100] of decTrace;
   glSynDected,glSynFreq         : Array[0..254] of CTypes.cfloat;
   dmAveSQ, dmBaseVB             : CTypes.cfloat;
   dmPlotAvgSq                   : CTypes.cfloat;
   glBinCount                    : CTypes.cdouble;
   glDTAvg,dmKVWasted            : CTypes.cdouble;
   dmruntime,dmarun,dmnzrun      : CTypes.cdouble;
   glnz,glUseKV,glUseWisdom      : Boolean;
   glnd65firstrun, glinprog      : Boolean;
   gld65HaveDecodes              : Boolean;

procedure doDecode(bStart, bEnd : Integer);

implementation
// This unit provides decoding of JT65 signals in a thread.  The thread is
// initialized and started in maincode and runs from program start to end
// controlled by var doDecodePass, but must be suspended when not in active
// use... if left looping it will consume 100% CPU in its infinite do nothing
// loop.
//
// When doDecodePass = True the thread will execute doDecode() returning any
// decodes to array of decodeResult record which maincode will poll to pick up
// any decode(s).  Var inProgress indicates the decoder is actually running.

procedure  set65(
                ); cdecl; external JT_DLL name 'setup65_';

procedure  msync(dat,
                 jz,
                 syncount,
                 dtxa,
                 dfxa,
                 snrxa,
                 snrsynca,
                 ical,
                 wisfile : Pointer
                ); cdecl; external JT_DLL name 'msync65_';

procedure  msync2(dat,
                 jz,
                 syncount,
                 dtxa,
                 dfxa,
                 snrxa,
                 snrsynca,
                 flipa,
                 ical,
                 wisfile : Pointer
                ); cdecl; external JT_DLL name 'msync65v2_';

procedure  shdec(dat,
                 jz,
                 MouseDF,
                 DFTolerance,
                 nspecial,
                 nstest,
                 dfsh,
                 iderrsh,
                 idriftsh,
                 snrsh,
                 nwsh,
                 idfsh,
                 ical,
                 wisfile : Pointer
                ); cdecl; external JT_DLL name 'short65_';

procedure unpack(dat,
                 msg : Pointer
                ); cdecl; external JT_DLL name 'unpackmsg_';

procedure cqz65(dat,
                jz,
                DFTolerance,
                NAFC,
                MouseDF2,
                idf,
                mline,
                ical,
                wisfile,
                kvfile : Pointer
               ); cdecl; external JT_DLL name 'cqz65_';

procedure cqz65v2(dat,
                  npts,
                  dtx,
                  dfx,
                  flip,
                  ical,
                  wisfile,
                  kvfile,
                  mline : Pointer
               ); cdecl; external JT_DLL name 'cqz65v2_';

procedure  lpf1(dat,
                jz,
                nz,
                mousedf,
                mousedf2,
                ical,
                wisfile : Pointer
               ); cdecl; external JT_DLL name 'lpf1_';

function     db(x : CTypes.cfloat) : CTypes.cfloat;
Begin
     Result := -99.0;
     if x > 1.259e-10 Then Result := 10.0 * log10(x);
end;

function  evalBM(s : String) : Boolean;
Var
   wcount : Integer;
   w      : String;
Begin
     Result := False;
     // Looking for a BM decode
     wcount := WordCount(s,CsvDelim);
     if wcount < 7 Then
     Begin
          Result := False;
     End
     Else
     Begin
          w := ExtractWord(7,s,CsvDelim);
          if Length(TrimLeft(TrimRight(w))) > 0 Then Result := True else Result := False;
     End;
end;

Function evalKV(Var kdec : String) : Boolean;
Var
   kvSec2,kvCount,ierr,i,j : CTypes.cint;
   kvProc                  : TProcess;
   kvDat                   : Array[0..11] of CTypes.cint;
   kvFile                  : File Of CTypes.cint;
   kvfullname              : String;
   kvwaste1,kvwaste2       : TDateTime;
Begin
     if glUseKV Then
     Begin
          // Looking for a KV decode
          Result := false;
          kdec := '';
          glkvs := '                      ';
          for i := 0 to 11 do kvDat[i] := 0;
          ierr := 0;
          kvfullname := dmtmpdir+'KVASD.DAT';
          if SysUtils.FileExists(kvfullname) Then
          Begin
               kvProc := TProcess.Create(nil);
               kvProc.Executable := dmtmpdir + 'kvasd.exe';
               kvProc.Parameters.Append('-q');
               kvProc.CurrentDirectory := dmtmpdir;
               kvProc.Options := kvProc.Options + [poWaitOnExit];
               kvProc.Options := kvProc.Options + [poNoConsole];
               kvProc.Execute;
               ierr := kvProc.ExitStatus;
          End
          Else
          Begin
               ierr := -1;
          end;

          if ierr = 0 Then
          Begin
               Try
                  // read kvasd.dat
                  AssignFile(kvFile, kvfullname);
                  Reset(kvFile);
                  j:=System.FileSize(kvfile);
                  If j > 256 Then
                  Begin
                       // Seek to nsec2 (256)
                       Seek(kvFile,256);
                       Read(kvFile, kvsec2);
                       Seek(kvFile,257);
                       Read(kvFile, kvcount);
                       For i := 258 to 269 do
                       Begin
                            Seek(kvFile, i);
                            Read(kvFile, kvDat[i-258]);
                       End;
                       CloseFile(kvFile);
                       if kvCount > -1 Then
                       Begin
                            unpack(@kvDat[0],glkvs);
                       End
                       Else
                       Begin
                            // No decode, kvasd failed to reconstruct message.
                            Result := False;
                            kdec := '';
                       End;
                  End
                  Else
                  Begin
                       CloseFile(kvFile);
                       Result := False;
                       kdec := '';
                  End;
               except
                  Result := False;
                  kdec := '';
               end;
          End
          Else
          Begin
               // No decode, error status returned from kvasd.exe
               Result := False;
               kdec := '';
          End;
          kvProc.Destroy;
          kdec := TrimLeft(TrimRight(StrPas(glkvs)));
          if (Length(kdec) > 0) And (kvCount > -1) Then
          Begin
               Result := True;
          End
          Else
          Begin
               // No decode, kvasd messge too short or SNR too low.
               Result := False;
               kdec := '';
          End;
     end
     else
     begin
          Result := False;
          kdec := '';
     end;

     // Clean up
     kvWaste1      := Now;
     try
        FileUtil.DeleteFileUTF8(kvfullname);
     except
        // No action required
     end;
     j := 0;
     if FileExists(kvfullname) Then
     Begin
          repeat
                try
                   FileUtil.DeleteFileUTF8(kvfullname);
                except
                   // No action required
                end;
                inc(j);
          until (j>9) or not FileExists(kvfullname);
     end;
     if j>0 then dmKVHangs := dmKVHangs+j;
     kvWaste2      := Now;
     dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
end;

procedure doDecode(bStart, bEnd : Integer);

Var
   i,k,n,jz,nave,ifoo,ndec,lical     : CTypes.cint;
   idf,bw,afc,lmousedf,mousedf2      : CTypes.cint;
   jz2,j,wcount,strongest,syncount   : CTypes.cint;
   passcount,passtest,binspace       : CTypes.cint;
   btest,imin,imax                   : CTypes.cint;
   allEqual,haveDupe,devel           : Boolean;
   avesq,basevb,ffoo,scale,fsum,fave : CTypes.cfloat;
   sq,fmin,fmax,f1,f2,f3             : CTypes.cfloat;
   dfxa,snrxa,snrsynca,dtxa,flipa    : Array[0..254] Of CTypes.cfloat;
   dfx,snrsync,dtx,flip,ftest        : CTypes.cfloat;
   bins                              : Array[0..100] Of CTypes.cint;
   decArray                          : Array[0..99] Of String;
   foo,kdec,dupeFoo,foo2,foo3        : String;
   decode                            : decodeRec;
   dmenter,dmexit,kvwaste1,kvwaste2  : TDateTime;
   nzenter,nzexit                    : TDateTime;
   nzspan,dtadj                      : Double;
   synres,synres2,synres3,synres4    : Array of msyncresult;


begin
     // General setup for pass
     glinprog := True;
     dmenter      := Now;
     gld65HaveDecodes := False;
     nzspan := 0;
     jz := bEnd;

     // Hard coding these... used to be variable in JT65-HF
     glNBlank := 0;
     afc := 1;


     // Counts how many times KV would let me delete KVASD.DAT during this run
     dmKVHangs := 0;
     // Counts time wasted deleting locked KVASD.DAT file
     dmKVWasted := 0.0;

     // Figure out if we're being wise or not
     //
     // ical =  0 = FFTW_ESTIMATE set, no load/no save wisdom.  Use ical = 0 when all else fails.
     // ical =  1 = FFTW_MEASURE set, yes load/no save wisdom.  Use ical = 1 to load saved wisdom.
     // ical = 11 = FFTW_MEASURE set, no load/no save wisdom.  Use ical = 11 when wisdom has been loaded and does not need saving.
     // ical = 21 = FFTW_MEASURE set, no load/yes save wisdom.  Use ical = 21 to save wisdom.
     //
     if not glUseWisdom
     Then
     Begin
          lical := 0;
     end
     else
     begin
          if glfftFWisdom > -1 Then
          Begin
               if glfftFWisdom = 1 Then
               Begin
                    if glnd65FirstRun Then lical := 1 else lical := 11;
               End;
               if glfftFWisdom = 21 Then
               Begin
                    if glnd65FirstRun Then lical := 21 else lical := 11;
               End;
          end;
     End;

     // Specials for first run
     if glnd65FirstRun Then
     Begin
          dmPlotCount := 0;
          glRunCount := 1;
          glDTAvg    := 0.0;
          glDemodCount := 0;
          glSampOffset := 2048;
          glmline := StrAlloc(72);
          glmcall := StrAlloc(12);
          glmyline := StrAlloc(43);
          glkvs := StrAlloc(22);
          glwisfile := StrAlloc(256);
          StrPCopy(glwisfile,PadRight(dmwisPath,255));
          glkvfname := StrAlloc(256);
          StrPCopy(glkvfname,PadRight(dmtmpdir+'KVASD.DAT',255));

          gldecOut := TStringList.Create;
          gldecOut.CaseSensitive := False;
          gldecOut.Sorted := False; // was true
          gldecOut.Duplicates := Types.dupIgnore;
          glsort1 := TStringList.Create;
          glsort1.CaseSensitive := False;
          glsort1.Sorted := False;
          glsort1.Duplicates := Types.dupIgnore;
          // Clear internal buffers
          for i := 0 to 661503 do
          Begin
               glf1Buffer[i] := 0.0;
               gllpfM[i] := 0.0;
          end;
          for i := 0 to 99 do
          Begin
               decArray[i] := '';
          end;
     End
     Else
     Begin
          // Clear internal buffers
          glDemodCount := 0;
          Inc(glRunCount);
          for i := 0 to 661503 do
          Begin
               glf1Buffer[i] := 0.0;
               glf2Buffer[i] := 0.0;
               gllpfM[i] := 0.0;
          end;
          for i := 0 to 99 do
          Begin
               decArray[i] := '';
          end;
     End;

     // General housekeeping for a start of decoder cycle
     glmline := '                                                                        ';
     glmcall := '            ';
     glmyline := '                                           ';
     // [d65.]glinBuffer contains 16 bit signed integer input samples and has
     // been populated from maincode.
     // I'm creating 2 versions of this.  One done exactly as in JT65-HF and
     // another with my various attempts to optimize decoder in play.

     // This is the new method that should run if faster decoding is enabled
     if glNZ Then
     Begin
          fsum := 0.0;
          nave := 0;
          for i := bStart to bEnd do fsum := fsum + glinBuffer[i];
          nave := Round(fsum/bEnd);
          if nave <> 0 Then for i := bStart to bEnd do glinBuffer[i] := min(32767,max(-32768,glinBuffer[i]-nave));
          imin :=  32768;
          imax := -32769;
          for i := bStart to bEnd do
          begin
               if glInBuffer[i] > imax then imax := glInBuffer[i];
               if glInBuffer[i] < imin then imin := glInBuffer[i];
          end;
          if abs(imin) > abs(imax) Then scale := abs(imin) else scale := abs(imax);
          fsum := 0.0;
          fmin :=  1e30;
          fmax := -1e30;
          for i := bStart to bEnd do
          Begin
               glf1Buffer[i] := glinBuffer[i]/scale;
               if glf1Buffer[i] > fmax then fmax := glf1Buffer[i];
               if glf1Buffer[i] < fmin then fmin := glf1Buffer[i];
          End;
          // From this point on glf1Buffer becomes sole sample holder.
          // Figure average level
          sq := 0.0;
          for i := bStart to bEnd do
          begin
               ffoo := glf1Buffer[i];
               if ffoo <> 0 Then sq := sq + power(ffoo,2);
          end;
          avesq := sq/jz;
          basevb := db(avesq) - 44;
          dmAveSQ  := aveSQ;
          dmBaseVB := baseVB;
          dmPlotAvgsq := db(avesq);
     end
     else
     begin
          // Convert glinBuffer to glf1buffer (int16 to float)
          fsum := 0.0;
          nave := 0;
          for i := bStart to bEnd do fsum := fsum + glinBuffer[i];
          nave := Round(fsum/bEnd);
          for i := bStart to bEnd do glinBuffer[i] := min(32767,max(-32768,glinBuffer[i]-nave));
          fsum := 0.0;
          fave := 0.0;
          for i := bStart to bEnd do
          Begin
               glf1Buffer[i] := 0.1 * glinBuffer[i];
               fsum := fsum + glf1Buffer[i];
          End;
          fave := fsum/bEnd;
          for i := bStart to bEnd do glf1Buffer[i] := glf1Buffer[i]-fave;
          // Int16 converted to float
          sq := 0.0;
          for i := bStart to bEnd do
          begin
               ffoo := glf1Buffer[i];
               if ffoo <> 0 Then sq := sq + power(ffoo,2);
          end;
          avesq := sq/jz;
          basevb := db(avesq) - 44;
          dmAveSQ  := aveSQ;
          dmBaseVB := baseVB;
          dmPlotAvgsq := db(avesq);
     end;

     ndec := 0;
     set65();

     lmousedf := 0;
     jz2 := 0;
     mousedf2 := 0;
     for i := 0 to jz do gllpfM[i] := glf1Buffer[i];

     // User WSJT LPF or simple decimate 2x based on classic or new demod choice
     if glnz then
     Begin
          // Since I'm not doing the lpf I'll do the simple 2x decimate here.
          j := 0;
          for i := 0 to jz do
          begin
               if odd(i) then
               begin
                    gllpfM[j] := glf1Buffer[i];
                    inc(j);
               end;
          end;
          jz2 := 262143;// POT transform on 262144 samples. 0..262143 = 262144
     end
     else
     begin
          lpf1(@gllpfM[0], @jz, @jz2, @lmousedf, @mousedf2, @lical, glwisfile);
     end;
     // Pad gllpfM just to be sure nothing get stuck on the (should be) unused tail
     for j := jz2 to length(gllpfM)-1 do glLPFM[j] := 0.0;

     // Clear the bins
     for i := 0 to 100 do bins[i] := 0;
     // Clear msync detect array structures
     for i := 0 to 254 do
     begin
          dtxa[i]     := 0.0;
          dfxa[i]     := -9999.0;
          snrxa[i]    := 0.0;
          snrsynca[i] := 0.0;
          flipa[i]    := 0.0;
     end;
     // Call msync to see what we have to work with
     syncount := 0;
     msync(@gllpfM[0],@jz2,@syncount,@dtxa[0],@dfxa[0],@snrxa[0],@snrsynca[0],@lical,glwisfile);
     // Time to start USING the data I'm getting from msync.
     // 1 - If snrx < -29.5 kill it.
     // 2 - if dtx > 8 or < -8 kill it.
     // snrsync not needed
     // 3 - if dfx < -1100 or > 1100 kill it.
     // Just set dfx to -9999 then populate bins will ignore it.
     for i := 0 to 254 do
     begin
          glSynDected[i] := 0.0;
          glSynFreq[i] := 0.0;
     end;
     for i := 0 to 254 do
     begin
          glSynDected[i] := snrxa[i];
          glSynFreq[i] := dfxa[i];
     end;
     k := 0;
     if syncount > 0 Then
     Begin
          for i := 0 to 254 do
          begin
               if snrxa[i] < -29.5 Then
               Begin
                    dfxa[i] := -9999.0;
               end
               else if dtxa[i] < -8.0 Then
               Begin
                    dfxa[i] := -9999.0;
               end
               else if dtxa[i] > 8.0 Then
               Begin
                    dfxa[i] := -9999.0;
               end
               else if dfxa[i] < -1100.0 Then
               Begin
                    dfxa[i] := -9999.0;
               end
               else if dfxa[i] > 1100.0 Then
               Begin
                    dfxa[i] := -9999.0;
               end
               else if round(snrsynca[i]-3.0) < 1 Then
               Begin
                    dfxa[i] := -9999.0;
               end;
          end;
     end;

     // This isn't quite there yet so forcing old demodulate methods
     devel := false;
     // At this point I can again fork to new vs old
     if devel Then
     Begin
          nzenter := now;
          // Attempt decodes using precomputed sync points from msync
          // Thinking about how to compact the sync detects to avoid decoding
          // passes on same signal that has bin spread.
          // If I start at first valid sync I want to look at all points that
          // run +20 of it and compact those into one choice, that being
          // strongest within 20 Hz.
          //
          // See how many sync points we have to work with.
          j := 0;
          for i := 0 to 254 do if dfxa[i] > -9999.0 then inc(j);
          dmSynPoints := j;
          if j > 1 Then
          Begin
               setlength(synres,j);
               setlength(synres2,j);
               for i := 0 to length(synres)-1 do
               begin
                    synres[i].df    := -9999.0;
                    synres2[i].df   := -9999.0;
                    synres[i].bin   := -1;
                    synres2[i].bin  := -1;
                    synres[i].flip  := 1.0; // Fix this later
                    synres2[i].flip := 1.0; // Fix this later
               end;
               j := 0;
               for i := 0 to 254 do
               begin
                    if dfxa[i] > -1200.0 Then
                    Begin
                         ftest := dfxa[i];
                         synres[j].df   := ftest;
                         synres[j].dt   := dtxa[i];
                         synres[j].snr  := snrxa[i];
                         synres[j].syn  := snrsynca[i];
                         inc(j);
                    end;
               end;
               // Now have all the sync detects that we need to work with
               // Assign bins based up -1010 to +1010 in 20 Hz steps

               for i := 0 to length(synres)-1 do
               begin
                    btest := Round(synres[i].df);
                    Case btest of
                         -1010..-990         : synres[i].bin := 0;  // -1000 +/- 10
                         -989..-970          : synres[i].bin := 1;  // -980 +/- 10
                         -969..-950          : synres[i].bin := 2;  // -960
                         -949..-930          : synres[i].bin := 3;  // -940
                         -929..-910          : synres[i].bin := 4;  // -920
                         -909..-890          : synres[i].bin := 5;  // -900
                         -889..-870          : synres[i].bin := 6;  // -880
                         -869..-850          : synres[i].bin := 7;  // -860
                         -849..-830          : synres[i].bin := 8;  // -840
                         -829..-810          : synres[i].bin := 9;  // -820
                         -809..-790          : synres[i].bin := 10; // -800
                         -789..-770          : synres[i].bin := 11; // -780
                         -769..-750          : synres[i].bin := 12; // -760
                         -749..-730          : synres[i].bin := 13; // -740
                         -729..-710          : synres[i].bin := 14; // -720
                         -709..-690          : synres[i].bin := 15; // -700
                         -689..-670          : synres[i].bin := 16; // -680
                         -669..-650          : synres[i].bin := 17; // -660
                         -649..-630          : synres[i].bin := 18; // -640
                         -629..-610          : synres[i].bin := 19; // -620
                         -609..-590          : synres[i].bin := 20; // -600
                         -589..-570          : synres[i].bin := 21; // -580
                         -569..-550          : synres[i].bin := 22; // -560
                         -549..-530          : synres[i].bin := 23; // -540
                         -529..-510          : synres[i].bin := 24; // -520
                         -509..-490          : synres[i].bin := 25; // -500
                         -489..-470          : synres[i].bin := 26; // -480
                         -469..-450          : synres[i].bin := 27; // -460
                         -449..-430          : synres[i].bin := 28; // -440
                         -429..-410          : synres[i].bin := 29; // -420
                         -409..-390          : synres[i].bin := 30; // -400
                         -389..-370          : synres[i].bin := 31; // -380
                         -369..-350          : synres[i].bin := 32; // -360
                         -349..-330          : synres[i].bin := 33; // -340
                         -329..-310          : synres[i].bin := 34; // -320
                         -309..-290          : synres[i].bin := 35; // -300
                         -289..-270          : synres[i].bin := 36; // -280
                         -269..-250          : synres[i].bin := 37; // -260
                         -249..-230          : synres[i].bin := 38; // -240
                         -229..-210          : synres[i].bin := 39; // -220
                         -209..-190          : synres[i].bin := 40; // -200
                         -189..-170          : synres[i].bin := 41; // -180
                         -169..-150          : synres[i].bin := 42; // -160
                         -149..-130          : synres[i].bin := 43; // -140
                         -129..-110          : synres[i].bin := 44; // -120
                         -109..-90           : synres[i].bin := 45; // -100
                         -89..-70            : synres[i].bin := 46; // -80
                         -69..-50            : synres[i].bin := 47; // -60
                         -49..-30            : synres[i].bin := 48; // -40
                         -29..-10            : synres[i].bin := 49; // -20
                         -9..10              : synres[i].bin := 50; // 0
                         11..30              : synres[i].bin := 51; // 20
                         31..50              : synres[i].bin := 52; // 40
                         51..70              : synres[i].bin := 53; // 60
                         71..90              : synres[i].bin := 54; // 80
                         91..110             : synres[i].bin := 55; // 100
                         111..130            : synres[i].bin := 56; // 120
                         131..150            : synres[i].bin := 57; // 140
                         151..170            : synres[i].bin := 58; // 160
                         171..190            : synres[i].bin := 59; // 180
                         191..210            : synres[i].bin := 60; // 200
                         211..230            : synres[i].bin := 61; // 220
                         231..250            : synres[i].bin := 62; // 240
                         251..270            : synres[i].bin := 63; // 260
                         271..290            : synres[i].bin := 64; // 280
                         291..310            : synres[i].bin := 65; // 300
                         311..330            : synres[i].bin := 66; // 320
                         331..350            : synres[i].bin := 67; // 340
                         351..370            : synres[i].bin := 68; // 360
                         371..390            : synres[i].bin := 69; // 380
                         391..410            : synres[i].bin := 70; // 400
                         411..430            : synres[i].bin := 71; // 420
                         431..450            : synres[i].bin := 72; // 440
                         451..470            : synres[i].bin := 73; // 460
                         471..490            : synres[i].bin := 74; // 480
                         491..510            : synres[i].bin := 75; // 500
                         511..530            : synres[i].bin := 76; // 520
                         531..550            : synres[i].bin := 77; // 540
                         551..570            : synres[i].bin := 78; // 560
                         571..590            : synres[i].bin := 79; // 580
                         591..610            : synres[i].bin := 80; // 600
                         611..630            : synres[i].bin := 81; // 620
                         631..650            : synres[i].bin := 82; // 640
                         651..670            : synres[i].bin := 83; // 660
                         671..690            : synres[i].bin := 84; // 680
                         691..710            : synres[i].bin := 85; // 700
                         711..730            : synres[i].bin := 86; // 720
                         731..750            : synres[i].bin := 87; // 740
                         751..770            : synres[i].bin := 88; // 760
                         771..790            : synres[i].bin := 89; // 780
                         791..810            : synres[i].bin := 90; // 800
                         811..830            : synres[i].bin := 91; // 820
                         831..850            : synres[i].bin := 92; // 840
                         851..870            : synres[i].bin := 93; // 860
                         871..890            : synres[i].bin := 94; // 880
                         891..910            : synres[i].bin := 95; // 900
                         911..930            : synres[i].bin := 96; // 920
                         931..950            : synres[i].bin := 97; // 940
                         951..970            : synres[i].bin := 98; // 960
                         971..990            : synres[i].bin := 99; // 980
                         991..1010           : synres[i].bin := 100; // 1000
                    end;
               end;

               // Each result has been placed into a bin assignment.  Now compress
               // any that may be multiples in single bin to 1 point based on strongest
               // wins.
               foo := '';
               for j := 0 to length(synres)-1 do foo := foo + IntToStr(synres[j].bin) + ',';

               for j := 0 to 100 do
               Begin
                    // I need to look for synres[x].bin = j and squash
                    // whatever count I have to 1.
                    // Find the max snr for this bin (j)
                    fmax := -1.0e30;
                    imax := -1;
                    for i := 0 to length(synres)-1 do
                    begin
                         ftest := synres[i].snr;
                         if (synres[i].bin = j) and (ftest > fmax) then
                         begin
                              imax := i;
                         end;
                    end;
                    // Have the strongest - move it to synres2[]
                    if imax > -1 Then
                    Begin
                         for i := 0 to length(synres)-1 do
                         begin
                              if synres2[i].df < -2000.0 Then
                              begin
                                   // Store this one here
                                   synres2[i].df   := synres[imax].df;
                                   synres2[i].dt   := synres[imax].dt;
                                   synres2[i].snr  := synres[imax].snr;
                                   synres2[i].syn  := synres[imax].syn;
                                   synres2[i].flip := synres[imax].flip;
                                   synres2[i].bin  := synres[imax].bin;
                                   break;
                              end;
                         end;
                    end;
               end;
               // Synres2 should now contain the compressed points.
               k := 0;
               for i := 0 to length(synres2)-1 do if synres2[i].df > -1200.0 then inc(k);
               // OK - now have synres2 holding the narrowed down subset of synres. I'm
               // now going to look for more that are very close and narrow again
               if k > 1 Then
               Begin
                    setlength(synres3,k); // Holds just the compressed set
                    j := 0;
                    for i := 0 to length(synres2)-1 do
                    begin
                         if synres2[i].df > -1200 Then
                         begin
                              synres3[j] := synres2[i];
                              inc(j);
                         end;
                    end;
                    // Synres3 now holding the set.  What I'm looking for is
                    // df less than 6 hz offset
                    i := 0;
                    j := 1;
                    repeat
                          // looking at pairs.
                          f1 := synres3[i].df;
                          f2 := synres3[j].df;
                          f3 := abs(f1-f2);
                          k  := round(f3);
                          if k < 6 Then
                          Begin
                               // I ***need*** to tune this.  6 Is probably too much.  Maybe 5 or 4 better.
                               // Squash again
                               if synres3[i].snr > synres3[j].snr Then synres3[j].bin := -1;
                               if synres3[j].snr > synres3[i].snr Then synres3[i].bin := -1;
                          end;
                          inc(i);
                          inc(j);
                    until j > length(synres3)-1;
                    // Now at long last I compress one more time to synres4
                    j := 0;
                    for i := 0 to length(synres3)-1 do if synres3[i].bin > -1 then inc(j);
                    if j > 0 Then
                    Begin
                         setLength(synres4,j);
                         j := 0;
                         for i := 0 to length(synres3)-1 do
                         begin
                              if synres3[i].bin > -1 then
                              begin
                                   synres4[j] := synres3[i];
                                   inc(j);
                              end;
                         end;
                    end;
               end
               else if k = 1 Then
               begin
                    // Odd, but suppose it can happen.
                    SetLength(synres4,1);
                    synres4[0] := synres[0];
               end
               else
               begin
                    // No sync
                    SetLength(synres4,0);
               end;
               setlength(synres,0);
               setlength(synres2,0);
               setlength(synres3,0);
          end
          else if j = 1 Then
          begin
               // Odd, but suppose it can happen.
               SetLength(synres4,1);
               for i := 0 to 254 do
               Begin
                    if dfxa[i] > -9999.0 then
                    Begin
                         synres4[j].df   := dfxa[i];
                         synres4[j].dt   := dtxa[i];
                         synres4[j].snr  := snrxa[i];
                         synres4[j].syn  := snrsynca[i];
                         synres4[j].flip := 1.0;
                         synres4[j].bin  := 0;
                    end;
               end;
          end
          else
          begin
               // No sync detect
               SetLength(synres4,0);
          end;
          // Yay!  Finally get to try a demod using cqz65v2 routine.
          glBinCount := length(synres4);
          if length(synres4)>0 Then
          Begin
               //procedure cqz65v2(dat,
               //                  npts,
               //                  dtx,
               //                  dfx,
               //                  flip,
               //                  ical,
               //                  wisfile,
               //                  kvfile,
               //                  mline : Pointer
               //               ); cdecl; external JT_DLL name 'cqz65v2_';
               foo3 := '';
               for i := 0 to length(synres4)-1 do
               begin
                    // Attempting to insure KVASD.DAT does not exist.
                    j := 0;
                    if FileExists(dmtmpdir+'KVASD.DAT') Then
                    Begin
                         kvWaste1      := Now;
                         repeat
                               try
                                  FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                               except
                                  // No action required
                               end;
                               inc(j);
                         until (j>9) or not FileExists(dmtmpdir+'KVASD.DAT');
                         kvWaste2      := Now;
                         dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
                    end;
                    if j>0 Then dmKVHangs := dmKVHangs+j;
                    if FileExists(dmtmpdir+'KVASD.DAT') Then
                    Begin
                         kvWaste1      := Now;
                         try
                            FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                         except
                            // No action required
                         end;
                         try
                            FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                         except
                            // No action required
                         end;
                         kvWaste2      := Now;
                         dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
                    end;
                    // Run a decode pass for each entry
                    jz2 := 262143;// POT transform on 262144 samples. 0..262143 = 262144
                    dtx := synres4[i].dt;
                    dfx := synres4[i].df;
                    flip := 1.0;
                    glmline := '                                                                        ';
                    for j := 0 to jz2-1 do glf2Buffer[j] := gllpfM[j];
                    for j := jz2 to length(glf2Buffer)-1 do glf2Buffer[j] := 0.0;
                    dtadj := dtx/(1.0/11025.0);
                    // dtadj is the amount of samples to move range is 0 to 8192
                    j := round(dtadj);
                    if j < 0 then j :=0;
                    if j > 8192 then j := 8192;
                    cqz65v2(@glf2Buffer[j],@jz2,@dtx,@dfx,@flip,@lical,glwisfile,glkvfname,glmline);
                    ifoo := 0;
                    foo := '';
                    foo2 := StrPas(glmline);
                    foo2 := TrimLeft(TrimRight(foo2));
                    foo3 := '';
                    if i < 10 then foo := '0' + IntToStr(i) + ',' + IntToStr(Round(synres4[i].df)) + ',10,' + IntToStr(Round(synres4[i].snr)) + ',' + FormatFloat('#.#',synres4[i].dt) + ',*,' else foo := IntToStr(i) + ',' + IntToStr(Round(synres4[i].df)) + ',10,' + IntToStr(Round(synres4[i].snr)) + ',' + FormatFloat('#.#',synres4[i].dt-1.0) + ',*,';
                    foo3 := foo + foo2;
                    if tryStrToInt(ExtractWord(3,foo3,CsvDelim),ifoo) Then
                    Begin
                         if ifoo > 0 Then
                         Begin
                              if evalBM(foo3) Then
                              Begin
                                   inc(ndec);
                                   gldecOut.Add(TrimLeft(TrimRight(foo3)+',B'));
                                   for j := 0 to 99 do
                                   begin
                                        if decArray[j] = '' Then
                                        Begin
                                             decArray[j] := TrimLeft(TrimRight(foo3))+',B';
                                             break;
                                        end;
                                   end;
                              end
                              else
                              begin
                                   // Oh joy.  Time to try for kv.
                                   kdec := '';
                                   if FileExists(dmtmpdir+'KVASD.DAT') And glUseKV Then
                                   Begin
                                        if evalKV(kdec) Then
                                        Begin
                                             inc(ndec);
                                             // Seems I found a kv decode.
                                             foo3 := TrimLeft(TrimRight(foo)) + TrimLeft(TrimRight(kdec));
                                             gldecOut.Add(TrimLeft(TrimRight(foo3))+',K');
                                             for j := 0 to 99 do
                                             begin
                                                  if decArray[j] = '' Then
                                                  Begin
                                                       decArray[j] := TrimLeft(TrimRight(foo3))+',K';
                                                       break;
                                                  end;
                                             end;
                                             try
                                                FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                                             except
                                                // No action required
                                             end;
                                        end;
                                   end;
                              end;
                         end;
                    end;
                    // Attempting to insure KVASD.DAT does not exist.
                    j := 0;
                    if FileExists(dmtmpdir+'KVASD.DAT') Then
                    Begin
                         kvWaste1      := Now;
                         repeat
                               try
                                  FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                               except
                                  // No action required
                               end;
                               inc(j);
                         until (j>9) or not FileExists(dmtmpdir+'KVASD.DAT');
                         kvWaste2      := Now;
                         dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
                    end;
                    if j>0 Then dmKVHangs := dmKVHangs+j;
                    if FileExists(dmtmpdir+'KVASD.DAT') Then
                    Begin
                         kvWaste1      := Now;
                         try
                            FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                         except
                            // No action required
                         end;
                         try
                            FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                         except
                            // No action required
                         end;
                         kvWaste2      := Now;
                         dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
                    end;
               end;
               setLength(synres4,0);
          end;
          nzexit := now;
          nzspan := MilliSecondSpan(nzenter,nzexit);
          dmnzrun := nzspan;
     end
     else
     begin
          // Use regular method where a sync detect is ran again at the singular
          // narrow bin for the decode.  Wastes time.
          // Syncount is number of potential sync points.
          // Recalculate sync count since it may now be zero
          k := 0;
          for i := 0 to 254 do if dfxa[i] > -9999.0 Then inc(k);
          syncount := k;
          dmSynPoints := syncount;
          if syncount > 0 Then
          Begin
               // Get bin spacing
               if glsteps = 1 Then
               Begin
                    binspace := glbinspace;  // Multiple decode resolution
                    if glnz and (syncount > 19) and (binspace < 200) Then
                    Begin
                         binspace := 50;
                    end
                    else if glnz and (syncount > 29) and (binspace < 100) Then
                    Begin
                         binspace := 100;
                    end
                    else if glnz and (syncount > 59) and (binspace < 200) Then
                    Begin
                         binspace := 200;
                    end;
                    if glnz and (syncount < 3) and (binspace > 20) then binspace := 20;
                    // Now... take the syncount list and place a 'tick' in each
                    // 'bin' where a sync detect has been found.
                    // 2000 Hz / 20 Hz = 100 bins. (101 actually)
               end
               else
               begin
                    dmSynPoints := 1;
                    syncount := 1;
                    // Single decode cycle @ glMouseDF, glDFTolerance
                    // find bin where glMouseDF might live.
                    passtest := glMouseDF;
                    binspace := glDFTolerance;  // Single decode resolution
               end;
               for i := 0 to syncount-1 do
               begin
                    if glsteps = 1 then
                    begin
                         passtest := trunc(dfxa[i]);
                         binspace := glbinspace;  // Multiple decode resolution
                    end
                    else
                    begin
                         passtest := glMouseDF;
                         binspace := glDFTolerance;  // Single decode resolution
                    end;
                    If binspace = 20 Then
                    Begin
                         // 20 Hz Bins
                         Case passtest of
                              -1010..-990         : inc(bins[0]);  // -1000 +/- 10
                              -989..-970          : inc(bins[1]);  // -980 +/- 10
                              -969..-950          : inc(bins[2]);  // -960
                              -949..-930          : inc(bins[3]);  // -940
                              -929..-910          : inc(bins[4]);  // -920
                              -909..-890          : inc(bins[5]);  // -900
                              -889..-870          : inc(bins[6]);  // -880
                              -869..-850          : inc(bins[7]);  // -860
                              -849..-830          : inc(bins[8]);  // -840
                              -829..-810          : inc(bins[9]);  // -820
                              -809..-790          : inc(bins[10]); // -800
                              -789..-770          : inc(bins[11]); // -780
                              -769..-750          : inc(bins[12]); // -760
                              -749..-730          : inc(bins[13]); // -740
                              -729..-710          : inc(bins[14]); // -720
                              -709..-690          : inc(bins[15]); // -700
                              -689..-670          : inc(bins[16]); // -680
                              -669..-650          : inc(bins[17]); // -660
                              -649..-630          : inc(bins[18]); // -640
                              -629..-610          : inc(bins[19]); // -620
                              -609..-590          : inc(bins[20]); // -600
                              -589..-570          : inc(bins[21]); // -580
                              -569..-550          : inc(bins[22]); // -560
                              -549..-530          : inc(bins[23]); // -540
                              -529..-510          : inc(bins[24]); // -520
                              -509..-490          : inc(bins[25]); // -500
                              -489..-470          : inc(bins[26]); // -480
                              -469..-450          : inc(bins[27]); // -460
                              -449..-430          : inc(bins[28]); // -440
                              -429..-410          : inc(bins[29]); // -420
                              -409..-390          : inc(bins[30]); // -400
                              -389..-370          : inc(bins[31]); // -380
                              -369..-350          : inc(bins[32]); // -360
                              -349..-330          : inc(bins[33]); // -340
                              -329..-310          : inc(bins[34]); // -320
                              -309..-290          : inc(bins[35]); // -300
                              -289..-270          : inc(bins[36]); // -280
                              -269..-250          : inc(bins[37]); // -260
                              -249..-230          : inc(bins[38]); // -240
                              -229..-210          : inc(bins[39]); // -220
                              -209..-190          : inc(bins[40]); // -200
                              -189..-170          : inc(bins[41]); // -180
                              -169..-150          : inc(bins[42]); // -160
                              -149..-130          : inc(bins[43]); // -140
                              -129..-110          : inc(bins[44]); // -120
                              -109..-90           : inc(bins[45]); // -100
                              -89..-70            : inc(bins[46]); // -80
                              -69..-50            : inc(bins[47]); // -60
                              -49..-30            : inc(bins[48]); // -40
                              -29..-10            : inc(bins[49]); // -20
                              -9..10              : inc(bins[50]); // 0
                              11..30              : inc(bins[51]); // 20
                              31..50              : inc(bins[52]); // 40
                              51..70              : inc(bins[53]); // 60
                              71..90              : inc(bins[54]); // 80
                              91..110             : inc(bins[55]); // 100
                              111..130            : inc(bins[56]); // 120
                              131..150            : inc(bins[57]); // 140
                              151..170            : inc(bins[58]); // 160
                              171..190            : inc(bins[59]); // 180
                              191..210            : inc(bins[60]); // 200
                              211..230            : inc(bins[61]); // 220
                              231..250            : inc(bins[62]); // 240
                              251..270            : inc(bins[63]); // 260
                              271..290            : inc(bins[64]); // 280
                              291..310            : inc(bins[65]); // 300
                              311..330            : inc(bins[66]); // 320
                              331..350            : inc(bins[67]); // 340
                              351..370            : inc(bins[68]); // 360
                              371..390            : inc(bins[69]); // 380
                              391..410            : inc(bins[70]); // 400
                              411..430            : inc(bins[71]); // 420
                              431..450            : inc(bins[72]); // 440
                              451..470            : inc(bins[73]); // 460
                              471..490            : inc(bins[74]); // 480
                              491..510            : inc(bins[75]); // 500
                              511..530            : inc(bins[76]); // 520
                              531..550            : inc(bins[77]); // 540
                              551..570            : inc(bins[78]); // 560
                              571..590            : inc(bins[79]); // 580
                              591..610            : inc(bins[80]); // 600
                              611..630            : inc(bins[81]); // 620
                              631..650            : inc(bins[82]); // 640
                              651..670            : inc(bins[83]); // 660
                              671..690            : inc(bins[84]); // 680
                              691..710            : inc(bins[85]); // 700
                              711..730            : inc(bins[86]); // 720
                              731..750            : inc(bins[87]); // 740
                              751..770            : inc(bins[88]); // 760
                              771..790            : inc(bins[89]); // 780
                              791..810            : inc(bins[90]); // 800
                              811..830            : inc(bins[91]); // 820
                              831..850            : inc(bins[92]); // 840
                              851..870            : inc(bins[93]); // 860
                              871..890            : inc(bins[94]); // 880
                              891..910            : inc(bins[95]); // 900
                              911..930            : inc(bins[96]); // 920
                              931..950            : inc(bins[97]); // 940
                              951..970            : inc(bins[98]); // 960
                              971..990            : inc(bins[99]); // 980
                              991..1010           : inc(bins[100]); // 1000
                         End;
                    End;
                    if binspace = 50 Then
                    Begin
                         // 50 Hz Bins
                         Case passtest of
                              -1025..-975         : inc(bins[0]);  // -1000 +/- 25
                              -974..-925          : inc(bins[1]);  // -950 +/- 25
                              -924..-875          : inc(bins[2]);  // -900
                              -874..-825          : inc(bins[3]);  // -850
                              -824..-775          : inc(bins[4]);  // -800
                              -774..-725          : inc(bins[5]);  // -750
                              -724..-675          : inc(bins[6]);  // -700
                              -674..-625          : inc(bins[7]);  // -650
                              -624..-575          : inc(bins[8]);  // -600
                              -574..-525          : inc(bins[9]);  // -550
                              -524..-475          : inc(bins[10]); // -500
                              -474..-425          : inc(bins[11]); // -450
                              -424..-375          : inc(bins[12]); // -400
                              -374..-325          : inc(bins[13]); // -350
                              -324..-275          : inc(bins[14]); // -300
                              -274..-225          : inc(bins[15]); // -250
                              -224..-175          : inc(bins[16]); // -200
                              -174..-125          : inc(bins[17]); // -150
                              -124..-75           : inc(bins[18]); // -100
                              -74..-25            : inc(bins[19]); // -50
                              -24..25             : inc(bins[20]); // 0
                              26..75              : inc(bins[21]); // 50
                              76..125             : inc(bins[22]); // 100
                              126..175            : inc(bins[23]); // 150
                              176..225            : inc(bins[24]); // 200
                              226..275            : inc(bins[25]); // 250
                              276..325            : inc(bins[26]); // 300
                              326..375            : inc(bins[27]); // 350
                              376..425            : inc(bins[28]); // 400
                              426..475            : inc(bins[29]); // 450
                              476..525            : inc(bins[30]); // 500
                              526..575            : inc(bins[31]); // 550
                              576..625            : inc(bins[32]); // 600
                              626..675            : inc(bins[33]); // 650
                              676..725            : inc(bins[34]); // 700
                              726..775            : inc(bins[35]); // 750
                              776..825            : inc(bins[36]); // 800
                              826..875            : inc(bins[37]); // 850
                              876..925            : inc(bins[38]); // 900
                              926..975            : inc(bins[39]); // 950
                              976..1025           : inc(bins[40]); // 1000
                         End;
                    End;
                    if binspace = 100 Then
                    Begin
                         // 100 Hz Bins
                         Case passtest of
                              -1050..-950         : inc(bins[0]);  // -1000 +/- 50
                              -949..-850          : inc(bins[1]);  // -900 +/- 50
                              -849..-750          : inc(bins[2]);  // -800
                              -749..-650          : inc(bins[3]);  // -700
                              -649..-550          : inc(bins[4]);  // -600
                              -549..-450          : inc(bins[5]);  // -500
                              -449..-350          : inc(bins[6]);  // -400
                              -349..-250          : inc(bins[7]);  // -300
                              -249..-150          : inc(bins[8]);  // -200
                              -149..-50           : inc(bins[9]);  // -100
                              -49..50             : inc(bins[10]); // 0
                              51..150             : inc(bins[11]); // 100
                              151..250            : inc(bins[12]); // 200
                              251..350            : inc(bins[13]); // 300
                              351..450            : inc(bins[14]); // 400
                              451..550            : inc(bins[15]); // 500
                              551..650            : inc(bins[16]); // 600
                              651..750            : inc(bins[17]); // 700
                              751..850            : inc(bins[18]); // 800
                              851..950            : inc(bins[19]); // 900
                              951..1050           : inc(bins[20]); // 1000
                         End;
                    End;
                    if binspace = 200 Then
                    Begin
                         // 200 Hz Bins
                         Case passtest of
                              -1100..-900         : inc(bins[0]);  // -1000 +/- 100
                              -899..-700          : inc(bins[1]);  // -800
                              -699..-500          : inc(bins[2]);  // -600
                              -499..-300          : inc(bins[3]);  // -400
                              -299..-100          : inc(bins[4]);  // -200
                              -99..100            : inc(bins[5]);  // 0
                              101..300            : inc(bins[6]);  // 200
                              301..500            : inc(bins[7]);  // 400
                              501..700            : inc(bins[8]);  // 600
                              701..900            : inc(bins[9]);  // 800
                              901..1100           : inc(bins[10]); // 1000
                         End;
                    End;
               end;
               passcount := 0;
               for i := 0 to 100 do if bins[i] > 0 then
               begin
                    bins[i] := 1;
                    inc(passcount);
               end;
               dmMerged := passcount;
               glBinCount := passcount/1.0;
               ndec := 0;
               gldecOut.Clear;
               glsort1.Clear;
               if glSteps=0 then passcount := 1;
               // Process bins
               if passcount > 0 Then
               Begin
                    if glSteps = 0 Then
                    Begin
                         mousedf2 := glMouseDF;
                         bw := glDFTolerance;  // Single decode resolution
                         idf := 0;
                         glmline := '                                                                        ';
                         // Copy lpfM to f3Buffer
                         for j := 0 to jz2-1 do glf2Buffer[j] := gllpfM[j];
                         for j := jz2 to length(glf2Buffer)-1 do glf2Buffer[j] := 0.0;
                         // Attempting to insure KVASD.DAT does not exist.
                         j := 0;
                         if FileExists(dmtmpdir+'KVASD.DAT') Then
                         Begin
                              kvWaste1      := Now;
                              repeat
                                    try
                                       FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                                    except
                                       // No action required
                                    end;
                                    inc(j);
                              until (j>9) or not FileExists(dmtmpdir+'KVASD.DAT');
                              kvWaste2      := Now;
                              dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
                         end;
                         if j>0 Then dmKVHangs := dmKVHangs+j;
                         if FileExists(dmtmpdir+'KVASD.DAT') Then
                         Begin
                              kvWaste1      := Now;
                              try
                                 FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                              except
                                 // No action required
                              end;
                              try
                                 FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                              except
                                 // No action required
                              end;
                              kvWaste2      := Now;
                              dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
                         end;
                         // Call decoder
                         cqz65(@glf2Buffer[glSampOffset],@jz2,@bw,@afc,@MouseDF2,@idf,glmline,@lical,glwisfile,glkvfname);
                         ifoo := 0;
                         foo := '';
                         foo := StrPas(glmline);
                         if i < 10 then foo := '0' + IntToStr(i) + ',' + foo else foo := IntToStr(i) + ',' + foo;
                         if tryStrToInt(ExtractWord(3,foo,CsvDelim),ifoo) Then
                         Begin
                              if ifoo > 0 Then
                              Begin
                                   if evalBM(foo) Then
                                   Begin
                                        inc(ndec);
                                        gldecOut.Add(TrimLeft(TrimRight(foo)+',B'));
                                        for j := 0 to 99 do
                                        begin
                                             if decArray[j] = '' Then
                                             Begin
                                                  decArray[j] := TrimLeft(TrimRight(foo))+',B';
                                                  break;
                                             end;
                                        end;
                                   end
                                   else
                                   begin
                                        // Oh joy.  Time to try for kv.
                                        kdec := '';
                                        if FileExists(dmtmpdir+'KVASD.DAT') and glUseKV Then
                                        Begin
                                             if evalKV(kdec) Then
                                             Begin
                                                  inc(ndec);
                                                  // Seems I found a kv decode.
                                                  foo := TrimLeft(TrimRight(foo)) + TrimLeft(TrimRight(kdec));
                                                  gldecOut.Add(TrimLeft(TrimRight(foo))+',K');
                                                  for j := 0 to 99 do
                                                  begin
                                                       if decArray[j] = '' Then
                                                       Begin
                                                            decArray[j] := TrimLeft(TrimRight(foo))+',K';
                                                            break;
                                                       end;
                                                  end;
                                                  try
                                                     FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                                                  except
                                                     // No action required
                                                  end;
                                             end;
                                        end;
                                   end;
                              end;
                         end;
                    end
                    else
                    begin
                         for i := 0 to 100 do
                         begin
                              if bins[i] > 0 Then
                              Begin
                                   // This bin needs a decode.
                                   if binspace = 20 Then
                                   Begin
                                        if i = 0 Then lmousedf := -1000 else lmousedf := -1000 + (i*20);
                                   End
                                   else if binspace = 50 Then
                                   Begin
                                        if i = 0 Then lmousedf := -1000 else lmousedf := -1000 + (i*50);
                                   End
                                   else if binspace = 100 Then
                                   Begin
                                        if i = 0 Then lmousedf := -1000 else lmousedf := -1000 + (i*100);
                                   End
                                   else if binspace = 200 Then
                                   Begin
                                        if i = 0 Then lmousedf := -1000 else lmousedf := -1000 + (i*200);
                                   End;
                                   mousedf2 := lmousedf;
                                   idf := lmousedf-mousedf2;
                                   glmline := '                                                                        ';
                                   bw := binspace;
                                   // Copy lpfM to f3Buffer
                                   for j := 0 to jz2-1 do glf2Buffer[j] := gllpfM[j];
                                   for j := jz2 to length(glf2Buffer)-1 do glf2Buffer[j] := 0.0;
                                   // Attempting to insure KVASD.DAT does not exist.
                                   j := 0;
                                   if FileExists(dmtmpdir+'KVASD.DAT') Then
                                   Begin
                                        kvWaste1      := Now;
                                        repeat
                                              try
                                                 FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                                              except
                                                 // No action required
                                              end;
                                              inc(j);
                                        until (j>9) or not FileExists(dmtmpdir+'KVASD.DAT');
                                        kvWaste2      := Now;
                                        dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
                                   end;
                                   if j>0 Then dmKVHangs := dmKVHangs+j;
                                   if FileExists(dmtmpdir+'KVASD.DAT') Then
                                   Begin
                                        kvWaste1      := Now;
                                        try
                                           FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                                        except
                                           // No action required
                                        end;
                                        try
                                           FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                                        except
                                           // No action required
                                        end;
                                        kvWaste2      := Now;
                                        dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
                                   end;
                                   // Call decoder
                                   cqz65(@glf2Buffer[glSampOffset],@jz2,@bw,@afc,@MouseDF2,@idf,glmline,@lical,glwisfile,glkvfname);
                                   ifoo := 0;
                                   foo := '';
                                   foo := StrPas(glmline);
                                   if i < 10 then foo := '0' + IntToStr(i) + ',' + foo else foo := IntToStr(i) + ',' + foo;
                                   if tryStrToInt(ExtractWord(3,foo,CsvDelim),ifoo) Then
                                   Begin
                                        if ifoo > 0 Then
                                        Begin
                                             if evalBM(foo) Then
                                             Begin
                                                  inc(ndec);
                                                  gldecOut.Add(TrimLeft(TrimRight(foo)+',B'));
                                                  for j := 0 to 99 do
                                                  begin
                                                       if decArray[j] = '' Then
                                                       Begin
                                                            decArray[j] := TrimLeft(TrimRight(foo))+',B';
                                                            break;
                                                       end;
                                                  end;
                                             end
                                             else
                                             begin
                                                  // Oh joy.  Time to try for kv.
                                                  kdec := '';
                                                  if FileExists(dmtmpdir+'KVASD.DAT') and glUseKV Then
                                                  Begin
                                                       if evalKV(kdec) Then
                                                       Begin
                                                            inc(ndec);
                                                            // Seems I found a kv decode.
                                                            foo := TrimLeft(TrimRight(foo)) + TrimLeft(TrimRight(kdec));
                                                            gldecOut.Add(TrimLeft(TrimRight(foo))+',K');
                                                            for j := 0 to 99 do
                                                            begin
                                                                 if decArray[j] = '' Then
                                                                 Begin
                                                                      decArray[j] := TrimLeft(TrimRight(foo))+',K';
                                                                      break;
                                                                 end;
                                                            end;
                                                            try
                                                               FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                                                            except
                                                               // No action required
                                                            end;
                                                       end;
                                                  end;
                                             end;
                                        end;
                                   end;
                              End;
                         end;
                    end;
                    j := 0;
                    // Another layer of being sure KVASD.DAT is gone.
                    if FileExists(dmtmpdir+'KVASD.DAT') Then
                    Begin
                         kvWaste1      := Now;
                         repeat
                               try
                                  FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                               except
                                  // No action required
                               end;
                               inc(j);
                         until (j>9) or not FileExists(dmtmpdir+'KVASD.DAT');
                         kvWaste2      := Now;
                         dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
                    end;
                    if j>0 Then dmKVHangs := dmKVHangs+j;
                    if FileExists(dmtmpdir+'KVASD.DAT') Then
                    Begin
                         kvWaste1      := Now;
                         try
                            FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                         except
                            // No action required
                         end;
                         try
                            FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                         except
                            // No action required
                         end;
                         kvWaste2      := Now;
                         dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
                    end;
               end;
          end;
     end;

     // Process decodes, removes dupes and format for sending back to main GUI
     if gldecOut.Count > 0 Then
     Begin
          // Have ndec decodes available in decArray[x]
          // Now.. I plan to do away with the long standing bug of reading a
          // very strong signal as a very weak one due to decoding a alias
          // and the 'real' signal.  First I need to remove any actual dupe
          // strings.  But.  Only need to go through all this if ndec > 1 :)
          ndec := 0;
          for i := 0 to 99 do if not (decArray[i] = '') then inc(ndec);
          if ndec > 1 Then
          Begin
               glsort1.Clear;
               glsort1.Sorted := True;
               glsort1.Duplicates := Types.dupIgnore;
               for i := 0 to gldecOut.Count-1 do
               Begin
                    foo := ExtractWord(7,gldecOut.Strings[i],CsvDelim);
                    glsort1.Add(foo);
               End;
               glsort1.sorted := False;
               gldecOut.Sorted := False;
               While glsort1.count > 0 do
               Begin
                    for i := 0 to glsort1.count - 1 do
                    Begin
                         dupeFoo := '';
                         foo := glsort1.Strings[i];
                         for j := 0 to gldecOut.Count-1 do if ExtractWord(7,gldecOut.Strings[j],csvDelim) = foo then dupeFoo := dupeFoo + IntToStr(j) + ',';
                         if Length(dupeFoo) > 1 Then
                         Begin
                              If dupeFoo[length(dupeFoo)]=',' Then dupeFoo[length(dupeFoo)] := ' ';
                              trimRight(dupeFoo);
                              wcount := WordCount(dupeFoo,csvDelim);
                              allEqual := True;
                              foo := ExtractWord(1,dupeFoo,csvDelim);
                              j := StrToInt(TrimLeft(TrimRight(foo)));
                              strongest := StrToInt(TrimLeft(TrimRight(ExtractWord(4,gldecOut.Strings[j],csvDelim))));
                              for j := 1 to wcount do
                              Begin
                                   foo := ExtractWord(j,dupeFoo,csvDelim);
                                   k := StrToInt(TrimLeft(TrimRight(foo)));
                                   foo := ExtractWord(4,gldecOut.Strings[k],csvDelim);
                                   if StrToInt(TrimLeft(TrimRight(foo))) <> strongest Then allEqual := False;
                              End;
                              If allEqual Then
                              Begin
                                   for j := 2 to wcount do
                                   begin
                                        k := StrToInt(TrimLeft(TrimRight(extractWord(j,dupeFoo,csvDelim))));
                                        gldecOut.Strings[k] := gldecOut.Strings[k] + ',D';
                                   end;
                              End;
                              If not allEqual Then
                              Begin
                                   // Need to find strongest then delete others.
                                   strongest := -99;
                                   for n := 1 to wcount do
                                   Begin
                                        foo := ExtractWord(n,dupeFoo,csvDelim);
                                        j := StrToInt(TrimLeft(TrimRight(foo)));
                                        k := StrToInt(TrimLeft(TrimRight(ExtractWord(4,gldecOut.Strings[j],csvDelim))));
                                        if k > strongest then strongest := k;
                                   End;
                                   for n := 1 to wcount do
                                   Begin
                                        foo := ExtractWord(n,dupeFoo,csvDelim);
                                        j := StrToInt(TrimLeft(TrimRight(foo)));
                                        k := StrToInt(TrimLeft(TrimRight(ExtractWord(4,gldecOut.Strings[j],csvDelim))));
                                        if k < strongest Then gldecOut.Strings[j] := gldecOut.Strings[j] + ',D';
                                   End;
                              End;
                         End;
                         glsort1.Delete(i);
                         break;
                    End;
               End;
               gldecOut.Sorted := True;
               glsort1.Sorted := False;
          end;
          // Do it all again to really remove the dupes in all cases but first
          // remove any entries labeled as dupes from first pass.
          repeat
                haveDupe := False;
                for i := 0 to gldecOut.Count-1 do
                Begin
                     if WordCount(gldecOut.Strings[i],csvDelim)>8 Then
                     Begin
                          gldecOut.delete(i);
                          haveDupe := True;
                          break;
                     End;
                End;
          until haveDupe = False;
          // Only need to do the dupe removal second pass if decOut.count > 1
          if gldecOut.Count>1 Then
          Begin
               glsort1.Clear;
               glsort1.Sorted := True;
               glsort1.Duplicates := Types.dupIgnore;
               for i := 0 to gldecOut.Count-1 do
               Begin
                    foo := ExtractWord(7,gldecOut.Strings[i],CsvDelim);
                    glsort1.Add(foo);
               End;
               glsort1.sorted := False;
               gldecOut.Sorted := False;
               While glsort1.count > 0 do
               Begin
                    for i := 0 to glsort1.count - 1 do
                    Begin
                         dupeFoo := '';
                         foo := glsort1.Strings[i];
                         for j := 0 to gldecOut.Count-1 do if ExtractWord(7,gldecOut.Strings[j],csvDelim) = foo then dupeFoo := dupeFoo + IntToStr(j) + ',';
                         if Length(dupeFoo) > 1 Then
                         Begin
                              If dupeFoo[length(dupeFoo)]=',' Then dupeFoo[length(dupeFoo)] := ' ';
                              trimRight(dupeFoo);
                              wcount := WordCount(dupeFoo,csvDelim);
                              allEqual := True;
                              foo := ExtractWord(1,dupeFoo,csvDelim);
                              j := StrToInt(TrimLeft(TrimRight(foo)));
                              strongest := StrToInt(TrimLeft(TrimRight(ExtractWord(4,gldecOut.Strings[j],csvDelim))));
                              for j := 1 to wcount do
                              Begin
                                   foo := ExtractWord(j,dupeFoo,csvDelim);
                                   k := StrToInt(TrimLeft(TrimRight(foo)));
                                   foo := ExtractWord(4,gldecOut.Strings[k],csvDelim);
                                   if StrToInt(TrimLeft(TrimRight(foo))) <> strongest Then allEqual := False;
                              End;
                              If allEqual Then
                              Begin
                                   for j := 2 to wcount do
                                   begin
                                        k := StrToInt(TrimLeft(TrimRight(extractWord(j,dupeFoo,csvDelim))));
                                        gldecOut.Strings[k] := gldecOut.Strings[k] + ',D';
                                   end;
                              End;
                              If not allEqual Then
                              Begin
                                   // Need to find strongest then delete others.
                                   strongest := -99;
                                   for n := 1 to wcount do
                                   Begin
                                        foo := ExtractWord(n,dupeFoo,csvDelim);
                                        j := StrToInt(TrimLeft(TrimRight(foo)));
                                        k := StrToInt(TrimLeft(TrimRight(ExtractWord(4,gldecOut.Strings[j],csvDelim))));
                                        if k > strongest then strongest := k;
                                   End;
                                   for n := 1 to wcount do
                                   Begin
                                        foo := ExtractWord(n,dupeFoo,csvDelim);
                                        j := StrToInt(TrimLeft(TrimRight(foo)));
                                        k := StrToInt(TrimLeft(TrimRight(ExtractWord(4,gldecOut.Strings[j],csvDelim))));
                                        if k < strongest Then gldecOut.Strings[j] := gldecOut.Strings[j] + ',D';
                                   End;
                              End;
                         End;
                         glsort1.Delete(i);
                         break;
                    End;
               End;
          End;
     End;
     gldecOut.sorted := True;
     // Now break the strings in decOut down to the record format for maincode.
     if gldecOut.Count > 0 Then
     Begin
          // WARNING LOOK AT THIS IF THINGS START TO GO WRONG IN DISPLAY!
          for j := 0 to 49 do
          begin
               gld65decodes[j].dtTimeStamp := '';
               gld65decodes[j].dtSigLevel := '';
               gld65decodes[j].dtNumSync := '';
               gld65decodes[j].dtDeltaTime := '';
               gld65decodes[j].dtDeltaFreq := '';
               gld65decodes[j].dtSigW := ' ';
               gld65decodes[j].dtCharSync := '';
               gld65decodes[j].dtDecoded := '';
               gld65decodes[j].dtProcessed := True;
               gld65decodes[j].dtType := '';
          end;
          // END OF WARNING
          for i := 0 to gldecOut.count-1 do
          Begin
               // DF,Sync,DB,DT,*/#,Exchange,EC Method
               // 1  2    3  4  5   6        7
               wcount := WordCount(gldecOut.Strings[i],CsvDelim);
               if (wcount > 2) and (wcount < 9) Then
               Begin
                    decode.deltaFreq := -9999.0;
                    decode.numSync := -99;
                    decode.dsigLevel := -99;
                    decode.deltaTime := -99.0;
                    decode.cSync := ' ';
                    decode.bDecoded := ' ';
                    decode.timeStamp := gld65timestamp;
                    foo := ExtractWord(2,gldecOut.Strings[i],CsvDelim);
                    If not TryStrToFloat(TrimLeft(TrimRight(foo)), decode.deltaFreq) Then decode.deltaFreq := -9999.0;
                    foo := ExtractWord(3,gldecOut.Strings[i],CsvDelim);
                    If not TryStrToInt(TrimLeft(TrimRight(foo)), decode.numSync) Then decode.numSync := -99;
                    foo := ExtractWord(4,gldecOut.Strings[i],CsvDelim);
                    If not TryStrToInt(TrimLeft(TrimRight(foo)), decode.dsigLevel) Then decode.dsigLevel := -99;
                    foo := ExtractWord(5,gldecOut.Strings[i],CsvDelim);
                    If not TryStrToFloat(TrimLeft(TrimRight(foo)), decode.deltaTime) Then decode.deltaTime := -99.0;
                    foo := ExtractWord(6,gldecOut.Strings[i],CsvDelim);
                    decode.cSync := TrimLeft(TrimRight(foo));
                    foo := ExtractWord(7,gldecOut.Strings[i],CsvDelim);
                    decode.bDecoded := TrimLeft(TrimRight(foo));
                    for j := 0 to 49 do
                    begin
                         if gld65decodes[j].dtProcessed Then
                         begin
                              gld65decodes[j].dtTimeStamp := decode.timeStamp;
                              if decode.dsigLevel > -1 Then decode.dsigLevel := -1;
                              gld65decodes[j].dtSigLevel := IntToStr(decode.dsigLevel);
                              gld65decodes[j].dtNumSync := IntToStr(decode.numSync);
                              gld65decodes[j].dtDeltaTime := FormatFloat('0.0',decode.deltaTime);
                              gld65decodes[j].dtDeltaFreq := FormatFloat('0',decode.deltaFreq);
                              gld65decodes[j].dtSigW := ' ';
                              gld65decodes[j].dtCharSync := decode.cSync;
                              gld65decodes[j].dtDecoded := decode.bDecoded;
                              gld65decodes[j].dtProcessed := False;
                              gld65decodes[j].dtType := TrimLeft(TrimRight(ExtractWord(8,gldecOut.Strings[i],CsvDelim)));
                              break;
                         end;
                    end;
               end;
          End;
          Inc(dmrcount);
          dmexit      := Now;
          dmruntime   := MilliSecondSpan(dmenter,dmexit);
          dmarun      := dmarun + dmruntime;
     end
     else
     begin
          dmexit      := Now;
          dmruntime   := MilliSecondSpan(dmenter,dmexit);

     end;
     gld65HaveDecodes := False;
     for i := 0 to length(gld65decodes)-1 do
     begin
          if not gld65decodes[i].dtProcessed Then
          Begin
               gld65HaveDecodes := true;
               inc(glDemodCount);
          end;
     end;

     // One last pass to insure KVASD.DAT does not exist.
     j := 0;
     if FileExists(dmtmpdir+'KVASD.DAT') Then
     Begin
          kvWaste1      := Now;
          repeat
                try
                   FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
                except
                   // No action required
                end;
                inc(j);
          until (j>9) or not FileExists(dmtmpdir+'KVASD.DAT');
          kvWaste2      := Now;
          dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
     end;
     if j>0 Then dmKVHangs := dmKVHangs+j;
     if FileExists(dmtmpdir+'KVASD.DAT') Then
     Begin
          kvWaste1      := Now;
          try
             FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
          except
             // No action required
          end;
          try
             FileUtil.DeleteFileUTF8(dmtmpdir+'KVASD.DAT');
          except
             // No action required
          end;
          kvWaste2      := Now;
          dmKVWasted := dmKVWasted + MilliSecondSpan(kvWaste1,kvWaste2);
     end;

     // All done - clean up.
     gldecOut.Clear;
     glsort1.Clear;
     glinprog := False;
     glnd65FirstRun := False;
     Inc(dmPlotCount);
End;
end.

