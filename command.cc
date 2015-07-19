
/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <signal.h>
#include <fcntl.h>
#include <pwd.h>

#include "command.h"

extern char **environ;

SimpleCommand::SimpleCommand()
{
	// Creat available space for 5 arguments
	_numberOfAvailableArguments = 5;
	_numberOfArguments = 0;
	_arguments = (char **) malloc( _numberOfAvailableArguments * sizeof( char * ) );
}

void
SimpleCommand::insertArgument( char * argument )
{
	if ( _numberOfAvailableArguments == _numberOfArguments  + 1 ) {
		// Double the available space
		_numberOfAvailableArguments *= 2;
		_arguments = (char **) realloc( _arguments,
				  _numberOfAvailableArguments * sizeof( char * ) );
	}
	
	int len = strlen(argument);
	int i = 0;
	int j = 0;
	int k = 0;
	int p = 0;
	int q = 0;
	int ctr = 0;
	int count = 0;

	char * esc = (char*)malloc(100);
	char * fin = (char*)malloc(100);
	char * no = (char*)malloc(100);
	char * env = (char*)malloc(100);
	char * exp = (char*)malloc(100);
	if(strchr(argument,'$') != NULL){

		for(i = 0; argument[i] != '\0';i++){
			if(argument[i] ==  '$' ){
				if(argument[i+1] == '{'){
					i += 2;
				}
				else{

				}
				for(i;argument[i] != '}';i++){
					env[j++] = argument[i];
				}
				k = j;
				env[k] = '\0';
				exp = getenv(env);
				strcat(fin,exp);
				free(env);
				j = 0;
			}
			else{ 
				for(i;argument[i] != '$' && argument[i] != '\0';i++){
					if(argument[i+1] == '{'){

					}
					else
					{
					no[j++] = argument[i];		
					k = j;
					}
				}
				no[k] = '\0';
				strcat(fin,no);
				free(no);
				count = 1;
				i--;
				j = 0;
			}	
	
		}
		argument = strdup(fin);
	}

	if(strchr(argument,'\\') != NULL){
		for(i = 0;argument[i] != '\0';i++){
			if(argument[i] == '\\'){
				i+=1;
			}
			esc[p++] = argument[i];
		}
		q = p;
		esc[q] = '\0';
		argument = strdup(esc);

	}

	if(len < 0){
		_exit(1);
	}
	else if(argument[0] == '~' && len > 0 ){
		if(len == 1){
			argument = strdup(getenv("HOME"));
		}
		else
		{
			argument = strdup(getpwnam(argument+1)->pw_dir);
		}
	} 
	_arguments[ _numberOfArguments ] = argument;

	// Add NULL argument at the end
	_arguments[ _numberOfArguments + 1] = NULL;
	
	_numberOfArguments++;
}

Command::Command()
{
	// Create available space for one simple command
	_numberOfAvailableSimpleCommands = 1;
	_simpleCommands = (SimpleCommand **)
		malloc( _numberOfSimpleCommands * sizeof( SimpleCommand * ) );

	_numberOfSimpleCommands = 0;
	_outFile = 0;
	_inputFile = 0;
	_errFile = 0;
	_background = 0;
}

void
Command::insertSimpleCommand( SimpleCommand * simpleCommand )
{
	if ( _numberOfAvailableSimpleCommands == _numberOfSimpleCommands ) {
		_numberOfAvailableSimpleCommands *= 2;
		_simpleCommands = (SimpleCommand **) realloc( _simpleCommands,
			 _numberOfAvailableSimpleCommands * sizeof( SimpleCommand * ) );
	}
	
	_simpleCommands[ _numberOfSimpleCommands ] = simpleCommand;
	_numberOfSimpleCommands++;
}

void
Command:: clear()
{
	for ( int i = 0; i < _numberOfSimpleCommands; i++ ) {
		for ( int j = 0; j < _simpleCommands[ i ]->_numberOfArguments; j ++ ) {
			free ( _simpleCommands[ i ]->_arguments[ j ] );
		}
		
		free ( _simpleCommands[ i ]->_arguments );
		free ( _simpleCommands[ i ] );
	}

	if ( _outFile ) {
		free( _outFile );
	}

	if ( _inputFile ) {
		free( _inputFile );
	}

	if ( _errFile ) {
		free( _errFile );
	}

	_numberOfSimpleCommands = 0;
	_outFile = 0;
	_inputFile = 0;
	_errFile = 0;
	_background = 0;
}

void
Command::print()
{
	printf("\n\n");
	printf("              COMMAND TABLE                \n");
	printf("\n");
	printf("  #   Simple Commands\n");
	printf("  --- ----------------------------------------------------------\n");
	
	for ( int i = 0; i < _numberOfSimpleCommands; i++ ) {
		printf("  %-3d ", i );
		for ( int j = 0; j < _simpleCommands[i]->_numberOfArguments; j++ ) {
			printf("\"%s\" \t", _simpleCommands[i]->_arguments[ j ] );
		}
	}

	printf( "\n\n" );
	printf( "  Output       Input        Error        Background\n" );
	printf( "  ------------ ------------ ------------ ------------\n" );
	printf( "  %-12s %-12s %-12s %-12s\n", _outFile?_outFile:"default",
		_inputFile?_inputFile:"default", _errFile?_errFile:"default",
		_background?"YES":"NO");
	printf( "\n\n" );
	
}

