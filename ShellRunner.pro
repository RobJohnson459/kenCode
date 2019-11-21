PRO ShellRunner

; read what months we have to do from /<driveName>/months.txt
openr, 2, 'D:months.txt'
monthsArray = []
dataReader = ''
WHILE  NOT eof(2) DO BEGIN
  readf, 2, dataReader
  monthsArray = [monthsArray, dataReader]
ENDWHILE
close, 2

;print, monthsArray; Unit test PASSED

; loop over all the months
;FOR

; read what month name to use from first line of days.txt
; 
; FOR a in individualDaysArray (Yeah, this is python. Its also pseudocode. I'm allowed to write how I need to convey the idea to myself and only myself. Holy cow I'm droning on.
;   start = a[1] end = a[2] month = month, day = position
;
; 
; 
; call read_images.pro
;   start = start, end = end, saver = userDefinedReceptacleLocation + month.string + day.string, 
; ENDFOR
;ENDFOR
;   
;   
END