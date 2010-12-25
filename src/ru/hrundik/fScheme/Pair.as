package ru.hrundik.fScheme
{
	import ru.hrundik.fScheme.util.DisplayUtil;
	
	public class Pair extends SExpression
	{
		public var car:*;
		public var cdr:*;
		
		public function Pair(car:*=null, cdr:*=null)
		{
			this.car = car;
			this.cdr = cdr;
		}
		
		public function get cdrPair ():Pair
		{
			return cdr as Pair;
		}
		
		public function get isNull ():Boolean
		{
			return car == null && cdr == null;
		}
		
		override public function toString ():String
		{
			if (isNull)
				return "()";
				
			var result:String = "(";
			var pair:Pair = this;
				
			while (pair && !pair.isNull)
			{
				var data:String = pair.car == null ? "()" : DisplayUtil.toString(pair.car);
				var cdr:Object = pair.cdr;
				pair = cdr as Pair;
				if (pair)
					result += data + (pair.isNull ? "" : " ");
				else if (cdr)
					result += data+" . "+DisplayUtil.toString(cdr);
				else
					result += data+" . null";
			}
			result += ")";
			return result;
		}
		
	}
}