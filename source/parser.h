#ifndef _PARSER_H
#define _PARSER_H 1

#include "ast.h"

Function* parseFunction(Tokens* tokens);

BlockExpression* parseBlock(Tokens* tokens);

Expression* parseBinaryTree(Tokens* tokens);
Expression* parseParenthesis(Tokens* tokens);
Expression* parsePrimaryExpression(Tokens* tokens);
Expression* parseIdentifier(Tokens* tokens);
Expression* parseNumber(Tokens* tokens);
Expression* parseExpression(Tokens* tokens);

#endif // _PARSER_H
