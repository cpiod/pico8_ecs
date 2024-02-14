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
-->8
-- fsm library

mode=nil
_enters={}

function reg_mode(nb,enter)
 assert(_enters[nb]==nil,"mode already registered!")
 _enters[nb]=enter or function() end
end

function change_state(nb)
 mode=nb
 _enters[nb]()
end
-->8
-- ui

-- font
poke(0x5600,unpack(split"8,8,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,24,24,24,24,0,24,0,0,54,54,18,0,0,0,0,0,54,127,54,127,54,0,0,24,124,30,60,120,62,24,0,6,102,48,24,12,102,96,0,28,54,54,28,110,54,108,0,24,24,8,0,0,0,0,0,24,12,6,6,6,12,24,0,24,48,96,96,96,48,24,0,24,126,60,24,60,126,24,0,0,24,24,126,24,24,0,0,0,0,0,0,0,12,12,6,0,0,0,126,0,0,0,0,0,0,0,0,0,0,12,0,0,96,48,24,12,6,0,0,0,0,60,118,110,102,60,0,0,0,24,28,24,24,60,0,0,0,62,96,60,6,126,0,0,0,62,96,56,96,62,0,0,0,56,60,54,126,48,0,0,0,126,6,62,96,62,0,0,0,60,6,62,102,60,0,0,0,126,96,48,24,12,0,0,0,60,102,60,102,60,0,0,0,60,102,124,96,60,0,0,0,0,12,0,12,0,0,0,0,0,12,0,12,12,6,48,24,12,6,12,24,48,0,0,0,0,126,0,0,0,0,12,24,48,96,48,24,12,0,0,60,102,48,24,0,24,0,0,60,102,118,110,118,60,0,0,0,60,102,126,102,102,0,0,0,62,102,62,102,62,0,0,0,60,102,6,102,60,0,0,0,62,102,102,102,62,0,0,0,126,6,30,6,126,0,0,0,126,6,30,6,6,0,0,0,124,6,118,102,124,0,0,0,102,102,126,102,102,0,0,0,60,24,24,24,60,0,0,0,96,96,96,102,60,0,0,0,102,54,30,54,102,0,0,0,6,6,6,6,126,0,0,0,66,102,126,126,102,0,0,0,102,110,126,118,102,0,0,0,60,102,102,102,60,0,0,0,62,102,62,6,6,0,0,0,60,102,102,54,108,0,0,0,62,102,126,54,102,0,0,0,124,6,60,96,62,0,0,0,126,24,24,24,24,0,0,0,102,102,102,102,60,0,0,0,102,102,102,60,24,0,0,0,102,126,126,102,66,0,0,0,102,60,24,60,102,0,0,0,102,102,60,24,24,0,0,0,126,48,24,12,126,0,62,6,6,6,6,6,62,0,0,6,12,24,48,96,0,0,62,48,48,48,48,48,62,0,24,60,102,0,0,0,0,0,0,0,0,0,0,0,0,126,12,24,48,0,0,0,0,0,0,60,102,102,126,102,102,0,0,62,102,62,102,102,62,0,0,60,102,6,6,102,60,0,0,62,102,102,102,102,62,0,0,126,6,30,6,6,126,0,0,126,6,30,6,6,6,0,0,124,6,118,102,102,124,0,0,102,102,126,102,102,102,0,0,60,24,24,24,24,60,0,0,96,96,96,96,102,60,0,0,102,54,30,54,102,102,0,0,6,6,6,6,6,126,0,0,66,102,126,126,102,102,0,0,102,110,126,118,102,102,0,0,60,102,102,102,102,60,0,0,62,102,102,62,6,6,0,0,60,102,102,102,54,108,0,0,62,102,102,62,54,102,0,0,124,6,60,96,96,62,0,0,126,24,24,24,24,24,0,0,102,102,102,102,102,60,0,0,102,102,102,102,60,24,0,0,102,102,126,126,102,66,0,0,102,60,24,60,102,102,0,0,102,102,60,24,24,24,0,0,126,48,24,12,6,126,0,56,12,12,6,12,12,56,0,24,24,24,24,24,24,24,24,14,24,24,48,24,24,14,0,44,26,0,0,0,0,0,0,0,28,54,28,0,0,0,0,255,255,255,255,255,255,255,255,85,170,85,170,85,170,85,170,0,195,255,189,189,255,126,0,60,126,255,129,195,231,126,60,17,68,17,68,17,68,17,0,4,12,252,124,62,63,48,32,60,110,223,255,255,255,126,60,102,255,255,255,126,60,24,0,24,60,102,231,102,60,24,0,24,24,0,60,90,24,60,102,60,126,255,126,82,82,94,0,60,110,231,227,227,231,110,60,0,255,153,153,255,129,255,0,56,120,216,24,30,31,14,0,0,126,195,219,219,195,126,0,8,28,62,127,62,28,8,0,0,0,0,0,85,0,0,0,60,118,231,199,199,231,118,60,0,8,28,127,62,28,54,0,127,34,20,8,8,20,42,127,60,126,231,195,129,255,126,60,0,5,82,32,0,0,0,0,0,17,42,68,0,0,0,0,0,126,219,231,231,219,126,0,255,0,255,0,255,0,255,0,85,85,85,85,85,85,85,85,255,129,129,129,129,129,129,255,255,195,165,153,153,165,195,255,0,126,62,30,62,118,34,0,8,28,62,127,127,62,8,62,8,28,28,107,127,107,8,28,28,34,73,93,73,34,28,0"))

function clear_boxes()
 boxes={}
 current_choice=0
 current_max=0
end

function add_box(x,y,w,h,text,c,back,sel,fun)
 local nb=nil
 if sel then
  nb=current_max
  current_max+=1
 end
 add(boxes,{x=x,y=y,w=w,h=h,text=text,c=c,nb=nb,fun=fun,back=back})
end

function update_box()
 if btnp(⬇️) or btnp(➡️) then
  current_choice+=1
  current_choice%=current_max
 elseif btnp(⬅️) or btnp(⬆️) then
  current_choice-=1
  current_choice%=current_max
 elseif btnp(❎) then
  for b in all(boxes) do
   if b.nb==current_choice then
    b.fun()
    break
   end
  end
 end
end

function draw_boxes()
 for b in all(boxes) do
  local c=b.c
  if b.nb==current_choice then
   c=3
  end
  if b.back then
   rectfill(b.x,b.y,b.x+b.w,b.y+b.h,b.back)
  end
  rect(b.x,b.y,b.x+b.w,b.y+b.h,c)
  if b.text then
   local y=b.y+b.h/2-2
   local x=b.x+b.w/2-#b.text*2
   nice_print(b.text,x,y,c,false)
  end
 end
end

function nice_print(t,x,y,c,big,c2)
 if(big==nil) big=true
 if big then
  x=x or 64-#t*4
  t="\014"..t
 else
  x=x or 64-#t*2
 end
 for dx=-1,1 do
  for dy=-1,1 do
   if dx==0 or dy==0 then
	   ?t,x+dx,y+dy,c2 or 0
   end
  end
 end
 ?t,x,y,c or 7
end

