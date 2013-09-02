// (c) 2013 CQZ Electronics
unit valobject;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

Const
     JT65delimiter = ['A'..'Z','0'..'9','+','-','.','/','?',' '];

type
  JT65Characters = Set Of Char;

  TValidator = Class
     private
        // Station callsign and grid
        prCall          : String;
        prCWCall        : String;
        prGrid          : String;
        prPrefix        : Integer;
        prSuffix        : Integer;
        prRBCall        : String;
        prRBInfo        : String;
        prCallValid     : Boolean;
        prCWCallValid   : Boolean;
        prRBCallValid   : Boolean;
        prGridValid     : Boolean;
        prPrefixValid   : Boolean;
        prSuffixValid   : Boolean;
        prRBInfoValid   : Boolean;
        prCallError     : String;
        prGridError     : String;
        prRBCallError   : String;
        prRBInfoError   : String;
        prSuffixError   : String;
        prPrefixError   : String;
        prDeciEuro      : Boolean;
        prDeciAmer      : Boolean;

     public
        Constructor create();
        procedure setCallsign(msg : String);
        procedure setCWCallsign(msg : String);
        procedure setRBCallsign(msg : String);
        procedure setGrid(msg : String);
        function asciiValidate(msg : Char; mode : String) : Boolean;
        function evalQRG(const qrg : String; const mode : string; var qrgk : Double; var qrghz : Integer; var asciiqrg : String) : Boolean;
        function evalIQRG(const qrg : Integer; const mode : String; var band : String) : Boolean;
        function evalCSign(const call : String) : Boolean;
        function evalGrid(const grid : String) : Boolean;

     property callsign      : String
        read  prCall
        write setCallsign;
     property cwCallsign    : String
        read  prCWCall
        write setCWCallsign;
     property rbCallsign    : String
        read  prRBCall
        write setRBCallsign;

     property grid          : String
        read  prGrid
        write setGrid;

     //property prefix        : Integer
     //   write setPrefix;
     //property suffix        : Integer
     //   write setSuffix;
     //property rbInfo        : String
     //   write setRBInfo;

     property callsignValid : Boolean
        read  prCallValid;
     property rbCallSignValid   : Boolean
        read  prRBCallValid;
     property cwCallsignValid : Boolean
        read  prCWCallValid;

     property gridValid     : Boolean
        read  prGridValid;

     property prefixValid   : Boolean
        read  prPrefixValid;
     property suffixValid   : Boolean
        read  prSuffixValid;

     property rbInfoValid   : Boolean
        read  prRBInfoValid;

     property callError     : String
        read  prCallError;

     property gridError     : String
        read  prGridError;

     property rbInfoError   : String
        read  prRBInfoError;

     property suffixError   : String
        read  prSuffixError;

     property prefixError   : String
        read  prPrefixError;

        property forceDecimalEuro : Boolean
           write prDeciEuro;
        property forceDecimalAmer : Boolean
           write prDeciAmer;
  end;

