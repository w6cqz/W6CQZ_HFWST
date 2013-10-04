{ TODO :

FIX - dupes being passed to main gui - these are true dupes as in exact
same signal values and call.  kill kill kill them.
}

{
  Compared to decoder circa JT65-HF 1.0.9.x this is somewhat less efficient
  at getting decodes but a quantum leap ahead in speed.  I need to ponder why
  the decoder is failing to pick out some it should and I have a feeling but
  need to think it through.  For now - it's good enough to get going with.

  LPF Samples since I changed libJT65 - Confirmed working properly by
  applying to spectrum display with a 1.5K LPF - a -9 db signal above 1.5K
  did not appear ;)  Also added HPF with a 400 Hz edge - it's 3 pole so 400
  is fine.

  Removed all calls to lpf1 - replaced with a simple 2x decimate and above
  referenced BPF action.

  Moved BPF to ADC unit so it can run in real time on the much smaller sample
  blocks.  This saves around 120...150 mS in the decoder.  Small - yes, but, for
  future things this might make a more substantial difference. :)
}

// (c) 2013 CQZ Electronics
unit demodulate;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, CTypes, Types, Math, StrUtils, Process, FileUtil,
  DateUtils;

Const
  JT_DLL = 'JT65v5.dll';

  // 19 pole butterworth LPF - good for < ~2.5KHz (this is an IIR type)
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

type

  decoded  = Record
      ts   : String;
      utc  : String;
      sync : String;
      db   : String;
      dt   : String;
      df   : String;
      ec   : String;
      dec  : String;
      sf   : String;
      ver  : String;
      nc1  : LongWord;
      nc2  : LongWord;
      ng   : LongWord;
      clr  : Boolean;
  end;

  kvrec = Record
      nsec1    : CTypes.cint;
      xlambda  : CTypes.cfloat;
      maxe     : CTypes.cint;
      naddsynd : CTypes.cint;
      mrsym    : Array[0..62] Of CTypes.cint;
      mrprob   : Array[0..62] Of CTypes.cint;
      mr2sym   : Array[0..62] Of CTypes.cint;
      mr2prob  : Array[0..62] Of CTypes.cint;
  end;

  spotRecord = record
      qrg      : Integer;
      date     : String;
      time     : String;
      sync     : Integer;
      db       : Integer;
      dt       : String;
      df       : Integer;
      decoder  : String;
      exchange : String;
      mode     : String;
      rbsent   : Boolean;
      pskrsent : Boolean;
      dbfsent  : Boolean;
  end;

  function fdemod(Const samps : Array Of CTypes.cfloat) : Boolean;

  Var
     dmical        : CTypes.cint;
     dmfirstPass   : Boolean;
     dmhaveDecode  : Boolean;
     dmdemodBusy   : Boolean;
     dmdecodes     : Array[0..499] Of decoded;
     dmruntime     : Double;
     dmbw,dmbws    : CTypes.cint;
     dmrcount      : Integer;
     dmarun        : Double;
     dmwispath     : String;
     glist         : Array[0..32767] Of String;
     dmlastraw     : Array[0..499] Of String;
     dmdecodecount : Integer;
     dmtmpdir      : String;
     dmprofile     : TStringList;

implementation

procedure set65; cdecl; external JT_DLL name 'setup65_';
//procedure lpf1(dat : CTypes.pcfloat; jz : CTypes.pcint; nz : CTypes.pcint; mousedf : CTypes.pcint; mousedf2 : CTypes.pcint; ical : CTypes.pcint; wisfile : PChar); cdecl; external JT_DLL name 'lpf1_';
procedure msync(dat : CTypes.pcfloat; jz : CTypes.pcint; syncount : CTypes.pcint; dtxa : CTypes.pcfloat; dfxa : CTypes.pcfloat; snrxa : CTypes.pcfloat; snrsynca : CTypes.pcfloat; ical : CTypes.pcint; wisfile : PChar); cdecl; external JT_DLL name 'msync65_';
procedure cqz65(dat         : CTypes.pcfloat;
                jz          : CTypes.pcint;
                DFTolerance : CTypes.pcint;
                MouseDF2    : CTypes.pcint;
                NAFC        : CTypes.pcint;
                wisfile     : PChar;
                ical        : CTypes.pcint;
                idf         : CTypes.pcint;
                sym1        : CTypes.pcint;
                sym2        : CTypes.pcint;
                sym1p       : CTypes.pcint;
                sym2p       : CTypes.pcint;
                flag        : CTypes.pcint;
                jdf         : CTypes.pcint;
                nsync       : CTypes.pcint;
                nsnr        : CTypes.pcint;
                ddtx        : CTypes.pcfloat
               ); cdecl; external JT_DLL name 'cqz65_';

procedure rsdecode(Pcsyms : CTypes.pcint; Pera : CTypes.pcint; Pnera : CTypes.pcint; Pdsyms : CTypes.pcint; Pcount : CTypes.pcint); cdecl; external JT_DLL name 'rs_decode_';

function isControlb(c : String) : Boolean;
Var
   i : Integer;
Begin
     // Grid, -##, R-##, RRR, RO, 73
     // c must be one of the above to return true.
     Result := False;
     if c = 'RRR' then result := true;
     if c = 'RO'  then result := true;
     if c = '73'  then result := true;
     if (length(c)=3) and (not result) then
     begin
          // better be -##
          i := 0;
          if TryStrToInt(c,i) Then
          Begin
               if i < 0 Then result := true;
          end
          else
          begin
               result := False;
          end;
     end;
     if (length(c)=4) and (not result) then
     begin
          if (c[1]='R') And (c[2]='-') Then
          Begin
               i := 0;
               if TryStrToInt(c[3..4],i) Then
               Begin
                    i := 0-i;
                    if i < 0 Then result := true;
               end
               else
               begin
                    result := False;
               end;
          end
          else
          begin
               result := False;
          end;
     end;
end;

function utcTime: TSystemTime;
Begin
     result.Day := 0;
     GetSystemTime(result);
end;

function  db(x : CTypes.cfloat) : CTypes.cfloat;
Begin
     Result := -99.0;
     if x > 1.259e-10 Then Result := 10.0 * log10(x);
end;

procedure populateBins(const dfxa : Array of CTypes.cfloat; const syncount : CTypes.cint; const binspace : CTypes.cint; Var bins : Array of CTypes.cint);
Var
   i,passtest : Integer;
   bl,bm,bh   : Integer;
   hl,hm,hh   : Boolean;
