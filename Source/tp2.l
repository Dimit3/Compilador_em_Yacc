%option noyywrap

%%
[+\-*\/()\r=\<\>\!\:\;\{\}\[\]\%]      {return yytext[0];}
(?i:RETURN)     {return(RETURN);}
(?i:AND)        {return(AND);}
(?i:OR)         {return(OR);}
(?i:IF)         {return(IF);}
(?i:THEN)       {return(THEN);}
(?i:ELSE)       {return(ELSE);}
(?i:FOR)        {return(FOR);}
(?i:DO)         {return(DO);}
(?i:READ)       {return(READ);}
(?i:WRITE)      {return(WRITE);}
(?i:WRITES)     {return(WRITES);}
(?i:INT)        {return(INT);}
(?i:ARRAY)      {return(ARRAY);}
[0-9]+          {yylval.valN = atof(yytext); return(NUM);}
[a-zA-Z]        {yylval.valC = toupper(yytext[0]); return (ID);}
\"[a-zA-Z\[\]0-9 \\n\=\,]+\"     {yylval.valS = strdup(yytext); return (STRING);}
.|\n            {;}
%%
