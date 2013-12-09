{ TODO :

Think about having RX move to keep passband centered for Rebel


Less urgent
Order fields in logging panel
Shorthand decoder core dumped
Begin to graft sound output code in
Add macro edit/define Partially done
Add qrg edit/define
Add worked call tracking taking into consideration a call worked in one grid is not
worked if in a new one.
}

// (c) 2013 CQZ Electronics
unit Unit1;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Math, StrUtils, CTypes, Windows, lconvencoding, TAGraph, TASeries,
  ComCtrls, EditBtn, DbCtrls, Types, portaudio, adc, spectrum,
  waterfall1, spot, BufDataset, sqlite3conn, sqldb, valobject, rebel,
  d65, LResources, blcksock, gettext;

Const
  JT_DLL = 'JT65v392.dll';
  JT9_DLL = 'libjt9.dll';
  SYNC65 : array[0..125] of CTypes.cint =
        (1,0,0,1,1,0,0,0,1,1,1,1,1,1,0,1,0,1,0,0,0,1,0,1,1,0,0,1,0,0,0,1,1,1,0,0,1,1,1,1,0,1,1,0,1,1,1,1,0,0,0,1,1,0,1,0,1,0,1,1,
        0,0,1,1,0,1,0,1,0,1,0,0,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,1,1,0,1,0,0,1,0,1,1,0,1,0,1,0,1,0,0,1,1,0,0,1,0,0,1,0,0,0,0,1,1,
        1,1,1,1,1,1);

  V1PREFIX : array[0..338] of String =
        ('1A','1S','3A','3B6','3B8','3B9','3C','3C0','3D2','3D2C','3D2R','3DA','3V','3W','3X','3Y','3YB','3YP','4J','4L','4S',
         '4U1I','4U1U','4W','4X','5A','5B','5H','5N','5R','5T','5U','5V','5W','5X','5Z','6W','6Y','7O','7P','7Q','7X','8P','8Q',
         '8R','9A','9G','9H','9J','9K','9L','9M2','9M6','9N','9Q','9U','9V','9X','9Y','A2','A3','A4','A5','A6','A7','A9','AP',
         'BS7','BV','BV9','BY','C2','C3','C5','C6','C9','CE','CE0X','CE0Y','CE0Z','CE9','CM','CN','CP','CT','CT3','CU','CX','CY0',
         'CY9','D2','D4','D6','DL','DU','E3','E4','EA','EA6','EA8','EA9','EI','EK','EL','EP','ER','ES','ET','EU','EX','EY','EZ',
         'F','FG','FH','FJ','FK','FKC','FM','FO','FOA','FOC','FOM','FP','FR','FRG','FRJ','FRT','FT5W','FT5X','FT5Z','FW','FY','M',
         'MD','MI','MJ','MM','MU','MW','H4','H40','HA','HB','HB0','HC','HC8','HH','HI','HK','HK0A','HK0M','HL','HM','HP','HR','HS',
         'HV','HZ','I','IS','IS0','J2','J3','J5','J6','J7','J8','JA','JDM','JDO','JT','JW','JX','JY','K','KG4','KH0','KH1','KH2',
         'KH3','KH4','KH5','KH5K','KH6','KH7','KH8','KH9','KL','KP1','KP2','KP4','KP5','LA','LU','LX','LY','LZ','OA','OD','OE','OH',
         'OH0','OJ0','OK','OM','ON','OX','OY','OZ','P2','P4','PA','PJ2','PJ7','PY','PY0F','PT0S','PY0T','PZ','R1F','R1M','S0','S2',
         'S5','S7','S9','SM','SP','ST','SU','SV','SVA','SV5','SV9','T2','T30','T31','T32','T33','T5','T7','T8','T9','TA','TF','TG',
         'TI','TI9','TJ','TK','TL','TN','TR','TT','TU','TY','TZ','UA','UA2','UA9','UK','UN','UR','V2','V3','V4','V5','V6','V7','V8',
         'VE','VK','VK0H','VK0M','VK9C','VK9L','VK9M','VK9N','VK9W','VK9X','VP2E','VP2M','VP2V','VP5','VP6','VP6D','VP8','VP8G',
         'VP8H','VP8O','VP8S','VP9','VQ9','VR','VU','VU4','VU7','XE','XF4','XT','XU','XW','XX9','XZ','YA','YB','YI','YJ','YK','YL',
         'YN','YO','YS','YU','YV','YV0','Z2','Z3','ZA','ZB','ZC4','ZD7','ZD8','ZD9','ZF','ZK1N','ZK1S','ZK2','ZK3','ZL','ZL7','ZL8',
         'ZL9','ZP','ZS','ZS8','KC4','E5');

  V1SUFFIX : array[0..11] of String =
        ('P','0','1','2','3','4','5','6','7','8','9','A');

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

  { TForm1 }

  TForm1 = class(TForm)
    b73: TButton;
    bACQ: TButton;
    bCQ: TButton;
    bnSaveMacro: TButton;
    bQRZ: TButton;
    bReport: TButton;
    bRReport: TButton;
    bRRR: TButton;
    Chart1: TChart;
    Chart1LineSeries1: TLineSeries;
    Chart2: TChart;
    Chart2LineSeries1: TLineSeries;
    Chart2LineSeries2: TLineSeries;
    Chart2LineSeries3: TLineSeries;
    Chart3: TChart;
    Chart3LineSeries1: TLineSeries;
    Chart3LineSeries2: TLineSeries;
    Chart3LineSeries3: TLineSeries;
    Chart4: TChart;
    Chart4BarSeries1: TBarSeries;
    edRebRXOffset40: TEdit;
    edRebTXOffset40: TEdit;
    Label16: TLabel;
    Label44: TLabel;
    Label45: TLabel;
    Label46: TLabel;
    logEQSL: TButton;
    logClearComments: TButton;
    doLogQSO: TButton;
    logCancel: TButton;
    logEndTime: TButton;
    logClearCancel: TButton;
    logGrid: TEdit;
    Label107: TLabel;
    logDXLab: TButton;
    buttonXferMacro: TButton;
    cbNZLPF: TCheckBox;
    cbWFTX: TCheckBox;
    cbSpecWindow: TCheckBox;
    comboTTYPorts: TComboBox;
    edRebTXOffset: TEdit;
    edRebRXOffset: TEdit;
    groupRebelOptions: TGroupBox;
    Image1: TImage;
    Label12: TLabel;
    Label14: TLabel;
    Label22: TLabel;
    Label25: TLabel;
    Label37: TLabel;
    Label53: TLabel;
    Label54: TLabel;
    Label55: TLabel;
    Label56: TLabel;
    Label57: TLabel;
    Label58: TLabel;
    Label59: TLabel;
    Label60: TLabel;
    Label61: TLabel;
    Label62: TLabel;
    Label63: TLabel;
    Label64: TLabel;
    Label65: TLabel;
    PaintBox1: TPaintBox;
    ProgressBar1: TProgressBar;
    rbRebBaud9600: TRadioButton;
    rbRebBaud115200: TRadioButton;
    rigCommander: TRadioButton;
    toggleTX: TToggleBox;
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
    Memo2: TMemo;
    Panel1: TPanel;
    rbMode65: TRadioButton;
    rbTXEven: TRadioButton;
    rbTXOdd: TRadioButton;
    rbMode4: TRadioButton;
    rbMode9: TRadioButton;
    rbRX2K: TRadioButton;
    rbRX5K: TRadioButton;
    rbModeR: TRadioButton;
    rbModeP: TRadioButton;
    groupTXMode: TRadioGroup;
    groupBW: TRadioGroup;
    rigRebel: TRadioButton;
    lastQRG: TEdit;
    tbMultiBin: TTrackBar;
    tbSingleBin: TTrackBar;
    txLevel: TEdit;
    version: TEdit;
    comboQRGList: TComboBox;
    GroupBox16: TGroupBox;
    Label121: TLabel;
    Label122: TLabel;
    Label24: TLabel;
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
    btnsetQRG: TButton;
    btnClearDecodes: TButton;
    buttonConfig: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    updateConfig: TButton;
    edDialQRG: TEdit;
    edGrid: TEdit;
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
    TabSheet9: TTabSheet;
    GroupBox17: TGroupBox;
    GroupBox18: TGroupBox;
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
    tbWFSpeed: TTrackBar;
    tbWFContrast: TTrackBar;
    tbWFBright: TTrackBar;
    tbWFGain: TTrackBar;
    Waterfall: TWaterfallControl1;
    procedure audioChange(Sender: TObject);
    procedure bnSaveMacroClick(Sender: TObject);
    procedure cbMultiOnChange(Sender: TObject);
    procedure Chart1DblClick(Sender: TObject);
    procedure doLogQSOClick(Sender: TObject);
    procedure buttonXferMacroClick(Sender: TObject);
    procedure cbNZLPFChange(Sender: TObject);
    procedure comboQRGListChange(Sender: TObject);
    procedure comboMacroListChange(Sender: TObject);
    procedure btnsetQRGClick(Sender: TObject);
    procedure btnClearDecodesClick(Sender: TObject);
    procedure buttonConfigClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure comboTTYPortsChange(Sender: TObject);
    procedure edRXDFChange(Sender: TObject);
    procedure edRXDFDblClick(Sender: TObject);
    procedure edTXDFChange(Sender: TObject);
    procedure edTXDFDblClick(Sender: TObject);
    procedure edTXReportDblClick(Sender: TObject);
    procedure edTXtoCallDblClick(Sender: TObject);
    procedure LogQSOClick(Sender: TObject);
    procedure Memo2DblClick(Sender: TObject);
    procedure edTXMsgDblClick(Sender: TObject);
    procedure ListBox1DrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
    procedure mgenClick(Sender: TObject);
    procedure rbOnChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure ListBox2DblClick(Sender: TObject);
    procedure rbTXEvenChange(Sender: TObject);
    procedure rigControlSet(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure tbMultiBinChange(Sender: TObject);
    procedure tbSingleBinChange(Sender: TObject);
    procedure WaterFallMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

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
    function  messageParser(const ex : String; var nc1t : String; var pfx : String; var sfx : String; var nc2t : String; var ng : String; var sh : String; var proto : String) : Boolean;

    procedure v1DecomposeDecode(const exchange    : String;
                                const connectedTo : String;
                                  var isValid       : Boolean;
                                  var isBreakIn     : Boolean;
                                  var level         : Integer;
                                  var response      : String;
                                  var connectTo     : String;
                                  var fullCall      : String;
                                  var hisGrid       : String);

    procedure displayDecodes3;
    procedure specHeader;

    function  db(x : CTypes.cfloat) : CTypes.cfloat;
    procedure toggleTXClick(Sender: TObject);
    function  txControl : Boolean;
    function  utcTime: TSystemTime;
//    procedure InitBar;

    procedure genTX(const msg : String; const txdf : Integer);
    function  rebelTuning(const f : Double) : CTypes.cuint;

    //procedure removeDupes(var list : TStringList; var removes : Array of Integer);

    procedure OncePerRuntime;
    procedure OncePerTick;
    procedure OncePerSecond;
    procedure OncePerMinute;
    procedure periodicSpecial;
    procedure adcdacTick;

    function  asBand(const qrg : Integer) : Integer;

    procedure updateDB;
    procedure setDefaults;
    procedure setupDB(const cfgPath : String);
    procedure mgen(const msg : String; var isValid : Boolean; var isBreakIn : Boolean; var level : Integer; var response : String; var connectTo : String; var fullCall : String; var hisGrid : String; var sdf : String; var sdB : String; var txp : Integer);

    function t(const s : String) : String;
    function valV1Prefix(const s : string) : Boolean;
    function valV1Suffix(const s : string) : Boolean;
    function isV1Call(const s : String) : Boolean;
    function lateTXOffset : Integer;
    function isSlashedCall(const s : String) : Boolean;
    function genSigRep(var s : String) : Boolean;

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

var
  Form1          : TForm1;
  clRebel        : rebel.TRebel;  // Class holder for Rebel
  rb             : spot.TSpot;    // Class holder for RB spotting
  mval           : valobject.TValidator;  // Class holder for validation
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
  thisADCTick    : CTypes.cuint;
  lastADCTick    : CTypes.cuint;
  paInParams     : TPaStreamParameters;
//  paOutParams    : TPaStreamParameters;
  ppaInParams    : PPaStreamParameters;
//  ppaOutParams   : PPaStreamParameters;
  paInStream     : PPaStream;
  paInStream2    : PPaStream;
  inDev          : Integer;//,outDev   : Integer;
  inIcal,pttDev  : Integer;
  auLevel        : Integer;
  auLevel1       : Integer;
  auLevel2       : Integer;
  rbping         : Boolean;
  rbposted       : CTypes.cuint64;
  runDecode      : Boolean;
  decodeping     : CTypes.cuint64;
  decoderBusy    : Boolean;
  rbThread       : rbcThread;
  decoderThread  : decodeThread;
  srun,lrun      : Double;
  defI           : Integer;//,defO      : Integer;
  qrgValid       : Boolean;
  catmethod      : String;
  catQRG         : Integer;
  dChar,kChar    : Char;
  kvcount        : CTypes.cuint64;
  bmcount        : CTypes.cuint64;
  shcount        : CTypes.cuint64;
  pfails         : CTypes.cuint64;
  avgdt          : Double;
  inQSOWith      : String;
  stime,etime    : String;
  setQRG,readQRG : Boolean;
  sopQRG,eopQRG  : Integer;
  qsyQRG         : Integer;
  readPTT,setPTT : Boolean;
  pttState       : Boolean;
  savedTADC      : String;
  savedIADC      : Integer;
  txperiod       : Integer; // 1 = Odd 0 = Even
  canTX          : Boolean; // Only true if callsign and grid is ok
  txDirty        : Boolean; // TX Message content has not been queued since generation if true
  txValid        : Boolean; // TX Message is generated and valid or not
  couldTX        : Boolean; // If one could TX this period (it matches even/odd selection)
  txrequested    : Boolean; // Is a request to TX in place?
  haveRebel      : Boolean; // Rebel selected and active/present?
  tmpdir         : String; // Path to user's temporary files directory
  homedir        : String; // Path to user's home directory
  qrgset         : Array[0..127] Of String; // Holds QRG values for Rebel TX load
  didTX          : Boolean; // Flag to indicate we did a TX this period so no decoder run
  lastTXDF       : String;  // Used to indicate marker above spectrum needs to change
  txInProgress   : Boolean; // tx in progress
  thisTXcall     : String;  // Station callsign (full with prefix or suffix if needed)
  thisTXgrid     : String;  // Station grid
  thisTXmsg      : String;  // Messages to TX
  lastTXmsg      : String;  // Last TX message (for watchdog)
  sameTXCount    : Integer; // Count same message sent (for watchdog)
  thisTXdf       : Integer; // DF for current TX message
  transmitting   : String;  // Holds message currently being transmitted
  transmitted    : String;  // Last message transmitted (used to compare to above for same TX message count)
  multion        : Boolean; // If multiple decode is on/off
  rxdf,txdf      : CTypes.cint; // Keeps current tx/rx dfs
  dtrejects      : Integer;
  mycall,myscall : String;  // Keeps this stations call and slashed call in order (Same if not a slashed call)
  kvdatdel       : Integer; // Tracing how many calls it takes to delete a stuck KV
  jtencode       : PChar; // To avoid heap error making this global
  jtdecode       : PChar; // To avoid heap error making this global
  //tx73,txFree    : Boolean; // Flags to determine if last message was a 73 or Free Text for CWID purposes
  //doCWID         : Boolean; // Set to fire CW ID TX
  mgendf         : String; // TX DF Message was last generated at
  qsycount       : Integer; // Used to delay message regen as a new TX DF is manually entered.
  instance       : Integer; // Allows multiple copies (eventually) to run = 1..4
  psAcc          : Array[0..1023] Of CTypes.cfloat;
  psTick         : Integer = 1;
  timeString     : String;  // Format of time, date, decimal character and thousands sep
  dateString     : String;  // Set using system functions to get localized settings.
  deciString     : String;
  kiloString     : String;
  plotCount      : CTypes.cint;
  headerRes      : CTypes.cint = 0; // Keeps track of resolution for spectrum header display
  lastTXDFMark   : CTypes.cint = -9000; // Keeps track of last painting for TX Marker
  lastRXDFMark   : CTypes.cint = -9000;
  periodDecodes  : Integer;
  b20,b50        : Graphics.TBitMap; // Waterfall headers for 20,50,100 and 200 hz bin spacing
  b100,b200      : Graphics.TBitMap;

implementation

procedure rscode(Psyms : CTypes.pcint; Ptsyms : CTypes.pcint); cdecl; external JT_DLL name 'rs_encode_';
procedure interleave(Ptsyms : CTypes.pcint; Pdirection : CTypes.pcint); cdecl; external JT_DLL name 'interleave63_';
procedure graycode(Ptsyms : CTypes.pcint; Pcount : CTypes.pcint; Pdirection : CTypes.pcint); cdecl; external JT_DLL name 'graycode_';
procedure set65; cdecl; external JT_DLL name 'setup65_';
procedure packgrid(saveGrid : PChar; ng : CTypes.pcint; text : CTypes.pcbool); cdecl; external JT_DLL name 'packgrid_';
procedure packmsg(msg : Pointer; syms : Pointer); cdecl; external JT_DLL name 'packmsg_';
procedure gen4fsk(mi, mo, mode, fsk, sym, dat, dgn : Pointer); cdecl; external JT_DLL name 'gen4jl_';
procedure jtEntail4(a,b : Pointer); cdecl; external JT_DLL name 'entail_';
procedure genjt9(msg,ichk,decoded,i4tone,itext : Pointer); cdecl; external JT9_DLL name 'genjt9_';

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
     OncePerTick; // Code that executes every ~100 mS.
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
   l,fbl     : String;
   deci      : PChar;
Begin
     // This runs on first timer interrupt once per run session
     timer1.Enabled:=False;
     // Read in spectrum headers
     b20 := Graphics.TBitmap.Create;
     b20.Height := 12;
     b20.Width  := 748;
     b20.LoadFromFile('header20.bmp');
     b50 := Graphics.TBitmap.Create;
     b50.Height := 12;
     b50.Width  := 748;
     b50.LoadFromFile('header50.bmp');
     b100 := Graphics.TBitmap.Create;
     b100.Height := 12;
     b100.Width  := 748;
     b100.LoadFromFile('header100.bmp');
     b200 := Graphics.TBitmap.Create;
     b200.Height := 12;
     b200.Width  := 748;
     b200.LoadFromFile('header200.bmp');
     // Getting locale settings
     l := '';
     fbl := '';
     GetLanguageIDs(l, fbl);
     deci := StrAlloc(255);
     GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SSHORTDATE,deci,255);
     dateString := TrimLeft(TrimRight(StrPas(deci)));
     GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_STIMEFORMAT,deci,255);
     timeString := TrimLeft(TrimRight(StrPas(deci)));
     GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SDECIMAL,deci,255);
     deciString := TrimLeft(TrimRight(StrPas(deci)));
     GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_STHOUSAND,deci,255);
     kiloString := TrimLeft(TrimRight(StrPas(deci)));
     // Trying to fix an ANNOYING corruption to my GUI layout
     TabSheet1.PageIndex := 0;
     TabSheet6.PageIndex := 1;
     TabSheet2.PageIndex := 2;
     TabSheet3.PageIndex := 3;
     TabSheet7.PageIndex := 4;
     TabSheet4.PageIndex := 5;
     TabSheet5.PageIndex := 6;
     TabSheet8.PageIndex := 7;
     TabSheet9.PageIndex := 8;
     PageControl.PageIndex := 0;

     // Below is a hack until I sort out another issue.
     LazarusResources.Add('decode','PNG',[
       #137'PNG'#13#10#26#10#0#0#0#13'IHDR'#0#0#0#25#0#0#0#216#8#6#0#0#0#30']Hr'#0#0
       +#0#6'bKGD'#0#255#0#255#0#255#160#189#167#147#0#0#0#9'pHYs'#0#0#11#19#0#0#11
       +#19#1#0#154#156#24#0#0#0#7'tIME'#7#221#11#11#5'/('#227#199'A='#0#0#0#29'iTXt'
       +'Comment'#0#0#0#0#0'Created with GIMPd.e'#7#0#0#2'HIDATx'#218#237#154'=kTA'
       +#20#134#31#151#221#136#185#1#195#134#248#129'E,'#221'Z'#11#27#139#128'Hj'#27
       +'m4XD'#177#209#127#224#215#143#208'?'#162#136#133#160#133#160#16#191'6~@'#4
       +#197'M'#163#16#5'%Z'#184'E,'#238#187#184'\d'#220#189'3'#19#21#222#7#134#129
       +'='#195'y'#185';'#231#156#189'{f'#192#24'c'#140'1'#198#24'c'#140'1'#198#24'c'
       +'L<'#155#149#177#1#244#128#155#192'y`*'#135'Hu'#188#7#14#166#18#25#176#29#216
       +#15','#2#175'e'#251#8#204#164#20#25#166#0#158#203'~9'#151#8#192'q'#217#31#230
       +#20#153#149#253'sN'#145#166#236#253#144#147'Fd`'#180'5'#127#205')rD'#243'j'
       +#206#232#234#202'~)'#165#200#4'0'#7#156#206#145''''#161#140'?'#148#186#172'|'
       +#7#214#128'[)k'#151'1'#6#182#141#152#144'Q>'#26'['#241'$'#205#196'O'#253#247
       +#158#164#225#141#247#198';'#186#254#141#232'2'#198#164#171#212#139#192'm'#224
       +#3#240'C'#157#137#21#224#6'p8V`/'#240'h'#132#255')'#181'i'#1#203'r'#178#6#156
       +'S7'#162#5'L'#2#29'`'#9'x'#16'#'#178'$'#129'w'#192#174'\{qW"'#167'rn'#248#186
       +'Dv'#231#20#233'K'#164#25#235'('#244'{'#242'E'#243'LN'#145#174#230'c9'#191
       +#174#179#250#186#222'Rv'#131#178'0'#1'<'#145'PO'#162's'#202#147#29#192#129#20
       +'y'#2#176'o(!'#179'd'#252'p'#230#159#1#238#168#143#210#31#170']'#215'S'#212
       +'.c'#204'h'#236#4#174'P'#246#229'74'#186#192'5`:'#133'@'#135#178#153#25'jtvb'
       +#4'&)'#155#202#155#192'3`'#129#178#177'Y'#168#252'?'#149'mUkkqQN^'#241#251
       +#174#233#20#191'z'#195#23#234#138#220#151#131#19#129'5'''#181#230'^]'#145'Or'
       +#16'z'#29#218#163'5'#235'9_$ZD'#30'm'#12#142'+'#218#129'5'#237#202'K'#199#216
       +'"/4'#207#7#214#204'W'#214#214#142#174#151#10#219'*'#133'lQ'#209'U'#0'o'#228
       +#228#177'r'#163'PN'#28#213'g'#209'y2'#200#248'^ '#227'{'#177#25'?`'#26#184
       +#170'z'#245'Mc%e'#237'2'#198#252#25#223#145#136#18#169'Vi'#223#145#24'K'#196
       +'w$'#198#138'.'#223#145#8#138#248#142#132'1'#153#240'Q'#249'X'#248#20#219#27
       +#255#159'o'#188#163#203#24'c'#140'1'#198#24'c'#140'1'#198'l'#17'?'#1'Y'#211
       +#251#161#157#127'o'#213#0#0#0#0'IEND'#174'B`'#130
     ]);
     LazarusResources.Add('receive','PNG',[
       #137'PNG'#13#10#26#10#0#0#0#13'IHDR'#0#0#0#25#0#0#0#216#8#6#0#0#0#30']Hr'#0#0
       +#0#6'bKGD'#0#255#0#255#0#255#160#189#167#147#0#0#0#9'pHYs'#0#0#11#19#0#0#11
       +#19#1#0#154#156#24#0#0#0#7'tIME'#7#221#11#11#5'0'#13'e'#153#155#228#0#0#0#29
       +'iTXtComment'#0#0#0#0#0'Created with GIMPd.e'#7#0#0#2'IIDATx'#218#237#154'=k'
       +#20'Q'#20#134#159']'#18'E'#11'S'#4#141#241#3'-'#181#181#146'T'#138'ba'#159
       +#194'B'#140'H4'#254#0#127#134#173#22'jc!'#18#196'6ZX*'#241#19'Qb'#163'Q'#208
       +'F'#193#194'h"'#137#31#172#197#190#131#195#176'$'#187's'#239'Y"'#190#15',s9'
       +#247'r'#223#157'9'#247#156#229#156'Y0'#198#24'c'#140'1'#198#24#211#127'Z'#149
       +#207'"0'#11#156#136#20')'#127'N'#230#22')'#24#5#174#203#246'<J'#4'`'#171'l'
       +#203#221'l'#208'L'#252#2#139'Q"'#219#129#139#26#223#141'v'#252#3'`['#164#200
       +'7'#224'x'#196#17#6#216#168#248'X'#6'V'#128#3#145#167#235#130'l'#179'@#Jd'#16
       +'x%'#251#185'('#17#128#163#178#127'Q'#128#134#136#0#220#210#220'm'#167'xc'
       +#210'h'#244#16#144#181#247'i'#246#227'N'#6#130#238#188#255'w'#210#180#227#237
       +'x'#159#174#245'q'#186#140'1y'#179#245')`'#6#248#8#252'P'#229#251#18#184#12
       +#28'L'#21#24#5#30#174#209#153'h'#165#8#12#2'O'#180#201#7'UU{e'#223#12#236#7
       +'&'#129#251')"'#147#18'x'#151#179#156#174'r'#143#204#141#154'N|'#150#200'H'
       +#164#200'O'#137#12#164'l'#178#214#239#201#130#174#195#145'"/t='#22#249#184
       +#206#234'q'#189#165#221#227#10'a'#3#240'LB'#239'%'#186'Gq'#178#9#216#151'#N'
       +#0'v'#150#2'2$'#226#203#145#127#154'v'#19#237#147'N]'#145#187'.'#229#200']'
       +#198#184'#'#225#194#212'5'#163#29#239#142#132'O'#151'1'#166#143#244'\*8'#11
       +'['#196'"'#22#249#23'E'#140'1'#233#20'M'#206#241'U'#214#140'k'#205#211#186'"'
       +#231#181#193#204'*k'#238'h'#205'T]'#145'!`'#9#248#13#236#234'0'#191'[sK'#192
       +#150#186#185'k'#1#152#214#186#137#14#243#19#154#155#6#190#166#248'eL'#143#227
       +'M'#165'lk'#0#243#154#27#203'q'#0#230#180#217#161#146#237#176'ls'#185'R'#253
       +#21']'#207#148'l'#197#248'j'#174#163'<L'#251#191#143#223#229#224'!'#141'WH|'
       +#237'Q'#229#6#127#255#146'8'#165#241#205#220#129'Y'#248#224#17#240'X'#227'#'
       +#17#141#133#215#165#210'a'#190#219'fC/'#191#241#173#138#147#175#145#233#149
       +'F'#149#17#218#175'd'#127#1';'#156#218#141#201#155'*'#186#141#246#218#251#184
       +#195#189#254'D'#236'x'#215#241'>]'#198#24'c'#140'1'#198#24'c'#140'1'#255'-'
       +#127#0#6'c'#169#225#243'2%U'#0#0#0#0'IEND'#174'B`'#130
     ]);
     LazarusResources.Add('transmit','PNG',[
       #137'PNG'#13#10#26#10#0#0#0#13'IHDR'#0#0#0#25#0#0#0#216#8#6#0#0#0#30']Hr'#0#0
       +#0#6'bKGD'#0#255#0#255#0#255#160#189#167#147#0#0#0#9'pHYs'#0#0#11#19#0#0#11
       +#19#1#0#154#156#24#0#0#0#7'tIME'#7#221#11#11#5'/:'#16'~0u'#0#0#0#29'iTXtComm'
       +'ent'#0#0#0#0#0'Created with GIMPd.e'#7#0#0#2#239'IDATx'#218#237#155'KHTQ'#24
       +#199#127'&bO!'#208'^`'#139'2z'#16#8'-'#2'i'#147#21'-'#218'D'#132'EDQdY'#238
       +'\'#180'lQ'#237#10#161']m'#10#155'UTD'#5#189'h'#211'S&'#16#10'z'#172#194#204
       +'U'#11#169'D'#135#180#176'i1'#223#208'a'#24'gt'#230'|'#131#212#255#7#151'9'
       +#243#157#227#253'q'#231#206#249#206#227#142' '#132#16'B'#8'!*AU'#129#186't'
       +#172's'#205#154#137'W'#158'.'#225#10'+s%'#146'H"'#201#12#145#8'!'#226#13#183
       +#217'c'#20'H'#2#251'<%'#225'q'#192'k'#226#176#20'HX'#236#141#231#236#164#193
       +'bc'#149'H'#144#163'^'#146'%@'#183#149#31'y'#223#248'^`'#145#167'd'#4#216#225
       +'5-'#173#181#254'1'#6#140#3#27'<'#191']''-'#150','#178'*(KR'#3'|'#176'x'#135
       +#231',~'#155#197#191'['#7'u[*'#220#180#186'[J'#241'BT'#150'Z`'#8#248#10#204
       +#246#146#236#15'2'#192'A/'#201#243'@'#242#210'C'#176'.H'#239#189'V^'#31'{'
       +#140#207#166#244'+'#192#197#156'X'#20#230#0#223#128#20'Pg7}'#200#210#252#220
       +'X'#146'C'#246#241'$'#130'X'#183#197#14#199#146'$'#237#132#155#131#216'*'#224
       +#183#213#149'Ms'#145#249'p'#218#218#148'u'#227';'#166#241#165'('#137#249#192
       +'00'#1'4'#230#169'o'#180#186'a`^'#169#146#163#246'q<('#208#230#161#181'i/U'
       +#210'g''h+'#208#166#205#218#244')'#181#11'Q'#153#29#137#243'%'#204#250#167'-'
       +#249#9#172#246#150#164'-O'#185'J'#238#219#235'NO'#201#26#224#23#208#159'3'
       +#177#139'*'#1#184'`'#229'S'#158#146#133'6KI'#1#203#189'$'#0#157#246#254#134
       +#167#164#26'xk'#177'-^'#18#128#173#22'{'#239')'#1#184#157#211#135'\$M'#182
       +#137#227'*'#1'8'#23'K"'#132#152#26#27#129';'#192#160#245#242#1#160#7#216#20
       +'K'#176#203#22':'#147'-'#229#162#240'.'#152'D4'#219#208#219#0#236#1#158#196
       +#146#140#153'dq9'')'#182'0'#237#183#215'c@'#189#215'M'#223#155's'#15'>'#2#215
       +'l'#199#168'&'#166#168#21#184'K'#230#161'L(|'#237'qu'#213#182'['#212#9'|2'
       +#209'%'#207#190#179#214'$'#131#158#146'e&'#25#143'q'#178'W'#192#9#155#166#214
       +#218'.E'#11#240'4'#152#177'D['#159#228';&'#128#221'S'#189#153#133#184#7#252
       +' '#179'yVg'#177'/'#192'c'#224'8'#17#159#208#9'!'#166#214#219#143#228#169#223
       +#30'c'#188#15#127'|'#241',O'#253#245#156'1'#166',I'#130#204'n'#246#138#160
       +#174#222'2'#240#213'X'#146#236#2#244'tP'#215'e'#177#214'X'#146'*'#224#179#141
       +#134'U'#193'Ti'#192#222'G'#145#0#156#229#239'C'#129#22'+'#159#137#177#150#15
       +#255#184#201#202'='#192'e+'#175#140'-'#1'xa'#223#166#17'2'#207#183#240#144
       +#180'O'#210'o'#162'J'#234'l'#243'&'#5','#240#146#148#220'N?'#182#20'B'#148
       +#159'j'#254#209#180'"'#137'$'#146#252'O'#18'!Dq'#244#239#159#202#194#146'H"'
       +#137#16'B'#8'!'#132#16'B'#204'p'#254#0#6#228'='#140')'#196'4'#153#0#0#0#0'IE'
       +'ND'#174'B`'#130
     ]);

     for i := 0 to 100 do d65.glDecTrace[i].trDIS := True;

     plotcount := 0;
     dtrejects := 0;
     d65.glDecCount := 0;
     kvdatdel := 0;
     headerRes := 0;
     lastTXDFMark := -9000;
     lastRXDFMark := -9000;
     //tx73   := False;
     //txFree := False;
     //doCWID := False;
     mgendf := '0';
     qsycount := 0;

     // Mark TX content as clean so any changes will lead to update
     txDirty := False;
     txValid := False;
     didTX := False;

     // Let adc know it is on first run so it can do its init
     adc.adcFirst := True;

     // Setup rebel object and the serial port support so we use this rebel or not.
     clRebel := rebel.TRebel.create;

     // Setup serial port list
     comboTTYPorts.Clear;
     comboTTYPorts.Items := clRebel.ports;
     comboTTYPorts.Items.Insert(0,'None');

     // Begin overly protective clearing the Rebel FSK values holder :)
     for i := 0 to 127 do qrgset[i] := '0';

     // Check instance is 1..4
     if (instance<1) or (instance>4) Then
     Begin
          showmessage('Invalid instance number (' + IntToStr(instance) + ')' + sLineBreak + 'Program must halt.');
          halt;
     end;

     // Setup configuration and data directories
     homedir := getUserDir;
     if not (homeDir[length(homedir)] = pathDelim) Then homeDir := homeDir + PathDelim;

     if not DirectoryExists(homedir + 'hfwst') Then
     Begin
          if not createDir(homedir + 'hfwst') Then
          Begin
               showmessage('Could not create data directory' + sLineBreak + 'Program must halt.');
               halt;
          end;
     end;

     // Breaking this down to allow more than one instance
     if not DirectoryExists(homedir + 'hfwst' + PathDelim + 'I1') Then
     Begin
          if not createDir(homedir + 'hfwst' + PathDelim + 'I1') Then
          Begin
               showmessage('Could not create Instance 1 data directory' + sLineBreak + 'Program must halt.');
               halt;
          end;
     end;
     if not DirectoryExists(homedir + 'hfwst' + PathDelim + 'I2') Then
     Begin
          if not createDir(homedir + 'hfwst' + PathDelim + 'I2') Then
          Begin
               showmessage('Could not create Instance 2 data directory' + sLineBreak + 'Program must halt.');
               halt;
          end;
     end;
     if not DirectoryExists(homedir + 'hfwst' + PathDelim + 'I3') Then
     Begin
          if not createDir(homedir + 'hfwst' + PathDelim + 'I3') Then
          Begin
               showmessage('Could not create Instance 3 data directory' + sLineBreak + 'Program must halt.');
               halt;
          end;
     end;
     if not DirectoryExists(homedir + 'hfwst' + PathDelim + 'I4') Then
     Begin
          if not createDir(homedir + 'hfwst' + PathDelim + 'I4') Then
          Begin
               showmessage('Could not create Instance 4 data directory' + sLineBreak + 'Program must halt.');
               halt;
          end;
     end;

     homedir := homedir + 'hfwst' + PathDelim + 'I' + intToStr(instance) + pathDelim;
     homedir := TrimFilename(homedir);

     foo := homedir;

     if not FileExists(homedir + 'kvasd.exe') Then
     Begin
          if not FileUtil.CopyFile('kvasd.exe',homedir + 'kvasd.exe') Then showmessage('Need kvasd.exe in data directory.') else showmessage('kvasd.exe copied to its processing location');
     end;
     if FileExists(homedir + 'KVASD.DAT') Then
     Begin
          // kill kill kill kill and kill it again
          try
             FileUtil.DeleteFileUTF8(homedir + 'KVASD.DAT');
          except
             ShowMessage('Debug - could not remove orphaned kvasd.dat' + sLineBreak + 'Please notify W6CQZ');
          end;
     end;

     basedir := GetAppConfigDir(false);
     basedir := TrimFilename(basedir);
     foo := basedir;

     if not DirectoryExists(basedir) Then
     Begin
          if not createDir(basedir) Then
          begin
               ShowMessage('Could not create base configuration directory' + sLineBreak + 'Program must halt.');
               halt;
          end;
     end;

     if basedir[Length(basedir)] = PathDelim Then
     Begin
          cfgpath := basedir + 'I' + IntToStr(instance) + PathDelim;
     end
     else
     begin
          cfgpath := basedir + PathDelim + cfgpath + 'I' + IntToStr(instance) + PathDelim;
     end;

     cfgpath := TrimFilename(cfgpath);

     // Check that path length won't be a problem.  It needs to be < 256 charcters in length with either kvasd.dat or wisdom3.dat appended
     // So actual length + 11 < 256 is OK.
     if Length(cfgpath)+11 > 255 then
     begin
          ShowMessage('Path length too long [ ' + IntToStr(Length(cfgpath)+11) + ' ]' + 'Program must halt.');
          halt;
     end;

     if not DirectoryExists(cfgpath) Then
     Begin
          if not createDir(cfgpath) Then
          begin
               ShowMessage('Could not create instance configuration directory (' + IntToStr(instance) + ')' + sLineBreak + 'Program must halt.');
               halt;
          end;
     end;

     // Create sqlite3 store, if necessary

     foo := cfgpath;

     // Changing this as of 12.08.2013 to force an update to DB
     if not fileExists(cfgPath + 'hfwstJ' + IntToStr(instance)) Then
     Begin
          setupDB(cfgPath);
     end;

     // Housekeeping items here
     d65.glnd65firstrun := True;
     d65.dmtmpdir := homedir;
     foo := d65.dmtmpdir;
     d65.dmwispath := TrimFilename(cfgPath+'wisdom3.dat');
     foo := d65.dmwispath;
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]); // This is a big one - must be set or BAD BAD things happen.

     // Query db for configuration with instance id = 1 and if it exists
     // read config, if not set to defaults and prompt for config update
     sqlite3.DatabaseName := cfgPath + 'hfwstJ' + IntToStr(instance);
     query.Active := False;
     query.SQL.Clear;
     query.SQL.Add('SELECT * FROM config WHERE instance = ' + IntToStr(instance) + ';'); // This uses the 1..4 instance!
     query.Active := True;
     if query.RecordCount = 0 then
     begin
          // Instance 1 not in place - fix that.
          query.Active := False;
          query.SQL.Clear;
          query.SQL.Add('INSERT INTO config(needcfg) VALUES(' + IntToStr(instance) + ');');
          query.ExecSQL;
          transaction.Commit;
     end;
     query.Active := False;
     query.SQL.Clear;
     query.SQL.Add('SELECT needcfg FROM config WHERE instance = ' + IntToStr(instance) + ';');
     query.Active := True;
     if query.RecordCount = 0 then
     begin
          ShowMessage('Error - no instance data (' + IntToStr(instance) + '. This is a fatal error please notify Joe w6cqz@w6cqz.org');
          halt;
     end
     else
     begin
          if query.Fields[0].AsBoolean then
          Begin
               ShowMessage('Please setup your station information.');
               mustcfg := True;
          end
          else
          begin
               mustcfg := False;
          end;
     end;

     if mustcfg Then setDefaults;
     // Read the data from config
     query.Active := False;
     query.SQL.Clear;
     query.SQL.Add('SELECT * FROM config WHERE instance=' + IntToStr(instance) + ';');
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
     foo := query.FieldByName('lastqrg').AsString;
     lastQRG.Text := foo;
     tbSingleBin.Position := query.FieldByName('sbinspace').AsInteger;
     tbMultiBin.Position := query.FieldByName('mbinspace').AsInteger;
     //tbTXLevel.Position := query.FieldByName('txlevel').AsInteger;
     version.Text := query.FieldByName('version').AsString;
     cbMultiOn.Checked := query.FieldByName('multion').AsBoolean;
     cbTXEqRXDF.Checked := query.FieldByName('txeqrxdf').AsBoolean;
     edRebRXOffset.Text := query.FieldByName('rebrxoffset').AsString;
     edRebTXOffset.Text := query.FieldByName('rebtxoffset').AsString;
     edRebRXOffset40.Text := query.FieldByName('rebrxoffset40').AsString;
     edRebTXOffset40.Text := query.FieldByName('rebtxoffset40').AsString;
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
     // Populate Macro list
     comboMacroList.Clear;
     query.SQL.Clear;
     query.SQL.Add('SELECT text FROM macro WHERE instance = ' + IntToStr(instance) + ';');
     query.Active := True;
     comboMacroList.Items.Add('');
     if query.RecordCount > 0 Then
     Begin
          query.First;
          for i := 0 to query.RecordCount-1 do
          begin
               comboMacroList.Items.Add(query.Fields[0].AsString);
               query.Next;
          end;
     end;
     comboMacroList.ItemIndex := 0;
     query.Active := False;
     { TODO : Dump this at V1.0 - just want to rid DB of the 3 shorthand strings without forcing a clean start }
     for i := 0 to comboMacroList.Items.Count-1 do
     begin
          if comboMacroList.Items.Strings[i] = 'RRR' Then
          Begin
               transaction.EndTransaction;
               transaction.StartTransaction;
               query.SQL.Clear;
               query.SQL.Text := 'DELETE FROM macro where instance=:INSTANCE And text=:TEXT;';
               // Defining the 3 shorthand types.
               query.Params.ParamByName('INSTANCE').AsInteger := instance;
               query.Params.ParamByName('TEXT').AsString := 'RRR';
               query.ExecSQL;
               transaction.Commit;
               transaction.EndTransaction;
               query.Active:=False;
               query.SQL.Clear;
          end;
          if comboMacroList.Items.Strings[i] = '73' Then
          Begin
               transaction.EndTransaction;
               transaction.StartTransaction;
               query.SQL.Clear;
               query.SQL.Text := 'DELETE FROM macro where instance=:INSTANCE And text=:TEXT;';
               // Defining the 3 shorthand types.
               query.Params.ParamByName('INSTANCE').AsInteger := instance;
               query.Params.ParamByName('TEXT').AsString := '73';
               query.ExecSQL;
               transaction.Commit;
               transaction.EndTransaction;
               query.Active:=False;
               query.SQL.Clear;
          end;
          if comboMacroList.Items.Strings[i] = 'RO' Then
          Begin
               transaction.EndTransaction;
               transaction.StartTransaction;
               query.SQL.Clear;
               query.SQL.Text := 'DELETE FROM macro where instance=:INSTANCE And text=:TEXT;';
               // Defining the 3 shorthand types.
               query.Params.ParamByName('INSTANCE').AsInteger := instance;
               query.Params.ParamByName('TEXT').AsString := 'RO';
               query.ExecSQL;
               transaction.Commit;
               transaction.EndTransaction;
               query.Active:=False;
               query.SQL.Clear;
          end;
     end;
     // Populate Macro list
     comboMacroList.Clear;
     query.SQL.Clear;
     query.SQL.Add('SELECT text FROM macro WHERE instance = ' + IntToStr(instance) + ';');
     query.Active := True;
     comboMacroList.Items.Add('');
     if query.RecordCount > 0 Then
     Begin
          query.First;
          for i := 0 to query.RecordCount-1 do
          begin
               comboMacroList.Items.Add(query.Fields[0].AsString);
               query.Next;
          end;
     end;
     comboMacroList.ItemIndex := 0;
     query.Active := False;
     // Lets read some config
     lastTXDF := '';
     inDev  := savedIADC;
     pttDev := -1;
     If not TryStrToInt(edPort.Text,pttDev) Then pttDev := -1;

     if cbNoOptFFT.Checked Then
     Begin
          inIcal := 0;
     end
     else
     begin
          if not fileExists(cfgPath + 'wisdom3.dat') Then
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
     //If TryStrToInt(TXLevel.Text,i) Then tbTXLevel.Position := i else tbTXLevel.Position := 16;
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
          dChar := deciString[1];
          kChar := kiloString[1];
          if dChar = '.' Then useDeciAuto.Caption := 'Use System Default (decimal = . thousands = ,)';
          if dChar = ',' Then useDeciAuto.Caption := 'Use System Default (decimal = , thousands = .)';
     end;
     // Intitialize to startup points
     kvcount   := 0;
     bmcount   := 0;
     shcount   := 0;
     pfails    := 0;
     avgdt     := 0.0;
     sopQRG    := 0;
     eopQRG    := 0;
     inQSOWith := '';
     readQRG   := False;
     readPTT   := False;
     setPTT    := False;
     pttState  := False;
     d65.dmruntime    := 0.0;
     d65.glbinspace := 100;
     d65.glDFTolerance := 100;
     If tbMultiBin.Position = 1 then d65.glbinspace := 20;
     If tbMultiBin.Position = 2 then d65.glbinspace := 50;
     If tbMultiBin.Position = 3 then d65.glbinspace := 100;
     If tbMultiBin.Position = 4 then d65.glbinspace := 200;
     Label26.Caption := 'Multi ' + IntToStr(d65.glbinspace) + ' Hz';
     If tbSingleBin.Position = 1 then d65.glDFTolerance := 20;
     If tbSingleBin.Position = 2 then d65.glDFTolerance := 50;
     If tbSingleBin.Position = 3 then d65.glDFTolerance := 100;
     If tbSingleBin.Position = 4 then d65.glDFTolerance := 200;
     Label87.Caption := 'Single ' + IntToStr(d65.glDFTolerance) + ' Hz';
     if inIcal >-1 then d65.glfftFWisdom := inIcal else d65.glfftFWisdom := 0;
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
     txOn := False;
     ListBox1.Clear;
     ListBox2.Clear;
     // Create and initialize TWaterfallControl
     Waterfall := TWaterfallControl1.Create(self);
     Waterfall.Height := 180;
     //Waterfall.Width  := 747;
     Waterfall.Width  := 748;
     Waterfall.Top    := 47;
     Waterfall.Left   := 152;
     Waterfall.Parent := Self;
     Waterfall.OnMouseDown := waterfallMouseDown;
     Waterfall.DoubleBuffered := True;

     If mustcfg Then
     Begin
          Waterfall.Visible := False;
          PaintBox1.Visible  := False;
     end;

     // Setup RB (thread)
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
               if tryStrToInt(edDialQRG.Text,i) Then
               Begin
                    if mval.evalIQRG(i,'lax',foo) Then
                    Begin
                         rb.myQRG  := i;
                         sopQRG    := i;
                         rb.useRB := True;
                         rb.useDBF := False;
                         rbping    := True;
                    end
                    else
                    begin
                         rb.myQRG  := 0;
                         sopQRG    := 0;
                         rb.useRB := False;
                         rb.useDBF := False;
                         rbping    := False;
                    end;
               end
               else
               begin
                    rb.myQRG  := 0;
                    sopQRG    := 0;
                    rb.useRB := False;
                    rb.useDBF := False;
                    rbping    := False;
               end;
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
               if tryStrToInt(edDialQRG.Text,i) Then
               Begin
                    if mval.evalIQRG(i,'lax',foo) Then
                    Begin
                         rb.myQRG  := i;
                         sopQRG    := i;
                         rb.useRB := False;
                         rb.useDBF := False;
                         rbping    := False;
                    end
                    else
                    begin
                         rb.myQRG  := 0;
                         sopQRG    := 0;
                         rb.useRB := False;
                         rb.useDBF := False;
                         rbping    := False;
                    end;
               end
               else
               begin
                    rb.myQRG  := 0;
                    sopQRG    := 0;
                    rb.useRB := False;
                    rb.useDBF := False;
                    rbping    := False;
               end;
          end
          else
          begin
               rb.useRB := False;
               rbping := False;
          end;
     end;
     // Setup Decoder (thread)
     runDecode      := False;
     decoderThread := decodeThread.Create(False);
     if not paActive Then
     Begin
          // Fire up portaudio using default in/out devices.
          // But first clear the i/o buffers in adc/dac
          ListBox2.Items.Add('Setting up PortAudio');
          for i := 0 to Length(adc.d65rxIBuffer)-1 do adc.d65rxIBuffer[i] := 0;

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

               // Initialize RX stream for 11025
               paResult := portaudio.Pa_OpenStream(PPaStream(paInStream),PPaStreamParameters(ppaInParams),PPaStreamParameters(Nil),CTypes.cdouble(11025.0),CTypes.culong(2048),TPaStreamFlags(0),PPaStreamCallback(@adc.adcCallback),Pointer(Self));
               if paResult <> 0 Then
               Begin
                    // Was unable to open RX.
                    ShowMessage('Unable to start PortAudio Input Stream.');
                    Halt;
               end;
               ListBox2.Items.Insert(0,'Opened input');

               // Initialize RX stream for 12000
               //paResult := portaudio.Pa_OpenStream(PPaStream(paInStream2),PPaStreamParameters(ppaInParams),PPaStreamParameters(Nil),CTypes.cdouble(12000.0),CTypes.culong(2048),TPaStreamFlags(0),PPaStreamCallback(@adc.adcCallback2),Pointer(Self));
               //if paResult <> 0 Then
               //Begin
                    // Was unable to open RX.
                    //ShowMessage('Unable to start secondary PortAudio Input Stream.');
                    //Halt;
               //end;
               //ListBox2.Items.Insert(0,'Opened secondary input');

               // Start the RX stream for 11025
               paResult := portaudio.Pa_StartStream(paInStream);
               if paResult <> 0 Then
               Begin
                    // Was unable to start RX stream.
                    ShowMessage('Unable to start PortAudio Input Stream.');
                    Halt;
               end;
               ListBox2.Items.Insert(0,'Started input');

               // Start the RX stream for 12000
               //paResult := portaudio.Pa_StartStream(paInStream2);
               //if paResult <> 0 Then
               //Begin
                    // Was unable to start RX stream.
                    //ShowMessage('Unable to start secondary PortAudio Input Stream.');
                    //Halt;
               //end;
               //ListBox2.Items.Insert(0,'Started secondary input');

               // Initialize tx stream.
               txInProgress := false;
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
     // For multiple instances I need to work out a lock mechanism such the multiple instances don't
     // attemp to attach to same Rebel.
     if rigRebel.Checked Then
     Begin
          // put class clRebel to work
          haveRebel := False;
          if rbRebBaud9600.Checked then clRebel.baud := 9600 else clRebel.baud := 115200;
          if length(edPort.Text)>0 Then
          Begin
               i := -2;
               if tryStrToInt(TrimLeft(TrimRight(edPort.Text)),i) Then
               Begin
                    if i>0 then
                    begin
                         clRebel.port := 'COM'+TrimLeft(TrimRight(edPort.Text));
                         ShowMessage('Connecting to Rebel on ' + clRebel.port + ' at ' + IntToStr(clRebel.baud) + ' baud' + sLineBreak + 'Please insure Rebel is connected and loaded with proper firmware.');
                         if clRebel.connect Then
                         Begin
                              // We're connected need to see if there's a Rebel on the other side
                              if clRebel.setup Then
                              Begin
                                   // Sure enough seem to have one
                                   haveRebel := True;
                                   ListBox2.Items.Insert(0,'Connected to Rebel');
                              end
                              else
                              begin
                                   haveRebel := False;
                                   rigNone.Checked := True;
                                   ShowMessage('Rebel did not respond at command port' + sLineBreak + 'Please check configuration.');
                              end;
                         end
                         else
                         begin
                              haveRebel := False;
                              rigNone.Checked := True;
                              ShowMessage('Could not open Rebel command port - please check configuration.');
                         end;
                    end
                    else
                    begin
                         haveRebel := False;
                         rigNone.Checked := True;
                         ShowMessage('Bad com port value - please check configuration.');
                    end;
               end;
          end
          else
          begin
               haveRebel := False;
               rigNone.Checked := True;
               ShowMessage('Bad com port value - please check configuration.');
          end;
     end;

     if rigRebel.Checked and haveRebel Then
     Begin
          // Need to read in Rebel's band selection so we know how to act here.
          if not clRebel.poll Then
          Begin
               ShowMessage('Unable to communicate with Rebel - will retry');
          end
          else
          begin
               ListBox2.Items.Insert(0,'Rebel firmare version = ' + clRebel.rebVer);
               ListBox2.Items.Insert(0,'Rebel DDS Type = ' + clRebel.ddsVer);
          end;
     end;

     // Populate QRG list but after Rebel handler in case I need to do things
     // here based on Rebel's settings.
     comboQRGList.Clear;
     query.Active := False;
     query.SQL.Clear;
     { TODO : Limit even more with Rebel based on band selected by jumpers }

     // Limit QRG list to 40/20M ranges for now if Rebel is on
     if not rigRebel.Checked Then query.SQL.Add('SELECT fqrg FROM qrg WHERE instance = ' + IntToStr(instance) + ' ORDER BY fqrg DESC;') else query.SQL.Add('SELECT fqrg FROM qrg WHERE instance = ' + IntToStr(instance) + ' AND fqrg > 6999999.9 AND fqrg < 14350000.1 ORDER BY fqrg DESC;');
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
               if rigRebel.Checked Then
               Begin
                    // This cuts out 30M entries for Rebel
                    if (mval.evalQRG(fs,'STRICT',ff,fi,fsc)) and ((fi < 10100000) or (fi > 10150000)) Then comboQRGList.Items.Add(fsc);
               end
               else
               begin
                    if (mval.evalQRG(fs,'STRICT',ff,fi,fsc)) Then comboQRGList.Items.Add(fsc);
               end;
               query.Next;
          end;
     end;
     query.Active := False;

     // Moved routines to deal with QRG down so I can know if this is a Rebel setup or not and react properly
     // Validate initial QRG
     //fs  := '';
     //ff  := 0.0;
     //fi  := 0;
     //fs  := edDialQRG.Text;
     //fsc := '';
     //mval.forceDecimalAmer := False;
     //mval.forceDecimalEuro := False;
     //if mval.evalQRG(fs,'STRICT',ff,fi,fsc) Then qrgValid := True else qrgValid := False;

     // Read in defaults if Rebel is on
     if haveRebel Then
     Begin
          //if clRebel.poll Then
          Begin
               //edDialQRG.Text := IntToStr(Round(clRebel.qrg));
               // Check to see if offset is different for RX/TX than defaults
               // hardwired in Rebel.  If so - update Rebel as we assume HFWST
               // has the correct values (maybe not the best assumption, but, safest
               // one).
               if clRebel.band = 20 Then
               Begin
                    if not tryStrToInt(edRebTXOffset.Text,i) Then edRebTXOffset.Text := '0';
                    if clRebel.txOffset <> StrToInt(edRebTXOffset.Text) Then
                    Begin
                         // fix it
                         if tryStrToInt(edRebTXOffset.Text,i) then clRebel.txOffset := i else clRebel.txOffset := 0;
                    end;
                    if not tryStrToInt(edRebRXOffset.Text,i) Then edRebRXOffset.Text := '0';
                    if clRebel.rxOffset <> StrToInt(edRebRXOffset.Text) Then
                    Begin
                         // fix it
                         if tryStrToInt(edRebRXOffset.Text,i) then clRebel.rxOffset := i else clRebel.rxOffset := 0;
                    end;
                    // push changes to Rebel
                    if not clRebel.setOffsets Then ShowMessage('Could not set offsets.' + sLineBreak + clRebel.lerror);
               end
               else if clRebel.band = 40 Then
               Begin
                    if not tryStrToInt(edRebTXOffset40.Text,i) Then edRebTXOffset40.Text := '0';
                    if clRebel.txOffset <> StrToInt(edRebTXOffset40.Text) Then
                    Begin
                         // fix it
                         if tryStrToInt(edRebTXOffset40.Text,i) then clRebel.txOffset := i else clRebel.txOffset := 0;
                    end;
                    if not tryStrToInt(edRebRXOffset40.Text,i) Then edRebRXOffset40.Text := '0';
                    if clRebel.rxOffset <> StrToInt(edRebRXOffset40.Text) Then
                    Begin
                         // fix it
                         if tryStrToInt(edRebRXOffset40.Text,i) then clRebel.rxOffset := i else clRebel.rxOffset := 0;
                    end;
                    // push changes to Rebel
                    if not clRebel.setOffsets Then ShowMessage('Could not set offsets.' + sLineBreak + clRebel.lerror);
               end;
          end;
          // Need to take into account Rebel may have had a band change since last run
          // so be sure band currently active fits last QRG setting.
          if not tryStrToInt(lastQRG.Text,fi) then lastQRG.Text := '0';
          if fi > 0 Then
          Begin
               edDialQRG.Text := lastQRG.Text;
               fs  := '';
               ff  := 0.0;
               fi  := 0;
               fs  := edDialQRG.Text;
               fsc := '';
               mval.forceDecimalAmer := False;
               mval.forceDecimalEuro := False;
               if mval.evalQRG(fs,'STRICT',ff,fi,fsc) Then qrgValid := True else qrgValid := False;
               if qrgValid Then
               Begin
                    // Set Rebel to last session QRG (maybe)
                    if clRebel.band = 20 Then
                    Begin
                         if (fi>=14000000) and (fi<=14350000) Then
                         Begin
                              edDialQRG.Text := lastQRG.Text;
                              if not tryStrToInt(edDialQRG.Text,i) Then edDialQRG.Text := '14076000';
                              qsyQRG := StrToInt(edDialQRG.Text);
                              setQRG := True;
                              editQRG.Text := fsc;
                         end
                         else
                         begin
                              edDialQRG.Text := '14076000';
                              qsyQRG := 14076000;
                              setQRG := True;
                              editQRG.Text := '14076';
                         end;
                    end
                    else if clRebel.band = 40 Then
                    Begin
                         if (fi>=7000000) and (fi<=7300000) Then
                         Begin
                              edDialQRG.Text := lastQRG.Text;
                              if not tryStrToInt(edDialQRG.Text,i) Then edDialQRG.Text := '7076000';
                              qsyQRG := StrToInt(edDialQRG.Text);
                              setQRG := True;
                              editQRG.Text := fsc;
                         end
                         else
                         begin
                              edDialQRG.Text := '7076000';
                              qsyQRG := 7076000;
                              setQRG := True;
                              editQRG.Text := '7076';
                         end;
                    end;
               end
               else
               begin
                    if clRebel.band = 20 Then
                    Begin
                         edDialQRG.Text := '14076000';
                         qsyQRG := 14076000;
                         setQRG := True;
                         editQRG.Text := '14076';
                    end
                    else if clRebel.band = 40 Then
                    begin
                         edDialQRG.Text := '7076000';
                         qsyQRG := 7076000;
                         setQRG := True;
                         editQRG.Text := '7076';
                    end;
               end;
          end;
     end
     else
     begin
          // No rebel so (for now) invalidate last QRG
          edDialQRG.Text := '';
          lastQRG.Text := '0';
     end;

     d65.glnz := cbNZLPF.Checked;
     spectrum.specWindow := cbSpecWindow.Checked;
     readQRG   := True;
     firstTick := False;
