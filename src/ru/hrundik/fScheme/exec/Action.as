package ru.hrundik.fScheme.exec
{
	import ru.hrundik.fScheme.SExpression;
	
	public class Action
	{
		public var actionCode:int; // positive action code means function call with N parameters
		public var argument:*;
		
		public function Action(actionCode:int, argument:*=null)
		{
			this.actionCode = actionCode;
			this.argument = argument;
		}

	}
}