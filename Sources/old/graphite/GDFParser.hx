package graphite;
import flash.utils.Dictionary;
import flash.Vector;

/**
 * ...
 * @author worldedit
 */

class GDFParser 
{
	private static var readMode:Int;
	private static var valueType:Int;
	private static var charPtr:Int;
	private static var deep:Int;
	
	public static var DEFAULT:Int = 0;
	public static var KEYREAD1:Int = 1;
	public static var KEYREAD2:Int = 2;
	public static var VALUEREAD:Int = 3;
	
	public static var NUMBER:Int = 1;
	public static var STRING:Int = 2;
	public static var INTEGER:Int = 3;
	
	private static var acE:EReg = ~/[a-zA-Z]/;
	private static var acnE:EReg = ~/[A-Za-z0-9]|_/;
	private static var nE:EReg = ~/[0-9]|\./;
	
	private static var objStack:Vector<Dynamic>;
	private static var objLevels:Vector<Int>;
	
	private static var key:String;
	private static var value:String;
	
	public static function parse(_code:String):Dynamic
	{
		readMode = GDFParser.DEFAULT;
		valueType = GDFParser.DEFAULT;
		deep = 0;
		charPtr = -1;
		var obj:Dynamic = { };
		var len:Int = _code.length;
		
		key = new String('');
		value = new String('');
		
		objStack = new Vector<Dynamic>();
		objLevels = new Vector<Int>();
		
		while (charPtr ++ < len-1)
		{
			var char:String = _code.charAt(charPtr);
			if (char == " " && valueType != STRING && readMode != VALUEREAD)
			{
				continue;
			}
			if (readMode == DEFAULT)
			{
				if (char == "[")
				{
					readMode = KEYREAD1;
					deep ++;
				}
				if (char == "]")
				{
					deep--;
					if(objLevels.length >0)
					if (objLevels[objLevels.length - 1] == deep + 1)
					{
						obj = objStack.pop();
						objLevels.pop();
						key = '';
						value = '';
						readMode = valueType = DEFAULT;
						continue;
					}
				}
			}else if (readMode == KEYREAD1)
			{
				if (acE.match(char))
				{
					key += char;
					readMode = KEYREAD2;
				}
			}else if (readMode == KEYREAD2)
			{
				if (acnE.match(char))
				{
					key += char;
				}else if (char == ":")
				{
					readMode = VALUEREAD;
				}
			}else if (readMode == VALUEREAD)
			{
				if (valueType == STRING && char != '"' && char != "]")
				{
					value += char;
				}
				else if (char == '"')
				{
					valueType = STRING;
				}else if (nE.match(char))
				{
					valueType = INTEGER;
					if (char == ".")
					{
						valueType = NUMBER;
					}
					value += char;
				}else if ((valueType == INTEGER || valueType == NUMBER) && char != "]")
				{
					value += char;
				}else if (char == "[")
				{
					var nobj:Dynamic = { };
					untyped { obj[key] = nobj; }
					objStack.push(obj);
					obj = nobj;
					readMode = KEYREAD1;
					valueType = DEFAULT;
					key = '';
					value = '';
					objLevels.push(deep);
					deep++;
				}else if (char == "]")
				{
					deep --;
					if(valueType == STRING)
					untyped {obj[key] = value;}
					else if (valueType == INTEGER)
					untyped {obj[key] = Std.parseInt(value); } 
					else if (valueType == NUMBER)
					untyped {obj[key] = Std.parseFloat(value); } 
					key = '';
					value = '';
					readMode = valueType = DEFAULT;
				}
			}
		}
		//trace(obj);
		return obj;
	}
	
	public function new() 
	{
		
	}
	
}