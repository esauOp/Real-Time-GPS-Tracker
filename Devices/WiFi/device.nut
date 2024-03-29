server.log("Device Started");


GGA <- {UTC="",
        Latitude="",
        NS="",
        Longitude="",
        EW="",
        Quality="",
        NumSats="",
        HDOP="",
        Alti="",
        AUnits="",
        Geoid=""
        GUnits="",
        Age="",
        Diff="",
        Checksum=""
    };


ZDA <- {UTC="",
        Day="",
        Month="",
        Year="",
        Empty1="",
        Empty2="",
        Checksum=""
    }
    
// Extract individual sub-strings for each field by looking for commas
function ParseGGA(s)
{    
    local i=0;
    local tmpstr="";
    
    i=7;
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.UTC = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.Latitude=tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.NS = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.Longitude = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.EW = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.Quality = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.NumSats = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.HDOP = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.Alti = tmpstr;
    tmpstr="";
    i++;    // skip comma
        while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.AUnits = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.Geoid = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.GUnits = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.Age = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!='*')   // note, check for star
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    GGA.Diff = tmpstr;
    tmpstr="";
    i++;    // skip star
    GGA.Checksum = s.slice(i,i+2);
}


// Extract individual sub-strings for each field by looking for commas
function ParseZDA(s)
{    
    local i=0;
    local tmpstr="";
    
    i=7;
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    ZDA.UTC = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    ZDA.Day=tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    ZDA.Month = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    ZDA.Year = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!=',')
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    ZDA.Empty1 = tmpstr;
    tmpstr="";
    i++;    // skip comma
    while (s[i]!='*')   // note, check for star
    {
        tmpstr+=s[i].tochar();
        i++;
    }
    ZDA.Empty2 = tmpstr;
    tmpstr="";
    i++;    // skip star
    ZDA.Checksum = s.slice(i,i+2);
}


// We've tested the string is valid, and checksum has been verified
// now we determine which kind of message is being sent, and
// process it accordingly
function CheckHeader(s)
{
    local header = s.slice(3,6);
    if (header=="GGA") ParseGGA(s);
    if (header=="ZDA") ParseZDA(s);
    // add more as required ....
}


// Checksum is the XOR of all bytes between $ and * (non-inclusive)
// We compare the value embedded in the string with the calculated value
// If they match, we assume we have received a valid string
function VerifyString(s)
{
    local i;
    local CalcCS=0;     // calculated checksum
    local len = s.len()-3;  // don't include checksum bytes or star
    for (i=1;i<len;i++)     // don't include $
        CalcCS = CalcCS ^ s[i];
 
    local EmbedCS;      // checksum embedded in string - take two hex
                        // chars and convert into an integer
    local MSB=s[len+1];
    local LSB=s[len+2];
    if (MSB > 0x40) MSB -= 0x37; else MSB -= 0x30;
    if (LSB > 0x40) LSB -= 0x37; else LSB -= 0x30;
    EmbedCS = MSB*16 + LSB;
   
    return((CalcCS == EmbedCS) ? 0 : -1);
}


// Firstly verify the checksum is valid, then extract each field into
// an entry within the table
function ProcessString(s)
{
    local error=0;
    local result = 0; // VerifyString(s);
    if (result == 0)
        CheckHeader(s);
    else
    {
        server.log("Checksum error");
        error=-1;
    }
    return(error);
}


// Callback that's activated once data is available in the UART RX buffer
start <- 0;
DataString <- "";
function ReadData()
{
    local len = 0;
    local ch = GPS.read();
    while (ch != -1)    // while there is data in the buffer
    {
        
        if (ch == '$')
        {
            start = 1;
        }
        
        if (start)
        {
            DataString += ch.tochar();
            len = DataString.len();
            if ((len > 3) && (DataString[len-3]=='*'))  // avoid negative index runtime error
            {
                start = 0;
                // server.log(DataString);   // uncomment for "live" updates
                ProcessString(DataString);
                DataString="";
            }            
        }    
        ch = GPS.read();
    }
}
 
function DisplayData(state)
{
    /*
    if (ZDA.UTC != "") server.log(ZDA.UTC);
    if (GGA.Latitude != "") server.log(GGA.Latitude);
    if (GGA.Longitude != "") server.log(GGA.Longitude);
    */
    agent.send("GPSdata",GGA);
    // imp.wakeup(10,DisplayData);
    // server.log("Setting LED to: " + state);
    GPS.write(state);
    imp.wakeup(5.0, function(){DisplayData(1 - state);});
}
 
// Alias UART to which Arduino is connected
 
GPS <- hardware.uart12;
GPS.configure(115200, 8, PARITY_NONE, 1, NO_CTSRTS, ReadData);
 
// Start 
 
DisplayData(1);

