// (c) 2013 CQZ Electronics
unit waterfall1;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LCLType, globalData;

type
  TWaterfallControl1 = class(TCustomControl)
  property
     onMouseDown;
  public
     procedure EraseBackground(DC: HDC); override;
     procedure Paint; override;
  end;

implementation

  procedure TWaterfallControl1.EraseBackground(DC: HDC);
  begin
       // Uncomment next to enable default background erase
       //inherited EraseBackground(DC);
  end;

  procedure TWaterfallControl1.Paint;
  var
     Bitmap : TBitmap;
  begin
     if globalData.specNewSpec65 Then
     Begin
          Bitmap := TBitmap.Create;
          Bitmap.Height := 180;
          Bitmap.Width  := 750;
          globalData.specMs65.Position := 0;
          Try
             Bitmap.LoadFromStream(globalData.specMs65);
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

