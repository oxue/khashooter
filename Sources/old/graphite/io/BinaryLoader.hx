package graphite.io;
import sys.io.File;

/**
 * ...
 * @author worldedit
 */

class BinaryLoader 
{
	
	private var _callback:Void->Void;
	
	public var data:String;

	public function new() 
	{
		data = new String('');
	}
	
	public function load(_url:String, __callback:Void->Void):Void
	{
		_callback = __callback;
		data = File.getContent(_url);
		__callback();
	}
	
}