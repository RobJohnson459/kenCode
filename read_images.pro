;;;;;READ Imager data



PRO read_images, date1, data4, dread


a='Jun26-27'


saver = '\'+a+'TempOH.sav'


dread='C:\Users\Masaru\Desktop\'+a+'\Processed'
dread1 = FILE_SEARCH(dread + '\TempOH_caun****.tif') ;dt=37sec


time = N_ELEMENTS(dread1)
;begins = 1233
;ends = 2804
;
;time = ends-begins+1
data1 = FLTARR(256, 256, time)
data2 = FLTARR(256, 256, time)
data3 = FLTARR(256, 256)


FOR i = 0, time-1 DO BEGIN
  tempo = ROTATE(READ_TIFF(dread1(i)), 7)
 ;Note!! The procedure "READ_TIFF" reads the tiff file upside down.
  data1(*,*,i) = tempo(32:319 - 32, *)
ENDFOR
data1=data1/100.0  ;;;;Divide by 100.0 to make Kelvin Temp


h1=bytarr(2)
h2=bytarr(198)
h3=bytarr(3)
;h4=bytarr(397)
img_size=intarr(2)   ;(width, height)
intensity=uintarr(2) ;(max, min)
l_time=ulonarr(3)
l_date=ulonarr(3)
l_day=ulonarr(3)
u_time=ulonarr(3)   ;UT (ss, mm, hh)
u_date=ulonarr(3)   ;UT (dd, mm-1, yyyy-1900)
u_day=ulonarr(3)    ;UT (??, # of day, ??)

fname=dread1(0)
openr,1,fname
readu,1,h1,h2,h3
readu,1,img_size,intensity
readu,1,u_time
close,1
First = u_time(1)
m=0
data2(*,*,0)=data1(*,*,0)

FOR k =0, time-1 DO BEGIN
 
  fname=dread1(k)
  openr,1,fname
  readu,1,h1,h2,h3
  readu,1,img_size,intensity
  readu,1,u_time
  dt = u_time(1)-First
  close,1 

  
  

  IF dt eq 0 THEN BEGIN
    FOR i = 0, 256 - 1 DO BEGIN
      FOR ii = 0, 256 - 1 DO BEGIN
        data2(i,ii,m) = mean([data1(i,ii,k),data2(i,ii,m)])
      ENDFOR
    ENDFOR
  ENDIF ELSE BEGIN 
    First = u_time(1)
    m=m+1
    FOR i = 0, 256 - 1 DO BEGIN
      FOR ii = 0, 256 - 1 DO BEGIN
        data2(i,ii,m)=data1(i,ii,k)
      ENDFOR
    ENDFOR 
      ENDELSE    


ENDFOR

data5 = FLTARR(256, 256,m+1 )
data4 = FLTARR(256, 256,m+1 )

data5 = data2(*,*,0:m)


FOR i = 0, 256 - 1 DO BEGIN
  FOR ii = 0, 256 - 1 DO BEGIN
    data3(i,ii)=MEAN(data5(i,ii,*))
  ENDFOR
ENDFOR

FOR p=0,m do begin
  data4(*,*,p) = (data5(*,*,p)); - data3(*,*))
ENDFOR


print,min(data4)
print,max(data4)
;


save, data4, filename=dread+saver


Q=M_FFT_AMTM_LOOP(data1)

beep
END