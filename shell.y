
/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [ | cmd [arg]*]* [ [> filename] [< filename] [ >& filename] [>> filename] [>>& filename] ]* [&]
 *
 */

%token	<string_val> WORD

%token 	NOTOKEN GREAT NEWLINE GREATGREAT AMPERSAND GREATAMPERSAND GREATGREATAMPERSAND LESS PIPE

%union	{
		char   *string_val;
	}

%{



#define yylex yylex
#include <stdio.h>
#include <string.h>
#include <dirent.h>

#include "command.h"
#include <regex.h>
#include <sys/types.h>

#define MAXFILENAME 1024


void yyerror(const char * s);
int yylex();

%}

%%

goal:	
	commands
	;

commands: 
	command
	| commands command 
	;

command: simple_command
        ;

simple_command:	
	command_and_args pipe_list iomodifier_list background_optional NEWLINE {
	       /* printf("   Yacc: Execute command\n"); */
		Command::_currentCommand.execute();
	}
	| NEWLINE 
	| error NEWLINE { yyerrok; }
	;

command_and_args:
	command_word arg_list {
		Command::_currentCommand.
			insertSimpleCommand( Command::_currentSimpleCommand );
	}
	;

arg_list:
	arg_list argument
	| 
	;

argument:
	WORD {
            /* printf("   Yacc: insert argument \"%s\"\n", $1); */
              
	       
	       Command::_currentSimpleCommand->insertArgument( $1 );
	       
	}
	;

command_word:
	WORD {
            /* printf("   Yacc: insert command \"%s\"\n", $1); */
	       
	       Command::_currentSimpleCommand = new SimpleCommand();
	       Command::_currentSimpleCommand->insertArgument( $1 );
	      
	}
	;

iomodifier_list:
	iomodifier_list iomodifier_opt
	|
	;

iomodifier_opt:
        GREAT WORD {
		if(Command::_currentCommand._outFile)
		{
		printf("Ambiguous output redirect\n");
		exit(1);
		}
		else
		{
	 /*	printf("   Yacc: insert output \"%s\"\n", $2); */
		Command::_currentCommand._outFile = $2;
		}
	}
	| GREATGREAT WORD {
		Command::_currentCommand._app = 1;
		if(Command::_currentCommand._outFile){
		printf("Ambiguous output redirect\n");
		exit(1);
		}
		else 
		{
	 /*	printf("   Yacc: insert output \"%s\"\n",$2); */
		Command::_currentCommand._outFile = $2;
		}
	}
	| GREATAMPERSAND WORD {
		
		if(Command::_currentCommand._outFile)
		{
		printf("Ambiguous output redirect\n");
		exit(1);
		}
		else
		{
	 /*	printf("    Yacc: insert output \"%s\"\n",$2); */
		Command::_currentCommand._outFile = $2;
	 /*	printf("    Yacc: insert error \"%s\"\n",$2); */
		Command::_currentCommand._errFile = strdup($2); 
		}
	}
	| GREATGREATAMPERSAND WORD {
		Command::_currentCommand._app = 1;
		if(Command::_currentCommand._outFile)
		{
		printf("Ambiguous output redirect\n");
		exit(1);
		}
		else
		{
	 /*	printf("    Yacc: insert output \"%s\"\n",$2); */
		Command::_currentCommand._outFile = $2;
	 /*	printf("    Yacc: insert error \"%s\"\n",$2); */
		Command::_currentCommand._errFile =strdup($2);
		}
	}
	| LESS WORD {
		if(Command::_currentCommand._outFile)
		{
		printf("Ambiguous output redirect\n");
		exit(1);
		}
		else
		{
	 /*	printf("    Yacc: insert input \"%s\"\n",$2); */
		Command::_currentCommand._inputFile = $2;
		}
		
	}
	
	;

pipe_list:
	pipe_list PIPE command_and_args
	| command_and_args
	|
	;

background_optional:
	AMPERSAND {
	Command::_currentCommand._background = 1;
	}
	|
	;

%%

#define MAXFILENAME 1024
void expandWildcards(char * prefix, char * suffix){
	if(suffix[0] == 0){
		Command::_currentSimpleCommand->insertArgument(strdup(prefix));
		return;
		}
	char * s = strchr(suffix, '/');
	char arg[MAXFILENAME];
	if(s!=NULL){
		strncpy(arg,suffix,s-suffix);
		suffix = s+1;
	}
	else{
		strcpy(arg,suffix);
		suffix = suffix + strlen(suffix);
	}
	
	char newPrefix[MAXFILENAME];
	char * b;
	char * c;
	b = strchr(arg,'*');
	c = strchr(arg,'?');

	if(b == NULL && c == NULL){
		sprintf(newPrefix,"%s/%s",prefix,arg);
		expandWildcards(newPrefix,suffix);
		return;
	}
	

	char * reg = (char*)malloc(2*strlen(arg) + 10);
	char * a = arg;
	char * r = reg;
	*r = '^';
	r++;

	while(*a) {
		if( *a == '?'){
			*r = '.';
			r++;
			*r = '*';
			r++;
			}
		else if(*a == '?'){
			*r = '.';
			r++;
		}
		else if(*a == '.'){
			*r = '\\';
			r++;
			*r = '.';
			r++;
		}
		else{
			*r = *a;
			r++;
		}
		a++;
	}
	*r = '$';
	r++;
	*r = 0;

	int regco;
	regex_t re;
	regco = regcomp(&re,reg,0);

	if(regco!=0){
	perror("BAD regex bro, better luck next time");
	exit(1);
	}

	/*char * expbuf = compile(reg,expbuf,&expbuf[strlen(expbuf)],-1);

	if(expbuf == NULL){
		perror("compile");
		return;
	}*/
	
	

	const char * dir;
	if(prefix == NULL){
		dir = ".";
	}
	else
	{
		dir = prefix;
	}
	
	DIR * d = opendir(dir);
	if(d == NULL){
		return;
	}

	struct dirent * ent;

	while((ent = readdir(d))!=NULL){
	
		if(regexec(&re,ent->d_name,(size_t)0,NULL,0)!=0){
			if(ent->d_name[0] == '.'){
					if(arg[0] == '.'){
						sprintf(newPrefix,"%s%s",prefix,ent->d_name);
						expandWildcards(newPrefix,suffix);
					}
					else
					{		
						sprintf(newPrefix,"%s%s",prefix, ent->d_name);
						expandWildcards(newPrefix,suffix);
					}	
	
			}
		}	

	}
	closedir(d);
}

void
yyerror(const char * s)
{
	fprintf(stderr,"%s", s);
}

#if 0
main()
{
	yyparse();
}
#endif
