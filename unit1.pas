{ TODO :
Work out handlers for working JT65V2 types.  Also need to think about case of where a data item could be
sent either in V1 or V2 format.  I think... I want to force the issue here and just use V2 for everything.
It's the only way to insure more update from ancient versions.

Fix reversed prefix/suffix in decoder
Any change to message, dial QRG or TXDF must regenerate the TX Message Data
Work out using single entry box for free text and generated message content
Look into issue with loss of net leading to program hang on exit if RB on - timeout too long on attempt to http is likely problem
Begin to graft sound output code in
Add logging code
Add macro edit/define
Add qrg edit/define
Add worked call tracking taking into consideration a call worked in one grid is not
worked if in a new one.
}

{
Hook decoder output back to double click actions - In progress, needs ***much*** testing.
Add serial communications routines for next phase
Validate validate validate message input, callsigns, grids, QRGs etc. - In progress - weak and needs testing.
Fill in RB call from Station call if user does not manually set. - Done.  Computes RB call from real pfx, call, sfx if nothing manually set.

Monitor situation with decodes sometimes being dropped or decoder indicating
a hit with no data returned... the main problem is corrected and it's likely
that will fix the other as well.

Tweak UI for small screen size ability [mostly complete - just needs minor
adjustments and font size testing]
}
// (c) 2013 CQZ Electronics
unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Math, StrUtils, CTypes, Windows, lconvencoding, ComCtrls, EditBtn,
  DbCtrls, TAGraph, TASeries, TAChartUtils, Types, Process, portaudio,
  globalData, adc, spectrum, waterfall1, spot, demodulate, db, BufDataset,
  sqlite3conn, sqldb, valobject, synaser;

Const
  JT_DLL = 'JT65v5.dll';

type

  exch  = Record
      utc  : String;
      sync : String;
      db   : String;
      dt   : String;
      df   : String;
      ec   : String;
      nc1  : String;
      nc1s : String;
      nc2  : String;
      ng   : String;
  end;

  alog = Record
      timeOn     : String;
      timeOff    : String;
      aCall      : String;
      sigtx      : String;
      sigrx      : String;
      qrg        : String;
      plvl       : String;
      comment    : String;
      haveMySig  : Boolean;
      allNew     : Boolean;
      inProgress : Boolean;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    b73: TButton;
    b73x: TButton;
    bACQ: TButton;
    bCQ: TButton;
    bDE: TButton;
    bQRZ: TButton;
    bReport: TButton;
    bRReport: TButton;
    bRRR: TButton;
    Button1: TButton;
    comboTTYPorts: TComboBox;
    Label12: TLabel;
    Memo3: TMemo;
    rbTXOff: TRadioButton;
    txControl: TButton;
    Button10: TButton;
    Button11: TButton;
    LogQSO: TButton;
    cbMultiOn: TCheckBox;
    cbTXEqRXDF: TCheckBox;
    cbUseSerial: TCheckBox;
    cbAttenuateRight: TCheckBox;
    cbSpecSmooth: TCheckBox;
    cbUseMono: TCheckBox;
    cbUseColor: TCheckBox;
    cbDivideDecodes: TCheckBox;
    cbCompactDivides: TCheckBox;
    cbSaveToCSV: TCheckBox;
    cbNoOptFFT: TCheckBox;
    cbAttenuateLeft: TCheckBox;
    cbUseTXWD: TCheckBox;
    cbRememberComments: TCheckBox;
    cbMultiOffQSO: TCheckBox;
    cbRestoreMulti: TCheckBox;
    cbHaltTXMultiOn: TCheckBox;
    cbDefaultsMultiOn: TCheckBox;
    cbNoKV: TCheckBox;
    comboMacroList: TComboBox;
    edRXDF: TEdit;
    edTXDF: TEdit;
    edTXMsg: TEdit;
    edTXReport: TEdit;
    edTXtoCall: TEdit;
    Label10: TLabel;
    Label11: TLabel;
    Label123: TLabel;
    Label19: TLabel;
    Label26: TLabel;
    Label5: TLabel;
    Label79: TLabel;
    Label87: TLabel;
    Label9: TLabel;
    Label92: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    Panel1: TPanel;
    RadioButton1: TRadioButton;
    rbTXEven: TRadioButton;
    rbTXOdd: TRadioButton;
    RadioButton4: TRadioButton;
    RadioButton5: TRadioButton;
    RadioButton6: TRadioButton;
    RadioButton7: TRadioButton;
    RadioButton8: TRadioButton;
    RadioButton9: TRadioButton;
    RadioGroup2: TRadioGroup;
    RadioGroup3: TRadioGroup;
    rigRebel: TRadioButton;
    lastQRG: TEdit;
    tbMultiBin: TTrackBar;
    tbSingleBin: TTrackBar;
    txLevel: TEdit;
    version: TEdit;
    comboQRGList: TComboBox;
    GroupBox16: TGroupBox;
    Label107: TLabel;
    Label108: TLabel;
    Label109: TLabel;
    Label110: TLabel;
    Label111: TLabel;
    Label112: TLabel;
    Label113: TLabel;
    Label114: TLabel;
    Label115: TLabel;
    Label116: TLabel;
    Label117: TLabel;
    Label121: TLabel;
    Label122: TLabel;
    Label24: TLabel;
    Label78: TLabel;
    Label80: TLabel;
    Label81: TLabel;
    Label82: TLabel;
    Label83: TLabel;
    Label84: TLabel;
    Label85: TLabel;
    Label86: TLabel;
    Label93: TLabel;
    Label94: TLabel;
    Label95: TLabel;
    Label96: TLabel;
    Label97: TLabel;
    Label98: TLabel;
    logPower: TEdit;
    Label106: TLabel;
    logComments: TEdit;
    Label105: TLabel;
    logTimeOn: TEdit;
    logTimeOff: TEdit;
    Label100: TLabel;
    Label101: TLabel;
    Label102: TLabel;
    Label103: TLabel;
    Label104: TLabel;
    Label99: TLabel;
    logMySig: TEdit;
    logQRG: TEdit;
    logSigReport: TEdit;
    logCallsign: TEdit;
    groupLogQSO: TGroupBox;
    Label90: TLabel;
    Label91: TLabel;
    btnsetQRG: TButton;
    Button2: TButton;
    buttonConfig: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    updateConfig: TButton;
    Chart1: TChart;
    edDialQRG: TEdit;
    edGrid: TEdit;
    edADIFMode: TEdit;
    editQRG: TEdit;
    edRBCall: TEdit;
    edStationInfo: TEdit;
    edTXWD: TEdit;
    edPort: TEdit;
    edPrefix: TEdit;
    edCall: TEdit;
    edSuffix: TEdit;
    Label73: TLabel;
    Label76: TLabel;
    Label77: TLabel;
    Label88: TLabel;
    Label89: TLabel;
    rbUseLeftAudio: TRadioButton;
    rbUseRightAudio: TRadioButton;
    sqlite3: TSQLite3Connection;
    query: TSQLQuery;
    transaction: TSQLTransaction;
    TabSheet10: TTabSheet;
    TabSheet9: TTabSheet;
    GroupBox17: TGroupBox;
    GroupBox18: TGroupBox;
    Label44: TLabel;
    rbOn: TCheckBox;
    comboAudioIn: TComboBox;
    cbCQCOlor: TComboBox;
    cbMyCallColor: TComboBox;
    cbQSOColor: TComboBox;
    spColorMap: TComboBox;
    edCSVPath: TDirectoryEdit;
    edADIFPath: TDirectoryEdit;
    edCWID: TEdit;
    GroupBox1: TGroupBox;
    GroupBox10: TGroupBox;
    GroupBox11: TGroupBox;
    GroupBox12: TGroupBox;
    GroupBox13: TGroupBox;
    GroupBox14: TGroupBox;
    GroupBox15: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    GroupBox8: TGroupBox;
    GroupBox9: TGroupBox;
    Label1: TLabel;
    Label13: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label23: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label3: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label38: TLabel;
    Label39: TLabel;
    Label4: TLabel;
    Label40: TLabel;
    Label41: TLabel;
    Label42: TLabel;
    Label43: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    ListBox1: TListBox;
    ListBox2: TListBox;
    ListBox3: TListBox;
    PageControl: TPageControl;
    rigNone: TRadioButton;
    rbNoCWID: TRadioButton;
    rbCWID73: TRadioButton;
    rbCWIDFree: TRadioButton;
    useDeciAmerican: TRadioButton;
    useDeciEuro: TRadioButton;
    useDeciAuto: TRadioButton;
    dgainL0: TRadioButton;
    dgainL3: TRadioButton;
    dgainL6: TRadioButton;
    dgainL9: TRadioButton;
    dgainR0: TRadioButton;
    dgainR3: TRadioButton;
    dgainR6: TRadioButton;
    dgainR9: TRadioButton;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;
    TabSheet8: TTabSheet;
    Timer1: TTimer;
    tbTXLevel: TTrackBar;
    FBar1: TBarSeries;
    tbWFSpeed: TTrackBar;
    tbWFContrast: TTrackBar;
    tbWFBright: TTrackBar;
    tbWFGain: TTrackBar;
    Waterfall1: TWaterfallControl1;
    xDBText1: TDBText; { TODO : Understand why I can't remove this as if removed breaks a dep - MUST FIND - DEBUG }
    procedure audioChange(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button14Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure cbSpecSmoothChange(Sender: TObject);
    procedure comboQRGListChange(Sender: TObject);
    procedure comboMacroListChange(Sender: TObject);
    procedure btnsetQRGClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure buttonConfigClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure comboTTYPortsChange(Sender: TObject);
    procedure edRXDFChange(Sender: TObject);
    procedure edRXDFDblClick(Sender: TObject);
    procedure edTXDFDblClick(Sender: TObject);
    procedure edTXReportDblClick(Sender: TObject);
    procedure edTXtoCallDblClick(Sender: TObject);
    procedure LogQSOClick(Sender: TObject);
    procedure Memo1DblClick(Sender: TObject);
    procedure Memo2DblClick(Sender: TObject);
    procedure Memo3DblClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure qrgdbAfterPost(DataSet: TDataSet);
    procedure edTXMsgDblClick(Sender: TObject);
    procedure ListBox1DrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
    procedure mgenClick(Sender: TObject);
    procedure rbOnChange(Sender: TObject);
    procedure txControlClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure ListBox2DblClick(Sender: TObject);
    procedure rbTXEvenChange(Sender: TObject);
    procedure rigControlSet(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure tbTXLevelChange(Sender: TObject);
    procedure tbMultiBinChange(Sender: TObject);
    procedure tbSingleBinChange(Sender: TObject);

    function  gCall(const Call : String) : LongWord;
    function  gPrefix(const form : String; const pfx : String) : LongWord;
    function  gSuffix(const form : String; const sfx : String) : LongWord;

    Procedure gGrid(const Grid : String; var v1ng : LongWord);
    function  gText(const msg: String; var nc1 : LongWord; var nc2 : LongWord; var ng : LongWord) : Boolean;
    function  gSyms(const nc1 : LongWord; const nc2 : LongWord; const ng : LongWord; var   syms : Array Of Integer) : Boolean;

    function  isDigit(c : Char) : Boolean;
    function  isLetter(c : Char) : Boolean;
    function  isGLLetter(c : Char) : Boolean;
    function  isCallsign(c : String) : Boolean;
    function  isGrid(c : String) : Boolean;
    function  isControl(c : String) : Boolean;
    function  isSText(c : String) : Boolean;
    function  isFText(c : String) : Boolean;
    function  getLocalGrid : String;
    function  messageParser(const ex : String; var nc1t : String; var pfx : String; var sfx : String; var nc2t : String; var ng : String; var sh : String) : Boolean;
    procedure decomposeDecode(const exchange    : String;
                              const connectedTo : String;
                              var isValid       : Boolean;
                              var isBreakIn     : Boolean;
                              var level         : Integer;
                              var response      : String;
                              var connectTo     : String;
                              var fullCall      : String;
                              var hisGrid       : String);
    procedure breakOutFields(const msg : String; var mvalid : Boolean);
    procedure displayDecodes;

    function  db(x : CTypes.cfloat) : CTypes.cfloat;
    function  utcTime: TSystemTime;
    procedure InitBar;

    //procedure genTX(const msg : String; const txdf : Integer; const plevel : Integer; var samples : Array of CTypes.cint16);
    procedure genTX(const msg : String; const txdf : Integer; const plevel : Integer);
    //procedure earlySync(Const samps : Array Of CTypes.cint16; Const endpoint : Integer);

    procedure removeDupes(var list : TStringList; var removes : Array of Integer);

    procedure OncePerRuntime;
    procedure OncePerTick;
    procedure OncePerSecond;
    procedure OncePerMinute;
    procedure periodicSpecial;
    procedure adcdacTick;

    function  asBand(const qrg : Integer) : Integer;

    procedure setG;

    procedure updateDB;
    procedure setDefaults;
    procedure setupDB(const cfgPath : String);
    //procedure mgen(const msg : String; var isValid : Boolean; var isBreakIn : Boolean; var level : Integer; var response : String; var connectTo : String; var fullCall : String; var hisGrid : String);
    //procedure mgen(const msg : String; var isValid : Boolean; var isBreakIn : Boolean; var level : Integer; var response : String; var connectTo : String; var fullCall : String; var hisGrid : String; var sdf : String; var sdB : String);
    procedure mgen(const msg : String; var isValid : Boolean; var isBreakIn : Boolean; var level : Integer; var response : String; var connectTo : String; var fullCall : String; var hisGrid : String; var sdf : String; var sdB : String; var txp : Integer);

    function rebelCommand(const cmd : String; const value : String; const ltx : Array of String; var error : String) : Boolean;
    function t(const s : String) : String;

  private
    { private declarations }
  public
    { public declarations }
  end;

Type
  decodeThread = class(TThread)
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
  end;

  rbcThread = class(TThread)
    protected
          procedure Execute; override;
    public
          Constructor Create(CreateSuspended : boolean);
  end;

  catThread = class(TThread)
    protected
          procedure Execute; override;
    public
          Constructor Create(CreateSuspended : boolean);
  end;

var
  Form1          : TForm1;
  firstPass      : Boolean;
  firstTick      : Boolean;
  inSync         : Boolean;
  newMinute      : Boolean;
  newSecond      : Boolean;
  paActive       : Boolean;
  txOn           : Boolean;
  thisUTC        : TSystemTime;
  thisSecond     : WORD;
  lastSecond     : WORD;
  thisTS         : String;
  thisADCTick    : CTypes.cuint;
  lastADCTick    : CTypes.cuint;
  paInParams     : TPaStreamParameters;
//  paOutParams    : TPaStreamParameters;
  ppaInParams    : PPaStreamParameters;
//  ppaOutParams   : PPaStreamParameters;
  paInStream     : PPaStream;
  adcSpecAvg1    : Integer;
  adcSpecAvg2    : Integer;
  firstAU1       : Boolean;
  firstAU2       : Boolean;
  inDev          : Integer;//,outDev   : Integer;
  inIcal,pttDev  : Integer;
  gtxlevel       : CTypes.cint;
  auLevel        : Integer;
  auLevel1       : Integer;
  auLevel2       : Integer;
  flipflop       : Integer;
  thisTXcall     : String;
  thisTXgrid     : String;
  thisTXmsg      : String;
  thisTXdf       : Integer;
  rb             : spot.TSpot;
  mval           : valobject.TValidator;
  rbping         : Boolean;
  rbposted       : CTypes.cuint64;
  doDecode       : Boolean;
  doCAT          : Boolean;
  catcommand     : String;
  decodeping     : CTypes.cuint64;
  decoderBusy    : Boolean;
  rbThread       : rbcThread;
  decoderThread  : decodeThread;
  rigThread      : catThread;
  srun,lrun      : Double;
  defI           : Integer;//,defO      : Integer;
  qrgValid       : Boolean;
  forceCAT       : Boolean;
  catmethod      : String;
  catQRG         : Integer;
  catFree        : Boolean;
  dChar,kChar    : Char;
  kvcount        : CTypes.cuint64;
  bmcount        : CTypes.cuint64;
  v1c,v2c        : CTypes.cuint64;
  msc,mfc        : CTypes.cuint64;
  pfails         : CTypes.cuint64;
  avgdt          : Double;
  inQSOWith      : String;
  newLog         : Boolean;
  logEntry       : alog;
  stime,etime    : String;
  setQRG,readQRG : Boolean;
  sopQRG,eopQRG  : Integer;
  qsyQRG         : Integer;
  readPTT,setPTT : Boolean;
  pttState       : Boolean;
  cfgDir         : String;
  catError       : TStringList;
  savedTADC      : String;
  savedIADC      : Integer;
  txperiod       : Integer; // 1 = Odd 0 = Even
  canTX          : Boolean; // Only true if callsign and grid is ok
  txDirty        : Boolean; // TX Message content has not been queued since generation if true
  couldTX        : Boolean; // If one could TX this period (it matches even/odd selection)
  txrequested    : Boolean; // Is a request to TX in place?
  haveRebel      : Boolean; // Rebel selected and active/present?
  tmpdir         : String; // Path to user's temporary files directory
  homedir        : String; // Path to user's home directory
  tty            : TBlockSerial;
  ttyPorts       : TStringList;
  qrgset         : Array[0..63] Of String; // Holds QRG values for Rebel TX load

implementation

procedure rscode(Psyms : CTypes.pcint; Ptsyms : CTypes.pcint); cdecl; external JT_DLL name 'rs_encode_';
procedure interleave(Ptsyms : CTypes.pcint; Pdirection : CTypes.pcint); cdecl; external JT_DLL name 'interleave63_';
procedure graycode(Ptsyms : CTypes.pcint; Pcount : CTypes.pcint; Pdirection : CTypes.pcint); cdecl; external JT_DLL name 'graycode_';
procedure set65; cdecl; external JT_DLL name 'setup65_';
procedure packgrid(saveGrid : PChar; ng : CTypes.pcint; text : CTypes.pcbool); cdecl; external JT_DLL name 'packgrid_';
function  ptt(nport : CTypes.pcint; msg : CTypes.pcschar; ntx : CTypes.pcint; iptt : CTypes.pcint) : CTypes.cint; cdecl; external JT_DLL name 'ptt_';
//procedure gSamps(Ptxdf : CTypes.pcint; Ptsysms : CTypes.pcint; Pshmsg : CTypes.pcint; Psamples : CTypes.pcint16; Psamplescount : CTypes.pcint; level : CTypes.pcint); cdecl; external JT_DLL name 'g65_';
//procedure msync(dat : CTypes.pcfloat; jz : CTypes.pcint; syncount : CTypes.pcint; dtxa : CTypes.pcfloat; dfxa : CTypes.pcfloat; snrxa : CTypes.pcfloat; snrsynca : CTypes.pcfloat; ical : CTypes.pcint; wisfile : PChar); cdecl; external JT_DLL name 'msync65_';

{$R *.lfm}

{ TForm1 }

procedure TForm1.Timer1Timer(Sender: TObject);
begin
     // Timer is set to 100 mS resolution - it gets (tm) "close" to that and
     // for what's needed here close is enough.  There's no sense in attempting
     // to decrease the tick interval or otherwise mess with it.
     timer1.Enabled := False; // Disable on entry just in case so we don't end up recusrsively calling this.
     // Triggers for periodic actions
     if firstTick Then OncePerRuntime; // Reads config and sets everything up to run state.
     OncePerTick; // Code that executes ever ~100 mS.
     if (thisUTC.Second = 0) and (lastSecond = 59) Then newMinute := True else newMinute := False;
     if newMinute Then OncePerMinute;
     if (thisSecond <> lastSecond) Then newSecond := True else newSecond := False;
     if newSecond then oncePerSecond;
     if thisADCTick > lastADCTick Then adcdacTick;
     // Setup for next tick
     lastSecond := thisSecond;
     lastADCTick := thisADCTick;
     if newMinute then newMinute := False;
     if newSecond then newSecond := False;
     timer1.enabled := True;
     // And that's it for the timing loop - so much simpler than JT65-HF 1.x
end;

procedure TForm1.OncePerRuntime;
Var
   foo       : String;
   paInS     : String;
   i,fi      : Integer;
   paResult  : TPaError;
   paDefApi  : Integer;
   paCount   : Integer;
   fs,fsc    : String;
   ff        : Double;
   cfgpath   : String;
   basedir   : String;
   mustcfg   : Boolean;
   dummy     : Array[0..1] of String; // Will do away with this but need it for the rebel command function for now
Begin
     // This runs on first timer interrupt once per run session

     // Setup profile timers for demodulator
     //demodulate.dmprofile := TStringList.Create;
     //demodulate.dmprofile.Clear;
     //demodulate.dmprofile.CaseSensitive := False;
     //demodulate.dmprofile.Sorted := False;
     //demodulate.dmprofile.Duplicates := Types.dupIgnore;

     // Initialize this temp kludge to avoid a warning
     dummy[0] := '';
     dummy[1] := '';

     // Mark TX content as clean so any changes will lead to update
     txDirty := False;

     // Let adc know it is on first run so it can do its init
     adc.adcFirst := True;

     // Setup serial control
     tty := TBlockSerial.Create;
     foo := '';
     foo := synaser.GetSerialPortNames;
     ttyPorts := TStringList.Create;
     ttyPorts.Clear;
     ttyPorts.CaseSensitive := False;
     ttyPorts.Sorted := False;
     ttyPorts.Duplicates := Types.dupIgnore;
     if length(foo)>0 Then ttyPorts.CommaText := foo;
     comboTTYPorts.Clear;
     comboTTYPorts.Items.Add('None');
     if ttyPorts.Count > 0 Then
     Begin
          //if ttyPorts.Count > 1 Then foo := 'Found ' + IntToStr(ttyPorts.Count) + ' ports.' + sLineBreak else foo := 'Found 1 Port' + sLineBreak;
          for i := 0 to ttyPorts.Count-1 do
          begin
               comboTTYPorts.Items.Add(ttyPorts.Strings[i]);
          end;
     end;

     //tmpdir := GetTempDir(false);
     //dmtmpdir := tmpdir; // For KV files -sigh- not.

     homedir := getUserDir;
     dmtmpdir := homedir+'hfwst\';

     mustcfg := False;

     catError := TStringList.Create;
     catError.Clear;
     catError.CaseSensitive := False;
     catError.Sorted := False;
     catError.Duplicates := Types.dupAccept;

     if not DirectoryExists(homedir+'hfwst') Then
     Begin
          if not createDir(homedir+'hfwst') Then
          Begin
               showmessage('Could not create data directory' + sLineBreak + 'Program must halt.');
               halt;
          //end
          //else
          //begin
          //     showmessage('Created temporary files directory at:' + sLineBreak + homedir+'hfwst\');
          end;
     //end
     //else
     //begin
     //     showmessage('Found temporary files directory at:' + sLineBreak + homedir+'hfwst\');
     end;
     homedir := homedir+'hfwst\';

     //showmessage(homedir);

     if not FileExists(homedir+'kvasd.exe') Then
     Begin
          if not FileUtil.CopyFile('kvasd.exe',homedir+'kvasd.exe') Then showmessage('Need kvasd.exe in data directory.') else showmessage('kvasd.exe copied to its processing location');
     //end
     //else
     //begin
     //     ShowMessage('kvasd.exe is in proper location');
     end;

     basedir := GetAppConfigDir(false);
     basedir := TrimFilename(basedir);

     if not DirectoryExists(basedir) Then
     Begin
          if not createDir(basedir) Then
          begin
               ShowMessage('Could not create base configuration directory' + sLineBreak + 'Program must halt.');
               halt;
          //end
          //else
          //begin
          //      showMessage('Created configuration directory');
          end;
     //end
     //else
     //begin
     //     ShowMessage('Configuration directory is in place.');
     end;

     if basedir[Length(basedir)] = PathDelim Then
     Begin
          cfgpath := basedir + 'I1' + PathDelim;
     end
     else
     begin
          cfgpath := basedir + PathDelim + cfgpath + 'I1' + PathDelim;
     end;

     if not DirectoryExists(cfgpath) Then
     Begin
          if not createDir(cfgpath) Then
          begin
               ShowMessage('Could not create instance configuration directory' + sLineBreak + 'Program must halt.');
               halt;
          //end
          //else
          //begin
          //      ShowMessage('Instance config dir created.');
          end;
     //end
     //else
     //begin
     //     ShowMessage('Instance config dir exists.')
     end;

     // Check that path length won't be a problem.  It needs to be < 256 charcters in length with either kvasd.dat or wisdom2.dat appended
     // So actual length + 11 < 256 is OK.
     if Length(cfgpath)+11 > 255 then
     begin
          ShowMessage('Path length too long [ ' + IntToStr(Length(cfgpath)+11) + ' ]' + 'Program must halt.');
          halt;
     end;

     // Create sqlite3 store, if necessary
     if not fileExists(cfgPath + 'jt65hf_datastore') Then setupDB(cfgPath);

     // Housekeeping items here
     cfgdir := cfgPath;
     demodulate.dmwispath := TrimFilename(cfgDir+'wisdom2.dat');
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]); // This is a big one - must be set or BAD BAD things happen.

     // Query db for configuration with instance id = 1 and if it exists
     // read config, if not set to defaults and prompt for config update

     sqlite3.DatabaseName := cfgPath + 'jt65hf_datastore';

     query.Active := False;
     query.SQL.Clear;
     query.SQL.Add('SELECT * FROM config WHERE instance = 1;');
     query.Active := True;
     if query.RecordCount = 0 then
     begin
          // Instance 1 not in place - fix that.
          query.Active := False;
          query.SQL.Clear;
          query.SQL.Add('INSERT INTO config(needcfg) VALUES(1);');
          query.ExecSQL;
          transaction.Commit;
     end;

     query.Active := False;
     query.SQL.Clear;
     query.SQL.Add('SELECT needcfg FROM config WHERE instance = 1;');
     query.Active := True;
     if query.RecordCount = 0 then
     begin
          ShowMessage('Error - no instance data.');
          halt;
     end
     else
     begin
          if query.Fields[0].AsBoolean then
          Begin
               ShowMessage('Please setup your station information.');
               mustcfg := True;
          end;
     end;

     // Read the V1 style grids lookup table
     query.Active := False;
     query.SQL.Clear;
     query.SQL.Add('SELECT xlate FROM ngdb;');
     query.Active := True;
     if query.RecordCount = 32768 Then
     Begin
          query.First;
          for i := 0 to 32767 do
          begin
               demodulate.glist[i] := query.Fields[0].AsString;
               query.Next;
          end;
     end;
     query.Active := False;

     if mustcfg Then setDefaults;

     // Read the data from config
     query.Active := False;
     query.SQL.Clear;
     query.SQL.Add('SELECT * FROM config WHERE instance=1;');
     query.Active := True;
     edPrefix.Text := query.FieldByName('prefix').AsString;
     edCall.Text   := query.FieldByName('call').AsString;
     edSuffix.Text := query.FieldByName('suffix').AsString;
     edGrid.Text   := query.FieldByName('grid').AsString;
     // Need to handle these in audio selector code! PageControl
     savedTADC := query.FieldByName('tadc').AsString;
     savedIADC := query.FieldByName('iadc').AsInteger;
     cbUseMono.Checked       := query.FieldByName('mono').AsBoolean;
     rbUseLeftAudio.Checked  := query.FieldByName('left').AsBoolean;
     rbUseRightAudio.Checked := query.FieldByName('right').AsBoolean;
     foo := query.FieldByName('dgainl').AsString;
     if foo='0' Then dgainL0.Checked := True;
     if foo='3' Then dgainL3.Checked := True;
     if foo='6' Then dgainL6.Checked := True;
     if foo='9' Then dgainL9.Checked := True;
     foo := query.FieldByName('dgainr').AsString;
     if foo='0' Then dgainR0.Checked := True;
     if foo='3' Then dgainR3.Checked := True;
     if foo='6' Then dgainR6.Checked := True;
     if foo='9' Then dgainR9.Checked := True;
     cbAttenuateLeft.Checked := query.FieldByName('dgainla').AsBoolean;
     cbAttenuateRight.Checked := query.FieldByName('dgainra').AsBoolean;
     cbUseSerial.Checked := query.FieldByName('useserial').AsBoolean;
     edPort.Text := query.FieldByName('port').AsString;
     cbUseTXWD.Checked := query.FieldByName('txwatchdog').AsBoolean;
     edTXWD.Text := query.FieldByName('txwatchdogcount').AsString;
     If query.FieldByName('rigcontrol').AsString = 'Rebel' Then rigRebel.Checked := True else rigNone.Checked := True;
     cbDivideDecodes.Checked := query.FieldByName('perioddivide').AsBoolean;
     cbCompactDivides.Checked := query.FieldByName('periodcompact').AsBoolean;
     cbUseColor.Checked := query.FieldByName('usecolor').AsBoolean;
     cbCQColor.ItemIndex := query.FieldByName('cqcolor').AsInteger;
     cbMyCallColor.ItemIndex := query.FieldByName('mycallcolor').AsInteger;
     cbQSOColor.ItemIndex := query.FieldByName('qsocolor').AsInteger;
     spColorMap.ItemIndex := query.FieldByName('wfcmap').AsInteger;
     tbWFSpeed.Position := query.FieldByName('wfspeed').AsInteger;
     tbWFContrast.Position := query.FieldByName('wfcontrast').AsInteger;
     tbWFBright.Position := query.FieldByName('wfbright').AsInteger;
     tbWFGain.Position := query.FieldByName('wfgain').AsInteger;
     cbSpecSmooth.Checked := query.FieldByName('wfsmooth').AsBoolean;
     edRBCall.Text := query.FieldByName('spotcall').AsString;
     edStationInfo.Text := query.FieldByName('spotinfo').AsString;
     cbSaveToCSV.Checked := query.FieldByName('usecsv').AsBoolean;
     edCSVPath.Text := query.FieldByName('csvpath').AsString;
     edADIFPath.Text := query.FieldByName('adifpath').AsString;
     edADIFMode.Text := query.FieldByName('logas').AsString;
     cbRememberComments.Checked := query.FieldByName('remembercomments').AsBoolean;
     cbMultiOffQSO.Checked := query.FieldByName('multioffqso').AsBoolean;
     cbRestoreMulti.Checked := query.FieldByName('automultion').AsBoolean;
     cbHaltTXMultiOn.Checked := query.FieldByName('halttxsetsmulti').AsBoolean;
     cbDefaultsMultiOn.Checked := query.FieldByName('defaultsetsmulti').AsBoolean;
     if query.FieldByName('decimal').AsString = 'USA' then useDeciAmerican.Checked := True;
     if query.FieldByName('decimal').AsString = 'Euro' then useDeciEuro.Checked := True;
     if query.FieldByName('decimal').AsString = 'Auto' then useDeciAuto.Checked := True;
     foo := query.FieldByName('cwid').AsString;
     if foo = 'None' Then rbNoCWID.Checked := True;
     if foo = '73' Then rbCWID73.Checked := True;
     if foo = 'Free' Then rbCWIDFree.Checked := True;
     edCWID.Text := query.FieldByName('cwidcall').AsString;
     cbNoOptFFT.Checked := query.FieldByName('disableoptfft').AsBoolean;
     cbNoKV.Checked := query.FieldByName('disablekv').AsBoolean;
     lastQRG.Text := query.FieldByName('lastqrg').AsString;
     tbSingleBin.Position := query.FieldByName('sbinspace').AsInteger;
     tbMultiBin.Position := query.FieldByName('mbinspace').AsInteger;
     tbTXLevel.Position := query.FieldByName('txlevel').AsInteger;
     version.Text := query.FieldByName('version').AsString;
     cbMultiOn.Checked := query.FieldByName('multion').AsBoolean;
     cbTXEqRXDF.Checked := query.FieldByName('txeqrxdf').AsBoolean;
     query.Active := False;

     // Setup rigcontrol object (used even if not using "real" rig control)
     rigControlSet(useDeciAuto);
     rigControlSet(tbWFSpeed);
     rigControlSet(tbWFContrast);
     rigControlSet(tbWFBright);
     rigControlSet(tbWFGain);
     rigControlSet(spColorMap);
     rigControlSet(dgainL0);
     rigControlSet(dgainR0);
     rigControlSet(rbUseLeftAudio);
     rigControlSet(rigNone);

     // Setup clock display
     foo := '';
     if thisUTC.Month < 10 Then foo := '0' + IntToStr(thisUTC.Month) + '-' else foo := IntToStr(thisUTC.Month) + '-';
     if thisUTC.Day   < 10 Then foo := foo + '0' + IntToStr(thisUTC.Day) + '-' else foo := foo + IntToStr(thisUTC.Day) + '-';
     foo := foo + IntToStr(thisUTC.Year) + '  ';
     if thisUTC.Hour  < 10 Then foo := foo + '0' + IntToStr(thisUTC.Hour) + ':' else foo := foo + IntToStr(thisUTC.Hour) + ':';
     if thisUTC.Minute < 10 Then foo := foo + '0' + IntToStr(thisUTC.Minute) + ':' else foo := foo + IntToStr(thisUTC.Minute) + ':';
     if thisUTC.Second < 10 Then foo := foo + '0' + IntToStr(thisUTC.Second) else foo := foo + IntToStr(thisUTC.Second);
     stime := 'Started:  ' + foo;

     // Validate initial QRG
     fs  := '';
     ff  := 0.0;
     fi  := 0;
     fs  := edDialQRG.Text;
     fsc := '';
     mval.forceDecimalAmer := False;
     mval.forceDecimalEuro := False;
     if mval.evalQRG(fs,'STRICT',ff,fi,fsc) Then qrgValid := True else qrgValid := False;


     // Populate QRG list
     comboQRGList.Clear;
     query.Active := False;
     query.SQL.Clear;
     query.SQL.Add('SELECT fqrg FROM qrg WHERE instance = 1 ORDER BY fqrg DESC;');
     query.Active := True;
     if query.RecordCount > 0 Then
     Begin
          query.First;
          for i := 0 to query.RecordCount-1 do
          begin
               fs  := query.Fields[0].AsString;
               ff  := 0.0;
               fi  := 0;
               fsc := '';
               if mval.evalQRG(fs,'STRICT',ff,fi,fsc) Then comboQRGList.Items.Add(fsc);
               query.Next;
          end;
     end;
     query.Active := False;

     // Populate Macro list
     comboMacroList.Clear;
     query.SQL.Clear;
     query.SQL.Add('SELECT text FROM macro WHERE instance = 1;');
     query.Active := True;
     if query.RecordCount > 0 Then
     Begin
          query.First;
          for i := 0 to query.RecordCount-1 do
          begin
               comboMacroList.Items.Add(query.Fields[0].AsString);
               query.Next;
          end;
     end;
     query.Active := False;

     // Lets read some config
     inDev  := savedIADC;
     pttDev := -1;
     If not TryStrToInt(edPort.Text,pttDev) Then pttDev := -1;

     if cbNoOptFFT.Checked Then
     Begin
          inIcal := 0;
     end
     else
     begin
          if not fileExists(cfgPath + 'wisdom2.dat') Then
          Begin
               inIcal := 21;
               ShowMessage('First decode cycle will be delayed and will fail to decode - computing optimal FFT values. A one time thing!');
          end
          else
          begin
               inIcal := 1;
          end;
     end;


     if cbSpecSmooth.Checked then spectrum.specSmooth := True else spectrum.specSmooth := False;
     if cbSpecSmooth.Checked then spectrum.specuseagc := True else spectrum.specuseagc := False;
     spectrum.specColorMap := spColorMap.ItemIndex;
     if not tryStrToInt(lastQRG.Text,fi) then lastQRG.Text := '0';
     edDialQRG.Text := lastQRG.Text;
     fs  := '';
     ff  := 0.0;
     fi  := 0;
     fs  := edDialQRG.Text;
     fsc := '';
     mval.forceDecimalAmer := False;
     mval.forceDecimalEuro := False;
     if mval.evalQRG(fs,'STRICT',ff,fi,fsc) Then qrgValid := True else qrgValid := False;
     If TryStrToInt(TXLevel.Text,i) Then tbTXLevel.Position := i else tbTXLevel.Position := 16;

     if useDeciAmerican.Checked then
     begin
          dChar := '.';
          kChar := ',';
     end;
     if useDeciEuro.Checked then
     begin
          dChar := ',';
          kChar := '.';
     end;
     if useDeciAuto.Checked then
     begin
          dChar := DecimalSeparator;
          kChar := ThousandSeparator;
          if dChar = '.' Then useDeciAuto.Caption := 'Use System Default (decimal = . thousands = ,)';
          if dChar = ',' Then useDeciAuto.Caption := 'Use System Default (decimal = , thousands = .)';
     end;

     // Intitialize to startup points
     forceCAT := False;
     qsyQRG   := 0;
     kvcount   := 0;
     bmcount   := 0;
     v1c       := 0;
     v2c       := 0;
     msc       := 0;
     mfc       := 0;
     pfails    := 0;
     avgdt     := 0.0;
     sopQRG    := 0;
     eopQRG    := 0;
     inQSOWith := '';
     newLog    := True;
     setQRG    := False;
     readQRG   := False;
     readPTT   := False;
     setPTT    := False;
     pttState  := False;
     catQRG    := 0;

     demodulate.dmfirstPass  := True;
     demodulate.dmhaveDecode := False;
     demodulate.dmdemodBusy  := False;
     demodulate.dmruntime    := 0.0;

     If tbMultiBin.Position = 1 then demodulate.dmbw := 20;
     If tbMultiBin.Position = 2 then demodulate.dmbw := 50;
     If tbMultiBin.Position = 3 then demodulate.dmbw := 100;
     If tbMultiBin.Position = 4 then demodulate.dmbw := 200;
     Label26.Caption := 'Multi ' + IntToStr(demodulate.dmbw) + ' Hz';

     If tbSingleBin.Position = 1 then demodulate.dmbws := 20;
     If tbSingleBin.Position = 2 then demodulate.dmbws := 50;
     If tbSingleBin.Position = 3 then demodulate.dmbws := 100;
     If tbSingleBin.Position = 4 then demodulate.dmbws := 200;
     Label87.Caption := 'Single ' + IntToStr(demodulate.dmbws) + ' Hz';

     if inIcal >-1 then demodulate.dmical := inIcal else demodulate.dmical := 0;

//     set65;
     paActive := False;
     thisTXCall := '';
     thisTXGrid := '';
     thisTXmsg  := '';
     thisTXdf   := 0;

     spectrum.specFirstRun := True;
     spectrum.specuseagc   := False;
     spectrum.specSmooth   := False;

     // Todo tie these to db vars
     spectrum.specVGain    := 7;  // 7 is "normal" can range from 1 to 13
     spectrum.specContrast := 1;
     spectrum.specGain     := 0;

     globalData.specMs65  := TMemoryStream.Create;
     globalData.specMs65.Position := 0;
     thisADCTick := 0;
     lastADCTick := 0;
     aulevel := 0;
     aulevel1 := 0;
     aulevel2 := 0;

     adc.adcMono := False;
     adc.auIDX   := 0;
     adc.specIDX := 0;
     adc.haveAU  := False;
     adc.haveSpec := False;

     flipflop := 0;
     fbar1 := Nil;
     if FBar1 = nil then InitBar;
     FBar1.Clear;
     FBar1.Marks.Style := TSeriesMarksStyle(smsNone);
     txOn := False;
     ListBox1.Clear;
     ListBox2.Clear;
     Memo1.Clear;

     // Create and initialize TWaterfallControl
     Waterfall1 := TWaterfallControl1.Create(Self);
     Waterfall1.Height := 180;
     Waterfall1.Width  := 747;
     Waterfall1.Top    := 68;
     Waterfall1.Left   := 152;
     Waterfall1.Parent := Self;
     //Waterfall1.OnMouseDown := waterfallMouseDown;
     Waterfall1.DoubleBuffered := True;
     If mustcfg Then Waterfall1.Visible := False;

     // Setup RB (thread)
     //rbtick  := 0;
     //rbpings := 0;
     rb := spot.TSpot.create(); // Used even if spotting is disabled
     // Set RB Version - note - wrong value here will lead to rb.php saying newp.
     rb.rbVersion := '3000';
     rbThread  := rbcThread.Create(False);
     if rbOn.Checked Then
     Begin
          if length(edRBCall.Text) <3 Then
          Begin
               edRBCall.Text := '';
               if length(edCall.Text) > 0 Then edRBCall.Text := edCall.Text;
               if length(edPrefix.Text) > 0 Then edRBCall.Text := edPrefix.Text + '/' + edRBCall.Text;
               if length(edSuffix.Text) > 0 Then edRBCall.Text := edRBCall.Text + '/' + edSuffix.Text;
          end;
          if length(edRBCall.Text) > 2 Then
          Begin
               rb.myCall := TrimLeft(TrimRight(UpCase(edRBCall.Text)));
               rb.myGrid := TrimLeft(TrimRight(edGrid.Text));
               rb.rbInfo := TrimLeft(TrimRight(edStationInfo.Text));
               rb.myQRG  := StrToInt(edDialQRG.Text);
               sopQRG    := StrToInt(edDialQRG.Text);
               rb.useRB := True;
               rb.useDBF := False;
               rbping    := True;
          end
          else
          begin
               rb.useRB := False;
               rbping := False;
          end;
     end
     else
     begin
          if length(edRBCall.Text) <3 Then
          Begin
               edRBCall.Text := '';
               if length(edCall.Text) > 0 Then edRBCall.Text := edCall.Text;
               if length(edPrefix.Text) > 0 Then edRBCall.Text := edPrefix.Text + '/' + edRBCall.Text;
               if length(edSuffix.Text) > 0 Then edRBCall.Text := edRBCall.Text + '/' + edSuffix.Text;
          end;
          if length(edRBCall.Text) > 2 Then
          Begin
               rb.myCall := TrimLeft(TrimRight(UpCase(edRBCall.Text)));
               rb.myGrid := TrimLeft(TrimRight(edGrid.Text));
               rb.rbInfo := TrimLeft(TrimRight(edStationInfo.Text));
               rb.myQRG  := StrToInt(edDialQRG.Text);
               sopQRG    := StrToInt(edDialQRG.Text);
               rb.useRB := False;
               rb.useDBF := False;
               rbping    := False;
          end
          else
          begin
               rb.useRB := False;
               rbping := False;
          end;
     end;

     // Setup Decoder (thread)
     doDecode      := False;
     decoderThread := decodeThread.Create(False);

     // Setup Rig Control (thread)
     doCAT      := False;
     rigThread  := catThread.Create(False);

     if not paActive Then
     Begin
          // Fire up portaudio using default in/out devices.
          // But first clear the i/o buffers in adc/dac
          ListBox2.Items.Add('Setting up PortAudio');
          for i := 0 to Length(adc.d65rxFBuffer)-1 do adc.d65rxFBuffer[i] := 0.0;
          //for i := 0 to Length(dac.d65txBuffer)-1 do dac.d65txBuffer[i] := 0;

          // Init PA.  If this doesn't work there's no reason to continue.
          PaResult := portaudio.Pa_Initialize();
          If PaResult <> 0 Then
          Begin
               ShowMessage('Fatal Error.  Could not initialize PortAudio.');
               halt;
          end;
          If PaResult = 0 Then ListBox2.Items.Insert(0,'PortAudio up.');
          // Now I need to populate the Sound In/Out pulldowns.  First I'm going to get
          // a list of the portaudio API descriptions.  For now I'm going to stick with
          // the default windows interface.
          paDefApi := portaudio.Pa_GetDefaultHostApi();
          if paDefApi >= 0 Then
          Begin
               paCount := portaudio.Pa_GetHostApiInfo(paDefApi)^.deviceCount;
               i := paCount-1;
               if i < 0 Then
               Begin
                    ShowMessage('PortAudio Reports no audio devices.');
                    Halt;
               End;
               comboAudioIn.Clear;
               //comboAudioOut.Clear;
               i := 0;
               While i < paCount do
               Begin
                    // I need to populate the pulldowns with the devices supported by
                    // the default portaudio API, select the default in/out devices for
                    // said API or restore the saved value of the user's choice of in
                    // out devices.
                    If portaudio.Pa_GetDeviceInfo(i)^.maxInputChannels > 0 Then
                    Begin
                         if i < 10 Then paInS := '0' + IntToStr(i) + '-' + ConvertEncoding(StrPas(portaudio.Pa_GetDeviceInfo(i)^.name),GuessEncoding(StrPas(portaudio.Pa_GetDeviceInfo(i)^.name)),EncodingUTF8) else paInS := IntToStr(i) + '-' + ConvertEncoding(StrPas(portaudio.Pa_GetDeviceInfo(i)^.name),GuessEncoding(StrPas(portaudio.Pa_GetDeviceInfo(i)^.name)),EncodingUTF8);
                         comboAudioIn.Items.Add(paInS);
                         ListBox2.Items.Insert(0,'Input:  ' + paInS);
                    End;
                    //If portaudio.Pa_GetDeviceInfo(i)^.maxOutputChannels > 0 Then
                    //Begin
                    //     if i < 10 Then paOutS := '0' + IntToStr(i) +  '-' + ConvertEncoding(StrPas(portaudio.Pa_GetDeviceInfo(i)^.name),GuessEncoding(StrPas(portaudio.Pa_GetDeviceInfo(i)^.name)),EncodingUTF8) else paOutS := IntToStr(i) +  '-' + ConvertEncoding(StrPas(portaudio.Pa_GetDeviceInfo(i)^.name),GuessEncoding(StrPas(portaudio.Pa_GetDeviceInfo(i)^.name)),EncodingUTF8);
                    //     comboAudioOut.Items.Add(paOutS);
                    //     ListBox2.Items.Insert(0,'Output:  ' + paOutS);
                    //End;
                    inc(i);
               End;

               foo := IntToStr(portaudio.Pa_GetHostApiInfo(paDefApi)^.defaultInputDevice);
               if length(foo)=1 then foo := '0'+foo;
               for i := 0 to comboAudioIn.Items.Count -1 do
               begin
                    if comboAudioIn.Items.Strings[i][1..2] = foo then break;
               end;
               comboAudioIn.ItemIndex := i;
               foo := IntToStr(portaudio.Pa_GetHostApiInfo(paDefApi)^.defaultOutputDevice);
               if length(foo)=1 then foo := '0'+foo;
               //for i := 0 to comboAudioOut.Items.Count -1 do
               //begin
               //     if comboAudioOut.Items.Strings[i][1..2] = foo then break;
               //end;
               //comboAudioOut.ItemIndex := i;

               defI := portaudio.Pa_GetHostApiInfo(paDefApi)^.defaultInputDevice;
               //defO := portaudio.Pa_GetHostApiInfo(paDefApi)^.defaultOutputDevice;
               ListBox2.Items.Insert(0,'Default input:  ' + IntToStr(defI));
               //ListBox2.Items.Insert(0,'Default output:  ' + IntToStr(defO));

               //if (inDev > -1) and (outDev > -1) Then
               //Begin
               //     ListBox2.Items.Insert(0,'Setting up ADC/DAC.  ADC:  ' + IntToStr(inDev) + ' DAC:  ' + IntToStr(outDev));
               //end
               //else
               //Begin
               //     ListBox2.Items.Insert(0,'Using DEFAULT input/output devices');
               //     ListBox2.Items.Insert(0,'Setting up ADC/DAC.  ADC:  ' + IntToStr(defI) + ' DAC:  ' + IntToStr(defO));
               //end;

               //if (inDev > -1) and (outDev > -1) Then
               //Begin
               //     ListBox2.Items.Insert(0,'Setting up ADC.  ADC:  ' + IntToStr(inDev));
               //end
               //else
               //Begin
               //     ListBox2.Items.Insert(0,'Using DEFAULT input device.');
               //     ListBox2.Items.Insert(0,'Setting up ADC.  ADC:  ' + IntToStr(defI));
               //end;

               if (inDev > -1) Then
               Begin
                    ListBox2.Items.Insert(0,'Setting up ADC.  ADC:  ' + IntToStr(inDev));
               end
               else
               Begin
                    ListBox2.Items.Insert(0,'Using DEFAULT input device.');
                    ListBox2.Items.Insert(0,'Setting up ADC.  ADC:  ' + IntToStr(defI));
               end;

               // Setup input device
               // Set parameters before call to start
               // Input
               if cbUseMono.Checked Then
               Begin
                    paInParams.channelCount := 1;
                    adc.adcMono := True;
                    ListBox2.Items.Insert(0,'Using Mono');
               end
               else
               begin
                    paInParams.channelCount := 2;
                    adc.adcMono := False;
                    ListBox2.Items.Insert(0,'Using Stereo');
               end;
               if inDev > -1 Then paInParams.device := inDev else paInParams.device := defI;
               paInParams.sampleFormat := paInt16;
               paInParams.suggestedLatency := 1;
               paInParams.hostApiSpecificStreamInfo := Nil;
               ppaInParams := @paInParams;
               // Set rxBuffer index to start of array.
               adc.d65rxBufferIdx := 0;
               adc.adcTick := 0;
               adc.adcECount := 0;
               adc.adcChan := 1;
               adc.adcLDgain := 0;
               adc.adcRDgain := 0;
               adcSpecAvg1 := 0;
               adcSpecAvg2 := 0;
               // output
               //paOutParams.channelCount := 2;
               //if outDev > -1 Then paOutParams.device := outDev else paOutParams.device := defO;
               //paOutParams.sampleFormat := paInt16;
               //paOutParams.suggestedLatency := 1;
               //paOutParams.hostApiSpecificStreamInfo := Nil;
               //ppaOutParams := @paOutParams;
               // Set txBuffer index to start of array.
               //dac.d65txBufferIdx := 0;
               //dac.dacECount := 0;
               //dac.dacTick := 0;
               // Attempt to open selected devices, both must pass open/start to continue.

               // Initialize RX stream.
               paResult := portaudio.Pa_OpenStream(PPaStream(paInStream),PPaStreamParameters(ppaInParams),PPaStreamParameters(Nil),CTypes.cdouble(11025.0),CTypes.culong(64),TPaStreamFlags(0),PPaStreamCallback(@adc.adcCallback),Pointer(Self));
               if paResult <> 0 Then
               Begin
                    // Was unable to open RX.
                    ShowMessage('Unable to start PortAudio Input Stream.');
                    Halt;
               end;
               ListBox2.Items.Insert(0,'Opened input device');
               // Start the RX stream.
               paResult := portaudio.Pa_StartStream(paInStream);
               if paResult <> 0 Then
               Begin
                    // Was unable to start RX stream.
                    ShowMessage('Unable to start PortAudio Input Stream.');
                    Halt;
               end;
               ListBox2.Items.Insert(0,'Started input device');

               // Initialize tx stream.
               globalData.txInProgress := False;
               //paResult := portaudio.Pa_OpenStream(PPaStream(paOutStream),PPaStreamParameters(Nil),PPaStreamParameters(ppaOutParams),CTypes.cdouble(11025.0),CTypes.culong(0),TPaStreamFlags(0),PPaStreamCallback(@dac.dacCallback),Pointer(Self));
               //if paResult <> 0 Then
               //Begin
                    // Was unable to open TX.
                    //ShowMessage('Unable to open PA TX Stream.');
                    //Halt;
               //end;
               // Start the TX stream.
               //paResult := portaudio.Pa_StartStream(paOutStream);
               //if paResult <> 0 Then
               //Begin
                    // Was unable to start TX stream.
                    //ShowMessage('Unable to start PA TX Stream.');
                    //Halt;
               //end;
               //i := 0;
               //while portAudio.Pa_IsStreamActive(paOutStream) > 0 do
               //Begin
                    // Stream is still running
                    //inc(i);
                    //sleep(1);
                    //application.ProcessMessages;
               //End;
               //paresult := portAudio.Pa_CloseStream(paOutStream);
               //paOutStream := Nil;
               //dac.dacTick := 0;
          end
          else
          begin
               ShowMessage('PortAudio Error.  No default API value.');
               halt;
          end;
          paActive := True;

          ListBox2.Items.Insert(0,'PortAudio configured and running');
          ListBox2.Items.Insert(0,'Waiting for sync to second = 0');

          // Set the audio selector to configured device so it doesn't
          // trigger any random changes when configuration is opened.
          for i := 0 to comboAudioIn.Items.Count-1 do
          begin
               if comboAudioIn.Items.Strings[i] = savedTADC Then
               Begin
                    comboAudioIn.ItemIndex := i;
                    break;
               end;
          end;

          //for i := 0 to comboAudioOut.Items.Count-1 do
          //begin
          //     if comboAudioOut.Items.Strings[i] = tdac.Text Then
          //     Begin
          //          comboAudioOut.ItemIndex := i;
          //          break;
          //     end;
          //end;
     end;

     if rigRebel.Checked Then
     Begin
          //function TForm1.rebelCommand(const cmd : String; const value : String; const ltx : Array of String; var error : String) : Boolean;
          if rebelCommand('VER', '', dummy, foo) Then
          Begin
               if foo = 'JT65100' Then
               begin
                    haveRebel := True;
               end;
          end
          else
          begin
               ShowMessage('Unable to connect to Rebel' + sLineBreak + 'Check settings and firmware' + sLineBreak + 'Error:  ' + foo);
               haveRebel := False;
               rigNone.Checked := True;
          end;
     end;

     catFree  := True;
     readQRG  := True;
     forceCAT := True;
     firstTick := False;
end;

procedure TForm1.OncePerTick;
Var
  i,fi      : Integer;
  np, ntx   : CTypes.cint;
  iptt      : CTypes.cint;
  ioresult  : CTypes.cint;
  msg       : CTypes.cschar;
  fs, fsc   : String;
  s1, s2    : String;
  ff        : Double;
  cqrg      : Integer;
  valid     : Boolean;
Begin
     // Runs on each timer tick
     thisUTC     := utcTime;
     thisSecond  := thisUTC.Second;
     thisADCTick := adc.adcTick;
     if not demodulate.dmdemodBusy and demodulate.dmhaveDecode Then displayDecodes;
     cqrg := StrToInt(edDialQRG.Text);
     if (sopQRG = eopQRG) And (sopQRG = cqrg) Then Label122.Caption := 'RB QRG Synchronized' else Label122.Caption := 'RB QRG Not Synchronized';
     Waterfall1.Repaint;
     flipflop := 0;
     if forceCAT and catFree Then
     Begin
          { TODO : Add CI-V Commander back as control option }
          If rigNone.Checked Then catMethod := 'None';
          if rigRebel.Checked Then catMethod := 'Rebel';
          //if rigCommander.Checked Then catMethod := 'Commander';
          doCAT     := True;
          forceCAT  := False;
     end;

     if catError.Count > 0 Then for i := 0 to catError.Count-1 do ListBox2.Items.Insert(0,catError.Strings[i]);
     if catError.Count > 0 Then catError.Clear;

     if cbUseColor.Checked Then ListBox1.Style := lbOwnerDrawFixed else ListBox1.Style := lbStandard;
     Label121.Caption := 'Decoder Resolution:  ' + IntToStr(demodulate.dmbw) + ' Hz';
     if kvcount > 0 Then Label95.Caption := PadLeft(IntToStr(kvcount),5) + '  ' + FormatFloat('0.0',(100.0*(kvcount/(kvcount+bmcount)))) + '%';
     if bmcount > 0 Then Label96.Caption := PadLeft(IntToStr(bmcount),5) + '  ' + FormatFloat('0.0',(100.0*(bmcount/(kvcount+bmcount)))) + '%';
     if bmcount+kvcount > 0 Then Label98.Caption := PadLeft(FormatFloat('0.00',(avgdt/(kvcount+bmcount))),5);
     if msc > 0 Then Label112.Caption := PadLeft(IntToStr(msc),5);
     if mfc > 0 Then Label113.Caption := PadLeft(IntToStr(mfc),5);
     if v1c > 0 Then Label116.Caption := PadLeft(IntToStr(v1c),5);
     if v2c > 0 Then Label117.Caption := PadLeft(IntToStr(v2c),5);

     fs  := '';
     ff  := 0.0;
     fi  := 0;
     fs  := edDialQRG.Text;
     fsc := '';
     mval.forceDecimalAmer := False;
     mval.forceDecimalEuro := False;
     if mval.evalQRG(fs,'STRICT',ff,fi,fsc) Then qrgValid := True else qrgValid := False;

     if qrgValid and (length(edRBCall.Text)>2) Then
     Begin
          rbOn.Enabled := True;
          rbOn.Font.Color := clBlack;
          if not rbOn.Checked then rbOn.Font.Color := clMaroon;
     end
     else
     begin
          rbOn.Checked := False;
          rbOn.Enabled := False;
          rbOn.Font.Color := clRed;
     end;

     // Converts Integer Hertz value to KHz taking into account local decimal character.
     // This is *better* than converting to float and dividing.  :)
     if length(edDialQRG.Text)> 3 Then
     Begin
          s1 := edDialQRG.Text;
          s2 := s1[Length(s1)-2..Length(s1)];
          s1 := s1[1..Length(s1)-3];
          s2 := s1 + dChar + s2;
          if s2[Length(s2)]='0' Then
          Begin
               s2 := s2[1..Length(s2)-1];
               if s2[Length(s2)]='0' Then
               Begin
                    s2 := s2[1..Length(s2)-1];
                    if s2[Length(s2)]='0' Then
                    Begin
                         s2 := s2[1..Length(s2)-1];
                    End;
               End;
          end;
          if s2[Length(s2)] = dChar then s2 := s2[1..Length(s2)-1];
          Label27.Caption := s2 + ' KHz';
     end
     else
     begin
          Label27.Caption := edDialQRG.Text;
     end;

     Label90.Caption := 'CAT QRG:  ' + IntToStr(catQRG);

     //if RadioButton1.Checked And globalData.txInProgress Then globalData.txInProgress := False;

     spectrum.specColorMap := spColorMap.ItemIndex;

     If tbMultiBin.Position = 1 then demodulate.dmbw := 20;
     If tbMultiBin.Position = 2 then demodulate.dmbw := 50;
     If tbMultiBin.Position = 3 then demodulate.dmbw := 100;
     If tbMultiBin.Position = 4 then demodulate.dmbw := 200;

     If tbSingleBin.Position = 1 then demodulate.dmbws := 20;
     If tbSingleBin.Position = 2 then demodulate.dmbws := 50;
     If tbSingleBin.Position = 3 then demodulate.dmbws := 100;
     If tbSingleBin.Position = 4 then demodulate.dmbws := 200;

     spectrum.specSpeed2 := tbWFSpeed.Position;
     if cbSpecSmooth.Checked Then spectrum.specSmooth := True else spectrum.specSmooth := False;
     if cbSpecSmooth.Checked Then spectrum.specuseagc := True else spectrum.specuseagc := False;
     spectrum.specColorMap := spColorMap.ItemIndex;

     if rbUseLeftAudio.Checked Then adc.adcChan  := 1;
     if rbUseRightaudio.Checked Then adc.adcChan := 2;
     if cbUseMono.Checked Then adc.adcMono := True else adc.adcMono := False;

     if not demodulate.dmdemodBusy Then
     Begin
          if dmruntime > lrun then lrun := dmruntime;
          if isZero(srun) Then srun := dmruntime;
          if dmruntime < srun Then srun := dmruntime;
          if not IsZero(demodulate.dmruntime) Then Label82.Caption := FormatFloat('0.000',(demodulate.dmruntime/1000.0));
          if not IsZero(lrun) Then Label83.Caption := FormatFloat('0.000',(lrun/1000.0));
          if not IsZero(srun) Then Label84.Caption := FormatFloat('0.000',(srun/1000.0));
          if not isZero(demodulate.dmarun) Then Label86.Caption := FormatFloat('0.000',((demodulate.dmarun/demodulate.dmrcount)/1000.0));
     end;

     // Compute actual full callsign to use from prefix+callsign+suffix

     // If Prefix and suffix defined (invalid) the prefix wins.
     If (Length(edPrefix.Text)>0) And (Length(edSuffix.Text)>0) Then edSuffix.Text := '';

     If (Length(edPrefix.Text)>0) And (Length(edSuffix.Text)=0) And ((Length(edCall.Text)>2) And (Length(edCall.Text)<7)) And ((Length(getLocalGrid)=4) Or (Length(getLocalGrid)=6)) Then
     Begin
          thisTXcall := TrimLeft(TrimRight(UpCase(edPrefix.Text))) + '/' + TrimLeft(Trimright(UpCase(edCall.Text)));
          thisTXgrid := TrimLeft(TrimRight(UpCase(getLocalGrid)));
          if Length(thisTXGrid)>4 Then thisTXGrid := thisTXGrid[1..4];
          Label8.Caption := 'DE ' + thisTXCall + ' in ' + edGrid.Text;
     end;

     If (Length(edPrefix.Text)=0) And (Length(edSuffix.Text)>0) And ((Length(edCall.Text)>2) And (Length(edCall.Text)<7)) And ((Length(getLocalGrid)=4) Or (Length(getLocalGrid)=6)) Then
     Begin
          thisTXcall := TrimLeft(Trimright(UpCase(edCall.Text))) + '/' + TrimLeft(TrimRight(UpCase(edSuffix.Text)));
          thisTXgrid := TrimLeft(TrimRight(UpCase(getLocalGrid)));
          if Length(thisTXGrid)>4 Then thisTXGrid := thisTXGrid[1..4];
          Label8.Caption := 'DE ' + thisTXCall + ' ' + edGrid.Text;
     end;

     If (Length(edPrefix.Text)=0) And (Length(edSuffix.Text)=0) And ((Length(edCall.Text)>2) And (Length(edCall.Text)<7)) And ((Length(getLocalGrid)=4) Or (Length(getLocalGrid)=6)) Then
     Begin
          thisTXcall := TrimLeft(Trimright(UpCase(edCall.Text)));
          thisTXgrid := TrimLeft(TrimRight(UpCase(getLocalGrid)));
          if Length(thisTXGrid)>4 Then thisTXGrid := thisTXGrid[1..4];
          Label8.Caption := 'DE ' + thisTXCall + ' ' + edGrid.Text;
     end;

     { TODO : And canTX with message to TX being valid }
     // canTX is based upon having valid callsign and grid in config & valid message ready to send
     valid := True;
     // Validate prefix (if present)
     if length(edPrefix.Text)>0 Then if not mval.evalPrefix(edPrefix.Text) Then valid := False;
     // Validate callsign
     if not mval.evalCSign(edCall.Text) Then valid := False;
     // Validate suffix (if present)
     if length(edSuffix.Text)>0 Then if not mval.evalSuffix(edSuffix.Text) Then valid := False;
     // Validate grid
     if not mval.evalGrid(edGrid.Text) Then valid := False;
     canTX := valid;
     If canTX Then txControl.Visible := True else txControl.Visible := False;

     { TODO Fix }
     //If txOn Then Label12.Caption := 'PTT:  ON' else Label12.Caption := 'PTT:  OFF';
     //If txOn Then Label12.Font.Color := clRed else Label12.Font.Color := clBlack;

     if not canTX Then
     Begin
          Label16.Caption := 'TX:  DISABLED';
          Label16.Font.Color := clBlack;
     end
     else
     begin
          If globalData.txInProgress Then
          Begin
               Label16.Caption := 'TX:  TRANSMITTING';
               Label16.Font.Color := clRed;
          end
          else
          Begin
               If (rbTXEven.Checked or rbTXOdd.Checked) and canTX  Then
               Begin
                    Label16.Caption := 'TX:  ENABLED';
                    Label16.Font.Color := clBlack;
               end
               else
               begin
                    Label16.Caption := 'TX:  OFF';
                    Label16.Font.Color := clBlack;
               end;
          end;
     end;

     // Enable PTT if necessary
     i := -1;
     If (cbUseSerial.Checked And TryStrToInt(TrimLeft(TrimRight(edPort.Text)),i)) And globalData.txInProgress And (not txOn) Then
     Begin
          // Need to assert PTT
          if (i > 0) And (i<256) Then
          Begin
               //function  ptt(nport : CTypes.pcint; msg : CTypes.pcschar; ntx : CTypes.pcint; iptt : CTypes.pcint) : CTypes.cint; cdecl; external JT_DLL name 'ptt_';
               ioresult := 2;
               msg := 0;
               np := i;
               ntx := 1;
               iptt := 0;
               CTypes.cint(ioresult) := ptt(CTypes.pcint(@np), CTypes.pcschar(@msg), CTypes.pcint(@ntx), CTypes.pcint(@iptt));
               //if ioresult = 0 Then Label17.Caption := 'PTT Status:  Keyed' else Label17.Caption := 'PTT Status:  Disabled';
               if ioresult = 0 Then txOn := True else txOn := False;
               if not txOn then
               begin
                    sleep(100);
               end;
          end;
     end;

     // Unkey PTT if on and should not be.
     i := -1;
     If (TryStrToInt(TrimLeft(TrimRight(edPort.Text)),i)) And txOn And (not globalData.txInProgress) Then
     Begin
          // Need to de-assert PTT
          if (i > 0) And (i<256) Then
          Begin
               //function  ptt(nport : CTypes.pcint; msg : CTypes.pcschar; ntx : CTypes.pcint; iptt : CTypes.pcint) : CTypes.cint; cdecl; external JT_DLL name 'ptt_';
               ioresult := 2;
               msg := 0;
               np := i;
               ntx := 0;
               iptt := 0;
               CTypes.cint(ioresult) := ptt(CTypes.pcint(@np), CTypes.pcschar(@msg), CTypes.pcint(@ntx), CTypes.pcint(@iptt));
               //Label17.Caption := 'PTT Status:  Disabled';
               if ioresult = 0 Then txOn := False else txOn := True;
               if txOn then
               Begin
                    sleep(100);
               end;
          end;
          {TODO Fix}
          //if not txOn Then Label12.Caption := 'PTT is OFF';
          //if not txON Then Label12.Font.Color := clBlack;

          //if not cbUseSerial.Checked Then
          //Begin
               //Label12.Caption := 'PTT is disabled';
               //Label12.Font.Color := clBlack;
          //end;
     end;

     //if inSync and paActive Then RadioGroup1.Visible := True else RadioGroup1.Visible := False;

     if rbOn.Checked then rbOn.Caption := 'Spots sent:  ' + IntToStr(rb.rbCount) else rbOn.Caption := 'RB Enable';
     if length(edRBCall.Text) < 3 Then rbOn.Caption := 'Setup RB Callsign please.';

     if rbOn.Checked and (not rb.rbOn) Then
     Begin
          rb.myCall := TrimLeft(TrimRight(UpCase(edRBCall.Text)));
          rb.myGrid := TrimLeft(TrimRight(edGrid.Text));
          rb.rbInfo := TrimLeft(TrimRight(edStationInfo.Text));
          rb.myQRG  := StrToInt(edDialQRG.Text);
          rb.useRB := True;
          rbping    := True;
     end;

     if useDeciAmerican.Checked then
     begin
          dChar := '.';
          kChar := ',';
     end;
     if useDeciEuro.Checked then
     begin
          dChar := ',';
          kChar := '.';
     end;
     if useDeciAuto.Checked then
     begin
          dChar := DecimalSeparator;
          kChar := ThousandSeparator;
     end;
end;

procedure TForm1.OncePerSecond;
Var
  foo : String;
  i   : Integer;
  //rxb : Packed Array of CTypes.cint16;
Begin
     // Items that run on each new second or selected new seconds

     if (thisSecond = 47) And (lastSecond = 46) And InSync And paActive Then eopQRG := StrToInt(edDialQRG.Text);

     if (thisSecond = 47) And (lastSecond = 46) And InSync And paActive And not decoderBusy Then
     Begin
          // Attempt a decode
          globalData.txInProgress := False;
          if thisUTC.Hour < 10 Then thisTS := '0' + IntToStr(thisUTC.Hour) + ':' else thisTS := IntToStr(thisUTC.Hour) + ':';
          if thisUTC.Minute < 10 Then thisTS := thisTS + '0' + IntToStr(thisUTC.Minute) else thisTS := thisTS + IntToStr(thisUTC.Minute);
          doDecode := True;
     end;

     // Hook for early sync detect.
     //if inSync And paActive Then
     //Begin
     //     if (thisSecond > 14) and (thisSecond < 46) and (thisSecond MOD 5 = 0) Then
     //     Begin
     //          if adc.d65rxBufferIdx > length(adc.d65rxBuffer1)-1 Then
     //          Begin
     //               sleep(1);
     //          end;
     //          i := 0;
     //          while adc.adcRunning do
     //          begin
     //               inc(i);
     //               if i > 25 then break;
     //               sleep(1);
     //          end;
     //          if i < 26 then
     //          begin
     //               setLength(rxb,length(adc.d65rxBuffer1));
     //               if adc.adcChan = 0 Then for i := 0 to length(adc.d65rxBuffer1)-1 do rxb[i] := adc.d65rxBuffer1[i];
     //               if adc.adcChan = 1 Then for i := 0 to length(adc.d65rxBuffer1)-1 do rxb[i] := adc.d65rxBuffer1[i];
     //               if adc.adcChan = 2 Then for i := 0 to length(adc.d65rxBuffer2)-1 do rxb[i] := adc.d65rxBuffer2[i];
     //               for i := adc.d65rxBufferIdx to Length(rxb)-1 do rxb[i] := 0;
     //               i := adc.d65rxBufferIdx;
     //               earlySync(rxb,i);
     //               setLength(rxb,0);
     //          end
     //          else
     //          begin
     //               sleep(1);
     //          end;
     //     end;
     //end;

     foo := '';
     if thisUTC.Month < 10 Then foo := '0' + IntToStr(thisUTC.Month) + '-' else foo := IntToStr(thisUTC.Month) + '-';
     if thisUTC.Day   < 10 Then foo := foo + '0' + IntToStr(thisUTC.Day) + '-' else foo := foo + IntToStr(thisUTC.Day) + '-';
     foo := foo + IntToStr(thisUTC.Year) + '  ';
     if thisUTC.Hour  < 10 Then foo := foo + '0' + IntToStr(thisUTC.Hour) + ':' else foo := foo + IntToStr(thisUTC.Hour) + ':';
     if thisUTC.Minute < 10 Then foo := foo + '0' + IntToStr(thisUTC.Minute) + ':' else foo := foo + IntToStr(thisUTC.Minute) + ':';
     if thisUTC.Second < 10 Then foo := foo + '0' + IntToStr(thisUTC.Second) else foo := foo + IntToStr(thisUTC.Second);
     Label15.Caption :=  foo;

     if (thisSecond = 15) and (thisUTC.Minute MOD 5 = 0) Then
     Begin
          if rbOn.Checked Then
          Begin
               // Update RB Status
               rb.myCall := TrimLeft(TrimRight(UpCase(edRBCall.Text)));
               rb.myGrid := TrimLeft(TrimRight(edGrid.Text));
               rb.rbInfo := TrimLeft(TrimRight(edStationInfo.Text));
               rb.myQRG  := StrToInt(edDialQRG.Text);
               rb.useRB := True;
               rbping    := True;
          end
          else
          begin
               rb.myCall := TrimLeft(TrimRight(UpCase(edRBCall.Text)));
               rb.myGrid := TrimLeft(TrimRight(edGrid.Text));
               rb.rbInfo := TrimLeft(TrimRight(edStationInfo.Text));
               rb.myQRG  := StrToInt(edDialQRG.Text);
               rb.useRB  := False;
               rbping    := False;
          end;
     end;

     if (thisSecond mod 15 = 0) and catFree Then
     Begin
          // Run a rig control cycle
          forceCAT  := False;
          readQRG   := True;
          if rigNone.Checked Then catMethod := 'None';
          if rigRebel.Checked Then catMethod := 'Rebel';
          //if rigCommander.Checked Then catMethod := 'Commander';
          doCAT     := True;
     end;

     if (thisSecond = 51) and (lastSecond = 50) Then
     Begin
          Try
             // Paint a line for second = 51
             for i := 0 to 749 do
             Begin
                  spectrum.specDisplayData[0][i].r := 255;
                  spectrum.specDisplayData[0][i].g := 0;
                  spectrum.specDisplayData[0][i].b := 0;
             end;
             // Probably will eventually remove the following line... here for PageControl for now.
          except
             ListBox2.Items.Insert(0,'Exception in paint line (2)');
          end;
     end;

     if (thisSecond = 0) and (lastSecond = 59) Then
     Begin
          sopQRG := StrToInt(edDialQRG.Text);
          Try
             // Paint a line for second = 59 and 0
             for i := 0 to 749 do
             Begin
                  spectrum.specDisplayData[0][i].r := 0;
                  spectrum.specDisplayData[0][i].g := 255;
                  spectrum.specDisplayData[0][i].b := 0;
             end;
             // Probably will eventually remove the following line... here for PageControl for now.
          except
             ListBox2.Items.Insert(0,'Exception in paint line (2)');
          end;
     end;
end;

procedure TForm1.OncePerMinute;
Var
  //foo       : String;
  i         : Integer;
  //paResult  : TPaError;
Begin
     // Items that run once per minute at new minute start
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
     // RX to index = 0
     adc.d65rxBufferIdx := 0;
     if not inSync Then
     Begin
          inSync := True;
          ListBox2.Items.Insert(0,'Timing loop now in sync');
     end;
     // TX to index = 0
     //dac.d65txBufferIdx := 0;
     FBar1.Clear;

     // Set flag for TX ability
     //txperiod       : Integer; // 1 = Odd 0 = Even
     //couldtx        : Boolean; // If one could TX this period (it matches even/odd selection)
     couldtx := False;
     if (txperiod = 1) and Odd(thisUTC.Minute) Then couldtx := True;
     if (txperiod = 0) and not Odd(thisUTC.Minute) Then couldtx := True;

     // Enable TX if necessary
     if (rbTXEven.Checked or rbTXOdd.Checked) and (not globalData.txInProgress) and inSync Then
     Begin
          i := -9999;
          if not tryStrToInt(TrimLeft(TrimRight(edTXDF.Text)),i) Then i := 0;
          if i > 1000 then i := 1000;
          if i < -1000 then i := -1000;
          edTXDF.Text := IntToStr(i);
          //foo := TrimLeft(TrimRight(UpCase(edTXMsg.Text)));
          //genTX(foo,i,gTXLevel,dac.d65txBuffer);
          globalData.txInProgress := False;

          {
          TODO : FIX this - it's not quite right :)
          I need to remove rbTXOff and have a control that enables/disable TX as I can't
          base TX on/off status on simply the period being checked.  Figure this out ASAP
          }

          //if rbTXEven.Checked and (not Odd(thisUTC.Minute)) and (not globalData.txInProgress) Then
          //Begin
               //globalData.txInProgress := True;
          //end;
          //if rbTXOdd.Checked and Odd(thisUTC.Minute) and (not globalData.txInProgress) Then
          //Begin
               //globalData.txInProgress := True;
               //genTX(foo,i,gTXLevel,dac.d65txBuffer);
          //end;
     end;

     if ListBox1.Items.Count > 250 Then
     Begin
          Try
             for i := ListBox1.Items.Count-1 downto 99 do
             begin
                  ListBox1.Items.Delete(i);
             end;
             //ListBox2.Items.Insert(0,'Ran prune list');
          except
             ListBox2.Items.Insert(0,'Exception in prune list');
          end;
     end;

     Try
        if spectrum.specagc > 0 Then spectrum.specagc := 0;
     Except
        ListBox2.Items.Insert(0,'Exception in reset agc');
     end;

     //// Populate predefined QRG list
     //comboQRGList.Clear;
     //dataqrg.DataSet.First;
     //for i := 0 to dataqrg.DataSet.RecordCount - 1 do
     //begin
     //     comboQRGList.Items.Add(dataqrg.DataSet.FieldValues['FQRG']);
     //     dataqrg.DataSet.Next;
     //end;
     //
     //// Populate Macro list
     //comboMacroList.Clear;
     //datamacro.DataSet.First;
     //for i := 0 to datamacro.DataSet.RecordCount - 1 do
     //begin
     //     comboMacroList.Items.Add(datamacro.DataSet.FieldValues['TEXT']);
     //     datamacro.DataSet.Next;
     //end;

     if rb.errLog.Count > 0 Then for i := 0 to rb.errLog.Count-1 do Memo1.Append(rb.errlog.Strings[i]);
     rb.clearErr;



end;

procedure TForm1.periodicSpecial;
Begin

end;

procedure TForm1.adcdacTick;
Begin
     // Events triggered from ADC/DAC callback counter change
     // Compute spectrum and audio levels.
     if adc.haveAU And (not demodulate.dmdemodBusy) Then
     Begin
          if adc.adcMono Then
          Begin
               //if aulevel = 0 Then aulevel := spectrum.computeAudio(adc.adclast2k1) else aulevel := (aulevel + spectrum.computeAudio(adc.adclast2k1)) div 2;
               aulevel := spectrum.computeAudio(adc.adclast2k1);
               Label108.Caption := IntToStr(Trunc((aulevel*0.4)-20)) + 'dB';
               Label78.Caption := 'Mono:';
               Label3.Caption := 'Audio Level';
               Label107.Visible := False;
               Label109.Visible := False;
          end
          else
          begin
               //if aulevel1 = 0 Then aulevel1 := spectrum.computeAudio(adc.adclast2k1) else aulevel1 := (aulevel1 + spectrum.computeAudio(adc.adclast2k1)) div 2;
               aulevel1 := spectrum.computeAudio(adc.adclast2k1);
               Label108.Caption := IntToStr(Trunc((aulevel1*0.4)-20)) + 'dB';
               //if aulevel2 = 0 Then aulevel2 := spectrum.computeAudio(adc.adclast2k2) else aulevel2 := (aulevel2 + spectrum.computeAudio(adc.adclast2k2)) div 2;
               aulevel2 := spectrum.computeAudio(adc.adclast2k1);
               Label109.Caption := IntToStr(Trunc((aulevel2*0.4)-20)) + 'dB';
               Label3.Caption := 'Audio Levels';
               Label78.Caption := 'Left:';
               Label107.Visible := True;
               Label109.Visible := True;
          end;
          // sLevel = 50 = 0dB sLevel 0 = -20dB sLevel 100 = 20dB
          // 1 sLevel = .4dB
          // db = (sLevel*0.4)-20
          adc.haveAU := False;
     end;

     If adc.haveSpec And (not demodulate.dmdemodBusy) Then
     Begin
          // Can do spectrum...
          if adc.adcMono Then
          Begin
               spectrum.computeSpectrum(adc.adclast4k1);
          end
          else
          begin
               if adc.adcChan = 1 Then spectrum.computeSpectrum(adc.adclast4k1) else spectrum.computeSpectrum(adc.adclast4k2);
          end;
          adc.haveSpec := False;
     end;
end;

function TForm1.asBand(const qrg : Integer) : Integer;
Begin
     // QRG is in hertz.
     result := 0;
     if (qrg >   1800000-1) and (qrg < 2000001)   then result := 160;
     if (qrg >   3500000-1) and (qrg < 4000001)   then result := 80;
     if (qrg >   7000000-1) and (qrg < 7350001)   then result := 40;
     if (qrg >  10100000-1) and (qrg < 10150001)  then result := 30;
     if (qrg >  14000000-1) and (qrg < 14400001)  then result := 20;
     if (qrg >  18068000-1) and (qrg < 18168001)  then result := 17;
     if (qrg >  21000000-1) and (qrg < 21450001)  then result := 15;
     if (qrg >  24890000-1) and (qrg < 24990001)  then result := 12;
     if (qrg >  28000000-1) and (qrg < 29700001)  then result := 10;
     if (qrg >  50000000-1) and (qrg < 54000001)  then result := 6;
     if (qrg > 144000000-1) and (qrg < 148000001) then result := 2;
     if qrg > 148000000 then result := 1;
end;

procedure TForm1.displayDecodes;
Var
   i,j,k    : Integer;
   dstrings : TStringList;
   removes  : Array of Integer;
   afoo     : String;
   bfoo     : String;
   cfoo     : String;
   srec     : Spot.spotRecord;
   tvalid   : Boolean;
   dcount   : Integer;
Begin
     //if not demodulate.dmdemodBusy And (demodulate.dmprofile.Count > 0) Then
     //Begin
     //     for i := 0 to demodulate.dmprofile.Count-1 do Memo2.Append(demodulate.dmprofile.Strings[i]);
     //     Memo2.Append('--------------------');
     //     demodulate.dmprofile.Clear;
     //end;

     memo3.Clear;
     for i := 0 to 499 do if length(demodulate.dmlastraw[i])>0 Then memo3.Append(demodulate.dmlastraw[i]);
     dcount := 0;
     //ListBox2.Items.Insert(0,'Enter display decodes');
     // Remove any duplicates and/or image decodes.
     j := 0;
     for i := 0 to 499 do if not demodulate.dmdecodes[i].clr Then inc(j);
     //if j=1 then showmessage('j=1');
     if j > 1 Then
     Begin
          SetLength(removes,j);
          dstrings := TStringList.Create;
          dstrings.Clear;
          dstrings.CaseSensitive := False;
          dstrings.Sorted := False;
          dstrings.Duplicates := Types.dupAccept;
          k := 0;
          for i := 0 to 499 do
          begin
               if not demodulate.dmdecodes[i].clr Then
               begin
                    // The input stringist contains db,exchange,index of array member
                    dstrings.Add(demodulate.dmdecodes[i].db + ',' + demodulate.dmdecodes[i].dec + ',' + IntToStr(k));
                    removes[k] := i;
                    inc(k);
               end;
          end;
          removeDupes(dstrings,removes);
          dstrings.Destroy;
          for i := 0 to length(removes) - 1 do if removes[i] > -1 Then demodulate.dmdecodes[removes[i]].clr := True;
          SetLength(removes,0);
     End;
     // Have decode results - display them.
     // Delete any impossible decodes like signal < -30
     for i := 0 to 499 do
     begin
          if not demodulate.dmdecodes[i].clr Then
          Begin
               k := Abs(StrToInt(demodulate.dmdecodes[i].db));
               if k > 30 Then
               Begin
                    Memo1.Append('Skipped:  ' + demodulate.dmdecodes[i].db + ',' + demodulate.dmdecodes[i].dec);
                    demodulate.dmdecodes[i].clr := True;
               end;
               k := Abs(StrToInt(demodulate.dmdecodes[i].sync));
               if k < 1 Then
               Begin
                    Memo1.Append('Skipped:  ' + demodulate.dmdecodes[i].db + ',' + demodulate.dmdecodes[i].dec);
                    demodulate.dmdecodes[i].clr := True;
               end;
          end;
     end;
     k := 0;
     for i := 0 to 499 do if not demodulate.dmdecodes[i].clr Then inc(k);
     If k>0 Then
     Begin
          if cbDivideDecodes.Checked Then ListBox1.Items.Insert(0,'------------------------------------------------------------');
          for i := 0 to 499 do
          begin
               if not demodulate.dmdecodes[i].clr Then
               Begin
                    inc(dcount);
                    // Adjust the decimal point to what it "should" be for user's display.
                    afoo := demodulate.dmdecodes[i].dt;
                    bfoo := ExtractWord(1,afoo,[',','.']);
                    cfoo := ExtractWord(2,afoo,[',','.']);
                    afoo := bfoo + dChar + cfoo;
                    avgdt := StrToFloat(afoo) + avgdt;
                    if demodulate.dmdecodes[i].ec = 'K' then inc(kvcount);
                    if demodulate.dmdecodes[i].ec = 'B' then inc(bmcount);
                    if demodulate.dmdecodes[i].ver = '1' Then inc(v1c);
                    if demodulate.dmdecodes[i].ver = '2' Then inc(v2c);
                    if demodulate.dmdecodes[i].sf = 'S' Then inc(msc);
                    if demodulate.dmdecodes[i].sf = 'F' Then inc(mfc);
                    if not ((demodulate.dmdecodes[i].nc1 = 0) And (demodulate.dmdecodes[i].nc2 = 0) And (demodulate.dmdecodes[i].ng = 0)) Then
                    Begin
                         if demodulate.dmdecodes[i].sf = 'S' Then
                         Begin
                              ListBox1.Items.Insert(0, demodulate.dmdecodes[i].utc + ' ' + demodulate.dmdecodes[i].sync + ' ' + demodulate.dmdecodes[i].db + ' ' + afoo + ' ' + demodulate.dmdecodes[i].df + '  ' + demodulate.dmdecodes[i].ec + '  ' + demodulate.dmdecodes[i].dec);
                              tvalid := False;
                              breakOutFields(demodulate.dmdecodes[i].utc + ' ' + demodulate.dmdecodes[i].sync + ' ' + demodulate.dmdecodes[i].db + ' ' + afoo + ' ' + demodulate.dmdecodes[i].df + '  ' + demodulate.dmdecodes[i].ec + '  ' + demodulate.dmdecodes[i].dec, tvalid);
                              if not tvalid then inc(pfails);
                              //if not tvalid then Label119.Caption := IntToStr(pfails);
                              if not tvalid then
                              Begin
                                   Memo1.Append('Failed to build - input:  ' + demodulate.dmdecodes[i].utc + ' ' + demodulate.dmdecodes[i].sync + ' ' + demodulate.dmdecodes[i].db + ' ' + afoo + ' ' + demodulate.dmdecodes[i].df + '  ' + demodulate.dmdecodes[i].ec + '  ' + demodulate.dmdecodes[i].dec);
                              end;
                              if demodulate.dmdecodes[i].ver = '2' Then
                              Begin
                                   // Diag dump the V2 string so I can track who's using V2! :)
                                   Memo1.Append('V2 Frame:  ' + demodulate.dmdecodes[i].utc + ' ' + demodulate.dmdecodes[i].sync + ' ' + demodulate.dmdecodes[i].db + ' ' + afoo + ' ' + demodulate.dmdecodes[i].df + '  ' + demodulate.dmdecodes[i].ec + '  ' + demodulate.dmdecodes[i].dec);
                              end;
                         end
                         else
                         begin
                              ListBox1.Items.Insert(0, demodulate.dmdecodes[i].utc + ' ' + demodulate.dmdecodes[i].sync + ' ' + demodulate.dmdecodes[i].db + ' ' + afoo + ' ' + demodulate.dmdecodes[i].df + '  ' + demodulate.dmdecodes[i].ec + '  ' + demodulate.dmdecodes[i].dec);
                         end;
                         if (rbOn.Checked) And (sopQRG = eopQRG) And (StrToInt(edDialQRG.Text) > 0) Then
                         Begin
                              // Post to RB
                              // Adjust the decimal point to what it "should" be. And here is should be .
                              afoo := bfoo + '.' + cfoo;
                              srec.qrg      := StrToInt(edDialQRG.Text);
                              srec.date     := TrimLeft(TrimRight(demodulate.dmdecodes[i].ts));
                              srec.time     := '';
                              srec.sync     := StrToInt(TrimLeft(TrimRight(demodulate.dmdecodes[i].sync)));
                              srec.db       := StrToInt(TrimLeft(TrimRight(demodulate.dmdecodes[i].db)));
                              srec.dt       := TrimLeft(TrimRight(afoo));
                              srec.df       := StrToInt(TrimLeft(TrimRight(demodulate.dmdecodes[i].df)));
                              srec.decoder  := TrimLeft(TrimRight(demodulate.dmdecodes[i].ec));
                              srec.decoder  := srec.decoder[1];
                              srec.exchange := TrimLeft(TrimRight(demodulate.dmdecodes[i].dec));
                              srec.mode     := '65A';
                              srec.rbsent   := False;
                              srec.dbfsent  := False;
                              rb.addSpot(srec);
                              inc(rbposted);
                         end;
                    end;
                    // Free record for demodulator's use next round.
                    //ListBox2.Items.Insert(0,'Cleared dmdecodes:  ' + IntToStr(i));
                    demodulate.dmdecodes[i].clr := True;
               end;
          end;
          demodulate.dmhaveDecode := False;
          if cbCompactDivides.Checked and cbDivideDecodes.Checked Then
          Begin
               // Remove extra --- divider lines
               j := 0;
               for i := 0 to ListBox1.Items.Count-1 do if ListBox1.Items.Strings[i] = '------------------------------------------------------------' Then inc(j);
               if j>1 then
               Begin
                    for i := ListBox1.Items.Count-1 downto 0 do
                    begin
                         if ListBox1.Items.Strings[i] = '------------------------------------------------------------' Then
                         Begin
                              ListBox1.Items.Delete(i);
                              dec(j);
                              if j < 2 Then break;
                         end;
                    end;
               end;
          end;
     end;
     k := 0;
     for i := 0 to 499 do if not demodulate.dmdecodes[i].clr Then inc(k);
     If k>0 Then Memo1.Append('Items not cleared at end of display pass - this is wrong.');
end;

function  TForm1.db(x : CTypes.cfloat) : CTypes.cfloat;
Begin
     Result := -99.0;
     if x > 1.259e-10 Then Result := 10.0 * log10(x);
end;

procedure TForm1.tbMultiBinChange(Sender: TObject);
begin
     If tbMultiBin.Position = 1 then demodulate.dmbw := 20;
     If tbMultiBin.Position = 2 then demodulate.dmbw := 50;
     If tbMultiBin.Position = 3 then demodulate.dmbw := 100;
     If tbMultiBin.Position = 4 then demodulate.dmbw := 200;
     Label26.Caption := 'Multi ' + IntToStr(demodulate.dmbw) + ' Hz';
end;

procedure TForm1.tbSingleBinChange(Sender: TObject);
begin
     If tbSingleBin.Position = 1 then demodulate.dmbws := 20;
     If tbSingleBin.Position = 2 then demodulate.dmbws := 50;
     If tbSingleBin.Position = 3 then demodulate.dmbws := 100;
     If tbSingleBin.Position = 4 then demodulate.dmbws := 200;
     Label87.Caption := 'Single ' + IntToStr(demodulate.dmbws) + ' Hz';
end;

procedure TForm1.tbTXLevelChange(Sender: TObject);
Var
   i   : CTypes.cint;
begin
     txLevel.Text := IntToStr(tbTXLevel.Position);
     Label1.Caption := 'TX Level:  ' + IntToStr(Trunc(6.25 * tbTXLevel.Position)) +'%';
     gTXLevel := tbTXLevel.Position * 2048;
     i := -9999;
     if not tryStrToInt(TrimLeft(TrimRight(edTXDF.Text)),i) Then i := 0;
     if i > 1000 then i := 1000;
     if i < -1000 then i := -1000;
     //foo := TrimLeft(TrimRight(UpCase(edTXMsg.Text)));
     //genTX(foo,i,gTXLevel,dac.d65txBuffer);
end;

function  TForm1.gText(const msg : String; var nc1 : LongWord; var nc2 : LongWord; var ng : LongWord) : Boolean;
Var
   cs  : Array[1..42] Of Char;
   foo : String;
   i,j : Integer;
   b   : Boolean;
Begin
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

     foo := UpCase(TrimLeft(TrimRight(msg)));
     foo := PadRight(foo,13);
     result := False;
     nc1 := 0;
     nc2 := 0;
     ng  := 0;
     b   := False;

     for i := 1 to 5 do
     Begin
          for j := 1 to 43 do
          Begin
               if j < 43 Then
               Begin
                    if foo[i] = cs[j] Then Break;
               end;
          end;
          if j < 43 Then
          begin
               b := False;
               dec(j);
               nc1 := 42 * nc1 + LongWord(j);
          end
          else
          begin
               b := True;
               break;
          end;
     end;

     if not b then
     begin
          // First 5 ok and in nc1 now to next 5 into nc2
          for i := 6 to 10 do
          Begin
               for j := 1 to 43 do
               Begin
                    if j < 43 Then
                    Begin
                         if foo[i] = cs[j] Then Break;
                    end;
               end;
               if j < 43 Then
               begin
                    b := False;
                    dec(j);
                    nc2 := 42 * nc2 + LongWord(j);
               end
               else
               begin
                    b := True;
                    break;
               end;
          end;
     end;

     if not b then
     begin
          // First 10 ok and in nc1/nc2 now to last 3 into ng
          for i := 11 to 13 do
          Begin
               for j := 1 to 43 do
               Begin
                    if j < 43 Then
                    Begin
                         if foo[i] = cs[j] Then Break;
                    end;
               end;
               if j < 43 Then
               begin
                    b := False;
                    dec(j);
                    ng := 42 * ng + LongWord(j);
               end
               else
               begin
                    b := True;
                    break;
               end;
          end;
     end;

     if not b then
     Begin
          // Characters mapped, now need to shuffle a few bits to make things fit in 28, 28 and 16 bits nc1, nc2, ng
          nc1 := nc1 + nc1;
          nc2 := nc2 + nc2;
          if (ng and 32768) > 0 Then inc(nc1);
          if (ng and 65536) > 0 Then inc(nc2);
          ng  := ng And 32767;
     End;

     if (nc1>268435455) Or (nc2>268435455) Then
     Begin
          b := True;
     end;

     // Invlaid character found or overflow in nc1 or nc2.
     if b then
     Begin
          nc1 := 0;
          nc2 := 0;
          ng  := 0;
          Result := False;
     End
     Else
     Begin
          Result := True;
          ng := ng Or 32768;  // Set bit 16
     end;

end;

function  TForm1.gSyms(const nc1 : LongWord; const nc2 : LongWord; const ng : LongWord; var   syms : Array Of Integer) : Boolean;
Var
   i : Integer;
Begin
     // Takes the values in nc1, nc2 and ng returning 12 6 bit channel symbols in syms[1..12] and true/false as conversion status.
     // NC1/NC2 allowed range is 0 ... 268,435,455 (2^28 - 1)
     // NG      allowed range is 0 ... 32768
     // Syms[x] allowed range is 0 ... 63 (2^6 - 1)
     Result := False;
     for i := 0 to 11 do syms[i]  := 0;

     syms[0]  := (nc1 shr 22) And 63;              // Highest 6 bits of nc1
     syms[1]  := (nc1 shr 16) And 63;              // Next   6 bits of nc1
     syms[2]  := (nc1 shr 10) And 63;              // Next   6 bits of nc1
     syms[3]  := (nc1 shr  4) And 63;              // Next   6 bits of nc1

     syms[4]  := 4*(nc1 And 15);                   // Lowest 4 bits of nc1
     syms[4]  := ((nc2 shr 26) And 3) + LongWord(syms[4]);   // Plus highest 2 bits of nc2

     syms[5]  := (nc2 shr 20) And 63;              // Next   6 bits of nc2
     syms[6]  := (nc2 shr 14) And 63;              // Next   6 bits of nc2
     syms[7]  := (nc2 shr  8) And 63;              // Next   6 bits of nc2
     syms[8]  := (nc2 shr  2) And 63;              // Next   6 bits of nc2

     syms[9] := 16*((nc2) And 3);                  // Lowest 2 bits of nc2
     syms[9] := ((ng shr 12) And 15) + LongWord(syms[9]);      // Plus highest 4 bits of ng

     syms[10] := (ng  shr  6) And 63;              // Next   6 bits of ng
     syms[11] := ng And 63;                        // Lowest 6 bits of ng

     // Total bits converted = 72

     Result := True;
     for i := 0 to 11 do if (syms[i] < 0) or (syms[i] > 63) Then result := False;
end;

procedure TForm1.gGrid(const Grid : String; var v1ng : LongWord);
Var
   wgrid : PChar;
   ng   : CTypes.cint;
   txt : CTypes.cbool;
Begin
     wgrid := StrAlloc(5);
     wgrid := PChar(Grid);
     ng := 0;
     txt := False;
     packgrid(PChar(wgrid),CTypes.pcint(@ng),CTypes.pcbool(@txt));
     v1ng := LongWord(ng);
     wgrid := StrAlloc(0);
end;

function  TForm1.gCall(const Call : String) : LongWord;
Var
   foo : String;
   ci  : Array[1..6] Of LongWord;
   ct  : LongWord;
   i,j : Integer;
Begin
     foo := TrimLeft(TrimRight(UpCase(Call)));
     // Prepend with space if character 2 is numeric
     i := 0;
     if tryStrToInt(foo[2],i) Then foo := ' ' + foo;
     // Pad right to 6 characters
     foo := PadRight(foo,6);
     i := Length(foo);
     // Map ASCII input characters to JT65 character value 0...36
     for i := 1 to 6 do
     begin
          if tryStrToInt(foo[i],j) Then
          Begin
               // This character is numeric
               //ci[i] := ord(foo[i]) - ord('0');
               ci[i] := j;
          end
          else
          begin
               // This character is alpha
               if foo[i] = ' ' then
               Begin
                    // Handler for space characters
                    ci[i] := 36;
               end
               else
               begin
                    j := ord(foo[i]) - ord('A') + 10;
                    ci[i] := j;
               end;
          end;
     end;
     // Compute nc based upon ASCII character to JT65 value for same.
     ct := 0;
     ct := ci[1];
     ct := 36 * ct + ci[2];
     ct := 10 * ct + ci[3];
     ct := 27 * ct + LongWord(ci[4])-10;
     ct := 27 * ct + LongWord(ci[5])-10;
     ct := 27 * ct + LongWord(ci[6])-10;
     result := ct;
end;

function  TForm1.gPrefix(const form : String; const pfx : String) : LongWord;
Var
   foo : String;
   cp  : Array[1..4] Of LongWord;
   ct  : LongWord;
   i,j : Integer;
Begin
     // Takes form as CQ, DE or QRZ and pfx as 1...4 character string returning value of 0 ... 1,823,507 if valid or 268,435,455 if invalid.
     foo := TrimLeft(TrimRight(UpCase(pfx)));
     if Length(foo) < 1 Then
     Begin
          result := 268435455;
          if form = 'CQ'  Then Result := 262177561;
          if form = 'QRZ' Then Result := 262177562;
          if form = 'DE'  Then Result := 267796945;
     end
     else
     Begin
          foo := PadRight(foo,4);
          // String formatted for case and length -- convert.
          // Prefix support using rule of 36 * 37 * 37 * 37

          for i := 1 to 4 do cp[i] := 0;
          ct := 0;
          i  := 0;
          j  := 0;

          for i := 1 to Length(foo) do
          begin
               if tryStrToInt(foo[i],j) Then
               Begin
                    cp[i] := j;
               end
               else
               begin
                    if foo[i] = ' ' then cp[i] := 36 else cp[i] := ord(foo[i]) - ord('A') + 10;
               end;
          end;
          ct := 0;
          ct := cp[1];
          ct := 37 * ct + cp[2];
          ct := 37 * ct + cp[3];
          ct := 37 * ct + cp[4];

          // CQ  (No Prefix/Suffix) 262,177,561
          // QRZ (No Prefix/Suffix) 262,177,562
          //
          // CQ ### (No Prefix/Suffix) 262,177,563 ... 262,178,562
          //
          // CQ  with Prefix 262,178,563 ... 264,002,071
          // QRZ with Prefix 264,002,072 ... 265,825,580
          // DE  with Prefix 265,825,581 ... 267,649,089
          //
          // CQ  with Suffix 267,649,090 ... 267,698,374
          // QRZ with Suffix 267,698,375 ... 267,747,659
          // DE  with Suffix 267,747,660 ... 267,796,944
          //
          // DE (No Prefix/Suffix) 267,796,945

          if form = 'CQ'  Then result := 262178563 + ct;
          if form = 'QRZ' Then result := 264002072 + ct;
          if form = 'DE'  Then result := 265825581 + ct;

          if not ((form='CQ') or (form='QRZ') or (form='DE')) then result := 268435455;
     end;
end;

function  TForm1.gSuffix(const form : String; const sfx : String) : LongWord;
Var
   foo : String;
   cs  : Array[1..3] Of LongWord;
   ct  : LongWord;
   i,j : Integer;
Begin
     // Takes form as CQ, DE or QRZ and sfx as 1...3 character string returning value of 0 ... 49,283 if valid or 268,435,455 if invalid.
     foo := TrimLeft(TrimRight(UpCase(sfx)));
     if Length(foo) < 1 Then
     Begin
          result := 268435455;
          if form = 'CQ'  Then Result := 262177561;
          if form = 'QRZ' Then Result := 262177562;
          if form = 'DE'  Then Result := 267796945;
     end
     else
     Begin
          foo := PadRight(foo,3);
          // Have Suffix
          // Support using rule of 36 * 37 * 37
          for i := 1 to 3 do cs[i] := 0;

          ct := 0;
          i  := 0;
          j  := 0;

          for i := 1 to Length(foo) do
          begin
               if tryStrToInt(foo[i],j) Then
               Begin
                    cs[i] := j;
               end
               else
               begin
                    if foo[i] = ' ' then cs[i] := 36 else cs[i] := ord(foo[i]) - ord('A') + 10;
               end;
          end;

          ct := 0;
          ct := cs[1];
          ct := 37 * ct + cs[2];
          ct := 37 * ct + cs[3];

          // CQ  (No Prefix/Suffix) 262,177,561
          // QRZ (No Prefix/Suffix) 262,177,562
          //
          // CQ ### (No Prefix/Suffix) 262,177,563 ... 262,178,562
          //
          // CQ  with Prefix 262,178,563 ... 264,002,071
          // QRZ with Prefix 264,002,072 ... 265,825,580
          // DE  with Prefix 265,825,581 ... 267,649,089
          //
          // CQ  with Suffix 267,649,090 ... 267,698,374
          // QRZ with Suffix 267,698,375 ... 267,747,659
          // DE  with Suffix 267,747,660 ... 267,796,944
          //
          // DE (No Prefix/Suffix) 267,796,945

          if form = 'CQ'  Then result := 267649090 + ct;
          if form = 'QRZ' Then result := 267698375 + ct;
          if form = 'DE'  Then result := 267747660 + ct;

          if not ((form='CQ') or (form='QRZ') or (form='DE')) then result := 268435455;

     end;
end;

function  TForm1.isLetter(c : Char) : Boolean;
Var
   i : Integer;
Begin
     i := 0;
     if TryStrToInt(c,i) Then
     Begin
          Result := False;
     end
     else
     begin
          case c of 'A'..'Z': Result := True else Result := False; end;
     end;
end;

function  TForm1.isGLLetter(c : Char) : Boolean;
Var
   i : Integer;
Begin
     i := 0;
     if TryStrToInt(c,i) Then
     Begin
          Result := False;
     end
     else
     begin
          case c of 'A'..'R': Result := True else Result := False; end;
     end;
end;

function  TForm1.isDigit(c : Char) : Boolean;
Var
   i : Integer;
Begin
     i := 0;
     if TryStrToInt(c,i) Then
     Begin
          Result := True;
     end
     else
     begin
          Result := False;
     end;
end;

function TForm1.isSText(c : String) : Boolean;
Var
   foo : String;
   i   : Integer;
Begin
     // Validates a string as only containing characters in the JT65 structured text character set
     Result := True;
     foo := UpCase(TrimLeft(TrimRight(c)));
     for i := 1 To Length(foo) do
     Begin
          if (not isLetter(foo[i])) And (not isDigit(foo[i])) Then Result := False;
          if not Result Then
          Begin
               if (foo[i] = '/') or (foo[i] = ' ' ) or (foo[i] = '-') Then Result := True;
          end;
          if not result then break;
     end;
end;

function TForm1.isFText(c : String) : Boolean;
Var
   foo : String;
   i   : Integer;
   a   : Char;
Begin
     // Validates a string as only containing characters in the JT65 free text character set
     Result := True;
     foo := UpCase(TrimLeft(TrimRight(c)));
     for i := 1 to Length(foo) do
     begin
          a := foo[i];
          case a of 'A'..'Z': Result := True else Result := False; end;
          if not result then case a of '0'..'9': Result := True else Result := False; end;
          if not result then case a of '+': Result := True else Result := False; end;
          if not result then case a of '-': Result := True else Result := False; end;
          if not result then case a of '.': Result := True else Result := False; end;
          if not result then case a of '/': Result := True else Result := False; end;
          if not result then case a of '?': Result := True else Result := False; end;
          if not result then case a of ' ': Result := True else Result := False; end;
          if not result then break;
     end;
end;

{ TODO : breakOutFields can -eventually- go away - it's here for testing - mgen is the real thing. }

procedure TForm1.breakOutFields(const msg : String; var mvalid : Boolean);
Var
  foo       : String;
  exchange  : exch;
  i,wc      : Integer;
  isiglevel : Integer;
  gonogo    : Boolean;
  toparse   : String;
  isValid   : Boolean;
  isBreakIn : Boolean;
  level     : Integer;
  response  : String;
  connectTo : String;
  fullCall  : String;
  hisGrid   : String;
Begin
     mvalid   := False;
     gonogo   := False;
     isValid  := False;
     // Get the decode to parse
     foo := msg;
     foo := DelSpace1(foo);
     foo := StringReplace(foo,' ',',',[rfReplaceAll,rfIgnoreCase]);

     // Now with a structured message I'll have...
     // UTC, Sync, dB, DT, DF, EC, NC1, Call FROM, MSG
     // Where NC1 is one of [CQ, CQ ###, QRZ, DE, CALLSIGN]
     // Where MSG is one of [Grid,-##,R-##,RRR,RO,73]

     // First check is for first two characters to be numeric AND wordcount
     // = 9 or 10.  10 Handles case of a CQ ### format (not seen on HF, but...)
     // If not wc = 9 or 10 then it's not something to parse here.
     i := 0;
     wc := wordcount(foo,[',']);
     if (wc=8) or (wc=9) or (wc=10) Then
     Begin
          if wc=8 Then
          Begin
               // Parse string into parts (8 word exchange)
               exchange.utc  := TrimLeft(TrimRight(UpCase(ExtractWord(1,foo,[',']))));
               exchange.sync := TrimLeft(TrimRight(UpCase(ExtractWord(2,foo,[',']))));
               exchange.db   := TrimLeft(TrimRight(UpCase(ExtractWord(3,foo,[',']))));
               exchange.dt   := TrimLeft(TrimRight(UpCase(ExtractWord(4,foo,[',']))));
               exchange.df   := TrimLeft(TrimRight(UpCase(ExtractWord(5,foo,[',']))));
               exchange.ec   := TrimLeft(TrimRight(UpCase(ExtractWord(6,foo,[',']))));
               exchange.nc1  := TrimLeft(TrimRight(UpCase(ExtractWord(7,foo,[',']))));
               exchange.nc1s := '';
               exchange.nc2  := TrimLeft(TrimRight(UpCase(ExtractWord(8,foo,[',']))));
               exchange.ng   := '';
          end;
          if wc=9 Then
          Begin
               // Parse string into parts (9 word exchange)
               exchange.utc  := TrimLeft(TrimRight(UpCase(ExtractWord(1,foo,[',']))));
               exchange.sync := TrimLeft(TrimRight(UpCase(ExtractWord(2,foo,[',']))));
               exchange.db   := TrimLeft(TrimRight(UpCase(ExtractWord(3,foo,[',']))));
               exchange.dt   := TrimLeft(TrimRight(UpCase(ExtractWord(4,foo,[',']))));
               exchange.df   := TrimLeft(TrimRight(UpCase(ExtractWord(5,foo,[',']))));
               exchange.ec   := TrimLeft(TrimRight(UpCase(ExtractWord(6,foo,[',']))));
               exchange.nc1  := TrimLeft(TrimRight(UpCase(ExtractWord(7,foo,[',']))));
               exchange.nc1s := '';
               exchange.nc2  := TrimLeft(TrimRight(UpCase(ExtractWord(8,foo,[',']))));
               exchange.ng   := TrimLeft(TrimRight(UpCase(ExtractWord(9,foo,[',']))));
          End;
          if wc=10 Then
          Begin
               // Parse string into parts (10 word exchange)
               exchange.utc  := TrimLeft(TrimRight(UpCase(ExtractWord(1,foo,[',']))));
               exchange.sync := TrimLeft(TrimRight(UpCase(ExtractWord(2,foo,[',']))));
               exchange.db   := TrimLeft(TrimRight(UpCase(ExtractWord(3,foo,[',']))));
               exchange.dt   := TrimLeft(TrimRight(UpCase(ExtractWord(4,foo,[',']))));
               exchange.df   := TrimLeft(TrimRight(UpCase(ExtractWord(5,foo,[',']))));
               exchange.ec   := TrimLeft(TrimRight(UpCase(ExtractWord(6,foo,[',']))));
               exchange.nc1  := TrimLeft(TrimRight(UpCase(ExtractWord(7,foo,[',']))));
               exchange.nc1s := TrimLeft(TrimRight(UpCase(ExtractWord(8,foo,[',']))));
               exchange.nc2  := TrimLeft(TrimRight(UpCase(ExtractWord(9,foo,[',']))));
               exchange.ng   := TrimLeft(TrimRight(UpCase(ExtractWord(10,foo,[',']))));
          End;

          i := 0;
          if TryStrToInt(exchange.utc[1..2],i) Then gonogo := True else gonogo := False;

          if gonogo Then
          Begin
               isiglevel := -30;
               if not tryStrToInt(exchange.db,isiglevel) Then
               Begin
                    gonogo := False;
               End
               Else
               Begin
                    gonogo := True;
                    if isiglevel > -1 Then
                    Begin
                         isiglevel := -1;
                    End;
                    if isiglevel < -30 Then
                    Begin
                         isiglevel := -30;
                    End;
               End;
          End;

          If gonogo then
          begin
               gonogo := False;
               i := -9999;
               if not TryStrToInt(exchange.df,i) Then
               begin
                    gonogo := False;
               end
               else
               begin
                    if (i<-1100) or (i>1100) Then gonogo := False else gonogo := True;
               end;
          end;

          if gonogo Then
          Begin
               gonogo := False;
               // Have signal report and DF
               // Now can Call the message parser
               toParse := '';
               if wc = 8 Then toParse  := exchange.nc1  + ' ' + exchange.nc2;
               if wc = 9 Then toParse  := exchange.nc1  + ' ' + exchange.nc2 + ' ' + exchange.ng;
               if wc = 10 Then toParse := exchange.nc1  + ' ' + exchange.nc1s + ' ' + exchange.nc2 + ' ' + exchange.ng;

               isValid   := False;
               isBreakIn := False;
               level     := 0;
               response  := '';
               connectTo := '';
               fullCall  := '';
               hisGrid   := '';

               decomposeDecode(toParse,inQSOWith,isValid,isBreakIn,level,response,connectTo,fullCall,hisGrid);

               if not isValid then
               Begin
                    mvalid := False;
               end
               else
               begin
                    mvalid := True;
               end;
          end;
     end;
end;

procedure TForm1.decomposeDecode(const exchange    : String;
                                 const connectedTo : String;
                                 var isValid       : Boolean;
                                 var isBreakIn     : Boolean;
                                 var level         : Integer;
                                 var response      : String;
                                 var connectTo     : String;
                                 var fullCall      : String;
                                 var hisGrid       : String);
Var
   wc           : Integer;
   isSlashed    : Boolean;
   nc1,nc2,ng   : String;
   s1,s2,mycall : String;
   myscall      : String;
   myGrid4      : String;
   siglevel     : String;
Begin
     // Takes decoded exchange and attempts to evaluate it as a structured message.
     // First is to see how many words in exchange - needs to be 2, 3 or 4.

     wc := WordCount(exchange,[' ']);
     nc1 := '';
     nc2 := '';
     ng  := '';
     nc1 := ExtractWord(1,exchange,[' ']);
     nc2 := ExtractWord(2,exchange,[' ']);
     ng  := ExtractWord(3,exchange,[' ']);

     isValid := False;
     isBreakin := False;
     level := 0;
     response := '';
     connectTo := '';
     fullcall := '';
     hisGrid := '';

     If Length(TrimLeft(TrimRight(edSuffix.Text))) > 0 Then myCall := TrimLeft(TrimRight(UpCase(edCall.Text))) + '/' + TrimLeft(TrimRight(UpCase(edSuffix.Text)));
     If Length(TrimLeft(TrimRight(edPrefix.Text))) > 0 Then myCall := TrimLeft(TrimRight(UpCase(edPrefix.Text))) + '/' + TrimLeft(TrimRight(UpCase(edCall.Text)));
     If (Length(TrimLeft(TrimRight(edSuffix.Text))) > 0) And (Length(TrimLeft(TrimRight(edPrefix.Text))) > 0) Then myCall := TrimLeft(TrimRight(UpCase(edCall.Text)));
     // TX Callsign is evaluated as (in order of precedence)
     // edPrefix.Text/edCall.Text
     // edCall.Text/edSuffix.Text
     // edCall.Text
     // myscall is this stations, as in my callsign, with prefix/suffix
     // mycall is just my base callsign
     If (Length(TrimLeft(TrimRight(edPrefix.Text))) < 1) And (Length(TrimLeft(TrimRight(edSuffix.Text))) <1) Then
     Begin
          myscall := TrimLeft(TrimRight(UpCase(edCall.Text)));
     end
     else
     begin
          // Since prefix outranks suffix this will insure prefix wins if both set.
          If (Length(TrimLeft(TrimRight(edSuffix.Text))) > 0) Then myscall := TrimLeft(TrimRight(UpCase(edCall.Text)))+'/'+TrimLeft(TrimRight(UpCase(edSuffix.Text)));
          If (Length(TrimLeft(TrimRight(edPrefix.Text))) > 0) Then myscall := TrimLeft(TrimRight(UpCase(edPrefix.Text)))+'/'+TrimLeft(TrimRight(UpCase(edCall.Text)));
     end;
     mycall := TrimLeft(TrimRight(UpCase(edCall.Text)));
     siglevel := TrimLeft(TrimRight(edTXReport.Text));
     myGrid4 := TrimLeft(TrimRight(UpCase(edGrid.Text)));
     if Length(myGrid4)>4 Then myGrid4 := myGrid4[1..4];

     if wc = 2 Then
     Begin
          // 2 Word types:
          //   Exchange                                 Protocol Level
          //   ------------------------------------     --------------
          //   CQ  Call (Technically not valid)          1
          //   QRZ Call                                  1
          //   CQ  Prefix/Call                           1
          //   CQ  Call/Suffix                           1
          //   QRZ Prefix/Call                           1
          //   QRZ Call/Suffix                           1
          level := 1;
          if (nc1 = 'CQ') or (nc1 = 'QRZ') or (nc1 = 'DE') Then
          Begin
               // Handler for CQ or QRZ [Call or Prefix/Call or Call/Suffix] types.
               level   := 1;
               if AnsiContainsText(nc2,'/') Then isSlashed := True else isSlashed := False;
               isValid := True;
               connectTo := TrimLeft(TrimRight(UpCase(nc2)));
               fullCall := connectTo;
               if isSlashed Then response := connectTo + ' ' + myscall;
               if not isSlashed Then response := connectTo + ' ' + myCall;
               // Response is like PFX/Call MYCALL
               //                  Call/SFX MYCALL
               //                  Call PFX/MYCALL
               //                  Call MYCALL/SFX
               //                  Call MYCALL
          end
          else
          begin
               // 2 Word types:
               //   Exchange                                 Protocol Level
               //   ------------------------------------     --------------
               //   Prefix/Call Call                          1
               //   Call/Suffix Call                          1
               //   Call Prefix/Call                          1
               //   Call Call/Suffix                          1
               //   Call Call                                 1/2 Technically invalid - but I'll work with it as long as it's too "me"

               // 2 Word types:
               //   Exchange                                 Protocol Level
               //   ------------------------------------     --------------
               //   Call -##                                  1
               //   Call R-##                                 1
               //   Call RO                                   1
               //   Call RRR                                  1
               //   Call 73                                   1
               //   Prefix/Call -##                           1
               //   Prefix/Call R-##                          1
               //   Prefix/Call RO                            1
               //   Prefix/Call RRR                           1
               //   Prefix/Call 73                            1
               //   Call/Suffix -##                           1
               //   Call/Suffix R-##                          1
               //   Call/Suffix RO                            1
               //   Call/Suffix RRR                           1
               //   Call/Suffix 73                            1

               // Two sub-forms to handle here.  Pair of calls or call and control field
               // If pair of calls I can look to see if it's to me or not to determing breakin
               // status.  If second word is control then I ONLY respond when word1 is mycall
               // AND connectedTo variable is set.

               if isControl(nc2) Then
               Begin
                    // The ONLY form of these I respond to is if nc1 contains my Call
                    // and connectedTo is set.
                    if ((nc1 = myCall) or (nc1 = mysCall)) And (Length(connectedTo)>0) Then
                    Begin
                         // Now look at nc2 to determine response.
                         response := '';
                         isValid := True;
                         isBreakin := False;

                         if nc2 = 'RO'  Then response := connectedTo + ' RRR';
                         if nc2 = 'RRR' Then response := connectedTo + ' 73';
                         if nc2 = '73'  Then response := connectedTo + ' 73';

                         If (Length(nc2)=3) And (nc2[1]='-') Then response := connectedTo + ' R-' + sigLevel;
                         If (Length(nc2)=4) And (nc2[1..2]='R-') Then response := connectedTo + ' RRR';
                    End;
               end
               else
               begin
                    // If word1 is mycall then there's only one response and that's hiscall -## report.
                    // If word1 != mycall then I can setup for a breakin to word2 but it only makes
                    // sense to do so if word2 is slashed.  Think about it.  :)
                    if ((nc1 = myCall) or (nc1 = mysCall)) Then
                    Begin
                         if AnsiContainsText(nc2,'/') Then
                         Begin
                              s1 := ExtractWord(1,nc2,['/']);
                              s2 := ExtractWord(2,nc2,['/']);
                              if isCallSign(s1) or isCallSign(s2) Then isValid := True else isValid := False;
                              isSlashed := True;
                         End
                         Else
                         Begin
                              if isCallSign(nc2) Then isValid := True else isValid := False;
                              isSlashed := False;
                         End;
                         if isValid Then
                         Begin
                              isValid := True;
                              isBreakin := False;
                              connectTo := nc2;
                              fullCall := connectTo;
                              response := connectTo + ' ' + sigLevel;
                         End
                         Else
                         Begin
                              isValid := False;
                              isBreakin := False;
                              response := '';
                              connectTo := '';
                              fullCall := connectTo;
                         End;
                         // Have now setup for anwering a Call to my Call
                    end
                    else
                    begin
                         if AnsiContainsText(nc2,'/') Then
                         Begin
                              s1 := ExtractWord(1,nc2,['/']);
                              s2 := ExtractWord(2,nc2,['/']);
                              if isCallSign(s1) or isCallSign(s2) Then isValid := True else isValid := False;
                              isSlashed := True;
                         End
                         Else
                         Begin
                              if isCallSign(nc2) Then isValid := True else isValid := False;
                         end;
                         If isValid and isSlashed Then
                         Begin
                              isBreakin := True;
                              isValid   := True;
                              connectTo := nc2;
                              fullCall := connectTo;
                              response  := connectTo + ' ' + myscall;
                              // Have now setup for a breakin type
                         end;
                         If isValid and (not isSlashed) Then
                         Begin
                              isBreakin := True;
                              isValid   := True;
                              connectTo := nc2;
                              fullCall  := nc2;
                              response  := connectTo + ' ' + myCall;
                         end;
                    end;
               end;
          end;
     end;

     if wc = 3 Then
     Begin
          // 3 Word types:
          //   ------------------------------------     --------------
          //   CQ  Call Grid                            1
          //   QRZ Call Grid                            1
          //   DE  Call Grid                            2
          //   CQ  Prefix/Call Grid                     2
          //   QRZ Prefix/Call Grid                     2
          //   DE  Prefix/Call Grid                     2
          //   CQ  Call/Suffix Grid                     2
          //   QRZ Call/Suffix Grid                     2
          //   DE  Call/Suffix Grid                     2
          //

          // Handling all the CQ/QRZ/DE Forms first.

          if ((nc1='CQ') or (nc1='QRZ') or (nc1='DE')) And isGrid(ng) Then
          Begin
               // Check for Prefix/Suffix Call
               If AnsiContainsText(nc2,'/') Then isSlashed := true else isSlashed := false;
               If isSlashed then level := 2 else level := 1;
               If isSlashed then
               Begin
                    s1 := ExtractWord(1,nc2,['/']);
                    s2 := ExtractWord(2,nc2,['/']);
                    if isCallsign(s1) or isCallsign(s2) Then isValid := True else isValid := False;
               end
               else
               begin
                    if isCallsign(nc2) Then isValid := True else isValid := False;
               end;
               If isValid Then
               Begin
                    if isSlashed then
                    begin
                         if isCallSign(s1) And isCallSign(s2) then connectTo := s2;
                         if isCallSign(s1) And (not isCallSign(s2)) then connectTo := s1;
                         if (not isCallSign(s1)) And isCallSign(s2) then connectTo := s2;
                         fullCall := nc2;
                    end
                    else
                    begin
                         connectTo := nc2;
                         fullCall  := nc2;
                    end;
               End;
               if isValid Then
               Begin
                    if isGrid(ng) Then hisGrid := ng else hisGrid := '';
                    response := connectTo + ' ' + myscall + ' ' + myGrid4;
                    isBreakin := False;
                    isValid := True;
               End
               Else
               Begin
                    response := '';
                    isBreakin := False;
                    isValid := False;
                    connectTo := '';
                    fullCall  := '';
               End;
               // Have now handled all the CQ/QRZ/DE Call Grid with response of Call MYCALL Grid
          End;

          //   DE Call 73                               2
          //   DE Prefix/Call 73                        2
          //   DE Call/Suffix 73                        2
          if ((nc1='CQ') or (nc1='QRZ') or (nc1='DE')) And (not isGrid(ng)) Then
          Begin
               // Check for Prefix/Suffix Call
               If AnsiContainsText(nc2,'/') Then isSlashed := true else isSlashed := false;
               If isSlashed then level := 2 else level := 1;
               If isSlashed then
               Begin
                    s1 := ExtractWord(1,nc2,['/']);
                    s2 := ExtractWord(2,nc2,['/']);
                    if isCallsign(s1) or isCallsign(s2) Then isValid := True else isValid := False;
               end
               else
               begin
                    if isCallsign(nc2) Then isValid := True else isValid := False;
               end;
               If isValid Then
               Begin
                    if isSlashed then
                    begin
                         if isCallSign(s1) And isCallSign(s2) then connectTo := s2;
                         if isCallSign(s1) And (not isCallSign(s2)) then connectTo := s1;
                         if (not isCallSign(s1)) And isCallSign(s2) then connectTo := s2;
                         fullCall := nc2;
                    end
                    else
                    begin
                         connectTo := nc2;
                         fullCall  := nc2;
                    end;
               End;
               if isValid Then
               Begin
                    if isGrid(ng) Then hisGrid := ng else hisGrid := '';
                    response := connectTo + ' ' + myscall + ' ' + myGrid4;
                    if ng='73' Then isBreakin := True else isBreakin := False;
                    isValid := True;
               End
               Else
               Begin
                    response := '';
                    isBreakin := False;
                    isValid := False;
                    connectTo := '';
                    fullCall  := '';
               End;
               // Have now handled all the CQ/QRZ/DE Call not Grid with response of Call MYCALL Grid
               // This covers something like a breakin for DE Call 73 or not a brakin for CQ Call .5W
          End;

          //   Call Call Grid                           1
          //   Call Call -##                            1
          //   Call Call R-##                           1
          //   Call Call RO (Deprecated on HF)          1
          //   Call Call RRR                            1
          //   Call Call 73                             1

          // An oddity I'm seeing is something like
          // callsign 73 none where none is a grid that's not defined.
          // I'm thinking this is likely a bug in the message generator
          // for JT65-HF (old) or WJST[x] where it's a free text entry
          // being formed such that it mutates to a structured message
          // type with no grid info.
          // Adding dealing with this to TODO but it's relatively low priority.

          if isCallsign(nc1) and isCallsign(nc2) Then
          Begin
               if isGrid(ng) Then
               Begin
                    // Need to see nc1 = myscall to not have a breakin response
                    if nc1 = myscall Then
                    Begin
                         // Only 1 response to this. HISCALL MYCALL -##
                         connectTo := nc2;
                         fullCall  := nc2;
                         hisGrid   := ng;
                         response := connectTo + ' ' + myscall + ' ' + sigLevel;
                         isBreakin := False;
                         isValid := True;
                    End
                    Else
                    Begin
                         // Only 1 response to this. HISCALL MYCALL MYGRID4
                         connectTo := nc2;
                         fullCall  := nc2;
                         hisGrid   := ng;
                         response := connectTo + ' ' + myscall + ' ' + myGrid4;
                         isBreakin := True;
                         isValid := True;
                    End;
               End;

               if isControl(ng) Then
               Begin
                    // Need to see nc1 = myscall to not have a breakin response
                    if nc1 = myscall Then
                    Begin
                         // Determine response form
                         connectTo := nc2;
                         fullcall := nc2;
                         hisgrid := '';
                         isBreakin := False;

                         response := '';
                         if ng = 'RO'  Then response := connectTo + ' ' + myscall + ' RRR';
                         if ng = 'RRR' Then response := connectTo + ' ' + myscall + ' 73';
                         if ng = '73'  Then response := connectTo + ' ' + myscall + ' 73';
                         if ng = 'NONE'  Then response := connectTo + ' ' + myscall + ' ' + myGrid4;

                         if (length(ng)=3) and (ng[1]='-') Then
                         Begin
                              response := '';
                              if newLog Then logMySig.Text := ng;
                              if newLog Then newLog := False;
                         end;

                         if (length(ng)=4) and (ng[1..2]='R-') Then
                         Begin
                              response := '';
                              if newLog Then logMySig.Text := ng[2..4];
                              if newLog Then newLog := False;
                         end;

                         if Length(response)>0 Then
                         Begin
                              connectTo := nc2;
                              fullcall := nc2;
                              hisgrid := '';
                              isBreakin := False;
                              isValid := True;
                         End
                         Else
                         Begin
                              connectTo := '';
                              fullCall  := '';
                              hisGrid   := '';
                              isBreakin := False;
                              isValid := False;
                              response := '';
                         End;
                    End
                    Else
                    Begin
                         // Only 1 response to this. HISCALL MYCALL MYGRID4
                         connectTo := nc2;
                         fullCall  := nc2;
                         hisGrid   := ng;
                         response := connectTo + ' ' + myscall + ' ' + myGrid4;
                         isBreakin := True;
                         isValid := True;
                    End;
               End;
          End;

          //   [Not supported in JT65-HF]
          //   CQ  ### Prefix/Call                       1
          //   CQ  ### Call/Suffix                       1
          //   QRZ ### Prefix/Call                       1
          //   QRZ ### Call/Suffix                       1
          //
          if ((nc1='CQ') or (nc1='QRZ')) And (not isCallSign(nc2)) Then
          Begin
               response := '';
               isBreakin := False;
               isValid := False;
               connectTo := '';
               fullCall  := '';
          End;
     end;

     if wc = 4 Then
     Begin
          // 4 Word types:
          //   ------------------------------------     --------------
          //   [Not supported in JT65-HF]
          //   CQ ### Call Grid                         1
          //
          level     := 1;
          isValid   := False;
          response  := '';
          connectTo := '';
     end;

end;

procedure TForm1.mgen(const msg : String; var isValid : Boolean; var isBreakIn : Boolean; var level : Integer; var response : String; var connectTo : String; var fullCall : String; var hisGrid : String; var sdf : String; var sdB : String; var txp : Integer);
Var
  foo       : String;
  exchange  : exch;
  i,wc      : Integer;
  isiglevel : Integer;
  gonogo    : Boolean;
  toparse   : String;
Begin
     gonogo   := False;
     isValid  := False;
     isBreakIn := False;
     level := 0;
     response := '';
     connectTo := '';
     fullCall := '';
     hisGrid := '';
     // Get the decode to parse
     foo := msg;
     foo := DelSpace1(foo);
     foo := StringReplace(foo,' ',',',[rfReplaceAll,rfIgnoreCase]);
     // Now with a structured message I'll have...
     // UTC, Sync, dB, DT, DF, EC, NC1, Call FROM, MSG
     // Where NC1 is one of [CQ, CQ ###, QRZ, DE, CALLSIGN]
     // Where MSG is one of [Grid,-##,R-##,RRR,RO,73]
     // First check is for first two characters to be numeric AND wordcount
     // = 9 or 10.  10 Handles case of a CQ ### format (not seen on HF, but...)
     // If not wc = 9 or 10 then it's not something to parse here.
     i := 0;
     wc := wordcount(foo,[',']);
     if (wc=8) or (wc=9) or (wc=10) Then
     Begin
          if wc=8 Then
          Begin
               // Parse string into parts (8 word exchange)
               exchange.utc  := TrimLeft(TrimRight(UpCase(ExtractWord(1,foo,[',']))));
               exchange.sync := TrimLeft(TrimRight(UpCase(ExtractWord(2,foo,[',']))));
               exchange.db   := TrimLeft(TrimRight(UpCase(ExtractWord(3,foo,[',']))));
               exchange.dt   := TrimLeft(TrimRight(UpCase(ExtractWord(4,foo,[',']))));
               exchange.df   := TrimLeft(TrimRight(UpCase(ExtractWord(5,foo,[',']))));
               exchange.ec   := TrimLeft(TrimRight(UpCase(ExtractWord(6,foo,[',']))));
               exchange.nc1  := TrimLeft(TrimRight(UpCase(ExtractWord(7,foo,[',']))));
               exchange.nc1s := '';
               exchange.nc2  := TrimLeft(TrimRight(UpCase(ExtractWord(8,foo,[',']))));
               exchange.ng   := '';
          end;
          if wc=9 Then
          Begin
               // Parse string into parts (9 word exchange)
               exchange.utc  := TrimLeft(TrimRight(UpCase(ExtractWord(1,foo,[',']))));
               exchange.sync := TrimLeft(TrimRight(UpCase(ExtractWord(2,foo,[',']))));
               exchange.db   := TrimLeft(TrimRight(UpCase(ExtractWord(3,foo,[',']))));
               exchange.dt   := TrimLeft(TrimRight(UpCase(ExtractWord(4,foo,[',']))));
               exchange.df   := TrimLeft(TrimRight(UpCase(ExtractWord(5,foo,[',']))));
               exchange.ec   := TrimLeft(TrimRight(UpCase(ExtractWord(6,foo,[',']))));
               exchange.nc1  := TrimLeft(TrimRight(UpCase(ExtractWord(7,foo,[',']))));
               exchange.nc1s := '';
               exchange.nc2  := TrimLeft(TrimRight(UpCase(ExtractWord(8,foo,[',']))));
               exchange.ng   := TrimLeft(TrimRight(UpCase(ExtractWord(9,foo,[',']))));
          End;
          if wc=10 Then
          Begin
               // Parse string into parts (10 word exchange)
               exchange.utc  := TrimLeft(TrimRight(UpCase(ExtractWord(1,foo,[',']))));
               exchange.sync := TrimLeft(TrimRight(UpCase(ExtractWord(2,foo,[',']))));
               exchange.db   := TrimLeft(TrimRight(UpCase(ExtractWord(3,foo,[',']))));
               exchange.dt   := TrimLeft(TrimRight(UpCase(ExtractWord(4,foo,[',']))));
               exchange.df   := TrimLeft(TrimRight(UpCase(ExtractWord(5,foo,[',']))));
               exchange.ec   := TrimLeft(TrimRight(UpCase(ExtractWord(6,foo,[',']))));
               exchange.nc1  := TrimLeft(TrimRight(UpCase(ExtractWord(7,foo,[',']))));
               exchange.nc1s := TrimLeft(TrimRight(UpCase(ExtractWord(8,foo,[',']))));
               exchange.nc2  := TrimLeft(TrimRight(UpCase(ExtractWord(9,foo,[',']))));
               exchange.ng   := TrimLeft(TrimRight(UpCase(ExtractWord(10,foo,[',']))));
          End;

          i := 0;
          if TryStrToInt(exchange.utc[1..2],i) Then gonogo := True else gonogo := False;
          if gonogo Then
          Begin
               isiglevel := -30;
               if not tryStrToInt(exchange.db,isiglevel) Then
               Begin
                    gonogo := False;
               End
               Else
               Begin
                    gonogo := True;
                    if isiglevel > -1 Then
                    Begin
                         isiglevel := -1;
                    End;
                    if isiglevel < -30 Then
                    Begin
                         isiglevel := -30;
                    End;
               End;
          End;
          If gonogo then
          begin
               gonogo := False;
               i := -9999;
               if not TryStrToInt(exchange.df,i) Then
               begin
                    gonogo := False;
               end
               else
               begin
                    if (i<-1100) or (i>1100) Then gonogo := False else gonogo := True;
               end;
          end;
          if gonogo Then
          Begin
               gonogo := False;
               // Have signal report and DF
               // Now can Call the message parser
               toParse := '';
               if wc = 8 Then toParse  := exchange.nc1  + ' ' + exchange.nc2;
               if wc = 9 Then toParse  := exchange.nc1  + ' ' + exchange.nc2 + ' ' + exchange.ng;
               if wc = 10 Then toParse := exchange.nc1  + ' ' + exchange.nc1s + ' ' + exchange.nc2 + ' ' + exchange.ng;
               decomposeDecode(toParse,inQSOWith,isValid,isBreakIn,level,response,connectTo,fullCall,hisGrid);
               sdb := exchange.db;
               sdf := exchange.df;
               // compute TX period
               foo := exchange.utc[4..5];
               i := -1;
               i := StrToInt(foo);
               if (i>-1) and odd(i) then txp := 0; // Was received Odd so TX Even!
               if (i>-1) and not odd(i) then txp := 1; // Was received Even so TX Odd!
          end;
     end;
end;

procedure TForm1.ListBox1DblClick(Sender: TObject);
Var
  foo       : String;
  i, txp    : Integer;
  tvalid    : Boolean;
  isBreakIn : Boolean;
  level     : Integer;
  response  : String;
  connectTo : String;
  fullCall  : String;
  hisGrid   : String;
  sdb, sdf  : String;
begin
     i := Form1.ListBox1.ItemIndex;
     if i > -1 Then
     Begin
          // Get the decode to parse
          foo := Form1.ListBox1.Items[i];
          foo := DelSpace1(foo);
          //foo := StringReplace(foo,' ',',',[rfReplaceAll,rfIgnoreCase]);
          tvalid    := False;
          hisGrid   := '';
          fullCall  := '';
          connectTo := '';
          response  := '';
          level     := -1;
          sdb       := '-99';
          sdf       := '9999';
          isBreakIn := False;
          txp       := 2;

          mgen(foo, tValid, isBreakin, Level, response, connectTo, fullCall, hisgrid, sdf, sdb, txp);
          if tValid Then
          Begin
               //if isBreakIn Then Memo1.Append('[TE] ' + response + ' to ' + connectTo + ' [' + fullCall + '] @ ' + hisGrid + ' Proto ' + IntToStr(level) + '[' + sdb + 'dB @ ' + sdf + 'Hz]') else Memo1.Append('[IM] ' + response + ' to ' + connectTo + ' [' + fullCall + '] @ ' + hisGrid + ' Proto ' + IntToStr(level) + '[' + sdb + 'dB @ ' + sdf + 'Hz]');
               edTXMsg.Text := response;
               edTXToCall.Text := fullCall;
               edTXReport.Text := sdb;
               edTXDF.Text := sdf;
               if cbTXeqRXDF.Checked Then edRXDF.Text := sdf;
               if txp=0 then rbTxEven.Checked := True else rbTxOdd.Checked := True;
          end
          else
          begin
               Memo1.Append('No message can be generated');
          end;
     End;
end;

procedure TForm1.ListBox1DrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
Var
   myColor            : TColor;
   myBrush            : TBrush;
   lineCQ, lineMyCall : Boolean;
   lineWarn           : Boolean;
   foo                : String;
begin
     if state = [odSelected] Then
     Begin
          // Do nothing - kills a compiler warn that bugs me.
     end;
     lineCQ := False;
     lineMyCall := False;
     if Index > -1 Then
     Begin
          foo := Form1.ListBox1.Items[Index];
          if IsWordPresent('WARNING:', foo, [' ']) Then lineWarn := True else lineWarn := False;
          if IsWordPresent('CQ', foo, [' ']) Then lineCQ := True;
          if IsWordPresent('QRZ', foo, [' ']) Then lineCQ := True;
          if IsWordPresent(TrimLeft(TrimRight(UpCase(edCall.Text))), foo, [' ']) Then lineMyCall := True else lineMyCall := False;
          myBrush := TBrush.Create;
          with (Control as TListBox).Canvas do
          begin
               //myColor := cfgvtwo.glqsoColor;
               If cbUseColor.Checked Then
               Begin
                    myColor := clSilver;
                    if lineCQ Then myColor := clLime;
                    if lineMyCall Then myColor := clRed;
                    if lineWarn then myColor := clRed;
               end
               else
               begin
                    myColor := clWhite;
               end;
               myBrush.Style := bsSolid;
               myBrush.Color := myColor;
               Windows.FillRect(handle, ARect, myBrush.Reference.Handle);
               Brush.Style := bsClear;
               TextOut(ARect.Left, ARect.Top,(Control as TListBox).Items[Index]);
               MyBrush.Free;
          end;
     end;
end;

procedure TForm1.ListBox2DblClick(Sender: TObject);
begin
     ListBox2.Clear;
end;

procedure TForm1.rbTXEvenChange(Sender: TObject);
begin
     if rbTXEven.Checked Then txperiod := 0 else txperiod := 1;
end;

procedure TForm1.rigControlSet(Sender: TObject);
begin
     if Sender = cbUseMono Then
     Begin
          if cbUseMono.Checked Then adc.adcMono := True else adc.adcMono := False;
          audioChange(TObject(comboAudioIn));
     end;

     if Sender = edDialQRG then LastQRG.Text := edDialQRG.Text;

     If (Sender = rbUseLeftAudio) or (Sender = rbUseRightAudio) Then
     Begin
          if rbUseLeftAudio.Checked Then adc.adcChan  := 1;
          if rbUseRightaudio.Checked Then adc.adcChan := 2;
     end;

     If Sender = rigNone Then catMethod := 'None';

     If Sender = rigRebel Then
     Begin
          catMethod := 'Rebel';
          if cbUseSerial.Checked Then cbUseSerial.Checked := False;
          { TODO : Graft code to connect to rebel if it wasn't on at startup }
     end;

     // If Sender = rigCommander Then catMethod := 'Commander';

end;

function TForm1.isCallsign(c : String) : Boolean;
Begin
     //
     // Rules for being a callsign (where A = Letter A...Z and # = Digit 0...9 in templates):
     // Length = 3 must be:  A#A
     //
     // Length = 4 must be:  A#AA AA#A #A#A A##A
     //
     // Length = 5 must be:  A#AAA AA#AA #A#AA A##AA
     //
     // Length = 6 must be:  AA#AAA #A#AAA A##AAA
     //
     // Length < 3 or > 6 = Not a callsign
     //
     If (Length(c) < 3) or (Length(c) > 6) Then
     Begin
          Result := False;
     End
     Else
     Begin
          if Length(c) = 3 Then
          Begin
               // Length = 3 must be:  A#A
               If isLetter(c[1]) And isDigit(c[2]) And isLetter(c[3]) Then Result := True else Result := False;
          end;

          if Length(c) = 4 Then
          Begin
               // Length = 4 must be:  A#AA or AA#A or #A#A or A##A
               Result := False;
               if isLetter(c[1]) And isDigit(c[2])  And isLetter(c[3]) And isLetter(c[4]) Then Result := True; // A#AA
               if isLetter(c[1]) And isLetter(c[2]) And isDigit(c[3])  And isLetter(c[4]) Then Result := True; // AA#A
               if isDigit(c[1])  And isLetter(c[2]) And isDigit(c[3])  And isLetter(c[4]) Then Result := True; // #A#A
               if isLetter(c[1]) And isDigit(c[2])  And isDigit(c[3])  And isLetter(c[4]) Then Result := True; // A##A
          end;

          if Length(c) = 5 Then
          Begin
               // Length = 5 must be:  A#AAA AA#AA #A#AA A##AA
               Result := False;
               if isLetter(c[1]) and isDigit(c[2])  and isLetter(c[3]) and isLetter(c[4]) and isLetter(c[5]) Then Result := True; // A#AAA
               if isLetter(c[1]) and isLetter(c[2]) and isDigit(c[3])  and isLetter(c[4]) and isLetter(c[5]) Then Result := True; // AA#AA
               if isDigit(c[1])  and isLetter(c[2]) and isDigit(c[3])  and isLetter(c[4]) and isLetter(c[5]) Then Result := True; // #A#AA
               if isLetter(c[1]) And isDigit(c[2])  and isDigit(c[3])  and isLetter(c[4]) and isLetter(c[5]) Then Result := True; // A##AA
          end;

          if Length(c) = 6 Then
          Begin
               // Length = 6 must be:  AA#AAA #A#AAA A##AAA
               Result := False;
               if isLetter(c[1]) and isLetter(c[2]) and isDigit(c[3])  and isLetter(c[4]) and isLetter(c[5]) and isLetter(c[6]) Then Result := True; // AA#AAA
               if isDigit(c[1])  and isLetter(c[2]) and isDigit(c[3])  and isLetter(c[4]) and isLetter(c[5]) and isLetter(c[6]) Then Result := True; // #A#AAA
               if isLetter(c[1]) And isDigit(c[2])  and isDigit(c[3])  and isLetter(c[4]) and isLetter(c[5]) and isLetter(c[6]) Then Result := True; // A##AAA
          end;
     end;
end;

function TForm1.isControl(c : String) : Boolean;
Var
   i : Integer;
Begin
     // Grid, -##, R-##, RRR, RO, 73, NONE (For missing Grid error)
     // c must be one of the above to return true.
     Result := False;
     if c = 'RRR' then result := true;
     if c = 'RO'  then result := true;
     if c = '73'  then result := true;
     if c = 'NONE' then result := true;
     if (length(c)=3) and (not result) then
     begin
          // better be -##
          i := 0;
          if TryStrToInt(c,i) Then
          Begin
               if (i < 0) and (i > -31) Then result := true;
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
                    if (i < 0) and (i > -31) Then result := true;
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

function TForm1.isGrid(c : String) : Boolean;
Var
   foo : String;
Begin
     // Grid is simple.  Must be LL## where L = alpha A...R and # 0...9
     foo := DelSpace(TrimLeft(TrimRight(UpCase(c))));  // Remove any spaces, paddding and upper case.
     if Length(foo)=4 Then
     Begin
          if isGLLetter(foo[1]) And isGLLetter(foo[2]) and isDigit(foo[3]) and isDigit(foo[4]) Then Result := True else Result := False;
     end
     else
     begin
          Result := False;
     end;
end;

function  TForm1.messageParser(const ex : String; var nc1t : String; var pfx : String; var sfx : String; var nc2t : String; var ng : String; var sh : String) : Boolean;
Var
   foo   : String;
   w1,w2 : String;
   i, wc : Integer;
   w     : Array[1..4] of String;
   ispfx : Boolean;
   issfx : Boolean;
   b     : Boolean;
Begin
     Result := False;
     nc1t   := '';
     pfx    := '';
     sfx    := '';
     nc2t   := '';
     ng     := '';
     sh     := '';
     // Attempts to take an arbitrary string and convert it into the fields of a structured message.
     // Easiest cases first
     for i := 1 to 4 do w[i] := '';
     foo := DelSpace1(TrimLeft(TrimRight(UpCase(ex)))); // Insures there is only one space between words, deletes left/right padding (space) and makes upper case.
     wc  := WordCount(foo,[' ']);
     If (wc > 0) and isSText(foo) Then
     Begin
          for i := 1 to wc do w[i] := ExtractWord(i,foo,[' ']);

          if wc=4 then
          Begin
               // Only one structured message has four words:  CQ ### Call Grid and Prefix/Suffix is disallowed with these.
               if w[1] = 'CQ' Then
               Begin
                    b := True;
                    for i := 1 to length(w[2]) do if not isDigit(w[2][i]) then b := False;

                    if b Then
                    Begin
                         if tryStrToInt(w[2],i) Then
                         Begin
                              if (i > 0) And (i < 1000) Then b := True else b := False;
                         end
                         else
                         begin
                              b := False;
                         end;
                         if b Then
                         Begin
                              // Have to have an offset 001 to 999 followed by a callsign followed by a Grid
                              nc1t := 'CQ';
                              nc2t := w[3];
                              if length(w[2]) = 1 Then w[2] := '00'+w[2];
                              if length(w[2]) = 2 Then w[2] := '0'+w[2];
                              pfx  := w[2];
                              sfx  := '';
                              ng   := w[4];
                              sh     := '';
                              if isGrid(ng) Then
                              Begin
                                   result := True;
                              end
                              else
                              begin
                                   Result := False;
                                   nc1t   := '';
                                   pfx    := '';
                                   sfx    := '';
                                   nc2t   := '';
                                   ng     := '';
                                   sh     := '';
                              end;
                         end
                         else
                         begin
                              // Does not contain a valid offset
                              Result := False;
                              nc1t   := '';
                              pfx    := '';
                              sfx    := '';
                              nc2t   := '';
                              ng     := '';
                              sh     := '';
                         end;
                    end
                    else
                    begin
                         // Does not contain a valid offset
                         Result := False;
                         nc1t   := '';
                         pfx    := '';
                         sfx    := '';
                         nc2t   := '';
                         ng     := '';
                         sh     := '';
                    end;
               End
               Else
               Begin
                    // No idea what it is - so it's free text.
                    Result := False;
                    nc1t   := '';
                    pfx    := '';
                    sfx    := '';
                    nc2t   := '';
                    ng     := '';
                    sh     := '';
               End;
          End;

          if wc=3 then
          Begin
               // Many types:
               //
               // CQ Call Grid
               // CQ Prefix/Call Grid
               // CQ Call/Suffix Grid
               //
               // QRZ Call Grid
               // QRZ Prefix/Call Grid
               // QRZ Call/Suffix Grid
               //
               // DE Call Grid
               // DE Prefix/Call Grid
               // DE Call/Suffix Grid
               // DE Call 73
               // DE Prefix/Call 73
               // DE Call/Suffix 73
               //
               // Call Call Grid
               // Call Call -##
               // Call Call R-##
               // Call Call RO
               // Call Call RRR
               // Call Call 73

               if (w[1]='CQ') Or (w[1]='QRZ') Or (w[1]='DE') Then
               Begin
                    If AnsiContainsText(w[2],'/') Then
                    Begin
                         w1 := '';
                         w2 := '';
                         w1 := ExtractWord(1,w[2],['/']);
                         w2 := ExtractWord(2,w[2],['/']);

                         ispfx := True;
                         issfx := True;

                         if isCallsign(w1) Then ispfx := False;
                         if isCallsign(w2) Then issfx := False;


                         if ispfx and issfx Then
                         Begin
                              // Seems to be a pair of non callsign values with a /
                              Result := False;
                              nc1t   := '';
                              pfx    := '';
                              sfx    := '';
                              nc2t   := '';
                              ng     := '';
                              sh     := '';
                         end;

                         if (not ispfx) and (not issfx) Then
                         Begin
                              // Bit more complicated here as it could be garbage or a Prefix that looks like a callsign.
                              // There are some 4 character Prefix values defined in WSJT that look like a full callsign
                              // like:
                              //
                              // 3D2C/ 3D2R/ CE0X/ CE0Y/ CE0Z/ HK0A/ HK0M/ KH5K/ PY0F/ PT0S/ PY0T/
                              // VK0H/ VK0M/ VK9C/ VK9L/ VK9M/ VK9N/ VK9W/ VK9X/ VP2E/ VP2M/ VP2V/
                              // VP6D/ VP8G/ VP8H/ VP8O/ VP8S/ ZK1N/ ZK1S/
                              //

                              // Now... the only way I can end up with a pair of calls is to have a 4 character Prefix
                              // that looks like a callsign with a 3 character "real" callsign or a 4 character callsign
                              // with a 3 character Suffix that looks like a callsign.  I have to wonder what the chances
                              // of that happening may be?  Seems slight at best.  A 4 character Prefix being used by a 1x1
                              // format callsign seems almost impossible, but, who knows...  A 4 character "real" callsign
                              // with a 3 character Suffix looking like a 1x1 callsign seems, well, stupid.

                              // So...  I'm going to punt for now and do a simple test for a > 4 character w1 value or > 3
                              // character w2 value.  If length w1=3 and w2=3 then I give up.

                              // Some simple checks here.  Prefix can be 1..4 characters
                              //                           Suffix can be 1..3 characters
                              // If w1 length > 4 it can't be a prefix
                              // If w2 length > 3 it can't be a prefix

                              // A couple of other tests... if length w1 < 3 or length w2 < 3 neither can be a callsign.  But,
                              // this is included in the isCallsign test so never mind.

                              // Actually... I'm way overthinking this as usual.  It'll only be when I parse these things in
                              // JT65-HF that this makes any difference.

                              if Length(w1) > 4 Then ispfx := False;
                              if Length(w2) > 3 Then issfx := False;
                              if (not ispfx) And (not issfx) Then
                              Begin
                                   if Length(w1) > Length(w2) Then issfx := True;
                                   if Length(w2) > Length(w1) Then ispfx := True;
                              end;

                              if Length(w1) = Length(w2) Then
                              Begin
                                   // Flip a coin... call w1 Prefix w2 Call
                                   ispfx := True;
                                   issfx := False;
                              end;

                         end;

                         If (ispfx and (not issfx)) Or (issfx and (not ispfx)) Then
                         Begin
                              // Yay! We have a winner
                              nc1t := w[1]; // CQ QRZ or DE
                              if ispfx then nc2t := w2;
                              if issfx then nc2t := w1;
                              if ispfx then pfx := w1 else pfx  := '';
                              if issfx then sfx := w2 else sfx  := '';
                              ng   := w[3];
                              if w[3] = '73' Then
                              Begin
                                   Result := True;
                              end
                              else
                              begin
                                   if isGrid(ng) Then
                                   Begin
                                        result := True;
                                   end
                                   else
                                   begin
                                        Result := False;
                                        nc1t   := '';
                                        pfx    := '';
                                        sfx    := '';
                                        nc2t   := '';
                                        ng     := '';
                                        sh     := '';
                                   end;
                              end;
                         end;
                    End
                    Else
                    Begin
                         // Have to have a callsign here followed by a Grid
                         // Or, for DE, A callsign follwed by 73
                         nc1t := w[1]; // CQ QRZ or DE
                         nc2t := w[2];
                         pfx  := '';
                         sfx  := '';
                         ng   := w[3];
                         sh     := '';
                         if w[3] = '73' Then
                         Begin
                              Result := True;
                         end
                         else
                         begin
                              if isGrid(ng) Then
                              Begin
                                   result := True;
                              end
                              else
                              begin
                                   Result := False;
                                   nc1t   := '';
                                   pfx    := '';
                                   sfx    := '';
                                   nc2t   := '';
                                   ng     := '';
                                   sh     := '';
                              end;
                         end;
                    End;
               End;

               // Have now covered CQ/DE/QRZ Call Grid, CQ/DE/QRZ PFX/Call Grid and CQ/DE/QRZ Call/SFX Grid

               If not Result Then
               Begin
                    // Didn't parse to any of the above cases leaving:
                    // Call Call Grid
                    // Call Call -##
                    // Call Call R-##
                    // Call Call RO
                    // Call Call RRR
                    // Call Call 73

                    if ((w[3] = 'RO') Or (w[3] = 'RRR') Or (w[3] = '73') Or (AnsiContainsText(w[3],'-'))) And (isCallSign(w[1]) and isCallsign(w[2])) Then
                    Begin
                         // Call Call RO or Call Call RRR or Call Call 73 or Call Call -## or Call Call R-##
                         nc1t := w[1];
                         nc2t := w[2];
                         pfx  := '';
                         sfx  := '';
                         ng   := w[3];
                         result := True;
                         sh     := '';
                    End;

                    If not Result Then
                    Begin
                         // This leaves Call Call Grid as only thing it can be if valid.
                         if isCallsign(w[1]) And isCallsign(w[2]) And isGrid(w[3]) Then
                         Begin
                              // It's a call call grid for sure at this point
                              nc1t := w[1];
                              nc2t := w[2];
                              pfx  := '';
                              sfx  := '';
                              ng   := w[3];
                              result := True;
                              sh     := '';
                         End;
                    End;
               End;
          End;

          if wc = 1 Then
          Begin
               // Handler for SH messages RO, RRR and 73 [And ATT]
               nc1t := '';
               nc2t := '';
               pfx  := '';
               sfx  := '';
               ng   := '';
               sh   := '';
               Result := False;

               if w[1] = 'RO'  Then sh := 'RO';
               if w[1] = 'RRR' Then sh := 'RRR';
               if w[1] = '73'  Then sh := '73';
               if w[1] = 'ATT' Then sh := 'ATT';

               if (sh='RO') or (sh='RRR') or (sh='73') or (sh='ATT') Then result := True;
          end;
     end
     else
     begin
          Result := False;
          nc1t   := '';
          pfx    := '';
          sfx    := '';
          nc2t   := '';
          ng     := '';
          sh     := '';
     end;

     if not Result Then
     Begin
          Result := False;
          nc1t   := '';
          pfx    := '';
          sfx    := '';
          nc2t   := '';
          ng     := '';
          sh     := '';
     end;
end;

//procedure TForm1.earlySync(Const samps : Array Of CTypes.cint16; Const endpoint : Integer);
//Var
//   fBuffer  : Array of CTypes.cfloat;
//   lBuffer  : Array of CTypes.cfloat;
//   iBuffer  : Array of CTypes.cint16;
//   i,j      : Integer;
//   fsum     : CTypes.cfloat;
//   ave      : CTypes.cfloat;
//   nave,jz  : CTypes.cint;
//   lmousedf : CTypes.cint;
//   jz2      : CTypes.cint;
//   mousedf2 : CTypes.cint;
//   lical    : CTypes.cint;
//   syncount : CTypes.cint;
//   wif      : PChar;
//   dtxa     : Array[0..254] Of CTypes.cfloat;
//   dfxa     : Array[0..254] Of CTypes.cfloat;
//   snrxa    : Array[0..254] Of CTypes.cfloat;
//   snrsynca : Array[0..254] Of CTypes.cfloat;
//   idfxa    : Array[0..254] Of CTypes.cint;
//   nsnr     : Array[0..254] Of CTypes.cint;
//   nsync    : Array[0..254] Of CTypes.cint;
//   bins     : Array[0..20] Of CTypes.cint;
//   added    : Boolean;
//   wispath  : String;
//Begin
//     // Attempt to find sync points early.  Experimental stuff.  :)
//     setLength(fBuffer,661504);
//     for i := 0 to Length(fBuffer)-1 do fBuffer[i] := 0.0;
//     setLength(lBuffer,661504);
//     for i := 0 to Length(lBuffer)-1 do lBuffer[i] := 0.0;
//     setLength(iBuffer,661504);
//     for i := 0 to Length(iBuffer)-1 do iBuffer[i] := 0;
//     // Convert to float
//     fsum := 0.0;
//     nave := 0;
//     for i := 0 to endpoint do fsum := fsum + samps[i];
//     nave := Round(fsum/(endpoint+1));
//     if nave <> 0 Then
//     Begin
//          for i := 0 to endpoint do iBuffer[i] := min(32766,max(-32766,samps[i]-nave));
//     End
//     Else
//     Begin
//          for i := 0 to endpoint do iBuffer[i] := min(32766,max(-32766,samps[i]));
//     End;
//     fsum := 0.0;
//     ave := 0.0;
//     for i := 0 to endpoint do
//     Begin
//          fBuffer[i] := 0.1 * iBuffer[i];
//          fsum := fsum + fBuffer[i];
//     End;
//     ave := fsum/(endpoint+1);
//     if ave <> 0.0 Then for i := 0 to endpoint do fBuffer[i] := fBuffer[i]-ave;
//     jz := endpoint;
//
//     // Samples now converted to float, apply lpf
//     lmousedf := 0;
//     jz2 := 0;
//     mousedf2 := 0;
//     lical := 0;
//     wif := StrAlloc(256);
//     wisPath := TrimFilename(cfgDir+'wisdom2.dat');
//     wisPath := PadRight(wisPath,255);
//     StrPCopy (wif,wisPath);
//     for i := 0 to jz do lBuffer[i] := fBuffer[i];
//     lpf1(CTypes.pcfloat(@lBuffer[0]),CTypes.pcint(@jz),CTypes.pcint(@jz2),CTypes.pcint(@lmousedf),CTypes.pcint(@mousedf2),CTypes.pcint(@lical),PChar(wif));
//
//     // Clear fBuffer
//     for i := 0 to Length(fBuffer)-1 do fBuffer[i] := 0.0;
//
//     // msync will want a downsampled and lpf version of data.
//
//     // Copy lBuffer to fBuffer
//     for i := 0 to jz2 do fBuffer[i] := lBuffer[i];
//     // Clear returns
//     for i := 0 to 254 do
//     begin
//          dtxa[i]     := 0.0;
//          dfxa[i]     := 0.0;
//          snrxa[i]    := 0.0;
//          snrsynca[i] := 0.0;
//          idfxa[i]     := 0;
//          nsnr[i]     := 0;
//          nsync[i]    := 0;
//     end;
//
//     syncount := 0;
//     msync(CTypes.pcfloat(@fBuffer[0]),CTypes.pcint(@jz2),CTypes.pcint(@syncount),CTypes.pcfloat(@dtxa[0]),CTypes.pcfloat(@dfxa[0]),CTypes.pcfloat(@snrxa[0]),CTypes.pcfloat(@snrsynca[0]),CTypes.pcint(@lical),PChar(wif));
//
//     for i := 0 to 254 do
//     begin
//          idfxa[i]    := trunc(dfxa[i]);
//          nsnr[i]     := trunc(snrxa[i]);
//          nsync[i]    := trunc(snrsynca[i]-3.0);
//     end;
//
//     for i := 0 to 20 do bins[i] := 0;
//
//     //  Low     CF      High     Bin
//     // -1050 . -1000 . -950      0
//     //  -949 . -900  . -850      1
//     //  -849 . -800  . -750      2
//     //  -749 . -700  . -650      3
//     //  -649 . -600  . -550      4
//     //  -549 . -500  . -450      5
//     //  -449 . -400  . -350      6
//     //  -349 . -300  . -250      7
//     //  -249 . -200  . -150      8
//     //  -149 . -100  . -50       9
//     //   -49 .  0    .  50       10
//     //    51    100  .  150      11
//     //   151    200  .  250      12
//     //   251    300  .  350      13
//     //   351    400  .  450      14
//     //   451    500  .  550      15
//     //   551    600  .  650      16
//     //   651    700  .  750      17
//     //   751    800  .  850      18
//     //   851    900  .  950      19
//     //   951   1000  .  1050     20
//
//     added := False;
//     for i := 0 to 254 do
//     begin
//          If (nsnr[i] > -33) and (nsync[i] > 0) Then
//          Begin
//               //ListBox1.Items.Insert(0,'dt:  ' + IntToStr(thisSecond) + ' ' + IntToStr(i) + ' dtxa:  ' + IntToStr(idtxa[i]) + ' dfxa:  ' + IntToStr(idfxa[i]) + ' nsnr:  ' + IntToStr(nsnr[i]) + ' nsync:  ' + IntToStr(nsync[i]));
//               added := True;
//               if (idfxa[i] > -1051) And (idfxa[i] < -951) Then
//               Begin
//                    Inc(bins[0]);   // -1050 ... -950 CF = -1000
//               End;
//
//               if (idfxa[i] > -950)  And (idfxa[i] < -851) Then
//               Begin
//                    Inc(bins[1]);   //  -951 ... -850 CF =  -900
//               End;
//
//               if (idfxa[i] > -850)  And (idfxa[i] < -751) Then
//               Begin
//                    Inc(bins[2]);   //  -851 ... -750 CF =  -800
//               End;
//
//               if (idfxa[i] > -750)  And (idfxa[i] < -651) Then
//               Begin
//                    Inc(bins[3]);   //  -751 ... -650 CF =  -700
//               End;
//
//               if (idfxa[i] > -650)  And (idfxa[i] < -551) Then
//               Begin
//                    Inc(bins[4]);   //  -651 ... -550 CF =  -600
//               End;
//
//               if (idfxa[i] > -550)  And (idfxa[i] < -451) Then
//               Begin
//                    Inc(bins[5]);   //  -551 ... -450 CF =  -500
//               End;
//
//               if (idfxa[i] > -450)  And (idfxa[i] < -351) Then
//               Begin
//                    Inc(bins[6]);   //  -451 ... -350 CF =  -400
//               End;
//
//               if (idfxa[i] > -350)  And (idfxa[i] < -251) Then
//               Begin
//                    Inc(bins[7]);   //  -351 ... -250 CF =  -300
//               End;
//
//               if (idfxa[i] > -250)  And (idfxa[i] < -151) Then
//               Begin
//                    Inc(bins[8]);   //  -251 ... -150 CF =  -200
//               End;
//
//               if (idfxa[i] > -150)  And (idfxa[i] < -51)  Then
//               Begin
//                    Inc(bins[9]);   //  -151 ... -50  CF =  -100
//               End;
//
//               if (idfxa[i] > -50)   And (idfxa[i] < 51)  Then
//               Begin
//                    Inc(bins[10]);   //  -51  ...  50  CF =  0
//               End;
//
//               if (idfxa[i] > 50)    And (idfxa[i] < 151) Then
//               Begin
//                    Inc(bins[11]);   //   51 ...  150  CF =  100
//               End;
//
//               if (idfxa[i] > 150)   And (idfxa[i] < 251) Then
//               Begin
//                    Inc(bins[12]);   //   151 ... 250 CF  =  200
//               End;
//
//               if (idfxa[i] > 250)   And (idfxa[i] < 351) Then
//               Begin
//                    Inc(bins[13]);   //   251 ... 350 CF  =  300
//               End;
//
//               if (idfxa[i] > 350)   And (idfxa[i] < 451) Then
//               Begin
//                    Inc(bins[14]);   //   351 ... 450 CF  =  400
//               End;
//
//               if (idfxa[i] > 450)   And (idfxa[i] < 551) Then
//               Begin
//                    Inc(bins[15]);   //   451 ... 550 CF  =  500
//               End;
//
//               if (idfxa[i] > 550)   And (idfxa[i] < 651) Then
//               Begin
//                    Inc(bins[16]);   //   551 ... 650 CF  =  600
//               End;
//
//               if (idfxa[i] > 650)   And (idfxa[i] < 751) Then
//               Begin
//                    Inc(bins[17]);   //   651 ... 750 CF  =  700
//               End;
//
//               if (idfxa[i] > 750)   And (idfxa[i] < 851) Then
//               Begin
//                    Inc(bins[18]);   //   751 ... 850 CF  =  800
//               End;
//
//               if (idfxa[i] > 850)   And (idfxa[i] < 951) Then
//               Begin
//                    Inc(bins[19]);   //   851 ... 950 CF  =  900
//               End;
//
//               if (idfxa[i] > 950)   And (idfxa[i] < 1051) Then
//               Begin
//                    Inc(bins[20]);  //   951 ... 1050 CF =  1000
//               End;
//          end;
//     end;
//
//     if added Then
//     Begin
//          FBar1.Clear;
//          j := -10;
//          For i := 0 to 20 do
//          Begin
//               FBar1.AddXY(j, bins[i]);
//               inc(j);
//          end;
//     end;
//
//     for i := 0 to 20 do bins[i] := 0;
//
//     wif := StrAlloc(0);
//     setLength(fBuffer,0);
//     setLength(lBuffer,0);
//     setLength(iBuffer,0);
//
//end;

//procedure TForm1.genTX(const msg : String; const txdf : Integer; const plevel : Integer; var samples : Array of CTypes.cint16);
procedure TForm1.genTX(const msg : String; const txdf : Integer; const plevel : Integer);
Var
   foo, sh       : String;
   form          : String;
   i,dir,cnt,j,k : CTypes.cint;
   nc1,nc2,ng    : LongWord;
   ng1           : LongWord;
   nc1t,nc2t,ngt : String;
   pfxt,sfxt     : String;
   sbasetx       : String;
   syms          : Array[0..11] Of CTypes.cint;
   tsyms         : Array[0..62] Of CTypes.cint;
   fsyms         : Array[0..62] Of CTypes.cfloat;
   isyms         : Array[0..62] Of CTypes.cint;
   isymsL,isymsR : Array[0..62] Of CTypes.cint;
   ssyms         : Array[0..62] Of String;
   ssymsL,ssymsR : Array[0..62] Of String;
   sm, ft, shm   : Boolean;
   nsamps        : CTypes.cint;
   shmsg         : CTypes.cint;
   baseTX,tf     : CTypes.cfloat;
begin
     nc1t := '';
     pfxt := '';
     sfxt := '';
     nc2t := '';
     ngt  := '';
     sh   := '';

     sm   := False; // Structured message type
     ft   := False; // Free text message type
     shm  := False; // Shorthand message type

     foo := TrimLeft(TrimRight(UpCase(msg)));

     if messageParser(foo, nc1t, pfxt, sfxt, nc2t, ngt, sh) Then
     Begin
          sm := True;
          if (sh='RO') or (sh='RRR') or (sh='ATT') or (sh='73') Then
          Begin
               sm  := false;
               ft  := false;
          end
          else
          begin
               shm := true;
          end;
     end
     else
     begin
          If Length(foo) > 13 Then foo := foo[1..13];
          if isFText(foo) Then
          Begin
               ft := True;
          end;
     end;
     // If sm this is a structured message
     if sm then
     begin
          nc1 := 0;
          nc2 := 0;
          ng  := 0;
          nc2 := gCall(nc2t);
          ng1 := 0;
          gGrid(ngt,ng1);
          ng  := ng1;
          if Length(TrimLeft(TrimRight(DelSpace1(UpCase(pfxt))))) > 0 Then
          Begin
               pfxt := TrimLeft(TrimRight(DelSpace1(UpCase(pfxt))));
               form := TrimLeft(TrimRight(DelSpace1(UpCase(nc1t))));
               nc1 := gPrefix(form,pfxt);
          end;
          if Length(TrimLeft(TrimRight(DelSpace1(UpCase(sfxt))))) > 0 Then
          Begin
               sfxt := TrimLeft(TrimRight(DelSpace1(UpCase(sfxt))));
               form := TrimLeft(TrimRight(DelSpace1(UpCase(nc1t))));
               nc1 := gSuffix(form,sfxt);
          end;
          If (Length(TrimLeft(TrimRight(DelSpace1(pfxt))))= 0) And (Length(TrimLeft(TrimRight(DelSpace1(sfxt))))= 0) Then
          Begin
               If (nc1t = 'CQ') or (nc1t = 'QRZ') or (nc1t = 'DE') Then
               Begin
                    sfxt := '';
                    pfxt := '';
                    form := TrimLeft(TrimRight(DelSpace1(UpCase(nc1t))));
                    nc1  := gPrefix(form,pfxt);
               end
               else
               begin
                    nc1 := gCall(nc1t);
               end;
          end;
          for i := 0 to 11 do syms[i] := 0;
          for i := 0 to 62 do tsyms[i] := 0;
          if gSyms(nc1,nc2,ng,syms) Then
          Begin
               rscode(CTypes.pcint(@syms[0]),CTypes.pcint(@tsyms[0]));
               dir := 1;
               interleave(CTypes.pcint(@tsyms[0]),CTypes.pcint(@dir));
               dir := 1;
               cnt := 63;
               graycode(CTypes.pcint(@tsyms[0]),CTypes.pcint(@cnt),CTypes.pcint(@dir));
               nsamps := 0;
               shmsg := 0;
               // tsyms holds the 63 TX symbols - will need to look at TXDF and current dial
               // RX QRG to compute the true RF TX QRG list.  TXDF 0 = 1270.5 Hz so if dial
               // is 14076.0 and TXDF = 0 then first tone (sync) will be at 14,077,270.5 Hz
               // What I want to do is create an array of 63 floats for the TX data frequencies
               // and a 64th element that is the sync (same in 63 places).  Then convert to
               // string then drop the MHz and 100 KHz (first 3 characters on 20M/first 2 on 40M
               // then remove the decimal - as in the example above of 14,077,270.5 would be
               // 772705
               //tsyms         : Array[0..62] Of CTypes.cint;
               //fsyms         : Array[0..62] Of CTypes.cfloat;
               //isyms         : Array[0..62] Of CTypes.cint;
               //ssyms         : Array[0..62] Of String;
               // So.... tone 0 (sync) = Dial QRG + 1270.5
               baseTX := 1270.5;
               // Now add the dial QRG
               tf := StrToFloat(edDialQRG.Text);
               if tf > 10200000.0 Then tf := tf - 14000000.0 else tf := tf - 7000000.0;
               //tf := tf + 0.002;
               // Now add the DF
               baseTX := baseTX+tf+txdf;
               //Memo1.Clear;
               //Memo1.Append('Sync at:  ' + FloatToStrF(baseTX,ffFixed,9,1));
               tf := StrToFloat(edDialQRG.Text);
               if tf > 10200000.0 Then sbasetx := '140' + FloatToStrF(baseTX,ffFixed,9,1) else sbasetx := '70' + FloatToStrF(baseTX,ffFixed,9,1);
               sbasetx := ExtractWord(1,sbasetx,['.']) + ExtractWord(2,sbasetx,['.']);
               //tf := txdf*1.0;
               //baseTX := baseTX + tf;
               // Have the sync RF carrier QRG - can now create the data values
               // based on the protocol definition as;
               // Encoded user information is transmitted during the 63 intervals not used for the sync tone.
               // Each channel symbol generates a tone at frequency 1270.5 + 2.6917 (N+2)m Hz, where
               // N is the integral symbol value, 0 ≤ N ≤ 63, and m assumes the values 1, 2, and 4 for JT65
               // sub-modes A, B, and C.
               // Not dealing with modes B/C so we have baseTX + 2.6917 (N+2) for (2) ... (65) for
               // baseTX + 5.3834 ... baseTX + 174.9605
               // Remember a symbol can range from 0...63 as it's a 6 bit value.
               // Starting this by creating an array of the audio tone values (will simplify later - this will
               // be easier to debug though)
               for i := 0 to 62 do
               begin
                    fsyms[i] := 0.0;
                    isyms[i] := 0;
                    isymsL[i] := 0;
                    isymsR[i] := 0;
                    ssyms[i] := '';
                    ssymsL[i] := '';
                    ssymsR[i] := '';
               end;
               for i := 0 to 62 do
               begin
                    // computing 63 audio frequency values from tsyms[i] into fsyms[i]
                    fsyms[i] := baseTX + (2.6917 * (tsyms[i]+2));
               end;
               // Have the audio tones - now add the RF
               //for i := 0 to 62 do
               //begin
               //     fsyms[i] := fsyms[i] + StrToFloat(edDialQRG.Text);
               //end;
               // Have carrier frequencies - now DF adjust
               for i := 0 to 62 do
               begin
                    fsyms[i] := fsyms[i] + (txdf/1.0);
               end;
               // This should be the real carrier frequencies we need to TX --- emphasis on should :)
               // Lets get rid of MHz
               //for i := 0 to 62 do
               //begin
               //     if fsyms[i] > 10000000.0 then fsyms[i] := fsyms[i]-14000000.0 else fsyms[i] := fsyms[i]-7000000.0;
               //end;
               // Okies - have just the KHz portion now and I want that down to one fractional resolution BUT
               // after too many years of this I DO NOT TRUST Laz/FPC or anything else to do it right. :(
               // Step one - floats to strings
               for i := 0 to 62 do
               begin
                    ssyms[i] := FloatToStrF(fsyms[i],ffFixed,8,4);
               end;
               // Now I ****should**** have a series of strings like 77275.8834 77445.4605 etc
               // I want to end up with 77275.9 and 77445.5 for the above :)
               // Ok - first things first - let me be absolutely sure I'm dealing with nothing but ###.####
               // no blasted , as decimal or otherwise present.
               for i := 0 to 62 do
               begin
                    If AnsiContainsText(ssyms[i],',') Then
                    Begin
                         // Decimal is , split accordingly
                         ssymsL[i] := ExtractWord(1,ssyms[i],[',']);
                         ssymsR[i] := ExtractWord(2,ssyms[i],[',']);
                         j := i;
                    end;
                    If AnsiContainsText(ssyms[i],'.') Then
                    Begin
                         // Decimal is . split accordingly
                         ssymsL[i] := ExtractWord(1,ssyms[i],['.']);
                         ssymsR[i] := ExtractWord(2,ssyms[i],['.']);
                         j := i;
                    end;
                    If AnsiContainsText(ssyms[i],',') And AnsiContainsText(ssyms[i],'.') Then
                    Begin
                         // EXPLODE CUSS AND KICK
                         j := i;
                    end;
               end;
               // Start conversion to integer format
               for i := 0 to 62 do
               begin
                    isymsL[i] := StrToInt(ssymsL[i]);
                    if length(ssymsR[i]) = 4 Then
                    Begin
                         j := StrToInt(ssymsR[i][4]);
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][3]);
                         j := j+k;
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][2]);
                         j := j+k;
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][1]);
                         j := j+k;
                         if j > 9 then
                         Begin
                              inc(isymsL[i]);
                              j := 0;
                         end;
                         isymsR[i] := j;
                    end;
                    if length(ssymsR[i]) = 3 Then
                    Begin
                         j := StrToInt(ssymsR[i][3]);
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][2]);
                         j := j+k;
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][1]);
                         j := j+k;
                         if j > 9 then
                         Begin
                              inc(isymsL[i]);
                              j := 0;
                         end;
                         isymsR[i] := j;
                    end;
                    if length(ssymsR[i]) = 2 Then
                    Begin
                         j := StrToInt(ssymsR[i][2]);
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][1]);
                         j := j+k;
                         if j > 9 then
                         Begin
                              inc(isymsL[i]);
                              j := 0;
                         end;
                         isymsR[i] := j;

                    end;
                    if length(ssymsR[i]) = 1 Then
                    Begin
                         // Nothing
                    end;
               end;
               // Ok - I think I now have what I need
               for i := 0 to 62 do
               begin
                    ssyms[i] := IntToStr(isymsL[i])+IntToStr(isymsR[i]);
                    isyms[i] := StrToInt(ssyms[i]);
               end;
               i := 0;
               // Need to think of a sanity check here... given typical usage I should be able to define a range of isyms value that makes sense.
               // 752705 (14075 Dial -1K DF - 200) 750705 --- call it 750000
               // 792705 (14077 Dial +1K DF + 200) 794705 --- call it 795000
               // I ***do not*** intend to leave this since it would hard limit the program to running at 7075000 ... 7077000 or 14075000 ... 14077000
               //for i := 0 to 62 do
               //begin
                    //if (isyms[i] < 750000) or (isyms[i] > 795000) Then ShowMessage('FSK QRG Range oddity at symbol ' + IntToStr(i) + ' for ' + IntToStr(isyms[i]));
               //end;
               Memo1.Append('LTX');
               Memo1.Append(sbasetx);
               for i := 0 to 63 do qrgset[i] := '';
               qrgset[0] := sbasetx;
               for i := 1 to 63 do
               Begin
                    Memo1.Append(IntToStr(isyms[i-1]));
                    qrgset[i] := IntToStr(isyms[i-1]);
               end;
               txDirty := True;  // Flag to force an update to the FSK TX
               //function TForm1.rebelCommand(const cmd : String; const value : String; const ltx : Array of String; var error : String) : Boolean;
               // Since this only makes sense if I'm working with a Rebel I'd call rebelCommand from here as in
               // rebelCommand('LTX','',qrgset,foo);
               // Though... I need to make qrgset global scope as it will be needed elsewhere (done)
               //gSamps(CTypes.pcint(@txdf),CTypes.pcint(@tsyms),CTypes.pcint(@shmsg),CTypes.pcint16(@samples[11025]),CTypes.pcint(@nsamps),CTypes.pcint(@plevel));
          end;
     end;
     //If ft this is free text
     if ft then
     begin
          nc1 := 0;
          nc2 := 0;
          ng  := 0;
          gText(foo,nc1,nc2,ng);
          for i := 0 to 11 do syms[i] := 0;
          for i := 0 to 62 do tsyms[i] := 0;
          if gSyms(nc1,nc2,ng,syms) Then
          Begin
               rscode(CTypes.pcint(@syms),CTypes.pcint(@tsyms));
               dir := 1;
               interleave(CTypes.pcint(@tsyms[0]),CTypes.pcint(@dir));
               dir := 1;
               cnt := 63;
               graycode(CTypes.pcint(@tsyms[0]),CTypes.pcint(@cnt),CTypes.pcint(@dir));
               nsamps := 0;
               shmsg := 0;
               // tsyms holds the 63 TX symbols - will need to look at TXDF and current dial
               // RX QRG to compute the true RF TX QRG list.  TXDF 0 = 1270.5 Hz so if dial
               // is 14076.0 and TXDF = 0 then first tone (sync) will be at 14,077,270.5 Hz
               // What I want to do is create an array of 63 floats for the TX data frequencies
               // and a 64th element that is the sync (same in 63 places).  Then convert to
               // string then drop the MHz and 100 KHz (first 3 characters on 20M/first 2 on 40M
               // then remove the decimal - as in the example above of 14,077,270.5 would be
               // 772705
               //tsyms         : Array[0..62] Of CTypes.cint;
               //fsyms         : Array[0..62] Of CTypes.cfloat;
               //isyms         : Array[0..62] Of CTypes.cint;
               //ssyms         : Array[0..62] Of String;
               // So.... tone 0 (sync) = Dial QRG + 1270.5
               baseTX := 1270.5;
               // Now add the dial QRG
               tf := StrToFloat(edDialQRG.Text);
               if tf > 10200000.0 Then tf := tf - 14000000.0 else tf := tf - 7000000.0;
               //tf := tf + 0.002;
               // Now add the DF
               baseTX := baseTX+tf+txdf;
               //Memo1.Clear;
               //Memo1.Append('Sync at:  ' + FloatToStrF(baseTX,ffFixed,9,1));
               tf := StrToFloat(edDialQRG.Text);
               if tf > 10200000.0 Then sbasetx := '140' + FloatToStrF(baseTX,ffFixed,9,1) else sbasetx := '70' + FloatToStrF(baseTX,ffFixed,9,1);
               sbasetx := ExtractWord(1,sbasetx,['.']) + ExtractWord(2,sbasetx,['.']);
               //tf := txdf*1.0;
               //baseTX := baseTX + tf;
               // Have the sync RF carrier QRG - can now create the data values
               // based on the protocol definition as;
               // Encoded user information is transmitted during the 63 intervals not used for the sync tone.
               // Each channel symbol generates a tone at frequency 1270.5 + 2.6917 (N+2)m Hz, where
               // N is the integral symbol value, 0 ≤ N ≤ 63, and m assumes the values 1, 2, and 4 for JT65
               // sub-modes A, B, and C.
               // Not dealing with modes B/C so we have baseTX + 2.6917 (N+2) for (2) ... (65) for
               // baseTX + 5.3834 ... baseTX + 174.9605
               // Remember a symbol can range from 0...63 as it's a 6 bit value.
               // Starting this by creating an array of the audio tone values (will simplify later - this will
               // be easier to debug though)
               for i := 0 to 62 do
               begin
                    fsyms[i] := 0.0;
                    isyms[i] := 0;
                    isymsL[i] := 0;
                    isymsR[i] := 0;
                    ssyms[i] := '';
                    ssymsL[i] := '';
                    ssymsR[i] := '';
               end;
               for i := 0 to 62 do
               begin
                    // computing 63 audio frequency values from tsyms[i] into fsyms[i]
                    fsyms[i] := baseTX + (2.6917 * (tsyms[i]+2));
               end;
               // Have the audio tones - now add the RF
               //for i := 0 to 62 do
               //begin
               //     fsyms[i] := fsyms[i] + StrToFloat(edDialQRG.Text);
               //end;
               // Have carrier frequencies - now DF adjust
               for i := 0 to 62 do
               begin
                    fsyms[i] := fsyms[i] + (txdf/1.0);
               end;
               // This should be the real carrier frequencies we need to TX --- emphasis on should :)
               // Lets get rid of MHz
               //for i := 0 to 62 do
               //begin
               //     if fsyms[i] > 10000000.0 then fsyms[i] := fsyms[i]-14000000.0 else fsyms[i] := fsyms[i]-7000000.0;
               //end;
               // Okies - have just the KHz portion now and I want that down to one fractional resolution BUT
               // after too many years of this I DO NOT TRUST Laz/FPC or anything else to do it right. :(
               // Step one - floats to strings
               for i := 0 to 62 do
               begin
                    ssyms[i] := FloatToStrF(fsyms[i],ffFixed,8,4);
               end;
               // Now I ****should**** have a series of strings like 77275.8834 77445.4605 etc
               // I want to end up with 77275.9 and 77445.5 for the above :)
               // Ok - first things first - let me be absolutely sure I'm dealing with nothing but ###.####
               // no blasted , as decimal or otherwise present.
               for i := 0 to 62 do
               begin
                    If AnsiContainsText(ssyms[i],',') Then
                    Begin
                         // Decimal is , split accordingly
                         ssymsL[i] := ExtractWord(1,ssyms[i],[',']);
                         ssymsR[i] := ExtractWord(2,ssyms[i],[',']);
                         j := i;
                    end;
                    If AnsiContainsText(ssyms[i],'.') Then
                    Begin
                         // Decimal is . split accordingly
                         ssymsL[i] := ExtractWord(1,ssyms[i],['.']);
                         ssymsR[i] := ExtractWord(2,ssyms[i],['.']);
                         j := i;
                    end;
                    If AnsiContainsText(ssyms[i],',') And AnsiContainsText(ssyms[i],'.') Then
                    Begin
                         // EXPLODE CUSS AND KICK
                         j := i;
                    end;
               end;
               // Start conversion to integer format
               for i := 0 to 62 do
               begin
                    isymsL[i] := StrToInt(ssymsL[i]);
                    if length(ssymsR[i]) = 4 Then
                    Begin
                         j := StrToInt(ssymsR[i][4]);
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][3]);
                         j := j+k;
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][2]);
                         j := j+k;
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][1]);
                         j := j+k;
                         if j > 9 then
                         Begin
                              inc(isymsL[i]);
                              j := 0;
                         end;
                         isymsR[i] := j;
                    end;
                    if length(ssymsR[i]) = 3 Then
                    Begin
                         j := StrToInt(ssymsR[i][3]);
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][2]);
                         j := j+k;
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][1]);
                         j := j+k;
                         if j > 9 then
                         Begin
                              inc(isymsL[i]);
                              j := 0;
                         end;
                         isymsR[i] := j;
                    end;
                    if length(ssymsR[i]) = 2 Then
                    Begin
                         j := StrToInt(ssymsR[i][2]);
                         if j>5 Then k := 1 else k := 0;
                         j := StrToInt(ssymsR[i][1]);
                         j := j+k;
                         if j > 9 then
                         Begin
                              inc(isymsL[i]);
                              j := 0;
                         end;
                         isymsR[i] := j;

                    end;
                    if length(ssymsR[i]) = 1 Then
                    Begin
                         // Nothing
                    end;
               end;
               // Ok - I think I now have what I need
               for i := 0 to 62 do
               begin
                    ssyms[i] := IntToStr(isymsL[i])+IntToStr(isymsR[i]);
                    isyms[i] := StrToInt(ssyms[i]);
               end;
               i := 0;
               // Need to think of a sanity check here... given typical usage I should be able to define a range of isyms value that makes sense.
               // 752705 (14075 Dial -1K DF - 200) 750705 --- call it 750000
               // 792705 (14077 Dial +1K DF + 200) 794705 --- call it 795000
               // I ***do not*** intend to leave this since it would hard limit the program to running at 7075000 ... 7077000 or 14075000 ... 14077000
               //for i := 0 to 62 do
               //begin
                    //if (isyms[i] < 750000) or (isyms[i] > 795000) Then ShowMessage('FSK QRG Range oddity at symbol ' + IntToStr(i) + ' for ' + IntToStr(isyms[i]));
               //end;
               Memo1.Append('LTX');
               Memo1.Append(sbasetx);
               for i := 0 to 63 do qrgset[i] := '';
               qrgset[0] := sbasetx;
               for i := 1 to 63 do
               Begin
                    Memo1.Append(IntToStr(isyms[i-1]));
                    qrgset[i] := IntToStr(isyms[i-1]);
               end;
               txDirty := True;  // Flag to force an update to the FSK TX
               //gSamps(CTypes.pcint(@i),CTypes.pcint(@tsyms),CTypes.pcint(@shmsg),CTypes.pcint16(@samples[11025]),CTypes.pcint(@nsamps),CTypes.pcint(@plevel));
          end;
     end;
     //If shm it's shorthand
     //if shm Then
     //begin
     //     // Lets play shorthand
     //     ListBox1.Items.Add('Encoding shorthand message');
     //     setLength(samps2,661500);
     //     for i := 0 to 661499 do samps[i] := 0;
     //     txdf := 0;
     //     nsamps := 0;
     //     shmsg := 0;
     //     if sh = 'ATT' Then shmsg := 1;
     //     if sh = 'RO'  Then shmsg := 2;
     //     if sh = 'RRR' Then shmsg := 3;
     //     if sh = '73'  Then shmsg := 4;
     //     //procedure  gSamps(Ptxdf,Ptsysms,Pshmsg,Psamples,Psamplescount : Pointer); cdecl; external JL_DLL name 'gen65_';
     //     gSamps(@txdf,@tsyms,@shmsg,@samps,@nsamps);
     //     for i := 0 to 11024 do samps2[i] := 0;
     //     for i := 11025 to 11025+nsamps do samps2[i] := samps[i-11025];
     //     j := i+1;
     //     for i := j to 661499 do samps2[i] := 0;
     //     for i := 0 to 661499 do samps[i] := 0;
     //     for i := 0 to 661499 do samps[i] := samps2[i];
     //     setLength(samps2,0);
     //     ListBox1.Items.Add('');
     //     ListBox1.Items.Add('Samples created.  Attempting demodulation/decode.');
     //     ListBox1.Items.Add('');
     //     for i := 0 to 11 do syms[i] := 0;
     //     if demodulate(samps, syms) Then
     //     Begin
     //          ListBox1.Items.Add('');
     //          foo := '';
     //          for i := 0 to 11 do foo := foo + IntToStr(syms[i]) + ' ';
     //          ListBox1.Items.Add('Raw demodulator symbols:  ' + foo);
     //          ListBox1.Items.Add('Raw demodulator symbols back to nc1, nc2 and ng...');
     //          ListBox1.Items.Add('');
     //          if dSyms(nc1,nc2,ng,syms) Then
     //          Begin
     //               if dText(foo,nc1,nc2,ng) Then ListBox1.Items.Add('JT65V2 Decoder:  ' + TrimLeft(TrimRight(foo))) Else ListBox1.Items.Add('JT65V2 Text Decoder fails.');
     //          end
     //          else
     //          begin
     //               ListBox1.Items.Add('Text decode failed.');
     //          end;
     //     end
     //     else
     //     begin
     //          ListBox1.Items.Add('Demodulator returns False');
     //     end;
     //end;
end;

procedure TForm1.txControlClick(Sender: TObject);
begin
     If txrequested then
     begin
          txrequested := False;
          txControl.Caption := 'Enable TX';
     end
     else
     begin
          txrequested := True;
          txControl.Caption := 'Disable TX';
     end;
end;

procedure TForm1.mgenClick(Sender: TObject);
Var
   foo : String;
begin
     thisTXmsg := '';
     if Sender = bCQ Then
     Begin
          thisTXmsg := 'CQ ' + thisTXCall + ' ' + thisTXgrid;
          edTXMsg.Text := thisTXmsg;

     end;
     if Sender = bQRZ Then
     Begin
          thisTXmsg := 'QRZ ' + thisTXCall + ' ' + thisTXgrid;
          edTXMsg.Text := thisTXmsg;
     end;
     if Sender = bDE Then
     Begin
          thisTXmsg := 'DE ' + thisTXCall + ' ' + thisTXgrid;
          edTXMsg.Text := thisTXmsg;
     end;
     if Sender = b73x Then
     Begin
          thisTXmsg := 'DE ' + thisTXCall + ' 73';
          edTXMsg.Text := thisTXmsg;
     end;
     if Sender = bACQ Then
     Begin
          foo := getLocalGrid;
          if length(foo)>4 then foo := foo[1..4];
          thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(edCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(foo)));
          edTXMsg.Text := thisTXmsg;
     end;
     if Sender = bReport Then
     Begin
          thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(edCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(edTXReport.Text)));
          edTXMsg.Text := thisTXmsg;
     end;
     if Sender = bRReport Then
     Begin
          thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(edCall.Text))) + ' R' + TrimLeft(TrimRight(UpCase(edTXReport.Text)));
          edTXMsg.Text := thisTXmsg;
     end;
     if Sender = bRRR Then
     Begin
          thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(edCall.Text))) + ' RRR';
          edTXMsg.Text := thisTXmsg;
     end;
     if Sender = b73 Then
     Begin
          thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(edCall.Text))) + ' 73';
          edTXMsg.Text := thisTXmsg;
     end;
     if length(thisTXmsg)>1 Then
     Begin
          genTX(thisTXmsg, StrToInt(edTXDF.Text), 100);
     end;
end;

procedure TForm1.rbOnChange(Sender: TObject);
begin
     if length(edRBCall.Text) <3 Then
     Begin
          edRBCall.Text := '';
          if length(edCall.Text) > 0 Then edRBCall.Text := edCall.Text;
          if length(edPrefix.Text) > 0 Then edRBCall.Text := edPrefix.Text + '/' + edRBCall.Text;
          if length(edSuffix.Text) > 0 Then edRBCall.Text := edRBCall.Text + '/' + edSuffix.Text;
     end;
end;

procedure TForm1.edTXMsgDblClick(Sender: TObject);
begin
     edTXMsg.Clear;
end;

//procedure TForm1.CheckBox2Change(Sender: TObject);
//begin
     {TODO Fix}
     //If cbUseSerial.Checked Then Label12.Caption := 'PTT is enabled' else Label12.Caption := 'PTT is disabled';
//end;

procedure TForm1.edRXDFChange(Sender: TObject);
begin
     if cbTXeqRXDF.Checked Then edTXDF.Text := edRXDF.Text;
end;

procedure TForm1.edRXDFDblClick(Sender: TObject);
begin
     edRXDF.Text := '0';
end;

procedure TForm1.edTXDFDblClick(Sender: TObject);
begin
     edTXDF.Text := '0';
end;

procedure TForm1.edTXReportDblClick(Sender: TObject);
begin
     edTXReport.Text := '';
end;

procedure TForm1.edTXtoCallDblClick(Sender: TObject);
begin
     edTXtoCall.Text := '';
end;

procedure TForm1.LogQSOClick(Sender: TObject);
begin
     { TODO : Actually log things :) }
     Waterfall1.Visible   := True;
     Chart1.Visible       := True;
     buttonConfig.Visible := True;
     groupLogQSO.Visible  := False;
     // Do logging

     // Clear log record for next time
     logEntry.timeOn     := '';
     logEntry.timeOff    := '';
     logEntry.aCall      := '';
     logEntry.sigtx      := '';
     logEntry.sigrx      := '';
     logEntry.qrg        := '';
     logEntry.plvl       := '';
     logEntry.comment    := '';
     logEntry.haveMySig  := False;
     logEntry.allNew     := True;
     logEntry.inProgress := False;
     newLog              := True;
end;

procedure TForm1.Memo1DblClick(Sender: TObject);
begin
     Memo1.Clear;
end;

procedure TForm1.Memo2DblClick(Sender: TObject);
begin
     memo2.Clear;
end;

procedure TForm1.Memo3DblClick(Sender: TObject);
begin
     Memo3.Clear;
end;

procedure TForm1.PageControlChange(Sender: TObject);
begin

end;

procedure TForm1.qrgdbAfterPost(DataSet: TDataSet);
Var
   fs  : String;
   fsc : String;
   ff  : Double;
   fi  : Integer;
begin
     fs  := '';
     ff  := 0.0;
     fi  := 0;
     fs  := DataSet.FieldValues['FQRG'];
     fsc := '';
     // Attempt to convert to integer assuming someing in Khz would be > 1799.9
     // and something in MHz < 1800.0
     // evalQRG(const qrg : String; const mode : string; var qrgk : Double; var qrghz : Integer; var asciiqrg : String) : Boolean;
     mval.forceDecimalAmer := False;
     mval.forceDecimalEuro := False;
     if not mval.evalQRG(fs,'STRICT',ff,fi,fsc) Then
     Begin
          ListBox1.Items.Insert(0,'Added QRG is invalid.');
          //DataSet.FieldValues['FQRG'] := '0.0';
     end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
     ListBox1.Clear;
end;

procedure TForm1.audioChange(Sender: TObject);
Var
   foo,ttadc  : String;
   paResult  : TPaError;
   iadcText  : String;
begin
     // Handle change to and saving of audio device setting
     If Sender = comboAudioIn Then
     Begin
          // Audio Input device change.  Set PA to new device and update DB
          ListBox2.Items.Insert(0,'Changing PortAudio input device');
          foo := comboAudioIn.Items.Strings[comboAudioIn.ItemIndex];
          ttadc := foo;
          if foo[1] = '0' Then iadcText := foo[2] else iadcText := foo[1..2];
          portAudio.Pa_AbortStream(paInStream);
          portAudio.Pa_CloseStream(paInStream);
          ListBox2.Items.Insert(0,'Closed former stream');

          //paInStream := Nil;

          // Input
          if cbUseMono.Checked Then
          Begin
               paInParams.channelCount := 1;
               adc.adcMono := True;
               ListBox2.Items.Insert(0,'Using Mono');
          end
          else
          begin
               paInParams.channelCount := 2;
               adc.adcMono := False;
               ListBox2.Items.Insert(0,'Using Stereo');
          end;
          paInParams.device := StrToInt(iadcText);
          paInParams.sampleFormat := paInt16;
          paInParams.suggestedLatency := 1;
          paInParams.hostApiSpecificStreamInfo := Nil;
          ppaInParams := @paInParams;
          // Set rxBuffer index to start of array.
          adc.d65rxBufferIdx := 0;
          adc.adcTick := 0;
          adc.adcECount := 0;
          adc.adcChan := 1;
          adc.adcLDgain := 0;
          adc.adcRDgain := 0;
          adcSpecAvg1 := 0;
          adcSpecAvg2 := 0;
          // Attempt to open selected devices, both must pass open/start to continue.
          // Initialize RX stream.
          paResult := portaudio.Pa_OpenStream(PPaStream(paInStream),PPaStreamParameters(ppaInParams),PPaStreamParameters(Nil),CTypes.cdouble(11025.0),CTypes.culong(64),TPaStreamFlags(0),PPaStreamCallback(@adc.adcCallback),Pointer(Self));
          if paResult <> 0 Then
          Begin
               // Was unable to open RX.
               ShowMessage('Unable to start PA RX Stream.');
               Halt;
          end;
          // Start the RX stream.
          paResult := portaudio.Pa_StartStream(paInStream);
          if paResult <> 0 Then
          Begin
               // Was unable to start RX stream.
               ShowMessage('Unable to start PA RX Stream.');
               Halt;
          end;
          ListBox2.Items.Insert(0,'Changed input to device:  ' + IntToStr(paInParams.device));
          ListBox2.Items.Insert(0,'Changed input to device:  ' + IntToStr(paInParams.device));
     end;

end;

procedure TForm1.comboQRGListChange(Sender: TObject);
Var
   fs  : String;
   fsc : String;
   ff  : Double;
   fi  : Integer;
begin
     editQRG.Text := comboQRGList.Items.Strings[comboQRGList.ItemIndex];
     fs  := '';
     ff  := 0.0;
     fi  := 0;
     fs  := TrimLeft(TrimRight(editQRG.Text));
     fsc := '';
     mval.forceDecimalAmer := False;
     mval.forceDecimalEuro := False;
     // TODO Decimal?
     if not mval.evalQRG(fs,'STRICT',ff,fi,fsc) Then
     Begin
          editQRG.Text := '0';
     end
     else
     begin
          edDialQRG.Text := IntToStr(fi);
          btnsetQRGClick(btnsetQRG);
     end;
end;

procedure TForm1.comboMacroListChange(Sender: TObject);
begin
     edTXMsg.Text := comboMacroList.Items.Strings[comboMacroList.ItemIndex];
end;

procedure TForm1.Button13Click(Sender: TObject);
begin
     GroupBox16.Visible := False;
end;

procedure TForm1.Button14Click(Sender: TObject);
begin
     GroupBox16.Visible := True;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
     Waterfall1.Visible   := False;
     Chart1.Visible       := False;
     buttonConfig.Visible := False;
     PageControl.Visible  := False;
     groupLogQSO.visible  := True;
end;

procedure TForm1.cbSpecSmoothChange(Sender: TObject);
begin

end;

procedure TForm1.btnsetQRGClick(Sender: TObject);
Var
   fs  : String;
   fsc : String;
   ff  : Double;
   fi  : Integer;
begin
     fs  := '';
     ff  := 0.0;
     fi  := 0;
     fs  := TrimLeft(TrimRight(editQRG.Text));
     fsc := '';
     mval.forceDecimalAmer := False;
     mval.forceDecimalEuro := False;
     if not mval.evalQRG(fs,'STRICT',ff,fi,fsc) Then
     Begin
          editQRG.Text := '0';
     end
     else
     begin
          edDialQRG.Text := IntToStr(fi);
          qsyQRG := fi;
          setQRG := True;
          forceCAT := True;
     end;

end;


procedure TForm1.buttonConfigClick(Sender: TObject);
begin
     Waterfall1.Visible   := False;
     Chart1.Visible       := False;
     buttonConfig.Visible := False;
     Button4.Visible      := True;
     PageControl.Visible := True;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
     if length(edRBCall.Text) <3 Then
     Begin
          edRBCall.Text := '';
          if length(edCall.Text) > 0 Then edRBCall.Text := edCall.Text;
          if length(edPrefix.Text) > 0 Then edRBCall.Text := edPrefix.Text + '/' + edRBCall.Text;
          if length(edSuffix.Text) > 0 Then edRBCall.Text := edRBCall.Text + '/' + edSuffix.Text;
     end;
     // Validate prefix (if present)
     canTX := True;
     if length(edPrefix.Text)>0 Then
     Begin
          if not mval.evalPrefix(edPrefix.Text) Then
          Begin
               ShowMessage('Invalid prefix.' + sLineBreak + 'Must be no more than 4 characters' + sLineBreak + 'of letters A to Z and/or numerals 0 to 9' + sLineBreak +'TX is disabled.');
               canTX := False;
          end;
     end;
     // Validate callsign
     if not mval.evalCSign(edCall.Text) Then
     Begin
          ShowMessage('Invalid callsign.' + sLineBreak + 'Must be no more than 6 characters' + sLineBreak + 'of letters A to Z and/or numerals 0 to 9' + sLineBreak +'TX is disabled.' + sLineBreak + 'See manual for valid forms of callsigns in JT65 protocol.');
          canTX := False;
     end;
     // Validate suffix (if present)
     if length(edSuffix.Text)>0 Then
     Begin
          if not mval.evalSuffix(edSuffix.Text) Then
          Begin
               ShowMessage('Invalid suffix.' + sLineBreak + 'Must be no more than 3 characters' + sLineBreak + 'of letters A to Z and/or numerals 0 to 9' + sLineBreak +'TX is disabled.');
               canTX := False;
          end;
     end;
     // Validate grid
     if not mval.evalGrid(edGrid.Text) Then
     Begin
          canTX := False;
          showmessage('The entered grid square is not valid' + sLineBreak + 'TX is disabled.');
     end;

     if canTX Then ListBox2.Items.Insert(0,'After config save CAN transmit') else ListBox2.Items.Insert(0,'After config save CAN NOT transmit.');

     Waterfall1.Visible   := True;
     Chart1.Visible       := True;
     buttonConfig.Visible := True;
     Button4.Visible      := False;
     PageControl.Visible := False;
     updateDB;
end;

procedure TForm1.comboTTYPortsChange(Sender: TObject);
begin
     if comboTTYPorts.Items.Strings[comboTTYPorts.ItemIndex] = 'None' Then
     Begin
          edPort.Text := '-1';
     end
     else
     begin
          if length(comboTTYPorts.Items.Strings[comboTTYPorts.ItemIndex]) = 4 Then edPort.Text := comboTTYPorts.Items.Strings[comboTTYPorts.ItemIndex][4];
          if length(comboTTYPorts.Items.Strings[comboTTYPorts.ItemIndex]) = 5 Then edPort.Text := comboTTYPorts.Items.Strings[comboTTYPorts.ItemIndex][4..5];
          if length(comboTTYPorts.Items.Strings[comboTTYPorts.ItemIndex]) = 6 Then edPort.Text := comboTTYPorts.Items.Strings[comboTTYPorts.ItemIndex][4..6];
     end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
Var
   foo   : String;
begin
     Timer1.Enabled := False;
     if CloseAction = caFree Then
     Begin
          updateDB;
          portAudio.Pa_AbortStream(paInStream);
          //portAudio.Pa_AbortStream(paOutStream);
          portaudio.Pa_Terminate();
          rb.useRB   := False;
          rb.useDBF  := False;
          rb.logoutRB;
          sleep(250);
          rbThread.Terminate;
          if not rbThread.FreeOnTerminate Then rbThread.Free;
          decoderThread.Terminate;
          if not decoderThread.FreeOnTerminate Then decoderThread.Free;
          foo := '';
          if thisUTC.Month < 10 Then foo := '0' + IntToStr(thisUTC.Month) + '-' else foo := IntToStr(thisUTC.Month) + '-';
          if thisUTC.Day   < 10 Then foo := foo + '0' + IntToStr(thisUTC.Day) + '-' else foo := foo + IntToStr(thisUTC.Day) + '-';
          foo := foo + IntToStr(thisUTC.Year) + '  ';
          if thisUTC.Hour  < 10 Then foo := foo + '0' + IntToStr(thisUTC.Hour) + ':' else foo := foo + IntToStr(thisUTC.Hour) + ':';
          if thisUTC.Minute < 10 Then foo := foo + '0' + IntToStr(thisUTC.Minute) + ':' else foo := foo + IntToStr(thisUTC.Minute) + ':';
          if thisUTC.Second < 10 Then foo := foo + '0' + IntToStr(thisUTC.Second) else foo := foo + IntToStr(thisUTC.Second);
          etime := 'Ended:  ' + foo;
          //ereport(stime + '  ' + etime);
          //ereport('Decodes:  ' + IntToStr(kvcount+bmcount) + ' KV Decodes:  ' + IntToStr(kvcount) + ' BM Decodes:  ' + IntToStr(bmcount));
          //ereport('Structured Decodes:  ' + IntToStr(msc) + ' Free Text Decodes:  ' + IntToStr(mfc));
          //ereport('V1 Decodes:  ' + IntToStr(v1c)+ ' V2 Decodes:  ' + IntToStr(v2c));
          //if not isZero(demodulate.dmarun) Then ereport('Avg decode time:  ' + FormatFloat('0.000',((demodulate.dmarun/demodulate.dmrcount)/1000.0)));
          //if not IsZero(lrun) Then ereport('Longest decode time:  ' + FormatFloat('0.000',(lrun/1000.0)));
          //if not IsZero(srun) Then ereport('Shortest decode time:  ' + FormatFloat('0.000',(srun/1000.0)));
          //if not isZero(avgdt) Then ereport('Avg DT:  ' + FormatFloat('0.00',(avgdt/(kvcount+bmcount))));
          //if rb.errLog.Count > 0 Then
          //Begin
               //ereport('RB Errors');
               //for i := 0 to rb.errLog.Count-1 do
               //begin
                    //ereport(rb.errlog.Strings[i]);
               //end;
               //ereport(' ');
          //end;
          //ereport('------------------------------');
     end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
     gTXLevel   := 32767;
     srun       := 0.0;
     lrun       := 0.0;
     demodulate.dmrcount := 0;
     demodulate.dmarun := 0.0;
     mval        := valobject.TValidator.create();
     Label1.Caption := 'TX Level:  100%';
     firstPass   := True;
     inSync      := False;
     paActive    := False;
     firstTick   := True;
     firstAU1    := True;
     firstAU2    := True;
     thisUTC     := utcTime;
     thisSecond  := thisUTC.Second;
     lastSecond  := 0;
     newMinute   := False;
     newSecond   := False;
     rbping      := False;
     //rbtick      := 0;
     //rbpings     := 0;
     rbposted    := 0;
     doDecode    := False;
     decodeping  := 0;
     decoderBusy := False;
     qrgValid    := False;
     Timer1.Enabled := True;
end;

procedure rbcThread.Execute;
begin
     while not Terminated and not Suspended and not rb.busy do
     begin
          // Do not use internal database system for now.
          rb.useDBF := False;
          // Refresh rb status if necessary
          if rbping then
          begin
               if qrgValid Then
               Begin
                    //inc(rbpings);
                    if rb.useRB then rb.loginRB;
                    rbping := False;
               end;
          end;
          // Push spots, this happens even if all the RB function is off just
          // to keep the internal data structures up to date.
          if not rb.busy then
          Begin
               if qrgValid Then
               Begin
                    rb.pushSpots;
               end;
          end;
          //inc(rbtick);
          sleep(1000);
     end;
end;

procedure decodeThread.Execute;
Var
   rxb : Packed Array of CTypes.cint16;
   rxf : Packed Array of CTypes.cfloat;
   i   : Integer;
begin
     while not Terminated and not Suspended and not decoderBusy do
     begin
          if doDecode then
          Begin
               decoderBusy := True;
               i := 0;
               while adc.adcRunning do
               begin
                    inc(i);
                    if i > 25 then break;
                    sleep(1);
               end;

//               setLength(rxb,length(adc.d65rxBuffer1));
//               if adc.adcChan = 0 Then for i := 0 to length(adc.d65rxBuffer1)-1 do rxb[i] := adc.d65rxBuffer1[i];
//               if adc.adcChan = 1 Then for i := 0 to length(adc.d65rxBuffer1)-1 do rxb[i] := adc.d65rxBuffer1[i];
//               if adc.adcChan = 2 Then for i := 0 to length(adc.d65rxBuffer2)-1 do rxb[i] := adc.d65rxBuffer2[i];

               setLength(rxf,length(adc.d65rxFBuffer));
//               if adc.adcChan = 0 Then for i := 0 to length(adc.d65rxFBuffer1)-1 do rxf[i] := adc.d65rxFBuffer1[i];
//               if adc.adcChan = 1 Then for i := 0 to length(adc.d65rxFBuffer1)-1 do rxf[i] := adc.d65rxFBuffer1[i];
//               if adc.adcChan = 2 Then for i := 0 to length(adc.d65rxFBuffer2)-1 do rxf[i] := adc.d65rxFBuffer2[i];

               for i := 0 to length(adc.d65rxFBuffer)-1 do rxf[i] := adc.d65rxFBuffer[i];
               demodulate.fdemod(rxf);

               inc(decodeping);
               setLength(rxb,0);
               //setLength(rxf,0);
               doDecode := False;
               decoderBusy := False;
          end;
          Sleep(100);
     end;
end;

procedure catThread.Execute;
Var
   commandline : String;
   catProc     : TProcess;
   i           : Integer;
   indata,foo  : String;
   MemStream   : TMemoryStream;
   BytesRead   : LongInt;
   NumBytes    : LongInt;
   OutputLines : TStringList;
   ecount      : LongInt;
   haveError   : Boolean;
begin
     while not Terminated and not Suspended do
     begin
          if doCAT then
          Begin
               catFree := False;
               if readQRG Then
               Begin
                    // Read QRG
                    commandline := '';
                    // Here's where I run the CAT control cycle by either launching
                    // jt65hfrc.exe for everything but hamlib or hamlib command line
                    // util
                    if catMethod = 'Commander' Then commandline := '-c COMMANDER -d . -r';
                    if length(commandline)>0 Then
                    Begin
                         haveError := False;
                         MemStream := TMemoryStream.Create;
                         BytesRead := 0;
                         catProc := TProcess.Create(nil);
                         catProc.Executable := 'jt65hfrc.exe';
                         catProc.Parameters.Add(commandline);
                         //catProc.CommandLine := commandline;
                         catProc.Options := [poUsePipes] + [poNoConsole];
                         catProc.Execute;
                         ecount := 0;
                         while catProc.Running Do
                         begin
                              MemStream.SetSize(BytesRead + 2048);
                              NumBytes := catProc.Output.Read((MemStream.Memory + BytesRead)^, 2048);
                              if NumBytes > 0 then
                              begin
                                   Inc(BytesRead, NumBytes);
                              end
                              else
                              begin
                                   inc(ecount);
                                   if ecount > 20 then break;
                              end;
                         end;

                         if ecount > 20 Then haveError := True;
                         if haveError Then
                         Begin
                              foo := '';
                              if thisUTC.Month < 10 Then foo := '0' + IntToStr(thisUTC.Month) + '-' else foo := IntToStr(thisUTC.Month) + '-';
                              if thisUTC.Day   < 10 Then foo := foo + '0' + IntToStr(thisUTC.Day) + '-' else foo := foo + IntToStr(thisUTC.Day) + '-';
                              foo := foo + IntToStr(thisUTC.Year) + '  ';
                              if thisUTC.Hour  < 10 Then foo := foo + '0' + IntToStr(thisUTC.Hour) + ':' else foo := foo + IntToStr(thisUTC.Hour) + ':';
                              if thisUTC.Minute < 10 Then foo := foo + '0' + IntToStr(thisUTC.Minute) + ':' else foo := foo + IntToStr(thisUTC.Minute) + ':';
                              if thisUTC.Second < 10 Then foo := foo + '0' + IntToStr(thisUTC.Second) else foo := foo + IntToStr(thisUTC.Second);
                              if catProc.Terminate(0) then catError.Add(foo + ' Terminated CAT process - timeout.') else catError.Add(foo + ' Failed to terminate timed out CAT process!');
                              foo := '';
                              catQRG := 0;
                         end
                         else
                         Begin
                              repeat
                                    MemStream.SetSize(BytesRead + 2048);
                                    NumBytes := catProc.Output.Read((MemStream.Memory + BytesRead)^, 2048);
                                    if NumBytes > 0 then Inc(BytesRead, NumBytes);
                              until NumBytes <= 0;
                              MemStream.SetSize(BytesRead);
                              OutputLines := TStringList.Create;
                              OutputLines.LoadFromStream(MemStream);
                              i := OutputLines.Count;
                              foo := '';
                              if i > 0 then foo := OutputLines.Strings[0] else foo := '-1';
                              OutputLines.Free;
                              MemStream.Free;
                              catProc.Free;
                              indata := '';
                              indata := TrimLeft(TrimRight(foo));
                              i := -2;
                              catQRG := -2;
                              if trystrtoint(indata,i) Then
                              begin
                                   catQRG := i;
                              end
                              else
                              begin
                                   catQRG := 0;
                              end;
                         end;
                         readQRG := False;
                    end;
               end;
               if setQRG Then
               Begin
                    // Set QRG
                    commandline := '';
                    // Here's where I run the CAT control cycle by either launching
                    // jt65hfrc.exe for everything but hamlib or hamlib command line
                    // util
                    if catMethod = 'Commander' Then commandline := 'jt65hfrc.exe -c COMMANDER -d . -s ' + IntToStr(qsyQRG);
                    if length(commandline)>0 Then
                    Begin
                         MemStream := TMemoryStream.Create;
                         BytesRead := 0;
                         catProc := TProcess.Create(nil);
                         catProc.Parameters.Add(commandline);
                         //catProc.CommandLine := commandline;
                         catProc.Options := [poUsePipes] + [poNoConsole];
                         catProc.Execute;

                         while catProc.Running Do
                         begin
                              MemStream.SetSize(BytesRead + 2048);
                              NumBytes := catProc.Output.Read((MemStream.Memory + BytesRead)^, 2048);
                              if NumBytes > 0 then Inc(BytesRead, NumBytes) else Sleep(100);
                         end;

                         repeat
                               MemStream.SetSize(BytesRead + 2048);
                               NumBytes := catProc.Output.Read((MemStream.Memory + BytesRead)^, 2048);
                               if NumBytes > 0 then Inc(BytesRead, NumBytes);
                         until NumBytes <= 0;
                         MemStream.SetSize(BytesRead);
                         OutputLines := TStringList.Create;
                         OutputLines.LoadFromStream(MemStream);
                         i := OutputLines.Count;
                         foo := '';
                         if i > 0 then foo := OutputLines.Strings[0] else foo := '-1';
                         OutputLines.Free;
                         MemStream.Free;
                         catProc.Free;
                         indata := '';
                         indata := TrimLeft(TrimRight(foo));
                         i := -2;
                         catQRG := -2;
                         if trystrtoint(indata,i) Then catQRG := i else catQRG := 0;
                    end;
                    setQRG := False;
               end;
               if readPTT Then
               Begin
                    // Read PTT state
                    MemStream := TMemoryStream.Create;
                    BytesRead := 0;
                    catProc := TProcess.Create(nil);
                    catProc.Parameters.Add(commandline);
                    //catProc.CommandLine := commandline;
                    catProc.Options := [poUsePipes] + [poNoConsole];
                    catProc.Execute;

                    while catProc.Running Do
                    begin
                         MemStream.SetSize(BytesRead + 2048);
                         NumBytes := catProc.Output.Read((MemStream.Memory + BytesRead)^, 2048);
                         if NumBytes > 0 then Inc(BytesRead, NumBytes) else Sleep(100);
                    end;

                    repeat
                          MemStream.SetSize(BytesRead + 2048);
                          NumBytes := catProc.Output.Read((MemStream.Memory + BytesRead)^, 2048);
                          if NumBytes > 0 then Inc(BytesRead, NumBytes);
                    until NumBytes <= 0;
                    MemStream.SetSize(BytesRead);
                    OutputLines := TStringList.Create;
                    OutputLines.LoadFromStream(MemStream);
                    i := OutputLines.Count;
                    foo := '';
                    if i > 0 then foo := OutputLines.Strings[0] else foo := '-1';
                    OutputLines.Free;
                    MemStream.Free;
                    catProc.Free;
                    indata := '';
                    indata := TrimLeft(TrimRight(foo));
                    i := -2;
                    catQRG := -2;
                    if trystrtoint(indata,i) Then catQRG := i else catQRG := 0;
                    readPTT := False;
               end;
               if setPTT Then
               Begin
                    // Set PTT state
                    MemStream := TMemoryStream.Create;
                    BytesRead := 0;
                    catProc := TProcess.Create(nil);
                    catProc.Parameters.Add(commandline);
                    //catProc.CommandLine := commandline;
                    catProc.Options := [poUsePipes] + [poNoConsole];
                    catProc.Execute;

                    while catProc.Running Do
                    begin
                         MemStream.SetSize(BytesRead + 2048);
                         NumBytes := catProc.Output.Read((MemStream.Memory + BytesRead)^, 2048);
                         if NumBytes > 0 then Inc(BytesRead, NumBytes) else Sleep(100);
                    end;

                    repeat
                          MemStream.SetSize(BytesRead + 2048);
                          NumBytes := catProc.Output.Read((MemStream.Memory + BytesRead)^, 2048);
                          if NumBytes > 0 then Inc(BytesRead, NumBytes);
                    until NumBytes <= 0;
                    MemStream.SetSize(BytesRead);
                    OutputLines := TStringList.Create;
                    OutputLines.LoadFromStream(MemStream);
                    i := OutputLines.Count;
                    foo := '';
                    if i > 0 then foo := OutputLines.Strings[0] else foo := '-1';
                    OutputLines.Free;
                    MemStream.Free;
                    catProc.Free;
                    indata := '';
                    indata := TrimLeft(TrimRight(foo));
                    i := -2;
                    catQRG := -2;
                    if trystrtoint(indata,i) Then catQRG := i else catQRG := 0;
                    setPTT := False;
               end;
               doCAT := False;
               catFree := True;
          end;
          Sleep(100);
     end;
end;

Function TForm1.getLocalGrid : String;
Var
  foo : String;
Begin
     foo := edGrid.Text;
     if length(foo)>4 then foo := foo[1..4];
     if isGrid(foo) Then result := TrimLeft(TrimRight(UpCase(foo))) Else Result := '';
end;

procedure TForm1.InitBar;
begin
     FBar1 := TBarSeries.Create(Chart1);
     FBar1.Title := '';
     FBar1.SeriesColor := clBLue;
     Chart1.AddSeries(FBar1);
end;

function TForm1.utcTime: TSystemTime;
Begin
     result.Day := 0;
     GetSystemTime(result);
end;

procedure TForm1.removeDupes(var list : TStringList; var removes : Array of Integer);
Var
  dupelist  : TStringList;
  i,j,c1,c2 : Integer;
  c4        : Integer;
  dcount    : Integer;
  s1        : String;
  havedupe  : Boolean;
  ostrong   : Boolean;
Begin
     // What I have here is a string list that may or may not have duplicates.
     // The easy cases of a true duplicate has already been handled, but...
     // The harder case may still be present where the excahnge is a dupe but
     // the signal strength/df/dt may differ.  This is the case when a very
     // strong signal leads to alias decodes.  What I need to do is look for
     // duplicate exchange text but differing "other" fields where the winner
     // is the decode with the strongest dB figure.
     //

     // The input stringist contains db,exchange,index of array member

     havedupe := True;
     dupeList := TStringList.Create;
     dupeList.Clear;
     dupeList.CaseSensitive := False;
     dupeList.Sorted := True;
     dupeList.Duplicates := Types.dupError;

     for i := 0 to length(removes)-1 do removes[i] := -9999;

     if list.Count < 2 Then havedupe := False;  // No need to bother here if it can't have a dupe!

     while havedupe do
     begin
          // See if any dupes exist.
          dupelist.clear;
          // Attempt to add all members (exchange portion only) to dupelist set
          // to disallow duplicates.  If an entry attempt of dupe is made an
          // exception will be thrown.  This repeats until all dupes have been
          // removed.
          havedupe := False;
          for i := 0 to list.Count - 1 do
          begin
               s1 := '';
               c1 := 9999;
               c2 := 9999;
               c4 := 9999;
               Try
                  if not (ExtractWord(2,list.strings[i],[',']) = 'REMOVE ME') Then
                  Begin
                       dupeList.Add(ExtractWord(2,list.strings[i],[',']));
                  end;
               except
                  havedupe := True;
                  s1 := ExtractWord(2,List.Strings[i],[',']) ; // Get exchange portion of the dupe.
                  c1 := StrToInt(ExtractWord(1,list.Strings[i],[','])); // Signal strength
                  c4 := i;                                              // Index of this entry in list.Strings[]
                  break;
               end;
          end;

          if havedupe then
          begin
               // I know I have duplicate(s) member(s) if I make it here.  Lets do it like so...
               // Comapre all other items in list.strings[] substring exchange to s1 (excluding
               // index c4 which is the original) to find if s1/c1 idx c4 is the strongest dupe.  If
               // s1/c1 idx c4 is strongest remove all other duplicate entries leaving only
               // list.strings[c4] or if not leaving only strongest dupe that is otherwise dupe of
               // s1/c1 idx c4.
               //
               // DO NOT DELTE ANY ENTRIES IN list.strings[] until done -- just set the exchange
               // substring to REMOVE ME

               // First pass - find dupe count.
               dcount := 0;
               ostrong := True;
               havedupe := True;

               For i := 0 to list.Count - 1 do
               begin
                    If ExtractWord(2,list.Strings[i],[',']) = s1 Then
                    Begin
                         if i <> c4 then
                         Begin
                              inc(dcount);
                              c2 := StrToInt(ExtractWord(1,list.Strings[i],[',']));
                              if c2 > c1 then ostrong := false;
                         End;
                    End;
               end;

               if dcount>0 Then
               // At this point I have a duplicate count (1...x) and will know if s1/c1 idx c4
               // is strongest.  If not strongest I go one way - If strongest I go another.

               if (dcount > 0) and ostrong Then
               Begin
                    //Memo1.Append('Removing dupes ['+ IntToStr(dcount) + ']');
                    // Have at least 1 dupe and s1/c1 idx c4 is strongest.
                    // Walk the list again and set all dupes that are not s1/c1 idx c4 to
                    // sig,REMOVE ME,idx instead of sig,EXCHANGE,idx
                    for i := 0 to list.Count-1 do
                    Begin
                         If ExtractWord(2,list.Strings[i],[',']) = s1 Then
                         Begin
                              if i <> c4 then
                              Begin
                                   // Update this string to remove status.
                                   list.Strings[i] := ExtractWord(1,list.strings[i],[',']) + ',REMOVE ME,' + ExtractWord(3,list.strings[i],[',']);
                                   //Memo1.Append(list.Strings[i]);
                              End;
                         End;
                    end;
               end;

               if (dcount > 0) and (not ostrong) Then
               Begin
                    // Have at least 1 dupe and s1/c1 idx c4 is NOT strongest so - flag s1/c1 idx c4 as removed.
                    list.Strings[c4] := ExtractWord(1,list.strings[c4],[',']) + ',REMOVE ME,' + ExtractWord(3,list.strings[c4],[',']);
                    //Memo1.Append(list.Strings[i]);
               end;
               // Keep repeating until havedupe false
          end;
          dupelist.Clear;
     end;
     j := 0; // j holds index to removes[] incremented after each add to removes[]
     // Now -- walk the list and add any entry in list.strings[] where exchange = REMOVE ME
     // to removes[] as its original index held in third word of list.strings[]
     for i := 0 to list.Count - 1 do
     begin
          if ExtractWord(2,list.strings[i],[',']) = 'REMOVE ME' then
          begin
               removes[j] := StrToInt(ExtractWord(3,list.Strings[i],[','])); // Index of this entry in calling code's data
               inc(j);
          end;
     end;
     dupeList.clear;
     dupeList.Destroy;
end;

constructor rbcThread.Create(CreateSuspended : boolean);
begin
     FreeOnTerminate := True;
     inherited Create(CreateSuspended);
end;

constructor decodeThread.Create(CreateSuspended : boolean);
begin
     FreeOnTerminate := True;
     inherited Create(CreateSuspended);
end;

constructor catThread.Create(CreateSuspended : boolean);
begin
     FreeOnTerminate := True;
     inherited Create(CreateSuspended);
end;

procedure TForm1.setG;
var
   z : AnsiString;
   wc,i : Integer;
Begin
     // All possible values of the ng field, all 32,768 of them :)
     // Gxx## is a grid, Pxxxx is a prefix, Sxxxx is a suffix
     // These comprise the entire JT65V1 ng data entities.  Rather than
     // compute them - I do the heavy lifting once, parsing this list
     // and storing in the sql datastore for future runs.
     z := '';

     z := z + 'GRA90,GRA91,GRA92,GRA93,GRA94,GRA95,GRA96,GRA97,GRA98,GRA99,GRB90,GRB91,GRB92,GRB93,GRB94,';
     z := z + 'GRB95,GRB96,GRB97,GRB98,GRB99,GRC90,GRC91,GRC92,GRC93,GRC94,GRC95,GRC96,GRC97,GRC98,GRC99,';
     z := z + 'GRD90,GRD91,GRD92,GRD93,GRD94,GRD95,GRD96,GRD97,GRD98,GRD99,GRE90,GRE91,GRE92,GRE93,GRE94,';
     z := z + 'GRE95,GRE96,GRE97,GRE98,GRE99,GRF90,GRF91,GRF92,GRF93,GRF94,GRF95,GRF96,GRF97,GRF98,GRF99,';
     z := z + 'GRG90,GRG91,GRG92,GRG93,GRG94,GRG95,GRG96,GRG97,GRG98,GRG99,GRH90,GRH91,GRH92,GRH93,GRH94,';
     z := z + 'GRH95,GRH96,GRH97,GRH98,GRH99,GRI90,GRI91,GRI92,GRI93,GRI94,GRI95,GRI96,GRI97,GRI98,GRI99,';
     z := z + 'GRJ90,GRJ91,GRJ92,GRJ93,GRJ94,GRJ95,GRJ96,GRJ97,GRJ98,GRJ99,GRK90,GRK91,GRK92,GRK93,GRK94,';
     z := z + 'GRK95,GRK96,GRK97,GRK98,GRK99,GRL90,GRL91,GRL92,GRL93,GRL94,GRL95,GRL96,GRL97,GRL98,GRL99,';
     z := z + 'GRM90,GRM91,GRM92,GRM93,GRM94,GRM95,GRM96,GRM97,GRM98,GRM99,GRN90,GRN91,GRN92,GRN93,GRN94,';
     z := z + 'GRN95,GRN96,GRN97,GRN98,GRN99,GRO90,GRO91,GRO92,GRO93,GRO94,GRO95,GRO96,GRO97,GRO98,GRO99,';
     z := z + 'GRP90,GRP91,GRP92,GRP93,GRP94,GRP95,GRP96,GRP97,GRP98,GRP99,GRQ90,GRQ91,GRQ92,GRQ93,GRQ94,';
     z := z + 'GRQ95,GRQ96,GRQ97,GRQ98,GRQ99,GRR90,GRR91,GRR92,GRR93,GRR94,P1A   ,P1S   ,P3A   ,P3B6  ,P3B8  ,';
     z := z + 'GRA80,GRA81,GRA82,GRA83,GRA84,GRA85,GRA86,GRA87,GRA88,GRA89,GRB80,GRB81,GRB82,GRB83,GRB84,';
     z := z + 'GRB85,GRB86,GRB87,GRB88,GRB89,GRC80,GRC81,GRC82,GRC83,GRC84,GRC85,GRC86,GRC87,GRC88,GRC89,';
     z := z + 'GRD80,GRD81,GRD82,GRD83,GRD84,GRD85,GRD86,GRD87,GRD88,GRD89,GRE80,GRE81,GRE82,GRE83,GRE84,';
     z := z + 'GRE85,GRE86,GRE87,GRE88,GRE89,GRF80,GRF81,GRF82,GRF83,GRF84,GRF85,GRF86,GRF87,GRF88,GRF89,';
     z := z + 'GRG80,GRG81,GRG82,GRG83,GRG84,GRG85,GRG86,GRG87,GRG88,GRG89,GRH80,GRH81,GRH82,GRH83,GRH84,';
     z := z + 'GRH85,GRH86,GRH87,GRH88,GRH89,GRI80,GRI81,GRI82,GRI83,GRI84,GRI85,GRI86,GRI87,GRI88,GRI89,';
     z := z + 'GRJ80,GRJ81,GRJ82,GRJ83,GRJ84,GRJ85,GRJ86,GRJ87,GRJ88,GRJ89,GRK80,GRK81,GRK82,GRK83,GRK84,';
     z := z + 'GRK85,GRK86,GRK87,GRK88,GRK89,GRL80,GRL81,GRL82,GRL83,GRL84,GRL85,GRL86,GRL87,GRL88,GRL89,';
     z := z + 'GRM80,GRM81,GRM82,GRM83,GRM84,GRM85,GRM86,GRM87,GRM88,GRM89,GRN80,GRN81,GRN82,GRN83,GRN84,';
     z := z + 'GRN85,GRN86,GRN87,GRN88,GRN89,GRO80,GRO81,GRO82,GRO83,GRO84,GRO85,GRO86,GRO87,GRO88,GRO89,';
     z := z + 'GRP80,GRP81,GRP82,GRP83,GRP84,GRP85,GRP86,GRP87,GRP88,GRP89,GRQ80,GRQ81,GRQ82,GRQ83,GRQ84,';
     z := z + 'GRQ85,GRQ86,GRQ87,GRQ88,GRQ89,GRR80,GRR81,GRR82,GRR83,GRR84,P3B9  ,P3C   ,P3C0  ,P3D2  ,P3D2C ,';
     z := z + 'GRA70,GRA71,GRA72,GRA73,GRA74,GRA75,GRA76,GRA77,GRA78,GRA79,GRB70,GRB71,GRB72,GRB73,GRB74,';
     z := z + 'GRB75,GRB76,GRB77,GRB78,GRB79,GRC70,GRC71,GRC72,GRC73,GRC74,GRC75,GRC76,GRC77,GRC78,GRC79,';
     z := z + 'GRD70,GRD71,GRD72,GRD73,GRD74,GRD75,GRD76,GRD77,GRD78,GRD79,GRE70,GRE71,GRE72,GRE73,GRE74,';
     z := z + 'GRE75,GRE76,GRE77,GRE78,GRE79,GRF70,GRF71,GRF72,GRF73,GRF74,GRF75,GRF76,GRF77,GRF78,GRF79,';
     z := z + 'GRG70,GRG71,GRG72,GRG73,GRG74,GRG75,GRG76,GRG77,GRG78,GRG79,GRH70,GRH71,GRH72,GRH73,GRH74,';
     z := z + 'GRH75,GRH76,GRH77,GRH78,GRH79,GRI70,GRI71,GRI72,GRI73,GRI74,GRI75,GRI76,GRI77,GRI78,GRI79,';
     z := z + 'GRJ70,GRJ71,GRJ72,GRJ73,GRJ74,GRJ75,GRJ76,GRJ77,GRJ78,GRJ79,GRK70,GRK71,GRK72,GRK73,GRK74,';
     z := z + 'GRK75,GRK76,GRK77,GRK78,GRK79,GRL70,GRL71,GRL72,GRL73,GRL74,GRL75,GRL76,GRL77,GRL78,GRL79,';
     z := z + 'GRM70,GRM71,GRM72,GRM73,GRM74,GRM75,GRM76,GRM77,GRM78,GRM79,GRN70,GRN71,GRN72,GRN73,GRN74,';
     z := z + 'GRN75,GRN76,GRN77,GRN78,GRN79,GRO70,GRO71,GRO72,GRO73,GRO74,GRO75,GRO76,GRO77,GRO78,GRO79,';
     z := z + 'GRP70,GRP71,GRP72,GRP73,GRP74,GRP75,GRP76,GRP77,GRP78,GRP79,GRQ70,GRQ71,GRQ72,GRQ73,GRQ74,';
     z := z + 'GRQ75,GRQ76,GRQ77,GRQ78,GRQ79,GRR70,GRR71,GRR72,GRR73,GRR74,P3D2R ,P3DA  ,P3V   ,P3W   ,P3X   ,';
     z := z + 'GRA60,GRA61,GRA62,GRA63,GRA64,GRA65,GRA66,GRA67,GRA68,GRA69,GRB60,GRB61,GRB62,GRB63,GRB64,';
     z := z + 'GRB65,GRB66,GRB67,GRB68,GRB69,GRC60,GRC61,GRC62,GRC63,GRC64,GRC65,GRC66,GRC67,GRC68,GRC69,';
     z := z + 'GRD60,GRD61,GRD62,GRD63,GRD64,GRD65,GRD66,GRD67,GRD68,GRD69,GRE60,GRE61,GRE62,GRE63,GRE64,';
     z := z + 'GRE65,GRE66,GRE67,GRE68,GRE69,GRF60,GRF61,GRF62,GRF63,GRF64,GRF65,GRF66,GRF67,GRF68,GRF69,';
     z := z + 'GRG60,GRG61,GRG62,GRG63,GRG64,GRG65,GRG66,GRG67,GRG68,GRG69,GRH60,GRH61,GRH62,GRH63,GRH64,';
     z := z + 'GRH65,GRH66,GRH67,GRH68,GRH69,GRI60,GRI61,GRI62,GRI63,GRI64,GRI65,GRI66,GRI67,GRI68,GRI69,';
     z := z + 'GRJ60,GRJ61,GRJ62,GRJ63,GRJ64,GRJ65,GRJ66,GRJ67,GRJ68,GRJ69,GRK60,GRK61,GRK62,GRK63,GRK64,';
     z := z + 'GRK65,GRK66,GRK67,GRK68,GRK69,GRL60,GRL61,GRL62,GRL63,GRL64,GRL65,GRL66,GRL67,GRL68,GRL69,';
     z := z + 'GRM60,GRM61,GRM62,GRM63,GRM64,GRM65,GRM66,GRM67,GRM68,GRM69,GRN60,GRN61,GRN62,GRN63,GRN64,';
     z := z + 'GRN65,GRN66,GRN67,GRN68,GRN69,GRO60,GRO61,GRO62,GRO63,GRO64,GRO65,GRO66,GRO67,GRO68,GRO69,';
     z := z + 'GRP60,GRP61,GRP62,GRP63,GRP64,GRP65,GRP66,GRP67,GRP68,GRP69,GRQ60,GRQ61,GRQ62,GRQ63,GRQ64,';
     z := z + 'GRQ65,GRQ66,GRQ67,GRQ68,GRQ69,GRR60,GRR61,GRR62,GRR63,GRR64,P3Y   ,P3YB  ,P3YP  ,P4J   ,P4L   ,';
     z := z + 'GRA50,GRA51,GRA52,GRA53,GRA54,GRA55,GRA56,GRA57,GRA58,GRA59,GRB50,GRB51,GRB52,GRB53,GRB54,';
     z := z + 'GRB55,GRB56,GRB57,GRB58,GRB59,GRC50,GRC51,GRC52,GRC53,GRC54,GRC55,GRC56,GRC57,GRC58,GRC59,';
     z := z + 'GRD50,GRD51,GRD52,GRD53,GRD54,GRD55,GRD56,GRD57,GRD58,GRD59,GRE50,GRE51,GRE52,GRE53,GRE54,';
     z := z + 'GRE55,GRE56,GRE57,GRE58,GRE59,GRF50,GRF51,GRF52,GRF53,GRF54,GRF55,GRF56,GRF57,GRF58,GRF59,';
     z := z + 'GRG50,GRG51,GRG52,GRG53,GRG54,GRG55,GRG56,GRG57,GRG58,GRG59,GRH50,GRH51,GRH52,GRH53,GRH54,';
     z := z + 'GRH55,GRH56,GRH57,GRH58,GRH59,GRI50,GRI51,GRI52,GRI53,GRI54,GRI55,GRI56,GRI57,GRI58,GRI59,';
     z := z + 'GRJ50,GRJ51,GRJ52,GRJ53,GRJ54,GRJ55,GRJ56,GRJ57,GRJ58,GRJ59,GRK50,GRK51,GRK52,GRK53,GRK54,';
     z := z + 'GRK55,GRK56,GRK57,GRK58,GRK59,GRL50,GRL51,GRL52,GRL53,GRL54,GRL55,GRL56,GRL57,GRL58,GRL59,';
     z := z + 'GRM50,GRM51,GRM52,GRM53,GRM54,GRM55,GRM56,GRM57,GRM58,GRM59,GRN50,GRN51,GRN52,GRN53,GRN54,';
     z := z + 'GRN55,GRN56,GRN57,GRN58,GRN59,GRO50,GRO51,GRO52,GRO53,GRO54,GRO55,GRO56,GRO57,GRO58,GRO59,';
     z := z + 'GRP50,GRP51,GRP52,GRP53,GRP54,GRP55,GRP56,GRP57,GRP58,GRP59,GRQ50,GRQ51,GRQ52,GRQ53,GRQ54,';
     z := z + 'GRQ55,GRQ56,GRQ57,GRQ58,GRQ59,GRR50,GRR51,GRR52,GRR53,GRR54,P4S   ,P4U1I ,P4U1U ,P4W   ,P4X   ,';
     z := z + 'GRA40,GRA41,GRA42,GRA43,GRA44,GRA45,GRA46,GRA47,GRA48,GRA49,GRB40,GRB41,GRB42,GRB43,GRB44,';
     z := z + 'GRB45,GRB46,GRB47,GRB48,GRB49,GRC40,GRC41,GRC42,GRC43,GRC44,GRC45,GRC46,GRC47,GRC48,GRC49,';
     z := z + 'GRD40,GRD41,GRD42,GRD43,GRD44,GRD45,GRD46,GRD47,GRD48,GRD49,GRE40,GRE41,GRE42,GRE43,GRE44,';
     z := z + 'GRE45,GRE46,GRE47,GRE48,GRE49,GRF40,GRF41,GRF42,GRF43,GRF44,GRF45,GRF46,GRF47,GRF48,GRF49,';
     z := z + 'GRG40,GRG41,GRG42,GRG43,GRG44,GRG45,GRG46,GRG47,GRG48,GRG49,GRH40,GRH41,GRH42,GRH43,GRH44,';
     z := z + 'GRH45,GRH46,GRH47,GRH48,GRH49,GRI40,GRI41,GRI42,GRI43,GRI44,GRI45,GRI46,GRI47,GRI48,GRI49,';
     z := z + 'GRJ40,GRJ41,GRJ42,GRJ43,GRJ44,GRJ45,GRJ46,GRJ47,GRJ48,GRJ49,GRK40,GRK41,GRK42,GRK43,GRK44,';
     z := z + 'GRK45,GRK46,GRK47,GRK48,GRK49,GRL40,GRL41,GRL42,GRL43,GRL44,GRL45,GRL46,GRL47,GRL48,GRL49,';
     z := z + 'GRM40,GRM41,GRM42,GRM43,GRM44,GRM45,GRM46,GRM47,GRM48,GRM49,GRN40,GRN41,GRN42,GRN43,GRN44,';
     z := z + 'GRN45,GRN46,GRN47,GRN48,GRN49,GRO40,GRO41,GRO42,GRO43,GRO44,GRO45,GRO46,GRO47,GRO48,GRO49,';
     z := z + 'GRP40,GRP41,GRP42,GRP43,GRP44,GRP45,GRP46,GRP47,GRP48,GRP49,GRQ40,GRQ41,GRQ42,GRQ43,GRQ44,';
     z := z + 'GRQ45,GRQ46,GRQ47,GRQ48,GRQ49,GRR40,GRR41,GRR42,GRR43,GRR44,P5A   ,P5B   ,P5H   ,P5N   ,P5R   ,';
     z := z + 'GRA30,GRA31,GRA32,GRA33,GRA34,GRA35,GRA36,GRA37,GRA38,GRA39,GRB30,GRB31,GRB32,GRB33,GRB34,';
     z := z + 'GRB35,GRB36,GRB37,GRB38,GRB39,GRC30,GRC31,GRC32,GRC33,GRC34,GRC35,GRC36,GRC37,GRC38,GRC39,';
     z := z + 'GRD30,GRD31,GRD32,GRD33,GRD34,GRD35,GRD36,GRD37,GRD38,GRD39,GRE30,GRE31,GRE32,GRE33,GRE34,';
     z := z + 'GRE35,GRE36,GRE37,GRE38,GRE39,GRF30,GRF31,GRF32,GRF33,GRF34,GRF35,GRF36,GRF37,GRF38,GRF39,';
     z := z + 'GRG30,GRG31,GRG32,GRG33,GRG34,GRG35,GRG36,GRG37,GRG38,GRG39,GRH30,GRH31,GRH32,GRH33,GRH34,';
     z := z + 'GRH35,GRH36,GRH37,GRH38,GRH39,GRI30,GRI31,GRI32,GRI33,GRI34,GRI35,GRI36,GRI37,GRI38,GRI39,';
     z := z + 'GRJ30,GRJ31,GRJ32,GRJ33,GRJ34,GRJ35,GRJ36,GRJ37,GRJ38,GRJ39,GRK30,GRK31,GRK32,GRK33,GRK34,';
     z := z + 'GRK35,GRK36,GRK37,GRK38,GRK39,GRL30,GRL31,GRL32,GRL33,GRL34,GRL35,GRL36,GRL37,GRL38,GRL39,';
     z := z + 'GRM30,GRM31,GRM32,GRM33,GRM34,GRM35,GRM36,GRM37,GRM38,GRM39,GRN30,GRN31,GRN32,GRN33,GRN34,';
     z := z + 'GRN35,GRN36,GRN37,GRN38,GRN39,GRO30,GRO31,GRO32,GRO33,GRO34,GRO35,GRO36,GRO37,GRO38,GRO39,';
     z := z + 'GRP30,GRP31,GRP32,GRP33,GRP34,GRP35,GRP36,GRP37,GRP38,GRP39,GRQ30,GRQ31,GRQ32,GRQ33,GRQ34,';
     z := z + 'GRQ35,GRQ36,GRQ37,GRQ38,GRQ39,GRR30,GRR31,GRR32,GRR33,GRR34,P5T   ,P5U   ,P5V   ,P5W   ,P5X   ,';
     z := z + 'GRA20,GRA21,GRA22,GRA23,GRA24,GRA25,GRA26,GRA27,GRA28,GRA29,GRB20,GRB21,GRB22,GRB23,GRB24,';
     z := z + 'GRB25,GRB26,GRB27,GRB28,GRB29,GRC20,GRC21,GRC22,GRC23,GRC24,GRC25,GRC26,GRC27,GRC28,GRC29,';
     z := z + 'GRD20,GRD21,GRD22,GRD23,GRD24,GRD25,GRD26,GRD27,GRD28,GRD29,GRE20,GRE21,GRE22,GRE23,GRE24,';
     z := z + 'GRE25,GRE26,GRE27,GRE28,GRE29,GRF20,GRF21,GRF22,GRF23,GRF24,GRF25,GRF26,GRF27,GRF28,GRF29,';
     z := z + 'GRG20,GRG21,GRG22,GRG23,GRG24,GRG25,GRG26,GRG27,GRG28,GRG29,GRH20,GRH21,GRH22,GRH23,GRH24,';
     z := z + 'GRH25,GRH26,GRH27,GRH28,GRH29,GRI20,GRI21,GRI22,GRI23,GRI24,GRI25,GRI26,GRI27,GRI28,GRI29,';
     z := z + 'GRJ20,GRJ21,GRJ22,GRJ23,GRJ24,GRJ25,GRJ26,GRJ27,GRJ28,GRJ29,GRK20,GRK21,GRK22,GRK23,GRK24,';
     z := z + 'GRK25,GRK26,GRK27,GRK28,GRK29,GRL20,GRL21,GRL22,GRL23,GRL24,GRL25,GRL26,GRL27,GRL28,GRL29,';
     z := z + 'GRM20,GRM21,GRM22,GRM23,GRM24,GRM25,GRM26,GRM27,GRM28,GRM29,GRN20,GRN21,GRN22,GRN23,GRN24,';
     z := z + 'GRN25,GRN26,GRN27,GRN28,GRN29,GRO20,GRO21,GRO22,GRO23,GRO24,GRO25,GRO26,GRO27,GRO28,GRO29,';
     z := z + 'GRP20,GRP21,GRP22,GRP23,GRP24,GRP25,GRP26,GRP27,GRP28,GRP29,GRQ20,GRQ21,GRQ22,GRQ23,GRQ24,';
     z := z + 'GRQ25,GRQ26,GRQ27,GRQ28,GRQ29,GRR20,GRR21,GRR22,GRR23,GRR24,P5Z   ,P6W   ,P6Y   ,P7O   ,P7P   ,';
     z := z + 'GRA10,GRA11,GRA12,GRA13,GRA14,GRA15,GRA16,GRA17,GRA18,GRA19,GRB10,GRB11,GRB12,GRB13,GRB14,';
     z := z + 'GRB15,GRB16,GRB17,GRB18,GRB19,GRC10,GRC11,GRC12,GRC13,GRC14,GRC15,GRC16,GRC17,GRC18,GRC19,';
     z := z + 'GRD10,GRD11,GRD12,GRD13,GRD14,GRD15,GRD16,GRD17,GRD18,GRD19,GRE10,GRE11,GRE12,GRE13,GRE14,';
     z := z + 'GRE15,GRE16,GRE17,GRE18,GRE19,GRF10,GRF11,GRF12,GRF13,GRF14,GRF15,GRF16,GRF17,GRF18,GRF19,';
     z := z + 'GRG10,GRG11,GRG12,GRG13,GRG14,GRG15,GRG16,GRG17,GRG18,GRG19,GRH10,GRH11,GRH12,GRH13,GRH14,';
     z := z + 'GRH15,GRH16,GRH17,GRH18,GRH19,GRI10,GRI11,GRI12,GRI13,GRI14,GRI15,GRI16,GRI17,GRI18,GRI19,';
     z := z + 'GRJ10,GRJ11,GRJ12,GRJ13,GRJ14,GRJ15,GRJ16,GRJ17,GRJ18,GRJ19,GRK10,GRK11,GRK12,GRK13,GRK14,';
     z := z + 'GRK15,GRK16,GRK17,GRK18,GRK19,GRL10,GRL11,GRL12,GRL13,GRL14,GRL15,GRL16,GRL17,GRL18,GRL19,';
     z := z + 'GRM10,GRM11,GRM12,GRM13,GRM14,GRM15,GRM16,GRM17,GRM18,GRM19,GRN10,GRN11,GRN12,GRN13,GRN14,';
     z := z + 'GRN15,GRN16,GRN17,GRN18,GRN19,GRO10,GRO11,GRO12,GRO13,GRO14,GRO15,GRO16,GRO17,GRO18,GRO19,';
     z := z + 'GRP10,GRP11,GRP12,GRP13,GRP14,GRP15,GRP16,GRP17,GRP18,GRP19,GRQ10,GRQ11,GRQ12,GRQ13,GRQ14,';
     z := z + 'GRQ15,GRQ16,GRQ17,GRQ18,GRQ19,GRR10,GRR11,GRR12,GRR13,GRR14,P7Q   ,P7X   ,P8P   ,P8Q   ,P8R   ,';
     z := z + 'GRA00,GRA01,GRA02,GRA03,GRA04,GRA05,GRA06,GRA07,GRA08,GRA09,GRB00,GRB01,GRB02,GRB03,GRB04,';
     z := z + 'GRB05,GRB06,GRB07,GRB08,GRB09,GRC00,GRC01,GRC02,GRC03,GRC04,GRC05,GRC06,GRC07,GRC08,GRC09,';
     z := z + 'GRD00,GRD01,GRD02,GRD03,GRD04,GRD05,GRD06,GRD07,GRD08,GRD09,GRE00,GRE01,GRE02,GRE03,GRE04,';
     z := z + 'GRE05,GRE06,GRE07,GRE08,GRE09,GRF00,GRF01,GRF02,GRF03,GRF04,GRF05,GRF06,GRF07,GRF08,GRF09,';
     z := z + 'GRG00,GRG01,GRG02,GRG03,GRG04,GRG05,GRG06,GRG07,GRG08,GRG09,GRH00,GRH01,GRH02,GRH03,GRH04,';
     z := z + 'GRH05,GRH06,GRH07,GRH08,GRH09,GRI00,GRI01,GRI02,GRI03,GRI04,GRI05,GRI06,GRI07,GRI08,GRI09,';
     z := z + 'GRJ00,GRJ01,GRJ02,GRJ03,GRJ04,GRJ05,GRJ06,GRJ07,GRJ08,GRJ09,GRK00,GRK01,GRK02,GRK03,GRK04,';
     z := z + 'GRK05,GRK06,GRK07,GRK08,GRK09,GRL00,GRL01,GRL02,GRL03,GRL04,GRL05,GRL06,GRL07,GRL08,GRL09,';
     z := z + 'GRM00,GRM01,GRM02,GRM03,GRM04,GRM05,GRM06,GRM07,GRM08,GRM09,GRN00,GRN01,GRN02,GRN03,GRN04,';
     z := z + 'GRN05,GRN06,GRN07,GRN08,GRN09,GRO00,GRO01,GRO02,GRO03,GRO04,GRO05,GRO06,GRO07,GRO08,GRO09,';
     z := z + 'GRP00,GRP01,GRP02,GRP03,GRP04,GRP05,GRP06,GRP07,GRP08,GRP09,GRQ00,GRQ01,GRQ02,GRQ03,GRQ04,';
     z := z + 'GRQ05,GRQ06,GRQ07,GRQ08,GRQ09,GRR00,GRR01,GRR02,GRR03,GRR04,P9A   ,P9G   ,P9H   ,P9J   ,P9K   ,';
     z := z + 'GQA90,GQA91,GQA92,GQA93,GQA94,GQA95,GQA96,GQA97,GQA98,GQA99,GQB90,GQB91,GQB92,GQB93,GQB94,';
     z := z + 'GQB95,GQB96,GQB97,GQB98,GQB99,GQC90,GQC91,GQC92,GQC93,GQC94,GQC95,GQC96,GQC97,GQC98,GQC99,';
     z := z + 'GQD90,GQD91,GQD92,GQD93,GQD94,GQD95,GQD96,GQD97,GQD98,GQD99,GQE90,GQE91,GQE92,GQE93,GQE94,';
     z := z + 'GQE95,GQE96,GQE97,GQE98,GQE99,GQF90,GQF91,GQF92,GQF93,GQF94,GQF95,GQF96,GQF97,GQF98,GQF99,';
     z := z + 'GQG90,GQG91,GQG92,GQG93,GQG94,GQG95,GQG96,GQG97,GQG98,GQG99,GQH90,GQH91,GQH92,GQH93,GQH94,';
     z := z + 'GQH95,GQH96,GQH97,GQH98,GQH99,GQI90,GQI91,GQI92,GQI93,GQI94,GQI95,GQI96,GQI97,GQI98,GQI99,';
     z := z + 'GQJ90,GQJ91,GQJ92,GQJ93,GQJ94,GQJ95,GQJ96,GQJ97,GQJ98,GQJ99,GQK90,GQK91,GQK92,GQK93,GQK94,';
     z := z + 'GQK95,GQK96,GQK97,GQK98,GQK99,GQL90,GQL91,GQL92,GQL93,GQL94,GQL95,GQL96,GQL97,GQL98,GQL99,';
     z := z + 'GQM90,GQM91,GQM92,GQM93,GQM94,GQM95,GQM96,GQM97,GQM98,GQM99,GQN90,GQN91,GQN92,GQN93,GQN94,';
     z := z + 'GQN95,GQN96,GQN97,GQN98,GQN99,GQO90,GQO91,GQO92,GQO93,GQO94,GQO95,GQO96,GQO97,GQO98,GQO99,';
     z := z + 'GQP90,GQP91,GQP92,GQP93,GQP94,GQP95,GQP96,GQP97,GQP98,GQP99,GQQ90,GQQ91,GQQ92,GQQ93,GQQ94,';
     z := z + 'GQQ95,GQQ96,GQQ97,GQQ98,GQQ99,GQR90,GQR91,GQR92,GQR93,GQR94,P9L   ,P9M2  ,P9M6  ,P9N   ,P9Q   ,';
     z := z + 'GQA80,GQA81,GQA82,GQA83,GQA84,GQA85,GQA86,GQA87,GQA88,GQA89,GQB80,GQB81,GQB82,GQB83,GQB84,';
     z := z + 'GQB85,GQB86,GQB87,GQB88,GQB89,GQC80,GQC81,GQC82,GQC83,GQC84,GQC85,GQC86,GQC87,GQC88,GQC89,';
     z := z + 'GQD80,GQD81,GQD82,GQD83,GQD84,GQD85,GQD86,GQD87,GQD88,GQD89,GQE80,GQE81,GQE82,GQE83,GQE84,';
     z := z + 'GQE85,GQE86,GQE87,GQE88,GQE89,GQF80,GQF81,GQF82,GQF83,GQF84,GQF85,GQF86,GQF87,GQF88,GQF89,';
     z := z + 'GQG80,GQG81,GQG82,GQG83,GQG84,GQG85,GQG86,GQG87,GQG88,GQG89,GQH80,GQH81,GQH82,GQH83,GQH84,';
     z := z + 'GQH85,GQH86,GQH87,GQH88,GQH89,GQI80,GQI81,GQI82,GQI83,GQI84,GQI85,GQI86,GQI87,GQI88,GQI89,';
     z := z + 'GQJ80,GQJ81,GQJ82,GQJ83,GQJ84,GQJ85,GQJ86,GQJ87,GQJ88,GQJ89,GQK80,GQK81,GQK82,GQK83,GQK84,';
     z := z + 'GQK85,GQK86,GQK87,GQK88,GQK89,GQL80,GQL81,GQL82,GQL83,GQL84,GQL85,GQL86,GQL87,GQL88,GQL89,';
     z := z + 'GQM80,GQM81,GQM82,GQM83,GQM84,GQM85,GQM86,GQM87,GQM88,GQM89,GQN80,GQN81,GQN82,GQN83,GQN84,';
     z := z + 'GQN85,GQN86,GQN87,GQN88,GQN89,GQO80,GQO81,GQO82,GQO83,GQO84,GQO85,GQO86,GQO87,GQO88,GQO89,';
     z := z + 'GQP80,GQP81,GQP82,GQP83,GQP84,GQP85,GQP86,GQP87,GQP88,GQP89,GQQ80,GQQ81,GQQ82,GQQ83,GQQ84,';
     z := z + 'GQQ85,GQQ86,GQQ87,GQQ88,GQQ89,GQR80,GQR81,GQR82,GQR83,GQR84,P9U   ,P9V   ,P9X   ,P9Y   ,PA2   ,';
     z := z + 'GQA70,GQA71,GQA72,GQA73,GQA74,GQA75,GQA76,GQA77,GQA78,GQA79,GQB70,GQB71,GQB72,GQB73,GQB74,';
     z := z + 'GQB75,GQB76,GQB77,GQB78,GQB79,GQC70,GQC71,GQC72,GQC73,GQC74,GQC75,GQC76,GQC77,GQC78,GQC79,';
     z := z + 'GQD70,GQD71,GQD72,GQD73,GQD74,GQD75,GQD76,GQD77,GQD78,GQD79,GQE70,GQE71,GQE72,GQE73,GQE74,';
     z := z + 'GQE75,GQE76,GQE77,GQE78,GQE79,GQF70,GQF71,GQF72,GQF73,GQF74,GQF75,GQF76,GQF77,GQF78,GQF79,';
     z := z + 'GQG70,GQG71,GQG72,GQG73,GQG74,GQG75,GQG76,GQG77,GQG78,GQG79,GQH70,GQH71,GQH72,GQH73,GQH74,';
     z := z + 'GQH75,GQH76,GQH77,GQH78,GQH79,GQI70,GQI71,GQI72,GQI73,GQI74,GQI75,GQI76,GQI77,GQI78,GQI79,';
     z := z + 'GQJ70,GQJ71,GQJ72,GQJ73,GQJ74,GQJ75,GQJ76,GQJ77,GQJ78,GQJ79,GQK70,GQK71,GQK72,GQK73,GQK74,';
     z := z + 'GQK75,GQK76,GQK77,GQK78,GQK79,GQL70,GQL71,GQL72,GQL73,GQL74,GQL75,GQL76,GQL77,GQL78,GQL79,';
     z := z + 'GQM70,GQM71,GQM72,GQM73,GQM74,GQM75,GQM76,GQM77,GQM78,GQM79,GQN70,GQN71,GQN72,GQN73,GQN74,';
     z := z + 'GQN75,GQN76,GQN77,GQN78,GQN79,GQO70,GQO71,GQO72,GQO73,GQO74,GQO75,GQO76,GQO77,GQO78,GQO79,';
     z := z + 'GQP70,GQP71,GQP72,GQP73,GQP74,GQP75,GQP76,GQP77,GQP78,GQP79,GQQ70,GQQ71,GQQ72,GQQ73,GQQ74,';
     z := z + 'GQQ75,GQQ76,GQQ77,GQQ78,GQQ79,GQR70,GQR71,GQR72,GQR73,GQR74,PA3   ,PA4   ,PA5   ,PA6   ,PA7   ,';
     z := z + 'GQA60,GQA61,GQA62,GQA63,GQA64,GQA65,GQA66,GQA67,GQA68,GQA69,GQB60,GQB61,GQB62,GQB63,GQB64,';
     z := z + 'GQB65,GQB66,GQB67,GQB68,GQB69,GQC60,GQC61,GQC62,GQC63,GQC64,GQC65,GQC66,GQC67,GQC68,GQC69,';
     z := z + 'GQD60,GQD61,GQD62,GQD63,GQD64,GQD65,GQD66,GQD67,GQD68,GQD69,GQE60,GQE61,GQE62,GQE63,GQE64,';
     z := z + 'GQE65,GQE66,GQE67,GQE68,GQE69,GQF60,GQF61,GQF62,GQF63,GQF64,GQF65,GQF66,GQF67,GQF68,GQF69,';
     z := z + 'GQG60,GQG61,GQG62,GQG63,GQG64,GQG65,GQG66,GQG67,GQG68,GQG69,GQH60,GQH61,GQH62,GQH63,GQH64,';
     z := z + 'GQH65,GQH66,GQH67,GQH68,GQH69,GQI60,GQI61,GQI62,GQI63,GQI64,GQI65,GQI66,GQI67,GQI68,GQI69,';
     z := z + 'GQJ60,GQJ61,GQJ62,GQJ63,GQJ64,GQJ65,GQJ66,GQJ67,GQJ68,GQJ69,GQK60,GQK61,GQK62,GQK63,GQK64,';
     z := z + 'GQK65,GQK66,GQK67,GQK68,GQK69,GQL60,GQL61,GQL62,GQL63,GQL64,GQL65,GQL66,GQL67,GQL68,GQL69,';
     z := z + 'GQM60,GQM61,GQM62,GQM63,GQM64,GQM65,GQM66,GQM67,GQM68,GQM69,GQN60,GQN61,GQN62,GQN63,GQN64,';
     z := z + 'GQN65,GQN66,GQN67,GQN68,GQN69,GQO60,GQO61,GQO62,GQO63,GQO64,GQO65,GQO66,GQO67,GQO68,GQO69,';
     z := z + 'GQP60,GQP61,GQP62,GQP63,GQP64,GQP65,GQP66,GQP67,GQP68,GQP69,GQQ60,GQQ61,GQQ62,GQQ63,GQQ64,';
     z := z + 'GQQ65,GQQ66,GQQ67,GQQ68,GQQ69,GQR60,GQR61,GQR62,GQR63,GQR64,PA9   ,PAP   ,PBS7  ,PBV   ,PBV9  ,';
     z := z + 'GQA50,GQA51,GQA52,GQA53,GQA54,GQA55,GQA56,GQA57,GQA58,GQA59,GQB50,GQB51,GQB52,GQB53,GQB54,';
     z := z + 'GQB55,GQB56,GQB57,GQB58,GQB59,GQC50,GQC51,GQC52,GQC53,GQC54,GQC55,GQC56,GQC57,GQC58,GQC59,';
     z := z + 'GQD50,GQD51,GQD52,GQD53,GQD54,GQD55,GQD56,GQD57,GQD58,GQD59,GQE50,GQE51,GQE52,GQE53,GQE54,';
     z := z + 'GQE55,GQE56,GQE57,GQE58,GQE59,GQF50,GQF51,GQF52,GQF53,GQF54,GQF55,GQF56,GQF57,GQF58,GQF59,';
     z := z + 'GQG50,GQG51,GQG52,GQG53,GQG54,GQG55,GQG56,GQG57,GQG58,GQG59,GQH50,GQH51,GQH52,GQH53,GQH54,';
     z := z + 'GQH55,GQH56,GQH57,GQH58,GQH59,GQI50,GQI51,GQI52,GQI53,GQI54,GQI55,GQI56,GQI57,GQI58,GQI59,';
     z := z + 'GQJ50,GQJ51,GQJ52,GQJ53,GQJ54,GQJ55,GQJ56,GQJ57,GQJ58,GQJ59,GQK50,GQK51,GQK52,GQK53,GQK54,';
     z := z + 'GQK55,GQK56,GQK57,GQK58,GQK59,GQL50,GQL51,GQL52,GQL53,GQL54,GQL55,GQL56,GQL57,GQL58,GQL59,';
     z := z + 'GQM50,GQM51,GQM52,GQM53,GQM54,GQM55,GQM56,GQM57,GQM58,GQM59,GQN50,GQN51,GQN52,GQN53,GQN54,';
     z := z + 'GQN55,GQN56,GQN57,GQN58,GQN59,GQO50,GQO51,GQO52,GQO53,GQO54,GQO55,GQO56,GQO57,GQO58,GQO59,';
     z := z + 'GQP50,GQP51,GQP52,GQP53,GQP54,GQP55,GQP56,GQP57,GQP58,GQP59,GQQ50,GQQ51,GQQ52,GQQ53,GQQ54,';
     z := z + 'GQQ55,GQQ56,GQQ57,GQQ58,GQQ59,GQR50,GQR51,GQR52,GQR53,GQR54,PBY   ,PC2   ,PC3   ,PC5   ,PC6   ,';
     z := z + 'GQA40,GQA41,GQA42,GQA43,GQA44,GQA45,GQA46,GQA47,GQA48,GQA49,GQB40,GQB41,GQB42,GQB43,GQB44,';
     z := z + 'GQB45,GQB46,GQB47,GQB48,GQB49,GQC40,GQC41,GQC42,GQC43,GQC44,GQC45,GQC46,GQC47,GQC48,GQC49,';
     z := z + 'GQD40,GQD41,GQD42,GQD43,GQD44,GQD45,GQD46,GQD47,GQD48,GQD49,GQE40,GQE41,GQE42,GQE43,GQE44,';
     z := z + 'GQE45,GQE46,GQE47,GQE48,GQE49,GQF40,GQF41,GQF42,GQF43,GQF44,GQF45,GQF46,GQF47,GQF48,GQF49,';
     z := z + 'GQG40,GQG41,GQG42,GQG43,GQG44,GQG45,GQG46,GQG47,GQG48,GQG49,GQH40,GQH41,GQH42,GQH43,GQH44,';
     z := z + 'GQH45,GQH46,GQH47,GQH48,GQH49,GQI40,GQI41,GQI42,GQI43,GQI44,GQI45,GQI46,GQI47,GQI48,GQI49,';
     z := z + 'GQJ40,GQJ41,GQJ42,GQJ43,GQJ44,GQJ45,GQJ46,GQJ47,GQJ48,GQJ49,GQK40,GQK41,GQK42,GQK43,GQK44,';
     z := z + 'GQK45,GQK46,GQK47,GQK48,GQK49,GQL40,GQL41,GQL42,GQL43,GQL44,GQL45,GQL46,GQL47,GQL48,GQL49,';
     z := z + 'GQM40,GQM41,GQM42,GQM43,GQM44,GQM45,GQM46,GQM47,GQM48,GQM49,GQN40,GQN41,GQN42,GQN43,GQN44,';
     z := z + 'GQN45,GQN46,GQN47,GQN48,GQN49,GQO40,GQO41,GQO42,GQO43,GQO44,GQO45,GQO46,GQO47,GQO48,GQO49,';
     z := z + 'GQP40,GQP41,GQP42,GQP43,GQP44,GQP45,GQP46,GQP47,GQP48,GQP49,GQQ40,GQQ41,GQQ42,GQQ43,GQQ44,';
     z := z + 'GQQ45,GQQ46,GQQ47,GQQ48,GQQ49,GQR40,GQR41,GQR42,GQR43,GQR44,PC9   ,PCE   ,PCE0X ,PCE0Y ,PCE0Z ,';
     z := z + 'GQA30,GQA31,GQA32,GQA33,GQA34,GQA35,GQA36,GQA37,GQA38,GQA39,GQB30,GQB31,GQB32,GQB33,GQB34,';
     z := z + 'GQB35,GQB36,GQB37,GQB38,GQB39,GQC30,GQC31,GQC32,GQC33,GQC34,GQC35,GQC36,GQC37,GQC38,GQC39,';
     z := z + 'GQD30,GQD31,GQD32,GQD33,GQD34,GQD35,GQD36,GQD37,GQD38,GQD39,GQE30,GQE31,GQE32,GQE33,GQE34,';
     z := z + 'GQE35,GQE36,GQE37,GQE38,GQE39,GQF30,GQF31,GQF32,GQF33,GQF34,GQF35,GQF36,GQF37,GQF38,GQF39,';
     z := z + 'GQG30,GQG31,GQG32,GQG33,GQG34,GQG35,GQG36,GQG37,GQG38,GQG39,GQH30,GQH31,GQH32,GQH33,GQH34,';
     z := z + 'GQH35,GQH36,GQH37,GQH38,GQH39,GQI30,GQI31,GQI32,GQI33,GQI34,GQI35,GQI36,GQI37,GQI38,GQI39,';
     z := z + 'GQJ30,GQJ31,GQJ32,GQJ33,GQJ34,GQJ35,GQJ36,GQJ37,GQJ38,GQJ39,GQK30,GQK31,GQK32,GQK33,GQK34,';
     z := z + 'GQK35,GQK36,GQK37,GQK38,GQK39,GQL30,GQL31,GQL32,GQL33,GQL34,GQL35,GQL36,GQL37,GQL38,GQL39,';
     z := z + 'GQM30,GQM31,GQM32,GQM33,GQM34,GQM35,GQM36,GQM37,GQM38,GQM39,GQN30,GQN31,GQN32,GQN33,GQN34,';
     z := z + 'GQN35,GQN36,GQN37,GQN38,GQN39,GQO30,GQO31,GQO32,GQO33,GQO34,GQO35,GQO36,GQO37,GQO38,GQO39,';
     z := z + 'GQP30,GQP31,GQP32,GQP33,GQP34,GQP35,GQP36,GQP37,GQP38,GQP39,GQQ30,GQQ31,GQQ32,GQQ33,GQQ34,';
     z := z + 'GQQ35,GQQ36,GQQ37,GQQ38,GQQ39,GQR30,GQR31,GQR32,GQR33,GQR34,PCE9  ,PCM   ,PCN   ,PCP   ,PCT   ,';
     z := z + 'GQA20,GQA21,GQA22,GQA23,GQA24,GQA25,GQA26,GQA27,GQA28,GQA29,GQB20,GQB21,GQB22,GQB23,GQB24,';
     z := z + 'GQB25,GQB26,GQB27,GQB28,GQB29,GQC20,GQC21,GQC22,GQC23,GQC24,GQC25,GQC26,GQC27,GQC28,GQC29,';
     z := z + 'GQD20,GQD21,GQD22,GQD23,GQD24,GQD25,GQD26,GQD27,GQD28,GQD29,GQE20,GQE21,GQE22,GQE23,GQE24,';
     z := z + 'GQE25,GQE26,GQE27,GQE28,GQE29,GQF20,GQF21,GQF22,GQF23,GQF24,GQF25,GQF26,GQF27,GQF28,GQF29,';
     z := z + 'GQG20,GQG21,GQG22,GQG23,GQG24,GQG25,GQG26,GQG27,GQG28,GQG29,GQH20,GQH21,GQH22,GQH23,GQH24,';
     z := z + 'GQH25,GQH26,GQH27,GQH28,GQH29,GQI20,GQI21,GQI22,GQI23,GQI24,GQI25,GQI26,GQI27,GQI28,GQI29,';
     z := z + 'GQJ20,GQJ21,GQJ22,GQJ23,GQJ24,GQJ25,GQJ26,GQJ27,GQJ28,GQJ29,GQK20,GQK21,GQK22,GQK23,GQK24,';
     z := z + 'GQK25,GQK26,GQK27,GQK28,GQK29,GQL20,GQL21,GQL22,GQL23,GQL24,GQL25,GQL26,GQL27,GQL28,GQL29,';
     z := z + 'GQM20,GQM21,GQM22,GQM23,GQM24,GQM25,GQM26,GQM27,GQM28,GQM29,GQN20,GQN21,GQN22,GQN23,GQN24,';
     z := z + 'GQN25,GQN26,GQN27,GQN28,GQN29,GQO20,GQO21,GQO22,GQO23,GQO24,GQO25,GQO26,GQO27,GQO28,GQO29,';
     z := z + 'GQP20,GQP21,GQP22,GQP23,GQP24,GQP25,GQP26,GQP27,GQP28,GQP29,GQQ20,GQQ21,GQQ22,GQQ23,GQQ24,';
     z := z + 'GQQ25,GQQ26,GQQ27,GQQ28,GQQ29,GQR20,GQR21,GQR22,GQR23,GQR24,PCT3  ,PCU   ,PCX   ,PCY0  ,PCY9  ,';
     z := z + 'GQA10,GQA11,GQA12,GQA13,GQA14,GQA15,GQA16,GQA17,GQA18,GQA19,GQB10,GQB11,GQB12,GQB13,GQB14,';
     z := z + 'GQB15,GQB16,GQB17,GQB18,GQB19,GQC10,GQC11,GQC12,GQC13,GQC14,GQC15,GQC16,GQC17,GQC18,GQC19,';
     z := z + 'GQD10,GQD11,GQD12,GQD13,GQD14,GQD15,GQD16,GQD17,GQD18,GQD19,GQE10,GQE11,GQE12,GQE13,GQE14,';
     z := z + 'GQE15,GQE16,GQE17,GQE18,GQE19,GQF10,GQF11,GQF12,GQF13,GQF14,GQF15,GQF16,GQF17,GQF18,GQF19,';
     z := z + 'GQG10,GQG11,GQG12,GQG13,GQG14,GQG15,GQG16,GQG17,GQG18,GQG19,GQH10,GQH11,GQH12,GQH13,GQH14,';
     z := z + 'GQH15,GQH16,GQH17,GQH18,GQH19,GQI10,GQI11,GQI12,GQI13,GQI14,GQI15,GQI16,GQI17,GQI18,GQI19,';
     z := z + 'GQJ10,GQJ11,GQJ12,GQJ13,GQJ14,GQJ15,GQJ16,GQJ17,GQJ18,GQJ19,GQK10,GQK11,GQK12,GQK13,GQK14,';
     z := z + 'GQK15,GQK16,GQK17,GQK18,GQK19,GQL10,GQL11,GQL12,GQL13,GQL14,GQL15,GQL16,GQL17,GQL18,GQL19,';
     z := z + 'GQM10,GQM11,GQM12,GQM13,GQM14,GQM15,GQM16,GQM17,GQM18,GQM19,GQN10,GQN11,GQN12,GQN13,GQN14,';
     z := z + 'GQN15,GQN16,GQN17,GQN18,GQN19,GQO10,GQO11,GQO12,GQO13,GQO14,GQO15,GQO16,GQO17,GQO18,GQO19,';
     z := z + 'GQP10,GQP11,GQP12,GQP13,GQP14,GQP15,GQP16,GQP17,GQP18,GQP19,GQQ10,GQQ11,GQQ12,GQQ13,GQQ14,';
     z := z + 'GQQ15,GQQ16,GQQ17,GQQ18,GQQ19,GQR10,GQR11,GQR12,GQR13,GQR14,PD2   ,PD4   ,PD6   ,PDL   ,PDU   ,';
     z := z + 'GQA00,GQA01,GQA02,GQA03,GQA04,GQA05,GQA06,GQA07,GQA08,GQA09,GQB00,GQB01,GQB02,GQB03,GQB04,';
     z := z + 'GQB05,GQB06,GQB07,GQB08,GQB09,GQC00,GQC01,GQC02,GQC03,GQC04,GQC05,GQC06,GQC07,GQC08,GQC09,';
     z := z + 'GQD00,GQD01,GQD02,GQD03,GQD04,GQD05,GQD06,GQD07,GQD08,GQD09,GQE00,GQE01,GQE02,GQE03,GQE04,';
     z := z + 'GQE05,GQE06,GQE07,GQE08,GQE09,GQF00,GQF01,GQF02,GQF03,GQF04,GQF05,GQF06,GQF07,GQF08,GQF09,';
     z := z + 'GQG00,GQG01,GQG02,GQG03,GQG04,GQG05,GQG06,GQG07,GQG08,GQG09,GQH00,GQH01,GQH02,GQH03,GQH04,';
     z := z + 'GQH05,GQH06,GQH07,GQH08,GQH09,GQI00,GQI01,GQI02,GQI03,GQI04,GQI05,GQI06,GQI07,GQI08,GQI09,';
     z := z + 'GQJ00,GQJ01,GQJ02,GQJ03,GQJ04,GQJ05,GQJ06,GQJ07,GQJ08,GQJ09,GQK00,GQK01,GQK02,GQK03,GQK04,';
     z := z + 'GQK05,GQK06,GQK07,GQK08,GQK09,GQL00,GQL01,GQL02,GQL03,GQL04,GQL05,GQL06,GQL07,GQL08,GQL09,';
     z := z + 'GQM00,GQM01,GQM02,GQM03,GQM04,GQM05,GQM06,GQM07,GQM08,GQM09,GQN00,GQN01,GQN02,GQN03,GQN04,';
     z := z + 'GQN05,GQN06,GQN07,GQN08,GQN09,GQO00,GQO01,GQO02,GQO03,GQO04,GQO05,GQO06,GQO07,GQO08,GQO09,';
     z := z + 'GQP00,GQP01,GQP02,GQP03,GQP04,GQP05,GQP06,GQP07,GQP08,GQP09,GQQ00,GQQ01,GQQ02,GQQ03,GQQ04,';
     z := z + 'GQQ05,GQQ06,GQQ07,GQQ08,GQQ09,GQR00,GQR01,GQR02,GQR03,GQR04,PE3   ,PE4   ,PEA   ,PEA6  ,PEA8  ,';
     z := z + 'GPA90,GPA91,GPA92,GPA93,GPA94,GPA95,GPA96,GPA97,GPA98,GPA99,GPB90,GPB91,GPB92,GPB93,GPB94,';
     z := z + 'GPB95,GPB96,GPB97,GPB98,GPB99,GPC90,GPC91,GPC92,GPC93,GPC94,GPC95,GPC96,GPC97,GPC98,GPC99,';
     z := z + 'GPD90,GPD91,GPD92,GPD93,GPD94,GPD95,GPD96,GPD97,GPD98,GPD99,GPE90,GPE91,GPE92,GPE93,GPE94,';
     z := z + 'GPE95,GPE96,GPE97,GPE98,GPE99,GPF90,GPF91,GPF92,GPF93,GPF94,GPF95,GPF96,GPF97,GPF98,GPF99,';
     z := z + 'GPG90,GPG91,GPG92,GPG93,GPG94,GPG95,GPG96,GPG97,GPG98,GPG99,GPH90,GPH91,GPH92,GPH93,GPH94,';
     z := z + 'GPH95,GPH96,GPH97,GPH98,GPH99,GPI90,GPI91,GPI92,GPI93,GPI94,GPI95,GPI96,GPI97,GPI98,GPI99,';
     z := z + 'GPJ90,GPJ91,GPJ92,GPJ93,GPJ94,GPJ95,GPJ96,GPJ97,GPJ98,GPJ99,GPK90,GPK91,GPK92,GPK93,GPK94,';
     z := z + 'GPK95,GPK96,GPK97,GPK98,GPK99,GPL90,GPL91,GPL92,GPL93,GPL94,GPL95,GPL96,GPL97,GPL98,GPL99,';
     z := z + 'GPM90,GPM91,GPM92,GPM93,GPM94,GPM95,GPM96,GPM97,GPM98,GPM99,GPN90,GPN91,GPN92,GPN93,GPN94,';
     z := z + 'GPN95,GPN96,GPN97,GPN98,GPN99,GPO90,GPO91,GPO92,GPO93,GPO94,GPO95,GPO96,GPO97,GPO98,GPO99,';
     z := z + 'GPP90,GPP91,GPP92,GPP93,GPP94,GPP95,GPP96,GPP97,GPP98,GPP99,GPQ90,GPQ91,GPQ92,GPQ93,GPQ94,';
     z := z + 'GPQ95,GPQ96,GPQ97,GPQ98,GPQ99,GPR90,GPR91,GPR92,GPR93,GPR94,PEA9  ,PEI   ,PEK   ,PEL   ,PEP   ,';
     z := z + 'GPA80,GPA81,GPA82,GPA83,GPA84,GPA85,GPA86,GPA87,GPA88,GPA89,GPB80,GPB81,GPB82,GPB83,GPB84,';
     z := z + 'GPB85,GPB86,GPB87,GPB88,GPB89,GPC80,GPC81,GPC82,GPC83,GPC84,GPC85,GPC86,GPC87,GPC88,GPC89,';
     z := z + 'GPD80,GPD81,GPD82,GPD83,GPD84,GPD85,GPD86,GPD87,GPD88,GPD89,GPE80,GPE81,GPE82,GPE83,GPE84,';
     z := z + 'GPE85,GPE86,GPE87,GPE88,GPE89,GPF80,GPF81,GPF82,GPF83,GPF84,GPF85,GPF86,GPF87,GPF88,GPF89,';
     z := z + 'GPG80,GPG81,GPG82,GPG83,GPG84,GPG85,GPG86,GPG87,GPG88,GPG89,GPH80,GPH81,GPH82,GPH83,GPH84,';
     z := z + 'GPH85,GPH86,GPH87,GPH88,GPH89,GPI80,GPI81,GPI82,GPI83,GPI84,GPI85,GPI86,GPI87,GPI88,GPI89,';
     z := z + 'GPJ80,GPJ81,GPJ82,GPJ83,GPJ84,GPJ85,GPJ86,GPJ87,GPJ88,GPJ89,GPK80,GPK81,GPK82,GPK83,GPK84,';
     z := z + 'GPK85,GPK86,GPK87,GPK88,GPK89,GPL80,GPL81,GPL82,GPL83,GPL84,GPL85,GPL86,GPL87,GPL88,GPL89,';
     z := z + 'GPM80,GPM81,GPM82,GPM83,GPM84,GPM85,GPM86,GPM87,GPM88,GPM89,GPN80,GPN81,GPN82,GPN83,GPN84,';
     z := z + 'GPN85,GPN86,GPN87,GPN88,GPN89,GPO80,GPO81,GPO82,GPO83,GPO84,GPO85,GPO86,GPO87,GPO88,GPO89,';
     z := z + 'GPP80,GPP81,GPP82,GPP83,GPP84,GPP85,GPP86,GPP87,GPP88,GPP89,GPQ80,GPQ81,GPQ82,GPQ83,GPQ84,';
     z := z + 'GPQ85,GPQ86,GPQ87,GPQ88,GPQ89,GPR80,GPR81,GPR82,GPR83,GPR84,PER   ,PES   ,PET   ,PEU   ,PEX   ,';
     z := z + 'GPA70,GPA71,GPA72,GPA73,GPA74,GPA75,GPA76,GPA77,GPA78,GPA79,GPB70,GPB71,GPB72,GPB73,GPB74,';
     z := z + 'GPB75,GPB76,GPB77,GPB78,GPB79,GPC70,GPC71,GPC72,GPC73,GPC74,GPC75,GPC76,GPC77,GPC78,GPC79,';
     z := z + 'GPD70,GPD71,GPD72,GPD73,GPD74,GPD75,GPD76,GPD77,GPD78,GPD79,GPE70,GPE71,GPE72,GPE73,GPE74,';
     z := z + 'GPE75,GPE76,GPE77,GPE78,GPE79,GPF70,GPF71,GPF72,GPF73,GPF74,GPF75,GPF76,GPF77,GPF78,GPF79,';
     z := z + 'GPG70,GPG71,GPG72,GPG73,GPG74,GPG75,GPG76,GPG77,GPG78,GPG79,GPH70,GPH71,GPH72,GPH73,GPH74,';
     z := z + 'GPH75,GPH76,GPH77,GPH78,GPH79,GPI70,GPI71,GPI72,GPI73,GPI74,GPI75,GPI76,GPI77,GPI78,GPI79,';
     z := z + 'GPJ70,GPJ71,GPJ72,GPJ73,GPJ74,GPJ75,GPJ76,GPJ77,GPJ78,GPJ79,GPK70,GPK71,GPK72,GPK73,GPK74,';
     z := z + 'GPK75,GPK76,GPK77,GPK78,GPK79,GPL70,GPL71,GPL72,GPL73,GPL74,GPL75,GPL76,GPL77,GPL78,GPL79,';
     z := z + 'GPM70,GPM71,GPM72,GPM73,GPM74,GPM75,GPM76,GPM77,GPM78,GPM79,GPN70,GPN71,GPN72,GPN73,GPN74,';
     z := z + 'GPN75,GPN76,GPN77,GPN78,GPN79,GPO70,GPO71,GPO72,GPO73,GPO74,GPO75,GPO76,GPO77,GPO78,GPO79,';
     z := z + 'GPP70,GPP71,GPP72,GPP73,GPP74,GPP75,GPP76,GPP77,GPP78,GPP79,GPQ70,GPQ71,GPQ72,GPQ73,GPQ74,';
     z := z + 'GPQ75,GPQ76,GPQ77,GPQ78,GPQ79,GPR70,GPR71,GPR72,GPR73,GPR74,PEY   ,PEZ   ,PF    ,PFG   ,PFH   ,';
     z := z + 'GPA60,GPA61,GPA62,GPA63,GPA64,GPA65,GPA66,GPA67,GPA68,GPA69,GPB60,GPB61,GPB62,GPB63,GPB64,';
     z := z + 'GPB65,GPB66,GPB67,GPB68,GPB69,GPC60,GPC61,GPC62,GPC63,GPC64,GPC65,GPC66,GPC67,GPC68,GPC69,';
     z := z + 'GPD60,GPD61,GPD62,GPD63,GPD64,GPD65,GPD66,GPD67,GPD68,GPD69,GPE60,GPE61,GPE62,GPE63,GPE64,';
     z := z + 'GPE65,GPE66,GPE67,GPE68,GPE69,GPF60,GPF61,GPF62,GPF63,GPF64,GPF65,GPF66,GPF67,GPF68,GPF69,';
     z := z + 'GPG60,GPG61,GPG62,GPG63,GPG64,GPG65,GPG66,GPG67,GPG68,GPG69,GPH60,GPH61,GPH62,GPH63,GPH64,';
     z := z + 'GPH65,GPH66,GPH67,GPH68,GPH69,GPI60,GPI61,GPI62,GPI63,GPI64,GPI65,GPI66,GPI67,GPI68,GPI69,';
     z := z + 'GPJ60,GPJ61,GPJ62,GPJ63,GPJ64,GPJ65,GPJ66,GPJ67,GPJ68,GPJ69,GPK60,GPK61,GPK62,GPK63,GPK64,';
     z := z + 'GPK65,GPK66,GPK67,GPK68,GPK69,GPL60,GPL61,GPL62,GPL63,GPL64,GPL65,GPL66,GPL67,GPL68,GPL69,';
     z := z + 'GPM60,GPM61,GPM62,GPM63,GPM64,GPM65,GPM66,GPM67,GPM68,GPM69,GPN60,GPN61,GPN62,GPN63,GPN64,';
     z := z + 'GPN65,GPN66,GPN67,GPN68,GPN69,GPO60,GPO61,GPO62,GPO63,GPO64,GPO65,GPO66,GPO67,GPO68,GPO69,';
     z := z + 'GPP60,GPP61,GPP62,GPP63,GPP64,GPP65,GPP66,GPP67,GPP68,GPP69,GPQ60,GPQ61,GPQ62,GPQ63,GPQ64,';
     z := z + 'GPQ65,GPQ66,GPQ67,GPQ68,GPQ69,GPR60,GPR61,GPR62,GPR63,GPR64,PFJ   ,PFK   ,PFKC  ,PFM   ,PFO   ,';
     z := z + 'GPA50,GPA51,GPA52,GPA53,GPA54,GPA55,GPA56,GPA57,GPA58,GPA59,GPB50,GPB51,GPB52,GPB53,GPB54,';
     z := z + 'GPB55,GPB56,GPB57,GPB58,GPB59,GPC50,GPC51,GPC52,GPC53,GPC54,GPC55,GPC56,GPC57,GPC58,GPC59,';
     z := z + 'GPD50,GPD51,GPD52,GPD53,GPD54,GPD55,GPD56,GPD57,GPD58,GPD59,GPE50,GPE51,GPE52,GPE53,GPE54,';
     z := z + 'GPE55,GPE56,GPE57,GPE58,GPE59,GPF50,GPF51,GPF52,GPF53,GPF54,GPF55,GPF56,GPF57,GPF58,GPF59,';
     z := z + 'GPG50,GPG51,GPG52,GPG53,GPG54,GPG55,GPG56,GPG57,GPG58,GPG59,GPH50,GPH51,GPH52,GPH53,GPH54,';
     z := z + 'GPH55,GPH56,GPH57,GPH58,GPH59,GPI50,GPI51,GPI52,GPI53,GPI54,GPI55,GPI56,GPI57,GPI58,GPI59,';
     z := z + 'GPJ50,GPJ51,GPJ52,GPJ53,GPJ54,GPJ55,GPJ56,GPJ57,GPJ58,GPJ59,GPK50,GPK51,GPK52,GPK53,GPK54,';
     z := z + 'GPK55,GPK56,GPK57,GPK58,GPK59,GPL50,GPL51,GPL52,GPL53,GPL54,GPL55,GPL56,GPL57,GPL58,GPL59,';
     z := z + 'GPM50,GPM51,GPM52,GPM53,GPM54,GPM55,GPM56,GPM57,GPM58,GPM59,GPN50,GPN51,GPN52,GPN53,GPN54,';
     z := z + 'GPN55,GPN56,GPN57,GPN58,GPN59,GPO50,GPO51,GPO52,GPO53,GPO54,GPO55,GPO56,GPO57,GPO58,GPO59,';
     z := z + 'GPP50,GPP51,GPP52,GPP53,GPP54,GPP55,GPP56,GPP57,GPP58,GPP59,GPQ50,GPQ51,GPQ52,GPQ53,GPQ54,';
     z := z + 'GPQ55,GPQ56,GPQ57,GPQ58,GPQ59,GPR50,GPR51,GPR52,GPR53,GPR54,PFOA  ,PFOC  ,PFOM  ,PFP   ,PFR   ,';
     z := z + 'GPA40,GPA41,GPA42,GPA43,GPA44,GPA45,GPA46,GPA47,GPA48,GPA49,GPB40,GPB41,GPB42,GPB43,GPB44,';
     z := z + 'GPB45,GPB46,GPB47,GPB48,GPB49,GPC40,GPC41,GPC42,GPC43,GPC44,GPC45,GPC46,GPC47,GPC48,GPC49,';
     z := z + 'GPD40,GPD41,GPD42,GPD43,GPD44,GPD45,GPD46,GPD47,GPD48,GPD49,GPE40,GPE41,GPE42,GPE43,GPE44,';
     z := z + 'GPE45,GPE46,GPE47,GPE48,GPE49,GPF40,GPF41,GPF42,GPF43,GPF44,GPF45,GPF46,GPF47,GPF48,GPF49,';
     z := z + 'GPG40,GPG41,GPG42,GPG43,GPG44,GPG45,GPG46,GPG47,GPG48,GPG49,GPH40,GPH41,GPH42,GPH43,GPH44,';
     z := z + 'GPH45,GPH46,GPH47,GPH48,GPH49,GPI40,GPI41,GPI42,GPI43,GPI44,GPI45,GPI46,GPI47,GPI48,GPI49,';
     z := z + 'GPJ40,GPJ41,GPJ42,GPJ43,GPJ44,GPJ45,GPJ46,GPJ47,GPJ48,GPJ49,GPK40,GPK41,GPK42,GPK43,GPK44,';
     z := z + 'GPK45,GPK46,GPK47,GPK48,GPK49,GPL40,GPL41,GPL42,GPL43,GPL44,GPL45,GPL46,GPL47,GPL48,GPL49,';
     z := z + 'GPM40,GPM41,GPM42,GPM43,GPM44,GPM45,GPM46,GPM47,GPM48,GPM49,GPN40,GPN41,GPN42,GPN43,GPN44,';
     z := z + 'GPN45,GPN46,GPN47,GPN48,GPN49,GPO40,GPO41,GPO42,GPO43,GPO44,GPO45,GPO46,GPO47,GPO48,GPO49,';
     z := z + 'GPP40,GPP41,GPP42,GPP43,GPP44,GPP45,GPP46,GPP47,GPP48,GPP49,GPQ40,GPQ41,GPQ42,GPQ43,GPQ44,';
     z := z + 'GPQ45,GPQ46,GPQ47,GPQ48,GPQ49,GPR40,GPR41,GPR42,GPR43,GPR44,PFRG  ,PFRJ  ,PFRT  ,PFT5W ,PFT5X ,';
     z := z + 'GPA30,GPA31,GPA32,GPA33,GPA34,GPA35,GPA36,GPA37,GPA38,GPA39,GPB30,GPB31,GPB32,GPB33,GPB34,';
     z := z + 'GPB35,GPB36,GPB37,GPB38,GPB39,GPC30,GPC31,GPC32,GPC33,GPC34,GPC35,GPC36,GPC37,GPC38,GPC39,';
     z := z + 'GPD30,GPD31,GPD32,GPD33,GPD34,GPD35,GPD36,GPD37,GPD38,GPD39,GPE30,GPE31,GPE32,GPE33,GPE34,';
     z := z + 'GPE35,GPE36,GPE37,GPE38,GPE39,GPF30,GPF31,GPF32,GPF33,GPF34,GPF35,GPF36,GPF37,GPF38,GPF39,';
     z := z + 'GPG30,GPG31,GPG32,GPG33,GPG34,GPG35,GPG36,GPG37,GPG38,GPG39,GPH30,GPH31,GPH32,GPH33,GPH34,';
     z := z + 'GPH35,GPH36,GPH37,GPH38,GPH39,GPI30,GPI31,GPI32,GPI33,GPI34,GPI35,GPI36,GPI37,GPI38,GPI39,';
     z := z + 'GPJ30,GPJ31,GPJ32,GPJ33,GPJ34,GPJ35,GPJ36,GPJ37,GPJ38,GPJ39,GPK30,GPK31,GPK32,GPK33,GPK34,';
     z := z + 'GPK35,GPK36,GPK37,GPK38,GPK39,GPL30,GPL31,GPL32,GPL33,GPL34,GPL35,GPL36,GPL37,GPL38,GPL39,';
     z := z + 'GPM30,GPM31,GPM32,GPM33,GPM34,GPM35,GPM36,GPM37,GPM38,GPM39,GPN30,GPN31,GPN32,GPN33,GPN34,';
     z := z + 'GPN35,GPN36,GPN37,GPN38,GPN39,GPO30,GPO31,GPO32,GPO33,GPO34,GPO35,GPO36,GPO37,GPO38,GPO39,';
     z := z + 'GPP30,GPP31,GPP32,GPP33,GPP34,GPP35,GPP36,GPP37,GPP38,GPP39,GPQ30,GPQ31,GPQ32,GPQ33,GPQ34,';
     z := z + 'GPQ35,GPQ36,GPQ37,GPQ38,GPQ39,GPR30,GPR31,GPR32,GPR33,GPR34,PFT5Z ,PFW   ,PFY   ,PM    ,PMD   ,';
     z := z + 'GPA20,GPA21,GPA22,GPA23,GPA24,GPA25,GPA26,GPA27,GPA28,GPA29,GPB20,GPB21,GPB22,GPB23,GPB24,';
     z := z + 'GPB25,GPB26,GPB27,GPB28,GPB29,GPC20,GPC21,GPC22,GPC23,GPC24,GPC25,GPC26,GPC27,GPC28,GPC29,';
     z := z + 'GPD20,GPD21,GPD22,GPD23,GPD24,GPD25,GPD26,GPD27,GPD28,GPD29,GPE20,GPE21,GPE22,GPE23,GPE24,';
     z := z + 'GPE25,GPE26,GPE27,GPE28,GPE29,GPF20,GPF21,GPF22,GPF23,GPF24,GPF25,GPF26,GPF27,GPF28,GPF29,';
     z := z + 'GPG20,GPG21,GPG22,GPG23,GPG24,GPG25,GPG26,GPG27,GPG28,GPG29,GPH20,GPH21,GPH22,GPH23,GPH24,';
     z := z + 'GPH25,GPH26,GPH27,GPH28,GPH29,GPI20,GPI21,GPI22,GPI23,GPI24,GPI25,GPI26,GPI27,GPI28,GPI29,';
     z := z + 'GPJ20,GPJ21,GPJ22,GPJ23,GPJ24,GPJ25,GPJ26,GPJ27,GPJ28,GPJ29,GPK20,GPK21,GPK22,GPK23,GPK24,';
     z := z + 'GPK25,GPK26,GPK27,GPK28,GPK29,GPL20,GPL21,GPL22,GPL23,GPL24,GPL25,GPL26,GPL27,GPL28,GPL29,';
     z := z + 'GPM20,GPM21,GPM22,GPM23,GPM24,GPM25,GPM26,GPM27,GPM28,GPM29,GPN20,GPN21,GPN22,GPN23,GPN24,';
     z := z + 'GPN25,GPN26,GPN27,GPN28,GPN29,GPO20,GPO21,GPO22,GPO23,GPO24,GPO25,GPO26,GPO27,GPO28,GPO29,';
     z := z + 'GPP20,GPP21,GPP22,GPP23,GPP24,GPP25,GPP26,GPP27,GPP28,GPP29,GPQ20,GPQ21,GPQ22,GPQ23,GPQ24,';
     z := z + 'GPQ25,GPQ26,GPQ27,GPQ28,GPQ29,GPR20,GPR21,GPR22,GPR23,GPR24,PMI   ,PMJ   ,PMM   ,PMU   ,PMW   ,';
     z := z + 'GPA10,GPA11,GPA12,GPA13,GPA14,GPA15,GPA16,GPA17,GPA18,GPA19,GPB10,GPB11,GPB12,GPB13,GPB14,';
     z := z + 'GPB15,GPB16,GPB17,GPB18,GPB19,GPC10,GPC11,GPC12,GPC13,GPC14,GPC15,GPC16,GPC17,GPC18,GPC19,';
     z := z + 'GPD10,GPD11,GPD12,GPD13,GPD14,GPD15,GPD16,GPD17,GPD18,GPD19,GPE10,GPE11,GPE12,GPE13,GPE14,';
     z := z + 'GPE15,GPE16,GPE17,GPE18,GPE19,GPF10,GPF11,GPF12,GPF13,GPF14,GPF15,GPF16,GPF17,GPF18,GPF19,';
     z := z + 'GPG10,GPG11,GPG12,GPG13,GPG14,GPG15,GPG16,GPG17,GPG18,GPG19,GPH10,GPH11,GPH12,GPH13,GPH14,';
     z := z + 'GPH15,GPH16,GPH17,GPH18,GPH19,GPI10,GPI11,GPI12,GPI13,GPI14,GPI15,GPI16,GPI17,GPI18,GPI19,';
     z := z + 'GPJ10,GPJ11,GPJ12,GPJ13,GPJ14,GPJ15,GPJ16,GPJ17,GPJ18,GPJ19,GPK10,GPK11,GPK12,GPK13,GPK14,';
     z := z + 'GPK15,GPK16,GPK17,GPK18,GPK19,GPL10,GPL11,GPL12,GPL13,GPL14,GPL15,GPL16,GPL17,GPL18,GPL19,';
     z := z + 'GPM10,GPM11,GPM12,GPM13,GPM14,GPM15,GPM16,GPM17,GPM18,GPM19,GPN10,GPN11,GPN12,GPN13,GPN14,';
     z := z + 'GPN15,GPN16,GPN17,GPN18,GPN19,GPO10,GPO11,GPO12,GPO13,GPO14,GPO15,GPO16,GPO17,GPO18,GPO19,';
     z := z + 'GPP10,GPP11,GPP12,GPP13,GPP14,GPP15,GPP16,GPP17,GPP18,GPP19,GPQ10,GPQ11,GPQ12,GPQ13,GPQ14,';
     z := z + 'GPQ15,GPQ16,GPQ17,GPQ18,GPQ19,GPR10,GPR11,GPR12,GPR13,GPR14,PH4   ,PH40  ,PHA   ,PHB   ,PHB0  ,';
     z := z + 'GPA00,GPA01,GPA02,GPA03,GPA04,GPA05,GPA06,GPA07,GPA08,GPA09,GPB00,GPB01,GPB02,GPB03,GPB04,';
     z := z + 'GPB05,GPB06,GPB07,GPB08,GPB09,GPC00,GPC01,GPC02,GPC03,GPC04,GPC05,GPC06,GPC07,GPC08,GPC09,';
     z := z + 'GPD00,GPD01,GPD02,GPD03,GPD04,GPD05,GPD06,GPD07,GPD08,GPD09,GPE00,GPE01,GPE02,GPE03,GPE04,';
     z := z + 'GPE05,GPE06,GPE07,GPE08,GPE09,GPF00,GPF01,GPF02,GPF03,GPF04,GPF05,GPF06,GPF07,GPF08,GPF09,';
     z := z + 'GPG00,GPG01,GPG02,GPG03,GPG04,GPG05,GPG06,GPG07,GPG08,GPG09,GPH00,GPH01,GPH02,GPH03,GPH04,';
     z := z + 'GPH05,GPH06,GPH07,GPH08,GPH09,GPI00,GPI01,GPI02,GPI03,GPI04,GPI05,GPI06,GPI07,GPI08,GPI09,';
     z := z + 'GPJ00,GPJ01,GPJ02,GPJ03,GPJ04,GPJ05,GPJ06,GPJ07,GPJ08,GPJ09,GPK00,GPK01,GPK02,GPK03,GPK04,';
     z := z + 'GPK05,GPK06,GPK07,GPK08,GPK09,GPL00,GPL01,GPL02,GPL03,GPL04,GPL05,GPL06,GPL07,GPL08,GPL09,';
     z := z + 'GPM00,GPM01,GPM02,GPM03,GPM04,GPM05,GPM06,GPM07,GPM08,GPM09,GPN00,GPN01,GPN02,GPN03,GPN04,';
     z := z + 'GPN05,GPN06,GPN07,GPN08,GPN09,GPO00,GPO01,GPO02,GPO03,GPO04,GPO05,GPO06,GPO07,GPO08,GPO09,';
     z := z + 'GPP00,GPP01,GPP02,GPP03,GPP04,GPP05,GPP06,GPP07,GPP08,GPP09,GPQ00,GPQ01,GPQ02,GPQ03,GPQ04,';
     z := z + 'GPQ05,GPQ06,GPQ07,GPQ08,GPQ09,GPR00,GPR01,GPR02,GPR03,GPR04,PHC   ,PHC8  ,PHH   ,PHI   ,PHK   ,';
     z := z + 'GOA90,GOA91,GOA92,GOA93,GOA94,GOA95,GOA96,GOA97,GOA98,GOA99,GOB90,GOB91,GOB92,GOB93,GOB94,';
     z := z + 'GOB95,GOB96,GOB97,GOB98,GOB99,GOC90,GOC91,GOC92,GOC93,GOC94,GOC95,GOC96,GOC97,GOC98,GOC99,';
     z := z + 'GOD90,GOD91,GOD92,GOD93,GOD94,GOD95,GOD96,GOD97,GOD98,GOD99,GOE90,GOE91,GOE92,GOE93,GOE94,';
     z := z + 'GOE95,GOE96,GOE97,GOE98,GOE99,GOF90,GOF91,GOF92,GOF93,GOF94,GOF95,GOF96,GOF97,GOF98,GOF99,';
     z := z + 'GOG90,GOG91,GOG92,GOG93,GOG94,GOG95,GOG96,GOG97,GOG98,GOG99,GOH90,GOH91,GOH92,GOH93,GOH94,';
     z := z + 'GOH95,GOH96,GOH97,GOH98,GOH99,GOI90,GOI91,GOI92,GOI93,GOI94,GOI95,GOI96,GOI97,GOI98,GOI99,';
     z := z + 'GOJ90,GOJ91,GOJ92,GOJ93,GOJ94,GOJ95,GOJ96,GOJ97,GOJ98,GOJ99,GOK90,GOK91,GOK92,GOK93,GOK94,';
     z := z + 'GOK95,GOK96,GOK97,GOK98,GOK99,GOL90,GOL91,GOL92,GOL93,GOL94,GOL95,GOL96,GOL97,GOL98,GOL99,';
     z := z + 'GOM90,GOM91,GOM92,GOM93,GOM94,GOM95,GOM96,GOM97,GOM98,GOM99,GON90,GON91,GON92,GON93,GON94,';
     z := z + 'GON95,GON96,GON97,GON98,GON99,GOO90,GOO91,GOO92,GOO93,GOO94,GOO95,GOO96,GOO97,GOO98,GOO99,';
     z := z + 'GOP90,GOP91,GOP92,GOP93,GOP94,GOP95,GOP96,GOP97,GOP98,GOP99,GOQ90,GOQ91,GOQ92,GOQ93,GOQ94,';
     z := z + 'GOQ95,GOQ96,GOQ97,GOQ98,GOQ99,GOR90,GOR91,GOR92,GOR93,GOR94,PHK0A ,PHK0M ,PHL   ,PHM   ,PHP   ,';
     z := z + 'GOA80,GOA81,GOA82,GOA83,GOA84,GOA85,GOA86,GOA87,GOA88,GOA89,GOB80,GOB81,GOB82,GOB83,GOB84,';
     z := z + 'GOB85,GOB86,GOB87,GOB88,GOB89,GOC80,GOC81,GOC82,GOC83,GOC84,GOC85,GOC86,GOC87,GOC88,GOC89,';
     z := z + 'GOD80,GOD81,GOD82,GOD83,GOD84,GOD85,GOD86,GOD87,GOD88,GOD89,GOE80,GOE81,GOE82,GOE83,GOE84,';
     z := z + 'GOE85,GOE86,GOE87,GOE88,GOE89,GOF80,GOF81,GOF82,GOF83,GOF84,GOF85,GOF86,GOF87,GOF88,GOF89,';
     z := z + 'GOG80,GOG81,GOG82,GOG83,GOG84,GOG85,GOG86,GOG87,GOG88,GOG89,GOH80,GOH81,GOH82,GOH83,GOH84,';
     z := z + 'GOH85,GOH86,GOH87,GOH88,GOH89,GOI80,GOI81,GOI82,GOI83,GOI84,GOI85,GOI86,GOI87,GOI88,GOI89,';
     z := z + 'GOJ80,GOJ81,GOJ82,GOJ83,GOJ84,GOJ85,GOJ86,GOJ87,GOJ88,GOJ89,GOK80,GOK81,GOK82,GOK83,GOK84,';
     z := z + 'GOK85,GOK86,GOK87,GOK88,GOK89,GOL80,GOL81,GOL82,GOL83,GOL84,GOL85,GOL86,GOL87,GOL88,GOL89,';
     z := z + 'GOM80,GOM81,GOM82,GOM83,GOM84,GOM85,GOM86,GOM87,GOM88,GOM89,GON80,GON81,GON82,GON83,GON84,';
     z := z + 'GON85,GON86,GON87,GON88,GON89,GOO80,GOO81,GOO82,GOO83,GOO84,GOO85,GOO86,GOO87,GOO88,GOO89,';
     z := z + 'GOP80,GOP81,GOP82,GOP83,GOP84,GOP85,GOP86,GOP87,GOP88,GOP89,GOQ80,GOQ81,GOQ82,GOQ83,GOQ84,';
     z := z + 'GOQ85,GOQ86,GOQ87,GOQ88,GOQ89,GOR80,GOR81,GOR82,GOR83,GOR84,PHR   ,PHS   ,PHV   ,PHZ   ,PI    ,';
     z := z + 'GOA70,GOA71,GOA72,GOA73,GOA74,GOA75,GOA76,GOA77,GOA78,GOA79,GOB70,GOB71,GOB72,GOB73,GOB74,';
     z := z + 'GOB75,GOB76,GOB77,GOB78,GOB79,GOC70,GOC71,GOC72,GOC73,GOC74,GOC75,GOC76,GOC77,GOC78,GOC79,';
     z := z + 'GOD70,GOD71,GOD72,GOD73,GOD74,GOD75,GOD76,GOD77,GOD78,GOD79,GOE70,GOE71,GOE72,GOE73,GOE74,';
     z := z + 'GOE75,GOE76,GOE77,GOE78,GOE79,GOF70,GOF71,GOF72,GOF73,GOF74,GOF75,GOF76,GOF77,GOF78,GOF79,';
     z := z + 'GOG70,GOG71,GOG72,GOG73,GOG74,GOG75,GOG76,GOG77,GOG78,GOG79,GOH70,GOH71,GOH72,GOH73,GOH74,';
     z := z + 'GOH75,GOH76,GOH77,GOH78,GOH79,GOI70,GOI71,GOI72,GOI73,GOI74,GOI75,GOI76,GOI77,GOI78,GOI79,';
     z := z + 'GOJ70,GOJ71,GOJ72,GOJ73,GOJ74,GOJ75,GOJ76,GOJ77,GOJ78,GOJ79,GOK70,GOK71,GOK72,GOK73,GOK74,';
     z := z + 'GOK75,GOK76,GOK77,GOK78,GOK79,GOL70,GOL71,GOL72,GOL73,GOL74,GOL75,GOL76,GOL77,GOL78,GOL79,';
     z := z + 'GOM70,GOM71,GOM72,GOM73,GOM74,GOM75,GOM76,GOM77,GOM78,GOM79,GON70,GON71,GON72,GON73,GON74,';
     z := z + 'GON75,GON76,GON77,GON78,GON79,GOO70,GOO71,GOO72,GOO73,GOO74,GOO75,GOO76,GOO77,GOO78,GOO79,';
     z := z + 'GOP70,GOP71,GOP72,GOP73,GOP74,GOP75,GOP76,GOP77,GOP78,GOP79,GOQ70,GOQ71,GOQ72,GOQ73,GOQ74,';
     z := z + 'GOQ75,GOQ76,GOQ77,GOQ78,GOQ79,GOR70,GOR71,GOR72,GOR73,GOR74,PIS   ,PIS0  ,PJ2   ,PJ3   ,PJ5   ,';
     z := z + 'GOA60,GOA61,GOA62,GOA63,GOA64,GOA65,GOA66,GOA67,GOA68,GOA69,GOB60,GOB61,GOB62,GOB63,GOB64,';
     z := z + 'GOB65,GOB66,GOB67,GOB68,GOB69,GOC60,GOC61,GOC62,GOC63,GOC64,GOC65,GOC66,GOC67,GOC68,GOC69,';
     z := z + 'GOD60,GOD61,GOD62,GOD63,GOD64,GOD65,GOD66,GOD67,GOD68,GOD69,GOE60,GOE61,GOE62,GOE63,GOE64,';
     z := z + 'GOE65,GOE66,GOE67,GOE68,GOE69,GOF60,GOF61,GOF62,GOF63,GOF64,GOF65,GOF66,GOF67,GOF68,GOF69,';
     z := z + 'GOG60,GOG61,GOG62,GOG63,GOG64,GOG65,GOG66,GOG67,GOG68,GOG69,GOH60,GOH61,GOH62,GOH63,GOH64,';
     z := z + 'GOH65,GOH66,GOH67,GOH68,GOH69,GOI60,GOI61,GOI62,GOI63,GOI64,GOI65,GOI66,GOI67,GOI68,GOI69,';
     z := z + 'GOJ60,GOJ61,GOJ62,GOJ63,GOJ64,GOJ65,GOJ66,GOJ67,GOJ68,GOJ69,GOK60,GOK61,GOK62,GOK63,GOK64,';
     z := z + 'GOK65,GOK66,GOK67,GOK68,GOK69,GOL60,GOL61,GOL62,GOL63,GOL64,GOL65,GOL66,GOL67,GOL68,GOL69,';
     z := z + 'GOM60,GOM61,GOM62,GOM63,GOM64,GOM65,GOM66,GOM67,GOM68,GOM69,GON60,GON61,GON62,GON63,GON64,';
     z := z + 'GON65,GON66,GON67,GON68,GON69,GOO60,GOO61,GOO62,GOO63,GOO64,GOO65,GOO66,GOO67,GOO68,GOO69,';
     z := z + 'GOP60,GOP61,GOP62,GOP63,GOP64,GOP65,GOP66,GOP67,GOP68,GOP69,GOQ60,GOQ61,GOQ62,GOQ63,GOQ64,';
     z := z + 'GOQ65,GOQ66,GOQ67,GOQ68,GOQ69,GOR60,GOR61,GOR62,GOR63,GOR64,PJ6   ,PJ7   ,PJ8   ,PJA   ,PJDM  ,';
     z := z + 'GOA50,GOA51,GOA52,GOA53,GOA54,GOA55,GOA56,GOA57,GOA58,GOA59,GOB50,GOB51,GOB52,GOB53,GOB54,';
     z := z + 'GOB55,GOB56,GOB57,GOB58,GOB59,GOC50,GOC51,GOC52,GOC53,GOC54,GOC55,GOC56,GOC57,GOC58,GOC59,';
     z := z + 'GOD50,GOD51,GOD52,GOD53,GOD54,GOD55,GOD56,GOD57,GOD58,GOD59,GOE50,GOE51,GOE52,GOE53,GOE54,';
     z := z + 'GOE55,GOE56,GOE57,GOE58,GOE59,GOF50,GOF51,GOF52,GOF53,GOF54,GOF55,GOF56,GOF57,GOF58,GOF59,';
     z := z + 'GOG50,GOG51,GOG52,GOG53,GOG54,GOG55,GOG56,GOG57,GOG58,GOG59,GOH50,GOH51,GOH52,GOH53,GOH54,';
     z := z + 'GOH55,GOH56,GOH57,GOH58,GOH59,GOI50,GOI51,GOI52,GOI53,GOI54,GOI55,GOI56,GOI57,GOI58,GOI59,';
     z := z + 'GOJ50,GOJ51,GOJ52,GOJ53,GOJ54,GOJ55,GOJ56,GOJ57,GOJ58,GOJ59,GOK50,GOK51,GOK52,GOK53,GOK54,';
     z := z + 'GOK55,GOK56,GOK57,GOK58,GOK59,GOL50,GOL51,GOL52,GOL53,GOL54,GOL55,GOL56,GOL57,GOL58,GOL59,';
     z := z + 'GOM50,GOM51,GOM52,GOM53,GOM54,GOM55,GOM56,GOM57,GOM58,GOM59,GON50,GON51,GON52,GON53,GON54,';
     z := z + 'GON55,GON56,GON57,GON58,GON59,GOO50,GOO51,GOO52,GOO53,GOO54,GOO55,GOO56,GOO57,GOO58,GOO59,';
     z := z + 'GOP50,GOP51,GOP52,GOP53,GOP54,GOP55,GOP56,GOP57,GOP58,GOP59,GOQ50,GOQ51,GOQ52,GOQ53,GOQ54,';
     z := z + 'GOQ55,GOQ56,GOQ57,GOQ58,GOQ59,GOR50,GOR51,GOR52,GOR53,GOR54,PJDO  ,PJT   ,PJW   ,PJX   ,PJY   ,';
     z := z + 'GOA40,GOA41,GOA42,GOA43,GOA44,GOA45,GOA46,GOA47,GOA48,GOA49,GOB40,GOB41,GOB42,GOB43,GOB44,';
     z := z + 'GOB45,GOB46,GOB47,GOB48,GOB49,GOC40,GOC41,GOC42,GOC43,GOC44,GOC45,GOC46,GOC47,GOC48,GOC49,';
     z := z + 'GOD40,GOD41,GOD42,GOD43,GOD44,GOD45,GOD46,GOD47,GOD48,GOD49,GOE40,GOE41,GOE42,GOE43,GOE44,';
     z := z + 'GOE45,GOE46,GOE47,GOE48,GOE49,GOF40,GOF41,GOF42,GOF43,GOF44,GOF45,GOF46,GOF47,GOF48,GOF49,';
     z := z + 'GOG40,GOG41,GOG42,GOG43,GOG44,GOG45,GOG46,GOG47,GOG48,GOG49,GOH40,GOH41,GOH42,GOH43,GOH44,';
     z := z + 'GOH45,GOH46,GOH47,GOH48,GOH49,GOI40,GOI41,GOI42,GOI43,GOI44,GOI45,GOI46,GOI47,GOI48,GOI49,';
     z := z + 'GOJ40,GOJ41,GOJ42,GOJ43,GOJ44,GOJ45,GOJ46,GOJ47,GOJ48,GOJ49,GOK40,GOK41,GOK42,GOK43,GOK44,';
     z := z + 'GOK45,GOK46,GOK47,GOK48,GOK49,GOL40,GOL41,GOL42,GOL43,GOL44,GOL45,GOL46,GOL47,GOL48,GOL49,';
     z := z + 'GOM40,GOM41,GOM42,GOM43,GOM44,GOM45,GOM46,GOM47,GOM48,GOM49,GON40,GON41,GON42,GON43,GON44,';
     z := z + 'GON45,GON46,GON47,GON48,GON49,GOO40,GOO41,GOO42,GOO43,GOO44,GOO45,GOO46,GOO47,GOO48,GOO49,';
     z := z + 'GOP40,GOP41,GOP42,GOP43,GOP44,GOP45,GOP46,GOP47,GOP48,GOP49,GOQ40,GOQ41,GOQ42,GOQ43,GOQ44,';
     z := z + 'GOQ45,GOQ46,GOQ47,GOQ48,GOQ49,GOR40,GOR41,GOR42,GOR43,GOR44,PK    ,PKG4  ,PKH0  ,PKH1  ,PKH2  ,';
     z := z + 'GOA30,GOA31,GOA32,GOA33,GOA34,GOA35,GOA36,GOA37,GOA38,GOA39,GOB30,GOB31,GOB32,GOB33,GOB34,';
     z := z + 'GOB35,GOB36,GOB37,GOB38,GOB39,GOC30,GOC31,GOC32,GOC33,GOC34,GOC35,GOC36,GOC37,GOC38,GOC39,';
     z := z + 'GOD30,GOD31,GOD32,GOD33,GOD34,GOD35,GOD36,GOD37,GOD38,GOD39,GOE30,GOE31,GOE32,GOE33,GOE34,';
     z := z + 'GOE35,GOE36,GOE37,GOE38,GOE39,GOF30,GOF31,GOF32,GOF33,GOF34,GOF35,GOF36,GOF37,GOF38,GOF39,';
     z := z + 'GOG30,GOG31,GOG32,GOG33,GOG34,GOG35,GOG36,GOG37,GOG38,GOG39,GOH30,GOH31,GOH32,GOH33,GOH34,';
     z := z + 'GOH35,GOH36,GOH37,GOH38,GOH39,GOI30,GOI31,GOI32,GOI33,GOI34,GOI35,GOI36,GOI37,GOI38,GOI39,';
     z := z + 'GOJ30,GOJ31,GOJ32,GOJ33,GOJ34,GOJ35,GOJ36,GOJ37,GOJ38,GOJ39,GOK30,GOK31,GOK32,GOK33,GOK34,';
     z := z + 'GOK35,GOK36,GOK37,GOK38,GOK39,GOL30,GOL31,GOL32,GOL33,GOL34,GOL35,GOL36,GOL37,GOL38,GOL39,';
     z := z + 'GOM30,GOM31,GOM32,GOM33,GOM34,GOM35,GOM36,GOM37,GOM38,GOM39,GON30,GON31,GON32,GON33,GON34,';
     z := z + 'GON35,GON36,GON37,GON38,GON39,GOO30,GOO31,GOO32,GOO33,GOO34,GOO35,GOO36,GOO37,GOO38,GOO39,';
     z := z + 'GOP30,GOP31,GOP32,GOP33,GOP34,GOP35,GOP36,GOP37,GOP38,GOP39,GOQ30,GOQ31,GOQ32,GOQ33,GOQ34,';
     z := z + 'GOQ35,GOQ36,GOQ37,GOQ38,GOQ39,GOR30,GOR31,GOR32,GOR33,GOR34,PKH3  ,PKH4  ,PKH5  ,PKH5K ,PKH6  ,';
     z := z + 'GOA20,GOA21,GOA22,GOA23,GOA24,GOA25,GOA26,GOA27,GOA28,GOA29,GOB20,GOB21,GOB22,GOB23,GOB24,';
     z := z + 'GOB25,GOB26,GOB27,GOB28,GOB29,GOC20,GOC21,GOC22,GOC23,GOC24,GOC25,GOC26,GOC27,GOC28,GOC29,';
     z := z + 'GOD20,GOD21,GOD22,GOD23,GOD24,GOD25,GOD26,GOD27,GOD28,GOD29,GOE20,GOE21,GOE22,GOE23,GOE24,';
     z := z + 'GOE25,GOE26,GOE27,GOE28,GOE29,GOF20,GOF21,GOF22,GOF23,GOF24,GOF25,GOF26,GOF27,GOF28,GOF29,';
     z := z + 'GOG20,GOG21,GOG22,GOG23,GOG24,GOG25,GOG26,GOG27,GOG28,GOG29,GOH20,GOH21,GOH22,GOH23,GOH24,';
     z := z + 'GOH25,GOH26,GOH27,GOH28,GOH29,GOI20,GOI21,GOI22,GOI23,GOI24,GOI25,GOI26,GOI27,GOI28,GOI29,';
     z := z + 'GOJ20,GOJ21,GOJ22,GOJ23,GOJ24,GOJ25,GOJ26,GOJ27,GOJ28,GOJ29,GOK20,GOK21,GOK22,GOK23,GOK24,';
     z := z + 'GOK25,GOK26,GOK27,GOK28,GOK29,GOL20,GOL21,GOL22,GOL23,GOL24,GOL25,GOL26,GOL27,GOL28,GOL29,';
     z := z + 'GOM20,GOM21,GOM22,GOM23,GOM24,GOM25,GOM26,GOM27,GOM28,GOM29,GON20,GON21,GON22,GON23,GON24,';
     z := z + 'GON25,GON26,GON27,GON28,GON29,GOO20,GOO21,GOO22,GOO23,GOO24,GOO25,GOO26,GOO27,GOO28,GOO29,';
     z := z + 'GOP20,GOP21,GOP22,GOP23,GOP24,GOP25,GOP26,GOP27,GOP28,GOP29,GOQ20,GOQ21,GOQ22,GOQ23,GOQ24,';
     z := z + 'GOQ25,GOQ26,GOQ27,GOQ28,GOQ29,GOR20,GOR21,GOR22,GOR23,GOR24,PKH7  ,PKH8  ,PKH9  ,PKL   ,PKP1  ,';
     z := z + 'GOA10,GOA11,GOA12,GOA13,GOA14,GOA15,GOA16,GOA17,GOA18,GOA19,GOB10,GOB11,GOB12,GOB13,GOB14,';
     z := z + 'GOB15,GOB16,GOB17,GOB18,GOB19,GOC10,GOC11,GOC12,GOC13,GOC14,GOC15,GOC16,GOC17,GOC18,GOC19,';
     z := z + 'GOD10,GOD11,GOD12,GOD13,GOD14,GOD15,GOD16,GOD17,GOD18,GOD19,GOE10,GOE11,GOE12,GOE13,GOE14,';
     z := z + 'GOE15,GOE16,GOE17,GOE18,GOE19,GOF10,GOF11,GOF12,GOF13,GOF14,GOF15,GOF16,GOF17,GOF18,GOF19,';
     z := z + 'GOG10,GOG11,GOG12,GOG13,GOG14,GOG15,GOG16,GOG17,GOG18,GOG19,GOH10,GOH11,GOH12,GOH13,GOH14,';
     z := z + 'GOH15,GOH16,GOH17,GOH18,GOH19,GOI10,GOI11,GOI12,GOI13,GOI14,GOI15,GOI16,GOI17,GOI18,GOI19,';
     z := z + 'GOJ10,GOJ11,GOJ12,GOJ13,GOJ14,GOJ15,GOJ16,GOJ17,GOJ18,GOJ19,GOK10,GOK11,GOK12,GOK13,GOK14,';
     z := z + 'GOK15,GOK16,GOK17,GOK18,GOK19,GOL10,GOL11,GOL12,GOL13,GOL14,GOL15,GOL16,GOL17,GOL18,GOL19,';
     z := z + 'GOM10,GOM11,GOM12,GOM13,GOM14,GOM15,GOM16,GOM17,GOM18,GOM19,GON10,GON11,GON12,GON13,GON14,';
     z := z + 'GON15,GON16,GON17,GON18,GON19,GOO10,GOO11,GOO12,GOO13,GOO14,GOO15,GOO16,GOO17,GOO18,GOO19,';
     z := z + 'GOP10,GOP11,GOP12,GOP13,GOP14,GOP15,GOP16,GOP17,GOP18,GOP19,GOQ10,GOQ11,GOQ12,GOQ13,GOQ14,';
     z := z + 'GOQ15,GOQ16,GOQ17,GOQ18,GOQ19,GOR10,GOR11,GOR12,GOR13,GOR14,PKP2  ,PKP4  ,PKP5  ,PLA   ,PLU   ,';
     z := z + 'GOA00,GOA01,GOA02,GOA03,GOA04,GOA05,GOA06,GOA07,GOA08,GOA09,GOB00,GOB01,GOB02,GOB03,GOB04,';
     z := z + 'GOB05,GOB06,GOB07,GOB08,GOB09,GOC00,GOC01,GOC02,GOC03,GOC04,GOC05,GOC06,GOC07,GOC08,GOC09,';
     z := z + 'GOD00,GOD01,GOD02,GOD03,GOD04,GOD05,GOD06,GOD07,GOD08,GOD09,GOE00,GOE01,GOE02,GOE03,GOE04,';
     z := z + 'GOE05,GOE06,GOE07,GOE08,GOE09,GOF00,GOF01,GOF02,GOF03,GOF04,GOF05,GOF06,GOF07,GOF08,GOF09,';
     z := z + 'GOG00,GOG01,GOG02,GOG03,GOG04,GOG05,GOG06,GOG07,GOG08,GOG09,GOH00,GOH01,GOH02,GOH03,GOH04,';
     z := z + 'GOH05,GOH06,GOH07,GOH08,GOH09,GOI00,GOI01,GOI02,GOI03,GOI04,GOI05,GOI06,GOI07,GOI08,GOI09,';
     z := z + 'GOJ00,GOJ01,GOJ02,GOJ03,GOJ04,GOJ05,GOJ06,GOJ07,GOJ08,GOJ09,GOK00,GOK01,GOK02,GOK03,GOK04,';
     z := z + 'GOK05,GOK06,GOK07,GOK08,GOK09,GOL00,GOL01,GOL02,GOL03,GOL04,GOL05,GOL06,GOL07,GOL08,GOL09,';
     z := z + 'GOM00,GOM01,GOM02,GOM03,GOM04,GOM05,GOM06,GOM07,GOM08,GOM09,GON00,GON01,GON02,GON03,GON04,';
     z := z + 'GON05,GON06,GON07,GON08,GON09,GOO00,GOO01,GOO02,GOO03,GOO04,GOO05,GOO06,GOO07,GOO08,GOO09,';
     z := z + 'GOP00,GOP01,GOP02,GOP03,GOP04,GOP05,GOP06,GOP07,GOP08,GOP09,GOQ00,GOQ01,GOQ02,GOQ03,GOQ04,';
     z := z + 'GOQ05,GOQ06,GOQ07,GOQ08,GOQ09,GOR00,GOR01,GOR02,GOR03,GOR04,PLX   ,PLY   ,PLZ   ,POA   ,POD   ,';
     z := z + 'GNA90,GNA91,GNA92,GNA93,GNA94,GNA95,GNA96,GNA97,GNA98,GNA99,GNB90,GNB91,GNB92,GNB93,GNB94,';
     z := z + 'GNB95,GNB96,GNB97,GNB98,GNB99,GNC90,GNC91,GNC92,GNC93,GNC94,GNC95,GNC96,GNC97,GNC98,GNC99,';
     z := z + 'GND90,GND91,GND92,GND93,GND94,GND95,GND96,GND97,GND98,GND99,GNE90,GNE91,GNE92,GNE93,GNE94,';
     z := z + 'GNE95,GNE96,GNE97,GNE98,GNE99,GNF90,GNF91,GNF92,GNF93,GNF94,GNF95,GNF96,GNF97,GNF98,GNF99,';
     z := z + 'GNG90,GNG91,GNG92,GNG93,GNG94,GNG95,GNG96,GNG97,GNG98,GNG99,GNH90,GNH91,GNH92,GNH93,GNH94,';
     z := z + 'GNH95,GNH96,GNH97,GNH98,GNH99,GNI90,GNI91,GNI92,GNI93,GNI94,GNI95,GNI96,GNI97,GNI98,GNI99,';
     z := z + 'GNJ90,GNJ91,GNJ92,GNJ93,GNJ94,GNJ95,GNJ96,GNJ97,GNJ98,GNJ99,GNK90,GNK91,GNK92,GNK93,GNK94,';
     z := z + 'GNK95,GNK96,GNK97,GNK98,GNK99,GNL90,GNL91,GNL92,GNL93,GNL94,GNL95,GNL96,GNL97,GNL98,GNL99,';
     z := z + 'GNM90,GNM91,GNM92,GNM93,GNM94,GNM95,GNM96,GNM97,GNM98,GNM99,GNN90,GNN91,GNN92,GNN93,GNN94,';
     z := z + 'GNN95,GNN96,GNN97,GNN98,GNN99,GNO90,GNO91,GNO92,GNO93,GNO94,GNO95,GNO96,GNO97,GNO98,GNO99,';
     z := z + 'GNP90,GNP91,GNP92,GNP93,GNP94,GNP95,GNP96,GNP97,GNP98,GNP99,GNQ90,GNQ91,GNQ92,GNQ93,GNQ94,';
     z := z + 'GNQ95,GNQ96,GNQ97,GNQ98,GNQ99,GNR90,GNR91,GNR92,GNR93,GNR94,POE   ,POH   ,POH0  ,POJ0  ,POK   ,';
     z := z + 'GNA80,GNA81,GNA82,GNA83,GNA84,GNA85,GNA86,GNA87,GNA88,GNA89,GNB80,GNB81,GNB82,GNB83,GNB84,';
     z := z + 'GNB85,GNB86,GNB87,GNB88,GNB89,GNC80,GNC81,GNC82,GNC83,GNC84,GNC85,GNC86,GNC87,GNC88,GNC89,';
     z := z + 'GND80,GND81,GND82,GND83,GND84,GND85,GND86,GND87,GND88,GND89,GNE80,GNE81,GNE82,GNE83,GNE84,';
     z := z + 'GNE85,GNE86,GNE87,GNE88,GNE89,GNF80,GNF81,GNF82,GNF83,GNF84,GNF85,GNF86,GNF87,GNF88,GNF89,';
     z := z + 'GNG80,GNG81,GNG82,GNG83,GNG84,GNG85,GNG86,GNG87,GNG88,GNG89,GNH80,GNH81,GNH82,GNH83,GNH84,';
     z := z + 'GNH85,GNH86,GNH87,GNH88,GNH89,GNI80,GNI81,GNI82,GNI83,GNI84,GNI85,GNI86,GNI87,GNI88,GNI89,';
     z := z + 'GNJ80,GNJ81,GNJ82,GNJ83,GNJ84,GNJ85,GNJ86,GNJ87,GNJ88,GNJ89,GNK80,GNK81,GNK82,GNK83,GNK84,';
     z := z + 'GNK85,GNK86,GNK87,GNK88,GNK89,GNL80,GNL81,GNL82,GNL83,GNL84,GNL85,GNL86,GNL87,GNL88,GNL89,';
     z := z + 'GNM80,GNM81,GNM82,GNM83,GNM84,GNM85,GNM86,GNM87,GNM88,GNM89,GNN80,GNN81,GNN82,GNN83,GNN84,';
     z := z + 'GNN85,GNN86,GNN87,GNN88,GNN89,GNO80,GNO81,GNO82,GNO83,GNO84,GNO85,GNO86,GNO87,GNO88,GNO89,';
     z := z + 'GNP80,GNP81,GNP82,GNP83,GNP84,GNP85,GNP86,GNP87,GNP88,GNP89,GNQ80,GNQ81,GNQ82,GNQ83,GNQ84,';
     z := z + 'GNQ85,GNQ86,GNQ87,GNQ88,GNQ89,GNR80,GNR81,GNR82,GNR83,GNR84,POM   ,PON   ,POX   ,POY   ,POZ   ,';
     z := z + 'GNA70,GNA71,GNA72,GNA73,GNA74,GNA75,GNA76,GNA77,GNA78,GNA79,GNB70,GNB71,GNB72,GNB73,GNB74,';
     z := z + 'GNB75,GNB76,GNB77,GNB78,GNB79,GNC70,GNC71,GNC72,GNC73,GNC74,GNC75,GNC76,GNC77,GNC78,GNC79,';
     z := z + 'GND70,GND71,GND72,GND73,GND74,GND75,GND76,GND77,GND78,GND79,GNE70,GNE71,GNE72,GNE73,GNE74,';
     z := z + 'GNE75,GNE76,GNE77,GNE78,GNE79,GNF70,GNF71,GNF72,GNF73,GNF74,GNF75,GNF76,GNF77,GNF78,GNF79,';
     z := z + 'GNG70,GNG71,GNG72,GNG73,GNG74,GNG75,GNG76,GNG77,GNG78,GNG79,GNH70,GNH71,GNH72,GNH73,GNH74,';
     z := z + 'GNH75,GNH76,GNH77,GNH78,GNH79,GNI70,GNI71,GNI72,GNI73,GNI74,GNI75,GNI76,GNI77,GNI78,GNI79,';
     z := z + 'GNJ70,GNJ71,GNJ72,GNJ73,GNJ74,GNJ75,GNJ76,GNJ77,GNJ78,GNJ79,GNK70,GNK71,GNK72,GNK73,GNK74,';
     z := z + 'GNK75,GNK76,GNK77,GNK78,GNK79,GNL70,GNL71,GNL72,GNL73,GNL74,GNL75,GNL76,GNL77,GNL78,GNL79,';
     z := z + 'GNM70,GNM71,GNM72,GNM73,GNM74,GNM75,GNM76,GNM77,GNM78,GNM79,GNN70,GNN71,GNN72,GNN73,GNN74,';
     z := z + 'GNN75,GNN76,GNN77,GNN78,GNN79,GNO70,GNO71,GNO72,GNO73,GNO74,GNO75,GNO76,GNO77,GNO78,GNO79,';
     z := z + 'GNP70,GNP71,GNP72,GNP73,GNP74,GNP75,GNP76,GNP77,GNP78,GNP79,GNQ70,GNQ71,GNQ72,GNQ73,GNQ74,';
     z := z + 'GNQ75,GNQ76,GNQ77,GNQ78,GNQ79,GNR70,GNR71,GNR72,GNR73,GNR74,PP2   ,PP4   ,PPA   ,PPJ2  ,PPJ7  ,';
     z := z + 'GNA60,GNA61,GNA62,GNA63,GNA64,GNA65,GNA66,GNA67,GNA68,GNA69,GNB60,GNB61,GNB62,GNB63,GNB64,';
     z := z + 'GNB65,GNB66,GNB67,GNB68,GNB69,GNC60,GNC61,GNC62,GNC63,GNC64,GNC65,GNC66,GNC67,GNC68,GNC69,';
     z := z + 'GND60,GND61,GND62,GND63,GND64,GND65,GND66,GND67,GND68,GND69,GNE60,GNE61,GNE62,GNE63,GNE64,';
     z := z + 'GNE65,GNE66,GNE67,GNE68,GNE69,GNF60,GNF61,GNF62,GNF63,GNF64,GNF65,GNF66,GNF67,GNF68,GNF69,';
     z := z + 'GNG60,GNG61,GNG62,GNG63,GNG64,GNG65,GNG66,GNG67,GNG68,GNG69,GNH60,GNH61,GNH62,GNH63,GNH64,';
     z := z + 'GNH65,GNH66,GNH67,GNH68,GNH69,GNI60,GNI61,GNI62,GNI63,GNI64,GNI65,GNI66,GNI67,GNI68,GNI69,';
     z := z + 'GNJ60,GNJ61,GNJ62,GNJ63,GNJ64,GNJ65,GNJ66,GNJ67,GNJ68,GNJ69,GNK60,GNK61,GNK62,GNK63,GNK64,';
     z := z + 'GNK65,GNK66,GNK67,GNK68,GNK69,GNL60,GNL61,GNL62,GNL63,GNL64,GNL65,GNL66,GNL67,GNL68,GNL69,';
     z := z + 'GNM60,GNM61,GNM62,GNM63,GNM64,GNM65,GNM66,GNM67,GNM68,GNM69,GNN60,GNN61,GNN62,GNN63,GNN64,';
     z := z + 'GNN65,GNN66,GNN67,GNN68,GNN69,GNO60,GNO61,GNO62,GNO63,GNO64,GNO65,GNO66,GNO67,GNO68,GNO69,';
     z := z + 'GNP60,GNP61,GNP62,GNP63,GNP64,GNP65,GNP66,GNP67,GNP68,GNP69,GNQ60,GNQ61,GNQ62,GNQ63,GNQ64,';
     z := z + 'GNQ65,GNQ66,GNQ67,GNQ68,GNQ69,GNR60,GNR61,GNR62,GNR63,GNR64,PPY   ,PPY0F ,PPT0S ,PPY0T ,PPZ   ,';
     z := z + 'GNA50,GNA51,GNA52,GNA53,GNA54,GNA55,GNA56,GNA57,GNA58,GNA59,GNB50,GNB51,GNB52,GNB53,GNB54,';
     z := z + 'GNB55,GNB56,GNB57,GNB58,GNB59,GNC50,GNC51,GNC52,GNC53,GNC54,GNC55,GNC56,GNC57,GNC58,GNC59,';
     z := z + 'GND50,GND51,GND52,GND53,GND54,GND55,GND56,GND57,GND58,GND59,GNE50,GNE51,GNE52,GNE53,GNE54,';
     z := z + 'GNE55,GNE56,GNE57,GNE58,GNE59,GNF50,GNF51,GNF52,GNF53,GNF54,GNF55,GNF56,GNF57,GNF58,GNF59,';
     z := z + 'GNG50,GNG51,GNG52,GNG53,GNG54,GNG55,GNG56,GNG57,GNG58,GNG59,GNH50,GNH51,GNH52,GNH53,GNH54,';
     z := z + 'GNH55,GNH56,GNH57,GNH58,GNH59,GNI50,GNI51,GNI52,GNI53,GNI54,GNI55,GNI56,GNI57,GNI58,GNI59,';
     z := z + 'GNJ50,GNJ51,GNJ52,GNJ53,GNJ54,GNJ55,GNJ56,GNJ57,GNJ58,GNJ59,GNK50,GNK51,GNK52,GNK53,GNK54,';
     z := z + 'GNK55,GNK56,GNK57,GNK58,GNK59,GNL50,GNL51,GNL52,GNL53,GNL54,GNL55,GNL56,GNL57,GNL58,GNL59,';
     z := z + 'GNM50,GNM51,GNM52,GNM53,GNM54,GNM55,GNM56,GNM57,GNM58,GNM59,GNN50,GNN51,GNN52,GNN53,GNN54,';
     z := z + 'GNN55,GNN56,GNN57,GNN58,GNN59,GNO50,GNO51,GNO52,GNO53,GNO54,GNO55,GNO56,GNO57,GNO58,GNO59,';
     z := z + 'GNP50,GNP51,GNP52,GNP53,GNP54,GNP55,GNP56,GNP57,GNP58,GNP59,GNQ50,GNQ51,GNQ52,GNQ53,GNQ54,';
     z := z + 'GNQ55,GNQ56,GNQ57,GNQ58,GNQ59,GNR50,GNR51,GNR52,GNR53,GNR54,PR1F  ,PR1M  ,PS0   ,PS2   ,PS5   ,';
     z := z + 'GNA40,GNA41,GNA42,GNA43,GNA44,GNA45,GNA46,GNA47,GNA48,GNA49,GNB40,GNB41,GNB42,GNB43,GNB44,';
     z := z + 'GNB45,GNB46,GNB47,GNB48,GNB49,GNC40,GNC41,GNC42,GNC43,GNC44,GNC45,GNC46,GNC47,GNC48,GNC49,';
     z := z + 'GND40,GND41,GND42,GND43,GND44,GND45,GND46,GND47,GND48,GND49,GNE40,GNE41,GNE42,GNE43,GNE44,';
     z := z + 'GNE45,GNE46,GNE47,GNE48,GNE49,GNF40,GNF41,GNF42,GNF43,GNF44,GNF45,GNF46,GNF47,GNF48,GNF49,';
     z := z + 'GNG40,GNG41,GNG42,GNG43,GNG44,GNG45,GNG46,GNG47,GNG48,GNG49,GNH40,GNH41,GNH42,GNH43,GNH44,';
     z := z + 'GNH45,GNH46,GNH47,GNH48,GNH49,GNI40,GNI41,GNI42,GNI43,GNI44,GNI45,GNI46,GNI47,GNI48,GNI49,';
     z := z + 'GNJ40,GNJ41,GNJ42,GNJ43,GNJ44,GNJ45,GNJ46,GNJ47,GNJ48,GNJ49,GNK40,GNK41,GNK42,GNK43,GNK44,';
     z := z + 'GNK45,GNK46,GNK47,GNK48,GNK49,GNL40,GNL41,GNL42,GNL43,GNL44,GNL45,GNL46,GNL47,GNL48,GNL49,';
     z := z + 'GNM40,GNM41,GNM42,GNM43,GNM44,GNM45,GNM46,GNM47,GNM48,GNM49,GNN40,GNN41,GNN42,GNN43,GNN44,';
     z := z + 'GNN45,GNN46,GNN47,GNN48,GNN49,GNO40,GNO41,GNO42,GNO43,GNO44,GNO45,GNO46,GNO47,GNO48,GNO49,';
     z := z + 'GNP40,GNP41,GNP42,GNP43,GNP44,GNP45,GNP46,GNP47,GNP48,GNP49,GNQ40,GNQ41,GNQ42,GNQ43,GNQ44,';
     z := z + 'GNQ45,GNQ46,GNQ47,GNQ48,GNQ49,GNR40,GNR41,GNR42,GNR43,GNR44,PS7   ,PS9   ,PSM   ,PSP   ,PST   ,';
     z := z + 'GNA30,GNA31,GNA32,GNA33,GNA34,GNA35,GNA36,GNA37,GNA38,GNA39,GNB30,GNB31,GNB32,GNB33,GNB34,';
     z := z + 'GNB35,GNB36,GNB37,GNB38,GNB39,GNC30,GNC31,GNC32,GNC33,GNC34,GNC35,GNC36,GNC37,GNC38,GNC39,';
     z := z + 'GND30,GND31,GND32,GND33,GND34,GND35,GND36,GND37,GND38,GND39,GNE30,GNE31,GNE32,GNE33,GNE34,';
     z := z + 'GNE35,GNE36,GNE37,GNE38,GNE39,GNF30,GNF31,GNF32,GNF33,GNF34,GNF35,GNF36,GNF37,GNF38,GNF39,';
     z := z + 'GNG30,GNG31,GNG32,GNG33,GNG34,GNG35,GNG36,GNG37,GNG38,GNG39,GNH30,GNH31,GNH32,GNH33,GNH34,';
     z := z + 'GNH35,GNH36,GNH37,GNH38,GNH39,GNI30,GNI31,GNI32,GNI33,GNI34,GNI35,GNI36,GNI37,GNI38,GNI39,';
     z := z + 'GNJ30,GNJ31,GNJ32,GNJ33,GNJ34,GNJ35,GNJ36,GNJ37,GNJ38,GNJ39,GNK30,GNK31,GNK32,GNK33,GNK34,';
     z := z + 'GNK35,GNK36,GNK37,GNK38,GNK39,GNL30,GNL31,GNL32,GNL33,GNL34,GNL35,GNL36,GNL37,GNL38,GNL39,';
     z := z + 'GNM30,GNM31,GNM32,GNM33,GNM34,GNM35,GNM36,GNM37,GNM38,GNM39,GNN30,GNN31,GNN32,GNN33,GNN34,';
     z := z + 'GNN35,GNN36,GNN37,GNN38,GNN39,GNO30,GNO31,GNO32,GNO33,GNO34,GNO35,GNO36,GNO37,GNO38,GNO39,';
     z := z + 'GNP30,GNP31,GNP32,GNP33,GNP34,GNP35,GNP36,GNP37,GNP38,GNP39,GNQ30,GNQ31,GNQ32,GNQ33,GNQ34,';
     z := z + 'GNQ35,GNQ36,GNQ37,GNQ38,GNQ39,GNR30,GNR31,GNR32,GNR33,GNR34,PSU   ,PSV   ,PSVA  ,PSV5  ,PSV9  ,';
     z := z + 'GNA20,GNA21,GNA22,GNA23,GNA24,GNA25,GNA26,GNA27,GNA28,GNA29,GNB20,GNB21,GNB22,GNB23,GNB24,';
     z := z + 'GNB25,GNB26,GNB27,GNB28,GNB29,GNC20,GNC21,GNC22,GNC23,GNC24,GNC25,GNC26,GNC27,GNC28,GNC29,';
     z := z + 'GND20,GND21,GND22,GND23,GND24,GND25,GND26,GND27,GND28,GND29,GNE20,GNE21,GNE22,GNE23,GNE24,';
     z := z + 'GNE25,GNE26,GNE27,GNE28,GNE29,GNF20,GNF21,GNF22,GNF23,GNF24,GNF25,GNF26,GNF27,GNF28,GNF29,';
     z := z + 'GNG20,GNG21,GNG22,GNG23,GNG24,GNG25,GNG26,GNG27,GNG28,GNG29,GNH20,GNH21,GNH22,GNH23,GNH24,';
     z := z + 'GNH25,GNH26,GNH27,GNH28,GNH29,GNI20,GNI21,GNI22,GNI23,GNI24,GNI25,GNI26,GNI27,GNI28,GNI29,';
     z := z + 'GNJ20,GNJ21,GNJ22,GNJ23,GNJ24,GNJ25,GNJ26,GNJ27,GNJ28,GNJ29,GNK20,GNK21,GNK22,GNK23,GNK24,';
     z := z + 'GNK25,GNK26,GNK27,GNK28,GNK29,GNL20,GNL21,GNL22,GNL23,GNL24,GNL25,GNL26,GNL27,GNL28,GNL29,';
     z := z + 'GNM20,GNM21,GNM22,GNM23,GNM24,GNM25,GNM26,GNM27,GNM28,GNM29,GNN20,GNN21,GNN22,GNN23,GNN24,';
     z := z + 'GNN25,GNN26,GNN27,GNN28,GNN29,GNO20,GNO21,GNO22,GNO23,GNO24,GNO25,GNO26,GNO27,GNO28,GNO29,';
     z := z + 'GNP20,GNP21,GNP22,GNP23,GNP24,GNP25,GNP26,GNP27,GNP28,GNP29,GNQ20,GNQ21,GNQ22,GNQ23,GNQ24,';
     z := z + 'GNQ25,GNQ26,GNQ27,GNQ28,GNQ29,GNR20,GNR21,GNR22,GNR23,GNR24,PT2   ,PT30  ,PT31  ,PT32  ,PT33  ,';
     z := z + 'GNA10,GNA11,GNA12,GNA13,GNA14,GNA15,GNA16,GNA17,GNA18,GNA19,GNB10,GNB11,GNB12,GNB13,GNB14,';
     z := z + 'GNB15,GNB16,GNB17,GNB18,GNB19,GNC10,GNC11,GNC12,GNC13,GNC14,GNC15,GNC16,GNC17,GNC18,GNC19,';
     z := z + 'GND10,GND11,GND12,GND13,GND14,GND15,GND16,GND17,GND18,GND19,GNE10,GNE11,GNE12,GNE13,GNE14,';
     z := z + 'GNE15,GNE16,GNE17,GNE18,GNE19,GNF10,GNF11,GNF12,GNF13,GNF14,GNF15,GNF16,GNF17,GNF18,GNF19,';
     z := z + 'GNG10,GNG11,GNG12,GNG13,GNG14,GNG15,GNG16,GNG17,GNG18,GNG19,GNH10,GNH11,GNH12,GNH13,GNH14,';
     z := z + 'GNH15,GNH16,GNH17,GNH18,GNH19,GNI10,GNI11,GNI12,GNI13,GNI14,GNI15,GNI16,GNI17,GNI18,GNI19,';
     z := z + 'GNJ10,GNJ11,GNJ12,GNJ13,GNJ14,GNJ15,GNJ16,GNJ17,GNJ18,GNJ19,GNK10,GNK11,GNK12,GNK13,GNK14,';
     z := z + 'GNK15,GNK16,GNK17,GNK18,GNK19,GNL10,GNL11,GNL12,GNL13,GNL14,GNL15,GNL16,GNL17,GNL18,GNL19,';
     z := z + 'GNM10,GNM11,GNM12,GNM13,GNM14,GNM15,GNM16,GNM17,GNM18,GNM19,GNN10,GNN11,GNN12,GNN13,GNN14,';
     z := z + 'GNN15,GNN16,GNN17,GNN18,GNN19,GNO10,GNO11,GNO12,GNO13,GNO14,GNO15,GNO16,GNO17,GNO18,GNO19,';
     z := z + 'GNP10,GNP11,GNP12,GNP13,GNP14,GNP15,GNP16,GNP17,GNP18,GNP19,GNQ10,GNQ11,GNQ12,GNQ13,GNQ14,';
     z := z + 'GNQ15,GNQ16,GNQ17,GNQ18,GNQ19,GNR10,GNR11,GNR12,GNR13,GNR14,PT5   ,PT7   ,PT8   ,PT9   ,PTA   ,';
     z := z + 'GNA00,GNA01,GNA02,GNA03,GNA04,GNA05,GNA06,GNA07,GNA08,GNA09,GNB00,GNB01,GNB02,GNB03,GNB04,';
     z := z + 'GNB05,GNB06,GNB07,GNB08,GNB09,GNC00,GNC01,GNC02,GNC03,GNC04,GNC05,GNC06,GNC07,GNC08,GNC09,';
     z := z + 'GND00,GND01,GND02,GND03,GND04,GND05,GND06,GND07,GND08,GND09,GNE00,GNE01,GNE02,GNE03,GNE04,';
     z := z + 'GNE05,GNE06,GNE07,GNE08,GNE09,GNF00,GNF01,GNF02,GNF03,GNF04,GNF05,GNF06,GNF07,GNF08,GNF09,';
     z := z + 'GNG00,GNG01,GNG02,GNG03,GNG04,GNG05,GNG06,GNG07,GNG08,GNG09,GNH00,GNH01,GNH02,GNH03,GNH04,';
     z := z + 'GNH05,GNH06,GNH07,GNH08,GNH09,GNI00,GNI01,GNI02,GNI03,GNI04,GNI05,GNI06,GNI07,GNI08,GNI09,';
     z := z + 'GNJ00,GNJ01,GNJ02,GNJ03,GNJ04,GNJ05,GNJ06,GNJ07,GNJ08,GNJ09,GNK00,GNK01,GNK02,GNK03,GNK04,';
     z := z + 'GNK05,GNK06,GNK07,GNK08,GNK09,GNL00,GNL01,GNL02,GNL03,GNL04,GNL05,GNL06,GNL07,GNL08,GNL09,';
     z := z + 'GNM00,GNM01,GNM02,GNM03,GNM04,GNM05,GNM06,GNM07,GNM08,GNM09,GNN00,GNN01,GNN02,GNN03,GNN04,';
     z := z + 'GNN05,GNN06,GNN07,GNN08,GNN09,GNO00,GNO01,GNO02,GNO03,GNO04,GNO05,GNO06,GNO07,GNO08,GNO09,';
     z := z + 'GNP00,GNP01,GNP02,GNP03,GNP04,GNP05,GNP06,GNP07,GNP08,GNP09,GNQ00,GNQ01,GNQ02,GNQ03,GNQ04,';
     z := z + 'GNQ05,GNQ06,GNQ07,GNQ08,GNQ09,GNR00,GNR01,GNR02,GNR03,GNR04,PTF   ,PTG   ,PTI   ,PTI9  ,PTJ   ,';
     z := z + 'GMA90,GMA91,GMA92,GMA93,GMA94,GMA95,GMA96,GMA97,GMA98,GMA99,GMB90,GMB91,GMB92,GMB93,GMB94,';
     z := z + 'GMB95,GMB96,GMB97,GMB98,GMB99,GMC90,GMC91,GMC92,GMC93,GMC94,GMC95,GMC96,GMC97,GMC98,GMC99,';
     z := z + 'GMD90,GMD91,GMD92,GMD93,GMD94,GMD95,GMD96,GMD97,GMD98,GMD99,GME90,GME91,GME92,GME93,GME94,';
     z := z + 'GME95,GME96,GME97,GME98,GME99,GMF90,GMF91,GMF92,GMF93,GMF94,GMF95,GMF96,GMF97,GMF98,GMF99,';
     z := z + 'GMG90,GMG91,GMG92,GMG93,GMG94,GMG95,GMG96,GMG97,GMG98,GMG99,GMH90,GMH91,GMH92,GMH93,GMH94,';
     z := z + 'GMH95,GMH96,GMH97,GMH98,GMH99,GMI90,GMI91,GMI92,GMI93,GMI94,GMI95,GMI96,GMI97,GMI98,GMI99,';
     z := z + 'GMJ90,GMJ91,GMJ92,GMJ93,GMJ94,GMJ95,GMJ96,GMJ97,GMJ98,GMJ99,GMK90,GMK91,GMK92,GMK93,GMK94,';
     z := z + 'GMK95,GMK96,GMK97,GMK98,GMK99,GML90,GML91,GML92,GML93,GML94,GML95,GML96,GML97,GML98,GML99,';
     z := z + 'GMM90,GMM91,GMM92,GMM93,GMM94,GMM95,GMM96,GMM97,GMM98,GMM99,GMN90,GMN91,GMN92,GMN93,GMN94,';
     z := z + 'GMN95,GMN96,GMN97,GMN98,GMN99,GMO90,GMO91,GMO92,GMO93,GMO94,GMO95,GMO96,GMO97,GMO98,GMO99,';
     z := z + 'GMP90,GMP91,GMP92,GMP93,GMP94,GMP95,GMP96,GMP97,GMP98,GMP99,GMQ90,GMQ91,GMQ92,GMQ93,GMQ94,';
     z := z + 'GMQ95,GMQ96,GMQ97,GMQ98,GMQ99,GMR90,GMR91,GMR92,GMR93,GMR94,PTK   ,PTL   ,PTN   ,PTR   ,PTT   ,';
     z := z + 'GMA80,GMA81,GMA82,GMA83,GMA84,GMA85,GMA86,GMA87,GMA88,GMA89,GMB80,GMB81,GMB82,GMB83,GMB84,';
     z := z + 'GMB85,GMB86,GMB87,GMB88,GMB89,GMC80,GMC81,GMC82,GMC83,GMC84,GMC85,GMC86,GMC87,GMC88,GMC89,';
     z := z + 'GMD80,GMD81,GMD82,GMD83,GMD84,GMD85,GMD86,GMD87,GMD88,GMD89,GME80,GME81,GME82,GME83,GME84,';
     z := z + 'GME85,GME86,GME87,GME88,GME89,GMF80,GMF81,GMF82,GMF83,GMF84,GMF85,GMF86,GMF87,GMF88,GMF89,';
     z := z + 'GMG80,GMG81,GMG82,GMG83,GMG84,GMG85,GMG86,GMG87,GMG88,GMG89,GMH80,GMH81,GMH82,GMH83,GMH84,';
     z := z + 'GMH85,GMH86,GMH87,GMH88,GMH89,GMI80,GMI81,GMI82,GMI83,GMI84,GMI85,GMI86,GMI87,GMI88,GMI89,';
     z := z + 'GMJ80,GMJ81,GMJ82,GMJ83,GMJ84,GMJ85,GMJ86,GMJ87,GMJ88,GMJ89,GMK80,GMK81,GMK82,GMK83,GMK84,';
     z := z + 'GMK85,GMK86,GMK87,GMK88,GMK89,GML80,GML81,GML82,GML83,GML84,GML85,GML86,GML87,GML88,GML89,';
     z := z + 'GMM80,GMM81,GMM82,GMM83,GMM84,GMM85,GMM86,GMM87,GMM88,GMM89,GMN80,GMN81,GMN82,GMN83,GMN84,';
     z := z + 'GMN85,GMN86,GMN87,GMN88,GMN89,GMO80,GMO81,GMO82,GMO83,GMO84,GMO85,GMO86,GMO87,GMO88,GMO89,';
     z := z + 'GMP80,GMP81,GMP82,GMP83,GMP84,GMP85,GMP86,GMP87,GMP88,GMP89,GMQ80,GMQ81,GMQ82,GMQ83,GMQ84,';
     z := z + 'GMQ85,GMQ86,GMQ87,GMQ88,GMQ89,GMR80,GMR81,GMR82,GMR83,GMR84,PTU   ,PTY   ,PTZ   ,PUA   ,PUA2  ,';
     z := z + 'GMA70,GMA71,GMA72,GMA73,GMA74,GMA75,GMA76,GMA77,GMA78,GMA79,GMB70,GMB71,GMB72,GMB73,GMB74,';
     z := z + 'GMB75,GMB76,GMB77,GMB78,GMB79,GMC70,GMC71,GMC72,GMC73,GMC74,GMC75,GMC76,GMC77,GMC78,GMC79,';
     z := z + 'GMD70,GMD71,GMD72,GMD73,GMD74,GMD75,GMD76,GMD77,GMD78,GMD79,GME70,GME71,GME72,GME73,GME74,';
     z := z + 'GME75,GME76,GME77,GME78,GME79,GMF70,GMF71,GMF72,GMF73,GMF74,GMF75,GMF76,GMF77,GMF78,GMF79,';
     z := z + 'GMG70,GMG71,GMG72,GMG73,GMG74,GMG75,GMG76,GMG77,GMG78,GMG79,GMH70,GMH71,GMH72,GMH73,GMH74,';
     z := z + 'GMH75,GMH76,GMH77,GMH78,GMH79,GMI70,GMI71,GMI72,GMI73,GMI74,GMI75,GMI76,GMI77,GMI78,GMI79,';
     z := z + 'GMJ70,GMJ71,GMJ72,GMJ73,GMJ74,GMJ75,GMJ76,GMJ77,GMJ78,GMJ79,GMK70,GMK71,GMK72,GMK73,GMK74,';
     z := z + 'GMK75,GMK76,GMK77,GMK78,GMK79,GML70,GML71,GML72,GML73,GML74,GML75,GML76,GML77,GML78,GML79,';
     z := z + 'GMM70,GMM71,GMM72,GMM73,GMM74,GMM75,GMM76,GMM77,GMM78,GMM79,GMN70,GMN71,GMN72,GMN73,GMN74,';
     z := z + 'GMN75,GMN76,GMN77,GMN78,GMN79,GMO70,GMO71,GMO72,GMO73,GMO74,GMO75,GMO76,GMO77,GMO78,GMO79,';
     z := z + 'GMP70,GMP71,GMP72,GMP73,GMP74,GMP75,GMP76,GMP77,GMP78,GMP79,GMQ70,GMQ71,GMQ72,GMQ73,GMQ74,';
     z := z + 'GMQ75,GMQ76,GMQ77,GMQ78,GMQ79,GMR70,GMR71,GMR72,GMR73,GMR74,PUA9  ,PUK   ,PUN   ,PUR   ,PV2   ,';
     z := z + 'GMA60,GMA61,GMA62,GMA63,GMA64,GMA65,GMA66,GMA67,GMA68,GMA69,GMB60,GMB61,GMB62,GMB63,GMB64,';
     z := z + 'GMB65,GMB66,GMB67,GMB68,GMB69,GMC60,GMC61,GMC62,GMC63,GMC64,GMC65,GMC66,GMC67,GMC68,GMC69,';
     z := z + 'GMD60,GMD61,GMD62,GMD63,GMD64,GMD65,GMD66,GMD67,GMD68,GMD69,GME60,GME61,GME62,GME63,GME64,';
     z := z + 'GME65,GME66,GME67,GME68,GME69,GMF60,GMF61,GMF62,GMF63,GMF64,GMF65,GMF66,GMF67,GMF68,GMF69,';
     z := z + 'GMG60,GMG61,GMG62,GMG63,GMG64,GMG65,GMG66,GMG67,GMG68,GMG69,GMH60,GMH61,GMH62,GMH63,GMH64,';
     z := z + 'GMH65,GMH66,GMH67,GMH68,GMH69,GMI60,GMI61,GMI62,GMI63,GMI64,GMI65,GMI66,GMI67,GMI68,GMI69,';
     z := z + 'GMJ60,GMJ61,GMJ62,GMJ63,GMJ64,GMJ65,GMJ66,GMJ67,GMJ68,GMJ69,GMK60,GMK61,GMK62,GMK63,GMK64,';
     z := z + 'GMK65,GMK66,GMK67,GMK68,GMK69,GML60,GML61,GML62,GML63,GML64,GML65,GML66,GML67,GML68,GML69,';
     z := z + 'GMM60,GMM61,GMM62,GMM63,GMM64,GMM65,GMM66,GMM67,GMM68,GMM69,GMN60,GMN61,GMN62,GMN63,GMN64,';
     z := z + 'GMN65,GMN66,GMN67,GMN68,GMN69,GMO60,GMO61,GMO62,GMO63,GMO64,GMO65,GMO66,GMO67,GMO68,GMO69,';
     z := z + 'GMP60,GMP61,GMP62,GMP63,GMP64,GMP65,GMP66,GMP67,GMP68,GMP69,GMQ60,GMQ61,GMQ62,GMQ63,GMQ64,';
     z := z + 'GMQ65,GMQ66,GMQ67,GMQ68,GMQ69,GMR60,GMR61,GMR62,GMR63,GMR64,PV3   ,PV4   ,PV5   ,PV6   ,PV7   ,';
     z := z + 'GMA50,GMA51,GMA52,GMA53,GMA54,GMA55,GMA56,GMA57,GMA58,GMA59,GMB50,GMB51,GMB52,GMB53,GMB54,';
     z := z + 'GMB55,GMB56,GMB57,GMB58,GMB59,GMC50,GMC51,GMC52,GMC53,GMC54,GMC55,GMC56,GMC57,GMC58,GMC59,';
     z := z + 'GMD50,GMD51,GMD52,GMD53,GMD54,GMD55,GMD56,GMD57,GMD58,GMD59,GME50,GME51,GME52,GME53,GME54,';
     z := z + 'GME55,GME56,GME57,GME58,GME59,GMF50,GMF51,GMF52,GMF53,GMF54,GMF55,GMF56,GMF57,GMF58,GMF59,';
     z := z + 'GMG50,GMG51,GMG52,GMG53,GMG54,GMG55,GMG56,GMG57,GMG58,GMG59,GMH50,GMH51,GMH52,GMH53,GMH54,';
     z := z + 'GMH55,GMH56,GMH57,GMH58,GMH59,GMI50,GMI51,GMI52,GMI53,GMI54,GMI55,GMI56,GMI57,GMI58,GMI59,';
     z := z + 'GMJ50,GMJ51,GMJ52,GMJ53,GMJ54,GMJ55,GMJ56,GMJ57,GMJ58,GMJ59,GMK50,GMK51,GMK52,GMK53,GMK54,';
     z := z + 'GMK55,GMK56,GMK57,GMK58,GMK59,GML50,GML51,GML52,GML53,GML54,GML55,GML56,GML57,GML58,GML59,';
     z := z + 'GMM50,GMM51,GMM52,GMM53,GMM54,GMM55,GMM56,GMM57,GMM58,GMM59,GMN50,GMN51,GMN52,GMN53,GMN54,';
     z := z + 'GMN55,GMN56,GMN57,GMN58,GMN59,GMO50,GMO51,GMO52,GMO53,GMO54,GMO55,GMO56,GMO57,GMO58,GMO59,';
     z := z + 'GMP50,GMP51,GMP52,GMP53,GMP54,GMP55,GMP56,GMP57,GMP58,GMP59,GMQ50,GMQ51,GMQ52,GMQ53,GMQ54,';
     z := z + 'GMQ55,GMQ56,GMQ57,GMQ58,GMQ59,GMR50,GMR51,GMR52,GMR53,GMR54,PV8   ,PVE   ,PVK   ,PVK0H ,PVK0M ,';
     z := z + 'GMA40,GMA41,GMA42,GMA43,GMA44,GMA45,GMA46,GMA47,GMA48,GMA49,GMB40,GMB41,GMB42,GMB43,GMB44,';
     z := z + 'GMB45,GMB46,GMB47,GMB48,GMB49,GMC40,GMC41,GMC42,GMC43,GMC44,GMC45,GMC46,GMC47,GMC48,GMC49,';
     z := z + 'GMD40,GMD41,GMD42,GMD43,GMD44,GMD45,GMD46,GMD47,GMD48,GMD49,GME40,GME41,GME42,GME43,GME44,';
     z := z + 'GME45,GME46,GME47,GME48,GME49,GMF40,GMF41,GMF42,GMF43,GMF44,GMF45,GMF46,GMF47,GMF48,GMF49,';
     z := z + 'GMG40,GMG41,GMG42,GMG43,GMG44,GMG45,GMG46,GMG47,GMG48,GMG49,GMH40,GMH41,GMH42,GMH43,GMH44,';
     z := z + 'GMH45,GMH46,GMH47,GMH48,GMH49,GMI40,GMI41,GMI42,GMI43,GMI44,GMI45,GMI46,GMI47,GMI48,GMI49,';
     z := z + 'GMJ40,GMJ41,GMJ42,GMJ43,GMJ44,GMJ45,GMJ46,GMJ47,GMJ48,GMJ49,GMK40,GMK41,GMK42,GMK43,GMK44,';
     z := z + 'GMK45,GMK46,GMK47,GMK48,GMK49,GML40,GML41,GML42,GML43,GML44,GML45,GML46,GML47,GML48,GML49,';
     z := z + 'GMM40,GMM41,GMM42,GMM43,GMM44,GMM45,GMM46,GMM47,GMM48,GMM49,GMN40,GMN41,GMN42,GMN43,GMN44,';
     z := z + 'GMN45,GMN46,GMN47,GMN48,GMN49,GMO40,GMO41,GMO42,GMO43,GMO44,GMO45,GMO46,GMO47,GMO48,GMO49,';
     z := z + 'GMP40,GMP41,GMP42,GMP43,GMP44,GMP45,GMP46,GMP47,GMP48,GMP49,GMQ40,GMQ41,GMQ42,GMQ43,GMQ44,';
     z := z + 'GMQ45,GMQ46,GMQ47,GMQ48,GMQ49,GMR40,GMR41,GMR42,GMR43,GMR44,PVK9C ,PVK9L ,PVK9M ,PVK9N ,PVK9W ,';
     z := z + 'GMA30,GMA31,GMA32,GMA33,GMA34,GMA35,GMA36,GMA37,GMA38,GMA39,GMB30,GMB31,GMB32,GMB33,GMB34,';
     z := z + 'GMB35,GMB36,GMB37,GMB38,GMB39,GMC30,GMC31,GMC32,GMC33,GMC34,GMC35,GMC36,GMC37,GMC38,GMC39,';
     z := z + 'GMD30,GMD31,GMD32,GMD33,GMD34,GMD35,GMD36,GMD37,GMD38,GMD39,GME30,GME31,GME32,GME33,GME34,';
     z := z + 'GME35,GME36,GME37,GME38,GME39,GMF30,GMF31,GMF32,GMF33,GMF34,GMF35,GMF36,GMF37,GMF38,GMF39,';
     z := z + 'GMG30,GMG31,GMG32,GMG33,GMG34,GMG35,GMG36,GMG37,GMG38,GMG39,GMH30,GMH31,GMH32,GMH33,GMH34,';
     z := z + 'GMH35,GMH36,GMH37,GMH38,GMH39,GMI30,GMI31,GMI32,GMI33,GMI34,GMI35,GMI36,GMI37,GMI38,GMI39,';
     z := z + 'GMJ30,GMJ31,GMJ32,GMJ33,GMJ34,GMJ35,GMJ36,GMJ37,GMJ38,GMJ39,GMK30,GMK31,GMK32,GMK33,GMK34,';
     z := z + 'GMK35,GMK36,GMK37,GMK38,GMK39,GML30,GML31,GML32,GML33,GML34,GML35,GML36,GML37,GML38,GML39,';
     z := z + 'GMM30,GMM31,GMM32,GMM33,GMM34,GMM35,GMM36,GMM37,GMM38,GMM39,GMN30,GMN31,GMN32,GMN33,GMN34,';
     z := z + 'GMN35,GMN36,GMN37,GMN38,GMN39,GMO30,GMO31,GMO32,GMO33,GMO34,GMO35,GMO36,GMO37,GMO38,GMO39,';
     z := z + 'GMP30,GMP31,GMP32,GMP33,GMP34,GMP35,GMP36,GMP37,GMP38,GMP39,GMQ30,GMQ31,GMQ32,GMQ33,GMQ34,';
     z := z + 'GMQ35,GMQ36,GMQ37,GMQ38,GMQ39,GMR30,GMR31,GMR32,GMR33,GMR34,PVK9X ,PVP2E ,PVP2M ,PVP2V ,PVP5  ,';
     z := z + 'GMA20,GMA21,GMA22,GMA23,GMA24,GMA25,GMA26,GMA27,GMA28,GMA29,GMB20,GMB21,GMB22,GMB23,GMB24,';
     z := z + 'GMB25,GMB26,GMB27,GMB28,GMB29,GMC20,GMC21,GMC22,GMC23,GMC24,GMC25,GMC26,GMC27,GMC28,GMC29,';
     z := z + 'GMD20,GMD21,GMD22,GMD23,GMD24,GMD25,GMD26,GMD27,GMD28,GMD29,GME20,GME21,GME22,GME23,GME24,';
     z := z + 'GME25,GME26,GME27,GME28,GME29,GMF20,GMF21,GMF22,GMF23,GMF24,GMF25,GMF26,GMF27,GMF28,GMF29,';
     z := z + 'GMG20,GMG21,GMG22,GMG23,GMG24,GMG25,GMG26,GMG27,GMG28,GMG29,GMH20,GMH21,GMH22,GMH23,GMH24,';
     z := z + 'GMH25,GMH26,GMH27,GMH28,GMH29,GMI20,GMI21,GMI22,GMI23,GMI24,GMI25,GMI26,GMI27,GMI28,GMI29,';
     z := z + 'GMJ20,GMJ21,GMJ22,GMJ23,GMJ24,GMJ25,GMJ26,GMJ27,GMJ28,GMJ29,GMK20,GMK21,GMK22,GMK23,GMK24,';
     z := z + 'GMK25,GMK26,GMK27,GMK28,GMK29,GML20,GML21,GML22,GML23,GML24,GML25,GML26,GML27,GML28,GML29,';
     z := z + 'GMM20,GMM21,GMM22,GMM23,GMM24,GMM25,GMM26,GMM27,GMM28,GMM29,GMN20,GMN21,GMN22,GMN23,GMN24,';
     z := z + 'GMN25,GMN26,GMN27,GMN28,GMN29,GMO20,GMO21,GMO22,GMO23,GMO24,GMO25,GMO26,GMO27,GMO28,GMO29,';
     z := z + 'GMP20,GMP21,GMP22,GMP23,GMP24,GMP25,GMP26,GMP27,GMP28,GMP29,GMQ20,GMQ21,GMQ22,GMQ23,GMQ24,';
     z := z + 'GMQ25,GMQ26,GMQ27,GMQ28,GMQ29,GMR20,GMR21,GMR22,GMR23,GMR24,PVP6  ,PVP6D ,PVP8  ,PVP8G ,PVP8H ,';
     z := z + 'GMA10,GMA11,GMA12,GMA13,GMA14,GMA15,GMA16,GMA17,GMA18,GMA19,GMB10,GMB11,GMB12,GMB13,GMB14,';
     z := z + 'GMB15,GMB16,GMB17,GMB18,GMB19,GMC10,GMC11,GMC12,GMC13,GMC14,GMC15,GMC16,GMC17,GMC18,GMC19,';
     z := z + 'GMD10,GMD11,GMD12,GMD13,GMD14,GMD15,GMD16,GMD17,GMD18,GMD19,GME10,GME11,GME12,GME13,GME14,';
     z := z + 'GME15,GME16,GME17,GME18,GME19,GMF10,GMF11,GMF12,GMF13,GMF14,GMF15,GMF16,GMF17,GMF18,GMF19,';
     z := z + 'GMG10,GMG11,GMG12,GMG13,GMG14,GMG15,GMG16,GMG17,GMG18,GMG19,GMH10,GMH11,GMH12,GMH13,GMH14,';
     z := z + 'GMH15,GMH16,GMH17,GMH18,GMH19,GMI10,GMI11,GMI12,GMI13,GMI14,GMI15,GMI16,GMI17,GMI18,GMI19,';
     z := z + 'GMJ10,GMJ11,GMJ12,GMJ13,GMJ14,GMJ15,GMJ16,GMJ17,GMJ18,GMJ19,GMK10,GMK11,GMK12,GMK13,GMK14,';
     z := z + 'GMK15,GMK16,GMK17,GMK18,GMK19,GML10,GML11,GML12,GML13,GML14,GML15,GML16,GML17,GML18,GML19,';
     z := z + 'GMM10,GMM11,GMM12,GMM13,GMM14,GMM15,GMM16,GMM17,GMM18,GMM19,GMN10,GMN11,GMN12,GMN13,GMN14,';
     z := z + 'GMN15,GMN16,GMN17,GMN18,GMN19,GMO10,GMO11,GMO12,GMO13,GMO14,GMO15,GMO16,GMO17,GMO18,GMO19,';
     z := z + 'GMP10,GMP11,GMP12,GMP13,GMP14,GMP15,GMP16,GMP17,GMP18,GMP19,GMQ10,GMQ11,GMQ12,GMQ13,GMQ14,';
     z := z + 'GMQ15,GMQ16,GMQ17,GMQ18,GMQ19,GMR10,GMR11,GMR12,GMR13,GMR14,PVP8O ,PVP8S ,PVP9  ,PVQ9  ,PVR   ,';
     z := z + 'GMA00,GMA01,GMA02,GMA03,GMA04,GMA05,GMA06,GMA07,GMA08,GMA09,GMB00,GMB01,GMB02,GMB03,GMB04,';
     z := z + 'GMB05,GMB06,GMB07,GMB08,GMB09,GMC00,GMC01,GMC02,GMC03,GMC04,GMC05,GMC06,GMC07,GMC08,GMC09,';
     z := z + 'GMD00,GMD01,GMD02,GMD03,GMD04,GMD05,GMD06,GMD07,GMD08,GMD09,GME00,GME01,GME02,GME03,GME04,';
     z := z + 'GME05,GME06,GME07,GME08,GME09,GMF00,GMF01,GMF02,GMF03,GMF04,GMF05,GMF06,GMF07,GMF08,GMF09,';
     z := z + 'GMG00,GMG01,GMG02,GMG03,GMG04,GMG05,GMG06,GMG07,GMG08,GMG09,GMH00,GMH01,GMH02,GMH03,GMH04,';
     z := z + 'GMH05,GMH06,GMH07,GMH08,GMH09,GMI00,GMI01,GMI02,GMI03,GMI04,GMI05,GMI06,GMI07,GMI08,GMI09,';
     z := z + 'GMJ00,GMJ01,GMJ02,GMJ03,GMJ04,GMJ05,GMJ06,GMJ07,GMJ08,GMJ09,GMK00,GMK01,GMK02,GMK03,GMK04,';
     z := z + 'GMK05,GMK06,GMK07,GMK08,GMK09,GML00,GML01,GML02,GML03,GML04,GML05,GML06,GML07,GML08,GML09,';
     z := z + 'GMM00,GMM01,GMM02,GMM03,GMM04,GMM05,GMM06,GMM07,GMM08,GMM09,GMN00,GMN01,GMN02,GMN03,GMN04,';
     z := z + 'GMN05,GMN06,GMN07,GMN08,GMN09,GMO00,GMO01,GMO02,GMO03,GMO04,GMO05,GMO06,GMO07,GMO08,GMO09,';
     z := z + 'GMP00,GMP01,GMP02,GMP03,GMP04,GMP05,GMP06,GMP07,GMP08,GMP09,GMQ00,GMQ01,GMQ02,GMQ03,GMQ04,';
     z := z + 'GMQ05,GMQ06,GMQ07,GMQ08,GMQ09,GMR00,GMR01,GMR02,GMR03,GMR04,PVU   ,PVU4  ,PVU7  ,PXE   ,PXF4  ,';
     z := z + 'GLA90,GLA91,GLA92,GLA93,GLA94,GLA95,GLA96,GLA97,GLA98,GLA99,GLB90,GLB91,GLB92,GLB93,GLB94,';
     z := z + 'GLB95,GLB96,GLB97,GLB98,GLB99,GLC90,GLC91,GLC92,GLC93,GLC94,GLC95,GLC96,GLC97,GLC98,GLC99,';
     z := z + 'GLD90,GLD91,GLD92,GLD93,GLD94,GLD95,GLD96,GLD97,GLD98,GLD99,GLE90,GLE91,GLE92,GLE93,GLE94,';
     z := z + 'GLE95,GLE96,GLE97,GLE98,GLE99,GLF90,GLF91,GLF92,GLF93,GLF94,GLF95,GLF96,GLF97,GLF98,GLF99,';
     z := z + 'GLG90,GLG91,GLG92,GLG93,GLG94,GLG95,GLG96,GLG97,GLG98,GLG99,GLH90,GLH91,GLH92,GLH93,GLH94,';
     z := z + 'GLH95,GLH96,GLH97,GLH98,GLH99,GLI90,GLI91,GLI92,GLI93,GLI94,GLI95,GLI96,GLI97,GLI98,GLI99,';
     z := z + 'GLJ90,GLJ91,GLJ92,GLJ93,GLJ94,GLJ95,GLJ96,GLJ97,GLJ98,GLJ99,GLK90,GLK91,GLK92,GLK93,GLK94,';
     z := z + 'GLK95,GLK96,GLK97,GLK98,GLK99,GLL90,GLL91,GLL92,GLL93,GLL94,GLL95,GLL96,GLL97,GLL98,GLL99,';
     z := z + 'GLM90,GLM91,GLM92,GLM93,GLM94,GLM95,GLM96,GLM97,GLM98,GLM99,GLN90,GLN91,GLN92,GLN93,GLN94,';
     z := z + 'GLN95,GLN96,GLN97,GLN98,GLN99,GLO90,GLO91,GLO92,GLO93,GLO94,GLO95,GLO96,GLO97,GLO98,GLO99,';
     z := z + 'GLP90,GLP91,GLP92,GLP93,GLP94,GLP95,GLP96,GLP97,GLP98,GLP99,GLQ90,GLQ91,GLQ92,GLQ93,GLQ94,';
     z := z + 'GLQ95,GLQ96,GLQ97,GLQ98,GLQ99,GLR90,GLR91,GLR92,GLR93,GLR94,PXT   ,PXU   ,PXW   ,PXX9  ,PXZ   ,';
     z := z + 'GLA80,GLA81,GLA82,GLA83,GLA84,GLA85,GLA86,GLA87,GLA88,GLA89,GLB80,GLB81,GLB82,GLB83,GLB84,';
     z := z + 'GLB85,GLB86,GLB87,GLB88,GLB89,GLC80,GLC81,GLC82,GLC83,GLC84,GLC85,GLC86,GLC87,GLC88,GLC89,';
     z := z + 'GLD80,GLD81,GLD82,GLD83,GLD84,GLD85,GLD86,GLD87,GLD88,GLD89,GLE80,GLE81,GLE82,GLE83,GLE84,';
     z := z + 'GLE85,GLE86,GLE87,GLE88,GLE89,GLF80,GLF81,GLF82,GLF83,GLF84,GLF85,GLF86,GLF87,GLF88,GLF89,';
     z := z + 'GLG80,GLG81,GLG82,GLG83,GLG84,GLG85,GLG86,GLG87,GLG88,GLG89,GLH80,GLH81,GLH82,GLH83,GLH84,';
     z := z + 'GLH85,GLH86,GLH87,GLH88,GLH89,GLI80,GLI81,GLI82,GLI83,GLI84,GLI85,GLI86,GLI87,GLI88,GLI89,';
     z := z + 'GLJ80,GLJ81,GLJ82,GLJ83,GLJ84,GLJ85,GLJ86,GLJ87,GLJ88,GLJ89,GLK80,GLK81,GLK82,GLK83,GLK84,';
     z := z + 'GLK85,GLK86,GLK87,GLK88,GLK89,GLL80,GLL81,GLL82,GLL83,GLL84,GLL85,GLL86,GLL87,GLL88,GLL89,';
     z := z + 'GLM80,GLM81,GLM82,GLM83,GLM84,GLM85,GLM86,GLM87,GLM88,GLM89,GLN80,GLN81,GLN82,GLN83,GLN84,';
     z := z + 'GLN85,GLN86,GLN87,GLN88,GLN89,GLO80,GLO81,GLO82,GLO83,GLO84,GLO85,GLO86,GLO87,GLO88,GLO89,';
     z := z + 'GLP80,GLP81,GLP82,GLP83,GLP84,GLP85,GLP86,GLP87,GLP88,GLP89,GLQ80,GLQ81,GLQ82,GLQ83,GLQ84,';
     z := z + 'GLQ85,GLQ86,GLQ87,GLQ88,GLQ89,GLR80,GLR81,GLR82,GLR83,GLR84,PYA   ,PYB   ,PYI   ,PYJ   ,PYK   ,';
     z := z + 'GLA70,GLA71,GLA72,GLA73,GLA74,GLA75,GLA76,GLA77,GLA78,GLA79,GLB70,GLB71,GLB72,GLB73,GLB74,';
     z := z + 'GLB75,GLB76,GLB77,GLB78,GLB79,GLC70,GLC71,GLC72,GLC73,GLC74,GLC75,GLC76,GLC77,GLC78,GLC79,';
     z := z + 'GLD70,GLD71,GLD72,GLD73,GLD74,GLD75,GLD76,GLD77,GLD78,GLD79,GLE70,GLE71,GLE72,GLE73,GLE74,';
     z := z + 'GLE75,GLE76,GLE77,GLE78,GLE79,GLF70,GLF71,GLF72,GLF73,GLF74,GLF75,GLF76,GLF77,GLF78,GLF79,';
     z := z + 'GLG70,GLG71,GLG72,GLG73,GLG74,GLG75,GLG76,GLG77,GLG78,GLG79,GLH70,GLH71,GLH72,GLH73,GLH74,';
     z := z + 'GLH75,GLH76,GLH77,GLH78,GLH79,GLI70,GLI71,GLI72,GLI73,GLI74,GLI75,GLI76,GLI77,GLI78,GLI79,';
     z := z + 'GLJ70,GLJ71,GLJ72,GLJ73,GLJ74,GLJ75,GLJ76,GLJ77,GLJ78,GLJ79,GLK70,GLK71,GLK72,GLK73,GLK74,';
     z := z + 'GLK75,GLK76,GLK77,GLK78,GLK79,GLL70,GLL71,GLL72,GLL73,GLL74,GLL75,GLL76,GLL77,GLL78,GLL79,';
     z := z + 'GLM70,GLM71,GLM72,GLM73,GLM74,GLM75,GLM76,GLM77,GLM78,GLM79,GLN70,GLN71,GLN72,GLN73,GLN74,';
     z := z + 'GLN75,GLN76,GLN77,GLN78,GLN79,GLO70,GLO71,GLO72,GLO73,GLO74,GLO75,GLO76,GLO77,GLO78,GLO79,';
     z := z + 'GLP70,GLP71,GLP72,GLP73,GLP74,GLP75,GLP76,GLP77,GLP78,GLP79,GLQ70,GLQ71,GLQ72,GLQ73,GLQ74,';
     z := z + 'GLQ75,GLQ76,GLQ77,GLQ78,GLQ79,GLR70,GLR71,GLR72,GLR73,GLR74,PYL   ,PYN   ,PYO   ,PYS   ,PYU   ,';
     z := z + 'GLA60,GLA61,GLA62,GLA63,GLA64,GLA65,GLA66,GLA67,GLA68,GLA69,GLB60,GLB61,GLB62,GLB63,GLB64,';
     z := z + 'GLB65,GLB66,GLB67,GLB68,GLB69,GLC60,GLC61,GLC62,GLC63,GLC64,GLC65,GLC66,GLC67,GLC68,GLC69,';
     z := z + 'GLD60,GLD61,GLD62,GLD63,GLD64,GLD65,GLD66,GLD67,GLD68,GLD69,GLE60,GLE61,GLE62,GLE63,GLE64,';
     z := z + 'GLE65,GLE66,GLE67,GLE68,GLE69,GLF60,GLF61,GLF62,GLF63,GLF64,GLF65,GLF66,GLF67,GLF68,GLF69,';
     z := z + 'GLG60,GLG61,GLG62,GLG63,GLG64,GLG65,GLG66,GLG67,GLG68,GLG69,GLH60,GLH61,GLH62,GLH63,GLH64,';
     z := z + 'GLH65,GLH66,GLH67,GLH68,GLH69,GLI60,GLI61,GLI62,GLI63,GLI64,GLI65,GLI66,GLI67,GLI68,GLI69,';
     z := z + 'GLJ60,GLJ61,GLJ62,GLJ63,GLJ64,GLJ65,GLJ66,GLJ67,GLJ68,GLJ69,GLK60,GLK61,GLK62,GLK63,GLK64,';
     z := z + 'GLK65,GLK66,GLK67,GLK68,GLK69,GLL60,GLL61,GLL62,GLL63,GLL64,GLL65,GLL66,GLL67,GLL68,GLL69,';
     z := z + 'GLM60,GLM61,GLM62,GLM63,GLM64,GLM65,GLM66,GLM67,GLM68,GLM69,GLN60,GLN61,GLN62,GLN63,GLN64,';
     z := z + 'GLN65,GLN66,GLN67,GLN68,GLN69,GLO60,GLO61,GLO62,GLO63,GLO64,GLO65,GLO66,GLO67,GLO68,GLO69,';
     z := z + 'GLP60,GLP61,GLP62,GLP63,GLP64,GLP65,GLP66,GLP67,GLP68,GLP69,GLQ60,GLQ61,GLQ62,GLQ63,GLQ64,';
     z := z + 'GLQ65,GLQ66,GLQ67,GLQ68,GLQ69,GLR60,GLR61,GLR62,GLR63,GLR64,PYV   ,PYV0  ,PZ2   ,PZ3   ,PZA   ,';
     z := z + 'GLA50,GLA51,GLA52,GLA53,GLA54,GLA55,GLA56,GLA57,GLA58,GLA59,GLB50,GLB51,GLB52,GLB53,GLB54,';
     z := z + 'GLB55,GLB56,GLB57,GLB58,GLB59,GLC50,GLC51,GLC52,GLC53,GLC54,GLC55,GLC56,GLC57,GLC58,GLC59,';
     z := z + 'GLD50,GLD51,GLD52,GLD53,GLD54,GLD55,GLD56,GLD57,GLD58,GLD59,GLE50,GLE51,GLE52,GLE53,GLE54,';
     z := z + 'GLE55,GLE56,GLE57,GLE58,GLE59,GLF50,GLF51,GLF52,GLF53,GLF54,GLF55,GLF56,GLF57,GLF58,GLF59,';
     z := z + 'GLG50,GLG51,GLG52,GLG53,GLG54,GLG55,GLG56,GLG57,GLG58,GLG59,GLH50,GLH51,GLH52,GLH53,GLH54,';
     z := z + 'GLH55,GLH56,GLH57,GLH58,GLH59,GLI50,GLI51,GLI52,GLI53,GLI54,GLI55,GLI56,GLI57,GLI58,GLI59,';
     z := z + 'GLJ50,GLJ51,GLJ52,GLJ53,GLJ54,GLJ55,GLJ56,GLJ57,GLJ58,GLJ59,GLK50,GLK51,GLK52,GLK53,GLK54,';
     z := z + 'GLK55,GLK56,GLK57,GLK58,GLK59,GLL50,GLL51,GLL52,GLL53,GLL54,GLL55,GLL56,GLL57,GLL58,GLL59,';
     z := z + 'GLM50,GLM51,GLM52,GLM53,GLM54,GLM55,GLM56,GLM57,GLM58,GLM59,GLN50,GLN51,GLN52,GLN53,GLN54,';
     z := z + 'GLN55,GLN56,GLN57,GLN58,GLN59,GLO50,GLO51,GLO52,GLO53,GLO54,GLO55,GLO56,GLO57,GLO58,GLO59,';
     z := z + 'GLP50,GLP51,GLP52,GLP53,GLP54,GLP55,GLP56,GLP57,GLP58,GLP59,GLQ50,GLQ51,GLQ52,GLQ53,GLQ54,';
     z := z + 'GLQ55,GLQ56,GLQ57,GLQ58,GLQ59,GLR50,GLR51,GLR52,GLR53,GLR54,PZB   ,PZC4  ,PZD7  ,PZD8  ,PZD9  ,';
     z := z + 'GLA40,GLA41,GLA42,GLA43,GLA44,GLA45,GLA46,GLA47,GLA48,GLA49,GLB40,GLB41,GLB42,GLB43,GLB44,';
     z := z + 'GLB45,GLB46,GLB47,GLB48,GLB49,GLC40,GLC41,GLC42,GLC43,GLC44,GLC45,GLC46,GLC47,GLC48,GLC49,';
     z := z + 'GLD40,GLD41,GLD42,GLD43,GLD44,GLD45,GLD46,GLD47,GLD48,GLD49,GLE40,GLE41,GLE42,GLE43,GLE44,';
     z := z + 'GLE45,GLE46,GLE47,GLE48,GLE49,GLF40,GLF41,GLF42,GLF43,GLF44,GLF45,GLF46,GLF47,GLF48,GLF49,';
     z := z + 'GLG40,GLG41,GLG42,GLG43,GLG44,GLG45,GLG46,GLG47,GLG48,GLG49,GLH40,GLH41,GLH42,GLH43,GLH44,';
     z := z + 'GLH45,GLH46,GLH47,GLH48,GLH49,GLI40,GLI41,GLI42,GLI43,GLI44,GLI45,GLI46,GLI47,GLI48,GLI49,';
     z := z + 'GLJ40,GLJ41,GLJ42,GLJ43,GLJ44,GLJ45,GLJ46,GLJ47,GLJ48,GLJ49,GLK40,GLK41,GLK42,GLK43,GLK44,';
     z := z + 'GLK45,GLK46,GLK47,GLK48,GLK49,GLL40,GLL41,GLL42,GLL43,GLL44,GLL45,GLL46,GLL47,GLL48,GLL49,';
     z := z + 'GLM40,GLM41,GLM42,GLM43,GLM44,GLM45,GLM46,GLM47,GLM48,GLM49,GLN40,GLN41,GLN42,GLN43,GLN44,';
     z := z + 'GLN45,GLN46,GLN47,GLN48,GLN49,GLO40,GLO41,GLO42,GLO43,GLO44,GLO45,GLO46,GLO47,GLO48,GLO49,';
     z := z + 'GLP40,GLP41,GLP42,GLP43,GLP44,GLP45,GLP46,GLP47,GLP48,GLP49,GLQ40,GLQ41,GLQ42,GLQ43,GLQ44,';
     z := z + 'GLQ45,GLQ46,GLQ47,GLQ48,GLQ49,GLR40,GLR41,GLR42,GLR43,GLR44,PZF   ,PZK1N ,PZK1S ,PZK2  ,PZK3  ,';
     z := z + 'GLA30,GLA31,GLA32,GLA33,GLA34,GLA35,GLA36,GLA37,GLA38,GLA39,GLB30,GLB31,GLB32,GLB33,GLB34,';
     z := z + 'GLB35,GLB36,GLB37,GLB38,GLB39,GLC30,GLC31,GLC32,GLC33,GLC34,GLC35,GLC36,GLC37,GLC38,GLC39,';
     z := z + 'GLD30,GLD31,GLD32,GLD33,GLD34,GLD35,GLD36,GLD37,GLD38,GLD39,GLE30,GLE31,GLE32,GLE33,GLE34,';
     z := z + 'GLE35,GLE36,GLE37,GLE38,GLE39,GLF30,GLF31,GLF32,GLF33,GLF34,GLF35,GLF36,GLF37,GLF38,GLF39,';
     z := z + 'GLG30,GLG31,GLG32,GLG33,GLG34,GLG35,GLG36,GLG37,GLG38,GLG39,GLH30,GLH31,GLH32,GLH33,GLH34,';
     z := z + 'GLH35,GLH36,GLH37,GLH38,GLH39,GLI30,GLI31,GLI32,GLI33,GLI34,GLI35,GLI36,GLI37,GLI38,GLI39,';
     z := z + 'GLJ30,GLJ31,GLJ32,GLJ33,GLJ34,GLJ35,GLJ36,GLJ37,GLJ38,GLJ39,GLK30,GLK31,GLK32,GLK33,GLK34,';
     z := z + 'GLK35,GLK36,GLK37,GLK38,GLK39,GLL30,GLL31,GLL32,GLL33,GLL34,GLL35,GLL36,GLL37,GLL38,GLL39,';
     z := z + 'GLM30,GLM31,GLM32,GLM33,GLM34,GLM35,GLM36,GLM37,GLM38,GLM39,GLN30,GLN31,GLN32,GLN33,GLN34,';
     z := z + 'GLN35,GLN36,GLN37,GLN38,GLN39,GLO30,GLO31,GLO32,GLO33,GLO34,GLO35,GLO36,GLO37,GLO38,GLO39,';
     z := z + 'GLP30,GLP31,GLP32,GLP33,GLP34,GLP35,GLP36,GLP37,GLP38,GLP39,GLQ30,GLQ31,GLQ32,GLQ33,GLQ34,';
     z := z + 'GLQ35,GLQ36,GLQ37,GLQ38,GLQ39,GLR30,GLR31,GLR32,GLR33,GLR34,PZL   ,PZL7  ,PZL8  ,PZL9  ,PZP   ,';
     z := z + 'GLA20,GLA21,GLA22,GLA23,GLA24,GLA25,GLA26,GLA27,GLA28,GLA29,GLB20,GLB21,GLB22,GLB23,GLB24,';
     z := z + 'GLB25,GLB26,GLB27,GLB28,GLB29,GLC20,GLC21,GLC22,GLC23,GLC24,GLC25,GLC26,GLC27,GLC28,GLC29,';
     z := z + 'GLD20,GLD21,GLD22,GLD23,GLD24,GLD25,GLD26,GLD27,GLD28,GLD29,GLE20,GLE21,GLE22,GLE23,GLE24,';
     z := z + 'GLE25,GLE26,GLE27,GLE28,GLE29,GLF20,GLF21,GLF22,GLF23,GLF24,GLF25,GLF26,GLF27,GLF28,GLF29,';
     z := z + 'GLG20,GLG21,GLG22,GLG23,GLG24,GLG25,GLG26,GLG27,GLG28,GLG29,GLH20,GLH21,GLH22,GLH23,GLH24,';
     z := z + 'GLH25,GLH26,GLH27,GLH28,GLH29,GLI20,GLI21,GLI22,GLI23,GLI24,GLI25,GLI26,GLI27,GLI28,GLI29,';
     z := z + 'GLJ20,GLJ21,GLJ22,GLJ23,GLJ24,GLJ25,GLJ26,GLJ27,GLJ28,GLJ29,GLK20,GLK21,GLK22,GLK23,GLK24,';
     z := z + 'GLK25,GLK26,GLK27,GLK28,GLK29,GLL20,GLL21,GLL22,GLL23,GLL24,GLL25,GLL26,GLL27,GLL28,GLL29,';
     z := z + 'GLM20,GLM21,GLM22,GLM23,GLM24,GLM25,GLM26,GLM27,GLM28,GLM29,GLN20,GLN21,GLN22,GLN23,GLN24,';
     z := z + 'GLN25,GLN26,GLN27,GLN28,GLN29,GLO20,GLO21,GLO22,GLO23,GLO24,GLO25,GLO26,GLO27,GLO28,GLO29,';
     z := z + 'GLP20,GLP21,GLP22,GLP23,GLP24,GLP25,GLP26,GLP27,GLP28,GLP29,GLQ20,GLQ21,GLQ22,GLQ23,GLQ24,';
     z := z + 'GLQ25,GLQ26,GLQ27,GLQ28,GLQ29,GLR20,GLR21,GLR22,GLR23,GLR24,PZS   ,PZS8  ,PKC4  ,PE5   ,P     ,';
     z := z + 'GLA10,GLA11,GLA12,GLA13,GLA14,GLA15,GLA16,GLA17,GLA18,GLA19,GLB10,GLB11,GLB12,GLB13,GLB14,';
     z := z + 'GLB15,GLB16,GLB17,GLB18,GLB19,GLC10,GLC11,GLC12,GLC13,GLC14,GLC15,GLC16,GLC17,GLC18,GLC19,';
     z := z + 'GLD10,GLD11,GLD12,GLD13,GLD14,GLD15,GLD16,GLD17,GLD18,GLD19,GLE10,GLE11,GLE12,GLE13,GLE14,';
     z := z + 'GLE15,GLE16,GLE17,GLE18,GLE19,GLF10,GLF11,GLF12,GLF13,GLF14,GLF15,GLF16,GLF17,GLF18,GLF19,';
     z := z + 'GLG10,GLG11,GLG12,GLG13,GLG14,GLG15,GLG16,GLG17,GLG18,GLG19,GLH10,GLH11,GLH12,GLH13,GLH14,';
     z := z + 'GLH15,GLH16,GLH17,GLH18,GLH19,GLI10,GLI11,GLI12,GLI13,GLI14,GLI15,GLI16,GLI17,GLI18,GLI19,';
     z := z + 'GLJ10,GLJ11,GLJ12,GLJ13,GLJ14,GLJ15,GLJ16,GLJ17,GLJ18,GLJ19,GLK10,GLK11,GLK12,GLK13,GLK14,';
     z := z + 'GLK15,GLK16,GLK17,GLK18,GLK19,GLL10,GLL11,GLL12,GLL13,GLL14,GLL15,GLL16,GLL17,GLL18,GLL19,';
     z := z + 'GLM10,GLM11,GLM12,GLM13,GLM14,GLM15,GLM16,GLM17,GLM18,GLM19,GLN10,GLN11,GLN12,GLN13,GLN14,';
     z := z + 'GLN15,GLN16,GLN17,GLN18,GLN19,GLO10,GLO11,GLO12,GLO13,GLO14,GLO15,GLO16,GLO17,GLO18,GLO19,';
     z := z + 'GLP10,GLP11,GLP12,GLP13,GLP14,GLP15,GLP16,GLP17,GLP18,GLP19,GLQ10,GLQ11,GLQ12,GLQ13,GLQ14,';
     z := z + 'GLQ15,GLQ16,GLQ17,GLQ18,GLQ19,GLR10,GLR11,GLR12,GLR13,GLR14,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GLA00,GLA01,GLA02,GLA03,GLA04,GLA05,GLA06,GLA07,GLA08,GLA09,GLB00,GLB01,GLB02,GLB03,GLB04,';
     z := z + 'GLB05,GLB06,GLB07,GLB08,GLB09,GLC00,GLC01,GLC02,GLC03,GLC04,GLC05,GLC06,GLC07,GLC08,GLC09,';
     z := z + 'GLD00,GLD01,GLD02,GLD03,GLD04,GLD05,GLD06,GLD07,GLD08,GLD09,GLE00,GLE01,GLE02,GLE03,GLE04,';
     z := z + 'GLE05,GLE06,GLE07,GLE08,GLE09,GLF00,GLF01,GLF02,GLF03,GLF04,GLF05,GLF06,GLF07,GLF08,GLF09,';
     z := z + 'GLG00,GLG01,GLG02,GLG03,GLG04,GLG05,GLG06,GLG07,GLG08,GLG09,GLH00,GLH01,GLH02,GLH03,GLH04,';
     z := z + 'GLH05,GLH06,GLH07,GLH08,GLH09,GLI00,GLI01,GLI02,GLI03,GLI04,GLI05,GLI06,GLI07,GLI08,GLI09,';
     z := z + 'GLJ00,GLJ01,GLJ02,GLJ03,GLJ04,GLJ05,GLJ06,GLJ07,GLJ08,GLJ09,GLK00,GLK01,GLK02,GLK03,GLK04,';
     z := z + 'GLK05,GLK06,GLK07,GLK08,GLK09,GLL00,GLL01,GLL02,GLL03,GLL04,GLL05,GLL06,GLL07,GLL08,GLL09,';
     z := z + 'GLM00,GLM01,GLM02,GLM03,GLM04,GLM05,GLM06,GLM07,GLM08,GLM09,GLN00,GLN01,GLN02,GLN03,GLN04,';
     z := z + 'GLN05,GLN06,GLN07,GLN08,GLN09,GLO00,GLO01,GLO02,GLO03,GLO04,GLO05,GLO06,GLO07,GLO08,GLO09,';
     z := z + 'GLP00,GLP01,GLP02,GLP03,GLP04,GLP05,GLP06,GLP07,GLP08,GLP09,GLQ00,GLQ01,GLQ02,GLQ03,GLQ04,';
     z := z + 'GLQ05,GLQ06,GLQ07,GLQ08,GLQ09,GLR00,GLR01,GLR02,GLR03,GLR04,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GKA90,GKA91,GKA92,GKA93,GKA94,GKA95,GKA96,GKA97,GKA98,GKA99,GKB90,GKB91,GKB92,GKB93,GKB94,';
     z := z + 'GKB95,GKB96,GKB97,GKB98,GKB99,GKC90,GKC91,GKC92,GKC93,GKC94,GKC95,GKC96,GKC97,GKC98,GKC99,';
     z := z + 'GKD90,GKD91,GKD92,GKD93,GKD94,GKD95,GKD96,GKD97,GKD98,GKD99,GKE90,GKE91,GKE92,GKE93,GKE94,';
     z := z + 'GKE95,GKE96,GKE97,GKE98,GKE99,GKF90,GKF91,GKF92,GKF93,GKF94,GKF95,GKF96,GKF97,GKF98,GKF99,';
     z := z + 'GKG90,GKG91,GKG92,GKG93,GKG94,GKG95,GKG96,GKG97,GKG98,GKG99,GKH90,GKH91,GKH92,GKH93,GKH94,';
     z := z + 'GKH95,GKH96,GKH97,GKH98,GKH99,GKI90,GKI91,GKI92,GKI93,GKI94,GKI95,GKI96,GKI97,GKI98,GKI99,';
     z := z + 'GKJ90,GKJ91,GKJ92,GKJ93,GKJ94,GKJ95,GKJ96,GKJ97,GKJ98,GKJ99,GKK90,GKK91,GKK92,GKK93,GKK94,';
     z := z + 'GKK95,GKK96,GKK97,GKK98,GKK99,GKL90,GKL91,GKL92,GKL93,GKL94,GKL95,GKL96,GKL97,GKL98,GKL99,';
     z := z + 'GKM90,GKM91,GKM92,GKM93,GKM94,GKM95,GKM96,GKM97,GKM98,GKM99,GKN90,GKN91,GKN92,GKN93,GKN94,';
     z := z + 'GKN95,GKN96,GKN97,GKN98,GKN99,GKO90,GKO91,GKO92,GKO93,GKO94,GKO95,GKO96,GKO97,GKO98,GKO99,';
     z := z + 'GKP90,GKP91,GKP92,GKP93,GKP94,GKP95,GKP96,GKP97,GKP98,GKP99,GKQ90,GKQ91,GKQ92,GKQ93,GKQ94,';
     z := z + 'GKQ95,GKQ96,GKQ97,GKQ98,GKQ99,GKR90,GKR91,GKR92,GKR93,GKR94,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GKA80,GKA81,GKA82,GKA83,GKA84,GKA85,GKA86,GKA87,GKA88,GKA89,GKB80,GKB81,GKB82,GKB83,GKB84,';
     z := z + 'GKB85,GKB86,GKB87,GKB88,GKB89,GKC80,GKC81,GKC82,GKC83,GKC84,GKC85,GKC86,GKC87,GKC88,GKC89,';
     z := z + 'GKD80,GKD81,GKD82,GKD83,GKD84,GKD85,GKD86,GKD87,GKD88,GKD89,GKE80,GKE81,GKE82,GKE83,GKE84,';
     z := z + 'GKE85,GKE86,GKE87,GKE88,GKE89,GKF80,GKF81,GKF82,GKF83,GKF84,GKF85,GKF86,GKF87,GKF88,GKF89,';
     z := z + 'GKG80,GKG81,GKG82,GKG83,GKG84,GKG85,GKG86,GKG87,GKG88,GKG89,GKH80,GKH81,GKH82,GKH83,GKH84,';
     z := z + 'GKH85,GKH86,GKH87,GKH88,GKH89,GKI80,GKI81,GKI82,GKI83,GKI84,GKI85,GKI86,GKI87,GKI88,GKI89,';
     z := z + 'GKJ80,GKJ81,GKJ82,GKJ83,GKJ84,GKJ85,GKJ86,GKJ87,GKJ88,GKJ89,GKK80,GKK81,GKK82,GKK83,GKK84,';
     z := z + 'GKK85,GKK86,GKK87,GKK88,GKK89,GKL80,GKL81,GKL82,GKL83,GKL84,GKL85,GKL86,GKL87,GKL88,GKL89,';
     z := z + 'GKM80,GKM81,GKM82,GKM83,GKM84,GKM85,GKM86,GKM87,GKM88,GKM89,GKN80,GKN81,GKN82,GKN83,GKN84,';
     z := z + 'GKN85,GKN86,GKN87,GKN88,GKN89,GKO80,GKO81,GKO82,GKO83,GKO84,GKO85,GKO86,GKO87,GKO88,GKO89,';
     z := z + 'GKP80,GKP81,GKP82,GKP83,GKP84,GKP85,GKP86,GKP87,GKP88,GKP89,GKQ80,GKQ81,GKQ82,GKQ83,GKQ84,';
     z := z + 'GKQ85,GKQ86,GKQ87,GKQ88,GKQ89,GKR80,GKR81,GKR82,GKR83,GKR84,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GKA70,GKA71,GKA72,GKA73,GKA74,GKA75,GKA76,GKA77,GKA78,GKA79,GKB70,GKB71,GKB72,GKB73,GKB74,';
     z := z + 'GKB75,GKB76,GKB77,GKB78,GKB79,GKC70,GKC71,GKC72,GKC73,GKC74,GKC75,GKC76,GKC77,GKC78,GKC79,';
     z := z + 'GKD70,GKD71,GKD72,GKD73,GKD74,GKD75,GKD76,GKD77,GKD78,GKD79,GKE70,GKE71,GKE72,GKE73,GKE74,';
     z := z + 'GKE75,GKE76,GKE77,GKE78,GKE79,GKF70,GKF71,GKF72,GKF73,GKF74,GKF75,GKF76,GKF77,GKF78,GKF79,';
     z := z + 'GKG70,GKG71,GKG72,GKG73,GKG74,GKG75,GKG76,GKG77,GKG78,GKG79,GKH70,GKH71,GKH72,GKH73,GKH74,';
     z := z + 'GKH75,GKH76,GKH77,GKH78,GKH79,GKI70,GKI71,GKI72,GKI73,GKI74,GKI75,GKI76,GKI77,GKI78,GKI79,';
     z := z + 'GKJ70,GKJ71,GKJ72,GKJ73,GKJ74,GKJ75,GKJ76,GKJ77,GKJ78,GKJ79,GKK70,GKK71,GKK72,GKK73,GKK74,';
     z := z + 'GKK75,GKK76,GKK77,GKK78,GKK79,GKL70,GKL71,GKL72,GKL73,GKL74,GKL75,GKL76,GKL77,GKL78,GKL79,';
     z := z + 'GKM70,GKM71,GKM72,GKM73,GKM74,GKM75,GKM76,GKM77,GKM78,GKM79,GKN70,GKN71,GKN72,GKN73,GKN74,';
     z := z + 'GKN75,GKN76,GKN77,GKN78,GKN79,GKO70,GKO71,GKO72,GKO73,GKO74,GKO75,GKO76,GKO77,GKO78,GKO79,';
     z := z + 'GKP70,GKP71,GKP72,GKP73,GKP74,GKP75,GKP76,GKP77,GKP78,GKP79,GKQ70,GKQ71,GKQ72,GKQ73,GKQ74,';
     z := z + 'GKQ75,GKQ76,GKQ77,GKQ78,GKQ79,GKR70,GKR71,GKR72,GKR73,GKR74,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GKA60,GKA61,GKA62,GKA63,GKA64,GKA65,GKA66,GKA67,GKA68,GKA69,GKB60,GKB61,GKB62,GKB63,GKB64,';
     z := z + 'GKB65,GKB66,GKB67,GKB68,GKB69,GKC60,GKC61,GKC62,GKC63,GKC64,GKC65,GKC66,GKC67,GKC68,GKC69,';
     z := z + 'GKD60,GKD61,GKD62,GKD63,GKD64,GKD65,GKD66,GKD67,GKD68,GKD69,GKE60,GKE61,GKE62,GKE63,GKE64,';
     z := z + 'GKE65,GKE66,GKE67,GKE68,GKE69,GKF60,GKF61,GKF62,GKF63,GKF64,GKF65,GKF66,GKF67,GKF68,GKF69,';
     z := z + 'GKG60,GKG61,GKG62,GKG63,GKG64,GKG65,GKG66,GKG67,GKG68,GKG69,GKH60,GKH61,GKH62,GKH63,GKH64,';
     z := z + 'GKH65,GKH66,GKH67,GKH68,GKH69,GKI60,GKI61,GKI62,GKI63,GKI64,GKI65,GKI66,GKI67,GKI68,GKI69,';
     z := z + 'GKJ60,GKJ61,GKJ62,GKJ63,GKJ64,GKJ65,GKJ66,GKJ67,GKJ68,GKJ69,GKK60,GKK61,GKK62,GKK63,GKK64,';
     z := z + 'GKK65,GKK66,GKK67,GKK68,GKK69,GKL60,GKL61,GKL62,GKL63,GKL64,GKL65,GKL66,GKL67,GKL68,GKL69,';
     z := z + 'GKM60,GKM61,GKM62,GKM63,GKM64,GKM65,GKM66,GKM67,GKM68,GKM69,GKN60,GKN61,GKN62,GKN63,GKN64,';
     z := z + 'GKN65,GKN66,GKN67,GKN68,GKN69,GKO60,GKO61,GKO62,GKO63,GKO64,GKO65,GKO66,GKO67,GKO68,GKO69,';
     z := z + 'GKP60,GKP61,GKP62,GKP63,GKP64,GKP65,GKP66,GKP67,GKP68,GKP69,GKQ60,GKQ61,GKQ62,GKQ63,GKQ64,';
     z := z + 'GKQ65,GKQ66,GKQ67,GKQ68,GKQ69,GKR60,GKR61,GKR62,GKR63,GKR64,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GKA50,GKA51,GKA52,GKA53,GKA54,GKA55,GKA56,GKA57,GKA58,GKA59,GKB50,GKB51,GKB52,GKB53,GKB54,';
     z := z + 'GKB55,GKB56,GKB57,GKB58,GKB59,GKC50,GKC51,GKC52,GKC53,GKC54,GKC55,GKC56,GKC57,GKC58,GKC59,';
     z := z + 'GKD50,GKD51,GKD52,GKD53,GKD54,GKD55,GKD56,GKD57,GKD58,GKD59,GKE50,GKE51,GKE52,GKE53,GKE54,';
     z := z + 'GKE55,GKE56,GKE57,GKE58,GKE59,GKF50,GKF51,GKF52,GKF53,GKF54,GKF55,GKF56,GKF57,GKF58,GKF59,';
     z := z + 'GKG50,GKG51,GKG52,GKG53,GKG54,GKG55,GKG56,GKG57,GKG58,GKG59,GKH50,GKH51,GKH52,GKH53,GKH54,';
     z := z + 'GKH55,GKH56,GKH57,GKH58,GKH59,GKI50,GKI51,GKI52,GKI53,GKI54,GKI55,GKI56,GKI57,GKI58,GKI59,';
     z := z + 'GKJ50,GKJ51,GKJ52,GKJ53,GKJ54,GKJ55,GKJ56,GKJ57,GKJ58,GKJ59,GKK50,GKK51,GKK52,GKK53,GKK54,';
     z := z + 'GKK55,GKK56,GKK57,GKK58,GKK59,GKL50,GKL51,GKL52,GKL53,GKL54,GKL55,GKL56,GKL57,GKL58,GKL59,';
     z := z + 'GKM50,GKM51,GKM52,GKM53,GKM54,GKM55,GKM56,GKM57,GKM58,GKM59,GKN50,GKN51,GKN52,GKN53,GKN54,';
     z := z + 'GKN55,GKN56,GKN57,GKN58,GKN59,GKO50,GKO51,GKO52,GKO53,GKO54,GKO55,GKO56,GKO57,GKO58,GKO59,';
     z := z + 'GKP50,GKP51,GKP52,GKP53,GKP54,GKP55,GKP56,GKP57,GKP58,GKP59,GKQ50,GKQ51,GKQ52,GKQ53,GKQ54,';
     z := z + 'GKQ55,GKQ56,GKQ57,GKQ58,GKQ59,GKR50,GKR51,GKR52,GKR53,GKR54,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GKA40,GKA41,GKA42,GKA43,GKA44,GKA45,GKA46,GKA47,GKA48,GKA49,GKB40,GKB41,GKB42,GKB43,GKB44,';
     z := z + 'GKB45,GKB46,GKB47,GKB48,GKB49,GKC40,GKC41,GKC42,GKC43,GKC44,GKC45,GKC46,GKC47,GKC48,GKC49,';
     z := z + 'GKD40,GKD41,GKD42,GKD43,GKD44,GKD45,GKD46,GKD47,GKD48,GKD49,GKE40,GKE41,GKE42,GKE43,GKE44,';
     z := z + 'GKE45,GKE46,GKE47,GKE48,GKE49,GKF40,GKF41,GKF42,GKF43,GKF44,GKF45,GKF46,GKF47,GKF48,GKF49,';
     z := z + 'GKG40,GKG41,GKG42,GKG43,GKG44,GKG45,GKG46,GKG47,GKG48,GKG49,GKH40,GKH41,GKH42,GKH43,GKH44,';
     z := z + 'GKH45,GKH46,GKH47,GKH48,GKH49,GKI40,GKI41,GKI42,GKI43,GKI44,GKI45,GKI46,GKI47,GKI48,GKI49,';
     z := z + 'GKJ40,GKJ41,GKJ42,GKJ43,GKJ44,GKJ45,GKJ46,GKJ47,GKJ48,GKJ49,GKK40,GKK41,GKK42,GKK43,GKK44,';
     z := z + 'GKK45,GKK46,GKK47,GKK48,GKK49,GKL40,GKL41,GKL42,GKL43,GKL44,GKL45,GKL46,GKL47,GKL48,GKL49,';
     z := z + 'GKM40,GKM41,GKM42,GKM43,GKM44,GKM45,GKM46,GKM47,GKM48,GKM49,GKN40,GKN41,GKN42,GKN43,GKN44,';
     z := z + 'GKN45,GKN46,GKN47,GKN48,GKN49,GKO40,GKO41,GKO42,GKO43,GKO44,GKO45,GKO46,GKO47,GKO48,GKO49,';
     z := z + 'GKP40,GKP41,GKP42,GKP43,GKP44,GKP45,GKP46,GKP47,GKP48,GKP49,GKQ40,GKQ41,GKQ42,GKQ43,GKQ44,';
     z := z + 'GKQ45,GKQ46,GKQ47,GKQ48,GKQ49,GKR40,GKR41,GKR42,GKR43,GKR44,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GKA30,GKA31,GKA32,GKA33,GKA34,GKA35,GKA36,GKA37,GKA38,GKA39,GKB30,GKB31,GKB32,GKB33,GKB34,';
     z := z + 'GKB35,GKB36,GKB37,GKB38,GKB39,GKC30,GKC31,GKC32,GKC33,GKC34,GKC35,GKC36,GKC37,GKC38,GKC39,';
     z := z + 'GKD30,GKD31,GKD32,GKD33,GKD34,GKD35,GKD36,GKD37,GKD38,GKD39,GKE30,GKE31,GKE32,GKE33,GKE34,';
     z := z + 'GKE35,GKE36,GKE37,GKE38,GKE39,GKF30,GKF31,GKF32,GKF33,GKF34,GKF35,GKF36,GKF37,GKF38,GKF39,';
     z := z + 'GKG30,GKG31,GKG32,GKG33,GKG34,GKG35,GKG36,GKG37,GKG38,GKG39,GKH30,GKH31,GKH32,GKH33,GKH34,';
     z := z + 'GKH35,GKH36,GKH37,GKH38,GKH39,GKI30,GKI31,GKI32,GKI33,GKI34,GKI35,GKI36,GKI37,GKI38,GKI39,';
     z := z + 'GKJ30,GKJ31,GKJ32,GKJ33,GKJ34,GKJ35,GKJ36,GKJ37,GKJ38,GKJ39,GKK30,GKK31,GKK32,GKK33,GKK34,';
     z := z + 'GKK35,GKK36,GKK37,GKK38,GKK39,GKL30,GKL31,GKL32,GKL33,GKL34,GKL35,GKL36,GKL37,GKL38,GKL39,';
     z := z + 'GKM30,GKM31,GKM32,GKM33,GKM34,GKM35,GKM36,GKM37,GKM38,GKM39,GKN30,GKN31,GKN32,GKN33,GKN34,';
     z := z + 'GKN35,GKN36,GKN37,GKN38,GKN39,GKO30,GKO31,GKO32,GKO33,GKO34,GKO35,GKO36,GKO37,GKO38,GKO39,';
     z := z + 'GKP30,GKP31,GKP32,GKP33,GKP34,GKP35,GKP36,GKP37,GKP38,GKP39,GKQ30,GKQ31,GKQ32,GKQ33,GKQ34,';
     z := z + 'GKQ35,GKQ36,GKQ37,GKQ38,GKQ39,GKR30,GKR31,GKR32,GKR33,GKR34,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GKA20,GKA21,GKA22,GKA23,GKA24,GKA25,GKA26,GKA27,GKA28,GKA29,GKB20,GKB21,GKB22,GKB23,GKB24,';
     z := z + 'GKB25,GKB26,GKB27,GKB28,GKB29,GKC20,GKC21,GKC22,GKC23,GKC24,GKC25,GKC26,GKC27,GKC28,GKC29,';
     z := z + 'GKD20,GKD21,GKD22,GKD23,GKD24,GKD25,GKD26,GKD27,GKD28,GKD29,GKE20,GKE21,GKE22,GKE23,GKE24,';
     z := z + 'GKE25,GKE26,GKE27,GKE28,GKE29,GKF20,GKF21,GKF22,GKF23,GKF24,GKF25,GKF26,GKF27,GKF28,GKF29,';
     z := z + 'GKG20,GKG21,GKG22,GKG23,GKG24,GKG25,GKG26,GKG27,GKG28,GKG29,GKH20,GKH21,GKH22,GKH23,GKH24,';
     z := z + 'GKH25,GKH26,GKH27,GKH28,GKH29,GKI20,GKI21,GKI22,GKI23,GKI24,GKI25,GKI26,GKI27,GKI28,GKI29,';
     z := z + 'GKJ20,GKJ21,GKJ22,GKJ23,GKJ24,GKJ25,GKJ26,GKJ27,GKJ28,GKJ29,GKK20,GKK21,GKK22,GKK23,GKK24,';
     z := z + 'GKK25,GKK26,GKK27,GKK28,GKK29,GKL20,GKL21,GKL22,GKL23,GKL24,GKL25,GKL26,GKL27,GKL28,GKL29,';
     z := z + 'GKM20,GKM21,GKM22,GKM23,GKM24,GKM25,GKM26,GKM27,GKM28,GKM29,GKN20,GKN21,GKN22,GKN23,GKN24,';
     z := z + 'GKN25,GKN26,GKN27,GKN28,GKN29,GKO20,GKO21,GKO22,GKO23,GKO24,GKO25,GKO26,GKO27,GKO28,GKO29,';
     z := z + 'GKP20,GKP21,GKP22,GKP23,GKP24,GKP25,GKP26,GKP27,GKP28,GKP29,GKQ20,GKQ21,GKQ22,GKQ23,GKQ24,';
     z := z + 'GKQ25,GKQ26,GKQ27,GKQ28,GKQ29,GKR20,GKR21,GKR22,GKR23,GKR24,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GKA10,GKA11,GKA12,GKA13,GKA14,GKA15,GKA16,GKA17,GKA18,GKA19,GKB10,GKB11,GKB12,GKB13,GKB14,';
     z := z + 'GKB15,GKB16,GKB17,GKB18,GKB19,GKC10,GKC11,GKC12,GKC13,GKC14,GKC15,GKC16,GKC17,GKC18,GKC19,';
     z := z + 'GKD10,GKD11,GKD12,GKD13,GKD14,GKD15,GKD16,GKD17,GKD18,GKD19,GKE10,GKE11,GKE12,GKE13,GKE14,';
     z := z + 'GKE15,GKE16,GKE17,GKE18,GKE19,GKF10,GKF11,GKF12,GKF13,GKF14,GKF15,GKF16,GKF17,GKF18,GKF19,';
     z := z + 'GKG10,GKG11,GKG12,GKG13,GKG14,GKG15,GKG16,GKG17,GKG18,GKG19,GKH10,GKH11,GKH12,GKH13,GKH14,';
     z := z + 'GKH15,GKH16,GKH17,GKH18,GKH19,GKI10,GKI11,GKI12,GKI13,GKI14,GKI15,GKI16,GKI17,GKI18,GKI19,';
     z := z + 'GKJ10,GKJ11,GKJ12,GKJ13,GKJ14,GKJ15,GKJ16,GKJ17,GKJ18,GKJ19,GKK10,GKK11,GKK12,GKK13,GKK14,';
     z := z + 'GKK15,GKK16,GKK17,GKK18,GKK19,GKL10,GKL11,GKL12,GKL13,GKL14,GKL15,GKL16,GKL17,GKL18,GKL19,';
     z := z + 'GKM10,GKM11,GKM12,GKM13,GKM14,GKM15,GKM16,GKM17,GKM18,GKM19,GKN10,GKN11,GKN12,GKN13,GKN14,';
     z := z + 'GKN15,GKN16,GKN17,GKN18,GKN19,GKO10,GKO11,GKO12,GKO13,GKO14,GKO15,GKO16,GKO17,GKO18,GKO19,';
     z := z + 'GKP10,GKP11,GKP12,GKP13,GKP14,GKP15,GKP16,GKP17,GKP18,GKP19,GKQ10,GKQ11,GKQ12,GKQ13,GKQ14,';
     z := z + 'GKQ15,GKQ16,GKQ17,GKQ18,GKQ19,GKR10,GKR11,GKR12,GKR13,GKR14,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GKA00,GKA01,GKA02,GKA03,GKA04,GKA05,GKA06,GKA07,GKA08,GKA09,GKB00,GKB01,GKB02,GKB03,GKB04,';
     z := z + 'GKB05,GKB06,GKB07,GKB08,GKB09,GKC00,GKC01,GKC02,GKC03,GKC04,GKC05,GKC06,GKC07,GKC08,GKC09,';
     z := z + 'GKD00,GKD01,GKD02,GKD03,GKD04,GKD05,GKD06,GKD07,GKD08,GKD09,GKE00,GKE01,GKE02,GKE03,GKE04,';
     z := z + 'GKE05,GKE06,GKE07,GKE08,GKE09,GKF00,GKF01,GKF02,GKF03,GKF04,GKF05,GKF06,GKF07,GKF08,GKF09,';
     z := z + 'GKG00,GKG01,GKG02,GKG03,GKG04,GKG05,GKG06,GKG07,GKG08,GKG09,GKH00,GKH01,GKH02,GKH03,GKH04,';
     z := z + 'GKH05,GKH06,GKH07,GKH08,GKH09,GKI00,GKI01,GKI02,GKI03,GKI04,GKI05,GKI06,GKI07,GKI08,GKI09,';
     z := z + 'GKJ00,GKJ01,GKJ02,GKJ03,GKJ04,GKJ05,GKJ06,GKJ07,GKJ08,GKJ09,GKK00,GKK01,GKK02,GKK03,GKK04,';
     z := z + 'GKK05,GKK06,GKK07,GKK08,GKK09,GKL00,GKL01,GKL02,GKL03,GKL04,GKL05,GKL06,GKL07,GKL08,GKL09,';
     z := z + 'GKM00,GKM01,GKM02,GKM03,GKM04,GKM05,GKM06,GKM07,GKM08,GKM09,GKN00,GKN01,GKN02,GKN03,GKN04,';
     z := z + 'GKN05,GKN06,GKN07,GKN08,GKN09,GKO00,GKO01,GKO02,GKO03,GKO04,GKO05,GKO06,GKO07,GKO08,GKO09,';
     z := z + 'GKP00,GKP01,GKP02,GKP03,GKP04,GKP05,GKP06,GKP07,GKP08,GKP09,GKQ00,GKQ01,GKQ02,GKQ03,GKQ04,';
     z := z + 'GKQ05,GKQ06,GKQ07,GKQ08,GKQ09,GKR00,GKR01,GKR02,GKR03,GKR04,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GJA90,GJA91,GJA92,GJA93,GJA94,GJA95,GJA96,GJA97,GJA98,GJA99,GJB90,GJB91,GJB92,GJB93,GJB94,';
     z := z + 'GJB95,GJB96,GJB97,GJB98,GJB99,GJC90,GJC91,GJC92,GJC93,GJC94,GJC95,GJC96,GJC97,GJC98,GJC99,';
     z := z + 'GJD90,GJD91,GJD92,GJD93,GJD94,GJD95,GJD96,GJD97,GJD98,GJD99,GJE90,GJE91,GJE92,GJE93,GJE94,';
     z := z + 'GJE95,GJE96,GJE97,GJE98,GJE99,GJF90,GJF91,GJF92,GJF93,GJF94,GJF95,GJF96,GJF97,GJF98,GJF99,';
     z := z + 'GJG90,GJG91,GJG92,GJG93,GJG94,GJG95,GJG96,GJG97,GJG98,GJG99,GJH90,GJH91,GJH92,GJH93,GJH94,';
     z := z + 'GJH95,GJH96,GJH97,GJH98,GJH99,GJI90,GJI91,GJI92,GJI93,GJI94,GJI95,GJI96,GJI97,GJI98,GJI99,';
     z := z + 'GJJ90,GJJ91,GJJ92,GJJ93,GJJ94,GJJ95,GJJ96,GJJ97,GJJ98,GJJ99,GJK90,GJK91,GJK92,GJK93,GJK94,';
     z := z + 'GJK95,GJK96,GJK97,GJK98,GJK99,GJL90,GJL91,GJL92,GJL93,GJL94,GJL95,GJL96,GJL97,GJL98,GJL99,';
     z := z + 'GJM90,GJM91,GJM92,GJM93,GJM94,GJM95,GJM96,GJM97,GJM98,GJM99,GJN90,GJN91,GJN92,GJN93,GJN94,';
     z := z + 'GJN95,GJN96,GJN97,GJN98,GJN99,GJO90,GJO91,GJO92,GJO93,GJO94,GJO95,GJO96,GJO97,GJO98,GJO99,';
     z := z + 'GJP90,GJP91,GJP92,GJP93,GJP94,GJP95,GJP96,GJP97,GJP98,GJP99,GJQ90,GJQ91,GJQ92,GJQ93,GJQ94,';
     z := z + 'GJQ95,GJQ96,GJQ97,GJQ98,GJQ99,GJR90,GJR91,GJR92,GJR93,GJR94,PP    ,P0    ,P1    ,P2    ,P3    ,';
     z := z + 'GJA80,GJA81,GJA82,GJA83,GJA84,GJA85,GJA86,GJA87,GJA88,GJA89,GJB80,GJB81,GJB82,GJB83,GJB84,';
     z := z + 'GJB85,GJB86,GJB87,GJB88,GJB89,GJC80,GJC81,GJC82,GJC83,GJC84,GJC85,GJC86,GJC87,GJC88,GJC89,';
     z := z + 'GJD80,GJD81,GJD82,GJD83,GJD84,GJD85,GJD86,GJD87,GJD88,GJD89,GJE80,GJE81,GJE82,GJE83,GJE84,';
     z := z + 'GJE85,GJE86,GJE87,GJE88,GJE89,GJF80,GJF81,GJF82,GJF83,GJF84,GJF85,GJF86,GJF87,GJF88,GJF89,';
     z := z + 'GJG80,GJG81,GJG82,GJG83,GJG84,GJG85,GJG86,GJG87,GJG88,GJG89,GJH80,GJH81,GJH82,GJH83,GJH84,';
     z := z + 'GJH85,GJH86,GJH87,GJH88,GJH89,GJI80,GJI81,GJI82,GJI83,GJI84,GJI85,GJI86,GJI87,GJI88,GJI89,';
     z := z + 'GJJ80,GJJ81,GJJ82,GJJ83,GJJ84,GJJ85,GJJ86,GJJ87,GJJ88,GJJ89,GJK80,GJK81,GJK82,GJK83,GJK84,';
     z := z + 'GJK85,GJK86,GJK87,GJK88,GJK89,GJL80,GJL81,GJL82,GJL83,GJL84,GJL85,GJL86,GJL87,GJL88,GJL89,';
     z := z + 'GJM80,GJM81,GJM82,GJM83,GJM84,GJM85,GJM86,GJM87,GJM88,GJM89,GJN80,GJN81,GJN82,GJN83,GJN84,';
     z := z + 'GJN85,GJN86,GJN87,GJN88,GJN89,GJO80,GJO81,GJO82,GJO83,GJO84,GJO85,GJO86,GJO87,GJO88,GJO89,';
     z := z + 'GJP80,GJP81,GJP82,GJP83,GJP84,GJP85,GJP86,GJP87,GJP88,GJP89,GJQ80,GJQ81,GJQ82,GJQ83,GJQ84,';
     z := z + 'GJQ85,GJQ86,GJQ87,GJQ88,GJQ89,GJR80,GJR81,GJR82,GJR83,GJR84,P4    ,P5    ,P6    ,P7    ,P8    ,';
     z := z + 'GJA70,GJA71,GJA72,GJA73,GJA74,GJA75,GJA76,GJA77,GJA78,GJA79,GJB70,GJB71,GJB72,GJB73,GJB74,';
     z := z + 'GJB75,GJB76,GJB77,GJB78,GJB79,GJC70,GJC71,GJC72,GJC73,GJC74,GJC75,GJC76,GJC77,GJC78,GJC79,';
     z := z + 'GJD70,GJD71,GJD72,GJD73,GJD74,GJD75,GJD76,GJD77,GJD78,GJD79,GJE70,GJE71,GJE72,GJE73,GJE74,';
     z := z + 'GJE75,GJE76,GJE77,GJE78,GJE79,GJF70,GJF71,GJF72,GJF73,GJF74,GJF75,GJF76,GJF77,GJF78,GJF79,';
     z := z + 'GJG70,GJG71,GJG72,GJG73,GJG74,GJG75,GJG76,GJG77,GJG78,GJG79,GJH70,GJH71,GJH72,GJH73,GJH74,';
     z := z + 'GJH75,GJH76,GJH77,GJH78,GJH79,GJI70,GJI71,GJI72,GJI73,GJI74,GJI75,GJI76,GJI77,GJI78,GJI79,';
     z := z + 'GJJ70,GJJ71,GJJ72,GJJ73,GJJ74,GJJ75,GJJ76,GJJ77,GJJ78,GJJ79,GJK70,GJK71,GJK72,GJK73,GJK74,';
     z := z + 'GJK75,GJK76,GJK77,GJK78,GJK79,GJL70,GJL71,GJL72,GJL73,GJL74,GJL75,GJL76,GJL77,GJL78,GJL79,';
     z := z + 'GJM70,GJM71,GJM72,GJM73,GJM74,GJM75,GJM76,GJM77,GJM78,GJM79,GJN70,GJN71,GJN72,GJN73,GJN74,';
     z := z + 'GJN75,GJN76,GJN77,GJN78,GJN79,GJO70,GJO71,GJO72,GJO73,GJO74,GJO75,GJO76,GJO77,GJO78,GJO79,';
     z := z + 'GJP70,GJP71,GJP72,GJP73,GJP74,GJP75,GJP76,GJP77,GJP78,GJP79,GJQ70,GJQ71,GJQ72,GJQ73,GJQ74,';
     z := z + 'GJQ75,GJQ76,GJQ77,GJQ78,GJQ79,GJR70,GJR71,GJR72,GJR73,GJR74,P9    ,PA    ,P     ,P     ,P     ,';
     z := z + 'GJA60,GJA61,GJA62,GJA63,GJA64,GJA65,GJA66,GJA67,GJA68,GJA69,GJB60,GJB61,GJB62,GJB63,GJB64,';
     z := z + 'GJB65,GJB66,GJB67,GJB68,GJB69,GJC60,GJC61,GJC62,GJC63,GJC64,GJC65,GJC66,GJC67,GJC68,GJC69,';
     z := z + 'GJD60,GJD61,GJD62,GJD63,GJD64,GJD65,GJD66,GJD67,GJD68,GJD69,GJE60,GJE61,GJE62,GJE63,GJE64,';
     z := z + 'GJE65,GJE66,GJE67,GJE68,GJE69,GJF60,GJF61,GJF62,GJF63,GJF64,GJF65,GJF66,GJF67,GJF68,GJF69,';
     z := z + 'GJG60,GJG61,GJG62,GJG63,GJG64,GJG65,GJG66,GJG67,GJG68,GJG69,GJH60,GJH61,GJH62,GJH63,GJH64,';
     z := z + 'GJH65,GJH66,GJH67,GJH68,GJH69,GJI60,GJI61,GJI62,GJI63,GJI64,GJI65,GJI66,GJI67,GJI68,GJI69,';
     z := z + 'GJJ60,GJJ61,GJJ62,GJJ63,GJJ64,GJJ65,GJJ66,GJJ67,GJJ68,GJJ69,GJK60,GJK61,GJK62,GJK63,GJK64,';
     z := z + 'GJK65,GJK66,GJK67,GJK68,GJK69,GJL60,GJL61,GJL62,GJL63,GJL64,GJL65,GJL66,GJL67,GJL68,GJL69,';
     z := z + 'GJM60,GJM61,GJM62,GJM63,GJM64,GJM65,GJM66,GJM67,GJM68,GJM69,GJN60,GJN61,GJN62,GJN63,GJN64,';
     z := z + 'GJN65,GJN66,GJN67,GJN68,GJN69,GJO60,GJO61,GJO62,GJO63,GJO64,GJO65,GJO66,GJO67,GJO68,GJO69,';
     z := z + 'GJP60,GJP61,GJP62,GJP63,GJP64,GJP65,GJP66,GJP67,GJP68,GJP69,GJQ60,GJQ61,GJQ62,GJQ63,GJQ64,';
     z := z + 'GJQ65,GJQ66,GJQ67,GJQ68,GJQ69,GJR60,GJR61,GJR62,GJR63,GJR64,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GJA50,GJA51,GJA52,GJA53,GJA54,GJA55,GJA56,GJA57,GJA58,GJA59,GJB50,GJB51,GJB52,GJB53,GJB54,';
     z := z + 'GJB55,GJB56,GJB57,GJB58,GJB59,GJC50,GJC51,GJC52,GJC53,GJC54,GJC55,GJC56,GJC57,GJC58,GJC59,';
     z := z + 'GJD50,GJD51,GJD52,GJD53,GJD54,GJD55,GJD56,GJD57,GJD58,GJD59,GJE50,GJE51,GJE52,GJE53,GJE54,';
     z := z + 'GJE55,GJE56,GJE57,GJE58,GJE59,GJF50,GJF51,GJF52,GJF53,GJF54,GJF55,GJF56,GJF57,GJF58,GJF59,';
     z := z + 'GJG50,GJG51,GJG52,GJG53,GJG54,GJG55,GJG56,GJG57,GJG58,GJG59,GJH50,GJH51,GJH52,GJH53,GJH54,';
     z := z + 'GJH55,GJH56,GJH57,GJH58,GJH59,GJI50,GJI51,GJI52,GJI53,GJI54,GJI55,GJI56,GJI57,GJI58,GJI59,';
     z := z + 'GJJ50,GJJ51,GJJ52,GJJ53,GJJ54,GJJ55,GJJ56,GJJ57,GJJ58,GJJ59,GJK50,GJK51,GJK52,GJK53,GJK54,';
     z := z + 'GJK55,GJK56,GJK57,GJK58,GJK59,GJL50,GJL51,GJL52,GJL53,GJL54,GJL55,GJL56,GJL57,GJL58,GJL59,';
     z := z + 'GJM50,GJM51,GJM52,GJM53,GJM54,GJM55,GJM56,GJM57,GJM58,GJM59,GJN50,GJN51,GJN52,GJN53,GJN54,';
     z := z + 'GJN55,GJN56,GJN57,GJN58,GJN59,GJO50,GJO51,GJO52,GJO53,GJO54,GJO55,GJO56,GJO57,GJO58,GJO59,';
     z := z + 'GJP50,GJP51,GJP52,GJP53,GJP54,GJP55,GJP56,GJP57,GJP58,GJP59,GJQ50,GJQ51,GJQ52,GJQ53,GJQ54,';
     z := z + 'GJQ55,GJQ56,GJQ57,GJQ58,GJQ59,GJR50,GJR51,GJR52,GJR53,GJR54,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GJA40,GJA41,GJA42,GJA43,GJA44,GJA45,GJA46,GJA47,GJA48,GJA49,GJB40,GJB41,GJB42,GJB43,GJB44,';
     z := z + 'GJB45,GJB46,GJB47,GJB48,GJB49,GJC40,GJC41,GJC42,GJC43,GJC44,GJC45,GJC46,GJC47,GJC48,GJC49,';
     z := z + 'GJD40,GJD41,GJD42,GJD43,GJD44,GJD45,GJD46,GJD47,GJD48,GJD49,GJE40,GJE41,GJE42,GJE43,GJE44,';
     z := z + 'GJE45,GJE46,GJE47,GJE48,GJE49,GJF40,GJF41,GJF42,GJF43,GJF44,GJF45,GJF46,GJF47,GJF48,GJF49,';
     z := z + 'GJG40,GJG41,GJG42,GJG43,GJG44,GJG45,GJG46,GJG47,GJG48,GJG49,GJH40,GJH41,GJH42,GJH43,GJH44,';
     z := z + 'GJH45,GJH46,GJH47,GJH48,GJH49,GJI40,GJI41,GJI42,GJI43,GJI44,GJI45,GJI46,GJI47,GJI48,GJI49,';
     z := z + 'GJJ40,GJJ41,GJJ42,GJJ43,GJJ44,GJJ45,GJJ46,GJJ47,GJJ48,GJJ49,GJK40,GJK41,GJK42,GJK43,GJK44,';
     z := z + 'GJK45,GJK46,GJK47,GJK48,GJK49,GJL40,GJL41,GJL42,GJL43,GJL44,GJL45,GJL46,GJL47,GJL48,GJL49,';
     z := z + 'GJM40,GJM41,GJM42,GJM43,GJM44,GJM45,GJM46,GJM47,GJM48,GJM49,GJN40,GJN41,GJN42,GJN43,GJN44,';
     z := z + 'GJN45,GJN46,GJN47,GJN48,GJN49,GJO40,GJO41,GJO42,GJO43,GJO44,GJO45,GJO46,GJO47,GJO48,GJO49,';
     z := z + 'GJP40,GJP41,GJP42,GJP43,GJP44,GJP45,GJP46,GJP47,GJP48,GJP49,GJQ40,GJQ41,GJQ42,GJQ43,GJQ44,';
     z := z + 'GJQ45,GJQ46,GJQ47,GJQ48,GJQ49,GJR40,GJR41,GJR42,GJR43,GJR44,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GJA30,GJA31,GJA32,GJA33,GJA34,GJA35,GJA36,GJA37,GJA38,GJA39,GJB30,GJB31,GJB32,GJB33,GJB34,';
     z := z + 'GJB35,GJB36,GJB37,GJB38,GJB39,GJC30,GJC31,GJC32,GJC33,GJC34,GJC35,GJC36,GJC37,GJC38,GJC39,';
     z := z + 'GJD30,GJD31,GJD32,GJD33,GJD34,GJD35,GJD36,GJD37,GJD38,GJD39,GJE30,GJE31,GJE32,GJE33,GJE34,';
     z := z + 'GJE35,GJE36,GJE37,GJE38,GJE39,GJF30,GJF31,GJF32,GJF33,GJF34,GJF35,GJF36,GJF37,GJF38,GJF39,';
     z := z + 'GJG30,GJG31,GJG32,GJG33,GJG34,GJG35,GJG36,GJG37,GJG38,GJG39,GJH30,GJH31,GJH32,GJH33,GJH34,';
     z := z + 'GJH35,GJH36,GJH37,GJH38,GJH39,GJI30,GJI31,GJI32,GJI33,GJI34,GJI35,GJI36,GJI37,GJI38,GJI39,';
     z := z + 'GJJ30,GJJ31,GJJ32,GJJ33,GJJ34,GJJ35,GJJ36,GJJ37,GJJ38,GJJ39,GJK30,GJK31,GJK32,GJK33,GJK34,';
     z := z + 'GJK35,GJK36,GJK37,GJK38,GJK39,GJL30,GJL31,GJL32,GJL33,GJL34,GJL35,GJL36,GJL37,GJL38,GJL39,';
     z := z + 'GJM30,GJM31,GJM32,GJM33,GJM34,GJM35,GJM36,GJM37,GJM38,GJM39,GJN30,GJN31,GJN32,GJN33,GJN34,';
     z := z + 'GJN35,GJN36,GJN37,GJN38,GJN39,GJO30,GJO31,GJO32,GJO33,GJO34,GJO35,GJO36,GJO37,GJO38,GJO39,';
     z := z + 'GJP30,GJP31,GJP32,GJP33,GJP34,GJP35,GJP36,GJP37,GJP38,GJP39,GJQ30,GJQ31,GJQ32,GJQ33,GJQ34,';
     z := z + 'GJQ35,GJQ36,GJQ37,GJQ38,GJQ39,GJR30,GJR31,GJR32,GJR33,GJR34,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GJA20,GJA21,GJA22,GJA23,GJA24,GJA25,GJA26,GJA27,GJA28,GJA29,GJB20,GJB21,GJB22,GJB23,GJB24,';
     z := z + 'GJB25,GJB26,GJB27,GJB28,GJB29,GJC20,GJC21,GJC22,GJC23,GJC24,GJC25,GJC26,GJC27,GJC28,GJC29,';
     z := z + 'GJD20,GJD21,GJD22,GJD23,GJD24,GJD25,GJD26,GJD27,GJD28,GJD29,GJE20,GJE21,GJE22,GJE23,GJE24,';
     z := z + 'GJE25,GJE26,GJE27,GJE28,GJE29,GJF20,GJF21,GJF22,GJF23,GJF24,GJF25,GJF26,GJF27,GJF28,GJF29,';
     z := z + 'GJG20,GJG21,GJG22,GJG23,GJG24,GJG25,GJG26,GJG27,GJG28,GJG29,GJH20,GJH21,GJH22,GJH23,GJH24,';
     z := z + 'GJH25,GJH26,GJH27,GJH28,GJH29,GJI20,GJI21,GJI22,GJI23,GJI24,GJI25,GJI26,GJI27,GJI28,GJI29,';
     z := z + 'GJJ20,GJJ21,GJJ22,GJJ23,GJJ24,GJJ25,GJJ26,GJJ27,GJJ28,GJJ29,GJK20,GJK21,GJK22,GJK23,GJK24,';
     z := z + 'GJK25,GJK26,GJK27,GJK28,GJK29,GJL20,GJL21,GJL22,GJL23,GJL24,GJL25,GJL26,GJL27,GJL28,GJL29,';
     z := z + 'GJM20,GJM21,GJM22,GJM23,GJM24,GJM25,GJM26,GJM27,GJM28,GJM29,GJN20,GJN21,GJN22,GJN23,GJN24,';
     z := z + 'GJN25,GJN26,GJN27,GJN28,GJN29,GJO20,GJO21,GJO22,GJO23,GJO24,GJO25,GJO26,GJO27,GJO28,GJO29,';
     z := z + 'GJP20,GJP21,GJP22,GJP23,GJP24,GJP25,GJP26,GJP27,GJP28,GJP29,GJQ20,GJQ21,GJQ22,GJQ23,GJQ24,';
     z := z + 'GJQ25,GJQ26,GJQ27,GJQ28,GJQ29,GJR20,GJR21,GJR22,GJR23,GJR24,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GJA10,GJA11,GJA12,GJA13,GJA14,GJA15,GJA16,GJA17,GJA18,GJA19,GJB10,GJB11,GJB12,GJB13,GJB14,';
     z := z + 'GJB15,GJB16,GJB17,GJB18,GJB19,GJC10,GJC11,GJC12,GJC13,GJC14,GJC15,GJC16,GJC17,GJC18,GJC19,';
     z := z + 'GJD10,GJD11,GJD12,GJD13,GJD14,GJD15,GJD16,GJD17,GJD18,GJD19,GJE10,GJE11,GJE12,GJE13,GJE14,';
     z := z + 'GJE15,GJE16,GJE17,GJE18,GJE19,GJF10,GJF11,GJF12,GJF13,GJF14,GJF15,GJF16,GJF17,GJF18,GJF19,';
     z := z + 'GJG10,GJG11,GJG12,GJG13,GJG14,GJG15,GJG16,GJG17,GJG18,GJG19,GJH10,GJH11,GJH12,GJH13,GJH14,';
     z := z + 'GJH15,GJH16,GJH17,GJH18,GJH19,GJI10,GJI11,GJI12,GJI13,GJI14,GJI15,GJI16,GJI17,GJI18,GJI19,';
     z := z + 'GJJ10,GJJ11,GJJ12,GJJ13,GJJ14,GJJ15,GJJ16,GJJ17,GJJ18,GJJ19,GJK10,GJK11,GJK12,GJK13,GJK14,';
     z := z + 'GJK15,GJK16,GJK17,GJK18,GJK19,GJL10,GJL11,GJL12,GJL13,GJL14,GJL15,GJL16,GJL17,GJL18,GJL19,';
     z := z + 'GJM10,GJM11,GJM12,GJM13,GJM14,GJM15,GJM16,GJM17,GJM18,GJM19,GJN10,GJN11,GJN12,GJN13,GJN14,';
     z := z + 'GJN15,GJN16,GJN17,GJN18,GJN19,GJO10,GJO11,GJO12,GJO13,GJO14,GJO15,GJO16,GJO17,GJO18,GJO19,';
     z := z + 'GJP10,GJP11,GJP12,GJP13,GJP14,GJP15,GJP16,GJP17,GJP18,GJP19,GJQ10,GJQ11,GJQ12,GJQ13,GJQ14,';
     z := z + 'GJQ15,GJQ16,GJQ17,GJQ18,GJQ19,GJR10,GJR11,GJR12,GJR13,GJR14,P     ,P     ,P     ,P     ,P     ,';
     z := z + 'GJA00,GJA01,GJA02,GJA03,GJA04,GJA05,GJA06,GJA07,GJA08,GJA09,GJB00,GJB01,GJB02,GJB03,GJB04,';
     z := z + 'GJB05,GJB06,GJB07,GJB08,GJB09,GJC00,GJC01,GJC02,GJC03,GJC04,GJC05,GJC06,GJC07,GJC08,GJC09,';
     z := z + 'GJD00,GJD01,GJD02,GJD03,GJD04,GJD05,GJD06,GJD07,GJD08,GJD09,GJE00,GJE01,GJE02,GJE03,GJE04,';
     z := z + 'GJE05,GJE06,GJE07,GJE08,GJE09,GJF00,GJF01,GJF02,GJF03,GJF04,GJF05,GJF06,GJF07,GJF08,GJF09,';
     z := z + 'GJG00,GJG01,GJG02,GJG03,GJG04,GJG05,GJG06,GJG07,GJG08,GJG09,GJH00,GJH01,GJH02,GJH03,GJH04,';
     z := z + 'GJH05,GJH06,GJH07,GJH08,GJH09,GJI00,GJI01,GJI02,GJI03,GJI04,GJI05,GJI06,GJI07,GJI08,GJI09,';
     z := z + 'GJJ00,GJJ01,GJJ02,GJJ03,GJJ04,GJJ05,GJJ06,GJJ07,GJJ08,GJJ09,GJK00,GJK01,GJK02,GJK03,GJK04,';
     z := z + 'GJK05,GJK06,GJK07,GJK08,GJK09,GJL00,GJL01,GJL02,GJL03,GJL04,GJL05,GJL06,GJL07,GJL08,GJL09,';
     z := z + 'GJM00,GJM01,GJM02,GJM03,GJM04,GJM05,GJM06,GJM07,GJM08,GJM09,GJN00,GJN01,GJN02,GJN03,GJN04,';
     z := z + 'GJN05,GJN06,GJN07,GJN08,GJN09,GJO00,GJO01,GJO02,GJO03,GJO04,GJO05,GJO06,GJO07,GJO08,GJO09,';
     z := z + 'GJP00,GJP01,GJP02,GJP03,GJP04,GJP05,GJP06,GJP07,GJP08,GJP09,GJQ00,GJQ01,GJQ02,GJQ03,GJQ04,';
     z := z + 'GJQ05,GJQ06,GJQ07,GJQ08,GJQ09,GJR00,GJR01,GJR02,GJR03,GJR04,P     ,P     ,P     ,PCUSTO,PS     ,';
     z := z + 'GIA90,GIA91,GIA92,GIA93,GIA94,GIA95,GIA96,GIA97,GIA98,GIA99,GIB90,GIB91,GIB92,GIB93,GIB94,';
     z := z + 'GIB95,GIB96,GIB97,GIB98,GIB99,GIC90,GIC91,GIC92,GIC93,GIC94,GIC95,GIC96,GIC97,GIC98,GIC99,';
     z := z + 'GID90,GID91,GID92,GID93,GID94,GID95,GID96,GID97,GID98,GID99,GIE90,GIE91,GIE92,GIE93,GIE94,';
     z := z + 'GIE95,GIE96,GIE97,GIE98,GIE99,GIF90,GIF91,GIF92,GIF93,GIF94,GIF95,GIF96,GIF97,GIF98,GIF99,';
     z := z + 'GIG90,GIG91,GIG92,GIG93,GIG94,GIG95,GIG96,GIG97,GIG98,GIG99,GIH90,GIH91,GIH92,GIH93,GIH94,';
     z := z + 'GIH95,GIH96,GIH97,GIH98,GIH99,GII90,GII91,GII92,GII93,GII94,GII95,GII96,GII97,GII98,GII99,';
     z := z + 'GIJ90,GIJ91,GIJ92,GIJ93,GIJ94,GIJ95,GIJ96,GIJ97,GIJ98,GIJ99,GIK90,GIK91,GIK92,GIK93,GIK94,';
     z := z + 'GIK95,GIK96,GIK97,GIK98,GIK99,GIL90,GIL91,GIL92,GIL93,GIL94,GIL95,GIL96,GIL97,GIL98,GIL99,';
     z := z + 'GIM90,GIM91,GIM92,GIM93,GIM94,GIM95,GIM96,GIM97,GIM98,GIM99,GIN90,GIN91,GIN92,GIN93,GIN94,';
     z := z + 'GIN95,GIN96,GIN97,GIN98,GIN99,GIO90,GIO91,GIO92,GIO93,GIO94,GIO95,GIO96,GIO97,GIO98,GIO99,';
     z := z + 'GIP90,GIP91,GIP92,GIP93,GIP94,GIP95,GIP96,GIP97,GIP98,GIP99,GIQ90,GIQ91,GIQ92,GIQ93,GIQ94,';
     z := z + 'GIQ95,GIQ96,GIQ97,GIQ98,GIQ99,GIR90,GIR91,GIR92,GIR93,GIR94,S1A   ,S1S   ,S3A   ,S3B6  ,S3B8  ,';
     z := z + 'GIA80,GIA81,GIA82,GIA83,GIA84,GIA85,GIA86,GIA87,GIA88,GIA89,GIB80,GIB81,GIB82,GIB83,GIB84,';
     z := z + 'GIB85,GIB86,GIB87,GIB88,GIB89,GIC80,GIC81,GIC82,GIC83,GIC84,GIC85,GIC86,GIC87,GIC88,GIC89,';
     z := z + 'GID80,GID81,GID82,GID83,GID84,GID85,GID86,GID87,GID88,GID89,GIE80,GIE81,GIE82,GIE83,GIE84,';
     z := z + 'GIE85,GIE86,GIE87,GIE88,GIE89,GIF80,GIF81,GIF82,GIF83,GIF84,GIF85,GIF86,GIF87,GIF88,GIF89,';
     z := z + 'GIG80,GIG81,GIG82,GIG83,GIG84,GIG85,GIG86,GIG87,GIG88,GIG89,GIH80,GIH81,GIH82,GIH83,GIH84,';
     z := z + 'GIH85,GIH86,GIH87,GIH88,GIH89,GII80,GII81,GII82,GII83,GII84,GII85,GII86,GII87,GII88,GII89,';
     z := z + 'GIJ80,GIJ81,GIJ82,GIJ83,GIJ84,GIJ85,GIJ86,GIJ87,GIJ88,GIJ89,GIK80,GIK81,GIK82,GIK83,GIK84,';
     z := z + 'GIK85,GIK86,GIK87,GIK88,GIK89,GIL80,GIL81,GIL82,GIL83,GIL84,GIL85,GIL86,GIL87,GIL88,GIL89,';
     z := z + 'GIM80,GIM81,GIM82,GIM83,GIM84,GIM85,GIM86,GIM87,GIM88,GIM89,GIN80,GIN81,GIN82,GIN83,GIN84,';
     z := z + 'GIN85,GIN86,GIN87,GIN88,GIN89,GIO80,GIO81,GIO82,GIO83,GIO84,GIO85,GIO86,GIO87,GIO88,GIO89,';
     z := z + 'GIP80,GIP81,GIP82,GIP83,GIP84,GIP85,GIP86,GIP87,GIP88,GIP89,GIQ80,GIQ81,GIQ82,GIQ83,GIQ84,';
     z := z + 'GIQ85,GIQ86,GIQ87,GIQ88,GIQ89,GIR80,GIR81,GIR82,GIR83,GIR84,S3B9  ,S3C   ,S3C0  ,S3D2  ,S3D2C ,';
     z := z + 'GIA70,GIA71,GIA72,GIA73,GIA74,GIA75,GIA76,GIA77,GIA78,GIA79,GIB70,GIB71,GIB72,GIB73,GIB74,';
     z := z + 'GIB75,GIB76,GIB77,GIB78,GIB79,GIC70,GIC71,GIC72,GIC73,GIC74,GIC75,GIC76,GIC77,GIC78,GIC79,';
     z := z + 'GID70,GID71,GID72,GID73,GID74,GID75,GID76,GID77,GID78,GID79,GIE70,GIE71,GIE72,GIE73,GIE74,';
     z := z + 'GIE75,GIE76,GIE77,GIE78,GIE79,GIF70,GIF71,GIF72,GIF73,GIF74,GIF75,GIF76,GIF77,GIF78,GIF79,';
     z := z + 'GIG70,GIG71,GIG72,GIG73,GIG74,GIG75,GIG76,GIG77,GIG78,GIG79,GIH70,GIH71,GIH72,GIH73,GIH74,';
     z := z + 'GIH75,GIH76,GIH77,GIH78,GIH79,GII70,GII71,GII72,GII73,GII74,GII75,GII76,GII77,GII78,GII79,';
     z := z + 'GIJ70,GIJ71,GIJ72,GIJ73,GIJ74,GIJ75,GIJ76,GIJ77,GIJ78,GIJ79,GIK70,GIK71,GIK72,GIK73,GIK74,';
     z := z + 'GIK75,GIK76,GIK77,GIK78,GIK79,GIL70,GIL71,GIL72,GIL73,GIL74,GIL75,GIL76,GIL77,GIL78,GIL79,';
     z := z + 'GIM70,GIM71,GIM72,GIM73,GIM74,GIM75,GIM76,GIM77,GIM78,GIM79,GIN70,GIN71,GIN72,GIN73,GIN74,';
     z := z + 'GIN75,GIN76,GIN77,GIN78,GIN79,GIO70,GIO71,GIO72,GIO73,GIO74,GIO75,GIO76,GIO77,GIO78,GIO79,';
     z := z + 'GIP70,GIP71,GIP72,GIP73,GIP74,GIP75,GIP76,GIP77,GIP78,GIP79,GIQ70,GIQ71,GIQ72,GIQ73,GIQ74,';
     z := z + 'GIQ75,GIQ76,GIQ77,GIQ78,GIQ79,GIR70,GIR71,GIR72,GIR73,GIR74,S3D2R ,S3DA  ,S3V   ,S3W   ,S3X   ,';
     z := z + 'GIA60,GIA61,GIA62,GIA63,GIA64,GIA65,GIA66,GIA67,GIA68,GIA69,GIB60,GIB61,GIB62,GIB63,GIB64,';
     z := z + 'GIB65,GIB66,GIB67,GIB68,GIB69,GIC60,GIC61,GIC62,GIC63,GIC64,GIC65,GIC66,GIC67,GIC68,GIC69,';
     z := z + 'GID60,GID61,GID62,GID63,GID64,GID65,GID66,GID67,GID68,GID69,GIE60,GIE61,GIE62,GIE63,GIE64,';
     z := z + 'GIE65,GIE66,GIE67,GIE68,GIE69,GIF60,GIF61,GIF62,GIF63,GIF64,GIF65,GIF66,GIF67,GIF68,GIF69,';
     z := z + 'GIG60,GIG61,GIG62,GIG63,GIG64,GIG65,GIG66,GIG67,GIG68,GIG69,GIH60,GIH61,GIH62,GIH63,GIH64,';
     z := z + 'GIH65,GIH66,GIH67,GIH68,GIH69,GII60,GII61,GII62,GII63,GII64,GII65,GII66,GII67,GII68,GII69,';
     z := z + 'GIJ60,GIJ61,GIJ62,GIJ63,GIJ64,GIJ65,GIJ66,GIJ67,GIJ68,GIJ69,GIK60,GIK61,GIK62,GIK63,GIK64,';
     z := z + 'GIK65,GIK66,GIK67,GIK68,GIK69,GIL60,GIL61,GIL62,GIL63,GIL64,GIL65,GIL66,GIL67,GIL68,GIL69,';
     z := z + 'GIM60,GIM61,GIM62,GIM63,GIM64,GIM65,GIM66,GIM67,GIM68,GIM69,GIN60,GIN61,GIN62,GIN63,GIN64,';
     z := z + 'GIN65,GIN66,GIN67,GIN68,GIN69,GIO60,GIO61,GIO62,GIO63,GIO64,GIO65,GIO66,GIO67,GIO68,GIO69,';
     z := z + 'GIP60,GIP61,GIP62,GIP63,GIP64,GIP65,GIP66,GIP67,GIP68,GIP69,GIQ60,GIQ61,GIQ62,GIQ63,GIQ64,';
     z := z + 'GIQ65,GIQ66,GIQ67,GIQ68,GIQ69,GIR60,GIR61,GIR62,GIR63,GIR64,S3Y   ,S3YB  ,S3YP  ,S4J   ,S4L   ,';
     z := z + 'GIA50,GIA51,GIA52,GIA53,GIA54,GIA55,GIA56,GIA57,GIA58,GIA59,GIB50,GIB51,GIB52,GIB53,GIB54,';
     z := z + 'GIB55,GIB56,GIB57,GIB58,GIB59,GIC50,GIC51,GIC52,GIC53,GIC54,GIC55,GIC56,GIC57,GIC58,GIC59,';
     z := z + 'GID50,GID51,GID52,GID53,GID54,GID55,GID56,GID57,GID58,GID59,GIE50,GIE51,GIE52,GIE53,GIE54,';
     z := z + 'GIE55,GIE56,GIE57,GIE58,GIE59,GIF50,GIF51,GIF52,GIF53,GIF54,GIF55,GIF56,GIF57,GIF58,GIF59,';
     z := z + 'GIG50,GIG51,GIG52,GIG53,GIG54,GIG55,GIG56,GIG57,GIG58,GIG59,GIH50,GIH51,GIH52,GIH53,GIH54,';
     z := z + 'GIH55,GIH56,GIH57,GIH58,GIH59,GII50,GII51,GII52,GII53,GII54,GII55,GII56,GII57,GII58,GII59,';
     z := z + 'GIJ50,GIJ51,GIJ52,GIJ53,GIJ54,GIJ55,GIJ56,GIJ57,GIJ58,GIJ59,GIK50,GIK51,GIK52,GIK53,GIK54,';
     z := z + 'GIK55,GIK56,GIK57,GIK58,GIK59,GIL50,GIL51,GIL52,GIL53,GIL54,GIL55,GIL56,GIL57,GIL58,GIL59,';
     z := z + 'GIM50,GIM51,GIM52,GIM53,GIM54,GIM55,GIM56,GIM57,GIM58,GIM59,GIN50,GIN51,GIN52,GIN53,GIN54,';
     z := z + 'GIN55,GIN56,GIN57,GIN58,GIN59,GIO50,GIO51,GIO52,GIO53,GIO54,GIO55,GIO56,GIO57,GIO58,GIO59,';
     z := z + 'GIP50,GIP51,GIP52,GIP53,GIP54,GIP55,GIP56,GIP57,GIP58,GIP59,GIQ50,GIQ51,GIQ52,GIQ53,GIQ54,';
     z := z + 'GIQ55,GIQ56,GIQ57,GIQ58,GIQ59,GIR50,GIR51,GIR52,GIR53,GIR54,S4S   ,S4U1I ,S4U1U ,S4W   ,S4X   ,';
     z := z + 'GIA40,GIA41,GIA42,GIA43,GIA44,GIA45,GIA46,GIA47,GIA48,GIA49,GIB40,GIB41,GIB42,GIB43,GIB44,';
     z := z + 'GIB45,GIB46,GIB47,GIB48,GIB49,GIC40,GIC41,GIC42,GIC43,GIC44,GIC45,GIC46,GIC47,GIC48,GIC49,';
     z := z + 'GID40,GID41,GID42,GID43,GID44,GID45,GID46,GID47,GID48,GID49,GIE40,GIE41,GIE42,GIE43,GIE44,';
     z := z + 'GIE45,GIE46,GIE47,GIE48,GIE49,GIF40,GIF41,GIF42,GIF43,GIF44,GIF45,GIF46,GIF47,GIF48,GIF49,';
     z := z + 'GIG40,GIG41,GIG42,GIG43,GIG44,GIG45,GIG46,GIG47,GIG48,GIG49,GIH40,GIH41,GIH42,GIH43,GIH44,';
     z := z + 'GIH45,GIH46,GIH47,GIH48,GIH49,GII40,GII41,GII42,GII43,GII44,GII45,GII46,GII47,GII48,GII49,';
     z := z + 'GIJ40,GIJ41,GIJ42,GIJ43,GIJ44,GIJ45,GIJ46,GIJ47,GIJ48,GIJ49,GIK40,GIK41,GIK42,GIK43,GIK44,';
     z := z + 'GIK45,GIK46,GIK47,GIK48,GIK49,GIL40,GIL41,GIL42,GIL43,GIL44,GIL45,GIL46,GIL47,GIL48,GIL49,';
     z := z + 'GIM40,GIM41,GIM42,GIM43,GIM44,GIM45,GIM46,GIM47,GIM48,GIM49,GIN40,GIN41,GIN42,GIN43,GIN44,';
     z := z + 'GIN45,GIN46,GIN47,GIN48,GIN49,GIO40,GIO41,GIO42,GIO43,GIO44,GIO45,GIO46,GIO47,GIO48,GIO49,';
     z := z + 'GIP40,GIP41,GIP42,GIP43,GIP44,GIP45,GIP46,GIP47,GIP48,GIP49,GIQ40,GIQ41,GIQ42,GIQ43,GIQ44,';
     z := z + 'GIQ45,GIQ46,GIQ47,GIQ48,GIQ49,GIR40,GIR41,GIR42,GIR43,GIR44,S5A   ,S5B   ,S5H   ,S5N   ,S5R   ,';
     z := z + 'GIA30,GIA31,GIA32,GIA33,GIA34,GIA35,GIA36,GIA37,GIA38,GIA39,GIB30,GIB31,GIB32,GIB33,GIB34,';
     z := z + 'GIB35,GIB36,GIB37,GIB38,GIB39,GIC30,GIC31,GIC32,GIC33,GIC34,GIC35,GIC36,GIC37,GIC38,GIC39,';
     z := z + 'GID30,GID31,GID32,GID33,GID34,GID35,GID36,GID37,GID38,GID39,GIE30,GIE31,GIE32,GIE33,GIE34,';
     z := z + 'GIE35,GIE36,GIE37,GIE38,GIE39,GIF30,GIF31,GIF32,GIF33,GIF34,GIF35,GIF36,GIF37,GIF38,GIF39,';
     z := z + 'GIG30,GIG31,GIG32,GIG33,GIG34,GIG35,GIG36,GIG37,GIG38,GIG39,GIH30,GIH31,GIH32,GIH33,GIH34,';
     z := z + 'GIH35,GIH36,GIH37,GIH38,GIH39,GII30,GII31,GII32,GII33,GII34,GII35,GII36,GII37,GII38,GII39,';
     z := z + 'GIJ30,GIJ31,GIJ32,GIJ33,GIJ34,GIJ35,GIJ36,GIJ37,GIJ38,GIJ39,GIK30,GIK31,GIK32,GIK33,GIK34,';
     z := z + 'GIK35,GIK36,GIK37,GIK38,GIK39,GIL30,GIL31,GIL32,GIL33,GIL34,GIL35,GIL36,GIL37,GIL38,GIL39,';
     z := z + 'GIM30,GIM31,GIM32,GIM33,GIM34,GIM35,GIM36,GIM37,GIM38,GIM39,GIN30,GIN31,GIN32,GIN33,GIN34,';
     z := z + 'GIN35,GIN36,GIN37,GIN38,GIN39,GIO30,GIO31,GIO32,GIO33,GIO34,GIO35,GIO36,GIO37,GIO38,GIO39,';
     z := z + 'GIP30,GIP31,GIP32,GIP33,GIP34,GIP35,GIP36,GIP37,GIP38,GIP39,GIQ30,GIQ31,GIQ32,GIQ33,GIQ34,';
     z := z + 'GIQ35,GIQ36,GIQ37,GIQ38,GIQ39,GIR30,GIR31,GIR32,GIR33,GIR34,S5T   ,S5U   ,S5V   ,S5W   ,S5X   ,';
     z := z + 'GIA20,GIA21,GIA22,GIA23,GIA24,GIA25,GIA26,GIA27,GIA28,GIA29,GIB20,GIB21,GIB22,GIB23,GIB24,';
     z := z + 'GIB25,GIB26,GIB27,GIB28,GIB29,GIC20,GIC21,GIC22,GIC23,GIC24,GIC25,GIC26,GIC27,GIC28,GIC29,';
     z := z + 'GID20,GID21,GID22,GID23,GID24,GID25,GID26,GID27,GID28,GID29,GIE20,GIE21,GIE22,GIE23,GIE24,';
     z := z + 'GIE25,GIE26,GIE27,GIE28,GIE29,GIF20,GIF21,GIF22,GIF23,GIF24,GIF25,GIF26,GIF27,GIF28,GIF29,';
     z := z + 'GIG20,GIG21,GIG22,GIG23,GIG24,GIG25,GIG26,GIG27,GIG28,GIG29,GIH20,GIH21,GIH22,GIH23,GIH24,';
     z := z + 'GIH25,GIH26,GIH27,GIH28,GIH29,GII20,GII21,GII22,GII23,GII24,GII25,GII26,GII27,GII28,GII29,';
     z := z + 'GIJ20,GIJ21,GIJ22,GIJ23,GIJ24,GIJ25,GIJ26,GIJ27,GIJ28,GIJ29,GIK20,GIK21,GIK22,GIK23,GIK24,';
     z := z + 'GIK25,GIK26,GIK27,GIK28,GIK29,GIL20,GIL21,GIL22,GIL23,GIL24,GIL25,GIL26,GIL27,GIL28,GIL29,';
     z := z + 'GIM20,GIM21,GIM22,GIM23,GIM24,GIM25,GIM26,GIM27,GIM28,GIM29,GIN20,GIN21,GIN22,GIN23,GIN24,';
     z := z + 'GIN25,GIN26,GIN27,GIN28,GIN29,GIO20,GIO21,GIO22,GIO23,GIO24,GIO25,GIO26,GIO27,GIO28,GIO29,';
     z := z + 'GIP20,GIP21,GIP22,GIP23,GIP24,GIP25,GIP26,GIP27,GIP28,GIP29,GIQ20,GIQ21,GIQ22,GIQ23,GIQ24,';
     z := z + 'GIQ25,GIQ26,GIQ27,GIQ28,GIQ29,GIR20,GIR21,GIR22,GIR23,GIR24,S5Z   ,S6W   ,S6Y   ,S7O   ,S7P   ,';
     z := z + 'GIA10,GIA11,GIA12,GIA13,GIA14,GIA15,GIA16,GIA17,GIA18,GIA19,GIB10,GIB11,GIB12,GIB13,GIB14,';
     z := z + 'GIB15,GIB16,GIB17,GIB18,GIB19,GIC10,GIC11,GIC12,GIC13,GIC14,GIC15,GIC16,GIC17,GIC18,GIC19,';
     z := z + 'GID10,GID11,GID12,GID13,GID14,GID15,GID16,GID17,GID18,GID19,GIE10,GIE11,GIE12,GIE13,GIE14,';
     z := z + 'GIE15,GIE16,GIE17,GIE18,GIE19,GIF10,GIF11,GIF12,GIF13,GIF14,GIF15,GIF16,GIF17,GIF18,GIF19,';
     z := z + 'GIG10,GIG11,GIG12,GIG13,GIG14,GIG15,GIG16,GIG17,GIG18,GIG19,GIH10,GIH11,GIH12,GIH13,GIH14,';
     z := z + 'GIH15,GIH16,GIH17,GIH18,GIH19,GII10,GII11,GII12,GII13,GII14,GII15,GII16,GII17,GII18,GII19,';
     z := z + 'GIJ10,GIJ11,GIJ12,GIJ13,GIJ14,GIJ15,GIJ16,GIJ17,GIJ18,GIJ19,GIK10,GIK11,GIK12,GIK13,GIK14,';
     z := z + 'GIK15,GIK16,GIK17,GIK18,GIK19,GIL10,GIL11,GIL12,GIL13,GIL14,GIL15,GIL16,GIL17,GIL18,GIL19,';
     z := z + 'GIM10,GIM11,GIM12,GIM13,GIM14,GIM15,GIM16,GIM17,GIM18,GIM19,GIN10,GIN11,GIN12,GIN13,GIN14,';
     z := z + 'GIN15,GIN16,GIN17,GIN18,GIN19,GIO10,GIO11,GIO12,GIO13,GIO14,GIO15,GIO16,GIO17,GIO18,GIO19,';
     z := z + 'GIP10,GIP11,GIP12,GIP13,GIP14,GIP15,GIP16,GIP17,GIP18,GIP19,GIQ10,GIQ11,GIQ12,GIQ13,GIQ14,';
     z := z + 'GIQ15,GIQ16,GIQ17,GIQ18,GIQ19,GIR10,GIR11,GIR12,GIR13,GIR14,S7Q   ,S7X   ,S8P   ,S8Q   ,S8R   ,';
     z := z + 'GIA00,GIA01,GIA02,GIA03,GIA04,GIA05,GIA06,GIA07,GIA08,GIA09,GIB00,GIB01,GIB02,GIB03,GIB04,';
     z := z + 'GIB05,GIB06,GIB07,GIB08,GIB09,GIC00,GIC01,GIC02,GIC03,GIC04,GIC05,GIC06,GIC07,GIC08,GIC09,';
     z := z + 'GID00,GID01,GID02,GID03,GID04,GID05,GID06,GID07,GID08,GID09,GIE00,GIE01,GIE02,GIE03,GIE04,';
     z := z + 'GIE05,GIE06,GIE07,GIE08,GIE09,GIF00,GIF01,GIF02,GIF03,GIF04,GIF05,GIF06,GIF07,GIF08,GIF09,';
     z := z + 'GIG00,GIG01,GIG02,GIG03,GIG04,GIG05,GIG06,GIG07,GIG08,GIG09,GIH00,GIH01,GIH02,GIH03,GIH04,';
     z := z + 'GIH05,GIH06,GIH07,GIH08,GIH09,GII00,GII01,GII02,GII03,GII04,GII05,GII06,GII07,GII08,GII09,';
     z := z + 'GIJ00,GIJ01,GIJ02,GIJ03,GIJ04,GIJ05,GIJ06,GIJ07,GIJ08,GIJ09,GIK00,GIK01,GIK02,GIK03,GIK04,';
     z := z + 'GIK05,GIK06,GIK07,GIK08,GIK09,GIL00,GIL01,GIL02,GIL03,GIL04,GIL05,GIL06,GIL07,GIL08,GIL09,';
     z := z + 'GIM00,GIM01,GIM02,GIM03,GIM04,GIM05,GIM06,GIM07,GIM08,GIM09,GIN00,GIN01,GIN02,GIN03,GIN04,';
     z := z + 'GIN05,GIN06,GIN07,GIN08,GIN09,GIO00,GIO01,GIO02,GIO03,GIO04,GIO05,GIO06,GIO07,GIO08,GIO09,';
     z := z + 'GIP00,GIP01,GIP02,GIP03,GIP04,GIP05,GIP06,GIP07,GIP08,GIP09,GIQ00,GIQ01,GIQ02,GIQ03,GIQ04,';
     z := z + 'GIQ05,GIQ06,GIQ07,GIQ08,GIQ09,GIR00,GIR01,GIR02,GIR03,GIR04,S9A   ,S9G   ,S9H   ,S9J   ,S9K   ,';
     z := z + 'GHA90,GHA91,GHA92,GHA93,GHA94,GHA95,GHA96,GHA97,GHA98,GHA99,GHB90,GHB91,GHB92,GHB93,GHB94,';
     z := z + 'GHB95,GHB96,GHB97,GHB98,GHB99,GHC90,GHC91,GHC92,GHC93,GHC94,GHC95,GHC96,GHC97,GHC98,GHC99,';
     z := z + 'GHD90,GHD91,GHD92,GHD93,GHD94,GHD95,GHD96,GHD97,GHD98,GHD99,GHE90,GHE91,GHE92,GHE93,GHE94,';
     z := z + 'GHE95,GHE96,GHE97,GHE98,GHE99,GHF90,GHF91,GHF92,GHF93,GHF94,GHF95,GHF96,GHF97,GHF98,GHF99,';
     z := z + 'GHG90,GHG91,GHG92,GHG93,GHG94,GHG95,GHG96,GHG97,GHG98,GHG99,GHH90,GHH91,GHH92,GHH93,GHH94,';
     z := z + 'GHH95,GHH96,GHH97,GHH98,GHH99,GHI90,GHI91,GHI92,GHI93,GHI94,GHI95,GHI96,GHI97,GHI98,GHI99,';
     z := z + 'GHJ90,GHJ91,GHJ92,GHJ93,GHJ94,GHJ95,GHJ96,GHJ97,GHJ98,GHJ99,GHK90,GHK91,GHK92,GHK93,GHK94,';
     z := z + 'GHK95,GHK96,GHK97,GHK98,GHK99,GHL90,GHL91,GHL92,GHL93,GHL94,GHL95,GHL96,GHL97,GHL98,GHL99,';
     z := z + 'GHM90,GHM91,GHM92,GHM93,GHM94,GHM95,GHM96,GHM97,GHM98,GHM99,GHN90,GHN91,GHN92,GHN93,GHN94,';
     z := z + 'GHN95,GHN96,GHN97,GHN98,GHN99,GHO90,GHO91,GHO92,GHO93,GHO94,GHO95,GHO96,GHO97,GHO98,GHO99,';
     z := z + 'GHP90,GHP91,GHP92,GHP93,GHP94,GHP95,GHP96,GHP97,GHP98,GHP99,GHQ90,GHQ91,GHQ92,GHQ93,GHQ94,';
     z := z + 'GHQ95,GHQ96,GHQ97,GHQ98,GHQ99,GHR90,GHR91,GHR92,GHR93,GHR94,S9L   ,S9M2  ,S9M6  ,S9N   ,S9Q   ,';
     z := z + 'GHA80,GHA81,GHA82,GHA83,GHA84,GHA85,GHA86,GHA87,GHA88,GHA89,GHB80,GHB81,GHB82,GHB83,GHB84,';
     z := z + 'GHB85,GHB86,GHB87,GHB88,GHB89,GHC80,GHC81,GHC82,GHC83,GHC84,GHC85,GHC86,GHC87,GHC88,GHC89,';
     z := z + 'GHD80,GHD81,GHD82,GHD83,GHD84,GHD85,GHD86,GHD87,GHD88,GHD89,GHE80,GHE81,GHE82,GHE83,GHE84,';
     z := z + 'GHE85,GHE86,GHE87,GHE88,GHE89,GHF80,GHF81,GHF82,GHF83,GHF84,GHF85,GHF86,GHF87,GHF88,GHF89,';
     z := z + 'GHG80,GHG81,GHG82,GHG83,GHG84,GHG85,GHG86,GHG87,GHG88,GHG89,GHH80,GHH81,GHH82,GHH83,GHH84,';
     z := z + 'GHH85,GHH86,GHH87,GHH88,GHH89,GHI80,GHI81,GHI82,GHI83,GHI84,GHI85,GHI86,GHI87,GHI88,GHI89,';
     z := z + 'GHJ80,GHJ81,GHJ82,GHJ83,GHJ84,GHJ85,GHJ86,GHJ87,GHJ88,GHJ89,GHK80,GHK81,GHK82,GHK83,GHK84,';
     z := z + 'GHK85,GHK86,GHK87,GHK88,GHK89,GHL80,GHL81,GHL82,GHL83,GHL84,GHL85,GHL86,GHL87,GHL88,GHL89,';
     z := z + 'GHM80,GHM81,GHM82,GHM83,GHM84,GHM85,GHM86,GHM87,GHM88,GHM89,GHN80,GHN81,GHN82,GHN83,GHN84,';
     z := z + 'GHN85,GHN86,GHN87,GHN88,GHN89,GHO80,GHO81,GHO82,GHO83,GHO84,GHO85,GHO86,GHO87,GHO88,GHO89,';
     z := z + 'GHP80,GHP81,GHP82,GHP83,GHP84,GHP85,GHP86,GHP87,GHP88,GHP89,GHQ80,GHQ81,GHQ82,GHQ83,GHQ84,';
     z := z + 'GHQ85,GHQ86,GHQ87,GHQ88,GHQ89,GHR80,GHR81,GHR82,GHR83,GHR84,S9U   ,S9V   ,S9X   ,S9Y   ,SA2   ,';
     z := z + 'GHA70,GHA71,GHA72,GHA73,GHA74,GHA75,GHA76,GHA77,GHA78,GHA79,GHB70,GHB71,GHB72,GHB73,GHB74,';
     z := z + 'GHB75,GHB76,GHB77,GHB78,GHB79,GHC70,GHC71,GHC72,GHC73,GHC74,GHC75,GHC76,GHC77,GHC78,GHC79,';
     z := z + 'GHD70,GHD71,GHD72,GHD73,GHD74,GHD75,GHD76,GHD77,GHD78,GHD79,GHE70,GHE71,GHE72,GHE73,GHE74,';
     z := z + 'GHE75,GHE76,GHE77,GHE78,GHE79,GHF70,GHF71,GHF72,GHF73,GHF74,GHF75,GHF76,GHF77,GHF78,GHF79,';
     z := z + 'GHG70,GHG71,GHG72,GHG73,GHG74,GHG75,GHG76,GHG77,GHG78,GHG79,GHH70,GHH71,GHH72,GHH73,GHH74,';
     z := z + 'GHH75,GHH76,GHH77,GHH78,GHH79,GHI70,GHI71,GHI72,GHI73,GHI74,GHI75,GHI76,GHI77,GHI78,GHI79,';
     z := z + 'GHJ70,GHJ71,GHJ72,GHJ73,GHJ74,GHJ75,GHJ76,GHJ77,GHJ78,GHJ79,GHK70,GHK71,GHK72,GHK73,GHK74,';
     z := z + 'GHK75,GHK76,GHK77,GHK78,GHK79,GHL70,GHL71,GHL72,GHL73,GHL74,GHL75,GHL76,GHL77,GHL78,GHL79,';
     z := z + 'GHM70,GHM71,GHM72,GHM73,GHM74,GHM75,GHM76,GHM77,GHM78,GHM79,GHN70,GHN71,GHN72,GHN73,GHN74,';
     z := z + 'GHN75,GHN76,GHN77,GHN78,GHN79,GHO70,GHO71,GHO72,GHO73,GHO74,GHO75,GHO76,GHO77,GHO78,GHO79,';
     z := z + 'GHP70,GHP71,GHP72,GHP73,GHP74,GHP75,GHP76,GHP77,GHP78,GHP79,GHQ70,GHQ71,GHQ72,GHQ73,GHQ74,';
     z := z + 'GHQ75,GHQ76,GHQ77,GHQ78,GHQ79,GHR70,GHR71,GHR72,GHR73,GHR74,SA3   ,SA4   ,SA5   ,SA6   ,SA7   ,';
     z := z + 'GHA60,GHA61,GHA62,GHA63,GHA64,GHA65,GHA66,GHA67,GHA68,GHA69,GHB60,GHB61,GHB62,GHB63,GHB64,';
     z := z + 'GHB65,GHB66,GHB67,GHB68,GHB69,GHC60,GHC61,GHC62,GHC63,GHC64,GHC65,GHC66,GHC67,GHC68,GHC69,';
     z := z + 'GHD60,GHD61,GHD62,GHD63,GHD64,GHD65,GHD66,GHD67,GHD68,GHD69,GHE60,GHE61,GHE62,GHE63,GHE64,';
     z := z + 'GHE65,GHE66,GHE67,GHE68,GHE69,GHF60,GHF61,GHF62,GHF63,GHF64,GHF65,GHF66,GHF67,GHF68,GHF69,';
     z := z + 'GHG60,GHG61,GHG62,GHG63,GHG64,GHG65,GHG66,GHG67,GHG68,GHG69,GHH60,GHH61,GHH62,GHH63,GHH64,';
     z := z + 'GHH65,GHH66,GHH67,GHH68,GHH69,GHI60,GHI61,GHI62,GHI63,GHI64,GHI65,GHI66,GHI67,GHI68,GHI69,';
     z := z + 'GHJ60,GHJ61,GHJ62,GHJ63,GHJ64,GHJ65,GHJ66,GHJ67,GHJ68,GHJ69,GHK60,GHK61,GHK62,GHK63,GHK64,';
     z := z + 'GHK65,GHK66,GHK67,GHK68,GHK69,GHL60,GHL61,GHL62,GHL63,GHL64,GHL65,GHL66,GHL67,GHL68,GHL69,';
     z := z + 'GHM60,GHM61,GHM62,GHM63,GHM64,GHM65,GHM66,GHM67,GHM68,GHM69,GHN60,GHN61,GHN62,GHN63,GHN64,';
     z := z + 'GHN65,GHN66,GHN67,GHN68,GHN69,GHO60,GHO61,GHO62,GHO63,GHO64,GHO65,GHO66,GHO67,GHO68,GHO69,';
     z := z + 'GHP60,GHP61,GHP62,GHP63,GHP64,GHP65,GHP66,GHP67,GHP68,GHP69,GHQ60,GHQ61,GHQ62,GHQ63,GHQ64,';
     z := z + 'GHQ65,GHQ66,GHQ67,GHQ68,GHQ69,GHR60,GHR61,GHR62,GHR63,GHR64,SA9   ,SAP   ,SBS7  ,SBV   ,SBV9  ,';
     z := z + 'GHA50,GHA51,GHA52,GHA53,GHA54,GHA55,GHA56,GHA57,GHA58,GHA59,GHB50,GHB51,GHB52,GHB53,GHB54,';
     z := z + 'GHB55,GHB56,GHB57,GHB58,GHB59,GHC50,GHC51,GHC52,GHC53,GHC54,GHC55,GHC56,GHC57,GHC58,GHC59,';
     z := z + 'GHD50,GHD51,GHD52,GHD53,GHD54,GHD55,GHD56,GHD57,GHD58,GHD59,GHE50,GHE51,GHE52,GHE53,GHE54,';
     z := z + 'GHE55,GHE56,GHE57,GHE58,GHE59,GHF50,GHF51,GHF52,GHF53,GHF54,GHF55,GHF56,GHF57,GHF58,GHF59,';
     z := z + 'GHG50,GHG51,GHG52,GHG53,GHG54,GHG55,GHG56,GHG57,GHG58,GHG59,GHH50,GHH51,GHH52,GHH53,GHH54,';
     z := z + 'GHH55,GHH56,GHH57,GHH58,GHH59,GHI50,GHI51,GHI52,GHI53,GHI54,GHI55,GHI56,GHI57,GHI58,GHI59,';
     z := z + 'GHJ50,GHJ51,GHJ52,GHJ53,GHJ54,GHJ55,GHJ56,GHJ57,GHJ58,GHJ59,GHK50,GHK51,GHK52,GHK53,GHK54,';
     z := z + 'GHK55,GHK56,GHK57,GHK58,GHK59,GHL50,GHL51,GHL52,GHL53,GHL54,GHL55,GHL56,GHL57,GHL58,GHL59,';
     z := z + 'GHM50,GHM51,GHM52,GHM53,GHM54,GHM55,GHM56,GHM57,GHM58,GHM59,GHN50,GHN51,GHN52,GHN53,GHN54,';
     z := z + 'GHN55,GHN56,GHN57,GHN58,GHN59,GHO50,GHO51,GHO52,GHO53,GHO54,GHO55,GHO56,GHO57,GHO58,GHO59,';
     z := z + 'GHP50,GHP51,GHP52,GHP53,GHP54,GHP55,GHP56,GHP57,GHP58,GHP59,GHQ50,GHQ51,GHQ52,GHQ53,GHQ54,';
     z := z + 'GHQ55,GHQ56,GHQ57,GHQ58,GHQ59,GHR50,GHR51,GHR52,GHR53,GHR54,SBY   ,SC2   ,SC3   ,SC5   ,SC6   ,';
     z := z + 'GHA40,GHA41,GHA42,GHA43,GHA44,GHA45,GHA46,GHA47,GHA48,GHA49,GHB40,GHB41,GHB42,GHB43,GHB44,';
     z := z + 'GHB45,GHB46,GHB47,GHB48,GHB49,GHC40,GHC41,GHC42,GHC43,GHC44,GHC45,GHC46,GHC47,GHC48,GHC49,';
     z := z + 'GHD40,GHD41,GHD42,GHD43,GHD44,GHD45,GHD46,GHD47,GHD48,GHD49,GHE40,GHE41,GHE42,GHE43,GHE44,';
     z := z + 'GHE45,GHE46,GHE47,GHE48,GHE49,GHF40,GHF41,GHF42,GHF43,GHF44,GHF45,GHF46,GHF47,GHF48,GHF49,';
     z := z + 'GHG40,GHG41,GHG42,GHG43,GHG44,GHG45,GHG46,GHG47,GHG48,GHG49,GHH40,GHH41,GHH42,GHH43,GHH44,';
     z := z + 'GHH45,GHH46,GHH47,GHH48,GHH49,GHI40,GHI41,GHI42,GHI43,GHI44,GHI45,GHI46,GHI47,GHI48,GHI49,';
     z := z + 'GHJ40,GHJ41,GHJ42,GHJ43,GHJ44,GHJ45,GHJ46,GHJ47,GHJ48,GHJ49,GHK40,GHK41,GHK42,GHK43,GHK44,';
     z := z + 'GHK45,GHK46,GHK47,GHK48,GHK49,GHL40,GHL41,GHL42,GHL43,GHL44,GHL45,GHL46,GHL47,GHL48,GHL49,';
     z := z + 'GHM40,GHM41,GHM42,GHM43,GHM44,GHM45,GHM46,GHM47,GHM48,GHM49,GHN40,GHN41,GHN42,GHN43,GHN44,';
     z := z + 'GHN45,GHN46,GHN47,GHN48,GHN49,GHO40,GHO41,GHO42,GHO43,GHO44,GHO45,GHO46,GHO47,GHO48,GHO49,';
     z := z + 'GHP40,GHP41,GHP42,GHP43,GHP44,GHP45,GHP46,GHP47,GHP48,GHP49,GHQ40,GHQ41,GHQ42,GHQ43,GHQ44,';
     z := z + 'GHQ45,GHQ46,GHQ47,GHQ48,GHQ49,GHR40,GHR41,GHR42,GHR43,GHR44,SC9   ,SCE   ,SCE0X ,SCE0Y ,SCE0Z ,';
     z := z + 'GHA30,GHA31,GHA32,GHA33,GHA34,GHA35,GHA36,GHA37,GHA38,GHA39,GHB30,GHB31,GHB32,GHB33,GHB34,';
     z := z + 'GHB35,GHB36,GHB37,GHB38,GHB39,GHC30,GHC31,GHC32,GHC33,GHC34,GHC35,GHC36,GHC37,GHC38,GHC39,';
     z := z + 'GHD30,GHD31,GHD32,GHD33,GHD34,GHD35,GHD36,GHD37,GHD38,GHD39,GHE30,GHE31,GHE32,GHE33,GHE34,';
     z := z + 'GHE35,GHE36,GHE37,GHE38,GHE39,GHF30,GHF31,GHF32,GHF33,GHF34,GHF35,GHF36,GHF37,GHF38,GHF39,';
     z := z + 'GHG30,GHG31,GHG32,GHG33,GHG34,GHG35,GHG36,GHG37,GHG38,GHG39,GHH30,GHH31,GHH32,GHH33,GHH34,';
     z := z + 'GHH35,GHH36,GHH37,GHH38,GHH39,GHI30,GHI31,GHI32,GHI33,GHI34,GHI35,GHI36,GHI37,GHI38,GHI39,';
     z := z + 'GHJ30,GHJ31,GHJ32,GHJ33,GHJ34,GHJ35,GHJ36,GHJ37,GHJ38,GHJ39,GHK30,GHK31,GHK32,GHK33,GHK34,';
     z := z + 'GHK35,GHK36,GHK37,GHK38,GHK39,GHL30,GHL31,GHL32,GHL33,GHL34,GHL35,GHL36,GHL37,GHL38,GHL39,';
     z := z + 'GHM30,GHM31,GHM32,GHM33,GHM34,GHM35,GHM36,GHM37,GHM38,GHM39,GHN30,GHN31,GHN32,GHN33,GHN34,';
     z := z + 'GHN35,GHN36,GHN37,GHN38,GHN39,GHO30,GHO31,GHO32,GHO33,GHO34,GHO35,GHO36,GHO37,GHO38,GHO39,';
     z := z + 'GHP30,GHP31,GHP32,GHP33,GHP34,GHP35,GHP36,GHP37,GHP38,GHP39,GHQ30,GHQ31,GHQ32,GHQ33,GHQ34,';
     z := z + 'GHQ35,GHQ36,GHQ37,GHQ38,GHQ39,GHR30,GHR31,GHR32,GHR33,GHR34,SCE9  ,SCM   ,SCN   ,SCP   ,SCT   ,';
     z := z + 'GHA20,GHA21,GHA22,GHA23,GHA24,GHA25,GHA26,GHA27,GHA28,GHA29,GHB20,GHB21,GHB22,GHB23,GHB24,';
     z := z + 'GHB25,GHB26,GHB27,GHB28,GHB29,GHC20,GHC21,GHC22,GHC23,GHC24,GHC25,GHC26,GHC27,GHC28,GHC29,';
     z := z + 'GHD20,GHD21,GHD22,GHD23,GHD24,GHD25,GHD26,GHD27,GHD28,GHD29,GHE20,GHE21,GHE22,GHE23,GHE24,';
     z := z + 'GHE25,GHE26,GHE27,GHE28,GHE29,GHF20,GHF21,GHF22,GHF23,GHF24,GHF25,GHF26,GHF27,GHF28,GHF29,';
     z := z + 'GHG20,GHG21,GHG22,GHG23,GHG24,GHG25,GHG26,GHG27,GHG28,GHG29,GHH20,GHH21,GHH22,GHH23,GHH24,';
     z := z + 'GHH25,GHH26,GHH27,GHH28,GHH29,GHI20,GHI21,GHI22,GHI23,GHI24,GHI25,GHI26,GHI27,GHI28,GHI29,';
     z := z + 'GHJ20,GHJ21,GHJ22,GHJ23,GHJ24,GHJ25,GHJ26,GHJ27,GHJ28,GHJ29,GHK20,GHK21,GHK22,GHK23,GHK24,';
     z := z + 'GHK25,GHK26,GHK27,GHK28,GHK29,GHL20,GHL21,GHL22,GHL23,GHL24,GHL25,GHL26,GHL27,GHL28,GHL29,';
     z := z + 'GHM20,GHM21,GHM22,GHM23,GHM24,GHM25,GHM26,GHM27,GHM28,GHM29,GHN20,GHN21,GHN22,GHN23,GHN24,';
     z := z + 'GHN25,GHN26,GHN27,GHN28,GHN29,GHO20,GHO21,GHO22,GHO23,GHO24,GHO25,GHO26,GHO27,GHO28,GHO29,';
     z := z + 'GHP20,GHP21,GHP22,GHP23,GHP24,GHP25,GHP26,GHP27,GHP28,GHP29,GHQ20,GHQ21,GHQ22,GHQ23,GHQ24,';
     z := z + 'GHQ25,GHQ26,GHQ27,GHQ28,GHQ29,GHR20,GHR21,GHR22,GHR23,GHR24,SCT3  ,SCU   ,SCX   ,SCY0  ,SCY9  ,';
     z := z + 'GHA10,GHA11,GHA12,GHA13,GHA14,GHA15,GHA16,GHA17,GHA18,GHA19,GHB10,GHB11,GHB12,GHB13,GHB14,';
     z := z + 'GHB15,GHB16,GHB17,GHB18,GHB19,GHC10,GHC11,GHC12,GHC13,GHC14,GHC15,GHC16,GHC17,GHC18,GHC19,';
     z := z + 'GHD10,GHD11,GHD12,GHD13,GHD14,GHD15,GHD16,GHD17,GHD18,GHD19,GHE10,GHE11,GHE12,GHE13,GHE14,';
     z := z + 'GHE15,GHE16,GHE17,GHE18,GHE19,GHF10,GHF11,GHF12,GHF13,GHF14,GHF15,GHF16,GHF17,GHF18,GHF19,';
     z := z + 'GHG10,GHG11,GHG12,GHG13,GHG14,GHG15,GHG16,GHG17,GHG18,GHG19,GHH10,GHH11,GHH12,GHH13,GHH14,';
     z := z + 'GHH15,GHH16,GHH17,GHH18,GHH19,GHI10,GHI11,GHI12,GHI13,GHI14,GHI15,GHI16,GHI17,GHI18,GHI19,';
     z := z + 'GHJ10,GHJ11,GHJ12,GHJ13,GHJ14,GHJ15,GHJ16,GHJ17,GHJ18,GHJ19,GHK10,GHK11,GHK12,GHK13,GHK14,';
     z := z + 'GHK15,GHK16,GHK17,GHK18,GHK19,GHL10,GHL11,GHL12,GHL13,GHL14,GHL15,GHL16,GHL17,GHL18,GHL19,';
     z := z + 'GHM10,GHM11,GHM12,GHM13,GHM14,GHM15,GHM16,GHM17,GHM18,GHM19,GHN10,GHN11,GHN12,GHN13,GHN14,';
     z := z + 'GHN15,GHN16,GHN17,GHN18,GHN19,GHO10,GHO11,GHO12,GHO13,GHO14,GHO15,GHO16,GHO17,GHO18,GHO19,';
     z := z + 'GHP10,GHP11,GHP12,GHP13,GHP14,GHP15,GHP16,GHP17,GHP18,GHP19,GHQ10,GHQ11,GHQ12,GHQ13,GHQ14,';
     z := z + 'GHQ15,GHQ16,GHQ17,GHQ18,GHQ19,GHR10,GHR11,GHR12,GHR13,GHR14,SD2   ,SD4   ,SD6   ,SDL   ,SDU   ,';
     z := z + 'GHA00,GHA01,GHA02,GHA03,GHA04,GHA05,GHA06,GHA07,GHA08,GHA09,GHB00,GHB01,GHB02,GHB03,GHB04,';
     z := z + 'GHB05,GHB06,GHB07,GHB08,GHB09,GHC00,GHC01,GHC02,GHC03,GHC04,GHC05,GHC06,GHC07,GHC08,GHC09,';
     z := z + 'GHD00,GHD01,GHD02,GHD03,GHD04,GHD05,GHD06,GHD07,GHD08,GHD09,GHE00,GHE01,GHE02,GHE03,GHE04,';
     z := z + 'GHE05,GHE06,GHE07,GHE08,GHE09,GHF00,GHF01,GHF02,GHF03,GHF04,GHF05,GHF06,GHF07,GHF08,GHF09,';
     z := z + 'GHG00,GHG01,GHG02,GHG03,GHG04,GHG05,GHG06,GHG07,GHG08,GHG09,GHH00,GHH01,GHH02,GHH03,GHH04,';
     z := z + 'GHH05,GHH06,GHH07,GHH08,GHH09,GHI00,GHI01,GHI02,GHI03,GHI04,GHI05,GHI06,GHI07,GHI08,GHI09,';
     z := z + 'GHJ00,GHJ01,GHJ02,GHJ03,GHJ04,GHJ05,GHJ06,GHJ07,GHJ08,GHJ09,GHK00,GHK01,GHK02,GHK03,GHK04,';
     z := z + 'GHK05,GHK06,GHK07,GHK08,GHK09,GHL00,GHL01,GHL02,GHL03,GHL04,GHL05,GHL06,GHL07,GHL08,GHL09,';
     z := z + 'GHM00,GHM01,GHM02,GHM03,GHM04,GHM05,GHM06,GHM07,GHM08,GHM09,GHN00,GHN01,GHN02,GHN03,GHN04,';
     z := z + 'GHN05,GHN06,GHN07,GHN08,GHN09,GHO00,GHO01,GHO02,GHO03,GHO04,GHO05,GHO06,GHO07,GHO08,GHO09,';
     z := z + 'GHP00,GHP01,GHP02,GHP03,GHP04,GHP05,GHP06,GHP07,GHP08,GHP09,GHQ00,GHQ01,GHQ02,GHQ03,GHQ04,';
     z := z + 'GHQ05,GHQ06,GHQ07,GHQ08,GHQ09,GHR00,GHR01,GHR02,GHR03,GHR04,SE3   ,SE4   ,SEA   ,SEA6  ,SEA8  ,';
     z := z + 'GGA90,GGA91,GGA92,GGA93,GGA94,GGA95,GGA96,GGA97,GGA98,GGA99,GGB90,GGB91,GGB92,GGB93,GGB94,';
     z := z + 'GGB95,GGB96,GGB97,GGB98,GGB99,GGC90,GGC91,GGC92,GGC93,GGC94,GGC95,GGC96,GGC97,GGC98,GGC99,';
     z := z + 'GGD90,GGD91,GGD92,GGD93,GGD94,GGD95,GGD96,GGD97,GGD98,GGD99,GGE90,GGE91,GGE92,GGE93,GGE94,';
     z := z + 'GGE95,GGE96,GGE97,GGE98,GGE99,GGF90,GGF91,GGF92,GGF93,GGF94,GGF95,GGF96,GGF97,GGF98,GGF99,';
     z := z + 'GGG90,GGG91,GGG92,GGG93,GGG94,GGG95,GGG96,GGG97,GGG98,GGG99,GGH90,GGH91,GGH92,GGH93,GGH94,';
     z := z + 'GGH95,GGH96,GGH97,GGH98,GGH99,GGI90,GGI91,GGI92,GGI93,GGI94,GGI95,GGI96,GGI97,GGI98,GGI99,';
     z := z + 'GGJ90,GGJ91,GGJ92,GGJ93,GGJ94,GGJ95,GGJ96,GGJ97,GGJ98,GGJ99,GGK90,GGK91,GGK92,GGK93,GGK94,';
     z := z + 'GGK95,GGK96,GGK97,GGK98,GGK99,GGL90,GGL91,GGL92,GGL93,GGL94,GGL95,GGL96,GGL97,GGL98,GGL99,';
     z := z + 'GGM90,GGM91,GGM92,GGM93,GGM94,GGM95,GGM96,GGM97,GGM98,GGM99,GGN90,GGN91,GGN92,GGN93,GGN94,';
     z := z + 'GGN95,GGN96,GGN97,GGN98,GGN99,GGO90,GGO91,GGO92,GGO93,GGO94,GGO95,GGO96,GGO97,GGO98,GGO99,';
     z := z + 'GGP90,GGP91,GGP92,GGP93,GGP94,GGP95,GGP96,GGP97,GGP98,GGP99,GGQ90,GGQ91,GGQ92,GGQ93,GGQ94,';
     z := z + 'GGQ95,GGQ96,GGQ97,GGQ98,GGQ99,GGR90,GGR91,GGR92,GGR93,GGR94,SEA9  ,SEI   ,SEK   ,SEL   ,SEP   ,';
     z := z + 'GGA80,GGA81,GGA82,GGA83,GGA84,GGA85,GGA86,GGA87,GGA88,GGA89,GGB80,GGB81,GGB82,GGB83,GGB84,';
     z := z + 'GGB85,GGB86,GGB87,GGB88,GGB89,GGC80,GGC81,GGC82,GGC83,GGC84,GGC85,GGC86,GGC87,GGC88,GGC89,';
     z := z + 'GGD80,GGD81,GGD82,GGD83,GGD84,GGD85,GGD86,GGD87,GGD88,GGD89,GGE80,GGE81,GGE82,GGE83,GGE84,';
     z := z + 'GGE85,GGE86,GGE87,GGE88,GGE89,GGF80,GGF81,GGF82,GGF83,GGF84,GGF85,GGF86,GGF87,GGF88,GGF89,';
     z := z + 'GGG80,GGG81,GGG82,GGG83,GGG84,GGG85,GGG86,GGG87,GGG88,GGG89,GGH80,GGH81,GGH82,GGH83,GGH84,';
     z := z + 'GGH85,GGH86,GGH87,GGH88,GGH89,GGI80,GGI81,GGI82,GGI83,GGI84,GGI85,GGI86,GGI87,GGI88,GGI89,';
     z := z + 'GGJ80,GGJ81,GGJ82,GGJ83,GGJ84,GGJ85,GGJ86,GGJ87,GGJ88,GGJ89,GGK80,GGK81,GGK82,GGK83,GGK84,';
     z := z + 'GGK85,GGK86,GGK87,GGK88,GGK89,GGL80,GGL81,GGL82,GGL83,GGL84,GGL85,GGL86,GGL87,GGL88,GGL89,';
     z := z + 'GGM80,GGM81,GGM82,GGM83,GGM84,GGM85,GGM86,GGM87,GGM88,GGM89,GGN80,GGN81,GGN82,GGN83,GGN84,';
     z := z + 'GGN85,GGN86,GGN87,GGN88,GGN89,GGO80,GGO81,GGO82,GGO83,GGO84,GGO85,GGO86,GGO87,GGO88,GGO89,';
     z := z + 'GGP80,GGP81,GGP82,GGP83,GGP84,GGP85,GGP86,GGP87,GGP88,GGP89,GGQ80,GGQ81,GGQ82,GGQ83,GGQ84,';
     z := z + 'GGQ85,GGQ86,GGQ87,GGQ88,GGQ89,GGR80,GGR81,GGR82,GGR83,GGR84,SER   ,SES   ,SET   ,SEU   ,SEX   ,';
     z := z + 'GGA70,GGA71,GGA72,GGA73,GGA74,GGA75,GGA76,GGA77,GGA78,GGA79,GGB70,GGB71,GGB72,GGB73,GGB74,';
     z := z + 'GGB75,GGB76,GGB77,GGB78,GGB79,GGC70,GGC71,GGC72,GGC73,GGC74,GGC75,GGC76,GGC77,GGC78,GGC79,';
     z := z + 'GGD70,GGD71,GGD72,GGD73,GGD74,GGD75,GGD76,GGD77,GGD78,GGD79,GGE70,GGE71,GGE72,GGE73,GGE74,';
     z := z + 'GGE75,GGE76,GGE77,GGE78,GGE79,GGF70,GGF71,GGF72,GGF73,GGF74,GGF75,GGF76,GGF77,GGF78,GGF79,';
     z := z + 'GGG70,GGG71,GGG72,GGG73,GGG74,GGG75,GGG76,GGG77,GGG78,GGG79,GGH70,GGH71,GGH72,GGH73,GGH74,';
     z := z + 'GGH75,GGH76,GGH77,GGH78,GGH79,GGI70,GGI71,GGI72,GGI73,GGI74,GGI75,GGI76,GGI77,GGI78,GGI79,';
     z := z + 'GGJ70,GGJ71,GGJ72,GGJ73,GGJ74,GGJ75,GGJ76,GGJ77,GGJ78,GGJ79,GGK70,GGK71,GGK72,GGK73,GGK74,';
     z := z + 'GGK75,GGK76,GGK77,GGK78,GGK79,GGL70,GGL71,GGL72,GGL73,GGL74,GGL75,GGL76,GGL77,GGL78,GGL79,';
     z := z + 'GGM70,GGM71,GGM72,GGM73,GGM74,GGM75,GGM76,GGM77,GGM78,GGM79,GGN70,GGN71,GGN72,GGN73,GGN74,';
     z := z + 'GGN75,GGN76,GGN77,GGN78,GGN79,GGO70,GGO71,GGO72,GGO73,GGO74,GGO75,GGO76,GGO77,GGO78,GGO79,';
     z := z + 'GGP70,GGP71,GGP72,GGP73,GGP74,GGP75,GGP76,GGP77,GGP78,GGP79,GGQ70,GGQ71,GGQ72,GGQ73,GGQ74,';
     z := z + 'GGQ75,GGQ76,GGQ77,GGQ78,GGQ79,GGR70,GGR71,GGR72,GGR73,GGR74,SEY   ,SEZ   ,SF    ,SFG   ,SFH   ,';
     z := z + 'GGA60,GGA61,GGA62,GGA63,GGA64,GGA65,GGA66,GGA67,GGA68,GGA69,GGB60,GGB61,GGB62,GGB63,GGB64,';
     z := z + 'GGB65,GGB66,GGB67,GGB68,GGB69,GGC60,GGC61,GGC62,GGC63,GGC64,GGC65,GGC66,GGC67,GGC68,GGC69,';
     z := z + 'GGD60,GGD61,GGD62,GGD63,GGD64,GGD65,GGD66,GGD67,GGD68,GGD69,GGE60,GGE61,GGE62,GGE63,GGE64,';
     z := z + 'GGE65,GGE66,GGE67,GGE68,GGE69,GGF60,GGF61,GGF62,GGF63,GGF64,GGF65,GGF66,GGF67,GGF68,GGF69,';
     z := z + 'GGG60,GGG61,GGG62,GGG63,GGG64,GGG65,GGG66,GGG67,GGG68,GGG69,GGH60,GGH61,GGH62,GGH63,GGH64,';
     z := z + 'GGH65,GGH66,GGH67,GGH68,GGH69,GGI60,GGI61,GGI62,GGI63,GGI64,GGI65,GGI66,GGI67,GGI68,GGI69,';
     z := z + 'GGJ60,GGJ61,GGJ62,GGJ63,GGJ64,GGJ65,GGJ66,GGJ67,GGJ68,GGJ69,GGK60,GGK61,GGK62,GGK63,GGK64,';
     z := z + 'GGK65,GGK66,GGK67,GGK68,GGK69,GGL60,GGL61,GGL62,GGL63,GGL64,GGL65,GGL66,GGL67,GGL68,GGL69,';
     z := z + 'GGM60,GGM61,GGM62,GGM63,GGM64,GGM65,GGM66,GGM67,GGM68,GGM69,GGN60,GGN61,GGN62,GGN63,GGN64,';
     z := z + 'GGN65,GGN66,GGN67,GGN68,GGN69,GGO60,GGO61,GGO62,GGO63,GGO64,GGO65,GGO66,GGO67,GGO68,GGO69,';
     z := z + 'GGP60,GGP61,GGP62,GGP63,GGP64,GGP65,GGP66,GGP67,GGP68,GGP69,GGQ60,GGQ61,GGQ62,GGQ63,GGQ64,';
     z := z + 'GGQ65,GGQ66,GGQ67,GGQ68,GGQ69,GGR60,GGR61,GGR62,GGR63,GGR64,SFJ   ,SFK   ,SFKC  ,SFM   ,SFO   ,';
     z := z + 'GGA50,GGA51,GGA52,GGA53,GGA54,GGA55,GGA56,GGA57,GGA58,GGA59,GGB50,GGB51,GGB52,GGB53,GGB54,';
     z := z + 'GGB55,GGB56,GGB57,GGB58,GGB59,GGC50,GGC51,GGC52,GGC53,GGC54,GGC55,GGC56,GGC57,GGC58,GGC59,';
     z := z + 'GGD50,GGD51,GGD52,GGD53,GGD54,GGD55,GGD56,GGD57,GGD58,GGD59,GGE50,GGE51,GGE52,GGE53,GGE54,';
     z := z + 'GGE55,GGE56,GGE57,GGE58,GGE59,GGF50,GGF51,GGF52,GGF53,GGF54,GGF55,GGF56,GGF57,GGF58,GGF59,';
     z := z + 'GGG50,GGG51,GGG52,GGG53,GGG54,GGG55,GGG56,GGG57,GGG58,GGG59,GGH50,GGH51,GGH52,GGH53,GGH54,';
     z := z + 'GGH55,GGH56,GGH57,GGH58,GGH59,GGI50,GGI51,GGI52,GGI53,GGI54,GGI55,GGI56,GGI57,GGI58,GGI59,';
     z := z + 'GGJ50,GGJ51,GGJ52,GGJ53,GGJ54,GGJ55,GGJ56,GGJ57,GGJ58,GGJ59,GGK50,GGK51,GGK52,GGK53,GGK54,';
     z := z + 'GGK55,GGK56,GGK57,GGK58,GGK59,GGL50,GGL51,GGL52,GGL53,GGL54,GGL55,GGL56,GGL57,GGL58,GGL59,';
     z := z + 'GGM50,GGM51,GGM52,GGM53,GGM54,GGM55,GGM56,GGM57,GGM58,GGM59,GGN50,GGN51,GGN52,GGN53,GGN54,';
     z := z + 'GGN55,GGN56,GGN57,GGN58,GGN59,GGO50,GGO51,GGO52,GGO53,GGO54,GGO55,GGO56,GGO57,GGO58,GGO59,';
     z := z + 'GGP50,GGP51,GGP52,GGP53,GGP54,GGP55,GGP56,GGP57,GGP58,GGP59,GGQ50,GGQ51,GGQ52,GGQ53,GGQ54,';
     z := z + 'GGQ55,GGQ56,GGQ57,GGQ58,GGQ59,GGR50,GGR51,GGR52,GGR53,GGR54,SFOA  ,SFOC  ,SFOM  ,SFP   ,SFR   ,';
     z := z + 'GGA40,GGA41,GGA42,GGA43,GGA44,GGA45,GGA46,GGA47,GGA48,GGA49,GGB40,GGB41,GGB42,GGB43,GGB44,';
     z := z + 'GGB45,GGB46,GGB47,GGB48,GGB49,GGC40,GGC41,GGC42,GGC43,GGC44,GGC45,GGC46,GGC47,GGC48,GGC49,';
     z := z + 'GGD40,GGD41,GGD42,GGD43,GGD44,GGD45,GGD46,GGD47,GGD48,GGD49,GGE40,GGE41,GGE42,GGE43,GGE44,';
     z := z + 'GGE45,GGE46,GGE47,GGE48,GGE49,GGF40,GGF41,GGF42,GGF43,GGF44,GGF45,GGF46,GGF47,GGF48,GGF49,';
     z := z + 'GGG40,GGG41,GGG42,GGG43,GGG44,GGG45,GGG46,GGG47,GGG48,GGG49,GGH40,GGH41,GGH42,GGH43,GGH44,';
     z := z + 'GGH45,GGH46,GGH47,GGH48,GGH49,GGI40,GGI41,GGI42,GGI43,GGI44,GGI45,GGI46,GGI47,GGI48,GGI49,';
     z := z + 'GGJ40,GGJ41,GGJ42,GGJ43,GGJ44,GGJ45,GGJ46,GGJ47,GGJ48,GGJ49,GGK40,GGK41,GGK42,GGK43,GGK44,';
     z := z + 'GGK45,GGK46,GGK47,GGK48,GGK49,GGL40,GGL41,GGL42,GGL43,GGL44,GGL45,GGL46,GGL47,GGL48,GGL49,';
     z := z + 'GGM40,GGM41,GGM42,GGM43,GGM44,GGM45,GGM46,GGM47,GGM48,GGM49,GGN40,GGN41,GGN42,GGN43,GGN44,';
     z := z + 'GGN45,GGN46,GGN47,GGN48,GGN49,GGO40,GGO41,GGO42,GGO43,GGO44,GGO45,GGO46,GGO47,GGO48,GGO49,';
     z := z + 'GGP40,GGP41,GGP42,GGP43,GGP44,GGP45,GGP46,GGP47,GGP48,GGP49,GGQ40,GGQ41,GGQ42,GGQ43,GGQ44,';
     z := z + 'GGQ45,GGQ46,GGQ47,GGQ48,GGQ49,GGR40,GGR41,GGR42,GGR43,GGR44,SFRG  ,SFRJ  ,SFRT  ,SFT5W ,SFT5X ,';
     z := z + 'GGA30,GGA31,GGA32,GGA33,GGA34,GGA35,GGA36,GGA37,GGA38,GGA39,GGB30,GGB31,GGB32,GGB33,GGB34,';
     z := z + 'GGB35,GGB36,GGB37,GGB38,GGB39,GGC30,GGC31,GGC32,GGC33,GGC34,GGC35,GGC36,GGC37,GGC38,GGC39,';
     z := z + 'GGD30,GGD31,GGD32,GGD33,GGD34,GGD35,GGD36,GGD37,GGD38,GGD39,GGE30,GGE31,GGE32,GGE33,GGE34,';
     z := z + 'GGE35,GGE36,GGE37,GGE38,GGE39,GGF30,GGF31,GGF32,GGF33,GGF34,GGF35,GGF36,GGF37,GGF38,GGF39,';
     z := z + 'GGG30,GGG31,GGG32,GGG33,GGG34,GGG35,GGG36,GGG37,GGG38,GGG39,GGH30,GGH31,GGH32,GGH33,GGH34,';
     z := z + 'GGH35,GGH36,GGH37,GGH38,GGH39,GGI30,GGI31,GGI32,GGI33,GGI34,GGI35,GGI36,GGI37,GGI38,GGI39,';
     z := z + 'GGJ30,GGJ31,GGJ32,GGJ33,GGJ34,GGJ35,GGJ36,GGJ37,GGJ38,GGJ39,GGK30,GGK31,GGK32,GGK33,GGK34,';
     z := z + 'GGK35,GGK36,GGK37,GGK38,GGK39,GGL30,GGL31,GGL32,GGL33,GGL34,GGL35,GGL36,GGL37,GGL38,GGL39,';
     z := z + 'GGM30,GGM31,GGM32,GGM33,GGM34,GGM35,GGM36,GGM37,GGM38,GGM39,GGN30,GGN31,GGN32,GGN33,GGN34,';
     z := z + 'GGN35,GGN36,GGN37,GGN38,GGN39,GGO30,GGO31,GGO32,GGO33,GGO34,GGO35,GGO36,GGO37,GGO38,GGO39,';
     z := z + 'GGP30,GGP31,GGP32,GGP33,GGP34,GGP35,GGP36,GGP37,GGP38,GGP39,GGQ30,GGQ31,GGQ32,GGQ33,GGQ34,';
     z := z + 'GGQ35,GGQ36,GGQ37,GGQ38,GGQ39,GGR30,GGR31,GGR32,GGR33,GGR34,SFT5Z ,SFW   ,SFY   ,SM    ,SMD   ,';
     z := z + 'GGA20,GGA21,GGA22,GGA23,GGA24,GGA25,GGA26,GGA27,GGA28,GGA29,GGB20,GGB21,GGB22,GGB23,GGB24,';
     z := z + 'GGB25,GGB26,GGB27,GGB28,GGB29,GGC20,GGC21,GGC22,GGC23,GGC24,GGC25,GGC26,GGC27,GGC28,GGC29,';
     z := z + 'GGD20,GGD21,GGD22,GGD23,GGD24,GGD25,GGD26,GGD27,GGD28,GGD29,GGE20,GGE21,GGE22,GGE23,GGE24,';
     z := z + 'GGE25,GGE26,GGE27,GGE28,GGE29,GGF20,GGF21,GGF22,GGF23,GGF24,GGF25,GGF26,GGF27,GGF28,GGF29,';
     z := z + 'GGG20,GGG21,GGG22,GGG23,GGG24,GGG25,GGG26,GGG27,GGG28,GGG29,GGH20,GGH21,GGH22,GGH23,GGH24,';
     z := z + 'GGH25,GGH26,GGH27,GGH28,GGH29,GGI20,GGI21,GGI22,GGI23,GGI24,GGI25,GGI26,GGI27,GGI28,GGI29,';
     z := z + 'GGJ20,GGJ21,GGJ22,GGJ23,GGJ24,GGJ25,GGJ26,GGJ27,GGJ28,GGJ29,GGK20,GGK21,GGK22,GGK23,GGK24,';
     z := z + 'GGK25,GGK26,GGK27,GGK28,GGK29,GGL20,GGL21,GGL22,GGL23,GGL24,GGL25,GGL26,GGL27,GGL28,GGL29,';
     z := z + 'GGM20,GGM21,GGM22,GGM23,GGM24,GGM25,GGM26,GGM27,GGM28,GGM29,GGN20,GGN21,GGN22,GGN23,GGN24,';
     z := z + 'GGN25,GGN26,GGN27,GGN28,GGN29,GGO20,GGO21,GGO22,GGO23,GGO24,GGO25,GGO26,GGO27,GGO28,GGO29,';
     z := z + 'GGP20,GGP21,GGP22,GGP23,GGP24,GGP25,GGP26,GGP27,GGP28,GGP29,GGQ20,GGQ21,GGQ22,GGQ23,GGQ24,';
     z := z + 'GGQ25,GGQ26,GGQ27,GGQ28,GGQ29,GGR20,GGR21,GGR22,GGR23,GGR24,SMI   ,SMJ   ,SMM   ,SMU   ,SMW   ,';
     z := z + 'GGA10,GGA11,GGA12,GGA13,GGA14,GGA15,GGA16,GGA17,GGA18,GGA19,GGB10,GGB11,GGB12,GGB13,GGB14,';
     z := z + 'GGB15,GGB16,GGB17,GGB18,GGB19,GGC10,GGC11,GGC12,GGC13,GGC14,GGC15,GGC16,GGC17,GGC18,GGC19,';
     z := z + 'GGD10,GGD11,GGD12,GGD13,GGD14,GGD15,GGD16,GGD17,GGD18,GGD19,GGE10,GGE11,GGE12,GGE13,GGE14,';
     z := z + 'GGE15,GGE16,GGE17,GGE18,GGE19,GGF10,GGF11,GGF12,GGF13,GGF14,GGF15,GGF16,GGF17,GGF18,GGF19,';
     z := z + 'GGG10,GGG11,GGG12,GGG13,GGG14,GGG15,GGG16,GGG17,GGG18,GGG19,GGH10,GGH11,GGH12,GGH13,GGH14,';
     z := z + 'GGH15,GGH16,GGH17,GGH18,GGH19,GGI10,GGI11,GGI12,GGI13,GGI14,GGI15,GGI16,GGI17,GGI18,GGI19,';
     z := z + 'GGJ10,GGJ11,GGJ12,GGJ13,GGJ14,GGJ15,GGJ16,GGJ17,GGJ18,GGJ19,GGK10,GGK11,GGK12,GGK13,GGK14,';
     z := z + 'GGK15,GGK16,GGK17,GGK18,GGK19,GGL10,GGL11,GGL12,GGL13,GGL14,GGL15,GGL16,GGL17,GGL18,GGL19,';
     z := z + 'GGM10,GGM11,GGM12,GGM13,GGM14,GGM15,GGM16,GGM17,GGM18,GGM19,GGN10,GGN11,GGN12,GGN13,GGN14,';
     z := z + 'GGN15,GGN16,GGN17,GGN18,GGN19,GGO10,GGO11,GGO12,GGO13,GGO14,GGO15,GGO16,GGO17,GGO18,GGO19,';
     z := z + 'GGP10,GGP11,GGP12,GGP13,GGP14,GGP15,GGP16,GGP17,GGP18,GGP19,GGQ10,GGQ11,GGQ12,GGQ13,GGQ14,';
     z := z + 'GGQ15,GGQ16,GGQ17,GGQ18,GGQ19,GGR10,GGR11,GGR12,GGR13,GGR14,SH4   ,SH40  ,SHA   ,SHB   ,SHB0  ,';
     z := z + 'GGA00,GGA01,GGA02,GGA03,GGA04,GGA05,GGA06,GGA07,GGA08,GGA09,GGB00,GGB01,GGB02,GGB03,GGB04,';
     z := z + 'GGB05,GGB06,GGB07,GGB08,GGB09,GGC00,GGC01,GGC02,GGC03,GGC04,GGC05,GGC06,GGC07,GGC08,GGC09,';
     z := z + 'GGD00,GGD01,GGD02,GGD03,GGD04,GGD05,GGD06,GGD07,GGD08,GGD09,GGE00,GGE01,GGE02,GGE03,GGE04,';
     z := z + 'GGE05,GGE06,GGE07,GGE08,GGE09,GGF00,GGF01,GGF02,GGF03,GGF04,GGF05,GGF06,GGF07,GGF08,GGF09,';
     z := z + 'GGG00,GGG01,GGG02,GGG03,GGG04,GGG05,GGG06,GGG07,GGG08,GGG09,GGH00,GGH01,GGH02,GGH03,GGH04,';
     z := z + 'GGH05,GGH06,GGH07,GGH08,GGH09,GGI00,GGI01,GGI02,GGI03,GGI04,GGI05,GGI06,GGI07,GGI08,GGI09,';
     z := z + 'GGJ00,GGJ01,GGJ02,GGJ03,GGJ04,GGJ05,GGJ06,GGJ07,GGJ08,GGJ09,GGK00,GGK01,GGK02,GGK03,GGK04,';
     z := z + 'GGK05,GGK06,GGK07,GGK08,GGK09,GGL00,GGL01,GGL02,GGL03,GGL04,GGL05,GGL06,GGL07,GGL08,GGL09,';
     z := z + 'GGM00,GGM01,GGM02,GGM03,GGM04,GGM05,GGM06,GGM07,GGM08,GGM09,GGN00,GGN01,GGN02,GGN03,GGN04,';
     z := z + 'GGN05,GGN06,GGN07,GGN08,GGN09,GGO00,GGO01,GGO02,GGO03,GGO04,GGO05,GGO06,GGO07,GGO08,GGO09,';
     z := z + 'GGP00,GGP01,GGP02,GGP03,GGP04,GGP05,GGP06,GGP07,GGP08,GGP09,GGQ00,GGQ01,GGQ02,GGQ03,GGQ04,';
     z := z + 'GGQ05,GGQ06,GGQ07,GGQ08,GGQ09,GGR00,GGR01,GGR02,GGR03,GGR04,SHC   ,SHC8  ,SHH   ,SHI   ,SHK   ,';
     z := z + 'GFA90,GFA91,GFA92,GFA93,GFA94,GFA95,GFA96,GFA97,GFA98,GFA99,GFB90,GFB91,GFB92,GFB93,GFB94,';
     z := z + 'GFB95,GFB96,GFB97,GFB98,GFB99,GFC90,GFC91,GFC92,GFC93,GFC94,GFC95,GFC96,GFC97,GFC98,GFC99,';
     z := z + 'GFD90,GFD91,GFD92,GFD93,GFD94,GFD95,GFD96,GFD97,GFD98,GFD99,GFE90,GFE91,GFE92,GFE93,GFE94,';
     z := z + 'GFE95,GFE96,GFE97,GFE98,GFE99,GFF90,GFF91,GFF92,GFF93,GFF94,GFF95,GFF96,GFF97,GFF98,GFF99,';
     z := z + 'GFG90,GFG91,GFG92,GFG93,GFG94,GFG95,GFG96,GFG97,GFG98,GFG99,GFH90,GFH91,GFH92,GFH93,GFH94,';
     z := z + 'GFH95,GFH96,GFH97,GFH98,GFH99,GFI90,GFI91,GFI92,GFI93,GFI94,GFI95,GFI96,GFI97,GFI98,GFI99,';
     z := z + 'GFJ90,GFJ91,GFJ92,GFJ93,GFJ94,GFJ95,GFJ96,GFJ97,GFJ98,GFJ99,GFK90,GFK91,GFK92,GFK93,GFK94,';
     z := z + 'GFK95,GFK96,GFK97,GFK98,GFK99,GFL90,GFL91,GFL92,GFL93,GFL94,GFL95,GFL96,GFL97,GFL98,GFL99,';
     z := z + 'GFM90,GFM91,GFM92,GFM93,GFM94,GFM95,GFM96,GFM97,GFM98,GFM99,GFN90,GFN91,GFN92,GFN93,GFN94,';
     z := z + 'GFN95,GFN96,GFN97,GFN98,GFN99,GFO90,GFO91,GFO92,GFO93,GFO94,GFO95,GFO96,GFO97,GFO98,GFO99,';
     z := z + 'GFP90,GFP91,GFP92,GFP93,GFP94,GFP95,GFP96,GFP97,GFP98,GFP99,GFQ90,GFQ91,GFQ92,GFQ93,GFQ94,';
     z := z + 'GFQ95,GFQ96,GFQ97,GFQ98,GFQ99,GFR90,GFR91,GFR92,GFR93,GFR94,SHK0A ,SHK0M ,SHL   ,SHM   ,SHP   ,';
     z := z + 'GFA80,GFA81,GFA82,GFA83,GFA84,GFA85,GFA86,GFA87,GFA88,GFA89,GFB80,GFB81,GFB82,GFB83,GFB84,';
     z := z + 'GFB85,GFB86,GFB87,GFB88,GFB89,GFC80,GFC81,GFC82,GFC83,GFC84,GFC85,GFC86,GFC87,GFC88,GFC89,';
     z := z + 'GFD80,GFD81,GFD82,GFD83,GFD84,GFD85,GFD86,GFD87,GFD88,GFD89,GFE80,GFE81,GFE82,GFE83,GFE84,';
     z := z + 'GFE85,GFE86,GFE87,GFE88,GFE89,GFF80,GFF81,GFF82,GFF83,GFF84,GFF85,GFF86,GFF87,GFF88,GFF89,';
     z := z + 'GFG80,GFG81,GFG82,GFG83,GFG84,GFG85,GFG86,GFG87,GFG88,GFG89,GFH80,GFH81,GFH82,GFH83,GFH84,';
     z := z + 'GFH85,GFH86,GFH87,GFH88,GFH89,GFI80,GFI81,GFI82,GFI83,GFI84,GFI85,GFI86,GFI87,GFI88,GFI89,';
     z := z + 'GFJ80,GFJ81,GFJ82,GFJ83,GFJ84,GFJ85,GFJ86,GFJ87,GFJ88,GFJ89,GFK80,GFK81,GFK82,GFK83,GFK84,';
     z := z + 'GFK85,GFK86,GFK87,GFK88,GFK89,GFL80,GFL81,GFL82,GFL83,GFL84,GFL85,GFL86,GFL87,GFL88,GFL89,';
     z := z + 'GFM80,GFM81,GFM82,GFM83,GFM84,GFM85,GFM86,GFM87,GFM88,GFM89,GFN80,GFN81,GFN82,GFN83,GFN84,';
     z := z + 'GFN85,GFN86,GFN87,GFN88,GFN89,GFO80,GFO81,GFO82,GFO83,GFO84,GFO85,GFO86,GFO87,GFO88,GFO89,';
     z := z + 'GFP80,GFP81,GFP82,GFP83,GFP84,GFP85,GFP86,GFP87,GFP88,GFP89,GFQ80,GFQ81,GFQ82,GFQ83,GFQ84,';
     z := z + 'GFQ85,GFQ86,GFQ87,GFQ88,GFQ89,GFR80,GFR81,GFR82,GFR83,GFR84,SHR   ,SHS   ,SHV   ,SHZ   ,SI    ,';
     z := z + 'GFA70,GFA71,GFA72,GFA73,GFA74,GFA75,GFA76,GFA77,GFA78,GFA79,GFB70,GFB71,GFB72,GFB73,GFB74,';
     z := z + 'GFB75,GFB76,GFB77,GFB78,GFB79,GFC70,GFC71,GFC72,GFC73,GFC74,GFC75,GFC76,GFC77,GFC78,GFC79,';
     z := z + 'GFD70,GFD71,GFD72,GFD73,GFD74,GFD75,GFD76,GFD77,GFD78,GFD79,GFE70,GFE71,GFE72,GFE73,GFE74,';
     z := z + 'GFE75,GFE76,GFE77,GFE78,GFE79,GFF70,GFF71,GFF72,GFF73,GFF74,GFF75,GFF76,GFF77,GFF78,GFF79,';
     z := z + 'GFG70,GFG71,GFG72,GFG73,GFG74,GFG75,GFG76,GFG77,GFG78,GFG79,GFH70,GFH71,GFH72,GFH73,GFH74,';
     z := z + 'GFH75,GFH76,GFH77,GFH78,GFH79,GFI70,GFI71,GFI72,GFI73,GFI74,GFI75,GFI76,GFI77,GFI78,GFI79,';
     z := z + 'GFJ70,GFJ71,GFJ72,GFJ73,GFJ74,GFJ75,GFJ76,GFJ77,GFJ78,GFJ79,GFK70,GFK71,GFK72,GFK73,GFK74,';
     z := z + 'GFK75,GFK76,GFK77,GFK78,GFK79,GFL70,GFL71,GFL72,GFL73,GFL74,GFL75,GFL76,GFL77,GFL78,GFL79,';
     z := z + 'GFM70,GFM71,GFM72,GFM73,GFM74,GFM75,GFM76,GFM77,GFM78,GFM79,GFN70,GFN71,GFN72,GFN73,GFN74,';
     z := z + 'GFN75,GFN76,GFN77,GFN78,GFN79,GFO70,GFO71,GFO72,GFO73,GFO74,GFO75,GFO76,GFO77,GFO78,GFO79,';
     z := z + 'GFP70,GFP71,GFP72,GFP73,GFP74,GFP75,GFP76,GFP77,GFP78,GFP79,GFQ70,GFQ71,GFQ72,GFQ73,GFQ74,';
     z := z + 'GFQ75,GFQ76,GFQ77,GFQ78,GFQ79,GFR70,GFR71,GFR72,GFR73,GFR74,SIS   ,SIS0  ,SJ2   ,SJ3   ,SJ5   ,';
     z := z + 'GFA60,GFA61,GFA62,GFA63,GFA64,GFA65,GFA66,GFA67,GFA68,GFA69,GFB60,GFB61,GFB62,GFB63,GFB64,';
     z := z + 'GFB65,GFB66,GFB67,GFB68,GFB69,GFC60,GFC61,GFC62,GFC63,GFC64,GFC65,GFC66,GFC67,GFC68,GFC69,';
     z := z + 'GFD60,GFD61,GFD62,GFD63,GFD64,GFD65,GFD66,GFD67,GFD68,GFD69,GFE60,GFE61,GFE62,GFE63,GFE64,';
     z := z + 'GFE65,GFE66,GFE67,GFE68,GFE69,GFF60,GFF61,GFF62,GFF63,GFF64,GFF65,GFF66,GFF67,GFF68,GFF69,';
     z := z + 'GFG60,GFG61,GFG62,GFG63,GFG64,GFG65,GFG66,GFG67,GFG68,GFG69,GFH60,GFH61,GFH62,GFH63,GFH64,';
     z := z + 'GFH65,GFH66,GFH67,GFH68,GFH69,GFI60,GFI61,GFI62,GFI63,GFI64,GFI65,GFI66,GFI67,GFI68,GFI69,';
     z := z + 'GFJ60,GFJ61,GFJ62,GFJ63,GFJ64,GFJ65,GFJ66,GFJ67,GFJ68,GFJ69,GFK60,GFK61,GFK62,GFK63,GFK64,';
     z := z + 'GFK65,GFK66,GFK67,GFK68,GFK69,GFL60,GFL61,GFL62,GFL63,GFL64,GFL65,GFL66,GFL67,GFL68,GFL69,';
     z := z + 'GFM60,GFM61,GFM62,GFM63,GFM64,GFM65,GFM66,GFM67,GFM68,GFM69,GFN60,GFN61,GFN62,GFN63,GFN64,';
     z := z + 'GFN65,GFN66,GFN67,GFN68,GFN69,GFO60,GFO61,GFO62,GFO63,GFO64,GFO65,GFO66,GFO67,GFO68,GFO69,';
     z := z + 'GFP60,GFP61,GFP62,GFP63,GFP64,GFP65,GFP66,GFP67,GFP68,GFP69,GFQ60,GFQ61,GFQ62,GFQ63,GFQ64,';
     z := z + 'GFQ65,GFQ66,GFQ67,GFQ68,GFQ69,GFR60,GFR61,GFR62,GFR63,GFR64,SJ6   ,SJ7   ,SJ8   ,SJA   ,SJDM  ,';
     z := z + 'GFA50,GFA51,GFA52,GFA53,GFA54,GFA55,GFA56,GFA57,GFA58,GFA59,GFB50,GFB51,GFB52,GFB53,GFB54,';
     z := z + 'GFB55,GFB56,GFB57,GFB58,GFB59,GFC50,GFC51,GFC52,GFC53,GFC54,GFC55,GFC56,GFC57,GFC58,GFC59,';
     z := z + 'GFD50,GFD51,GFD52,GFD53,GFD54,GFD55,GFD56,GFD57,GFD58,GFD59,GFE50,GFE51,GFE52,GFE53,GFE54,';
     z := z + 'GFE55,GFE56,GFE57,GFE58,GFE59,GFF50,GFF51,GFF52,GFF53,GFF54,GFF55,GFF56,GFF57,GFF58,GFF59,';
     z := z + 'GFG50,GFG51,GFG52,GFG53,GFG54,GFG55,GFG56,GFG57,GFG58,GFG59,GFH50,GFH51,GFH52,GFH53,GFH54,';
     z := z + 'GFH55,GFH56,GFH57,GFH58,GFH59,GFI50,GFI51,GFI52,GFI53,GFI54,GFI55,GFI56,GFI57,GFI58,GFI59,';
     z := z + 'GFJ50,GFJ51,GFJ52,GFJ53,GFJ54,GFJ55,GFJ56,GFJ57,GFJ58,GFJ59,GFK50,GFK51,GFK52,GFK53,GFK54,';
     z := z + 'GFK55,GFK56,GFK57,GFK58,GFK59,GFL50,GFL51,GFL52,GFL53,GFL54,GFL55,GFL56,GFL57,GFL58,GFL59,';
     z := z + 'GFM50,GFM51,GFM52,GFM53,GFM54,GFM55,GFM56,GFM57,GFM58,GFM59,GFN50,GFN51,GFN52,GFN53,GFN54,';
     z := z + 'GFN55,GFN56,GFN57,GFN58,GFN59,GFO50,GFO51,GFO52,GFO53,GFO54,GFO55,GFO56,GFO57,GFO58,GFO59,';
     z := z + 'GFP50,GFP51,GFP52,GFP53,GFP54,GFP55,GFP56,GFP57,GFP58,GFP59,GFQ50,GFQ51,GFQ52,GFQ53,GFQ54,';
     z := z + 'GFQ55,GFQ56,GFQ57,GFQ58,GFQ59,GFR50,GFR51,GFR52,GFR53,GFR54,SJDO  ,SJT   ,SJW   ,SJX   ,SJY   ,';
     z := z + 'GFA40,GFA41,GFA42,GFA43,GFA44,GFA45,GFA46,GFA47,GFA48,GFA49,GFB40,GFB41,GFB42,GFB43,GFB44,';
     z := z + 'GFB45,GFB46,GFB47,GFB48,GFB49,GFC40,GFC41,GFC42,GFC43,GFC44,GFC45,GFC46,GFC47,GFC48,GFC49,';
     z := z + 'GFD40,GFD41,GFD42,GFD43,GFD44,GFD45,GFD46,GFD47,GFD48,GFD49,GFE40,GFE41,GFE42,GFE43,GFE44,';
     z := z + 'GFE45,GFE46,GFE47,GFE48,GFE49,GFF40,GFF41,GFF42,GFF43,GFF44,GFF45,GFF46,GFF47,GFF48,GFF49,';
     z := z + 'GFG40,GFG41,GFG42,GFG43,GFG44,GFG45,GFG46,GFG47,GFG48,GFG49,GFH40,GFH41,GFH42,GFH43,GFH44,';
     z := z + 'GFH45,GFH46,GFH47,GFH48,GFH49,GFI40,GFI41,GFI42,GFI43,GFI44,GFI45,GFI46,GFI47,GFI48,GFI49,';
     z := z + 'GFJ40,GFJ41,GFJ42,GFJ43,GFJ44,GFJ45,GFJ46,GFJ47,GFJ48,GFJ49,GFK40,GFK41,GFK42,GFK43,GFK44,';
     z := z + 'GFK45,GFK46,GFK47,GFK48,GFK49,GFL40,GFL41,GFL42,GFL43,GFL44,GFL45,GFL46,GFL47,GFL48,GFL49,';
     z := z + 'GFM40,GFM41,GFM42,GFM43,GFM44,GFM45,GFM46,GFM47,GFM48,GFM49,GFN40,GFN41,GFN42,GFN43,GFN44,';
     z := z + 'GFN45,GFN46,GFN47,GFN48,GFN49,GFO40,GFO41,GFO42,GFO43,GFO44,GFO45,GFO46,GFO47,GFO48,GFO49,';
     z := z + 'GFP40,GFP41,GFP42,GFP43,GFP44,GFP45,GFP46,GFP47,GFP48,GFP49,GFQ40,GFQ41,GFQ42,GFQ43,GFQ44,';
     z := z + 'GFQ45,GFQ46,GFQ47,GFQ48,GFQ49,GFR40,GFR41,GFR42,GFR43,GFR44,SK    ,SKG4  ,SKH0  ,SKH1  ,SKH2  ,';
     z := z + 'GFA30,GFA31,GFA32,GFA33,GFA34,GFA35,GFA36,GFA37,GFA38,GFA39,GFB30,GFB31,GFB32,GFB33,GFB34,';
     z := z + 'GFB35,GFB36,GFB37,GFB38,GFB39,GFC30,GFC31,GFC32,GFC33,GFC34,GFC35,GFC36,GFC37,GFC38,GFC39,';
     z := z + 'GFD30,GFD31,GFD32,GFD33,GFD34,GFD35,GFD36,GFD37,GFD38,GFD39,GFE30,GFE31,GFE32,GFE33,GFE34,';
     z := z + 'GFE35,GFE36,GFE37,GFE38,GFE39,GFF30,GFF31,GFF32,GFF33,GFF34,GFF35,GFF36,GFF37,GFF38,GFF39,';
     z := z + 'GFG30,GFG31,GFG32,GFG33,GFG34,GFG35,GFG36,GFG37,GFG38,GFG39,GFH30,GFH31,GFH32,GFH33,GFH34,';
     z := z + 'GFH35,GFH36,GFH37,GFH38,GFH39,GFI30,GFI31,GFI32,GFI33,GFI34,GFI35,GFI36,GFI37,GFI38,GFI39,';
     z := z + 'GFJ30,GFJ31,GFJ32,GFJ33,GFJ34,GFJ35,GFJ36,GFJ37,GFJ38,GFJ39,GFK30,GFK31,GFK32,GFK33,GFK34,';
     z := z + 'GFK35,GFK36,GFK37,GFK38,GFK39,GFL30,GFL31,GFL32,GFL33,GFL34,GFL35,GFL36,GFL37,GFL38,GFL39,';
     z := z + 'GFM30,GFM31,GFM32,GFM33,GFM34,GFM35,GFM36,GFM37,GFM38,GFM39,GFN30,GFN31,GFN32,GFN33,GFN34,';
     z := z + 'GFN35,GFN36,GFN37,GFN38,GFN39,GFO30,GFO31,GFO32,GFO33,GFO34,GFO35,GFO36,GFO37,GFO38,GFO39,';
     z := z + 'GFP30,GFP31,GFP32,GFP33,GFP34,GFP35,GFP36,GFP37,GFP38,GFP39,GFQ30,GFQ31,GFQ32,GFQ33,GFQ34,';
     z := z + 'GFQ35,GFQ36,GFQ37,GFQ38,GFQ39,GFR30,GFR31,GFR32,GFR33,GFR34,SKH3  ,SKH4  ,SKH5  ,SKH5K ,SKH6  ,';
     z := z + 'GFA20,GFA21,GFA22,GFA23,GFA24,GFA25,GFA26,GFA27,GFA28,GFA29,GFB20,GFB21,GFB22,GFB23,GFB24,';
     z := z + 'GFB25,GFB26,GFB27,GFB28,GFB29,GFC20,GFC21,GFC22,GFC23,GFC24,GFC25,GFC26,GFC27,GFC28,GFC29,';
     z := z + 'GFD20,GFD21,GFD22,GFD23,GFD24,GFD25,GFD26,GFD27,GFD28,GFD29,GFE20,GFE21,GFE22,GFE23,GFE24,';
     z := z + 'GFE25,GFE26,GFE27,GFE28,GFE29,GFF20,GFF21,GFF22,GFF23,GFF24,GFF25,GFF26,GFF27,GFF28,GFF29,';
     z := z + 'GFG20,GFG21,GFG22,GFG23,GFG24,GFG25,GFG26,GFG27,GFG28,GFG29,GFH20,GFH21,GFH22,GFH23,GFH24,';
     z := z + 'GFH25,GFH26,GFH27,GFH28,GFH29,GFI20,GFI21,GFI22,GFI23,GFI24,GFI25,GFI26,GFI27,GFI28,GFI29,';
     z := z + 'GFJ20,GFJ21,GFJ22,GFJ23,GFJ24,GFJ25,GFJ26,GFJ27,GFJ28,GFJ29,GFK20,GFK21,GFK22,GFK23,GFK24,';
     z := z + 'GFK25,GFK26,GFK27,GFK28,GFK29,GFL20,GFL21,GFL22,GFL23,GFL24,GFL25,GFL26,GFL27,GFL28,GFL29,';
     z := z + 'GFM20,GFM21,GFM22,GFM23,GFM24,GFM25,GFM26,GFM27,GFM28,GFM29,GFN20,GFN21,GFN22,GFN23,GFN24,';
     z := z + 'GFN25,GFN26,GFN27,GFN28,GFN29,GFO20,GFO21,GFO22,GFO23,GFO24,GFO25,GFO26,GFO27,GFO28,GFO29,';
     z := z + 'GFP20,GFP21,GFP22,GFP23,GFP24,GFP25,GFP26,GFP27,GFP28,GFP29,GFQ20,GFQ21,GFQ22,GFQ23,GFQ24,';
     z := z + 'GFQ25,GFQ26,GFQ27,GFQ28,GFQ29,GFR20,GFR21,GFR22,GFR23,GFR24,SKH7  ,SKH8  ,SKH9  ,SKL   ,SKP1  ,';
     z := z + 'GFA10,GFA11,GFA12,GFA13,GFA14,GFA15,GFA16,GFA17,GFA18,GFA19,GFB10,GFB11,GFB12,GFB13,GFB14,';
     z := z + 'GFB15,GFB16,GFB17,GFB18,GFB19,GFC10,GFC11,GFC12,GFC13,GFC14,GFC15,GFC16,GFC17,GFC18,GFC19,';
     z := z + 'GFD10,GFD11,GFD12,GFD13,GFD14,GFD15,GFD16,GFD17,GFD18,GFD19,GFE10,GFE11,GFE12,GFE13,GFE14,';
     z := z + 'GFE15,GFE16,GFE17,GFE18,GFE19,GFF10,GFF11,GFF12,GFF13,GFF14,GFF15,GFF16,GFF17,GFF18,GFF19,';
     z := z + 'GFG10,GFG11,GFG12,GFG13,GFG14,GFG15,GFG16,GFG17,GFG18,GFG19,GFH10,GFH11,GFH12,GFH13,GFH14,';
     z := z + 'GFH15,GFH16,GFH17,GFH18,GFH19,GFI10,GFI11,GFI12,GFI13,GFI14,GFI15,GFI16,GFI17,GFI18,GFI19,';
     z := z + 'GFJ10,GFJ11,GFJ12,GFJ13,GFJ14,GFJ15,GFJ16,GFJ17,GFJ18,GFJ19,GFK10,GFK11,GFK12,GFK13,GFK14,';
     z := z + 'GFK15,GFK16,GFK17,GFK18,GFK19,GFL10,GFL11,GFL12,GFL13,GFL14,GFL15,GFL16,GFL17,GFL18,GFL19,';
     z := z + 'GFM10,GFM11,GFM12,GFM13,GFM14,GFM15,GFM16,GFM17,GFM18,GFM19,GFN10,GFN11,GFN12,GFN13,GFN14,';
     z := z + 'GFN15,GFN16,GFN17,GFN18,GFN19,GFO10,GFO11,GFO12,GFO13,GFO14,GFO15,GFO16,GFO17,GFO18,GFO19,';
     z := z + 'GFP10,GFP11,GFP12,GFP13,GFP14,GFP15,GFP16,GFP17,GFP18,GFP19,GFQ10,GFQ11,GFQ12,GFQ13,GFQ14,';
     z := z + 'GFQ15,GFQ16,GFQ17,GFQ18,GFQ19,GFR10,GFR11,GFR12,GFR13,GFR14,SKP2  ,SKP4  ,SKP5  ,SLA   ,SLU   ,';
     z := z + 'GFA00,GFA01,GFA02,GFA03,GFA04,GFA05,GFA06,GFA07,GFA08,GFA09,GFB00,GFB01,GFB02,GFB03,GFB04,';
     z := z + 'GFB05,GFB06,GFB07,GFB08,GFB09,GFC00,GFC01,GFC02,GFC03,GFC04,GFC05,GFC06,GFC07,GFC08,GFC09,';
     z := z + 'GFD00,GFD01,GFD02,GFD03,GFD04,GFD05,GFD06,GFD07,GFD08,GFD09,GFE00,GFE01,GFE02,GFE03,GFE04,';
     z := z + 'GFE05,GFE06,GFE07,GFE08,GFE09,GFF00,GFF01,GFF02,GFF03,GFF04,GFF05,GFF06,GFF07,GFF08,GFF09,';
     z := z + 'GFG00,GFG01,GFG02,GFG03,GFG04,GFG05,GFG06,GFG07,GFG08,GFG09,GFH00,GFH01,GFH02,GFH03,GFH04,';
     z := z + 'GFH05,GFH06,GFH07,GFH08,GFH09,GFI00,GFI01,GFI02,GFI03,GFI04,GFI05,GFI06,GFI07,GFI08,GFI09,';
     z := z + 'GFJ00,GFJ01,GFJ02,GFJ03,GFJ04,GFJ05,GFJ06,GFJ07,GFJ08,GFJ09,GFK00,GFK01,GFK02,GFK03,GFK04,';
     z := z + 'GFK05,GFK06,GFK07,GFK08,GFK09,GFL00,GFL01,GFL02,GFL03,GFL04,GFL05,GFL06,GFL07,GFL08,GFL09,';
     z := z + 'GFM00,GFM01,GFM02,GFM03,GFM04,GFM05,GFM06,GFM07,GFM08,GFM09,GFN00,GFN01,GFN02,GFN03,GFN04,';
     z := z + 'GFN05,GFN06,GFN07,GFN08,GFN09,GFO00,GFO01,GFO02,GFO03,GFO04,GFO05,GFO06,GFO07,GFO08,GFO09,';
     z := z + 'GFP00,GFP01,GFP02,GFP03,GFP04,GFP05,GFP06,GFP07,GFP08,GFP09,GFQ00,GFQ01,GFQ02,GFQ03,GFQ04,';
     z := z + 'GFQ05,GFQ06,GFQ07,GFQ08,GFQ09,GFR00,GFR01,GFR02,GFR03,GFR04,SLX   ,SLY   ,SLZ   ,SOA   ,SOD   ,';
     z := z + 'GEA90,GEA91,GEA92,GEA93,GEA94,GEA95,GEA96,GEA97,GEA98,GEA99,GEB90,GEB91,GEB92,GEB93,GEB94,';
     z := z + 'GEB95,GEB96,GEB97,GEB98,GEB99,GEC90,GEC91,GEC92,GEC93,GEC94,GEC95,GEC96,GEC97,GEC98,GEC99,';
     z := z + 'GED90,GED91,GED92,GED93,GED94,GED95,GED96,GED97,GED98,GED99,GEE90,GEE91,GEE92,GEE93,GEE94,';
     z := z + 'GEE95,GEE96,GEE97,GEE98,GEE99,GEF90,GEF91,GEF92,GEF93,GEF94,GEF95,GEF96,GEF97,GEF98,GEF99,';
     z := z + 'GEG90,GEG91,GEG92,GEG93,GEG94,GEG95,GEG96,GEG97,GEG98,GEG99,GEH90,GEH91,GEH92,GEH93,GEH94,';
     z := z + 'GEH95,GEH96,GEH97,GEH98,GEH99,GEI90,GEI91,GEI92,GEI93,GEI94,GEI95,GEI96,GEI97,GEI98,GEI99,';
     z := z + 'GEJ90,GEJ91,GEJ92,GEJ93,GEJ94,GEJ95,GEJ96,GEJ97,GEJ98,GEJ99,GEK90,GEK91,GEK92,GEK93,GEK94,';
     z := z + 'GEK95,GEK96,GEK97,GEK98,GEK99,GEL90,GEL91,GEL92,GEL93,GEL94,GEL95,GEL96,GEL97,GEL98,GEL99,';
     z := z + 'GEM90,GEM91,GEM92,GEM93,GEM94,GEM95,GEM96,GEM97,GEM98,GEM99,GEN90,GEN91,GEN92,GEN93,GEN94,';
     z := z + 'GEN95,GEN96,GEN97,GEN98,GEN99,GEO90,GEO91,GEO92,GEO93,GEO94,GEO95,GEO96,GEO97,GEO98,GEO99,';
     z := z + 'GEP90,GEP91,GEP92,GEP93,GEP94,GEP95,GEP96,GEP97,GEP98,GEP99,GEQ90,GEQ91,GEQ92,GEQ93,GEQ94,';
     z := z + 'GEQ95,GEQ96,GEQ97,GEQ98,GEQ99,GER90,GER91,GER92,GER93,GER94,SOE   ,SOH   ,SOH0  ,SOJ0  ,SOK   ,';
     z := z + 'GEA80,GEA81,GEA82,GEA83,GEA84,GEA85,GEA86,GEA87,GEA88,GEA89,GEB80,GEB81,GEB82,GEB83,GEB84,';
     z := z + 'GEB85,GEB86,GEB87,GEB88,GEB89,GEC80,GEC81,GEC82,GEC83,GEC84,GEC85,GEC86,GEC87,GEC88,GEC89,';
     z := z + 'GED80,GED81,GED82,GED83,GED84,GED85,GED86,GED87,GED88,GED89,GEE80,GEE81,GEE82,GEE83,GEE84,';
     z := z + 'GEE85,GEE86,GEE87,GEE88,GEE89,GEF80,GEF81,GEF82,GEF83,GEF84,GEF85,GEF86,GEF87,GEF88,GEF89,';
     z := z + 'GEG80,GEG81,GEG82,GEG83,GEG84,GEG85,GEG86,GEG87,GEG88,GEG89,GEH80,GEH81,GEH82,GEH83,GEH84,';
     z := z + 'GEH85,GEH86,GEH87,GEH88,GEH89,GEI80,GEI81,GEI82,GEI83,GEI84,GEI85,GEI86,GEI87,GEI88,GEI89,';
     z := z + 'GEJ80,GEJ81,GEJ82,GEJ83,GEJ84,GEJ85,GEJ86,GEJ87,GEJ88,GEJ89,GEK80,GEK81,GEK82,GEK83,GEK84,';
     z := z + 'GEK85,GEK86,GEK87,GEK88,GEK89,GEL80,GEL81,GEL82,GEL83,GEL84,GEL85,GEL86,GEL87,GEL88,GEL89,';
     z := z + 'GEM80,GEM81,GEM82,GEM83,GEM84,GEM85,GEM86,GEM87,GEM88,GEM89,GEN80,GEN81,GEN82,GEN83,GEN84,';
     z := z + 'GEN85,GEN86,GEN87,GEN88,GEN89,GEO80,GEO81,GEO82,GEO83,GEO84,GEO85,GEO86,GEO87,GEO88,GEO89,';
     z := z + 'GEP80,GEP81,GEP82,GEP83,GEP84,GEP85,GEP86,GEP87,GEP88,GEP89,GEQ80,GEQ81,GEQ82,GEQ83,GEQ84,';
     z := z + 'GEQ85,GEQ86,GEQ87,GEQ88,GEQ89,GER80,GER81,GER82,GER83,GER84,SOM   ,SON   ,SOX   ,SOY   ,SOZ   ,';
     z := z + 'GEA70,GEA71,GEA72,GEA73,GEA74,GEA75,GEA76,GEA77,GEA78,GEA79,GEB70,GEB71,GEB72,GEB73,GEB74,';
     z := z + 'GEB75,GEB76,GEB77,GEB78,GEB79,GEC70,GEC71,GEC72,GEC73,GEC74,GEC75,GEC76,GEC77,GEC78,GEC79,';
     z := z + 'GED70,GED71,GED72,GED73,GED74,GED75,GED76,GED77,GED78,GED79,GEE70,GEE71,GEE72,GEE73,GEE74,';
     z := z + 'GEE75,GEE76,GEE77,GEE78,GEE79,GEF70,GEF71,GEF72,GEF73,GEF74,GEF75,GEF76,GEF77,GEF78,GEF79,';
     z := z + 'GEG70,GEG71,GEG72,GEG73,GEG74,GEG75,GEG76,GEG77,GEG78,GEG79,GEH70,GEH71,GEH72,GEH73,GEH74,';
     z := z + 'GEH75,GEH76,GEH77,GEH78,GEH79,GEI70,GEI71,GEI72,GEI73,GEI74,GEI75,GEI76,GEI77,GEI78,GEI79,';
     z := z + 'GEJ70,GEJ71,GEJ72,GEJ73,GEJ74,GEJ75,GEJ76,GEJ77,GEJ78,GEJ79,GEK70,GEK71,GEK72,GEK73,GEK74,';
     z := z + 'GEK75,GEK76,GEK77,GEK78,GEK79,GEL70,GEL71,GEL72,GEL73,GEL74,GEL75,GEL76,GEL77,GEL78,GEL79,';
     z := z + 'GEM70,GEM71,GEM72,GEM73,GEM74,GEM75,GEM76,GEM77,GEM78,GEM79,GEN70,GEN71,GEN72,GEN73,GEN74,';
     z := z + 'GEN75,GEN76,GEN77,GEN78,GEN79,GEO70,GEO71,GEO72,GEO73,GEO74,GEO75,GEO76,GEO77,GEO78,GEO79,';
     z := z + 'GEP70,GEP71,GEP72,GEP73,GEP74,GEP75,GEP76,GEP77,GEP78,GEP79,GEQ70,GEQ71,GEQ72,GEQ73,GEQ74,';
     z := z + 'GEQ75,GEQ76,GEQ77,GEQ78,GEQ79,GER70,GER71,GER72,GER73,GER74,SP2   ,SP4   ,SPA   ,SPJ2  ,SPJ7  ,';
     z := z + 'GEA60,GEA61,GEA62,GEA63,GEA64,GEA65,GEA66,GEA67,GEA68,GEA69,GEB60,GEB61,GEB62,GEB63,GEB64,';
     z := z + 'GEB65,GEB66,GEB67,GEB68,GEB69,GEC60,GEC61,GEC62,GEC63,GEC64,GEC65,GEC66,GEC67,GEC68,GEC69,';
     z := z + 'GED60,GED61,GED62,GED63,GED64,GED65,GED66,GED67,GED68,GED69,GEE60,GEE61,GEE62,GEE63,GEE64,';
     z := z + 'GEE65,GEE66,GEE67,GEE68,GEE69,GEF60,GEF61,GEF62,GEF63,GEF64,GEF65,GEF66,GEF67,GEF68,GEF69,';
     z := z + 'GEG60,GEG61,GEG62,GEG63,GEG64,GEG65,GEG66,GEG67,GEG68,GEG69,GEH60,GEH61,GEH62,GEH63,GEH64,';
     z := z + 'GEH65,GEH66,GEH67,GEH68,GEH69,GEI60,GEI61,GEI62,GEI63,GEI64,GEI65,GEI66,GEI67,GEI68,GEI69,';
     z := z + 'GEJ60,GEJ61,GEJ62,GEJ63,GEJ64,GEJ65,GEJ66,GEJ67,GEJ68,GEJ69,GEK60,GEK61,GEK62,GEK63,GEK64,';
     z := z + 'GEK65,GEK66,GEK67,GEK68,GEK69,GEL60,GEL61,GEL62,GEL63,GEL64,GEL65,GEL66,GEL67,GEL68,GEL69,';
     z := z + 'GEM60,GEM61,GEM62,GEM63,GEM64,GEM65,GEM66,GEM67,GEM68,GEM69,GEN60,GEN61,GEN62,GEN63,GEN64,';
     z := z + 'GEN65,GEN66,GEN67,GEN68,GEN69,GEO60,GEO61,GEO62,GEO63,GEO64,GEO65,GEO66,GEO67,GEO68,GEO69,';
     z := z + 'GEP60,GEP61,GEP62,GEP63,GEP64,GEP65,GEP66,GEP67,GEP68,GEP69,GEQ60,GEQ61,GEQ62,GEQ63,GEQ64,';
     z := z + 'GEQ65,GEQ66,GEQ67,GEQ68,GEQ69,GER60,GER61,GER62,GER63,GER64,SPY   ,SPY0F ,SPT0S ,SPY0T ,SPZ   ,';
     z := z + 'GEA50,GEA51,GEA52,GEA53,GEA54,GEA55,GEA56,GEA57,GEA58,GEA59,GEB50,GEB51,GEB52,GEB53,GEB54,';
     z := z + 'GEB55,GEB56,GEB57,GEB58,GEB59,GEC50,GEC51,GEC52,GEC53,GEC54,GEC55,GEC56,GEC57,GEC58,GEC59,';
     z := z + 'GED50,GED51,GED52,GED53,GED54,GED55,GED56,GED57,GED58,GED59,GEE50,GEE51,GEE52,GEE53,GEE54,';
     z := z + 'GEE55,GEE56,GEE57,GEE58,GEE59,GEF50,GEF51,GEF52,GEF53,GEF54,GEF55,GEF56,GEF57,GEF58,GEF59,';
     z := z + 'GEG50,GEG51,GEG52,GEG53,GEG54,GEG55,GEG56,GEG57,GEG58,GEG59,GEH50,GEH51,GEH52,GEH53,GEH54,';
     z := z + 'GEH55,GEH56,GEH57,GEH58,GEH59,GEI50,GEI51,GEI52,GEI53,GEI54,GEI55,GEI56,GEI57,GEI58,GEI59,';
     z := z + 'GEJ50,GEJ51,GEJ52,GEJ53,GEJ54,GEJ55,GEJ56,GEJ57,GEJ58,GEJ59,GEK50,GEK51,GEK52,GEK53,GEK54,';
     z := z + 'GEK55,GEK56,GEK57,GEK58,GEK59,GEL50,GEL51,GEL52,GEL53,GEL54,GEL55,GEL56,GEL57,GEL58,GEL59,';
     z := z + 'GEM50,GEM51,GEM52,GEM53,GEM54,GEM55,GEM56,GEM57,GEM58,GEM59,GEN50,GEN51,GEN52,GEN53,GEN54,';
     z := z + 'GEN55,GEN56,GEN57,GEN58,GEN59,GEO50,GEO51,GEO52,GEO53,GEO54,GEO55,GEO56,GEO57,GEO58,GEO59,';
     z := z + 'GEP50,GEP51,GEP52,GEP53,GEP54,GEP55,GEP56,GEP57,GEP58,GEP59,GEQ50,GEQ51,GEQ52,GEQ53,GEQ54,';
     z := z + 'GEQ55,GEQ56,GEQ57,GEQ58,GEQ59,GER50,GER51,GER52,GER53,GER54,SR1F  ,SR1M  ,SS0   ,SS2   ,SS5   ,';
     z := z + 'GEA40,GEA41,GEA42,GEA43,GEA44,GEA45,GEA46,GEA47,GEA48,GEA49,GEB40,GEB41,GEB42,GEB43,GEB44,';
     z := z + 'GEB45,GEB46,GEB47,GEB48,GEB49,GEC40,GEC41,GEC42,GEC43,GEC44,GEC45,GEC46,GEC47,GEC48,GEC49,';
     z := z + 'GED40,GED41,GED42,GED43,GED44,GED45,GED46,GED47,GED48,GED49,GEE40,GEE41,GEE42,GEE43,GEE44,';
     z := z + 'GEE45,GEE46,GEE47,GEE48,GEE49,GEF40,GEF41,GEF42,GEF43,GEF44,GEF45,GEF46,GEF47,GEF48,GEF49,';
     z := z + 'GEG40,GEG41,GEG42,GEG43,GEG44,GEG45,GEG46,GEG47,GEG48,GEG49,GEH40,GEH41,GEH42,GEH43,GEH44,';
     z := z + 'GEH45,GEH46,GEH47,GEH48,GEH49,GEI40,GEI41,GEI42,GEI43,GEI44,GEI45,GEI46,GEI47,GEI48,GEI49,';
     z := z + 'GEJ40,GEJ41,GEJ42,GEJ43,GEJ44,GEJ45,GEJ46,GEJ47,GEJ48,GEJ49,GEK40,GEK41,GEK42,GEK43,GEK44,';
     z := z + 'GEK45,GEK46,GEK47,GEK48,GEK49,GEL40,GEL41,GEL42,GEL43,GEL44,GEL45,GEL46,GEL47,GEL48,GEL49,';
     z := z + 'GEM40,GEM41,GEM42,GEM43,GEM44,GEM45,GEM46,GEM47,GEM48,GEM49,GEN40,GEN41,GEN42,GEN43,GEN44,';
     z := z + 'GEN45,GEN46,GEN47,GEN48,GEN49,GEO40,GEO41,GEO42,GEO43,GEO44,GEO45,GEO46,GEO47,GEO48,GEO49,';
     z := z + 'GEP40,GEP41,GEP42,GEP43,GEP44,GEP45,GEP46,GEP47,GEP48,GEP49,GEQ40,GEQ41,GEQ42,GEQ43,GEQ44,';
     z := z + 'GEQ45,GEQ46,GEQ47,GEQ48,GEQ49,GER40,GER41,GER42,GER43,GER44,SS7   ,SS9   ,SSM   ,SSP   ,SST   ,';
     z := z + 'GEA30,GEA31,GEA32,GEA33,GEA34,GEA35,GEA36,GEA37,GEA38,GEA39,GEB30,GEB31,GEB32,GEB33,GEB34,';
     z := z + 'GEB35,GEB36,GEB37,GEB38,GEB39,GEC30,GEC31,GEC32,GEC33,GEC34,GEC35,GEC36,GEC37,GEC38,GEC39,';
     z := z + 'GED30,GED31,GED32,GED33,GED34,GED35,GED36,GED37,GED38,GED39,GEE30,GEE31,GEE32,GEE33,GEE34,';
     z := z + 'GEE35,GEE36,GEE37,GEE38,GEE39,GEF30,GEF31,GEF32,GEF33,GEF34,GEF35,GEF36,GEF37,GEF38,GEF39,';
     z := z + 'GEG30,GEG31,GEG32,GEG33,GEG34,GEG35,GEG36,GEG37,GEG38,GEG39,GEH30,GEH31,GEH32,GEH33,GEH34,';
     z := z + 'GEH35,GEH36,GEH37,GEH38,GEH39,GEI30,GEI31,GEI32,GEI33,GEI34,GEI35,GEI36,GEI37,GEI38,GEI39,';
     z := z + 'GEJ30,GEJ31,GEJ32,GEJ33,GEJ34,GEJ35,GEJ36,GEJ37,GEJ38,GEJ39,GEK30,GEK31,GEK32,GEK33,GEK34,';
     z := z + 'GEK35,GEK36,GEK37,GEK38,GEK39,GEL30,GEL31,GEL32,GEL33,GEL34,GEL35,GEL36,GEL37,GEL38,GEL39,';
     z := z + 'GEM30,GEM31,GEM32,GEM33,GEM34,GEM35,GEM36,GEM37,GEM38,GEM39,GEN30,GEN31,GEN32,GEN33,GEN34,';
     z := z + 'GEN35,GEN36,GEN37,GEN38,GEN39,GEO30,GEO31,GEO32,GEO33,GEO34,GEO35,GEO36,GEO37,GEO38,GEO39,';
     z := z + 'GEP30,GEP31,GEP32,GEP33,GEP34,GEP35,GEP36,GEP37,GEP38,GEP39,GEQ30,GEQ31,GEQ32,GEQ33,GEQ34,';
     z := z + 'GEQ35,GEQ36,GEQ37,GEQ38,GEQ39,GER30,GER31,GER32,GER33,GER34,SSU   ,SSV   ,SSVA  ,SSV5  ,SSV9  ,';
     z := z + 'GEA20,GEA21,GEA22,GEA23,GEA24,GEA25,GEA26,GEA27,GEA28,GEA29,GEB20,GEB21,GEB22,GEB23,GEB24,';
     z := z + 'GEB25,GEB26,GEB27,GEB28,GEB29,GEC20,GEC21,GEC22,GEC23,GEC24,GEC25,GEC26,GEC27,GEC28,GEC29,';
     z := z + 'GED20,GED21,GED22,GED23,GED24,GED25,GED26,GED27,GED28,GED29,GEE20,GEE21,GEE22,GEE23,GEE24,';
     z := z + 'GEE25,GEE26,GEE27,GEE28,GEE29,GEF20,GEF21,GEF22,GEF23,GEF24,GEF25,GEF26,GEF27,GEF28,GEF29,';
     z := z + 'GEG20,GEG21,GEG22,GEG23,GEG24,GEG25,GEG26,GEG27,GEG28,GEG29,GEH20,GEH21,GEH22,GEH23,GEH24,';
     z := z + 'GEH25,GEH26,GEH27,GEH28,GEH29,GEI20,GEI21,GEI22,GEI23,GEI24,GEI25,GEI26,GEI27,GEI28,GEI29,';
     z := z + 'GEJ20,GEJ21,GEJ22,GEJ23,GEJ24,GEJ25,GEJ26,GEJ27,GEJ28,GEJ29,GEK20,GEK21,GEK22,GEK23,GEK24,';
     z := z + 'GEK25,GEK26,GEK27,GEK28,GEK29,GEL20,GEL21,GEL22,GEL23,GEL24,GEL25,GEL26,GEL27,GEL28,GEL29,';
     z := z + 'GEM20,GEM21,GEM22,GEM23,GEM24,GEM25,GEM26,GEM27,GEM28,GEM29,GEN20,GEN21,GEN22,GEN23,GEN24,';
     z := z + 'GEN25,GEN26,GEN27,GEN28,GEN29,GEO20,GEO21,GEO22,GEO23,GEO24,GEO25,GEO26,GEO27,GEO28,GEO29,';
     z := z + 'GEP20,GEP21,GEP22,GEP23,GEP24,GEP25,GEP26,GEP27,GEP28,GEP29,GEQ20,GEQ21,GEQ22,GEQ23,GEQ24,';
     z := z + 'GEQ25,GEQ26,GEQ27,GEQ28,GEQ29,GER20,GER21,GER22,GER23,GER24,ST2   ,ST30  ,ST31  ,ST32  ,ST33  ,';
     z := z + 'GEA10,GEA11,GEA12,GEA13,GEA14,GEA15,GEA16,GEA17,GEA18,GEA19,GEB10,GEB11,GEB12,GEB13,GEB14,';
     z := z + 'GEB15,GEB16,GEB17,GEB18,GEB19,GEC10,GEC11,GEC12,GEC13,GEC14,GEC15,GEC16,GEC17,GEC18,GEC19,';
     z := z + 'GED10,GED11,GED12,GED13,GED14,GED15,GED16,GED17,GED18,GED19,GEE10,GEE11,GEE12,GEE13,GEE14,';
     z := z + 'GEE15,GEE16,GEE17,GEE18,GEE19,GEF10,GEF11,GEF12,GEF13,GEF14,GEF15,GEF16,GEF17,GEF18,GEF19,';
     z := z + 'GEG10,GEG11,GEG12,GEG13,GEG14,GEG15,GEG16,GEG17,GEG18,GEG19,GEH10,GEH11,GEH12,GEH13,GEH14,';
     z := z + 'GEH15,GEH16,GEH17,GEH18,GEH19,GEI10,GEI11,GEI12,GEI13,GEI14,GEI15,GEI16,GEI17,GEI18,GEI19,';
     z := z + 'GEJ10,GEJ11,GEJ12,GEJ13,GEJ14,GEJ15,GEJ16,GEJ17,GEJ18,GEJ19,GEK10,GEK11,GEK12,GEK13,GEK14,';
     z := z + 'GEK15,GEK16,GEK17,GEK18,GEK19,GEL10,GEL11,GEL12,GEL13,GEL14,GEL15,GEL16,GEL17,GEL18,GEL19,';
     z := z + 'GEM10,GEM11,GEM12,GEM13,GEM14,GEM15,GEM16,GEM17,GEM18,GEM19,GEN10,GEN11,GEN12,GEN13,GEN14,';
     z := z + 'GEN15,GEN16,GEN17,GEN18,GEN19,GEO10,GEO11,GEO12,GEO13,GEO14,GEO15,GEO16,GEO17,GEO18,GEO19,';
     z := z + 'GEP10,GEP11,GEP12,GEP13,GEP14,GEP15,GEP16,GEP17,GEP18,GEP19,GEQ10,GEQ11,GEQ12,GEQ13,GEQ14,';
     z := z + 'GEQ15,GEQ16,GEQ17,GEQ18,GEQ19,GER10,GER11,GER12,GER13,GER14,ST5   ,ST7   ,ST8   ,ST9   ,STA   ,';
     z := z + 'GEA00,GEA01,GEA02,GEA03,GEA04,GEA05,GEA06,GEA07,GEA08,GEA09,GEB00,GEB01,GEB02,GEB03,GEB04,';
     z := z + 'GEB05,GEB06,GEB07,GEB08,GEB09,GEC00,GEC01,GEC02,GEC03,GEC04,GEC05,GEC06,GEC07,GEC08,GEC09,';
     z := z + 'GED00,GED01,GED02,GED03,GED04,GED05,GED06,GED07,GED08,GED09,GEE00,GEE01,GEE02,GEE03,GEE04,';
     z := z + 'GEE05,GEE06,GEE07,GEE08,GEE09,GEF00,GEF01,GEF02,GEF03,GEF04,GEF05,GEF06,GEF07,GEF08,GEF09,';
     z := z + 'GEG00,GEG01,GEG02,GEG03,GEG04,GEG05,GEG06,GEG07,GEG08,GEG09,GEH00,GEH01,GEH02,GEH03,GEH04,';
     z := z + 'GEH05,GEH06,GEH07,GEH08,GEH09,GEI00,GEI01,GEI02,GEI03,GEI04,GEI05,GEI06,GEI07,GEI08,GEI09,';
     z := z + 'GEJ00,GEJ01,GEJ02,GEJ03,GEJ04,GEJ05,GEJ06,GEJ07,GEJ08,GEJ09,GEK00,GEK01,GEK02,GEK03,GEK04,';
     z := z + 'GEK05,GEK06,GEK07,GEK08,GEK09,GEL00,GEL01,GEL02,GEL03,GEL04,GEL05,GEL06,GEL07,GEL08,GEL09,';
     z := z + 'GEM00,GEM01,GEM02,GEM03,GEM04,GEM05,GEM06,GEM07,GEM08,GEM09,GEN00,GEN01,GEN02,GEN03,GEN04,';
     z := z + 'GEN05,GEN06,GEN07,GEN08,GEN09,GEO00,GEO01,GEO02,GEO03,GEO04,GEO05,GEO06,GEO07,GEO08,GEO09,';
     z := z + 'GEP00,GEP01,GEP02,GEP03,GEP04,GEP05,GEP06,GEP07,GEP08,GEP09,GEQ00,GEQ01,GEQ02,GEQ03,GEQ04,';
     z := z + 'GEQ05,GEQ06,GEQ07,GEQ08,GEQ09,GER00,GER01,GER02,GER03,GER04,STF   ,STG   ,STI   ,STI9  ,STJ   ,';
     z := z + 'GDA90,GDA91,GDA92,GDA93,GDA94,GDA95,GDA96,GDA97,GDA98,GDA99,GDB90,GDB91,GDB92,GDB93,GDB94,';
     z := z + 'GDB95,GDB96,GDB97,GDB98,GDB99,GDC90,GDC91,GDC92,GDC93,GDC94,GDC95,GDC96,GDC97,GDC98,GDC99,';
     z := z + 'GDD90,GDD91,GDD92,GDD93,GDD94,GDD95,GDD96,GDD97,GDD98,GDD99,GDE90,GDE91,GDE92,GDE93,GDE94,';
     z := z + 'GDE95,GDE96,GDE97,GDE98,GDE99,GDF90,GDF91,GDF92,GDF93,GDF94,GDF95,GDF96,GDF97,GDF98,GDF99,';
     z := z + 'GDG90,GDG91,GDG92,GDG93,GDG94,GDG95,GDG96,GDG97,GDG98,GDG99,GDH90,GDH91,GDH92,GDH93,GDH94,';
     z := z + 'GDH95,GDH96,GDH97,GDH98,GDH99,GDI90,GDI91,GDI92,GDI93,GDI94,GDI95,GDI96,GDI97,GDI98,GDI99,';
     z := z + 'GDJ90,GDJ91,GDJ92,GDJ93,GDJ94,GDJ95,GDJ96,GDJ97,GDJ98,GDJ99,GDK90,GDK91,GDK92,GDK93,GDK94,';
     z := z + 'GDK95,GDK96,GDK97,GDK98,GDK99,GDL90,GDL91,GDL92,GDL93,GDL94,GDL95,GDL96,GDL97,GDL98,GDL99,';
     z := z + 'GDM90,GDM91,GDM92,GDM93,GDM94,GDM95,GDM96,GDM97,GDM98,GDM99,GDN90,GDN91,GDN92,GDN93,GDN94,';
     z := z + 'GDN95,GDN96,GDN97,GDN98,GDN99,GDO90,GDO91,GDO92,GDO93,GDO94,GDO95,GDO96,GDO97,GDO98,GDO99,';
     z := z + 'GDP90,GDP91,GDP92,GDP93,GDP94,GDP95,GDP96,GDP97,GDP98,GDP99,GDQ90,GDQ91,GDQ92,GDQ93,GDQ94,';
     z := z + 'GDQ95,GDQ96,GDQ97,GDQ98,GDQ99,GDR90,GDR91,GDR92,GDR93,GDR94,STK   ,STL   ,STN   ,STR   ,STT   ,';
     z := z + 'GDA80,GDA81,GDA82,GDA83,GDA84,GDA85,GDA86,GDA87,GDA88,GDA89,GDB80,GDB81,GDB82,GDB83,GDB84,';
     z := z + 'GDB85,GDB86,GDB87,GDB88,GDB89,GDC80,GDC81,GDC82,GDC83,GDC84,GDC85,GDC86,GDC87,GDC88,GDC89,';
     z := z + 'GDD80,GDD81,GDD82,GDD83,GDD84,GDD85,GDD86,GDD87,GDD88,GDD89,GDE80,GDE81,GDE82,GDE83,GDE84,';
     z := z + 'GDE85,GDE86,GDE87,GDE88,GDE89,GDF80,GDF81,GDF82,GDF83,GDF84,GDF85,GDF86,GDF87,GDF88,GDF89,';
     z := z + 'GDG80,GDG81,GDG82,GDG83,GDG84,GDG85,GDG86,GDG87,GDG88,GDG89,GDH80,GDH81,GDH82,GDH83,GDH84,';
     z := z + 'GDH85,GDH86,GDH87,GDH88,GDH89,GDI80,GDI81,GDI82,GDI83,GDI84,GDI85,GDI86,GDI87,GDI88,GDI89,';
     z := z + 'GDJ80,GDJ81,GDJ82,GDJ83,GDJ84,GDJ85,GDJ86,GDJ87,GDJ88,GDJ89,GDK80,GDK81,GDK82,GDK83,GDK84,';
     z := z + 'GDK85,GDK86,GDK87,GDK88,GDK89,GDL80,GDL81,GDL82,GDL83,GDL84,GDL85,GDL86,GDL87,GDL88,GDL89,';
     z := z + 'GDM80,GDM81,GDM82,GDM83,GDM84,GDM85,GDM86,GDM87,GDM88,GDM89,GDN80,GDN81,GDN82,GDN83,GDN84,';
     z := z + 'GDN85,GDN86,GDN87,GDN88,GDN89,GDO80,GDO81,GDO82,GDO83,GDO84,GDO85,GDO86,GDO87,GDO88,GDO89,';
     z := z + 'GDP80,GDP81,GDP82,GDP83,GDP84,GDP85,GDP86,GDP87,GDP88,GDP89,GDQ80,GDQ81,GDQ82,GDQ83,GDQ84,';
     z := z + 'GDQ85,GDQ86,GDQ87,GDQ88,GDQ89,GDR80,GDR81,GDR82,GDR83,GDR84,STU   ,STY   ,STZ   ,SUA   ,SUA2  ,';
     z := z + 'GDA70,GDA71,GDA72,GDA73,GDA74,GDA75,GDA76,GDA77,GDA78,GDA79,GDB70,GDB71,GDB72,GDB73,GDB74,';
     z := z + 'GDB75,GDB76,GDB77,GDB78,GDB79,GDC70,GDC71,GDC72,GDC73,GDC74,GDC75,GDC76,GDC77,GDC78,GDC79,';
     z := z + 'GDD70,GDD71,GDD72,GDD73,GDD74,GDD75,GDD76,GDD77,GDD78,GDD79,GDE70,GDE71,GDE72,GDE73,GDE74,';
     z := z + 'GDE75,GDE76,GDE77,GDE78,GDE79,GDF70,GDF71,GDF72,GDF73,GDF74,GDF75,GDF76,GDF77,GDF78,GDF79,';
     z := z + 'GDG70,GDG71,GDG72,GDG73,GDG74,GDG75,GDG76,GDG77,GDG78,GDG79,GDH70,GDH71,GDH72,GDH73,GDH74,';
     z := z + 'GDH75,GDH76,GDH77,GDH78,GDH79,GDI70,GDI71,GDI72,GDI73,GDI74,GDI75,GDI76,GDI77,GDI78,GDI79,';
     z := z + 'GDJ70,GDJ71,GDJ72,GDJ73,GDJ74,GDJ75,GDJ76,GDJ77,GDJ78,GDJ79,GDK70,GDK71,GDK72,GDK73,GDK74,';
     z := z + 'GDK75,GDK76,GDK77,GDK78,GDK79,GDL70,GDL71,GDL72,GDL73,GDL74,GDL75,GDL76,GDL77,GDL78,GDL79,';
     z := z + 'GDM70,GDM71,GDM72,GDM73,GDM74,GDM75,GDM76,GDM77,GDM78,GDM79,GDN70,GDN71,GDN72,GDN73,GDN74,';
     z := z + 'GDN75,GDN76,GDN77,GDN78,GDN79,GDO70,GDO71,GDO72,GDO73,GDO74,GDO75,GDO76,GDO77,GDO78,GDO79,';
     z := z + 'GDP70,GDP71,GDP72,GDP73,GDP74,GDP75,GDP76,GDP77,GDP78,GDP79,GDQ70,GDQ71,GDQ72,GDQ73,GDQ74,';
     z := z + 'GDQ75,GDQ76,GDQ77,GDQ78,GDQ79,GDR70,GDR71,GDR72,GDR73,GDR74,SUA9  ,SUK   ,SUN   ,SUR   ,SV2   ,';
     z := z + 'GDA60,GDA61,GDA62,GDA63,GDA64,GDA65,GDA66,GDA67,GDA68,GDA69,GDB60,GDB61,GDB62,GDB63,GDB64,';
     z := z + 'GDB65,GDB66,GDB67,GDB68,GDB69,GDC60,GDC61,GDC62,GDC63,GDC64,GDC65,GDC66,GDC67,GDC68,GDC69,';
     z := z + 'GDD60,GDD61,GDD62,GDD63,GDD64,GDD65,GDD66,GDD67,GDD68,GDD69,GDE60,GDE61,GDE62,GDE63,GDE64,';
     z := z + 'GDE65,GDE66,GDE67,GDE68,GDE69,GDF60,GDF61,GDF62,GDF63,GDF64,GDF65,GDF66,GDF67,GDF68,GDF69,';
     z := z + 'GDG60,GDG61,GDG62,GDG63,GDG64,GDG65,GDG66,GDG67,GDG68,GDG69,GDH60,GDH61,GDH62,GDH63,GDH64,';
     z := z + 'GDH65,GDH66,GDH67,GDH68,GDH69,GDI60,GDI61,GDI62,GDI63,GDI64,GDI65,GDI66,GDI67,GDI68,GDI69,';
     z := z + 'GDJ60,GDJ61,GDJ62,GDJ63,GDJ64,GDJ65,GDJ66,GDJ67,GDJ68,GDJ69,GDK60,GDK61,GDK62,GDK63,GDK64,';
     z := z + 'GDK65,GDK66,GDK67,GDK68,GDK69,GDL60,GDL61,GDL62,GDL63,GDL64,GDL65,GDL66,GDL67,GDL68,GDL69,';
     z := z + 'GDM60,GDM61,GDM62,GDM63,GDM64,GDM65,GDM66,GDM67,GDM68,GDM69,GDN60,GDN61,GDN62,GDN63,GDN64,';
     z := z + 'GDN65,GDN66,GDN67,GDN68,GDN69,GDO60,GDO61,GDO62,GDO63,GDO64,GDO65,GDO66,GDO67,GDO68,GDO69,';
     z := z + 'GDP60,GDP61,GDP62,GDP63,GDP64,GDP65,GDP66,GDP67,GDP68,GDP69,GDQ60,GDQ61,GDQ62,GDQ63,GDQ64,';
     z := z + 'GDQ65,GDQ66,GDQ67,GDQ68,GDQ69,GDR60,GDR61,GDR62,GDR63,GDR64,SV3   ,SV4   ,SV5   ,SV6   ,SV7   ,';
     z := z + 'GDA50,GDA51,GDA52,GDA53,GDA54,GDA55,GDA56,GDA57,GDA58,GDA59,GDB50,GDB51,GDB52,GDB53,GDB54,';
     z := z + 'GDB55,GDB56,GDB57,GDB58,GDB59,GDC50,GDC51,GDC52,GDC53,GDC54,GDC55,GDC56,GDC57,GDC58,GDC59,';
     z := z + 'GDD50,GDD51,GDD52,GDD53,GDD54,GDD55,GDD56,GDD57,GDD58,GDD59,GDE50,GDE51,GDE52,GDE53,GDE54,';
     z := z + 'GDE55,GDE56,GDE57,GDE58,GDE59,GDF50,GDF51,GDF52,GDF53,GDF54,GDF55,GDF56,GDF57,GDF58,GDF59,';
     z := z + 'GDG50,GDG51,GDG52,GDG53,GDG54,GDG55,GDG56,GDG57,GDG58,GDG59,GDH50,GDH51,GDH52,GDH53,GDH54,';
     z := z + 'GDH55,GDH56,GDH57,GDH58,GDH59,GDI50,GDI51,GDI52,GDI53,GDI54,GDI55,GDI56,GDI57,GDI58,GDI59,';
     z := z + 'GDJ50,GDJ51,GDJ52,GDJ53,GDJ54,GDJ55,GDJ56,GDJ57,GDJ58,GDJ59,GDK50,GDK51,GDK52,GDK53,GDK54,';
     z := z + 'GDK55,GDK56,GDK57,GDK58,GDK59,GDL50,GDL51,GDL52,GDL53,GDL54,GDL55,GDL56,GDL57,GDL58,GDL59,';
     z := z + 'GDM50,GDM51,GDM52,GDM53,GDM54,GDM55,GDM56,GDM57,GDM58,GDM59,GDN50,GDN51,GDN52,GDN53,GDN54,';
     z := z + 'GDN55,GDN56,GDN57,GDN58,GDN59,GDO50,GDO51,GDO52,GDO53,GDO54,GDO55,GDO56,GDO57,GDO58,GDO59,';
     z := z + 'GDP50,GDP51,GDP52,GDP53,GDP54,GDP55,GDP56,GDP57,GDP58,GDP59,GDQ50,GDQ51,GDQ52,GDQ53,GDQ54,';
     z := z + 'GDQ55,GDQ56,GDQ57,GDQ58,GDQ59,GDR50,GDR51,GDR52,GDR53,GDR54,SV8   ,SVE   ,SVK   ,SVK0H ,SVK0M ,';
     z := z + 'GDA40,GDA41,GDA42,GDA43,GDA44,GDA45,GDA46,GDA47,GDA48,GDA49,GDB40,GDB41,GDB42,GDB43,GDB44,';
     z := z + 'GDB45,GDB46,GDB47,GDB48,GDB49,GDC40,GDC41,GDC42,GDC43,GDC44,GDC45,GDC46,GDC47,GDC48,GDC49,';
     z := z + 'GDD40,GDD41,GDD42,GDD43,GDD44,GDD45,GDD46,GDD47,GDD48,GDD49,GDE40,GDE41,GDE42,GDE43,GDE44,';
     z := z + 'GDE45,GDE46,GDE47,GDE48,GDE49,GDF40,GDF41,GDF42,GDF43,GDF44,GDF45,GDF46,GDF47,GDF48,GDF49,';
     z := z + 'GDG40,GDG41,GDG42,GDG43,GDG44,GDG45,GDG46,GDG47,GDG48,GDG49,GDH40,GDH41,GDH42,GDH43,GDH44,';
     z := z + 'GDH45,GDH46,GDH47,GDH48,GDH49,GDI40,GDI41,GDI42,GDI43,GDI44,GDI45,GDI46,GDI47,GDI48,GDI49,';
     z := z + 'GDJ40,GDJ41,GDJ42,GDJ43,GDJ44,GDJ45,GDJ46,GDJ47,GDJ48,GDJ49,GDK40,GDK41,GDK42,GDK43,GDK44,';
     z := z + 'GDK45,GDK46,GDK47,GDK48,GDK49,GDL40,GDL41,GDL42,GDL43,GDL44,GDL45,GDL46,GDL47,GDL48,GDL49,';
     z := z + 'GDM40,GDM41,GDM42,GDM43,GDM44,GDM45,GDM46,GDM47,GDM48,GDM49,GDN40,GDN41,GDN42,GDN43,GDN44,';
     z := z + 'GDN45,GDN46,GDN47,GDN48,GDN49,GDO40,GDO41,GDO42,GDO43,GDO44,GDO45,GDO46,GDO47,GDO48,GDO49,';
     z := z + 'GDP40,GDP41,GDP42,GDP43,GDP44,GDP45,GDP46,GDP47,GDP48,GDP49,GDQ40,GDQ41,GDQ42,GDQ43,GDQ44,';
     z := z + 'GDQ45,GDQ46,GDQ47,GDQ48,GDQ49,GDR40,GDR41,GDR42,GDR43,GDR44,SVK9C ,SVK9L ,SVK9M ,SVK9N ,SVK9W ,';
     z := z + 'GDA30,GDA31,GDA32,GDA33,GDA34,GDA35,GDA36,GDA37,GDA38,GDA39,GDB30,GDB31,GDB32,GDB33,GDB34,';
     z := z + 'GDB35,GDB36,GDB37,GDB38,GDB39,GDC30,GDC31,GDC32,GDC33,GDC34,GDC35,GDC36,GDC37,GDC38,GDC39,';
     z := z + 'GDD30,GDD31,GDD32,GDD33,GDD34,GDD35,GDD36,GDD37,GDD38,GDD39,GDE30,GDE31,GDE32,GDE33,GDE34,';
     z := z + 'GDE35,GDE36,GDE37,GDE38,GDE39,GDF30,GDF31,GDF32,GDF33,GDF34,GDF35,GDF36,GDF37,GDF38,GDF39,';
     z := z + 'GDG30,GDG31,GDG32,GDG33,GDG34,GDG35,GDG36,GDG37,GDG38,GDG39,GDH30,GDH31,GDH32,GDH33,GDH34,';
     z := z + 'GDH35,GDH36,GDH37,GDH38,GDH39,GDI30,GDI31,GDI32,GDI33,GDI34,GDI35,GDI36,GDI37,GDI38,GDI39,';
     z := z + 'GDJ30,GDJ31,GDJ32,GDJ33,GDJ34,GDJ35,GDJ36,GDJ37,GDJ38,GDJ39,GDK30,GDK31,GDK32,GDK33,GDK34,';
     z := z + 'GDK35,GDK36,GDK37,GDK38,GDK39,GDL30,GDL31,GDL32,GDL33,GDL34,GDL35,GDL36,GDL37,GDL38,GDL39,';
     z := z + 'GDM30,GDM31,GDM32,GDM33,GDM34,GDM35,GDM36,GDM37,GDM38,GDM39,GDN30,GDN31,GDN32,GDN33,GDN34,';
     z := z + 'GDN35,GDN36,GDN37,GDN38,GDN39,GDO30,GDO31,GDO32,GDO33,GDO34,GDO35,GDO36,GDO37,GDO38,GDO39,';
     z := z + 'GDP30,GDP31,GDP32,GDP33,GDP34,GDP35,GDP36,GDP37,GDP38,GDP39,GDQ30,GDQ31,GDQ32,GDQ33,GDQ34,';
     z := z + 'GDQ35,GDQ36,GDQ37,GDQ38,GDQ39,GDR30,GDR31,GDR32,GDR33,GDR34,SVK9X ,SVP2E ,SVP2M ,SVP2V ,SVP5  ,';
     z := z + 'GDA20,GDA21,GDA22,GDA23,GDA24,GDA25,GDA26,GDA27,GDA28,GDA29,GDB20,GDB21,GDB22,GDB23,GDB24,';
     z := z + 'GDB25,GDB26,GDB27,GDB28,GDB29,GDC20,GDC21,GDC22,GDC23,GDC24,GDC25,GDC26,GDC27,GDC28,GDC29,';
     z := z + 'GDD20,GDD21,GDD22,GDD23,GDD24,GDD25,GDD26,GDD27,GDD28,GDD29,GDE20,GDE21,GDE22,GDE23,GDE24,';
     z := z + 'GDE25,GDE26,GDE27,GDE28,GDE29,GDF20,GDF21,GDF22,GDF23,GDF24,GDF25,GDF26,GDF27,GDF28,GDF29,';
     z := z + 'GDG20,GDG21,GDG22,GDG23,GDG24,GDG25,GDG26,GDG27,GDG28,GDG29,GDH20,GDH21,GDH22,GDH23,GDH24,';
     z := z + 'GDH25,GDH26,GDH27,GDH28,GDH29,GDI20,GDI21,GDI22,GDI23,GDI24,GDI25,GDI26,GDI27,GDI28,GDI29,';
     z := z + 'GDJ20,GDJ21,GDJ22,GDJ23,GDJ24,GDJ25,GDJ26,GDJ27,GDJ28,GDJ29,GDK20,GDK21,GDK22,GDK23,GDK24,';
     z := z + 'GDK25,GDK26,GDK27,GDK28,GDK29,GDL20,GDL21,GDL22,GDL23,GDL24,GDL25,GDL26,GDL27,GDL28,GDL29,';
     z := z + 'GDM20,GDM21,GDM22,GDM23,GDM24,GDM25,GDM26,GDM27,GDM28,GDM29,GDN20,GDN21,GDN22,GDN23,GDN24,';
     z := z + 'GDN25,GDN26,GDN27,GDN28,GDN29,GDO20,GDO21,GDO22,GDO23,GDO24,GDO25,GDO26,GDO27,GDO28,GDO29,';
     z := z + 'GDP20,GDP21,GDP22,GDP23,GDP24,GDP25,GDP26,GDP27,GDP28,GDP29,GDQ20,GDQ21,GDQ22,GDQ23,GDQ24,';
     z := z + 'GDQ25,GDQ26,GDQ27,GDQ28,GDQ29,GDR20,GDR21,GDR22,GDR23,GDR24,SVP6  ,SVP6D ,SVP8  ,SVP8G ,SVP8H ,';
     z := z + 'GDA10,GDA11,GDA12,GDA13,GDA14,GDA15,GDA16,GDA17,GDA18,GDA19,GDB10,GDB11,GDB12,GDB13,GDB14,';
     z := z + 'GDB15,GDB16,GDB17,GDB18,GDB19,GDC10,GDC11,GDC12,GDC13,GDC14,GDC15,GDC16,GDC17,GDC18,GDC19,';
     z := z + 'GDD10,GDD11,GDD12,GDD13,GDD14,GDD15,GDD16,GDD17,GDD18,GDD19,GDE10,GDE11,GDE12,GDE13,GDE14,';
     z := z + 'GDE15,GDE16,GDE17,GDE18,GDE19,GDF10,GDF11,GDF12,GDF13,GDF14,GDF15,GDF16,GDF17,GDF18,GDF19,';
     z := z + 'GDG10,GDG11,GDG12,GDG13,GDG14,GDG15,GDG16,GDG17,GDG18,GDG19,GDH10,GDH11,GDH12,GDH13,GDH14,';
     z := z + 'GDH15,GDH16,GDH17,GDH18,GDH19,GDI10,GDI11,GDI12,GDI13,GDI14,GDI15,GDI16,GDI17,GDI18,GDI19,';
     z := z + 'GDJ10,GDJ11,GDJ12,GDJ13,GDJ14,GDJ15,GDJ16,GDJ17,GDJ18,GDJ19,GDK10,GDK11,GDK12,GDK13,GDK14,';
     z := z + 'GDK15,GDK16,GDK17,GDK18,GDK19,GDL10,GDL11,GDL12,GDL13,GDL14,GDL15,GDL16,GDL17,GDL18,GDL19,';
     z := z + 'GDM10,GDM11,GDM12,GDM13,GDM14,GDM15,GDM16,GDM17,GDM18,GDM19,GDN10,GDN11,GDN12,GDN13,GDN14,';
     z := z + 'GDN15,GDN16,GDN17,GDN18,GDN19,GDO10,GDO11,GDO12,GDO13,GDO14,GDO15,GDO16,GDO17,GDO18,GDO19,';
     z := z + 'GDP10,GDP11,GDP12,GDP13,GDP14,GDP15,GDP16,GDP17,GDP18,GDP19,GDQ10,GDQ11,GDQ12,GDQ13,GDQ14,';
     z := z + 'GDQ15,GDQ16,GDQ17,GDQ18,GDQ19,GDR10,GDR11,GDR12,GDR13,GDR14,SVP8O ,SVP8S ,SVP9  ,SVQ9  ,SVR   ,';
     z := z + 'GDA00,GDA01,GDA02,GDA03,GDA04,GDA05,GDA06,GDA07,GDA08,GDA09,GDB00,GDB01,GDB02,GDB03,GDB04,';
     z := z + 'GDB05,GDB06,GDB07,GDB08,GDB09,GDC00,GDC01,GDC02,GDC03,GDC04,GDC05,GDC06,GDC07,GDC08,GDC09,';
     z := z + 'GDD00,GDD01,GDD02,GDD03,GDD04,GDD05,GDD06,GDD07,GDD08,GDD09,GDE00,GDE01,GDE02,GDE03,GDE04,';
     z := z + 'GDE05,GDE06,GDE07,GDE08,GDE09,GDF00,GDF01,GDF02,GDF03,GDF04,GDF05,GDF06,GDF07,GDF08,GDF09,';
     z := z + 'GDG00,GDG01,GDG02,GDG03,GDG04,GDG05,GDG06,GDG07,GDG08,GDG09,GDH00,GDH01,GDH02,GDH03,GDH04,';
     z := z + 'GDH05,GDH06,GDH07,GDH08,GDH09,GDI00,GDI01,GDI02,GDI03,GDI04,GDI05,GDI06,GDI07,GDI08,GDI09,';
     z := z + 'GDJ00,GDJ01,GDJ02,GDJ03,GDJ04,GDJ05,GDJ06,GDJ07,GDJ08,GDJ09,GDK00,GDK01,GDK02,GDK03,GDK04,';
     z := z + 'GDK05,GDK06,GDK07,GDK08,GDK09,GDL00,GDL01,GDL02,GDL03,GDL04,GDL05,GDL06,GDL07,GDL08,GDL09,';
     z := z + 'GDM00,GDM01,GDM02,GDM03,GDM04,GDM05,GDM06,GDM07,GDM08,GDM09,GDN00,GDN01,GDN02,GDN03,GDN04,';
     z := z + 'GDN05,GDN06,GDN07,GDN08,GDN09,GDO00,GDO01,GDO02,GDO03,GDO04,GDO05,GDO06,GDO07,GDO08,GDO09,';
     z := z + 'GDP00,GDP01,GDP02,GDP03,GDP04,GDP05,GDP06,GDP07,GDP08,GDP09,GDQ00,GDQ01,GDQ02,GDQ03,GDQ04,';
     z := z + 'GDQ05,GDQ06,GDQ07,GDQ08,GDQ09,GDR00,GDR01,GDR02,GDR03,GDR04,SVU   ,SVU4  ,SVU7  ,SXE   ,SXF4  ,';
     z := z + 'GCA90,GCA91,GCA92,GCA93,GCA94,GCA95,GCA96,GCA97,GCA98,GCA99,GCB90,GCB91,GCB92,GCB93,GCB94,';
     z := z + 'GCB95,GCB96,GCB97,GCB98,GCB99,GCC90,GCC91,GCC92,GCC93,GCC94,GCC95,GCC96,GCC97,GCC98,GCC99,';
     z := z + 'GCD90,GCD91,GCD92,GCD93,GCD94,GCD95,GCD96,GCD97,GCD98,GCD99,GCE90,GCE91,GCE92,GCE93,GCE94,';
     z := z + 'GCE95,GCE96,GCE97,GCE98,GCE99,GCF90,GCF91,GCF92,GCF93,GCF94,GCF95,GCF96,GCF97,GCF98,GCF99,';
     z := z + 'GCG90,GCG91,GCG92,GCG93,GCG94,GCG95,GCG96,GCG97,GCG98,GCG99,GCH90,GCH91,GCH92,GCH93,GCH94,';
     z := z + 'GCH95,GCH96,GCH97,GCH98,GCH99,GCI90,GCI91,GCI92,GCI93,GCI94,GCI95,GCI96,GCI97,GCI98,GCI99,';
     z := z + 'GCJ90,GCJ91,GCJ92,GCJ93,GCJ94,GCJ95,GCJ96,GCJ97,GCJ98,GCJ99,GCK90,GCK91,GCK92,GCK93,GCK94,';
     z := z + 'GCK95,GCK96,GCK97,GCK98,GCK99,GCL90,GCL91,GCL92,GCL93,GCL94,GCL95,GCL96,GCL97,GCL98,GCL99,';
     z := z + 'GCM90,GCM91,GCM92,GCM93,GCM94,GCM95,GCM96,GCM97,GCM98,GCM99,GCN90,GCN91,GCN92,GCN93,GCN94,';
     z := z + 'GCN95,GCN96,GCN97,GCN98,GCN99,GCO90,GCO91,GCO92,GCO93,GCO94,GCO95,GCO96,GCO97,GCO98,GCO99,';
     z := z + 'GCP90,GCP91,GCP92,GCP93,GCP94,GCP95,GCP96,GCP97,GCP98,GCP99,GCQ90,GCQ91,GCQ92,GCQ93,GCQ94,';
     z := z + 'GCQ95,GCQ96,GCQ97,GCQ98,GCQ99,GCR90,GCR91,GCR92,GCR93,GCR94,SXT   ,SXU   ,SXW   ,SXX9  ,SXZ   ,';
     z := z + 'GCA80,GCA81,GCA82,GCA83,GCA84,GCA85,GCA86,GCA87,GCA88,GCA89,GCB80,GCB81,GCB82,GCB83,GCB84,';
     z := z + 'GCB85,GCB86,GCB87,GCB88,GCB89,GCC80,GCC81,GCC82,GCC83,GCC84,GCC85,GCC86,GCC87,GCC88,GCC89,';
     z := z + 'GCD80,GCD81,GCD82,GCD83,GCD84,GCD85,GCD86,GCD87,GCD88,GCD89,GCE80,GCE81,GCE82,GCE83,GCE84,';
     z := z + 'GCE85,GCE86,GCE87,GCE88,GCE89,GCF80,GCF81,GCF82,GCF83,GCF84,GCF85,GCF86,GCF87,GCF88,GCF89,';
     z := z + 'GCG80,GCG81,GCG82,GCG83,GCG84,GCG85,GCG86,GCG87,GCG88,GCG89,GCH80,GCH81,GCH82,GCH83,GCH84,';
     z := z + 'GCH85,GCH86,GCH87,GCH88,GCH89,GCI80,GCI81,GCI82,GCI83,GCI84,GCI85,GCI86,GCI87,GCI88,GCI89,';
     z := z + 'GCJ80,GCJ81,GCJ82,GCJ83,GCJ84,GCJ85,GCJ86,GCJ87,GCJ88,GCJ89,GCK80,GCK81,GCK82,GCK83,GCK84,';
     z := z + 'GCK85,GCK86,GCK87,GCK88,GCK89,GCL80,GCL81,GCL82,GCL83,GCL84,GCL85,GCL86,GCL87,GCL88,GCL89,';
     z := z + 'GCM80,GCM81,GCM82,GCM83,GCM84,GCM85,GCM86,GCM87,GCM88,GCM89,GCN80,GCN81,GCN82,GCN83,GCN84,';
     z := z + 'GCN85,GCN86,GCN87,GCN88,GCN89,GCO80,GCO81,GCO82,GCO83,GCO84,GCO85,GCO86,GCO87,GCO88,GCO89,';
     z := z + 'GCP80,GCP81,GCP82,GCP83,GCP84,GCP85,GCP86,GCP87,GCP88,GCP89,GCQ80,GCQ81,GCQ82,GCQ83,GCQ84,';
     z := z + 'GCQ85,GCQ86,GCQ87,GCQ88,GCQ89,GCR80,GCR81,GCR82,GCR83,GCR84,SYA   ,SYB   ,SYI   ,SYJ   ,SYK   ,';
     z := z + 'GCA70,GCA71,GCA72,GCA73,GCA74,GCA75,GCA76,GCA77,GCA78,GCA79,GCB70,GCB71,GCB72,GCB73,GCB74,';
     z := z + 'GCB75,GCB76,GCB77,GCB78,GCB79,GCC70,GCC71,GCC72,GCC73,GCC74,GCC75,GCC76,GCC77,GCC78,GCC79,';
     z := z + 'GCD70,GCD71,GCD72,GCD73,GCD74,GCD75,GCD76,GCD77,GCD78,GCD79,GCE70,GCE71,GCE72,GCE73,GCE74,';
     z := z + 'GCE75,GCE76,GCE77,GCE78,GCE79,GCF70,GCF71,GCF72,GCF73,GCF74,GCF75,GCF76,GCF77,GCF78,GCF79,';
     z := z + 'GCG70,GCG71,GCG72,GCG73,GCG74,GCG75,GCG76,GCG77,GCG78,GCG79,GCH70,GCH71,GCH72,GCH73,GCH74,';
     z := z + 'GCH75,GCH76,GCH77,GCH78,GCH79,GCI70,GCI71,GCI72,GCI73,GCI74,GCI75,GCI76,GCI77,GCI78,GCI79,';
     z := z + 'GCJ70,GCJ71,GCJ72,GCJ73,GCJ74,GCJ75,GCJ76,GCJ77,GCJ78,GCJ79,GCK70,GCK71,GCK72,GCK73,GCK74,';
     z := z + 'GCK75,GCK76,GCK77,GCK78,GCK79,GCL70,GCL71,GCL72,GCL73,GCL74,GCL75,GCL76,GCL77,GCL78,GCL79,';
     z := z + 'GCM70,GCM71,GCM72,GCM73,GCM74,GCM75,GCM76,GCM77,GCM78,GCM79,GCN70,GCN71,GCN72,GCN73,GCN74,';
     z := z + 'GCN75,GCN76,GCN77,GCN78,GCN79,GCO70,GCO71,GCO72,GCO73,GCO74,GCO75,GCO76,GCO77,GCO78,GCO79,';
     z := z + 'GCP70,GCP71,GCP72,GCP73,GCP74,GCP75,GCP76,GCP77,GCP78,GCP79,GCQ70,GCQ71,GCQ72,GCQ73,GCQ74,';
     z := z + 'GCQ75,GCQ76,GCQ77,GCQ78,GCQ79,GCR70,GCR71,GCR72,GCR73,GCR74,SYL   ,SYN   ,SYO   ,SYS   ,SYU   ,';
     z := z + 'GCA60,GCA61,GCA62,GCA63,GCA64,GCA65,GCA66,GCA67,GCA68,GCA69,GCB60,GCB61,GCB62,GCB63,GCB64,';
     z := z + 'GCB65,GCB66,GCB67,GCB68,GCB69,GCC60,GCC61,GCC62,GCC63,GCC64,GCC65,GCC66,GCC67,GCC68,GCC69,';
     z := z + 'GCD60,GCD61,GCD62,GCD63,GCD64,GCD65,GCD66,GCD67,GCD68,GCD69,GCE60,GCE61,GCE62,GCE63,GCE64,';
     z := z + 'GCE65,GCE66,GCE67,GCE68,GCE69,GCF60,GCF61,GCF62,GCF63,GCF64,GCF65,GCF66,GCF67,GCF68,GCF69,';
     z := z + 'GCG60,GCG61,GCG62,GCG63,GCG64,GCG65,GCG66,GCG67,GCG68,GCG69,GCH60,GCH61,GCH62,GCH63,GCH64,';
     z := z + 'GCH65,GCH66,GCH67,GCH68,GCH69,GCI60,GCI61,GCI62,GCI63,GCI64,GCI65,GCI66,GCI67,GCI68,GCI69,';
     z := z + 'GCJ60,GCJ61,GCJ62,GCJ63,GCJ64,GCJ65,GCJ66,GCJ67,GCJ68,GCJ69,GCK60,GCK61,GCK62,GCK63,GCK64,';
     z := z + 'GCK65,GCK66,GCK67,GCK68,GCK69,GCL60,GCL61,GCL62,GCL63,GCL64,GCL65,GCL66,GCL67,GCL68,GCL69,';
     z := z + 'GCM60,GCM61,GCM62,GCM63,GCM64,GCM65,GCM66,GCM67,GCM68,GCM69,GCN60,GCN61,GCN62,GCN63,GCN64,';
     z := z + 'GCN65,GCN66,GCN67,GCN68,GCN69,GCO60,GCO61,GCO62,GCO63,GCO64,GCO65,GCO66,GCO67,GCO68,GCO69,';
     z := z + 'GCP60,GCP61,GCP62,GCP63,GCP64,GCP65,GCP66,GCP67,GCP68,GCP69,GCQ60,GCQ61,GCQ62,GCQ63,GCQ64,';
     z := z + 'GCQ65,GCQ66,GCQ67,GCQ68,GCQ69,GCR60,GCR61,GCR62,GCR63,GCR64,SYV   ,SYV0  ,SZ2   ,SZ3   ,SZA   ,';
     z := z + 'GCA50,GCA51,GCA52,GCA53,GCA54,GCA55,GCA56,GCA57,GCA58,GCA59,GCB50,GCB51,GCB52,GCB53,GCB54,';
     z := z + 'GCB55,GCB56,GCB57,GCB58,GCB59,GCC50,GCC51,GCC52,GCC53,GCC54,GCC55,GCC56,GCC57,GCC58,GCC59,';
     z := z + 'GCD50,GCD51,GCD52,GCD53,GCD54,GCD55,GCD56,GCD57,GCD58,GCD59,GCE50,GCE51,GCE52,GCE53,GCE54,';
     z := z + 'GCE55,GCE56,GCE57,GCE58,GCE59,GCF50,GCF51,GCF52,GCF53,GCF54,GCF55,GCF56,GCF57,GCF58,GCF59,';
     z := z + 'GCG50,GCG51,GCG52,GCG53,GCG54,GCG55,GCG56,GCG57,GCG58,GCG59,GCH50,GCH51,GCH52,GCH53,GCH54,';
     z := z + 'GCH55,GCH56,GCH57,GCH58,GCH59,GCI50,GCI51,GCI52,GCI53,GCI54,GCI55,GCI56,GCI57,GCI58,GCI59,';
     z := z + 'GCJ50,GCJ51,GCJ52,GCJ53,GCJ54,GCJ55,GCJ56,GCJ57,GCJ58,GCJ59,GCK50,GCK51,GCK52,GCK53,GCK54,';
     z := z + 'GCK55,GCK56,GCK57,GCK58,GCK59,GCL50,GCL51,GCL52,GCL53,GCL54,GCL55,GCL56,GCL57,GCL58,GCL59,';
     z := z + 'GCM50,GCM51,GCM52,GCM53,GCM54,GCM55,GCM56,GCM57,GCM58,GCM59,GCN50,GCN51,GCN52,GCN53,GCN54,';
     z := z + 'GCN55,GCN56,GCN57,GCN58,GCN59,GCO50,GCO51,GCO52,GCO53,GCO54,GCO55,GCO56,GCO57,GCO58,GCO59,';
     z := z + 'GCP50,GCP51,GCP52,GCP53,GCP54,GCP55,GCP56,GCP57,GCP58,GCP59,GCQ50,GCQ51,GCQ52,GCQ53,GCQ54,';
     z := z + 'GCQ55,GCQ56,GCQ57,GCQ58,GCQ59,GCR50,GCR51,GCR52,GCR53,GCR54,SZB   ,SZC4  ,SZD7  ,SZD8  ,SZD9  ,';
     z := z + 'GCA40,GCA41,GCA42,GCA43,GCA44,GCA45,GCA46,GCA47,GCA48,GCA49,GCB40,GCB41,GCB42,GCB43,GCB44,';
     z := z + 'GCB45,GCB46,GCB47,GCB48,GCB49,GCC40,GCC41,GCC42,GCC43,GCC44,GCC45,GCC46,GCC47,GCC48,GCC49,';
     z := z + 'GCD40,GCD41,GCD42,GCD43,GCD44,GCD45,GCD46,GCD47,GCD48,GCD49,GCE40,GCE41,GCE42,GCE43,GCE44,';
     z := z + 'GCE45,GCE46,GCE47,GCE48,GCE49,GCF40,GCF41,GCF42,GCF43,GCF44,GCF45,GCF46,GCF47,GCF48,GCF49,';
     z := z + 'GCG40,GCG41,GCG42,GCG43,GCG44,GCG45,GCG46,GCG47,GCG48,GCG49,GCH40,GCH41,GCH42,GCH43,GCH44,';
     z := z + 'GCH45,GCH46,GCH47,GCH48,GCH49,GCI40,GCI41,GCI42,GCI43,GCI44,GCI45,GCI46,GCI47,GCI48,GCI49,';
     z := z + 'GCJ40,GCJ41,GCJ42,GCJ43,GCJ44,GCJ45,GCJ46,GCJ47,GCJ48,GCJ49,GCK40,GCK41,GCK42,GCK43,GCK44,';
     z := z + 'GCK45,GCK46,GCK47,GCK48,GCK49,GCL40,GCL41,GCL42,GCL43,GCL44,GCL45,GCL46,GCL47,GCL48,GCL49,';
     z := z + 'GCM40,GCM41,GCM42,GCM43,GCM44,GCM45,GCM46,GCM47,GCM48,GCM49,GCN40,GCN41,GCN42,GCN43,GCN44,';
     z := z + 'GCN45,GCN46,GCN47,GCN48,GCN49,GCO40,GCO41,GCO42,GCO43,GCO44,GCO45,GCO46,GCO47,GCO48,GCO49,';
     z := z + 'GCP40,GCP41,GCP42,GCP43,GCP44,GCP45,GCP46,GCP47,GCP48,GCP49,GCQ40,GCQ41,GCQ42,GCQ43,GCQ44,';
     z := z + 'GCQ45,GCQ46,GCQ47,GCQ48,GCQ49,GCR40,GCR41,GCR42,GCR43,GCR44,SZF   ,SZK1N ,SZK1S ,SZK2  ,SZK3  ,';
     z := z + 'GCA30,GCA31,GCA32,GCA33,GCA34,GCA35,GCA36,GCA37,GCA38,GCA39,GCB30,GCB31,GCB32,GCB33,GCB34,';
     z := z + 'GCB35,GCB36,GCB37,GCB38,GCB39,GCC30,GCC31,GCC32,GCC33,GCC34,GCC35,GCC36,GCC37,GCC38,GCC39,';
     z := z + 'GCD30,GCD31,GCD32,GCD33,GCD34,GCD35,GCD36,GCD37,GCD38,GCD39,GCE30,GCE31,GCE32,GCE33,GCE34,';
     z := z + 'GCE35,GCE36,GCE37,GCE38,GCE39,GCF30,GCF31,GCF32,GCF33,GCF34,GCF35,GCF36,GCF37,GCF38,GCF39,';
     z := z + 'GCG30,GCG31,GCG32,GCG33,GCG34,GCG35,GCG36,GCG37,GCG38,GCG39,GCH30,GCH31,GCH32,GCH33,GCH34,';
     z := z + 'GCH35,GCH36,GCH37,GCH38,GCH39,GCI30,GCI31,GCI32,GCI33,GCI34,GCI35,GCI36,GCI37,GCI38,GCI39,';
     z := z + 'GCJ30,GCJ31,GCJ32,GCJ33,GCJ34,GCJ35,GCJ36,GCJ37,GCJ38,GCJ39,GCK30,GCK31,GCK32,GCK33,GCK34,';
     z := z + 'GCK35,GCK36,GCK37,GCK38,GCK39,GCL30,GCL31,GCL32,GCL33,GCL34,GCL35,GCL36,GCL37,GCL38,GCL39,';
     z := z + 'GCM30,GCM31,GCM32,GCM33,GCM34,GCM35,GCM36,GCM37,GCM38,GCM39,GCN30,GCN31,GCN32,GCN33,GCN34,';
     z := z + 'GCN35,GCN36,GCN37,GCN38,GCN39,GCO30,GCO31,GCO32,GCO33,GCO34,GCO35,GCO36,GCO37,GCO38,GCO39,';
     z := z + 'GCP30,GCP31,GCP32,GCP33,GCP34,GCP35,GCP36,GCP37,GCP38,GCP39,GCQ30,GCQ31,GCQ32,GCQ33,GCQ34,';
     z := z + 'GCQ35,GCQ36,GCQ37,GCQ38,GCQ39,GCR30,GCR31,GCR32,GCR33,GCR34,SZL   ,SZL7  ,SZL8  ,SZL9  ,SZP   ,';
     z := z + 'GCA20,GCA21,GCA22,GCA23,GCA24,GCA25,GCA26,GCA27,GCA28,GCA29,GCB20,GCB21,GCB22,GCB23,GCB24,';
     z := z + 'GCB25,GCB26,GCB27,GCB28,GCB29,GCC20,GCC21,GCC22,GCC23,GCC24,GCC25,GCC26,GCC27,GCC28,GCC29,';
     z := z + 'GCD20,GCD21,GCD22,GCD23,GCD24,GCD25,GCD26,GCD27,GCD28,GCD29,GCE20,GCE21,GCE22,GCE23,GCE24,';
     z := z + 'GCE25,GCE26,GCE27,GCE28,GCE29,GCF20,GCF21,GCF22,GCF23,GCF24,GCF25,GCF26,GCF27,GCF28,GCF29,';
     z := z + 'GCG20,GCG21,GCG22,GCG23,GCG24,GCG25,GCG26,GCG27,GCG28,GCG29,GCH20,GCH21,GCH22,GCH23,GCH24,';
     z := z + 'GCH25,GCH26,GCH27,GCH28,GCH29,GCI20,GCI21,GCI22,GCI23,GCI24,GCI25,GCI26,GCI27,GCI28,GCI29,';
     z := z + 'GCJ20,GCJ21,GCJ22,GCJ23,GCJ24,GCJ25,GCJ26,GCJ27,GCJ28,GCJ29,GCK20,GCK21,GCK22,GCK23,GCK24,';
     z := z + 'GCK25,GCK26,GCK27,GCK28,GCK29,GCL20,GCL21,GCL22,GCL23,GCL24,GCL25,GCL26,GCL27,GCL28,GCL29,';
     z := z + 'GCM20,GCM21,GCM22,GCM23,GCM24,GCM25,GCM26,GCM27,GCM28,GCM29,GCN20,GCN21,GCN22,GCN23,GCN24,';
     z := z + 'GCN25,GCN26,GCN27,GCN28,GCN29,GCO20,GCO21,GCO22,GCO23,GCO24,GCO25,GCO26,GCO27,GCO28,GCO29,';
     z := z + 'GCP20,GCP21,GCP22,GCP23,GCP24,GCP25,GCP26,GCP27,GCP28,GCP29,GCQ20,GCQ21,GCQ22,GCQ23,GCQ24,';
     z := z + 'GCQ25,GCQ26,GCQ27,GCQ28,GCQ29,GCR20,GCR21,GCR22,GCR23,GCR24,SZS   ,SZS8  ,SKC4  ,SE5   ,S     ,';
     z := z + 'GCA10,GCA11,GCA12,GCA13,GCA14,GCA15,GCA16,GCA17,GCA18,GCA19,GCB10,GCB11,GCB12,GCB13,GCB14,';
     z := z + 'GCB15,GCB16,GCB17,GCB18,GCB19,GCC10,GCC11,GCC12,GCC13,GCC14,GCC15,GCC16,GCC17,GCC18,GCC19,';
     z := z + 'GCD10,GCD11,GCD12,GCD13,GCD14,GCD15,GCD16,GCD17,GCD18,GCD19,GCE10,GCE11,GCE12,GCE13,GCE14,';
     z := z + 'GCE15,GCE16,GCE17,GCE18,GCE19,GCF10,GCF11,GCF12,GCF13,GCF14,GCF15,GCF16,GCF17,GCF18,GCF19,';
     z := z + 'GCG10,GCG11,GCG12,GCG13,GCG14,GCG15,GCG16,GCG17,GCG18,GCG19,GCH10,GCH11,GCH12,GCH13,GCH14,';
     z := z + 'GCH15,GCH16,GCH17,GCH18,GCH19,GCI10,GCI11,GCI12,GCI13,GCI14,GCI15,GCI16,GCI17,GCI18,GCI19,';
     z := z + 'GCJ10,GCJ11,GCJ12,GCJ13,GCJ14,GCJ15,GCJ16,GCJ17,GCJ18,GCJ19,GCK10,GCK11,GCK12,GCK13,GCK14,';
     z := z + 'GCK15,GCK16,GCK17,GCK18,GCK19,GCL10,GCL11,GCL12,GCL13,GCL14,GCL15,GCL16,GCL17,GCL18,GCL19,';
     z := z + 'GCM10,GCM11,GCM12,GCM13,GCM14,GCM15,GCM16,GCM17,GCM18,GCM19,GCN10,GCN11,GCN12,GCN13,GCN14,';
     z := z + 'GCN15,GCN16,GCN17,GCN18,GCN19,GCO10,GCO11,GCO12,GCO13,GCO14,GCO15,GCO16,GCO17,GCO18,GCO19,';
     z := z + 'GCP10,GCP11,GCP12,GCP13,GCP14,GCP15,GCP16,GCP17,GCP18,GCP19,GCQ10,GCQ11,GCQ12,GCQ13,GCQ14,';
     z := z + 'GCQ15,GCQ16,GCQ17,GCQ18,GCQ19,GCR10,GCR11,GCR12,GCR13,GCR14,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GCA00,GCA01,GCA02,GCA03,GCA04,GCA05,GCA06,GCA07,GCA08,GCA09,GCB00,GCB01,GCB02,GCB03,GCB04,';
     z := z + 'GCB05,GCB06,GCB07,GCB08,GCB09,GCC00,GCC01,GCC02,GCC03,GCC04,GCC05,GCC06,GCC07,GCC08,GCC09,';
     z := z + 'GCD00,GCD01,GCD02,GCD03,GCD04,GCD05,GCD06,GCD07,GCD08,GCD09,GCE00,GCE01,GCE02,GCE03,GCE04,';
     z := z + 'GCE05,GCE06,GCE07,GCE08,GCE09,GCF00,GCF01,GCF02,GCF03,GCF04,GCF05,GCF06,GCF07,GCF08,GCF09,';
     z := z + 'GCG00,GCG01,GCG02,GCG03,GCG04,GCG05,GCG06,GCG07,GCG08,GCG09,GCH00,GCH01,GCH02,GCH03,GCH04,';
     z := z + 'GCH05,GCH06,GCH07,GCH08,GCH09,GCI00,GCI01,GCI02,GCI03,GCI04,GCI05,GCI06,GCI07,GCI08,GCI09,';
     z := z + 'GCJ00,GCJ01,GCJ02,GCJ03,GCJ04,GCJ05,GCJ06,GCJ07,GCJ08,GCJ09,GCK00,GCK01,GCK02,GCK03,GCK04,';
     z := z + 'GCK05,GCK06,GCK07,GCK08,GCK09,GCL00,GCL01,GCL02,GCL03,GCL04,GCL05,GCL06,GCL07,GCL08,GCL09,';
     z := z + 'GCM00,GCM01,GCM02,GCM03,GCM04,GCM05,GCM06,GCM07,GCM08,GCM09,GCN00,GCN01,GCN02,GCN03,GCN04,';
     z := z + 'GCN05,GCN06,GCN07,GCN08,GCN09,GCO00,GCO01,GCO02,GCO03,GCO04,GCO05,GCO06,GCO07,GCO08,GCO09,';
     z := z + 'GCP00,GCP01,GCP02,GCP03,GCP04,GCP05,GCP06,GCP07,GCP08,GCP09,GCQ00,GCQ01,GCQ02,GCQ03,GCQ04,';
     z := z + 'GCQ05,GCQ06,GCQ07,GCQ08,GCQ09,GCR00,GCR01,GCR02,GCR03,GCR04,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GBA90,GBA91,GBA92,GBA93,GBA94,GBA95,GBA96,GBA97,GBA98,GBA99,GBB90,GBB91,GBB92,GBB93,GBB94,';
     z := z + 'GBB95,GBB96,GBB97,GBB98,GBB99,GBC90,GBC91,GBC92,GBC93,GBC94,GBC95,GBC96,GBC97,GBC98,GBC99,';
     z := z + 'GBD90,GBD91,GBD92,GBD93,GBD94,GBD95,GBD96,GBD97,GBD98,GBD99,GBE90,GBE91,GBE92,GBE93,GBE94,';
     z := z + 'GBE95,GBE96,GBE97,GBE98,GBE99,GBF90,GBF91,GBF92,GBF93,GBF94,GBF95,GBF96,GBF97,GBF98,GBF99,';
     z := z + 'GBG90,GBG91,GBG92,GBG93,GBG94,GBG95,GBG96,GBG97,GBG98,GBG99,GBH90,GBH91,GBH92,GBH93,GBH94,';
     z := z + 'GBH95,GBH96,GBH97,GBH98,GBH99,GBI90,GBI91,GBI92,GBI93,GBI94,GBI95,GBI96,GBI97,GBI98,GBI99,';
     z := z + 'GBJ90,GBJ91,GBJ92,GBJ93,GBJ94,GBJ95,GBJ96,GBJ97,GBJ98,GBJ99,GBK90,GBK91,GBK92,GBK93,GBK94,';
     z := z + 'GBK95,GBK96,GBK97,GBK98,GBK99,GBL90,GBL91,GBL92,GBL93,GBL94,GBL95,GBL96,GBL97,GBL98,GBL99,';
     z := z + 'GBM90,GBM91,GBM92,GBM93,GBM94,GBM95,GBM96,GBM97,GBM98,GBM99,GBN90,GBN91,GBN92,GBN93,GBN94,';
     z := z + 'GBN95,GBN96,GBN97,GBN98,GBN99,GBO90,GBO91,GBO92,GBO93,GBO94,GBO95,GBO96,GBO97,GBO98,GBO99,';
     z := z + 'GBP90,GBP91,GBP92,GBP93,GBP94,GBP95,GBP96,GBP97,GBP98,GBP99,GBQ90,GBQ91,GBQ92,GBQ93,GBQ94,';
     z := z + 'GBQ95,GBQ96,GBQ97,GBQ98,GBQ99,GBR90,GBR91,GBR92,GBR93,GBR94,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GBA80,GBA81,GBA82,GBA83,GBA84,GBA85,GBA86,GBA87,GBA88,GBA89,GBB80,GBB81,GBB82,GBB83,GBB84,';
     z := z + 'GBB85,GBB86,GBB87,GBB88,GBB89,GBC80,GBC81,GBC82,GBC83,GBC84,GBC85,GBC86,GBC87,GBC88,GBC89,';
     z := z + 'GBD80,GBD81,GBD82,GBD83,GBD84,GBD85,GBD86,GBD87,GBD88,GBD89,GBE80,GBE81,GBE82,GBE83,GBE84,';
     z := z + 'GBE85,GBE86,GBE87,GBE88,GBE89,GBF80,GBF81,GBF82,GBF83,GBF84,GBF85,GBF86,GBF87,GBF88,GBF89,';
     z := z + 'GBG80,GBG81,GBG82,GBG83,GBG84,GBG85,GBG86,GBG87,GBG88,GBG89,GBH80,GBH81,GBH82,GBH83,GBH84,';
     z := z + 'GBH85,GBH86,GBH87,GBH88,GBH89,GBI80,GBI81,GBI82,GBI83,GBI84,GBI85,GBI86,GBI87,GBI88,GBI89,';
     z := z + 'GBJ80,GBJ81,GBJ82,GBJ83,GBJ84,GBJ85,GBJ86,GBJ87,GBJ88,GBJ89,GBK80,GBK81,GBK82,GBK83,GBK84,';
     z := z + 'GBK85,GBK86,GBK87,GBK88,GBK89,GBL80,GBL81,GBL82,GBL83,GBL84,GBL85,GBL86,GBL87,GBL88,GBL89,';
     z := z + 'GBM80,GBM81,GBM82,GBM83,GBM84,GBM85,GBM86,GBM87,GBM88,GBM89,GBN80,GBN81,GBN82,GBN83,GBN84,';
     z := z + 'GBN85,GBN86,GBN87,GBN88,GBN89,GBO80,GBO81,GBO82,GBO83,GBO84,GBO85,GBO86,GBO87,GBO88,GBO89,';
     z := z + 'GBP80,GBP81,GBP82,GBP83,GBP84,GBP85,GBP86,GBP87,GBP88,GBP89,GBQ80,GBQ81,GBQ82,GBQ83,GBQ84,';
     z := z + 'GBQ85,GBQ86,GBQ87,GBQ88,GBQ89,GBR80,GBR81,GBR82,GBR83,GBR84,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GBA70,GBA71,GBA72,GBA73,GBA74,GBA75,GBA76,GBA77,GBA78,GBA79,GBB70,GBB71,GBB72,GBB73,GBB74,';
     z := z + 'GBB75,GBB76,GBB77,GBB78,GBB79,GBC70,GBC71,GBC72,GBC73,GBC74,GBC75,GBC76,GBC77,GBC78,GBC79,';
     z := z + 'GBD70,GBD71,GBD72,GBD73,GBD74,GBD75,GBD76,GBD77,GBD78,GBD79,GBE70,GBE71,GBE72,GBE73,GBE74,';
     z := z + 'GBE75,GBE76,GBE77,GBE78,GBE79,GBF70,GBF71,GBF72,GBF73,GBF74,GBF75,GBF76,GBF77,GBF78,GBF79,';
     z := z + 'GBG70,GBG71,GBG72,GBG73,GBG74,GBG75,GBG76,GBG77,GBG78,GBG79,GBH70,GBH71,GBH72,GBH73,GBH74,';
     z := z + 'GBH75,GBH76,GBH77,GBH78,GBH79,GBI70,GBI71,GBI72,GBI73,GBI74,GBI75,GBI76,GBI77,GBI78,GBI79,';
     z := z + 'GBJ70,GBJ71,GBJ72,GBJ73,GBJ74,GBJ75,GBJ76,GBJ77,GBJ78,GBJ79,GBK70,GBK71,GBK72,GBK73,GBK74,';
     z := z + 'GBK75,GBK76,GBK77,GBK78,GBK79,GBL70,GBL71,GBL72,GBL73,GBL74,GBL75,GBL76,GBL77,GBL78,GBL79,';
     z := z + 'GBM70,GBM71,GBM72,GBM73,GBM74,GBM75,GBM76,GBM77,GBM78,GBM79,GBN70,GBN71,GBN72,GBN73,GBN74,';
     z := z + 'GBN75,GBN76,GBN77,GBN78,GBN79,GBO70,GBO71,GBO72,GBO73,GBO74,GBO75,GBO76,GBO77,GBO78,GBO79,';
     z := z + 'GBP70,GBP71,GBP72,GBP73,GBP74,GBP75,GBP76,GBP77,GBP78,GBP79,GBQ70,GBQ71,GBQ72,GBQ73,GBQ74,';
     z := z + 'GBQ75,GBQ76,GBQ77,GBQ78,GBQ79,GBR70,GBR71,GBR72,GBR73,GBR74,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GBA60,GBA61,GBA62,GBA63,GBA64,GBA65,GBA66,GBA67,GBA68,GBA69,GBB60,GBB61,GBB62,GBB63,GBB64,';
     z := z + 'GBB65,GBB66,GBB67,GBB68,GBB69,GBC60,GBC61,GBC62,GBC63,GBC64,GBC65,GBC66,GBC67,GBC68,GBC69,';
     z := z + 'GBD60,GBD61,GBD62,GBD63,GBD64,GBD65,GBD66,GBD67,GBD68,GBD69,GBE60,GBE61,GBE62,GBE63,GBE64,';
     z := z + 'GBE65,GBE66,GBE67,GBE68,GBE69,GBF60,GBF61,GBF62,GBF63,GBF64,GBF65,GBF66,GBF67,GBF68,GBF69,';
     z := z + 'GBG60,GBG61,GBG62,GBG63,GBG64,GBG65,GBG66,GBG67,GBG68,GBG69,GBH60,GBH61,GBH62,GBH63,GBH64,';
     z := z + 'GBH65,GBH66,GBH67,GBH68,GBH69,GBI60,GBI61,GBI62,GBI63,GBI64,GBI65,GBI66,GBI67,GBI68,GBI69,';
     z := z + 'GBJ60,GBJ61,GBJ62,GBJ63,GBJ64,GBJ65,GBJ66,GBJ67,GBJ68,GBJ69,GBK60,GBK61,GBK62,GBK63,GBK64,';
     z := z + 'GBK65,GBK66,GBK67,GBK68,GBK69,GBL60,GBL61,GBL62,GBL63,GBL64,GBL65,GBL66,GBL67,GBL68,GBL69,';
     z := z + 'GBM60,GBM61,GBM62,GBM63,GBM64,GBM65,GBM66,GBM67,GBM68,GBM69,GBN60,GBN61,GBN62,GBN63,GBN64,';
     z := z + 'GBN65,GBN66,GBN67,GBN68,GBN69,GBO60,GBO61,GBO62,GBO63,GBO64,GBO65,GBO66,GBO67,GBO68,GBO69,';
     z := z + 'GBP60,GBP61,GBP62,GBP63,GBP64,GBP65,GBP66,GBP67,GBP68,GBP69,GBQ60,GBQ61,GBQ62,GBQ63,GBQ64,';
     z := z + 'GBQ65,GBQ66,GBQ67,GBQ68,GBQ69,GBR60,GBR61,GBR62,GBR63,GBR64,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GBA50,GBA51,GBA52,GBA53,GBA54,GBA55,GBA56,GBA57,GBA58,GBA59,GBB50,GBB51,GBB52,GBB53,GBB54,';
     z := z + 'GBB55,GBB56,GBB57,GBB58,GBB59,GBC50,GBC51,GBC52,GBC53,GBC54,GBC55,GBC56,GBC57,GBC58,GBC59,';
     z := z + 'GBD50,GBD51,GBD52,GBD53,GBD54,GBD55,GBD56,GBD57,GBD58,GBD59,GBE50,GBE51,GBE52,GBE53,GBE54,';
     z := z + 'GBE55,GBE56,GBE57,GBE58,GBE59,GBF50,GBF51,GBF52,GBF53,GBF54,GBF55,GBF56,GBF57,GBF58,GBF59,';
     z := z + 'GBG50,GBG51,GBG52,GBG53,GBG54,GBG55,GBG56,GBG57,GBG58,GBG59,GBH50,GBH51,GBH52,GBH53,GBH54,';
     z := z + 'GBH55,GBH56,GBH57,GBH58,GBH59,GBI50,GBI51,GBI52,GBI53,GBI54,GBI55,GBI56,GBI57,GBI58,GBI59,';
     z := z + 'GBJ50,GBJ51,GBJ52,GBJ53,GBJ54,GBJ55,GBJ56,GBJ57,GBJ58,GBJ59,GBK50,GBK51,GBK52,GBK53,GBK54,';
     z := z + 'GBK55,GBK56,GBK57,GBK58,GBK59,GBL50,GBL51,GBL52,GBL53,GBL54,GBL55,GBL56,GBL57,GBL58,GBL59,';
     z := z + 'GBM50,GBM51,GBM52,GBM53,GBM54,GBM55,GBM56,GBM57,GBM58,GBM59,GBN50,GBN51,GBN52,GBN53,GBN54,';
     z := z + 'GBN55,GBN56,GBN57,GBN58,GBN59,GBO50,GBO51,GBO52,GBO53,GBO54,GBO55,GBO56,GBO57,GBO58,GBO59,';
     z := z + 'GBP50,GBP51,GBP52,GBP53,GBP54,GBP55,GBP56,GBP57,GBP58,GBP59,GBQ50,GBQ51,GBQ52,GBQ53,GBQ54,';
     z := z + 'GBQ55,GBQ56,GBQ57,GBQ58,GBQ59,GBR50,GBR51,GBR52,GBR53,GBR54,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GBA40,GBA41,GBA42,GBA43,GBA44,GBA45,GBA46,GBA47,GBA48,GBA49,GBB40,GBB41,GBB42,GBB43,GBB44,';
     z := z + 'GBB45,GBB46,GBB47,GBB48,GBB49,GBC40,GBC41,GBC42,GBC43,GBC44,GBC45,GBC46,GBC47,GBC48,GBC49,';
     z := z + 'GBD40,GBD41,GBD42,GBD43,GBD44,GBD45,GBD46,GBD47,GBD48,GBD49,GBE40,GBE41,GBE42,GBE43,GBE44,';
     z := z + 'GBE45,GBE46,GBE47,GBE48,GBE49,GBF40,GBF41,GBF42,GBF43,GBF44,GBF45,GBF46,GBF47,GBF48,GBF49,';
     z := z + 'GBG40,GBG41,GBG42,GBG43,GBG44,GBG45,GBG46,GBG47,GBG48,GBG49,GBH40,GBH41,GBH42,GBH43,GBH44,';
     z := z + 'GBH45,GBH46,GBH47,GBH48,GBH49,GBI40,GBI41,GBI42,GBI43,GBI44,GBI45,GBI46,GBI47,GBI48,GBI49,';
     z := z + 'GBJ40,GBJ41,GBJ42,GBJ43,GBJ44,GBJ45,GBJ46,GBJ47,GBJ48,GBJ49,GBK40,GBK41,GBK42,GBK43,GBK44,';
     z := z + 'GBK45,GBK46,GBK47,GBK48,GBK49,GBL40,GBL41,GBL42,GBL43,GBL44,GBL45,GBL46,GBL47,GBL48,GBL49,';
     z := z + 'GBM40,GBM41,GBM42,GBM43,GBM44,GBM45,GBM46,GBM47,GBM48,GBM49,GBN40,GBN41,GBN42,GBN43,GBN44,';
     z := z + 'GBN45,GBN46,GBN47,GBN48,GBN49,GBO40,GBO41,GBO42,GBO43,GBO44,GBO45,GBO46,GBO47,GBO48,GBO49,';
     z := z + 'GBP40,GBP41,GBP42,GBP43,GBP44,GBP45,GBP46,GBP47,GBP48,GBP49,GBQ40,GBQ41,GBQ42,GBQ43,GBQ44,';
     z := z + 'GBQ45,GBQ46,GBQ47,GBQ48,GBQ49,GBR40,GBR41,GBR42,GBR43,GBR44,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GBA30,GBA31,GBA32,GBA33,GBA34,GBA35,GBA36,GBA37,GBA38,GBA39,GBB30,GBB31,GBB32,GBB33,GBB34,';
     z := z + 'GBB35,GBB36,GBB37,GBB38,GBB39,GBC30,GBC31,GBC32,GBC33,GBC34,GBC35,GBC36,GBC37,GBC38,GBC39,';
     z := z + 'GBD30,GBD31,GBD32,GBD33,GBD34,GBD35,GBD36,GBD37,GBD38,GBD39,GBE30,GBE31,GBE32,GBE33,GBE34,';
     z := z + 'GBE35,GBE36,GBE37,GBE38,GBE39,GBF30,GBF31,GBF32,GBF33,GBF34,GBF35,GBF36,GBF37,GBF38,GBF39,';
     z := z + 'GBG30,GBG31,GBG32,GBG33,GBG34,GBG35,GBG36,GBG37,GBG38,GBG39,GBH30,GBH31,GBH32,GBH33,GBH34,';
     z := z + 'GBH35,GBH36,GBH37,GBH38,GBH39,GBI30,GBI31,GBI32,GBI33,GBI34,GBI35,GBI36,GBI37,GBI38,GBI39,';
     z := z + 'GBJ30,GBJ31,GBJ32,GBJ33,GBJ34,GBJ35,GBJ36,GBJ37,GBJ38,GBJ39,GBK30,GBK31,GBK32,GBK33,GBK34,';
     z := z + 'GBK35,GBK36,GBK37,GBK38,GBK39,GBL30,GBL31,GBL32,GBL33,GBL34,GBL35,GBL36,GBL37,GBL38,GBL39,';
     z := z + 'GBM30,GBM31,GBM32,GBM33,GBM34,GBM35,GBM36,GBM37,GBM38,GBM39,GBN30,GBN31,GBN32,GBN33,GBN34,';
     z := z + 'GBN35,GBN36,GBN37,GBN38,GBN39,GBO30,GBO31,GBO32,GBO33,GBO34,GBO35,GBO36,GBO37,GBO38,GBO39,';
     z := z + 'GBP30,GBP31,GBP32,GBP33,GBP34,GBP35,GBP36,GBP37,GBP38,GBP39,GBQ30,GBQ31,GBQ32,GBQ33,GBQ34,';
     z := z + 'GBQ35,GBQ36,GBQ37,GBQ38,GBQ39,GBR30,GBR31,GBR32,GBR33,GBR34,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GBA20,GBA21,GBA22,GBA23,GBA24,GBA25,GBA26,GBA27,GBA28,GBA29,GBB20,GBB21,GBB22,GBB23,GBB24,';
     z := z + 'GBB25,GBB26,GBB27,GBB28,GBB29,GBC20,GBC21,GBC22,GBC23,GBC24,GBC25,GBC26,GBC27,GBC28,GBC29,';
     z := z + 'GBD20,GBD21,GBD22,GBD23,GBD24,GBD25,GBD26,GBD27,GBD28,GBD29,GBE20,GBE21,GBE22,GBE23,GBE24,';
     z := z + 'GBE25,GBE26,GBE27,GBE28,GBE29,GBF20,GBF21,GBF22,GBF23,GBF24,GBF25,GBF26,GBF27,GBF28,GBF29,';
     z := z + 'GBG20,GBG21,GBG22,GBG23,GBG24,GBG25,GBG26,GBG27,GBG28,GBG29,GBH20,GBH21,GBH22,GBH23,GBH24,';
     z := z + 'GBH25,GBH26,GBH27,GBH28,GBH29,GBI20,GBI21,GBI22,GBI23,GBI24,GBI25,GBI26,GBI27,GBI28,GBI29,';
     z := z + 'GBJ20,GBJ21,GBJ22,GBJ23,GBJ24,GBJ25,GBJ26,GBJ27,GBJ28,GBJ29,GBK20,GBK21,GBK22,GBK23,GBK24,';
     z := z + 'GBK25,GBK26,GBK27,GBK28,GBK29,GBL20,GBL21,GBL22,GBL23,GBL24,GBL25,GBL26,GBL27,GBL28,GBL29,';
     z := z + 'GBM20,GBM21,GBM22,GBM23,GBM24,GBM25,GBM26,GBM27,GBM28,GBM29,GBN20,GBN21,GBN22,GBN23,GBN24,';
     z := z + 'GBN25,GBN26,GBN27,GBN28,GBN29,GBO20,GBO21,GBO22,GBO23,GBO24,GBO25,GBO26,GBO27,GBO28,GBO29,';
     z := z + 'GBP20,GBP21,GBP22,GBP23,GBP24,GBP25,GBP26,GBP27,GBP28,GBP29,GBQ20,GBQ21,GBQ22,GBQ23,GBQ24,';
     z := z + 'GBQ25,GBQ26,GBQ27,GBQ28,GBQ29,GBR20,GBR21,GBR22,GBR23,GBR24,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GBA10,GBA11,GBA12,GBA13,GBA14,GBA15,GBA16,GBA17,GBA18,GBA19,GBB10,GBB11,GBB12,GBB13,GBB14,';
     z := z + 'GBB15,GBB16,GBB17,GBB18,GBB19,GBC10,GBC11,GBC12,GBC13,GBC14,GBC15,GBC16,GBC17,GBC18,GBC19,';
     z := z + 'GBD10,GBD11,GBD12,GBD13,GBD14,GBD15,GBD16,GBD17,GBD18,GBD19,GBE10,GBE11,GBE12,GBE13,GBE14,';
     z := z + 'GBE15,GBE16,GBE17,GBE18,GBE19,GBF10,GBF11,GBF12,GBF13,GBF14,GBF15,GBF16,GBF17,GBF18,GBF19,';
     z := z + 'GBG10,GBG11,GBG12,GBG13,GBG14,GBG15,GBG16,GBG17,GBG18,GBG19,GBH10,GBH11,GBH12,GBH13,GBH14,';
     z := z + 'GBH15,GBH16,GBH17,GBH18,GBH19,GBI10,GBI11,GBI12,GBI13,GBI14,GBI15,GBI16,GBI17,GBI18,GBI19,';
     z := z + 'GBJ10,GBJ11,GBJ12,GBJ13,GBJ14,GBJ15,GBJ16,GBJ17,GBJ18,GBJ19,GBK10,GBK11,GBK12,GBK13,GBK14,';
     z := z + 'GBK15,GBK16,GBK17,GBK18,GBK19,GBL10,GBL11,GBL12,GBL13,GBL14,GBL15,GBL16,GBL17,GBL18,GBL19,';
     z := z + 'GBM10,GBM11,GBM12,GBM13,GBM14,GBM15,GBM16,GBM17,GBM18,GBM19,GBN10,GBN11,GBN12,GBN13,GBN14,';
     z := z + 'GBN15,GBN16,GBN17,GBN18,GBN19,GBO10,GBO11,GBO12,GBO13,GBO14,GBO15,GBO16,GBO17,GBO18,GBO19,';
     z := z + 'GBP10,GBP11,GBP12,GBP13,GBP14,GBP15,GBP16,GBP17,GBP18,GBP19,GBQ10,GBQ11,GBQ12,GBQ13,GBQ14,';
     z := z + 'GBQ15,GBQ16,GBQ17,GBQ18,GBQ19,GBR10,GBR11,GBR12,GBR13,GBR14,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GBA00,GBA01,GBA02,GBA03,GBA04,GBA05,GBA06,GBA07,GBA08,GBA09,GBB00,GBB01,GBB02,GBB03,GBB04,';
     z := z + 'GBB05,GBB06,GBB07,GBB08,GBB09,GBC00,GBC01,GBC02,GBC03,GBC04,GBC05,GBC06,GBC07,GBC08,GBC09,';
     z := z + 'GBD00,GBD01,GBD02,GBD03,GBD04,GBD05,GBD06,GBD07,GBD08,GBD09,GBE00,GBE01,GBE02,GBE03,GBE04,';
     z := z + 'GBE05,GBE06,GBE07,GBE08,GBE09,GBF00,GBF01,GBF02,GBF03,GBF04,GBF05,GBF06,GBF07,GBF08,GBF09,';
     z := z + 'GBG00,GBG01,GBG02,GBG03,GBG04,GBG05,GBG06,GBG07,GBG08,GBG09,GBH00,GBH01,GBH02,GBH03,GBH04,';
     z := z + 'GBH05,GBH06,GBH07,GBH08,GBH09,GBI00,GBI01,GBI02,GBI03,GBI04,GBI05,GBI06,GBI07,GBI08,GBI09,';
     z := z + 'GBJ00,GBJ01,GBJ02,GBJ03,GBJ04,GBJ05,GBJ06,GBJ07,GBJ08,GBJ09,GBK00,GBK01,GBK02,GBK03,GBK04,';
     z := z + 'GBK05,GBK06,GBK07,GBK08,GBK09,GBL00,GBL01,GBL02,GBL03,GBL04,GBL05,GBL06,GBL07,GBL08,GBL09,';
     z := z + 'GBM00,GBM01,GBM02,GBM03,GBM04,GBM05,GBM06,GBM07,GBM08,GBM09,GBN00,GBN01,GBN02,GBN03,GBN04,';
     z := z + 'GBN05,GBN06,GBN07,GBN08,GBN09,GBO00,GBO01,GBO02,GBO03,GBO04,GBO05,GBO06,GBO07,GBO08,GBO09,';
     z := z + 'GBP00,GBP01,GBP02,GBP03,GBP04,GBP05,GBP06,GBP07,GBP08,GBP09,GBQ00,GBQ01,GBQ02,GBQ03,GBQ04,';
     z := z + 'GBQ05,GBQ06,GBQ07,GBQ08,GBQ09,GBR00,GBR01,GBR02,GBR03,GBR04,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GAA90,GAA91,GAA92,GAA93,GAA94,GAA95,GAA96,GAA97,GAA98,GAA99,GAB90,GAB91,GAB92,GAB93,GAB94,';
     z := z + 'GAB95,GAB96,GAB97,GAB98,GAB99,GAC90,GAC91,GAC92,GAC93,GAC94,GAC95,GAC96,GAC97,GAC98,GAC99,';
     z := z + 'GAD90,GAD91,GAD92,GAD93,GAD94,GAD95,GAD96,GAD97,GAD98,GAD99,GAE90,GAE91,GAE92,GAE93,GAE94,';
     z := z + 'GAE95,GAE96,GAE97,GAE98,GAE99,GAF90,GAF91,GAF92,GAF93,GAF94,GAF95,GAF96,GAF97,GAF98,GAF99,';
     z := z + 'GAG90,GAG91,GAG92,GAG93,GAG94,GAG95,GAG96,GAG97,GAG98,GAG99,GAH90,GAH91,GAH92,GAH93,GAH94,';
     z := z + 'GAH95,GAH96,GAH97,GAH98,GAH99,GAI90,GAI91,GAI92,GAI93,GAI94,GAI95,GAI96,GAI97,GAI98,GAI99,';
     z := z + 'GAJ90,GAJ91,GAJ92,GAJ93,GAJ94,GAJ95,GAJ96,GAJ97,GAJ98,GAJ99,GAK90,GAK91,GAK92,GAK93,GAK94,';
     z := z + 'GAK95,GAK96,GAK97,GAK98,GAK99,GAL90,GAL91,GAL92,GAL93,GAL94,GAL95,GAL96,GAL97,GAL98,GAL99,';
     z := z + 'GAM90,GAM91,GAM92,GAM93,GAM94,GAM95,GAM96,GAM97,GAM98,GAM99,GAN90,GAN91,GAN92,GAN93,GAN94,';
     z := z + 'GAN95,GAN96,GAN97,GAN98,GAN99,GAO90,GAO91,GAO92,GAO93,GAO94,GAO95,GAO96,GAO97,GAO98,GAO99,';
     z := z + 'GAP90,GAP91,GAP92,GAP93,GAP94,GAP95,GAP96,GAP97,GAP98,GAP99,GAQ90,GAQ91,GAQ92,GAQ93,GAQ94,';
     z := z + 'GAQ95,GAQ96,GAQ97,GAQ98,GAQ99,GAR90,GAR91,GAR92,GAR93,GAR94,SP    ,S0    ,S1    ,S2    ,S3    ,';
     z := z + 'GAA80,GAA81,GAA82,GAA83,GAA84,GAA85,GAA86,GAA87,GAA88,GAA89,GAB80,GAB81,GAB82,GAB83,GAB84,';
     z := z + 'GAB85,GAB86,GAB87,GAB88,GAB89,GAC80,GAC81,GAC82,GAC83,GAC84,GAC85,GAC86,GAC87,GAC88,GAC89,';
     z := z + 'GAD80,GAD81,GAD82,GAD83,GAD84,GAD85,GAD86,GAD87,GAD88,GAD89,GAE80,GAE81,GAE82,GAE83,GAE84,';
     z := z + 'GAE85,GAE86,GAE87,GAE88,GAE89,GAF80,GAF81,GAF82,GAF83,GAF84,GAF85,GAF86,GAF87,GAF88,GAF89,';
     z := z + 'GAG80,GAG81,GAG82,GAG83,GAG84,GAG85,GAG86,GAG87,GAG88,GAG89,GAH80,GAH81,GAH82,GAH83,GAH84,';
     z := z + 'GAH85,GAH86,GAH87,GAH88,GAH89,GAI80,GAI81,GAI82,GAI83,GAI84,GAI85,GAI86,GAI87,GAI88,GAI89,';
     z := z + 'GAJ80,GAJ81,GAJ82,GAJ83,GAJ84,GAJ85,GAJ86,GAJ87,GAJ88,GAJ89,GAK80,GAK81,GAK82,GAK83,GAK84,';
     z := z + 'GAK85,GAK86,GAK87,GAK88,GAK89,GAL80,GAL81,GAL82,GAL83,GAL84,GAL85,GAL86,GAL87,GAL88,GAL89,';
     z := z + 'GAM80,GAM81,GAM82,GAM83,GAM84,GAM85,GAM86,GAM87,GAM88,GAM89,GAN80,GAN81,GAN82,GAN83,GAN84,';
     z := z + 'GAN85,GAN86,GAN87,GAN88,GAN89,GAO80,GAO81,GAO82,GAO83,GAO84,GAO85,GAO86,GAO87,GAO88,GAO89,';
     z := z + 'GAP80,GAP81,GAP82,GAP83,GAP84,GAP85,GAP86,GAP87,GAP88,GAP89,GAQ80,GAQ81,GAQ82,GAQ83,GAQ84,';
     z := z + 'GAQ85,GAQ86,GAQ87,GAQ88,GAQ89,GAR80,GAR81,GAR82,GAR83,GAR84,S4    ,S5    ,S6    ,S7    ,S8    ,';
     z := z + 'GAA70,GAA71,GAA72,GAA73,GAA74,GAA75,GAA76,GAA77,GAA78,GAA79,GAB70,GAB71,GAB72,GAB73,GAB74,';
     z := z + 'GAB75,GAB76,GAB77,GAB78,GAB79,GAC70,GAC71,GAC72,GAC73,GAC74,GAC75,GAC76,GAC77,GAC78,GAC79,';
     z := z + 'GAD70,GAD71,GAD72,GAD73,GAD74,GAD75,GAD76,GAD77,GAD78,GAD79,GAE70,GAE71,GAE72,GAE73,GAE74,';
     z := z + 'GAE75,GAE76,GAE77,GAE78,GAE79,GAF70,GAF71,GAF72,GAF73,GAF74,GAF75,GAF76,GAF77,GAF78,GAF79,';
     z := z + 'GAG70,GAG71,GAG72,GAG73,GAG74,GAG75,GAG76,GAG77,GAG78,GAG79,GAH70,GAH71,GAH72,GAH73,GAH74,';
     z := z + 'GAH75,GAH76,GAH77,GAH78,GAH79,GAI70,GAI71,GAI72,GAI73,GAI74,GAI75,GAI76,GAI77,GAI78,GAI79,';
     z := z + 'GAJ70,GAJ71,GAJ72,GAJ73,GAJ74,GAJ75,GAJ76,GAJ77,GAJ78,GAJ79,GAK70,GAK71,GAK72,GAK73,GAK74,';
     z := z + 'GAK75,GAK76,GAK77,GAK78,GAK79,GAL70,GAL71,GAL72,GAL73,GAL74,GAL75,GAL76,GAL77,GAL78,GAL79,';
     z := z + 'GAM70,GAM71,GAM72,GAM73,GAM74,GAM75,GAM76,GAM77,GAM78,GAM79,GAN70,GAN71,GAN72,GAN73,GAN74,';
     z := z + 'GAN75,GAN76,GAN77,GAN78,GAN79,GAO70,GAO71,GAO72,GAO73,GAO74,GAO75,GAO76,GAO77,GAO78,GAO79,';
     z := z + 'GAP70,GAP71,GAP72,GAP73,GAP74,GAP75,GAP76,GAP77,GAP78,GAP79,GAQ70,GAQ71,GAQ72,GAQ73,GAQ74,';
     z := z + 'GAQ75,GAQ76,GAQ77,GAQ78,GAQ79,GAR70,GAR71,GAR72,GAR73,GAR74,S9    ,SA    ,S     ,S     ,S     ,';
     z := z + 'GAA60,GAA61,GAA62,GAA63,GAA64,GAA65,GAA66,GAA67,GAA68,GAA69,GAB60,GAB61,GAB62,GAB63,GAB64,';
     z := z + 'GAB65,GAB66,GAB67,GAB68,GAB69,GAC60,GAC61,GAC62,GAC63,GAC64,GAC65,GAC66,GAC67,GAC68,GAC69,';
     z := z + 'GAD60,GAD61,GAD62,GAD63,GAD64,GAD65,GAD66,GAD67,GAD68,GAD69,GAE60,GAE61,GAE62,GAE63,GAE64,';
     z := z + 'GAE65,GAE66,GAE67,GAE68,GAE69,GAF60,GAF61,GAF62,GAF63,GAF64,GAF65,GAF66,GAF67,GAF68,GAF69,';
     z := z + 'GAG60,GAG61,GAG62,GAG63,GAG64,GAG65,GAG66,GAG67,GAG68,GAG69,GAH60,GAH61,GAH62,GAH63,GAH64,';
     z := z + 'GAH65,GAH66,GAH67,GAH68,GAH69,GAI60,GAI61,GAI62,GAI63,GAI64,GAI65,GAI66,GAI67,GAI68,GAI69,';
     z := z + 'GAJ60,GAJ61,GAJ62,GAJ63,GAJ64,GAJ65,GAJ66,GAJ67,GAJ68,GAJ69,GAK60,GAK61,GAK62,GAK63,GAK64,';
     z := z + 'GAK65,GAK66,GAK67,GAK68,GAK69,GAL60,GAL61,GAL62,GAL63,GAL64,GAL65,GAL66,GAL67,GAL68,GAL69,';
     z := z + 'GAM60,GAM61,GAM62,GAM63,GAM64,GAM65,GAM66,GAM67,GAM68,GAM69,GAN60,GAN61,GAN62,GAN63,GAN64,';
     z := z + 'GAN65,GAN66,GAN67,GAN68,GAN69,GAO60,GAO61,GAO62,GAO63,GAO64,GAO65,GAO66,GAO67,GAO68,GAO69,';
     z := z + 'GAP60,GAP61,GAP62,GAP63,GAP64,GAP65,GAP66,GAP67,GAP68,GAP69,GAQ60,GAQ61,GAQ62,GAQ63,GAQ64,';
     z := z + 'GAQ65,GAQ66,GAQ67,GAQ68,GAQ69,GAR60,GAR61,GAR62,GAR63,GAR64,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GAA50,GAA51,GAA52,GAA53,GAA54,GAA55,GAA56,GAA57,GAA58,GAA59,GAB50,GAB51,GAB52,GAB53,GAB54,';
     z := z + 'GAB55,GAB56,GAB57,GAB58,GAB59,GAC50,GAC51,GAC52,GAC53,GAC54,GAC55,GAC56,GAC57,GAC58,GAC59,';
     z := z + 'GAD50,GAD51,GAD52,GAD53,GAD54,GAD55,GAD56,GAD57,GAD58,GAD59,GAE50,GAE51,GAE52,GAE53,GAE54,';
     z := z + 'GAE55,GAE56,GAE57,GAE58,GAE59,GAF50,GAF51,GAF52,GAF53,GAF54,GAF55,GAF56,GAF57,GAF58,GAF59,';
     z := z + 'GAG50,GAG51,GAG52,GAG53,GAG54,GAG55,GAG56,GAG57,GAG58,GAG59,GAH50,GAH51,GAH52,GAH53,GAH54,';
     z := z + 'GAH55,GAH56,GAH57,GAH58,GAH59,GAI50,GAI51,GAI52,GAI53,GAI54,GAI55,GAI56,GAI57,GAI58,GAI59,';
     z := z + 'GAJ50,GAJ51,GAJ52,GAJ53,GAJ54,GAJ55,GAJ56,GAJ57,GAJ58,GAJ59,GAK50,GAK51,GAK52,GAK53,GAK54,';
     z := z + 'GAK55,GAK56,GAK57,GAK58,GAK59,GAL50,GAL51,GAL52,GAL53,GAL54,GAL55,GAL56,GAL57,GAL58,GAL59,';
     z := z + 'GAM50,GAM51,GAM52,GAM53,GAM54,GAM55,GAM56,GAM57,GAM58,GAM59,GAN50,GAN51,GAN52,GAN53,GAN54,';
     z := z + 'GAN55,GAN56,GAN57,GAN58,GAN59,GAO50,GAO51,GAO52,GAO53,GAO54,GAO55,GAO56,GAO57,GAO58,GAO59,';
     z := z + 'GAP50,GAP51,GAP52,GAP53,GAP54,GAP55,GAP56,GAP57,GAP58,GAP59,GAQ50,GAQ51,GAQ52,GAQ53,GAQ54,';
     z := z + 'GAQ55,GAQ56,GAQ57,GAQ58,GAQ59,GAR50,GAR51,GAR52,GAR53,GAR54,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GAA40,GAA41,GAA42,GAA43,GAA44,GAA45,GAA46,GAA47,GAA48,GAA49,GAB40,GAB41,GAB42,GAB43,GAB44,';
     z := z + 'GAB45,GAB46,GAB47,GAB48,GAB49,GAC40,GAC41,GAC42,GAC43,GAC44,GAC45,GAC46,GAC47,GAC48,GAC49,';
     z := z + 'GAD40,GAD41,GAD42,GAD43,GAD44,GAD45,GAD46,GAD47,GAD48,GAD49,GAE40,GAE41,GAE42,GAE43,GAE44,';
     z := z + 'GAE45,GAE46,GAE47,GAE48,GAE49,GAF40,GAF41,GAF42,GAF43,GAF44,GAF45,GAF46,GAF47,GAF48,GAF49,';
     z := z + 'GAG40,GAG41,GAG42,GAG43,GAG44,GAG45,GAG46,GAG47,GAG48,GAG49,GAH40,GAH41,GAH42,GAH43,GAH44,';
     z := z + 'GAH45,GAH46,GAH47,GAH48,GAH49,GAI40,GAI41,GAI42,GAI43,GAI44,GAI45,GAI46,GAI47,GAI48,GAI49,';
     z := z + 'GAJ40,GAJ41,GAJ42,GAJ43,GAJ44,GAJ45,GAJ46,GAJ47,GAJ48,GAJ49,GAK40,GAK41,GAK42,GAK43,GAK44,';
     z := z + 'GAK45,GAK46,GAK47,GAK48,GAK49,GAL40,GAL41,GAL42,GAL43,GAL44,GAL45,GAL46,GAL47,GAL48,GAL49,';
     z := z + 'GAM40,GAM41,GAM42,GAM43,GAM44,GAM45,GAM46,GAM47,GAM48,GAM49,GAN40,GAN41,GAN42,GAN43,GAN44,';
     z := z + 'GAN45,GAN46,GAN47,GAN48,GAN49,GAO40,GAO41,GAO42,GAO43,GAO44,GAO45,GAO46,GAO47,GAO48,GAO49,';
     z := z + 'GAP40,GAP41,GAP42,GAP43,GAP44,GAP45,GAP46,GAP47,GAP48,GAP49,GAQ40,GAQ41,GAQ42,GAQ43,GAQ44,';
     z := z + 'GAQ45,GAQ46,GAQ47,GAQ48,GAQ49,GAR40,GAR41,GAR42,GAR43,GAR44,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GAA30,GAA31,GAA32,GAA33,GAA34,GAA35,GAA36,GAA37,GAA38,GAA39,GAB30,GAB31,GAB32,GAB33,GAB34,';
     z := z + 'GAB35,GAB36,GAB37,GAB38,GAB39,GAC30,GAC31,GAC32,GAC33,GAC34,GAC35,GAC36,GAC37,GAC38,GAC39,';
     z := z + 'GAD30,GAD31,GAD32,GAD33,GAD34,GAD35,GAD36,GAD37,GAD38,GAD39,GAE30,GAE31,GAE32,GAE33,GAE34,';
     z := z + 'GAE35,GAE36,GAE37,GAE38,GAE39,GAF30,GAF31,GAF32,GAF33,GAF34,GAF35,GAF36,GAF37,GAF38,GAF39,';
     z := z + 'GAG30,GAG31,GAG32,GAG33,GAG34,GAG35,GAG36,GAG37,GAG38,GAG39,GAH30,GAH31,GAH32,GAH33,GAH34,';
     z := z + 'GAH35,GAH36,GAH37,GAH38,GAH39,GAI30,GAI31,GAI32,GAI33,GAI34,GAI35,GAI36,GAI37,GAI38,GAI39,';
     z := z + 'GAJ30,GAJ31,GAJ32,GAJ33,GAJ34,GAJ35,GAJ36,GAJ37,GAJ38,GAJ39,GAK30,GAK31,GAK32,GAK33,GAK34,';
     z := z + 'GAK35,GAK36,GAK37,GAK38,GAK39,GAL30,GAL31,GAL32,GAL33,GAL34,GAL35,GAL36,GAL37,GAL38,GAL39,';
     z := z + 'GAM30,GAM31,GAM32,GAM33,GAM34,GAM35,GAM36,GAM37,GAM38,GAM39,GAN30,GAN31,GAN32,GAN33,GAN34,';
     z := z + 'GAN35,GAN36,GAN37,GAN38,GAN39,GAO30,GAO31,GAO32,GAO33,GAO34,GAO35,GAO36,GAO37,GAO38,GAO39,';
     z := z + 'GAP30,GAP31,GAP32,GAP33,GAP34,GAP35,GAP36,GAP37,GAP38,GAP39,GAQ30,GAQ31,GAQ32,GAQ33,GAQ34,';
     z := z + 'GAQ35,GAQ36,GAQ37,GAQ38,GAQ39,GAR30,GAR31,GAR32,GAR33,GAR34,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GAA20,GAA21,GAA22,GAA23,GAA24,GAA25,GAA26,GAA27,GAA28,GAA29,GAB20,GAB21,GAB22,GAB23,GAB24,';
     z := z + 'GAB25,GAB26,GAB27,GAB28,GAB29,GAC20,GAC21,GAC22,GAC23,GAC24,GAC25,GAC26,GAC27,GAC28,GAC29,';
     z := z + 'GAD20,GAD21,GAD22,GAD23,GAD24,GAD25,GAD26,GAD27,GAD28,GAD29,GAE20,GAE21,GAE22,GAE23,GAE24,';
     z := z + 'GAE25,GAE26,GAE27,GAE28,GAE29,GAF20,GAF21,GAF22,GAF23,GAF24,GAF25,GAF26,GAF27,GAF28,GAF29,';
     z := z + 'GAG20,GAG21,GAG22,GAG23,GAG24,GAG25,GAG26,GAG27,GAG28,GAG29,GAH20,GAH21,GAH22,GAH23,GAH24,';
     z := z + 'GAH25,GAH26,GAH27,GAH28,GAH29,GAI20,GAI21,GAI22,GAI23,GAI24,GAI25,GAI26,GAI27,GAI28,GAI29,';
     z := z + 'GAJ20,GAJ21,GAJ22,GAJ23,GAJ24,GAJ25,GAJ26,GAJ27,GAJ28,GAJ29,GAK20,GAK21,GAK22,GAK23,GAK24,';
     z := z + 'GAK25,GAK26,GAK27,GAK28,GAK29,GAL20,GAL21,GAL22,GAL23,GAL24,GAL25,GAL26,GAL27,GAL28,GAL29,';
     z := z + 'GAM20,GAM21,GAM22,GAM23,GAM24,GAM25,GAM26,GAM27,GAM28,GAM29,GAN20,GAN21,GAN22,GAN23,GAN24,';
     z := z + 'GAN25,GAN26,GAN27,GAN28,GAN29,GAO20,GAO21,GAO22,GAO23,GAO24,GAO25,GAO26,GAO27,GAO28,GAO29,';
     z := z + 'GAP20,GAP21,GAP22,GAP23,GAP24,GAP25,GAP26,GAP27,GAP28,GAP29,GAQ20,GAQ21,GAQ22,GAQ23,GAQ24,';
     z := z + 'GAQ25,GAQ26,GAQ27,GAQ28,GAQ29,GAR20,GAR21,GAR22,GAR23,GAR24,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GAA10,GAA11,GAA12,GAA13,GAA14,GAA15,GAA16,GAA17,GAA18,GAA19,GAB10,GAB11,GAB12,GAB13,GAB14,';
     z := z + 'GAB15,GAB16,GAB17,GAB18,GAB19,GAC10,GAC11,GAC12,GAC13,GAC14,GAC15,GAC16,GAC17,GAC18,GAC19,';
     z := z + 'GAD10,GAD11,GAD12,GAD13,GAD14,GAD15,GAD16,GAD17,GAD18,GAD19,GAE10,GAE11,GAE12,GAE13,GAE14,';
     z := z + 'GAE15,GAE16,GAE17,GAE18,GAE19,GAF10,GAF11,GAF12,GAF13,GAF14,GAF15,GAF16,GAF17,GAF18,GAF19,';
     z := z + 'GAG10,GAG11,GAG12,GAG13,GAG14,GAG15,GAG16,GAG17,GAG18,GAG19,GAH10,GAH11,GAH12,GAH13,GAH14,';
     z := z + 'GAH15,GAH16,GAH17,GAH18,GAH19,GAI10,GAI11,GAI12,GAI13,GAI14,GAI15,GAI16,GAI17,GAI18,GAI19,';
     z := z + 'GAJ10,GAJ11,GAJ12,GAJ13,GAJ14,GAJ15,GAJ16,GAJ17,GAJ18,GAJ19,GAK10,GAK11,GAK12,GAK13,GAK14,';
     z := z + 'GAK15,GAK16,GAK17,GAK18,GAK19,GAL10,GAL11,GAL12,GAL13,GAL14,GAL15,GAL16,GAL17,GAL18,GAL19,';
     z := z + 'GAM10,GAM11,GAM12,GAM13,GAM14,GAM15,GAM16,GAM17,GAM18,GAM19,GAN10,GAN11,GAN12,GAN13,GAN14,';
     z := z + 'GAN15,GAN16,GAN17,GAN18,GAN19,GAO10,GAO11,GAO12,GAO13,GAO14,GAO15,GAO16,GAO17,GAO18,GAO19,';
     z := z + 'GAP10,GAP11,GAP12,GAP13,GAP14,GAP15,GAP16,GAP17,GAP18,GAP19,GAQ10,GAQ11,GAQ12,GAQ13,GAQ14,';
     z := z + 'GAQ15,GAQ16,GAQ17,GAQ18,GAQ19,GAR10,GAR11,GAR12,GAR13,GAR14,S     ,S     ,S     ,S     ,S     ,';
     z := z + 'GAA00,GAA01,GAA02,GAA03,GAA04,GAA05,GAA06,GAA07,GAA08,GAA09,GAB00,GAB01,GAB02,GAB03,GAB04,';
     z := z + 'GAB05,GAB06,GAB07,GAB08,GAB09,GAC00,GAC01,GAC02,GAC03,GAC04,GAC05,GAC06,GAC07,GAC08,GAC09,';
     z := z + 'GAD00,GAD01,GAD02,GAD03,GAD04,GAD05,GAD06,GAD07,GAD08,GAD09,GAE00,GAE01,GAE02,GAE03,GAE04,';
     z := z + 'GAE05,GAE06,GAE07,GAE08,GAE09,GAF00,GAF01,GAF02,GAF03,GAF04,GAF05,GAF06,GAF07,GAF08,GAF09,';
     z := z + 'GAG00,GAG01,GAG02,GAG03,GAG04,GAG05,GAG06,GAG07,GAG08,GAG09,GAH00,GAH01,GAH02,GAH03,GAH04,';
     z := z + 'GAH05,GAH06,GAH07,GAH08,GAH09,GAI00,GAI01,GAI02,GAI03,GAI04,GAI05,GAI06,GAI07,GAI08,GAI09,';
     z := z + 'GAJ00,GAJ01,GAJ02,GAJ03,GAJ04,GAJ05,GAJ06,GAJ07,GAJ08,GAJ09,GAK00,GAK01,GAK02,GAK03,GAK04,';
     z := z + 'GAK05,GAK06,GAK07,GAK08,GAK09,GAL00,GAL01,GAL02,GAL03,GAL04,GAL05,GAL06,GAL07,GAL08,GAL09,';
     z := z + 'GAM00,GAM01,GAM02,GAM03,GAM04,GAM05,GAM06,GAM07,GAM08,GAM09,GAN00,GAN01,GAN02,GAN03,GAN04,';
     z := z + 'GAN05,GAN06,GAN07,GAN08,GAN09,GAO00,GAO01,GAO02,GAO03,GAO04,GAO05,GAO06,GAO07,GAO08,GAO09,';
     z := z + 'GAP00,GAP01,GAP02,GAP03,GAP04,GAP05,GAP06,GAP07,GAP08,GAP09,GAQ00,GAQ01,GAQ02,GAQ03,GAQ04,';
     z := z + 'GAQ05,GAQ06,GAQ07,GAQ08,GAQ09,GAR00,GAR01,GAR02,GAR03,GAR04,S     ,S     ,S     ,SCUSTO,S     ,';
     z := z + 'GRA90';
     wc := WordCount(z,[',']);
     for i := 0 to 32767 do demodulate.glist[i] := '';
     for i := 1 to wc do demodulate.glist[i-1] := UpCase(TrimLeft(TrimRight(ExtractWord(i,z,[',']))));
end;

function TForm1.t(const s : string) : String;
Begin
     result := TrimLeft(TrimRight(s));
end;

procedure TForm1.updateDB;
var
   foo  : string;
   foo2 : String;
   i    : Integer;
begin
     transaction.EndTransaction;
     query.Active:=False;
     query.SQL.Clear;
     foo := 'UPDATE config SET ';
     foo := foo + 'prefix=:PREFIX,call=:CALL,suffix=:SUFFIX,grid=:GRID,';
     foo := foo + 'tadc=:TADC,iadc=:IADC,tdac=:TDAC,idac=:IDAC,mono=:MONO,left=:LEFT,';
     foo := foo + 'right=:RIGHT,dgainl=:DGAINL,dgainla=:DGAINLA,dgainr=:DGAINR,dgainra=:DGAINRA,useserial=:USESERIAL,';
     foo := foo + 'usealt=:USEALT,port=:PORT,pttdtrrts=:PTTDTRRTS,pttrts=:PTTRTS,pttdtr=:PTTDTR,dtrnever=:DTRNEVER,';
     foo := foo + 'dtralways=:DTRALWAYS,rtsnever=:RTSNEVER,rtsalways=:RTSALWAYS,txwatchdog=:TXWD,txwatchdogcount=:TXWDCOUNT,';
     foo := foo + 'rigcontrol=:RIGCONTROL,pttcat=:PTTCAT,txdfcat=:TXDFCAT,perioddivide=:PDIVIDE,periodcompact=:PCOMPACT,';
     foo := foo + 'usecolor=:USECOLOR,cqcolor=:CQCOLOR,mycallcolor=:MYCOLOR,qsocolor=:QSOCOLOR,wfcmap=:WFCMAP,';
     foo := foo + 'wfspeed=:WFSPEED,wfcontrast=:WFCONTRAST,wfbright=:WFBRIGHT,wfgain=:WFGAIN,wfsmooth=:WFSMOOTH,';
     foo := foo + 'wfagc=:WFAGC,userb=:USERB,spotcall=:RBCALL,spotinfo=:RBINFO,';
     foo := foo + 'usecsv=:USECSV,csvpath=:CSVPATH,adifpath=:ADIFPATH,logas=:LOGAS,remembercomments=:REMCOM,';
     foo := foo + 'multioffqso=:MQSOOFF,automultion=:MAUTOON,halttxsetsmulti=:MHALTMON,defaultsetsmulti=:MDEFMON,';
     foo := foo + 'decimal=:DECI,cwid=:CWID,cwidcall=:CWCALL,disableoptfft=:NOOPTFFT,disablekv=:NOKV,';
     foo := foo + 'lastqrg=:LASTQRG,sbinspace=:SBIN,mbinspace=:MBIN,txlevel=:TXLEVEL,version=:VER,';
     foo := foo + 'multion=:MON,txeqrxdf=:TXEQRX,needcfg=:NEEDCFG WHERE instance=:INSTANCE';
     query.SQL.Text := foo;
     Query.Params.ParamByName('PREFIX').AsString     := t(edPrefix.Text);
     Query.Params.ParamByName('CALL').AsString       := t(edCall.Text);
     Query.Params.ParamByName('SUFFIX').AsString     := t(edSuffix.Text);
     Query.Params.ParamByName('GRID').AsString       := t(edGrid.Text);
     Query.Params.ParamByName('TADC').AsString       := t(savedTADC);
     Query.Params.ParamByName('IADC').AsInteger      := savedIADC;
     //Query.Params.ParamByName('TDAC').AsString       := t(tdac.Text);
     //If not TryStrToInt(t(idac.Text),i) then i := -1;
     //Query.Params.ParamByName('IDAC').AsInteger      := i;
     Query.Params.ParamByName('MONO').AsBoolean      := cbUseMono.Checked;
     Query.Params.ParamByName('LEFT').AsBoolean      := rbUseLeftAudio.Checked;
     Query.Params.ParamByName('RIGHT').AsBoolean     := rbUseRightAudio.Checked;
     if dgainL0.Checked then i := 0;
     if dgainL3.Checked then i := 3;
     if dgainL6.Checked then i := 6;
     if dgainL9.Checked then i := 9;
     Query.Params.ParamByName('DGAINL').AsInteger    := i;
     Query.Params.ParamByName('DGAINLA').AsBoolean   := cbAttenuateLeft.Checked;
     if dgainR0.Checked then i := 0;
     if dgainR3.Checked then i := 3;
     if dgainR6.Checked then i := 6;
     if dgainR9.Checked then i := 9;
     Query.Params.ParamByName('DGAINR').AsInteger    := i;
     Query.Params.ParamByName('DGAINRA').AsBoolean   := cbAttenuateRight.Checked;
     Query.Params.ParamByName('USESERIAL').AsBoolean := cbUseSerial.Checked;
     //Query.Params.ParamByName('USEALT').AsBoolean    := cbUseAltPTT.Checked;
     If not TryStrToInt(t(edPort.Text),i) then i := -1;
     Query.Params.ParamByName('PORT').AsInteger      := i;
     Query.Params.ParamByName('TXWD').AsBoolean      := cbUseTXWD.Checked;
     If not TryStrToInt(t(edTXWD.Text),i) then i := -1;
     Query.Params.ParamByName('TXWDCOUNT').AsInteger := i;
     if rigNone.Checked then foo2 := 'None';
     if rigRebel.Checked then foo2 := 'Rebel';
     Query.Params.ParamByName('RIGCONTROL').AsString := t(foo2);
     Query.Params.ParamByName('PDIVIDE').AsBoolean   := cbDivideDecodes.Checked;
     Query.Params.ParamByName('PCOMPACT').AsBoolean  := cbCompactDivides.Checked;
     Query.Params.ParamByName('USECOLOR').AsBoolean  := cbUseColor.Checked;
     Query.Params.ParamByName('CQCOLOR').AsInteger   := cbCQColor.ItemIndex;
     Query.Params.ParamByName('MYCOLOR').AsInteger   := cbMyCallColor.ItemIndex;
     Query.Params.ParamByName('QSOCOLOR').AsInteger  := cbQSOColor.ItemIndex;
     Query.Params.ParamByName('WFCMAP').AsInteger    := spColorMap.ItemIndex;
     Query.Params.ParamByName('WFSPEED').AsInteger   := tbWFSpeed.Position;
     Query.Params.ParamByName('WFCONTRAST').AsInteger := tbWFContrast.Position;
     Query.Params.ParamByName('WFBRIGHT').AsInteger   := tbWFBright.Position;
     Query.Params.ParamByName('WFGAIN').AsInteger     := tbWFGain.Position;
     Query.Params.ParamByName('WFSMOOTH').AsBoolean  := cbSpecSmooth.Checked;
     Query.Params.ParamByName('WFAGC').AsBoolean     := cbSpecSmooth.Checked;
     Query.Params.ParamByName('USERB').AsBoolean     := True;
     Query.Params.ParamByName('RBCALL').AsString     := t(edRBCall.Text);
     Query.Params.ParamByName('RBINFO').AsString     := t(edStationInfo.Text);
     Query.Params.ParamByName('USECSV').AsBoolean    := cbSaveToCSV.Checked;
     Query.Params.ParamByName('CSVPATH').AsString    := t(edCSVPath.Text);
     Query.Params.ParamByName('ADIFPATH').AsString   := t(edADIFPath.Text);
     Query.Params.ParamByName('LOGAS').AsString      := t(edADIFMode.Text);
     Query.Params.ParamByName('REMCOM').AsBoolean    := cbRememberComments.Checked;
     Query.Params.ParamByName('MQSOOFF').AsBoolean   := cbMultiOffQSO.Checked;
     Query.Params.ParamByName('MAUTOON').AsBoolean   := cbRestoreMulti.Checked;
     Query.Params.ParamByName('MHALTMON').AsBoolean  := cbHaltTXMultiOn.Checked;
     Query.Params.ParamByName('MDEFMON').AsBoolean   := cbDefaultsMultiOn.Checked;
     foo2 := 'Auto';
     if useDeciAmerican.Checked then foo2 := 'USA';
     if useDeciEuro.Checked then foo2 := 'Euro';
     if useDeciAuto.Checked then foo2 := 'Auto';
     Query.Params.ParamByName('DECI').AsString      := t(foo2);
     foo2 := 'Never';
     if rbNoCWID.Checked then foo2 := 'Never';
     if rbCWID73.Checked then foo2 := '73';
     if rbCWIDFree.Checked then foo2 := 'Free';
     Query.Params.ParamByName('CWID').AsString      := t(foo2);
     Query.Params.ParamByName('CWCALL').AsString    := t(edCWID.Text);
     Query.Params.ParamByName('NOOPTFFT').AsBoolean := cbNoOptFFT.Checked;
     Query.Params.ParamByName('NOKV').AsBoolean     := cbNoKV.Checked;
     Query.Params.ParamByName('LASTQRG').AsString   := t(lastQRG.Text);
     Query.Params.ParamByName('SBIN').AsInteger    := tbSingleBin.Position;
     Query.Params.ParamByName('MBIN').AsInteger    := tbMultiBin.Position;
     Query.Params.ParamByName('TXLEVEL').AsInteger    := tbTXLevel.Position;
     If not TryStrToInt(t(version.Text),i) then i := -1;
     Query.Params.ParamByName('VER').AsInteger    := i;
     Query.Params.ParamByName('MON').AsBoolean    := cbMultiOn.Checked;
     Query.Params.ParamByName('TXEQRX').AsBoolean := cbTXEqRXDF.Checked;
     Query.Params.ParamByName('NEEDCFG').AsBoolean := False;
     Query.Params.ParamByName('INSTANCE').AsInteger := 1;
     transaction.StartTransaction;
     query.ExecSQL;
     transaction.Commit;
     transaction.Active:=False;
     query.Active:=False;
end;

procedure TForm1.setupDB(const cfgPath : String);
Var
   foo : String;
   i   : Integer;
Begin
     showMessage('Building initial config - this may take some time and program will appear non-responsive.');
     setG;
     sqlite3.DatabaseName := cfgPath + 'jt65hf_datastore';
     query.SQL.Clear;
     query.SQL.Add('CREATE TABLE ngdb(id integer primary key, xlate string(5))');
     query.ExecSQL;
     transaction.Commit;
     // Definitions for ng 15 bit field
     for i := 0 to length(demodulate.glist)-1 do
     begin
          query.SQL.Clear;
          query.SQL.Add('INSERT INTO ngdb(xlate) VALUES("' + demodulate.glist[i] + '")');
          query.ExecSQL;
     end;
     transaction.Commit;
     // QRG Definitions
     query.SQL.Clear;
     query.SQL.Add('CREATE TABLE qrg(id integer primary key, instance integer, fqrg float)');
     query.ExecSQL;
     query.SQL.Clear;
     query.SQL.Text := 'INSERT INTO qrg(instance, fqrg) VALUES(:INSTANCE,:QRG);';
     query.Params.ParamByName('INSTANCE').AsInteger :=1;
     query.Params.ParamByName('QRG').AsFloat := 1836000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 3576000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 7039000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 7075700.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 7076000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 7076300.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 10138000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 14075300.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 14075600.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 14076000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 14076300.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 14076600.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 14076900.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 18102000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 18106000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 21076000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 24920000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 28076000.0;
     query.ExecSQL;
     query.Params.ParamByName('QRG').AsFloat := 50276000.0;
     query.ExecSQL;
     transaction.Commit;
     // Macro Definitions
     query.SQL.Clear;
     query.SQL.Add('CREATE TABLE macro(id integer primary key, instance integer, text string(13))');
     query.ExecSQL;
     query.SQL.Clear;
     query.SQL.Text := 'INSERT INTO macro(instance, text) VALUES(:INSTANCE,:TEXT);';
     // Defining the 3 shorthand types.
     query.Params.ParamByName('INSTANCE').AsInteger :=1;
     query.Params.ParamByName('TEXT').AsString := 'RRR';
     query.ExecSQL;
     query.Params.ParamByName('TEXT').AsString := 'RO';
     query.ExecSQL;
     query.Params.ParamByName('TEXT').AsString := '73';
     query.ExecSQL;
     transaction.Commit;
     // Configuration
     foo :='CREATE TABLE config(';
     foo := foo + 'instance integer primary key,prefix string(4),call string(6),suffix string(3), grid string(6), ';
     foo := foo + 'tadc varchar(255), iadc integer, tdac varchar(255), idac integer, mono bool, left bool, ';
     foo := foo + 'right bool, dgainl integer, dgainla bool, dgainr integer, dgainra bool, useserial bool, ';
     foo := foo + 'usealt bool, port integer, pttdtrrts bool, pttrts bool, pttdtr bool, dtrnever bool, ';
     foo := foo + 'dtralways bool, rtsnever bool, rtsalways bool, txwatchdog bool, txwatchdogcount integer, ';
     foo := foo + 'rigcontrol varchar(12), pttcat bool, txdfcat bool, perioddivide bool, periodcompact bool, ';
     foo := foo + 'usecolor bool, cqcolor integer, mycallcolor integer, qsocolor integer, wfcmap integer, ';
     foo := foo + 'wfspeed integer, wfcontrast integer, wfbright integer, wfgain integer, wfsmooth bool, ';
     foo := foo + 'wfagc bool, userb bool, spotcall varchar(32), spotinfo varchar(255), ';
     foo := foo + 'usecsv bool, csvpath varchar(255), adifpath varchar(255), logas varchar(5), remembercomments bool, ';
     foo := foo + 'multioffqso bool, automultion bool, halttxsetsmulti bool, defaultsetsmulti bool, ';
     foo := foo + 'decimal varchar(10), cwid varchar(10), cwidcall varchar(11), disableoptfft bool, disablekv bool, ';
     foo := foo + 'lastqrg varchar(10), sbinspace integer, mbinspace integer, txlevel integer, version integer, ';
     foo := foo + 'multion bool, txeqrxdf bool, needcfg bool)';
     query.SQL.Clear;
     query.SQL.Add(foo);
     query.ExecSQL;
     transaction.Commit;
End;

procedure TForm1.setDefaults;
Begin
     // Need to set sane defaults.
     // Tabsheet 1
     edPrefix.Text := '';
     edCall.Text := '';
     edSuffix.Text :='';
     edGrid.Text := '';
     comboAudioIn.ItemIndex:=0;
     cbUseMono.Checked := False;
     rbUseLeftAudio.Checked := True;
     dgainL0.Checked := True;
     dgainR0.Checked := True;
     cbAttenuateLeft.Checked := False;
     cbAttenuateRight.Checked := False;
     // Tabsheet 2
     rigNone.Checked := True;
     cbUseSerial.Checked := True;
     edPort.Text := '-1';
     cbUseTXWD.Checked := True;
     edTXWD.Text := '10';
     // Tabsheet 3
     cbDivideDecodes.Checked := True;
     cbCompactDivides.Checked := True;
     cbUseColor.Checked := True;
     cbCQColor.ItemIndex := 0;
     cbMyCallColor.ItemIndex := 0;
     cbQSOColor.ItemIndex := 0;
     spColorMap.ItemIndex := 2;
     tbWFSpeed.Position := 5;
     tbWFContrast.Position := 0;
     tbWFBright.Position := 0;
     tbWFGain.Position := 0;
     cbSpecSmooth.Checked := True;
     // Tabsheet 4
     edRBCall.Text := '';
     edStationInfo.Text := '';
     cbSaveToCSV.Checked := False;
     edCSVPath.Text := homeDir;
     // Tabsheet 5
     edADIFPath.Text := homeDir;
     edADIFMode.Text := 'JT65';
     cbRememberComments.Checked := False;
     // Tabsheet 6
     cbMultiOffQSO.Checked := True;
     cbRestoreMulti.Checked := True;
     cbHaltTXMultiOn.Checked := False;
     cbDefaultsMultiOn.Checked := True;
     useDeciAuto.Checked := True;
     rbNoCWID.Checked := True;
     edCWID.Text := '';
     cbNoOptFFT.Checked := False;
     cbNoKV.Checked := False;
     // Set main GUI variable controls
     tbMultiBin.Position := 1; // 20 Hz
     tbMultiBinChange(tbMultiBin);
     inDev  := -1;
     pttDev := -1;
     inIcal := 0;
     edDialQRG.Text := '0';
     editQRG.Text := '0';
     tbTXLevel.Position := 16;
     // Setup decimal characters
     if useDeciAmerican.Checked then
     begin
          dChar := '.';
          kChar := ',';
     end;
     if useDeciEuro.Checked then
     begin
          dChar := ',';
          kChar := '.';
     end;
     if useDeciAuto.Checked then
     begin
          dChar := DecimalSeparator;
          kChar := ThousandSeparator;
          if dChar = '.' Then useDeciAuto.Caption := 'Use System Default (decimal = . thousands = ,)';
          if dChar = ',' Then useDeciAuto.Caption := 'Use System Default (decimal = , thousands = .)';
     end;
     // Update the DB
     updateDB;
     buttonConfig.Visible := False;
     Button4.Visible      := True;
     PageControl.Visible := True;
end;

function TForm1.rebelCommand(const cmd : String; const value : String; const ltx : Array of String; var error : String) : Boolean;
Var
   portvalid : Boolean;
   i         : Integer;
   foo       : String;
Begin
     {
     Command         Value                    Response Expected
     VER                                      JT65100 or something like that - TBD as of now
     RRX                                      Current RX QRZ as integer Hz (String)
     SRX             Integr HZ as String      OK or NO   Set RX QRG to value
     TXE                                      OK or NO   Key and start TX
     TXH                                      OK or NO   Unkey and stop TX
     LTX                                      OK or NO   Load TX Values (compound command)
     On OK to LTX next comes first frequency Hz to 1/10 hz resolution as string - no decimal like 140772705 for 12,077,270.5 Hz
     140772705                                OK or NO   Load base frequency for sync vector
     on OK start loading in remaining 63 QRG values same format as above but drop the MHz
     772758                                   . or X     That 14(or 7),077,275.8 Hz
     On . load next value - on X retry
     Load remaining 62 values as above - after load of 64th frequency response is OK or NO
     }
     portvalid := False;
     error := 'NO';
     // Check that we have a valid setup to even try this
     If edPort.Text = '-1' Then
     Begin
          error := 'Bad COM Port Value (-1)';
          portvalid := False;
     end
     else
     begin
          // Check to see if we have a valid port
          if length(edPort.Text) > 0 Then
          Begin
               i := -1;
               If not TryStrToInt(edPort.Text,i) Then i := -2;
               if (i > 0) And (i < 256) Then
               Begin
                    // Seem to have a valid port lets see if we can open it
                    tty.Connect('COM'+edPort.Text);
                    try
                       if tty.InstanceActive Then
                       Begin
                            tty.Config(115200,8,'N',synaser.SB1,False,False);
                            portvalid := True;
                       end
                       else
                       begin
                            error := 'Open of COM' + edPort.Text + ' fails';
                            portvalid := False;
                       end;
                    except
                       error := 'Open of COM' + edPort.Text + ' fails';
                       portvalid := False;
                    end;
               end
               else
               begin
                    error := 'Bad COM Port Value (-1)';
                    portvalid := False;
               end;
          end
          else
          begin
               error := 'Open of COM' + edPort.Text + ' fails';
               portvalid := False;
          end;
     end;

     if portvalid Then
     Begin
          // LTX
          if cmd='LTX' Then
          Begin
               try
                  for i := -1 to 63 do
                  begin
                       if i = -1 Then
                       Begin
                            // Send LTX
                            tty.SendString('LTX' + sLineBreak);
                            foo := '';
                            foo := tty.Recvstring(100); // Expects a CR/LF terminated string.
                            if tty.LastError = synaser.ErrTimeout then foo := tty.Recvstring(100); // 1 retry
                            if tty.LastError <> 0 then
                            Begin
                                 error := 'Timeout';
                                 result := False;
                                 break;
                            end
                            else
                            begin
                                 if foo = 'OK' Then
                                 Begin
                                      // Continue on
                                 end
                                 else
                                 begin
                                      // NAK from Rebel - all is lost
                                      error := 'Abort';
                                      result := False;
                                      break;
                                 end;
                            end;
                       end;

                       if i = 0 Then
                       Begin
                            // Send Sync QRG
                            // Can move on to next step - LTX acked load base QRG
                            tty.SendString(ltx[0] + sLineBreak); // Sent sync QRG
                            foo := '';
                            foo := tty.Recvstring(100); // Expects a CR/LF terminated string.
                            if tty.LastError = synaser.ErrTimeout then foo := tty.Recvstring(100); // 1 retry
                            if tty.LastError <> 0 then
                            Begin
                                 error := 'Timeout';
                                 result := False;
                                 break;
                            end
                            else
                            begin
                                 if foo = 'OK' Then
                                 Begin
                                      // Continue on
                                 end
                                 else
                                 begin
                                      // NAK from Rebel - all is lost
                                      error := 'Abort';
                                      result := False;
                                      break;
                                 end;
                            end;
                       end;

                       if (i>0) And (i<63) Then
                       Begin
                            // Send first 62 data QRG values
                            // 1..62 expects a . or X response
                            tty.SendString(ltx[i] + sLineBreak); // Sent sync QRG
                            foo := '';
                            foo := tty.Recvstring(100); // Expects a CR/LF terminated string.
                            if tty.LastError = synaser.ErrTimeout then foo := tty.Recvstring(100); // 1 retry
                            if tty.LastError <> 0 then
                            Begin
                                 error := 'Timeout';
                                 result := False;
                                 break; // Terminate the loop - we're dead.
                            end
                            else
                            begin
                                 if foo = '.' Then
                                 Begin
                                      // Continue on
                                 end
                                 else
                                 Begin
                                      // NAK from Rebel - all is lost
                                      error := 'Abort';
                                      result := False;
                                      break;
                                 end;
                            end;
                       end;

                       if i=63 Then
                       Begin
                            // Send 63rd data QRG value
                            tty.SendString(ltx[i] + sLineBreak); // Send last data QRG
                            foo := '';
                            foo := tty.Recvstring(100); // Expects a CR/LF terminated string.
                            if tty.LastError = synaser.ErrTimeout then foo := tty.Recvstring(100); // 1 retry
                            if tty.LastError <> 0 then
                            Begin
                                 error := 'Timeout';
                                 result := False;
                                 break; // Terminate the loop - we're dead.
                            end
                            else
                            begin
                                 if foo = 'OK' Then
                                 Begin
                                      error := foo;
                                      result := True;
                                 end
                                 else
                                 Begin
                                      // NAK from Rebel - all is lost
                                      error := 'Abort';
                                      result := False;
                                      break;
                                 end;
                            end;
                       end;
                  end;
               except
                  error := 'Port error';
                  result := False;
               end;
          end;

          // VER
          if cmd='VER' Then
          Begin
               Try
                  tty.SendString('VER'+sLineBreak);
                  foo := '';
                  foo := tty.Recvstring(100); // Expects a CR/LF terminated string.
                  if tty.LastError = synaser.ErrTimeout then foo := tty.Recvstring(100); // 1 retry
                  if tty.LastError <> 0 then
                  Begin
                       error := 'Timeout';
                       result := False;
                  end
                  else
                  begin
                       result := True;
                       error := foo;
                  end;
               except
                  error := 'Port error';
                  result := False;
               end;
          end;

          // RRX
          if cmd='RRX' Then
          Begin
               Try
                  tty.SendString('RRX' + sLineBreak);
                  foo := '';
                  foo := tty.Recvstring(100); // Expects a CR/LF terminated string.
                  if tty.LastError = synaser.ErrTimeout then foo := tty.Recvstring(100); // 1 retry
                  if tty.LastError <> 0 then
                  Begin
                       error := 'Timeout';
                       result := False;
                  end
                  else
                  begin
                       result := True;
                       error := foo;
                  end;
               except
                  error := 'Port error';
                  result := False;
               end;
          end;

          // SRX
          if cmd='SRX' Then
          Begin
               Try
                  tty.SendString('SRX '+ value + sLineBreak);
                  foo := '';
                  foo := tty.Recvstring(100); // Expects a CR/LF terminated string.
                  if tty.LastError = synaser.ErrTimeout then foo := tty.Recvstring(100); // 1 retry
                  if tty.LastError <> 0 then
                  Begin
                       error := 'Timeout';
                       result := False;
                  end
                  else
                  begin
                       result := True;
                       error := foo;
                  end;
               except
                  error := 'Port error';
                  result := False;
               end;
          end;

          // TXE
          if cmd='TXE' Then
          Begin
               Try
                  tty.SendString('TXE' + sLineBreak);
                  foo := '';
                  foo := tty.Recvstring(100); // Expects a CR/LF terminated string.
                  if tty.LastError = synaser.ErrTimeout then foo := tty.Recvstring(100); // 1 retry
                  if tty.LastError <> 0 then
                  Begin
                       error := 'Timeout';
                       result := False;
                  end
                  else
                  begin
                       result := True;
                       error := foo;
                  end;
               except
                  error := 'Port error';
                  result := False;
               end;
          end;
          // THX
          if cmd='TXH' Then
          Begin
               Try
                  tty.SendString('TXH' + sLineBreak);
                  foo := '';
                  foo := tty.Recvstring(100); // Expects a CR/LF terminated string.
                  if tty.LastError = synaser.ErrTimeout then foo := tty.Recvstring(100); // 1 retry
                  if tty.LastError <> 0 then
                  Begin
                       error := 'Timeout';
                       result := False;
                  end
                  else
                  begin
                       result := True;
                       error := foo;
                  end;
               except
                  error := 'Port error';
                  result := False;
               end;
          end;
     end
     else
     begin
          if error='NO' then error  := 'Invalid COM settings';
          Result := False;
     end;

     // Clean up
     try
        tty.CloseSocket;
     except
        // Probably never opened - safe to ignore.
     end;
end;
end.
