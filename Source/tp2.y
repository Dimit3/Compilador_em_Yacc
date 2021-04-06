%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>

int TabId[26];
int error = 0;
extern FILE *yyin,*yyout;
int c = 0 ;
int conta = 0;

%}

%union{ int valN; char valC; char* valS; }
%token <valN> NUM
%token <valC> ID
%token <valS> STRING
%token AND OR READ WRITE WRITES INT ARRAY
%token RETURN IF THEN ELSE FOR DO
%type <valS> Expr Termo ExprR Fator Comando Atrib Comandos Declaracao

%%


Codigo: Comandos                 { fprintf(yyout,"START\n%s" , $1);}
      ;


Comandos : Comando               { if (error != 1 ) asprintf( &$$ , "%s" , $1);  }
         | Comandos Comando      { if (error != 1 ) asprintf( &$$ , "%s%s" , $1 , $2);  }
         ;


Comando : IF ExprR THEN '{' Comandos '}' ELSE '{' Comandos '}'    { asprintf ( &$$ , "%sJZ ELSE%d\n%sJUMP FIM%d\nELSE%d:\n%sFIM%d:\n" , $2,c,$5, c,c,$9,c);c++;}
        | IF ExprR THEN '{' Comandos '}'                          { asprintf ( &$$ , "%sJZ FIM%d\n%sFIM%d:\n" , $2,c,$5,c);c++;}
        | FOR '(' Atrib ';' Expr ';' Atrib ')' DO '{' Comandos '}'{ asprintf ( &$$ , "%sCICLO%d:\n%sJZ FIM%d\n%s%sJUMP CICLO%d\nFIM%d:\n" , $3,c,$5,c,$11,$7,c,c);c++;}
        | Declaracao ';'                                          { $$ = strdup($1); }                                                                                                       
        | Atrib ';'                                               { $$ = strdup($1); }                                        
        | WRITES STRING ';'                                       { asprintf( &$$ , "PUSHS %s\nWRITES\n",$2);}        
        | WRITE  ID ';'                                           { asprintf(&$$,"PUSHG %d\nWRITEI\n" , TabId[$2-'A'] );}
        | RETURN ExprR  ';'                                       { asprintf(&$$,"%sPUSHS \"O return e \"\nWRITES\nWRITEI\nSTOP\n" , $2);}
      ;
 
Declaracao: INT Atrib                { $$ = strdup($2); }   
          | INT ID                   { if (TabId[$2-'A'] == INT_MAX) {
                                                TabId[$2 - 'A'] =  conta ;
                                                conta++;
                                                asprintf( &$$ , "PUSHI 0\n" ); }
                                       else { error = 1;
                                              $$ = strdup("");
                                              fprintf(yyout,"ERR \"Redeclaracao de variavel\"\nSTOP\n");}  }

          | INT ARRAY '[' NUM ']' ID { if (TabId[$6-'A'] == INT_MAX) {
                                                TabId[$6 - 'A'] =  conta ;
                                                conta = conta + $4;
                                                asprintf( &$$ , "PUSHN %d\n" , $4);}
  
                                       else { error = 1;
                                              $$ = strdup("");
                                              fprintf(yyout,"ERR \"Redeclaração de variavel\"\nSTOP\n");}}
          
          | INT ARRAY '[' NUM ']' '[' NUM ']' ID { if (TabId[$9-'A'] == INT_MAX) {
                                                TabId[$9 - 'A'] =  conta ;
                                                conta = conta + ($4*$7);
                                                asprintf( &$$ , "PUSHN %d\n" , ($4*$7));}
  
                                                    else { error = 1;
                                                      $$ = strdup("");
                                                      fprintf(yyout,"ERR \"Redeclaração de variavel\"\nSTOP\n");}}
          ;
        
Atrib : ID '=' ExprR                   { if (TabId[$1-'A'] == INT_MAX) {
                                                 TabId[$1 - 'A'] =  conta ;
                                                 asprintf( &$$ , "%s" ,$3);
                                                 conta++;}
                                         else {asprintf( &$$ , "%sSTOREG %d\n" ,$3 , TabId[$1-'A']);}}
                                                 
      | ID '[' Fator ']'  '=' ExprR    { if (TabId[$1-'A'] == INT_MAX) {
                                                 error = 1;
                                                 $$ = strdup("");
                                                 fprintf(yyout,"ERR \"Array não declarado\"\nSTOP\n");}

                                         else{ asprintf( &$$ , "PUSHGP\nPUSHI %d\nPADD\n%s%sSTOREN\n" ,TabId[$1-'A'] , $3 , $6 ); }}

      | ID NUM '[' Fator ']''[' Fator ']'  '=' ExprR    { if (TabId[$1-'A'] == INT_MAX) {
                                                            error = 1;
                                                            $$ = strdup("");
                                                            fprintf(yyout,"ERR \"Array não declarado\"\nSTOP\n");}

                                                      else{ asprintf( &$$ , "PUSHGP\nPUSHI %d\nPADD\n%sPUSHI %d\nMUL\n%sADD\n%sSTOREN\n" ,TabId[$1-'A'] , $4 , $2 , $7 ,$10 ); }}                                   
      ;

