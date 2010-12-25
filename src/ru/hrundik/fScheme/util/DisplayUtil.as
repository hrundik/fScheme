package ru.hrundik.fScheme.util
{
	import ru.hrundik.fScheme.SExpression;
	
	public class DisplayUtil
	{
		private static var strRegExp:RegExp = new RegExp('"', "g");
		
		public static function toString (obj:*):String
		{
			if (obj is SExpression)
			{
				return SExpression(obj).toString();
			}
			else if (obj is Boolean)
			{
				return obj ? "#t" : "#f";
			}
			else if (obj is String)
			{
				return '"'+(obj as String).replace(strRegExp, '\\"')+'"';
			}
			else if (obj is Array)
			{
				var result:String = '#(';
				var n:uint = obj.length;
				if(n > 0)
				{
					result += toString(obj[i]);
					for(var i:int = 1; i < n; i++)
					{
						result += " ";
						result += toString(obj[i]);
					}
				}
				result += ')';
				return result;
			}
			else if (obj != null)
			{
				return obj.toString();
			}
			else
			{
				return String(obj);
			}
				
		}
	}
}