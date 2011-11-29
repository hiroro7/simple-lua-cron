dofile("delayed_cron_monitor.lua")

----------------------------
-----from here example---------
----------------------------


--- plz define getticks() as your sysmetm's time function  
function getticks() return os.time()*1000 end  -- time as ms

--- plz define wait(t) as your sysmetm's wait or sleep function like http://lua-users.org/wiki/SleepFunction
local function wait(t) local start = getticks()  while  getticks() - start < t do end end 


--like crontab, you should write task schedule config table 
--this example print "s ..." and some debug inf with interval 1s=1000ms
task_schedule_table_simple={ --config table
   {iterate=true   
    ,delays={mydelay=1000} 
    ,conditions={} 
    ,action=function(self) print("s ",self.timers.mydelay,#self.tasks) end}
} 
deo=delayed_cron_monitor.new(task_schedule_table_simple)   --generate monitor function object from config table task_schedule_table_simple
--loop the monitor func deo for 5s. Then scheduled tasks are executed 
for i=1,5 do 
   deo:refresh() 
   wait(1000) 
end



---more delatiled example 

task_schedule_table_sample={ 
   {--1st task of this config table
      --- iterate flag. without this flag, task executed only onece 
      iterate=true             

    ---delay interval time (ms) for iterate tasks
      ,delays={debugdelay1=10000,debugdelay2=1000} --iterate this task with interval 10s, and  2nd task will exec after 1s of this task exec. You see 2nd task use timer named debugdelay2

      --- only when all conditions are true, this task executed
      ,conditions={function(self) return true end , function(self) return getticks() > 0  end   
		   ,function(self) return getticks()  > self.timers.debugdelay1   end  -- timer status also can write in condition section
		} 

      ---This is task body. Here "self" is monitor object("deo1" defined later). you can use monitor function object menber like "self.timers.debugdelay".
      ,action=function(self) print("u ",self.timers.debugdelay1,#self.tasks) end 
   }  
   ,
   --Single config table can have defs of many tasks (in oder to use same timer).
   {--2nd task of this config table
      iterate=true
      ,delays={debugdelay2=3000} --note timer name is same to 1st task. In this case common timer is used. For example task2-> wait(3000)->task1->wait(1000)->task1 ...  if you want use different timer, you shoud use different timer name 
      ,conditions={} --blank is same to all all condition true
      ,action=
	 function(self) 
	    print("v ",self.timers.debugdelay2,#self.tasks) 
	    self.status.some_flag=true  --if you want use some flag or states info, that should write inside status menber of monitor_object (=self.status)
	 end
   } 
   ,
   {--3rd task exec only when after 2nd task exec. see variable self.status.some_flag
      iterate=true
      ,conditions={
	 function (self) return self.status.some_flag end -- This mean : only when self.status.some_flag=true following action executed
      },
      action=
	 function(self) 
	    print("w ",self.timers.debugdelay2,#self.tasks) 
	    self.status.some_flag=false --reset flag 
	 end
   }  
} 





recur_task= 
   { 
   delays={debug1delay=1000} 
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
deo1=delayed_cron_monitor.new(task_schedule_table_sample)  
deo2=delayed_cron_monitor.new(debug_tasks2) 

--loop monitor func. then scheduled tasks are executed 
for i=1,1000000 do 
   deo1:refresh() 
   deo2:refresh() 
   wait(1000) 
end