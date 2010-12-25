package ru.hrundik.fScheme
{
public class Promise
{
	public function Promise(expression:*)
	{
		super();
		this.expression = expression;
	}
	
	public var resultEvaluated:Boolean = false;
	public var result:*;
	public var expression:*;
	
	public function toString():String
	{
	 	return "[Promise:]";
	}
}
}