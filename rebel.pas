// (c) 2013 CQZ Electronics
unit rebel;
{
Note 1:  TX tuning words array is 128 instead of 126 due to my method of clocking in
4 tuning words per round.  The last 2 values will be ignored on Rebel side, but, should
be set to 0 to be safe.
}
{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils, SynaSer, Types, CTypes, StrUtils;

Type

    { TRebel }

    TRebel = Class
           Private
                 prPort      : String;
                 prBaud      : Integer;
                 prConnected : Boolean;
                 prCommand   : String;
                 prResponse  : String;
                 prError     : String;
                 prTTY       : SynaSer.TBlockSerial;
                 prPorts     : TStringList;
                 prQRG       : Double;
                 prBand      : CTypes.cint;
                 prRXOffset  : CTypes.cint;
                 prTXOffset  : CTypes.cint;
                 prDDSRef    : CTypes.cint;
                 prRebVer    : String;
                 prDDSVer    : String;
                 prLocked    : Boolean;
                 prBusy      : Boolean;
                 prLoopSpeed : String;
                 prTXState   : Boolean; // True = TX on False = TX off
                 prTXArray   : Array[0..127] Of CTypes.cuint; // Holds the 126 tuning words needed to TX a JT65 frame [See note 1 why it's 128]
                 prDebug     : String;
                 function    ddsWord(const hz : double; const offset : CTypes.cint; const ref : CTypes.cint) : CTypes.cuint32;

           Public
                 Constructor create;
                 Destructor  destroy; override;
                 function    connect    : Boolean;
                 function    disconnect : Boolean;
                 function    setup      : Boolean;
                 function    ask        : Boolean;
                 function    setQRG     : Boolean;
                 function    poll       : Boolean;
                 function    pttOn      : Boolean;
                 function    pttOff     : Boolean;
                 function    ltx        : Boolean; // Loads array into rebel for TX
                 function    setOffsets : Boolean;
                 function    getData(Index: Integer): CTypes.cuint;
                 procedure   setData(Index: Integer; AValue: CTypes.cuint);
                 function    dumptx     : String;

                 property port      : String
                    read  prPort
                    write prPort;
                 property baud      : Integer
                    read  prBaud
                    write prBaud;
                 property connected : Boolean
                    read  prConnected;
                 property command   : String
                    read  prCommand
                    write prCommand;
                 property response  : String
                    read  prResponse
                    write prResponse;
                 property lerror    : String
                    read  prError;
                 property ports     : TStringList
                    read  prPorts;
                 property qrg       : Double
                    read  prQRG
                    write prQRG;
                 property band      : CTypes.cint
                    read  prBand;
                 property rxoffset  : CTypes.cint
                    read  prRXOffset
                    write prRXOffset;
                 property txOffset  : CTypes.cint
                    read  prTXOffset
                    write prTXOffset;
                 property ddsRef    : CTypes.cint
                    read  prDDSRef;
                 property rebVer    : String
                    read  prRebVer;
                 property ddsVer    : String
                    read  prDDSVer;
                 property locked    : Boolean
                    read  prLocked
                    write prLocked;
                 property loops     : String
                    read  prLoopSpeed;
                 property txStat    : Boolean
                    read  prTXState; // True = PTT on False = PTT off
                 property txArray [Index: Integer]: CTypes.cuint
                    read  getData
                    write setData;
                 property busy      : Boolean
                    read  prBusy;
                 property debug     : String
                    read  prDebug;
    end;

implementation
constructor TRebel.Create;
Var
   foo : String;
   i   : Integer;
Begin
     prBusy := True;
     prTTY := SynaSer.TBlockSerial.Create;
     foo := '';
     foo := synaser.GetSerialPortNames;
     prPorts := TStringList.Create;
     prPorts.Clear;
     prPorts.CaseSensitive := False;
     prPorts.Sorted := False;
     prPorts.Duplicates := Types.dupIgnore;
     if length(foo)>0 Then prPorts.CommaText := foo;
     prPort      := 'None';
     prBaud      := 115200;
     prConnected := False;
     prCommand   := '';
     prResponse  := '';
     prError     := '';
     prQRG       := 0.0;
     prBand      := 0;
     prRXOffset  := 0;
     prTXOffset  := 0;
     prDDSRef    := 0;
     prRebVer    := '';
     prDDSVer    := '';
     prLocked    := False;
     prLoopSpeed := '';
     prTXState   := False;
     for i := 0 to 63 do prTXArray[i] := 0;
     prBusy := False;
End;

Destructor TRebel.Destroy;
Begin
     prTTY.CloseSocket;
     prTTY.Destroy;
     prPorts.Clear;
     prPorts.Destroy;
end;

function TRebel.disconnect : Boolean;
Begin
     prBusy := True;
     prConnected := False;
     if prTXState Then pttOff;
     prTTY.CloseSocket;
     result := True;
     prBusy := False;
end;

function TRebel.ddsWord(const hz : double; const offset : CTypes.cint; const ref : CTypes.cint) : CTypes.cuint32;
Begin
     // Calculate DDS tuning word from hz, offset and ref based upon formula for prDDSVer
     // Current prDDSVer is only AD9834 and it uses fWord as integer = fout * 2^28/fref
     // 14076000
     // 14076000 + 718 * (2^28/49999750) = 14076718 * 5.3687359636798183990919954599773 = 75574182.177179045895229476147381 = 75574182
     result := Round((hz+offset) * (268435456/ref));
end;

function TRebel.ltx : Boolean;
var
   foo,f2: String;
   i,j   : Integer;
Begin
     prBusy := True;
     // Need to do the FSK tuning word uploader here
     // Ok - this is the most critical and complex part of this entire mess.
     // I need to get 64 tuning words from ptTXArray into the Rebel.  First
     // I need to get a go ahead to start the upload then clock the values in
     // 4 at a time with an ack between each push.
     prCommand := '5;';  // Request to upload FSK Words  I need to get back 1,5; as response.  0,5; means Rebel can't do this now.
     prResponse := '';
     if ask Then
     Begin
          if prResponse = '1,5;' Then
          Begin
               // Lets be double sure and send command 21 to clear any data already uploaded.
               prCommand := '21;';
               prResponse := '';
               if ask and (prResponse = '1,21;') Then
               Begin
                    // Have go ahead to start upload
                    // Command ID=20,Block {1..32},I1,I2,I3,I4;
                    prDebug := '';
                    foo := '0,FSK VALUES FOLLOW,';
                    for j := 0 to 126 do foo := foo + IntToStr(prTXArray[j]) + ',';
                    prDebug := foo + IntToStr(prTXArray[127]);
                    j := 0;
                    for i := 1 to 32 do
                    begin
                         foo := '20,'+IntToStr(i)+','+IntToStr(prTXArray[j])+','+IntToStr(prTXArray[j+1])+','+IntToStr(prTXArray[j+2])+','+IntToStr(prTXArray[j+3])+';';
                         prCommand := foo;
                         prResponse := '';
                         if ask Then
                         Begin
                              If prResponse = foo Then
                              Begin
                                   // This indicates the block was accepted and matches what I expect it to be.
                                   f2 := prResponse;
                                   j := j+4;
                              end
                              else
                              begin
                                   // Bad news :(
                                   f2 := prResponse;
                                   break;
                              end;
                         end
                         else
                         begin
                              f2 := prResponse;
                              prError := 'Upload block fails ack';
                              result := false;
                              break;
                         end;
                    end;
                    if i<32 Then
                    Begin
                         prError := 'Bad upload';
                         result := False;
                    end
                    else
                    begin
                         prError := '';
                         result := True;
                    end;
               end
               else
               begin
                    prError := 'Clear fails';
                    result := False;
               end;
          end
          else
          begin
               // Rebel can't deal with this now.
               prError := 'Rebel refuses upload';
               result := False;
          end;
     end
     else
     begin
          // Rebel can't deal with this now.
          prError := 'Command timeout';
          result := False;
     end;
     prBusy := False;
end;

function TRebel.setOffsets: Boolean;
begin
     prBusy := True;
     prError := '';
     // Need to set RX and TX offsets
     // 16,INTEGER; = Set RX Offset
     prCommand := '16,' + IntToStr(prRXOffset) + ';';  // RX Offset
     prResponse := '';
     if ask Then
     Begin
          if prResponse='1,' + IntToStr(prRXOffset) + ';' Then
          Begin
               result := True;
          end
          else
          Begin
               Result := False;
               prError := 'RX Offset fails';
          end;
     end
     else
     begin
          prTXState := False;
          result := False;
          prError := 'Command timeout RX Offset';
     end;

     prCommand := '17,' + IntToStr(prTXOffset) + ';';  // TX Offset
     prResponse := '';
     if ask Then
     Begin
          if prResponse='1,' + IntToStr(prTXOffset) + ';' Then
          Begin
               result := True;
          end
          else
          Begin
               Result := False;
               if Length(prError)>0 Then prError := ' TX Offset fails' else prError :='TX Offset fails';
          end;
     end
     else
     begin
          prTXState := False;
          result := False;
          prError := 'Command timeout TX Offset';
     end;
     prBusy := False;
end;

function TRebel.getData(Index: Integer): CTypes.cuint;
begin
     result := prTXArray[Index];
end;

procedure TRebel.setData(Index: Integer; AValue: CTypes.cuint);
begin
     prTXArray[Index] := AValue;
end;

function TRebel.dumptx: String;
Var
   foo : String;
   i   : Integer;
begin
     prBusy := True;
     // Reading back FSK Values from the actual stored in array values
     // 22; = Read FSK Array
     prCommand := '22;';  // TX ON
     prResponse := '';
     if ask Then
     Begin
          foo := prResponse;
          result := foo;
     end
     else
     begin
          prError := 'FSK Readback fault';
          result := 'Big fat E R R O R';
     end;
     prBusy := False;
end;

function TRebel.pttOn : Boolean;
Var
   foo : String;
   i   : Integer;
Begin
     prBusy := True;
     // Need to turn it ON
     // 10; = ON
     prCommand := '10;';  // TX ON
     prResponse := '';
     if ask Then
     Begin
          foo := prResponse;
          if prResponse='1,10;' Then
          Begin
               prTXState := True;
               result := True;
          end
          else
          Begin
               prTXState := False;
               Result := False;
               prError := 'Rebel refuses command';
          end;
     end
     else
     begin
          prTXState := False;
          result := False;
          prError := 'Command timeout';
     end;
     prBusy := False;
end;

function TRebel.pttOff : Boolean;
Var
   foo : String;
   i   : Integer;
Begin
     prBusy := True;
     // Need to turn it OFF
     // 11; = OFF
     prCommand := '11;';  // TX OFF
     prResponse := '';
     if ask Then
     Begin
          if prResponse='1,11;' Then
          Begin
               prTXState := False;
               result := True;
          end
          else
          Begin
               prTXState := True;
               Result := False;
               prError := 'Rebel refuses command';
          end;
     end
     else
     begin
          prTXState := False;
          result := False;
          prError := 'Command timeout';
     end;
     prBusy := False;
end;

function TRebel.setQRG : Boolean;
var
   foo : String;
   t   : double;
   i   : Integer;
Begin
     prBusy := True;
     // Sends set RX command with DDS tuning word as value
     // Take into account if band is 20M the DDS word is desired (RX + offset) - IF
     // WARNING WARNING WARNING WARNING and MORE WARNING
     //
     if prBand = 20 then t := prQRG-9000000.0;
     prCommand := '3,' + IntToStr(ddsWord(t,prRXOffset+prTXOffset,prDDSRef)) + ';';  // Sets RX frequency
     prResponse := '';
     if ask Then
     Begin
          i := wordcount(prResponse,[',',';']);
          if i > 1 Then foo := ExtractWord(2,prResponse,[',',';']) else foo := '-1';
          // Response sends back the tuning word and it should be = to what we calculated :)
          if IntToStr(ddsWord(t,prRXOffset+prTXOffset,prDDSRef)) = foo Then
          Begin
               result := True;
               prError := '';
               poll;
          end
          else
          begin
               result := False;
               prError := 'Rebel word != calculated word';
          end;
     end
     else
     begin
          result := False;
          prError := 'Command timeout';
     end;
     prBusy := False;
end;

function TRebel.ask : Boolean;
Var
   foo : String;
   i   : Integer;
Begin
     prBusy := True;
     if prConnected Then
     Begin
          if length(prCommand)>1 Then
          Begin
               prResponse := '';
               prError := '';
               result := False;
               prTTY.SendString(prCommand);
               foo := '';
               for i := 0 to 9 do
               begin
                    foo := prTTY.Recvstring(50);
                    if length(foo)>1 Then break;
               end;
               if length(foo)>1 Then
               Begin
                    prResponse := foo;
                    prError := '';
                    result := True;
               end
               else
               begin
                    prResponse := '';
                    prError := 'Timeout';
                    result := False;
               end;
          end
          else
          begin
               prResponse := '';
               prError := 'Bad command';
               result := False;
          end;
     end
     else
     begin
          prResponse := '';
          prError := 'Not connected';
          result := False;
     end;
     prBusy := False;
end;

function TRebel.poll : Boolean;
Var
   foo : String;
   ff  : Double;
   i,j : Integer;
Begin
     prBusy := True;
     // Poll for various values
     prCommand := '6;';  // Returns Rebel Version
     prResponse := '';
     if ask Then
     Begin
          i := wordcount(prResponse,[',',';']);
          if i > 1 Then prRebVer := ExtractWord(2,prResponse,[',',';']) else prRebVer := '';
     end;

     prCommand := '8;'; // Returns DDS Type
     prResponse := '';
     if ask Then
     Begin
          i := wordcount(prResponse,[',',';']);
          if i > 1 Then prDDSVer := ExtractWord(2,prResponse,[',',';']) else prDDSVer := '';
     end;
     prCommand := '7;'; // Returns Integer DDS Reference QRG (as string)
     prResponse := '';
     if ask Then
     Begin
          i := wordcount(prResponse,[',',';']);
          if i > 1 Then if tryStrToInt(ExtractWord(2,prResponse,[',',';']),i) then prDDSRef := i else prDDSRef := 0;
     end;

     prCommand := '18;'; // Returns Integer RX Frequency offset (as string)
     prResponse := '';
     if ask Then
     Begin
          i := wordcount(prResponse,[',',';']);
          if i > 1 Then if tryStrToInt(ExtractWord(2,prResponse,[',',';']),i) then prRXOffset := i else prRXOffset := 0;
     end;

     prCommand := '19;'; // Returns Integer TX Frequency offset (as string)
     prResponse := '';
     if ask Then
     Begin
          i := wordcount(prResponse,[',',';']);
          if i > 1 Then if tryStrToInt(ExtractWord(2,prResponse,[',',';']),i) then prTXOffset := i else prTXOffset := 0;
     end;

     prCommand := '4;'; // Returns Integer Band hard selected (as string)
     prResponse := '';
     if ask Then
     Begin
          i := wordcount(prResponse,[',',';']);
          if i > 1 Then if tryStrToInt(ExtractWord(2,prResponse,[',',';']),i) then prBand := i else prTXOffset := 0;
     end;

     prCommand := '2;';  // Returns DDS RX Tuning word as 1,#####;
     prResponse := '';
     if ask Then
     Begin
          i := wordcount(prResponse,[',',';']);
          if i > 1 Then if tryStrToInt(ExtractWord(2,prResponse,[',',';']),i) then j := i else j := 0;
          if (j>0) and (prDDSRef>0) then ff := j/(268435456.0/prDDSRef) else ff := 0.0;
          if ff>0 Then prQRG := (ff + 9000000.0)-(prRXOffset+prTXOffset);
     end;

     prCommand := '15;';  // Returns Loop speed as string
     prResponse := '';
     if ask Then
     Begin
          i := wordcount(prResponse,[',',';']);
          if i > 1 Then prLoopSpeed := ExtractWord(2,prResponse,[',',';']) else prLoopSpeed := '';
     end;
     result := True;
     prBusy := False;
end;

function TRebel.Connect : Boolean;
Var
   foo : String;
   i   : Integer;
Begin
     prBusy := True;
     prConnected := false;
     prError := '';
     result := false;
     if length(prPort) > 3 Then
     Begin
          if UpCase(prPort[1..3])='COM' Then
          Begin
               foo := prPort[4..Length(prPort)];
               i := -1;
               if TryStrToInt(foo,i) Then
               Begin
                    if (i>0) and (i<256) Then
                    Begin
                         if (prBaud=9600) or (prBaud=115200) Then
                         Begin
                              // Have a good value for port and baud - lets open it.
                              try
                                 prTTY.Connect(prPort);
                                 if prTTY.InstanceActive Then
                                 Begin
                                      prTTY.Config(prBaud,8,'N',synaser.SB1,False,False);
                                      prConnected := True;
                                      result := True;
                                 end
                                 else
                                 begin
                                      prError := 'Open of COM' + prPort + ' fails';
                                      prConnected := false;
                                      result := False;
                                 end;
                              except
                                 prError := 'Open of COM' + prPort + ' fails';
                                 prConnected := false;
                                 result := False;
                              end;
                         end
                         else
                         begin
                              prError := 'Bad Baud Rate';
                              result  := False;
                              prConnected := False;
                         end;
                    end
                    else
                    begin
                         prError := 'Bad Port';
                         result  := False;
                         prConnected := False;
                    end;
               end
               else
               begin
                    prError := 'Bad Port';
                    result  := False;
                    prConnected := False;
               end;
          end
          else
          begin
               prError := 'Bad Port';
               result  := False;
               prConnected := False;
          end;
     end
     else
     begin
          prError := 'Bad Port';
          result  := False;
          prConnected := False;
     end;
     prBusy := False;
end;

Function TRebel.setup : Boolean;
Var
     foo : String;
     i   : Integer;
Begin
     prBusy := True;
     result := False;
     // Need to wait for the sign in message - This WILL change from '1,Rebel Command Ready;'
     if prConnected Then
     Begin
          i := 0;
          foo := '';
          while i < 100 do
          begin
               foo := prTTY.Recvstring(50);
               if length(foo)>0 Then break;
          end;
          if foo = '1,Rebel Command Ready;' Then
          Begin
               result := True;
               prError := '';
          end
          else
          begin
               result := False;
               prError := 'Bad response';
          end;
     end
     else
     begin
          result := False;
          prError := 'Not connected';
     end;
     prBusy := False;
end;

end.

