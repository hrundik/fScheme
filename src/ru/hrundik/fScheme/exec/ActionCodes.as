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

package ru.hrundik.fScheme.exec
{
	public class ActionCodes
	{
		public static const CALL:int = 0;
		public static const EVALUATE:int = -1;
		public static const QUOTE:int = -2;
		public static const COND_CLAUSE:int = -3;
		public static const UNLESS_CLAUSE:int = -4;
		public static const END_OF_CLAUSES:int = -5;
		public static const DROP_RESULT:int = -6;
		public static const SET_CONTEXT:int = -7;
		public static const DEFINE:int = -8;
		public static const ALLOCATE:int = -9;
		public static const SET:int = -10;
		public static const LOOP:int = -11;
		public static const CASE_COND_CLAUSE:int = -12;
		public static const QUASIQUOTE:int = -13;
		public static const SAVE_PROMISE:int = -14;
		
		public static function textValue(code:int):String
		{
			switch(code)
			{
				case CALL:
					return "call";
				case EVALUATE:
					return "eval";
				case QUOTE:
					return "quote";
				case COND_CLAUSE:
					return "cond";
				case CASE_COND_CLAUSE:
					return "caseCond";
				case UNLESS_CLAUSE:
					return "unless";
				case END_OF_CLAUSES:
					return "end-of-clauses";
				case DROP_RESULT:
					return "dropResult";
				case SET_CONTEXT:
					return "setContext";
				case DEFINE:
					return "define";
				case ALLOCATE:
					return "allocate";
				case SET:
					return "set";
				case LOOP:
					return "loop";
				case QUASIQUOTE:
					return "quasiquote";
				case SAVE_PROMISE:
					return "savePromise";
				default:
					return "-unknown-";
			}
		}
	}
}