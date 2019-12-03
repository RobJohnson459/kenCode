;;;;;READ Imager data



FUNCTION read_images, dateString=dateString, sourcePath=sourcePath, begins=begins, ends=ends, endDir=endDir

;-----------------User Defined Variables--------------------;
IF (keyword_set(begins)) THEN begins = begins + 1 ELSE begins = 0
IF (keyword_set(ends)) THEN ends = ends -1 ELSE ends = -1
IF NOT (keyword_set(dateString)) THEN dateString = 'apr19-20'
IF NOT (keyword_set(sourcePath)) THEN sourcePath = 'D:April 2018\'
IF NOT (keyword_set(endDir)) THEN endDir = 'C:\Users\Masaru\Documents\robCode\MCM_AMTM_2018'
;---------------End User Defined Variables------------------;


saver = '\'+dateString+'TempOH.sav'


sourceFile= sourcePath +dateString+'\Processed'
tempFiles = FILE_SEARCH(sourceFile + '\TempOH_caun****.tif') ;dt=37sec


IF ends LE 0 THEN ends = N_ELEMENTS(tempFiles)
frames = ends-begins+1
shortPeriodData = FLTARR(256, 256, frames)
correctedImages = FLTARR(320, 256, frames)
dataInMinutes = FLTARR(256, 256, frames)
nightAverage = FLTARR(256, 256)


FOR i = begins, ends-1 DO BEGIN
 ;Note!! The procedure "READ_TIFF" reads the tiff file upside down.
  correctedImages(*,*, i-begins) = ROTATE(READ_TIFF(tempFiles(i)), 7)
  shortPeriodData(*,*,i-begins) = correctedImages(32:319-32,*, i-begins)
 ;ShortPeriodData has a period of ~37 seconds, meaning it has more data than we want read.
ENDFOR
shortPeriodData=shortPeriodData/100.0  ;;;;Divide by 100.0 to make Kelvin Temp

; are h1, h2 and h3 to just read away data we don't need?
h1=bytarr(2)
h2=bytarr(198)
h3=bytarr(3)
img_size=intarr(2)   ;(width, height)
intensity=uintarr(2) ;(max, min)
u_time=ulonarr(3)   ;UT (ss, mm, hh)

;the open and read actions here are to get us the First time so we can use it later.
;This leads to the question - what is faster? reading one more file or an if statement frames times?
;alternate solution: First = 61. It is an unreachable number, so it will always trigger the if statement.
fname=tempFiles(begins)
openr,1,fname
readu,1,h1,h2,h3
readu,1,img_size,intensity
readu,1,u_time
close,1
First = u_time(1)
m=0
dataInMinutes(*,*,0)=shortPeriodData(*,*,0)

FOR k = 0, frames-1 DO BEGIN ; put the data into minutes. If two frames occupy the same minute, average them.
 
  fname=tempFiles(k)
  openr,1,fname
  readu,1,h1,h2,h3
  readu,1,img_size,intensity
  readu,1,u_time
  dt = u_time(1)-First ;minutes place of the data
  close,1 

  
  

  IF dt eq 0 THEN BEGIN ;These two frames 
    FOR i = 0, 256 - 1 DO BEGIN
      FOR j = 0, 256 - 1 DO BEGIN
        dataInMinutes(i,j,m) = mean([shortPeriodData(i,j,k),dataInMinutes(i,j,m)])
      ENDFOR
    ENDFOR
  ENDIF ELSE BEGIN 
    First = u_time(1)
    m=m+1
    FOR i = 0, 256 - 1 DO BEGIN
      FOR j = 0, 256 - 1 DO BEGIN
        dataInMinutes(i,j,m)=shortPeriodData(i,j,k)
      ENDFOR
    ENDFOR 
  ENDELSE    


ENDFOR

timeAdjustedData = FLTARR(256, 256,m+1 )
deviationData = FLTARR(256, 256,m+1 )

timeAdjustedData = dataInMinutes(*,*,0:m)


FOR i = 0, 256 - 1 DO BEGIN
  FOR j = 0, 256 - 1 DO BEGIN
    nightAverage(i,j)=MEAN(timeAdjustedData(i,j,*))
  ENDFOR
ENDFOR

FOR p=0,m do begin
  deviationData(*,*,p) = (timeAdjustedData(*,*,p)); - nightAverage(*,*))
ENDFOR


print,min(deviationData)
print,max(deviationData)


save, deviationData, filename=sourceFile+saver


Q=M_FFT_AMTM_LOOP(shortPeriodData, locationToSaveTo=endDir)

beep
END