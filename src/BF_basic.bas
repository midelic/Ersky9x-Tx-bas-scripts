rem ----By Midelic
rem --- script to change PID&Rates
rem --- in betaflight using sport frames
rem --- for TX using ersky9x firmware
rem --- ported from betaflight TX LUA script to tiny basic language used by ersky9x
rem --- https://github.com/betaflight/betaflight-tx-lua-scripts


if init = 0
	init = 1
		
SPORT_MSP_VERSION = 32
SPORT_MSP_STARTFLAG = 16
LOCAL_SENSOR_ID = 0x0D
REMOTE_SENSOR_ID = 0x1B
REQUEST_FRAME_ID = 0x30
REPLY_FRAME_ID  = 0x32	
MSP_RC_TUNING     = 111
MSP_SET_PID       = 202
MSP_PID           = 112
MSP_SET_RC_TUNING = 204
MSP_PID_ADVANCED     = 94
MSP_SET_PID_ADVANCED = 95
MSP_EEPROM_WRITE = 250
REQ_TIMEOUT = 80

PAGE_DISPLAY = 2
EDITING      = 3
PAGE_SAVING  = 4
MENU_DISP    = 5
TEST = 6
	
currentPage = 1
currentLine = 1
saveTS = 0
saveRetries = 0	
gState = PAGE_DISPLAY

	sportMspSeq = 0
	sportMspRemoteSeq = 0
    sportMspRemoteSeqm = 0
	rem --- Rx values
	array byte mspRxBuf[32]
	mspRxIdx = 1
	mspRxCRC = 0
	mspStarted = false
	mspLastReq = 0
	
	rem --- TX values
	array byte mspTxBuf[34]
	mspTxIdx = 1
	mspTxCRC = 0
	mspTxPk = 0

	mspRequestsSent = 0
	mspRepliesReceived = 0
	mspPkRxed = 0
	mspErrorPk = 0
	mspStartPk = 0
	mspOutOfOrder = 0
	mspCRCErrors = 0
	
	array byte payload[7]
	array byte payloadTx[7]
	array byte payloadReq[32]
	array byte values[32]
	array byte values_pid[32]
	array byte values_rates[32]
	array byte value[32]
	
    val = 0
	lastReqTS = 0	
	result = 0
	startm = 0
	headm = 0
	err_flag = 0
	now = 0
	seq = 0
	ret = 0
lastRunTS =0
end

goto run

reset:
	mspRequestsSent = 0
	mspRepliesReceived = 0
	mspPkRxed = 0
	mspErrorPk = 0
	mspStartPk = 0
	mspOutOfOrder = 0
	mspCRCErrors = 0
return


mspSendRequest:
 rem -- busy
  if t_size != 0
 return
  end
   
mspTxBuf[1] = p_size
mspTxBuf[2] = cmnd & 0xFF

if p_size > 1
j=1
while  j <= p_size
mspTxBuf[j+2] = payloadReq[j]
j=j+1
end
end

mspLastReq = cmnd
mspRequestsSent = mspRequestsSent + 1
t_size = p_size + 2
gosub mspProcessTxQ
return



mspProcessTxQ:
if t_size = 0
return
end
rem---need here code to check if the previous frame is sent before send the next
rest = sportTelemetrySend(0xFF)
if rest = 0 
return 
end

j = 1
while j <= 6
payloadTx[j] = 0
j=j+1
end

mspRequestsSent = mspRequestsSent + 1

payloadTx[1] = sportMspSeq+ SPORT_MSP_VERSION
sportMspSeq += 1
sportMspSeq = sportMspSeq & 0x0F
	
	
  if mspTxIdx = 1 
  rem --- start flag only for id=1
  payloadTx[1] = payloadTx[1] + SPORT_MSP_STARTFLAG
  end

 i = 2
  while i <= 6
  rem --- payloadTx[2]=payload size
   payloadTx[i] = mspTxBuf[mspTxIdx]
    mspTxIdx = mspTxIdx + 1
    mspTxCRC ^= payloadTx[i]
    i = i + 1
    if mspTxIdx > t_size
     goto break1
     end
end 

