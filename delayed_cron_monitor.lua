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
--- class name mybe change to more valid name
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



