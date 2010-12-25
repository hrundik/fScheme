package ru.hrundik.fScheme.exec
{
	import ru.hrundik.fScheme.Name;
	import ru.hrundik.fScheme.Pair;
	import ru.hrundik.fScheme.parser.SchemeParser;
	import ru.hrundik.fScheme.util.DisplayUtil;
	
	public dynamic class DefaultLexicalContext implements IContext
	{
		public function DefaultLexicalContext()
		{
			this["boolean?"] = isBoolean;
			this["pair?"] = isPair;
			this["list?"] = isList;
			this["null?"] = isNull;
			this["vector?"] = isVector;
			this["eqv?"] = isEqv;
			this["eq?"] = isEqv;
			this["equal?"] = isEqual;
			this["isSymbol?"] = isSymbol;
			this["string->symbol"] = string_to_symbol;
			this["symbol->string"] = symbol_to_string;
			this["+"] = plus;
			this["-"] = minus;
			this["*"] = multiply;
			this["/"] = divide;
			this["="] = numEqual;
			this["<"] = numLess;
			this[">"] = numGreater;
			this["<="] = numLessEq;
			this[">="] = numGreaterEq;
			this["number?"] = isNumber;
			this["real?"] = isReal;
			this["integer?"] = isInt; 
			this["procedure?"] = isProcedure;
			this["string?"] = isString;
			this["char?"] = isChar;
			this["display"] = write;
			this["for-each"] = for_each;
			this["make-vector"] = make_vector;
			this["vector-length"] = vector_length;
			this["vector-ref"] = vector_ref;
			this["vector-set!"] = vector_set;
			this["vector-fill!"] = vector_fill;
			this["vector->list"] = vector_to_list;
			this["list->vector"] = list_to_vector;
			
			this["vector-push!"] = vector_push;
			this["vector-pop!"] = vector_pop;
			this["vector-shift!"] = vector_shift;
			this["vector-unshift!"] = vector_unshift;
			
			this["call/cc"] = call_cc;
			this["call-with-current-continuation"] = call_cc;
			this["call-with-values"] = call_with_values;
			
			this["set-car!"] = set_car;
			this["set-cdr!"] = set_cdr;
			this["list-tail"] = list_tail;
			this["list-ref"] = list_ref;
			
			this["char=?"] = stringEq;
			this["char<?"] = stringLess;
			this["char<=?"] = stringLessEq;
			this["char>?"] = stringGreater;
			this["char>=?"] = stringGreaterEq;
			
			this["char-ci=?"] = stringEq_ci;
			this["char-ci<?"] = stringLess_ci;
			this["char-ci<=?"] = stringLessEq_ci;
			this["char-ci>?"] = stringGreater_ci;
			this["char-ci>=?"] = stringGreaterEq_ci;
			
			this["string=?"] = stringEq;
			this["string<?"] = stringLess;
			this["string<=?"] = stringLessEq;
			this["string>?"] = stringGreater;
			this["string>=?"] = stringGreaterEq;
			
			this["string-ci=?"] = stringEq_ci;
			this["string-ci<?"] = stringLess_ci;
			this["string-ci<=?"] = stringLessEq_ci;
			this["string-ci>?"] = stringGreater_ci;
			this["string-ci>=?"] = stringGreaterEq_ci;
			
			this["char-upcase"] = string_upcase;
			this["char-downcase"] = string_downcase;
			
			this["char->integer"] = char_to_integer;
			this["integer->char"] = integer_to_char;
			
			this["char-alphabetic?"] = charIsAlpha;
			this["char-numeric?"] = charIsNum;
			this["char-whitespace?"] = charIsWhitespace;
			this["char-upper-case?"] = charIsUpper;
			this["char-lower-case?"] = charIsLower;
			
			this["make-string"] = make_string;
			this["string-length"] = string_length;
			this["string-ref"] = string_ref;
			this["string-set"] = string_set;
			this["string-append"] = string_append;
			this["string-copy"] = string_copy;
			this["string-fill"] = string_fill;
			this["string->list"] = string_to_list;
			this["list->string"] = list_to_string;
			
			this["number->string"] = number_to_string;
			this["string->number"] = string_to_number;
			this["zero?"] = isZero;
			this["positive?"] = isPositive;
			this["negative?"] = isNegative;
			this["odd?"] = isOdd;
			this["even?"] = isEven;
		}
		
		public var continuation:Continuation;
		
		public function get parentContext ():IContext
		{
			return null;
		}
		
//-------------------------------------------------------------------
//																	
// SYSTEM PROCEDURES, DIRECTLY MANIPULATE ACTION AND RESULT STACKS
//
//-------------------------------------------------------------------
		public function eval(list:Pair):void
		{
			continuation.actionStack.push(new Action(ActionCodes.EVALUATE, list));
		}
		
		public function apply(func:Function, ...rest):*
		{
			var tailArgs:Pair = rest.pop();
			while(!tailArgs.isNull)
			{
				rest.push(tailArgs.car);
				tailArgs = tailArgs.cdrPair;
			}
			
			applyImpl(func, rest);
		}
		
		public function force(promise:Function):*
		{
			var value:* = promise();
			if (value !== undefined)
				continuation.resultStack.push(value);
		}
		
		public function map(func:Function, ...lists):*
		{
			if(Pair(lists[0]).isNull)
			{
				return new Pair();
			}
			else
			{
				var len:Number = lists.length;
				var firsts:Array = new Array(len);
				var rests:Array = new Array(len+1);
				rests[0] = func;
				for(var i:int = 0; i < len; i++)
				{
					var pair:Pair = Pair(lists[i]); 
					firsts[i] = pair.car;
					rests[i+1] = pair.cdr;
				}
				continuation.actionStack.push(new Action(ActionCodes.CALL, 2)); // schedule cons
				continuation.resultStack.push(cons);
				applyPostponed(map, rests); // second argument for cons
				applyImpl(func, firsts); // first argument for cons
			}
		}
		
		private function for_each(func:Function, ...lists):void
		{
			if(Pair(lists[0]).isNull)
				return;
			
			var len:Number = lists.length;
			var firsts:Array = new Array(len);
			var rests:Array = new Array(len+1);
			rests[0] = func;
			for(var i:int = 0; i < len; i++)
			{
				var pair:Pair = Pair(lists[i]); 
				firsts[i] = pair.car;
				rests[i+1] = pair.cdr;
			}
			applyPostponed(for_each, rests);
			continuation.actionStack.push(new Action(ActionCodes.DROP_RESULT));
			applyImpl(func, firsts);
		}
		
		private function applyImpl(func:Function, args:Array):void
		{
			var len:uint = args.length;
			continuation.resultStack.push(func);
			continuation.actionStack.push(new Action(ActionCodes.CALL, len));
			for(var i:int = 0; i < len; i++)
			{
				continuation.resultStack.push(args[i]);
			}
		}
		
		private function applyPostponed(func:Function, args:Array):void
		{
			var len:uint = args.length;
			continuation.actionStack.push(new Action(ActionCodes.CALL, len));
			for(var i:int = len-1; i >= 0; i--)
			{
				continuation.actionStack.push(new Action(ActionCodes.QUOTE, args[i]));
			}
			continuation.actionStack.push(new Action(ActionCodes.QUOTE, func));
		}
		
		public function call_cc(handler:Function):void
		{
			var frozenContinuation:FrozenContinuation = new FrozenContinuation(continuation);
			if(continuation.verbose)
				trace("SAVING STATE");
			var escapeFunction:Function = function (...rest):*
			{
				if(continuation.verbose)
					trace("RESTORING STATE");
				continuation.actionStack = frozenContinuation.actionStack.concat(); // immutable, so create copy
				continuation.resultStack = frozenContinuation.resultStack.concat(); // immutable, so create copy
				continuation.lexicalContext = frozenContinuation.lexicalContext;
				return rest[0];
			};
			continuation.resultStack.push(handler);
			continuation.resultStack.push(escapeFunction);
			continuation.actionStack.push(new Action(ActionCodes.CALL, 1));
		}
		
		public function values (...args):*
		{
			if(args.length > 1)
				return args; // return the arguments as an array;
			else
				return args[0];
		}
		
		private function call_with_values (producer:Function, consumer:Function):void
		{
			continuation.actionStack.push(new Action(ActionCodes.CALL, -1));
			continuation.resultStack.push(consumer);
			continuation.actionStack.push(new Action(ActionCodes.CALL, 0));
			continuation.resultStack.push(producer);
		}
//-------------------------------------------------------------------
//																	
// End of SYSTEM PROCEDURES, DIRECTLY MANIPULATE ACTION AND RESULT STACKS
//
//-------------------------------------------------------------------
		
		public function set_car(pair:Pair, value:*):Pair
		{
			pair.car = value;
			return pair;
		}
		
		public function set_cdr(pair:Pair, value:*):Pair
		{
			pair.cdr = value;
			return pair;
		}
		
		public function car (expr:*):*
		{
			var pair:Pair = expr as Pair;
			if (pair)
				return pair.car;
			else
				return null;
		}
		
		public function cdr (expr:*):*
		{
			var pair:Pair = expr as Pair;
			if (pair)
				return pair.cdr;
			else
				return null;
		}
		
// 
// caar, cadr, ..., cdddar, cddddr
//
		public function caar (expr:*):*
		{
			return car(car(expr));
		}
		
		public function cadr (expr:*):*
		{
			return car(cdr(expr));
		}
		
		public function cdar (expr:*):*
		{
			return cdr(car(expr));
		}
		
		public function cddr (expr:*):*
		{
			return cdr(cdr(expr));
		}
		
		public function caaar (expr:*):*
		{
			return car(car(car(expr)));
		}
		public function caadr (expr:*):*
		{
			return car(car(cdr(expr)));
		}
		public function cadar (expr:*):*
		{
			return car(cdr(car(expr)));
		}
		public function caddr (expr:*):*
		{
			return car(cdr(cdr(expr)));
		}
		public function cdaar (expr:*):*
		{
			return cdr(car(car(expr)));
		}
		public function cdadr (expr:*):*
		{
			return cdr(car(cdr(expr)));
		}
		public function cddar (expr:*):*
		{
			return cdr(cdr(car(expr)));
		}
		public function cdddr (expr:*):*
		{
			return cdr(cdr(cdr(expr)));
		}
		
		public function caaaar (expr:*):*
		{
			return car(car(car(car(expr))));
		}
		public function caaadr (expr:*):*
		{
			return car(car(car(cdr(expr))));
		}
		public function caadar (expr:*):*
		{
			return car(car(cdr(car(expr))));
		}
		public function caaddr (expr:*):*
		{
			return car(car(cdr(cdr(expr))));
		}
		public function cadaar (expr:*):*
		{
			return car(cdr(car(car(expr))));
		}
		public function cadadr (expr:*):*
		{
			return car(cdr(car(cdr(expr))));
		}
		public function caddar (expr:*):*
		{
			return car(cdr(cdr(car(expr))));
		}
		public function cadddr (expr:*):*
		{
			return car(cdr(cdr(cdr(expr))));
		}
		public function cdaaar (expr:*):*
		{
			return cdr(car(car(car(expr))));
		}
		public function cdaadr (expr:*):*
		{
			return cdr(car(car(cdr(expr))));
		}
		public function cdadar (expr:*):*
		{
			return cdr(car(cdr(car(expr))));
		}
		public function cdaddr (expr:*):*
		{
			return cdr(car(cdr(cdr(expr))));
		}
		public function cddaar (expr:*):*
		{
			return cdr(cdr(car(car(expr))));
		}
		public function cddadr (expr:*):*
		{
			return cdr(cdr(car(cdr(expr))));
		}
		public function cdddar (expr:*):*
		{
			return cdr(cdr(cdr(car(expr))));
		}
		public function cddddr (expr:*):*
		{
			return cdr(cdr(cdr(cdr(expr))));
		}
		
//
// end of caar, cadr, ..., cdddar, cddddr
//
		
		public function cons (expr1:*, expr2:*):Pair
		{
			return new Pair(expr1, expr2);
		}
		
		public function list (...values):Pair
		{
			var list:Pair = new Pair();
			var pair:Pair = list;
			var n:int = values.length;
			for(var i:int = 0; i < n; i++)
			{
				pair.car = values[i];
				pair = pair.cdr = new Pair();
			}
			
			return list;
		}
		
		public function length (pair:Pair):int
		{
			var n:int = 0;
			while(!pair.isNull)
			{
				n++;
				pair = pair.cdrPair;
			}
			return n;
		}
		
		public function append (list:Pair, ...lists):*
		{
			var newList:Pair = new Pair();
			var pair:Pair = newList;
			while(!list.isNull)
			{
				pair.car = list.car;
				pair = pair.cdr = new Pair();
				list = list.cdrPair;
			}
			
			for(var i:int = 0; i < lists.length-1; i++)
			{
				list = Pair(lists[i]);
				
				while(!list.isNull)
				{
					pair.car = list.car;
					pair = pair.cdr = new Pair();
					list = list.cdrPair;
				}
			}
			
			list = lists[i] as Pair; // last list
			if(list)
			{
				while(list.cdrPair && !list.cdrPair.isNull)
				{
					pair.car = list.car;
					pair = pair.cdr = new Pair();
					list = list.cdrPair;
				}	
				pair.car = list.car;
				if(list.cdrPair && list.cdrPair.isNull)
					pair.cdr = new Pair();
				else
					pair.cdr = list.cdr;
			}
			else if(i < lists.length && i > -1)
			{
				return lists[i];
			}
			
			return newList;
		}
		
		public function reverse(list:Pair):Pair
		{
			var head:Pair = new Pair();
			reverseHelper(list, head);
			return head;
		}
		
		private function reverseHelper(list:Pair, head:Pair):Pair
		{
			if(list.isNull)
				return head;
			
			var result:Pair = reverseHelper(list.cdrPair, head);
			result.car = list.car;
			result.cdr = new Pair();
			return result.cdrPair;
		}
		
		private function list_tail(list:Pair, k:int):Pair
		{
			for(; k > 0; k--)
			{
				list = list.cdrPair;
			}
			return list;
		}
		
		private function list_ref(list:Pair, k:int):*
		{
			return list_tail(list, k).car;
		}
		
		public function memq(obj:*, list:Pair):*
		{
			while(!list.isNull)
			{
				if(isEqv(list.car, obj))
					return list;
				list = list.cdrPair;
			}
			
			return false;
		}
		
		public function memv(obj:*, list:Pair):*
		{
			return memq(obj, list);
		}
		
		public function member(obj:*, list:Pair):*
		{
			while(!list.isNull)
			{
				if(isEqual(list.car, obj))
					return list;
				list = list.cdrPair;
			}
			
			return false;
		}
		
		public function assq(obj:*, list:Pair):*
		{
			while(!list.isNull)
			{
				if(isEqv(Pair(list.car).car, obj))
					return list.car;
				list = list.cdrPair;
			}
			
			return false;
		}
		
		public function assv(obj:*, list:Pair):*
		{
			assq(obj, list);
		}
		
		public function assoc(obj:*, list:Pair):*
		{
			while(!list.isNull)
			{
				if(isEqual(Pair(list.car).car, obj))
					return list.car;
				list = list.cdrPair;
			}
			
			return false;
		}
		
		private function isPair (expr:*):Boolean
		{
			return expr is Pair; 
		}
		
		private function isList (expr:*):Boolean
		{
			if (expr is Pair)
			{
				var cdr:Pair = Pair(expr).cdr as Pair;
				while (cdr)
				{
					if (cdr.isNull)
						return true;
					cdr = cdr.cdr as Pair;
				}
				return false;
			}
			else
			{
				return false;
			}
		}
		
		private function isNull (expr:*):Boolean
		{
			return expr is Pair && Pair(expr).isNull;
		}
		
		private function isBoolean (expr:*):Boolean
		{
			return expr is Boolean;
		}
		
		private function isVector (expr:*):Boolean
		{
			return expr is Array; 
		}
		
		private function make_vector (n:int, fill:* = null):Array
		{
			var arr:Array = new Array(n); 
			if(fill === null)
			{
				return arr;
			}
			else
			{
				for(n--; n >= 0; n--)
				{
					arr[n] = fill;
				}
			}
			return arr;
		}
		
		public function vector(...elems):Array
		{
			var n:int = elems.length;
			var v:Array = new Array(n);
			for(var i:int = 0; i < n; i++)
			{
				v[i] = elems[i];
			}
			return v;
		}
		
		private function vector_length(vector:Array):int
		{
			return vector.length;
		}
		
		private function vector_ref(vector:Array, i:int):*
		{
			return vector[i];
		}
		
		private function vector_set(vector:Array, i:int, value:*):*
		{
			return vector[i] = value;
		}
		
		private function vector_fill(vector:Array, value:*):Array
		{
			var n:uint = vector.length;
			for(var i:int=0; i < n; i++)
			{
				vector[i] = value;
			}
			return vector;
		}
		
		private function vector_to_list(vector:Array):Pair
		{
			var list:Pair = new Pair();
			var pair:Pair = list;
			var n:int = vector.length;
			for(var i:int = 0; i < n; i++)
			{
				pair.car = vector[i];
				pair = pair.cdr = new Pair();
			}
			return list;
		}
		
		private function list_to_vector(list:Pair):Array
		{
			var vec:Array = [];
			while(!list.isNull)
			{
				vec.push(list.car);
				list = list.cdr;
			}
			return vec;
		}
		
		private function vector_pop(vector:Array):*
		{
			return vector.pop();
		}
		
		private function vector_push(vector:Array, value:*):uint
		{
			return vector.push(value);
		}
		
		private function vector_shift(vector:Array):*
		{
			return vector.shift();
		}
		
		private function vector_unshift(vector:Array, value:*):uint
		{
			return vector.unshift(value);
		}
		
		public function not (expr:*):Boolean
		{
			return expr is Boolean && !expr;
		}
		
		private function isEqv (expr1:*, expr2:*):Boolean
		{
			if (expr1 is Pair && expr2 is Pair)
			{
				if (expr1 == expr2)
					return true;
				else if (Pair(expr1).isNull && Pair(expr2).isNull)
					return true;
				else
					return false;
			}
			else if (expr1 is Name && expr2 is Name)
			{
				return Name(expr1).value == Name(expr2).value;
			}
			else
			{
				return expr1 == expr2;
			}
		}
		
		private function isEqual (expr1:*, expr2:*):Boolean
		{
			if(expr1 is Array && expr2 is Array)
			{
				var arr1:Array = expr1 as Array;
				var arr2:Array = expr2 as Array;
				var len:int = arr1.length;
				if(arr2.length != len)
					return false;
				for(var i:int = 0; i < len; i++)
				{
					if(!isEqual(arr1[i], arr2[i]))
						return false;
				}
				return true;
			}
			else if(expr1 is Pair && expr2 is Pair)
			{
				var p1:Pair = expr1 as Pair;
				var p2:Pair = expr2 as Pair;
				while(!p1.isNull && !p2.isNull)
				{
					if(!isEqual(p1.car, p2.car))
						return false;
					p1 = p1.cdrPair;
					p2 = p2.cdrPair;
					if(!p1 && p2 || p1 && !p2)
						return false;
					else if(!p1 && !p2)
						return isEqual(p1.cdr, p2.cdr);
				}
				return true;
			}
			else
			{
				return isEqv(expr1, expr2);
			}
		}
		
		private function symbol_to_string (symbol:Name):String
		{
			return symbol.value;
		}
		
		private function string_to_symbol (string:String):Name
		{
			return new Name(string);
		}
		
		public function write (expr:*):*
		{
			trace(DisplayUtil.toString(expr));
			return expr;
		}
		
		public function read (expr:*):*
		{
			var parser:SchemeParser = new SchemeParser();
			return parser.parse(String(expr));
		}
		
		public function max (...rest):*
		{
			var value:Number = rest[0];
			for(var i:int = 1; i < rest.length; i++)
			{
				if(rest[i] > value)
					value = rest[i];
			}
			return value;
		}
		
		public function min (...rest):*
		{
			var value:Number = rest[0];
			for(var i:int = 1; i < rest.length; i++)
			{
				if(rest[i] < value)
					value = rest[i];
			}
			return value;
		}
		
		public function abs (x:Number):Number
		{
			if(x < 0)
				return -x;
			return x;
		}
		
		private function minus (...rest):*
		{
			if (rest.length == 1)
			{
				return -rest[0];
			}
			else
			{
				var result:* = rest[0];
				var n:int = rest.length;
				for (var i:int = 1; i < n; i++)
					result -= rest[i];
				return result;
			}
			
		}
		
		private function plus (...rest):*
		{
			var result:* = 0;
			var n:int = rest.length;
			for (var i:int = 0; i < n; i++)
				result += rest[i];
			return result;
		}
		
		private function multiply (...rest):*
		{
			var result:* = 1;
			var n:int = rest.length;
			for (var i:int = 0; i < n; i++)
				result *= rest[i];
			return result;
		}
		
		private function divide (...rest):Number
		{
			if (rest.length == 1)
				return 1 / rest[0];
			var result:Number = rest[0];
			var n:int = rest.length;
			for (var i:int = 1; i < n; i++)
				result /= rest[i];
			return result;
		}
		
		public function floor(num:Number):Number
		{
			return Math.floor(num);
		}
		
		public function ceiling(num:Number):Number
		{
			return Math.ceil(num);
		}
		
		public function round(num:Number):Number
		{
			return Math.round(num);
		}
		
		public function truncate(num:Number):Number
		{
			return int(num);
		}
		
		public function exp(num:Number):Number
		{
			return Math.exp(num);
		}
		
		public function cos(num:Number):Number
		{
			return Math.cos(num);
		}
		
		public function sin(num:Number):Number
		{
			return Math.sin(num);
		}
		
		public function log(num:Number):Number
		{
			return Math.log(num);
		}
		
		public function tan(num:Number):Number
		{
			return Math.tan(num);
		}
		
		public function asin(x:Number):Number
		{
			return Math.asin(x);
		}
		
		public function acos(x:Number):Number
		{
			return Math.acos(x);
		}
		
		public function atan(a:Number, b:Number = NaN):Number
		{
			if(isNaN(b))
				return Math.atan(a);
			else
				return Math.atan2(a, b); 
		}
		
		public function sqrt(a:Number):Number
		{
			return Math.sqrt(a);
		}
		
		public function expt(z1:Number, z2:Number):Number
		{
			if(z1 == 0)
			{
				if(z2 == 0)
					return 1;
				else 
					return 0;
			}
			
			return Math.exp(z2 * Math.log(z1));
		}
		
		private function number_to_string(num:Number, radix:int = 10):String
		{
			var str:String = num.toString(radix);
			if(radix == 10)
				return str;
			else if(radix == 2)
				return "#b"+str;
			else if(radix == 8)
				return "#o"+str;
			else if(radix == 16)
				return "#x"+str;
			else
				return str;
			
		}
		
		private function string_to_number(str:String, radix:int = 10):*
		{
			str = str.toLowerCase();
			var char0:String;
			if(str.length < 3 || (char0 = str.charAt(0)) != '#')
			{
				if(str.indexOf(".") > -1)
					return parseFloat(str);
				else
					return parseInt(str, radix);
			}
			else if(char0)
			{
				var c2:String = str.charAt(1);
				var str:String = str.substr(2);
				if(c2 == 'd')
				{
					if(str.indexOf(".") > -1)
						return parseFloat(str);
					else
						return parseInt(str, radix);
				}
				else if(c2 == 'o')
				{
					return parseInt(str, 8);
				}
				else if(c2 == 'b')
				{
					return parseInt(str, 2);
				}
				else if(c2 == 'x')
				{
					return parseInt(str, 16);
				}
				else
				{
					return false;
				}
			}
			else
			{
				return false;
			}
		}
		
		private function isZero(x:Number):Boolean
		{
			return x == 0;
		}
		
		private function isPositive(x:Number):Boolean
		{
			return x > 0;
		}
		
		private function isNegative(x:Number):Boolean
		{
			return x < 0;
		}
		
		private function isOdd(x:Number):Boolean
		{
			return (x % 2) == 1;
		}
		
		private function isEven(x:Number):Boolean
		{
			return (x % 2) == 0;
		}
		
		private function numEqual (...rest):Boolean
		{
			var arg1:* = rest[0];
			var arg2:*;
			var n:int = rest.length;
			for (var i:int = 1; i < n; i++)
			{
				arg2 = rest[i];
				if (arg1 != arg2)
					return false;
				arg1 = arg2;
			}
			return true;
		}	
		
		private function numLess (...rest):Boolean
		{
			var arg1:* = rest[0];
			var arg2:*;
			var n:int = rest.length;
			for (var i:int = 1; i < n; i++)
			{
				arg2 = rest[i];
				if (arg1 < arg2)
					arg1 = arg2;
				else
					return false;
			
			}
			return true;
		}
		
		private function numGreater (...rest):Boolean
		{
			var arg1:* = rest[0];
			var arg2:*;
			var n:int = rest.length;
			for (var i:int = 1; i < n; i++)
			{
				arg2 = rest[i];
				if (arg1 > arg2)
					arg1 = arg2;
				else
					return false;
			
			}
			return true;
		}
		
		private function numLessEq (...rest):Boolean
		{
			var arg1:* = rest[0];
			var arg2:*;
			var n:int = rest.length;
			for (var i:int = 1; i < n; i++)
			{
				arg2 = rest[i];
				if (arg1 <= arg2)
					arg1 = arg2;
				else
					return false;
			
			}
			return true;
		}
		
		private function numGreaterEq (...rest):Boolean
		{
			var arg1:* = rest[0];
			var arg2:*;
			var n:int = rest.length;
			for (var i:int = 1; i < n; i++)
			{
				arg2 = rest[i];
				if (arg1 >= arg2)
					arg1 = arg2;
				else
					return false;
			
			}
			return true;
		}
		
		private function stringLess (str1:String, str2:String):Boolean
		{
			return str1 < str2;
		}
		
		private function stringLessEq (str1:String, str2:String):Boolean
		{
			return str1 <= str2;
		}
		
		private function stringEq (str1:String, str2:String):Boolean
		{
			return str1 == str2;
		}
		
		private function stringGreater (str1:String, str2:String):Boolean
		{
			return str1 > str2;
		}
		
		private function stringGreaterEq (str1:String, str2:String):Boolean
		{
			return str1 >= str2;
		}
		
		private function stringLess_ci (str1:String, str2:String):Boolean
		{
			return str1.toLowerCase() < str2.toLowerCase();
		}
		
		private function stringLessEq_ci (str1:String, str2:String):Boolean
		{
			return str1.toLowerCase() <= str2.toLowerCase();
		}
		
		private function stringEq_ci (str1:String, str2:String):Boolean
		{
			return str1.toLowerCase() == str2.toLowerCase();
		}
		
		private function stringGreater_ci (str1:String, str2:String):Boolean
		{
			return str1.toLowerCase() > str2.toLowerCase();
		}
		
		private function stringGreaterEq_ci (str1:String, str2:String):Boolean
		{
			return str1.toLowerCase() >= str2.toLowerCase();
		}
		
		private function string_upcase(str:String):String
		{
			return str.toUpperCase();
		}
		
		private function string_downcase(str:String):String
		{
			return str.toLowerCase();
		}
		
		private function char_to_integer(str:String):int
		{
			return str.charCodeAt(0);
		}
		
		private function integer_to_char(code:int):String
		{
			return String.fromCharCode(code);
		}
		
		private function charIsAlpha(char:String):Boolean
		{
			return /^\w$/.exec(char) != null && !charIsNum(char);
		}
		
		private function charIsNum(char:String):Boolean
		{
			return /^\d$/.exec(char) != null;
		}
		
		private function charIsWhitespace(char:String):Boolean
		{
			return /^\s$/.exec(char) != null;
		}
		
		private function charIsUpper(char:String):Boolean
		{
			return char.toUpperCase() == char;
		}
		
		private function charIsLower(char:String):Boolean
		{
			return char.toLowerCase() == char;
		}
		
		private function make_string(length:int, fill:String = " "):String
		{
			var str:String = "";
			while(str.length < length)
				str += fill;
			return str;
		}
		
		public function string(...chars):String
		{
			var str:String = "";
			var n:int = chars.length;
			for(var i:int = 0; i < n; i++)
			{
				str += chars[i];
			}
			return str;
		}
		
		private function string_length(str:String):int
		{
			return str.length;
		}
		
		private function string_ref(str:String, n:int):String
		{
			return str.charAt(n);
		}
		
		private function string_set(str:String, n:int, char:String):String
		{
			return str.slice(0, n) + char + str.slice(n+1);
		}
		
		public function substring(str:String, start:int, end:int):String
		{
			return str.substring(start, end);
		}
		
		private function string_append(...strings):String
		{
			var str:String = strings[0];
			var n:int = strings.length;
			for(var i:int = 1; i < n; i++)
				str += strings[i];
			return str;
		}
		
		private function string_copy(str:String):String
		{
			return str+"";
		}
		
		private function string_fill(str:String, char:String):String
		{
			var newStr:String = "";
			while(newStr.length < str.length)
				newStr += char;
			return newStr;
		}
		
		private function string_to_list(str:String):Pair
		{
			var first:Pair = new Pair();
			var pair:Pair = first;
			var n:int = str.length;
			for(var i:int = 0; i < n; i++)
			{
				pair.car = str.charAt(i);
				pair = pair.cdr = new Pair();
			}
			return first;
		}
		
		private function list_to_string(list:Pair):String
		{
			var str:String = "";
			while(!list.isNull)
			{
				str += list.car;
				list = list.cdrPair;
			}
			return str;
		}
		
		private function isNumber (arg:*):Boolean
		{
			return arg is Number;
		}
		
		private function isInt (arg:*):Boolean
		{
			return arg is int;
		}
		
		private function isReal (arg:*):Boolean
		{
			return arg is Number;
		}
		
		private function isProcedure (arg:*):Boolean
		{
			return arg is Function;
		}
		
		private function isString (arg:*):Boolean
		{
			return arg is String;
		}
		
		private function isChar(arg:*):Boolean
		{
			return arg is String && arg.length == 1;
		}
		
		private function isSymbol (arg:*):Boolean
		{
			return arg is Name;
		}
	}
}