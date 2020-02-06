rem ----By Midelic
rem --- script to change DIY RX/JUMPER R8 parameters



if init = 0
init = 1

rem --transmit--
rem physicalId = 0x17
rem primId = 0x30
rem primId = 0x31
rem dataId = 0x0c20

rem --receive--
rem physicalId = 0x1B 
rem primId = 0x32
rem dataId = 0x0c20


LOCAL_SENSOR_ID = 0x17
REQUEST_FRAME_ID = 0x30
DATA_ID = 0x0C20
rem--
REMOTE_SENSOR_ID = 0x1B
REPLY_FRAME_ID = 0x32

rem--read modes
CFG_MODES = 0xE4

rem--write modes	
CFG_SET_MODES = 0xE4
REQUEST_SET_FRAME_ID = 0x31

rem--read
CFG_STATISTICS = 0xE5
CFG_STATISTICS2 = 0xE6
REQ_TIMEOUT = 80

PAGE_DISPLAY = 2
EDITING      = 3
PAGE_SAVING = 4
MENU_DISP    = 5
TEST = 6

currentPage = 1
currentLine = 1
saveTS = 0
saveRetries = 0	
gState = PAGE_DISPLAY

rem --- Rx values
array byte cfgRxBuf[10]
cfgRxIdx = 1	
rem --- TX values
array byte cfgTxBuf[10]
cfgTxIdx = 1
cfgRequestsSent = 0
cfgRepliesReceived = 0
array byte payload[10]
array byte payloadTx[10]
array byte payloadReq[10]
array byte values[10]
array byte values_servo[5]	
values_modes = 0
values_sbus = 0
values_proto = 0
values_sport = 0
k = 0
values_servo[0] = 0
values_servo[1] = 225
values_servo[2]	= 180
values_servo[3] = 90
array byte values_page[6]	
values_page[1] = values_modes
rem values_page[2] = values_servo[0]
values_page[3] = values_sbus
values_page[4] = values_sport
values_page[5] = values_proto	
array byte values_statistics[10]		
cfg_mode = 0 
value = 0	
val = 0
result = 0
now = 0
ret = 0
lastRunTS =0
end

goto run

reset:
cfgRequestsSent = 0
cfgRepliesReceived = 0
cfgPkRxed = 0
cfgErrorPk = 0
cfgStartPk = 0
return




cfgSendRequest:
rem -- busy
if t_size != 0
return
end

cfgTxBuf[1] = cmd & 0xFF

if page = 2
if cfgTxPk > 0
cmd = CFG_STATISTICS2
cfgTxPk = 0
end
end


if p_size > 1
j = 2
p_size += 1
while  j <= p_size
cfgTxBuf[j] = payloadReq[j-1]
j=j+1
end
end

cfgLastReq = cmd
cfgRequestsSent += 1
t_size = 1
gosub cfgProcessTxQ
return



cfgProcessTxQ:
if t_size = 0
return
end

rem---need here code to check if the previous frame is sent before send the next
rest = sportTelemetrySend(0xFF)
if rest = 0 
return 
end

j = 1
while j <= 4
payloadTx[j] = 0
j+=1
end

if p_size > 1
if cfgTxBuf[2]<=4
temp = 4 - cfgTxBuf[2]
end
n = 0
v = 1
while n <= temp
v *=2
n +=1
end
cfgTxBuf[2]= v
cfgTxBuf[5] *= 4
cfgTxBuf[6] *= 16 
cfgTxBuf[4] = cfgTxBuf[4]+cfgTxBuf[5]+cfgTxBuf[6]
end

i = 1
while i <= 4
payloadTx[i] = cfgTxBuf[i]
i += 1
end
t_size = 0

i = 1
while i <= p_size
cfgTxBuf[i] = 0
i += 1
end

value = 0
value = payloadTx[1] + payloadTx[2] * 256 + payloadTx[3] * 65536 + payloadTx[4] * 16777216
rem = 0xE4+ modes*256 + servo*65536+(sbus+sport+protocol)* 16777216 
reti = sportTelemetrySend(LOCAL_SENSOR_ID, REQUEST_FRAME_ID, DATA_ID, value)
if reti > 0 	
cfgTxPk = cfgTxPk + 1
return 


