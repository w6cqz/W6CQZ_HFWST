unit rebel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SynaSer, Types, CTypes, StrUtils;

Type
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
                 prLoopSpeed : String;
                 prTXState   : Boolean;
           Public
                 Constructor create;
                 Destructor  destroy; override;
                 function    connect : Boolean;
                 function    ping : Boolean;
                 function    ask : Boolean;
                 //function    state : Boolean;
                 function    poll : Boolean;
                 //function    command : Boolean;
                 //function    disconnect : Boolean;

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
                 property error     : String
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
                    read  prTXState;
    end;

implementation
constructor TRebel.Create;
Var
   foo : String;
Begin
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
End;

Destructor TRebel.Destroy;
Begin
     prTTY.CloseSocket;
     prTTY.Destroy;
     prPorts.Clear;
     prPorts.Destroy;
end;

function TRebel.ask : Boolean;
Var
   foo : String;
   i   : Integer;
Begin
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
end;

function TRebel.poll : Boolean;
Var
   foo : String;
   ff  : Double;
   i,j : Integer;
Begin
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
          if ff>0 Then prQRG := (ff + 9000000.0)-prRXOffset;
     end;

     prCommand := '15;';  // Returns Loop speed as string
     prResponse := '';
     if ask Then
     Begin
          i := wordcount(prResponse,[',',';']);
          if i > 1 Then prLoopSpeed := ExtractWord(2,prResponse,[',',';']) else prLoopSpeed := '';
     end;

     //prLocked    := False;
     //prTXState   := False;
end;

function TRebel.Connect : Boolean;
Var
   foo : String;
   i   : Integer;
Begin
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
end;

Function TRebel.ping : Boolean;
Var
     foo : String;
     i   : Integer;
Begin
     result := False;
     // Need to wait for the sign in message
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
end;

end.