implementation
   constructor TValidator.Create();
   begin
        prCall          := '';
        prCWCall        := '';
        prGrid          := '';
        prPrefix        := 0;
        prSuffix        := 0;
        prRBCall        := '';
        prRBInfo        := '';
        prCallValid     := False;
        prCWCallValid   := False;
        prGridValid     := False;
        prPrefixValid   := False;
        prSuffixValid   := False;
        prRBCallValid   := False;
        prRBInfoValid   := False;
        prCallError     := '';
        prGridError     := '';
        prRBCallError   := '';
        prRBInfoError   := '';
        prSuffixError   := '';
        prPrefixError   := '';
        prDeciEuro      := False;
        prDeciAmer      := False;
   end;

   procedure TValidator.setCWCallsign(msg : String);
   var
        testcall : String;
   begin
        testcall := trimleft(trimright(msg));
        testcall := upcase(testcall);
        If (AnsiContainsText(testcall,'.')) Or
           (AnsiContainsText(testcall,'-')) Or (AnsiContainsText(testcall,'\')) Or
           (AnsiContainsText(testcall,',')) Or (AnsiContainsText(testcall,' ')) Or
           (AnsiContainsText(testcall,'Ø')) Or (length(testcall) < 3) Or
           (length(testcall) > 32) Then
        Begin
             // Contains bad character
             if (length(testcall) > 2) and (length(testcall) < 33) then prCallError := 'May not contain the characters . - \ , Ø or space.' else prCallError := 'Too short';
             prCWCallValid := false;
             prCWCall := '';
        end
        else
        begin
             prCallError := '';
             prCWCallValid := true;
             prCWCall := testcall;
        end;
   end;

   procedure TValidator.setRBCallsign(msg : String);
   var
        testcall : String;
   begin
        testcall := trimleft(trimright(msg));
        testcall := upcase(testcall);
        If (AnsiContainsText(testcall,'.')) Or
           (AnsiContainsText(testcall,'-')) Or (AnsiContainsText(testcall,'\')) Or
           (AnsiContainsText(testcall,',')) Or (AnsiContainsText(testcall,' ')) Or
           (AnsiContainsText(testcall,'Ø')) Or (length(testcall) < 3) Or
           (length(testcall) > 32) Then
        Begin
             // Contains bad character
             if (length(testcall) > 2) and (length(testcall) < 33) then prCallError := 'May not contain the characters . - \ , Ø or space.' else prCallError := 'Too short';
             prRBCallValid := false;
             prRBCall := '';
        end
        else
        begin
             prCallError := '';
             prRBCallValid := true;
             prRBCall := testcall;
        end;
   end;

   function  TValidator.evalCSign(const call : String) : Boolean;
   var
        valid    : Boolean;
        testcall : String;
   begin
        valid := True;
        result := False;
        testcall := call;
        // Simple length check
        if (length(testcall) < 3) or (length(testcall) > 6) then
        begin
             valid := False;
             prCallError := 'Too short';
        end
        else
        begin
             valid := True;
        end;
        // Not too short or too long, now test for presence of 'bad' characters.
        if valid then
        begin
             If (AnsiContainsText(testcall,'/')) Or (AnsiContainsText(testcall,'.')) Or
                (AnsiContainsText(testcall,'-')) Or (AnsiContainsText(testcall,'\')) Or
                (AnsiContainsText(testcall,',')) Or (AnsiContainsText(testcall,' ')) Then
             Begin
                  valid := False;
                  prCallError := 'May not contain the characters . - \ , Ø or space.';
             end
             else
             begin
                  valid := true;
             end;
        end;
        // If length and bad character checks pass on to the full validator
        if valid then
        begin
             valid := False;
             // Callsign rules:
             // Length must be >= 3 and <= 6
             // Must be of one of the following;
             // A = Alpha character A ... Z
             // # = Numeral 0 ... 9
             // Allowing SWL for use as well with SWL ID in RB callsign field
             //
             // A#A A#AA A#AAA or AA#A AA#AA AA#AAA or #A#A #A#AA #A#AAA or
             // A##A A##AA A##AAA
             //
             // All characters must be A...Z or 0...9 or space
             if length(testCall) = 3 Then
             Begin
                  // 3 Character callsigns have only one valid format: A#A
                  valid := False;
                  case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                  if valid then
                  begin
                       case testcall[2] of '0'..'9': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[3] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if not valid then
                  begin
                       if testcall = 'SWL' then valid := true else valid := false;
                  end;
             End;
             if length(testCall) = 4 Then
             Begin
                  // 4 Character callsigns can be:  A#AA AA#A #A#A A##A
                  // Testing for A#AA
                  valid := False;
                  case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                  if valid then
                  begin
                       case testcall[2] of '0'..'9': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[3] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  // Testing for AA#A (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  // Testing for #A#A (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of '0'..'9': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  // Testing for A##A (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
             End;
             if length(testCall) = 5 Then
             Begin
                  // 5 Character callsigns can be:  A#AAA AA#AA #A#AA A##AA
                  // Testing for A#AAA
                  valid := False;
                  case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                  if valid then
                  begin
                       case testcall[2] of '0'..'9': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[3] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  // Testing for AA#AA (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  // Testing for #A#AA (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of '0'..'9': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  // Testing for A##AA (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
             End;
             if length(testCall) = 6 Then
             Begin
                  // 6 Character callsigns can be:  AA#AAA #A#AAA A##AAA
                  // Testing for AA#AAA
                  valid := False;
                  case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                  if valid then
                  begin
                       case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[3] of '0'..'9': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[6] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  // Testing for #A#AAA (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of '0'..'9': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[6] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  // Testing for A##AAA (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[6] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
             End;
             // All possible 3, 4, 5 and 6 character length callsigns have been tested
             // for conformance to JT65 callsign encoding rules.  If valid = true we're
             // good to go.  Of course, you can still specify a callsign that is not
             // 'real', but, which conforms to the encoding rules...  I make no attempt
             // to validate a callsign to be something that is valid/legal.  Only that it
             // conforms to the encoder rules.
        end;
        if not valid Then prCallError := 'Callsign does not fit the JT65 protocol requirements.';
        result := valid;
   end;

   procedure TValidator.setCallsign(msg : String);
   var
        valid    : Boolean;
        testcall : String;
   begin
        valid := True;
        testcall := trimleft(trimright(msg));
        testcall := upcase(testcall);
        prCall := testcall;
        // Simple length check
        if (length(testcall) < 3) or (length(testcall) > 6) then
        begin
             prCallValid := False;
             if length(testcall) < 3 then prCallError := 'Callsign too short.';
             if length(testcall) > 6 then prCallError := 'Callsign too long.';
             valid := False;
        end
        else
        begin
             prCallError := '';
             valid := True;
        end;
        // Not too short or too long, now test for presence of 'bad' characters.
        if valid then
        begin
             If (AnsiContainsText(testcall,'/')) Or (AnsiContainsText(testcall,'.')) Or
                (AnsiContainsText(testcall,'-')) Or (AnsiContainsText(testcall,'\')) Or
                (AnsiContainsText(testcall,',')) Or (AnsiContainsText(testcall,' ')) Then
             Begin
                  valid := False;
                  // Contains bad character
                  prCallError := 'May not contain the characters / . - \ , Ø or space.';
             end
             else
             begin
                  prCallError := '';
                  valid := True;
             end;
        end;
        // If length and bad character checks pass on to the full validator
        if valid then
        begin
             valid := False;
             // Callsign rules:
             // Length must be >= 3 and <= 6
             // Must be of one of the following;
             // A = Alpha character A ... Z
             // # = Numeral 0 ... 9
             // Allowing SWL for use as well with SWL ID in RB callsign field
             //
             // A#A A#AA A#AAA or AA#A AA#AA AA#AAA or #A#A #A#AA #A#AAA or
             // A##A A##AA A##AAA
             //
             // All characters must be A...Z or 0...9 or space
             if length(testCall) = 3 Then
             Begin
                  // 3 Character callsigns have only one valid format: A#A
                  valid := False;
                  case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                  if valid then
                  begin
                       case testcall[2] of '0'..'9': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[3] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if not valid then
                  begin
                       if testcall = 'SWL' then valid := true else valid := false;
                  end;
                  if not valid then prCallError := 'Must be A#A or SWL' + sLineBreak + 'Where A = Letter A to Z and # = Digit 0 to 9' else prCallError := '';
             End;
             if length(testCall) = 4 Then
             Begin
                  // 4 Character callsigns can be:  A#AA AA#A #A#A A##A
                  // Testing for A#AA
                  valid := False;
                  case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                  if valid then
                  begin
                       case testcall[2] of '0'..'9': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[3] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  // Testing for AA#A (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  // Testing for #A#A (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of '0'..'9': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  // Testing for A##A (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  if not valid then
                  begin
                       // 4 Character callsigns can be:  A#AA AA#A #A#A A##A
                       prCallError := 'Must be A#AA or AA#A or #A#A or A##A' + sLineBreak + 'Where A = Letter A to Z and # = Digit 0 to 9';
                  end
                  else
                  begin
                       prCallError := '';
                  end;
             End;
             if length(testCall) = 5 Then
             Begin
                  // 5 Character callsigns can be:  A#AAA AA#AA #A#AA A##AA
                  // Testing for A#AAA
                  valid := False;
                  case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                  if valid then
                  begin
                       case testcall[2] of '0'..'9': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[3] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  // Testing for AA#AA (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  // Testing for #A#AA (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of '0'..'9': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  // Testing for A##AA (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  if not valid then
                  begin
                       // 5 Character callsigns can be:  A#AAA AA#AA #A#AA A##AA
                       prCallError := 'Must be A#AAA or AA#AA or #A#AA or A##AA' + sLineBreak + 'Where A = Letter A to Z and # = Digit 0 to 9';
                  end
                  else
                  begin
                       prCallError := '';
                  end;
             End;
             if length(testCall) = 6 Then
             Begin
                  // 6 Character callsigns can be:  AA#AAA #A#AAA A##AAA
                  // Testing for AA#AAA
                  valid := False;
                  case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                  if valid then
                  begin
                       case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[3] of '0'..'9': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  if valid then
                  begin
                       case testcall[6] of 'A'..'Z': valid := True else valid := False; end;
                  end;
                  // Testing for #A#AAA (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of '0'..'9': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[6] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  // Testing for A##AAA (if test above didn't return true)
                  if not valid then
                  begin
                       case testcall[1] of 'A'..'Z': valid := True else valid := False; end;
                       if valid then
                       begin
                            case testcall[2] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[3] of '0'..'9': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[4] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[5] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                       if valid then
                       begin
                            case testcall[6] of 'A'..'Z': valid := True else valid := False; end;
                       end;
                  end;
                  if not valid then
                  begin
                       // 6 Character callsigns can be:  AA#AAA #A#AAA A##AAA
                       prCallError := 'Must be AA#AAA or #A#AAA or A##AAA' + sLineBreak + 'Where A = Letter A to Z and # = Digit 0 to 9';
                  end
                  else
                  begin
                       prCallError := '';
                  end;
             End;
             // All possible 3, 4, 5 and 6 character length callsigns have been tested
             // for conformance to JT65 callsign encoding rules.  If valid = true we're
             // good to go.  Of course, you can still specify a callsign that is not
             // 'real', but, which conforms to the encoding rules...  I make no attempt
             // to validate a callsign to be something that is valid/legal.  Only that it
             // conforms to the encoder rules.
        end;
        if valid then
        begin
             prCallValid := true;
             prCallError := '';
        end;
   end;

   function  TValidator.evalGrid(const grid : String) : Boolean;
   var
        valid    : Boolean;
        testGrid : String;
   begin
        valid := True;
        testGrid := trimleft(trimright(grid));
        testGrid := upcase(testGrid);
        if (length(testGrid) < 4) or (length(testGrid) > 6) or (length(testGrid) = 5) then
        begin
             valid := False;
        end
        else
        begin
             valid := True;
        end;
        if valid then
        begin
             // Validate grid
             // Grid format:
             // Length = 4 or 6
             // characters 1 and 2 range of A ... R, upper case, alpha only.
             // characters 3 and 4 range of 0 ... 9, numeric only.
             // characters 5 and 6 range of a ... x, lower case, alpha only, optional.
             // Validate grid
             if length(testGrid) = 6 then
             begin
                  testGrid[1] := upcase(testGrid[1]);
                  testGrid[2] := upcase(testGrid[2]);
                  testGrid[5] := lowercase(testGrid[5]);
                  testGrid[6] := lowercase(testGrid[6]);
                  prGrid := testGrid;
                  valid := false;
                  case testGrid[1] of 'A'..'R': valid := True else valid := False; end;
                  if valid then case testGrid[2] of 'A'..'R': valid := True else valid := False; end;
                  if valid then case testGrid[3] of '0'..'9': valid := True else valid := False; end;
                  if valid then case testGrid[4] of '0'..'9': valid := True else valid := False; end;
                  if valid then case testGrid[5] of 'a'..'x': valid := True else valid := False; end;
                  if valid then case testGrid[6] of 'a'..'x': valid := True else valid := False; end;
             end
             else
             begin
                  testGrid[1] := upcase(testGrid[1]);
                  testGrid[2] := upcase(testGrid[2]);
                  prGrid := testGrid;
                  valid := false;
                  case testGrid[1] of 'A'..'R': valid := True else valid := False; end;
                  if valid then case testGrid[2] of 'A'..'R': valid := True else valid := False; end;
                  if valid then case testGrid[3] of '0'..'9': valid := True else valid := False; end;
                  if valid then case testGrid[4] of '0'..'9': valid := True else valid := False; end;
             end;
        End;
        result := valid;
   end;

   procedure TValidator.setGrid(msg : String);
   var
        valid    : Boolean;
        testGrid : String;
   begin
        valid := True;
        testGrid := trimleft(trimright(msg));
        testGrid := upcase(testGrid);
        prGrid := testGrid;
        if (length(testGrid) < 4) or (length(testGrid) > 6) or (length(testGrid) = 5) then
        begin
             if length(testGrid) < 4 then prGridError := 'Must be 4 or 6 characters';
             if length(testGrid) > 6 then prGridError := 'Must be 4 or 6 characters';
             if length(testGrid) = 5 then prGridError := 'Must be 4 or 6 characters';
             valid := False;
        end
        else
        begin
             valid := True;
             prGridError := '';
        end;
        if valid then
        begin
             // Validate grid
             // Grid format:
             // Length = 4 or 6
             // characters 1 and 2 range of A ... R, upper case, alpha only.
             // characters 3 and 4 range of 0 ... 9, numeric only.
             // characters 5 and 6 range of a ... x, lower case, alpha only, optional.
             // Validate grid
             if length(testGrid) = 6 then
             begin
                  testGrid[1] := upcase(testGrid[1]);
                  testGrid[2] := upcase(testGrid[2]);
                  testGrid[5] := lowercase(testGrid[5]);
                  testGrid[6] := lowercase(testGrid[6]);
                  prGrid := testGrid;
                  valid := false;
                  case testGrid[1] of 'A'..'R': valid := True else valid := False; end;
                  if valid then case testGrid[2] of 'A'..'R': valid := True else valid := False; end;
                  if valid then case testGrid[3] of '0'..'9': valid := True else valid := False; end;
                  if valid then case testGrid[4] of '0'..'9': valid := True else valid := False; end;
                  if valid then case testGrid[5] of 'a'..'x': valid := True else valid := False; end;
                  if valid then case testGrid[6] of 'a'..'x': valid := True else valid := False; end;
             end
             else
             begin
                  testGrid[1] := upcase(testGrid[1]);
                  testGrid[2] := upcase(testGrid[2]);
                  prGrid := testGrid;
                  valid := false;
                  case testGrid[1] of 'A'..'R': valid := True else valid := False; end;
                  if valid then case testGrid[2] of 'A'..'R': valid := True else valid := False; end;
                  if valid then case testGrid[3] of '0'..'9': valid := True else valid := False; end;
                  if valid then case testGrid[4] of '0'..'9': valid := True else valid := False; end;
             end;
             if not valid then
             begin
                  prGridError := 'Grid must be in format of RR## or RR##xx' + sLineBreak + 'Where R is letter A to R, # is digit 0 to 9 and ' + sLineBreak + 'x is letter a to x';
             end
             else
             begin
                  prGridError := '';
             end;
        End;
        if valid then
        begin
             prGridValid := True;
        end
        else
        begin
             prGridValid := False;
        end;
   end;

   function TValidator.asciiValidate(msg : Char; mode : String) : Boolean;
   Var
        tstArray1 : Array[0..41] Of String;
        tstArray2 : Array[0..35] Of String;
        tstArray3 : Array[0..36] Of String;
        tstArray4 : Array[0..11] Of String;
        tstArray5 : Array[0..10] Of String;
   begin
        tstArray1[0] := 'A';
        tstArray1[1] := 'B';
        tstArray1[2] := 'C';
        tstArray1[3] := 'D';
        tstArray1[4] := 'E';
        tstArray1[5] := 'F';
        tstArray1[6] := 'G';
        tstArray1[7] := 'H';
        tstArray1[8] := 'I';
        tstArray1[9] := 'J';
        tstArray1[10] := 'K';
        tstArray1[11] := 'L';
        tstArray1[12] := 'M';
        tstArray1[13] := 'N';
        tstArray1[14] := 'O';
        tstArray1[15] := 'P';
        tstArray1[16] := 'Q';
        tstArray1[17] := 'R';
        tstArray1[18] := 'S';
        tstArray1[19] := 'T';
        tstArray1[20] := 'U';
        tstArray1[21] := 'V';
        tstArray1[22] := 'W';
        tstArray1[23] := 'X';
        tstArray1[24] := 'Y';
        tstArray1[25] := 'Z';
        tstArray1[26] := '0';
        tstArray1[27] := '1';
        tstArray1[28] := '2';
        tstArray1[29] := '3';
        tstArray1[30] := '4';
        tstArray1[31] := '5';
        tstArray1[32] := '6';
        tstArray1[33] := '7';
        tstArray1[34] := '8';
        tstArray1[35] := '9';
        tstArray1[36] := '+';
        tstArray1[37] := '-';
        tstArray1[38] := '.';
        tstArray1[39] := '/';
        tstArray1[40] := '?';
        tstArray1[41] := ' ';

        tstArray2[0] := 'A';
        tstArray2[1] := 'B';
        tstArray2[2] := 'C';
        tstArray2[3] := 'D';
        tstArray2[4] := 'E';
        tstArray2[5] := 'F';
        tstArray2[6] := 'G';
        tstArray2[7] := 'H';
        tstArray2[8] := 'I';
        tstArray2[9] := 'J';
        tstArray2[10] := 'K';
        tstArray2[11] := 'L';
        tstArray2[12] := 'M';
        tstArray2[13] := 'N';
        tstArray2[14] := 'O';
        tstArray2[15] := 'P';
        tstArray2[16] := 'Q';
        tstArray2[17] := 'R';
        tstArray2[18] := 'S';
        tstArray2[19] := 'T';
        tstArray2[20] := 'U';
        tstArray2[21] := 'V';
        tstArray2[22] := 'W';
        tstArray2[23] := 'X';
        tstArray2[24] := 'Y';
        tstArray2[25] := 'Z';
        tstArray2[26] := '0';
        tstArray2[27] := '1';
        tstArray2[28] := '2';
        tstArray2[29] := '3';
        tstArray2[30] := '4';
        tstArray2[31] := '5';
        tstArray2[32] := '6';
        tstArray2[33] := '7';
        tstArray2[34] := '8';
        tstArray2[35] := '9';

        tstArray3[0] := 'A';
        tstArray3[1] := 'B';
        tstArray3[2] := 'C';
        tstArray3[3] := 'D';
        tstArray3[4] := 'E';
        tstArray3[5] := 'F';
        tstArray3[6] := 'G';
        tstArray3[7] := 'H';
        tstArray3[8] := 'I';
        tstArray3[9] := 'J';
        tstArray3[10] := 'K';
        tstArray3[11] := 'L';
        tstArray3[12] := 'M';
        tstArray3[13] := 'N';
        tstArray3[14] := 'O';
        tstArray3[15] := 'P';
        tstArray3[16] := 'Q';
        tstArray3[17] := 'R';
        tstArray3[18] := 'S';
        tstArray3[19] := 'T';
        tstArray3[20] := 'U';
        tstArray3[21] := 'V';
        tstArray3[22] := 'W';
        tstArray3[23] := 'X';
        tstArray3[24] := 'Y';
        tstArray3[25] := 'Z';
        tstArray3[26] := '0';
        tstArray3[27] := '1';
        tstArray3[28] := '2';
        tstArray3[29] := '3';
        tstArray3[30] := '4';
        tstArray3[31] := '5';
        tstArray3[32] := '6';
        tstArray3[33] := '7';
        tstArray3[34] := '8';
        tstArray3[35] := '9';
        tstArray3[36] := '/';

        tstArray4[0]  := '0';
        tstArray4[1]  := '1';
        tstArray4[2]  := '2';
        tstArray4[3]  := '3';
        tstArray4[4]  := '4';
        tstArray4[5]  := '5';
        tstArray4[6]  := '6';
        tstArray4[7]  := '7';
        tstArray4[8]  := '8';
        tstArray4[9]  := '9';
        tstArray4[10] := '.';
        tstArray4[11] := ',';

        tstArray5[0]  := '0';
        tstArray5[1]  := '1';
        tstArray5[2]  := '2';
        tstArray5[3]  := '3';
        tstArray5[4]  := '4';
        tstArray5[5]  := '5';
        tstArray5[6]  := '6';
        tstArray5[7]  := '7';
        tstArray5[8]  := '8';
        tstArray5[9]  := '9';
        tstArray5[10] := '-';


        if mode = 'csign' then
        begin
             If ansiIndexStr(msg,tstArray2)>-1 then result := true else result := false;
        end;
        if mode = 'gsign' then
        begin
             If ansiIndexStr(upcase(msg),tstArray2)>-1 then result := true else result := false;
        end;
        if mode = 'xcsign' then
        begin
             If ansiIndexStr(msg,tstArray3)>-1 then result := true else result := false;
        end;
        if mode = 'free' then
        begin
             If ansiIndexStr(msg,tstArray1)>-1 then result := true else result := false;
        end;
        if mode = 'numeric' then
        begin
             If ansiIndexStr(msg,tstArray4)>-1 then result := true else result := false;
        end;
        if mode = 'sig' then
        begin
             If ansiIndexStr(msg,tstArray5)>-1 then result := true else result := false;
        end;
   end;

   function TValidator.evalQRG(const qrg : String; const mode : string; var qrgk : Double; var qrghz : Integer; var asciiqrg : String) : Boolean;
   var
        i1,i2,i3 : Integer;
        wcount   : Integer;
        resolved : Boolean;
        foo, s1  : String;
        s2, sqrg : String;
        decichar : Char;
        kilochar : Char;
   begin
        // Returns an integer value in Hz for an input string that may be
        // in MHz, KHz or Hz.  Mode parameter can be lax or strict.  Float QRG
        // in KHz returns in qrgk and Integer QRG in Hz returns in qrghz if
        // valid, otherwise both will be set to 0.  If mode = strict then QRG
        // must resolve to a valid amateur band in range of 160M to 33cm
        // excluding 60M.  If lax then anything that can be converted from a
        // string to integer will do.  If mode = draconian the QRG must be within
        // +/- 5 KHz of any one of the JT65 'designated' frequencies.  This is
        // only used for the RB system as a way to cut down on mislabled spots.

        // OK, this is a nightmare.  Conversion of the string to floating point
        // representation then to integer for Hz value leads to a plethora of FP
        // rounding/imprecision errors.  Feed the routine the string 28076.04 and
        // you get the FP value 28076.0391 which is not good enough.  So.  Since
        // I know the format expected if it's KHz or MHz I must, for better or
        // worse, do a string to FP conversion of my own making.  This will be
        // less than fun.

        // Look for the following characters , . and attempt to determine if
        // I have a single , representing a decimal seperator as in some Euro
        // conventions or a , and a . indicating a thousands demarcation and a
        // decimal demarcation.
        qrgk     := 0.0;
        qrghz    := 0;
        asciiqrg := '';
        result   := False;
        resolved := false;
        foo      := '';
        sqrg     := '';
        // Will rely on defined constants for decimal and thousand markers.
        // Hopefully this will be correct for decimal point indication.
        decichar := DecimalSeparator;
        kilochar := ThousandSeparator;
        // Variables to override the system idea of deci and kilo
        if prDeciEuro Then
        Begin
             decichar := ',';
             kilochar := '.';
        end;
        if prDeciAmer Then
        Begin
             decichar := '.';
             kilochar := ',';
        end;
        // "Normalize" string qrg to a string with no thousands mark and a . decimal mark
        // based upon locale setting for those marks.

        // Remove any thousands indicators first.
        foo := StringReplace(qrg,kilochar,'',[rfReplaceAll]);

        // If decichar not . then be sure it is now.
        if not (decichar='.') then
        begin
             foo := StringReplace(foo,decichar,'.',[rfReplaceAll]);
        end;
        // Save converted string for rest of routine to use
        sqrg := foo;
        // Now I need to deal with a nice simple 14.076515 or 14076.515
        if not resolved and (ansiContainsText(sqrg,'.')) and not (ansiContainsText(sqrg,',')) then
        begin
             // Now only dealing with a string having ####.#### with . as decimal point.  Still
             // no idea if I'm seeing MHz or KHz, but will attempt to figure that out now.
             // s1 holds string to left of decimal point
             // s2 holds string to right of decimal point
             // i3 holds the conversion of string to integer for processing later
             s1 := '';
             s2 := '';
             wcount := WordCount(sqrg,['.']);
             if wcount = 2 then
             begin
                  s1 := ExtractWord(1,sqrg,['.']);
                  s2 := ExtractWord(2,sqrg,['.']);
             end
             else
             begin
                  s1 := '0';
                  s2 := '0';
             end;

             // It will most likely be a KHz value if length(s1) >= 4 with s2 being 3 or less
             if length(s1) > 3 then
             begin
                  //s1(i1) will be thousands as in 1838 for 1838000 or 7076 for 7076000
                  //s2(i2) will be 1s 10s or 100s depending upon length length=3 = 1s length = 2 = 10s length = 1 = 100s
                  if not trystrToInt(s1,i1) then i1 := 0;
                  if not trystrToInt(s2,i2) then i2 := 0;
                  i1 := i1*1000;
                  if length(s2)=3 then i2 := i2*1; // Redundant, but necessary for understanding the logic
                  if length(s2)=2 then i2 := i2*10;
                  if length(s2)=1 then i2 := i2*100;
                  i3 := i1+i2;
                  resolved := true;
             end;

             if length(s1) < 4 then
             begin
                  //This will likely be MHz in s1 and fractional MHz in s2
                  // 1.838    Would be 1 million 838 thousand
                  // 1.8381   Would be 1 million 838 thousand 100
                  // 1.83812  Would be 1 million 838 thousand 120
                  // 1.838123 Would be 1 million 838 thousand 123
                  if not trystrToInt(s1,i1) then i1 := 0;
                  if not trystrToInt(s2,i2) then i2 := 0;
                  i1 := i1*1000000;
                  if length(s2)=6 then i2 := i2*1;
                  if length(s2)=5 then i2 := i2*10;
                  if length(s2)=4 then i2 := i2*100;
                  if length(s2)=3 then i2 := i2*1000;
                  if length(s2)=2 then i2 := i2*10000;
                  if length(s2)=1 then i2 := i2*100000;
                  i3 := i2+i1;
                  resolved := true;
             end;
        end;

        // OK, now I've handled everything I can think of except the case of an
        // integer value being passed.  I would hope that if I do get a value
        // that seems to be an integer it will be Hz, but it could be KHz or Mhz
        // and I'll try to resolve that before finishing this.
        if not resolved and not (ansiContainsText(qrg,',')) and not (ansiContainsText(qrg,'.')) Then
        Begin
             // Seems to have an integer so we'll make it simple
             if trystrToInt(qrg,i3) then resolved := true else resolved := false;
        end;

        // Now... if resolved = true then i3 will hold an integer value.  Lets
        // see if it seems to make sense.
        if resolved then
        begin
             resolved := false;
             // OK... this is either a hertz value or a value in KHz or MHz.
             // If it's KHz then it needs to be 1838 to 460000.  If it's MHz
             // then I need to see 1 to 460.  Realistically I don't expect
             // to ever see MHz here, but, who knows....
             if not resolved and (i3 < 1838) then
             begin
                  // MHz
                  i3 := i3*1000000;
                  resolved := true;
             end;
             if not resolved and (i3 > 1837) and (i3 < 460000) then
             begin
                  // KHz
                  i3 := i3*1000;
                  resolved := true;
             end;
             if not resolved and (i3 > 1799999) then
             begin
                  // Hz
                  i3 := i3*1;  // Silly, but helps me keep my logic straight.
                  resolved := true;
             end;

             if (upcase(mode)='LAX') and resolved then
             begin
                  qrgk     := i3/1000;
                  qrghz    := i3;
                  asciiqrg := floatToStr(qrgk);
                  result   := true;
             end;

             if (upcase(mode)='STRICT') and resolved then
             begin
                  // In strict mode QRG must be in the following ranges
                  resolved := false;
                  if (i3 >    1799999) and (i3 <    2000001) then resolved := true;  // 160M
                  if (i3 >    3499999) and (i3 <    4000001) then resolved := true;  //  80M
                  if (i3 >    5330000) and (i3 <    5405000) then resolved := true;  //  60M
                  if (i3 >    6999999) and (i3 <    7300001) then resolved := true;  //  40M
                  if (i3 >   10099999) and (i3 <   10150001) then resolved := true;  //  30M
                  if (i3 >   13999999) and (i3 <   14350001) then resolved := true;  //  20M
                  if (i3 >   18067999) and (i3 <   18168001) then resolved := true;  //  17M
                  if (i3 >   20999999) and (i3 <   21450001) then resolved := true;  //  15M
                  if (i3 >   24889999) and (i3 <   24990001) then resolved := true;  //  12M
                  if (i3 >   27999999) and (i3 <   29700001) then resolved := true;  //  10M
                  if (i3 >   49999999) and (i3 <   54000001) then resolved := true;  //   6M
                  if (i3 >  143999999) and (i3 <  148000001) then resolved := true;  //   2M
                  if (i3 >  221999999) and (i3 <  225000001) then resolved := true;  //   1.25M
                  if (i3 >  419999999) and (i3 <  450000001) then resolved := true;  //   70cm
                  if (i3 >  901999999) and (i3 <  928000001) then resolved := true;  //   33cm
                  if (i3 > 1269999999) and (i3 < 1300000001) then resolved := true;  //   23cm
                  //if resolved then result := i3;
                  if resolved then
                  begin
                       qrgk     := i3/1000;
                       qrghz    := i3;
                       asciiqrg := floatToStr(qrgk);
                       result   := true;
                  end;
             end;

             if not resolved then
             begin
                  qrgk     := 0.0;
                  qrghz    := 0;
                  asciiqrg := '0.0';
                  result := false;
             end;
        end
        else
        begin
             qrgk     := 0.0;
             qrghz    := 0;
             asciiqrg := '0.0';
             result := false;
        end;
   end;

   function TValidator.evalIQRG(const qrg : Integer; const mode : String; var band : String) : Boolean;
   var
        valid : Boolean;
   begin
        // Validates an integer value (qrg) for being within a valid amateur band
        // from 160M to 23cm (excluding 60M).  If mode = lax then the qrg must be
        // within an amateur band.  If mode = draconian then qrg must be within +/-
        // 2 KHz of a designated JT65 QRG.
        band := '';
        valid := false;
        if (qrg >    1799999) and (qrg <    2000001) then valid := true; // 160M
        if (qrg >    3499999) and (qrg <    4000001) then valid := true; //  80M
        if (qrg >    6999999) and (qrg <    7300001) then valid := true; //  40M
        if (qrg >   10099999) and (qrg <   10150001) then valid := true; //  30M
        if (qrg >   13999999) and (qrg <   14350001) then valid := true; //  20M
        if (qrg >   18067999) and (qrg <   18168001) then valid := true; //  17M
        if (qrg >   20999999) and (qrg <   21450001) then valid := true; //  15M
        if (qrg >   24889999) and (qrg <   24990001) then valid := true; //  12M
        if (qrg >   27999999) and (qrg <   29700001) then valid := true; //  10M
        if (qrg >   49999999) and (qrg <   54000001) then valid := true; //   6M
        if (qrg >  143999999) and (qrg <  148000001) then valid := true; //   2M
        if (qrg >  221999999) and (qrg <  225000001) then valid := true; //   1.25M
        if (qrg >  419999999) and (qrg <  450000001) then valid := true; //   70cm
        if (qrg >  901999999) and (qrg <  928000001) then valid := true; //   33cm
        if (qrg > 1269999999) and (qrg < 1295000001) then valid := true; //   23cm
        if (qrg > 1239999999) and (qrg < 1300000001) then valid := true; //   23cm
        if valid then
        begin
             if (qrg >    1799999) and (qrg <    2000001) then band := '160M';
             if (qrg >    3499999) and (qrg <    4000001) then band :=  '80M';
             if (qrg >    6999999) and (qrg <    7300001) then band :=  '40M';
             if (qrg >   10099999) and (qrg <   10150001) then band :=  '30M';
             if (qrg >   13999999) and (qrg <   14350001) then band :=  '20M';
             if (qrg >   18067999) and (qrg <   18168001) then band :=  '17M';
             if (qrg >   20999999) and (qrg <   21450001) then band :=  '15M';
             if (qrg >   24889999) and (qrg <   24990001) then band :=  '12M';
             if (qrg >   27999999) and (qrg <   29700001) then band :=  '10M';
             if (qrg >   49999999) and (qrg <   54000001) then band :=   '6M';
             if (qrg >  143999999) and (qrg <  148000001) then band :=   '2M';
             if (qrg >  221999999) and (qrg <  225000001) then band := '1.25M';
             if (qrg >  419999999) and (qrg <  450000001) then band :=  '70CM';
             if (qrg >  901999999) and (qrg <  928000001) then band :=  '33CM';
             if (qrg > 1269999999) and (qrg < 1295000001) then band :=  '23CM';
             if (qrg > 1239999999) and (qrg < 1300000001) then band :=  '23CM';
             // Now to 'draconian' validation mode
             if mode = 'draconian' then
             begin
                  valid := false;
                  if (qrg >    1799999) and (qrg <    2000001) then valid := true; // For 160M I'm not setting to any particular QRG range for draconian mode
                  if (qrg >    3499999) and (qrg <    4000001) then valid := true; // For  80M I'm not setting to any particular QRG range for draconian mode
                  if (qrg >    7036999) and (qrg <    7041001) then valid := true; // For  40M I have 2 QRG Values 7039 and 7076
                  if (qrg >    7073999) and (qrg <    7078001) then valid := true; // For  40M I have 2 QRG Values 7039 and 7076
                  if (qrg >   10099999) and (qrg <   10150001) then valid := true; // For  30M I'm not setting to any particular QRG range for draconian mode
                  if (qrg >   14073999) and (qrg <   14078001) then valid := true; // For  20M I'm at 14076
                  if (qrg >   18067999) and (qrg <   18168001) then valid := true; // For  17M I'm not setting to any particular QRG range for draconian mode
                  if (qrg >   21073999) and (qrg <   21078001) then valid := true; // For  15M I'm at 21076
                  if (qrg >   24889999) and (qrg <   24990001) then valid := true; // For  12M I'm not setting to any particular QRG range for draconian mode
                  if (qrg >   28073999) and (qrg <   28078001) then valid := true; // For  10M I'm at 28076
                  if (qrg >   49999999) and (qrg <   54000001) then valid := true; // For all bands above 10M I'm not setting to any particular QRG range for draconian mode
                  if (qrg >  143999999) and (qrg <  148000001) then valid := true;
                  if (qrg >  221999999) and (qrg <  225000001) then valid := true;
                  if (qrg >  419999999) and (qrg <  450000001) then valid := true;
                  if (qrg >  901999999) and (qrg <  928000001) then valid := true;
                  if (qrg > 1269999999) and (qrg < 1295000001) then valid := true;
                  if (qrg > 1239999999) and (qrg < 1300000001) then valid := true;
             end;
        end;
        result := valid;
   end;
end.