end;

procedure TForm1.OncePerTick;
Var
   i,fi,dti   : Integer;
   fs,fsc     : String;
   s1,s2,foo  : String;
   ff,dta,tot : Double;
   valid      : Boolean;
   c1,c2,c3   : Array[0..125] of String;
   adjtime    : Boolean;
Begin
     // Disable timer while here.  It should be disabled already, but this is
     // a double check for that.  :)
     timer1.Enabled:=False;

     // Runs on each timer tick
     thisUTC     := utcTime;
     thisSecond  := thisUTC.Second;
     thisADCTick := adc.adcTick;

     if cbNoKV.Checked Then d65.glUseKV := False else d65.glUseKV := True;
     if cbNoOptFFT.Checked Then d65.glUseWisdom := False else d65.glUseWisdom := True;

     // Check to see if message needs regen due to TxDF change since last
     if length(edTXMsg.Text)>0 Then
     Begin
          if mgendf <> edTXDF.Text then
          Begin
               inc(qsycount);
               i := qsycount;
          end;
          if qsycount > 6 Then
          Begin
               // Mark message needing regeneration
               if tryStrToInt(edTXDF.Text,i) Then genTX(edTXMsg.Text, i+clRebel.txOffset);
               qsycount := 0;
          end;
     end
     else
     begin
          qsycount := 0;
     end;

     // This is a high priortiy item.
     if not toggleTX.Checked Then
     Begin
          txInProgress := false;
          if clRebel.txStat and (not clRebel.busy) then clRebel.pttOff;
     end;
     // This is mainly for me.  :)
     If cbWFTX.Checked Then
     Begin
          Waterfall.Repaint;
     end
     else
     begin
          If not clRebel.txStat then Waterfall.repaint;
     end;

     If toggleTX.Checked then toggleTX.state := cbChecked else toggleTX.state := cbUnchecked;
     if not d65.glinprog and d65.gld65HaveDecodes Then DisplayDecodes3;
     if cbUseColor.Checked Then ListBox1.Style := lbOwnerDrawFixed else ListBox1.Style := lbStandard;
     multion := cbMultiOn.Checked;
     fs  := '';
     ff  := 0.0;
     fi  := 0;
     fs  := edDialQRG.Text;
     fsc := '';
     mval.forceDecimalAmer := False;
     mval.forceDecimalEuro := False;
     if mval.evalQRG(fs,'STRICT',ff,fi,fsc) Then qrgValid := True else qrgValid := False;
     if tryStrToInt(edRXDF.Text,i) Then rxdf := i else rxdf := 0;
     if tryStrToInt(edTXDF.Text,i) Then txdf := i else txdf := 0;

     Label121.Caption := 'Decoder Resolution:  ' + IntToStr(d65.glbinspace) + ' Hz';
     if d65.glRunCount < 2 Then
     Begin
          // Reject first decode cycle data.
          d65.glDecCount := 0;
          d65.glDTAvg := 0.0;
          dtrejects := 0;
          avgdt := 0.0;
          kvcount := 0;
          bmcount := 0;
     end;
     if kvcount > 0 Then Label95.Caption := PadLeft(IntToStr(kvcount),5) + '  ' + FormatFloat('0.0',(100.0*(kvcount/(kvcount+bmcount)))) + '%';
     if bmcount > 0 Then Label96.Caption := PadLeft(IntToStr(bmcount),5) + '  ' + FormatFloat('0.0',(100.0*(bmcount/(kvcount+bmcount)))) + '%';
     Label53.Caption := 'DT Samples = ' + IntToStr(d65.glDecCount);
     Label54.Caption := 'Rejected DT Samples = ' + IntToStr(dtrejects);
     Label98.Caption := PadLeft(FormatFloat('0.000',(d65.glDTAvg)),5);
     If AnsiContainsText(Label98.Caption,'nan') Then
     Begin
          // Average DT is evaluating as NaN
          // Reset all the counters.
          d65.glDecCount := 0;
          d65.glDTAvg := 0.0;
          dtrejects := 0;
          avgdt := 0.0;
          Label98.Caption := PadLeft(FormatFloat('0.000',(d65.glDTAvg)),5);
     end;
     adjtime := False;
     if (d65.glDecCount > 19) and ((d65.glDTAvg < -0.5) or (d65.glDTAvg > 0.5)) Then adjtime := True else adjtime := false;
     //if not adjtime and (d65.glDecCount > 99) Then adjtime := True;
     if not adjtime and (d65.glDecCount > 49) Then adjtime := True;
     if adjtime Then
     Begin
          // Lets see about moving the average DT error every 100 receptions
          // maybe a stupid idea, but, I wanna know.  :)
          // Samples fed to the decoder go in with an offset to start of data
          // with 4096 being default.  At 11025 samples per second this is
          // 1/11025 second per sample.  If I do (glDTAvg/(1/11025)) I get
          // an adjustment value needed to move it to zero DT average.
          dta := d65.glDTAvg/(1.0/11025.0);
          dti := round(dta);
          if (dti > 1) or (dti < -1) Then
          Begin
               dti := dti div 2; // This smoothes the changes a bit so it doesn't oscillate.
               d65.glSampOffset := d65.glSampOffset+dti;
               if d65.glSampOffset < 0 Then d65.glSampOffset := 0;
               if d65.glSampOffset > 8192 Then d65.glSampOffset := 8192;
               ListBox2.Items.Add('Changing decoder sample offset to ' + IntToStr(d65.glSampOffset));
          end;
          d65.glDecCount := 0;
          d65.glDTAvg := 0.0;
          dtrejects := 0;
          avgdt := 0.0;
     end;

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
     // This is *better* than converting to float and dividing.  :) This reads from the
     // internal edDialQRG field and sets the user visible elements.

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
          Label27.Caption := s2;
     end
     else
     begin
          Label27.Caption := edDialQRG.Text;
     end;

     spectrum.specColorMap := spColorMap.ItemIndex;

     If tbMultiBin.Position = 1 then d65.glbinspace := 20;
     If tbMultiBin.Position = 2 then d65.glbinspace := 50;
     If tbMultiBin.Position = 3 then d65.glbinspace := 100;
     If tbMultiBin.Position = 4 then d65.glbinspace := 200;

     If tbSingleBin.Position = 1 then d65.glDFTolerance := 20;
     If tbSingleBin.Position = 2 then d65.glDFTolerance := 50;
     If tbSingleBin.Position = 3 then d65.glDFTolerance := 100;
     If tbSingleBin.Position = 4 then d65.glDFTolerance := 200;

     spectrum.specSpeed2 := tbWFSpeed.Position;
     if cbSpecSmooth.Checked Then spectrum.specSmooth := True else spectrum.specSmooth := False;
     if cbSpecSmooth.Checked Then spectrum.specuseagc := True else spectrum.specuseagc := False;
     spectrum.specColorMap := spColorMap.ItemIndex;

     if rbUseLeftAudio.Checked Then adc.adcChan  := 1;
     if rbUseRightaudio.Checked Then adc.adcChan := 2;
     if cbUseMono.Checked Then adc.adcMono := True else adc.adcMono := False;

     // Compute actual full callsign to use from prefix+callsign+suffix

     // If Prefix and suffix defined (invalid) the prefix wins.
     If (Length(edPrefix.Text)>0) And (Length(edSuffix.Text)>0) Then edSuffix.Text := '';

     If (Length(edPrefix.Text)>0) And (Length(edSuffix.Text)=0) And ((Length(edCall.Text)>2) And (Length(edCall.Text)<7)) And ((Length(getLocalGrid)=4) Or (Length(getLocalGrid)=6)) Then
     Begin
          thisTXcall := TrimLeft(TrimRight(UpCase(edPrefix.Text))) + '/' + TrimLeft(Trimright(UpCase(edCall.Text)));
          thisTXgrid := TrimLeft(TrimRight(UpCase(getLocalGrid)));
          if Length(thisTXGrid)>4 Then thisTXGrid := thisTXGrid[1..4];
          Label8.Caption := thisTXCall + ' (' + edGrid.Text + ')';
     end;

     If (Length(edPrefix.Text)=0) And (Length(edSuffix.Text)>0) And ((Length(edCall.Text)>2) And (Length(edCall.Text)<7)) And ((Length(getLocalGrid)=4) Or (Length(getLocalGrid)=6)) Then
     Begin
          thisTXcall := TrimLeft(Trimright(UpCase(edCall.Text))) + '/' + TrimLeft(TrimRight(UpCase(edSuffix.Text)));
          thisTXgrid := TrimLeft(TrimRight(UpCase(getLocalGrid)));
          if Length(thisTXGrid)>4 Then thisTXGrid := thisTXGrid[1..4];
          Label8.Caption := thisTXCall + ' (' + edGrid.Text + ')';
     end;

     If (Length(edPrefix.Text)=0) And (Length(edSuffix.Text)=0) And ((Length(edCall.Text)>2) And (Length(edCall.Text)<7)) And ((Length(getLocalGrid)=4) Or (Length(getLocalGrid)=6)) Then
     Begin
          thisTXcall := TrimLeft(Trimright(UpCase(edCall.Text)));
          thisTXgrid := TrimLeft(TrimRight(UpCase(getLocalGrid)));
          if Length(thisTXGrid)>4 Then thisTXGrid := thisTXGrid[1..4];
          Label8.Caption := thisTXCall + ' (' + edGrid.Text + ')';
     end;

     // canTX is based upon having valid callsign and grid in config & valid message ready to send
     valid := True;
     // Check for prefix and suffix set (prefix wins)
     if (length(edPrefix.Text)>0) and (length(edSuffix.Text)>0) Then edSuffix.Text := '';
     // Validate prefix (if present)
     if length(edPrefix.Text)>0 Then if not isV1Call(edPrefix.Text + '/' + edCall.Text) Then valid := False;
     // Validate suffix (if present)
     if length(edSuffix.Text)>0 Then if not isV1Call(edCall.Text + '/' + edSuffix.Text) Then valid := False;
     // Validate callsign
     if not mval.evalCSign(edCall.Text) Then valid := False;
     // Validate grid
     if not mval.evalGrid(edGrid.Text) Then valid := False;
     if (not isSText(edTXMsg.Text)) or (not isFText(edTXMsg.Text)) Then valid := False;
     canTX := valid;

     // Changing this so it doesn't disable the control while TX is in progress.
     If canTX or clRebel.TXStat Then toggleTX.Enabled := True else toggleTX.Enabled := False;

     // Update TX control based upon current context
     If toggleTX.Checked Then
     Begin
          if clRebel.txStat Then toggleTX.Caption := 'HALT TX' else toggleTX.Caption := 'Disable TX';
     End
     else
     Begin
          toggleTX.Caption := 'Enable TX';
          txInProgress := false;
          if clRebel.txStat and (not clRebel.busy) then clRebel.pttOff;
     end;

     if not canTX Then
     Begin
          Label16.Caption := 'TX:  DISABLED';
          Label16.Font.Color := clBlack;
     end
     else
     begin
          If txInProgress Then
          Begin
               Label16.Caption := 'TX:  ' + transmitting;
               Label16.Hint:='';
               Label16.Font.Color := clRed;
          end
          else
          Begin
               If toggleTX.checked and canTX  Then
               Begin
                    Label16.Caption := 'TX:  ENABLED';
                    Label16.Hint:='';
                    Label16.Font.Color := clBlack;
               end
               else
               begin
                    Label16.Caption := 'TX:  OFF';
                    Label16.Hint:='';
                    Label16.Font.Color := clBlack;
               end;
          end;
     end;

     if canTX and txValid and txDirty Then
     Begin
          // A valid message is awaiting upload to Rebel
          // Load it into the class data buffer
          if (not clRebel.txStat) and (not clRebel.busy) Then
          Begin
               for i := 0 to 127 do clRebel.setData(i,StrToInt(qrgset[i]));
               if clRebel.ltx then txDirty := False else txDirty := True;
               //
               // clRebel.debug holds the symbols sent
               // clRebel.dumptx holds the symbols read back
               // qrgset[0..125] holds the calculated
               // All 3 need to match.
               for i := 0 to 125 do
               begin
                    c1[i] := '0';
                    c2[i] := '0';
                    c3[i] := qrgset[i];
               end;
               // Break debug set into array first.
               if wordcount(clRebel.debug,[',']) > 126 Then
               Begin
                    for i := 3 to wordcount(clRebel.debug,[','])-2 do c1[i-3] := ExtractWord(i,clRebel.debug,[',']);
               end;

               if wordcount(clRebel.dumptx,[',']) > 126 Then
               Begin
                    for i := 3 to wordcount(clRebel.debug,[','])-2 do c2[i-3] := ExtractWord(i,clRebel.debug,[',']);
               end;

               valid := true;
               for i := 0 to 125 do
               begin
                    if (c1[i]=c2[i]) and (c2[i]=c3[i]) Then
                    Begin
                         // all good
                    end
                    else
                    begin
                         valid := false;
                    end;
               end;

               if not valid then
               Begin
                    { TODO : Don't let this continue forever if it fails repeatedly. }
                    ListBox1.Items.Insert(0,'WARNING: Rebel refused message');
                    // Changing this to delete the TX buffer message so it doesn't go
                    // into an infinite loop should the Rebel be in distress for some
                    // reason.
                    edTXMsg.Text := '';
                    thisTXMsg := '';
               end;
          end;
     end;

     If not clRebel.txStat And not clRebel.busy And txControl And txInprogress Then
     Begin
          // We checked that Rebel is not already transmitting
          // We checked that Rebel is not currently busy
          // We validated message content and sender data
          // We see TX has been requested.
          // Now - we need to turn it on - First with the simple on time case
          If (thisSecond = 1) And (lastSecond=0) Then
          Begin
               // Check for repeat TX and case of exceeding watchdog counter for runaway TX
               if lastTXMsg = thisTXmsg Then
               Begin
                    inc(sameTXCount);
                    i := -1;
                    if tryStrToInt(edTXWD.Text,i) Then
                    Begin
                         if i > 0 Then
                         Begin
                              if sameTXCount > i-1 Then
                              Begin
                                   toggleTX.Checked := False;
                                   toggleTX.state := cbUnchecked;
                                   lastTXMsg := '';
                                   sameTXCount := 0;
                                   ListBox1.Items.Insert(0,'Notice: Same TX Message ' + edTXWD.Text + ' times.  TX is OFF');
                              end;
                         end;
                    end;
               end
               else
               begin
                    lastTXMsg := thisTXmsg;
                    sameTXCount := 0;
               end;
               // PTT on
               clRebel.pttOn;
               // Check to see if it went to TX
               if not clRebel.txStat Then
               Begin
                    // If for some reason it didn't enter TX clear the TX request
                    // It will be reset if necessary and attempt again.
                    txInProgress := false;
               end
               else
               begin
                    // Indicate TX triggered during this minute
                    didTX := True;
                    // Indicate it is in TX
                    Image1.Picture.LoadFromLazarusResource('transmit');
                    transmitting := thisTXmsg;
               end;
          end
          else
          begin
               // Need firmware >=99 to do this.
               if StrToInt(clRebel.rebVer) > 98 Then
               Begin
                    // Late TX start - first see if it could even happen this late.
                    // Not sure I could get here if thisSecond <= 1, but lets be sure.
                    if thisSecond > 1 Then
                    Begin
                         i := lateTXOffset;
                         if i > -1 Then
                         Begin
                              // Can do.  Send Rebel late TX start command with offset
                              // to proper symbol to begin TX at.
                              // Check for repeat TX and case of exceeding watchdog counter for runaway TX
                              if lastTXMsg = thisTXmsg Then
                              Begin
                                   inc(sameTXCount);
                                   i := -1;
                                   if tryStrToInt(edTXWD.Text,i) Then
                                   Begin
                                        if i > 0 Then
                                        Begin
                                             if sameTXCount > i-1 Then
                                             Begin
                                                  toggleTX.Checked := False;
                                                  toggleTX.state := cbUnchecked;
                                                  lastTXMsg := '';
                                                  sameTXCount := 0;
                                                  ListBox1.Items.Insert(0,'Notice: Same TX Message ' + edTXWD.Text + ' times.  TX is OFF');
                                             end;
                                        end;
                                   end;
                              end
                              else
                              begin
                                   lastTXMsg := thisTXmsg;
                                   sameTXCount := 0;
                              end;
                              ListBox2.Items.Insert(0,'TX On at offset = ' + IntToStr(i));
                              clRebel.lateOffset := i;
                              // PTT on
                              clRebel.latePTTOn;
                              if not clRebel.txStat Then
                              Begin
                                   // If for some reason it didn't enter TX clear the TX request
                                   // It will be reset if necessary and attempt again.
                                   txInProgress := false;
                              end
                              else
                              begin
                                   // Indicate TX triggered during this minute
                                   didTX := True;
                                   // Indicate it is in TX
                                   Image1.Picture.LoadFromLazarusResource('transmit');
                                   transmitting := thisTXmsg;
                                   // Double checking to clear Late TX offset value
                                   clRebel.lateOffset := 0;
                              end;
                         end
                         else
                         begin
                              // Was too late
                              ListBox2.Items.Insert(0,'Too late for TX to start');
                         end;
                    end;
               end
               else
               begin
                    ListBox2.Items.Insert(0,'Rebel firmware not late TX capable');
               end;
          end;
     end;

     if clRebel.txStat and (not txInProgress) Then
     Begin
          // TX should be off
          if not clRebel.busy then clRebel.pttOff; // This gets handled more aggressively elsewhere in case it is busy.
          if not clRebel.txStat And not d65.glinprog Then Image1.Picture.LoadFromLazarusResource('receive');
     end;

     if (thisSecond=48) and clRebel.txStat and (not clRebel.busy) Then
     Begin
          clRebel.pttOff;
          txInProgress := False;
          transmitting := '';
     end;

     if rbOn.Checked then rbOn.Caption := 'RB Spots:  ' + IntToStr(rb.rbCount) else rbOn.Caption := 'RB Enable';
     if length(edRBCall.Text) < 3 Then rbOn.Caption := 'Disabled';

     if rbOn.Checked and (not rb.rbOn) Then
     Begin
          rb.myCall := TrimLeft(TrimRight(UpCase(edRBCall.Text)));
          rb.myGrid := TrimLeft(TrimRight(edGrid.Text));
          rb.rbInfo := TrimLeft(TrimRight(edStationInfo.Text));
          foo := '';
          if tryStrToInt(edDialQRG.Text,i) Then
          Begin
               if mval.evalIQRG(i,'lax',foo) Then
               Begin
                    rb.myQRG  := i;
                    sopQRG    := i;
                    rb.useRB := True;
                    rb.useDBF := False;
                    rbping    := True;
               end
               else
               begin
                    rb.myQRG  := 0;
                    sopQRG    := 0;
                    rb.useRB := False;
                    rb.useDBF := False;
                    rbping    := False;
               end;
          end
          else
          begin
               rb.myQRG  := 0;
               sopQRG    := 0;
               rb.useRB := False;
               rb.useDBF := False;
               rbping    := False;
          end;
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
          dChar := deciString[1];
          kChar := kiloString[1];
     end;
     if d65.glinprog Then Image1.Picture.LoadFromLazarusResource('decode');
     if not clRebel.txStat And not d65.glinprog Then Image1.Picture.LoadFromLazarusResource('receive');

     If (Length(TrimLeft(TrimRight(edPrefix.Text))) < 1) And (Length(TrimLeft(TrimRight(edSuffix.Text))) <1) Then
     Begin
          myscall := TrimLeft(TrimRight(UpCase(edCall.Text)));
          mycall  := myscall;
     end
     else
     begin
          // Since prefix outranks suffix this will insure prefix wins if both set.
          If (Length(TrimLeft(TrimRight(edSuffix.Text))) > 0) Then myscall := TrimLeft(TrimRight(UpCase(edCall.Text)))+'/'+TrimLeft(TrimRight(UpCase(edSuffix.Text)));
          If (Length(TrimLeft(TrimRight(edPrefix.Text))) > 0) Then myscall := TrimLeft(TrimRight(UpCase(edPrefix.Text)))+'/'+TrimLeft(TrimRight(UpCase(edCall.Text)));
          mycall := TrimLeft(TrimRight(UpCase(edCall.Text)));
     end;
     // Brute force remove kvasd.dat if it gets left over
     If not d65.glinprog Then
     Begin
          if FileExists(homedir+'KVASD.DAT') Then
          Begin
               if kvdatdel = 0 Then ListBox2.Items.Add('Had to delete kvasd.dat in main loop');
               // kill kill kill kill and kill it again
               try
                  if not FileUtil.DeleteFileUTF8(homedir+'KVASD.DAT') Then inc(kvdatdel) else kvdatdel :=0;
               except
                  //ShowMessage('Debug - could not remove orphaned kvasd.dat' + sLineBreak + 'Please notify W6CQZ');
               end;
          end;
     end;

     if not d65.glinprog Then
     begin
          tot := 0.0;
          fi := 0;
          for i := 0 to 100 do
          begin
               if not d65.glDecTrace[i].trDIS Then
               Begin
                    Memo2.Append(FormatFloat('####',d65.glDecTrace[i].trTIM) + ' mS Bin:  ' + IntToStr(d65.glDecTrace[i].trBIN) + '  DF:  ' + IntToStr(Round(d65.glDecTrace[i].trDFX)) + '  db:  ' + IntToStr(Round(d65.glDecTrace[i].trSNR)) + '  DT:  ' + FormatFloat('##.#',d65.glDecTrace[i].trDTX) + ' [' + d65.glDecTrace[i].trDEC + ']');
                    tot := tot + d65.glDecTrace[i].trTIM;
                    d65.glDecTrace[i].trDIS := True;
                    inc(fi);
               end;
          end;
          if fi>0 Then
          Begin
               Memo2.Append('');
               Memo2.Append(FormatFloat('##.###',tot) + ' mS');
               Memo2.Append('--------------------------------------------------------');
          end;
     end;
end;

procedure TForm1.OncePerSecond;
Var
  i   : Integer;
  foo   : String;
Begin
     // Items that run on each new second or selected new seconds

     // Check to see if we should invoke TX during the only valid time window
     // this should occur thisSecond >=0 and thisSecond <=15
     if (thisSecond < 16) and not clRebel.txStat and not txInProgress Then
     Begin
          // Honoring Rebel being in TX already so it doesn't cancel TX if you clear the message buffer
          if txValid and not txDirty then canTX := True;
          if not canTX and not clRebel.txStat then toggleTX.Checked := False;

          // Enable TX if necessary
          if not txInProgress and inSync and txControl Then
          Begin
               txInProgress := False;
               if rbTXEven.Checked and (not Odd(thisUTC.Minute)) and (not txInProgress) Then
               Begin
                    txInProgress := true;
               end;
               if rbTXOdd.Checked and Odd(thisUTC.Minute) and (not txInProgress) Then
               Begin
                    txInProgress := true;
               end;
          end
          else
          begin
               txInProgress := false;
          end;
     end;

     if (thisSecond = 48) And (lastSecond = 47) And paActive And not decoderBusy And not didTX and inSync Then
     Begin
          // Attempt a decode with V3 Decoder
          for i := 0 to length(adc.d65rxIBuffer)-1 do d65.glinBuffer[i] := adc.d65rxIBuffer[i];
          d65.dmtimestamp := '';
          d65.dmtimestamp := d65.dmtimestamp + IntToStr(thisUTC.Year);
          if thisUTC.Month < 10 Then d65.dmtimestamp := d65.dmtimestamp + '0' + IntToStr(thisUTC.Month) else d65.dmtimestamp := d65.dmtimestamp + IntToStr(thisUTC.Month);
          if thisUTC.Day < 10 Then d65.dmtimestamp := d65.dmtimestamp + '0' + IntToStr(thisUTC.Day) else d65.dmtimestamp := d65.dmtimestamp + IntToStr(thisUTC.Day);
          if thisUTC.Hour < 10 Then d65.dmtimestamp := d65.dmtimestamp + '0' + IntToStr(thisUTC.Hour) else d65.dmtimestamp := d65.dmtimestamp + IntToStr(thisUTC.Hour);
          if thisUTC.Minute < 10 Then d65.dmtimestamp := d65.dmtimestamp + '0' + IntToStr(thisUTC.Minute) else d65.dmtimestamp := d65.dmtimestamp + IntToStr(thisUTC.Minute);
          d65.dmtimestamp := d65.dmtimestamp + '00';
          if thisUTC.Hour < 10 then d65.gld65timestamp := '0' + IntToStr(thisUTC.Hour) else d65.gld65timestamp := IntToStr(thisUTC.Hour);
          if thisUTC.Minute < 10 then d65.gld65timestamp := d65.gld65timestamp + ':0' + IntToStr(thisUTC.Minute) else d65.gld65timestamp := d65.gld65timestamp + ':' + IntToStr(thisUTC.Minute);
          if multion then
          Begin
               glSteps := 1;
               d65.glMouseDF := 0;
               If tbMultiBin.Position = 1 then d65.glbinspace := 20;
               If tbMultiBin.Position = 2 then d65.glbinspace := 50;
               If tbMultiBin.Position = 3 then d65.glbinspace := 100;
               If tbMultiBin.Position = 4 then d65.glbinspace := 200;
          end
          else
          begin
               glSteps := 0;
               d65.glMouseDF := rxdf;
               If tbSingleBin.Position = 1 then d65.glDFTolerance := 20;
               If tbSingleBin.Position = 2 then d65.glDFTolerance := 50;
               If tbSingleBin.Position = 3 then d65.glDFTolerance := 100;
               If tbSingleBin.Position = 4 then d65.glDFTolerance := 200;
          end;
          runDecode := True;
     end;
     if clRebel.band = 20 Then
     Begin
          i := 0;
          if haveRebel and tryStrToInt(edRebTXOffset.Text,i) and (clRebel.txOffset <> i) Then
          Begin
               // fix it
               if not clRebel.Busy then
               begin
                    clRebel.txOffset := i;
                    clRebel.setOffsets;
                    if tryStrToInt(edDialQRG.Text,i) Then
                    Begin
                         qsyQRG := i;
                         setQRG := True;
                    end;
               end;
          end;
     end
     else if clRebel.band = 40 Then
     Begin
          i := 0;
          if haveRebel and tryStrToInt(edRebTXOffset40.Text,i) and (clRebel.txOffset <> i) Then
          Begin
               // fix it
               if not clRebel.Busy then
               begin
                    clRebel.txOffset := i;
                    clRebel.setOffsets;
                    if tryStrToInt(edDialQRG.Text,i) Then
                    Begin
                         qsyQRG := i;
                         setQRG := True;
                    end;
               end;
          end;
     end;
     i := 0;
     if clRebel.band = 20 Then
     Begin
          if haveRebel and tryStrToInt(edRebRXOffset.Text,i) and (clRebel.rxOffset <> i) Then
          Begin
               // fix it
               if not clRebel.busy then
               begin
                    clRebel.rxOffset := i;
                    clRebel.setOffsets;
                    if tryStrToInt(edDialQRG.Text,i) Then
                    Begin
                         qsyQRG := i;
                         setQRG := True;
                    end;
               end;
          end;
     end
     else if clRebel.band = 40 Then
     Begin
          if haveRebel and tryStrToInt(edRebRXOffset40.Text,i) and (clRebel.rxOffset <> i) Then
          Begin
               // fix it
               if not clRebel.busy then
               begin
                    clRebel.rxOffset := i;
                    clRebel.setOffsets;
                    if tryStrToInt(edDialQRG.Text,i) Then
                    Begin
                         qsyQRG := i;
                         setQRG := True;
                    end;
               end;
          end;
     end;

     // Overkill but lets be sure
     if thisSecond = 48 then txInProgress := False;

     // Frame progress indicator
     if (thisSecond < 48) Then ProgressBar1.Position := thisSecond;
     if (thisSecond = 47) And (lastSecond = 46) And InSync And paActive Then
     Begin
          if tryStrToInt(edDialQRG.Text,i) Then eopQRG := i else eopQRG := 0; // Track start/end frame QRG values
     end;
     // Update clock display
     foo := '';
     //if thisUTC.Month < 10 Then foo := '0' + IntToStr(thisUTC.Month) + '-' else foo := IntToStr(thisUTC.Month) + '-';
     //if thisUTC.Day   < 10 Then foo := foo + '0' + IntToStr(thisUTC.Day) else foo := foo + IntToStr(thisUTC.Day);
     //foo := foo + '  ';
     if thisUTC.Hour  < 10 Then foo := foo + '0' + IntToStr(thisUTC.Hour) + ':' else foo := foo + IntToStr(thisUTC.Hour) + ':';
     if thisUTC.Minute < 10 Then foo := foo + '0' + IntToStr(thisUTC.Minute) + ':' else foo := foo + IntToStr(thisUTC.Minute) + ':';
     if thisUTC.Second < 10 Then foo := foo + '0' + IntToStr(thisUTC.Second) else foo := foo + IntToStr(thisUTC.Second);
     Label15.Caption :=  foo;
     Label44.Caption := FormatDateTime(dateString,now);

     // Ping RB Server to keep alive on minutes 0,5,10,15,20,25,30,35,40,45,50,55 at 15 seconds
     if (thisSecond = 15) and (thisUTC.Minute MOD 5 = 0) Then
     Begin
          if rbOn.Checked Then
          Begin
               // Update RB Status
               rb.myCall := TrimLeft(TrimRight(UpCase(edRBCall.Text)));
               rb.myGrid := TrimLeft(TrimRight(edGrid.Text));
               rb.rbInfo := TrimLeft(TrimRight(edStationInfo.Text));
               if tryStrToInt(edDialQRG.Text,i) Then
               Begin
                    if mval.evalIQRG(i,'lax',foo) Then
                    Begin
                         rb.myQRG  := i;
                         rb.useRB  := True;
                         rbping    := True;
                    end
                    else
                    begin
                         rb.myQRG  := 0;
                         rb.useRB  := False;
                         rbping    := False;
                    end;
               end
               else
               begin
                    rb.myQRG   := 0;
                    rb.useRB  := False;
                    rbping    := False;
               end;
          end
          else
          begin
               rb.myCall := TrimLeft(TrimRight(UpCase(edRBCall.Text)));
               rb.myGrid := TrimLeft(TrimRight(edGrid.Text));
               rb.rbInfo := TrimLeft(TrimRight(edStationInfo.Text));
               if tryStrToInt(edDialQRG.Text,i) Then
               Begin
                    if mval.evalIQRG(i,'lax',foo) Then
                    Begin
                         rb.myQRG  := i;
                         sopQRG    := i;
                         rb.useRB := False;
                         rb.useDBF := False;
                         rbping    := False;
                    end
                    else
                    begin
                         rb.myQRG  := 0;
                         sopQRG    := 0;
                         rb.useRB := False;
                         rb.useDBF := False;
                         rbping    := False;
                    end;
               end
               else
               begin
                    rb.myQRG  := 0;
                    sopQRG    := 0;
                    rb.useRB := False;
                    rb.useDBF := False;
                    rbping    := False;
               end;
          end;
     end;
     // Update rig control method before processing any rig control event
     If rigNone.Checked Then catMethod := 'None';
     if rigRebel.Checked Then catMethod := 'Rebel';
     if rigCommander.Checked Then catMethod := 'Commander';
     if rigRebel.Checked and haveRebel and (not setQRG) Then
     Begin
          // Only read QRG every 5 seconds except during 46 to 59
          if (thisUTC.Second < 46) or (thisUTC.Second > 59) Then if thisUTC.Second MOD 5 = 0 Then readQRG := True else readQRG := False;
     end
     else
     begin
          readQRG := False;
     end;
     // Ok - this is going to be ugly - but.  If we have a rebel and it wasn't setup at
     // program start we have to do it now and suffer the program hang.  Only one way to
     // see if that's fatal.  First handle case of disconnecting from a Rebel that is
     // alive.
     if not rigRebel.Checked and clRebel.connected Then
     Begin
          clRebel.disconnect;
          haveRebel := False;
     end;
     // Now deal with connecting to one
     if rigRebel.Checked and not clRebel.connected Then
     Begin
          haveRebel := False;
          if rbRebBaud9600.Checked then clRebel.baud := 9600 else clRebel.baud := 115200;
          if length(edPort.Text)>0 Then
          Begin
               i := -2;
               if tryStrToInt(TrimLeft(TrimRight(edPort.Text)),i) Then
               Begin
                    if i>0 then
                    begin
                         clRebel.port := 'COM'+TrimLeft(TrimRight(edPort.Text));
                         ShowMessage('Connecting to Rebel on ' + clRebel.port + ' at ' + IntToStr(clRebel.baud) + ' baud' + sLineBreak + 'Please insure Rebel is connected and loaded with proper firmware.');
                         if clRebel.connect Then
                         Begin
                              // We're connected need to see if there's a Rebel on the other side
                              if clRebel.setup Then
                              Begin
                                   // Sure enough seem to have one
                                   haveRebel := True;
                              end
                              else
                              begin
                                   haveRebel := False;
                                   rigNone.Checked := True;
                                   ShowMessage('Rebel did not respond at command port' + sLineBreak + 'Please check configuration.');
                              end;
                         end
                         else
                         begin
                              haveRebel := False;
                              rigNone.Checked := True;
                              ShowMessage('Could not open Rebel command port - please check configuration.');
                         end;
                    end
                    else
                    begin
                         haveRebel := False;
                         rigNone.Checked := True;
                         ShowMessage('Bad com port value - please check configuration.');
                    end;
               end;
          end
          else
          begin
               haveRebel := False;
               rigNone.Checked := True;
               ShowMessage('Bad com port value - please check configuration.');
          end;
          inSync := False;  // Have almost certainly lost stream sync during this so resync so act as if it's all new again
          adc.adcFirst := True;
          adc.d65rxBufferIdx := 0;
          adc.d65rxBufferIdx := 0;
          adc.adcTick := 0;
          adc.adcECount := 0;
     end;
     // Deal with Rebel
     // Changing this to defer any CAT work while busy or TX in progress for setting QRG
     if rigRebel.Checked and haveRebel and setQRG and (not clRebel.busy) and (not clRebel.txStat) Then
     Begin
          clRebel.qrg := qsyQRG;
          if clRebel.setQRG Then
          Begin
               ListBox2.Items.Insert(0,'QSY to ' + IntToStr(qsyQRG) + ' complete');
               // CLEAR the TX message on a QSY to force a renegeration
               edTXMsg.Text := '';
               edRXDF.Text := '0';
               edTXDF.Text := '0';
               edDialQRG.Text := IntToStr(qsyQRG);
               readQRG := False;
               setQRG := False;
               if clRebel.poll Then
               Begin
                    edDialQRG.Text:= IntToStr(Round(clRebel.qrg));
               end;
          End
          else
          Begin
               ListBox2.Items.Insert(0,'QSY to ' + IntToStr(qsyQRG) + ' fails');
               edDialQRG.Text := '0';
               editQRG.Text := '0';
               readQRG := False;
               setQRG := False;
          end;
     end

     else if rigRebel.Checked and haveRebel and readQRG and (not clRebel.busy) and (not clRebel.txStat) Then
     Begin
          if clRebel.poll Then
          Begin
               edDialQRG.Text:= IntToStr(Round(clRebel.qrg));
          end;
          readQRG := False;
          setQRG := False;
     end;
     // Update Rebel debug information
     if catMethod = 'Rebel' Then groupRebelOptions.Visible := True else groupRebelOptions.Visible := False;
     // Paint a line for second = 51
     if (thisSecond = 51) and (lastSecond = 50) Then
     Begin
          Try
             //for i := 0 to 749 do
             for i := 0 to 929 do
             Begin
                  spectrum.specPNG[0][i].r := 65535;
                  spectrum.specPNG[0][i].g := 0;
                  spectrum.specPNG[0][i].b := 0;
                  spectrum.specPNG[0][i].a := 8192;
             end;
             // Probably will eventually remove the following line... here for PageControl for now.
          except
             ListBox2.Items.Insert(0,'Exception in paint line (2)');
          end;
     end;

     // Paint a line for second = 0
     if (thisSecond = 1) and (lastSecond = 0) Then
     Begin
          if tryStrToInt(edDialQRG.Text,i) Then sopQRG := i else sopQRG := 0;
          Try
             //for i := 0 to 749 do
             for i := 0 to 929
             do
             Begin
                  spectrum.specPNG[0][i].r := 0;
                  spectrum.specPNG[0][i].g := 65535;
                  spectrum.specPNG[0][i].b := 0;
                  spectrum.specPNG[0][i].a := 32768;
             end;
             // Probably will eventually remove the following line... here for PageControl for now.
          except
             ListBox2.Items.Insert(0,'Exception in paint line (2)');
          end;
     end;

     if cbMultiOn.Checked Then edRXDF.Text := '0';
     specHeader;  // Update spectrum display header
end;

procedure TForm1.OncePerMinute;
Var
  i        : Integer;
Begin
     for i := 0 to 1023 do psAcc[i] := 0.0;
     pstick := 1;
     // Items that run once per minute at new minute start
     SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
     // RX to index = 0
     adc.d65rxBufferIdx := 0;
     didTX := False;
     if not inSync Then
     Begin
          inSync := True;
          ListBox2.Items.Insert(0,'Timing loop now in sync');
     end;

     // Prune decoder output display
     if ListBox1.Items.Count > 250 Then
     Begin
          Try
             for i := ListBox1.Items.Count-1 downto 99 do
             begin
                  ListBox1.Items.Delete(i);
             end;
          except
             ListBox2.Items.Insert(0,'Exception in prune list');
          end;
     end;
     // This resets AGC action in Spectrum if it's on - keeps it from getting stuck and leading to a no smooth display.
     Try
        if spectrum.specagc > 0 Then spectrum.specagc := 0;
     Except
        ListBox2.Items.Insert(0,'Exception in reset agc');
     end;
     // Display any RB Errors
     //if rb.errLog.Count > 0 Then for i := 0 to rb.errLog.Count-1 do Memo2.Append(rb.errlog.Strings[i]);
     rb.clearErr;
end;

procedure TForm1.periodicSpecial;
Begin
     // Nothing
end;

procedure TForm1.adcdacTick;
Begin
     // Events triggered from ADC/DAC callback counter change
     // Compute spectrum and audio levels.
     if cbWFTX.Checked Then
     Begin
          If adc.haveSpec And (not d65.glinprog) Then
          Begin
               spectrum.specWindow := cbSpecWindow.Checked;
               spectrum.computeSpectrum(adc.adclast4k1);
               adc.haveSpec := False;
          end
          else
          begin
               adc.haveSpec := False;
          end;
     end
     else
     begin
          If adc.haveSpec And (not d65.glinprog) And (not clRebel.txStat) Then
          Begin
               spectrum.specWindow := cbSpecWindow.Checked;
               spectrum.computeSpectrum(adc.adclast4k1);
               adc.haveSpec := False;
          end
          else
          begin
               adc.haveSpec := False;
          end;
     end;
     if adc.haveAU And (not d65.glinprog) And (not clRebel.txStat) Then
     Begin
          // Compute/display audio level(s)
          aulevel := spectrum.computeAudio(adc.adclast2k1);
          if (aulevel*0.4)-20.0 < -7.0 Then
          Begin
               Label3.Caption := 'Audio Low';
               Label3.Font.Color := clRed;
          end
          else if (aulevel*0.4)-20.0 > 7.0 Then
          Begin
               Label3.Caption := 'Audio High';
               Label3.Font.Color := clRed;
          end
          else
          begin
               Label3.Caption := 'Audio OK';
               Label3.Font.Color := clBlack;
          end;
          // sLevel = 50 = 0dB sLevel 0 = -20dB sLevel 100 = 20dB
          // 1 sLevel = .4dB
          // db = (sLevel*0.4)-20
          adc.haveAU := False;
     end;
end;

procedure TForm1.specHeader;
Var
   i,ii,txHpix : Integer;
   cfPix       : Integer;
   floatVar    : Single;
Begin
     If not TryStrToInt(edTXDF.Text,i) Then i := -9000;
     If not TryStrToInt(edRXDF.Text,ii) Then ii := -9000;
     if (i>-9000) and (ii>-9000) Then
     Begin
          // Reload header Paint the TX/RX Markers.  RX Marker is not painted unless in single decode mode.
          paintbox1.Canvas.Clear;
          if (d65.glbinspace = 0) or (d65.glbinspace = 20) Then
          Begin
               paintBox1.Canvas.Draw(0,0,B20);
          end
          else if d65.glbinspace = 50 then
          begin
               paintBox1.Canvas.Draw(0,0,B50);

          end
          else if d65.glbinspace = 100 then
          begin
               paintBox1.Canvas.Draw(0,0,B100);
          end
          else if d65.glbinspace = 200 then
          begin
               paintBox1.Canvas.Draw(0,0,B200);
          end
          else
          begin
               paintBox1.Canvas.Draw(0,0,B20);
          end;

          if i <> 0 Then
          Begin
               floatVar := i / 2.7027;
               floatVar := 376+floatVar;
               cfPix := Round(floatVar);
               txHpix := Round(floatVar+66.7);
               PaintBox1.Canvas.Pen.Color := clRed;
               PaintBox1.Canvas.Pen.Width := 3;
               PaintBox1.Canvas.Line(cfPix,1,cfPix,7);
               PaintBox1.Canvas.Line(txHpix,1,txHpix,7);
               PaintBox1.Canvas.Line(cfPix,1,txHpix,1);
          End
          Else
          Begin
               // TXCF = 0hz so CF marker is at pixel 376
               cfPix := 376;
               txHpix := 376+67;
               PaintBox1.Canvas.Pen.Color := clRed;
               PaintBox1.Canvas.Pen.Width := 3;
               PaintBox1.Canvas.Line(cfPix,1,cfPix,7);
               PaintBox1.Canvas.Line(txHpix,1,txHpix,7);
               PaintBox1.Canvas.Line(cfPix,1,txHpix,1);
          end;
          if ii <> 0 Then
          Begin
               floatVar := ii / 2.7027;
               floatVar := 376+floatVar;
               cfPix := Round(floatVar);
               PaintBox1.Canvas.Pen.Color := clGreen;
               PaintBox1.Canvas.Pen.Width := 5;
               PaintBox1.Canvas.Line(cfpix,1,cfpix,7);
          end
          else
          begin
               cfPix := 376;
               PaintBox1.Canvas.Pen.Color := clGreen;
               PaintBox1.Canvas.Pen.Width := 5;
               PaintBox1.Canvas.Line(cfpix,1,cfpix,7);
          end;
          lastTXDFMark := i;
          lastRXDFMark := ii;
          headerRes := d65.glBinSpace;
     end;

End;

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

procedure TForm1.displayDecodes3;
Var
   i,j,k,wc : Integer;
   afoo     : String;
   bfoo,n1  : String;
   cfoo,ng  : String;
   srec     : Spot.spotRecord;
   nodteval : Boolean;
   td,te,tf : CTypes.cdouble;
Begin
     periodDecodes := 0;
     k := 0;
     for i := 0 to 49 do if not d65.gld65decodes[i].dtProcessed Then inc(k);
     if thisUTC.Hour < 10 Then afoo := '0'+IntToStr(thisUTC.Hour) else afoo := intToStr(thisUTC.Hour);
     if thisUTC.Minute < 10 then afoo := afoo + ':0' + intToStr(thisUTC.Minute) else afoo := afoo + ':' + intToStr(thisUTC.Minute);
     If k>0 Then
     Begin
          // Update decoder statistics
          if d65.dmruntime > lrun then lrun := d65.dmruntime;
          if isZero(srun) Then srun := d65.dmruntime;
          if d65.dmruntime < srun Then srun := d65.dmruntime;
          if not IsZero(d65.dmruntime) Then Label82.Caption := FormatFloat('0.000',(d65.dmruntime/1000.0));
          if not IsZero(lrun) Then Label83.Caption := FormatFloat('0.000',(lrun/1000.0));
          if not IsZero(srun) Then Label84.Caption := FormatFloat('0.000',(srun/1000.0));
          if not isZero(d65.dmarun) Then Label86.Caption := FormatFloat('0.000',((d65.dmarun/d65.dmrcount)/1000.0));

          if cbDivideDecodes.Checked Then ListBox1.Items.Insert(0,'------------------------------------------------------------');
          for i := 0 to 49 do
          begin
               if not d65.gld65decodes[i].dtProcessed Then
               Begin
                    inc(periodDecodes);
                    // Adjust the decimal point to what it "should" be for user's display.
                    afoo := d65.gld65decodes[i].dtDeltaTime;
                    if length(afoo)> 2 Then
                    Begin
                         bfoo := ExtractWord(1,afoo,[',','.']);
                         cfoo := ExtractWord(2,afoo,[',','.']);
                         afoo := bfoo + dChar + cfoo;
                         // I don't want stations hugely out of time compared to our local timebase
                         // skewing this.
                         nodteval := True;
                         If (StrToFloat(afoo) > 0.99) or (StrToFloat(afoo) < -0.99) Then
                         Begin
                              nodteval := True;
                              inc(dtrejects);
                         End
                         Else
                         Begin
                              nodteval := False;
                              avgdt := StrToFloat(afoo) + avgdt;
                         end;
                    end;
                    if d65.gld65decodes[i].dtType = 'K' then inc(kvcount);
                    if d65.gld65decodes[i].dtType = 'B' then inc(bmcount);
                    if d65.gld65decodes[i].dtType = 'S' then inc(shcount);
                    if length(d65.gld65decodes[i].dtDecoded)>1 Then
                    Begin
                         if not nodteval Then inc(d65.glDecCount);
                         d65.glDTAvg := (d65.glDTAvg+avgdt)/d65.glDecCount;
                         // 12:34  -##  -1000  MESSAGE
                         // 12:34  -##   1000  MESSAGE
                         if not AnsiContainsText(d65.gld65decodes[i].dtDeltaFreq,'-') Then d65.gld65decodes[i].dtDeltaFreq := ' ' + d65.gld65decodes[i].dtDeltaFreq;
                         if length(d65.gld65decodes[i].dtSigLevel)=2 Then d65.gld65decodes[i].dtSigLevel := d65.gld65decodes[i].dtSigLevel[1] + '0' + d65.gld65decodes[i].dtSigLevel[2];
                         ListBox1.Items.Insert(0, d65.gld65decodes[i].dtTimeStamp + '  ' + PadRight(d65.gld65decodes[i].dtSigLevel,3) + '  ' + PadRight(d65.gld65decodes[i].dtDeltaFreq,5) + '   ' + d65.gld65decodes[i].dtDecoded);
                         // Look at exchange - it should be their_call my_call -## or their_call my_call R-##
                         // if seen that should be the signal report value
                         wc := WordCount(d65.gld65decodes[i].dtDecoded,[' ']);
                         if wc = 3 Then
                         Begin
                              n1 := '';
                              ng  := '';
                              n1 := ExtractWord(1,d65.gld65decodes[i].dtDecoded,[' ']);
                              ng  := ExtractWord(3,d65.gld65decodes[i].dtDecoded,[' ']);
                              if((n1=myscall) or (n1=mycall)) and (length(ng)>2) then
                              Begin
                                   // Need to see if ng is a R-## or #--
                                   if ng[1]='-' Then logMySig.Text:=ng else if ng[1..2]='R-' Then logMySig.Text := ng[2..Length(ng)];
                              end;
                         end;
                         if wc = 2 Then
                         Begin
                              // In case of working with slashed calls
                              n1 := '';
                              ng  := '';
                              n1 := ExtractWord(1,d65.gld65decodes[i].dtDecoded,[' ']);
                              ng  := ExtractWord(2,d65.gld65decodes[i].dtDecoded,[' ']);
                              if((n1=myscall) or (n1=mycall)) and (length(ng)>2) then
                              Begin
                                   // Need to see if ng is a R-## or #--
                                   if ng[1]='-' Then logMySig.Text:=ng else if ng[1..2]='R-' Then logMySig.Text := ng[2..Length(ng)];
                              end;
                         end;
                         if not tryStrToInt(edDialQRG.Text,j) Then edDialQRG.Text := '0';
                         if (rbOn.Checked) And (sopQRG = eopQRG) And (StrToInt(edDialQRG.Text) > 0) Then
                         Begin
                              //Post to RB
                              //Adjust the decimal point to what it "should" be. And here is should be .
                              afoo := bfoo + '.' + cfoo;
                              srec.qrg      := StrToInt(edDialQRG.Text);
                              srec.date     := TrimLeft(TrimRight(d65.dmTimeStamp));
                              srec.time     := '';
                              srec.sync     := StrToInt(TrimLeft(TrimRight(d65.gld65decodes[i].dtNumSync)));
                              srec.db       := StrToInt(TrimLeft(TrimRight(d65.gld65decodes[i].dtSigLevel)));
                              srec.dt       := TrimLeft(TrimRight(afoo));
                              srec.df       := StrToInt(TrimLeft(TrimRight(d65.gld65decodes[i].dtDeltaFreq)));
                              srec.decoder  := TrimLeft(TrimRight(d65.gld65decodes[i].dtType));
                              srec.decoder  := srec.decoder[1];
                              srec.exchange := TrimLeft(TrimRight(d65.gld65decodes[i].dtDecoded));
                              srec.mode     := '65A';
                              srec.rbsent   := False;
                              srec.dbfsent  := False;
                              rb.addSpot(srec);
                              inc(rbposted);
                         End;
                    end;
                    // Free record for demodulator's use next round.
                    d65.gld65decodes[i].dtProcessed := True;
               end;
          end;
          d65.gld65HaveDecodes := False;
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
     for i := 0 to 49 do
     begin
          d65.gld65decodes[i].dtProcessed := True;
     end;
     // Post msync results to Chart4BarSeries1
     Chart4BarSeries1.Clear;
     for i := 0 to 254 do if d65.glSynFreq[i] > -9999.0 Then Chart4BarSeries1.AddXY(d65.glSynFreq[i],d65.glSynDected[i]);

     if plotCount <> d65.dmPlotCount Then
     Begin
          td := periodDecodes*1.0;
          te := d65.dmSynPoints*1.0;
          tf := d65.glBinCount *1.0;
          if d65.dmPlotCount > 360 Then
          Begin
               Chart1LineSeries1.Clear;
               Chart2LineSeries1.Clear;
               Chart2LineSeries2.Clear;
               Chart3LineSeries1.Clear;
               Chart3LineSeries2.Clear;
               Chart3LineSeries3.Clear;
               Chart4BarSeries1.Clear;
               d65.dmPlotCount := 0;
               Chart1LineSeries1.AddXY(d65.dmPlotCount,d65.dmPlotAvgSq);
               Chart2LineSeries1.AddXY(d65.dmPlotCount,d65.dmruntime/1000.0);
               Chart2LineSeries2.AddXY(d65.dmPlotCount,(d65.dmarun/d65.dmrcount)/1000.0);
               Chart2LineSeries3.AddXY(d65.dmPlotCount,(d65.dmnzrun)/1000.0);
               Chart3LineSeries1.AddXY(d65.dmPlotCount,te);
               Chart3LineSeries2.AddXY(d65.dmPlotCount,tf);
               Chart3LineSeries3.AddXY(d65.dmPlotCount,td);
               plotcount := d65.dmPlotCount;
          end
          else
          begin
               Chart1LineSeries1.AddXY(d65.dmPlotCount,d65.dmPlotAvgSq);
               Chart2LineSeries1.AddXY(d65.dmPlotCount,d65.dmruntime/1000.0);
               Chart2LineSeries2.AddXY(d65.dmPlotCount,(d65.dmarun/d65.dmrcount)/1000.0);
               Chart2LineSeries3.AddXY(d65.dmPlotCount,(d65.dmnzrun)/1000.0);
               Chart3LineSeries1.AddXY(d65.dmPlotCount,te);
               Chart3LineSeries2.AddXY(d65.dmPlotCount,tf);
               Chart3LineSeries3.AddXY(d65.dmPlotCount,td);
               plotcount := d65.dmPlotCount;
          end;
     end;
     d65.dmAveSQ := 0.0;
     d65.dmBaseVB := 0.0;
     d65.dmSynPoints := 0;
     d65.dmMerged := 0;
     d65.dmkvhangs := 0;
end;

function  TForm1.db(x : CTypes.cfloat) : CTypes.cfloat;
Begin
     Result := -99.0;
     if x > 1.259e-10 Then Result := 10.0 * log10(x);
end;

procedure TForm1.toggleTXClick(Sender: TObject);
begin
     lastTXMsg := '';
     sameTXCount := 0;
     If toggleTX.Checked then toggleTX.state := cbChecked else toggleTX.state := cbUnchecked;
end;

procedure TForm1.tbMultiBinChange(Sender: TObject);
begin
     If tbMultiBin.Position = 1 then d65.glbinspace := 20;
     If tbMultiBin.Position = 2 then d65.glbinspace := 50;
     If tbMultiBin.Position = 3 then d65.glbinspace := 100;
     If tbMultiBin.Position = 4 then d65.glbinspace := 200;
     Label26.Caption := 'Multi ' + IntToStr(d65.glbinspace) + ' Hz';
end;

procedure TForm1.tbSingleBinChange(Sender: TObject);
begin
     If tbSingleBin.Position = 1 then d65.glDFTolerance := 20;
     If tbSingleBin.Position = 2 then d65.glDFTolerance := 50;
     If tbSingleBin.Position = 3 then d65.glDFTolerance := 100;
     If tbSingleBin.Position = 4 then d65.glDFTolerance := 200;
     Label87.Caption := 'Single ' + IntToStr(d65.glDFTolerance) + ' Hz';
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
     if length(foo)>0 Then
     Begin
          for i := 1 To Length(foo) do
          Begin
               if (not isLetter(foo[i])) And (not isDigit(foo[i])) Then Result := False;
               if not Result Then
               Begin
                    if (foo[i] = '/') or (foo[i] = ' ' ) or (foo[i] = '-') Then Result := True;
               end;
               if not result then break;
          end;
     end
     else
     begin
          result := false;
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
     if length(foo)>0 Then
     Begin
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
     end
     else
     begin
          result := false;
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
     // Updating for less.... verbose :) decoder display.
     // It has
     // UTC dB  DF  Message  enough of the endless bitching about inconsequential DT levels.
     // Word Count must be 3 for UTC, dB and DF + 2, 3 or 4 for exchange for 5, 6 or 7.
     // Now with a structured message I'll have...
     // UTC, Sync, dB, DT, DF, EC, NC1, Call FROM, MSG
     // Where NC1 is one of [CQ, CQ ###, QRZ, DE, CALLSIGN]
     // Where MSG is one of [Grid,-##,R-##,RRR,RO,73]
     // First check is for first two characters to be numeric AND wordcount
     // = 9 or 10.  10 Handles case of a CQ ### format (not seen on HF, but...)
     // If not wc = 9 or 10 then it's not something to parse here.
     i := 0;
     wc := wordcount(foo,[',']);
     if (wc=5) or (wc=6) or (wc=7) Then
     Begin
          if wc=5 Then
          Begin
               // Parse string into parts (5 word exchange)
               exchange.utc  := TrimLeft(TrimRight(UpCase(ExtractWord(1,foo,[',']))));
               exchange.db   := TrimLeft(TrimRight(UpCase(ExtractWord(2,foo,[',']))));
               exchange.df   := TrimLeft(TrimRight(UpCase(ExtractWord(3,foo,[',']))));
               exchange.nc1  := TrimLeft(TrimRight(UpCase(ExtractWord(4,foo,[',']))));
               exchange.nc1s := '';
               exchange.nc2  := TrimLeft(TrimRight(UpCase(ExtractWord(5,foo,[',']))));
               exchange.ng   := '';
          end;
          if wc=6 Then
          Begin
               // Parse string into parts (6 word exchange)
               exchange.utc  := TrimLeft(TrimRight(UpCase(ExtractWord(1,foo,[',']))));
               exchange.db   := TrimLeft(TrimRight(UpCase(ExtractWord(2,foo,[',']))));
               exchange.df   := TrimLeft(TrimRight(UpCase(ExtractWord(3,foo,[',']))));
               exchange.nc1  := TrimLeft(TrimRight(UpCase(ExtractWord(4,foo,[',']))));
               exchange.nc1s := '';
               exchange.nc2  := TrimLeft(TrimRight(UpCase(ExtractWord(5,foo,[',']))));
               exchange.ng   := TrimLeft(TrimRight(UpCase(ExtractWord(6,foo,[',']))));
          End;
          if wc=7 Then
          Begin
               // Parse string into parts (7 word exchange)
               exchange.utc  := TrimLeft(TrimRight(UpCase(ExtractWord(1,foo,[',']))));
               exchange.db   := TrimLeft(TrimRight(UpCase(ExtractWord(2,foo,[',']))));
               exchange.df   := TrimLeft(TrimRight(UpCase(ExtractWord(3,foo,[',']))));
               exchange.nc1  := TrimLeft(TrimRight(UpCase(ExtractWord(4,foo,[',']))));
               exchange.nc1s := TrimLeft(TrimRight(UpCase(ExtractWord(5,foo,[',']))));
               exchange.nc2  := TrimLeft(TrimRight(UpCase(ExtractWord(6,foo,[',']))));
               exchange.ng   := TrimLeft(TrimRight(UpCase(ExtractWord(7,foo,[',']))));
          End;

          i := 0;
          if Length(exchange.utc)=5 Then gonogo := True else gonogo := False;
          if gonogo and TryStrToInt(exchange.utc[1..2],i) and TryStrToInt(exchange.utc[4..5],i) and (exchange.utc[3]=':') Then gonogo := True else gonogo := False;
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
                    if isiglevel > -10 Then
                    Begin
                         edTXReport.Text := '-0' + IntToStr(Abs(isiglevel));
                         sdb := edTXReport.Text;
                    end
                    else
                    begin
                         edTXReport.Text := IntToStr(isiglevel);
                         sdb := edTXReport.Text;
                    end;
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
               if wc = 5 Then toParse := exchange.nc1  + ' ' + exchange.nc2;
               if wc = 6 Then toParse := exchange.nc1  + ' ' + exchange.nc2 + ' ' + exchange.ng;
               if wc = 7 Then toParse := exchange.nc1  + ' ' + exchange.nc1s + ' ' + exchange.nc2 + ' ' + exchange.ng;
               v1DecomposeDecode(toParse,inQSOWith,isValid,isBreakIn,level,response,connectTo,fullCall,hisGrid);
               //sdb := exchange.db;
               sdf := exchange.df;
               // compute TX period
               foo := exchange.utc[4..5];
               i := -1;
               tryStrToInt(foo,i);
               if (i>-1) and odd(i) then txp := 0; // Was received Odd so TX Even!
               if (i>-1) and not odd(i) then txp := 1; // Was received Even so TX Odd!
          end;
     end;
end;

function TForm1.isSlashedCall(const s : String) : Boolean;
begin
     if ansicontainstext(s,'/') Then result := true else result := false;
end;

{ TODO : Validate this }

procedure TForm1.v1DecomposeDecode(const exchange    : String;
                                 const connectedTo : String;
                                 var isValid       : Boolean;
                                 var isBreakIn     : Boolean;
                                 var level         : Integer;
                                 var response      : String;
                                 var connectTo     : String;
                                 var fullCall      : String;
                                 var hisGrid       : String);
Var
   wc,i         : Integer;
   nc1,nc2,ng   : String;
   myGrid4      : String;
   siglevel     : String;
Begin
     // Handles message parsing and response generation for strict JT65V1 compliance }
     isValid   := False;
     isBreakin := True;
     level     := 1;
     response  := '';

     wc := WordCount(exchange,[' ']);
     nc1 := '';
     nc2 := '';
     ng  := '';
     if (wc=2) or (wc=3) Then
     Begin
          // Break out the first call (nc1), second call (nc2) and [maybe] grid (ng) if 3 words - if 2 it's just nc1 and nc2
          if wc=3 Then
          Begin
               nc1 := ExtractWord(1,exchange,[' ']);
               nc2 := ExtractWord(2,exchange,[' ']);
               ng  := ExtractWord(3,exchange,[' ']);
          end
          else
          begin
               nc1 := ExtractWord(1,exchange,[' ']);
               nc2 := ExtractWord(2,exchange,[' ']);
               ng  := '';
          end;
          // Get local info needed to build response
          siglevel := TrimLeft(TrimRight(edTXReport.Text));
          if tryStrToInt(siglevel,i) Then
          Begin
               if i > -10 Then
               Begin
                    siglevel := '-0' + IntToStr(Abs(i));
               end
               else
               begin
                    siglevel := siglevel;
               end;
          end
          else
          begin
               // Signal level did not parse to integer.. bad
               wc:=0;
               Memo2.Append('Signal report did not parse to integer. No response.');
          end;
          myGrid4 := TrimLeft(TrimRight(UpCase(edGrid.Text)));
          if Length(myGrid4)>4 Then myGrid4 := myGrid4[1..4];
          if not isGrid(myGrid4) Then
          Begin
               // Stopping the no grid set nonsense once and for all
               // It *should* have been caught before now, but, will do
               // this as a final check.
               isValid   := False;
               connectTo := TrimLeft(TrimRight(UpCase(nc2)));
               fullCall  := connectTo;
               hisGrid   := ng;
               isBreakIn := False;
               response  := '';
               ListBox1.Items.Insert(0,'Notice: Setup your Grid');
               wc := 0;
          end;

          // Start figuring out what we have 2 word types first.
          if wc=2 Then
          Begin
               // 2 Word types for V1
               // CQ PREFIX/CALL
               // CQ CALL/SUFFIX
               // CQ CALL (Technically invalid, but will handle)

               // QRZ PREFIX/CALL
               // QRZ CALL/SUFFIX
               // QRZ CALL (Technically invalid, but will handle)

               // CALL PREFIX/CALL
               // CALL CALL/SUFFIX
               // PREFIX/CALL CALL
               // CALL/SUFFIX CALL
               // CALL CALL (Technically invalid, but will handle)

               // CALL CONTROL (Where control is -##, R-##, RRR or 73)
               // PREFIX/CALL CONTROL
               // CALL/SUFFIX CONTROL

               if ((nc1='CQ') or (nc1='QRZ')) And isV1Call(nc2) Then
               Begin
                    // Now - I CAN NOT have both the remote and local call have / - JT65 doesn't allow this.
                    if isSlashedCall(nc2) and isSlashedCall(myscall) Then
                    Begin
                         response  := '';
                         isValid   := False;
                         fullCall  := '';
                         connectTo := '';
                         ListBox1.Items.Insert(0,'Notice: both calls to have /');
                         ListBox1.Items.Insert(0,'Notice: JT65V1 does not allow');
                    end
                    else
                    begin
                         isValid   := True;
                         connectTo := TrimLeft(TrimRight(UpCase(nc2)));
                         fullCall  := connectTo;
                         logGrid.Text := '';

                         response  := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall)));
                         isBreakIn := False;
                    end;
               end;

               if isV1Call(nc1) and isV1Call(nc2) Then
               Begin
                    // Here we have a pair of calls - if one is mine then I have one response
                    // his call + signal report.  If my call isn't in here then I can setup
                    // for a tail end reply.
                    if isSlashedCall(nc2) and isSlashedCall(myscall) Then
                    Begin
                         response  := '';
                         isValid   := False;
                         fullCall  := '';
                         connectTo := '';
                         ListBox1.Items.Insert(0,'Notice: both calls to have /');
                         ListBox1.Items.Insert(0,'Notice: JT65V1 does not allow');
                    end
                    else
                    begin
                         if (nc1 = mycall) or (nc1 = myscall) Then
                         Begin
                              isValid   := True;
                              connectTo := TrimLeft(TrimRight(UpCase(nc2)));
                              fullCall  := connectTo;
                              response  := connectTo + ' ' + siglevel;
                              isBreakIn := False;
                              logGrid.Text := '';
                         end
                         else
                         begin
                              isValid   := True;
                              connectTo := TrimLeft(TrimRight(UpCase(nc2)));
                              fullCall  := connectTo;
                              response  := connectTo + ' ' + siglevel;
                              isBreakIn := True;
                              logGrid.Text := '';
                         end;
                    end;
               end;

               if isV1Call(nc1) and isControl(nc2) Then
               Begin
                    // Now this one gets tricky.  Only 1 valid case and that is
                    // nc1 = mycall or myscall - but the response must be to connectTo
                    // which had to be found earlier.
                    // I don't have to worry about the double slashed calls check here
                    if ((nc1=mycall) or (nc1=myscall)) And (Length(connectedTo)>0) Then
                    Begin
                         // Ok - it has mycall and connectedTo is set.
                         // Now - I need to see;
                         // MYCALL CONTROL (Where control is -##, R-##, RRR or 73)
                         // Two simple ones first.
                         if (nc2='RRR') or (nc2='73') Then
                         Begin
                              // Response is MYCALL 73
                              isValid   := True;
                              isBreakIn := False;
                              // Trying something cute here
                              if Length('DE ' + TrimLeft(TrimRight(UpCase(myscall))) + ' 73') < 14 Then
                              Begin
                                   response := 'DE ' + TrimLeft(TrimRight(UpCase(myscall))) + ' 73';  // This is a *CHANGE* from former way where it was HISCALL 73
                              end
                              else
                              begin
                                   response := TrimLeft(TrimRight(UpCase(myscall))) + ' 73';  // This is a *CHANGE* from former way where it was HISCALL 73
                              end;
                         end
                         else if nc2[1] = '-' Then
                         begin
                              // Has to be -##
                              // Response is HISCALL R-##
                              isValid   := True;
                              isBreakIn := False;
                              response := connectedTo + ' R' + sigLevel;
                              logMySig.Text := nc2;
                         end
                         else if nc2[1..2] = 'R-' Then
                         Begin
                              // Has to be R-##
                              // Response is HISCALL RRR
                              isValid   := True;
                              isBreakIn := False;
                              response := connectedTo + ' RRR';
                              logMySig.Text := nc2[2..Length(nc2)];
                         end
                         else
                         begin
                              response  := '';
                              isValid   := False;
                              ListBox1.Items.Insert(0,'Notice: No response calculated');
                         end;
                    end
                    else
                    begin
                         response  := '';
                         isValid   := False;
                         fullCall  := '';
                         connectTo := '';
                         ListBox1.Items.Insert(0,'Notice: No response calculated');
                    end;
               end;
          end;
          // Now 3 Word Types
          // CQ CALL GRID
          // QRZ CALL GRID
          // CALL CALL GRID
          // CALL CALL CONTROL
          if ((nc1='CQ') or (nc1='QRZ')) and isV1Call(nc2) and isGrid(ng) Then
          Begin
               // Ok this is a good one - only constraint is if myscall is slashed
               if isSlashedCall(nc2) and isSlashedCall(myscall) Then
               Begin
                    // This shouldn't be able to happen here... but.  :)
                    response  := '';
                    isValid   := False;
                    fullCall  := '';
                    connectTo := '';
                    logGrid.Text := '';
                    ListBox1.Items.Insert(0,'Notice: both calls to have /');
                    ListBox1.Items.Insert(0,'Notice: JT65V1 does not allow');
               end
               else
               begin
                    isValid   := True;
                    connectTo := TrimLeft(TrimRight(UpCase(nc2)));
                    fullCall  := connectTo;
                    hisGrid   := ng;
                    isBreakIn := False;
                    logGrid.Text := ng;

                    if isSlashedCall(myscall) Then
                    Begin
                         response  := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall)));
                    end
                    else
                    begin
                         response := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' ' + mygrid4;
                    end;
               end;
          end;

          if isV1Call(nc1) and isV1Call(nc2) and isGrid(ng) Then
          Begin
               // This one has to be to myscall in nc1 or it will be treated as a break in type.
               if isSlashedCall(nc2) and isSlashedCall(myscall) Then
               Begin
                    response  := '';
                    isValid   := False;
                    fullCall  := '';
                    connectTo := '';
                    ListBox1.Items.Insert(0,'Notice: both calls to have /');
                    ListBox1.Items.Insert(0,'Notice: JT65V1 does not allow');
               end
               else
               begin
                    if nc1=myscall Then
                    Begin
                         // Response to this is his_call my_call -##
                         isValid   := True;
                         connectTo := TrimLeft(TrimRight(UpCase(nc2)));
                         fullCall  := connectTo;
                         hisGrid   := ng;
                         isBreakIn := False;
                         logGrid.Text := ng;

                         if isSlashedCall(myscall) Then
                         Begin
                              response  := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall)));
                         end
                         else
                         begin
                              response := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' ' + siglevel;
                         end;
                    end
                    else
                    begin
                         // Response to this is his_call my_call -## but is a break in
                         isValid   := True;
                         connectTo := TrimLeft(TrimRight(UpCase(nc2)));
                         fullCall  := connectTo;
                         hisGrid   := ng;
                         isBreakIn := True;
                         logGrid.Text := ng;

                         if isSlashedCall(myscall) Then
                         Begin
                              response  := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall)));
                         end
                         else
                         begin
                              response := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' ' + mygrid4;
                         end;
                    end;
               end;
          end;

          if isV1Call(nc1) and isV1Call(nc2) and isControl(ng) Then
          Begin
               // This one has to be to myscall in nc1 or it will be treated as a break in type.
               if isSlashedCall(nc2) and isSlashedCall(myscall) Then
               Begin
                    response  := '';
                    isValid   := False;
                    fullCall  := '';
                    connectTo := '';
                    ListBox1.Items.Insert(0,'Notice: both calls to have /');
                    ListBox1.Items.Insert(0,'Notice: JT65V1 does not allow');
               end
               else
               begin
                    if nc1=myscall Then
                    Begin
                         // Need to see mycall hiscall -## or R-## or RRR or 73
                         if (ng='RRR') or (ng='73') Then
                         Begin
                              // Response is 73
                              if isSlashedCall(myscall) Then
                              Begin
                                   // Trying something cute here
                                   if Length('DE ' + TrimLeft(TrimRight(UpCase(myscall))) + ' 73') < 14 Then
                                   Begin
                                        response := 'DE ' + TrimLeft(TrimRight(UpCase(myscall))) + ' 73';  // This is a *CHANGE* from former way where it was HISCALL 73
                                   end
                                   else
                                   begin
                                        response := TrimLeft(TrimRight(UpCase(myscall))) + ' 73';  // This is a *CHANGE* from former way where it was HISCALL 73
                                   end;
                              end
                              else
                              begin
                                   response := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' 73';
                              end;
                         end
                         else if ng[1]='-' Then
                         Begin
                              // Grab this for logging signal report :)
                              // Response is R-##
                              isValid   := True;
                              connectTo := TrimLeft(TrimRight(UpCase(nc2)));
                              fullCall  := connectTo;
                              isBreakIn := False;
                              logMySig.Text := ng;

                              if isSlashedCall(myscall) Then
                              Begin
                                   response  := connectTo + ' R' + sigLevel;
                              end
                              else
                              begin
                                   response := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' R' + siglevel;
                              end;
                         end
                         else if ng[1..2]='R-' Then
                         Begin
                              // Response is RRR
                              // Grab this for logging signal report :)
                              isValid   := True;
                              connectTo := TrimLeft(TrimRight(UpCase(nc2)));
                              fullCall  := connectTo;
                              isBreakIn := False;
                              logMySig.Text := ng[2..Length(ng)];

                              if isSlashedCall(myscall) Then
                              Begin
                                   response  := connectTo + ' RRR';
                              end
                              else
                              begin
                                   response := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' RRR';
                              end;
                         end;
                    end
                    else
                    begin
                         // Break in type
                         // Only one response hiscall mycall GRID or hiscall my/call break in type
                         isValid   := True;
                         connectTo := TrimLeft(TrimRight(UpCase(nc2)));
                         fullCall  := connectTo;
                         isBreakIn := True;

                         if isSlashedCall(myscall) Then
                         Begin
                              response  := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall)));
                         end
                         else
                         begin
                              response := connectTo + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' ' + mygrid4;
                         end;
                    end;
               end;
          end;
     end
     else
     begin
          response := '';
          isValid  := False;
          fullCall  := '';
          connectTo := '';
          ListBox1.Items.Insert(0,'Notice: No response calculated');
     end;

