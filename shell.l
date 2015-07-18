
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
#include <unistd.h>
#include <errno.h>


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
   









