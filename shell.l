
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
#include <wait.h>


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

[^ \t\n|<>&]*\\[^ \t\n]* {
	int i = 0;
	int j = 0;
	char * escape = (char*)malloc(100);
	while(yytext[i] != '\0'){
		if(yytext[i] =='\\'){ 
			if(yytext[i+1] == '\\'){
			escape[j] = yytext[i+1];
			i++;
			j++;
			}
		}
		else
		{
		escape[j] = yytext[i];
		j++;
		}
	i++;
	}
	yylval.string_val = strdup(escape);
	return WORD;

}



[^ \t\n|<>&][^ \t\n|<>&]*  {
		/* Assume that file names have only alpha chars */
		yylval.string_val = strdup(yytext);
		return WORD;
	}



\"[^\n\"]*\"       {
		/*int last = 0;
		char * st = strdup(yytext);
			st++;
		st[strlen(st) - 1] = 0;
		yylval.string_val = st;
		return WORD;
		*/
		yylval.string_val = strdup(yytext+1);
		yylval.string_val[strlen(yylval.string_val)-1] = 0;
		return WORD;
		
	}


 `[^\n`]*`	{
 	char buffer[100];
	char cmd[100];
	int i = 0;
	int j = 0;
	int ctr = 0;
	while(yytext[i] != '\0'){
		if(yytext[0] == '`'){	
			cmd[j++] = yytext[i++];
		}
	}
	cmd[j-1] = '\0';
	
	int tmpin = dup(0);
	int tmpout = dup(1);
	int fdpipec[2];
	int fdpipep[2];

	int fdc = pipe(fdpipec);
	int fdp = pipe(fdpipep);

	if(fdc == -1){
		perror("pipe");
		exit(1);
	}
	if(fdp == -1){
		perror("pipe");
		exit(1);
	}
	
	/*int len = strlen(cmd);
	while(ctr <= len){
	write(1,cmd,1);
	}

	dup2(fdpipep[0],0);
        close(fdpipep[0]);

        dup2(fdpipec[1],1);
        close(fdpipec[1]);*/
       
	
    
               
 }	

	

	