ExprR : Expr                    { $$ = strdup($1); }
      | READ                    { asprintf( &$$ , "READ\nATOI\n");}
      | ExprR AND Expr          { asprintf ( &$$ , "%sPUSHI 0\nEQUAL\n%sPUSHI 0\nEQUAL\nADD\nPUSHI 0\nEQUAL\n" , $1,$3 );}
      | ExprR OR Expr           { asprintf ( &$$ , "%sPUSHI 0\nEQUAL\n%sPUSHI 0\nEQUAL\nADD\nPUSHI 2\nINF\n" , $1,$3 );}
      | '(' ExprR ')'           { $$ = strdup($2);}
      ;

Expr  : Termo                   { $$ = strdup($1); }
      | Expr '+' Termo          { asprintf( &$$ , "%s%sADD\n" , $1 ,$3 );}
      | Expr '-' Termo          { asprintf( &$$ , "%s%sSUB\n" , $1 ,$3 );}
      | Expr '=''=' Termo       { asprintf( &$$ , "%s%sEQUAL\n" , $1 ,$4 );}
      | Expr '!''=' Termo       { asprintf( &$$ , "%s%sEQUAL\nNOT\n" , $1 ,$4 ); }
      | Expr '<' Termo          { asprintf( &$$ , "%s%sINF\n" , $1 ,$3 ); }
      | Expr '<''=' Termo       { asprintf( &$$ , "%s%sINFEQ\n" , $1 ,$4 ); }
      | Expr '>' Termo          { asprintf( &$$ , "%s%sSUP\n" , $1 ,$3 ); }
      | Expr '>''=' Termo       { asprintf( &$$ , "%s%sSUPEQ\n" , $1 ,$4 ); }
      ;




Termo : Fator                   { $$ = strdup($1);}
      | Termo '*' Fator         { asprintf( &$$ , "%s%sMUL\n" , $1 ,$3 );}
      | Termo '/' Fator         { asprintf( &$$ , "%sPUSHI 0\nEQUAL\nNOT\nJZ ELSE%d\n%s%sDIV\nJUMP FIM%d\nELSE%d:\nERR \"Divisão por zero\"\nSTOP\nFIM%d:\n" , $3,c,$1,$3, c,c,c);c++;}
      | Termo '%' Fator         { asprintf( &$$ , "%s%sMOD\n" , $1 ,$3 );}
      ;

         
Fator : NUM                      { asprintf( &$$ , "PUSHI %d\n" , $1 ); } 
	| '-' NUM                  { asprintf( &$$ , "PUSHI -%d\n" , $2 );}
	| ID                       { if ( TabId[ $1-'A' ] != INT_MAX ) { asprintf( &$$ , "PUSHG %d\n" , TabId[ $1-'A' ] ); }
                                   else {  fprintf(yyout,"ERR \"Variável não declarada\"\nSTOP\n"); 
                                           $$ = strdup("");
                                           error=1; } }
      | ID '[' Fator ']'         { if ( TabId[ $1-'A' ] != INT_MAX ) { asprintf( &$$ , "PUSHGP\nPUSHI %d\nPADD\n%sLOADN\n" , TabId[$1-'A'] , $3); } 
                                   else {  fprintf(yyout,"ERR \"Array não declarado\"\nSTOP\n");
                                           $$ = strdup("");
                                           error=1; } }      
      | ID NUM '[' Fator ']' '[' Fator ']'        { if ( TabId[ $1-'A' ] != INT_MAX ) { asprintf( &$$ , "PUSHGP\nPUSHI %d\nPADD\n%sPUSHI %d\nMUL\n%sADD\nLOADN\n" , TabId[$1-'A'] , $4 , $2 , $7); } 
                                                else {  fprintf(yyout,"ERR \"Array não declarado\"\nSTOP\n");
                                                      $$ = strdup("");
                                                      error=1; } }                                                                         
       
	| '(' Expr ')'             { $$ = strdup($2);}
	;
 	
	
	

%%

#include "lex.yy.c"


int yyerror(char * s){
		printf("Frase invalida:%s\n" , s);

}


int main(int argc, char *argv[]){


         int i;
         for (i=0; i<26; i++) { TabId[i] = INT_MAX; }
            
           
         if ((yyin = fopen(argv[1],"r") )== NULL ) {
	    		   printf("Não consegui ler '%s'\n", argv[1]);
	                   return 0;
	}
           
           
            
           if ((yyout = fopen(strcat(argv[2],".vm"),"w")) == NULL ) {
	    	            printf("Não consegui escrever '%s'\n", argv[2]);
		            return 0;
	}
            
                          printf("Inicio do parsing\n");
                          
                          
            yyparse();
            
            
            
            
                          printf("Fim do parsing\n");
                          
            return 0;
                                     
}
