--Developed by LNETeam
--Please respect Open Source and due credit
--You can use this utility in your program as long as this banner remains

tArgs = {...}
stat,err = pcall(function()


 function literalize(s)
	return string.gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]",function (c) return "%" .. c end)
end

function lmap(message,sender)
	local net_base = textutils.unserialize(message) --Unserialize the network object
	local net = NetworkCollection.RepairType(net_base,"network") --Repair network object
	
	
	local home = NetworkCollection.new.Computer(net,sender) --Create new computer for (current) host with the global network and parent as parameters

	home:AnalyzeForInterfaces() --Get interfaces

	net:AddComputer(home)
	net:AddCompletedId(os.getComputerID())

	
	for r,t in ipairs(home:GetMountedInterfaces()) do --Foreach interface..

		rednet.open(t:GetSide()) --Open the network

		local found = {rednet.lookup("ip-mon:netwisp")} -- Lookup all computers immediately connected that are ready for a netmap

		if #found > 0 then --Um..
			for k,v in ipairs(found) do --Loop through found clients

				if (not net:ContainsId(v)) then
					rednet.send(v,"request:map", "ip-mon:netwisp") --Send a map request
					local senderId,message,protocol = rednet.receive("ip-mon:netwisp",2) --increase if required
					if senderId ~= nil and message ~= nil then --Ensure that we got a genuine reply
						if senderId == v then --If the computer that was sent to and the reply are the same
							if message == "request:map:yes" then --The computer approves map
								local connection = NetworkCollection.new.AuthenticationBinding(v,os.getComputerID()) --New binding key. This is for future reference that it is indeed the intended host
								rednet.send(v,"request:map:execute","ip-mon:netwisp") --Send execution command
								sleep(0.5) --Wait for client to process

								rednet.send(v,textutils.serialize(net),"ip-mon:netwisp") --Send serialized network object (yes, everything. Could consider sending a new network and merging the, but meh)
								local sId,mge,pr = rednet.receive("ip-mon:netwisp") --Wait for the map to finish. May take a VERY long time depending on the size of the network
								
								if connection:IsMember(sId) then --If the message originated from paired computer
									--net = NetworkCollection.RepairType(mge,"network") --Repair the returned network object to a usable state
									net = textutils.unserialize(mge)
									net = NetworkCollection.RepairType(net,"network")
								end --Untrusted
							end
						end
					end
				end
			end
		end
		rednet.close(t:GetSide()) --Close the side to prevent re-mapping (infinite recursion)
	end
	home:OpenAllInterfaces()
	rednet.send(tonumber(sender),textutils.serialize(net),"ip-mon:netwisp")

	home:CloseAllInterfaces()
	mon()
end

function mon()
	local comp = NetworkCollection.new.Computer(nil) --New temporary computer (to get the mounted interfaces)
	comp:AnalyzeForInterfaces()
	local intfs = comp:GetMountedInterfaces() --Interfaces
	comp:OpenAllInterfaces()
	rednet.host("ip-mon:netwisp","ip-mon:"..math.random()) --Host the waiting map protocol
	local senderId, message, protocol = rednet.receive("ip-mon:netwisp") --Request
	if message ~= nil then --If the message is something
		if message == "request:map" then --If the message is to map
			rednet.send(senderId,"request:map:yes","ip-mon:netwisp") --Send back with a confirmation
			
			local senderId,message,protocol = rednet.receive("ip-mon:netwisp") --Get execution request


			if message == "request:map:execute" then

				local senderId,message,protocol = rednet.receive("ip-mon:netwisp") --sending of network data packet
				comp:CloseAllInterfaces() --Close all interfaces (no more comms with parent, but parent is saved as the sender id which is recovered by using the NetworkCollection.GetComputerByID() method and repaired by NetworkCollection.RepairType())
				lmap(message,senderId)
			end
		end
	end
end

function bgProcesor()

	while true do
		local event = { os.pullEvent() }
		if event[ 1 ] == "kill_mon" then
			os.queueEvent("terminated")
		  return
		end
	end
end

function termHandler()
	parallel.waitForAny(bgProcesor,mon)
	local sides = {"top","bottom","left","right","front","back"}
	local mounted = {}
	for k,v in ipairs(sides) do
		if (peripheral.isPresent(v) and peripheral.getType(v) == "modem") then
			rednet.close(v)

		end
	end
	print("Process: ip-mon, stopped")
	return
end

if fs.exists("netwisp.data/NetworkCollection") then os.loadAPI("netwisp.data/NetworkCollection") else error("missing critical data type...\ncannot continue")end --Ensure they have the proper data type
if #tArgs == 0 then
	error("ip-mon: Expected mode",2) --Need something
