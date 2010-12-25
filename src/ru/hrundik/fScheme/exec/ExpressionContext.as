package ru.hrundik.fScheme.exec
{
	public dynamic class ExpressionContext implements IContext
	{
		private var _parentContext:IContext;
		
		public function ExpressionContext(parentContext:IContext)
		{
			_parentContext = parentContext; 
		}

		public function get parentContext():IContext
		{
			return _parentContext;
		}
		
	}
}