void
Command::execute()
{	
	int i = 0;
	// Don't do anything if there are no simple commands
	if ( _numberOfSimpleCommands == 0 ) {
		//fflush(stdout);
		//clear();
		prompt();
		return;
	}
	if(strcmp(_simpleCommands[0]->_arguments[0],"exit") == 0){
	printf("Goodbye! \n\n" );
	_exit(1);
	}

	if(!strcmp(_simpleCommands[i]->_arguments[0],"setenv")){
			setenv(_simpleCommands[i]->_arguments[1],_simpleCommands[i]->_arguments[2],1);

	}


	if(!strcmp(_simpleCommands[i]->_arguments[0],"unsetenv")){
			unsetenv(_simpleCommands[i]->_arguments[1]);
	}




	if(strcmp(_simpleCommands[i]->_arguments[0],"cd") == 0){
		
			int res = 0;
			char * argv1 = _simpleCommands[0]->_arguments[1];
			char * hdir = getenv("HOME");
			if(argv1 != NULL && _simpleCommands[0]->_numberOfArguments >= 1 )
				res = chdir(argv1);
			else
				//char * hdir = getenv("HOME");
				res = chdir(hdir);

			if(res == 0){
				clear();
				prompt();
				return;
			}
			else
				perror("chdir");

		}


	// Print contents of Command data structure
	//print();

	



	int tmpin=dup(0);
	int tmpout=dup(1);
	int tmperr = dup(2);
	//set the initial input
	int fdin;	
	if (_inputFile) {
		fdin = open(_inputFile,O_RDONLY, 0700);
	}
	else {
		// Use default input
		fdin = dup(tmpin);
	}
	int ret;
	int fdout;
	int ferr;
	for(i=0;i<_numberOfSimpleCommands;i++) {
		//redirect input
		dup2(fdin, 0);
		close(fdin);
		//setup output
		if (i == _numberOfSimpleCommands-1){
			// Last simple command
			if(_outFile){
				if(_app == 1)
					fdout=open(_outFile,O_RDWR|O_CREAT|O_APPEND,0600);
				else if(_app == 0)
					fdout=open(_outFile,O_RDWR|O_CREAT|O_TRUNC,0600);
			}
			else {
			// Use default output
				fdout=dup(tmpout);
			}
			if(_errFile){
				dup2(fdout,2);			
			}
			else{
				ferr = dup(tmperr);

			}

		}
		
		else {
			// Not last
			//simple command
			//create pipe
			int fdpipe[2];
			pipe(fdpipe);
			fdout=fdpipe[1];
			fdin=fdpipe[0];
		}	
		// if/else
		// Redirect output
		dup2(fdout,1);
		close(fdout);

		

		
		
		ret=fork();
		if(ret==0) {
			if(!strcmp(_simpleCommands[i]->_arguments[0],"printenv")){
				char **p = environ;
				while(*p != NULL){
					printf("%s\n",*p);
					p++;
				}
				exit(0);
			}


		execvp(_simpleCommands[i]->_arguments[0],_simpleCommands[i]->_arguments);
		perror("execvp");
		_exit(1);
		}
		else if(ret<0){
			perror("fork");
			_exit(2);
		}
		else{
			// This is the parent process
			// ret is the pid of the child
			// Wait until the child exits
			waitpid(ret, NULL,0);
		}
	} // for







		// execute

		// Add execution here
		// For every simple command fork a new process
		// Setup i/o redirection
		// and call exec

	dup2(tmpin,0);
	dup2(tmpout,1);
	dup2(tmperr,2);
	close(tmpin);
	close(tmpout);
	close(tmperr);
	if (!_background) {
// Wait for last command
	waitpid(ret, NULL,0);
	}	





	

		// Clear to prepare for next command
	clear();
	
	// Print new prompt
	prompt();
}

// Shell implementation

void
Command::prompt()
{
if(isatty(0)){
	printf("myshell>");
	
	fflush(stdout);
}
}

void disp( int sig ){
	fprintf(stderr,"\n");
	Command::_currentCommand.prompt();
}

void killzombie(int sig){
	while(waitpid(-1,NULL,WNOHANG) > 0);
}



Command Command::_currentCommand;
SimpleCommand * Command::_currentSimpleCommand;

int yyparse(void);

main()
{	

	struct sigaction signalAction;
	signalAction.sa_handler = killzombie;
	sigemptyset(&signalAction.sa_mask);
	signalAction.sa_flags = SA_RESTART;
	int error = sigaction(SIGCHLD, &signalAction, NULL );
	if ( error )
	{
		perror( "sigaction" );
		exit( -1 );
	}
	
	struct sigaction signalAction1;
	signalAction1.sa_handler = disp;
	sigemptyset(&signalAction1.sa_mask);
	signalAction1.sa_flags = SA_RESTART;
	int error1 = sigaction(SIGINT, &signalAction1, NULL );
	if ( error1 )
	{
		perror( "sigaction" );
		exit( -1 );
	}


	Command::_currentCommand.prompt();
	yyparse();
}