Begin
     for i := 0 to syncount-1 do
     begin
          passtest := trunc(dfxa[i]);
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
     // Normalize bins to 0 or 1
     for i := 0 to 100 do
     begin
          if bins[i] > 0 then bins[i] := 1 else bins[i] := 0;
     end;
     if binspace = 20 Then
     Begin
          // Looking for clusters of 3 consecutive bins - these will likely be
          // dupes (spectral leakage) - if things go wrong DEBUG this :)
          // So far so good on this - not seeing any immediate meltdown and it
          // has certainly killed the true dupes.
          bl := 0;
          bm := 1;
          bh := 2;
          hl := False;
          hm := False;
          hh := False;
          While bh < 101 Do
          Begin
               if bins[bl] > 0 Then hl := True;
               if bins[bm] > 0 Then hm := True;
               if bins[bh] > 0 Then hh := True;
               if (hl And hm) Or (hm And hh) Then
               Begin
                    bins[bl] := 0;
                    bins[bh] := 0;
                    bl := bh+1;
                    bm := bh+2;
                    bh := bh+3;
               end
               else
               begin
                    inc(bl);
                    inc(bm);
                    inc(bh);
               end;
               hl := False;
               hm := False;
               hh := False;
          end;
     end;
End;

function  dSyms(var   nc1 : LongWord; var   nc2 : LongWord; var   ng : LongWord; const syms : Array Of Integer) : Boolean;
Begin
     // Takes the values in syms[1..12] and returns nc1, nc2 and ng and true/false as conversion status.
     // NC1/NC2 allowed range is 0 ... 268,435,455 (2^28 - 1)
     // NG      allowed range is 0 ... 65535 (2^16 - 1)
     // Syms[x] allowed range is 0 ... 63 (2^6 - 1)

     Result := False;

     nc1    := 0;
     nc2    := 0;
     ng     := 0;

     nc1 := (syms[0] shl 22) + (syms[1] shl 16) + (syms[2] shl 10) + (syms[3] shl 4) + ((syms[4] shr 2) And 15);

     nc2 := ((syms[4] And 3) shl 26) + (syms[5] shl 20) + (syms[6] shl 14) + (syms[7] shl 8) + (syms[8] shl 2) + ((syms[9] shr 4) And 3);
     ng  := ((syms[9] And 15) shl 12) + (syms[10] shl 6) + syms[11];

     if (nc1 < 268435456) And (nc2 < 268435456) And (ng < 65536) Then Result := True else Result := False;
end;

function dForm(var form : String; var sfx : Boolean; var pfx : Boolean; const nc : LongWord) : String;
Var
   tc, cv, cm, ct : Longword;
   foo            : String;
   cs             : Array[1..37] Of Char;
Begin
     // ASCII to JT65 value mapping Callsigns/Prefix/Suffix
     cs[1] := '0';
     cs[2] := '1';
     cs[3] := '2';
     cs[4] := '3';
     cs[5] := '4';
     cs[6] := '5';
     cs[7] := '6';
     cs[8] := '7';
     cs[9] := '8';
     cs[10] := '9';
     cs[11] := 'A';
     cs[12] := 'B';
     cs[13] := 'C';
     cs[14] := 'D';
     cs[15] := 'E';
     cs[16] := 'F';
     cs[17] := 'G';
     cs[18] := 'H';
     cs[19] := 'I';
     cs[20] := 'J';
     cs[21] := 'K';
     cs[22] := 'L';
     cs[23] := 'M';
     cs[24] := 'N';
     cs[25] := 'O';
     cs[26] := 'P';
     cs[27] := 'Q';
     cs[28] := 'R';
     cs[29] := 'S';
     cs[30] := 'T';
     cs[31] := 'U';
     cs[32] := 'V';
     cs[33] := 'W';
     cs[34] := 'X';
     cs[35] := 'Y';
     cs[36] := 'Z';
     cs[37] := ' ';
     // Takes a 28 bit value and returns prefix, suffix or nothing along with frame form of CQ, QRZ, DE or CALL
     form   := '';
     sfx    := False;
     pfx    := False;
     result := '';
     tc     := 0;

     // CQ  (No prefix/suffix) 262,177,561
     // QRZ (No prefix/suffix) 262,177,562
     //
     // CQ ### (No prefix/suffix) 262,177,563 ... 262,178,562
     //
     // CQ  with Prefix 262,178,563 ... 264,002,071
     // QRZ with Prefix 264,002,072 ... 265,825,580
     // DE  with Prefix 265,825,581 ... 267,649,089
     //
     // CQ  with Suffix 267,649,090 ... 267,698,374
     // QRZ with Suffix 267,698,375 ... 267,747,659
     // DE  with Suffix 267,747,660 ... 267,796,944
     //
     // DE (No prefix/suffix) 267,796,945

     if nc < 262177560 then
     Begin
          form   := 'CALL';
          sfx    := False;
          pfx    := False;
          result := '';
          tc     := nc;
          cv     := tc;
          // Convert integer as input to 6 integers as index to character
          ct := 0;  // Same as cv div 27 or div 10 or div 36
          cm := 0;  // Same as cv mod 27 or mod 10 or mod 36
          foo := '';
          DivMod(cv,27,ct,cm); // Creates ct, cm as commented above in one step
          foo := cs[cm+11];
          cv := ct;

          cm := 0;
          DivMod(cv,27,ct,cm);
          foo := cs[cm+11] + foo;
          cv := ct;

          cm := 0;
          DivMod(cv,27,ct,cm);
          foo := cs[cm+11] + foo;
          cv := ct;

          cm := 0;
          DivMod(cv,10,ct,cm);
          foo := cs[cm+1] + foo;
          cv := ct;

          cm := 0;
          DivMod(cv,36,ct,cm);
          foo := cs[cm+1] + foo;
          cv := ct;

          foo := cs[cv+1] + foo;
          result := foo;

     end;

     if nc = 262177561 then
     Begin
          form   := 'CQ';
          sfx    := False;
          pfx    := False;
          result := '';
          tc     := nc;
     end;

     if nc = 262177562 then
     Begin
          form   := 'QRZ';
          sfx    := False;
          pfx    := False;
          result := '';
          tc     := nc;
     end;

     if ((nc > 262177562) and (nc < 262178563)) then
     Begin
          form   := 'CQ';
          sfx    := False;
          pfx    := False;
          tc     := nc-262177560-3;
          result := IntToStr(tc);
     End;

     if ((nc > 262178562) and (nc < 267796945)) then
     begin
          // Contains a V2 prefix or suffix
          if nc < 267649090 Then
          begin
               // Prefix
               pfx := true;
               // CQ  with Prefix 262,178,563 ... 264,002,071
               // QRZ with Prefix 264,002,072 ... 265,825,580
               // DE  with Prefix 265,825,581 ... 267,649,089
               if ((nc > 262178562) and (nc < 264002772)) Then
               Begin
                    form := 'CQ';
                    tc   := nc - 262178563;
               end;
               if ((nc > 264002071) and (nc < 265825581)) Then
               Begin
                    form := 'QRZ';
                    tc   := nc - 264002072;
               end;
               if ((nc > 265825580) and (nc < 267649090)) Then
               Begin
                    form := 'DE';
                    tc   := nc - 265825581;
               end;
               // Now compute the prefix
               if tc < 1823508 Then
               Begin
                    foo := '';
                    // Convert integer as input to 4 integers as index to character
                    cv := tc;
                    ct := 0;
                    cm := 0;
                    DivMod(cv,37,ct,cm);
                    foo := cs[cm+1];
                    cv := ct;

                    cm := 0;
                    DivMod(cv,37,ct,cm);
                    foo := cs[cm+1] + foo;
                    cv := ct;

                    cm := 0;
                    DivMod(cv,37,ct,cm);
                    foo := cs[cm+1] + foo;
                    cv := ct;

                    foo := cs[cv+1] + foo;
                    result := foo;
               end
               else
               begin
                    // Invalid
                    result := '????';
               end;
          end
          else
          begin
               // Suffix
               sfx := true;
               // CQ  with Suffix 267,649,090 ... 267,698,374
               // QRZ with Suffix 267,698,375 ... 267,747,659
               // DE  with Suffix 267,747,660 ... 267,796,944
               if ((nc > 267649089) and (nc < 267698375)) Then
               Begin
                    form := 'CQ';
                    tc   := nc - 267649090;
               end;
               if ((nc > 267698374) and (nc < 267747660)) Then
               Begin
                    form := 'QRZ';
                    tc   := nc - 267698375;
               end;
               if ((nc > 267747659) and (nc < 267796945)) Then
               Begin
                    form := 'DE';
                    tc   := nc - 267747660;
               end;
               // Now compute the suffix
               if tc < 1823508 Then
               Begin
                    foo := '';
                    // Convert integer as input to 3 integers as index to character
                    cv := tc;
                    ct := 0;
                    cm := 0;
                    DivMod(cv,37,ct,cm);
                    foo := cs[cm+1];
                    cv := ct;

                    cm := 0;
                    DivMod(cv,37,ct,cm);
                    foo := cs[cm+1] + foo;
                    cv := ct;

                    foo := cs[cv+1] + foo;
                    result := foo;
               end
               else
               begin
                    // Invalid
                    result := '???';
               end;
          end;
     end;

     if nc = 267796945 then
     Begin
          // This is plain and simple de CALL GRID [nc1 nc2 ng]
          form   := 'DE';
          sfx    := False;
          pfx    := False;
          result := '';
          tc     := nc;
     end;

