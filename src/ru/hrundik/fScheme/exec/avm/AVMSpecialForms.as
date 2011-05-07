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

package ru.hrundik.fScheme.exec.avm
{
import flash.utils.getDefinitionByName;

import ru.hrundik.fScheme.Name;
import ru.hrundik.fScheme.Pair;
import ru.hrundik.fScheme.exec.Action;
import ru.hrundik.fScheme.exec.ActionCodes;
import ru.hrundik.fScheme.exec.Continuation;
import ru.hrundik.fScheme.exec.SpecialForms;

public dynamic class AVMSpecialForms extends SpecialForms
{
	public function AVMSpecialForms(continuation:Continuation)
	{
		super(continuation);
		this["."] = call_arg;
		this["import"] = import_impl;
	}
	
	private function call_arg(pairArg:Pair):*
	{
		var callAction:Action = new Action(ActionCodes.CALL, 2);
		actionStack.push(callAction);
		
		var evals:Vector.<Action> = evalsTmp;
		var ei:int = evals.length;
		evals[--ei] = new Action(ActionCodes.QUOTE, call_arg_impl);
		evals[--ei] = new Action(ActionCodes.EVALUATE, pairArg.car); // instance
		
		var fieldNameArg:Pair = pairArg.cdrPair;
		
		if (fieldNameArg.car is Name || fieldNameArg.car is String) //  don't evaluate field name if it's a name
			evals[--ei] = new Action(ActionCodes.QUOTE, fieldNameArg.car);
		else // but evaluate it in all other cases (this way 
			evals[--ei] = new Action(ActionCodes.EVALUATE, fieldNameArg.car);
		
		var callArg:Pair = fieldNameArg.cdrPair;
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
	
	private function call_arg_impl(instance:Object, argName:String, ...args):*
	{
		var arg:* = instance[argName];
		if (args.length > 0 || arg is Function)
			return arg.apply(instance, args);
		else		
			return arg;
	}
	
	// prop is used when you need to get property containing Function
	// . will call it instead
	public function prop(pairArg:Pair):void
	{
		var callAction:Action = new Action(ActionCodes.CALL, 2);
		actionStack.push(callAction);
		
		var fieldNameArg:Pair = pairArg.cdrPair;
		if (fieldNameArg.car is Name || fieldNameArg.car is String) //  don't evaluate field name if it's a name
			actionStack.push(new Action(ActionCodes.QUOTE, fieldNameArg.car));
		else // but evaluate it in all other cases (this way 
			actionStack.push(new Action(ActionCodes.EVALUATE, fieldNameArg.car));
		
		actionStack.push(new Action(ActionCodes.EVALUATE, pairArg.car)); // instance
		actionStack.push(new Action(ActionCodes.QUOTE, prop_impl));
	}
	
	private function prop_impl(instance:*, propName:String):*
	{
		return instance[propName];
	}
	
	override protected function setVar(arg:Pair):void
	{
		var instanceProp:Pair = arg.car as Pair;
		if (instanceProp && instanceProp.car is Name && Name(instanceProp.car).value == ".")
		{
			var instanceExpr:* = instanceProp.cdrPair.car;
			var fieldNameArg:* = instanceProp.cdrPair.cdrPair.car;
			if (!instanceProp.cdrPair.cdrPair.cdrPair.isNull)
				throw new Error("set! instance field argument should have (. instance field) syntax");
			
			actionStack.push(new Action(ActionCodes.SET));
			
			if (fieldNameArg is Name || fieldNameArg is String)
				actionStack.push(new Action(ActionCodes.QUOTE, fieldNameArg));
			else
				actionStack.push(new Action(ActionCodes.EVALUATE, fieldNameArg));
			actionStack.push(new Action(ActionCodes.EVALUATE, instanceExpr));
			
			actionStack.push(new Action(ActionCodes.EVALUATE, arg.cdrPair.car));
		}
		else
		{
			super.setVar(arg);
		}
	}
	
	private function import_impl(arg:Pair):void
	{
		var name:Name = arg.car as Name;
		var className:String = name.value;
		var classAlias:String = className.split(".").pop();
		actionStack.push(new Action(ActionCodes.DEFINE, new Name(classAlias)));
		actionStack.push(new Action(ActionCodes.QUOTE, getDefinitionByName(className)));
	}
}
}