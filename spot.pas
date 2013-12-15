{ TODO : Low priority - Look at what RB server says to spots sent - low priority for now }
// (c) 2013 CQZ Electronics
unit spot;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, httpsend, synacode, valobject, StrUtils, CTypes,
  DateUtils, Windows, Types;

Type
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
      dbfsent  : Boolean;
    end;

    spotsArray = Array of spotRecord;

    // Encapsulates all the possible spotting methods to a single unified interface.
    // Handles (for now) RB and PSKR spotting.
    TSpot = Class
       private
              // Control values
              prMyCall      : String;
              prMyGrid      : String;
              prMyQRG       : Integer;
              prUseRB       : Boolean;
              prUseDBF      : Boolean;
              prRBOn        : Boolean;
              prRBError     : String;
              prBusy        : Boolean;
              prVersion     : String;
              prSpots       : spotsArray;
              prVal         : valobject.TValidator;
              prRBCount     : CTypes.cint;
              prRBFail      : CTypes.cint;
              prRBDiscard   : CTypes.cint;
              prPRCount     : CTypes.cint;
              prDBFCount    : CTypes.cint;
              prDBFUCount   : CTypes.cint;
              prDBLock      : Boolean;
              prInfo        : String;
              prLogDir      : String;
              prErrDir      : String;
              prhttp        : THTTPSend;
              rbResult      : TStringList;
              prElog        : TStringList;
              function parseExchange(const exchange : String; var callheard : String; var gridheard : String) : Boolean;
       public
             Constructor create;
             Destructor  endspots;
             function    addSpot(const spot : spotRecord) : Boolean;
             procedure   clearErr;
             function    loginRB    : Boolean;
             function    logoutRB   : Boolean;
             function    pushSpots  : Boolean;
             function    RBCountI   : CTypes.cint;
             function    RBFailS    : String;
             function    RBDiscardS : String;
             function    PRcountS   : String;

             property myCall    : String
                read  prMyCall
                write prMyCall;
             property myGrid    : String
                read  prMyGrid
                write prMyGrid;
             property myQRG     : Integer
                read  prMyQRG
                write prMyQRG;
             property useRB     : Boolean
                read  prUseRB
                write prUseRB;
             property useDBF    : Boolean
                read  prUseDBF
                write prUseDBF;
             property rbOn      : Boolean
                read  prRBOn;
             property busy      : Boolean
                read  prBusy;
             property rbError   : String
                read  prRBError;
             property version   : String
                read  prVersion
                write prVersion;
             property rbCount   : CTypes.cint
                read  RBCountI;
             property rbDiscard : String
                read  rbDiscardS;
             property rbFail    : String
                read  RBFailS;
             property rbInfo    : String
                read  prInfo
                write prInfo;
             property rbVersion : String
                read  prVersion
                write prVersion;
             property logDir : String
                read  prLogDir
                write prLogDir;
             property errDir : String
                read  prErrDir
                write prErrDir;
             property errLog : TStringList
                read  prElog;
       end;

