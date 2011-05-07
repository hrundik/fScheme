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
	import flash.utils.getDefinitionByName;
	
	import ru.hrundik.fScheme.Name;
	import ru.hrundik.fScheme.Pair;
	import ru.hrundik.fScheme.Promise;
	import flash.utils.getTimer;
	
	// v 0.7
	final public class Continuation
	{
		public var resultStack:Array;
		public var actionStack:Vector.<Action>;
		
		public var lexicalContext:IContext;
		private var defaultContext:IContext;
		
		public var specialForms:Object;
		
		public var steps:int = 0;
		
		public var verbose:Boolean = false;
		
		public function Continuation(lexicalContext:IContext=null, specialFormsClass:Class = null)
		{
			resultStack = new Array();
			actionStack = new Vector.<Action>();
			if (lexicalContext == null)
				lexicalContext = new DefaultLexicalContext();
			
			if(lexicalContext is DefaultLexicalContext)
				DefaultLexicalContext(lexicalContext).continuation = this; 
			
			defaultContext = lexicalContext;
			this.lexicalContext = lexicalContext;
			
			if (specialFormsClass == null)
				this.specialForms = new SpecialForms(this);
			else
				this.specialForms = new specialFormsClass(this);
			
			init();
		}
		
		private var actionMap:Object;
		
		private var evalsTmp:Vector.<Action>;
		
		private var _executing:Boolean;
		public function get executing():Boolean
		{
			return _executing;
		}
		
		private function init():void
		{
			actionMap = {};
			actionMap[ActionCodes.CALL] = call;
			actionMap[ActionCodes.EVALUATE] = evaluate;
			actionMap[ActionCodes.QUOTE] = quote;
			actionMap[ActionCodes.COND_CLAUSE] = condClause;
			actionMap[ActionCodes.DROP_RESULT] = dropResult;
			actionMap[ActionCodes.UNLESS_CLAUSE] = unlessClause;
			actionMap[ActionCodes.END_OF_CLAUSES] = endOfClauses;
			actionMap[ActionCodes.SET_CONTEXT] = setContext;
			actionMap[ActionCodes.DEFINE] = define;
			actionMap[ActionCodes.ALLOCATE] = allocate;
			actionMap[ActionCodes.SET] = setVar;
			actionMap[ActionCodes.LOOP] = loop;
			actionMap[ActionCodes.CASE_COND_CLAUSE] = caseCondClause;
			actionMap[ActionCodes.QUASIQUOTE] = quasiquote;
			actionMap[ActionCodes.SAVE_PROMISE] = savePromise;
			
			evalsTmp = new Vector.<Action>(100);
		}
		
		public function execute(expression:*):*
		{
			actionStack = new Vector.<Action>();
			resultStack = [];
			
			if(expression)
				actionStack.push(new Action(ActionCodes.EVALUATE, expression));
			
			return executeToAction();
		}
		
		public function executeToAction(targetAction:Action = null):*
		{
			var mainExecutor:Boolean = !_executing;
			if (mainExecutor)
				_executing = true;
			while (actionStack.length > 0)
			{
				if(verbose)
					traceState();
				
				steps++;
				if(verbose)
					trace("-------------");
				
				var action:Action = actionStack.pop();
				actionMap[action.actionCode](action);
				
				if(targetAction && action == targetAction)
					break;
			}
			
			if (mainExecutor)
				_executing = false;
			if (resultStack.length > 0)
				return resultStack.pop();
			else
				return undefined;
		}
		
		public function traceState():void
		{
			trace("Step:", steps);
			trace("Actions:");
			for(var i:int = actionStack.length-1; i >= 0; i--)
			{
				trace(i+":",ActionCodes.textValue(actionStack[i].actionCode), actionStack[i].argument);
			}
			
			trace("Results:");
			for(i = resultStack.length-1; i >= 0; i--)
			{
				trace(i+":", resultStack[i]);
			}
				
		}
		
//
//		Actions for action codes
//		
		private function call (action:Action):void
		{
			var args:Array;
			if(action.argument == -1)
			{
				var arg:* = resultStack.pop();
				if(arg is Array)
					args = arg;
				else
					args = [arg];
			}
			else
			{
				args = new Array(action.argument);
				for (var i:int = action.argument-1; i >= 0; i--)
				{
					args[i] = resultStack.pop();
				}
			}
			
			var func:Function = resultStack.pop() as Function;
			if (func == null)
				throw new Error("Error on calling function - function undefined");
			var n:int = actionStack.length;
			if(n > 0 && actionStack[n-1].actionCode == ActionCodes.END_OF_CLAUSES)
				actionStack.pop();
			
			var value:* = func.apply(this, args);
			if (value !== undefined)
				resultStack.push(value);
				
		}
		
		private function evaluate (action:Action):void
		{
			var arg:* = action.argument;
			if (arg is Pair)
			{
				var pairArg:Pair = Pair(arg);
				var funcExpr:* = pairArg.car;
				var specialForm:Function;
				if (funcExpr is Name)
					specialForm = specialForms[Name(funcExpr).value] as Function;
				
				if (specialForm != null)
				{
					specialForm(pairArg.cdrPair);
				}
				else
				{
					var callAction:Action = new Action(ActionCodes.CALL, 0); 
					actionStack.push(callAction);
					var evals:Vector.<Action> = evalsTmp;
					var ei:int = evals.length-1;
					evals[ei] = new Action(ActionCodes.EVALUATE, funcExpr);
					var callArg:Pair = pairArg.cdrPair;
					while (!callArg.isNull)
					{
						if (ei == 0)
						{
							evals = new Vector.<Action>(100).concat(evals);
							ei = 100;
						}
						
						evals[--ei] = new Action(ActionCodes.EVALUATE, callArg.car);
						callAction.argument++;
						callArg = callArg.cdrPair;
					}
					
					var n:int = evals.length;
					for (; ei < n; ei++)
					{
						actionStack.push(evals[ei]);
					}
				}
			}
			else if (arg is Name) // evaluate value
			{
				var value:* = getValueByName(Name(arg));
				if (value == null)
					throw new Error("Variable '"+Name(arg).value+"' is not defined!");
				resultStack.push(value);
			}
			else if (arg is Boolean || arg is int || arg is Number || arg is String || arg is Function)
			{
				resultStack.push(arg);
			}
			else 
			{
				throw new Error("evaluation error - unknown argument type!");
			}
		}
		
		private function getValueByName (name:Name):*
		{
			var context:IContext = lexicalContext;
			var nameValue:String = name.value;
			var value:*;
			while (context != null)
			{
				value = context[nameValue];
				if (value !== undefined)
					return value;
				context = context.parentContext;
			}
			
			// try class name definition
			try
			{
				var definition:Object = getDefinitionByName(nameValue);
				return definition;
			}
			catch (e:ReferenceError)
			{
				throw new Error("Value of "+name+" is undefined!");
			}
		}
		
		private function quote (action:Action):void
		{
			resultStack.push(action.argument);
		}
		
		private function quasiquote (action:Action):void
		{
			var pairArg:Pair = action.argument as Pair;
			if(pairArg)
			{
				resultStack.push(unquoteList(pairArg));
				return;
			}
			
			var vecArg:Array = action.argument as Array;
			if(vecArg)
			{
				resultStack.push(unquoteVector(vecArg));
				return;
			}
			
			resultStack.push(action.argument);
		}
		
		private function unquoteList (list:Pair):*
		{
			if(list.isNull)
				return list;
			
			var name:Name;
			if(list.car is Name)
			{
				name = list.car as Name;
				if(name.value == "unquote" || name.value == "unquote-splicing")
				{
					return resultStack.pop();
				}
			}
			
			// trace(list.toString());
			list.cdr = unquoteList(list.cdrPair);
			// trace(list.toString());
			
			var carPair:Pair = list.car as Pair;
			if(carPair)
			{
				name = carPair.car as Name;
				if(name)
				{
					if(name.value == "unquote")
					{
						list.car = resultStack.pop();
					}
					else if(name.value == "unquote-splicing")
					{
						var valueList:* = resultStack.pop();
						if(valueList is Pair)
						{
							if(!Pair(valueList).isNull)
							{
								var cdr:* = list.cdr;
								list = valueList;
								while(!valueList.cdrPair.isNull)
								{
									valueList = valueList.cdrPair;
								}
								valueList.cdr = cdr;
							}
							else
							{
								return list.cdr;
							}
						}
						else
						{
							list.car = valueList;
						}
					}
					else if(name.value != "quasiquote")
					{
						unquoteList(carPair);
					}
				}
				else 
				{
					unquoteList(carPair);
				}
			}
			else if(list.car is Array)
			{
				unquoteVector(list.car as Array);
			}
			return list;
		}
		
		private function unquoteVector (vec:Array):Array
		{
			var n:int = vec.length - 1;
			for(var i:int = n; i >= 0; i--)
			{
				var pair:Pair = vec[i] as Pair;
				if(pair)
				{
					var name:Name = pair.car as Name;
					if(name)
					{
						if(name.value == "unquote")
						{
							vec[i] = resultStack.pop();
						}
						else if(name.value == "unquote-splicing")
						{
							var valueList:Pair = resultStack.pop();
							var items:Array = defaultContext["list->vector"](valueList);
							if(items.length == 0)
							{
								vec.splice(i, 1);
							}
							else
							{
								vec.splice.apply(vec, [i, 1].concat(items));
							}
						}
						else if(name.value != "quasiquote")
						{
							unquoteList(pair);
						}
					}
					else
					{
						unquoteList(pair);
					}
				}
				else if(vec[i] is Array)
				{
					unquoteVector(vec[i]);
				}
			}
			
			return vec;
		}
		
		private function savePromise (action:Action):void
		{
			var promise:Promise = Promise(action.argument); 
			promise.resultEvaluated = true;
			promise.result = resultStack[resultStack.length-1];
		}
		
		private function caseCondClause (action:Action):void
		{
			var curTest:Object = resultStack.pop();
			var len:int = resultStack.length;
			var compare:Object = resultStack[len - 1];
			if(defaultContext['eqv?'](curTest, compare))
			{
				resultStack.pop(); // remove compare object
				discardClauses();
				
				var arg:Pair = action.argument as Pair;			
				if (arg == null || arg.isNull)
					resultStack.push(curTest);
				else
					SpecialForms(specialForms).begin(arg);		
			}
		}
		
		private function condClause (action:Action):void
		{
			var result:Object = resultStack.pop();
			if (result is Boolean && !result)
				return;
				
			discardClauses();
			
			var arg:Pair = action.argument as Pair;			
			if (arg == null || arg.isNull)
				resultStack.push(result);
			else
				SpecialForms(specialForms).begin(arg);
		}
		
		private function discardClauses():void
		{
			var omittedAction:Action;
			do 
			{
				omittedAction = actionStack.pop();
			} while (omittedAction.actionCode != ActionCodes.END_OF_CLAUSES);
			
			// check if there is a LOOP action after END_OF_CLAUSES and remove it
			// because (cond) was executed successfully
			var lastIndex:Number = actionStack.length - 1; 
			if(lastIndex >= 0 && actionStack[lastIndex].actionCode == ActionCodes.LOOP)
				actionStack.pop();
		}
		
		private function unlessClause (action:Action):void
		{
			var result:Object = resultStack.pop();
			if (result is Boolean && !result)
			{
				discardClauses();
				resultStack.push(result);
			}
		}
		
		private function endOfClauses(action:Action):void
		{
		}
		
		private function loop(action:Action):void
		{
			resultStack.pop(); // discard action of the last evaluation
			actionStack.push(action);
			actionStack.push(new Action(ActionCodes.EVALUATE, action.argument));
		}
		
		private function dropResult (action:Action):void
		{
			resultStack.pop();
		}
		
		private function setContext (action:Action):void
		{
			if(action.argument)
				lexicalContext = IContext(action.argument);
			else
				lexicalContext = new ExpressionContext(lexicalContext);
		}
		
		private function define (action:Action):void
		{
			lexicalContext[Name(action.argument).value] = resultStack.pop();
		}
		
		private function allocate (action:Action):void
		{
			lexicalContext[Name(action.argument).value] = null;
		}
		
		private function setVar (action:Action):void
		{
			if (action.argument)
			{
				var nameString:String = Name(action.argument).value;
				var context:IContext = lexicalContext;
				while (context != null)
				{
					if (context[nameString] !== undefined)
					{
						context[nameString] = resultStack[resultStack.length-1];
						return;					
					}
					context = context.parentContext;
				}
				throw new Error("set!: "+nameString+" is not defined.");
			}
			else // setting instance field, which should be on the stack
			{
				var fieldName:String = resultStack.pop();
				var instance:Object = resultStack.pop();
				instance[fieldName] = resultStack[resultStack.length-1];
			}
		}
	}
}