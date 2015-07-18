
/*
 *
 * CS-252
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <string.h>
#include "y.tab.h"

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
    unput(c);
}

%}

%%

\n 	{
		return NEWLINE;
	}

[ \t] 	{
		/* Discard spaces and tabs */
     	}	

">>&" 	{
		return GREATGREATAMPERSAND;
	}
">>"	{
		return GREATGREAT;
	}
">&"	{
		return GREATAMPERSAND;
	}
">"	{
		return GREAT;
	}
"&"	{
		return AMPERSAND;
	}

"<"	{
		return LESS;
	}
"|"	{
		return PIPE;
	}


[^ \t\n][^ \t\n]*  {
		/* Assume that file names have only alpha chars */
		yylval.string_val = strdup(yytext);
		return WORD;
	}



\"[^\n\"]*\"       {
		int last = 0;
		char * st = strdup(yytext);
			st++;
		st[strlen(st) - 1] = 0;
		yylval.string_val = st;
		return WORD;
		
	}


[^ ^\\&<>|\t\n][^ ^\\&<>|\t\n]*  {
    	char *sNewArg = (char*) malloc(1024*sizeof(char));

        int i = 0; int j = 0;

        for(i = 0; i != strlen(yytext); i++){
            if(yytext[i] == 92){
                // means escape char was hit
                if(yytext[i+1] == 92){
                    sNewArg[j] = yytext[i+1];
                    i++; j++;
                }
            }
			else {
            	sNewArg[j] = yytext[i];
            	j++;
			}
        }
       
        yylval.string_val = strdup(sNewArg);
        return WORD;
       
}






