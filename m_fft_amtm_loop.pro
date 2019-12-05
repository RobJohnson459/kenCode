Function M_FFT_AMTM_LOOP, img,dx=dx,dy=dy,dt=dt,$
  LH_min=LH_min, LH_max=LH_max, T_min=T_min, T_max=T_max,Vp_min=Vp_min,$
  Vp_max=Vp_max, zpx=zpx, zpy=zpy, zpt=zpt, wn = wn, min1 = min1, max1 = max1,$
  interpolation=interpolation, locationToSaveTo=locationToSaveTo
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
  ;                   Interpolation   - Interpolation method. The default is triagle interpolation. Please set keyword to 1 IF you wish to use default Matsuda et al., 2014 interpolation method.
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

  ;-----------------------------------------------------------------------------------------;
  ;---------------------User Defined Variables----------------------------------------------;
  ;-----------------------------------------------------------------------------------------;
IF NOT (keyword_set(LocationToSaveTo)) THEN BEGIN
  locationToSaveTo = 'C:\Users\Masaru\Documents\robCode\MCM_AMTM_2018\April2018'
ENDIF
LocationToSaveTo = LocationToSaveTo + '\TempOH'
imageNum = 30


;-----------------------------------------------------------------------------------------;
;----------------------Code Premature Exit Conditions-------------------------------------;
;-----------------------------------------------------------------------------------------;


;-------------------Check IF the horizontal wavelength inputs are correct-----------------;

IF LH_max LE LH_min THEN BEGIN
  ;print, 'WARNING: LH_max should be larger than LH_min!'
  stop
ENDIF ELSE BEGIN
  IF LH_min LE 1000 THEN BEGIN
    ;print, 'WARNING: Horizontal wavelength value should be in meter!'
    stop
  ENDIF ELSE BEGIN
    IF LH_min LE (2.*dx) THEN BEGIN
      ;print, 'WARNING: Horizontal wavelength minimum should be larger than 2*dx!'
      stop
    ENDIF ELSE BEGIN
      IF LH_max GT (2.*zpx*dx) THEN BEGIN
        ;print, 'WARNING: Horizontal wavelength maximum should be less than 2*zpx*dx!'
        stop
      ENDIF
    ENDELSE
  ENDELSE
ENDELSE

;------------------Check IF the wave period inputs are correct--------------------------------;

IF T_max LE T_min THEN BEGIN
  ;print, 'WARNING: T_max should be larger than T_min!'
  stop
ENDIF ELSE BEGIN
  IF T_min LT (2.*dt) THEN BEGIN
    ;print, 'WARNING: Wave period minimum should be larger than 2*dt!'
    stop
  ENDIF ELSE BEGIN
    ;ENDELSE
    IF T_max GT (2.*zpt*dt) THEN BEGIN
      ;print, 'WARNING: Wave period maximum should be less than 2.*zpt*dt!'
      stop
    ENDIF
  ENDELSE
ENDELSE

;---------------------Check if the zero padding parameter is correct--------------------------;

IF zpx LT nx OR zpx GT 2048 THEN BEGIN
  ;print, 'Error: zpx should be in the range between nx and 2048'
  stop
ENDIF
IF zpy LT ny OR zpy GT 2048 THEN BEGIN
  ;print, 'Error: zpy should be in the range between ny and 2048'
  stop
ENDIF
IF zpt LT nt OR zpt GT 2048 THEN BEGIN
  ;print, 'Error: zpt should be in the range between nt and 2048'
  stop
ENDIF


;-----------------------------------------------------------------------------------------;
;----------------------Other constant variables-------------------------------------------;
;-----------------------------------------------------------------------------------------;  
dataSize=size(img)
dataTime=dataSize(3)
ddt=floor(dataTime/imageNum)
Power=fltarr(ddt-2)

