package ru.hrundik.fScheme
{
	public class Name extends SExpression
	{
		public var value:String;
		
		public function Name(value:String)
		{
			this.value = value;
		}
		
		override public function toString ():String
		{
			return value;
		}
		
	}
}