end;

function TForm1.txControl : Boolean;
Var
  t1,t2 : Boolean;
  foo   : String;
Begin
     // Call this to see if you can TX at top of new minute.  Idea is to put ALL the logic for
     // being sure you can TX in O N E spot.
     // Ok - first.  What defines when you can TX?
     // Is TX enabled?
     // Is this minute matching the selected period?
     // Is a valid message in place?
     // Is the callsign and grid info correct for this program's user?
     // If any of that is false answer is false.
     result := False;
     t1 := False;
     t2 := False;
     if toggleTX.Checked Then
     Begin
          // TX is enabled.  Is this a correct minute to TX?
          if Odd(thisUTC.Minute) And rbTXOdd.Checked Then t1 := true else t1 := false;
          if (not Odd(thisUTC.Minute)) And rbTXEven.Checked then t2 := true else t2 := false;
          if t1 or t2 then t1 := true else t1 := false;
          if t1 Then
          Begin
               // Correct minute to TX - check message
               if isStext(edTXMsg.Text) or isFText(edTXMsg.Text) Then t1 := true else t1 := false;
          end;
          if t1 Then
          Begin
               // Message is valid.  Check callsign and grid
               { TODO : Be sure this works as expected }
               t1 := true;
               if not isCallsign(edCall.Text) then
               Begin
                    t1 := False;
               end;
               If Length(edPrefix.Text)> 1 Then
               Begin
                    if not isV1Call(edPrefix.Text + '/' + edCall.Text) then
                    Begin
                         t1 := False;
                    end;
               end;
               If Length(edSuffix.Text)> 1 Then
               Begin
                    if not isV1Call(edCall.Text + '/' + edSuffix.Text) then
                    Begin
                         t1 := False;
                    end;
               end;
               if length(edGrid.Text)> 4 Then foo := edGrid.Text[1..4] else foo := edGrid.Text;
               if not isGrid(foo) then
               Begin
                    t1 := False;
               end;
          end;
     end;
     if txDirty then t1 := False; // Message has not been uploaded to Rebel
     if not txValid then t1 := False; // txValid is set true by mgen when a valid message is in place
     if rigRebel.Checked and (not haveRebel) Then t1 := False; // Can't TX if Rebel isn't here
     result := t1;