;----------------------Set Image Resolution----------------------------------------------;
IF NOT (keyword_set(dx)) THEN dx=625. ;Image resolution of x axis (m)
IF NOT (keyword_set(dy)) THEN dy=dx    ;Image resolution of y axis (m)
IF NOT (keyword_set(dt)) THEN dt=60.   ;Image time resolution (s);;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dx=FLOAT(dx)
dy=FLOAT(dy)

;-----------------------Set Wave Parameters Input-----------------------------------------;

IF NOT (keyword_set(LH_min)) THEN LH_min= 10000.0         ;Horizontal wavelength minimum (m)
IF NOT (keyword_set(LH_max)) THEN LH_max= 80000.0       ;Horizontal wavelength maximum (m)
IF NOT (keyword_set(T_min)) THEN T_min= 5.0*60.0            ;Wave period minimum (s)
IF NOT (keyword_set(T_max)) THEN T_max= 3600.0       ;Wave period maximum (s)
IF NOT (keyword_set(Vp_min)) THEN Vp_min= 0.0            ;Wave speed minimum (m/s)
IF NOT (keyword_set(Vp_max)) THEN Vp_max= 150.0           ;Wave speed maximum (m/s)

;-------------------------Set zero padding parameters------------------------------------;

IF NOT (keyword_set(zpx)) THEN zpx=512.  ;Size of zero padding in x axis
IF NOT (keyword_set(zpy)) THEN zpy=zpx    ;Size of zero padding in y axis
IF NOT (keyword_set(zpt)) THEN zpt=2^10.   ;Zero padding size in time dimension


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




  ;-----------------------------------------------------------------------------------------;
  ;----------------------------Main looping event-------------------------------------------;
  ;-----------------------------------------------------------------------------------------;  
FOR q=0,ddt-5 DO BEGIN
  print, q
  FILE = LocationToSaveTo +string(q)
   
  deviationData=img(*,*,q*imageNum:(q+4)*imageNum) ;;;;;Here is where I meant that the mean is subtracted each loop. KZ
  deviationData=deviationData-mean(deviationData)


  ;-----------------------Image Size--------------------------------------------------------;
  imgSize=size(deviationData) ;Get image size
  nx=imgSize(1)     ;Image size in x axis
  ny=nx             ;Image size in y axis
  nt=imgSize(3)     ;Image size in time
  icen=(nt-1)/2

  ;-----------------------Set sampling period-----------------------------------------------;

  tres=float(dt)
  tr_min=t_min   ;Period minimum (s)
  tr_max=t_max   ;Period maximum (s)
  tr1=round([zpt/2.-zpt/fix(tr_min/tres),zpt/2.-zpt/fix(tr_max/tres)]) ;Period range
  
  img2=fltarr(nx,ny,nt)
  
  FOR t=0,nx-1 DO BEGIN
   FOR d=0,ny-1 DO BEGIN
     img2(t,d,*)=deviationData(t,d,*);*hanning(nt)
   ENDFOR
  ENDFOR
  ;---------------Prewhitening process----------------------------------------------------------------;

  ;print, 'pre-whitening ...', FORMAT='(A,$)'
  IF (nt-1) EQ (floor((nt-1)/2.0)*2) THEN BEGIN ;even case
    ran1=icen-(nt-1)/2 & ran2=icen+(nt-1)/2 & ran3=zpt/2-(nt-1)/2 & ran4=zpt/2+(nt-1)/2
  ENDIF ELSE BEGIN ;odd case
    ran1=icen-(nt-2)/2-1 & ran2=icen+(nt-2)/2 & ran3=zpt/2-(nt-2)/2-1 & ran4=zpt/2+(nt-2)/2
  ENDELSE

  img3=fltarr(nx,ny,zpt)
  prewhite1=fltarr(nx,ny)
  FOR pw1=ran3(0),ran4(0) DO BEGIN
    prewhite1(*,*)=img2(*,*,pw1-ran3)
    img3(*,*,pw1)=convol(prewhite1,fker) ;Prewhitening result

  ENDFOR
  ;print, ' done'
  
  
  ;---------------------Zero padding------------------------------------------------------------------;

  rr1=zpx/2-1-nx/2+1 & rr2=zpx/2-1+nx/2   ;rr1=position to put the real image
  fa1=fltarr(zpx,zpy,zpt)
  fft_result1=fltarr(zpx,zpy,zpt) ;Array to hold initial FFT_result

  ;--------------------Apply Hanning window (not applied in time dimension)---------------------------;

  ;print, 'hanning Window ... ', FORMAT='(A,$)'
  FOR le1=ran3(0),ran4(0) DO fa1(rr1:rr2,rr1:rr2,le1)=img3(*,*,le1)*HANNING(nx,ny)
  
  ;print, 'done'
  ;---------------------3D FFT------------------------------------------------------------------------;

  ;print, '3D FFT ...', FORMAT='(A,$)'
  fft_result1(*,*,*)=2.0*((abs(FFT(fa1(*,*,*),/center)))^2) ;Initial FFT result for whole spectrum (k,l,w)
  fvalue=((float(zpx)^2)*float(zpt))/((float(nx)^2)*float((nt))) ;Correction factor

  ;print, 'done'
  ;--------------------Recoloring----------------------------------------------------------------------;

  ;print, 'recoloring ... ', FORMAT='(A,$)'
  FOR le2=0,zpt-1 DO fft_result1(1:zpx-1,1:zpy-1,le2)=fft_result1(1:zpx-1,1:zpy-1,le2)*(((float(zpx*dx)*float(zpy*dy))*float(zpt))*fvalue(0))*float(tres)/fres(*,*)
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
  FOR i=0,tt1-1 DO BEGIN

    Pband=alog10(fft_result2(*,*,i)/float(zpt*tres)+1.0e-22)
    NAME=FILE+'_WN_'+string(i)+'.csv'
    FILES=NAME.compress()
    WRITE_CSV,FILES,Pband
    
