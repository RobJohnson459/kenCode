PRO ShellRunner

; read what months we have to do from /<driveName>/months.txt
openr, 2, 'D:months.txt'
monthsArray = []
dataReader = ''
WHILE NOT eof(2) DO BEGIN
  readf, 2, dataReader
  monthsArray = [monthsArray, dataReader]
ENDWHILE
close, 2

;print, monthsArray; Unit test PASSED

; loop over all the months
FOR i=0, N_ELEMENTS(monthsArray)-1 DO BEGIN ;go through all months in the array
  openr, 2, 'D:' + monthsArray[i] + '\days.txt'
  monthName = '' ;the first element is the needed opener for each directory
  readf, 2, monthName
  daysArray = []
  ; put all the days in an array
  WHILE NOT eof(2) DO BEGIN
    readf, 2, dataReader
    daysArray = [daysArray, dataReader]
  ENDWHILE
  close, 2
  loopEnd = N_ELEMENTS(daysArray)-1
  FOR j=0, loopEnd DO BEGIN ; go through all the days in the array
    dayInfo = daysArray[j].split(' ')

    ;This nested if statement is to make sure we don't have two files from the same night overlap and overwrite each other.
    dirSubtitle = ''
    IF j GT 1 THEN BEGIN
      IF dayInfo[0].equals(daysArray[j-1]) THEN BEGIN
        dirSubtitle = dayInfo[1] + '-' + dayInfo[2]
      ENDIF
    ENDIF
          
    IF j LT (loopEnd -1) THEN BEGIN
      IF dayInfo[0].equals(daysArray[j+1].split(' ')[0]) THEN BEGIN
        dirSubtitle = dayInfo[1] + '-' + dayInfo[2]
      ENDIF
    ENDIF

    
    FILE_MKDIR, 'C:\Users\Masaru\Documents\robCode\MCM_AMTM_2018\' + monthsArray[j] + '\' + monthName + dayInfo[0] + dirSubtitle
    read_images(dateString = monthName + dayInfo[0], sourcePath = 'D:' + monthsArray[i] + '\' , begins = uint(daysInfo[1]), ends = uint(daysInfo[2]), 
    $ endDir = 'C:\Users\Masaru\Documents\robCode\MCM_AMTM_2018\' + monthsArray[j] + '\' + monthName + dayInfo[0] + dirSubtitle
  ENDFOR
ENDFOR
;   
;   
END