break1:

		
if i <= 6 
payloadTx[i] = mspTxCRC  
      i = i + 1
	  rem --- zero fill
     while i <= 6 
     payloadTx[i] = 0
      i = i + 1
      end 	  
gosub mspSendSport

rem ---reset buffer
j = 1
while j < 32
mspTxBuf[j] = 0
j = j + 1
end
t_size = 0
mspTxIdx = 1
mspTxCRC = 0
return
end
 
gosub mspSendSport
return


mspSendSport:
dataId = 0
dataId=payloadTx[1] + payloadTx[2] * 256
value = 0
value = payloadTx[3] + payloadTx[4] * 256 + payloadTx[5] * 65536 + payloadTx[6] * 16777216
reti = sportTelemetrySend(LOCAL_SENSOR_ID, REQUEST_FRAME_ID, dataId, value)
if reti > 0 	
mspTxPk = mspTxPk + 1
end
return 


mspReceivedReply:

	mspPkRxed += 1  
	idx = 1
	head = payload[idx]
	
	headm = head & 0x20
	
	if headm # 0 
	err_flag = 1
	else
	err_flag = 0
	end
	
	idx += 1

	if err_flag = 1
		mspStarted = 0
		mspErrorPk += 1
	ret = 0
	return	
	end
 
   	startm = head & 0x10
	
	if startm # 0
	start = 1
	else
	start = 0
	end
	
	seq = head & 0x0F
		
	if start	
	
	 j = 1
 	while j< 32
 	mspRxBuf[j]=0
 	j = j+1
 	end
	
	sportMspRemoteSeqm = sportMspRemoteseq + 1
	sportMspRemoteSeqm = sportMspRemoteSeqm & 0x0F    
	mspRxIdx = 1
		mspRxSize = payload[idx]
        mspRxCRC = mspRxSize ^ mspLastReq
		idx += 1
		mspStarted = true      
		mspStartPk += 1		
	elseif mspStarted = false	
	mspOutOfOrder += 1
     ret = 0		
      rem return
	elseif sportMspRemoteseqm # seq                     
	mspOutOfOrder += 1
	 rem mspStarted = false
     ret = 0		
	rem return	
	end
		
		
	while (idx <= 6) & (mspRxIdx <= mspRxSize)
	  mspRxBuf[mspRxIdx] = payload[idx]
	   mspRxCRC ^= payload[idx]
	  mspRxIdx += 1		
	   idx += 1
	   end
	
	
	if idx > 6
	sportMspRemoteSeq = seq
	ret = 1
    return	
	end

	if mspRxCRC # payload[idx]
		mspStarted = 0
		mspCRCErrors += 1
    ret = 0		
	return	
	end
	
	mspRepliesReceived += 1
	mspStarted = 0
	ret = 2
	rem --return mspRxBuf
return


mspPollReply:
while 1
      result = sportTelemetryReceive( physicalId, primId, dataId , value)
		 if result > 0		 
			if (physicalId = 0x1B) & (primId = 0x32)
				j=1
				while j<=6
				payload[j]=0				
				j = j+1
				end
					payload[1] = dataId & 0xFF
					dataId /= 256					
					payload[2] = dataId & 0xFF					
					payload[3] = value & 0xFF
					value /= 256
					value = value & 0xFFFFFF
					payload[4] = value & 0xFF
					value /= 256					
					payload[5] = value & 0xFF
					value /= 256
					payload[6] = value & 0xFF					
					gosub mspReceivedReply
                    if ret = 2
					cmd = mspLastReq
					return			
					end					
					else
				   cmd = 0
			       return
                   end					
			else
			cmd = 0
			return
		    end		   
 end
return


processMspReply:

if cmd = 0
return
end

page = currentPage
gosub SetupPages

rem ---ignore write for now

 if cmd = write
 cmnd = MSP_EEPROM_WRITE
 p_size = 0
 gosub payload_zero
 gosub mspSendRequest
 return
 end

 if cmd = MSP_EEPROM_WRITE
     gState = PAGE_DISPLAY
     gosub empty_buffer
     saveTS = 0
 end

  if cmd != read
 return
 end 
   
 if ret = 2
 if mspRxIdx > 1
 j = 1
 while j <= mspRxIdx
 if page = 1
 values_pid[j] = mspRxBuf[j]
 else
 values_rates[j] = mspRxBuf[j]
 end
 j += 1
 end
 end
 ret = 0
 end
