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

public class ClassConstructor
{
	public function ClassConstructor()
	{
		constructors = Vector.<Function>(
			[construct0, constuct1, constuct2, constuct3, constuct4, constuct5,
				constuct6, constuct7, constuct8, constuct9, constuct10]);
	}
	
	private var constructors:Vector.<Function>;
	
	public function construct(classObject:Object, args:Array):*
	{
		var constructorF:Function = constructors[args.length];
		return constructorF.apply(this, [classObject].concat(args));
	}
	
	private function construct0(classObject:Object):*
	{
		return new classObject();
	}
	
	private function constuct1(classObject:Object, arg1:*):*
	{
		return new classObject(arg1);
	}
	
	private function constuct2(classObject:Object, arg1:*, arg2:*):*
	{
		return new classObject(arg1, arg2);
	}
	
	private function constuct3(classObject:Object, arg1:*, arg2:*, arg3:*):*
	{
		return new classObject(arg1, arg2, arg3);
	}
	
	private function constuct4(classObject:Object, arg1:*, arg2:*, arg3:*, arg4:*):*
	{
		return new classObject(arg1, arg2, arg3, arg4);
	}
	
	private function constuct5(classObject:Object, arg1:*, arg2:*, arg3:*, arg4:*, arg5:*):*
	{
		return new classObject(arg1, arg2, arg3, arg4, arg5);
	}
	
	private function constuct6(classObject:Object, arg1:*, arg2:*, arg3:*, arg4:*, arg5:*,
		arg6:*):*
	{
		return new classObject(arg1, arg2, arg3, arg4, arg5, arg6);
	}
	
	private function constuct7(classObject:Object, arg1:*, arg2:*, arg3:*, arg4:*, arg5:*,
		arg6:*, arg7:*):*
	{
		return new classObject(arg1, arg2, arg3, arg4, arg5, arg6, arg7);
	}
	
	private function constuct8(classObject:Object, arg1:*, arg2:*, arg3:*, arg4:*, arg5:*,
		arg6:*, arg7:*, arg8:*):*
	{
		return new classObject(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
	}
	
	private function constuct9(classObject:Object, arg1:*, arg2:*, arg3:*, arg4:*, arg5:*,
		arg6:*, arg7:*, arg8:*, arg9:*):*
	{
		return new classObject(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
	}
	
	private function constuct10(classObject:Object, arg1:*, arg2:*, arg3:*, arg4:*, arg5:*,
		arg6:*, arg7:*, arg8:*, arg9:*, arg10:*):*
	{
		return new classObject(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
	}
}
}