end;

procedure TForm1.ListBox1DblClick(Sender: TObject);
Var
  foo,ldate : String;
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
               ldate := IntToStr(thisUTC.Year);
               if thisUTC.Month < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Month) else ldate := ldate + IntToStr(thisUTC.Month);
               if thisUTC.Day < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Day) else ldate := ldate + IntToStr(thisUTC.Day);
               ldate := ldate + ' ';
               if thisUTC.Hour < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Hour) else ldate := ldate + IntToStr(thisUTC.Hour);
               if thisUTC.Minute < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Minute) else ldate := ldate + IntToStr(thisUTC.Minute);
               logTimeOn.Text := ldate;
               if isBreakIn Then Memo2.Append('[TE] ' + response + ' to ' + connectTo + ' [' + fullCall + '] @ ' + hisGrid + ' Proto ' + IntToStr(level) + '[' + sdb + 'dB @ ' + sdf + 'Hz]') else Memo2.Append('[IM] ' + response + ' to ' + connectTo + ' [' + fullCall + '] @ ' + hisGrid + ' Proto ' + IntToStr(level) + '[' + sdb + 'dB @ ' + sdf + 'Hz]');
               logCallsign.Text := fullCall;
               logSigReport.Text := sdb;
               if not TryStrToInt(edDialQRG.Text,i) Then edDialQRG.Text := '0';
               logQRG.Text := FormatFloat('0.0000',(StrToInt(edDialQRG.Text)/1000000.0));
               edTXMsg.Text := response;
               thisTXMsg := response;
               edTXToCall.Text := fullCall;
               edTXReport.Text := sdb;
               if cbTXeqRXDF.Checked Then
               Begin
                    edTXDF.Text := sdf;
                    edRXDF.Text := sdf;
               end
               else
               begin
                    sdf := edTXDF.Text;
               end;

               if isFText(response) or isSText(response) Then
               Begin
                    if not tryStrToInt(sdf,i) then sdf := '0';
                    genTX(response, StrToInt(sdf)+clRebel.txOffset);
                    if txp=0 then rbTxEven.Checked := True else rbTxOdd.Checked := True;
                    if not isBreakin then toggleTX.State := cbChecked else toggleTX.State := cbUnchecked;
                    if not isBreakin then toggleTX.Checked := True else toggleTX.Checked := false;
               end
               else
               begin
                    // This shouldn't happen, but, message is invalid.
                    Memo2.Append('Odd - message did not self resolve.');
                    edTXMsg.Text := '';
                    edTXToCall.Text := '';
                    edTXReport.Text := '';
                    toggleTX.Checked := False;
                    toggleTX.State := cbUnChecked;
               end;
          end
          else
          begin
               Memo2.Append('No message can be generated');
               edTXMsg.Text := '';
               edTXToCall.Text := '';
               edTXReport.Text := '';
               toggleTX.Checked := False;
               toggleTX.State := cbUnChecked;
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
          if IsWordPresent('WARNING:', foo, [' ']) Then
          Begin
               lineWarn := True;
          end
          else if IsWordPresent('Notice:', foo, [' ']) Then
          Begin
               lineWarn := True;
          end
          else
          begin
               lineWarn := False;
          end;

          if (IsWordPresent('CQ', foo, [' '])) or IsWordPresent('QRZ', foo, [' ']) Then lineCQ := True;

          if IsWordPresent(TrimLeft(TrimRight(UpCase(mycall))), foo, [' ']) Then
          Begin
               lineMyCall := True;
          end
          else if IsWordPresent(TrimLeft(TrimRight(UpCase(myscall))), foo, [' ']) Then
          begin
               lineMyCall := True;
          end
          else if ansicontainstext(foo,edCall.Text) then
          begin
               lineMyCall := True;
          end
          else
          begin
               lineMyCall := False;
          end;

          myBrush := TBrush.Create;
          with (Control as TListBox).Canvas do
          begin
               //myColor := cfgvtwo.glqsoColor;
               { TODO : Add back custom color choices }
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
var
   i : Integer;
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

     If Sender = rigNone Then
     Begin
          catMethod := 'None';
          groupRebelOptions.Visible := False;
     end;

     If Sender = rigRebel Then
     Begin
          i := -1;
          if tryStrToInt(edPort.Text,i) and (i > 0) Then
          Begin
               catMethod := 'Rebel';
               if cbUseSerial.Checked Then cbUseSerial.Checked := False;
               groupRebelOptions.Visible := True;
          end
          else
          begin
               catMethod := 'None';
               rigNone.Checked := True;
          end;
     end;

     If Sender = rigCommander Then
     Begin
          catMethod := 'Commander';
          groupRebelOptions.Visible := False;
     end;
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

