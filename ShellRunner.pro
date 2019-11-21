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
  FOR j=0, N_ELEMENTS(daysArray)-1 DO BEGIN ; go through all the days in the array
    dayInfo = daysArray[j].split(' ')
;    read_images(monthName + dayInfo[0], 'D:' + monthsArray[i] + '\' , uint(daysInfo[1]), uint(daysInfo[2])
  ENDFOR
ENDFOR
;   
;   
END