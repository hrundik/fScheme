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