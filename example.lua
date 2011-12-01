dofile("delayed_cron_monitor.lua")

----------------------------
-----from here example---------
----------------------------


--- plz define getticks() as your sysmetm's time function  
function getticks() return os.time()*1000 end  -- time as ms

--- plz define wait(t) as your sysmetm's wait or sleep function like http://lua-users.org/wiki/SleepFunction
local function wait(t) local start = getticks()  while  getticks() - start < t do end end 


--Like crontab, you should write task schedule config table. 
--This example print "s " (and some debug inf ) with interval 1s=1000ms
task_schedule_table_simple={ --config table
   {iterate=true   
    ,delays={mydelay=1000} 
    ,conditions={} 
    ,action=function(self) print("s ",self.timers.mydelay,#self.tasks) end}
} 
deo=delayed_cron_monitor.new(task_schedule_table_simple)   --generate monitor function object from config table "task_schedule_table_simple"
--loop the monitor function deo for 5s. Then scheduled tasks are executed 
for i=1,5 do 
   deo:refresh() 
   wait(1000) 
end



---more delatiled example 

task_schedule_table_sample={ 
   {--1st task of this config table
      --- set iterate flag. Without this flag, task executed only onece 
      iterate=true             

    ---delay interval time (ms) for iterate tasks
      ,delays={cpu1=10000 -- This task occupy resorce named "cpu1" for 10s=10000ms .
	       ,gpu2=1000 -- This task occupy resorce named "gpu2" for 1s=1000ms .
      } --this task is iterated with interval 10s. Also resorce "gpu2" is used for 1s.  2nd task will be executed after 1s of this task (after task1 free  the resorce "gpu2") .  You see 2nd task use resorce named "gpu2"

      --- only when all conditions are true, this task executed
      ,conditions={function(self) return true end , function(self) return getticks() > 0  end   
		   ,function(self) return getticks()  > self.timers.cpu1   end  -- timer status (resorce ocuppeid time contision) also can write in condition section
		} 

      ---This is task body. Here "self" is monitor object("deo1" defined later). you can use the object's menber like "self.timers.cpu1".
      ,action=function(self) print("u ",self.timers.cpu1,#self.tasks) end 
   }  
   ,
   --Single config table can have defs of many tasks (in oder to use same timer).
   {--2nd task of this config table
      iterate=true
    ,delays={gpu2=3000} --Note same resorce "gpu2" is used in 1st task. In this case, this task is executed after task1 free resorce "gpu2". For example "gpu2" is used by task2-> wait(3000)->task1->wait(1000)->task2 -> wait(3000) -> task2 ...  
      ,conditions={} --blank is same to all all condition true
      ,action=
	 function(self) 
	    print("v ",self.timers.gpu2,#self.tasks) 
	    self.status.some_flag=true  --if you want use some flag or parameter, that should write inside status menber of monitor_object (=self.status)
	 end
   } 
   ,
   {--3rd task exec only when after 2nd task exec. see variable self.status.some_flag
      iterate=true
      ,conditions={
	 function (self) return self.status.some_flag end -- This mean : if self.status.some_flag=true  then action executed
      },
      action=
	 function(self) 
	    print("w ",self.timers.gpu2,#self.tasks) 
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
	 self:append_tasks({recur_task})   --from inside scheduled task, you can add another task like this.
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