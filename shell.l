
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
#include <stdio.h>
/*
extern "C" {
char * read_line();
}

int mygetc(FILE * f) {
  static char *p;
  char ch;

  if (!isatty(0)) {
    // stdin is not a tty. Call real getc
    return getc(f);
  }

  // stdin is a tty. Call our read_line.

  if (p==NULL || *p == 0) {
    char * s = read_line();
    p = s;
  }

  ch = *p;
  p++;

  return ch;
}

#undef getc
#define getc(f) mygetc(f)
*/


/*static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
    unput(c);
}*/


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

[^ \t\n&<>\|]*\\[^ \t\n]* {
	int i = 0;
	int j = 0;
	char * escape = (char*)malloc(100);
	while(yytext[i] != '\0'){
		if(yytext[i] == '\\'){
				i+=1;
				escape[j] = yytext[i];
				i+=1;
				j++;
		}
		else
		{
		escape[j] = yytext[i];
		j++;
		i++;
		}
		i++;
	}
	yylval.string_val = strdup(yytext);
	return WORD;

}



[^ \t\n|<>&][^ \t\n|<>&]*  {
		/* Assume that file names have only alpha chars */
		yylval.string_val = strdup(yytext);
		return WORD;
	}



\"[^\n\"]*\"       {
		
		yytext++;
		yytext[strlen(yytext) - 1] = '\0';
		yylval.string_val = strdup(yytext);
		return WORD;
		
		/*
		yylval.string_val = strdup(yytext+1);
		yylval.string_val[strlen(yylval.string_val)-1] = 0;
		return WORD;*/
		
	}


 `[^\n`]*`	{
 	//char buffer[100];
	char * cmd = (char*)malloc(1000);
	int i = 0;
	int j = 0;
	int k = 0;
	int counter = 0;
	char ch = 0;
	char * buf = (char*)malloc(1000);
	yytext++;
	yytext[strlen(yytext)-1] = '\0';
	for(i = 0;yytext[i] != '\0';i++,j++){
		cmd[j] = yytext[i];
	}
	int len = strlen(cmd);
	int tmpin = dup(0);
	int tmpout = dup(1);


	int fdpipep[2];
	int fdpipec[2];

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
	int cr = fdpipep[0];
	int cw = fdpipec[1];
	int pr = fdpipec[0];
	int pw = fdpipep[1];
	
       
	int ret = fork();

	if(ret == 0){
		write(fdpipep[1],cmd,len);
		close(fdpipep[1]);
		close(fdpipec[0]);
		dup2(fdpipep[0],0);
		dup2(fdpipec[1],1);

		execvp("shell",NULL);
			perror("execvp");
			exit(1);
	}

	else
	{
		close(fdpipep[1]);
		close(fdpipec[1]);
		close(fdpipep[0]);
		waitpid(ret,NULL,0);
		

		while(read(fdpipec[0],&ch,1)){
			buf[k] = ch;
			k++;
		}
		
		close(fdpipec[0]);
		dup2(tmpin,0);
		dup2(tmpout,1);

		counter = k;

		for(;counter > 0;counter --){
			if(buf[counter] == '\n'){
			buf[counter] = ' ';
			}
			unput(buf[counter]);
		}
   	}	

}	

	