; Uncomment this to recieve the full data
;    Pband=alog10(fft_result1(*,*,i)/float(zpt*tres)+1.0e-22)
;    NAME=FILE+'_WNfull_'+string(i)+'.csv'
;    FILES=NAME.compress()
;    WRITE_CSV,FILES,Pband
  ENDFOR

;Printing out Total FFT Power (Variance) of T' 
Power(q)=TOTAL(fft_result2)/((zpt*dt)*(zpx*dx)^2)   
NAME=FILE+'_POW_'+'.csv'
FILES=NAME.compress()
WRITE_CSV,FILES,Power

  IF (xy1 mod 2) EQ 1 THEN BEGIN
    ax1=fltarr(xy1)
    ax1(0:xy1/2-1)=-reverse(findgen((xy1-1)/2)+1)
    replacement_value=1.0e-38
    ax1((xy1-1)/2)=ax1((xy1-1)/2)+replacement_value
    ax1(xy1/2+1:xy1-1)=-reverse(ax1(0:xy1/2-1))
  ENDIF ELSE BEGIN
    ax1=fltarr(xy1)
    ax1(0:xy1/2)=-reverse(findgen(xy1/2+1)+1)
    ax1(xy1/2+2:xy1-1)=findgen(xy1/2-2)+1
  ENDELSE


  r=fltarr(xy1,xy1) ;Radius of the circle


  FOR i=0,xy1-1 DO BEGIN
    FOR j=0,xy1-1 DO BEGIN
      r(i,j)=sqrt(ax1(i)^2+ax1(j)^2)
    ENDFOR
  ENDFOR

  r((xy1-1)/2,(xy1-1)/2)=r((xy1-1)/2,(xy1-1)/2)+0.3826 ;Replace the center with GDM value to avoid division by 0

  v1a_1=fltarr(xy1,xy1)
  jacobian1_1=fltarr(xy1,xy1)
  angle1a_1=fltarr(xy1,xy1)

  FOR i1=0,xy1-1 DO BEGIN
    FOR i2=0,xy1-1 DO BEGIN
      ;r(i1,i2)=sqrt(ax1(i1)^2+ax1(i2)^2)
      v1a_1(i1,i2)=round(float(zpx*dx)/r(i1,i2)  )
      jacobian1_1(i1,i2)=(r(i1,i2)^4/(float(zpx*dx))^4)
      angle1a_1(i1,i2)=atan(ax1(i2),ax1(i1))
    ENDFOR
  ENDFOR

  FOR i3=0,tt1-1  DO BEGIN
    v1a(*,*,i3)=v1a_1(*,*)/(float(zpt*tres))*float(zpt/2-tr1(0)-i3)
    jacobian1(*,*,i3)=jacobian1_1(*,*)*(((float(zpt*tres))^2)/(float(zpt/2-tr1(0)-i3))^2)
    angle1a(*,*,i3)=angle1a_1(*,*)
  ENDFOR


  xgo1(*,*,*)=round(float(xy2-1.0)/2.0+v1a(*,*,*)*cos(angle1a(*,*,*)))
  ygo1(*,*,*)=round(float(xy2-1.0)/2.0+v1a(*,*,*)*sin(angle1a(*,*,*)))

  ;print,'done'
  ;---------------Masking---------------------------------------------------------------------------------;

  mask1a=fltarr(xy1,xy1)
  mask1b=fltarr(xy1,xy1)
  rr2=dblarr(xy1,xy1)
  FOR lc1=0,xy1-1 DO BEGIN
    FOR lc2=0,xy1-1 DO BEGIN
      rr2(lc1,lc2)=sqrt((float(lc1)-float(xy1-1.0)/2.0)^2+(float(lc2)-float(xy1-1.0)/2.0)^2)
    ENDFOR
  ENDFOR


  cir2=where((rr2 LT float(zpx*dx)/LH_max) OR (rr2 GT float(zpx*dx)/LH_min))
  FOR lc3=0,tt1-1 DO BEGIN
    mask1a(*,*)=xgo1(*,*,lc3)
    mask1b(*,*)=ygo1(*,*,lc3)
    mask1a(cir2)=999
    mask1b(cir2)=999
    xgo1(*,*,lc3)=mask1a(*,*)
    ygo1(*,*,lc3)=mask1b(*,*)
  ENDFOR

  v2=dblarr(xy2,xy2,tt1)
  v3=dblarr(xy2,xy2,tt1)
  v4=dblarr(xy2,xy2,tt1)

  ;------------------------Conversion to phase speed domain----------------------------------------------------------------------------------;

  ;print, 'conversion to phase speed ... ', FORMAT='(A,$)'
  FOR ca4=0,tt1-1 DO BEGIN
    FOR ca1=0,xy1-1 DO BEGIN
      FOR ca2=0,xy1-1 DO BEGIN
        IF (v1a(ca1,ca2,ca4) GT Vp_min) AND (v1a(ca1,ca2,ca4) LE Vp_max) AND ((v1a(ca1,ca2,ca4) NE 0)) AND (xgo1(ca1,ca2,ca4) NE 999) THEN BEGIN
          v2(xgo1(ca1,ca2,ca4),ygo1(ca1,ca2,ca4),ca4) +=fft_result2(ca1,ca2,ca4)*jacobian1(ca1,ca2,ca4)
          v3(xgo1(ca1,ca2,ca4),ygo1(ca1,ca2,ca4),ca4) +=1.0
        ENDIF
      ENDFOR
    ENDFOR
  ENDFOR
  
  
  ;print, 'done'
  
  
  v3(where(v3 EQ 0.0))=1.0
  v4(*,*,*)=v2(*,*,*)/v3(*,*,*)
  convol_result=v4  ;Phase speed array before interpolation

