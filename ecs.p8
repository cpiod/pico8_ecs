pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- cpiod ecs
-- 276 tokens (176 without asserts)

-- world
_ents={}

function ent()
 -- you can remove this function
 -- if you delete the asserts
 function check_no_duplicates(self)
  for k1,t1 in pairs(self) do
   for k2,t2 in pairs(self) do
    if k1<k2 then
	    for f1,_ in pairs(t1) do
	     for f2,_ in pairs(t2) do
	      assert(k1==k2 or f1!=f2,"duplicated field "..f1.." in "..k1.." and "..k2)
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
	  for _,t in pairs(self) do
	   if(t[a]!=nil) return t[a]
	  end
	  assert(false,"field not found:"..a)
  end,
  __newindex=function(self,a,v)
   assert(v!=nil)
	  for _,t in pairs(self) do
	   if(t[a]!=nil) t[a]=v return
	  end
	  assert(false,"field not found:"..a)
  end,
  __add=function(self,cmp)
   -- two cases: string or table
   if type(cmp)=="string" then
    assert(rawget(self,cmp)==nil,"already existing: "..cmp)
    rawset(self,cmp,{})
   else
    -- check if already existing
    assert(rawget(self,cmp._cn)==nil,"already existing: "..cmp._cn)
    rawset(self,cmp._cn,cmp)
    -- remove this function if you remove asserts
    -- it's useful but costly
    cmp._cn=nil -- technically not required
    check_no_duplicates(self)
   end
   return self
  end,
  __sub=function(self,cn)
   -- double removal is not a problem
   rawset(self,cn,nil)
   return self
  end}))
end

function cmp(cn,t)
 t._cn=cn
 return t
end

function sys(cmps,f)
 return function(...)
  for e in all(_ents) do
   for cn in all(cmps) do
    if(not rawget(e,cn)) goto _
   end
   f(e,...)
   ::_::
  end
 end
end

function is(e,cn)
 return rawget(e,cn)!=nil
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
	 if is(e,"bleeding") then
	  e.hp-=1
	 end
  e-="bleeding" -- remove component
	end)

-- call system
?"bleeding before remove:"..tostr(rawget(b,"bleed"))
?"hp before sys:"..b.hp
sys_heal(3) -- params are passed
sys_heal(5) -- double "bleeding" remove is not a problem
?"bleeding after remove:"..tostr(rawget(b,"bleed"))
?"hp after sys:"..b.hp

-- delete from world
del(_ents,b)
-- b won't be updated
sys_heal(4)
?"hp after 3nd sys:"..b.hp
