package ru.hrundik.fScheme.exec
{
public class FrozenContinuation
{
	public function FrozenContinuation(continuation:Continuation)
	{
		actionStack = continuation.actionStack.concat(); // create copy
		resultStack = continuation.resultStack.concat(); // also copy
		lexicalContext = continuation.lexicalContext; // no copy
	}
	
	public var actionStack:Vector.<Action>;
	public var resultStack:Array;
	
	public var lexicalContext:IContext;
}
}