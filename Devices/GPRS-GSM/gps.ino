

#include <SoftwareSerial.h>
#include "Adafruit_FONA.h"

// ****************************** FONA ****************************** 
#define FONA_RX 2
#define FONA_TX 3
#define FONA_RST 4

// this is a large buffer for replies
char replybuffer[255];

int GPRSON = 0;

SoftwareSerial fonaSS = SoftwareSerial(FONA_TX, FONA_RX);
Adafruit_FONA fona = Adafruit_FONA(&fonaSS, FONA_RST);

uint8_t readline(char *buff, uint8_t maxbuff, uint16_t timeout = 0);

// ***************************************************************** 

// ****************************** GPS ****************************** 
int byteCh=-1;
int start = 0;
char datastring[300];
char comandoGP[7] = "$GPGGA";
char service[29] = "domain.com/dir/index.html?data=";
char url[80];

int conta=0;
int ok=0;

// ***************************************************************** 

void setup(){
  Serial.begin(115200);
  for(int i=0;i<300;i++){
    datastring[i]=' ';
  }

  for(int j=0;j<79;j++){
    if(j<28){
      url[j]=service[j];
    }
    else{
      url[j]=' ';
    }
  }
  
  // ***************************************************************** 
  
  if (! fona.begin(4800)) {  // make it slow so its easy to read!
    Serial.println(F("Couldn't find FONA"));
    while (1);
  }
  
  Serial.println(F("FONA is OK"));
}

void loop(){
  if(GPRSON==0){
    if (!fona.enableGPRS(true))
    {
       Serial.println(F("Failed to turn on"));
       GPRSON=0;
       //while(fona.enableGPRS(true));
    }
    else{
      GPRSON=1;
    }
  }

  // Getting GPS data  
  ReadData();
  
  // Get -> website URL
  uint16_t statuscode;
  int16_t length;
  // char url[80];
  
  // flushSerial();
   
  // readline(url, 79);
  
  Serial.println((char)url[28]);
  Serial.println((char)url[29]);
  
  if((char)url[28]!=' ' && (char)url[29]!=' ' && GPRSON==1)
  {
     if (!fona.HTTP_GET_start(url, &statuscode, (uint16_t *)&length)) {
       Serial.println("Failed!");
     }
     else{
       while (length > 0) {
         while (fona.available()) {
           char c = fona.read();
           
           // Serial.write is too slow, we'll write directly to Serial register!
           loop_until_bit_is_set(UCSR0A, UDRE0); /* Wait until data register empty. */
           UDR0 = c;
           
           length--;
           if (! length) break;
         }
       }
       // Serial.println(F("\n****"));
       fona.HTTP_GET_end();
       
      for(int j=0;j<79;j++){
        if(j<28){
          url[j]=service[j];
        }
        else{
          url[j]=' ';
        }
      }
    
     }
  }
  else{
    Serial.println("-> No data...");
  }
  
  delay(1000);
}

void ReadData(){
  while(Serial.available()){
    byteCh = Serial.read();
    if(byteCh==36){ //36=$
      // Serial.println(" ");
      for(int i=0;i<300;i++){
        datastring[i]=' ';
      }
      conta=0;
      start=1;
    }
    if(start){
      datastring[conta] = byteCh;
      conta++;
      ok=0;
      if(byteCh==42){ //42=*
        for (int i=0;i<6;i++){     // Verifies if the received command starts with $GPR
         if (datastring[i]==comandoGP[i]){
           // Serial.print((char)datastring[i]);
           ok++;
         }
        }
       if(ok==6){
         // Serial.println(":D");
         ParseGGA(datastring);
         break;
       }
        start=0;
      }
    }
  } //While Serial
}

void ParseGGA(char *buff){
  int i=0;
  int t=0;
  int indx=0;

  Serial.println(buff);

  while(t<2){
    if(buff[i-1]==44){
      indx=i;
      t++;
    }
    i++;
  }
  
  int y=28; // 28 from Service leng
  i--;
  
  // Latitud
  while(buff[i]!=44){
    url[y]=buff[i];
    i++;
    y++;
  }
  
  url[y]=',';
  y++;
  i=i+3;
  
  // Longitud
  while(buff[i]!=44){
    url[y]=buff[i];
    i++;
    y++;
  }
  
  Serial.println(url);
  
}


