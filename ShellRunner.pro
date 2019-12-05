PRO ShellRunner

; read what months we have to do from /<driveName>/months.txt
openr, 2, 'D:months.txt'
monthsArray = []
dataReader = ''
WHILE NOT eof(2) DO BEGIN
  readf, 2, dataReader
  IF dataReader.Contains('#') THEN BEGIN
    CONTINUE
  ENDIF ELSE BEGIN
    monthsArray = [monthsArray, dataReader]
  ENDELSE
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
      IF dataReader.Contains('#') THEN BEGIN
        CONTINUE
      ENDIF ELSE BEGIN
            daysArray = [daysArray, dataReader]
      ENDELSE
  ENDWHILE
  close, 2
  loopEnd = N_ELEMENTS(daysArray)-1
  FOR j=0, loopEnd DO BEGIN ; go through all the days in the array
    dayInfo = daysArray[j].split(' ')

    ;The subtitle is to distinguish between data from the same days.
    dirSubtitle = '____' + dayInfo[1] + '-' + dayInfo[2]

    date = monthName + dayInfo[0]
    path = 'D:' + monthsArray[i] + '\'
    futurePath = 'C:\Users\Masaru\Documents\robCode\MCM_AMTM_2018\newData\' + monthsArray[i] + '\' + monthName + dayInfo[0] + dirSubtitle
    
    FILE_MKDIR, futurePath
    q = read_images(dateString = date, sourcePath = path, begins = uint(dayInfo[1]), ends = uint(dayInfo[2]), endDir = futurePath)
    debugStop = 1
;            
;            This is left for debugging
;    print, (monthName + dayInfo[0]), ('D:' + monthsArray[i] + '\' ), uint(dayInfo[1]), uint(dayInfo[2]), $
;      ('C:\Users\Masaru\Documents\robCode\MCM_AMTM_2018\newData\' + monthsArray[i] + '\' + monthName + dayInfo[0] + dirSubtitle)
  ENDFOR
ENDFOR
;   
;   
END