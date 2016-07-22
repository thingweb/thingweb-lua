-- Class definition of a servient
-- Autor: Sebastian Kaebisch (sebastiankb@git)

-- servient class
servient={}
servient.name = ""

-- which protocols does the servient support (e.g., CoAP, HTTP, ...)
servient.coap=false 
servient.http=false

servient.properties={} -- servient's properties
servient.actions={} -- servient's actions
servient.events={} -- servient's events

--property class
property={}
property.name=""
property.writable=false
property.bpr = "" -- binds Lua parameter (=property value) to resource

--action class
action={}
action.name=""
action.inputData={} -- multiple data can be transmitted
action.outputData="" -- only one return type
action.bpr = "" -- binds Lua parameter (=action function) to resource


function servient:new()
    local res = {}
    setmetatable(res,self)
    self.__index = self
    return res
end

function property:new()
    local res = {}
    setmetatable(res,self)
    self.__index = self
    return res
end

function action:new()
    local res = {}
    setmetatable(res,self)
    self.__index = self
    return res
end

function servient:addProperty(prop)
    table.insert(self.properties, prop)
end

function servient:addAction(act)
    table.insert(self.actions, act)
end

json_msg="{\"value\":"

-- starts the servient and provides the services online
function startServient(s)

    if(s.coap==true) then
    
        cs=coap.Server()
        cs:listen(5683)

        -- for each property a coap resource is added
        for i=1,#s.properties,1 do

            if s.properties[i].writable == true then
                cs:var(coap.GET, coap.PUT, s.properties[i].bpr, 0, 0)
            else
                cs:var(coap.GET, s.properties[i].bpr, 0, 0)
            end
        end



    end

    if(s.http==true) then
        startHTTPServer(s)

    end

end

function startHTTPServer(s)
        print("Start HTTP Server")
        srv = net.createServer(net.TCP)
        srv:listen(80, function(conn)
            conn:on("receive", function(conn, payload)
                
                 -- get requested resource name
                 i_s, j = string.find(payload, "/")
                 i_e, j = string.find(payload, " ",j)

                 meth = string.sub(payload,1,i_s-2);
                 res = string.sub(payload,i_s+1,i_e-1);

                -- print(meth)
                 if meth=="GET" then

                    ret = (_G[res])

                    if ret~=nil then


                        if type(ret) == "number" then

                           ret =  json_msg .. ret .."}"
                        else
                            ret =  json_msg .. "\"".. ret .."\"}"

                        end
                        conn:send(ret)
                    end

                elseif meth=="PUT" then

                    if (_G[res])~=nil then
                        -- _G[res] = 123

                        -- get payload data
                        i, j_s = string.find(payload, ":", i_e)
                        i_e, j = string.find(payload, "}", j_s)
                        a = string.sub(payload,j_s+1, i_e-1)
                        a=a:gsub("^%s*", "")

                        if type(_G[res])== "number" then
                            _G[res] = tonumber(a)
                        else
                            
                            _G[res] = a
                        end

                        
                        conn:send()
                    end
                   
                
                elseif meth=="POST" then
                     
                     if (_G[res])~=nil then
                        -- todo, read input data
                        ret = _G[res]()


                        if type(ret) == "number" then

                           ret =  json_msg .. ret .."}"
                        else
                            ret =  json_msg .. "\"".. ret .."\"}"
                        end
                        
                        conn:send(ret)
                    end
                   
                end

                
            end)
            conn:on("sent", function(conn) conn:close() end)
        end)
end