function  TForm1.messageParser(const ex : String; var nc1t : String; var pfx : String; var sfx : String; var nc2t : String; var ng : String; var sh : String; var proto : String) : Boolean;
Var
   foo   : String;
   i, wc : Integer;
   w     : Array[1..4] of String;
   go    : Boolean;
Begin
     Result := False;
     nc1t   := '';
     pfx    := '';
     sfx    := '';
     nc2t   := '';
     ng     := '';
     sh     := '';
     proto  := '';
     // As usual this has turned into a pit of confusing despair.  Part of it is that I was too close to my brain exploding
     // when I wrote this and I based it on being V2 compliant so now having to back pedal in V1 support.

     // So.  Here's what I need this to do.  V2 support is off the table for now.
     // It needs to return proto = JL if it's a standard no slashed callsigns message or JT if it is.
     // Reason for this - I generate messages for non-slashed with my own code and use JT's in libJT65
     // for the convoluted V1 slashed types.  Basically being lazy but I don't have time (right now)
     // to reinvent and validate that wheel.

     // This returns true if it's a structured message with the fields broken out into nc1t, pfx, sfx, nc2t, ng if (and only
     // if proto = JL

     // ex contains the full message.  Check for presence of slash first.
     if ansicontainstext(ex,'/') Then proto := 'JT' else proto := 'JL';

     // Break this into the words - array w[1..4] where count may be 1, 2, 3 or 4. NOTE the 1 based index!
     for i := 1 to 4 do w[i] := '';
     foo := DelSpace1(TrimLeft(TrimRight(UpCase(ex)))); // Insures there is only one space between words, deletes left/right padding (space) and makes upper case.
     wc  := WordCount(foo,[' ']);
     if (wc > 0) and (wc < 5) Then for i := 1 to wc do w[i] := ExtractWord(i,foo,[' ']) else wc := 0;

     // OK - simplification time!
     // If proto = JT all I care about is that it could be encoded as a structured message using libJT65 encoder
     // If proto = JL all I care about is that it could be encoded as a structured message using my custom encoder
     //
     // For proto = JT this means Word 1 is a call, Word 2 is a call and Word 3 is a control type.  That's IT
     if isSText(foo) and (proto = 'JL') and (wc = 3) Then
     Begin
          if (isCallsign(w[1]) or (w[1]='CQ') or (w[1]='QRZ')) and isCallsign(w[2]) and (isControl(w[3]) or isGrid(w[3])) Then
          Begin
               Result := True;
               nc1t   := w[1];
               pfx    := '';
               sfx    := '';
               nc2t   := w[2];
               ng     := w[3];
               sh     := '';
               proto  := 'JL';
          end
          else
          Begin
               Result := False;
               nc1t   := '';
               pfx    := '';
               sfx    := '';
               nc2t   := '';
               ng     := '';
               sh     := '';
          end;
     End;

     if (proto = 'JT') and (wc=2) Then
     Begin
          // For proto = JT I'm not breaking out the fields - all I care about is proto = JT and result = true.
          Result := False;
          nc1t   := '';
          pfx    := '';
          sfx    := '';
          nc2t   := '';
          ng     := '';
          sh     := '';
          // Working with V1 slashed calls.  I'm only interested in what could be valid structured types here so
          // it has to be a 2 word exchange and contain a slash in the text somewhere.
          proto := 'JT'; // Forces the encoder to use JT65V1 from library for message crunching
          //
          // There is an impossible case - both calls containing slash.  Can't be done.
          //
          go := True; // Sets to false if this set evaluates to a return
          if (ansiContainsText(w[1],'/')) and (ansiContainsText(w[2],'/')) Then
          Begin
               // Can't do it
               go := False;
               Result := False;
          end;

          // CQ Prefix/Call
          // CQ Call/Suffix
          // CQ Call
          // QRZ Prefix/Call
          // QRZ Call/Suffix
          // QRZ Call
          if go and ((w[1]='CQ') or (w[1]='QRZ')) Then
          Begin
               // w[2] MUST be a valid call or prefix/call or call/suffix
               if isV1Call(w[2]) Then
               Begin
                    go := False;
                    result := True;
               end
               else
               begin
                    // Call is not JT65V1 compliant.
                    go := False;
                    result := False;
               end;
          end
          else
          begin
               // Not a CQ, QRZ, DE form - try next eval.
               go := True;
               result := False;
          end;

          // Call Prefix/Call
          // Call Call/Suffix
          // Prefix/Call Call
          // Call/Suffix Call
          // Call Call (Technically invalid but will handle for those that didn't set the flippn' grid
          If go Then
          Begin
               // Didn't evaluate to one of the CQ,QRZ or DE forms
               // Next up is pair of calls
               // Where we must have
               // CALL CALL (stupid but will do)
               // PREFIX/CALL CALL
               // CALL/SUFFIX CALL
               // CALL PREFIX/CALL
               // CALL CALL/SUFFIX
               if isV1Call(w[1]) and isV1Call(w[2]) Then
               Begin
                    go := False;
                    result := True;
               End
               else
               begin
                    // Not a call call type - try next eval.
                    go := True;
                    result := False;
               end;
          end;

          // Call -##
          // Call R-##
          // Call RRR
          // Call 73
          // Prefix/Call 73
          // Call/Suffix 73
          // Call 73
          If go then
          begin
               // Didn't evaluate to one of the CQ or CALL CALL forms
               // Next up is call and control type
               // CALL -##
               // CALL R-##
               // CALL RRR
               // CALL 73
               // PREFIX/CALL -##
               // CALL/SUFFIX -##
               // PREFIX/CALL R-##
               // CALL/SUFFIX R-##
               // PREFIX/CALL RRR
               // CALL/SUFFIX RRR
               // PREFIX/CALL 73
               // CALL/SUFFIX 73
               if isV1Call(w[1]) And isControl(w[2]) Then
               Begin
                    go := False;
                    result := True;
               end
               else
               begin
                    go := True;
                    result := False;
               end;
          end;
     end;
