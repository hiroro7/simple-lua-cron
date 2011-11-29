
--from http://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua 
function array_concat(...)  
   local t = {} 
   for n = 1,select("#",...) do 
      local arg = select(n,...) 
      if type(arg)=="table" then 
	 for _,v in ipairs(arg) do 
	    t[#t+1] = v 
	 end 
      else 
	 t[#t+1] = arg 
      end 
   end 
   return t 
end 



---License is Affero GPL
delayed_cron_monitor={} 
function delayed_cron_monitor.new(...) 
   local delayed_cron_monitor_obj= 
      {   
      timers={} 
      ,status={} 
      ,tasks={} 
      ,reset=function(self) self.timers={} self.tasks={} end 
      --,make_timer=function(self, timer_name) return function(self) return self.timers[timer_name] < getticks() end end 
      --,delay=function(self, timer_name,d) self.timers[timer_name] = getticks() end 
      ,set_timer_when_nil=function(self, timer_name,t) if self.timers[timer_name]==nil then self.timers[timer_name]=t end end 
      ,check_conditions 
	 =function(self,t_conditions) 
	     for ic, vc in next,t_conditions do 
		if not vc(self) then 
		   return false 
		end 
	     end 
	     return true 
	  end 
      ,check_delays 
	 =function(self,t_delays) 
	     local lasttime = getticks() 
	     for id, vd in next,t_delays do 
		if lasttime <  self.timers[id] then 
		   return false 
		end 
	     end 
	     return true 
	  end, 
      
      set_delays 
	 =function(self,t_delays) 
	     local lasttime = getticks() 
	     for id, vd in next,t_delays do 
		self.timers[id]=lasttime + vd 
	     end 
	  end, 
      init_timers 
	 =function(self) 
	     local lasttime = getticks() 
	     for it, vt in next, self.tasks do 
		for id, vd in next,vt.delays do 
		   self.set_timer_when_nil(self,id,lasttime) 
		end 
	     end 
	  end, 
      set_tasks 
	 =function(self,tasks) 
	     self.tasks=tasks 
	     self.init_timers(self) 
	  end, 
      append_tasks 
	 =function(self,tasks) 
	     self.tasks=array_concat(self.tasks, tasks) 
	     self.init_timers(self) 
	  end 
      ,refresh 
	 =function(self) 
	     --print(#self.tasks) 
	     for it, vt in next, self.tasks do 
		--print(vt.conditions[1]())       
		if vt.conditions == nil or #vt.conditions == 0 or self.check_conditions(self,vt.conditions) 
		then 
		   if vt.delays ==nil or self.check_delays(self,vt.delays) then 
		      vt.action(self) 
		      if vt.delays ~= nil then 
			 self.set_delays(self,vt.delays) 
		      end 
		      if not vt.iterate then 
			 table.remove(self.tasks,it) 
                      end 
		   end 
		end 
	     end 
	  end 
   } 
   delayed_cron_monitor_obj:set_tasks(arg[1]) 
   return delayed_cron_monitor_obj 
end



----------------------------
-----from here example---------
----------------------------


--- plz use your sysmetm's time function. 
--function getticks() return os.clock()*1000000 end 
function getticks() return os.time()*1000 end  -- time as ms

--- plz use your sysmetm's wait or sleep function. 
---from http://lua-users.org/wiki/SleepFunction
local function wait(t) local start = getticks()  while  getticks() - start < t do end end 




task_schedule_table_sample={ 
   {
      delays={debugdelay1=1000,debugdelay2=2100}  --- interval time (ms)
      ,iterate=true             --- iterate flag. without this flag, task executed only onece 
      ,conditions={function(self) return true end , function(self) return getticks() > 0  end  } --- only when all conditions are true, task executed

      ,action=function(self) print("u ",self.timers.debugdelay1,#self.tasks) end ---task body. where self is monitor object. you can reffer monitor function object information like "self.timers.debugdelay" and so on.
   }  
   ,
   --single config table have def of many tasks, in oder to use same timer
   {delays={debugdelay1=2000} --note timer name is same to 1st task. In this case common timer is used. if you want use different timer, you shoud use different timer name 
      ,conditions={} --blank is same to all true
      ,action=function(self) print("v ",self.timers.debugdelay2,#self.tasks) end}  
} 




debug_tasks1={ 
   {delays={debug1delay=2000} 
    ,conditions={} 
    ,action=function(self) print("1 ",self.timers.debug1delay,#self.tasks) end}  
   ,{delays={debug1delay=4000} 
     ,conditions={} 
     ,action=function(self) print("2 ",self.timers.debug1delay,#self.tasks) end}  
} 

recur_task= 
   { 
   delays={debug1delay=2000} 
   ,conditions={} 
   ,action= 
      function(self)  
	 print("b " ,self.timers.debug1delay,#self.tasks ) 
	 self:append_tasks({recur_task})   --from inside scheduled task, you can add another task 
      end} 

debug_tasks2={ 
   {delays={debug1delay=2000} 
    ,conditions={} 
    ,action= 
       function(self)  
	  print("a " ,self.timers.debug1delay)  
       end}  
   ,recur_task 
} 

--generate monitor function object 
deo0=delayed_cron_monitor.new(task_schedule_table_sample)  
deo1=delayed_cron_monitor.new(debug_tasks1)  
deo2=delayed_cron_monitor.new(debug_tasks2) 

--loop monitor func. then scheduled tasks are executed 
for i=1,1000000 do 
   deo0:refresh() 
   deo1:refresh() 
   deo2:refresh() 
   wait(1000) 
end