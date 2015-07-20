
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

#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <assert.h>
#include "command.h"
#include <regex.h>
#include <sys/types.h>

#define MAXFILENAME 1024

void sortArrayStrings(char **,int);
void expandWildcards(char *,char *);
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
	| NEWLINE {
		Command::_currentCommand.prompt();
	}
	| error NEWLINE { 
		yyerrok;
	}
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
              
		if(strchr($1,'*') == NULL && strchr($1,'?') == NULL){
			Command::_currentSimpleCommand->insertArgument($1);
		}
	        else {	
		//char *st =(char*)malloc(3);
		//st[0] = '\0';
	 	      	expandWildcards(NULL,$1);
		}
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

void expandWildcards(char * prefix, char * suffix){
	printf("Pref: [%s] Suff: [%s]\n", prefix, suffix);
	if(suffix[0] == 0){
		//Command::_currentSimpleCommand->insertArgument(strdup(prefix));
		return;
		}
	char * s  = strchr(suffix, '/');
	char arg[MAXFILENAME];
	if(s!=NULL){
		strncpy(arg,suffix,s-suffix);
		if(s-suffix == 0){
		//printf("BEF:[%s]\n",arg);
			arg[0] = '/';
			//suffix = s+1;
		//printf("AFTER:[%s]\n",arg);
		}
		suffix = s+1;
		//suffix ++;
	}
	else{
		strcpy(arg,suffix);
		suffix = suffix + strlen(suffix);
	}

	//printf("arg : [%s]\n",arg);
	//printf("suffix : [%s]\n",suffix);
	char newPrefix[MAXFILENAME];
	char * b;
	char * c;
	b = strchr(arg,'*');
	c = strchr(arg,'?');
	//printf("NEWPREF: [%s] SUFF: [%s]\n",newPrefix,suffix);
	//printf("ARG : [%s]\n",arg);
	if(0){//if(b == NULL && c == NULL){
		if( prefix == NULL && arg[0] != '\0'){
			
			sprintf(newPrefix,"%s",arg);
			expandWildcards(newPrefix,suffix);
			//printf("NEWPref: [%s] SUFF: [%s]\n",newPrefix,suffix); 
		}
		else if(prefix[0] == '/' && arg != NULL){
			sprintf(newPrefix,"/%s",arg);
			expandWildcards(newPrefix,suffix);		
		}

		else if(prefix != NULL  && arg[0] != '\0'){
			if(prefix[0] != '\0' && prefix[strlen(prefix) - 1] == '/'){
				prefix[strlen(prefix) -1] = '\0';			
			}
			sprintf(newPrefix,"%s/%s",prefix,arg);
			expandWildcards(newPrefix,suffix);
		}
		else if(prefix[0] == '\0' && arg[0] != '\0'){
			sprintf(newPrefix,"%s",arg);
			expandWildcards(newPrefix,suffix);
			//printf("NEWPREF: [%s] SUFF [%s]\n",newPrefix,suffix);
		}
		
		/*if(prefix[0] =='/'){
			sprintf(newPrefix,"%s/%s",prefix,arg);
			expandWildcards(newPrefix,suffix);
		}*/

		else if(arg[0] == '\0'){
			expandWildcards("",suffix);
		}
		//return;
	}
	
	//printf("Prefix : [%s]\n",prefix);
	//printf("suffix : [%s]\n",suffix);

	char * reg = (char*)malloc(2*strlen(arg) + 10);
	char * a = arg;
	char * r = reg;
	*r = '^';
	r++;

	while(*a) {
		if( *a == '*'){
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
	regco = regcomp(&re,reg,REG_EXTENDED | REG_NOSUB);

	if(regco!=0){
	perror("BAD regex bro, better luck next time");
	exit(1);
	}

	
	
	 char * dir;
	if(prefix == NULL){
		dir = strdup(".");
	}
	else
	{
		dir = strdup(prefix);
	}
	
	DIR * d = opendir(dir);
	if(d == NULL){
		//perror("OPENDIR");
		return;
	}

	struct dirent * ent;
	int maxEntries = 20;
	int nEntries = 0;
	char ** array = (char**)malloc(maxEntries*sizeof(char*));
	regmatch_t fucboi;
	while((ent = readdir(d))!=NULL){
	
		if(regexec(&re,ent->d_name,1,&fucboi,0)== 0){
			//printf("fucboi: [%s]\n", ent->d_name);
			if(nEntries == maxEntries){
				maxEntries*=2;
				array = (char**)realloc(array,maxEntries * sizeof(char*));
				assert(array!=NULL);
			}
			
				if(ent->d_name[0] == '.'){
					if(arg[0] == '.'){
						if(prefix != NULL){
							sprintf(newPrefix,"%s%s",prefix,ent->d_name);
							//expandWildcards(newPrefix,suffix);
							//printf("Prefix : [%s]\n",prefix);
							array[nEntries] = strdup(newPrefix);
							nEntries++;
						}
						else if(prefix == NULL){
							sprintf(newPrefix,"%s",ent->d_name);
							//printf("Prefixcunt : [%s]\n",newPrefix);
							//expandWildcards(newPrefix,suffix);
							array[nEntries] = strdup(newPrefix);
							nEntries++;
						}
						else{
						}

					}
				}
				else
				{	if(prefix != NULL){
							if(prefix[0]!= '\0' && prefix[strlen(prefix)-1] == '/'){
								prefix[strlen(prefix) -1] = '\0';
							}
							sprintf(newPrefix,"%s/%s",prefix, ent->d_name);
							
							expandWildcards(newPrefix,suffix);
							//printf("Prefix : [%s]\n",prefix);
							//printf("ent->d_name : [%s]\n",ent->d_name);
							array[nEntries] =strdup(newPrefix);
							nEntries++;
						}
						else if(prefix == NULL){
							sprintf(newPrefix,"%s",ent->d_name);
							//printf("Prefix : [%s]\n",prefix);
							//printf("ent->d_name : [%s]\n",ent->d_name);
							expandWildcards(newPrefix,suffix);
							array[nEntries] =strdup(newPrefix);
							nEntries++;
						}
						else{
						}
                                            
				}	
				expandWildcards(newPrefix,suffix);
			

		}	

	}
	closedir(d);
	free(dir);
	sortArrayStrings(array,nEntries);
	int i = 0;int j = 0;
		//printf("ARRAY is :%s\n",array[i]);
	/*	char ** tri = array;
		if(array[0][0] == '/' && array[0][1] == '/'){

		for(j = 1 ;j < nEntries;j++){
		Command::_currentSimpleCommand->insertArgument(tri[j]);
		}
	}*/
	
		for(i = 0;i < nEntries;i++){
		Command::_currentSimpleCommand->insertArgument(array[i]);
	}
	
	/*free(array);*/ 
	return;
}

void sortArrayStrings(char ** arr,int num){
	int i = 0;
	int j = 0;
	int boole = 1;
	do{
		boole = 0;
		for(j=0;j < num -1; j++){
			if(strcmp(arr[j],arr[j+1]) > 0){
				char * tmp = arr[j];
				arr[j] = arr[j+1];
				arr[j+1] = tmp;
				boole = 1;
			}
		}
	}
	while(boole);
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
