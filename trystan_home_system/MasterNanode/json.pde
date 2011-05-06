//-----------------------------------------------------------------------------------------------
// JSON functions
//-----------------------------------------------------------------------------------------------


//-----------------------------------------------------------------------------------------------
// JSON structure characters
//-----------------------------------------------------------------------------------------------
                                                      //JSON structure uses " = 34
char jsonS[] = {'{','\0'};                         //JSON start characters
char jsonB1[] = {':','\0'};                     //JSON characters between key and value
char jsonB2[] = {',','\0'};                     //JSON characters between each data pair
char jsonE[] = {'}','\0'};                         //JSON end characters

//-----------------------------------------------------------------------------------------------
// Adds start of JSON characters
//-----------------------------------------------------------------------------------------------
char * srtJSON ( char * destination )
{
    strcat(destination,jsonS);  
}

//-----------------------------------------------------------------------------------------------
// Adds a JSON key and data pair to the string
//-----------------------------------------------------------------------------------------------
char * addJSON ( char * destination, const char * source, const double value )
{
  strcat(destination,source);
  strcat(destination,jsonB1);
  
  
  char fstr[10];
  dtostrf(value,0,2,fstr);
  
  strcat(destination,fstr);
  strcat(destination,jsonB2);
}

//-----------------------------------------------------------------------------------------------
// Adds end of JSON characters
//-----------------------------------------------------------------------------------------------
char * endJSON ( char * destination )
{
    str[strlen(destination)-1]='\0';
    strcat(destination,jsonE);  
}