end;

function TForm1.isV1Call(const s : String) : Boolean;
Var
   wa, wb : String;
   i      : Integer;
Begin
     Result := False;
     if ansiContainsText(s,'/') Then
     Begin
          // It's slashed
          // split it to wa and wb
          i := WordCount(s,['/']);
          If i=2 Then
          Begin
               wa := ExtractWord(1,s,['/']);
               wb := ExtractWord(2,s,['/']);
               // Ok - we must have wa = valid prefix and wb = valid call
               // or
               // wa = valid call and wb = valid suffix
               // or (dammit - thanks JT, really... thanks)
               // wa = valid call and wb = 'MM' where MM is actually a prefix value shuffled to suffix position.
               If valV1Prefix(wa) and isCallSign(wb) Then
               Begin
                    Result := True;
               end;
               If isCallSign(wa) and valV1Suffix(wb) Then
               Begin
                    Result := True;
               end;
               if isCallSign(wa) and (wb='MM') Then
               Begin
                    Result := True;
               end;
          end
          else
          begin
               // This means it has more than 1 slash - impossible so bail.
               // This was handled above so should never get here but might
               // as well have a double check as it's important.
               Result := False;
          end;
     end
     else
     begin
          // No slash - validate it
          if isCallsign(s) Then Result := True;
     end;