elseif  #tArgs == 1 then
	if tArgs[1] == "--imap" then --Network map option
		local net = NetworkCollection.new.Network()--New Global network map object

		net:StartMap() --Begin local and global map
		net:AddCompletedId(os.getComputerID())
		local lcomp = net:GetComputerByID(os.getComputerID())
		lcomp:CloseAllInterfaces()
		if (#lcomp:GetMountedInterfaces() > 0) then --Find "mounted" interfaces
			for k,v in ipairs(net:GetComputerByID(os.getComputerID()):GetMountedInterfaces()) do --Foreach interface..
				rednet.open(v:GetSide()) --Open the network
				
				local found = {rednet.lookup("ip-mon:netwisp")} -- Lookup all computers immediately connected that are ready for a netmap
				if #found > 0 then --Um..
					for k,v in ipairs(found) do --Loop through found clients
						if (not net:ContainsId(v)) then
							rednet.send(v,"request:map", "ip-mon:netwisp") --Send a map request
							local senderId,message,protocol = rednet.receive("ip-mon:netwisp",2) --increase if required
							if senderId ~= nil and message ~= nil then --Ensure that we got a genuine reply
								if senderId == v then --If the computer that was sent to and the reply are the same
									if message == "request:map:yes" then --The computer approves map
										local connection = NetworkCollection.new.AuthenticationBinding(v,os.getComputerID()) --New binding key. This is for future reference that it is indeed the intended host
										rednet.send(v,"request:map:execute","ip-mon:netwisp") --Send execution command
										sleep(0.5) --Wait for client to process
										rednet.send(v,textutils.serialize(net),"ip-mon:netwisp") --Send serialized network object (yes, everything. Could consider sending a new network and merging the, but meh)
										local sId,mge,pr = rednet.receive("ip-mon:netwisp") --Wait for the map to finish. May take a VERY long time depending on the size of the network
										
										if connection:IsMember(sId) then --If the message originated from paired computer
											--net = NetworkCollection.RepairType(mge,"network") --Repair the returned network object to a usable state
											net = textutils.unserialize(mge)
											net = NetworkCollection.RepairType(net,"network")
										end --Untrusted
									end
								end
							end
						end
					end
				end
				rednet.close(v:GetSide()) --Close the side to prevent re-mapping (infinite recursion)
			end
			local  handle = io.open("netwisp.data/log_result.log","w")
			net.completed_ids = nil
			handle:write(textutils.serialize(net))
			handle:close()
			
		end
		print("Network map finished. View netobject at: netwisp.data/log_result.log or run 'ip-mon --view' to see user-friendly version. --STOP")
	elseif tArgs[1] == "--view" then --View the netobject
		if fs.exists("netwisp.data/log_result.log") then
			local data = io.open("netwisp.data/log_result.log","r")
			local dt = data:read()
			data:close()
			local mw,mh = term.getSize()
			term.setTextColor(colors.white)
			term.setBackgroundColor(colors.blue)
			term.clear()
			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.black)
			term.setCursorPos(1,1)
			term.clearLine()
			term.setCursorPos(1,1)
			local cmd = input()
			while true do
			   if (cmd == "list") then
			       
			   end
			   sleep(.1) 
			end
		else
			print("No network map file found. Run 'ip-mon --imap' to get network topology")			
		end
	elseif tArgs[1] == "--mon" then --Computer is currently listening
		mon()
	end
elseif #tArgs == 2 then --Mapping in progress.
	if (tArgs[1] == "--mon" and tArgs[2] == "-bg") then
		term.clear()
		term.setCursorPos(1,1)
		local ops = {function() shell.run("shell")end,termHandler}
		parallel.waitForAny(unpack(ops))
		
	elseif (tArgs[1] == "--mon" and tArgs[2] == "-k") then
		os.queueEvent("kill_mon")
	end
end

end)

if (not stat) then
	if (err == "Terminated") then return end
	term.setBackgroundColor(colors.lightGray)
	term.clear()
	term.setCursorPos(1,2)
	term.setBackgroundColor(colors.gray)
	term.clearLine()
	term.setCursorPos(1,3)
	term.setBackgroundColor(colors.gray)
	term.clearLine()
	term.write(" Netwisp has encountered an error!")
	term.setCursorPos(1,4)
	term.setBackgroundColor(colors.gray)
	term.clearLine()
	term.setBackgroundColor(colors.lightGray)
	term.setCursorPos(1,6)
	print("Please try re-running netwisp. If you continue to experience crashes, please submit an issue to our Github repo for review.")
	term.setCursorPos(1,10)
	print("Exception:")
	term.setTextColor(colors.black)
	print("  "..err)
	print()
	term.setTextColor(colors.white)
	print("Press any key to exit...")
	os.pullEvent("key")
	term.setBackgroundColor(colors.black)
	term.clear()
	term.setCursorPos(4,1)
	print("Thank you for your patience!")
end
