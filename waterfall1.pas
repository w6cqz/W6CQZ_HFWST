// (c) 2013 CQZ Electronics
unit waterfall1;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LCLType, Spectrum;

type
  TWaterfallControl1 = class(TCustomControl)
  property
     onMouseDown;
  public
     procedure init;
     procedure EraseBackground(DC: HDC); override;
     procedure Paint; override;
  end;

implementation

  Procedure TWaterfallControl1.init;
  Begin
       spectrum.specMs65  := TMemoryStream.Create;
       spectrum.specMs65.Position := 0;
  end;

  procedure TWaterfallControl1.EraseBackground(DC: HDC);
  begin
       // Uncomment next to enable default background erase
       //inherited EraseBackground(DC);
  end;

  procedure TWaterfallControl1.Paint;
  var
     Bitmap : TBitmap;
  begin
     if spectrum.specNewSpec65 Then
     Begin
          Bitmap := TBitmap.Create;
          Bitmap.Height := 180;
          Bitmap.Width  := 750;
          spectrum.specMs65.Position := 0;
          Try
             Bitmap.LoadFromStream(spectrum.specMs65);
             Canvas.Draw(0,0, Bitmap);
             inherited Paint;
             Bitmap.Free;
          Except
             // Do nothing for now...
             //dlog.fileDebug('Exception raised in waterfall unit');
             inherited Paint;
             Bitmap.Free;
          End;
     End;
  end;
end.