;
;  v5 = total(convol_result(*,*,*)/float(zpt*tres),3)
;  NAME=FILE+'_PS.csv'
;  NAME=NAME.compress()
;  WRITE_CSV,NAME,v5

  ;------------Make interpolation table-----------------------------------------------------------------------------;

  sz1=xy2
  sz2=sz1*2-1
  sz3=(sz1-1)/2
  phsp_range=fltarr(2,tt1)  ;Phase speed range
  interpolate_table=intarr(sz1,sz1,tt1)
  interpol_result=fltarr(sz1,sz1,tt1)

  FOR ts1=0,tt1-1 DO BEGIN
    phsp_range(0,ts1)=round((LH_min/(zpt*tres))*((zpt/2-tr1(0)-ts1)))
    phsp_range(1,ts1)=round((LH_max/(zpt*tres))*(zpt/2-tr1(0)-ts1))
    array2=dblarr(sz2,sz2)
    sarray1=intarr(sz2,sz2)
    ax3=fltarr(sz2)
    IF (sz2 mod 2) EQ 1 THEN BEGIN
      ax3(0:sz2/2-1)=-reverse(findgen((sz2-1)/2)+1)
      ax3(sz2/2+1:sz2-1)=-reverse(ax3(0:sz2/2-1))
    ENDIF ELSE BEGIN
      ax3(0:sz2/2)=-reverse(findgen(sz2/2+1)+1)
      ax3(sz2/2+2:sz2-1)=findgen(sz2/2-2)+1
    ENDELSE
    array2((sz2-1)/2-sz3:(sz2-1)/2+sz3,(sz2-1)/2-sz3:(sz2-1)/2+sz3)=v3(*,*,ts1)

    FOR is1=(sz2-1)/2-sz3,(sz2-1)/2+sz3 DO BEGIN
      FOR is2=(sz2-1)/2-sz3,(sz2-1)/2+sz3 DO BEGIN
        spr1=sqrt(ax3(is1)^2+ax3(is2)^2)
        IF (spr1 ge phsp_range(0,ts1)) AND (spr1 LE phsp_range(1,ts1)) AND (spr1 GT Vp_min) AND (spr1 LE Vp_max) THEN BEGIN
          is3=-1
          repeat BEGIN
            is3=is3+1
            sarray1(is1,is2)=is3
            key1=0 & key2=0
            key1=keyword_set(where(array2(is1-is3:is1+is3,is2-is3:is2+is3) NE 0.0 ,/null))
            key2=keyword_set(array2(is1,is2) NE 0.0)
          endrep until (key1 EQ 1) OR (key2 EQ 1)
        ENDIF ELSE BEGIN
          sarray1(is1,is2)=999
        ENDELSE
      ENDFOR
    ENDFOR
    interpolate_table(*,*,ts1)=sarray1((sz2-1)/2-sz3:(sz2-1)/2+sz3,(sz2-1)/2-sz3:(sz2-1)/2+sz3)
  ENDFOR
  interpol_table=interpolate_table

  ;------Get the convolution result-----------------------------------------------------------------;
  
  ;print, 'convolution ... ', FORMAT='(A,$)'
  array1_int=convol_result
  fsize_int=size(array1_int) & sz1_int=fsize_int(1) & tt1_int=fsize_int(3)
  sr1_int=[zpx/2-fix(float(zpx*dx)/float(LH_min)),zpy/2+fix(float(zpy*dy)/float(LH_min))]

  ;print, 'done'
  ;----------------------Interpolation-------------------------------------------------------------;
  
  ;print, 'interpolation', FORMAT='(A,$)'