end;

procedure dGrid(const gv : LongWord; var v1grid : String; var prefix : String; var suffix : String; var c1 : Boolean; var c2 : Boolean);
Var
   ng : CTypes.cint;
   ngt : String;
Begin
     c1 := False;
     c2 := False;
     ng := CTypes.cint(gv);
     prefix := '';
     suffix := '';

     if ng >= 32400 Then
     Begin
          // Control message detected
          ng := ng - 32401;
          if ng < 1 Then v1Grid := 'NONE';
          if (ng >= 1) and (ng <= 30) Then
          Begin
               if ng > 9 Then v1grid := '-' + IntToStr(ng) else v1Grid := '-0' + IntToStr(ng); // -## Report
          end;
          if (ng >= 31) and (ng <= 60) Then
          Begin
               if ng-30 > 9 Then v1grid := 'R-' + IntToStr(ng-30) else v1Grid := 'R-0' + IntToStr(ng-30); // -## Report
          end;
          if ng = 61 Then v1grid := 'RO';
          if ng = 62 Then v1grid := 'RRR';
          if ng = 63 Then v1grid := '73';
     end
     else
     Begin
          c1 := False;
          c2 := False;
          suffix := '';
          prefix := '';
          v1Grid := '';
          if ng <32400 Then ngt := glist[gv];
          if ngt[1] = 'G' Then v1Grid := ngt[2..Length(ngt)]; // JT65V1 Grid
          if ngt[1] = 'P' Then
          begin
               // This is a JT65V1 Prefix
               If Length(ngt)> 1 Then
               Begin
                    prefix := ngt[2..Length(ngt)];
                    suffix := '';
                    c1 := True;
                    c2 := False;
                    v1Grid := 'NONE';
               end
               else
               begin
                    suffix := '';
                    prefix := '';
                    c1 := False;
                    c2 := False;
                    v1Grid := '';
               end;
          end;
          if ngt[1] = 'S' Then
          begin
               // This is a JT65V1 Suffix
               If Length(ngt)> 1 Then
               Begin
                    suffix := ngt[2..Length(ngt)];
                    prefix := '';
                    c1 := False;
                    c2 := True;
                    v1Grid := 'NONE';
               end
               else
               begin
                    // Value 29516 (for one) returns a blank suffix string... Just an S
                    suffix := '';
                    prefix := '';
                    c1 := False;
                    c2 := False;
                    v1Grid := '';
               end;
          end;
     end;
end;

function  dText(var msg : String; const nc1 : LongWord; const nc2 : LongWord; const ng : LongWord) : Boolean;
Var
   cs   : Array[1..42] Of Char;
   tnc1 : LongWord;
   tnc2 : LongWord;
   tng  : LongWord;
   foo  : String;
   i    : Integer;
   cv   : LongWord;
   cm   : LongWord;
   ct   : LongWord;