End;
function TForm1.rebelTuning(const f : Double) : CTypes.cuint;
Begin
     // Takes Hz value and returns DDS tuning word based upon DDS ref frequency
     // being known and DDS type.  For now hard coding ref to 49999750 and ignoring
     // TX offset value.
     // Current DDS is only AD9834 and it uses fWord as integer = fout * 2^28/fref
     // 14076000
     // 14076000 + 718 * (2^28/49999750) = 14076718 * 5.3687359636798183990919954599773 = 75574182.177179045895229476147381 = 75574182
     result := Round(f * (268435456.0/49999750.0));
end;

procedure TForm1.genTX(const msg : String; const txdf : Integer);
Var
   foo, sh       : String;
   form, proto   : String;
   i,j,k,dir,cnt : CTypes.cint;
   nc1,nc2,ng    : LongWord;
   ng1           : LongWord;
   nc1t,nc2t,ngt : String;
   pfxt,sfxt     : String;
   syms          : Array[0..11] Of CTypes.cint;
   tsyms         : Array[0..62] Of CTypes.cint;
   //itone9        : Array[0..84] Of CTypes.cint;
   //itone9fsk     : Array[0..84] Of CTypes.cdouble;
   //itone9dds     : Array[0..84] Of CTypes.cuint;
   sm, ft, doit  : Boolean;
   baseTX        : CTypes.cdouble;
   //maxf,minf,bw  : CTypes.cdouble;
begin
     // Validate the message for proper content BEFORE calling this
     txValid := False;
     nc1t := '';
     pfxt := '';
     sfxt := '';
     nc2t := '';
     ngt  := '';
     sh   := '';
     proto:= ''; // Proto is to handle if I call my own (JL) encoder or use JT's (JT)
     sm   := False; // Structured message type
     ft   := False; // Free text message type
     doit := False;
     foo := TrimLeft(TrimRight(UpCase(msg)));
     if messageParser(foo, nc1t, pfxt, sfxt, nc2t, ngt, sh, proto) Then
     Begin
          sm := True;
          sh := '';
     end
     else
     begin
          If Length(foo) > 13 Then foo := foo[1..13];
          if isFText(foo) Then
          Begin
               ft := True;
          end;
     end;

//     strpcopy(jtencode,PadRight(foo,22));
//     jtdecode := '                                ';
//     for i := 0 to length(itone9)-1 do
//     begin
//          itone9[i] := 0;
//          itone9fsk[i] := 0.0;
//          itone9dds[i] := 0;
//     end;
//
//     i := 0;
//     j := 0;
//     genjt9(jtencode,@i,jtdecode,@itone9[0],@j);
//     foo := StrPas(jtdecode);
//
//     for i := 0 to length(itone9)-1 do itone9fsk[i] := ((itone9[i] * 1.736) + 2270.0) + 14076000.0;
//
//     maxf := -1.0e30;
//     minf := 1.0e30;
//     bw   := 0.0;
//
//     for i := 0 to length(itone9fsk)-1 do
//     begin
//          if itone9fsk[i] > maxf then maxf := itone9fsk[i];
//          if itone9fsk[i] < minf then minf := itone9fsk[i];
//     end;
//     bw := maxf-minf;
//
//     for i := 0 to length(itone9fsk)-1 do itone9dds[i] := rebelTuning(itone9fsk[i]);
//     for i := 0 to length(itone9fsk)-1 do
//     begin
//          if itone9fsk[i] > maxf then maxf := itone9fsk[i];
//          if itone9fsk[i] < minf then minf := itone9fsk[i];
//     end;

     // One last check for proto.  This will force it to use libJT65 message generator if
     // there's a slash in the string and it wasn't set to JT proto.  Maybe not, again, one
     // of my better ideas... but for now it stands.
     if sm and (ansicontainstext(foo,'/')) and (not (proto='JT')) Then proto := 'JT';

     // If sm this is a structured message
     if sm then
     begin
          doit := False;
          if proto = 'JT' Then
          Begin
               // It's a slashed call form so use the tried and true V1 encoder from libJT65
               strpcopy(jtencode,PadRight(foo,22));
               for i := 0 to 11 do syms[i] := 0;
               for i := 0 to 62 do tsyms[i] := 0;
               packmsg(jtencode,CTypes.pcint(@syms[0]));
               rscode(CTypes.pcint(@syms[0]),CTypes.pcint(@tsyms[0]));
               dir := 1;
               interleave(CTypes.pcint(@tsyms[0]),CTypes.pcint(@dir));
               dir := 1;
               cnt := 63;
               graycode(CTypes.pcint(@tsyms[0]),CTypes.pcint(@cnt),CTypes.pcint(@dir));
               doit := True; // Make the FSK generator run :)
          end
          else
          begin
               // Use local code encoder and by my current rule set there will be no slashed calls here
               nc1 := 0;
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

               nc2 := 0;
               nc2 := gCall(nc2t);

               ng  := 0;
               ng1 := 0;
               gGrid(ngt,ng1);
               ng  := ng1; // Why do I do this?

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
                    doit := true;
               End;
          end;
     end;

     //If ft this is free text
     if ft then
     begin
          doit := False;
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
               doit := True;
          end;
     end;
     // Generate FSK values
     if doit and haveRebel Then
     Begin
          // tsyms holds the 63 TX symbols - will need to look at TXDF and current dial
          // RX QRG to compute the true RF TX QRG list.  TXDF 0 = 1270.5 Hz so if dial
          // is 14076.0 and TXDF = 0 then first tone (sync) will be at 14,077,270.5 Hz
          // Then call rebelTuning(double f in hz) to get back an UINT32 tuning word
          // for the AD9834.
          //isyms         : Array[0..62] Of CTypes.cint;
          //ssyms         : Array[0..62] Of String;
          // So.... tone 0 (sync) = Dial QRG + 1270.5 + TXDF
          baseTX   := 1270.5;
          if not tryStrToInt(edDialQRG.Text,i) Then edDialQRG.Text := '0';
          baseTX   := baseTX + StrToInt(edDialQRG.Text) + txdf;  // This is the floating point value in Hz of the sync carrier (base frequency - data goes up from this)
          k := rebelTuning(baseTX); // Base sync tone as RF tuning word
          // For this we clear the whole 128 and it's 128 because of way I pass FSK values to Rebel - it only uses 126 :)
          for i := 0 to 127 do qrgset[i] := '0';
          j := 0;
          // Two passes - stuff sync then stuff data.
          // Once I debug and am sure can try rolling it into one pass.
          // Stuff the values - sync where SYNC65[i]=1 data where SYNC65[i]=0;
          // NOTE for this it's 125 on qrgset - DONT'T bork this and do 127 :)
          for i := 0 to 125 do if SYNC65[i]=1 Then qrgset[i] := IntToStr(k);
          for i := 0 to 125 do
          begin
               if SYNC65[i]=0 Then
               Begin
                    qrgset[i] := IntToStr(rebelTuning(baseTX + (2.6917 * (tsyms[j]+2))));
                    inc(j); // Not to self - yes it generates nice 2 tone FSK if you leave this line out.
               end;
          end;
          txDirty := True;  // Flag to force an update to the FSK TX
          txValid := True;
          mgendf := IntToStr(txdf-clRebel.txOffset);
          if edTXDF.Text <> mgendf Then edTXDF.Text := mgendf;
          Memo2.Append('Msg: ' + TrimLeft(TrimRight(foo)) + ' DF ' + edTXDF.Text + ' ' + FormatFloat('########.##',baseTX-clRebel.txOffset) + ' Hz');

     end;
end;

function TForm1.genSigRep(var s : String) : Boolean;
Var
   i : Integer;
Begin
     result := False;
     if tryStrToInt(s,i) Then
     Begin
          // It has to be < 0
          if i < 0 then
          Begin
               if i > -10 Then
               begin
                    // Double check it has leading 0
                    s := '-0' + IntToStr(abs(i));
               end;
          end
          else
          begin
               s := '-01';
          end;
          Result := True;
     end
     else
     begin
          Result := False;
          s := '';
     end;
end;

procedure TForm1.mgenClick(Sender: TObject);
Var
   foo : String;
   i   : Integer;
begin
     lastTXMsg := '';
     sameTXCount := 0;
     thisTXmsg := '';
     foo := edTXReport.Text;

     if not isV1Call(myscall) Then
     Begin
          ShowMessage('Setup your Call to a valid setting.');
          thisTXMsg := '';
          edTXMsg.Text :='';
     end
     else if not isGrid(getLocalGrid) Then
     Begin
          ShowMessage('Setup your Grid to a valid setting.');
          thisTXMsg := '';
          edTXMsg.Text :='';
     end
     else
     begin
          if Sender = bCQ Then
          Begin
               if isSlashedCall(myscall) Then thisTXmsg := 'CQ ' + thisTXCall else thisTXmsg := 'CQ ' + thisTXCall + ' ' + getLocalGrid;
               edTXMsg.Text := thisTXmsg;
               // Not sure this is best idea... but when calling CQ one should not move.
               cbTXeqRXDF.Checked := False;
               edRXDF.Text := edTXDF.Text;
          end;

          if Sender = bQRZ Then
          Begin
               if isSlashedCall(myscall) Then thisTXmsg := 'QRZ ' + thisTXCall else thisTXmsg := 'QRZ ' + thisTXCall + ' ' + getLocalGrid;
               edTXMsg.Text := thisTXmsg;
               // Not sure this is best idea... but when calling CQ/QRZ one should not move.
               cbTXeqRXDF.Checked := False;
               edRXDF.Text := edTXDF.Text;
          end;

          if Sender = bACQ Then
          Begin
               if isSlashedCall(edTXtoCall.Text) or isSlashedCall(myscall) Then
               Begin
                    // Working with V1 slashed
                    // A locally slashed call can't send its slashed call to another slashed call
                    if isSlashedCall(edTXtoCall.Text) And isSlashedCall(myscall) Then
                    Begin
                         ListBox1.Items.Insert(0,'Notice: both calls to have /');
                         ListBox1.Items.Insert(0,'Notice: JT65V1 does not allow');
                         thisTXMsg := '';
                         edTXMSg.Text := '';
                    end
                    else
                    begin
                         if isV1Call(edTXToCall.Text) Then
                         Begin
                              thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(myscall)));
                              edTXMsg.Text := thisTXmsg;
                         end
                         else
                         begin
                              ListBox1.Items.Insert(0,'Notice: TX to Call does not compute');
                              thisTXmsg := '';
                              edTXMsg.Text := '';
                         end;
                    end;
               end
               else
               begin
                    // No slashes here
                    if isV1Call(edTXToCall.Text) Then
                    begin
                         thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' ' + getLocalGrid;
                         edTXMsg.Text := thisTXmsg;
                    end
                    else
                    begin
                         thisTXmsg := '';
                         edTXMsg.Text := '';
                         ListBox1.Items.Insert(0,'Notice: TX to Call does not compute');
                    end;
               end;
          end;

          if Sender = bReport Then
          Begin
               // For this one if the remote call is slashed then it's easy mode as I'm not sending the local call to begin with
               // so none of the worry introduced in answering a CQ method for slashed.
               foo := edTXReport.Text;
               if not genSigRep(foo) Then
               begin
                    thisTXmsg := '';
                    edTXMsg.Text := '';
                    ListBox1.Items.Insert(0,'Notice: Signal report does not compute');
               end
               else
               begin
                    edTXReport.Text := foo;  // This set signal report to properly formatted value
                    if isSlashedCall(edTXtoCall.Text) or isSlashedCall(myscall) Then
                    Begin
                         if isV1Call(edTXToCall.Text) Then
                         begin
                              thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(edTXReport.Text)));
                              edTXMsg.Text := thisTXmsg;
                         end
                         else
                         begin
                              thisTXmsg := '';
                              edTXMsg.Text := '';
                              ListBox1.Items.Insert(0,'Notice: TX to Call does not compute');
                         end;
                    end
                    else
                    begin
                         // No slashes here
                         if isV1Call(edTXToCall.Text) Then
                         begin
                              thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' ' + TrimLeft(TrimRight(UpCase(edTXReport.Text)));
                              edTXMsg.Text := thisTXmsg;
                         end
                         else
                         begin
                              thisTXmsg := '';
                              edTXMsg.Text := '';
                              ListBox1.Items.Insert(0,'Notice: TX to Call does not compute');
                         end;
                    end;
               end;
          end;

          if Sender = bRReport Then
          Begin
               foo := edTXReport.Text;
               if not genSigRep(foo) Then
               begin
                    thisTXmsg := '';
                    edTXMsg.Text := '';
                    ListBox1.Items.Insert(0,'Notice: Signal report does not compute');
               end
               else
               begin
                    edTXReport.Text := foo;  // This set signal report to properly formatted value
                    if isSlashedCall(edTXtoCall.Text) or isSlashedCall(myscall) Then
                    Begin
                         if isV1Call(edTXToCall.Text) Then
                         begin
                              thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' R' + TrimLeft(TrimRight(UpCase(edTXReport.Text)));
                              edTXMsg.Text := thisTXmsg;
                         end
                         else
                         begin
                              thisTXmsg := '';
                              edTXMsg.Text := '';
                              ListBox1.Items.Insert(0,'Notice: TX to Call does not compute');
                         end;
                    end
                    else
                    begin
                         // No slash here
                         if isV1Call(edTXToCall.Text) Then
                         begin
                              thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' R' + TrimLeft(TrimRight(UpCase(edTXReport.Text)));
                              edTXMsg.Text := thisTXmsg;
                         end
                         else
                         begin
                              thisTXmsg := '';
                              edTXMsg.Text := '';
                              ListBox1.Items.Insert(0,'Notice: TX to Call does not compute');
                         end;
                    end;
               end;
          end;

          if Sender = bRRR Then
          Begin
               if isSlashedCall(edTXtoCall.Text) or isSlashedCall(myscall) Then
               Begin
                    if isV1Call(edTXToCall.Text) Then
                    begin
                         thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' RRR';
                         edTXMsg.Text := thisTXmsg;
                    end
                    else
                    begin
                         thisTXmsg := '';
                         edTXMsg.Text := '';
                         ListBox1.Items.Insert(0,'Notice: TX to Call does not compute');
                    end;
               end
               else
               begin
                    // No slash here
                    if isV1Call(edTXToCall.Text) Then
                    begin
                         thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(edCall.Text))) + ' RRR';
                         edTXMsg.Text := thisTXmsg;
                    end
                    else
                    begin
                         thisTXmsg := '';
                         edTXMsg.Text := '';
                         ListBox1.Items.Insert(0,'Notice: TX to Call does not compute');
                    end;
               end;
          end;

          if Sender = b73 Then
          Begin
               if isSlashedCall(edTXtoCall.Text) or isSlashedCall(myscall) Then
               Begin
                    // Trying something cute here
                    if Length('DE ' + TrimLeft(TrimRight(UpCase(myscall))) + ' 73') < 14 Then
                    Begin
                         thisTXmsg := 'DE ' + TrimLeft(TrimRight(UpCase(myscall))) + ' 73';  // This is a *CHANGE* from former way where it was HISCALL 73
                    end
                    else
                    begin
                         thisTXmsg := TrimLeft(TrimRight(UpCase(myscall))) + ' 73';  // This is a *CHANGE* from former way where it was HISCALL 73
                    end;
                    edTXMsg.Text := thisTXmsg;
               end
               else
               begin
                    // No slash here
                    if isV1Call(edTXToCall.Text) Then
                    begin
                         thisTXmsg := TrimLeft(TrimRight(UpCase(edTXtoCall.Text))) + ' ' + TrimLeft(TrimRight(UpCase(myscall))) + ' 73';
                         edTXMsg.Text := thisTXmsg;
                    end
                    else
                    begin
                         thisTXmsg := '';
                         edTXMsg.Text := '';
                         ListBox1.Items.Insert(0,'Notice: TX to Call does not compute');
                    end;
               end;
               //if rbCWID73.Checked Then doCWID := True else doCWID := False;
          end;
          // Final QC check
          if length(thisTXmsg)>1 Then
          Begin
               if (isFText(thisTXmsg) or isSText(thisTXmsg)) and tryStrToInt(edTXDF.Text,i) Then genTX(thisTXmsg, StrToInt(edTXDF.Text)+clRebel.txOffset) else thisTXmsg := '';
               edTXMsg.Text := thisTXmsg; // this double checks for valid message.
               if thisTXMsg = '' Then ShowMessage('Error.. odd... no message from a button?  Please tell W6CQZ');
          end;
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

