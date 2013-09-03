// (c) 2013 CQZ Electronics
unit fftw_jl;

{$mode objfpc}{$H+}

{
   FFTW - Fastest Fourier Transform in the West library

   This interface unit is (C) 2005 by Daniel Mantione
     member of the Free Pascal development team.

   See the file COPYING.FPC, included in this distribution,
   for details about the copyright.

   This file carries, as a independend work calling a well
   documented binary interface, the Free Pascal LGPL license
   with static linking exception.

   Note that the FFTW library itself carries the GPL license
   and can therefore not be used in non-GPL software.

   Modified by Joe Large - W6CQZ 20/Feb/2010
            Added thread functions 02/SEP/2013
}

{*****************************************************************************}
                                    interface
{*****************************************************************************}

Const
{$IFDEF WIN32}
  FFT_DLL = 'libfftw3f-3.dll';
{$ENDIF}
{$IFDEF LINUX}
  FFT_DLL = 'libfftw3f-3';
{$ENDIF}
{$IFDEF DARWIN}
  FFT_DLL = 'libfftw3f-3';
{$ENDIF}

{$CALLING cdecl} {Saves some typing.}


type    complex_single=record
          re,im:single;
        end;
        Pcomplex_single=^complex_single;

        fftw_plan_single=type pointer;

        fftw_sign=(fftw_forward=-1,fftw_backward=1);

        fftw_flag=(fftw_measure,            {generated optimized algorithm}
                   fftw_destroy_input,      {default}
                   fftw_unaligned,          {data is unaligned}
                   fftw_conserve_memory,    {needs no explanation}
                   fftw_exhaustive,         {search optimal algorithm}
                   fftw_preserve_input,     {don't overwrite input}
                   fftw_patient,            {generate highly optimized alg.}
                   fftw_estimate);          {don't optimize, just use an alg.}
        fftw_flagset=set of fftw_flag;
                   

{Complex to complex transformations.}

function fftw_plan_dft_1d(n:cardinal;i,o:Pcomplex_single;
                          sign:fftw_sign;flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_1d';
function fftw_plan_dft_2d(nx,ny:cardinal;i,o:Pcomplex_single;
                          sign:fftw_sign;flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_2d';
function fftw_plan_dft_3d(nx,ny,nz:cardinal;i,o:Pcomplex_single;
                          sign:fftw_sign;flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_3d';

function fftw_plan_dft(rank:cardinal;n:Pcardinal;i,o:Pcomplex_single;
                       sign:fftw_sign;flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft';

{Real to complex transformations.}
function fftw_plan_dft_1d(n:cardinal;i:Psingle;o:Pcomplex_single;
                          flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_r2c_1d';
function fftw_plan_dft_2d(nx,ny:cardinal;i:Psingle;o:Pcomplex_single;
                          flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_r2c_2d';
function fftw_plan_dft_3d(nx,ny,nz:cardinal;i:Psingle;o:Pcomplex_single;
                          flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_r2c_3d';
function fftw_plan_dft(rank:cardinal;n:Pcardinal;i:Psingle;o:Pcomplex_single;
                       flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_r2c';

{Complex to real transformations.}
function fftw_plan_dft_1d(n:cardinal;i:Pcomplex_single;o:Psingle;
                          flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_c2r_1d';
function fftw_plan_dft_2d(nx,ny:cardinal;i:Pcomplex_single;o:Psingle;
                          flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_c2r_2d';
function fftw_plan_dft_3d(nx,ny,nz:cardinal;i:Pcomplex_single;o:Psingle;
                          flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_c2r_3d';
function fftw_plan_dft(rank:cardinal;n:Pcardinal;i:Pcomplex_single;o:Psingle;
                       flags:fftw_flagset):fftw_plan_single;
         external FFT_DLL name 'fftwf_plan_dft_c2r';


procedure fftw_destroy_plan(plan:fftw_plan_single);
          external FFT_DLL name 'fftwf_destroy_plan';
procedure fftw_execute(plan:fftw_plan_single);
          external FFT_DLL name 'fftwf_execute';

{Wisdom functions}
function fftwf_export_wisdom_to_string() : Pointer;
         external FFT_DLL name 'fftwf_export_wisdom_to_string';

function fftwf_import_wisdom_from_string(wisdom : PChar) : Pointer;
         external FFT_DLL name 'fftwf_import_wisdom_from_string';

procedure fftwf_forget_wisdom();
          external FFT_DLL name 'fftwf_forget_wisdom';

{Thread stuffs}
function  fftwf_init_threads() : Pointer;
          external FFT_DLL name 'fftwf_init_threads';

procedure fftwf_plan_with_nthreads(n:cardinal);
          external FFT_DLL name 'fftwf_plan_with_nthreads';

procedure fftwf_cleanup_threads;
          external FFT_DLL name 'fftwf_cleanup_threads';

{$calling register} {Back to normal!}

{*****************************************************************************}
                                  implementation
{*****************************************************************************}

end.
