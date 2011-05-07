////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2010-2011 by Nikita Petrov                                      
//	                                                                             
// Permission is hereby granted, free of charge, to any person obtaining a copy  
// of this software and associated documentation files (the "Software"), to deal 
// in the Software without restriction, including without limitation the rights  
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell    
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//	
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//	
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////

package ru.hrundik.fScheme.parser
{
	import ru.hrundik.fScheme.Pair;
	import ru.hrundik.fScheme.Name;
	import ru.hrundik.fScheme.SExpression;
	
	// v. 0.2
	
	public class SchemeParser
	{
		public function SchemeParser()
		{
		
		}
		
		private static const numberStart:String = "0123456789";
		private static const possibleNumbers:String = "+-.";
		private static const firstChars:String = "!$%&*/:<=>?@^_~";
		private static const extChars:String = firstChars+possibleNumbers;
		
		private var skipSpaceRegExp:RegExp = new RegExp('\\s+', "g");
		private var firstCharRE:RegExp = new RegExp("[a-zA-Z"+firstChars+"]", "g");
		private var idRegExp:RegExp = new RegExp("([a-zA-Z"+firstChars+"][a-zA-Z0-9"+extChars+"]*)", "g");
		
		private var decimalRegExp:RegExp = new RegExp("(#d)?(#e|#i)?([+-]?)([0-9]*)\\.?([0-9]*)([sflde][0-9]*)?", "gi");
		private var hexRegExp:RegExp = new RegExp("#x(#e|#i)?([+-]?)([0-9a-f]+)", "gi");
		private var octalRegExp:RegExp = new RegExp("#o(#e|#i)?([+-]?)([0-7]+)", "gi"); 
		private var binaryRegExp:RegExp = new RegExp("#b(#e|#i)?([+-]?)([01]+)", "gi");
		
		private var expression:String;
		private var lastIndex:int = 0;
		
		public function parse (expression:String):*
		{
			this.expression = expression;
			var currentIndex:int = 0;
			lastIndex = 0;
			var beginExpr:Pair = new Pair(new Name("begin"), null);
			var currentExpr:Pair = beginExpr;
			while (lastIndex < expression.length)
			{
				var parsedExpr:* = parseExpression();
				if (lastIndex == currentIndex)
				{
					break;
				}
				else
				{
					currentExpr.cdr = new Pair(parsedExpr, null);
					currentExpr = currentExpr.cdrPair;
				}
				skipSpace();
			}
			
			if (lastIndex != expression.length)
				throw new Error("Syntax error at symbol #"+lastIndex);
			if (beginExpr.cdrPair == null)
				throw new Error("No expressions specified!");
			if (beginExpr.cdrPair.cdr == null)
			{
				return beginExpr.cdrPair.car;
			}
			else
			{
				currentExpr.cdr = new Pair(null, null);
				return beginExpr;
			}
		}
		
		private function parseExpression ():*
		{
			skipSpace();	
			var c:String = expression.charAt(lastIndex);
			var c2:String; 
			var innerExpr:*;
			var num:*;
			while (c == ";")
			{
				var endOfLine:int = expression.indexOf("\n", lastIndex);
				if (endOfLine == -1)
				{
					lastIndex = expression.length;
					return null;
				}	
				else
				{
					lastIndex = endOfLine+1;
					skipSpace();
					c = expression.charAt(lastIndex);
				}
			}
			
			if (c == '(')
			{
				return parseList();
			}
			else if (c == ')')
			{
				return null;
			}
			else if (c == "'") // (quote %)
			{
				lastIndex++;
				innerExpr = parseExpression();
				if (innerExpr == null)
					throw new Error("quote must have one parameter!");
				return new Pair(new Name("quote"), new Pair(innerExpr, new Pair()));
			}
			else if (c == "`") // quasiquote
			{
				lastIndex++;
				innerExpr = parseExpression();
				if (innerExpr == null)
					throw new Error("quasiquote must have one parameter!");
				return new Pair(new Name("quasiquote"), new Pair(innerExpr, new Pair()));
			}
			else if (c == ",") // unquote
			{
				lastIndex++;
				var splicing:Boolean = false;
				if(expression.charAt(lastIndex) == "@")
				{
					lastIndex++;
					splicing = true;
				}
				
				innerExpr = parseExpression();
				if (innerExpr == null)
					throw new Error("unquote must have one parameter!");
				
				return new Pair(new Name(splicing ? "unquote-splicing" : "unquote"), new Pair(innerExpr, new Pair()));
			}
			else if (c == '"') // we've got a string starting here!
			{
				return parseString();
			}
			else if (c == '#') // boolean, char, vector, number.
			{ 
				c2 = expression.charAt(lastIndex+1).toLowerCase();
				if(c2 == '(') // vector
				{
					return parseVector();
				}
				else if(c2 == 't')
				{
					lastIndex += 2;
					return true;
				}
				else if(c2 == 'f')
				{
					lastIndex += 2;
					return false;
				}
				else if(c2 == '\\') // char
				{
					lastIndex += 2;
					return parseChar();
				}
				else
				{
					num = null;
					if (c2 == "e" || c2 == "i") // ignore exact/inexact information
					{
						lastIndex += 2;
						c2 = expression.charAt(lastIndex+1).toLowerCase();
					}
						
					switch (c2)
					{
						case "x": // hex
							num = parseHexNumber();
							break;
						case "b": // binary
							num = parseBinaryNumber();
							break;
						case "o": // octal
							num = parseOctalNumber();
							break;
						case "d": // decimal
						default:
							num = parseDecimalNumber();
							break;
					}
					if (num != null)
						return num;
				}
				throw new Error("# may be used for boolean, numbers and vectors only for now!");
			}
			else if (numberStart.indexOf(c) > -1)
			{
				num = parseDecimalNumber(); // either int or Number	
				if (num != null)
					return num;
			}
			else if (possibleNumbers.indexOf(c) > -1)
			{
				// we should check next symbol at first
				c2 = expression.charAt(lastIndex+1);
				if (numberStart.indexOf(c2) > -1 || c2 == ".")
				{
					num = parseDecimalNumber();
					if (num != null)
						return num;
				}
			}
			
			firstCharRE.lastIndex = lastIndex;
			var match:Object = firstCharRE.exec(expression);
			if (match && match.index == lastIndex)
			{
				return parseName();
			}
			else // still may be a string or a special identifier (+, -, ., ...)
			{
				switch (c)
				{
					case "-":
					case "+":
					case ".":
						lastIndex++;
						return new Name(c);
						break;
				}
			} 
			
			return null;
		}
		
		private function parseVector ():Array
		{
			if(expression.charAt(lastIndex) != '#' && expression.charAt(lastIndex+1) != '(')
				throw new Error("parseVector called with a not-a-vector argument!");
			lastIndex += 2;
			
			var vector:Array = [];
			while (lastIndex < expression.length)
			{	
				var expr:* = parseExpression();
				if(expr != null)
				{
					vector.push(expr);
				}
				else if (expression.charAt(lastIndex) == ')')
				{
					lastIndex++;
					return vector;
				}
				else
				{
					break;
				}
			}
			
			throw new Error('Syntax error in vector definition at index '+lastIndex);
		}
		
		private function parseList ():Pair
		{
			var pair:Pair;
			var prevPair:Pair;
			var list:Pair;
			list = pair = new Pair();
			
			if (expression.charAt(lastIndex) != '(')
				throw new Error("parseList called with a not-a-list argument!");
			lastIndex++;	
			while (lastIndex < expression.length)
			{	
				var expr:* = parseExpression();
				if (expr != null)
				{
					if (pair == null || pair.car != null)
						throw new Error("Syntax error at symbol "+lastIndex);
					pair.car = expr;
					pair.cdr = new Pair();
					prevPair = pair;
					pair = pair.cdrPair;
				}
				else
				{			
					var c:String = expression.charAt(lastIndex);
					if (c == ')')
					{
						lastIndex++;
						return list;
					}
					else if (c == ".") // dotted pair
					{
						lastIndex++;
						if (prevPair)
						{
							prevPair.cdr = parseExpression();
							pair = null;
						}
						else // special "." name used for object manipulation
						{
							pair.car = new Name(".");
							pair.cdr = new Pair();
							prevPair = pair;
							pair = pair.cdrPair;
						}
					}
					else
					{
						break;
					}
				}
			}
			throw new Error("Syntax error: cannot find closing bracket!");
			return list;
		}
		
		private function parseName():Name
		{
			idRegExp.lastIndex = lastIndex;
			var idMatch:Object = idRegExp.exec(expression);
			if (!idMatch || idMatch.index != lastIndex)
				throw new Error("Syntax error at symbol #"+lastIndex);
			lastIndex = idRegExp.lastIndex;	
			return new Name(idMatch[1]);	
		}
		
		private function parseChar():String
		{
			var c:String = expression.charAt(lastIndex);
			if(c.match(/\s/))
				return " ";
			if(c.match(/\d/))
			{
				lastIndex++;
				return c;
			}
			
			idRegExp.lastIndex = lastIndex;
			var idMatch:Object = idRegExp.exec(expression);
			if (!idMatch || idMatch.index != lastIndex)
				throw new Error("Syntax error at symbol #"+lastIndex);
			
			lastIndex = idRegExp.lastIndex;
			
			var symbol:String = idMatch[1];
			if(symbol.length == 1)	
				return symbol;
			symbol = symbol.toLowerCase();
			
			if(symbol == "space")
				return " ";
			else if(symbol == "newline")
				return "\n";
			else if(symbol == "tab")
				return "\t";
			else
				throw new Error("Syntax error at char literal near symbol #"+lastIndex);
		}
		
		private function parseBoolean():*
		{
			var c:String = expression.charAt(lastIndex);
			if (c != "#")
				throw new Error("Non-boolean context passed to parseBoolean");
			lastIndex++;
			c = expression.charAt(lastIndex).toLowerCase();
			lastIndex++;
			if (c == 't')
			{
				return true;
			}
			else if (c == 'f')
			{
				return false;
			}
			else
			{
				lastIndex -= 2;
				return null;
			}
		}
		
		private function parseDecimalNumber ():*
		{
			decimalRegExp.lastIndex = lastIndex;
			var numMatch:Object = decimalRegExp.exec(expression);
			if (numMatch && numMatch.index == lastIndex)
			{
				lastIndex = decimalRegExp.lastIndex;
				if (numMatch[5]) // real
				{
					return parseFloat(numMatch[3]+numMatch[4]+"."+numMatch[5]);
				}
				else // integer
				{
					var n:String = numMatch[3]+numMatch[4];
					if (n)
						return int(parseInt(n));
					else 
						return null;
				}
			}
			else
			{
				return null;
			}
		}
		
		private function parseHexNumber ():*
		{
			hexRegExp.lastIndex = lastIndex;
			var numMatch:Object = hexRegExp.exec(expression);
			if (numMatch && numMatch.index == lastIndex)
			{
				lastIndex = hexRegExp.lastIndex;
				return int(parseInt(numMatch[2]+numMatch[3], 16));
			}
			else
			{
				return null;
			}	
		}
		
		private function parseOctalNumber ():*
		{
			octalRegExp.lastIndex = lastIndex;
			var numMatch:Object = octalRegExp.exec(expression);
			if (numMatch && numMatch.index == lastIndex)
			{
				lastIndex = octalRegExp.lastIndex;
				return int(parseInt(numMatch[2]+numMatch[3], 8));
			}
			else
			{
				return null;
			}	
		}
		
		private function parseBinaryNumber ():*
		{
			binaryRegExp.lastIndex = lastIndex;
			var numMatch:Object = binaryRegExp.exec(expression);
			if (numMatch && numMatch.index == lastIndex)
			{
				lastIndex = binaryRegExp.lastIndex;
				return int(parseInt(numMatch[2]+numMatch[3], 2));
			}
			else
			{
				return null;
			}	
		}
		
		private function parseString ():*
		{
			var str:String = "";
			var index:int = lastIndex;
			var l:int = expression.length;
			var c:String = expression.charAt(index);
			var prevC:String;
			if (c != '"')
				throw new Error("Error on parsing: parseString was called in not-a-string context!");
			index++;
			prevC = c;
			while (index < l)
			{
				c = expression.charAt(index);
				index++;
				if (prevC == "\\")
				{
					str += c;
					prevC = null;
				}
				else if (c != '"' && c != '\\')
				{
					str += c;
				}
				else if (c == '"')
				{
					lastIndex = index;
					return str;	
				}
				prevC = c;		  
			}
			throw new Error("Syntax error: string literal is not terminated, string begins at symbol "+lastIndex);
			return null;
		}
		
		private function skipSpace ():void
		{
			skipSpaceRegExp.lastIndex = lastIndex;
			var match:Object = skipSpaceRegExp.exec(expression);
			if (match && match.index == lastIndex)
				lastIndex = skipSpaceRegExp.lastIndex;
		}

	}
}