cfgPollReply:
while 1
result = sportTelemetryReceive( physicalId, primId, dataId ,value)
if result > 0		 
if primId = REPLY_FRAME_ID
j = 1
while j <= 6
payload[j] = 0				
j = j+1
end
if dataId = 0x0C20				
payload[1] = value & 0xFF
value /= 256
value = value & 0xFFFFFF
payload[2] = value & 0xFF
value /= 256					
payload[3] = value & 0xFF
value /= 256
payload[4] = value & 0xFF					
gosub cfgReceivedReply
if cfgRepliesReceived > 0
return
end
end 				 
end
end
break		
end
return


cfgReceivedReply:
idx = 1
cfgRxIdx = 1
while cfgRxIdx <= 4
cfgRxBuf[cfgRxIdx] = payload[idx]
cfgRxIdx += 1
idx += 1
end
rem -- flag received data
cfgRepliesReceived += 1 
return


processcfgReply:
if cmd = 0
return
end

page = currentPage
gosub SetupPages

rem if cmd = write
if REQUEST_FRAME_ID = REQUEST_SET_FRAME_ID
p_size = 0
gosub payload_zero
gosub empty_buffer
return
end

if cfgRxIdx > 1

if page =  1

if v_flag = 0
cfg_mode = cfgRxBuf[1]

n = 0
while n <= 4
cfg_mode /= 2
if cfg_mode = 1
break
end
n += 1
end

if n <= 4
n = (4-n)
end

values_proto = cfgRxBuf[4]

if values_proto = 1
values_modes = 0
else
values_modes = 1
end

if  cfgRxBuf[2] = 225
k = 1
elseif cfgRxBuf[2] = 180
k = 2
elseif cfgRxBuf[2] = 90 
k = 3
end 

values_sbus = cfgRxBuf[3] & 0x0F
values_sport = (cfgRxBuf[3] & 0xF0)/16
end

elseif page = 2
if cfgLastReq = CFG_STATISTICS2
values_statistics[1] = cfgRxBuf[1] + cfgRxBuf[2]*256
values_statistics[2] = cfgRxBuf[3]
values_statistics[3] = cfgRxBuf[4]
elseif cfgLastReq = CFG_STATISTICS
values_statistics[4] = cfgRxBuf[1] + cfgRxBuf[2]*256
values_statistics[5] = cfgRxBuf[3] + cfgRxBuf[4]*256
end
cfgRxIdx = 1
end
end
return




empty_buffer:
if page = 1
values_modes = 0
k = 0;
values_sbus = 0
values_proto = 0
values_sport = 0 
elseif page = 2
i = 1
while i <= 5 
values_statistics[i] = 0
i += 1
end
end
return

payload_zero:
j = 1
while j <= 4
payloadReq[j] = 0
j += 1
end
return


requestPage:
if reqTS = 0
reqTS = gettime()
gosub payload_zero
p_size = 0
cmd = read
REQUEST_FRAME_ID = 0x30
gosub  cfgSendRequest

elseif reqTS + REQ_TIMEOUT <= gettime()
reqTS = gettime()
gosub payload_zero
p_size = 0
cmd = read
REQUEST_FRAME_ID = 0x30
gosub  cfgSendRequest
end
return


incLine:
currentLine = currentLine + 1
if currentLine > MaxLines 
currentLine = 1
elseif currentLine < 1 
currentLine = MaxLines
end
return 

decLine:
currentLine = currentLine - 1
if currentLine > MaxLines 
currentLine = 1
elseif currentLine < 1 
currentLine = MaxLines
end
return

incPage:
currentPage = currentPage + 1
if currentPage > 2 
currentPage = 1
elseif currentPage < 1 
currentPage = 2
end
currentLine = 1
return



incValue:
page = currentPage
z = currentLine
if page = 1
values[z] = values_page[z]
rem end
if z = 2
k += 1
else
values[z] += 1
end
val = values[z]
gosub clipValue

values[z] = val


rem if page = 1
values_page[z] = values[z]
if z = 1
values_modes = values_page[z]
elseif z = 3
values_sbus = values_page[z]
elseif z = 4
values_sport = values_page[z]
elseif z = 5
values_proto = values_page[z]
end
end
return


decValue:
page= currentPage
z = currentLine
if page = 1
values[z] = values_page[z]
end
if z = 2
k -= 1
else
values[z] -= 1
end
val = values[z]
gosub clipValue
values[z] = val

