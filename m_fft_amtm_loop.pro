Function M_FFT_AMTM_LOOP, img,dx=dx,dy=dy,dt=dt,$
  LH_min=LH_min, LH_max=LH_max, T_min=T_min, T_max=T_max,Vp_min=Vp_min,$
  Vp_max=Vp_max, zpx=zpx, zpy=zpy, zpt=zpt, wn = wn, min1 = min1, max1 = max1,$
  interpolation=interpolation
  ;+
  ; NAME:
  ;                   MATSUDA_FFT
;~Qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
  ; PURPOSE:
  ;                   Calculate horizontal phase velocity spectral from airglow intensity image data by using 3D FFT.
  ;
  ; CALLING SEQUENCE:
  ;                   Result=Matsuda_FFT(img)
  ;
  ; INPUTS:
  ;                   img - Time series of 2D airglow data (x,y,t)
  ;
  ; INPUT KEYWORDS:
  ;                   dx, dy, dt      - Image resolution in x (m), y (m) and time (s). Default values are 1000 m (dx,dy) and 60 s (dt).
  ;                   LH_min, LH_max  - Minimum and Maximum of horizontal wavelength (m). Default values are 5000 m (LH_min) and 100000 m (LH_max).
  ;                   T_min, T_max    - Minimum and Maximum of wave period           (s). Default values are 480 s (T_min) and 3600 s (T_max).
  ;                   Vp_min, Vp_max  - Minimum and Maximum of horizontal wave speed (m/s). Default values are 0 m/s (Vp_min) and 150 m/s (Vp_max).
  ;                   zpx, zpy, zpt   - Zero padding size in x, y and t. Default values are 1024 (zpx), 1024 (zpy) and 256 (zpt).
  ;                   wn              - Window number for plot display.
  ;                   min1, max1      - Minimum and Maximum of phase velocity spectrum on the plot. The default values are -11.5 (min1) and -6.5 (max1).
  ;                   Interpolation   - Interpolation method. The default is triagle interpolation. Please set keyword to 1 if you wish to use default Matsuda et al., 2014 interpolation method.
  ;
  ; OUTPUTS:
  ;                  2D phase speed spectra (vx,vy).
  ;
  ;
  ; RESTRICTIONS:
  ;                 Requires equal image interval sampling (dt).
  ;
  ; METHOD:
  ;                 This function is based on the Matsuda et al., 2014 method that was publised in JGR: Matsuda, T. S., T. Nakamura, M. K. Ejiri, M. Tsutsumi,
  ;                 and K. Shiokawa (2014), New statistical analysis of the horizontal phase velocity distribution of gravity waves observed by airglow imaging,
  ;                 J. Geophys. Res. Atmos., 119, 9707–9718, doi:10.1002/2014JD021543.
  ;
  ; MODIFICATION HISTORY:
  ;                 Perwitasari, September 2017.
  ;                 Kogure, January 2018.
  ;                 Perwitasari, June 2018 (Replace the center of r with reasonable number 0.3826)
  ;                 Kogure, July 2018 (Added triangle interpolation option)
  ; -





  imagenum = 30
  datasize=size(img)
  datatime=datasize(3)
  ddt=floor(datatime/imagenum)
  FOR q=0,ddt-1 DO BEGIN
    IF q gt 226 THEN BEGIN
      STOP
    ENDIF
    FILE = 'C:\Users\Masaru\Desktop\DefNotFake\TempOH'+string(q)
   
    img5=img(*,*,q*imagenum:(q+4)*imagenum)
    img5=img5-mean(img5)



  ;----------------------Set Image Resolution----------------------------------------------;
  if not (keyword_set(dx)) then dx=625. ;Image resolution of x axis (m)
  if not (keyword_set(dy)) then dy=dx    ;Image resolution of y axis (m)
  if not (keyword_set(dt)) then dt=60.   ;Image time resolution (s);;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  dx=FLOAT(dx)
  dy=FLOAT(dy)
  ;-----------------------Image Size--------------------------------------------------------;
  imgsize=size(img5) ;Get image size
  nx=imgsize(1)     ;Image size in x axis
  ny=nx             ;Image size in y axis
  nt=imgsize(3)     ;Image size in time
  icen=(nt-1)/2

  ;-----------------------Set Wave Parameters Input-----------------------------------------;

  if not (keyword_set(LH_min)) then LH_min= 10000.0         ;Horizontal wavelength minimum (m)
  if not (keyword_set(LH_max)) then LH_max= 80000.0       ;Horizontal wavelength maximum (m)
  if not (keyword_set(T_min)) then T_min= 5.0*60.0            ;Wave period minimum (s)
  if not (keyword_set(T_max)) then T_max= 3600.0       ;Wave period maximum (s)
  if not (keyword_set(Vp_min)) then Vp_min= 0.0            ;Wave speed minimum (m/s)
  if not (keyword_set(Vp_max)) then Vp_max= 150.0           ;Wave speed maximum (m/s)

  ;-------------------------Set zero padding parameters------------------------------------;

  if not (keyword_set(zpx)) then zpx=512.  ;Size of zero padding in x axis
  if not (keyword_set(zpy)) then zpy=zpx    ;Size of zero padding in y axis
  if not (keyword_set(zpt)) then zpt=2^10.   ;Zero padding size in time dimension


  ;-----------------------Set sampling period-----------------------------------------------;

  tres=FLOAT(dt)
  tr_min=t_min   ;Period minimum (s)
  tr_max=t_max   ;Period maximum (s)
  tr1=round([zpt/2.-zpt/fix(tr_min/tres),zpt/2.-zpt/fix(tr_max/tres)]) ;Period range


  ;-------------------Check if the horizontal wavelength inputs are correct------------------;

  if LH_max le LH_min then begin
    print, 'WARNING: LH_max should be larger than LH_min!'
    stop
  endif else begin
    if LH_min le 1000 then begin
      print, 'WARNING: Horizontal wavelength value should be in meter!'
      stop
    endif else begin
      if LH_min le (2.*dx) then begin
        print, 'WARNING: Horizontal wavelength minimum should be larger than 2*dx!'
        stop
      endif else begin
        if LH_max gt (2.*zpx*dx) then begin
          print, 'WARNING: Horizontal wavelength maximum should be less than 2*zpx*dx!'
          stop
        endif
      endelse
    endelse
  endelse

  ;------------------Check if the wave period inputs are correct--------------------------------;

  if T_max le T_min then begin
    print, 'WARNING: T_max should be larger than T_min!'
    stop
  endif else begin
    if T_min lt (2.*dt) then begin
      print, 'WARNING: Wave period minimum should be larger than 2*dt!'
      stop
    endif else begin
      ;endelse
      if T_max gt (2.*zpt*dt) then begin
        print, 'WARNING: Wave period maximum should be less than 2.*zpt*dt!'
        stop
      endif
    endelse
  endelse

  ;---------------------Check if the zero padding parameter is correct--------------------------;

  if zpx lt nx or zpx gt 2048 then begin
    print, 'Error: zpx should be in the range between nx and 2048'
    stop
  endif
  if zpy lt ny or zpy gt 2048 then begin
    print, 'Error: zpy should be in the range between ny and 2048'
    stop
  endif
  if zpt lt nt or zpt gt 2048 then begin
    print, 'Error: zpt should be in the range between nt and 2048'
    stop
  endif

  ;---------------------Pre_whitening filter (Coble et al.1998)-----------------------------------------;

  fker=fltarr(11,11) ;Kernel array
  fker(0,5)=-0.0002
  fker(1,*)=[0.0,0.0,-0.0001,-0.0002,-0.0003,0.0008,-0.0003,-0.0002,-0.0001,0.0,0.0]
  fker(2,*)=[0.0,-0.0001,-0.0003,-0.0007,-0.0016,-0.0071,-0.0016,-0.0007,-0.0003,-0.0001,0.0]
  fker(3,*)=[0.0,-0.0002,-0.0007,-0.0020,-0.0032,0.0146,-0.0032,-0.0020,-0.0007,-0.0002,0.0]
  fker(4,*)=[0.0,-0.0003,-0.0016,-0.0032,-0.0291,-0.1721,-0.0291,-0.0032,-0.0016,-0.0003,0.0]
  fker(5,*)=[-0.0002,0.0008,-0.0071,0.0146,-0.1721,1.0219,-0.1721,0.0146,-0.0071,0.0008,-0.0002]
  fker(6,*)=fker(4,*)
  fker(7,*)=fker(3,*)
  fker(8,*)=fker(2,*)
  fker(9,*)=fker(1,*)
  fker(10,*)=fker(0,*)

  ;---------------------Pre_whitening filter response-------------------------------------------------;

  kspec1=fltarr(zpx - 1, zpy-1)
  kspec1(zpx * 0.5 - 1,zpx * 0.5 - 1)=1.0
  kspec2=convol(kspec1,fker)
  kspec3=2.0*((abs(fft(kspec2,/center)))^2)
  fres=kspec3/max(kspec3)
  
  
  
  
  img2=fltarr(nx,ny,nt)
  
  for t=0,nx-1 do begin
   for d=0,ny-1 do begin
     img2(t,d,*)=img5(t,d,*);*hanning(nt)
   endfor
  endfor
  ;---------------Prewhitening process----------------------------------------------------------------;

  print, 'pre-whitening ...', FORMAT='(A,$)'
  if (nt-1) eq (floor((nt-1)/2.0)*2) then begin ;even case
    ran1=icen-(nt-1)/2 & ran2=icen+(nt-1)/2 & ran3=zpt/2-(nt-1)/2 & ran4=zpt/2+(nt-1)/2
  endif else begin ;odd case
    ran1=icen-(nt-2)/2-1 & ran2=icen+(nt-2)/2 & ran3=zpt/2-(nt-2)/2-1 & ran4=zpt/2+(nt-2)/2
  endelse

  img3=fltarr(nx,ny,zpt)
  prewhite1=fltarr(nx,ny)
  for pw1=ran3(0),ran4(0) do begin
    prewhite1(*,*)=img2(*,*,pw1-ran3)
    img3(*,*,pw1)=convol(prewhite1,fker) ;Prewhitening result

  endfor
  print, ' done'
  
  
  ;---------------------Zero padding------------------------------------------------------------------;

  rr1=zpx/2-1-nx/2+1 & rr2=zpx/2-1+nx/2   ;rr1=position to put the real image
  fa1=fltarr(zpx,zpy,zpt)
  fft_result1=fltarr(zpx,zpy,zpt) ;Array to hold initial FFT_result

  ;--------------------Apply Hanning window (not applied in time dimension)---------------------------;

  print, 'hanning Window ... ', FORMAT='(A,$)'
  for le1=ran3(0),ran4(0) do fa1(rr1:rr2,rr1:rr2,le1)=img3(*,*,le1)*HANNING(nx,ny)
  
  print, 'done'
  ;---------------------3D FFT------------------------------------------------------------------------;

  print, '3D FFT ...', FORMAT='(A,$)'
  fft_result1(*,*,*)=2.0*((abs(FFT(fa1(*,*,*),/center)))^2) ;Initial FFT result for whole spectrum (k,l,w)
  fvalue=((float(zpx)^2)*float(zpt))/((float(nx)^2)*float((nt))) ;Correction factor

  print, 'done'
  ;--------------------Recoloring----------------------------------------------------------------------;

  print, 'recoloring ... ', FORMAT='(A,$)'
  for le2=0,zpt-1 do fft_result1(1:zpx-1,1:zpy-1,le2)=fft_result1(1:zpx-1,1:zpy-1,le2)*(((float(zpx*dx)*float(zpy*dy))*float(zpt))*fvalue(0))*float(tres)/fres(*,*)
  sr1=[zpx/2-fix(float(zpx*dx)/float(LH_min)),zpx/2+fix(float(zpx*dx)/float(LH_min))]
  fft_result2=fft_result1(sr1(0):sr1(1),sr1(0):sr1(1),tr1(0):tr1(1)) ;FFT result limited between LH_min and LH_max

  xy2=Vp_max * 2 + 1
  xy1=sr1(1)-sr1(0)+1            ;Range of k and l
  tt1=tr1(1)-tr1(0)+1            ;Range of frequency
  v1a=intarr(xy1,xy1,tt1)
  angle1a=fltarr(xy1,xy1,tt1)    ;Angle omega/k, omega/l
  jacobian1=fltarr(xy1,xy1,tt1)  ;Jacobian
  xgo1=intarr(xy1,xy1,tt1)       ;Distance from the center in k
  ygo1=intarr(xy1,xy1,tt1)       ;Distance from the center in l

  for i=0,tt1-1 do begin

    Pband=alog10(fft_result2(*,*,i)/float(zpt*tres)+1.0e-22)
    NAME=FILE+'_WN_'+string(i)+'.csv'
    FILES=NAME.compress()
    WRITE_CSV,FILES,Pband
  endfor


  if (xy1 mod 2) eq 1 then begin
    ax1=fltarr(xy1)
    ax1(0:xy1/2-1)=-reverse(findgen((xy1-1)/2)+1)
    replacement_value=1.0e-38
    ax1((xy1-1)/2)=ax1((xy1-1)/2)+replacement_value
    ax1(xy1/2+1:xy1-1)=-reverse(ax1(0:xy1/2-1))
  endif else begin
    ax1=fltarr(xy1)
    ax1(0:xy1/2)=-reverse(findgen(xy1/2+1)+1)
    ax1(xy1/2+2:xy1-1)=findgen(xy1/2-2)+1
  endelse


  r=fltarr(xy1,xy1) ;Radius of the circle


  for i1=0,xy1-1 do begin
    for i2=0,xy1-1 do begin
      r(i1,i2)=sqrt(ax1(i1)^2+ax1(i2)^2)
    endfor
  endfor

  r((xy1-1)/2,(xy1-1)/2)=r((xy1-1)/2,(xy1-1)/2)+0.3826 ;Replace the center with GDM value to avoid division by 0

  v1a_1=fltarr(xy1,xy1)
  jacobian1_1=fltarr(xy1,xy1)
  angle1a_1=fltarr(xy1,xy1)

  for i1=0,xy1-1 do begin
    for i2=0,xy1-1 do begin
      ;r(i1,i2)=sqrt(ax1(i1)^2+ax1(i2)^2)
      v1a_1(i1,i2)=round(float(zpx*dx)/r(i1,i2)  )
      jacobian1_1(i1,i2)=(r(i1,i2)^4/(float(zpx*dx))^4)
      angle1a_1(i1,i2)=atan(ax1(i2),ax1(i1))
    endfor
  endfor

  for i3=0,tt1-1  do begin
    v1a(*,*,i3)=v1a_1(*,*)/(float(zpt*tres))*float(zpt/2-tr1(0)-i3)
    jacobian1(*,*,i3)=jacobian1_1(*,*)*(((float(zpt*tres))^2)/(float(zpt/2-tr1(0)-i3))^2)
    angle1a(*,*,i3)=angle1a_1(*,*)
  endfor


  xgo1(*,*,*)=round(float(xy2-1.0)/2.0+v1a(*,*,*)*cos(angle1a(*,*,*)))
  ygo1(*,*,*)=round(float(xy2-1.0)/2.0+v1a(*,*,*)*sin(angle1a(*,*,*)))

  print,'done'
  ;---------------Masking---------------------------------------------------------------------------------;

  mask1a=fltarr(xy1,xy1)
  mask1b=fltarr(xy1,xy1)
  rr2=dblarr(xy1,xy1)
  for lc1=0,xy1-1 do begin
    for lc2=0,xy1-1 do begin
      rr2(lc1,lc2)=sqrt((float(lc1)-float(xy1-1.0)/2.0)^2+(float(lc2)-float(xy1-1.0)/2.0)^2)
    endfor
  endfor


  cir2=where((rr2 lt float(zpx*dx)/LH_max) or (rr2 gt float(zpx*dx)/LH_min))
  for lc3=0,tt1-1 do begin
    mask1a(*,*)=xgo1(*,*,lc3)
    mask1b(*,*)=ygo1(*,*,lc3)
    mask1a(cir2)=999
    mask1b(cir2)=999
    xgo1(*,*,lc3)=mask1a(*,*)
    ygo1(*,*,lc3)=mask1b(*,*)
  endfor

  v2=dblarr(xy2,xy2,tt1)
  v3=dblarr(xy2,xy2,tt1)
  v4=dblarr(xy2,xy2,tt1)

  ;------------------------Conversion to phase speed domain----------------------------------------------------------------------------------;

  print, 'conversion to phase speed ... ', FORMAT='(A,$)'
  for ca4=0,tt1-1 do begin
    for ca1=0,xy1-1 do begin
      for ca2=0,xy1-1 do begin
        if (v1a(ca1,ca2,ca4) gt Vp_min) and (v1a(ca1,ca2,ca4) le Vp_max) and ((v1a(ca1,ca2,ca4) ne 0)) and (xgo1(ca1,ca2,ca4) ne 999) then begin
          v2(xgo1(ca1,ca2,ca4),ygo1(ca1,ca2,ca4),ca4) +=fft_result2(ca1,ca2,ca4)*jacobian1(ca1,ca2,ca4)
          v3(xgo1(ca1,ca2,ca4),ygo1(ca1,ca2,ca4),ca4) +=1.0
        endif
      endfor
    endfor
  endfor
  
  
  print, 'done'
  
  
  v3(where(v3 eq 0.0))=1.0
  v4(*,*,*)=v2(*,*,*)/v3(*,*,*)
  convol_result=v4  ;Phase speed array before interpolation


  v5 = total(convol_result(*,*,*)/float(zpt*tres),3)
  NAME=FILE+'_PS.csv'
  NAME=NAME.compress()
  WRITE_CSV,NAME,v5

  ;------------Make interpolation table-----------------------------------------------------------------------------;

  sz1=xy2
  sz2=sz1*2-1
  sz3=(sz1-1)/2
  phsp_range=fltarr(2,tt1)  ;Phase speed range
  interpolate_table=intarr(sz1,sz1,tt1)
  interpol_result=fltarr(sz1,sz1,tt1)

  for ts1=0,tt1-1 do begin
    phsp_range(0,ts1)=round((LH_min/(zpt*tres))*((zpt/2-tr1(0)-ts1)))
    phsp_range(1,ts1)=round((LH_max/(zpt*tres))*(zpt/2-tr1(0)-ts1))
    array2=dblarr(sz2,sz2)
    sarray1=intarr(sz2,sz2)
    ax3=fltarr(sz2)
    if (sz2 mod 2) eq 1 then begin
      ax3(0:sz2/2-1)=-reverse(findgen((sz2-1)/2)+1)
      ax3(sz2/2+1:sz2-1)=-reverse(ax3(0:sz2/2-1))
    endif else begin
      ax3(0:sz2/2)=-reverse(findgen(sz2/2+1)+1)
      ax3(sz2/2+2:sz2-1)=findgen(sz2/2-2)+1
    endelse
    array2((sz2-1)/2-sz3:(sz2-1)/2+sz3,(sz2-1)/2-sz3:(sz2-1)/2+sz3)=v3(*,*,ts1)

    for is1=(sz2-1)/2-sz3,(sz2-1)/2+sz3 do begin
      for is2=(sz2-1)/2-sz3,(sz2-1)/2+sz3 do begin
        spr1=sqrt(ax3(is1)^2+ax3(is2)^2)
        if (spr1 ge phsp_range(0,ts1)) and (spr1 le phsp_range(1,ts1)) and (spr1 gt Vp_min) and (spr1 le Vp_max) then begin
          is3=-1
          repeat begin
            is3=is3+1
            sarray1(is1,is2)=is3
            key1=0 & key2=0
            key1=keyword_set(where(array2(is1-is3:is1+is3,is2-is3:is2+is3) ne 0.0 ,/null))
            key2=keyword_set(array2(is1,is2) ne 0.0)
          endrep until (key1 eq 1) or (key2 eq 1)
        endif else begin
          sarray1(is1,is2)=999
        endelse
      endfor
    endfor
    interpolate_table(*,*,ts1)=sarray1((sz2-1)/2-sz3:(sz2-1)/2+sz3,(sz2-1)/2-sz3:(sz2-1)/2+sz3)
  endfor
  interpol_table=interpolate_table

  ;------Get the convolution result-----------------------------------------------------------------;
  
  print, 'convolution ... ', FORMAT='(A,$)'
  array1_int=convol_result
  fsize_int=size(array1_int) & sz1_int=fsize_int(1) & tt1_int=fsize_int(3)
  sr1_int=[zpx/2-fix(float(zpx*dx)/float(LH_min)),zpy/2+fix(float(zpy*dy)/float(LH_min))]

  print, 'done'
  ;----------------------Interpolation-------------------------------------------------------------;
  
  print, 'interpolation', FORMAT='(A,$)'
  if keyword_set(interpolation) then begin   ;Matsuda et al., 2014 original interpolation method
    sz2_int=sz1*2-1
    sz3_int=(sz1-1)/2
    array2_Int=dblarr(sz2_int,sz2_int,tt1_int)
    array3_int=dblarr(sz2_int,sz2_int,tt1_int)
    array3_int1=dblarr(sz2_int,sz2_int,tt1_int)
    array4_int=dblarr(sz1_int,sz1_int,tt1_int)
    sarray1_int=intarr(sz2_int,sz2_int,tt1_int)

    array2_int((sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,(sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,*)=array1_int(*,*,*)
    sarray1_int((sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,(sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,*)=interpol_table(*,*,*)

    for in4=0,tt1_int-1 do begin
      for in1=(sz2_int-1)/2-sz3_int,(sz2_int-1)/2+sz3_int do begin
        for in2=(sz2_int-1)/2-sz3_int,(sz2_int-1)/2+sz3_int do begin
          in3=sarray1_int(in1,in2,in4)
          if  (in3 ne 999) then begin
            if (in3 gt 0) then begin
              array3_int(in1,in2,in4)=max(array2_int(in1-in3:in1+in3,in2-in3:in2+in3,in4))
            endif else begin
              array3_int(in1,in2,in4)=array2_int(in1,in2,in4)
            endelse

          endif
        endfor
      endfor
    endfor
    array4_int(*,*,*)=array3_int((sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,(sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,*)
    interpol_result=array4_int ;Phase speed array after interpolation (vx,vy,w)
  endif  else begin

    for in4=0,tt1_int-1 do begin  ;Triangle interpolation method
      C0 = interpol_table(*, *,in4)
      ND1 = WHERE(C0 ne 999)
      C1 = 0
      C2 = 0
      C3 = FLTARR(xy2, xy2)

      IF ND1(0) ne - 1 THEN BEGIN
        c1 = array1_int(*, *,in4)
        yyyy = INTARR(xy2,xy2)
        FOR i = 0, xy2 - 1 DO BEGIN
          yyyy(i , *) = INDGEN(xy2)
        ENDFOR
        xxxx = transpose(yyyy)
        ND0 = WHERE(c1(ND1) ne 0)
        TRIANGULATE,  xxxx(ND1(ND0)) , yyyy(ND1(ND0)),tri
        c2 = trigrid( xxxx(ND1(ND0)), yyyy(ND1(ND0)), c1(ND1(ND0)),  $
          tri,NY = MAX(xxxx(ND1(ND0))) - MIN(xxxx(ND1(ND0))) + 1,NX =  MAX(yyyy(ND1(ND0))) - MIN(yyyy(ND1(ND0))) + 1)
        ND2 = WHERE(C0  eq 999 )
        c3(MIN(xxxx(ND1(ND0))):MAX(xxxx(ND1(ND0))), MIN(yyyy(ND1(ND0))):MAX(yyyy(ND1(ND0)))) = c2
        c3(ND2) = 0.

      ENDIF
      interpol_result(*, *,in4) = c3 ;;Phase speed array after interpolation (vx,vy,w)

    endfor
  endelse

  print, 'done'
  ;----------------Calculate the 2D phase velocity-----------------------------------------------------------;

  total_result_new=alog10(total(interpol_result(*,*,*)/float(zpt*tres),3)+1.0e-22) ;2D Phase speed array (vx,vy)
  final_2D_PHS=total_result_new
  print, 'Minimum PSD= ', min(final_2D_phs)
  print, 'Maximum PSD= ', max(final_2D_phs)
  FINAL_DATA=total_result_new

  ;================================================================================

  TOC
;   for i=0,tt1_int-1 do begin
;  
;     Pband=alog10(interpol_result(*,*,i)/float(zpt*tres)+1.0e-22)
;     NAME=FILE+'_'+string(i)+'.csv'
;     FILES=NAME.compress()
;     WRITE_CSV,FILES,Pband
;   endfor
NAME=FILE+'_TOTAL.csv'
NAME=NAME.compress()
  WRITE_CSV,NAME,FINAL_DATA
TOC
  
 ENDFOR
end