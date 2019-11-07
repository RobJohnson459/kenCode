;;;;;READ Imager data



PRO read_images, date1, deviationData, sourceFile

;-----------------User Defined Variables--------------------;
dateRange='Jun26-27'
sourcePath = 'C:\Users\Masaru\Desktop\'
;---------------End User Defined Variables------------------;


saver = '\'+dateRange+'TempOH.sav'


sourceFile= sourcePath +dateRange+'\Processed'
tempFiles = FILE_SEARCH(sourceFile + '\TempOH_caun****.tif') ;dt=37sec


frames = N_ELEMENTS(tempFiles)
;begins = 1233
;ends = 2804
;
;frames = ends-begins+1
shortPeriodData = FLTARR(256, 256, frames)
dataInMinutes = FLTARR(256, 256, frames)
nightAverage = FLTARR(256, 256)


FOR i = 0, frames-1 DO BEGIN
 ;Note!! The procedure "READ_TIFF" reads the tiff file upside down.
  correctedImages = ROTATE(READ_TIFF(tempFiles(i)), 7)
  shortPeriodData(*,*,i) = correctedImages(32:319 - 32, *)
ENDFOR
shortPeriodData=shortPeriodData/100.0  ;;;;Divide by 100.0 to make Kelvin Temp


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

fname=tempFiles(0)
openr,1,fname
readu,1,h1,h2,h3
readu,1,img_size,intensity
readu,1,u_time
close,1
First = u_time(1)
m=0
dataInMinutes(*,*,0)=shortPeriodData(*,*,0)

FOR k =0, frames-1 DO BEGIN
 
  fname=tempFiles(k)
  openr,1,fname
  readu,1,h1,h2,h3
  readu,1,img_size,intensity
  readu,1,u_time
  dt = u_time(1)-First
  close,1 

  
  

  IF dt eq 0 THEN BEGIN
    FOR i = 0, 256 - 1 DO BEGIN
      FOR ii = 0, 256 - 1 DO BEGIN
        dataInMinutes(i,ii,m) = mean([shortPeriodData(i,ii,k),dataInMinutes(i,ii,m)])
      ENDFOR
    ENDFOR
  ENDIF ELSE BEGIN 
    First = u_time(1)
    m=m+1
    FOR i = 0, 256 - 1 DO BEGIN
      FOR ii = 0, 256 - 1 DO BEGIN
        dataInMinutes(i,ii,m)=shortPeriodData(i,ii,k)
      ENDFOR
    ENDFOR 
      ENDELSE    


ENDFOR

timeAdjustedData = FLTARR(256, 256,m+1 )
deviationData = FLTARR(256, 256,m+1 )

timeAdjustedData = dataInMinutes(*,*,0:m)


FOR i = 0, 256 - 1 DO BEGIN
  FOR ii = 0, 256 - 1 DO BEGIN
    nightAverage(i,ii)=MEAN(timeAdjustedData(i,ii,*))
  ENDFOR
ENDFOR

FOR p=0,m do begin
  deviationData(*,*,p) = (timeAdjustedData(*,*,p)); - nightAverage(*,*))
ENDFOR


print,min(deviationData)
print,max(deviationData)


save, deviationData, filename=sourceFile+saver


Q=M_FFT_AMTM_LOOP(shortPeriodData)

beep
END