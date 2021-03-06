
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

extern "C" char * read_line();


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

	int i = 0;
	int j = 0;
	int k = 0;
	int counter = 0;
	char ch = 0;
	char * buf = (char*)malloc(1000);
	char * cmd = strdup(yytext);
	cmd[strlen(yytext)-1] = '\0';
	cmd++;
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

	write(fdpipec[1],cmd,len);
	write(fdpipec[1],"\n",1);
	write(fdpipec[1],"exit",4);
	write(fdpipec[1],"\n",1);

	close(fdpipec[1]);
	dup2(fdpipec[0],0);
	close(fdpipec[0]);
	dup2(fdpipep[1],1);
	close(fdpipep[1]);

	int ret = fork();

	if(ret == 0){
		execvp("/proc/self/exe",NULL);
			perror("execvp");
			_exit(1);
		
	
	}
	else if (ret < 0){
		perror("fork");
		exit(1);
	}
	else{
	}

	dup2(tmpin,0);
	dup2(tmpout,1);

		

	while(read(fdpipep[0],&ch,1)){
		if(ch == '\n'){
			buf[k] = ' ';
			}
			else{
				buf[k] = ch;
				
			}
			k++;
		}
		buf[k] = '\0';
		



		for(counter = strlen(buf);counter >= 0;counter --){
			if(buf[counter] == '\n'){
			buf[counter] = ' ';
			}
			unput(buf[counter]);
		}
   }	
	

	