Begin
     result := False;
     // ASCII to JT65 value mapping Free Text
     cs[1] := '0';
     cs[2] := '1';
     cs[3] := '2';
     cs[4] := '3';
     cs[5] := '4';
     cs[6] := '5';
     cs[7] := '6';
     cs[8] := '7';
     cs[9] := '8';
     cs[10] := '9';
     cs[11] := 'A';
     cs[12] := 'B';
     cs[13] := 'C';
     cs[14] := 'D';
     cs[15] := 'E';
     cs[16] := 'F';
     cs[17] := 'G';
     cs[18] := 'H';
     cs[19] := 'I';
     cs[20] := 'J';
     cs[21] := 'K';
     cs[22] := 'L';
     cs[23] := 'M';
     cs[24] := 'N';
     cs[25] := 'O';
     cs[26] := 'P';
     cs[27] := 'Q';
     cs[28] := 'R';
     cs[29] := 'S';
     cs[30] := 'T';
     cs[31] := 'U';
     cs[32] := 'V';
     cs[33] := 'W';
     cs[34] := 'X';
     cs[35] := 'Y';
     cs[36] := 'Z';
     cs[37] := ' ';
     cs[38] := '+';
     cs[39] := '-';
     cs[40] := '.';
     cs[41] := '/';
     cs[42] := '?';

     tnc1 := nc1;
     tnc2 := nc2;
     tng  := ng;

     tng := tng And 32767;

     if (tnc1 And 1) > 0 Then tng := tng + 32768;
     tnc1 := tnc1 div 2;

     if (tnc2 And 1) > 0 Then tng := tng + 65536;
     tnc2 := tnc2 div 2;

     foo := '             ';

     cv := tnc1;
     for i := 5 downto 1 do
     begin
          ct := 0;  // Same as cv div 42 or div 10
          cm := 0;  // Same as cv mod 42 or mod 10
          DivMod(cv,42,ct,cm);
          inc(cm);
          foo[i] :=  cs[cm];
          cv := ct;
     end;

     cv := tnc2;
     for i := 10 downto 6 do
     begin
          ct := 0;
          cm := 0;
          DivMod(cv,42,ct,cm);
          inc(cm);
          foo[i] :=  cs[cm];
          cv := ct;
     end;

     cv := tng;
     for i := 13 downto 11 do
     begin
          ct := 0;
          cm := 0;
          DivMod(cv,42,ct,cm);
          inc(cm);
          foo[i] :=  cs[cm];
          cv := ct;
     end;

     msg := foo;
     result := True;
end;

function decode(const decsyms : Array of Integer; var decoded : String; var sf : String; var ver : String; var nc1 : LongWord; var nc2 : LongWord; var ng : LongWord) : Boolean;
Var
   foo           : String;
   nc1t,nc2t,ngt : String;
   pfxt,sfxt     : String;
   v1pfx,v1sfx   : String;
   sfx, pfx      : Boolean;
   c1add,c2add   : Boolean;
   form          : String;
   ngt1          : String;
Begin
     Result  := False;
     decoded := '';
     foo     := '';
     sf      := '';
     ver     := '1';

     nc1 := 0;
     nc2 := 0;
     ng  := 0;

     if dSyms(nc1,nc2,ng,decsyms) Then
     Begin
          nc1t  := '';
          nc2t  := '';
          ngt   := '';
          pfxt  := '';
          sfxt  := '';
          v1pfx := '';
          v1sfx := '';
          pfx   := False;
          sfx   := False;
          foo   := '';
          form  := '';

          if ng < 32768 Then
          Begin
               sf := 'S';
               nc1t := dForm(form,sfx,pfx,nc1);
               if pfx or sfx Then
               Begin
                    ver := '2';
                    // Have a V2 prefix or suffix call
                    if pfx Then pfxt := TrimLeft(TrimRight(nc1t));  // Prefix in pfxt
                    if sfx Then sfxt := TrimLeft(TrimRight(nc1t));  // Suffix in sfxt
                    foo := TrimLeft(TrimRight(form));  // For a V2 prefixed/suffixed call there will ALWAYS be a form of CQ, QRZ or DE.
                    nc2t := dForm(form,sfx,pfx,nc2);
                    nc2t := TrimLeft(TrimRight(nc2t));  // Callsign of sending station (nc2)
                    ngt1 := '';
                    v1pfx := '';
                    v1sfx := '';
                    c1add := False;
                    c2add := False;
                    dGrid(ng, ngt1,v1pfx,v1sfx,c1add,c2add);
                    ngt  := TrimLeft(TrimRight(ngt1));
                    if (Length(v1pfx)>0) Or (Length(v1sfx)>0) Then
                    Begin
                         // This would seem to be an error.  It's a V2 frame with a V1 prefix/suffix in ng
                         // Handle it as a real grid rather than a V1 type.
                         if Length(ngt) > 4 Then ngt := ngt[1..4];
                         if length(pfxt)>0 Then foo := foo + ' ' + pfxt + '/' + nc2t + ' ' + ngt;
                         if length(sfxt)>0 Then foo := foo + ' ' + nc2t + '/' + sfxt + ' ' + ngt;
                         If (length(pfxt)=0) And (length(sfxt)=0) Then foo := foo + ' ' + nc2t + ' ' + ngt;
                    end
                    else
                    begin
                         if Length(ngt) > 4 Then ngt := ngt[1..4];
                         if length(pfxt)>0 Then foo := foo + ' ' + pfxt + '/' + nc2t + ' ' + ngt;
                         if length(sfxt)>0 Then foo := foo + ' ' + nc2t + '/' + sfxt + ' ' + ngt;
                         If (length(pfxt)=0) And (length(sfxt)=0) Then foo := foo + ' ' + nc2t + ' ' + ngt;
                    end;
                    foo := TrimLeft(TrimRight(foo));
                    Result  := True;
                    decoded := foo;
               end
               else
               Begin
                    ver := '1';
                    // No V2 prefix/suffix detected.
                    nc1t := dForm(form,sfx,pfx,nc1);
                    nc1t := TrimLeft(TrimRight(nc1t));
                    If (form = 'CQ') or (form = 'QRZ') or (form = 'DE') Then nc1t := form;
                    If form = 'DE' Then ver := '2' else ver := '1';
                    nc2t := dForm(form,sfx,pfx,nc2);
                    nc2t := TrimLeft(TrimRight(nc2t));
                    ngt1 := '';
                    v1pfx := '';
                    v1sfx := '';
                    c1add := False;
                    c2add := False;
                    dGrid(ng, ngt1,v1pfx,v1sfx,c1add,c2add);
                    ngt  := TrimLeft(TrimRight(ngt1));

                    if (((Length(v1pfx)>0) Or (Length(v1sfx)>0))) And (c1add or c2add) Then
                    Begin
                         if c1add Then
                         Begin
                              sleep(1);
                              // This is a pfx/sfx to nc1 position
                              if Length(v1pfx)>0 Then foo := TrimLeft(TrimRight(UpCase(v1pfx))) + '/' + nc1t + ' ' + nc2t;
                              if Length(v1sfx)>0 Then foo := nc1t + '/' + TrimLeft(TrimRight(UpCase(v1sfx))) + ' ' + nc2t;
                              sleep(1);
                         end;
                         if c2add Then
                         Begin
                              sleep(1);
                              // This is a pfx/sfx to nc2 position
                              if Length(v1pfx)>0 Then foo := nc1t + ' ' + TrimLeft(TrimRight(UpCase(v1pfx))) + '/' + nc2t;
                              if Length(v1sfx)>0 Then foo := nc1t + ' ' + nc2t + '/' + TrimLeft(TrimRight(UpCase(v1sfx)));
                              sleep(1);
                         end;
                    end
                    else
                    begin
                         ngt := TrimLeft(TrimRight(UpCase(ngt)));
                         if Length(ngt) > 4 Then ngt := ngt[1..4];
                         foo := nc1t + ' ' + nc2t + ' ' + ngt;
                    end;
                    foo := TrimLeft(TrimRight(foo));
                    Result  := True;
                    decoded := foo;
               end;
          end
          else
          begin
               // Free format text.
               sf := 'F';
               if dText(foo,nc1,nc2,ng) Then
               Begin
                    foo := TrimLeft(TrimRight(foo));
                    Result  := True;
                    decoded := foo;
               end
               else
               begin
                    Result  := False;
                    decoded := '';
               end;
          end;
     End
     Else
     Begin
          Result  := False;
          decoded := '';
     End;
