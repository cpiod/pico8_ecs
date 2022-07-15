pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- cpiod ecs
-- 191 tokens (155 without asserts)

-- world
_ents={}

function ent()
 return add(_ents,
  setmetatable({},{
  -- check value in components
  -- components cannot be accessed directly
  __index=function(self,a)
	  for _,t in pairs(self) do
	   if(t[a]) return t[a]
	  end
	  assert(false,"field not found:"..a)
  end,
  __newindex=function(self,a,v)
	  for _,t in pairs(self) do
	   if(t[a]) t[a]=v return
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
    cmp._cn=nil -- technically not required
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
-->8
-- example

-- new entity
b=ent()

-- add components
b+=cmp("blob",{hp=1,mp=6,x=12,y=23})
b+="bleed" -- just use a string if no field
-- b+="bleed" -- no! duplicated components are forbidden!

-- how it looks internally:
-- b={bleed={},blob={hp=1,...}}

-- direct access to values
?"hp before:"..b.hp
b.hp+=1 -- it must exist
?"hp after:"..b.hp

-- it means all component
-- field names must be unique!

-- new system
sys_heal=sys({"blob"},
	function(e,number)
	 e.hp+=number -- use component
	 e-="bleed" -- remove component
	end)

-- call system
?"bleed before remove:"..tostr(rawget(b,"bleed"))
?"hp before sys:"..b.hp
sys_heal(3) -- params are passed
sys_heal(5) -- double "bleed" remove is not a problem
?"bleed after remove:"..tostr(rawget(b,"bleed"))
?"hp after sys:"..b.hp

-- delete from world
del(ents,b)
-- b won't be updated
sys_heal(4)
?"hp after 3nd sys:"..b.hp
