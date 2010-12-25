package ru.hrundik.fScheme.exec
{
	import ru.hrundik.fScheme.Name;
	import ru.hrundik.fScheme.Pair;
	import ru.hrundik.fScheme.Promise;
	import ru.hrundik.fScheme.SExpression;
	
	public dynamic class SpecialForms
	{
		private var continuation:Continuation;
		
		public function SpecialForms(continuation:Continuation)
		{
			this.continuation = continuation;
			this["if"] = evalIf;
			this["do"] = evalDo;
			this["case"] = evalCase;
			this["let*"] = letSequenced;
			this["set!"] = setVar;
			this["'"] = quote;
			this["`"] = quasiquote;
		}
		
		private function get actionStack():Vector.<Action>
		{
			return continuation.actionStack;
		}
		
		public function quote (quotedPair:Pair):void
		{
			if (quotedPair.car == null)
				throw new Error("No parameters specified for quote!");
			else if (!quotedPair.cdrPair.isNull)
				throw new Error("Only one parameter may be passed to quote!");
			actionStack.push(new Action(ActionCodes.QUOTE, quotedPair.car));
		}
		
		public function quasiquote (qqPair:Pair):void
		{
			if(qqPair.car == null)
				throw new Error("No parameters specified for quasiquote!");
			else if (!qqPair.cdrPair.isNull)
				throw new Error("Only one parameter may be passed to quasiquote!");
			actionStack.push(new Action(ActionCodes.QUASIQUOTE, qqPair.car));
			
			scheduleQQ(qqPair.car);
		}
		
		private function scheduleQQ (arg:*):void
		{
			var evals:Vector.<Action> = new Vector.<Action>();
			var pairArg:Pair = arg as Pair;
			if(pairArg)
				scheduleListQQ(pairArg, evals);
			else if(arg as Array)
				scheduleVectorQQ(arg as Array, evals);
			
			pushActionsToStack(evals);
		}
		
		private function scheduleListQQ (arg:Pair, evals:Vector.<Action>):void
		{
			var name:String;
			while(!arg.isNull)
			{
				var carPair:Pair = arg.car as Pair;
				if(carPair && carPair.car is Name)
				{ 
					name = Name(carPair.car).value;
					if(name == 'unquote' || name == 'unquote-splicing')
					{
						if(!carPair.cdrPair.cdrPair.isNull)
							throw new Error("unquote must have only argument!");
						
						evals.unshift(new Action(ActionCodes.EVALUATE, carPair.cdrPair.car));
					}
					else if(name != 'quasiquote')
					{
						scheduleListQQ(carPair, evals);
					}
				}
				else if(carPair)
				{
					scheduleListQQ(carPair, evals);
				}
				else if(arg.car is Array)
				{
					scheduleVectorQQ(arg.car as Array, evals);
				}
				else if(arg.car is Name)
				{
					name = Name(arg.car).value;
					if(name == 'unquote' || name == 'unquote-splicing')
					{
						if(!arg.cdrPair.cdrPair.isNull)
							throw new Error("unquote must have only argument!");
						
						evals.unshift(new Action(ActionCodes.EVALUATE, arg.cdrPair.car));
					}
				}
				
				arg = arg.cdrPair;
			}
		}
		
		private function scheduleVectorQQ (arg:Array, evals:Vector.<Action>):void
		{
			var name:String;
			var n:int = arg.length;
			var tmpEvals:Vector.<Action>;
			var j:int;
			for(var i:int = n-1; i >= 0; i--)
			{
				var pair:Pair = arg[i] as Pair;
				if(pair && pair.car is Name)
				{
					name = Name(pair.car).value;
					if(name == 'unquote' || name == 'unquote-splicing')
					{
						if(!pair.cdrPair.cdrPair.isNull)
							throw new Error("unquote must have only argument!");
						evals.push(new Action(ActionCodes.EVALUATE, pair.cdrPair.car));
					}
					else if(name != 'quasiquote')
					{
						tmpEvals = new Vector.<Action>();
						scheduleListQQ(pair, tmpEvals);
						for(j=0; j < tmpEvals.length; j++)
							evals.push(tmpEvals[j]);
					}
					
				}
				else if(pair)
				{
					tmpEvals = new Vector.<Action>();
					scheduleListQQ(pair, tmpEvals);
					for(j=0; j < tmpEvals.length; j++)
						evals.push(tmpEvals[j]);
				}
				else if(arg[i] is Array)
				{
					scheduleVectorQQ(arg[i] as Array, evals);
				}
			}
		}
		
		public function delay(arg:Pair):void
		{
			var promise:Promise = new Promise(arg.car);
			var context:IContext = continuation.lexicalContext;
			var evalPromise:Function = function():*
			{
				if(promise.resultEvaluated)
					return promise.result;
				if(continuation.lexicalContext != context)
					saveCurrentContext();
				actionStack.push(new Action(ActionCodes.SAVE_PROMISE, promise));
				actionStack.push(new Action(ActionCodes.EVALUATE, promise.expression));
				if(continuation.lexicalContext != context)
					actionStack.push(new Action(ActionCodes.SET_CONTEXT, context));
			};
			continuation.resultStack.push(evalPromise);
		}
		
		private function evalDo (args:Pair):void
		{
			var vars:Pair = Pair(args.car);
			args = args.cdrPair;
			
			var bindings:Pair = new Pair();
			var increments:Pair = new Pair();
			var increment:Pair = increments;
			var curVar:Pair = vars;
			while (!curVar.isNull)
			{
				var curVarPair:Pair = Pair(curVar.car); 
				var name:Name = Name(curVarPair.car);
				var value:* = curVarPair.cdrPair.car;
				bindings = new Pair(new Pair(name, new Pair(value, null)), bindings);
				
				var incrExpr:* = curVarPair.cdrPair.cdrPair.car;
				if(incrExpr)
				{
					var curIncr:Pair = new Pair(new Name("set!"), new Pair(name, new Pair(incrExpr, new Pair())));
					increment.car = curIncr;
					increment = increment.cdr = new Pair();
				}
				curVar = curVar.cdrPair;
			}
			
			var testCond:Pair = Pair(args.car);
			var body:Pair = args.cdrPair;
			
			if(!body.isNull)
				body = new Pair(new Name("begin"), body);
			
			if(!increments.isNull)
			{
				if(body.isNull)
					body = new Pair(new Name("begin"), increments);
				else
					body = new Pair(new Name("begin"), new Pair(body, increments));
			}
			var ifClause:Pair = new Pair(testCond.car, // test expression
												  new Pair(testCond.cdrPair.car, // exit expression
												  new Pair(body, // loop body 
													  	   new Pair())));
			var fullIf:Pair = new Pair(new Name("if"), ifClause);
			scheduleLetLike(bindings, 
				function():void
				{
					actionStack.push(new Action(ActionCodes.LOOP, fullIf));
					evalIf(ifClause)
				});
		}
		
		private function evalCase (caseArgs:Pair):void
		{
			actionStack.push(new Action(ActionCodes.END_OF_CLAUSES));
			var caseExpr:* = caseArgs.car;
			caseArgs = caseArgs.cdr;
			
			var elseClause:*;
			var actions:Vector.<Action> = new Vector.<Action>();
			while(!caseArgs.isNull)
			{
				var curCase:Pair = caseArgs.car;
				var curExpr:* = curCase.cdr;
				if(curCase.car is Name && Name(curCase.car).value == "else")
				{
					elseClause = curExpr;
					if(!caseArgs.cdrPair.isNull)
						throw new Error("no statements allowed after else!");
					break;
				}
				else
				{
					var test:Pair = curCase.car;
					while(!test.isNull)
					{
						actions.unshift(new Action(ActionCodes.EVALUATE, test.car));
						actions.unshift(new Action(ActionCodes.CASE_COND_CLAUSE, curExpr));
						test = test.cdr;
					}
				}
				caseArgs = caseArgs.cdrPair;
			}
			if(elseClause)
				begin(elseClause);
			else
				actionStack.push(new Action(ActionCodes.QUOTE, false));

			actionStack.push(new Action(ActionCodes.DROP_RESULT));

			pushActionsToStack(actions);
			
			actionStack.push(new Action(ActionCodes.EVALUATE, caseExpr));
		}
		
		private function evalIf (ifClause:Pair):void
		{
			actionStack.push(new Action(ActionCodes.END_OF_CLAUSES));
			var trueClause:Pair = ifClause.cdrPair;
			var falseClause:Pair = trueClause.cdrPair;
			if (falseClause.isNull)
				actionStack.push(new Action(ActionCodes.QUOTE, false));
			else
				actionStack.push(new Action(ActionCodes.EVALUATE, falseClause.car));
			actionStack.push(new Action(ActionCodes.COND_CLAUSE, new Pair(trueClause.car, new Pair())));
			actionStack.push(new Action(ActionCodes.EVALUATE, ifClause.car));	
		}
		
		public function cond (clause:Pair):void
		{
			actionStack.push(new Action(ActionCodes.END_OF_CLAUSES));
			var elseClause:Pair;
			var furtherActions:Array = [];
			if (clause.isNull)
				throw new Error("cond should have at least one clause!");
			while (!clause.isNull)
			{
				var pair:Pair = clause.car;
				if(pair.car is Name && Name(pair.car).value == "else")
				{
					elseClause = pair.cdr;
					
					if(!clause.cdrPair.isNull)
						throw new Error("no statements allowed after else!");
					break;
				}
				else
				{	
					furtherActions.unshift(new Action(ActionCodes.EVALUATE, pair.car));
					if(pair.cdrPair.car is Name && Name(pair.cdrPair.car).value == "=>") 
						furtherActions.unshift(new Action(ActionCodes.COND_CLAUSE, pair.cdrPair.cdr));
					else
						furtherActions.unshift(new Action(ActionCodes.COND_CLAUSE, pair.cdr));
					clause = clause.cdrPair;
				}
			}
			if(elseClause)
				begin(elseClause);
			else
				actionStack.push(new Action(ActionCodes.QUOTE, false));
			
			for each (var furtherAction:Action in furtherActions)
				actionStack.push(furtherAction);
		}
		
		public function or (clause:Pair):void
		{
			actionStack.push(new Action(ActionCodes.END_OF_CLAUSES));
			actionStack.push(new Action(ActionCodes.QUOTE, false));
			var orActions:Array = [];
			while (!clause.isNull)
			{
				orActions.unshift(new Action(ActionCodes.EVALUATE, clause.car));
				orActions.unshift(new Action(ActionCodes.COND_CLAUSE));
				clause = clause.cdrPair;
			}
		}
		
		public function and (clause:Pair):void
		{
			if (clause.isNull) // no parameters passed to (and)
			{
				actionStack.push(new Action(ActionCodes.QUOTE, true));
			}
			else
			{
				actionStack.push(new Action(ActionCodes.END_OF_CLAUSES));
				var andActions:Vector.<Action> = new Vector.<Action>();
				while (true) 
				{
					andActions.unshift(new Action(ActionCodes.EVALUATE, clause.car));
					clause = clause.cdrPair;
					if (!clause.isNull)
						andActions.unshift(new Action(ActionCodes.UNLESS_CLAUSE));
					else
						break;					
				}
				pushActionsToStack(andActions);
			}
		}
		
		public function define (arg:Pair):void
		{
			var name:Name = arg.car as Name;
			if (name == null)
			{
				var args:Pair = arg.car as Pair;
				if (args == null)
					throw new Error("Define argument must be either a name or a single-level list.");
				name = args.car as Name;
				if (name == null)
					throw new Error("Procedure name should be specified correctly.");
				actionStack.push(new Action(ActionCodes.DEFINE, name));
				lambda(new Pair(args.cdr, arg.cdr));
			}
			else // simple variable
			{
				actionStack.push(new Action(ActionCodes.DEFINE, name));
				actionStack.push(new Action(ActionCodes.EVALUATE, arg.cdrPair.car));
			}				
		}
		
		private function setVar (arg:Pair):void
		{
			var name:Name = arg.car as Name;
			if (name == null)
				throw new Error("set! argument must be a proper name!");
			actionStack.push(new Action(ActionCodes.SET, name));
			actionStack.push(new Action(ActionCodes.EVALUATE, arg.cdrPair.car));
		} 
		
		public function lambda (lambdaArg:Pair):void
		{
			var args:SExpression = lambdaArg.car;
			var body:Pair = lambdaArg.cdrPair;
			var context:IContext = continuation.lexicalContext;	
			var proc:Function = function (...rest):*
			{
				saveCurrentContext();
				begin(body);
				// bind args
				if (args is Pair)
				{
					var arg:Pair = args as Pair;
					while (!arg.isNull)
					{
						actionStack.push(new Action(ActionCodes.DEFINE, arg.car));
						continuation.resultStack.push(rest.shift());
						if (arg.cdr is Name)
						{
							actionStack.push(new Action(ActionCodes.DEFINE, arg.cdr));
							continuation.resultStack.push(createList(rest));
							break;
						}
						else
						{
							arg = arg.cdr;
						}
					}
					if (arg.isNull && rest.length > 0)
						throw new Error("Wrong number of arguments passed!");
				}
				else if (args is Name)
				{
					actionStack.push(new Action(ActionCodes.DEFINE, args));
					continuation.resultStack.push(createList(rest));
				}
				else
				{
					throw new Error("lambda expression parameters should be specified either as list or as a single variable");
				}
				actionStack.push(new Action(ActionCodes.SET_CONTEXT, new ExpressionContext(context)));
			};
			continuation.resultStack.push(proc);
		}
		
		public function begin (arg:Pair):void
		{
			var evals:Array = [];
			while (arg && !arg.isNull)
			{
				if (evals.length > 0)
					evals.unshift(new Action(ActionCodes.DROP_RESULT));
				evals.unshift(new Action(ActionCodes.EVALUATE, arg.car));	
				arg = arg.cdrPair;
			}
			for each (var evalAction:Action in evals)
				actionStack.push(evalAction);
		}
		
		/**
		 * binds - a list of (name, evalValue) pairs
		 * bodyCall - parameter-less function which should schedule body of let-like construction 
		 */
		private function scheduleLetLike(binds:Pair, bodyCall:Function):void
		{
			saveCurrentContext();
			bodyCall();
			
			var defines:Vector.<Action> = new Vector.<Action>();
			var binding:Pair = binds;
			while (!binding.isNull) // bind all the variables
			{
				var name:Name = Name(Pair(binding.car).car);
				defines.unshift(new Action(ActionCodes.DEFINE, name));
				binding = binding.cdrPair;
			}
			pushActionsToStack(defines);
			actionStack.push(new Action(ActionCodes.SET_CONTEXT));
			
			binding = binds;
			while (!binding.isNull)
			{
				actionStack.push(new Action(ActionCodes.EVALUATE, Pair(binding.car).cdrPair.car));
				binding = binding.cdrPair;
			}
		}
		
		public function let (arg:Pair):void
		{
			var loopName:Name;
			if(arg.car is Name)
			{
				loopName = arg.car as Name;
				arg = arg.cdrPair;
			}
			
			var bindings:Pair = Pair(arg.car);
			var body:Pair = arg.cdrPair;
			
			if(loopName)
			{
				var lambdaArgs:Pair = new Pair();
				var binding:Pair = bindings;
				var lambdaArg:Pair = lambdaArgs;
				while (!binding.isNull)
				{
					lambdaArg.car = Pair(binding.car).car;
					lambdaArg = lambdaArg.cdr = new Pair();
					binding = binding.cdrPair;
				}
				var lambda:Pair = new Pair(new Name("lambda"), new Pair(lambdaArgs, body));
				bindings = new Pair(new Pair(loopName, new Pair(lambda, null)), bindings);
			}
			
			scheduleLetLike(bindings, function():void {begin(body)})
		}
		
		private function letSequenced (arg:Pair):void
		{
			var binding:Pair = Pair(arg.car);
			saveCurrentContext();
			var body:Pair = arg.cdrPair;
			begin(body);
			var definesAndEvals:Vector.<Action> = new Vector.<Action>();
			while (!binding.isNull) // bind all the variables
			{
				var name:Name = Name(Pair(binding.car).car);
				definesAndEvals.unshift(new Action(ActionCodes.EVALUATE, Pair(binding.car).cdrPair.car));
				definesAndEvals.unshift(new Action(ActionCodes.SET_CONTEXT));
				definesAndEvals.unshift(new Action(ActionCodes.DEFINE, name));
				binding = binding.cdrPair;
			}
			pushActionsToStack(definesAndEvals);
		}
		
		public function letrec (arg:Pair):void
		{
			var binding:Pair = Pair(arg.car);
			saveCurrentContext();
			var body:Pair = arg.cdrPair;
			begin(body);
			var definesAndEvals:Vector.<Action> = new Vector.<Action>();
			while (!binding.isNull) // initialize all the variables
			{
				var name:Name = Name(Pair(binding.car).car);
				definesAndEvals.unshift(new Action(ActionCodes.EVALUATE, Pair(binding.car).cdrPair.car));
				definesAndEvals.unshift(new Action(ActionCodes.SET, name));
				binding = binding.cdrPair;
			}
			pushActionsToStack(definesAndEvals);
			
			binding = Pair(arg.car);
			while (!binding.isNull) // allocate all the variables
			{
				name = Name(Pair(binding.car).car);
				actionStack.push(new Action(ActionCodes.ALLOCATE, name));
				binding = binding.cdrPair;
			}
			actionStack.push(new Action(ActionCodes.SET_CONTEXT, new ExpressionContext(continuation.lexicalContext)));
		}
		
		private function saveCurrentContext ():void
		{
			var len:int = actionStack.length;
			while(len > 0 && actionStack[len-1].actionCode == ActionCodes.CALL) // tail recursion optimization measures
			{
				len--;
			}
			if(len == 0 || actionStack[len-1].actionCode != ActionCodes.SET_CONTEXT)
				actionStack.push(new Action(ActionCodes.SET_CONTEXT, continuation.lexicalContext));
		}
		
		private function pushActionsToStack (actions:Vector.<Action>):void
		{
			for each (var action:Action in actions)
				actionStack.push(action);
		}
		
		private function createList (source:Array):Pair
		{
			var list:Pair = new Pair(null, null);
			var pair:Pair = list;
			for each (var val:* in source)
			{
				pair.car = val;
				pair = pair.cdr = new Pair(null, null);
			}
			return list;
		}
	}
}