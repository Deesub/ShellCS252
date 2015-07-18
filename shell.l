
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



	/*	int last = 0;
		char * st = strdup(yytext);
			st++;
		st[strlen(st) - 1] = 0;
		yylval.string_val = st;
		return WORD; */
		
	

\"[^\n\"]*\" {
	int end = 0;
	int i = 0;
	
	while ( yytext[i] != '\0' ) {
		if (i == 0) {		
			i++;
			//printf("here1\n");
			continue;
		}

		yylval.string_val[i-1] = yytext[i];
		//printf("%c\n", yytext[i]);
		end = i;
		i++;
	}

	yylval.string_val[end-1] = '\0';
	return WORD;
}


