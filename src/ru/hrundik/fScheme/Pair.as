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

package ru.hrundik.fScheme
{
	import ru.hrundik.fScheme.util.DisplayUtil;
	
	final public class Pair extends SExpression
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