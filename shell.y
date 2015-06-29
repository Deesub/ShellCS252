
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
#include "command.h"
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
	command_and_args pipe_list iomodifier_opt background_optional NEWLINE {
		printf("   Yacc: Execute command\n");
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
               printf("   Yacc: insert argument \"%s\"\n", $1);

	       Command::_currentSimpleCommand->insertArgument( $1 );\
	}
	;

command_word:
	WORD {
               printf("   Yacc: insert command \"%s\"\n", $1);
	       
	       Command::_currentSimpleCommand = new SimpleCommand();
	       Command::_currentSimpleCommand->insertArgument( $1 );
	}
	;

pipe_list:
pipe_list PIPE  command_and_args
| command_and_args
|
;

iomodifier_opt:
        GREAT WORD {
		printf("   Yacc: insert output \"%s\"\n", $2);
		Command::_currentCommand._outFile = $2;
	}
	| GREATGREAT WORD {
		printf("   Yacc: insert output \"%s\"\n",$2);
		Command::_currentCommand._outFile = $2; 
	}
	| GREATAMPERSAND WORD {
		printf("    Yacc: insert output \"%s\"\n",$2);
		Command::_currentCommand._outFile = $2;
		printf("    Yacc: insert error \"%s\"\n",$2);
		Command::_currentCommand._errFile = $2;
	}
	| GREATGREATAMPERSAND WORD {
		printf("    Yacc: insert output \"%s\"\n",$2);
		Command::_currentCommand._outFile = $2;
		printf("    Yacc: insert error \"%s\"\n",$2);
		Command::_currentCommand._errFile = $2;
	}
	| LESS WORD {
		printf("    Yacc: insert input \"%s\"\n",$2);
		Command::_currentCommand._inputFile = $2;
		
	}
	|
	;

background_optional:
	AMPERSAND {
	Command::_currentCommand._background = 1;
	}
	|
	;
%%

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
