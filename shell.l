
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


[^ \t\n|<>&][^ \t\n|<>&]*  {
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

 `[^\n`]*`	{
	
	/*
	char cmd[100];
	char buff[100];
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
	
	dup2(fdpipep[0],0);
	close(fdpipep[0]);

	dup2(fdpipec[1],1);
	close(fdpipec[1]);

	int ret = fork();

	if(ret == 0){
		close(fdpipec[0]);

		char *args[2];
		args[0] = "shell";
		args[1] = NULL;

		execvp(args[0],args);
		if(execvp(args[0],args) < 0){
			perror("execvp");
			exit(1);			
		}
	}
	else if(ret < 0){
		perror("fork");
		exit(1);
	}
	*/
	char buffer[100];
	 char *commands = (char*) malloc(sizeof(char) * 1024);
        int i = 0;
        int j = 0;
        for(i = 0; yytext[i] != '\0'; i++){
            if(yytext[i] == '`'){
                continue;
            }
            commands[j] = yytext[i];
            j++;
        }
        commands[j] = '\n';
        j++;

		// pass another exit to ensure exiting
        char sExit[6] = "exit\n";
        for(i = 0; sExit[i] != '\0'; i++){
            commands[j] = sExit[i];
            j++;
        }
        j++;
        commands[j] = '\0';
       
        // preserve stdin and stdout
        int tmpin = dup(0);
        int tmpout = dup(1);
       
        // create pipe for transferring commands/results
        int parentPipe[2];
        int childPipe[2];
       
        if(pipe(parentPipe) == -1){
            perror("pipe");
            exit(2);
        }
        if(pipe(childPipe) == -1){
            perror("pipe");
            exit(2);
        }   
       
       
        // parent stdin to parentPipe[0]
        dup2(parentPipe[0],0);
        close(parentPipe[0]);

        // parent stdout to childPipe[1]
        dup2(childPipe[1],1);
        close(childPipe[1]);
       
		// fork the new process
        int ret = fork();
       
        if(ret == 0){
            // child stdin to childpipe[0]
            dup2(childPipe[0],0);
            close(childPipe[0]);
           
            // child output to parent so it can pass results back
            dup2(parentPipe[1],1);
            close(parentPipe[1]);
 
			// run the subshell
            char *arguments[2];
            arguments[0] = "shell";
            arguments[1] = NULL;
            execvp(arguments[0], arguments);
           
            perror("execvp");
           
            exit(1);
        }else if(ret < 0){
            perror("fork");
            exit(1);
        }else{
            int count = 0;

            for (count = 0; count <= strlen(commands); count++)
            {
                write(1,commands+count,1);
            }

            dup2(tmpout, 1);
            close(tmpout);

            close(parentPipe[1]);
            close(parentPipe[0]);

            close(childPipe[1]);
            close(childPipe[0]);
           
            int k = 0;
            char c = 0;   
            while (read(0, &c, 1) != 0)
            {
                if (c == '\n')
                {
                    buffer[k] = ' ';
                }
                else
                {
                    //grow buffer if necessary
                    buffer[k] = c;
                }
                k++;
            }
            buffer[k] = '\0';
           
            dup2(tmpin, 0);
            close(tmpin);

            close(parentPipe[1]);
            close(parentPipe[0]);
            close(childPipe[1]);
            close(childPipe[0]);
        }
       
       
        waitpid(ret, NULL, 0);
       
        int c = 0;
        int length = strlen(buffer);
        while (c < length)
        {
            unput(buffer[length - 1 - c]);
            c++;
        }
 }




	