end;

Function evalKV(const fname : String; Var decoded : String; Var sf : String; Var ver : String; var nc1 : LongWord; var nc2 : LongWord; var ng : LongWord) : Boolean;
Var
   kvSec2, kvCount,ierr,i,j : CTypes.cint;
   kvProc                   : TProcess;
   kvDat                    : Array[0..11] of CTypes.cint;
   kvFile                   : File Of CTypes.cint;
   foo,kvfullname           : String;
Begin
     // Looking for a KV decode
     Result  := false;
     decoded := '';
     foo     := '';
     sf      := '';
     ver     := '';

     for i := 0 to 11 do
     Begin
          kvDat[i] := 0;
     End;

     ierr := 0;
     kvfullname := dmtmpdir+fname;
     if FileExists(kvfullname) Then
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
          //ListBox2.Items.Insert(0,'KV File missing');
     end;

     if ierr = 0 Then
     Begin
          Try
             // read kvasd.dat
             AssignFile(kvFile,kvfullname);
             Reset(kvFile);
             //ListBox2.Items.Insert(0,'kv size = ' + IntToStr(System.FileSize(kvfile)));
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
                       foo  := '';
                       sf   := '';
                       ver  := '';
                       nc1 := 0;
                       nc2 := 0;
                       ng  := 0;
                       If decode(kvdat,foo,sf,ver,nc1,nc2,ng) Then
                       Begin
                            //ListBox2.Items.Insert(0,'KV File decode OK');
                            Result  := True;
                            decoded := foo;
                       end
                       else
                       begin
                            //ListBox2.Items.Insert(0,'KV File decode fails');
                            Result  := False;
                            decoded := '';
                       end;
                  End
                  Else
                  Begin
                       // No decode, kvasd failed to reconstruct message.
                       //ListBox2.Items.Insert(0,'KV File decode fails kvcount');
                       Result  := False;
                       decoded := '';
                  End;
             End
             Else
             Begin
                  if j<>256 Then
                  Begin
                       Result := False;
                  end;
                  //ListBox2.Items.Insert(0,'KV File wrong size');
                  CloseFile(kvFile);
                  Result  := False;
                  decoded := '';
             End;
          except
             //ListBox2.Items.Insert(0,'KV File decode exception');
             Result  := False;
             decoded := '';
          end;
     End
     Else
     Begin
          // No decode, error status returned from kvasd.exe
          //ListBox2.Items.Insert(0,'KV File kvasd returns error');
          Result  := False;
          decoded := '';
     End;

     kvProc.Destroy;

     try
        FileUtil.DeleteFileUTF8(kvfullname);
     except
        // No action required
     end;

end;

function fdemod(Const samps : Array Of CTypes.cfloat) : Boolean;
Var
   glinbuffer    : Array of CTypes.cint;
   glf1buffer    : Array of CTypes.cfloat;
   glf3buffer    : Array[0..661503] of CTypes.cfloat;
   gllpfm        : Array[0..661503] Of Ctypes.cfloat;
   dfxa          : Array[0..254] Of CTypes.cfloat;
   snrsynca      : Array[0..254] Of CTypes.cfloat;
   snrxa         : Array[0..254] Of CTypes.cfloat;
   dtxa          : Array[0..254] Of CTypes.cfloat;
   decsyms       : Array[0..11] Of Ctypes.cint;
   lsym1,lsym2   : Array[0..62] Of CTypes.cint;
   lsym1p,lsym2p : Array[0..62] Of CTypes.cint;
   rsera         : Array[0..50] Of CTypes.cint;
   rsecount      : CTypes.cint;
   rscount       : CTypes.cint;
   i,jz2,k,jz,bw : CTypes.cint;
   lical,idf,j   : CTypes.cint;
   //lmousedf,bw   : CTypes.cint;
   mousedf2,afc  : CTypes.cint;
   syncount      : CTypes.cint;
   foo,ver       : String;
   wif           : PChar;
   //ave,sq        : CTypes.cfloat;
   ffoo,avesq    : CTypes.cfloat;
   basevb,sq     : CTypes.cfloat;
   lflag,ljdf    : CTypes.cint;
   lnsync,lnsnr  : CTypes.cint;
   lddtx         : CTypes.cfloat;
   wc,passcount  : Integer;
   foo1,foo2     : String;
   bins          : Array[0..100] Of CTypes.cint;
   clearList     : TStringList;
   kvdat         : kvrec;
   kvfile        : File Of kvrec;
   dmtimestamp   : String;
   dmthisutc,sf  : String;
   thisUTC       : TSystemTime;
   dmenter       : TDateTime;
   dmexit        : TDateTime;
   penter,pexit  : TDateTime;
   pruntime      : Double;
   lnc1,lnc2,lng : LongWord;
   wisPath       : String;
   rawcount      : Integer;