rem if page = 1
values_page[z] = values[z]
if z = 1
values_modes = values_page[z]
elseif z = 3
values_sbus = values_page[z]
elseif z = 4
values_sport = values_page[z]
elseif z = 5
values_proto = values_page[z]
end
end
return

clipValue:
if val < 1 
val = 1
end
if k < 1
k = 1
elseif k > 3
k = 3
end
if z = 2
if val < 90
val = 90
elseif val >225 
val = 225	  
end
elseif z = 4
if val > 2
val = 2
end	  
elseif z = 5
if val > 3
val = 3
end
elseif z = 1
if val > 4
val = 4
end
else
if val > 2
val = 2
end 	
end
return


SetupPages:
if page = 1
packet_size = 5
MaxLines = 5
read = CFG_MODES
write = CFG_SET_MODES
elseif page = 2
packet_size = 5
MaxLines = 5
read = CFG_STATISTICS
end
return



drawScreen:
if page = 1
drawtext( 0, 0, "RX-MODES", INVERS )
drawtext( 111, 0, "1/2", 0 )

drawtext( 4, 10, "Modes", 0 )
drawtext( 4, 21, "Servo[ms]", 0 )
drawtext( 4, 32, "Sbus_Inv", 0 )	
drawtext( 4, 43, "Sport_Inv", 0 )	
drawtext( 4, 54, "Protocol", 0 )	

j = 1
gosub selectone
if values_modes = 0 then drawtext(60, 10, "NS", text_options)
if values_modes = 1 then drawtext(60, 10, "1-8", text_options)
if values_modes = 2 then drawtext(60, 10, "1-8NT", text_options.)
if values_modes = 3 then drawtext(60, 10, "9-16", text_options)
if values_modes = 4 then drawtext(60, 10, "9-16NT", text_options)
j += 1
gosub selectone
drawnumber( 76, 21, values_servo[k], text_options+PREC1)
j += 1
gosub selectone
if values_sbus = 0 then drawtext(60, 32, "NS",text_options)
if values_sbus = 1 then drawtext(60, 32, "NO",text_options)
if values_sbus = 2  then drawtext(60, 32, "YES",text_options)
j += 1
gosub selectone

if values_sport = 0 then drawtext(60, 43, "NS",text_options)
if values_sport = 1 then drawtext(60, 43, "NO",text_options)
if values_sport = 2  then drawtext(60, 43, "YES",text_options)

j += 1
gosub selectone
if values_proto = 0 then drawtext(60, 54, "NS", text_options)
if values_proto = 1 then drawtext(60, 54, "D8", text_options)
if values_proto = 2 then drawtext(60, 54, "D16", text_options)
if values_proto = 3 then drawtext(60, 54, "LBT", text_options)

elseif page = 2 
drawtext( 0, 0, "Statistics", INVERS )
drawtext( 111, 0, "2/2", 0 )

drawtext( 4, 10, "DropPkt", 0 )
drawtext( 4, 21, "Drop%", 0 )
drawtext( 4, 32, "TotCrcErr", 0 )
drawtext( 4, 43, "LbtBlks", 0 )
drawtext( 4, 54, "PktErr", 0 )

j = 1
y = 0
while j < 6
gosub selectone
drawnumber( 65, 10+y, values_statistics[j], text_options )
y += 11
j  += 1
end

end
return



selectone:
text_options = 0
if j = currentLine
text_options = INVERS
if gState = EDITING 
text_options = text_options + BLINK
end
end
return


drawMenu:
x = 12
y = 12
w = 105
menuList_size = 2
h = menuList_size * 8 + 6

drawrectangle( x, y,w-1,h-1 )
drawtext(x+4,y+3,"Menu:")
j = 1
if menuActive = 1
drawtext(x+36,y+(j-1)*8+3,"save page",INVERS	)
j += 1
drawtext(x+36,y+(j-1)*8+3,"reload",0)
else
drawtext(x+36,y+(j-1)*8+3,"save page",0)
j += 1
drawtext(x+36,y+(j-1)*8+3,"reload",INVERS)
end 
return


incMenu:
menuActive = menuActive + 1
if menuActive > 2 
menuActive = 1
elseif menuActive < 1 then
menuActive = 1
end
return

decMenu:
menuActive = menuActive - 1
if menuActive > 2 
menuActive = 1
elseif menuActive < 1 then
menuActive = 1
end
return

check_values:
v_flag = 0