implementation

    constructor TSpot.Create;
    var
       i : Integer;
    Begin
         // Setup validation utility object
         prVal     := valobject.TValidator.create();
         // Setup http object for RB use
         prhttp         := THTTPSend.Create;
         prMyCall    := '';
         prMyGrid    := '';
         prMyQRG     := 0;
         prUseRB     := false;
         prUseDBF    := False;
         prRBOn      := False;
         prRBError   := '';
         prVersion   := '0';
         prRBCount   := 0;
         prPRCount   := 0;
         prRBFail    := 0;
         prDBFCount  := 0;
         prDBFUCount := 0;
         prRBDiscard := 0;
         prDBLock    := False;
         prInfo      := '';
         prLogDir    := '';
         prErrDir    := '';

         prELog := TStringList.Create;
         prELog.CaseSensitive := False;
         prELog.Sorted := False;
         prELog.Duplicates := Types.dupAccept;
         prElog.Clear;

         setlength(prSpots,65536);
         for i := 0 to Length(prspots)-1 do
         begin
              prspots[i].qrg      := 0;
              prspots[i].date     := '';
              prspots[i].time     := '';
              prspots[i].sync     := 0;
              prspots[i].db       := 0;
              prspots[i].dt       := '0.0';
              prspots[i].df       := 0;
              prspots[i].decoder  := '';
              prspots[i].exchange := '';
              prspots[i].mode     := '65A';
              prspots[i].rbsent   := true;
              prspots[i].dbfsent  := true;
         end;
         rbResult := TStringList.Create;
         rbResult.Clear;
    End;

    Destructor TSpot.endspots;
    Begin
         prHTTP.Free;                       // Release HTTP object
         setlength(prSpots,0);              // Free spots array
    end;

    procedure TSpot.clearErr;
    Begin
         errLog.Clear;
    end;

    function  TSpot.RBcountI : CTypes.cint;
    begin
         result := prRBCount;
    end;

    function  TSpot.RBDiscardS : String;
    begin
         result := IntToStr(prRBDiscard);
    end;

    function  TSpot.RBFailS : String;
    begin
         result := IntToStr(prRBFail);
    end;

    function  TSpot.PRcountS : String;
    begin
         result := IntToStr(prPRCount);
    end;

    function  TSpot.addSpot(const spot : spotRecord) : Boolean;
    var
       i         : Integer;
       inserted  : Boolean;
    begin
         inserted := false;
         for i := 0 to Length(prspots)-1 do
         begin
              if prSpots[i].rbsent and prSpots[i].dbfsent then
              begin
                   // Found a spot to insert a new report
                   prspots[i].qrg      := spot.qrg;
                   prspots[i].date     := spot.date;
                   prspots[i].time     := spot.time;
                   prspots[i].sync     := spot.sync;
                   prspots[i].db       := spot.db;
                   prspots[i].dt       := spot.dt;
                   prspots[i].df       := spot.df;
                   prspots[i].decoder  := spot.decoder;
                   prspots[i].exchange := spot.exchange;
                   prspots[i].mode     := '65A';
                   prspots[i].rbsent   := false;
                   prspots[i].dbfsent  := false;
                   inserted := true;
                   break;
              end;
         end;
         result := inserted;
    end;

    function TSpot.loginRB : Boolean;
    var
       url      : String;
    Begin
         prRBError    := '';
         prBusy       := True;
         url          := 'http://jt65.w6cqz.org/rb.php?func=LI&callsign=' + prMyCall + '&grid=' + prMyGrid + '&qrg=' + IntToStr(prMyQRG) + '&rbversion=' + prVersion;
         prhttp.Clear;
         prhttp.Timeout := 10000;  // 10K ms = 10 s
         prhttp.Headers.Add('Accept: text/html');
         rbResult.Clear;
         Try
            // This logs in to the RB System using parameters set in the object class
            if not prHTTP.HTTPMethod('GET', url) Then
            begin
                 prRBOn := False;
                 result := False;
            end
            else
            begin
                 rbResult.LoadFromStream(prHTTP.Document);
                 // Messages RB login can return:
                 // QSL - All good, logged in.
                 // NO - Indicates login failed but not due to bad RB data, so it's safe to try again. (Probably RB Server busy)
                 // BAD QRG - Fix the RB's QRG error before trying again.
                 // BAD GRID - Invalid Grid value, fix before trying again.
                 // BAD CALL - RB Call too short/long, fix before trying again.
                 prRBOn := False;
                 If TrimLeft(TrimRight(rbResult.Text)) = 'QSL'      Then prRBOn := true;
                 //If TrimLeft(TrimRight(rbResult.Text)) = 'BAD QRG'  Then prRBOn := false;
                 //If TrimLeft(TrimRight(rbResult.Text)) = 'BAD GRID' Then prRBOn := false;
                 //If TrimLeft(TrimRight(rbResult.Text)) = 'BAD CALL' Then prRBOn := false;
                 //If TrimLeft(TrimRight(rbResult.Text)) = 'BAD MODE' Then prRBOn := false;
                 //If TrimLeft(TrimRight(rbResult.Text)) = 'NO'       Then prRBOn := false;
                 prRBError := TrimLeft(TrimRight(rbresult.Text));
            end;
         Except
            prRBError := 'EXCEPTION';
            prRBOn    := False;
         End;
         prBusy := False;
         prBusy := False;
         result := prRBOn;
    end;

    function TSpot.logoutRB : Boolean;
    var
       url  : String;
       band : String;
       go   : Boolean;
    Begin
         prBusy       := True;
         band := '';
         if prVal.evalIQRG(prMyQRG,'LAX',band) then go := true else go := false;
         if go then
         begin
              rbResult.Clear;
              prRBError    := '';
              url          := 'http://jt65.w6cqz.org/rb.php?func=LO&callsign=' + prMyCall + '&grid=' + prMyGrid + '&qrg=' + IntToStr(prMyQRG) + '&rbversion=' + prVersion;
              prhttp.Clear;
              prhttp.Timeout := 10000;  // 10K ms = 10 s
              prhttp.Headers.Add('Accept: text/html');
              Try
                 // This logs out the RB using parameters set in the object class
                 if not prHTTP.HTTPMethod('GET', url) Then
                 begin
                      prRBOn := False;
                      result := False;
                 end
                 else
                 begin
                      rbResult.LoadFromStream(prHTTP.Document);
                      // Messages RB login can return:
                      // QSL - All good, logged out.
                      // NO - Indicates logout failed. (Probably RB Server busy)
                      If TrimLeft(TrimRight(rbResult.Text[1..3])) = 'QSL' Then prRBOn := false;
                      If TrimLeft(TrimRight(rbResult.Text[1..2])) = 'NO'  Then prRBOn := true;
                      prRBError := TrimLeft(TrimRight(rbresult.Text));
                 end;
              Except
                 prRBError := 'EXCEPTION';
                 prRBOn    := True;
              End;
              if prRBOn then result := false else result := true;
         end
         else
         begin
              prRBError := 'QRG';
              prRBOn    := false;
              result    := false;
         end;
         result := true;
         prBusy := False;
    end;

    function TSpot.pushSpots : Boolean;
    var
       url       : String;
       i         : Integer;
       resolved  : Boolean;
       callheard : String;
       gridheard : String;
       band      : String;
       cont      : Boolean;
    Begin
         // Check to see if there's any reason to execute any of this :)
         cont := false;
         for i := 0 to Length(prspots)-1 do
         begin
              if not prSpots[i].rbsent then cont := true;
              //if not prSpots[i].pskrsent then cont := true;
              if cont then break;
         end;

         prRBError := '';
         band      := '';
         prBusy    := True;
         // This function handles sending spots to RB Network, PSK Reporter or Internal Database
         if prUseRB and cont then
         begin
              // Do RB work
              for i := 0 to Length(prspots)-1 do
              begin
                   if not prSpots[i].rbsent then
                   begin
                        // OK.  Found an entry not marked as sent.  Is it something to send or not?
                        rbResult.Clear;
                        url       := '';
                        resolved  := false;
                        callheard := '';
                        gridheard := '';
                        if parseExchange(prSpots[i].exchange, callheard, gridheard) and prVal.evalIQRG(prSpots[i].qrg,'LAX',band) then
                        begin
                             prhttp.Clear;
                             prhttp.Timeout := 10000;  // 10K ms = 10 s
                             prhttp.Headers.Add('Accept: text/html');
                             url := synacode.EncodeURL('http://jt65.w6cqz.org/rb.php?func=RR&callsign=' + prMyCall + '&grid=' + prMyGrid + '&qrg=' + IntToStr(prSpots[i].qrg) + '&rxdate=' + prSpots[i].date + '&callheard=' + callheard + '&gridheard=' + gridheard + '&siglevel=' + IntToStr(prSpots[i].db) + '&deltaf=' + IntToStr(prSpots[i].df) + '&deltat=' + prSpots[i].dt + '&decoder=' + prSpots[i].decoder + '&mode=' + prSpots[i].mode + '&exchange=' + prSpots[i].exchange + '&rbversion=' + prVersion);
                             Try
                                if prHTTP.HTTPMethod('GET', url) Then
                                begin
                                     rbResult.LoadFromStream(prHTTP.Document);
                                     // Messages RB login can return:
                                     // QSL - All good, spot saved.
                                     // NO - Indicates spot failed and safe to retry. (Probably RB Server busy)
                                     // ERR - Indicates RB Server has an issue with the data and not allowed to retry.
                                     // QRG - Indicates RB Server will no accept the current QRG
                                     prRBError := rbResult.Text;
                                     If Length(rbResult.Text) > 1 then
                                     begin
                                          resolved := True;
                                          If TrimLeft(TrimRight(rbResult.Text)) = 'QSL' Then resolved := true;
                                          If TrimLeft(TrimRight(rbResult.Text)) = 'QRG' Then resolved := false;
                                          If TrimLeft(TrimRight(rbResult.Text)) = 'NO'  Then resolved := false;
                                          If TrimLeft(TrimRight(rbResult.Text)) = 'ERR' Then resolved := false;
                                          if not resolved then
                                          Begin
                                               prElog.Add(url);
                                               prElog.Add('Unexpected response:  ' + rbResult.Text);
                                          end;
                                     end
                                     else
                                     begin
                                          // Unexpected return value from URL call
                                          prElog.Add(url);
                                          prElog.Add('Unexpected response [short]:  ' + rbResult.Text);
                                     end;
                                end
                                else
                                begin
                                     resolved := False;
                                     prElog.Add(url);
                                     prElog.Add('Server failed to respond:  ' + prHTTP.ResultString);
                                end;
                             Except
                                //foo := 'EXC';
                                resolved := false;
                                prElog.Add(url);
                                prElog.Add('Exception thrown');
                             End;
                             // Wrap up by checking for status of spot and clearing its place in the list as appropriate.
                             if resolved then
                             begin
                                  prSpots[i].rbsent := true;
                                  inc(prRBCount);
                             end
                             else
                             begin
                                  { TODO [1.1.0] Pass back error to main code so user can be notified of problem }
                                  { TODO [1.1.0] This is a hard fail.. even in the case where a retry is warranted the spot is discarded. }
                                  //if length(foo) < 2 then foo := 'EXC';
                                  //prSpots[i].rbsent:= true;
                                  //if foo[1..3] = 'QRG' then prSpots[i].rbsent := true;  // RB Server says bad QRG so don't try to send this again...
                                  //if foo[1..2] = 'NO' then prSpots[i].rbsent  := true; { TODO : Fix this (Set back to true) once I decide how to better handle retries }
                                  //if foo[1..3] = 'EXC' then prSpots[i].rbsent := true; { TODO : Fix this (Set back to true) once I decide how to better handle retries }
                                  //if foo[1..3] = 'ERR' then prSpots[i].rbsent := true;
                                  //if foo[1..3] = 'BAD' then prSpots[i].rbsent := true;  // RB Server doesn't like some of the data (probably big DT) so no resend
                                  //foo := prRBError;
                                  inc(prRBFail);
                             end;
                        end
                        else
                        begin
                             inc(prRBDiscard);
                             // Excahnge did not parse to something of use or qrg invalid.  Mark it sent so it can be cleared.
                             prSpots[i].rbsent   := true;
                             prSpots[i].dbfsent  := true;
                        end;
                        Randomize;
                        sleep(Random(300)); // Lets not overload the RB server with little or no delay between spot posts.
                   end;
              end;
         end
         else
         begin
              // Process any spots marked as not sent for RB lest the array fills with unsent entries. This is only called
              // when RB spotting is not enabled as it is otherwise cleared above.
              for i := 0 to Length(prspots)-1 do if not prSpots[i].rbsent then prSpots[i].rbsent := true;
         end;
         // All done.

         // Security blanket code
         for i := 0 to Length(prspots)-1 do if not prSpots[i].rbsent then prSpots[i].rbsent := true;
         for i := 0 to Length(prspots)-1 do if not prSpots[i].dbfsent then prSpots[i].dbfsent := true;
         result := true;
         prBusy := false;
    end;

    function  TSpot.parseExchange(const exchange : String; var callheard : String; var gridheard : String) : Boolean;
    var
       w1,w2,w3  : String;
       w4,w5,w6  : String;
       resolved  : Boolean;
    Begin
         // I'm probably going to annoy some, but, as of 1.8.0 the RB/PSK Reporter
         // spots will only spot callsigns using JT65 frames that are strictly valid
         // in the sense of JT65 structured messages.
         // Those being:
         //
         // 2 Word frames
         //
         // CQ           PFX/CALLSIGN
         // CQ           CALLSIGN/SFX
         // QRZ          PFX/CALLSIGN
         // QRZ          CALLSIGN/SFX
         // CALLSIGN     PFX/CALLSIGN
         // CALLSIGN     CALLSIGN/SFX
         // PFX/CALLSIGN CALLSIGN
         // CALLSIGN/SFX CALLSIGN
         //
         // And I will allow the following messages that are not structured,
         // but, are safe enough to deal with in free text mode and not, in
         // general, abused.
         //
         // Non-structured 2 word frames
         //
         // TEST         CALLSIGN
         // CALLSIGN     TEST
         // CALLSIGN     GRID6
         // CALLSIGN     GRID4
         //
         // 3 Word frames
         //
         // CQ           CALLSIGN GRID
         // QRZ          CALLSIGN GRID
         // CALLSIGN     CALLSIGN GRID
         // CALLSIGN     CALLSIGN -##
         // CALLSIGN     CALLSIGN R-##
         // CALLSIGN     CALLSIGN RRR
         // CALLSIGN     CALLSIGN 73
         //
         // OK.  Those are what I'll allow.  This means stations using something
         // like CQ DX CALLSIGN or CQDX CALLSIGN or whatever of the endless things
         // people think to try will not be spotted.  Since the RB system is mine
         // I get to make the rules.  :)
         //
         //
         // If the word count is < 2 or > 3 then I'm not interested in trying
         // to extract anything from it.
         //
         resolved := false;
         result    := false;
         if (wordcount(exchange,[' ']) = 2) or (wordcount(exchange,[' ']) = 3) then resolved := true else resolved := false;
         if resolved then
         begin
              if(wordcount(exchange,[' ']) = 2) then
              begin
                   w1 := ExtractWord(1,exchange,[' ']);
                   w2 := ExtractWord(2,exchange,[' ']);
                   w3 := '   ';
              end;
              if(wordcount(exchange,[' ']) = 3) then
              begin
                   w1 := ExtractWord(1,exchange,[' ']);
                   w2 := ExtractWord(2,exchange,[' ']);
                   w3 := ExtractWord(3,exchange,[' ']);
              end;
         end;
         if resolved then
         begin
              // Have an exchange with 2 or 3 words so it is safe to proceed.
              // Evaluate excahnge for slashed callsign in a 3 word frame
              if (wordcount(exchange,[' '])=3) and (ansiContainsText(exchange,'/')) then resolved := false else resolved := true;
              if resolved then
              begin
                   // Passed the check for no slash in 3 word frame
                   // Doing the 3 word frame types first
                   resolved := false;
                   if not resolved and (w1='CQ') and prVal.evalCSign(w2) and prVal.evalGrid(w3) then
                   begin
                        // w1           w2       w3
                        // CQ           CALLSIGN GRID
                        resolved  := true;
                        result    := true;
                        callheard := w2;
                        gridheard := w3;
                   end;
                   if not resolved and (w1='QRZ') and prVal.evalCSign(w2) and prVal.evalGrid(w3) then
                   begin
                        // w1           w2       w3
                        // QRZ          CALLSIGN GRID
                        resolved  := true;
                        result    := true;
                        callheard := w2;
                        gridheard := w3;
                   end;
                   if not resolved and prVal.evalCSign(w1) and prVal.evalCSign(w2) and prVal.evalGrid(w3) then
                   begin
                        // w1           w2       w3
                        // CALLSIGN     CALLSIGN GRID
                        resolved  := true;
                        result    := true;
                        callheard := w2;
                        gridheard := w3;
                   end;
                   if not resolved and prVal.evalCSign(w1) and prVal.evalCSign(w2) and (w3[1]='-') then
                   begin
                        // w1           w2       w3
                        // CALLSIGN     CALLSIGN -##
                        resolved  := true;
                        result    := true;
                        callheard := w2;
                        gridheard := 'NILL';
                   end;
                   if not resolved and prVal.evalCSign(w1) and prVal.evalCSign(w2) and (w3[1]='R') then
                   begin
                        // w1           w2       w3
                        // CALLSIGN     CALLSIGN R-##
                        // CALLSIGN     CALLSIGN RRR
                        resolved  := true;
                        result    := true;
                        callheard := w2;
                        gridheard := 'NILL';
                   end;
                   if not resolved and prVal.evalCSign(w1) and prVal.evalCSign(w2) and (w3[1]='7') then
                   begin
                        // w1           w2       w3
                        // CALLSIGN     CALLSIGN 73
                        resolved  := true;
                        result    := true;
                        callheard := w2;
                        gridheard := 'NILL';
                   end;
              end;
              //
              // 3 word frames handled now on to 2 word frames
              //
              if not resolved then
              begin
                   if not resolved and (w1='TEST') and prVal.evalCSign(w2) and (w3 = '   ') then
                   begin
                        // w1           w2
                        // TEST         CALLSIGN
                        resolved  := true;
                        result    := true;
                        callheard := w2;
                        gridheard := 'NILL';
                   end;
                   if not resolved and prVal.evalCSign(w1) and (w1='TEST') and (w3 = '   ') then
                   begin
                        // w1           w2
                        // CALLSIGN     TEST
                        resolved  := true;
                        result    := true;
                        callheard := w1;
                        gridheard := 'NILL';
                   end;
                   if not resolved and prVal.evalCSign(w1) and prVal.evalGrid(w2) and (w3 = '   ') then
                   begin
                        // w1           w2
                        // CALLSIGN     GRID6
                        // CALLSIGN     GRID4
                        resolved  := true;
                        result    := true;
                        callheard := w1;
                        gridheard := w2;
                   end;
                   if not resolved and ((w1='CQ') or (w1='QRZ')) and prVal.evalCSign(w2) and (w3 = '   ') then
                   begin
                        // w1           w2
                        // CQ           CALLSIGN
                        // QRZ          CALLSIGN
                        resolved  := true;
                        result    := true;
                        callheard := w2;
                        gridheard := 'NILL';
                   end;
                   if not resolved and prVal.evalCSign(w1) and prVal.evalCSign(w2) and (w3 = '   ') then
                   begin
                        // Tentative on this one...
                        // w1           w2
                        // CALLSIGN     CALLSIGN
                        resolved  := true;
                        result    := true;
                        callheard := w2;
                        gridheard := 'NILL';
                   end;
                   if not resolved and (ansiContainsText(w1,'/') or ansiContainsText(w2,'/')) then
                   begin
                        if not resolved and ((w1='CQ') or (w1='QRZ')) then
                        Begin
                             // The slash has to be in the second word...
                             if ansiContainsText(w2,'/') then
                             begin
                                  w4 := ExtractWord(1,w2,['/']);
                                  w5 := ExtractWord(2,w2,['/']);
                                  if length(w4) > length(w5) then w6 := w4;
                                  if length(w5) > length(w4) then w6 := w5;
                                  if prVal.evalCSign(w6) then
                                  begin
                                       // w1           w2
                                       // CQ           PFX/CALLSIGN
                                       // CQ           CALLSIGN/SFX
                                       // QRZ          PFX/CALLSIGN
                                       // QRZ          CALLSIGN/SFX
                                       resolved  := True;
                                       result    := true;
                                       callheard := w2;  // Remember, w2 contains the full callsign where w6 only contains the base call
                                       gridheard := 'NILL';
                                  end;
                             end;
                        end;
                        if not resolved and prVal.evalCSign(w1) then
                        begin
                             // w2 must be the slashed callsign
                             if ansiContainsText(w2,'/') then
                             begin
                                  w4 := ExtractWord(1,w2,['/']);
                                  w5 := ExtractWord(2,w2,['/']);
                                  if length(w4) > length(w5) then w6 := w4;
                                  if length(w5) > length(w4) then w6 := w5;
                                  if prVal.evalCSign(w6) then
                                  begin
                                       // w1           w2
                                       // CALLSIGN     PFX/CALLSIGN
                                       // CALLSIGN     CALLSIGN/SFX
                                       resolved  := True;
                                       result    := true;
                                       callheard := w2;  // Remember, w2 contains the full callsign where w6 only contains the base call
                                       gridheard := 'NILL';
                                  end;
                             end;
                        end;
                        if not resolved and prVal.evalCSign(w2) then
                        begin
                             // w1 must be the slashed callsign and it doesn't matter so this is easy
                             // w1           w2
                             // PFX/CALLSIGN CALLSIGN
                             // CALLSIGN/SFX CALLSIGN
                             resolved  := True;
                             result    := true;
                             callheard := w2;
                             gridheard := 'NILL';
                        end;
                   end;
              end;
         end;
    end;

    //function TSpot.BuildRemoteString (call, mode, freq, date, time : String) : WideString;
    //begin
    //     If freq='0' Then
    //        result := 'call' + #0 + call + #0 + 'mode' + #0 + mode + #0 + 'QSO_DATE' + #0 + date + #0 + 'TIME_ON' + #0 + time + #0 + #0
    //     else
    //        result := 'call' + #0 + call + #0 + 'mode' + #0 + mode + #0 + 'freq' + #0 + freq + #0 + 'QSO_DATE' + #0 + date + #0 + 'TIME_ON' + #0 + time + #0 + #0;
    //end;
    //
    //function TSpot.BuildRemoteStringGrid (call, mode, freq, grid, date, time : String) : WideString;
    //begin
    //     If freq='0' Then
    //        result := 'call' + #0 + call + #0 + 'mode' + #0 + mode + #0 + 'gridsquare' + #0 + grid + #0 + 'QSO_DATE' + #0 + date + #0 + 'TIME_ON' + #0 + time + #0 + #0
    //     else
    //        result := 'call' + #0 + call + #0 + 'mode' + #0 + mode + #0 + 'freq' + #0 + freq + #0 + 'gridsquare' + #0 + 'QSO_DATE' + #0 + date + #0 + 'TIME_ON' + #0 + time + #0 + #0;
    //end;
    //
    //function TSpot.BuildLocalString (station_callsign, my_gridsquare, programid, programversion, my_antenna : String) : WideString;
    //begin
    //     result := 'station_callsign' + #0 + station_callsign + #0 + 'my_gridsquare' + #0 + my_gridsquare + #0 +
    //               'programid' + #0 + programid + #0 +
    //               'programversion' + #0 + programversion + #0 +
    //               'my_antenna' + #0 + my_antenna + #0 + #0;
    //end;

end.