;;  IF keyword_set(interpolation) THEN BEGIN   ;Matsuda et al., 2014 original interpolation method
;    sz2_int=sz1*2-1
;    sz3_int=(sz1-1)/2
;    array2_Int=dblarr(sz2_int,sz2_int,tt1_int)
;    array3_int=dblarr(sz2_int,sz2_int,tt1_int)
;    array3_int1=dblarr(sz2_int,sz2_int,tt1_int)
;    array4_int=dblarr(sz1_int,sz1_int,tt1_int)
;    sarray1_int=intarr(sz2_int,sz2_int,tt1_int)
;
;    array2_int((sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,(sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,*)=array1_int(*,*,*)
;    sarray1_int((sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,(sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,*)=interpol_table(*,*,*)
;
;    FOR in4=0,tt1_int-1 DO BEGIN
;      FOR in1=(sz2_int-1)/2-sz3_int,(sz2_int-1)/2+sz3_int DO BEGIN
;        FOR in2=(sz2_int-1)/2-sz3_int,(sz2_int-1)/2+sz3_int DO BEGIN
;          in3=sarray1_int(in1,in2,in4)
;          IF  (in3 NE 999) THEN BEGIN
;            IF (in3 GT 0) THEN BEGIN
;              array3_int(in1,in2,in4)=max(array2_int(in1-in3:in1+in3,in2-in3:in2+in3,in4))
;            ENDIF ELSE BEGIN
;              array3_int(in1,in2,in4)=array2_int(in1,in2,in4)
;            ENDELSE
;
;          ENDIF
;        ENDFOR
;      ENDFOR
;    ENDFOR
;    array4_int(*,*,*)=array3_int((sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,(sz2_int-1)/2-sz3_int:(sz2_int-1)/2+sz3_int,*)
;    interpol_result=array4_int ;Phase speed array after interpolation (vx,vy,w)
;;  ENDIF  ELSE BEGIN

    FOR in4=0,tt1_int-1 DO BEGIN  ;Triangle interpolation method
      C0 = interpol_table(*, *,in4)
      ND1 = WHERE(C0 NE 999)
      C1 = 0
      C2 = 0
      C3 = FLTARR(xy2, xy2)

      IF ND1(0) NE - 1 THEN BEGIN
        c1 = array1_int(*, *,in4)
        yyyy = INTARR(xy2,xy2)
        FOR i = 0, xy2 - 1 DO BEGIN
          yyyy(i , *) = INDGEN(xy2)
        ENDFOR
        xxxx = transpose(yyyy)
        ND0 = WHERE(c1(ND1) NE 0)
        TRIANGULATE,  xxxx(ND1(ND0)) , yyyy(ND1(ND0)),tri
        c2 = trigrid( xxxx(ND1(ND0)), yyyy(ND1(ND0)), c1(ND1(ND0)),  $
          tri,NY = MAX(xxxx(ND1(ND0))) - MIN(xxxx(ND1(ND0))) + 1,NX =  MAX(yyyy(ND1(ND0))) - MIN(yyyy(ND1(ND0))) + 1)
        ND2 = WHERE(C0  EQ 999 )
        c3(MIN(xxxx(ND1(ND0))):MAX(xxxx(ND1(ND0))), MIN(yyyy(ND1(ND0))):MAX(yyyy(ND1(ND0)))) = c2
        c3(ND2) = 0.

      ENDIF
      interpol_result(*, *,in4) = c3 ;;Phase speed array after interpolation (vx,vy,w)

    ENDFOR
;  ENDELSE

  ;print, 'done'
  ;----------------Calculate the 2D phase velocity-----------------------------------------------------------;

  total_result_new=alog10(total(interpol_result(*,*,*)/float(zpt*tres),3)+1.0e-22) ;2D Phase speed array (vx,vy)
  final_2D_PHS=total_result_new
  print, 'Minimum PSD= ', min(final_2D_phs)
  print, 'Maximum PSD= ', max(final_2D_phs)
  FINAL_DATA=total_result_new

  ;================================================================================


  NAME=FILE+'_TOTAL.csv'
  NAME=NAME.compress()
  WRITE_CSV,NAME,FINAL_DATA
TOC
  
ENDFOR
end