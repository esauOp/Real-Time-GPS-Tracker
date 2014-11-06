
gpsData <- null;

device.on("GPSdata", function(t) {
    // do something with the temperature
    // we'll just store it
    gpsData = t;
    
    if (gpsData.Latitude != ""){
        server.log(gpsData.Latitude);
        if (gpsData.Longitude != ""){
            server.log(gpsData.Longitude);
        
        // local la = (gpsData.Latitude.tofloat()/100);
        // local lo = ((gpsData.Longitude.tofloat()/100)*-1);
        local vars = {
            "IdRuta": "23",
            "Latitud": ""+gpsData.Latitude+"",
            "Longitud": ""+gpsData.Longitude+""
          }
      
        local headers = { "Content-Type": "application/json" };
      
        local jvars = http.jsonencode(vars);
         server.log(jvars);
        // send data to your web service
        local req = http.post("http://www.domain.com/dir", headers, jvars);
        local res = req.sendsync();
        server.log("agent res: "+res.body);
         
        local am = "IdRuta=23&Latitud="+gpsData.Latitude+"&Longitud="+gpsData.Longitude; 
        local body = http.urlencode({value=am});
        // server.log(body);
        }
        
    }
    // local req = http.post("http://www.domain.com/dir",{}, body);
    // User Request.in to test http://requestb.in/15tleyw1?inspect
    // local res = req.sendsync();
    // server.log("agent res: "+res.body);
});

// Agent POST
server.log("Agent: v1.3");
siteID <-200;
locID <-5;

device.on("impMsg",function(im){    
  server.log("agent: impMsg:"+v+"|"+im.dateTime+"|"+im.rssi+"|"+im.vdd);
  local am = "s|"+siteID+"."+locID+"|"+v+"|"+im.dateTime+"|Movement|Msg|"+im.rssi+"|"+im.vdd; 
  local body = http.urlencode({value=am});
  local req = http.post("http://requestb.in/15tleyw1",{}, body);
 // User Request.in to test http://requestb.in/15tleyw1?inspect
  local res = req.sendsync();
  server.log("agent res: "+res.statuscode);
});

//Imp
// agent.send("impMsg",{v=5,dateTime=getDateTime(),rssi=imp.rssi(),vdd=hardware.voltage()});