if page = 1
if values_sbus  = 0 & values_modes = 0 & values_proto = 0 & values_sport = 0
v_flag = 0
else
v_flag = 1
end
elseif page = 2
v_flag = 0
end
end

return

saveSettings:
rem --write commands
if v_flag
cmd = write
REQUEST_FRAME_ID = REQUEST_SET_FRAME_ID
j = 1
if page = 1
p_size = packet_size
payloadReq[j] = values_modes
j += 1
payloadReq[j] = values_servo[k]
j += 1
payloadReq[j] = values_sbus
j += 1
payloadReq[j] = values_sport
j += 1	   
payloadReq[j]= values_proto

elseif page = 2
p_size = 0
while j <= 5
payloadReq[j] = values_statistics[i]
j += 1
end
end	  

gosub cfgSendRequest

saveTS = gettime()
if gState = PAGE_SAVING 
saveRetries = saveRetries + 1
else
gState = PAGE_SAVING
end	  
end
return



invalidatePages:
values_modes = 0
k = 0
values_sbus = 0
values_proto = 0
values_sport = 0
j=1
while j < 6
values_statistics[j] = 0
j+=1
end
gState = PAGE_DISPLAY
saveTS = 0
return


run:
now = gettime()

if lastRunTS + 50 < now
gosub SetupPages
gosub invalidatePages
end
lastRunTS = now

if (gState = PAGE_SAVING) & (saveTS + 150 < now)
if saveRetries < 2 
gosub SetupPages
gosub  saveSettings
else
rem  --- two retries and still no success
gState = PAGE_DISPLAY
saveTS = 0
end 
end


rem if t_size > 0 
rem gosub cfgProcessTxQ
rem end

rem  -- navigation
rem  if Event = EVT_LEFT_FIRST
if Event = EVT_MENU_LONG
menuActive = 1
gState = MENU_DISP
end		 
rem -- menu is currently displayed 
if gState = MENU_DISP
if Event = EVT_EXIT_BREAK 
gState = PAGE_DISPLAY
elseif (Event = EVT_UP_FIRST) 
gosub incMenu
elseif (Event = EVT_DOWN_FIRST) 
gosub decMenu		 
elseif Event = EVT_RIGHT_FIRST
gState = PAGE_DISPLAY
if menuActive = 1
gosub  saveSettings
else
gosub invalidatePages
end
end		 
rem   -- normal page viewing	   
elseif gState <= PAGE_DISPLAY
if  Event = EVT_MENU_BREAK 
gosub incPage
elseif Event = EVT_UP_FIRST
gosub decLine
elseif Event = EVT_DOWN_FIRST 
gosub incLine
elseif Event = EVT_RIGHT_FIRST
page = currentPage
gosub SetupPages
gosub check_values
if v_flag
gState = EDITING
end
end
rem   -- editing value
elseif gState = EDITING
if Event = EVT_EXIT_BREAK
values_mod = 1		 
gState = PAGE_DISPLAY
elseif Event = EVT_UP_FIRST
gosub decValue 
elseif Event = EVT_DOWN_FIRST
gosub incValue 		 
end
end


page = currentPage
gosub SetupPages
gosub check_values 

if v_flag = 0
gosub requestPage 
end

drawclear()
if getvalue("RSSI") = 0 
drawtext(30, 55, "No Telemetry", BLINK)
gosub invalidatePages
elseif values_mod = 1
drawtext(10, 55, "Press left to save", BLINK)
elseif values_mod = 0 
if (gState != MENU_DISP) & (gState != PAGE_SAVING)
rem drawtext(4, 55, "Press MENU PAGE", BLINK)
end
end

if gState = MENU_DISP
values_mod = 0
if getvalue("RSSI") != 0 
drawtext(10, 55, "Press right to send", BLINK)
end
gosub  drawMenu
elseif gState = PAGE_SAVING
drawrectangle(12,12,104,22)
drawtext(16,22,"Saving...",DBLSIZE + BLINK)
drawtext(16,40,"Turn Tx OFF", BLINK)
drawtext(1,50,"When saving completed ", BLINK)
elseif gState = PAGE_DISPLAY
gosub drawScreen
elseif  gState = EDITING
gosub drawScreen
if Event = EVT_LEFT_FIRST
gState = PAGE_DISPLAY
end
end

if Event = EVT_EXIT_BREAK
gState = PAGE_DISPLAY
end

gosub cfgPollReply
gosub processcfgReply

stop
done:
finish
