// (c) 2013 CQZ Electronics
unit waterfall1;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LCLType, Spectrum, FPImage, FPCanvas,
  FPImgCanv, FPWritePNG, FPWriteBMP, FPReadPNG;

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
     Bitmap    : TBitmap;
     ccanvas   : TFPCustomCanvas;
     image     : TFPCustomImage;
     writer    : TFPCustomImageWriter;
     ccolor    : TFPColor;
     specPMs65 : TMemoryStream;
     i,j       : Integer;
  begin
       if spectrum.specNewSpec65 Then
       Begin
            Try
               specPMs65 := TMemoryStream.Create;
               specPMs65.Position := 0;

               Bitmap := TBitmap.Create;
               Bitmap.Height := 180;
               Bitmap.Width  := 750;

               image   := TFPMemoryImage.Create (750,180);
               ccanvas := TFPImageCanvas.create(image);
               writer  := TFPWriterBMP.Create;

               ccanvas.Pen.Mode  := pmCopy;
               ccanvas.Pen.Style := psSolid;
               ccanvas.Pen.Width := 1;
               ccolor.alpha := 65535;
               ccolor.red := 0;
               ccolor.blue := 0;
               // Build a png then convert to a bmp then paint it - awesome (sarcasm++++) but it's way it has to be done with custom control
               for i := 0 to 749 do
               Begin
                    for j := 0 to 179 do
                    Begin
                         ccolor.green := spectrum.specPNG[j][i].g;
                         ccolor.red   := spectrum.specPNG[j][i].r;
                         ccolor.blue  := spectrum.specPNG[j][i].b;
                         ccanvas.Pen.FPColor := ccolor;
                         ccanvas.Line(i,j,i,j);
                    end;
               end;
               specPMs65.Position:=0;
               image.SaveToStream(specPMS65,writer);
               specPMs65.Position:=0;
               bitmap.LoadFromStream(specPMs65);
               Canvas.Draw(0,0,Bitmap);
               inherited Paint;
               writer.Free;
               ccanvas.Free;
               image.Free;
               Bitmap.Free;
               specpms65.Free;
            Except
               // Do nothing for now...
               //dlog.fileDebug('Exception raised in waterfall unit');
               inherited Paint;
               writer.Free;
               ccanvas.Free;
               image.Free;
               Bitmap.Free;
               specpms65.Free;
            End;
       End;
  end;
end.