return

empty_buffer:
      j = 1
 	  while j <= packet_size
	  if page = 1
	  values_pid[j] = 0
	  else
 	  values_rates[j] = 0
	  end
 	  j += 1
 	  end
return

payload_zero:
j = 1
while j < 32
payloadReq[j] = 0
j += 1
end
return

requestPage:
if reqTS = 0
reqTS = gettime()
gosub payload_zero
p_size = 0
cmnd = read
gosub  mspSendRequest
elseif reqTS + REQ_TIMEOUT <= gettime()
reqTS = gettime()
gosub payload_zero
p_size = 0
cmnd = read
gosub  mspSendRequest
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
if page =1
values[z] = values_pid[z]
else
values[z] = values_rates[z]
end
values[z] += 1
val = values[z]

gosub clipValue

values[z] = val
if page = 1
values_pid[z] = values[z]
else
values_rates[z] = values[z]
end
return


decValue:
page= currentPage
z = currentLine
if page = 1
values[z] = values_pid[z]
else
values[z] = values_rates[z]
end
values[z] -= 1
val = values[z]
gosub clipValue
values[z] = val
if page = 1
values_pid[z] = values[z]
else
values_rates[z] = values[z]
end
return

clipValue:
 if val < 0 
      val = 0
elseif val > 255 
      val = 255
   end
return


SetupPages:
if page = 1
rem --- 0x1E size
packet_size = 30
MaxLines = 8
read = MSP_PID
write = MSP_SET_PID

elseif page = 2
rem ---0x0C size
packet_size = 12
MaxLines = 7
read = MSP_RC_TUNING
write = MSP_SET_RC_TUNING
end
return



drawScreen:
if page = 1
drawtext( 0, 0, "Betaflight / PIDs", INVERS )
drawtext( 111, 0, "1/5", 0 )
	 
drawtext( 4, 25, "Roll", 0 )
drawtext( 4, 36, "Pitch", 0 )
drawtext( 4, 47, "Yaw", 0 )	 
	 
drawtext( 50, 14, "P", 0 )
drawtext( 78, 14, "I", 0 )
drawtext( 106, 14, "D", 0 )


 j = 1
gosub selectone
drawnumber( 55, 25, values_pid[j], text_options )
j += 1
gosub selectone
drawnumber( 83, 25, values_pid[j], text_options)
j += 1
gosub selectone
drawnumber( 111, 25, values_pid[j], text_options )
j += 1
gosub selectone
drawnumber( 55, 36, values_pid[j], text_options )
j += 1
gosub selectone
drawnumber( 83, 36, values_pid[j], text_options )
j += 1
gosub selectone
drawnumber( 111, 36, values_pid[j], text_options )
j += 1
gosub selectone
drawnumber( 55, 47, values_pid[j], text_options )
j += 1
gosub selectone
drawnumber( 83, 47, values_pid[j], text_options )

rem j += 1
rem gosub selectone
rem drawnumber( 111, 47, values_pid[j],text_options )


elseif page = 2 
drawtext( 0, 0, "Betaflight / Rates", INVERS )
drawtext( 111, 0, "2/5", 0 )

drawtext( 4, 25, "Roll", 0 )
drawtext( 4, 36, "Pitch", 0 )
drawtext( 4, 47, "Yaw", 0 )

drawtext( 39, 9, "RC", 0 )
drawtext( 39, 16, "Rate", 0 )

drawtext( 69, 9, "Super", 0 )
drawtext( 69, 16, "Rate", 0 )

drawtext( 97, 9, "RC", 0 )
drawtext( 97, 16, "Expo", 0 )