begin
     dmenter      := Now;
     penter       := Now;
     pruntime     := 0.0;
     dmdemodBusy  := True;
     dmhaveDecode := False;
     thisUTC      := utcTime;

     bw           := dmbw;  // Sets decoder bin space in hertz
     if (bw<20) Or (bw>200) Then bw := 100;

     dmtimestamp := '';
     dmtimestamp := dmtimestamp + IntToStr(thisUTC.Year);
     if thisUTC.Month < 10 Then dmtimestamp := dmtimestamp + '0' + IntToStr(thisUTC.Month) else dmtimestamp := dmtimestamp + IntToStr(thisUTC.Month);
     if thisUTC.Day < 10 Then dmtimestamp := dmtimestamp + '0' + IntToStr(thisUTC.Day) else dmtimestamp := dmtimestamp + IntToStr(thisUTC.Day);
     if thisUTC.Hour < 10 Then dmtimestamp := dmtimestamp + '0' + IntToStr(thisUTC.Hour) else dmtimestamp := dmtimestamp + IntToStr(thisUTC.Hour);
     if thisUTC.Minute < 10 Then dmtimestamp := dmtimestamp + '0' + IntToStr(thisUTC.Minute) else dmtimestamp := dmtimestamp + IntToStr(thisUTC.Minute);
     dmtimestamp := dmtimestamp + '00';

     dmthisutc := '';
     if thisUTC.Hour < 10 then dmthisutc := '0' + IntToStr(thisUTC.hour) else dmthisutc := IntToStr(thisUTC.hour);
     if thisUTC.Minute < 10 then dmthisutc := dmthisutc + ':0' + IntToStr(thisUTC.minute) else dmthisutc := dmthisutc + ':' + IntToStr(thisUTC.minute);

     clearList := TStringList.Create;
     clearList.CaseSensitive := False;
     clearList.Sorted := False;
     clearList.Duplicates := Types.dupAccept;
     { TODO : Monitor following change CLOSELY }
     // DEBUG if the decoder blows up this be the place to look!
     // Can't sort - really messes things up.
     //clearList.Sorted := True;
     //clearList.Duplicates := Types.dupIgnore;

     Result := False;
     //
     // ical =  0 = FFTW_ESTIMATE set, no load/no save wisdom.  Use ical = 0 when all else fails.
     // ical =  1 = FFTW_MEASURE set, yes load/no save wisdom.  Use ical = 1 to load saved wisdom.
     // ical = 11 = FFTW_MEASURE set, no load/no save wisdom.  Use ical = 11 when wisdom has been loaded and does not need saving.
     // ical = 21 = FFTW_MEASURE set, no load/yes save wisdom.  Use ical = 21 to save wisdom.
     //

     // Clear the bins
     for i := 0 to 100 do
     begin
          bins[i] := 0;
     end;

     if dmical > -1 Then
     Begin
          if dmical = 1 Then
          Begin
               if dmfirstPass Then lical := 1 else lical := 11;
          End;
          if dmical = 21 Then
          Begin
               if dmfirstPass Then lical := 21 else lical := 11;
          End;
     End;

     // DEBUG - Following may be a mistake.... I may need to rebuild
     // the pchar variable each time.. let's see. - seems not - leaving this
     // for now though.
     if dmFirstPass Then
     Begin
          wif := StrAlloc(256);
          wisPath := dmwisPath;
          wisPath := PadRight(wisPath,255);
          StrPCopy (wif,wisPath);
     end;

     dmfirstPass := False;

     // Clean the decoder returns array/record
     // Yes, 500 entries is a lot. Method, madness and etc.  :)
     for i := 0 to 499 do
     begin
          dmdecodes[i].ts   := '';
          dmdecodes[i].utc  := '';
          dmdecodes[i].sync := '';
          dmdecodes[i].db   := '';
          dmdecodes[i].dt   := '';
          dmdecodes[i].df   := '';
          dmdecodes[i].ec   := '';
          dmdecodes[i].dec  := '';
          dmdecodes[i].clr  := true;
          dmlastraw[i]      := '';
     end;
     dmdecodecount := 0;
     rawcount := 0; // Index for saving raw decoder outputs

     // Setup temporary spaces
     setLength(glInBuffer,661504);
     setLength(glf1Buffer,661504);

     // Clear internal buffers
     for i := 0 to 661503 do
     Begin
          glInBuffer[i] := 0;
          glf1Buffer[i] := 0.0;
          glf3Buffer[i] := 0.0;
          gllpfM[i] := 0.0;
          if i < 101 Then bins[i] := 0;
          if i < 12 then decsyms[i] := 0;
     end;
     // samps[] contains 16 bit signed integer input samples
     // Convert samps to f1buffer (int16 to float)
     jz := 524287;  // This truncates the last symbol to get a POT transform - otherwise I have to move up to 1048575 - can't see a problem with that so far

     // From this point on f1Buffer becomes sole sample holder.
     // Figure average level
     sq := 0.0;
     for i := 0 to jz do
     begin
          ffoo := samps[i];
          if ffoo <> 0 Then sq := sq + power(ffoo,2);
     end;
     avesq := sq/jz;
     basevb := db(avesq) - 44;
     if (avesq <> 0.0) And (basevb > -16.0) And (basevb < 21.0) Then
     Begin
          set65;
          // Run msync
          //lmousedf := 0;
          jz2 := 0;
          mousedf2 := 0;
          for i := 0 to jz do gllpfM[i] := glf1Buffer[i];
          // lpf1 downsamples from 11025 S/S to 5512.5 S/S
          //lpf1(CTypes.pcfloat(@gllpfM[0]),CTypes.pcint(@jz),CTypes.pcint(@jz2),CTypes.pcint(@lmousedf),CTypes.pcint(@mousedf2),CTypes.pcint(@lical),PChar(wif));

          // HAVE to at least try this :) 262,144 is decimated buffer size
          // Wow... simple decimate seems to work fine.  No more call to the costly lpf1 routine.
          // This starts to put JT65 decoding within range of some DSP chips as all FFT ops but
          // for lpf1 are small size 2K or smaller transforms (I think).  Certainly none left as
          // costly as that done in lpf1.  DEBUG - watch this and make sure it doesn't go to hell
          // once the band picks up - it's fairly dead hours now.

          // Simple 2x decimate on the LPF filtered sample data.
          j := 0;
          jz2 := 262143;
          for i := 0 to jz2 do
          begin
               gllpfM[i] := samps[j];
               j := j+2;
          end;

          // msync will want a downsampled and lpf version of data.
          // Copy lpfM to f3Buffer
          for j := 0 to jz2 do glf3Buffer[j] := gllpfM[j];
          for j := jz2+1 to 661503 do glf3Buffer[j] := 0.0;
          for i := 0 to 254 do
          begin
               dtxa[i]     := 0.0;
               dfxa[i]     := 0.0;
               snrxa[i]    := 0.0;
               snrsynca[i] := 0.0;
          end;

          {
            TODO Think about squashing doing a decode at x then x+20 hz or x then x+50 hz
            for those 2 resolutions.  Tho I would like to do this by picking the strongest
            bin for the points.  This would effectively give a dynamic decoder resolution
            where I look for sync at a fine resolution then "decide" if it's likely I'm
            seeing leakage to bins adjacent.  Might be a good thing.

            So I have dt,df,? and snr of sync - right now I'm just doing a decode anywhere I see a potential
            and not looking at the snr... maybeeeeee if I look at that I can shave some needless decode passes
            on the 20/50 Hz resolutions.

            Say I have a hit at x-20, x, x+20 - that may well be two signals overlapping or spectral leakage
            amongst the bins on strong signals.  The trick will be in squashing images of strong ones without
            killing ability to pull out a weak one that may be intermixed.

            I think - maybe the way will be to say I have a strong hit at X - do not do a pass at X-20 (or 50) or at
            X+20 (or 50).  Once I move to 100+ spacing there's little advantage to thinking about any of this.

            So - if I walk the bins and look for clusters of x-20 x x+20 (or -/+ 50) where x is strongest I should
            likely not do a decode at -x or +x since that seems pretty clearly to be leakage.  And if it's not -
            probably wouldn't get a decode anyways.  Gut tells me this might be a (very) good thing for 20 less so
            on 50 hz spacing.

            First deal with above then research next.

            Now wait - there's another thing.  It's not 20,50,100,200 Hz etc spacing - let me (later) think about
            what the bins actually space to in terms of the FFT resolution - I can still call it 20,50 and etc but....
            it may be more grief is caused pushing these integer centers to the decoder since it may be splitting
            bins or, worse, missing some.
            }

          syncount := 0;
          msync(CTypes.pcfloat(@glf3Buffer[0]),CTypes.pcint(@jz2),CTypes.pcint(@syncount),CTypes.pcfloat(@dtxa[0]),CTypes.pcfloat(@dfxa[0]),CTypes.pcfloat(@snrxa[0]),CTypes.pcfloat(@snrsynca[0]),CTypes.pcint(@lical),PChar(wif));

          // Time to start USING the data I'm getting from msync.
          // 1 - If snrx < -29 kill it.
          // 2 - if dtx > 5 or < -5 kill it.
          // snrsync not needed
          // 3 - if dfx < -1100 or > 1100 kill it.
          // Just set dfx to -9999 then populate bins will ignore it.

          for i := 0 to 254 do
          begin
               if (dtxa[i] < -5.5) Or (dtxa[i] > 5.5) Or (snrxa[i] < -29.6) Or (dfxa[i] < -1100.0) Or (dfxa[i] > 1100.0) Then dfxa[i] := -9999.0;
          end;

          populateBins(dfxa, syncount, bw, bins);

          passcount := 0;
          for i := 0 to 100 do if bins[i] > 0 Then inc(passcount);
          // Passcount is number of potential bins with sync detected.

          i := -1000;
          j := 0;
          // Walk the passband -1000 ... +1000 Hertz in (2000/bin spacing) + 1 steps.
          // bins[0...100] has been set for bins needing a decode
          // Bin space = 100 steps = (2000/100)+1 = 21
          // Bin space =  50 steps = (2000/50)+1  = 41
          while i < 1001 do
          begin
               if bins[j] > 0 Then
               Begin
                    // This bin needs a decode
                    dmlastraw[rawcount] := IntToStr(i) + ' bf ';
                    //ListBox2.Items.Insert(0,'Decode at Center DF = ' + IntToStr(i) + ' for bin = ' + IntToStr(j));
                    // Copy lpfM to f3Buffer
                    for k := 0 to jz2 do glf3Buffer[k] := gllpfM[k];
                    for k := jz2+1 to 661503 do glf3Buffer[k] := 0.0;
                    // Call decoder
                    for k := 0 to 62 do
                    begin
                         lsym1[k] := 0;
                         lsym2[k] := 0;
                         lsym1p[k] := 0;
                         lsym2p[k] := 0;
                    end;

                    lflag    := 0;
                    ljdf     := 0;
                    lnsync   := 0;
                    lnsnr    := 0;
                    lddtx    := 0.0;
                    mouseDF2 := i;
                    afc      := 1;

                    cqz65(CTypes.pcfloat(@glf3buffer[4096]),
                          CTypes.pcint(@jz2),
                          CTypes.pcint(@bw),
                          CTypes.pcint(@MouseDF2),
                          CTypes.pcint(@afc),
                          PChar(wif),
                          CTypes.pcint(@lical),
                          CTypes.pcint(@idf),
                          CTypes.pcint(@lsym1[0]),
                          CTypes.pcint(@lsym2[0]),
                          CTypes.pcint(@lsym1p[0]),
                          CTypes.pcint(@lsym2p[0]),
                          CTypes.pcint(@lflag),
                          CTypes.pcint(@ljdf),
                          CTypes.pcint(@lnsync),
                          CTypes.pcint(@lnsnr),
                          CTypes.pcfloat(@lddtx)
                         );
                    for k := 0 to 50 do rsera[k]  := 0;
                    for k:= 0 to 11 do decsyms[k] := 0;

                    foo := IntToStr(ljdf) + ' df ' + IntToStr(lnsnr) + ' db ' + FormatFloat('0.0',lddtx) + ' dt ' + IntToStr(lnsync) + ' sy';
                    dmlastraw[rawcount] := dmlastraw[rawcount] + foo;
                    rsecount := 0;
                    rscount  := 0;
                    if lflag > -1 Then
                    Begin
                         rsdecode(CTypes.pcint(@lsym1[0]),CTypes.pcint(@rsera[0]),CTypes.pcint(@rsecount),CTypes.pcint(@decsyms[0]),CTypes.pcint(@rscount));
                         foo := IntToStr(ljdf) + ',' + IntToStr(lnsnr) + ',' + FormatFloat('0.0',lddtx) + ',' + IntToStr(lnsync);
                         if rscount > -1 Then
                         Begin
                              foo1 := '';
                              sf   := '';
                              ver  := '';
                              lnc1 := 0;
                              lnc2 := 0;
                              lng  := 0;
                              If decode(decsyms,foo1,sf,ver,lnc1,lnc2,lng) Then
                              Begin
                                   inc(dmdecodecount);
                                   foo := foo + ',B,';
                                   foo := foo + foo1;
                                   dmlastraw[rawcount] := dmlastraw[rawcount] + ' ' + foo1 + ' +B';
                                   wc  := WordCount(foo,[',']);
                                   if wc = 6 Then
                                   Begin
                                        Try
                                           clearList.Add(foo + ',' + sf + ',' + ver + ',' + IntToStr(lnc1) + ',' + IntToStr(lnc2) + ',' + IntToStr(lng)); // Unsorted to maintain proper order
                                        except
                                           // Nada (Any error in adding is ignored as it's likely a dupe reject or bad decode)
                                        end;
                                   end;
                              end
                              else
                              begin
                                   dmlastraw[rawcount] := dmlastraw[rawcount] + ' Data Invalid ';
                              end;
                         end
                         else
                         begin
                              // This is where I try KV
                              // Build the data record
                              dmlastraw[rawcount] := dmlastraw[rawcount] + ' -B';
                              kvdat.nsec1    := 1;
                              kvdat.xlambda  := 12.0;
                              kvdat.maxe     := 8;
                              kvdat.naddsynd := 50;
                              for k := 0 to 62 do kvdat.mrsym[k]  := lsym1[k];
                              for k := 0 to 62 do kvdat.mrprob[k] := lsym1p[k];
                              for k := 0 to 62 do kvdat.mr2sym[k]  := lsym2[k];
                              for k := 0 to 62 do kvdat.mr2prob[k] := lsym2p[k];
                              AssignFile(kvfile,dmtmpdir+'kvasd.dat');
                              //AssignFile(kvfile,'kvasd.dat');
                              Rewrite(kvfile);
                              write(kvfile,kvdat);
                              CloseFile(kvfile);
                              //ListBox2.Items.Insert(0,'Wrote kvasd.dat');
                              // Now attempt the KV process.
                              foo2 := '';
                              sf   := '';
                              ver  := '';
                              lnc1 := 0;
                              lnc2 := 0;
                              lng  := 0;
                              { TODO :
                                Done - pending confirmation my idea works.
                                MUST place kvasd.dat in a proper place and have KV pull from that - not the launch time current directory!
                              }
                              if evalKV('kvasd.dat',foo2,sf,ver,lnc1,lnc2,lng) Then
                              Begin
                                   inc(dmdecodecount);
                                   //ListBox2.Items.Insert(0,'KV Says:  ' + foo2);
                                   foo := foo + ',K,';
                                   foo := foo + foo2;
                                   dmlastraw[rawcount] := dmlastraw[rawcount] + ' ' + foo2 + ' +K';
                                   wc  := WordCount(foo,[',']);
                                   if wc = 6 Then
                                   Begin
                                        Try
                                           clearList.Add(foo + ',' + sf + ',' + ver + ',' + IntToStr(lnc1) + ',' + IntToStr(lnc2) + ',' + IntToStr(lng)); // Unsorted to maintain proper order
                                        except
                                           // Nada (Any error in adding is ignored as it's likely a dupe reject or bad decode)
                                        end;
                                   end;
                              end
                              else
                              begin
                                   dmlastraw[rawcount] := dmlastraw[rawcount] + ' -K';
                              end;
                         end;
                    end
                    else
                    begin
                         dmlastraw[rawcount] := dmlastraw[rawcount] + ' -BK';
                    end;
                    inc(rawcount);
               end;
               inc(j);
               i := i + bw;

          end;

          if clearList.Count > 0 Then
          Begin
               dmhaveDecode := True;
               for j := 0 to clearList.Count-1 do
               begin
                    for k := 0 to 499 do
                    Begin
                         If dmdecodes[k].clr Then
                         Begin
                              dmdecodes[k].ts   := TrimLeft(TrimRight(dmtimestamp));
                              dmdecodes[k].utc  := TrimLeft(TrimRight(dmthisutc));
                              dmdecodes[k].sync := PadLeft(TrimLeft(TrimRight(ExtractWord(4,clearList.Strings[j],[',']))),2);
                              dmdecodes[k].db   := PadLeft(TrimLeft(TrimRight(ExtractWord(2,clearList.Strings[j],[',']))),3);
                              dmdecodes[k].dt   := PadLeft(TrimLeft(TrimRight(ExtractWord(3,clearList.Strings[j],[',']))),4);
                              dmdecodes[k].df   := PadLeft(TrimLeft(TrimRight(ExtractWord(1,clearList.Strings[j],[',']))),5);
                              dmdecodes[k].ec   := TrimLeft(TrimRight(ExtractWord(5,clearList.Strings[j],[','])));
                              dmdecodes[k].dec  := TrimLeft(TrimRight(ExtractWord(6,clearList.Strings[j],[','])));
                              dmdecodes[k].sf   := TrimLeft(TrimRight(ExtractWord(7,clearList.Strings[j],[','])));
                              dmdecodes[k].ver  := TrimLeft(TrimRight(ExtractWord(8,clearList.Strings[j],[','])));
                              dmdecodes[k].nc1  := StrToInt(TrimLeft(TrimRight(ExtractWord(9,clearList.Strings[j],[',']))));
                              dmdecodes[k].nc2  := StrToInt(TrimLeft(TrimRight(ExtractWord(10,clearList.Strings[j],[',']))));
                              dmdecodes[k].ng   := StrToInt(TrimLeft(TrimRight(ExtractWord(11,clearList.Strings[j],[',']))));
                              dmdecodes[k].clr  := False;
                              break;
                         end;
                    end;
               end;
          end;
          clearList.Clear;
          Result := True;
     End
     Else
     Begin
          Result := False;
     End;
     //if decCount = 0 Then
     //Begin
     //     // This was a single decode pass with no decode.  Run the shorthand
     //     // decoder just in case.  Remember.. shdec wants the float samples
     //     // BEFORE LPF application!  This data just happens to be still sitting
     //     // in glf1Buffer[x]
     //     nspecial := 0;
     //     nstest := 0;
     //     dfsh := 0;
     //     iderrsh := 0;
     //     idriftsh := 0;
     //     snrsh := 0;
     //     nwsh := 0;
     //     idfsh := 0;
     //     be := 0;
     //     lmousedf := 0;
     //     binspace := 100;
     //     ListBox1.Items.Add('Attempting SH Decode.');
     //     shdec(@glf1Buffer[0],@be,@lMouseDF,@binspace,@nspecial,@nstest,@dfsh,@iderrsh,@idriftsh,@snrsh,@nwsh,@idfsh,@lical);
     //     if nspecial > 0 Then
     //     Begin
     //          foo := '';
     //          if nspecial = 1 Then foo := 'ATT';
     //          if nspecial = 2 Then foo := 'RO';
     //          if nspecial = 3 Then foo := 'RRR';
     //          if nspecial = 4 Then foo := '73';
     //          ListBox1.Items.Add('Message:  ' + TrimLeft(TrimRight(foo)));
     //     End
     //     Else
     //     Begin
     //          ListBox1.Items.Add('No SH message found.');
     //     End;
     //End;
     setLength(glInBuffer,0);
     setLength(glf1Buffer,0);
     clearList.Destroy;
     dmexit      := Now;
     dmruntime   := MilliSecondSpan(dmenter,dmexit);
     dmarun      := dmarun + dmruntime;
     Inc(dmrcount);
     dmdemodBusy := False;
End;
end.

