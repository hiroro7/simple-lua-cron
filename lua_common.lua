not_fn = function(x) return not x end
true_fn = function() return true end
false_fn = function() return false end
and_fn = function(...) 
	    for it, vt in next, arg do 
	       if not vt then return false end 
	    end 
	    return true
	 end
or_fn = function(...) 
	    for it, vt in next, arg do 
	       if vt then return true end 
	    end 
	    return false
	 end
function even(a) return a % 2 == 0 end

--for debug print 
function printup(obj) print(unpack(obj)) end
--printup({1,2,3})


function compose(f, g) return function(...) return f(g(...)) end end
----usage
--if compose(not_fn,not_fn)() then print("Y") else print("N") end

function force(x) return x() end
function bind1st(f,v) return function(...) return f(v,...)  end end
function bind2nd(f,v) return function(x,...) return f(x,v,...)  end end
function apply1(f,x) return f(x) end
function apply_args(f,...) return f(...) end
function apply(f,ar) return f(unpack(ar)) end
----usage
-- function foo(a,b,c) print(a,b,c) end
-- bind1st(foo,10)(2,3)
-- apply1(bind1st(bind1st(foo,4),5),6)
-- apply_args(bind2nd(foo,7),8,9)
-- apply_args(foo,10,11,12)
-- apply(foo,{13,14,15})






function filter(t, func)
  local ret = {}
  for i, v in ipairs(t) do ret[#ret+1] = func(v) and v or nil end
  return ret
end
----usage 
--print(unpack(filter({1,2,3,4,5,6,7,8,9,10},even)))




--- from http://en.wikibooks.org/wiki/Lua_Functional_Programming/Functions

-- function map(func, table)
--     local dest = {}
--     for k, v in pairs (table) do
--         dest[k] = func (v)
--     end
--     return dest
--  end
function map(func, array)
  local new_array = {}
  for i,v in ipairs(array) do
    new_array[i] = func(v)
  end
  return new_array
end
----usage
-- l = {1, 2, 3, 4, 5};
-- sq = map(function (x) return x * x end,l)
-- print(unpack(sq))
-- => 1, 4, 9, 16, 25


function mapn(func, ...)
  local new_array = {}
  local i=1
  local arg_length = table.getn(arg)
  while true do
    local arg_list = map(function(arr) return arr[i] end, arg)
    if table.getn(arg_list) < arg_length then return new_array end
    new_array[i] = func(unpack(arg_list))
    i = i+1
  end
end
-- t = mapn(function(a,b) return a+b end, {1,2,3}, {4,5,6})
-- print(unpack(t))


function cdr(arr)
  local new_array = {}
  for i = 2, table.getn(arr) do
    table.insert(new_array, arr[i])
 end
 return new_array 
end
--printup(cdr({1,2,3}))


function cons(car, cdr)
  local new_array = {car}
  for i = 1, table.getn(cdr) do
     table.insert(new_array, cdr[i])
  end
  return new_array
end
--printup(cons(10,{1,2,3}))


function remove_if(func, arr)
  local new_array = {}
  --for _,v in arr do
  for i, v in next, arr do
    if not func(v) then 
       table.insert(new_array, v) 
       --new_array[i]=v
       --print(v)
    end
  end
  return new_array
end
-- t=remove_if(function(x) return math.mod(x,2)==0 end, {1,2,3,4,5})
-- print(#t)
-- printup(t)




--from http://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value
function table.copy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end


-- http://lua-users.org/wiki/CopyTable
function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