procedure TForm1.edRXDFChange(Sender: TObject);
begin
     //if cbTXeqRXDF.Checked Then edTXDF.Text := edRXDF.Text;
end;

procedure TForm1.edRXDFDblClick(Sender: TObject);
begin
     edRXDF.Text := '0';
end;

procedure TForm1.edTXDFChange(Sender: TObject);
Var
   i : Integer;
begin
     // Need to (maybe) regenerate message
     i := 0;
     if tryStrToInt(edTXDF.Text,i) Then
     Begin
          if (i > 1050) or (i < -1050) Then
          Begin
               if i > 1050 Then i := 1050;
               if i < -1050 Then i := -1050;
               edTXDF.Text := IntToStr(i); // Hopefully this doesn't create a loop....
               edTXMsg.Text := '';
               thisTXMsg := '';
          end
          else
          begin
               if isFText(edTXMsg.Text) or isSText(edTXMsg.Text) Then
               Begin
                    thisTXMsg := edTXMsg.Text;
                    //genTX(thisTXmsg, i+clRebel.txOffset);
                    edTXMsg.Text := thisTXmsg; // this double checks for valid message.
               end;
          end;
     end;
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
Var
   sock      : TTCPBLockSocket;
   cmd,parm  : String;
   dt,tm     : String;
   foo,ldate : String;
   wc        : Integer;
   fname     : String;
   lfile     : TextFile;
begin

     if sender = logClearComments Then logComments.Text := '';

     if sender = logClearCancel Then
     Begin
          // Clear all fields and dismiss
          logCallSign.Text := '';
          logQRG.Text := '';
          logGrid.Text := '';
          logTimeOn.Text := '';
          logTimeOff.Text := '';
          logSigReport.Text := '';
          logMySig.Text := '';
          Waterfall.Visible   := True;
          PaintBox1.Visible    := True;
          buttonConfig.Visible := True;
          PageControl.Visible  := False;
          groupLogQSO.visible  := False;
     end;
     if sender = logCancel Then
     Begin
          // Just dismiss but don't clear fields
          Waterfall.Visible   := True;
          PaintBox1.Visible    := True;
          buttonConfig.Visible := True;
          PageControl.Visible  := False;
          groupLogQSO.visible  := False;
     end;
     if sender = logEndTime Then
     Begin
          // Set QSO end time to now
          ldate := IntToStr(thisUTC.Year);
          if thisUTC.Month < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Month) else ldate := ldate + IntToStr(thisUTC.Month);
          if thisUTC.Day < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Day) else ldate := ldate + IntToStr(thisUTC.Day);
          ldate := ldate + ' ';
          if thisUTC.Hour < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Hour) else ldate := ldate + IntToStr(thisUTC.Hour);
          if thisUTC.Minute < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Minute) else ldate := ldate + IntToStr(thisUTC.Minute);
          logTimeOff.Text := ldate;
     end;
     // Do logging
     if (sender = logDXLab) or (sender = logQSO) or (sender = logEQSL) Then
     Begin
          // Build the ADIF string for direct DX Keeper or file logging.
          parm := '<CALL:' + IntToStr(Length(logCallSign.Text)) + '>' + UpCase(logCallSign.Text);
          parm := parm + '<RST_SENT:' + IntToStr(Length(logSigReport.Text)) + '>' + logSigReport.Text;
          parm := parm + '<RST_RCVD:' + IntToStr(Length(logMySig.Text)) + '>' + logMySig.Text;
          parm := parm + '<FREQ:' + IntToStr(Length(logQRG.Text)) +'>' + logQRG.Text;
          if (length(logGrid.Text)=4) or (length(logGrid.Text)=6) Then
          Begin
               // <GRIDSQUARE:#>
               parm := parm + '<GRIDSQUARE:' + IntToStr(Length(logGrid.Text)) + '>' + logGrid.Text;
          end;
          if length(logPower.text) > 0 Then
          Begin
               // <TX_PWR:#> logPower.text
               parm := parm + '<TX_PWR:' + IntToStr(Length(logPower.Text)) + '>' + logPower.Text;
          end;
          if length(logComments.Text) > 0 Then
          Begin
               // <COMMENT:#>
               parm := parm + '<COMMENT:' + IntToStr(Length(logComments.Text)) + '>' + logComments.Text;
          end;
          foo := DelSpace1(TrimLeft(TrimRight(UpCase(logQRG.Text)))); // Insures there is only one space between words, deletes left/right padding (space) and makes upper case.
          wc  := WordCount(foo,['.',',']);
          if wc=2 Then
          Begin
               dt := ExtractWord(1,foo,['.',',']);
               tm := ExtractWord(2,foo,['.',',']);
               if dt='1' Then foo := '160M';
               if dt='3' Then foo := '80M';
               if dt='7' Then foo := '40M';
               if dt='10' Then foo := '30M';
               if dt='14' Then foo := '20M';
               if dt='18' Then foo := '17M';
               if dt='21' Then foo := '15M';
               if dt='24' Then foo := '12M';
               if dt='28' Then foo := '10M';
               if dt='50' Then foo := '6M';
               if dt='144' Then foo := '2M';
               parm := parm + '<BAND:' + IntToStr(Length(foo)) + '>' + foo;
          end;
          parm := parm + '<MODE:4>JT65';  // OK as hardcoded for now but not later :)
          foo := DelSpace1(TrimLeft(TrimRight(UpCase(logTimeOn.Text)))); // Insures there is only one space between words, deletes left/right padding (space) and makes upper case.
          wc  := WordCount(foo,[' ']);
          dt := ExtractWord(1,foo,[' ']);
          tm := ExtractWord(2,foo,[' ']);
          parm := parm + '<QSO_DATE:' + IntToStr(Length(dt)) + '>' + dt;
          parm := parm + '<TIME_ON:' + IntToStr(Length(tm)) + '>' + tm;
          if length(logTimeOff.Text)= 13 Then
          Begin
               foo := DelSpace1(TrimLeft(TrimRight(UpCase(logTimeOff.Text)))); // Insures there is only one space between words, deletes left/right padding (space) and makes upper case.
               wc  := WordCount(foo,[' ']);
               dt := ExtractWord(1,foo,[' ']);
               tm := ExtractWord(2,foo,[' ']);
               parm := parm + '<TIME_OFF:' + IntToStr(Length(tm)) + '>' + tm;
          end;
          parm := parm + '<EOR>';

          if sender = logDXLab Then
          Begin
               try
                  // Direct TCP log to DX Keeper \0/!
                  // For this I need to create a socket - connect to DX Keeper at
                  // 127.0.0.1 port 52001
                  sock := TTCPBlockSocket.Create;
                  sock.Connect('127.0.0.1','52001');
                  //if sender = logEQSL then cmd  := 'EQSLLOG' else cmd := 'LOG';
                  cmd := 'LOG';
                  sock.SendString('<command:'+IntToStr(length(cmd))+'>' + cmd + '<parameters:' + IntToStr(length(parm)) + '>' + parm);
                  sock.CloseSocket;
                  sock.Destroy;
               except
                  // Should show a message that this failed, but it is saved to the ADIF file so it's not a total loss.
               end;
          end;

          // If this was a DX Keeper log it's been done - now push the ADIF string to flat file
          // This gives a fallback in case DX Keeper barfs or if DX Keeper not in play does all
          // needing to be done.
          // ADIF Path is defined in edADIFPath file name is hfwst_log.adif
          try
             fname := edADIFPath.Text + PathDelim + 'hfwst_log.adif';
             // Parm has the ADIF string
             if fileExists(fname) Then
             Begin
                  // Need to open and append
                  AssignFile(lfile, fname);
                  Append(lFile);
                  writeln(lfile,parm);
                  closeFile(lfile);
             end
             else
             begin
                  // Need to create and add
                  AssignFile(lfile, fname);
                  rewrite(lfile);
                  writeln(lfile,'HFWST ADIF Export');
                  writeln(lfile,'<eoh>');
                  writeln(lfile,parm);
                  closeFile(lfile);
             end;
          except
             { TODO : Do something about this }
          end;

          logCallSign.Text := '';
          logQRG.Text := '';
          logGrid.Text := '';
          logTimeOn.Text := '';
          logTimeOff.Text := '';
          logSigReport.Text := '';
          logMySig.Text := '';
          if not cbRememberComments.Checked then logComments.Text := '';
          Waterfall.Visible   := True;
          PaintBox1.Visible    := True;
          buttonConfig.Visible := True;
          PageControl.Visible  := False;
          groupLogQSO.visible  := False;
     end;
end;

procedure TForm1.Memo2DblClick(Sender: TObject);
begin
     memo2.Clear;
end;

procedure TForm1.btnClearDecodesClick(Sender: TObject);
begin
     ListBox1.Clear;
end;

procedure TForm1.audioChange(Sender: TObject);
Var
   foo       : String;
   paResult  : TPaError;
   iadcText  : String;
begin
     // Handle change to and saving of audio device setting
     If Sender = comboAudioIn Then
     Begin
          // Audio Input device change.  Set PA to new device and update DB
          ListBox2.Items.Insert(0,'Changing PortAudio input device');
          foo := comboAudioIn.Items.Strings[comboAudioIn.ItemIndex];
          if foo[1] = '0' Then iadcText := foo[2] else iadcText := foo[1..2];
          portAudio.Pa_AbortStream(paInStream);
          portAudio.Pa_CloseStream(paInStream);
          ListBox2.Items.Insert(0,'Closed former stream');
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
          // Attempt to open selected devices, both must pass open/start to continue.
          // Initialize RX stream.
          paResult := portaudio.Pa_OpenStream(PPaStream(paInStream),PPaStreamParameters(ppaInParams),PPaStreamParameters(Nil),CTypes.cdouble(11025.0),CTypes.culong(2048),TPaStreamFlags(0),PPaStreamCallback(@adc.adcCallback),Pointer(Self));
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
     end;

end;

procedure TForm1.bnSaveMacroClick(Sender: TObject);
Var
   foo : String;
   i   : Integer;
begin
     // Saves text in free form slot and reloads macros
     // Validate content then save
     i := comboMacroList.ItemIndex;
     if comboMacroList.ItemIndex = -1 Then
     Begin
          foo := comboMacroList.Text;
          If Length(foo)>13 Then foo := foo[1..13];
          ComboMacroList.Text := foo;
          if isFText(comboMacroList.Text) or isSText(comboMacroList.Text) Then
          Begin
               transaction.EndTransaction;
               transaction.StartTransaction;
               query.SQL.Clear;
               query.SQL.Text := 'INSERT INTO macro(instance, text) VALUES(:INSTANCE,:TEXT);';
               // Defining the 3 shorthand types.
               query.Params.ParamByName('INSTANCE').AsInteger := instance;
               query.Params.ParamByName('TEXT').AsString := foo;
               query.ExecSQL;
               transaction.Commit;
               transaction.EndTransaction;
               query.Active:=False;
               query.SQL.Clear;
          end;
          // Populate Macro list
          comboMacroList.Clear;
          query.SQL.Clear;
          query.SQL.Add('SELECT text FROM macro WHERE instance = ' + IntToStr(instance) + ';');
          query.Active := True;
          comboMacroList.Items.Add('');
          if query.RecordCount > 0 Then
          Begin
               query.First;
               for i := 0 to query.RecordCount-1 do
               begin
                    comboMacroList.Items.Add(query.Fields[0].AsString);
                    query.Next;
               end;
          end;
          comboMacroList.ItemIndex := 0;
          query.Active := False;
          ComboMacroList.Text := foo;
     end;
end;

procedure TForm1.cbMultiOnChange(Sender: TObject);
begin
     if cbMultiOn.Checked Then edRXDF.Text := '0' else edRXDF.Text := edTXDF.Text;
end;

procedure TForm1.Chart1DblClick(Sender: TObject);
begin
     Chart4BarSeries1.Clear;
     Chart1LineSeries1.Clear;
     Chart2LineSeries1.Clear;
     Chart2LineSeries2.Clear;
     Chart2LineSeries3.clear;
     Chart3LineSeries1.Clear;
     Chart3LineSeries2.Clear;
     Chart3LineSeries3.Clear;
     d65.dmPlotCount := 0;
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
     if comboMacroList.ItemIndex > 0 Then
     Begin
          comboMacroList.ReadOnly := True;
          bnSaveMacro.Visible := False;
     end
     else
     begin
          comboMacroList.ReadOnly := False;
          bnSaveMacro.Visible := True;
     end;
end;

procedure TForm1.doLogQSOClick(Sender: TObject);
Var
   ldate : String;
begin
     ldate := IntToStr(thisUTC.Year);
     if thisUTC.Month < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Month) else ldate := ldate + IntToStr(thisUTC.Month);
     if thisUTC.Day < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Day) else ldate := ldate + IntToStr(thisUTC.Day);
     ldate := ldate + ' ';
     if thisUTC.Hour < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Hour) else ldate := ldate + IntToStr(thisUTC.Hour);
     if thisUTC.Minute < 10 then ldate := ldate + '0' + IntToStr(thisUTC.Minute) else ldate := ldate + IntToStr(thisUTC.Minute);
     logTimeOff.Text := ldate;
     Waterfall.Visible   := False;
     PaintBox1.Visible    := False;
     buttonConfig.Visible := False;
     PageControl.Visible  := False;
     groupLogQSO.visible  := True;
end;

procedure TForm1.buttonXferMacroClick(Sender: TObject);
Var
   foo : String;
   i   : Integer;
begin
     // Transfers contents of Macro buffer to TX Message buffer
     //function TForm1.isFText(c : String) : Boolean;
     //function TForm1.isSText(c : String) : Boolean;
     foo := comboMacroList.Text;

     if length(foo)>13 Then foo := foo[1..13];
     comboMacroList.Text := foo;

     if isFText(comboMacroList.Text) or isSText(comboMacroList.Text) Then
     Begin
          thisTXMsg := comboMacroList.Text;
          if (isFText(thisTXmsg) or isSText(thisTXmsg)) and tryStrToInt(edTXDF.Text,i) Then genTX(thisTXmsg, StrToInt(edTXDF.Text)+clRebel.txOffset) else thisTXmsg := '';
          edTXMsg.Text := thisTXmsg; // this double checks for valid message.
          //if rbCWIDFree.Checked Then doCWID := True else doCWID := False;
     end;
end;

procedure TForm1.cbNZLPFChange(Sender: TObject);
begin
     d65.glnz := cbNZLPF.Checked;
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
     end;

end;

procedure TForm1.buttonConfigClick(Sender: TObject);
begin
     Waterfall.Visible   := False;
     PaintBox1.Visible    := False;
     buttonConfig.Visible := False;
     Button4.Visible      := True;
     PageControl.Visible  := True;
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

     //if canTX Then ListBox2.Items.Insert(0,'After config save CAN transmit') else ListBox2.Items.Insert(0,'After config save CAN NOT transmit.');

     Waterfall.Visible   := True;
     PaintBox1.Visible    := True;
     buttonConfig.Visible := True;
     Button4.Visible      := False;
     PageControl.Visible  := False;
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
begin
     Timer1.Enabled := False;
     if CloseAction = caFree Then
     Begin
          updateDB;
          portAudio.Pa_AbortStream(paInStream);
          portaudio.Pa_Terminate();
          rbThread.Terminate;
          if not rbThread.FreeOnTerminate Then rbThread.Free;
          decoderThread.Terminate;
          if not decoderThread.FreeOnTerminate Then decoderThread.Free;
          if clRebel.txStat Then clRebel.pttOff;
          clRebel.destroy;
     end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
     { TODO : Need to eventually get instance from commnad line }
     instance   := 1; // Range 1..4
     srun       := 0.0;
     lrun       := 0.0;
     d65.dmarun := 0.0;
     mval        := valobject.TValidator.create();
     Label1.Caption := 'TX Level:  100%';
     firstPass   := True;
     inSync      := False;
     paActive    := False;
     firstTick   := True;
     thisUTC     := utcTime;
     thisSecond  := thisUTC.Second;
     lastSecond  := 0;
     newMinute   := False;
     newSecond   := False;
     rbping      := False;
     rbposted    := 0;
     runDecode   := False;
     decodeping  := 0;
     decoderBusy := False;
     qrgValid    := False;
     jtencode    := SysUtils.StrAlloc(32);
     jtdecode    := SysUtils.StrAlloc(32);
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
          sleep(1000);
     end;
end;

procedure decodeThread.Execute;
Var
   //rxf : Packed Array of CTypes.cfloat;
   i   : Integer;
begin
     while not Terminated and not Suspended and not decoderBusy do
     begin
          if runDecode then
          Begin
               decoderBusy := True;
               i := 0;
               while adc.adcRunning do
               begin
                    inc(i);
                    if i > 25 then break;
                    sleep(1);
               end;
               d65.doDecode(0,524287);
               inc(decodeping);
               runDecode := False;
               decoderBusy := False;
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

procedure TForm1.WaterFallMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
Var
   df : Single;
begin
     if x = 0 then df := -1019;
     if x > 0 Then df := X*2.7027;
     df := -1018.9189 + df;

     if Button = mbLeft Then
     Begin
          edTXDF.Text := IntToStr(round(df));
          if cbTXeqRXDF.Checked Then edRXDF.Text := edTXDF.Text;
     End;

     if Button = mbRight Then
     Begin
          edRXDF.Text := IntToStr(round(df));
          if cbTXeqRXDF.Checked Then edTXDF.Text := edRXDF.Text;
     End;

end;

function TForm1.utcTime: TSystemTime;
Begin
     result.Day := 0;
     GetSystemTime(result);
end;

function TForm1.lateTXOffset : Integer;
Var
   msoff : Integer;
   msidx : Double;
Begin
     result := 0;
     // I need to look at current second and millisecond getting as close to current
     // symbol that would be transmitting had I started on time.
     msoff := ((ThisUTC.Second * 1000) + ThisUTC.Millisecond)-1000;  // Remember we start at second = 1 thus -1000
     if msoff > 15000 then
     begin
          result := -1;
     end
     else
     begin
          // OK a JT65 symbol is 371.5 ms long so lets figure this puppy out.
          msidx  := msoff/371.5;
          msoff  := round(msidx);
          result := msoff;
     end;

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

function TForm1.t(const s : string) : String;
Begin
     result := TrimLeft(TrimRight(s));
end;

function TForm1.valV1Prefix(const s : string) : Boolean;
Var
   i : Integer;
Begin
     result := False;
     for i := 0 to length(V1PREFIX)-1 do
     begin
          if V1PREFIX[i]=TrimLeft(TrimRight(UpCase(s))) Then
          begin
               result := true;
               break;
          end;
     end;
end;

function TForm1.valV1Suffix(const s : string) : Boolean;
Var
   i : Integer;
Begin
     result := False;
     for i := 0 to length(V1SUFFIX)-1 do
     begin
          if V1SUFFIX[i]=TrimLeft(TrimRight(UpCase(s))) Then
          begin
               result := true;
               break;
          end;
     end;
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
     foo := foo + 'multion=:MON,txeqrxdf=:TXEQRX,needcfg=:NEEDCFG,rebrxoffset=:RXOFFSET,rebtxoffset=:TXOFFSET,';
     foo := foo + 'rebrxoffset40=:RXOFFSET40,rebtxoffset40=:TXOFFSET40 WHERE instance=:INSTANCE';

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
     Query.Params.ParamByName('TXLEVEL').AsInteger    := 16;
     If not TryStrToInt(t(version.Text),i) then i := -1;
     Query.Params.ParamByName('VER').AsInteger    := i;
     Query.Params.ParamByName('MON').AsBoolean    := cbMultiOn.Checked;
     Query.Params.ParamByName('TXEQRX').AsBoolean := cbTXEqRXDF.Checked;
     Query.Params.ParamByName('NEEDCFG').AsBoolean := False;
     Query.Params.ParamByName('INSTANCE').AsInteger := instance;
     Query.Params.ParamByName('RXOFFSET').AsString := t(edRebRXOffset.Text);
     Query.Params.ParamByName('TXOFFSET').AsString := t(edRebTXOffset.Text);
     Query.Params.ParamByName('RXOFFSET40').AsString := t(edRebRXOffset40.Text);
     Query.Params.ParamByName('TXOFFSET40').AsString := t(edRebTXOffset40.Text);
     transaction.StartTransaction;
     query.ExecSQL;
     transaction.Commit;
     transaction.Active:=False;
     query.Active:=False;
end;

procedure TForm1.setupDB(const cfgPath : String);
Var
   foo : String;
Begin
     sqlite3.DatabaseName := cfgPath + 'hfwstJ' + IntToStr(instance);
     query.SQL.Clear;
     query.SQL.Add('CREATE TABLE ngdb(id integer primary key, xlate string(5))');
     query.ExecSQL;
     transaction.Commit;
     // QRG Definitions
     query.SQL.Clear;
     query.SQL.Add('CREATE TABLE qrg(id integer primary key, instance integer, fqrg float)');
     query.ExecSQL;
     query.SQL.Clear;
     query.SQL.Text := 'INSERT INTO qrg(instance, fqrg) VALUES(:INSTANCE,:QRG);';
     query.Params.ParamByName('INSTANCE').AsInteger := instance;
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
     query.Params.ParamByName('QRG').AsFloat := 10147000.0;
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
     foo := foo + 'multion bool, txeqrxdf bool, needcfg bool, rebrxoffset string, rebtxoffset string, rebrxoffset40 string, ';
     foo := foo + 'rebtxoffset40 string)';
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
     rbRebBaud115200.Checked:=True;
     edRebRXOffset.Text:='700';
     edRebTXOffset.Text:='0';
     edRebRXOffset40.Text:='-700';
     edRebTXOffset40.Text:='0';
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
     //tbTXLevel.Position := 16;
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
          dChar := deciString[1];
          kChar := kiloString[1];
          if dChar = '.' Then useDeciAuto.Caption := 'Use System Default (decimal = . thousands = ,)';
          if dChar = ',' Then useDeciAuto.Caption := 'Use System Default (decimal = , thousands = .)';
     end;
     // Update the DB
     updateDB;
     buttonConfig.Visible := False;
     Button4.Visible      := True;
     PageControl.Visible := True;
end;
end.
