pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- cpiod ecs
-- remove the asserts to gain tokens

-- world
ents={}

function ent()
 local e=setmetatable({},{
  __index=function(self,a)
  -- check value in components
  -- components cannot be accessed directly
   for _,t in pairs(self) do
    local r=t[a]
    if(r) return r
   end
   assert(false,"field not found:"..a)
   return nil
  end,
  __newindex=function(self,a,v)
  -- check value in components
   for _,t in pairs(self) do
    local r=t[a]
    if(r) t[a]=v return
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
  end
  })
 add(ents,e)
 return e
end

function cmp(cn,t)
 t._cn=cn
 return t
end

function sys(cmps,f)
 return function(...)
  for e in all(ents) do
   for cn in all(cmps) do
    if(rawget(e,cn)==nil) goto _
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
b+=cmp("blob",{hp=1,mp=6,x=12,y=23,target=""})
b+="bleed" -- just use a string if no field
-- b+="bleed" -- no! duplicated component is forbidden!

-- what it looks internaly:
-- b={bleed={},
-- blob={hp=1,...}}

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
?"bleed after remove:"..tostr(rawget(b,"bleed"))
?"hp after sys:"..b.hp

-- delete from world
del(ents,b)
-- b won't be updated
sys_heal(3)
?"hp after 2nd sys:"..b.hp
