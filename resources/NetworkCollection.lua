--Developed by LNETeam
--Please respect Open Source and due credit
--Object implemention credited to LYQYD

new = {}
--Private functions


local function isSideRegistered(computer,side) --Removed network
	sides = {computer:GetMountedInterfaces()} --List of interfaces
	for k,v in ipairs(sides) do
		if v.local_side == side then
			return true
		end
	end
	return false
end

local function discoverMountedInterfaces(p_object)
	local sides = {"top","bottom","left","right","front","back"}
	local mounted = {}
	for k,v in ipairs(sides) do
		if (peripheral.isPresent(v) and peripheral.getType(v) == "modem") then
			local h = peripheral.wrap(v)
			local s = {IsWireless=false}
			mounted[v] = s
			if h.isWireless() then
				mounted[v].IsWireless = true
			else
				mounted[v].IsWireless = false
			end

		end
	end
	if tablelength(mounted) > 0 then
		interfaces = {}

		for k,v in pairs(mounted) do
			local int = new.Interface(k,p_object,v.IsWireless)
			local h = int:Mount()
			for i=1,65535 do
				if h.isOpen(i) then 
					local s,r = int:AddPort(i)
					--if not s then error(r) end
				end
			end

			table.insert(interfaces,int)
			h = nil
		end
		--p_object:AddInterfaceRange(interfaces)
		--for k,v in ipairs(interfaces) do
		--	p_object:AddInterface(interfaces[3])
		--end
		p_object.interfaces = interfaces --This will be changed. Temporary
	end
	
end

--Properties
local binding = 
{
	IsMember = function(self,o)
		for k,v in ipairs(self.members) do
			if v == o then return true end
		end
		return false
	end,
}

