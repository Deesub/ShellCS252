
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
	/*	int last = 0;
		char * st = strdup(yytext);
			st++;
		st[strlen(st) - 1] = 0;
		yylval.string_val = st;
		return WORD; */
		yylval.string_val = strdup(yytext+1);
		yylval.string_val[strlen(yylval.string_val)-1] = 0;
		return WORD;
		
	}


[^ ^\\&<>|\t\n]  {
		 char *buff = strdup(yytext);
    		 char *word = (char*)malloc(strlen(yytext) + 1);
    
	  	 int j;
    		 j = 0;

    			int i;
    			i = 0;
   		 while (i < strlen(buff) + 1)
    			{
        		if (buff[i] == '\\')
        			{
            				word[j] = buff[i+1];
            				i = i + 2;
        		}
        		else
        		{
            			word[j] = buff[i];
            			i++;
        		}

        		j++;
    			}

    		yylval.string_val = strdup(word);
    		return WORD;
	}
	








