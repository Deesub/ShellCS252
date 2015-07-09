
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
	
	_arguments[ _numberOfArguments ] = argument;

	// Add NULL argument at the end
	_arguments[ _numberOfArguments + 1] = NULL;
	
	_numberOfArguments++;

	int len = strlen(argument);
	if(len <= 0){
		_exit(1);
	}
	else if(len == 1){
		if(argument[0] == '~'){
			argument = strdup(getenv("HOME"));
		}
		else{
			argument = strdup(getpwnam(argument+1)->pw_dir);
		}
	}
	else{
	}
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
	_exit(1);
	}


	if(!strcmp(_simpleCommands[i]->_arguments[0],"cd")){
			char ** p =environ;
			int count = 0;
			int res = 0;
			while(*p != NULL){
				if(strncmp(*p,"HOME",4)){
					break;
					}
				p++;
				count++;
			}
			char hdir[count];
		        
			if(_simpleCommands[i]->_numberOfArguments > 0)
				res = chdir(_simpleCommands[i]->_arguments[1]);
			else if(_simpleCommands[i]->_numberOfArguments <= 0)
				res = chdir(hdir);
			else{
				_exit(1);
			}

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
				fdout=open(_outFile,O_RDWR|O_CREAT|O_TRUNC,0700);
			}
			else {
			// Use default output
			fdout=dup(tmpout);
			}
			if(_errFile){
			dup2(fdout,2);
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

		if(!strcmp(_simpleCommands[i]->_arguments[0],"setenv")){
			
			setenv(_simpleCommands[i]->_arguments[1],_simpleCommands[i]->_arguments[2],1);
			clear();
			prompt();
			return;

		}

		

		if(!strcmp(_simpleCommands[i]->_arguments[0],"unsetenv")){
			unsetenv(_simpleCommands[i]->_arguments[1]);
			clear();
			prompt();
			return;
		}

		
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

extern "C" void disp( int sig ){
	fprintf(stderr,"\n");
}



Command Command::_currentCommand;
SimpleCommand * Command::_currentSimpleCommand;

int yyparse(void);

main()
{
	Command::_currentCommand.prompt();
	yyparse();
}

