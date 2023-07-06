pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- cpiod ecs
-- 142 tokens

-- renaming and world
cmp,has,_ents=pack,rawget,{}

function ent()
 -- find the value in components
 function _find(self,a)
 	 for _,t in pairs(self) do
	   if(t[a]!=nil) return t
	  end
 end

 return add(_ents,
  setmetatable({},{
  -- check value in components
  -- components cannot be accessed directly
  __index=function(self,a)
   return _find(self,a)[a]
  end,
  __newindex=function(self,a,v)
   _find(self,a)[a]=v
  end,
  __add=function(self,cmp)
   -- two cases: string or table
   return type(cmp)=="string"
    and rawset(self,cmp,{})
    or rawset(self,unpack(cmp))
  end,
  __sub=function(self,cn)
   -- double removal is not a problem
   return rawset(self,cn,nil)
  end}))
end

function sys(cmps,f)
 return function(...)
  for e in all(_ents) do
   for cn in all(cmps) do
    if(not has(e,cn)) goto _
   end
   f(e,...)
   ::_::
  end
 end
end
-->8
-- version with asserts (238 tokens)

-- renaming and world
cmp,has,_ents=pack,rawget,{}

function ent()
 -- find the value in components
 function _find(self,a)
 	 for _,t in pairs(self) do
	   if(t[a]!=nil) return t
	  end
	  assert(false,"field not found:"..a)
 end
 
 -- you can remove this function
 -- if you delete the asserts
 function check_no_duplicates(self)
  for k1,t1 in pairs(self) do
   for k2,t2 in pairs(self) do
    if k1<k2 then
	    for f1,_ in pairs(t1) do
	     for f2,_ in pairs(t2) do
	      assert(f1!=f2,"duplicated field "..f1.." in "..k1.." and in "..k2)
	     end
	    end
    end
   end
  end
 end
 
 return add(_ents,
  setmetatable({},{
  -- check value in components
  -- components cannot be accessed directly
  __index=function(self,a)
   return _find(self,a)[a]
  end,
  __newindex=function(self,a,v)
   _find(self,a)[a]=v
  end,
  __add=function(self,cmp)
   -- two cases: string or table
   if type(cmp)=="string" then
    assert(rawget(self,cmp)==nil,"already existing: "..cmp)
    rawset(self,cmp,{})
   else
    -- check if already existing
    local cn=cmp[1]
    assert(rawget(self,cn)==nil,"already existing: "..cn)
    rawset(self,cn,cmp[2])
    check_no_duplicates(self)
   end
   return self
  end,
  __sub=function(self,cn)
   -- double removal is not a problem
   return rawset(self,cn,nil)
  end}))
end

function sys(cmps,f)
 return function(...)
  for e in all(_ents) do
   for cn in all(cmps) do
    if(not has(e,cn)) goto _
   end
   f(e,...)
   ::_::
  end
 end
end
-->8
-- example

-- new entity
b=ent()

-- add components
b+=cmp("blob",{hp=1,mp=6,x=12,y=23})
b+="bleeding" -- just use a string if no field
-- b+="bleeding" -- crashes: duplicated components are forbidden!
-- how it looks internally:
-- b={bleeding={},blob={hp=1,...}}

-- direct access to values
?"hp before:"..b.hp
b.hp+=1 -- it must exist
?"hp after:"..b.hp

-- it means all component
-- field names must be unique!
-- b+=cmp("test",{hp=4}) -- crashes

-- new system
sys_heal=sys({"blob"},
	function(e,number)
	 e.hp+=number -- use component
	 -- check if an entity has a component
	 if has(e,"bleeding") then
	  e.hp-=1
	 end
  e-="bleeding" -- remove component
	end)

assert(has(b,"blob"))
-- call system
?"bleeding before remove:"..tostr(rawget(b,"bleeding"))
?"hp before sys:"..b.hp
assert(has(b,"bleeding"))
sys_heal(3) -- params are passed
?"hp after 1st sys:"..b.hp
assert(b.hp==4)
assert(not has(b,"bleeding"))
sys_heal(5) -- double "bleeding" remove is not a problem
assert(b.hp==9)
?"bleeding after remove:"..tostr(rawget(b,"bleeding"))
?"hp after 2nd sys:"..b.hp

-- delete from world
del(_ents,b)
-- b won't be updated
sys_heal(4)
assert(b.hp==9)
?"hp after 3nd sys:"..b.hp