j = 1
gosub selectone
drawnumber( 55, 30, values_rates[j], text_options)
j += 1
gosub selectone
drawnumber( 111, 30, values_rates[j], text_options)
j += 1
gosub selectone
drawnumber( 83, 25, values_rates[j], text_options )
j += 1
gosub selectone
drawnumber( 83, 36, values_rates[j], text_options )
j += 1
gosub selectone
drawnumber( 83, 47,values_rates[j], text_options )
j += 1
gosub selectone
drawnumber( 55, 47, values_rates[j+6], text_options)
j += 1
gosub selectone
drawnumber( 111, 47, values_rates[j+6], text_options)
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
j = 1
c = 1
v_flag = 0
while j <= packet_size
if page = 1
if values_pid[j] = 0
c += 1
end
else
if values_rates[j] = 0
c += 1
end

end
j += 1
end

rem --if all values are zero
if c  >=  packet_size
v_flag = 0
else
v_flag = 1
end

return


saveSettings:
rem --write commands
gosub check_values
   if v_flag
      cmnd = write
      p_size = packet_size
	  j = 1
	  while j <= packet_size
      if page = 1
	   payloadReq[j] = values_pid[j]
      else
	   payloadReq[j] = values_rates[j]
       end	  
	  j = j+1
	  end
      gosub mspSendRequest


      saveTS = gettime()
      if gState = PAGE_SAVING 
         saveRetries = saveRetries + 1
      else
       gState = PAGE_SAVING
      end	  
end
return


invalidatePages:
j = 1
while j < 32
values_pid[j] = 0
values_rates[j] = 0
j += 1
end
gState = PAGE_DISPLAY
saveTS = 0
return

drawTestScreen:
rem ---here you can add any variable that you want to be displayed on the screen 
rem ---for debugging purposes

rem drawnumber(40, 11, payloadTx[1], 0)
		drawnumber(40, 11, mspRxBuf[1], 0)
		    
rem drawnumber(40, 21, payloadTx[2], 0)
		drawnumber(40, 21, mspRxBuf[2], 0)
       
rem drawnumber(40, 31, payloadTx[3], 0)  
         drawnumber(40, 31, mspRxBuf[3], 0) 
	  
rem drawnumber(40, 41, payloadTx[4], 0)
		drawnumber(40, 41, mspRxBuf[4], 0)
		
rem drawnumber(100, 11, payloadTx[5], 0)
        drawnumber(100, 11, mspRxBuf[5], 0)
	  
rem drawnumber(100, 21, payloadTx[6], 0)
		drawnumber(100, 21, mspRxBuf[6], 0)
		drawnumber(40, 51,  mspRxBuf[7], 0)		
		drawnumber(100,31,mspRxBuf[8],0)				
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
  
      
 if t_size > 0 
 gosub mspProcessTxQ
 end

 rem  -- navigation
  
 if Event = EVT_MENU_LONG
         menuActive = 1
         gState = MENU_DISP		 
rem -- menu is currently displayed 
 elseif gState = MENU_DISP
         if Event = EVT_EXIT_BREAK 
         gState = PAGE_DISPLAY
         elseif Event = EVT_UP_BREAK	 
         gosub incMenu
         elseif Event = EVT_DOWN_BREAK
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
     elseif Event = EVT_UP_BREAK
		 gosub decLine
	  elseif Event = EVT_DOWN_BREAK	 
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
         gState = PAGE_DISPLAY
	     elseif Event = EVT_UP_BREAK
		 gosub incValue 
         elseif Event = EVT_DOWN_BREAK
	     gosub decValue 
	 end
	 end

   	
   page = currentPage
   gosub SetupPages
   gosub check_values 
   
   if v_flag = 0
   gosub requestPage 
   end

drawclear()
rem gosub drawScreen
if getvalue("RSSI") = 0 
 drawtext(30, 55, "No Telemetry", BLINK)
 gosub invalidatePages
 end

 if gState = MENU_DISP
 gosub  drawMenu
 elseif gState = PAGE_SAVING
 drawrectangle(12,12,104,30)
 drawtext(16,22,"Saving...",DBLSIZE + BLINK)
 elseif gState = PAGE_DISPLAY
 gosub drawScreen
 elseif  gState = EDITING
 gosub drawScreen
 elseif gState = TEST
 gosub drawTestScreen
 end
  
 if Event = EVT_EXIT_BREAK
 gState = PAGE_DISPLAY
 elseif Event = EVT_LEFT_FIRST
 gState = TEST
 end
   
gosub mspPollReply
gosub processMspReply

stop
done:
finish