local network = 
{
	AddComputer = function(self,cObject)

		local stat,r = pcall(function()

			if (#self.computer_object > 0) then

				for s,f in pairs(self.computer_object) do
					if f:GetID() == cObject:GetID() then error("computer with the same id has already been added",2)
					else
						table.insert(self.computer_object,cObject)
						return
					end
				end
			else

				table.insert(self.computer_object,cObject)
			end
		end)
		return stat,r
	end,
	AddCompletedId = function(self,id)
	local stat,r = pcall(function()
			--print(textutils.serialize(self.interfaces)			
			if (#self.completed_ids > 0) then
				for k,v in pairs(self.completed_ids) do
					if (v == id) then error("id already completed") end
					table.insert(self.completed_ids,id)
				end
			else
				table.insert(self.completed_ids,id)
			end	
		end)
	end,
	ContainsId = function(self,id)
		for k,v in pairs(self.completed_ids) do
			if (v == id) then return true end
		end
		return false
	end,
	GetComputerByID = function(self,id)

		for s,f in ipairs(self.computer_object) do
			if f:GetID() == id then return f end
		end
		return nil
	end,
	Reveal = function(self)
		return self.seed_host_id
	end,
	StartMap = function(self)
		local comp = new.Computer(self)
		
		comp:AnalyzeForInterfaces()
		self:AddComputer(comp)
	end,

} 

local interface = 
{
	AddPort = function(self,c)
		local stat,r = pcall(function()
			if (#self.local_open_ports > 0) then
				for s,f in ipairs(self.local_open_ports) do
					if f == c then error("port with the same id has already been added",2) end
					table.insert(self.local_open_ports,c)
				end
			else
				table.insert(self.local_open_ports,c)
			end
		end)
		return stat,r
	end,
	GetOpenPorts = function(self)
		return self.local_open_ports
	end,
	GetUniqueID = function(self)
		return self.priv_id
	end,
	GetSide = function(self)
		return self.local_side
	end,
	Mount = function(self)
		return peripheral.wrap(self.local_side)
	end,

}

local computer = 
{

	AddInterface = function(self,i)
		local stat,r = pcall(function() 
			if (#self.interfaces > 0) then
				for s,f in ipairs(self.interfaces) do
					if f:GetUniqueID() == i:GetUniqueID() then error("interface with the same id has already been added",2) end
					table.insert(self.interfaces,i)
				end
			else
				table.insert(self.interfaces,i)
			end
		end)
		return stat,r
	end,
	AddInterfaceRange = function(self,...)
		iRange = {...}

		local stat,r = pcall(function()
			--print(textutils.serialize(self.interfaces))
			for k,v in ipairs(iRange) do
				
				for i,p in ipairs(v) do
					
					if (#self.interfaces > 0) then
						term.write("Page?")
						read()
						
						for s,f in ipairs(self.interfaces) do
							print(textutils.serialize(f))
							if f:GetUniqueID() == p:GetUniqueID() then error("interface with the same id has already been added",2) end
							self:AddInterface(p)
						end
					else

						self:AddInterface(p)

					end

				end
			end
		end)

		return stat,r
	end,
	
	AnalyzeForInterfaces = function(self)
		 discoverMountedInterfaces(self)
	end,
	
	CloseAllInterfaces = function(self)
		for k,v in ipairs(self.interfaces) do
			if rednet.isOpen(v.local_side) then rednet.close(v.local_side) end
		end
		return true
	end,
	ExecuteCommand = function(self,command_and_args) --Scoped only while on current machine.... for now. going to add remote host command execution

	end,
	GetID = function(self)
		return self.id
	end,
	GetMountedInterfaces = function(self)
		return self.interfaces
	end,
	GetParentID = function(self)
		return self.parent_id
	end,
	OpenAllInterfaces = function(self)
		for k,v in ipairs(self.interfaces) do
			if not rednet.isOpen(v.local_side) then rednet.open(v.local_side) end
		end
		return true
	end
}
--EOF Properties

--Test

local function repairNetworkType(obj)
	setmetatable(obj, {__index = network})
	for k,v in ipairs(obj.computer_object) do
		setmetatable(v, {__index = computer})
		for i,o in ipairs(v.interfaces) do
			setmetatable(o, {__index = interface})
		end
	end
	return obj
end

--End Test

--Public Functions
function new.AuthenticationBinding(keyA,keyB)
	local temp = 
	{
		members = {keyA,keyB},
	}
	setmetatable(temp, {__index = binding})
	return temp
end

function new.Network()
	local temp = 
	{
		computer_object = {},
		seed_host_id = os.getComputerID(),
		completed_ids = {}
	}
	setmetatable(temp, {__index = network})
	return temp
end

function new.Computer(parent,parent_computer)
	local temp = 
	{
		--parent_network = parent,
		generation = 0,
		parent_id = (parent_computer ~= nil) and parent_computer or os.getComputerID(),
		id = os.getComputerID(),
		label = os.getComputerLabel(),
		interfaces = {},
		neighbor_ips = {},
	}
	setmetatable(temp, {__index = computer})
	return temp
end

function new.Interface(side,parent,wired)
	local temp = 
	{
		isWireless = not wired,
		priv_id = math.random(),
		--parent_computer = parent,
		parent_id = parent:GetID(),
		local_open_ports = {},
		local_side = isSideRegistered(parent,side) and error("interface with side: "..side.." already exists") or side,
	}	

	setmetatable(temp, {__index = interface})
	return temp
end

function RepairType(object,typer)
	if typer == "interface" then
		return repairInterfaceType(object)
	elseif typer == "network" then
		return repairNetworkType(object)
	elseif typer == "computer" then
		return repairComputerType(object)
	else
		error("no such data type",2)
	end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function writw( dat )
	-- body
local handle = io.open("info",'w')
handle:write(textutils.serialize(dat))
handle:close()
end



--Stuff
function to_string(Table)
   local savedTables = {} -- used to record tables that have been saved, so that we do not go into an infinite recursion
   local outFuncs = {
      ['string']  = function(value) return string.format("%q",value) end;
      ['boolean'] = function(value) if (value) then return 'true' else return 'false' end end;
      ['number']  = function(value) return string.format('%f',value) end;
   }
   local outFuncsMeta = {
      __index = function(t,k) error('Invalid Type For SaveTable: '..k) end      
   }
   setmetatable(outFuncs,outFuncsMeta)
   local tableOut = function(value)
      if (savedTables[value]) then
         error('There is a cyclical reference (table value referencing another table value) in this set.');
      end
      local outValue = function(value) return outFuncs[type(value)](value) end
      local out = '{'
      for i,v in pairs(value) do out = out..'['..outValue(i)..']='..outValue(v)..';' end
      savedTables[value] = true; --record that it has already been saved
      return out..'}'
   end
   outFuncs['table'] = tableOut;
   return tableOut(Table);
end
-- EOF Public Functions
